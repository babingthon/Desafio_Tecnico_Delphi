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

implementation

end.

