program DieVix;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Delphi 12.2 Athens VCL Desktop Application
==============================================================================}

uses
  Vcl.Forms,
  DieVix.CalculationEngine in 'src\Engine\DieVix.CalculationEngine.pas',
  DieVix.Domain in 'src\Domain\DieVix.Domain.pas',
  DieVix.ConnectionManager in 'src\Database\DieVix.ConnectionManager.pas',
  DieVix.Repositories in 'src\Repositories\DieVix.Repositories.pas',
  DieVix.MasterDataService in 'src\Services\DieVix.MasterDataService.pas',
  frmMain in 'src\Forms\frmMain.pas' {frmMain},
  frmCylinderMaster in 'src\Forms\frmCylinderMaster.pas' {frmCylinderMaster},
  frmMachineMaster in 'src\Forms\frmMachineMaster.pas' {frmMachineMaster},
  frmMachineCylinderMatrix in 'src\Forms\frmMachineCylinderMatrix.pas' {frmMachineCylinderMatrix},
  frmCustomerMaster in 'src\Forms\frmCustomerMaster.pas' {frmCustomerMaster},
  frmMediaMaster in 'src\Forms\frmMediaMaster.pas' {frmMediaMaster},
  frmDieStatusMaster in 'src\Forms\frmDieStatusMaster.pas' {frmDieStatusMaster},
  frmSettings in 'src\Forms\frmSettings.pas' {frmSettings};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'DieVix — Rotary Die & Keyline Manager';
  Application.CreateForm(TfrmMain, FormMain);
  Application.Run;
end.
