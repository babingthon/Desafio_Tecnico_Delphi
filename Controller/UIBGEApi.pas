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
  System.StrUtils,
  System.Math;

type
  TIBGEService = class
  private
    FHttpClient: TNetHTTPClient;
    FMunicipiosIBGE: TDictionary<string, TMunicipioIBGE>;

    function NormalizeString(const S: string): string;
    function Levenshtein(const S1, S2: string): Integer;

    function SafeGetString(AObj: TJSONObject; const AName: string): string;
    function SafeGetObject(AObj: TJSONObject; const AName: string): TJSONObject;

    function FindFuzzy(const AName: string): TMunicipioIBGE;
    procedure LoadAllMunicipios;

  public
    constructor Create(AHttpClient: TNetHTTPClient);
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
  if not Assigned(AObj) then
    Exit('');
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
  if not Assigned(AObj) then
    Exit(nil);
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

function TIBGEService.Levenshtein(const S1, S2: string): Integer;
var
  I, J: Integer;
  Cost: Integer;
  d: array of array of Integer;
begin
  SetLength(d, Length(S1) + 1, Length(S2) + 1);

  for I := 0 to Length(S1) do
    d[I][0] := I;

  for J := 0 to Length(S2) do
    d[0][J] := J;

  for I := 1 to Length(S1) do
    for J := 1 to Length(S2) do
    begin
      if S1[I] = S2[J] then
        Cost := 0
      else
        Cost := 1;

      d[I][J] := Min(
        Min(d[I - 1][J] + 1, d[I][J - 1] + 1),
        d[I - 1][J - 1] + Cost
      );
    end;

  Result := d[Length(S1)][Length(S2)];
end;

constructor TIBGEService.Create(AHttpClient: TNetHTTPClient);
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
  LResponse: IHTTPResponse;
  LJSONArray: TJSONArray;
  LMun, LMeso, LMicro, LUF, LReg: TJSONObject;
  Item: TMunicipioIBGE;
  I: Integer;
begin
  LResponse := FHttpClient.Get(IBGE_API_URL);

  if LResponse.StatusCode <> 200 then
    raise Exception.Create('Erro ao consultar IBGE: HTTP ' + LResponse.StatusCode.ToString);

  LJSONArray := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONArray;
  if not Assigned(LJSONArray) then
    raise Exception.Create('JSON inválido do IBGE');

  try
    for I := 0 to LJSONArray.Count - 1 do
    begin
      LMun := LJSONArray.Items[I] as TJSONObject;

      Item.MunicipioIBGE := SafeGetString(LMun, 'nome');
      Item.IdIBGE := LMun.GetValue<Int64>('id', 0);

      LMicro := SafeGetObject(LMun, 'microrregiao');
      LMeso := SafeGetObject(LMicro, 'mesorregiao');
      LUF := SafeGetObject(LMeso, 'UF');
      LReg := SafeGetObject(LUF, 'regiao');

      Item.UF := SafeGetString(LUF, 'sigla');
      Item.Regiao := SafeGetString(LReg, 'nome');

      Item.ChaveBusca := NormalizeString(Item.MunicipioIBGE);

      FMunicipiosIBGE.AddOrSetValue(Item.ChaveBusca, Item);
    end;
  finally
    LJSONArray.Free;
  end;
end;

function TIBGEService.FindFuzzy(const AName: string): TMunicipioIBGE;
var
  Normal: string;
  BestKey: string;
  BestDist: Integer;
  Dist: Integer;
  Item: TMunicipioIBGE;
  Pair: TPair<string, TMunicipioIBGE>;
  S: string;
begin
  Result.MunicipioIBGE := '';
  Result.IdIBGE := 0;

  Normal := NormalizeString(AName);
  BestDist := 99;
  BestKey := '';

  S := Normal;
  if Pos('OO', S) > 0 then
    Exit;
  if Pos('AA', S) > 0 then
    Exit;
  if Pos('EE', S) > 0 then
    Exit;
  if Pos('II', S) > 0 then
    Exit;
  if Pos('UU', S) > 0 then
    Exit;

  for Pair in FMunicipiosIBGE do
  begin
    if Abs(Length(Normal) - Length(Pair.Key)) > 1 then
      Continue;

    Dist := Levenshtein(Normal, Pair.Key);

    if Dist <= 2 then
    begin
      if Dist < BestDist then
      begin
        BestDist := Dist;
        BestKey := Pair.Key;
      end;
    end;
  end;

  if (BestDist <= 2) and FMunicipiosIBGE.TryGetValue(BestKey, Item) then
    Result := Item;
end;

function TIBGEService.FindMunicipio(const AName: string): TMunicipioIBGE;
var
  Key: string;
begin
  Key := NormalizeString(AName);

  if FMunicipiosIBGE.TryGetValue(Key, Result) then
    Exit;

  Result := FindFuzzy(AName);
end;

end.

