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
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  System.IOUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
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
  Data.DB;

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
    procedure ConfigureConnection(AConn: TFDConnection; const ACfg: TDatabaseConfig);
  public
    constructor Create;
    destructor Destroy; override;

    class function Instance: TDieVixConnectionManager;
    class procedure ReleaseInstance;
    class function IsWaitCursorRegistered: Boolean;

    class procedure SetDefaultIniFileName(const AFileName: string);
    class function GetDefaultIniFileName: string;

    procedure LoadFromIni(const APath: string = '');
    procedure SaveToIni(const APath: string = '');

    function GetConnection: TFDConnection;
    function TestConnection(out AErrorMsg: string): Boolean;
    function CreateNewConnection: TFDConnection;

    { Migration runner }
    function ApplyMigrations(const AMigrationsDir: string; out AAppliedCount: Integer; out ALog: string): Boolean;

    property Config: TDatabaseConfig read FConfig write FConfig;
    property IniPath: string read FIniPath write FIniPath;
    property WaitCursor: TFDGUIxWaitCursor read FWaitCursor;
    property DriverLink: TFDPhysFBDriverLink read FDriverLink;
  end;

{ Pure safety guard for test database paths }
function IsSafeTestDatabasePath(const ATestDbPath, AAppIniPath: string; out AReason: string): Boolean; overload;
function IsSafeTestDatabasePath(const ATestDbPath, AAppIniPath: string): Boolean; overload;

implementation

{ TDatabaseConfig }

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
var
  TargetIniName: string;
begin
  inherited Create;
  FConfig := TDatabaseConfig.DefaultServer;

  if FDefaultIniFileName <> '' then
    TargetIniName := FDefaultIniFileName
  else
    TargetIniName := 'DieVix.ini';

  if TPath.IsPathRooted(TargetIniName) then
    FIniPath := TargetIniName
  else
  begin
    FIniPath := TPath.Combine(ExtractFilePath(ParamStr(0)), TargetIniName);
    if not FileExists(FIniPath) and FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\' + TargetIniName)) then
      FIniPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\' + TargetIniName))
    else if not FileExists(FIniPath) and FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\' + TargetIniName)) then
      FIniPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\' + TargetIniName))
    else if not FileExists(FIniPath) and FileExists(TargetIniName) then
      FIniPath := TPath.GetFullPath(TargetIniName);
  end;

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

procedure TDieVixConnectionManager.ConfigureConnection(AConn: TFDConnection; const ACfg: TDatabaseConfig);
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
  AConn.Params.Add('OpenMode=OpenOrCreate');

  // Transaction options
  AConn.TxOptions.AutoCommit := True;
  AConn.TxOptions.Isolation := xiReadCommitted;

  AConn.LoginPrompt := False;
end;

procedure TDieVixConnectionManager.LoadFromIni(const APath: string);
var
  Ini: TIniFile;
  TargetFile: string;
  ModeStr: string;
  ExampleFileName: string;
  ExamplePath: string;
begin
  if APath <> '' then
    FIniPath := APath;

  TargetFile := FIniPath;
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
    FConfig.Password := Ini.ReadString('Database', 'Password', '');
    FConfig.VendorLib := Ini.ReadString('Database', 'VendorLib', 'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll');
    FConfig.CharSet := Ini.ReadString('Database', 'CharacterSet', 'UTF8');
    FConfig.ConnectionTimeoutSec := Ini.ReadInteger('Database', 'Timeout', 15);

    SetupDriverLink;
    ConfigureConnection(FConnection, FConfig);
  finally
    Ini.Free;
  end;
end;

procedure TDieVixConnectionManager.SaveToIni(const APath: string);
var
  Ini: TIniFile;
  TargetFile: string;
begin
  if APath <> '' then
    FIniPath := APath;

  TargetFile := FIniPath;
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
    Ini.WriteString('Database', 'Password', FConfig.Password);
    Ini.WriteString('Database', 'VendorLib', FConfig.VendorLib);
    Ini.WriteString('Database', 'CharacterSet', FConfig.CharSet);
    Ini.WriteInteger('Database', 'Timeout', FConfig.ConnectionTimeoutSec);
  finally
    Ini.Free;
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
  Trans: TFDTransaction;
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
            var ScriptLines := TStringList.Create;
            try
              ScriptLines.LoadFromFile(Item.FullPath);
              for var LIdx := ScriptLines.Count - 1 downto 0 do
              begin
                if ScriptLines[LIdx].ToUpper.Contains('INSERT INTO SCHEMA_VERSION') then
                  ScriptLines.Delete(LIdx);
              end;
              Script.SQLScripts.Add.SQL.Assign(ScriptLines);
            finally
              ScriptLines.Free;
            end;
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

            // Record version atomically in the transaction (if not already recorded by script itself)
            if not Conn.InTransaction then
              Conn.StartTransaction;
            Qry.SQL.Text := 'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSION_NUM = :V';
            Qry.ParamByName('V').AsInteger := Item.Version;
            Qry.Open;
            if Qry.Fields[0].AsInteger = 0 then
            begin
              Qry.Close;
              Qry.SQL.Text := 'INSERT INTO SCHEMA_VERSION (VERSION_NUM, SCRIPT_NAME) VALUES (:V, :N)';
              Qry.ParamByName('V').AsInteger := Item.Version;
              Qry.ParamByName('N').AsString := Item.FileName;
              Qry.ExecSQL;
            end
            else
              Qry.Close;

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
