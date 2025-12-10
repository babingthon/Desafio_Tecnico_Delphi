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
  UIBGEApi,
  System.Net.HttpClientComponent,
  Datasnap.DBClient;

type
  TProcessController = class
  private
    FIBGEService: TIBGEService;
    FHttpClient: TNetHTTPClient;
    FAuthToken: string;
    FProcessedList: TList<TMunicipioProcessado>;
    function ProcessLine(const Line: string): TMunicipioProcessado;
    procedure SaveStatsJSONToFile(const AStats: TJSONObject);
  public
    constructor Create(AHttpClient: TNetHTTPClient; const AAuthToken: string);
    destructor Destroy; override;
    procedure Execute(const AInputFilePath: string);
    procedure CalculateStatistics(const ASourceData: TClientDataSet; out AStats: TJSONObject);
    procedure GenerateCSVFile(const ASourceData: TClientDataSet);
    procedure SendStats(const AStats: TJSONObject);
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
  FHttpClient := AHttpClient;
  FAuthToken := AAuthToken;
  FProcessedList := TList<TMunicipioProcessado>.Create;

  try
    FIBGEService := TIBGEService.Create(FHttpClient);
  except
    on E: Exception do
      raise Exception.Create('Falha ao inicializar o serviço IBGE: ' + E.Message);
  end;
end;

destructor TProcessController.Destroy;
begin
  FreeAndNil(FIBGEService);
  FreeAndNil(FProcessedList);
  inherited Destroy;
end;

function TProcessController.ProcessLine(const Line: string): TMunicipioProcessado;
var
  LParts: TStringDynArray;
  LPop: Int64;
  LNome: string;
  LDataIBGE: TMunicipioIBGE;
begin
  FillChar(Result, SizeOf(TMunicipioProcessado), 0);
  Result.Status := stERRO_API;

  LParts := Line.Split([',']);

  for var I := 0 to High(LParts) do
    LParts[I] := Trim(LParts[I]);

  if Length(LParts) < 2 then
    Exit;

  LNome := Trim(LParts[0]);

  if not TryStrToInt64(Trim(LParts[1]), LPop) then
  begin
    Result.MunicipioInput := LNome;
    Result.PopulacaoInput := 0;
    Result.Status := stNAO_ENCONTRADO;
    Exit;
  end;

  Result.MunicipioInput := LNome;
  Result.PopulacaoInput := LPop;

  LDataIBGE := FIBGEService.FindMunicipio(LNome);

  if LDataIBGE.MunicipioIBGE <> '' then
  begin
    Result.MunicipioIBGE := LDataIBGE.MunicipioIBGE;
    Result.UF := LDataIBGE.UF;
    Result.Regiao := LDataIBGE.Regiao;
    Result.IdIBGE := LDataIBGE.IdIBGE;
    Result.Status := stOK;
  end
  else
    Result.Status := stNAO_ENCONTRADO;
end;

procedure TProcessController.Execute(const AInputFilePath: string);
var
  LFileLines: TStringDynArray;
  LProcessedItem: TMunicipioProcessado;
  LStatsJSON: TJSONObject;
  I: Integer;
begin
  FProcessedList.Clear;

  //LFileLines := CheckAndLoadInputFile(AInputFilePath);

  for I := 1 to High(LFileLines) do
  begin
    LProcessedItem := ProcessLine(LFileLines[I]);
    FProcessedList.Add(LProcessedItem);
  end;

  LStatsJSON := TJSONObject.Create;
  try
    //CalculateStatistics(LStatsJSON);
    SendStats(LStatsJSON);
  finally
    LStatsJSON.Free;
  end;
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

    SaveStatsJSONToFile(AStats);
  finally
    ASourceData.EnableControls;
    LStats.Free;
  end;
end;

procedure TProcessController.SaveStatsJSONToFile(const AStats: TJSONObject);
var
  LFilePath: string;
  LJSONFormatted: string;
begin
  if AStats = nil then
    raise Exception.Create('Objeto JSON de estatísticas está vazio.');

  LFilePath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'stats_output.json');

  LJSONFormatted := AStats.Format(2);
  TFile.WriteAllText(LFilePath, LJSONFormatted, TEncoding.UTF8);
end;

procedure TProcessController.SendStats(const AStats: TJSONObject);
var
  LResponse: IHTTPResponse;
  LJSONPayload: TJSONObject;
  LJSONResponse: TJSONObject;
  LStream: TStringStream;
  Score: Double;
  Feedback: string;
begin
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

      if LResponse.StatusCode = 200 then
      begin
        LJSONResponse := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONObject;
        try
          Writeln('✅ Envio de resultados OK.');

          if LJSONResponse.TryGetValue<Double>('score', Score) then
            Writeln(Format('Score Recebido: %.2f', [Score]))
          else
            Writeln('Score não encontrado na resposta.');

          if LJSONResponse.TryGetValue<string>('feedback', Feedback) then
            Writeln('Feedback: ' + Feedback);
        finally
          LJSONResponse.Free;
        end;
      end
      else
      begin
        raise Exception.Create(Format('Erro HTTP %d ao enviar resultados. Detalhe: %s', [LResponse.StatusCode, LResponse.ContentAsString]));
      end;
    finally
      LStream.Free;
    end;
  finally
    LJSONPayload.Free;
  end;
end;

end.

