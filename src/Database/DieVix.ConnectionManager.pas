unit DieVix.ConnectionManager;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  FireDAC Database Connection Manager for Firebird 5.0
  Supports:
    - Server Mode (Multi-user LAN via TCP/IP)
    - Embedded Mode (Single-user workstation)
==============================================================================}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  System.IOUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.NetEncoding,
  System.Hash,
  System.RegularExpressions,
  FireDAC.Comp.Client,
  FireDAC.Comp.UI,
  FireDAC.Comp.Script,
  FireDAC.Comp.ScriptCommands,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.Stan.Param,
  FireDAC.Stan.Intf,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Phys.Intf,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.Phys.IBBase,
  FireDAC.UI.Intf,
  FireDAC.Stan.Factory,
  Data.DB,
  DieVix.Domain;

type
  TConnectionMode = (cmServer, cmEmbedded);

  TDatabaseConfig = record
    Mode: TConnectionMode;
    Server: string;
    Port: Integer;
    Database: string;
    UserName: string;
    Password: string;
    VendorLib: string;
    CharSet: string;
    ConnectionTimeoutSec: Integer;
    class function DefaultServer: TDatabaseConfig; static;
    class function DefaultEmbedded: TDatabaseConfig; static;
  end;

  TDieVixConnectionManager = class
  private
    class var FInstance: TDieVixConnectionManager;
    class var FDefaultIniFileName: string;
  private
    FConfig: TDatabaseConfig;
    FConnection: TFDConnection;
    FDriverLink: TFDPhysFBDriverLink;
    FWaitCursor: TFDGUIxWaitCursor;
    FIniPath: string;
    procedure SetupDriverLink;
    procedure SetupWaitCursor;
  public
    constructor Create;
    destructor Destroy; override;

    class function Instance: TDieVixConnectionManager;
    class procedure ReleaseInstance;
    class function IsWaitCursorRegistered: Boolean;
    class procedure ConfigureConnection(AConn: TFDConnection; const ACfg: TDatabaseConfig);

    class procedure SetDefaultIniFileName(const AFileName: string);
    class function GetDefaultIniFileName: string;

    procedure LoadFromIni(const APath: string = '');
    procedure SaveToIni(const APath: string = '');

    function GetConnection: TFDConnection;
    function TestConnection(out AErrorMsg: string): Boolean;
    function CreateNewConnection: TFDConnection;
    procedure CreateDatabaseIfMissing;

    { Schema version & migrations }
    function GetDatabaseSchemaVersion: Integer;
    function GetHighestAvailableMigrationVersion(const AMigrationsDir: string): Integer;
    function ApplyMigrations(const AMigrationsDir: string; out AAppliedCount: Integer; out ALog: string): Boolean;

    property Config: TDatabaseConfig read FConfig write FConfig;
    property IniPath: string read FIniPath write FIniPath;
    property WaitCursor: TFDGUIxWaitCursor read FWaitCursor;
    property DriverLink: TFDPhysFBDriverLink read FDriverLink;
  end;

const
  CRYPTPROTECT_UI_FORBIDDEN = $1;
  CRYPTPROTECT_LOCAL_MACHINE = $4;

  ISC_DEADLOCK        = 335544336; // isc_deadlock
  ISC_LOCK_CONFLICT   = 335544345; // isc_lock_conflict
  ISC_UPDATE_CONFLICT = 335544451; // isc_update_conflict
  ISC_LOCK_TIMEOUT    = 335544510; // isc_lock_timeout
  ISC_LOGIN_ERROR     = 335544472; // isc_login

{ DPAPI secret protection }
function ProtectSecret(const APlain: string; const AIsMachineScope: Boolean = False): string;
function UnprotectSecret(const AStored: string): string;
function IsProgramDataConfigPath(const APath: string): Boolean;

{ Concurrency / DB exception mapping }
function TranslateDBException(const E: Exception): Exception;

{ INI path resolution }
function ResolveConfigIniPath(const ACustomIni: string = ''): string;

{ Pure safety guard for test database paths }
function IsSafeTestDatabasePath(const ATestDbPath, AAppIniPath: string; out AReason: string): Boolean; overload;
function IsSafeTestDatabasePath(const ATestDbPath, AAppIniPath: string): Boolean; overload;

implementation

{ TDatabaseConfig }

type
  DATA_BLOB = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDATA_BLOB = ^DATA_BLOB;

function CryptProtectData(
  pDataIn: PDATA_BLOB;
  szDataDescr: LPCWSTR;
  pOptionalEntropy: PDATA_BLOB;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PDATA_BLOB
): BOOL; stdcall; external 'crypt32.dll';

function CryptUnprotectData(
  pDataIn: PDATA_BLOB;
  ppszDataDescr: PLPWSTR;
  pOptionalEntropy: PDATA_BLOB;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PDATA_BLOB
): BOOL; stdcall; external 'crypt32.dll';

function IsProgramDataConfigPath(const APath: string): Boolean;
var
  ProgData: string;
  FullProgData, FullPath: string;
begin
  Result := False;
  if Trim(APath) = '' then
    Exit;
  try
    ProgData := GetEnvironmentVariable('ProgramData');
    if ProgData <> '' then
    begin
      FullProgData := IncludeTrailingPathDelimiter(TPath.GetFullPath(ProgData).ToLower);
      FullPath := TPath.GetFullPath(APath).ToLower;
      Result := FullPath.StartsWith(FullProgData);
    end;
  except
    Result := False;
  end;
end;

function ProtectSecret(const APlain: string; const AIsMachineScope: Boolean = False): string;
var
  DataIn, DataOut: DATA_BLOB;
  PlainBytes: TBytes;
  CipherBytes: TBytes;
  Flags: DWORD;
begin
  Result := APlain;
  if APlain = '' then
    Exit;
  try
    PlainBytes := TEncoding.UTF8.GetBytes(APlain);
    DataIn.cbData := Length(PlainBytes);
    DataIn.pbData := PByte(PlainBytes);
    FillChar(DataOut, SizeOf(DataOut), 0);
    Flags := CRYPTPROTECT_UI_FORBIDDEN;
    if AIsMachineScope then
      Flags := Flags or CRYPTPROTECT_LOCAL_MACHINE;

    if CryptProtectData(@DataIn, 'DieVixSecret', nil, nil, nil, Flags, @DataOut) then
    begin
      try
        SetLength(CipherBytes, DataOut.cbData);
        if DataOut.cbData > 0 then
          Move(DataOut.pbData^, CipherBytes[0], DataOut.cbData);
        Result := 'DPAPI:' + TNetEncoding.Base64String.EncodeBytesToString(CipherBytes);
      finally
        if DataOut.pbData <> nil then
          LocalFree(HLOCAL(DataOut.pbData));
      end;
    end;
  except
    Result := APlain;
  end;
end;

function UnprotectSecret(const AStored: string): string;
var
  CipherBytes: TBytes;
  DataIn, DataOut: DATA_BLOB;
  OutBytes: TBytes;
  B64: string;
begin
  Result := AStored;
  if not AStored.StartsWith('DPAPI:', True) then
    Exit;

  try
    B64 := Copy(AStored, 7, Length(AStored) - 6);
    CipherBytes := TNetEncoding.Base64String.DecodeStringToBytes(B64);
    if Length(CipherBytes) = 0 then
      Exit;
    DataIn.cbData := Length(CipherBytes);
    DataIn.pbData := PByte(CipherBytes);
    FillChar(DataOut, SizeOf(DataOut), 0);
    // CryptUnprotectData automatically decrypts both user-scoped and machine-scoped data
    if CryptUnprotectData(@DataIn, nil, nil, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @DataOut) then
    begin
      try
        SetLength(OutBytes, DataOut.cbData);
        if DataOut.cbData > 0 then
          Move(DataOut.pbData^, OutBytes[0], DataOut.cbData);
        Result := TEncoding.UTF8.GetString(OutBytes);
      finally
        if DataOut.pbData <> nil then
          LocalFree(HLOCAL(DataOut.pbData));
      end;
    end;
  except
    Result := AStored;
  end;
end;

function TranslateDBException(const E: Exception): Exception;
var
  DbErr: EFDDBEngineException;
  I: Integer;
  IsConflict: Boolean;
  IsLoginError: Boolean;
  LowerMsg: string;
begin
  Result := nil;
  if E = nil then
    Exit;

  IsConflict := False;
  IsLoginError := False;

  if E is EFDDBEngineException then
  begin
    DbErr := EFDDBEngineException(E);
    for I := 0 to DbErr.ErrorCount - 1 do
    begin
      if DbErr.Errors[I].ErrorCode = ISC_LOGIN_ERROR then
        IsLoginError := True;

      if (DbErr.Errors[I].ErrorCode = ISC_DEADLOCK) or
         (DbErr.Errors[I].ErrorCode = ISC_LOCK_CONFLICT) or
         (DbErr.Errors[I].ErrorCode = ISC_UPDATE_CONFLICT) or
         (DbErr.Errors[I].ErrorCode = ISC_LOCK_TIMEOUT) then
        IsConflict := True;
    end;

    if (not IsLoginError) and (DbErr.Kind = ekRecordLocked) then
      IsConflict := True;
  end;

  LowerMsg := LowerCase(E.Message);
  if (Pos('user name and password', LowerMsg) > 0) or
     (Pos('login', LowerMsg) > 0) or
     (Pos('authentication', LowerMsg) > 0) then
    IsLoginError := True;

  if (not IsLoginError) and (not IsConflict) then
  begin
    if (Pos('lock conflict', LowerMsg) > 0) or
       (Pos('update conflict', LowerMsg) > 0) or
       (Pos('lock timeout', LowerMsg) > 0) or
       (Pos('deadlock', LowerMsg) > 0) then
      IsConflict := True;
  end;

  if IsConflict and (not IsLoginError) then
    Result := EDieVixConcurrencyException.Create(
      'Concurrency conflict: The record is currently locked or was updated by another session. Please reload and review before saving.'
    );
end;

function ResolveConfigIniPath(const ACustomIni: string): string;
var
  ProgramDataDir: string;
  AppDataDir: string;
  AppDir: string;
  Cand: string;
  TargetDir: string;
begin
  if Trim(ACustomIni) <> '' then
  begin
    if TPath.IsPathRooted(ACustomIni) then
      Exit(ACustomIni);
    if FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), ACustomIni)) then
      Exit(TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), ACustomIni)));
    if FileExists(ACustomIni) then
      Exit(TPath.GetFullPath(ACustomIni));
    Exit(TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), ACustomIni)));
  end;

  // 1. Check %ProgramData%\DieVix\DieVix.ini
  try
    ProgramDataDir := GetEnvironmentVariable('ProgramData');
    if ProgramDataDir <> '' then
    begin
      Cand := TPath.Combine(ProgramDataDir, 'DieVix\DieVix.ini');
      if FileExists(Cand) then
        Exit(Cand);
    end;
  except
  end;

  // 2. Check %APPDATA%\DieVix\DieVix.ini
  try
    AppDataDir := GetEnvironmentVariable('APPDATA');
    if AppDataDir <> '' then
    begin
      Cand := TPath.Combine(AppDataDir, 'DieVix\DieVix.ini');
      if FileExists(Cand) then
        Exit(Cand);
    end;
  except
  end;

  // 3. Fallback to existing application directory DieVix.ini
  AppDir := ExtractFilePath(ParamStr(0));
  if FileExists(TPath.Combine(AppDir, 'DieVix.ini')) then
    Exit(TPath.Combine(AppDir, 'DieVix.ini'));
  if FileExists(TPath.Combine(AppDir, '..\DieVix.ini')) then
    Exit(TPath.GetFullPath(TPath.Combine(AppDir, '..\DieVix.ini')));
  if FileExists(TPath.Combine(AppDir, '..\..\DieVix.ini')) then
    Exit(TPath.GetFullPath(TPath.Combine(AppDir, '..\..\DieVix.ini')));
  if FileExists('DieVix.ini') then
    Exit(TPath.GetFullPath('DieVix.ini'));

  // 4. Default creation target if no file exists yet:
  // Prefer %ProgramData%\DieVix if accessible, else %APPDATA%\DieVix, else AppDir
  try
    if ProgramDataDir <> '' then
    begin
      TargetDir := TPath.Combine(ProgramDataDir, 'DieVix');
      if not DirectoryExists(TargetDir) then
        TDirectory.CreateDirectory(TargetDir);
      Exit(TPath.Combine(TargetDir, 'DieVix.ini'));
    end;
  except
  end;

  try
    if AppDataDir <> '' then
    begin
      TargetDir := TPath.Combine(AppDataDir, 'DieVix');
      if not DirectoryExists(TargetDir) then
        TDirectory.CreateDirectory(TargetDir);
      Exit(TPath.Combine(TargetDir, 'DieVix.ini'));
    end;
  except
  end;

  Result := TPath.Combine(AppDir, 'DieVix.ini');
end;

class function TDatabaseConfig.DefaultServer: TDatabaseConfig;
begin
  Result.Mode := cmServer;
  Result.Server := 'localhost';
  Result.Port := 3050;
  Result.Database := 'DIEVIX.FDB';
  Result.UserName := 'SYSDBA';
  Result.Password := '';
  Result.VendorLib := 'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll';
  Result.CharSet := 'UTF8';
  Result.ConnectionTimeoutSec := 15;
end;

class function TDatabaseConfig.DefaultEmbedded: TDatabaseConfig;
begin
  Result.Mode := cmEmbedded;
  Result.Server := '';
  Result.Port := 0;
  Result.Database := 'DIEVIX.FDB';
  Result.UserName := 'SYSDBA';
  Result.Password := '';
  Result.VendorLib := 'fbclient.dll';
  Result.CharSet := 'UTF8';
  Result.ConnectionTimeoutSec := 15;
end;

{ TDieVixConnectionManager }

class procedure TDieVixConnectionManager.SetDefaultIniFileName(const AFileName: string);
begin
  FDefaultIniFileName := AFileName;
end;

class function TDieVixConnectionManager.GetDefaultIniFileName: string;
begin
  Result := FDefaultIniFileName;
end;

constructor TDieVixConnectionManager.Create;
begin
  inherited Create;
  FConfig := TDatabaseConfig.DefaultServer;

  FIniPath := ResolveConfigIniPath(FDefaultIniFileName);

  SetupWaitCursor;

  FDriverLink := TFDPhysFBDriverLink.Create(nil);
  SetupDriverLink;

  FConnection := TFDConnection.Create(nil);
  if FileExists(FIniPath) then
    LoadFromIni(FIniPath)
  else
  begin
    LoadFromIni(FIniPath);
    if not FileExists(FIniPath) then
      ConfigureConnection(FConnection, FConfig);
  end;
end;

destructor TDieVixConnectionManager.Destroy;
begin
  if Assigned(FConnection) then
  begin
    if FConnection.Connected then
      FConnection.Close;
    FreeAndNil(FConnection);
  end;

  FreeAndNil(FDriverLink);
  FreeAndNil(FWaitCursor);
  inherited Destroy;
end;

class function TDieVixConnectionManager.Instance: TDieVixConnectionManager;
begin
  if FInstance = nil then
    FInstance := TDieVixConnectionManager.Create;
  Result := FInstance;
end;

class procedure TDieVixConnectionManager.ReleaseInstance;
begin
  FreeAndNil(FInstance);
end;

class function TDieVixConnectionManager.IsWaitCursorRegistered: Boolean;
var
  Intf: IFDGUIxWaitCursor;
begin
  try
    FDCreateInterface(IFDGUIxWaitCursor, Intf, False);
    Result := Assigned(Intf);
  except
    Result := False;
  end;
end;

procedure TDieVixConnectionManager.SetupWaitCursor;
begin
  if not Assigned(FWaitCursor) then
  begin
    FWaitCursor := TFDGUIxWaitCursor.Create(nil);
    FWaitCursor.ScreenCursor := gcrSQLWait;
  end;
end;

procedure TDieVixConnectionManager.SetupDriverLink;
begin
  if FileExists(FConfig.VendorLib) then
    FDriverLink.VendorLib := FConfig.VendorLib
  else if FileExists('C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll') then
    FDriverLink.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll';
end;

class procedure TDieVixConnectionManager.ConfigureConnection(AConn: TFDConnection; const ACfg: TDatabaseConfig);
begin
  AConn.Close;
  AConn.Params.Clear;
  AConn.DriverName := 'FB';

  if ACfg.Mode = cmServer then
  begin
    AConn.Params.Add('Server=' + ACfg.Server);
    AConn.Params.Add('Port=' + IntToStr(ACfg.Port));
    AConn.Params.Add('Protocol=TCPIP');
  end
  else
  begin
    AConn.Params.Add('Protocol=Local');
  end;

  AConn.Params.Database := ACfg.Database;
  AConn.Params.UserName := ACfg.UserName;
  AConn.Params.Password := ACfg.Password;
  AConn.Params.Add('CharacterSet=' + ACfg.CharSet);
  AConn.Params.Add('OpenMode=Open');

  // Apply timeout configuration
  if ACfg.ConnectionTimeoutSec > 0 then
  begin
    AConn.Params.Add('LoginTimeout=' + IntToStr(ACfg.ConnectionTimeoutSec));
    AConn.Params.Add('ConnectionTimeout=' + IntToStr(ACfg.ConnectionTimeoutSec));
    AConn.ResourceOptions.CmdExecTimeout := ACfg.ConnectionTimeoutSec * 1000;
  end;

  // Transaction options: wait with lock timeout for concurrent transactions
  AConn.TxOptions.AutoCommit := True;
  AConn.TxOptions.Isolation := xiReadCommitted;
  AConn.TxOptions.Params.Clear;
  AConn.TxOptions.Params.Add('read_committed');
  AConn.TxOptions.Params.Add('rec_version');
  AConn.TxOptions.Params.Add('wait');
  AConn.TxOptions.Params.Add('lock_timeout=5');
  AConn.UpdateOptions.LockWait := True;

  AConn.LoginPrompt := False;
end;

procedure TDieVixConnectionManager.LoadFromIni(const APath: string);
var
  Ini: TIniFile;
  TargetFile: string;
  ModeStr: string;
  ExampleFileName: string;
  ExamplePath: string;
  RawPassword: string;
begin
  if APath <> '' then
    FIniPath := APath;

  TargetFile := FIniPath;
  try
    if not FileExists(TargetFile) then
    begin
      // First run initialization: copy template if available or generate default config
      ExampleFileName := ExtractFileName(TargetFile) + '.example';
      ExamplePath := TPath.Combine(ExtractFilePath(TargetFile), ExampleFileName);
      if not FileExists(ExamplePath) then
        ExamplePath := TPath.Combine(ExtractFilePath(ParamStr(0)), ExampleFileName);
      if not FileExists(ExamplePath) and FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\' + ExampleFileName)) then
        ExamplePath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\' + ExampleFileName));
      if not FileExists(ExamplePath) and FileExists(ExampleFileName) then
        ExamplePath := TPath.GetFullPath(ExampleFileName);

      if FileExists(ExamplePath) then
      begin
        try
          var TargetDir := ExtractFilePath(TargetFile);
          if (TargetDir <> '') and not DirectoryExists(TargetDir) then
            TDirectory.CreateDirectory(TargetDir);
          TFile.Copy(ExamplePath, TargetFile, False);
        except
          SaveToIni(TargetFile);
        end;
      end
      else
        SaveToIni(TargetFile);
    end;

    if not FileExists(TargetFile) then
      Exit;

    Ini := TIniFile.Create(TargetFile);
    try
      ModeStr := Ini.ReadString('Database', 'Mode', 'Server');
      if SameText(ModeStr, 'Embedded') then
        FConfig.Mode := cmEmbedded
      else
        FConfig.Mode := cmServer;

      FConfig.Server := Ini.ReadString('Database', 'Server', 'localhost');
      FConfig.Port := Ini.ReadInteger('Database', 'Port', 3050);
      FConfig.Database := Ini.ReadString('Database', 'Database', 'DIEVIX.FDB');
      if (ExtractFileDrive(FConfig.Database) = '') and not FConfig.Database.StartsWith('/') then
      begin
        if FileExists(TPath.Combine(ExtractFilePath(TargetFile), FConfig.Database)) then
          FConfig.Database := TPath.GetFullPath(TPath.Combine(ExtractFilePath(TargetFile), FConfig.Database))
        else if FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), FConfig.Database)) then
          FConfig.Database := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), FConfig.Database));
      end;
      FConfig.UserName := Ini.ReadString('Database', 'UserName', 'SYSDBA');
      RawPassword := Ini.ReadString('Database', 'Password', '');
      FConfig.Password := UnprotectSecret(RawPassword);
      FConfig.VendorLib := Ini.ReadString('Database', 'VendorLib', 'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll');
      FConfig.CharSet := Ini.ReadString('Database', 'CharacterSet', 'UTF8');
      FConfig.ConnectionTimeoutSec := Ini.ReadInteger('Database', 'Timeout', 15);

      SetupDriverLink;
      ConfigureConnection(FConnection, FConfig);
    finally
      Ini.Free;
    end;
  except
    // Safe fallback: never throw from inside exception handler
  end;
end;

procedure TDieVixConnectionManager.SaveToIni(const APath: string);
var
  Ini: TIniFile;
  TargetFile: string;
  TargetDir: string;
begin
  if APath <> '' then
    FIniPath := APath;

  TargetFile := FIniPath;
  try
    TargetDir := ExtractFilePath(TargetFile);
    if (TargetDir <> '') and not DirectoryExists(TargetDir) then
      TDirectory.CreateDirectory(TargetDir);

    Ini := TIniFile.Create(TargetFile);
    try
      if FConfig.Mode = cmEmbedded then
        Ini.WriteString('Database', 'Mode', 'Embedded')
      else
        Ini.WriteString('Database', 'Mode', 'Server');

      Ini.WriteString('Database', 'Server', FConfig.Server);
      Ini.WriteInteger('Database', 'Port', FConfig.Port);
      Ini.WriteString('Database', 'Database', FConfig.Database);
      Ini.WriteString('Database', 'UserName', FConfig.UserName);
      Ini.WriteString('Database', 'Password', ProtectSecret(FConfig.Password, IsProgramDataConfigPath(TargetFile)));
      Ini.WriteString('Database', 'VendorLib', FConfig.VendorLib);
      Ini.WriteString('Database', 'CharacterSet', FConfig.CharSet);
      Ini.WriteInteger('Database', 'Timeout', FConfig.ConnectionTimeoutSec);
    finally
      Ini.Free;
    end;
  except
    // Safe fallback: never throw from inside exception handler
  end;
end;

function TDieVixConnectionManager.GetConnection: TFDConnection;
begin
  if not FConnection.Connected then
  begin
    ConfigureConnection(FConnection, FConfig);
    FConnection.Open;
  end;
  Result := FConnection;
end;

function TDieVixConnectionManager.CreateNewConnection: TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  ConfigureConnection(Result, FConfig);
end;

procedure TDieVixConnectionManager.CreateDatabaseIfMissing;
var
  TempConn: TFDConnection;
  DbDir: string;
begin
  // 1. Verify if database can already be opened with OpenMode=Open
  TempConn := CreateNewConnection;
  try
    try
      TempConn.Open;
      Exit; // Database exists and is accessible
    except
      // Failed to open; attempt explicit creation
    end;
  finally
    TempConn.Free;
  end;

  // 2. Perform explicit creation
  TempConn := TFDConnection.Create(nil);
  try
    ConfigureConnection(TempConn, FConfig);
    TempConn.Params.Values['OpenMode'] := 'Create';

    if (FConfig.Mode = cmEmbedded) or (ExtractFileDrive(FConfig.Database) <> '') then
    begin
      DbDir := ExtractFilePath(FConfig.Database);
      if (DbDir <> '') and not DirectoryExists(DbDir) then
        TDirectory.CreateDirectory(DbDir);
    end;

    TempConn.Open;
    TempConn.Close;
  finally
    TempConn.Free;
  end;
end;

function TDieVixConnectionManager.GetDatabaseSchemaVersion: Integer;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
begin
  Result := 0;
  Conn := GetConnection;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := Conn;
    Qry.SQL.Text := 'SELECT 1 FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = ''SCHEMA_VERSION'' AND RDB$VIEW_BLR IS NULL';
    Qry.Open;
    if Qry.IsEmpty then
      Exit;
    Qry.Close;

    Qry.SQL.Text := 'SELECT COALESCE(MAX(VERSION_NUM), 0) FROM SCHEMA_VERSION';
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.Fields[0].AsInteger;
    Qry.Close;
  finally
    Qry.Free;
  end;
end;

function TryParseMigrationFileName(const AFileName: string; out AVersion: Integer): Boolean; forward;

function TDieVixConnectionManager.GetHighestAvailableMigrationVersion(const AMigrationsDir: string): Integer;
var
  Files: TArray<string>;
  F, FileName: string;
  VerNum: Integer;
begin
  Result := 0;
  if not DirectoryExists(AMigrationsDir) then
    Exit;

  Files := TDirectory.GetFiles(AMigrationsDir, '*.sql');
  for F in Files do
  begin
    FileName := ExtractFileName(F);
    if TryParseMigrationFileName(FileName, VerNum) then
    begin
      if VerNum > Result then
        Result := VerNum;
    end;
  end;
end;

function TDieVixConnectionManager.TestConnection(out AErrorMsg: string): Boolean;
var
  TestConn: TFDConnection;
begin
  AErrorMsg := '';
  TestConn := CreateNewConnection;
  try
    try
      TestConn.Open;
      Result := TestConn.Connected;
    except
      on E: Exception do
      begin
        Result := False;
        AErrorMsg := E.Message;
      end;
    end;
  finally
    TestConn.Free;
  end;
end;

type
  TMigrationItem = record
    Version: Integer;
    FileName: string;
    FullPath: string;
    Checksum: string;
  end;

function ComputeMigrationFileChecksum(const AFilePath: string): string;
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
  try
    Result := THashSHA2.GetHashString(FS, THashSHA2.TSHA2Version.SHA256);
  finally
    FS.Free;
  end;
end;

function TryParseMigrationFileName(const AFileName: string; out AVersion: Integer): Boolean;
var
  SepPos: Integer;
  VerStr: string;
  I: Integer;
begin
  AVersion := 0;
  Result := False;

  if not SameText(ExtractFileExt(AFileName), '.sql') then
    Exit;

  // Expected format: V<digits>__<description>.sql (e.g., V001__initial_schema.sql)
  if (Length(AFileName) < 7) or (UpCase(AFileName[1]) <> 'V') then
    Exit;

  SepPos := Pos('__', AFileName);
  if SepPos < 3 then // Must have at least 1 digit between 'V' and '__'
    Exit;

  VerStr := Copy(AFileName, 2, SepPos - 2);
  for I := 1 to Length(VerStr) do
    if not CharInSet(VerStr[I], ['0'..'9']) then
      Exit;

  if not TryStrToInt(VerStr, AVersion) or (AVersion <= 0) then
    Exit;

  // Must have a non-empty description between '__' and '.sql'
  if (Length(AFileName) - 4) < (SepPos + 2) then
    Exit;

  Result := True;
end;

function TDieVixConnectionManager.ApplyMigrations(
  const AMigrationsDir: string;
  out AAppliedCount: Integer;
  out ALog: string
): Boolean;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
  Script: TFDScript;
  Files: TArray<string>;
  F: string;
  FileName: string;
  VerNum: Integer;
  Applied: Boolean;
  MigrationList: TList<TMigrationItem>;
  Item: TMigrationItem;
  I: Integer;
  TableExistedBefore: Boolean;

  function HasSchemaVersionTable: Boolean;
  begin
    if not Conn.InTransaction then
      Conn.StartTransaction;
    try
      Qry.SQL.Text := 'SELECT 1 FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = ''SCHEMA_VERSION'' AND RDB$VIEW_BLR IS NULL';
      Qry.Open;
      Result := not Qry.IsEmpty;
      Qry.Close;
    finally
      if Conn.InTransaction then
        Conn.Commit;
    end;
  end;

  function HasChecksumColumn: Boolean;
  begin
    if not Conn.InTransaction then
      Conn.StartTransaction;
    try
      Qry.SQL.Text :=
        'SELECT 1 FROM RDB$RELATION_FIELDS ' +
        'WHERE RDB$RELATION_NAME = ''SCHEMA_VERSION'' AND RDB$FIELD_NAME = ''CHECKSUM''';
      Qry.Open;
      Result := not Qry.IsEmpty;
      Qry.Close;
    finally
      if Conn.InTransaction then
        Conn.Commit;
    end;
  end;

begin
  AAppliedCount := 0;
  ALog := '';
  Result := False;

  if not DirectoryExists(AMigrationsDir) then
  begin
    ALog := 'Migrations directory not found: ' + AMigrationsDir;
    Exit;
  end;

  MigrationList := TList<TMigrationItem>.Create;
  try
    // 1. Discover and robustly validate all migration files
    Files := TDirectory.GetFiles(AMigrationsDir, '*.sql');
    for F in Files do
    begin
      FileName := ExtractFileName(F);
      if not TryParseMigrationFileName(FileName, VerNum) then
      begin
        ALog := ALog + Format('Malformed migration file name: "%s". Expected format: V<number>__<description>.sql', [FileName]) + sLineBreak;
        Exit(False);
      end;

      Item.Version := VerNum;
      Item.FileName := FileName;
      Item.FullPath := F;
      Item.Checksum := ComputeMigrationFileChecksum(F);
      MigrationList.Add(Item);
    end;

    // 2. Sort migrations numerically by version number
    MigrationList.Sort(TComparer<TMigrationItem>.Construct(
      function(const Left, Right: TMigrationItem): Integer
      begin
        Result := Left.Version - Right.Version;
      end
    ));

    // 3. Enforce version uniqueness
    for I := 1 to MigrationList.Count - 1 do
    begin
      if MigrationList[I].Version = MigrationList[I - 1].Version then
      begin
        ALog := ALog + Format('Duplicate migration version %d detected in files: "%s" and "%s"',
          [MigrationList[I].Version, MigrationList[I - 1].FileName, MigrationList[I].FileName]) + sLineBreak;
        Exit(False);
      end;
    end;

    // 4. Connect and prepare execution context
    Conn := GetConnection;
    Qry := TFDQuery.Create(nil);
    Script := TFDScript.Create(nil);
    try
      Qry.Connection := Conn;
      Script.Connection := Conn;
      Script.ScriptOptions.BreakOnError := True;
      Script.ScriptOptions.CommitEachNCommands := 0;

      // 5. Apply each unapplied migration atomically inside a transaction
      for Item in MigrationList do
      begin
        TableExistedBefore := HasSchemaVersionTable;
        Applied := False;
        if TableExistedBefore then
        begin
          if not Conn.InTransaction then
            Conn.StartTransaction;
          try
            Qry.SQL.Text := 'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSION_NUM = :V';
            Qry.ParamByName('V').AsInteger := Item.Version;
            Qry.Open;
            Applied := Qry.Fields[0].AsInteger > 0;
            Qry.Close;

            if Applied and HasChecksumColumn then
            begin
              Qry.SQL.Text := 'SELECT CHECKSUM FROM SCHEMA_VERSION WHERE VERSION_NUM = :V';
              Qry.ParamByName('V').AsInteger := Item.Version;
              Qry.Open;
              var StoredChecksum := Trim(Qry.Fields[0].AsString);
              Qry.Close;

              if StoredChecksum <> '' then
              begin
                if not SameText(StoredChecksum, Item.Checksum) then
                begin
                  ALog := ALog + Format('CHECKSUM MISMATCH for applied migration %s (Version %d). Expected: %s, Found on disk: %s. Refusing to run.',
                    [Item.FileName, Item.Version, StoredChecksum, Item.Checksum]) + sLineBreak;
                  Exit(False);
                end;
              end
              else
              begin
                // Backfill checksum for previously applied migration
                Qry.SQL.Text := 'UPDATE SCHEMA_VERSION SET CHECKSUM = :C WHERE VERSION_NUM = :V';
                Qry.ParamByName('C').AsString := Item.Checksum;
                Qry.ParamByName('V').AsInteger := Item.Version;
                Qry.ExecSQL;
              end;
            end;
          finally
            if Conn.InTransaction then
              Conn.Commit;
          end;
        end;

        if not Applied then
        begin
          ALog := ALog + Format('Applying %s...', [Item.FileName]) + sLineBreak;
          if not Conn.InTransaction then
            Conn.StartTransaction;
          try
            Script.SQLScripts.Clear;
            var ScriptContent := TFile.ReadAllText(Item.FullPath, TEncoding.UTF8);
            // Replace any embedded INSERT INTO SCHEMA_VERSION statements with empty string
            // so migration version is recorded strictly in code
            ScriptContent := TRegEx.Replace(ScriptContent, '(?is)\bINSERT\s+INTO\s+SCHEMA_VERSION\b[^;]*;', '');
            Script.SQLScripts.Add.SQL.Text := ScriptContent;

            if (not Script.ExecuteAll) or (Script.TotalErrors > 0) then
              raise Exception.Create(Format('Script execution failed with %d error(s)', [Script.TotalErrors]));

            // In Firebird, metadata changes (DDL that creates a new table like SCHEMA_VERSION in V001)
            // must be committed before DML can access the newly created table in the metadata cache.
            if not TableExistedBefore then
            begin
              if Conn.InTransaction then
                Conn.Commit;
              Conn.StartTransaction;
            end;

            // Record version atomically in the transaction in code only
            if not Conn.InTransaction then
              Conn.StartTransaction;

            if HasChecksumColumn then
            begin
              Qry.SQL.Text :=
                'UPDATE OR INSERT INTO SCHEMA_VERSION (VERSION_NUM, SCRIPT_NAME, CHECKSUM, APPLIED_AT) ' +
                'VALUES (:V, :N, :C, CURRENT_TIMESTAMP) MATCHING (VERSION_NUM)';
              Qry.ParamByName('V').AsInteger := Item.Version;
              Qry.ParamByName('N').AsString := Item.FileName;
              Qry.ParamByName('C').AsString := Item.Checksum;
            end
            else
            begin
              Qry.SQL.Text :=
                'UPDATE OR INSERT INTO SCHEMA_VERSION (VERSION_NUM, SCRIPT_NAME, APPLIED_AT) ' +
                'VALUES (:V, :N, CURRENT_TIMESTAMP) MATCHING (VERSION_NUM)';
              Qry.ParamByName('V').AsInteger := Item.Version;
              Qry.ParamByName('N').AsString := Item.FileName;
            end;
            Qry.ExecSQL;

            Conn.Commit;
            Inc(AAppliedCount);
            ALog := ALog + Format('Applied %s successfully.', [Item.FileName]) + sLineBreak;
          except
            on E: Exception do
            begin
              if Conn.InTransaction then
                Conn.Rollback;
              ALog := ALog + Format('Error applying migration %s: %s', [Item.FileName, E.Message]) + sLineBreak;
              Exit(False);
            end;
          end;
        end;
      end;

      Result := True;
    finally
      Script.Free;
      Qry.Free;
    end;
  finally
    MigrationList.Free;
  end;
end;

function IsSafeTestDatabasePath(const ATestDbPath, AAppIniPath: string; out AReason: string): Boolean;
var
  TargetFileName: string;
  NormalizedTarget: string;
  AppDbVal: string;
  NormalizedAppDb: string;
  Ini: TIniFile;
begin
  AReason := '';
  if Trim(ATestDbPath) = '' then
  begin
    AReason := 'Target test database path is empty.';
    Exit(False);
  end;

  TargetFileName := LowerCase(ExtractFileName(ATestDbPath));
  // 1. Filename must contain 'disposable' or 'test' (case-insensitive)
  if (Pos('disposable', TargetFileName) = 0) and (Pos('test', TargetFileName) = 0) then
  begin
    AReason := Format('Database filename "%s" does not contain "disposable" or "test". Refusing execution to protect non-test databases.', [ExtractFileName(ATestDbPath)]);
    Exit(False);
  end;

  // 2. Refuse if target is the same database configured in DieVix.ini (when it exists)
  if (Trim(AAppIniPath) <> '') and FileExists(AAppIniPath) then
  begin
    try
      Ini := TIniFile.Create(AAppIniPath);
      try
        AppDbVal := Trim(Ini.ReadString('Database', 'Database', ''));
      finally
        Ini.Free;
      end;

      if AppDbVal <> '' then
      begin
        NormalizedTarget := LowerCase(TPath.GetFullPath(ATestDbPath));
        NormalizedAppDb := LowerCase(TPath.GetFullPath(AppDbVal));

        if (NormalizedTarget = NormalizedAppDb) or SameText(TargetFileName, LowerCase(ExtractFileName(AppDbVal))) then
        begin
          AReason := Format('Target test database "%s" matches application database "%s" configured in %s.',
            [ExtractFileName(ATestDbPath), ExtractFileName(AppDbVal), ExtractFileName(AAppIniPath)]);
          Exit(False);
        end;
      end;
    except
      on E: Exception do
      begin
        AReason := 'Failed to read application configuration ' + AAppIniPath + ': ' + E.Message;
        Exit(False);
      end;
    end;
  end;

  Result := True;
end;

function IsSafeTestDatabasePath(const ATestDbPath, AAppIniPath: string): Boolean;
var
  DummyReason: string;
begin
  Result := IsSafeTestDatabasePath(ATestDbPath, AAppIniPath, DummyReason);
end;

initialization

finalization
  TDieVixConnectionManager.ReleaseInstance;

end.
