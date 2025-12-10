unit UMainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  UAuthentication,
  System.Net.URLClient,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  System.IOUtils,
  Data.DB,
  Vcl.Grids,
  Vcl.DBGrids,
  Datasnap.DBClient,
  System.Types,
  UIBGEApi,
  UModelTypes,
  Vcl.ExtCtrls,
  UProcessController,
  System.JSON;

type
  TFrmPrincipal = class(TForm)
    PageControl: TPageControl;
    TabAutenticacao: TTabSheet;
    TabIBGE: TTabSheet;
    EdtEmail: TEdit;
    EdtPassword: TEdit;
    BtnLogin: TButton;
    NetHttpClientAuth: TNetHTTPClient;
    EdtNome: TEdit;
    EdtInputFile: TEdit;
    BtnBrowse: TButton;
    OpenDialog: TOpenDialog;
    BtnCarregarCSV: TButton;
    DBGrdMunicipios: TDBGrid;
    MemLog: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    CDSInputData: TClientDataSet;
    DSInputData: TDataSource;
    BtnConsultarIBGE: TButton;
    Panel1: TPanel;
    RgFiltroStatus: TRadioGroup;
    BtnProcessar: TButton;
    procedure BtnLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnBrowseClick(Sender: TObject);
    procedure BtnCarregarCSVClick(Sender: TObject);
    procedure BtnConsultarIBGEClick(Sender: TObject);
    procedure RgFiltroStatusClick(Sender: TObject);
    procedure BtnProcessarClick(Sender: TObject);
  private
    FAuthToken: string;
    FAuthService: TAuthenticationService;
    procedure LoadTokenIfExists;
    procedure CreateDataSetStructure;
    procedure LoadCSVToDataSet;
  protected
    procedure Loaded; override;
    procedure FormDestroy(Sender: TObject);
  public
    { Public declarations }
    property AuthToken: string read FAuthToken;
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

const
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

{$R *.dfm}

{ TFrmPrincipal }

procedure TFrmPrincipal.BtnBrowseClick(Sender: TObject);
begin
  OpenDialog.Filter := 'CSV Files (*.csv)|*.csv';
  OpenDialog.FileName := 'input.csv';

  if OpenDialog.Execute then
  begin
    EdtInputFile.Text := OpenDialog.FileName;
  end;
end;

procedure TFrmPrincipal.BtnCarregarCSVClick(Sender: TObject);
begin
  MemLog.Clear;
  BtnCarregarCSV.Enabled := False;

  try
    LoadCSVToDataSet;

    MemLog.Lines.Add(Format('✅ %d linhas carregadas no DataSet.', [CDSInputData.RecordCount]));
    MemLog.Lines.Add('✔ Pronto para consulta à API do IBGE.');

    BtnConsultarIBGE.Enabled := True;
  except
    on E: Exception do
    begin
      MemLog.Lines.Add('❌ ERRO ao carregar CSV:');
      MemLog.Lines.Add(E.Message);
    end;
  end;

  BtnCarregarCSV.Enabled := True;
end;

procedure TFrmPrincipal.BtnConsultarIBGEClick(Sender: TObject);
var
  LIBGEService: TIBGEService;
  LDataIBGE: TMunicipioIBGE;
  LInputName: string;
  LTotalFound: Integer;
begin
  MemLog.Clear;
  BtnConsultarIBGE.Enabled := False;
  LTotalFound := 0;

  LIBGEService := nil;
  try
    try
      MemLog.Lines.Add('Conectando à API do IBGE...');

      LIBGEService := TIBGEService.Create(NetHttpClientAuth);
      MemLog.Lines.Add('✅ Lista completa de municípios carregada.');

      CDSInputData.DisableControls;

      if CDSInputData.Active and (CDSInputData.RecordCount > 0) then
      begin
        CDSInputData.First;

        while not CDSInputData.EOF do
        begin
          LInputName := CDSInputData.FieldByName('MUNICIPIO_INPUT').AsString.Trim;

          LDataIBGE := LIBGEService.FindMunicipio(LInputName);

          CDSInputData.Edit;

          if LDataIBGE.MunicipioIBGE <> '' then
          begin
            CDSInputData.FieldByName('MUNICIPIO_IBGE').AsString := LDataIBGE.MunicipioIBGE;
            CDSInputData.FieldByName('UF').AsString := LDataIBGE.UF;
            CDSInputData.FieldByName('REGIAO').AsString := LDataIBGE.Regiao;
            CDSInputData.FieldByName('ID_IBGE').AsLargeInt := LDataIBGE.IdIBGE;
            CDSInputData.FieldByName('STATUS').AsString := StatusToString(stOK);

            Inc(LTotalFound);
          end
          else
          begin
            CDSInputData.FieldByName('STATUS').AsString := StatusToString(stNAO_ENCONTRADO);
          end;

          CDSInputData.Post;
          CDSInputData.Next;
        end;

        CDSInputData.First;
      end;

      MemLog.Lines.Add('');
      MemLog.Lines.Add('===== RESULTADO DA CONSULTA =====');
      MemLog.Lines.Add(Format('✔ Municípios encontrados: %d', [LTotalFound]));
      MemLog.Lines.Add(Format('✖ Não encontrados: %d', [CDSInputData.RecordCount - LTotalFound]));
      MemLog.Lines.Add('');
      MemLog.Lines.Add('Pronto para a etapa final: Processamento e Envio.');
      BtnProcessar.Enabled := True;
    except
      on E: Exception do
      begin
        MemLog.Lines.Add('❌ ERRO na Consulta IBGE: ' + E.Message);
      end;
    end;
  finally
    CDSInputData.EnableControls;
    FreeAndNil(LIBGEService);
    BtnConsultarIBGE.Enabled := True;
  end;
end;

procedure TFrmPrincipal.BtnLoginClick(Sender: TObject);
begin
  FAuthToken := '';
  MemLog.Clear;
  BtnLogin.Enabled := False;

  try
    MemLog.Lines.Add('Tentando fazer login...');

    FAuthToken := FAuthService.Login(EdtEmail.Text, EdtPassword.Text);

    if FAuthToken <> '' then
    begin
      MemLog.Lines.Add('✅ Autenticação bem-sucedida!');
      MemLog.Lines.Add('Token obtido.');
      MemLog.Lines.Add(FAuthToken);
      PageControl.ActivePage := TabIBGE;
    end
    else
    begin
      MemLog.Lines.Add('❌ Falha na autenticação (Token vazio).');
    end;
  except
    on E: Exception do
    begin
      MemLog.Lines.Add('❌ Erro de Login: ' + E.Message);
    end;
  end;

  BtnLogin.Enabled := True;
end;

procedure TFrmPrincipal.BtnProcessarClick(Sender: TObject);
var
  LController: TProcessController;
  LStatsJSON: TJSONObject;
begin
  MemLog.Clear;
  BtnProcessar.Enabled := False;

  if FAuthToken = '' then
  begin
    MemLog.Lines.Add('❌ Erro: Por favor, faça a autenticação.');
    BtnProcessar.Enabled := True;
    Exit;
  end;

  if (not CDSInputData.Active) or (CDSInputData.RecordCount = 0) then
  begin
    MemLog.Lines.Add('❌ Erro: Não há dados carregados para processar.');
    BtnProcessar.Enabled := True;
    Exit;
  end;

  LController := nil;
  LStatsJSON := nil;

  try
    LController := TProcessController.Create(NetHttpClientAuth, FAuthToken);
    try

      MemLog.Lines.Add('1. Gerando resultado.csv...');
      LController.GenerateCSVFile(CDSInputData);
      MemLog.Lines.Add('✅ Arquivo resultado.csv gerado com sucesso.');

      MemLog.Lines.Add('2. Calculando estatísticas e montando JSON...');
      LStatsJSON := TJSONObject.Create;
      LController.CalculateStatistics(CDSInputData, LStatsJSON);
      MemLog.Lines.Add('✅ Estatísticas calculadas.');

      MemLog.Lines.Add('3. Enviando resultados para a API de correção...');
      LController.SendStats(LStatsJSON);

      MemLog.Lines.Add('Processo concluído com sucesso.');
    except
      on E: Exception do
      begin
        MemLog.Lines.Add('❌ ERRO CRÍTICO: ' + E.Message);
      end;
    end;
  finally
    FreeAndNil(LController);
    FreeAndNil(LStatsJSON);
    BtnProcessar.Enabled := True;
  end;
end;

procedure TFrmPrincipal.CreateDataSetStructure;
begin
  if CDSInputData.Active then
    CDSInputData.Fields.Clear;

  CDSInputData.Close;
  CDSInputData.FieldDefs.Clear;

  CDSInputData.FieldDefs.Add('MUNICIPIO_INPUT', ftString, 100);
  CDSInputData.FieldDefs.Add('POPULACAO_INPUT', ftLargeint);

  CDSInputData.FieldDefs.Add('MUNICIPIO_IBGE', ftString, 100);
  CDSInputData.FieldDefs.Add('UF', ftString, 2);
  CDSInputData.FieldDefs.Add('REGIAO', ftString, 30);
  CDSInputData.FieldDefs.Add('ID_IBGE', ftLargeint);

  CDSInputData.FieldDefs.Add('STATUS', ftString, 20);

  CDSInputData.FieldDefs.Items[0].CreateField(CDSInputData); // MUNICIPIO_INPUT
  CDSInputData.FieldDefs.Items[1].CreateField(CDSInputData); // POPULACAO_INPUT
  CDSInputData.FieldDefs.Items[2].CreateField(CDSInputData); // MUNICIPIO_IBGE
  CDSInputData.FieldDefs.Items[3].CreateField(CDSInputData); // UF
  CDSInputData.FieldDefs.Items[4].CreateField(CDSInputData); // REGIAO
  CDSInputData.FieldDefs.Items[5].CreateField(CDSInputData); // ID_IBGE
  CDSInputData.FieldDefs.Items[6].CreateField(CDSInputData); // STATUS

  CDSInputData.CreateDataSet;
  CDSInputData.FieldDefs.Update;

  (CDSInputData.FieldByName('MUNICIPIO_INPUT') as TStringField).DisplayLabel := 'Município (CSV)';
  (CDSInputData.FieldByName('MUNICIPIO_INPUT') as TStringField).DisplayWidth := 25;

  CDSInputData.FieldByName('POPULACAO_INPUT').DisplayLabel := 'População';
  CDSInputData.FieldByName('POPULACAO_INPUT').DisplayWidth := 10;

  (CDSInputData.FieldByName('MUNICIPIO_IBGE') as TStringField).DisplayLabel := 'Município IBGE';
  (CDSInputData.FieldByName('MUNICIPIO_IBGE') as TStringField).DisplayWidth := 25;

  (CDSInputData.FieldByName('UF') as TStringField).DisplayLabel := 'UF';
  CDSInputData.FieldByName('UF').DisplayWidth := 5;

  (CDSInputData.FieldByName('REGIAO') as TStringField).DisplayLabel := 'Região';
  CDSInputData.FieldByName('REGIAO').DisplayWidth := 10;

  CDSInputData.FieldByName('ID_IBGE').DisplayLabel := 'Cód. IBGE';
  CDSInputData.FieldByName('ID_IBGE').DisplayWidth := 12;

  CDSInputData.FieldByName('STATUS').DisplayLabel := 'Status';
  CDSInputData.FieldByName('STATUS').DisplayWidth := 12;

  DBGrdMunicipios.Columns.RebuildColumns;
end;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
  EdtInputFile.Text := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'input.csv');
end;

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FAuthService);
end;

procedure TFrmPrincipal.LoadCSVToDataSet;
var
  LInputPath: string;
  LFileLines: TStringDynArray;
  LStringList: TStringList;
  LParts: TStringDynArray;
  I: Integer;
  LPop: Int64;
begin
  MemLog.Lines.Add('Carregando arquivo CSV...');

  LInputPath := Trim(EdtInputFile.Text);
  if LInputPath = '' then
  begin
    MemLog.Lines.Add('❌ Caminho do arquivo não informado.');
    Exit;
  end;

  if not TPath.IsPathRooted(LInputPath) then
    LInputPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), LInputPath);

  if not TFile.Exists(LInputPath) then
  begin
    LStringList := TStringList.Create;
    try
      for I := Low(INPUT_CSV_CONTENT) to High(INPUT_CSV_CONTENT) do
        LStringList.Add(INPUT_CSV_CONTENT[I]);

      LStringList.SaveToFile(LInputPath, TEncoding.UTF8);
      MemLog.Lines.Add('⚠ Arquivo input.csv não encontrado. Criado automaticamente.');
    finally
      LStringList.Free;
    end;
  end;

  LFileLines := TFile.ReadAllLines(LInputPath, TEncoding.UTF8);

  CreateDataSetStructure;

  CDSInputData.DisableControls;
  try
    for I := 1 to High(LFileLines) do
    begin
      LParts := LFileLines[I].Split([',']);

      if Length(LParts) < 2 then
        Continue;

      CDSInputData.Insert;

      CDSInputData.FieldByName('MUNICIPIO_INPUT').AsString := Trim(LParts[0]);

      if TryStrToInt64(Trim(LParts[1]), LPop) then
        CDSInputData.FieldByName('POPULACAO_INPUT').AsLargeInt := LPop
      else
        CDSInputData.FieldByName('POPULACAO_INPUT').AsLargeInt := 0;

      CDSInputData.FieldByName('STATUS').AsString := 'NAO_ENCONTRADO';

      CDSInputData.Post;
    end;
  finally
    CDSInputData.EnableControls;
  end;

  CDSInputData.First;

  MemLog.Lines.Add('✅ CSV carregado com sucesso.');
  MemLog.Lines.Add(Format('Total de linhas carregadas: %d', [CDSInputData.RecordCount]));
end;

procedure TFrmPrincipal.Loaded;
begin
  inherited;
  FAuthService := TAuthenticationService.Create(NetHttpClientAuth);
  LoadTokenIfExists;
end;

procedure TFrmPrincipal.LoadTokenIfExists;
var
  LFilePath: string;
  LToken: string;
begin
  LFilePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'access_token.txt');

  if not FileExists(LFilePath) then
    Exit;

  LToken := TFile.ReadAllText(LFilePath, TEncoding.UTF8).Trim;

  if LToken = '' then
    Exit;

  FAuthToken := LToken;
  MemLog.Lines.Add(LToken);
  MemLog.Lines.Add('');
  MemLog.Lines.Add('');
  BtnLogin.Enabled := False;
end;

procedure TFrmPrincipal.RgFiltroStatusClick(Sender: TObject);
var
  LFilterValue: string;
begin
  if not CDSInputData.Active then
    Exit;

  // Desativa os controles para garantir que o filtro seja aplicado rapidamente
  CDSInputData.DisableControls;
  try
    case RgFiltroStatus.ItemIndex of
      // 0: "Todos"
      0:
        begin
          CDSInputData.Filtered := False; // Desativa qualquer filtro ativo
        end;

      // 1: "OK"
        1:
        begin
          LFilterValue := StatusToString(stOK);
        // Aplica o filtro na coluna STATUS
          CDSInputData.Filter := 'STATUS = ' + QuotedStr(LFilterValue);
          CDSInputData.Filtered := True;
        end;

      // 2: "Não Encontrados"
        2:
        begin
          LFilterValue := StatusToString(stNAO_ENCONTRADO);
        // Aplica o filtro na coluna STATUS
          CDSInputData.Filter := 'STATUS = ' + QuotedStr(LFilterValue);
          CDSInputData.Filtered := True;
        end;

      // Adicionar filtros para ERRO_API e AMBIGUO, se necessário (itens 3 e 4)
    end;
  finally
    CDSInputData.EnableControls; // Reativa a visualização no DBGrid
  end;
end;

end.

