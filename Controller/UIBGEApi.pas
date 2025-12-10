unit UIBGEApi;

interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.Generics.Collections,
  UModelTypes,
  System.Net.HttpClientComponent,
  System.StrUtils;

type
  TIBGEService = class
  private
    FHttpClient: TNetHttpClient;
    FMunicipiosIBGE: TDictionary<string, TMunicipioIBGE>;

    function NormalizeString(const S: string): string;
    function SafeGetString(AObj: TJSONObject; const AName: string): string;
    function SafeGetObject(AObj: TJSONObject; const AName: string): TJSONObject;
    procedure LoadAllMunicipios;

  public
    constructor Create(AHttpClient: TNetHttpClient);
    destructor Destroy; override;

    function FindMunicipio(const AName: string): TMunicipioIBGE;
  end;

implementation

const
  IBGE_API_URL = 'https://servicodados.ibge.gov.br/api/v1/localidades/municipios';

function TIBGEService.SafeGetString(AObj: TJSONObject; const AName: string): string;
var
  V: TJSONValue;
begin
  if not Assigned(AObj) then Exit('');
  V := AObj.GetValue(AName);
  if Assigned(V) then
    Result := V.Value
  else
    Result := '';
end;

function TIBGEService.SafeGetObject(AObj: TJSONObject; const AName: string): TJSONObject;
var
  V: TJSONValue;
begin
  if not Assigned(AObj) then Exit(nil);
  V := AObj.GetValue(AName);
  if (Assigned(V)) and (V is TJSONObject) then
    Result := TJSONObject(V)
  else
    Result := nil;
end;

function TIBGEService.NormalizeString(const S: string): string;
var
  L: string;
begin
  L := Trim(S).ToLower;

  L := StringReplace(L, 'ã', 'a', [rfReplaceAll]);
  L := StringReplace(L, 'õ', 'o', [rfReplaceAll]);
  L := StringReplace(L, 'á', 'a', [rfReplaceAll]);
  L := StringReplace(L, 'à', 'a', [rfReplaceAll]);
  L := StringReplace(L, 'â', 'a', [rfReplaceAll]);
  L := StringReplace(L, 'é', 'e', [rfReplaceAll]);
  L := StringReplace(L, 'ê', 'e', [rfReplaceAll]);
  L := StringReplace(L, 'í', 'i', [rfReplaceAll]);
  L := StringReplace(L, 'ó', 'o', [rfReplaceAll]);
  L := StringReplace(L, 'ô', 'o', [rfReplaceAll]);
  L := StringReplace(L, 'ú', 'u', [rfReplaceAll]);
  L := StringReplace(L, 'ç', 'c', [rfReplaceAll]);
  L := StringReplace(L, '-', '', [rfReplaceAll]);
  L := StringReplace(L, ' ', '', [rfReplaceAll]);

  Result := UpperCase(L);
end;

constructor TIBGEService.Create(AHttpClient: TNetHttpClient);
begin
  inherited Create;
  FHttpClient := AHttpClient;
  FMunicipiosIBGE := TDictionary<string, TMunicipioIBGE>.Create;
  LoadAllMunicipios;
end;

destructor TIBGEService.Destroy;
begin
  FMunicipiosIBGE.Free;
  inherited Destroy;
end;

procedure TIBGEService.LoadAllMunicipios;
var
  LResponse: IHttpResponse;
  LJSONArray: TJSONArray;
  LMunicipio: TJSONObject;
  LMeso, LMicro, LUF, LRegiao: TJSONObject;
  Item: TMunicipioIBGE;
  I: Integer;
begin
  FHttpClient.ConnectionTimeout := 30000;

  LResponse := FHttpClient.Get(IBGE_API_URL);

  if LResponse.StatusCode <> 200 then
    raise Exception.Create('Erro ao consultar IBGE. HTTP ' + LResponse.StatusCode.ToString);

  LJSONArray := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONArray;

  if not Assigned(LJSONArray) then
    raise Exception.Create('Resposta inválida da API IBGE (JSON malformado).');

  try
    for I := 0 to LJSONArray.Count - 1 do
    begin
      LMunicipio := LJSONArray.Items[I] as TJSONObject;

      Item.MunicipioIBGE := SafeGetString(LMunicipio, 'nome');
      Item.IdIBGE := LMunicipio.GetValue<Int64>('id', 0);

      LMicro   := SafeGetObject(LMunicipio, 'microrregiao');
      LMeso    := SafeGetObject(LMicro, 'mesorregiao');
      LUF      := SafeGetObject(LMeso, 'UF');
      LRegiao  := SafeGetObject(LUF, 'regiao');

      Item.UF := SafeGetString(LUF, 'sigla');
      Item.Regiao := SafeGetString(LRegiao, 'nome');

      Item.ChaveBusca := NormalizeString(Item.MunicipioIBGE);

      FMunicipiosIBGE.AddOrSetValue(Item.ChaveBusca, Item);
    end;

  finally
    LJSONArray.Free;
  end;

  FHttpClient.ConnectionTimeout := 5000;
end;

function TIBGEService.FindMunicipio(const AName: string): TMunicipioIBGE;
var
  Key: string;
begin
  Key := NormalizeString(AName);

  if FMunicipiosIBGE.TryGetValue(Key, Result) then
    Exit;

  Result.MunicipioIBGE := '';
  Result.IdIBGE := 0;
  Result.UF := '';
  Result.Regiao := '';
  Result.ChaveBusca := '';
end;

end.

