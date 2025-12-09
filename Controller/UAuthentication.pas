unit UAuthentication;

interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.IOUtils,
  System.Net.HttpClientComponent;

type
  TAuthenticationService = class
  private
    FHttpClient: TNetHTTPClient;
    procedure SaveTokenToFile(const AToken: string);
  public
    constructor Create(AHttpClient: TNetHTTPClient);
    destructor Destroy; override;
    function Login(const AEmail, ASenha: string): string;
  end;

implementation

const
  SUPABASE_URL = 'https://mynxlubykylncinttggu.supabase.co';
  SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im15bnhsdWJ5a3lsbmNpbnR0Z2d1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxODg2NzAsImV4cCI6MjA4MDc2NDY3MH0.Z-zqiD6_tjnF2WLU167z7jT5NzZaG72dWH0dpQW1N-Y';
  LOGIN_ENDPOINT = '/auth/v1/token?grant_type=password';

{ TAuthenticationService }

constructor TAuthenticationService.Create(AHttpClient: TNetHTTPClient);
begin
  inherited Create;
  FHttpClient := AHttpClient;
end;

destructor TAuthenticationService.Destroy;
begin
  inherited Destroy;
end;

procedure TAuthenticationService.SaveTokenToFile(const AToken: string);
var
  LFilePath: string;
begin
  LFilePath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'access_token.txt');
  TFile.WriteAllText(LFilePath, AToken, TEncoding.UTF8);
end;

function TAuthenticationService.Login(const AEmail, ASenha: string): string;
var
  LResponse: IHTTPResponse;
  LJSONPayload: TJSONObject;
  LJSONResponse: TJSONObject;
  LStream: TStringStream;
  LToken: string;
begin
  Result := '';

  // Necessário para autenticação
  FHttpClient.CustomHeaders['apikey'] := SUPABASE_ANON_KEY;

  LJSONPayload := TJSONObject.Create;
  try
    LJSONPayload.AddPair('email', AEmail);
    LJSONPayload.AddPair('password', ASenha);

    LStream := TStringStream.Create(LJSONPayload.ToString, TEncoding.UTF8);
    try
      // Importante: enviar o Content-Type no Post
      LResponse := FHttpClient.Post(
        SUPABASE_URL + LOGIN_ENDPOINT,
        LStream,
        nil,
        [TNameValuePair.Create('Content-Type', 'application/json')]
      );

      if LResponse.StatusCode <> 200 then
        raise Exception.Create('Erro HTTP ' + LResponse.StatusCode.ToString + ' Detalhe: ' + LResponse.ContentAsString);

      LJSONResponse := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONObject;

      if not Assigned(LJSONResponse) then
        raise Exception.Create('Resposta JSON inválida do servidor.');

      try
        if not LJSONResponse.TryGetValue<string>('access_token', LToken) then
          raise Exception.Create('A resposta não contém "access_token".');

        SaveTokenToFile(LToken);
        Result := LToken;
      finally
        LJSONResponse.Free;
      end;
    finally
      LStream.Free;
    end;
  finally
    LJSONPayload.Free;
  end;
end;

end.

