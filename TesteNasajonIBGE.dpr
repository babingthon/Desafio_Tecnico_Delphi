program TesteNasajonIBGE;



uses
  Vcl.Forms,
  UMainForm in 'View\UMainForm.pas' {FrmPrincipal},
  UAuthentication in 'Controller\UAuthentication.pas',
  UIBGEApi in 'Controller\UIBGEApi.pas',
  UProcessController in 'Controller\UProcessController.pas',
  UModelTypes in 'Model\UModelTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
