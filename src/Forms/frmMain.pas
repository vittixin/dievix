unit frmMain;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Main Application Desktop Shell
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.ConnectionManager, DieVix.MasterDataService,
  frmCylinderMaster, frmMachineMaster, frmMachineCylinderMatrix,
  frmCustomerMaster, frmMediaMaster, frmDieStatusMaster, frmSettings;

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    lblAppTitle: TLabel;
    lblTagline: TLabel;
    pnlSidebar: TPanel;
    btnCylinders: TButton;
    btnMachines: TButton;
    btnMatrix: TButton;
    btnCustomers: TButton;
    btnMedia: TButton;
    btnStatuses: TButton;
    btnSettings: TButton;
    pnlContent: TPanel;
    pnlDashboardCards: TPanel;
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
    btnQuickMatrix: TButton;
    btnQuickCylinder: TButton;
    btnQuickCustomer: TButton;
    btnQuickSettings: TButton;
    statBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCylindersClick(Sender: TObject);
    procedure btnMachinesClick(Sender: TObject);
    procedure btnMatrixClick(Sender: TObject);
    procedure btnCustomersClick(Sender: TObject);
    procedure btnMediaClick(Sender: TObject);
    procedure btnStatusesClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
  private
    FService: TMasterDataService;
    procedure RefreshDashboard;
    procedure UpdateStatusBar;
  public
  end;

var
  FormMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FService := TMasterDataService.Create;
  UpdateStatusBar;
  RefreshDashboard;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
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
  Cyls: TList<TCylinder>;
  Machs: TList<TMachine>;
  Custs: TList<TCustomer>;
  Media: TList<TMedia>;
begin
  try
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

end.
