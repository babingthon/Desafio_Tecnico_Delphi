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
  System.IOUtils;

type
  TFrmPrincipal = class(TForm)
    PageControl: TPageControl;
    TabAutenticacao: TTabSheet;
    TabIBGE: TTabSheet;
    EdtEmail: TEdit;
    EdtPassword: TEdit;
    BtnLogin: TButton;
    MemLog: TMemo;
    NetHttpClientAuth: TNetHTTPClient;
    EdtNome: TEdit;
    procedure BtnLoginClick(Sender: TObject);
  private
    FAuthToken: string;
    FAuthService: TAuthenticationService;
    procedure LoadTokenIfExists;
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

{$R *.dfm}

{ TFrmPrincipal }

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

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FAuthService);
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

  MemLog.Lines.Text := LToken;
  BtnLogin.Enabled := False;
end;

end.

