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
  end;

  TMunicipioIBGE = record
    MunicipioIBGE: string;
    UF: string;
    Regiao: string;
    IdIBGE: Int64;
    ChaveBusca: string;
  end;

  TRegiaoStats = record
    TotalPopulacao: Int64;
    TotalMunicipios: Integer;
  end;

function StatusToString(const AStatus: TStatus): string;

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

end.

