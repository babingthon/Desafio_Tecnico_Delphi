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
  System.Net.HttpClientComponent;

type
  TProcessController = class
  private
    FIBGEService: TIBGEService;
    FHttpClient: TNetHTTPClient;
    FAuthToken: string;
    FProcessedList: TList<TMunicipioProcessado>;
    function ProcessLine(const Line: string): TMunicipioProcessado;
    procedure CalculateStatistics(AStats: TJSONObject);
    procedure GenerateCSVFile;
    procedure SendStats(const AStats: TJSONObject);
    function CheckAndLoadInputFile(const AInputFilePath: string): TStringDynArray;
  public
    constructor Create(AHttpClient: TNetHTTPClient; const AAuthToken: string);
    destructor Destroy; override;
    procedure Execute(const AInputFilePath: string);
  end;

implementation

uses
  System.StrUtils,
  System.Math;

const
  CORRECTOR_API_URL = 'https://mynxlubykylncinttggu.functions.supabase.co/ibge-submit';
  INPUT_CSV_CONTENT: array[0..10] of string = (
    'municipio,populacao',
    'Niteroi,515317',
    'Sao Gonçalo,1091737',
    'Sao Paulo,12396372',
    'Belo Horzionte,2530701',
    'Florianopolis,516524',
    'Santo Andre,723889',
    'Santoo Andre,700000',
    'Rio de Janeiro,6718903',
    'Curitba,1963726',
    'Brasilia,3094325'
    );

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

function TProcessController.CheckAndLoadInputFile(const AInputFilePath: string): TStringDynArray;
var
  LStringList: TStringList;
  I: Integer;
begin
  if not TFile.Exists(AInputFilePath) then
  begin
    LStringList := TStringList.Create;
    try
      for I := Low(INPUT_CSV_CONTENT) to High(INPUT_CSV_CONTENT) do
        LStringList.Add(INPUT_CSV_CONTENT[I]);

      LStringList.SaveToFile(AInputFilePath, TEncoding.UTF8);
      Writeln(Format('Aviso: Arquivo input.csv não encontrado. Um novo arquivo foi criado em: %s', [AInputFilePath]));
    finally
      LStringList.Free;
    end;
  end;

  try
    Result := TFile.ReadAllLines(AInputFilePath, TEncoding.UTF8);
  except
    on E: Exception do
      raise Exception.Create('Erro ao ler o arquivo input.csv: ' + E.Message);
  end;
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

  LFileLines := CheckAndLoadInputFile(AInputFilePath);

  for I := 1 to High(LFileLines) do
  begin
    LProcessedItem := ProcessLine(LFileLines[I]);
    FProcessedList.Add(LProcessedItem);
  end;

  GenerateCSVFile;

  LStatsJSON := TJSONObject.Create;
  try
    CalculateStatistics(LStatsJSON);
    SendStats(LStatsJSON);
  finally
    LStatsJSON.Free;
  end;
end;

procedure TProcessController.GenerateCSVFile;
var
  LStringList: TStringList;
  LItem: TMunicipioProcessado;
  LFileName: string;
begin
  LFileName := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'resultado.csv');
  LStringList := TStringList.Create;
  try
    LStringList.Add('municipio_input,populacao_input,municipio_ibge,uf,regiao,id_ibge,status');

    for LItem in FProcessedList do
    begin
      LStringList.Add(
        LItem.MunicipioInput + ',' +
        IntToStr(LItem.PopulacaoInput) + ',' +
        LItem.MunicipioIBGE + ',' +
        LItem.UF + ',' +
        LItem.Regiao + ',' +
        IntToStr(LItem.IdIBGE) + ',' +
        StatusToString(LItem.Status)
      );
    end;

    LStringList.SaveToFile(LFileName, TEncoding.UTF8);
  finally
    LStringList.Free;
  end;
end;

procedure TProcessController.CalculateStatistics(AStats: TJSONObject);
var
  LItem: TMunicipioProcessado;
  LStats: TDictionary<string, TRegiaoStats>;
  LTotalOK: Integer;
  LTotalNaoEncontrado: Integer;
  LTotalErroAPI: Integer;
  LPopTotalOK: Int64;
  LRegiaoStats: TRegiaoStats;
  LMediasJSON: TJSONObject;
  LPair: TPair<string, TRegiaoStats>;
  Media: Double;
begin
  if AStats = nil then
    raise Exception.Create('Parâmetro AStats não pode ser nil.');

  LTotalOK := 0;
  LTotalNaoEncontrado := 0;
  LTotalErroAPI := 0;
  LPopTotalOK := 0;
  LStats := TDictionary<string, TRegiaoStats>.Create;
  LMediasJSON := TJSONObject.Create;

  try
    for LItem in FProcessedList do
    begin
      case LItem.Status of
        stOK:
          begin
            Inc(LTotalOK);
            Inc(LPopTotalOK, LItem.PopulacaoInput);

            if not LStats.TryGetValue(LItem.Regiao, LRegiaoStats) then
              FillChar(LRegiaoStats, SizeOf(TRegiaoStats), 0);

            Inc(LRegiaoStats.TotalPopulacao, LItem.PopulacaoInput);
            Inc(LRegiaoStats.TotalMunicipios);
            LStats.AddOrSetValue(LItem.Regiao, LRegiaoStats);
          end;
        stNAO_ENCONTRADO:
          Inc(LTotalNaoEncontrado);
        stERRO_API:
          Inc(LTotalErroAPI);
      end;
    end;

    for LPair in LStats do
    begin
      if LPair.Value.TotalMunicipios > 0 then
      begin
        Media := LPair.Value.TotalPopulacao / LPair.Value.TotalMunicipios;
        LMediasJSON.AddPair(LPair.Key, TJSONNumber.Create(Media));
      end;
    end;

    AStats.AddPair('total_municipios', TJSONNumber.Create(FProcessedList.Count));
    AStats.AddPair('total_ok', TJSONNumber.Create(LTotalOK));
    AStats.AddPair('total_nao_encontrado', TJSONNumber.Create(LTotalNaoEncontrado));
    AStats.AddPair('total_erro_api', TJSONNumber.Create(LTotalErroAPI));
    AStats.AddPair('pop_total_ok', TJSONNumber.Create(LPopTotalOK));
    AStats.AddPair('medias_por_regiao', LMediasJSON);
  finally
    LStats.Free;
  end;
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

