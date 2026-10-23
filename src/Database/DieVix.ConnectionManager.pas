unit DieVix.ConnectionManager;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
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
  private
    FConfig: TDatabaseConfig;
    FConnection: TFDConnection;
    FDriverLink: TFDPhysFBDriverLink;
    FIniPath: string;
    procedure SetupDriverLink;
    procedure ConfigureConnection(AConn: TFDConnection; const ACfg: TDatabaseConfig);
  public
    constructor Create;
    destructor Destroy; override;

    class function Instance: TDieVixConnectionManager;
    class procedure ReleaseInstance;

    procedure LoadFromIni(const APath: string = '');
    procedure SaveToIni(const APath: string = '');

    function GetConnection: TFDConnection;
    function TestConnection(out AErrorMsg: string): Boolean;
    function CreateNewConnection: TFDConnection;

    { Migration runner }
    function ApplyMigrations(const AMigrationsDir: string; out AAppliedCount: Integer; out ALog: string): Boolean;

    property Config: TDatabaseConfig read FConfig write FConfig;
    property IniPath: string read FIniPath write FIniPath;
  end;

implementation

{ TDatabaseConfig }

class function TDatabaseConfig.DefaultServer: TDatabaseConfig;
begin
  Result.Mode := cmServer;
  Result.Server := 'localhost';
  Result.Port := 3050;
  Result.Database := 'DIEVIX.FDB';
  Result.UserName := 'SYSDBA';
  Result.Password := 'masterkey';
  Result.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll';
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
  Result.Password := 'masterkey';
  Result.VendorLib := 'fbclient.dll';
  Result.CharSet := 'UTF8';
  Result.ConnectionTimeoutSec := 15;
end;

{ TDieVixConnectionManager }

constructor TDieVixConnectionManager.Create;
begin
  inherited Create;
  FConfig := TDatabaseConfig.DefaultServer;
  FIniPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'DieVix.ini');

  FDriverLink := TFDPhysFBDriverLink.Create(nil);
  SetupDriverLink;

  FConnection := TFDConnection.Create(nil);
  ConfigureConnection(FConnection, FConfig);
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
begin
  if APath <> '' then
    FIniPath := APath;

  TargetFile := FIniPath;
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
    FConfig.UserName := Ini.ReadString('Database', 'UserName', 'SYSDBA');
    FConfig.Password := Ini.ReadString('Database', 'Password', 'masterkey');
    FConfig.VendorLib := Ini.ReadString('Database', 'VendorLib', 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll');
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
  VerStr: string;
begin
  AAppliedCount := 0;
  ALog := '';
  Result := False;

  if not DirectoryExists(AMigrationsDir) then
  begin
    ALog := 'Migrations directory not found: ' + AMigrationsDir;
    Exit;
  end;

  Conn := GetConnection;
  Qry := TFDQuery.Create(nil);
  Script := TFDScript.Create(nil);
  try
    Qry.Connection := Conn;
    Script.Connection := Conn;

    // 1. Ensure SCHEMA_VERSION table exists
    try
      Qry.SQL.Text := 'SELECT COUNT(*) FROM SCHEMA_VERSION';
      Qry.Open;
    except
      // Create SCHEMA_VERSION if not exists
      Qry.Close;
      Qry.SQL.Text :=
        'CREATE TABLE SCHEMA_VERSION (' +
        '  VERSION_NUM INTEGER NOT NULL PRIMARY KEY,' +
        '  SCRIPT_NAME VARCHAR(100) NOT NULL,' +
        '  APPLIED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL' +
        ')';
      Qry.ExecSQL;
    end;
    Qry.Close;

    // 2. Discover migration files
    Files := TDirectory.GetFiles(AMigrationsDir, 'V*.sql');
    TArray.Sort<string>(Files);

    for F in Files do
    begin
      FileName := ExtractFileName(F);
      // Expected naming: V001__description.sql
      VerStr := Copy(FileName, 2, Pos('__', FileName) - 2);
      VerNum := StrToIntDef(VerStr, 0);

      if VerNum = 0 then
        Continue;

      // Check if already applied
      Qry.SQL.Text := 'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSION_NUM = :V';
      Qry.ParamByName('V').AsInteger := VerNum;
      Qry.Open;
      Applied := Qry.Fields[0].AsInteger > 0;
      Qry.Close;

      if not Applied then
      begin
        ALog := ALog + Format('Applying %s...', [FileName]) + sLineBreak;
        Script.SQLScripts.Clear;
        Script.SQLScripts.Add.SQL.LoadFromFile(F);
        Script.ExecuteAll;

        // Record version
        Qry.SQL.Text := 'INSERT INTO SCHEMA_VERSION (VERSION_NUM, SCRIPT_NAME) VALUES (:V, :N)';
        Qry.ParamByName('V').AsInteger := VerNum;
        Qry.ParamByName('N').AsString := FileName;
        Qry.ExecSQL;

        Inc(AAppliedCount);
        ALog := ALog + Format('Applied %s successfully.', [FileName]) + sLineBreak;
      end;
    end;

    Result := True;
  finally
    Script.Free;
    Qry.Free;
  end;
end;

initialization

finalization
  TDieVixConnectionManager.ReleaseInstance;

end.
