unit UModelTypes;

interface

uses
  System.SysUtils;

type
  TStatus = (stOK, stNAO_ENCONTRADO, stERRO_API, stAMBIGUO);

  TMunicipioProcessado = record
    MunicipioInput: string;
    PopulacaoInput: Int64;

    MunicipioIBGE: string;
    UF: string;
    Regiao: string;
    IdIBGE: Int64;

    Status: TStatus;

    class function Empty: TMunicipioProcessado; static;
  end;

  TMunicipioIBGE = record
    MunicipioIBGE: string;
    UF: string;
    Regiao: string;
    IdIBGE: Int64;
    ChaveBusca: string;

    class function Empty: TMunicipioIBGE; static;
  end;

  TRegiaoStats = record
    TotalPopulacao: Int64;
    TotalMunicipios: Integer;

    function Media: Double;
  end;

function StatusToString(const AStatus: TStatus): string;

function StringToStatus(const S: string): TStatus;

implementation

function StatusToString(const AStatus: TStatus): string;
begin
  case AStatus of
    stOK:
      Result := 'OK';
    stNAO_ENCONTRADO:
      Result := 'NAO_ENCONTRADO';
    stERRO_API:
      Result := 'ERRO_API';
    stAMBIGUO:
      Result := 'AMBIGUO';
  else
    Result := 'DESCONHECIDO';
  end;
end;

function StringToStatus(const S: string): TStatus;
var
  U: string;
begin
  U := UpperCase(S);

  if U = 'OK' then
    Exit(stOK);
  if U = 'NAO_ENCONTRADO' then
    Exit(stNAO_ENCONTRADO);
  if U = 'ERRO_API' then
    Exit(stERRO_API);
  if U = 'AMBIGUO' then
    Exit(stAMBIGUO);

  Result := stERRO_API;
end;

class function TMunicipioProcessado.Empty: TMunicipioProcessado;
begin
  Result.MunicipioInput := '';
  Result.PopulacaoInput := 0;
  Result.MunicipioIBGE := '';
  Result.UF := '';
  Result.Regiao := '';
  Result.IdIBGE := 0;
  Result.Status := stNAO_ENCONTRADO;
end;

class function TMunicipioIBGE.Empty: TMunicipioIBGE;
begin
  Result.MunicipioIBGE := '';
  Result.UF := '';
  Result.Regiao := '';
  Result.IdIBGE := 0;
  Result.ChaveBusca := '';
end;

function TRegiaoStats.Media: Double;
begin
  if TotalMunicipios = 0 then
    Result := 0
  else
    Result := TotalPopulacao / TotalMunicipios;
end;

end.

