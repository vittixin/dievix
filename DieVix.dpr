program DieVix;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Delphi 12.2 Athens VCL Desktop Application
==============================================================================}

uses
  Vcl.Forms,
  FireDAC.VCLUI.Wait,
  DieVix.CalculationEngine in 'src\Engine\DieVix.CalculationEngine.pas',
  DieVix.Domain in 'src\Domain\DieVix.Domain.pas',
  DieVix.ConnectionManager in 'src\Database\DieVix.ConnectionManager.pas',
  DieVix.Repositories in 'src\Repositories\DieVix.Repositories.pas',
  DieVix.MasterDataService in 'src\Services\DieVix.MasterDataService.pas',
  DieVix.DieService in 'src\Services\DieVix.DieService.pas',
  DieVix.KeylineService in 'src\Services\DieVix.KeylineService.pas',
  DieVix.ReportService in 'src\Services\DieVix.ReportService.pas',
  DieVix.BackupService in 'src\Services\DieVix.BackupService.pas',
  DieVix.FlatbedDieService in 'src\Services\DieVix.FlatbedDieService.pas',
  frmMain in 'src\Forms\frmMain.pas' {frmMain},
  frmCylinderMaster in 'src\Forms\frmCylinderMaster.pas' {frmCylinderMaster},
  frmMachineMaster in 'src\Forms\frmMachineMaster.pas' {frmMachineMaster},
  frmMachineCylinderMatrix in 'src\Forms\frmMachineCylinderMatrix.pas' {frmMachineCylinderMatrix},
  frmCustomerMaster in 'src\Forms\frmCustomerMaster.pas' {frmCustomerMaster},
  frmMediaMaster in 'src\Forms\frmMediaMaster.pas' {frmMediaMaster},
  frmDieStatusMaster in 'src\Forms\frmDieStatusMaster.pas' {frmDieStatusMaster},
  frmSettings in 'src\Forms\frmSettings.pas' {frmSettings},
  frmBackup in 'src\Forms\frmBackup.pas' {frmBackup},
  frmDieEditor in 'src\Forms\frmDieEditor.pas' {frmDieEditor},
  frmDieRegister in 'src\Forms\frmDieRegister.pas' {frmDieRegister},
  frmKeylineCalculator in 'src\Forms\frmKeylineCalculator.pas' {frmKeylineCalculator},
  frmFlatbedDieEditor in 'src\Forms\frmFlatbedDieEditor.pas' {frmFlatbedDieEditor},
  frmFlatbedDieRegister in 'src\Forms\frmFlatbedDieRegister.pas' {frmFlatbedDieRegister};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'DieVix - Rotary Die & Keyline Manager';
  Application.CreateForm(TfrmMain, FormMain);
  Application.Run;
end.
