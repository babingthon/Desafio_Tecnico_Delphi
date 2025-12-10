program TesteNasajonIBGE;

uses
  Vcl.Forms,
  UMainForm in '..\View\UMainForm.pas' {FrmPrincipal},
  UAuthentication in 'UAuthentication.pas',
  UModelTypes in '..\Model\UModelTypes.pas',
  UIBGEApi in 'UIBGEApi.pas',
  UProcessController in 'UProcessController.pas',
  UDataModule in '..\UDataModule.pas' {DM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
