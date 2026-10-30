unit frmBackup;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Database & Report Backup Management Console
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.IOUtils, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls,
  DieVix.ConnectionManager,
  DieVix.BackupService;

type
  TfrmBackup = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pgcBackup: TPageControl;
    tabDatabase: TTabSheet;
    tabReports: TTabSheet;
    tabFullSystem: TTabSheet;
    tabHistory: TTabSheet;
    
    { Database Tab }
    pnlDbInfo: TPanel;
    lblActiveDbTitle: TLabel;
    lblActiveDbPath: TLabel;
    lblActiveMode: TLabel;
    grpDbBackup: TGroupBox;
    lblDbDest: TLabel;
    edtDbDest: TEdit;
    btnBrowseDbDest: TButton;
    chkVerbose: TCheckBox;
    chkIgnoreChecksums: TCheckBox;
    btnBackupDatabase: TButton;
    btnPhysicalHotBackup: TButton;
    grpDbRestore: TGroupBox;
    lblRestoreSrc: TLabel;
    edtRestoreSrc: TEdit;
    btnBrowseRestoreSrc: TButton;
    lblRestoreDest: TLabel;
    edtRestoreDest: TEdit;
    btnBrowseRestoreDest: TButton;
    chkOverwriteDb: TCheckBox;
    btnRestoreDatabase: TButton;

    { Reports Tab }
    pnlRepInfo: TPanel;
    lblReportsPathTitle: TLabel;
    lblReportsPath: TLabel;
    lblReportCount: TLabel;
    lvTemplates: TListView;
    grpRepActions: TGroupBox;
    btnBackupReportsZip: TButton;
    btnBackupReportsFolder: TButton;
    btnRestoreReportsZip: TButton;
    btnRestoreReportsFolder: TButton;
    btnRefreshTemplates: TButton;

    { Full System Tab }
    grpFullBackup: TGroupBox;
    lblFullHelp: TLabel;
    lblOperator: TLabel;
    edtOperator: TEdit;
    lblFullZipDest: TLabel;
    edtFullZipDest: TEdit;
    btnBrowseFullZip: TButton;
    btnRunFullBackup: TButton;
    grpFullRestore: TGroupBox;
    lblFullRestoreSrc: TLabel;
    edtFullRestoreSrc: TEdit;
    btnBrowseFullRestoreSrc: TButton;
    lblFullRestoreDbTarget: TLabel;
    edtFullRestoreDbTarget: TEdit;
    btnBrowseFullRestoreDbTarget: TButton;
    btnRunFullRestore: TButton;

    { History Tab }
    pnlHistTop: TPanel;
    lblHistFolder: TLabel;
    edtHistFolder: TEdit;
    btnBrowseHistFolder: TButton;
    btnRefreshHistory: TButton;
    btnVerifySelected: TButton;
    lvHistory: TListView;

    { Bottom Log & Controls }
    pnlBottom: TPanel;
    lblLog: TLabel;
    memLog: TMemo;
    pnlButtons: TPanel;
    btnClearLog: TButton;
    btnClose: TButton;

    { Dialogs }
    dlgSaveFbk: TSaveDialog;
    dlgOpenFbk: TOpenDialog;
    dlgSaveZip: TSaveDialog;
    dlgOpenZip: TOpenDialog;
    dlgSaveFdb: TSaveDialog;
    dlgOpenFolder: TFileOpenDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseDbDestClick(Sender: TObject);
    procedure btnBackupDatabaseClick(Sender: TObject);
    procedure btnPhysicalHotBackupClick(Sender: TObject);
    procedure btnBrowseRestoreSrcClick(Sender: TObject);
    procedure btnBrowseRestoreDestClick(Sender: TObject);
    procedure btnRestoreDatabaseClick(Sender: TObject);
    procedure btnRefreshTemplatesClick(Sender: TObject);
    procedure btnBackupReportsZipClick(Sender: TObject);
    procedure btnBackupReportsFolderClick(Sender: TObject);
    procedure btnRestoreReportsZipClick(Sender: TObject);
    procedure btnRestoreReportsFolderClick(Sender: TObject);
    procedure btnBrowseFullZipClick(Sender: TObject);
    procedure btnRunFullBackupClick(Sender: TObject);
    procedure btnBrowseFullRestoreSrcClick(Sender: TObject);
    procedure btnBrowseFullRestoreDbTargetClick(Sender: TObject);
    procedure btnRunFullRestoreClick(Sender: TObject);
    procedure btnRefreshHistoryClick(Sender: TObject);
    procedure btnBrowseHistFolderClick(Sender: TObject);
    procedure btnVerifySelectedClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FService: TDieVixBackupService;
    procedure InitForm;
    procedure RefreshDbInfo;
    procedure RefreshTemplatesList;
    procedure RefreshHistoryList;
    procedure AppendLog(const AMsg: string);
  public
    property Service: TDieVixBackupService read FService write FService;
  end;

var
  FormBackup: TfrmBackup;

implementation

{$R *.dfm}

procedure TfrmBackup.FormCreate(Sender: TObject);
begin
  if not Assigned(FService) then
    FService := TDieVixBackupService.Create;

  FService.OnProgress := procedure(const AMsg: string)
  begin
    AppendLog(AMsg);
  end;

  InitForm;
end;

procedure TfrmBackup.FormDestroy(Sender: TObject);
begin
  FService.Free;
end;

procedure TfrmBackup.InitForm;
var
  DefBackupDir: string;
begin
  DefBackupDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'backups');
  if not DirectoryExists(DefBackupDir) then
    ForceDirectories(DefBackupDir);

  edtHistFolder.Text := DefBackupDir;
  edtDbDest.Text := TPath.Combine(DefBackupDir, 'DieVix_DB_' + FormatDateTime('YYYYMMDD_HHNNSS', Now) + '.fbk');
  edtFullZipDest.Text := TPath.Combine(DefBackupDir, 'DieVix_SystemBackup_' + FormatDateTime('YYYYMMDD_HHNNSS', Now) + '.zip');

  var Cfg := TDieVixConnectionManager.Instance.Config;
  edtRestoreDest.Text := TPath.ChangeExtension(Cfg.Database, '_RESTORED.FDB');
  edtFullRestoreDbTarget.Text := TPath.ChangeExtension(Cfg.Database, '_FULL_RESTORED.FDB');

  RefreshDbInfo;
  RefreshTemplatesList;
  RefreshHistoryList;
end;

procedure TfrmBackup.AppendLog(const AMsg: string);
begin
  memLog.Lines.Add(Format('[%s] %s', [FormatDateTime('HH:NN:SS', Now), AMsg]));
  SendMessage(memLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
  Application.ProcessMessages;
end;

procedure TfrmBackup.RefreshDbInfo;
var
  Cfg: TDatabaseConfig;
begin
  Cfg := TDieVixConnectionManager.Instance.Config;
  lblActiveDbPath.Caption := 'Database: ' + Cfg.Database;
  if (Cfg.Mode = cmServer) then
    lblActiveMode.Caption := Format('Connection Mode: SERVER (%s:%d)', [Cfg.Server, Cfg.Port])
  else
    lblActiveMode.Caption := 'Connection Mode: EMBEDDED';
end;

procedure TfrmBackup.RefreshTemplatesList;
var
  Templates: TArray<TReportTemplateInfo>;
  I: Integer;
  Item: TListItem;
  RepDir: string;
begin
  lvTemplates.Items.BeginUpdate;
  try
    lvTemplates.Items.Clear;
    Templates := FService.GetAvailableReportTemplates;
    RepDir := FService.ReportsPath;
    if (RepDir = '') then
      RepDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'reports');
    lblReportsPath.Caption := 'Active Path: ' + RepDir;
    lblReportCount.Caption := Format('Discovered Templates: %d', [Length(Templates)]);

    for I := 0 to High(Templates) do
    begin
      Item := lvTemplates.Items.Add;
      Item.Caption := Templates[I].FileName;
      Item.SubItems.Add(Templates[I].Title);
      Item.SubItems.Add(FormatFloat('#,##0 KB', Templates[I].FileSizeBytes / 1024.0));
      Item.SubItems.Add(FormatDateTime('YYYY-MM-DD HH:NN:SS', Templates[I].ModifiedTime));
      if Templates[I].IsValid then
        Item.SubItems.Add('VALID')
      else
        Item.SubItems.Add('CORRUPT: ' + Templates[I].ValidationNote);
    end;
  finally
    lvTemplates.Items.EndUpdate;
  end;
end;

procedure TfrmBackup.RefreshHistoryList;
var
  Items: TArray<TBackupItemInfo>;
  I: Integer;
  ListItem: TListItem;
  HistDir: string;
begin
  lvHistory.Items.BeginUpdate;
  try
    lvHistory.Items.Clear;
    HistDir := Trim(edtHistFolder.Text);
    Items := FService.EnumerateBackups(HistDir);

    for I := 0 to High(Items) do
    begin
      ListItem := lvHistory.Items.Add;
      ListItem.Caption := Items[I].FileName;
      ListItem.SubItems.Add(Items[I].Description);
      ListItem.SubItems.Add(FormatFloat('#,##0.0 KB', Items[I].FileSizeBytes / 1024.0));
      ListItem.SubItems.Add(FormatDateTime('YYYY-MM-DD HH:NN:SS', Items[I].ModifiedTime));
      ListItem.SubItems.Add(Items[I].FilePath);
    end;
  finally
    lvHistory.Items.EndUpdate;
  end;
end;

procedure TfrmBackup.btnBrowseDbDestClick(Sender: TObject);
begin
  dlgSaveFbk.InitialDir := ExtractFilePath(edtDbDest.Text);
  dlgSaveFbk.FileName := ExtractFileName(edtDbDest.Text);
  if dlgSaveFbk.Execute then
    edtDbDest.Text := dlgSaveFbk.FileName;
end;

procedure TfrmBackup.btnBackupDatabaseClick(Sender: TObject);
var
  Res: TBackupResult;
  Dest: string;
begin
  Dest := Trim(edtDbDest.Text);
  AppendLog('--- Triggering Firebird Logical Database Backup ---');
  Res := FService.BackupDatabase(Dest, chkVerbose.Checked, chkIgnoreChecksums.Checked);
  if Res.Success then
  begin
    ShowMessage(Format('Database backup completed successfully!'#13#10#13#10 +
      'File: %s'#13#10'Size: %d bytes'#13#10'Duration: %d ms',
      [Res.TargetFilePath, Res.FileSizeBytes, Res.DurationMs]));
    RefreshHistoryList;
  end
  else
    MessageDlg('Database backup failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnPhysicalHotBackupClick(Sender: TObject);
var
  Res: TBackupResult;
  Dest: string;
begin
  Dest := TPath.ChangeExtension(Trim(edtDbDest.Text), '.fdb.bak');
  AppendLog('--- Triggering Online Physical Hot Snapshot Backup ---');
  Res := FService.BackupDatabasePhysical(Dest);
  if Res.Success then
  begin
    ShowMessage(Format('Physical hot database snapshot created!'#13#10#13#10 +
      'File: %s'#13#10'Size: %d bytes'#13#10'Duration: %d ms',
      [Res.TargetFilePath, Res.FileSizeBytes, Res.DurationMs]));
    RefreshHistoryList;
  end
  else
    MessageDlg('Physical hot backup failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnBrowseRestoreSrcClick(Sender: TObject);
begin
  if dlgOpenFbk.Execute then
    edtRestoreSrc.Text := dlgOpenFbk.FileName;
end;

procedure TfrmBackup.btnBrowseRestoreDestClick(Sender: TObject);
begin
  if dlgSaveFdb.Execute then
    edtRestoreDest.Text := dlgSaveFdb.FileName;
end;

procedure TfrmBackup.btnRestoreDatabaseClick(Sender: TObject);
var
  Src, Dest: string;
  Res: TRestoreResult;
begin
  Src := Trim(edtRestoreSrc.Text);
  Dest := Trim(edtRestoreDest.Text);

  if (Src = '') or not FileExists(Src) then
  begin
    MessageDlg('Please specify a valid source .fbk backup archive.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if (Dest = '') then
  begin
    MessageDlg('Please specify a destination database (.fdb) file path.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if MessageDlg(Format('Are you sure you want to restore the database?'#13#10#13#10 +
    'Source: %s'#13#10'Target: %s'#13#10#13#10 +
    'WARNING: If the target database already exists, it will be replaced!',
    [Src, Dest]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  AppendLog('--- Triggering Firebird Database Restore ---');
  Res := FService.RestoreDatabase(Src, Dest, 8192, chkOverwriteDb.Checked);
  if Res.Success then
    ShowMessage(Format('Database restored successfully!'#13#10#13#10 +
      'Target: %s'#13#10'Duration: %d ms', [Res.TargetLocation, Res.DurationMs]))
  else
    MessageDlg('Database restore failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnRefreshTemplatesClick(Sender: TObject);
begin
  RefreshTemplatesList;
end;

procedure TfrmBackup.btnBackupReportsZipClick(Sender: TObject);
var
  Res: TBackupResult;
  Dest: string;
begin
  dlgSaveZip.InitialDir := Trim(edtHistFolder.Text);
  dlgSaveZip.FileName := 'DieVix_Reports_' + FormatDateTime('YYYYMMDD_HHNNSS', Now) + '.zip';
  if not dlgSaveZip.Execute then
    Exit;

  Dest := dlgSaveZip.FileName;
  AppendLog('--- Triggering Report Templates Backup to ZIP ---');
  Res := FService.BackupReportsToZip(Dest);
  if Res.Success then
  begin
    ShowMessage(Format('Report templates backed up to ZIP successfully!'#13#10#13#10 +
      'Archive: %s'#13#10'Templates: %d'#13#10'Size: %d bytes',
      [Res.TargetFilePath, Res.ItemCount, Res.FileSizeBytes]));
    RefreshHistoryList;
  end
  else
    MessageDlg('Report backup to ZIP failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnBackupReportsFolderClick(Sender: TObject);
var
  TargetDir: string;
  Res: TBackupResult;
begin
  TargetDir := TPath.Combine(Trim(edtHistFolder.Text),
    'Reports_' + FormatDateTime('YYYYMMDD_HHNNSS', Now));

  AppendLog('--- Triggering Report Templates Backup to Folder ---');
  Res := FService.BackupReportsToFolder(TargetDir);
  if Res.Success then
  begin
    ShowMessage(Format('Report templates copied to destination folder!'#13#10#13#10 +
      'Folder: %s'#13#10'Templates: %d'#13#10'Size: %d bytes',
      [Res.TargetFilePath, Res.ItemCount, Res.FileSizeBytes]));
    RefreshHistoryList;
  end
  else
    MessageDlg('Report folder backup failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnRestoreReportsZipClick(Sender: TObject);
var
  Res: TRestoreResult;
  Src: string;
begin
  if not dlgOpenZip.Execute then
    Exit;

  Src := dlgOpenZip.FileName;
  AppendLog('--- Triggering Report Templates Restore from ZIP ---');
  Res := FService.RestoreReportsFromZip(Src, '', True);
  if Res.Success then
  begin
    ShowMessage(Format('Report templates restored successfully!'#13#10#13#10 +
      'Templates restored: %d'#13#10'Target Directory: %s',
      [Res.RestoredCount, Res.TargetLocation]));
    RefreshTemplatesList;
  end
  else
    MessageDlg('Report restore failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnRestoreReportsFolderClick(Sender: TObject);
var
  Src: string;
  Res: TRestoreResult;
begin
  dlgOpenFolder.Title := 'Select Source Reports Folder to Restore';
  dlgOpenFolder.Options := dlgOpenFolder.Options + [fdoPickFolders];
  if not dlgOpenFolder.Execute then
    Exit;

  Src := dlgOpenFolder.FileName;
  AppendLog('--- Triggering Report Templates Restore from Folder ---');
  Res := FService.RestoreReportsFromFolder(Src, '', True);
  if Res.Success then
  begin
    ShowMessage(Format('Report templates restored from folder successfully!'#13#10#13#10 +
      'Templates restored: %d'#13#10'Target Directory: %s',
      [Res.RestoredCount, Res.TargetLocation]));
    RefreshTemplatesList;
  end
  else
    MessageDlg('Report restore from folder failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnBrowseFullZipClick(Sender: TObject);
begin
  dlgSaveZip.InitialDir := ExtractFilePath(edtFullZipDest.Text);
  dlgSaveZip.FileName := ExtractFileName(edtFullZipDest.Text);
  if dlgSaveZip.Execute then
    edtFullZipDest.Text := dlgSaveZip.FileName;
end;

procedure TfrmBackup.btnRunFullBackupClick(Sender: TObject);
var
  Res: TBackupResult;
  Dest, Op: string;
begin
  Dest := Trim(edtFullZipDest.Text);
  Op := Trim(edtOperator.Text);
  AppendLog('--- Triggering Full System Unified Backup (Database + Reports) ---');
  Res := FService.BackupFullSystem(Dest, Op);
  if Res.Success then
  begin
    ShowMessage(Format('Unified Full System Backup created successfully!'#13#10#13#10 +
      'Package: %s'#13#10'Items Packaged: %d'#13#10'Package Size: %d bytes'#13#10'Duration: %d ms',
      [Res.TargetFilePath, Res.ItemCount, Res.FileSizeBytes, Res.DurationMs]));
    RefreshHistoryList;
  end
  else
    MessageDlg('Full system backup failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnBrowseFullRestoreSrcClick(Sender: TObject);
begin
  if dlgOpenZip.Execute then
    edtFullRestoreSrc.Text := dlgOpenZip.FileName;
end;

procedure TfrmBackup.btnBrowseFullRestoreDbTargetClick(Sender: TObject);
begin
  if dlgSaveFdb.Execute then
    edtFullRestoreDbTarget.Text := dlgSaveFdb.FileName;
end;

procedure TfrmBackup.btnRunFullRestoreClick(Sender: TObject);
var
  Src, TargetDb: string;
  Res: TRestoreResult;
begin
  Src := Trim(edtFullRestoreSrc.Text);
  TargetDb := Trim(edtFullRestoreDbTarget.Text);

  if (Src = '') or not FileExists(Src) then
  begin
    MessageDlg('Please select a valid system backup ZIP package.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if MessageDlg(Format('Are you sure you want to restore the full system package?'#13#10#13#10 +
    'Package: %s'#13#10'Target Database: %s'#13#10#13#10 +
    'Report templates will be restored to the active reports folder.',
    [Src, TargetDb]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  AppendLog('--- Triggering Full System Package Restore ---');
  Res := FService.RestoreFullSystem(Src, TargetDb, '', True);
  if Res.Success then
  begin
    ShowMessage(Format('Full system restore completed!'#13#10#13#10 +
      'Items Restored: %d'#13#10'Duration: %d ms', [Res.RestoredCount, Res.DurationMs]));
    RefreshTemplatesList;
  end
  else
    MessageDlg('Full system restore failed:'#13#10 + Res.ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmBackup.btnRefreshHistoryClick(Sender: TObject);
begin
  RefreshHistoryList;
end;

procedure TfrmBackup.btnBrowseHistFolderClick(Sender: TObject);
begin
  dlgOpenFolder.Title := 'Select Backups Folder';
  dlgOpenFolder.Options := dlgOpenFolder.Options + [fdoPickFolders];
  if dlgOpenFolder.Execute then
  begin
    edtHistFolder.Text := dlgOpenFolder.FileName;
    RefreshHistoryList;
  end;
end;

procedure TfrmBackup.btnVerifySelectedClick(Sender: TObject);
var
  Item: TListItem;
  FilePath, Details: string;
  Ext: string;
  Valid: Boolean;
  Count: Integer;
begin
  Item := lvHistory.Selected;
  if not Assigned(Item) then
  begin
    ShowMessage('Please select a backup item from the list to verify.');
    Exit;
  end;

  FilePath := Item.SubItems[3];
  Ext := LowerCase(ExtractFileExt(FilePath));
  AppendLog('Verifying backup file: ' + FilePath);

  if (Ext = '.fbk') or (Ext = '.bak') then
  begin
    Valid := FService.VerifyDatabaseBackup(FilePath, Details);
    if Valid then
      ShowMessage('Database backup verified successfully!'#13#10#13#10 + Details)
    else
      MessageDlg('Database backup verification failed:'#13#10 + Details, mtWarning, [mbOK], 0);
  end
  else if (Ext = '.zip') then
  begin
    Valid := FService.VerifyReportsArchive(FilePath, Count, Details);
    if Valid then
      ShowMessage('Archive verified successfully!'#13#10#13#10 + Details)
    else
      MessageDlg('Archive verification failed:'#13#10 + Details, mtWarning, [mbOK], 0);
  end
  else
    ShowMessage('Selected file type does not support verification.');
end;

procedure TfrmBackup.btnClearLogClick(Sender: TObject);
begin
  memLog.Lines.Clear;
end;

procedure TfrmBackup.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
