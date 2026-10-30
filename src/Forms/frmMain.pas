unit frmMain;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Main Application Desktop Shell
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.ConnectionManager, DieVix.MasterDataService,
  frmCylinderMaster, frmMachineMaster, frmMachineCylinderMatrix,
  frmCustomerMaster, frmMediaMaster, frmDieStatusMaster, frmSettings,
  DieVix.DieService, frmDieRegister, frmKeylineCalculator, frmBackup,
  DieVix.FlatbedDieService, frmFlatbedDieRegister;

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    lblAppTitle: TLabel;
    lblTagline: TLabel;
    pnlSidebar: TPanel;
    btnDieRegister: TButton;
    btnFlatbedRegister: TButton;
    btnKeylineCalc: TButton;
    btnCylinders: TButton;
    btnMachines: TButton;
    btnMatrix: TButton;
    btnCustomers: TButton;
    btnMedia: TButton;
    btnStatuses: TButton;
    btnSettings: TButton;
    btnBackup: TButton;
    pnlContent: TPanel;
    pnlDashboardCards: TPanel;
    cardDies: TPanel;
    lblCountDies: TLabel;
    lblTitleDies: TLabel;
    cardCylinders: TPanel;
    lblCountCylinders: TLabel;
    lblTitleCylinders: TLabel;
    cardMachines: TPanel;
    lblCountMachines: TLabel;
    lblTitleMachines: TLabel;
    cardCustomers: TPanel;
    lblCountCustomers: TLabel;
    lblTitleCustomers: TLabel;
    cardMedia: TPanel;
    lblCountMedia: TLabel;
    lblTitleMedia: TLabel;
    pnlQuickActions: TPanel;
    lblQuickActions: TLabel;
    btnQuickDieRegister: TButton;
    btnQuickMatrix: TButton;
    btnQuickCylinder: TButton;
    btnQuickCustomer: TButton;
    btnQuickSettings: TButton;
    btnQuickKeylineCalc: TButton;
    btnQuickBackup: TButton;
    btnQuickFlatbed: TButton;
    statBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnDieRegisterClick(Sender: TObject);
    procedure btnFlatbedRegisterClick(Sender: TObject);
    procedure btnKeylineCalcClick(Sender: TObject);
    procedure btnCylindersClick(Sender: TObject);
    procedure btnMachinesClick(Sender: TObject);
    procedure btnMatrixClick(Sender: TObject);
    procedure btnCustomersClick(Sender: TObject);
    procedure btnMediaClick(Sender: TObject);
    procedure btnStatusesClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnBackupClick(Sender: TObject);
  private
    FService: TMasterDataService;
    FDieService: TDieService;
    FFlatbedService: TFlatbedDieService;
    procedure RefreshDashboard;
    procedure UpdateStatusBar;
  public
  end;

var
  FormMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var
  MigDir: string;
  AppCount: Integer;
  LogStr: string;
begin
  if not TDieVixConnectionManager.IsWaitCursorRegistered then
    raise Exception.Create('FireDAC UI wait cursor factory is not registered.');

  // Auto-apply migrations if migrations directory is discovered
  MigDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'migrations');
  if not DirectoryExists(MigDir) then
    MigDir := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\migrations');
  if not DirectoryExists(MigDir) and DirectoryExists('migrations') then
    MigDir := TPath.GetFullPath('migrations');

  if DirectoryExists(MigDir) then
    TDieVixConnectionManager.Instance.ApplyMigrations(MigDir, AppCount, LogStr);

  FService := TMasterDataService.Create;
  FDieService := TDieService.Create;
  FFlatbedService := TFlatbedDieService.Create;
  UpdateStatusBar;
  RefreshDashboard;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FFlatbedService.Free;
  FDieService.Free;
  FService.Free;
end;

procedure TfrmMain.UpdateStatusBar;
var
  Cfg: TDatabaseConfig;
  ModeStr: string;
begin
  Cfg := TDieVixConnectionManager.Instance.Config;
  if Cfg.Mode = cmServer then
    ModeStr := Format('Server: %s:%d [%s]', [Cfg.Server, Cfg.Port, ExtractFileName(Cfg.Database)])
  else
    ModeStr := Format('Embedded: [%s]', [ExtractFileName(Cfg.Database)]);

  statBar.Panels[0].Text := 'Connected: Firebird 5.0';
  statBar.Panels[1].Text := ModeStr;
  statBar.Panels[2].Text := 'Pitch: 3,175 um (1/8")';
  statBar.Panels[3].Text := 'Ready';
end;

procedure TfrmMain.RefreshDashboard;
var
  Dies: TList<TDie>;
  Cyls: TList<TCylinder>;
  Machs: TList<TMachine>;
  Custs: TList<TCustomer>;
  Media: TList<TMedia>;
begin
  try
    Dies := FDieService.GetAllDies;
    try
      lblCountDies.Caption := IntToStr(Dies.Count);
    finally
      Dies.Free;
    end;

    Cyls := FService.GetAllCylinders(True);
    try
      lblCountCylinders.Caption := IntToStr(Cyls.Count);
    finally
      Cyls.Free;
    end;

    Machs := FService.GetAllMachines(True);
    try
      lblCountMachines.Caption := IntToStr(Machs.Count);
    finally
      Machs.Free;
    end;

    Custs := FService.GetAllCustomers(True);
    try
      lblCountCustomers.Caption := IntToStr(Custs.Count);
    finally
      Custs.Free;
    end;

    Media := FService.GetAllMedia(True);
    try
      lblCountMedia.Caption := IntToStr(Media.Count);
    finally
      Media.Free;
    end;
  except
    on E: Exception do
    begin
      statBar.Panels[3].Text := 'Dashboard refresh error: ' + E.Message;
    end;
  end;
end;

procedure TfrmMain.btnDieRegisterClick(Sender: TObject);
var
  Form: TfrmDieRegister;
begin
  Form := TfrmDieRegister.Create(Self);
  try
    Form.DieService := FDieService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
  RefreshDashboard;
end;

procedure TfrmMain.btnFlatbedRegisterClick(Sender: TObject);
var
  Form: TfrmFlatbedDieRegister;
begin
  Form := TfrmFlatbedDieRegister.Create(Self);
  try
    Form.FlatbedService := FFlatbedService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
  RefreshDashboard;
end;

procedure TfrmMain.btnKeylineCalcClick(Sender: TObject);
var
  Form: TfrmKeylineCalculator;
begin
  Form := TfrmKeylineCalculator.CreateWithServices(Self, nil, FDieService);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
  RefreshDashboard;
end;

procedure TfrmMain.btnCylindersClick(Sender: TObject);
var
  Form: TfrmCylinderMaster;
begin
  Form := TfrmCylinderMaster.Create(Self);
  try
    Form.Service := FService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
  RefreshDashboard;
end;

procedure TfrmMain.btnMachinesClick(Sender: TObject);
var
  Form: TfrmMachineMaster;
begin
  Form := TfrmMachineMaster.Create(Self);
  try
    Form.Service := FService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
  RefreshDashboard;
end;

procedure TfrmMain.btnMatrixClick(Sender: TObject);
var
  Form: TfrmMachineCylinderMatrix;
begin
  Form := TfrmMachineCylinderMatrix.Create(Self);
  try
    Form.Service := FService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TfrmMain.btnCustomersClick(Sender: TObject);
var
  Form: TfrmCustomerMaster;
begin
  Form := TfrmCustomerMaster.Create(Self);
  try
    Form.Service := FService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
  RefreshDashboard;
end;

procedure TfrmMain.btnMediaClick(Sender: TObject);
var
  Form: TfrmMediaMaster;
begin
  Form := TfrmMediaMaster.Create(Self);
  try
    Form.Service := FService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
  RefreshDashboard;
end;

procedure TfrmMain.btnStatusesClick(Sender: TObject);
var
  Form: TfrmDieStatusMaster;
begin
  Form := TfrmDieStatusMaster.Create(Self);
  try
    Form.Service := FService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TfrmMain.btnSettingsClick(Sender: TObject);
var
  Form: TfrmSettings;
begin
  Form := TfrmSettings.Create(Self);
  try
    Form.Service := FService;
    Form.ShowModal;
  finally
    Form.Free;
  end;
  UpdateStatusBar;
end;

procedure TfrmMain.btnBackupClick(Sender: TObject);
var
  Form: TfrmBackup;
begin
  Form := TfrmBackup.Create(Self);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
  RefreshDashboard;
end;

end.
