unit UProcessController;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.IOUtils,
  System.Types,
  UModelTypes,
  System.Net.HttpClientComponent,
  Datasnap.DBClient;

type
  TProcessController = class
  private
    FHttpClient: TNetHTTPClient;
    FAuthToken: string;
    function PrettyJSON(const AJson: string): string;
    procedure SaveStatsJSONToFile(const APayload: TJSONObject);
  public
    constructor Create(AHttpClient: TNetHTTPClient; const AAuthToken: string);
    destructor Destroy; override;

    procedure CalculateStatistics(const ASourceData: TClientDataSet; out AStats: TJSONObject);
    procedure GenerateCSVFile(const ASourceData: TClientDataSet);
    function SendStats(const AStats: TJSONObject): string;
  end;

implementation

uses
  System.StrUtils,
  System.Math;

const
  CORRECTOR_API_URL = 'https://mynxlubykylncinttggu.functions.supabase.co/ibge-submit';

{ TProcessController }

constructor TProcessController.Create(AHttpClient: TNetHTTPClient; const AAuthToken: string);
begin
  inherited Create;

  if AHttpClient = nil then
    raise Exception.Create('HttpClient não pode ser nil.');

  FHttpClient := AHttpClient;
  FAuthToken := AAuthToken;
end;

destructor TProcessController.Destroy;
begin
  inherited Destroy;
end;

procedure TProcessController.GenerateCSVFile(const ASourceData: TClientDataSet);
var
  LStringList: TStringList;
  LFileName: string;

  function SafeCSV(const S: string): string;
  begin
    if (S.Contains(',')) or (S.Contains('"')) then
      Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"'
    else
      Result := S;
  end;

begin
  LFileName := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'resultado.csv');
  LStringList := TStringList.Create;

  ASourceData.DisableControls;
  try
    LStringList.Add('municipio_input,populacao_input,municipio_ibge,uf,regiao,id_ibge,status');

    if ASourceData.Active and (ASourceData.RecordCount > 0) then
    begin
      ASourceData.First;
      while not ASourceData.EOF do
      begin
        LStringList.Add(
          SafeCSV(ASourceData.FieldByName('MUNICIPIO_INPUT').AsString) + ',' +
          ASourceData.FieldByName('POPULACAO_INPUT').AsLargeInt.ToString + ',' +
          SafeCSV(ASourceData.FieldByName('MUNICIPIO_IBGE').AsString) + ',' +
          ASourceData.FieldByName('UF').AsString + ',' +
          ASourceData.FieldByName('REGIAO').AsString + ',' +
          ASourceData.FieldByName('ID_IBGE').AsLargeInt.ToString + ',' +
          ASourceData.FieldByName('STATUS').AsString
        );

        ASourceData.Next;
      end;
    end;

    LStringList.SaveToFile(LFileName, TEncoding.UTF8);
  finally
    ASourceData.EnableControls;
    LStringList.Free;
  end;
end;

function TProcessController.PrettyJSON(const AJson: string): string;
var
  JsonValue: TJSONValue;
begin
  Result := AJson;

  JsonValue := TJSONObject.ParseJSONValue(AJson);
  try
    if Assigned(JsonValue) then
      Result := JsonValue.Format(2);
  finally
    JsonValue.Free;
  end;
end;

procedure TProcessController.CalculateStatistics(const ASourceData: TClientDataSet; out AStats: TJSONObject);
var
  LStats: TDictionary<string, TRegiaoStats>;
  LTotalOK: Integer;
  LTotalNaoEncontrado: Integer;
  LTotalErroAPI: Integer;
  LPopTotalOK: Int64;
  LRegiaoStats: TRegiaoStats;
  LMediasJSON: TJSONObject;
  LPair: TPair<string, TRegiaoStats>;
  LStatusStr: string;
  LPop: Int64;
  LRegiao: string;
  Media: Double;
begin
  AStats := nil;

  if (not ASourceData.Active) or (ASourceData.RecordCount = 0) then
    raise Exception.Create('Dataset vazio ou não carregado.');

  LTotalOK := 0;
  LTotalNaoEncontrado := 0;
  LTotalErroAPI := 0;
  LPopTotalOK := 0;

  LStats := TDictionary<string, TRegiaoStats>.Create;
  LMediasJSON := TJSONObject.Create;

  ASourceData.DisableControls;
  try
    ASourceData.First;

    while not ASourceData.EOF do
    begin
      LStatusStr := ASourceData.FieldByName('STATUS').AsString;

      if LStatusStr = StatusToString(stOK) then
      begin
        Inc(LTotalOK);

        LPop := ASourceData.FieldByName('POPULACAO_INPUT').AsLargeInt;
        Inc(LPopTotalOK, LPop);

        LRegiao := ASourceData.FieldByName('REGIAO').AsString;

        if not LStats.TryGetValue(LRegiao, LRegiaoStats) then
          FillChar(LRegiaoStats, SizeOf(TRegiaoStats), 0);

        Inc(LRegiaoStats.TotalPopulacao, LPop);
        Inc(LRegiaoStats.TotalMunicipios);
        LStats.AddOrSetValue(LRegiao, LRegiaoStats);
      end
      else if LStatusStr = StatusToString(stNAO_ENCONTRADO) then
      begin
        Inc(LTotalNaoEncontrado);
      end
      else if LStatusStr = StatusToString(stERRO_API) then
      begin
        Inc(LTotalErroAPI);
      end;

      ASourceData.Next;
    end;

    for LPair in LStats do
    begin
      if LPair.Value.TotalMunicipios > 0 then
      begin
        Media := LPair.Value.TotalPopulacao / LPair.Value.TotalMunicipios;
        LMediasJSON.AddPair(LPair.Key, TJSONNumber.Create(Media));
      end;
    end;

    AStats := TJSONObject.Create;
    AStats.AddPair('total_municipios', TJSONNumber.Create(ASourceData.RecordCount));
    AStats.AddPair('total_ok', TJSONNumber.Create(LTotalOK));
    AStats.AddPair('total_nao_encontrado', TJSONNumber.Create(LTotalNaoEncontrado));
    AStats.AddPair('total_erro_api', TJSONNumber.Create(LTotalErroAPI));
    AStats.AddPair('pop_total_ok', TJSONNumber.Create(LPopTotalOK));
    AStats.AddPair('medias_por_regiao', LMediasJSON);
  finally
    ASourceData.EnableControls;
    LStats.Free;
  end;
end;

procedure TProcessController.SaveStatsJSONToFile(const APayload: TJSONObject);
var
  LFilePath: string;
  LJSONFormatted: string;
begin
  if APayload = nil then
    raise Exception.Create('Objeto JSON de estatísticas está vazio.');

  LFilePath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'stats_output.json');

  LJSONFormatted := APayload.Format(2);
  TFile.WriteAllText(LFilePath, LJSONFormatted, TEncoding.UTF8);
end;

function TProcessController.SendStats(const AStats: TJSONObject): string;
var
  LResponse: IHTTPResponse;
  LJSONPayload: TJSONObject;
  LJSONResponse: TJSONObject;
  LStream: TStringStream;
begin
  Result := '';

  if AStats = nil then
    raise Exception.Create('Stats JSON não pode ser nil ao enviar para o corretor.');

  FHttpClient.CustomHeaders['Authorization'] := 'Bearer ' + FAuthToken;

  LJSONPayload := TJSONObject.Create;
  try
    LJSONPayload.AddPair('stats', AStats.Clone as TJSONObject);

    SaveStatsJSONToFile(LJSONPayload);

    LStream := TStringStream.Create(LJSONPayload.ToString, TEncoding.UTF8);
    try
      LResponse := FHttpClient.Post(
        CORRECTOR_API_URL,
        LStream,
        nil,
        [TNameValuePair.Create('Content-Type', 'application/json')]
      );

      if LResponse.StatusCode <> 200 then
      begin
        raise Exception.CreateFmt(
          'Erro HTTP %d ao enviar resultados. Detalhe: %s',
          [LResponse.StatusCode, LResponse.ContentAsString]
        );
      end;

      Result := PrettyJSON(LResponse.ContentAsString);

      LJSONResponse := TJSONObject.ParseJSONValue(Result) as TJSONObject;
      if Assigned(LJSONResponse) then
        LJSONResponse.Free;

    finally
      LStream.Free;
    end;

  finally
    LJSONPayload.Free;
  end;
end;

end.

