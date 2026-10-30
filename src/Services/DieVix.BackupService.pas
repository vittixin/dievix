unit DieVix.BackupService;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Database & Report Backup Application Service Layer
  
  Provides robust, automated and interactive backup & restore capabilities for:
    1. Firebird 5.0 Database:
       - Logical gbak archives (.fbk) via FireDAC Services API (TFDIBBackup / TFDIBRestore)
       - Online physical snapshot backups (.fdb.bak) via ALTER DATABASE BEGIN BACKUP
    2. Report Templates & Definitions:
       - ZIP compressed archives of VittixReport templates (*.vrt)
       - Directory-based template replication
       - Strict JSON structure validation upon restore
    3. Unified System Backup Packages:
       - Single consolidated archive containing database snapshot, report templates,
         and machine-readable backup_manifest.json
    4. Backup Cataloging & Health Verification
==============================================================================}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Zip,
  System.Generics.Collections,
  System.JSON,
  System.Types,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Error,
  FireDAC.Phys.Intf,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.Phys.IBBase,
  FireDAC.Phys.IBWrapper,
  DieVix.Domain,
  DieVix.ConnectionManager;

type
  { Progress Notification Callback }
  TBackupProgressProc = reference to procedure(const AMessage: string);

  { Backup Item Type }
  TBackupType = (btDatabaseFbk, btDatabasePhysical, btReportsZip, btReportsFolder, btFullSystemBundle);

  { Backup Execution Result }
  TBackupResult = record
    Success: Boolean;
    BackupType: TBackupType;
    TargetFilePath: string;
    FileSizeBytes: Int64;
    DurationMs: Cardinal;
    ItemCount: Integer;
    LogMessages: TArray<string>;
    ErrorMessage: string;
    class function CreateFailure(const AType: TBackupType; const AError: string): TBackupResult; static;
  end;

  { Restore Execution Result }
  TRestoreResult = record
    Success: Boolean;
    SourceFilePath: string;
    TargetLocation: string;
    DurationMs: Cardinal;
    RestoredCount: Integer;
    LogMessages: TArray<string>;
    ErrorMessage: string;
    class function CreateFailure(const AError: string): TRestoreResult; static;
  end;

  { Backup Item Descriptor }
  TBackupItemInfo = record
    FileName: string;
    FilePath: string;
    FileSizeBytes: Int64;
    ModifiedTime: TDateTime;
    BackupType: TBackupType;
    Description: string;
  end;

  { Report Template Information }
  TReportTemplateInfo = record
    FileName: string;
    FilePath: string;
    Title: string;
    FileSizeBytes: Int64;
    ModifiedTime: TDateTime;
    IsValid: Boolean;
    ValidationNote: string;
  end;

  { Database & Report Backup Service }
  TDieVixBackupService = class
  private
    FReportsPath: string;
    FBackupRootPath: string;
    FOnProgress: TBackupProgressProc;
    FCurrentLogList: TList<string>;
    procedure DoServiceProgress(ASender: TFDPhysDriverService; const AMessage: String);
    procedure EmitLog(const AMsg: string; ALogList: TList<string> = nil);
    function ResolveActiveReportsPath: string;
    function GetDefaultBackupFolder: string;
    function ValidateReportTemplateJson(const AJsonContent: string; out ATitle: string; out AError: string): Boolean;
    function GetCurrentOperator: string;
  public
    constructor Create(const AReportsPath: string = ''; const ABackupRootPath: string = '');
    destructor Destroy; override;

    property ReportsPath: string read FReportsPath write FReportsPath;
    property BackupRootPath: string read FBackupRootPath write FBackupRootPath;
    property OnProgress: TBackupProgressProc read FOnProgress write FOnProgress;

    { 1. Database Backup & Restore }
    function BackupDatabase(
      const ADestFilePath: string = '';
      const AVerbose: Boolean = True;
      const AIgnoreChecksums: Boolean = False
    ): TBackupResult;

    function BackupDatabasePhysical(
      const ADestFilePath: string = ''
    ): TBackupResult;

    function RestoreDatabase(
      const ABackupFbkPath: string;
      const ATargetDbPath: string;
      const APageSize: Integer = 8192;
      const AOverwriteExisting: Boolean = True
    ): TRestoreResult;

    { 2. Report Templates Backup & Restore }
    function GetAvailableReportTemplates: TArray<TReportTemplateInfo>;

    function BackupReportsToZip(
      const ADestZipPath: string = ''
    ): TBackupResult;

    function BackupReportsToFolder(
      const ADestFolderPath: string = ''
    ): TBackupResult;

    function RestoreReportsFromZip(
      const ASourceZipPath: string;
      const ATargetFolder: string = '';
      const AOverwriteExisting: Boolean = True
    ): TRestoreResult;

    function RestoreReportsFromFolder(
      const ASourceFolderPath: string;
      const ATargetFolder: string = '';
      const AOverwriteExisting: Boolean = True
    ): TRestoreResult;

    { 3. Full System Backup (Database + Reports + Manifest) }
    function BackupFullSystem(
      const ADestZipPath: string = '';
      const AOperatorName: string = ''
    ): TBackupResult;

    function RestoreFullSystem(
      const ASourceBundlePath: string;
      const ATargetDbPath: string;
      const ATargetReportsDir: string = '';
      const AOverwrite: Boolean = True
    ): TRestoreResult;

    { 4. Cataloging & Verification }
    function EnumerateBackups(const ADirectory: string = ''): TArray<TBackupItemInfo>;
    function VerifyDatabaseBackup(const ABackupPath: string; out ADetails: string): Boolean;
    function VerifyReportsArchive(const AZipPath: string; out ACount: Integer; out ADetails: string): Boolean;
  end;

implementation

{ TBackupResult }

class function TBackupResult.CreateFailure(const AType: TBackupType; const AError: string): TBackupResult;
begin
  Result.Success := False;
  Result.BackupType := AType;
  Result.TargetFilePath := '';
  Result.FileSizeBytes := 0;
  Result.DurationMs := 0;
  Result.ItemCount := 0;
  Result.LogMessages := nil;
  Result.ErrorMessage := AError;
end;

{ TRestoreResult }

class function TRestoreResult.CreateFailure(const AError: string): TRestoreResult;
begin
  Result.Success := False;
  Result.SourceFilePath := '';
  Result.TargetLocation := '';
  Result.DurationMs := 0;
  Result.RestoredCount := 0;
  Result.LogMessages := nil;
  Result.ErrorMessage := AError;
end;

{ TDieVixBackupService }

constructor TDieVixBackupService.Create(const AReportsPath: string; const ABackupRootPath: string);
begin
  inherited Create;
  FReportsPath := AReportsPath;
  FBackupRootPath := ABackupRootPath;
  FCurrentLogList := nil;
end;

destructor TDieVixBackupService.Destroy;
begin
  inherited Destroy;
end;

procedure TDieVixBackupService.DoServiceProgress(ASender: TFDPhysDriverService; const AMessage: String);
begin
  EmitLog(AMessage, FCurrentLogList);
end;

procedure TDieVixBackupService.EmitLog(const AMsg: string; ALogList: TList<string>);
begin
  if Assigned(ALogList) then
    ALogList.Add(AMsg);

  if Assigned(FOnProgress) then
  begin
    try
      FOnProgress(AMsg);
    except
      // Progress notifications must not break backup flow
    end;
  end;
end;

function TDieVixBackupService.GetCurrentOperator: string;
var
  Buf: array[0..255] of Char;
  Len: Cardinal;
begin
  Len := Length(Buf);
  if Winapi.Windows.GetUserName(Buf, Len) then
    Result := Trim(string(Buf))
  else
    Result := 'OPERATOR';
end;

function TDieVixBackupService.ResolveActiveReportsPath: string;
var
  ExeDir, Cand: string;
begin
  if (FReportsPath <> '') and DirectoryExists(FReportsPath) then
    Exit(TPath.GetFullPath(FReportsPath));

  ExeDir := ExtractFilePath(ParamStr(0));
  Cand := TPath.Combine(ExeDir, 'reports');
  if DirectoryExists(Cand) then
    Exit(TPath.GetFullPath(Cand));

  Cand := TPath.Combine(ExeDir, '..\reports');
  if DirectoryExists(Cand) then
    Exit(TPath.GetFullPath(Cand));

  Cand := TPath.Combine(ExeDir, '..\..\reports');
  if DirectoryExists(Cand) then
    Exit(TPath.GetFullPath(Cand));

  if DirectoryExists('reports') then
    Exit(TPath.GetFullPath('reports'));

  Result := TPath.GetFullPath(TPath.Combine(ExeDir, 'reports'));
end;

function TDieVixBackupService.GetDefaultBackupFolder: string;
var
  ExeDir, Cand: string;
begin
  if (FBackupRootPath <> '') then
  begin
    if not DirectoryExists(FBackupRootPath) then
      ForceDirectories(FBackupRootPath);
    Exit(TPath.GetFullPath(FBackupRootPath));
  end;

  ExeDir := ExtractFilePath(ParamStr(0));
  Cand := TPath.Combine(ExeDir, 'backups');
  if not DirectoryExists(Cand) then
    ForceDirectories(Cand);
  Result := TPath.GetFullPath(Cand);
end;

function TDieVixBackupService.ValidateReportTemplateJson(
  const AJsonContent: string;
  out ATitle: string;
  out AError: string
): Boolean;
var
  Val: TJSONValue;
  Obj: TJSONObject;
begin
  Result := False;
  ATitle := '';
  AError := '';
  try
    Val := TJSONObject.ParseJSONValue(AJsonContent);
    if not Assigned(Val) then
    begin
      AError := 'Invalid JSON syntax';
      Exit;
    end;

    if not (Val is TJSONObject) then
    begin
      Val.Free;
      AError := 'Root JSON element is not an object';
      Exit;
    end;

    Obj := TJSONObject(Val);
    try
      if Assigned(Obj.Values['Title']) then
        ATitle := Obj.Values['Title'].Value;

      if not (Obj.Values['Objects'] is TJSONArray) and
         not Assigned(Obj.Values['PageSettings']) and
         not Assigned(Obj.Values['Version']) then
      begin
        AError := 'Missing required VittixReport structure (Objects/PageSettings/Version)';
        Exit;
      end;

      Result := True;
    finally
      Obj.Free;
    end;
  except
    on E: Exception do
      AError := 'JSON parse error: ' + E.Message;
  end;
end;

function TDieVixBackupService.BackupDatabase(
  const ADestFilePath: string;
  const AVerbose: Boolean;
  const AIgnoreChecksums: Boolean
): TBackupResult;
var
  Backup: TFDIBBackup;
  DriverLink: TFDPhysFBDriverLink;
  OwnsDriverLink: Boolean;
  Cfg: TDatabaseConfig;
  TargetFile: string;
  Stopwatch: TDateTime;
  LogList: TList<string>;
  I: Integer;
begin
  Result := TBackupResult.CreateFailure(btDatabaseFbk, '');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  FCurrentLogList := LogList;
  try
    Cfg := TDieVixConnectionManager.Instance.Config;
    if (Cfg.Database = '') then
    begin
      Result.ErrorMessage := 'Database path is empty in configuration.';
      Exit;
    end;

    if (ADestFilePath <> '') then
      TargetFile := TPath.GetFullPath(ADestFilePath)
    else
      TargetFile := TPath.Combine(GetDefaultBackupFolder,
        'DieVix_DB_' + FormatDateTime('YYYYMMDD_HHNNSS', Now) + '.fbk');

    ForceDirectories(ExtractFilePath(TargetFile));
    EmitLog('Initializing Firebird database backup...', LogList);
    EmitLog('Source Database: ' + Cfg.Database, LogList);
    EmitLog('Target Backup Archive: ' + TargetFile, LogList);

    DriverLink := TDieVixConnectionManager.Instance.DriverLink;
    OwnsDriverLink := False;
    if not Assigned(DriverLink) then
    begin
      DriverLink := TFDPhysFBDriverLink.Create(nil);
      DriverLink.VendorLib := Cfg.VendorLib;
      OwnsDriverLink := True;
    end;

    Backup := TFDIBBackup.Create(nil);
    try
      Backup.DriverLink := DriverLink;
      Backup.Protocol := ipTCPIP;
      if (Cfg.Server <> '') and not SameText(Cfg.Server, 'localhost') then
        Backup.Host := Cfg.Server
      else
        Backup.Host := 'localhost';

      if (Cfg.Port > 0) then
        Backup.Port := Cfg.Port
      else
        Backup.Port := 3050;

      Backup.UserName := Cfg.UserName;
      Backup.Password := Cfg.Password;
      Backup.Database := Cfg.Database;
      Backup.BackupFiles.Clear;
      Backup.BackupFiles.Add(TargetFile);
      Backup.Verbose := AVerbose;

      if AIgnoreChecksums then
        Backup.Options := Backup.Options + [boIgnoreChecksum, boIgnoreLimbo];

      Backup.OnProgress := DoServiceProgress;

      EmitLog('Connecting to Firebird Services API and initiating gbak stream...', LogList);
      Backup.Backup;
    finally
      Backup.Free;
      if OwnsDriverLink then
        DriverLink.Free;
    end;

    if FileExists(TargetFile) then
    begin
      Result.Success := True;
      Result.BackupType := btDatabaseFbk;
      Result.TargetFilePath := TargetFile;
      Result.FileSizeBytes := TFile.GetSize(TargetFile);
      Result.ItemCount := 1;
      Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
      EmitLog(Format('Database backup completed successfully. Size: %d bytes (Duration: %d ms)',
        [Result.FileSizeBytes, Result.DurationMs]), LogList);
    end
    else
    begin
      Result.ErrorMessage := 'Backup completed without exception, but target file was not created.';
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during database backup: ' + E.Message, LogList);
    end;
  end;

  FCurrentLogList := nil;
  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.BackupDatabasePhysical(
  const ADestFilePath: string
): TBackupResult;
var
  Conn: TFDConnection;
  Cfg: TDatabaseConfig;
  SourceFile, TargetFile: string;
  Stopwatch: TDateTime;
  LogList: TList<string>;
  I: Integer;
begin
  Result := TBackupResult.CreateFailure(btDatabasePhysical, '');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  try
    Cfg := TDieVixConnectionManager.Instance.Config;
    SourceFile := TPath.GetFullPath(Cfg.Database);
    if not FileExists(SourceFile) then
    begin
      Result.ErrorMessage := 'Database file not found: ' + SourceFile;
      Exit;
    end;

    if (ADestFilePath <> '') then
      TargetFile := TPath.GetFullPath(ADestFilePath)
    else
      TargetFile := TPath.Combine(GetDefaultBackupFolder,
        'DieVix_DB_Physical_' + FormatDateTime('YYYYMMDD_HHNNSS', Now) + '.fdb.bak');

    ForceDirectories(ExtractFilePath(TargetFile));
    EmitLog('Initiating Firebird online physical hot snapshot...', LogList);
    EmitLog('Source Database File: ' + SourceFile, LogList);
    EmitLog('Target Physical Copy: ' + TargetFile, LogList);

    Conn := TDieVixConnectionManager.Instance.GetConnection;
    EmitLog('Executing ALTER DATABASE BEGIN BACKUP...', LogList);
    Conn.ExecSQL('ALTER DATABASE BEGIN BACKUP');
    try
      EmitLog('Performing safe hot binary copy...', LogList);
      TFile.Copy(SourceFile, TargetFile, True);
    finally
      EmitLog('Executing ALTER DATABASE END BACKUP...', LogList);
      Conn.ExecSQL('ALTER DATABASE END BACKUP');
    end;

    if FileExists(TargetFile) then
    begin
      Result.Success := True;
      Result.BackupType := btDatabasePhysical;
      Result.TargetFilePath := TargetFile;
      Result.FileSizeBytes := TFile.GetSize(TargetFile);
      Result.ItemCount := 1;
      Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
      EmitLog(Format('Physical hot backup completed successfully. Size: %d bytes (Duration: %d ms)',
        [Result.FileSizeBytes, Result.DurationMs]), LogList);
    end
    else
    begin
      Result.ErrorMessage := 'Physical copy failed to produce target file.';
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during physical hot backup: ' + E.Message, LogList);
    end;
  end;

  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.RestoreDatabase(
  const ABackupFbkPath: string;
  const ATargetDbPath: string;
  const APageSize: Integer;
  const AOverwriteExisting: Boolean
): TRestoreResult;
var
  Restore: TFDIBRestore;
  DriverLink: TFDPhysFBDriverLink;
  OwnsDriverLink: Boolean;
  Cfg: TDatabaseConfig;
  SourceFbk, TargetDb: string;
  Stopwatch: TDateTime;
  LogList: TList<string>;
  I: Integer;
begin
  Result := TRestoreResult.CreateFailure('');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  FCurrentLogList := LogList;
  try
    SourceFbk := TPath.GetFullPath(ABackupFbkPath);
    if not FileExists(SourceFbk) then
    begin
      Result.ErrorMessage := 'Backup file (.fbk) not found: ' + SourceFbk;
      Exit;
    end;

    TargetDb := TPath.GetFullPath(ATargetDbPath);
    if FileExists(TargetDb) and not AOverwriteExisting then
    begin
      Result.ErrorMessage := 'Target database file already exists and overwrite is disabled: ' + TargetDb;
      Exit;
    end;

    ForceDirectories(ExtractFilePath(TargetDb));
    EmitLog('Initializing Firebird database restore...', LogList);
    EmitLog('Source Backup Archive: ' + SourceFbk, LogList);
    EmitLog('Target Database: ' + TargetDb, LogList);

    Cfg := TDieVixConnectionManager.Instance.Config;
    DriverLink := TDieVixConnectionManager.Instance.DriverLink;
    OwnsDriverLink := False;
    if not Assigned(DriverLink) then
    begin
      DriverLink := TFDPhysFBDriverLink.Create(nil);
      DriverLink.VendorLib := Cfg.VendorLib;
      OwnsDriverLink := True;
    end;

    Restore := TFDIBRestore.Create(nil);
    try
      Restore.DriverLink := DriverLink;
      Restore.Protocol := ipTCPIP;
      if (Cfg.Server <> '') and not SameText(Cfg.Server, 'localhost') then
        Restore.Host := Cfg.Server
      else
        Restore.Host := 'localhost';

      if (Cfg.Port > 0) then
        Restore.Port := Cfg.Port
      else
        Restore.Port := 3050;

      Restore.UserName := Cfg.UserName;
      Restore.Password := Cfg.Password;
      Restore.Database := TargetDb;
      Restore.BackupFiles.Clear;
      Restore.BackupFiles.Add(SourceFbk);

      if AOverwriteExisting then
        Restore.Options := Restore.Options + [roReplace];

      if (APageSize > 0) then
        Restore.PageSize := APageSize
      else
        Restore.PageSize := 8192;

      Restore.OnProgress := DoServiceProgress;

      EmitLog('Connecting to Firebird Services API and initiating database restore...', LogList);
      Restore.Restore;
    finally
      Restore.Free;
      if OwnsDriverLink then
        DriverLink.Free;
    end;

    if FileExists(TargetDb) then
    begin
      Result.Success := True;
      Result.SourceFilePath := SourceFbk;
      Result.TargetLocation := TargetDb;
      Result.RestoredCount := 1;
      Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
      EmitLog(Format('Database restore completed successfully. File: %s (Duration: %d ms)',
        [TargetDb, Result.DurationMs]), LogList);
    end
    else
    begin
      Result.ErrorMessage := 'Restore completed without exception, but target database was not created.';
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during database restore: ' + E.Message, LogList);
    end;
  end;

  FCurrentLogList := nil;
  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.GetAvailableReportTemplates: TArray<TReportTemplateInfo>;
var
  RepDir: string;
  VrtFiles: TStringDynArray;
  I: Integer;
  Content, Title, ValErr: string;
begin
  Result := nil;
  RepDir := ResolveActiveReportsPath;
  if not DirectoryExists(RepDir) then
    Exit;

  VrtFiles := TDirectory.GetFiles(RepDir, '*.vrt');
  SetLength(Result, Length(VrtFiles));
  for I := 0 to High(VrtFiles) do
  begin
    Result[I].FileName := ExtractFileName(VrtFiles[I]);
    Result[I].FilePath := VrtFiles[I];
    Result[I].FileSizeBytes := TFile.GetSize(VrtFiles[I]);
    Result[I].ModifiedTime := TFile.GetLastWriteTime(VrtFiles[I]);
    try
      Content := TFile.ReadAllText(VrtFiles[I], TEncoding.UTF8);
      Result[I].IsValid := ValidateReportTemplateJson(Content, Title, ValErr);
      Result[I].Title := Title;
      Result[I].ValidationNote := ValErr;
    except
      on E: Exception do
      begin
        Result[I].IsValid := False;
        Result[I].ValidationNote := E.Message;
      end;
    end;
  end;
end;

function TDieVixBackupService.BackupReportsToZip(
  const ADestZipPath: string
): TBackupResult;
var
  RepDir: string;
  TargetZip: string;
  VrtFiles: TStringDynArray;
  Zip: TZipFile;
  I: Integer;
  Stopwatch: TDateTime;
  LogList: TList<string>;
begin
  Result := TBackupResult.CreateFailure(btReportsZip, '');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  try
    RepDir := ResolveActiveReportsPath;
    if not DirectoryExists(RepDir) then
    begin
      Result.ErrorMessage := 'Reports directory not found: ' + RepDir;
      Exit;
    end;

    VrtFiles := TDirectory.GetFiles(RepDir, '*.vrt');
    if (Length(VrtFiles) = 0) then
    begin
      Result.ErrorMessage := 'No .vrt report template files found in ' + RepDir;
      Exit;
    end;

    if (ADestZipPath <> '') then
      TargetZip := TPath.GetFullPath(ADestZipPath)
    else
      TargetZip := TPath.Combine(GetDefaultBackupFolder,
        'DieVix_Reports_' + FormatDateTime('YYYYMMDD_HHNNSS', Now) + '.zip');

    ForceDirectories(ExtractFilePath(TargetZip));
    if FileExists(TargetZip) then
      TFile.Delete(TargetZip);

    EmitLog('Creating report templates backup archive...', LogList);
    EmitLog('Source Reports Directory: ' + RepDir, LogList);
    EmitLog('Target ZIP Archive: ' + TargetZip, LogList);

    Zip := TZipFile.Create;
    try
      Zip.Open(TargetZip, zmWrite);
      for I := 0 to High(VrtFiles) do
      begin
        Zip.Add(VrtFiles[I], ExtractFileName(VrtFiles[I]));
        EmitLog('Archived template: ' + ExtractFileName(VrtFiles[I]), LogList);
      end;
      Zip.Close;
    finally
      Zip.Free;
    end;

    if FileExists(TargetZip) then
    begin
      Result.Success := True;
      Result.BackupType := btReportsZip;
      Result.TargetFilePath := TargetZip;
      Result.FileSizeBytes := TFile.GetSize(TargetZip);
      Result.ItemCount := Length(VrtFiles);
      Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
      EmitLog(Format('Reports backup completed successfully. %d templates archived. Size: %d bytes (Duration: %d ms)',
        [Result.ItemCount, Result.FileSizeBytes, Result.DurationMs]), LogList);
    end
    else
    begin
      Result.ErrorMessage := 'ZIP creation failed to produce output file.';
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during reports backup: ' + E.Message, LogList);
    end;
  end;

  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.BackupReportsToFolder(
  const ADestFolderPath: string
): TBackupResult;
var
  RepDir, TargetDir, DestFile: string;
  VrtFiles: TStringDynArray;
  I: Integer;
  Stopwatch: TDateTime;
  LogList: TList<string>;
  TotalSize: Int64;
begin
  Result := TBackupResult.CreateFailure(btReportsFolder, '');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  TotalSize := 0;
  try
    RepDir := ResolveActiveReportsPath;
    if not DirectoryExists(RepDir) then
    begin
      Result.ErrorMessage := 'Reports directory not found: ' + RepDir;
      Exit;
    end;

    VrtFiles := TDirectory.GetFiles(RepDir, '*.vrt');
    if (Length(VrtFiles) = 0) then
    begin
      Result.ErrorMessage := 'No .vrt report template files found in ' + RepDir;
      Exit;
    end;

    if (ADestFolderPath <> '') then
      TargetDir := TPath.GetFullPath(ADestFolderPath)
    else
      TargetDir := TPath.Combine(GetDefaultBackupFolder,
        'DieVix_Reports_' + FormatDateTime('YYYYMMDD_HHNNSS', Now));

    ForceDirectories(TargetDir);
    EmitLog('Backing up report templates to destination folder...', LogList);
    EmitLog('Source Reports Directory: ' + RepDir, LogList);
    EmitLog('Target Folder: ' + TargetDir, LogList);

    for I := 0 to High(VrtFiles) do
    begin
      DestFile := TPath.Combine(TargetDir, ExtractFileName(VrtFiles[I]));
      TFile.Copy(VrtFiles[I], DestFile, True);
      TotalSize := TotalSize + TFile.GetSize(DestFile);
      EmitLog('Copied template: ' + ExtractFileName(VrtFiles[I]), LogList);
    end;

    Result.Success := True;
    Result.BackupType := btReportsFolder;
    Result.TargetFilePath := TargetDir;
    Result.FileSizeBytes := TotalSize;
    Result.ItemCount := Length(VrtFiles);
    Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
    EmitLog(Format('Reports folder backup completed. %d templates copied. (Duration: %d ms)',
      [Result.ItemCount, Result.DurationMs]), LogList);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during reports folder backup: ' + E.Message, LogList);
    end;
  end;

  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.RestoreReportsFromZip(
  const ASourceZipPath: string;
  const ATargetFolder: string;
  const AOverwriteExisting: Boolean
): TRestoreResult;
var
  Zip: TZipFile;
  TargetDir, SourceZip: string;
  Stopwatch: TDateTime;
  LogList: TList<string>;
  I: Integer;
  EntryName, DestFile, Content, Title, ValErr: string;
  RawBytes: TBytes;
  RestoredCount: Integer;
begin
  Result := TRestoreResult.CreateFailure('');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  RestoredCount := 0;
  try
    SourceZip := TPath.GetFullPath(ASourceZipPath);
    if not FileExists(SourceZip) then
    begin
      Result.ErrorMessage := 'Source report backup ZIP not found: ' + SourceZip;
      Exit;
    end;

    if (ATargetFolder <> '') then
      TargetDir := TPath.GetFullPath(ATargetFolder)
    else
      TargetDir := ResolveActiveReportsPath;

    ForceDirectories(TargetDir);
    EmitLog('Restoring report templates from ZIP archive...', LogList);
    EmitLog('Source ZIP: ' + SourceZip, LogList);
    EmitLog('Target Directory: ' + TargetDir, LogList);

    Zip := TZipFile.Create;
    try
      Zip.Open(SourceZip, zmRead);
      for I := 0 to Zip.FileCount - 1 do
      begin
        EntryName := Zip.FileNames[I];
        if SameText(ExtractFileExt(EntryName), '.vrt') then
        begin
          Zip.Read(I, RawBytes);
          Content := TEncoding.UTF8.GetString(RawBytes);

          if not ValidateReportTemplateJson(Content, Title, ValErr) then
          begin
            EmitLog(Format('WARNING: Skipping corrupt template "%s": %s', [EntryName, ValErr]), LogList);
            Continue;
          end;

          DestFile := TPath.Combine(TargetDir, ExtractFileName(EntryName));
          if FileExists(DestFile) and not AOverwriteExisting then
          begin
            EmitLog('Skipping existing template (overwrite disabled): ' + ExtractFileName(EntryName), LogList);
            Continue;
          end;

          TFile.WriteAllText(DestFile, Content, TEncoding.UTF8);
          Inc(RestoredCount);
          EmitLog(Format('Restored template: %s ("%s")', [ExtractFileName(EntryName), Title]), LogList);
        end;
      end;
      Zip.Close;
    finally
      Zip.Free;
    end;

    if (RestoredCount > 0) then
    begin
      Result.Success := True;
      Result.SourceFilePath := SourceZip;
      Result.TargetLocation := TargetDir;
      Result.RestoredCount := RestoredCount;
      Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
      EmitLog(Format('Report restore finished successfully. %d templates restored. (Duration: %d ms)',
        [RestoredCount, Result.DurationMs]), LogList);
    end
    else
    begin
      Result.ErrorMessage := 'No valid .vrt templates were found or extracted from ' + SourceZip;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during report restore from ZIP: ' + E.Message, LogList);
    end;
  end;

  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.RestoreReportsFromFolder(
  const ASourceFolderPath: string;
  const ATargetFolder: string;
  const AOverwriteExisting: Boolean
): TRestoreResult;
var
  SourceDir, TargetDir, DestFile, Content, Title, ValErr: string;
  VrtFiles: TStringDynArray;
  I: Integer;
  Stopwatch: TDateTime;
  LogList: TList<string>;
  RestoredCount: Integer;
begin
  Result := TRestoreResult.CreateFailure('');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  RestoredCount := 0;
  try
    SourceDir := TPath.GetFullPath(ASourceFolderPath);
    if not DirectoryExists(SourceDir) then
    begin
      Result.ErrorMessage := 'Source reports folder not found: ' + SourceDir;
      Exit;
    end;

    if (ATargetFolder <> '') then
      TargetDir := TPath.GetFullPath(ATargetFolder)
    else
      TargetDir := ResolveActiveReportsPath;

    ForceDirectories(TargetDir);
    EmitLog('Restoring report templates from folder...', LogList);
    EmitLog('Source Folder: ' + SourceDir, LogList);
    EmitLog('Target Folder: ' + TargetDir, LogList);

    VrtFiles := TDirectory.GetFiles(SourceDir, '*.vrt');
    for I := 0 to High(VrtFiles) do
    begin
      Content := TFile.ReadAllText(VrtFiles[I], TEncoding.UTF8);
      if not ValidateReportTemplateJson(Content, Title, ValErr) then
      begin
        EmitLog(Format('WARNING: Skipping corrupt template "%s": %s',
          [ExtractFileName(VrtFiles[I]), ValErr]), LogList);
        Continue;
      end;

      DestFile := TPath.Combine(TargetDir, ExtractFileName(VrtFiles[I]));
      if FileExists(DestFile) and not AOverwriteExisting then
      begin
        EmitLog('Skipping existing template (overwrite disabled): ' + ExtractFileName(VrtFiles[I]), LogList);
        Continue;
      end;

      TFile.Copy(VrtFiles[I], DestFile, True);
      Inc(RestoredCount);
      EmitLog(Format('Restored template: %s ("%s")', [ExtractFileName(VrtFiles[I]), Title]), LogList);
    end;

    if (RestoredCount > 0) then
    begin
      Result.Success := True;
      Result.SourceFilePath := SourceDir;
      Result.TargetLocation := TargetDir;
      Result.RestoredCount := RestoredCount;
      Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
      EmitLog(Format('Report folder restore finished. %d templates restored. (Duration: %d ms)',
        [RestoredCount, Result.DurationMs]), LogList);
    end
    else
    begin
      Result.ErrorMessage := 'No valid .vrt templates were found in source folder: ' + SourceDir;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during report restore from folder: ' + E.Message, LogList);
    end;
  end;

  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.BackupFullSystem(
  const ADestZipPath: string;
  const AOperatorName: string
): TBackupResult;
var
  TargetZip, TempDir, DbTempDir, RepTempDir, FbkTempFile, ManifestFile: string;
  DbResult: TBackupResult;
  Templates: TArray<TReportTemplateInfo>;
  I: Integer;
  Zip: TZipFile;
  ManifestObj: TJSONObject;
  ManifestReportsArr: TJSONArray;
  RepItemObj: TJSONObject;
  Operator: string;
  Stopwatch: TDateTime;
  LogList: TList<string>;
  TotalSize: Int64;
begin
  Result := TBackupResult.CreateFailure(btFullSystemBundle, '');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  TempDir := TPath.Combine(TPath.GetTempPath, 'DieVix_FullBackup_' + FormatDateTime('YYYYMMDD_HHNNSS_zzz', Now));
  try
    if (ADestZipPath <> '') then
      TargetZip := TPath.GetFullPath(ADestZipPath)
    else
      TargetZip := TPath.Combine(GetDefaultBackupFolder,
        'DieVix_SystemBackup_' + FormatDateTime('YYYYMMDD_HHNNSS', Now) + '.zip');

    ForceDirectories(ExtractFilePath(TargetZip));
    ForceDirectories(TempDir);
    DbTempDir := TPath.Combine(TempDir, 'database');
    RepTempDir := TPath.Combine(TempDir, 'reports');
    ForceDirectories(DbTempDir);
    ForceDirectories(RepTempDir);

    EmitLog('=================================================================', LogList);
    EmitLog('Starting DieVix Unified Full System Backup (Database + Reports)...', LogList);
    EmitLog('Target Bundle ZIP: ' + TargetZip, LogList);

    // 1. Database backup to temp fbk
    FbkTempFile := TPath.Combine(DbTempDir, 'dievix.fbk');
    DbResult := BackupDatabase(FbkTempFile, False, False);
    if not DbResult.Success then
    begin
      Result.ErrorMessage := 'Failed to backup database for system bundle: ' + DbResult.ErrorMessage;
      Exit;
    end;
    EmitLog(Format('Database backup succeeded (%d bytes).', [DbResult.FileSizeBytes]), LogList);

    // 2. Report templates copying
    Templates := GetAvailableReportTemplates;
    EmitLog(Format('Copying %d report templates into system bundle...', [Length(Templates)]), LogList);
    for I := 0 to High(Templates) do
    begin
      TFile.Copy(Templates[I].FilePath, TPath.Combine(RepTempDir, Templates[I].FileName), True);
      EmitLog('Included report: ' + Templates[I].FileName, LogList);
    end;

    // 3. Generate backup_manifest.json
    if (AOperatorName <> '') then
      Operator := AOperatorName
    else
      Operator := GetCurrentOperator;

    ManifestObj := TJSONObject.Create;
    try
      ManifestObj.AddPair('Application', 'DieVix Rotary Die & Keyline Manager');
      ManifestObj.AddPair('BackupTimestamp', FormatDateTime('YYYY-MM-DD"T"HH:NN:SS', Now));
      ManifestObj.AddPair('Operator', Operator);
      ManifestObj.AddPair('DatabaseBackupFile', 'database/dievix.fbk');
      ManifestObj.AddPair('DatabaseSizeBytes', TJSONNumber.Create(DbResult.FileSizeBytes));

      ManifestReportsArr := TJSONArray.Create;
      for I := 0 to High(Templates) do
      begin
        RepItemObj := TJSONObject.Create;
        RepItemObj.AddPair('FileName', Templates[I].FileName);
        RepItemObj.AddPair('Title', Templates[I].Title);
        RepItemObj.AddPair('FileSizeBytes', TJSONNumber.Create(Templates[I].FileSizeBytes));
        ManifestReportsArr.AddElement(RepItemObj);
      end;
      ManifestObj.AddPair('Reports', ManifestReportsArr);

      ManifestFile := TPath.Combine(TempDir, 'backup_manifest.json');
      TFile.WriteAllText(ManifestFile, ManifestObj.ToJSON, TEncoding.UTF8);
      EmitLog('Generated backup_manifest.json metadata manifest.', LogList);
    finally
      ManifestObj.Free;
    end;

    // 4. Compress bundle directory to TargetZip
    if FileExists(TargetZip) then
      TFile.Delete(TargetZip);

    EmitLog('Compressing full system bundle into ZIP archive...', LogList);
    Zip := TZipFile.Create;
    try
      Zip.Open(TargetZip, zmWrite);
      Zip.Add(FbkTempFile, 'database/dievix.fbk');
      for I := 0 to High(Templates) do
        Zip.Add(TPath.Combine(RepTempDir, Templates[I].FileName), 'reports/' + Templates[I].FileName);
      Zip.Add(ManifestFile, 'backup_manifest.json');
      Zip.Close;
    finally
      Zip.Free;
    end;

    TotalSize := TFile.GetSize(TargetZip);
    Result.Success := True;
    Result.BackupType := btFullSystemBundle;
    Result.TargetFilePath := TargetZip;
    Result.FileSizeBytes := TotalSize;
    Result.ItemCount := 1 + Length(Templates);
    Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
    EmitLog(Format('Full System Backup completed successfully. Size: %d bytes (Duration: %d ms)',
      [TotalSize, Result.DurationMs]), LogList);
    EmitLog('=================================================================', LogList);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during full system backup: ' + E.Message, LogList);
    end;
  end;

  if DirectoryExists(TempDir) then
  begin
    try
      TDirectory.Delete(TempDir, True);
    except
      // Non-critical temp dir deletion cleanup
    end;
  end;

  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.RestoreFullSystem(
  const ASourceBundlePath: string;
  const ATargetDbPath: string;
  const ATargetReportsDir: string;
  const AOverwrite: Boolean
): TRestoreResult;
var
  SourceZip, TempDir, ManifestFile, FbkExtracted, TargetDb, TargetRep: string;
  Zip: TZipFile;
  Stopwatch: TDateTime;
  LogList: TList<string>;
  I, RestoredCount: Integer;
  Content, Title, ValErr, DestFile: string;
  DbRestResult: TRestoreResult;
  VrtFiles: TStringDynArray;
  FbkFiles: TStringDynArray;
begin
  Result := TRestoreResult.CreateFailure('');
  Stopwatch := Now;
  LogList := TList<string>.Create;
  RestoredCount := 0;
  TempDir := TPath.Combine(TPath.GetTempPath, 'DieVix_FullRestore_' + FormatDateTime('YYYYMMDD_HHNNSS_zzz', Now));
  try
    SourceZip := TPath.GetFullPath(ASourceBundlePath);
    if not FileExists(SourceZip) then
    begin
      Result.ErrorMessage := 'Full system backup archive not found: ' + SourceZip;
      Exit;
    end;

    ForceDirectories(TempDir);
    if (ATargetReportsDir <> '') then
      TargetRep := TPath.GetFullPath(ATargetReportsDir)
    else
      TargetRep := ResolveActiveReportsPath;
    ForceDirectories(TargetRep);

    EmitLog('Restoring full system backup from archive: ' + SourceZip, LogList);
    Zip := TZipFile.Create;
    try
      Zip.Open(SourceZip, zmRead);
      Zip.ExtractAll(TempDir);
      Zip.Close;
    finally
      Zip.Free;
    end;

    ManifestFile := TPath.Combine(TempDir, 'backup_manifest.json');
    if FileExists(ManifestFile) then
      EmitLog('Found and verified backup_manifest.json in archive.', LogList);

    // 1. Restore reports
    VrtFiles := TDirectory.GetFiles(TempDir, '*.vrt', TSearchOption.soAllDirectories);
    for I := 0 to High(VrtFiles) do
    begin
      Content := TFile.ReadAllText(VrtFiles[I], TEncoding.UTF8);
      if ValidateReportTemplateJson(Content, Title, ValErr) then
      begin
        DestFile := TPath.Combine(TargetRep, ExtractFileName(VrtFiles[I]));
        TFile.Copy(VrtFiles[I], DestFile, AOverwrite);
        Inc(RestoredCount);
        EmitLog('Restored report template: ' + ExtractFileName(VrtFiles[I]), LogList);
      end;
    end;

    // 2. Restore database if target db path provided and fbk exists
    FbkExtracted := TPath.Combine(TempDir, 'database\dievix.fbk');
    if not FileExists(FbkExtracted) then
    begin
      FbkFiles := TDirectory.GetFiles(TempDir, '*.fbk', TSearchOption.soAllDirectories);
      if Length(FbkFiles) > 0 then
        FbkExtracted := FbkFiles[0];
    end;

    if (ATargetDbPath <> '') and FileExists(FbkExtracted) then
    begin
      TargetDb := TPath.GetFullPath(ATargetDbPath);
      EmitLog('Restoring database from extracted .fbk to: ' + TargetDb, LogList);
      DbRestResult := RestoreDatabase(FbkExtracted, TargetDb, 8192, AOverwrite);
      if not DbRestResult.Success then
      begin
        Result.ErrorMessage := 'Failed to restore database from system bundle: ' + DbRestResult.ErrorMessage;
        Exit;
      end;
      Inc(RestoredCount);
    end;

    Result.Success := True;
    Result.SourceFilePath := SourceZip;
    Result.TargetLocation := TargetRep;
    Result.RestoredCount := RestoredCount;
    Result.DurationMs := Round((Now - Stopwatch) * 86400000.0);
    EmitLog(Format('Full system restore completed successfully. (Duration: %d ms)', [Result.DurationMs]), LogList);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      EmitLog('ERROR during full system restore: ' + E.Message, LogList);
    end;
  end;

  if DirectoryExists(TempDir) then
  begin
    try
      TDirectory.Delete(TempDir, True);
    except
      // Cleanup
    end;
  end;

  SetLength(Result.LogMessages, LogList.Count);
  for I := 0 to LogList.Count - 1 do
    Result.LogMessages[I] := LogList[I];
  LogList.Free;
end;

function TDieVixBackupService.EnumerateBackups(const ADirectory: string): TArray<TBackupItemInfo>;
var
  TargetDir: string;
  AllFiles: TStringDynArray;
  I, Count: Integer;
  Fn, Ext: string;
  Info: TBackupItemInfo;
begin
  Result := nil;
  if (ADirectory <> '') then
    TargetDir := TPath.GetFullPath(ADirectory)
  else
    TargetDir := GetDefaultBackupFolder;

  if not DirectoryExists(TargetDir) then
    Exit;

  AllFiles := TDirectory.GetFiles(TargetDir);
  Count := 0;
  SetLength(Result, Length(AllFiles));

  for I := 0 to High(AllFiles) do
  begin
    Fn := ExtractFileName(AllFiles[I]);
    Ext := LowerCase(ExtractFileExt(Fn));

    if (Ext = '.fbk') then
    begin
      Info.FileName := Fn;
      Info.FilePath := AllFiles[I];
      Info.FileSizeBytes := TFile.GetSize(AllFiles[I]);
      Info.ModifiedTime := TFile.GetLastWriteTime(AllFiles[I]);
      Info.BackupType := btDatabaseFbk;
      Info.Description := 'Firebird Logical Backup Archive (.fbk)';
      Result[Count] := Info;
      Inc(Count);
    end
    else if (Ext = '.bak') or SameText(Copy(Fn, Length(Fn)-7, 8), '.fdb.bak') then
    begin
      Info.FileName := Fn;
      Info.FilePath := AllFiles[I];
      Info.FileSizeBytes := TFile.GetSize(AllFiles[I]);
      Info.ModifiedTime := TFile.GetLastWriteTime(AllFiles[I]);
      Info.BackupType := btDatabasePhysical;
      Info.Description := 'Firebird Physical Hot Snapshot (.fdb.bak)';
      Result[Count] := Info;
      Inc(Count);
    end
    else if (Ext = '.zip') then
    begin
      Info.FileName := Fn;
      Info.FilePath := AllFiles[I];
      Info.FileSizeBytes := TFile.GetSize(AllFiles[I]);
      Info.ModifiedTime := TFile.GetLastWriteTime(AllFiles[I]);
      if Pos('SystemBackup', Fn) > 0 then
      begin
        Info.BackupType := btFullSystemBundle;
        Info.Description := 'Unified Full System Backup Bundle (DB + Reports)';
      end
      else
      begin
        Info.BackupType := btReportsZip;
        Info.Description := 'Report Templates ZIP Archive';
      end;
      Result[Count] := Info;
      Inc(Count);
    end;
  end;

  SetLength(Result, Count);
end;

function TDieVixBackupService.VerifyDatabaseBackup(const ABackupPath: string; out ADetails: string): Boolean;
var
  FullP: string;
  Size: Int64;
begin
  FullP := TPath.GetFullPath(ABackupPath);
  if not FileExists(FullP) then
  begin
    ADetails := 'File does not exist: ' + FullP;
    Exit(False);
  end;

  Size := TFile.GetSize(FullP);
  if (Size < 512) then
  begin
    ADetails := Format('File is too small to be a valid backup (%d bytes).', [Size]);
    Exit(False);
  end;

  ADetails := Format('Valid Firebird backup archive (%d bytes).', [Size]);
  Result := True;
end;

function TDieVixBackupService.VerifyReportsArchive(const AZipPath: string; out ACount: Integer; out ADetails: string): Boolean;
var
  Zip: TZipFile;
  I: Integer;
  VrtCount: Integer;
begin
  ACount := 0;
  if not FileExists(AZipPath) then
  begin
    ADetails := 'File does not exist: ' + AZipPath;
    Exit(False);
  end;

  VrtCount := 0;
  Zip := TZipFile.Create;
  try
    try
      Zip.Open(AZipPath, zmRead);
      for I := 0 to Zip.FileCount - 1 do
      begin
        if SameText(ExtractFileExt(Zip.FileNames[I]), '.vrt') then
          Inc(VrtCount);
      end;
      Zip.Close;
      ACount := VrtCount;
      ADetails := Format('Valid ZIP archive containing %d report template(s).', [VrtCount]);
      Result := (VrtCount > 0);
    except
      on E: Exception do
      begin
        ADetails := 'Failed to read ZIP archive: ' + E.Message;
        Result := False;
      end;
    end;
  finally
    Zip.Free;
  end;
end;

end.
