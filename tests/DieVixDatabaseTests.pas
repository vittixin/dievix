unit DieVixDatabaseTests;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  DUnitX Integration Test Suite: Firebird 5.0, FireDAC, Repositories & Services
  Operates on disposable test database: dievix_disposable_test.fdb
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.IniFiles,
  System.Generics.Collections,
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  FireDAC.Comp.UI,
  FireDAC.Comp.Script,
  FireDAC.UI.Intf,
  FireDAC.Stan.Factory,
  DieVix.CalculationEngine,
  DieVix.Domain,
  DieVix.ConnectionManager,
  DieVix.Repositories,
  DieVix.MasterDataService;

type
  [TestFixture]
  TDieVixDatabaseTests = class
  private
    FConn: TFDConnection;
    FService: TMasterDataService;
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FCylinderRepo: ICylinderRepository;
    FMachineRepo: IMachineRepository;
    FMachineCylinderRepo: IMachineCylinderRepository;
    FSettingRepo: IAppSettingRepository;
    FDieRepo: TDieRepository;
  public
    [SetupFixture]
    procedure SetupFixture;

    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure TestFireDACConnection;

    [Test]
    procedure TestFireDACWaitCursorRegistration;

    [Test]
    procedure TestCustomerTableExistsAndReadable;

    [Test]
    procedure TestCylinderFleetSeededSixteenSizes;

    [Test]
    procedure TestDuplicateCylinderTeethRejected;

    [Test]
    procedure TestCustomerCrudLifecycle;

    [Test]
    procedure TestDuplicateCustomerCodeRejected;

    [Test]
    procedure TestMediaCrudLifecycle;

    [Test]
    procedure TestMachineCrudAndValidation;

    [Test]
    procedure TestMachineCylinderAssignmentMatrix;

    [Test]
    procedure TestTransactionRollbackIntegrity;

    [Test]
    procedure TestExactNumericRoundTrip;

    [Test]
    procedure TestApplicationSettingsPersistence;

    [Test]
    procedure TestCylinderScaleAndPitchRepeat;

    [Test]
    procedure TestDieComputedColumnsUsePitchUm;

    [Test]
    procedure TestCatalogViewDynamicGapPolicyStatus;

    [Test]
    procedure TestApplyMigrationsToFreshDatabase;

    [Test]
    procedure TestMalformedMigrationFilenameRejected;

    [Test]
    procedure TestGapPolicyViewMatchesEngineCalculations;

    [Test]
    procedure TestMultiUpsGapPolicyViewMatchesEngine;

    [Test]
    procedure TestConsolidatedSchemaIncludesSchemaVersion;

    [Test]
    procedure TestMigrationRollbackOnFailure;

    [Test]
    procedure TestIsSafeTestDatabasePathGuard;

    [Test]
    procedure TestAuditSerialColumnAndBackfill;
  end;

implementation

{ TDieVixDatabaseTests }

procedure TDieVixDatabaseTests.SetupFixture;
var
  Mgr: TDieVixConnectionManager;
  AppCount: Integer;
  LogStr: string;
begin
  Mgr := TDieVixConnectionManager.Instance;
  FConn := Mgr.GetConnection;

  // Apply migrations to test database
  Mgr.ApplyMigrations(TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\migrations')), AppCount, LogStr);

  // Clean up any test dies from previous interrupted runs to ensure test hygiene
  FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-%'')');
  FConn.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-%''');

  FCustomerRepo := TCustomerRepository.Create(FConn);
  FMediaRepo := TMediaRepository.Create(FConn);
  FCylinderRepo := TCylinderRepository.Create(FConn);
  FMachineRepo := TMachineRepository.Create(FConn);
  FMachineCylinderRepo := TMachineCylinderRepository.Create(FConn);
  FSettingRepo := TAppSettingRepository.Create(FConn);
  FDieRepo := TDieRepository.Create(FConn);

  FService := TMasterDataService.Create(
    FCustomerRepo, FMediaRepo, nil, FCylinderRepo, FMachineRepo, FMachineCylinderRepo, FSettingRepo
  );
end;

procedure TDieVixDatabaseTests.TearDownFixture;
begin
  if Assigned(FConn) and FConn.Connected then
  begin
    try
      FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-%'')');
      FConn.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-%''');
    except
    end;
  end;
  FDieRepo.Free;
  FService.Free;
end;

procedure TDieVixDatabaseTests.TestFireDACConnection;
begin
  Assert.IsNotNull(FConn, 'Connection object must be allocated');
  Assert.IsTrue(FConn.Connected, 'FireDAC must be connected to Firebird 5');
end;

procedure TDieVixDatabaseTests.TestFireDACWaitCursorRegistration;
var
  Intf: IFDGUIxWaitCursor;
begin
  Assert.IsTrue(TDieVixConnectionManager.IsWaitCursorRegistered,
    'FireDAC wait cursor interface factory must be registered');
  Assert.IsNotNull(TDieVixConnectionManager.Instance.WaitCursor,
    'TDieVixConnectionManager must configure an active TFDGUIxWaitCursor instance');
  FDCreateInterface(IFDGUIxWaitCursor, Intf, True);
  Assert.IsNotNull(Intf, 'Wait cursor interface instance must be resolved by factory');
end;

procedure TDieVixDatabaseTests.TestCustomerTableExistsAndReadable;
var
  Custs: TList<TCustomer>;
begin
  Custs := FCustomerRepo.GetAll(False);
  try
    Assert.IsNotNull(Custs, 'Customer list must be allocated');
  finally
    Custs.Free;
  end;
end;

procedure TDieVixDatabaseTests.TestCylinderFleetSeededSixteenSizes;
var
  Cyls: TList<TCylinder>;
  Expected: TArray<Integer>;
  I: Integer;
begin
  Expected := [66, 68, 72, 76, 82, 86, 90, 94, 96, 98, 102, 106, 112, 120, 126, 132];
  Cyls := FService.GetAllCylinders(False);
  try
    Assert.AreEqual(16, Integer(Cyls.Count), 'Fleet must contain exactly 16 seeded sizes');
    for I := 0 to 15 do
    begin
      Assert.AreEqual(Expected[I], Cyls[I].Teeth, Format('Index %d must be %dT', [I, Expected[I]]));
      Assert.AreEqual(3175, Cyls[I].PitchUm, 'Default pitch must be 3175 um');
      Assert.IsTrue(Cyls[I].RepeatMm > 0.0, 'Repeat mm must be positive');
    end;
  finally
    Cyls.Free;
  end;
end;

procedure TDieVixDatabaseTests.TestDuplicateCylinderTeethRejected;
var
  DupCyl: TCylinder;
  ExceptionThrown: Boolean;
begin
  DupCyl := TCylinder.CreateNew(96, 3175);
  ExceptionThrown := False;
  try
    FService.SaveCylinder(DupCyl, True); // IsNew = True
  except
    on E: EDieVixValidationException do
      ExceptionThrown := True;
  end;

  Assert.IsTrue(ExceptionThrown, 'Inserting duplicate cylinder teeth must raise validation exception');
end;

procedure TDieVixDatabaseTests.TestCustomerCrudLifecycle;
var
  Cust: TCustomer;
  NewID: Integer;
  Fetched: TCustomer;
begin
  Cust := TCustomer.CreateNew('ZZTEST_CUST01', 'Test Customer Pvt Ltd');
  Cust.ContactPerson := 'John Doe';
  Cust.Phone := '+91 9876543210';
  Cust.City := 'Ahmedabad';

  NewID := FService.SaveCustomer(Cust);
  Assert.IsTrue(NewID > 0, 'Customer ID must be generated');

  Fetched := FCustomerRepo.GetByID(NewID);
  Assert.AreEqual('ZZTEST_CUST01', Fetched.Code);
  Assert.AreEqual('Test Customer Pvt Ltd', Fetched.Name);
  Assert.AreEqual('John Doe', Fetched.ContactPerson);

  // Update
  Fetched.ContactPerson := 'Jane Smith';
  FService.SaveCustomer(Fetched);

  Fetched := FCustomerRepo.GetByID(NewID);
  Assert.AreEqual('Jane Smith', Fetched.ContactPerson);

  // Clean up
  Assert.IsTrue(FService.DeleteCustomer(NewID), 'Delete must succeed');
end;

procedure TDieVixDatabaseTests.TestDuplicateCustomerCodeRejected;
var
  C1, C2: TCustomer;
  ID1: Integer;
  ExceptionThrown: Boolean;
begin
  C1 := TCustomer.CreateNew('DUP-CODE', 'First Company');
  ID1 := FService.SaveCustomer(C1);

  C2 := TCustomer.CreateNew('DUP-CODE', 'Second Company');
  ExceptionThrown := False;
  try
    FService.SaveCustomer(C2);
  except
    on E: EDieVixValidationException do
      ExceptionThrown := True;
  end;

  FService.DeleteCustomer(ID1);
  Assert.IsTrue(ExceptionThrown, 'Duplicate customer code must be rejected');
end;

procedure TDieVixDatabaseTests.TestMediaCrudLifecycle;
var
  M: TMedia;
  NewID: Integer;
  Fetched: TMedia;
begin
  M := TMedia.CreateNew('ZZTEST_POLY', 'Poly White Test Substrate');
  M.FaceMaterial := 'Polypropylene 50um';
  M.LinerMaterial := 'PET 23um';
  M.TotalCaliperUm := 85;

  NewID := FService.SaveMedia(M);
  Assert.IsTrue(NewID > 0, 'Media ID must be generated');

  Fetched := FMediaRepo.GetByID(NewID);
  Assert.AreEqual('ZZTEST_POLY', Fetched.Code);
  Assert.AreEqual(85, Fetched.TotalCaliperUm);

  Assert.IsTrue(FService.DeleteMedia(NewID));
end;

procedure TDieVixDatabaseTests.TestMachineCrudAndValidation;
var
  Mach: TMachine;
  NewID: Integer;
  InvalidMach: TMachine;
  ExceptionThrown: Boolean;
begin
  Mach := TMachine.CreateNew('ZZTEST_M01', 'Test Flexo 10"', 254.0);
  Mach.MinWebWidthMm := 60.0;
  Mach.DefaultMarginMm := 4.0;
  NewID := FService.SaveMachine(Mach);
  Assert.IsTrue(NewID > 0, 'Machine ID must be generated');

  // Test validation: max web < min web
  InvalidMach := TMachine.CreateNew('ZZTEST_ERR', 'Invalid Machine', 50.0);
  InvalidMach.MinWebWidthMm := 100.0; // Error: max < min
  ExceptionThrown := False;
  try
    FService.SaveMachine(InvalidMach);
  except
    on E: EDieVixValidationException do
      ExceptionThrown := True;
  end;
  Assert.IsTrue(ExceptionThrown, 'Max web width < Min web width must be rejected');

  FService.DeleteMachine(NewID);
end;

procedure TDieVixDatabaseTests.TestMachineCylinderAssignmentMatrix;
var
  Mach: TMachine;
  MachID: Integer;
  Assigned: TList<Integer>;
begin
  Mach := TMachine.CreateNew('MATRIX-M1', 'Matrix Press Test', 254.0);
  MachID := FService.SaveMachine(Mach);

  // Assign 66, 96, 112
  FService.SaveMachineCylinderAssignments(MachID, [66, 96, 112]);

  Assigned := FService.GetAssignedCylindersForMachine(MachID);
  try
    Assert.AreEqual(3, Integer(Assigned.Count));
    Assert.AreEqual(66, Assigned[0]);
    Assert.AreEqual(96, Assigned[1]);
    Assert.AreEqual(112, Assigned[2]);
  finally
    Assigned.Free;
  end;

  // Toggle off 66
  FService.ToggleAssignment(MachID, 66, False);
  Assert.IsFalse(FMachineCylinderRepo.IsAssigned(MachID, 66));
  Assert.IsTrue(FMachineCylinderRepo.IsAssigned(MachID, 96));

  FService.DeleteMachine(MachID);
end;

procedure TDieVixDatabaseTests.TestTransactionRollbackIntegrity;
var
  Cust: TCustomer;
  CheckCust: TCustomer;
begin
  FConn.StartTransaction;
  try
    Cust := TCustomer.CreateNew('ROLLBACK-CUST', 'Rollback Candidate');
    FCustomerRepo.Insert(Cust);
    // Explicit rollback
    FConn.Rollback;
  except
    FConn.Rollback;
  end;

  CheckCust := FCustomerRepo.GetByCode('ROLLBACK-CUST');
  Assert.AreEqual(0, CheckCust.ID, 'Record must not exist after transaction rollback');
end;

procedure TDieVixDatabaseTests.TestExactNumericRoundTrip;
var
  Mach: TMachine;
  MachID: Integer;
  Fetched: TMachine;
begin
  // NUMERIC(9,3) exact 3 decimal places
  Mach := TMachine.CreateNew('NUM-TEST', 'Numeric Precision Press', 330.125);
  Mach.MinWebWidthMm := 75.375;
  Mach.DefaultMarginMm := 4.875;
  MachID := FService.SaveMachine(Mach);

  Fetched := FMachineRepo.GetByID(MachID);
  Assert.AreEqual(330.125, Fetched.MaxWebWidthMm, 0.0001);
  Assert.AreEqual(75.375, Fetched.MinWebWidthMm, 0.0001);
  Assert.AreEqual(4.875, Fetched.DefaultMarginMm, 0.0001);

  FService.DeleteMachine(MachID);
end;

procedure TDieVixDatabaseTests.TestApplicationSettingsPersistence;
var
  MinGap: Int64;
  HardBlock: Int64;
begin
  MinGap := FService.GetMinAroundGapUm;
  Assert.AreEqual(Int64(3000), MinGap, 'Default min around gap must be 3000 um (3.0 mm)');

  HardBlock := FService.GetHardBlockGapUm;
  Assert.AreEqual(Int64(0), HardBlock, 'Default hard block must be 0 (disabled)');

  // Save new settings
  FService.SaveSettings(3500, 2000, 3.5, 2.5);
  Assert.AreEqual(Int64(3500), FService.GetMinAroundGapUm);
  Assert.AreEqual(Int64(2000), FService.GetHardBlockGapUm);
  Assert.AreEqual(3.5, FService.GetDefaultAcrossGapMm, 0.001);

  // Restore defaults
  FService.SaveSettings(3000, 0, 3.0, 2.0);
end;

procedure TDieVixDatabaseTests.TestCylinderScaleAndPitchRepeat;
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT REPEAT_MM, REPEAT_INCH FROM CYLINDER_SIZE WHERE TEETH = 66';
    Qry.Open;
    Assert.IsFalse(Qry.IsEmpty, '66T cylinder must exist');
    Assert.AreEqual(209.550, Qry.FieldByName('REPEAT_MM').AsFloat, 0.001, '66T repeat mm must be 209.550 (not truncated to 209.5)');
    Assert.AreEqual(8.250, Qry.FieldByName('REPEAT_INCH').AsFloat, 0.001, '66T repeat inch must be 8.250 (not truncated to 8.2)');
  finally
    Qry.Free;
  end;
end;

procedure TDieVixDatabaseTests.TestDieComputedColumnsUsePitchUm;
var
  Qry: TFDQuery;
  DieID: Integer;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    // Insert a die with custom pitch 3000 um on seeded 96T cylinder
    // (96 teeth * 3000 um = 288.000 mm, 3 ups of 94.0mm -> gap = (288 - 282)/3 = 2.000 mm)
    Qry.SQL.Text :=
      'INSERT INTO DIE (SERIAL_NO, TEETH, PITCH_UM, AROUND_SIZE_MM, ACROSS_SIZE_MM, AROUND_UPS, ACROSS_UPS, CREATED_BY) ' +
      'VALUES (''ZZTEST-PITCH-001'', 96, 3000, 94.000, 50.000, 3, 1, ''TEST'') ' +
      'RETURNING ID';
    Qry.Open;
    DieID := Qry.Fields[0].AsInteger;
    Qry.Close;

    // Verify computed columns evaluated with PITCH_UM (3000 um) rather than standard 3175 um
    Qry.SQL.Text := 'SELECT COMPUTED_REPEAT_MM, COMPUTED_AROUND_GAP_MM FROM DIE WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := DieID;
    Qry.Open;
    Assert.AreEqual(288.000, Qry.FieldByName('COMPUTED_REPEAT_MM').AsFloat, 0.001, 'Repeat must be 96 * 3000 / 1000 = 288.000 mm');
    Assert.AreEqual(2.000, Qry.FieldByName('COMPUTED_AROUND_GAP_MM').AsFloat, 0.001, 'Around gap must be (288 - 282) / 3 = 2.000 mm');
    Qry.Close;

    // Cleanup
    Qry.SQL.Text := 'DELETE FROM DIE WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := DieID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

procedure TDieVixDatabaseTests.TestCatalogViewDynamicGapPolicyStatus;
var
  Qry: TFDQuery;
  DieID: Integer;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    // Insert a test die with 2.800 mm gap (standard 96T, 3 ups of 98.8mm -> repeat 304.8mm, cut 296.4mm -> gap = 8.4/3 = 2.800 mm)
    Qry.SQL.Text :=
      'INSERT INTO DIE (SERIAL_NO, TEETH, PITCH_UM, AROUND_SIZE_MM, ACROSS_SIZE_MM, AROUND_UPS, ACROSS_UPS, CREATED_BY) ' +
      'VALUES (''ZZTEST-GAP-VIEW-TEST'', 96, 3175, 98.800, 50.000, 3, 1, ''TEST'') ' +
      'RETURNING ID';
    Qry.Open;
    DieID := Qry.Fields[0].AsInteger;
    Qry.Close;

    // With default MIN_AROUND_GAP_UM = 3000, 2.800 mm gap is WARNING_SUB3MM
    Qry.SQL.Text := 'SELECT GAP_POLICY_STATUS FROM V_DIE_CATALOG WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := DieID;
    Qry.Open;
    Assert.AreEqual('WARNING_SUB3MM', Qry.FieldByName('GAP_POLICY_STATUS').AsString);
    Qry.Close;

    // Temporarily set MIN_AROUND_GAP_UM = 2500 in APP_SETTING -> view should immediately show APPROVED
    Qry.SQL.Text := 'UPDATE APP_SETTING SET SETTING_VALUE = ''2500'' WHERE SETTING_KEY = ''MIN_AROUND_GAP_UM''';
    Qry.ExecSQL;

    Qry.SQL.Text := 'SELECT GAP_POLICY_STATUS FROM V_DIE_CATALOG WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := DieID;
    Qry.Open;
    Assert.AreEqual('APPROVED', Qry.FieldByName('GAP_POLICY_STATUS').AsString, 'View must dynamically reflect updated APP_SETTING');
    Qry.Close;

    // Restore setting
    Qry.SQL.Text := 'UPDATE APP_SETTING SET SETTING_VALUE = ''3000'' WHERE SETTING_KEY = ''MIN_AROUND_GAP_UM''';
    Qry.ExecSQL;

    // Cleanup
    Qry.SQL.Text := 'DELETE FROM DIE WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := DieID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

procedure TDieVixDatabaseTests.TestApplyMigrationsToFreshDatabase;
var
  FreshDbPath: string;
  FreshConn: TFDConnection;
  FreshMgr: TDieVixConnectionManager;
  FreshCfg: TDatabaseConfig;
  AppliedCount: Integer;
  LogText: string;
  Success: Boolean;
  Qry: TFDQuery;
  ExpectedVer: Integer;
  ActualVer: Integer;
  MigFiles: TArray<string>;
  TotalExpected: Integer;
begin
  FreshDbPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\tmp\dievix_fresh_migrations_test.fdb'));
  if FileExists(FreshDbPath) then
    DeleteFile(FreshDbPath);

  // Count existing migration files in migrations directory
  MigFiles := TDirectory.GetFiles('..\migrations', 'V*.sql');
  TotalExpected := Length(MigFiles);
  Assert.IsTrue(TotalExpected >= 5, 'Must have at least 5 migration files (V001..V005)');

  // Create fresh database via FireDAC OpenMode=CreateUTF8
  FreshConn := TFDConnection.Create(nil);
  try
    FreshConn.DriverName := 'FB';
    FreshConn.Params.Add('Protocol=TCPIP');
    FreshConn.Params.Add('Server=localhost');
    FreshConn.Params.Add('Port=3050');
    FreshConn.Params.Database := FreshDbPath;
    FreshConn.Params.UserName := 'SYSDBA';
    FreshConn.Params.Password := 'masterkey';
    FreshConn.Params.Add('CharacterSet=UTF8');
    FreshConn.Params.Add('OpenMode=Create');
    FreshConn.LoginPrompt := False;
    FreshConn.Open;
    FreshConn.Close;
  finally
    FreshConn.Free;
  end;

  // Run ApplyMigrations through a dedicated connection manager instance
  FreshMgr := TDieVixConnectionManager.Create;
  try
    FreshCfg := TDatabaseConfig.DefaultServer;
    FreshCfg.Database := FreshDbPath;
    FreshCfg.UserName := 'SYSDBA';
    FreshCfg.Password := 'masterkey';
    FreshCfg.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll';
    FreshMgr.Config := FreshCfg;

    Success := FreshMgr.ApplyMigrations('..\migrations', AppliedCount, LogText);
    Assert.IsTrue(Success, 'ApplyMigrations must succeed on fresh database. Log: ' + LogText);
    Assert.AreEqual(TotalExpected, AppliedCount, 'Applied count must match total migration files');

    // Query SCHEMA_VERSION and assert versions 1 to TotalExpected are each recorded exactly once
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := FreshMgr.GetConnection;
      Qry.SQL.Text := 'SELECT VERSION_NUM, SCRIPT_NAME FROM SCHEMA_VERSION ORDER BY VERSION_NUM';
      Qry.Open;
      Assert.AreEqual(TotalExpected, Qry.RecordCount, 'SCHEMA_VERSION row count must equal total migrations');

      ExpectedVer := 1;
      while not Qry.Eof do
      begin
        ActualVer := Qry.FieldByName('VERSION_NUM').AsInteger;
        Assert.AreEqual(ExpectedVer, ActualVer, Format('SCHEMA_VERSION sequence must have version %d', [ExpectedVer]));
        Inc(ExpectedVer);
        Qry.Next;
      end;
      Qry.Close;
    finally
      Qry.Free;
    end;

    // Second run: verify idempotency (0 applied)
    Success := FreshMgr.ApplyMigrations('..\migrations', AppliedCount, LogText);
    Assert.IsTrue(Success, 'Second run must succeed idempotently');
    Assert.AreEqual(0, AppliedCount, 'Second run must apply 0 migrations');
  finally
    FreshMgr.Free;
    if FileExists(FreshDbPath) then
      DeleteFile(FreshDbPath);
  end;
end;

procedure TDieVixDatabaseTests.TestMalformedMigrationFilenameRejected;
var
  TempDir: string;
  Mgr: TDieVixConnectionManager;
  AppliedCount: Integer;
  LogText: string;
  Success: Boolean;
begin
  TempDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'tmp_malformed_migrations');
  if DirectoryExists(TempDir) then
    TDirectory.Delete(TempDir, True);
  TDirectory.CreateDirectory(TempDir);
  try
    // Write a malformed migration file
    TFile.WriteAllText(TPath.Combine(TempDir, 'V_bad_migration.sql'), 'SELECT 1 FROM RDB$DATABASE;');

    Mgr := TDieVixConnectionManager.Create;
    try
      Mgr.Config := TDieVixConnectionManager.Instance.Config;
      Success := Mgr.ApplyMigrations(TempDir, AppliedCount, LogText);
      Assert.IsFalse(Success, 'ApplyMigrations must return False when a migration file name is malformed');
      Assert.IsTrue(Pos('V_bad_migration.sql', LogText) > 0, 'ALog must report the malformed file name');
    finally
      Mgr.Free;
    end;
  finally
    if DirectoryExists(TempDir) then
      TDirectory.Delete(TempDir, True);
  end;
end;

procedure TDieVixDatabaseTests.TestGapPolicyViewMatchesEngineCalculations;
var
  Qry: TFDQuery;
  CustID, MediaID: Integer;
  DieID1, DieID2, DieID3, DieID4: Integer;
  EngRes1, EngRes2, EngRes3, EngRes4: TGapResult;
  ViewStatus: string;

  function StatusToStr(AStatus: TGapStatus): string;
  begin
    case AStatus of
      gsStandardApproved: Result := 'APPROVED';
      gsSubStandardWarning: Result := 'WARNING_SUB3MM';
      gsMechanicallyRejected: Result := 'REJECTED_MECHANICAL';
    else
      Result := 'UNKNOWN';
    end;
  end;

  function InsertTestDie(const ASerial: string; const AAroundSize: Double): Integer;
  begin
    Qry.SQL.Text :=
      'INSERT INTO DIE (SERIAL_NO, CUSTOMER_ID, MEDIA_ID, TEETH, AROUND_SIZE_MM, ACROSS_SIZE_MM, ' +
      '                 AROUND_UPS, ACROSS_UPS, STATUS_CODE, PITCH_UM) ' +
      'VALUES (:SERIAL, :CUST, :MEDIA, 66, :AROUND, 50.0, 1, 1, ''AVAILABLE'', 3175) ' +
      'RETURNING ID';
    Qry.ParamByName('SERIAL').AsString := ASerial;
    Qry.ParamByName('CUST').AsInteger := CustID;
    Qry.ParamByName('MEDIA').AsInteger := MediaID;
    Qry.ParamByName('AROUND').AsFloat := AAroundSize;
    Qry.Open;
    Result := Qry.Fields[0].AsInteger;
    Qry.Close;
  end;

begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;

    Qry.SQL.Text := 'SELECT FIRST 1 ID FROM CUSTOMER WHERE IS_ACTIVE = 1';
    Qry.Open;
    if not Qry.IsEmpty then
      CustID := Qry.Fields[0].AsInteger
    else
      CustID := 1;
    Qry.Close;

    Qry.SQL.Text := 'SELECT FIRST 1 ID FROM MEDIA';
    Qry.Open;
    if not Qry.IsEmpty then
      MediaID := Qry.Fields[0].AsInteger
    else
      MediaID := 1;
    Qry.Close;

    // Clean up any test dies
    Qry.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-GAP-%'')');
    Qry.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-GAP-%''');

    // 66T repeat = 66 * 3.175 = 209.550 mm
    // Die 1: Around size 205.0 mm -> Gap = 4.550 mm (>= 3.0 mm min -> APPROVED)
    DieID1 := InsertTestDie('ZZTEST-GAP-1-APP', 205.0);
    // Die 2: Around size 207.0 mm -> Gap = 2.550 mm (between 2.0 mm hard and 3.0 mm min -> WARNING_SUB3MM)
    DieID2 := InsertTestDie('ZZTEST-GAP-2-WARN', 207.0);
    // Die 3: Around size 208.5 mm -> Gap = 1.050 mm (< 2.0 mm hard -> REJECTED when hard > 0, WARNING when hard = 0)
    DieID3 := InsertTestDie('ZZTEST-GAP-3-HARD', 208.5);
    // Die 4: Around size 215.0 mm -> Gap = -5.450 mm (< 0 -> REJECTED_MECHANICAL always)
    DieID4 := InsertTestDie('ZZTEST-GAP-4-NEG', 215.0);

    try
      // CONFIGURATION 1: MIN_AROUND_GAP_UM = 3000, HARD_BLOCK_GAP_UM = 2000 (2.0 mm)
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''3000'' WHERE SETTING_KEY = ''MIN_AROUND_GAP_UM''');
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''2000'' WHERE SETTING_KEY = ''HARD_BLOCK_GAP_UM''');

      EngRes1 := CalculateAroundGap(66, MmToUm(205.0), 1, 3000, 2000, 3175);
      EngRes2 := CalculateAroundGap(66, MmToUm(207.0), 1, 3000, 2000, 3175);
      EngRes3 := CalculateAroundGap(66, MmToUm(208.5), 1, 3000, 2000, 3175);
      EngRes4 := CalculateAroundGap(66, MmToUm(215.0), 1, 3000, 2000, 3175);

      Qry.SQL.Text := 'SELECT GAP_POLICY_STATUS FROM V_DIE_CATALOG WHERE ID = :ID';

      // Verify Die 1 under Config 1 -> APPROVED
      Qry.ParamByName('ID').AsInteger := DieID1;
      Qry.Open;
      ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
      Qry.Close;
      Assert.AreEqual(StatusToStr(EngRes1.Status), ViewStatus, 'Config 1: Die 1 view status must match engine');
      Assert.AreEqual('APPROVED', ViewStatus);

      // Verify Die 2 under Config 1 -> WARNING_SUB3MM
      Qry.ParamByName('ID').AsInteger := DieID2;
      Qry.Open;
      ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
      Qry.Close;
      Assert.AreEqual(StatusToStr(EngRes2.Status), ViewStatus, 'Config 1: Die 2 view status must match engine');
      Assert.AreEqual('WARNING_SUB3MM', ViewStatus);

      // Verify Die 3 under Config 1 -> REJECTED_MECHANICAL
      Qry.ParamByName('ID').AsInteger := DieID3;
      Qry.Open;
      ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
      Qry.Close;
      Assert.AreEqual(StatusToStr(EngRes3.Status), ViewStatus, 'Config 1: Die 3 view status must match engine');
      Assert.AreEqual('REJECTED_MECHANICAL', ViewStatus);

      // Verify Die 4 under Config 1 -> REJECTED_MECHANICAL
      Qry.ParamByName('ID').AsInteger := DieID4;
      Qry.Open;
      ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
      Qry.Close;
      Assert.AreEqual(StatusToStr(EngRes4.Status), ViewStatus, 'Config 1: Die 4 view status must match engine');
      Assert.AreEqual('REJECTED_MECHANICAL', ViewStatus);

      // CONFIGURATION 2: MIN_AROUND_GAP_UM = 3000, HARD_BLOCK_GAP_UM = 0 (disabled)
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''3000'' WHERE SETTING_KEY = ''MIN_AROUND_GAP_UM''');
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''0'' WHERE SETTING_KEY = ''HARD_BLOCK_GAP_UM''');

      EngRes1 := CalculateAroundGap(66, MmToUm(205.0), 1, 3000, 0, 3175);
      EngRes2 := CalculateAroundGap(66, MmToUm(207.0), 1, 3000, 0, 3175);
      EngRes3 := CalculateAroundGap(66, MmToUm(208.5), 1, 3000, 0, 3175);
      EngRes4 := CalculateAroundGap(66, MmToUm(215.0), 1, 3000, 0, 3175);

      Qry.SQL.Text := 'SELECT GAP_POLICY_STATUS FROM V_DIE_CATALOG WHERE ID = :ID';

      // Verify Die 1 under Config 2 -> APPROVED
      Qry.ParamByName('ID').AsInteger := DieID1;
      Qry.Open;
      ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
      Qry.Close;
      Assert.AreEqual(StatusToStr(EngRes1.Status), ViewStatus, 'Config 2: Die 1 view status must match engine');
      Assert.AreEqual('APPROVED', ViewStatus);

      // Verify Die 2 under Config 2 -> WARNING_SUB3MM
      Qry.ParamByName('ID').AsInteger := DieID2;
      Qry.Open;
      ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
      Qry.Close;
      Assert.AreEqual(StatusToStr(EngRes2.Status), ViewStatus, 'Config 2: Die 2 view status must match engine');
      Assert.AreEqual('WARNING_SUB3MM', ViewStatus);

      // Verify Die 3 under Config 2 -> WARNING_SUB3MM (hard block disabled!)
      Qry.ParamByName('ID').AsInteger := DieID3;
      Qry.Open;
      ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
      Qry.Close;
      Assert.AreEqual(StatusToStr(EngRes3.Status), ViewStatus, 'Config 2: Die 3 view status must match engine');
      Assert.AreEqual('WARNING_SUB3MM', ViewStatus);

      // Verify Die 4 under Config 2 -> REJECTED_MECHANICAL (negative gap)
      Qry.ParamByName('ID').AsInteger := DieID4;
      Qry.Open;
      ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
      Qry.Close;
      Assert.AreEqual(StatusToStr(EngRes4.Status), ViewStatus, 'Config 2: Die 4 view status must match engine');
      Assert.AreEqual('REJECTED_MECHANICAL', ViewStatus);
    finally
      // Restore default settings
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''3000'' WHERE SETTING_KEY = ''MIN_AROUND_GAP_UM''');
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''0'' WHERE SETTING_KEY = ''HARD_BLOCK_GAP_UM''');
      Qry.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-GAP-%'')');
      Qry.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-GAP-%''');
    end;
  finally
    Qry.Free;
  end;
end;

procedure TDieVixDatabaseTests.TestConsolidatedSchemaIncludesSchemaVersion;
var
  FreshDbPath: string;
  FreshConn: TFDConnection;
  Script: TFDScript;
  FreshMgr: TDieVixConnectionManager;
  FreshCfg: TDatabaseConfig;
  AppliedCount: Integer;
  LogText: string;
  Success: Boolean;
  ConsolidatedPath: string;
begin
  FreshDbPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\tmp\dievix_consolidated_schema_test.fdb'));
  if FileExists(FreshDbPath) then
    DeleteFile(FreshDbPath);

  ConsolidatedPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\src\Database\DieVix_Schema_Firebird5.sql'));
  Assert.IsTrue(FileExists(ConsolidatedPath), 'Consolidated schema file must exist');

  FreshConn := TFDConnection.Create(nil);
  try
    FreshConn.DriverName := 'FB';
    FreshConn.Params.Add('Protocol=TCPIP');
    FreshConn.Params.Add('Server=localhost');
    FreshConn.Params.Add('Port=3050');
    FreshConn.Params.Database := FreshDbPath;
    FreshConn.Params.UserName := 'SYSDBA';
    FreshConn.Params.Password := 'masterkey';
    FreshConn.Params.Add('CharacterSet=UTF8');
    FreshConn.Params.Add('OpenMode=Create');
    FreshConn.LoginPrompt := False;
    FreshConn.Open;
    FreshConn.Close;
  finally
    FreshConn.Free;
  end;

  FreshMgr := TDieVixConnectionManager.Create;
  try
    FreshCfg := TDatabaseConfig.DefaultServer;
    FreshCfg.Database := FreshDbPath;
    FreshCfg.UserName := 'SYSDBA';
    FreshCfg.Password := 'masterkey';
    FreshCfg.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll';
    FreshMgr.Config := FreshCfg;

    FreshConn := FreshMgr.GetConnection;
    Script := TFDScript.Create(nil);
    try
      Script.Connection := FreshConn;
      Script.ScriptOptions.BreakOnError := True;
      Script.SQLScripts.Add.SQL.LoadFromFile(ConsolidatedPath);
      Assert.IsTrue(Script.ExecuteAll, 'Consolidated schema script execution must succeed');
    finally
      Script.Free;
    end;

    // Reset connection so transaction state is completely clean after internal script COMMITs
    FreshConn.Connected := False;

    Success := FreshMgr.ApplyMigrations(
      TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\migrations')),
      AppliedCount, LogText
    );
    Assert.IsTrue(Success, 'ApplyMigrations must return True. Log: ' + LogText);
    Assert.AreEqual(0, AppliedCount, 'ApplyMigrations must apply 0 migrations because consolidated schema pre-populates SCHEMA_VERSION');
  finally
    FreshMgr.Free;
    if FileExists(FreshDbPath) then
      DeleteFile(FreshDbPath);
  end;
end;

procedure TDieVixDatabaseTests.TestMigrationRollbackOnFailure;
var
  TempMigDir: string;
  FreshDbPath: string;
  FreshConn: TFDConnection;
  FreshMgr: TDieVixConnectionManager;
  FreshCfg: TDatabaseConfig;
  AppliedCount: Integer;
  LogText: string;
  Success: Boolean;
  Qry: TFDQuery;

  function TableExists(AConn: TFDConnection; const ATableName: string): Boolean;
  var
    Q: TFDQuery;
  begin
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text := 'SELECT COUNT(*) FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = :NAME';
      Q.ParamByName('NAME').AsString := UpperCase(ATableName);
      Q.Open;
      Result := Q.Fields[0].AsInteger > 0;
      Q.Close;
    finally
      Q.Free;
    end;
  end;

begin
  FreshDbPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\tmp\dievix_rollback_test.fdb'));
  if FileExists(FreshDbPath) then
    DeleteFile(FreshDbPath);

  TempMigDir := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\tmp\test_rollback_migrations'));
  if TDirectory.Exists(TempMigDir) then
    TDirectory.Delete(TempMigDir, True);
  TDirectory.CreateDirectory(TempMigDir);

  // Migration 1: Valid schema creating SCHEMA_VERSION and TEST_ROLLBACK_TABLE_A
  TFile.WriteAllText(TPath.Combine(TempMigDir, 'V001__valid_table_a.sql'),
    'CREATE TABLE SCHEMA_VERSION (VERSION_NUM INTEGER NOT NULL PRIMARY KEY, SCRIPT_NAME VARCHAR(100) NOT NULL, APPLIED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL);' + sLineBreak +
    'CREATE TABLE TEST_ROLLBACK_TABLE_A (ID INTEGER PRIMARY KEY);'
  );

  // Migration 2: Deliberately broken script creating partial table then invalid syntax
  TFile.WriteAllText(TPath.Combine(TempMigDir, 'V002__broken_table_b.sql'),
    'CREATE TABLE TEST_ROLLBACK_PARTIAL (ID INTEGER PRIMARY KEY);' + sLineBreak +
    'INVALID SQL SYNTAX THAT CANNOT PARSE;'
  );

  // Migration 3: Third valid migration that should NOT be executed
  TFile.WriteAllText(TPath.Combine(TempMigDir, 'V003__third_valid_table_c.sql'),
    'CREATE TABLE TEST_ROLLBACK_TABLE_C (ID INTEGER PRIMARY KEY);'
  );

  FreshConn := TFDConnection.Create(nil);
  try
    FreshConn.DriverName := 'FB';
    FreshConn.Params.Add('Protocol=TCPIP');
    FreshConn.Params.Add('Server=localhost');
    FreshConn.Params.Add('Port=3050');
    FreshConn.Params.Database := FreshDbPath;
    FreshConn.Params.UserName := 'SYSDBA';
    FreshConn.Params.Password := 'masterkey';
    FreshConn.Params.Add('CharacterSet=UTF8');
    FreshConn.Params.Add('OpenMode=Create');
    FreshConn.LoginPrompt := False;
    FreshConn.Open;
    FreshConn.Close;
  finally
    FreshConn.Free;
  end;

  FreshMgr := TDieVixConnectionManager.Create;
  try
    FreshCfg := TDatabaseConfig.DefaultServer;
    FreshCfg.Database := FreshDbPath;
    FreshCfg.UserName := 'SYSDBA';
    FreshCfg.Password := 'masterkey';
    FreshCfg.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll';
    FreshMgr.Config := FreshCfg;

    Success := FreshMgr.ApplyMigrations(TempMigDir, AppliedCount, LogText);

    Assert.IsFalse(Success, 'ApplyMigrations must return False when a script fails');
    Assert.IsTrue(Pos('V002__broken_table_b.sql', LogText) > 0,
      'LogText must clearly state failing filename. Log: ' + LogText);
    Assert.AreEqual(1, AppliedCount, 'Only 1 migration (V001) should have been recorded as applied');

    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := FreshMgr.GetConnection;

      Assert.IsTrue(TableExists(FreshMgr.GetConnection, 'TEST_ROLLBACK_TABLE_A'), 'Table A must exist');
      Qry.SQL.Text := 'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSION_NUM = 1';
      Qry.Open;
      Assert.AreEqual(1, Qry.Fields[0].AsInteger, 'Version 1 must be recorded in SCHEMA_VERSION');
      Qry.Close;

      Assert.IsFalse(TableExists(FreshMgr.GetConnection, 'TEST_ROLLBACK_PARTIAL'),
        'TEST_ROLLBACK_PARTIAL must not exist (must have been rolled back atomically)');
      Qry.SQL.Text := 'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSION_NUM = 2';
      Qry.Open;
      Assert.AreEqual(0, Qry.Fields[0].AsInteger, 'Version 2 must NOT be in SCHEMA_VERSION');
      Qry.Close;

      Assert.IsFalse(TableExists(FreshMgr.GetConnection, 'TEST_ROLLBACK_TABLE_C'),
        'TEST_ROLLBACK_TABLE_C must not exist (execution must stop on failure)');
      Qry.SQL.Text := 'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSION_NUM = 3';
      Qry.Open;
      Assert.AreEqual(0, Qry.Fields[0].AsInteger, 'Version 3 must NOT be in SCHEMA_VERSION');
      Qry.Close;
    finally
      Qry.Free;
    end;
  finally
    FreshMgr.Free;
    if TDirectory.Exists(TempMigDir) then
      TDirectory.Delete(TempMigDir, True);
    if FileExists(FreshDbPath) then
      DeleteFile(FreshDbPath);
  end;
end;

procedure TDieVixDatabaseTests.TestIsSafeTestDatabasePathGuard;
var
  Reason: string;
  TempAppIni: string;
  Ini: TIniFile;
begin
  // 1. Empty path must be rejected
  Assert.IsFalse(IsSafeTestDatabasePath('', '', Reason), 'Empty path must be rejected');
  Assert.IsTrue(Pos('empty', LowerCase(Reason)) > 0, 'Reason must mention empty');

  // 2. Path without 'disposable' or 'test' must be rejected
  Assert.IsFalse(IsSafeTestDatabasePath('C:\Production\DieVix.fdb', '', Reason),
    'Path without test/disposable must be rejected');
  Assert.IsTrue(Pos('does not contain', LowerCase(Reason)) > 0, 'Reason must mention missing keyword');

  // 3. Path with 'test' or 'disposable' (case-insensitive) without app ini must be accepted
  Assert.IsTrue(IsSafeTestDatabasePath('C:\Data\my_test_database.fdb', '', Reason),
    'Filename containing "test" must be accepted');
  Assert.IsTrue(IsSafeTestDatabasePath('D:\Temp\DISPOSABLE_RUN.FDB', '', Reason),
    'Filename containing "DISPOSABLE" must be accepted');

  // 4. Collision with application database in DieVix.ini must be rejected
  TempAppIni := TPath.Combine(TPath.GetTempPath, 'TestAppGuard_' + TGUID.NewGuid.ToString + '.ini');
  try
    Ini := TIniFile.Create(TempAppIni);
    try
      Ini.WriteString('Database', 'Database', 'C:\DieVix\Data\dievix_test.fdb');
    finally
      Ini.Free;
    end;

    // Matching filename must be rejected
    Assert.IsFalse(IsSafeTestDatabasePath('C:\DieVix\Data\dievix_test.fdb', TempAppIni, Reason),
      'Exact matching database path must be rejected');
    Assert.IsTrue(Pos('matches application database', LowerCase(Reason)) > 0);

    // Matching filename in different directory must also be rejected
    Assert.IsFalse(IsSafeTestDatabasePath('D:\OtherDir\dievix_test.fdb', TempAppIni, Reason),
      'Matching database filename must be rejected');

    // Distinct test database filename must be accepted
    Assert.IsTrue(IsSafeTestDatabasePath('D:\OtherDir\dievix_disposable_separate.fdb', TempAppIni, Reason),
      'Distinct test database filename must be accepted');
  finally
    if FileExists(TempAppIni) then
      DeleteFile(TempAppIni);
  end;
end;

procedure TDieVixDatabaseTests.TestMultiUpsGapPolicyViewMatchesEngine;
var
  Qry: TFDQuery;
  CustID, MediaID: Integer;
  DieIDs: array[1..14] of Integer;

  function StatusToStr(const AStatus: TGapStatus): string;
  begin
    case AStatus of
      gsStandardApproved: Result := 'APPROVED';
      gsSubStandardWarning: Result := 'WARNING_SUB3MM';
      gsMechanicallyRejected: Result := 'REJECTED_MECHANICAL';
    else
      Result := 'UNKNOWN';
    end;
  end;

  function InsertMultiUpsDie(const ASerial: string; const ATeeth, AUps: Integer; const AAroundSize: Double): Integer;
  begin
    Qry.SQL.Text :=
      'INSERT INTO DIE (SERIAL_NO, CUSTOMER_ID, MEDIA_ID, TEETH, AROUND_SIZE_MM, ACROSS_SIZE_MM, ' +
      '                 AROUND_UPS, ACROSS_UPS, STATUS_CODE, PITCH_UM) ' +
      'VALUES (:SERIAL, :CUST, :MEDIA, :TEETH, :AROUND, 50.0, :UPS, 1, ''AVAILABLE'', 3175) ' +
      'RETURNING ID';
    Qry.ParamByName('SERIAL').AsString := ASerial;
    Qry.ParamByName('CUST').AsInteger := CustID;
    Qry.ParamByName('MEDIA').AsInteger := MediaID;
    Qry.ParamByName('TEETH').AsInteger := ATeeth;
    Qry.ParamByName('AROUND').AsFloat := AAroundSize;
    Qry.ParamByName('UPS').AsInteger := AUps;
    Qry.Open;
    Result := Qry.Fields[0].AsInteger;
    Qry.Close;
  end;

  procedure VerifyDie(const ADieID, ATeeth, AUps: Integer; const AAroundSize: Double; const AMinUm, AHardUm: Int64; const AConfigName: string);
  var
    EngRes: TGapResult;
    ViewStatus: string;
  begin
    EngRes := CalculateAroundGap(ATeeth, MmToUm(AAroundSize), AUps, AMinUm, AHardUm, 3175);
    Qry.SQL.Text := 'SELECT GAP_POLICY_STATUS FROM V_DIE_CATALOG WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := ADieID;
    Qry.Open;
    ViewStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;
    Qry.Close;
    Assert.AreEqual(StatusToStr(EngRes.Status), ViewStatus,
      Format('%s: Die %d (Teeth=%d, Ups=%d, Size=%.3f) View status must match Engine',
        [AConfigName, ADieID, ATeeth, AUps, AAroundSize]));
  end;

begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;

    Qry.SQL.Text := 'SELECT FIRST 1 ID FROM CUSTOMER WHERE IS_ACTIVE = 1';
    Qry.Open;
    if not Qry.IsEmpty then
      CustID := Qry.Fields[0].AsInteger
    else
      CustID := 1;
    Qry.Close;

    Qry.SQL.Text := 'SELECT FIRST 1 ID FROM MEDIA';
    Qry.Open;
    if not Qry.IsEmpty then
      MediaID := Qry.Fields[0].AsInteger
    else
      MediaID := 1;
    Qry.Close;

    // Clean up any test dies
    Qry.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-MULTI-%'')');
    Qry.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-MULTI-%''');

    // AROUND_UPS = 3
    // Min gap threshold = 3.000 mm -> pool threshold = 9.000 mm
    // Die 1: 96T, 3 ups, 98.600 mm -> repeat 304.800, 3*98.600=295.800 -> Pool = 9.000 mm (APPROVED)
    DieIDs[1] := InsertMultiUpsDie('ZZTEST-MULTI-3-9000', 96, 3, 98.600);
    // Die 2: 98T, 3 ups, 100.717 mm -> repeat 311.150, 3*100.717=302.151 -> Pool = 8.999 mm (WARNING)
    DieIDs[2] := InsertMultiUpsDie('ZZTEST-MULTI-3-8999', 98, 3, 100.717);
    // Die 3: 94T, 3 ups, 96.484 mm -> repeat 298.450, 3*96.484=289.452 -> Pool = 8.998 mm (WARNING)
    DieIDs[3] := InsertMultiUpsDie('ZZTEST-MULTI-3-8998', 94, 3, 96.484);

    // Hard block threshold = 2.000 mm -> pool threshold = 6.000 mm
    // Die 4: 96T, 3 ups, 99.600 mm -> repeat 304.800, 3*99.600=298.800 -> Pool = 6.000 mm (WARNING)
    DieIDs[4] := InsertMultiUpsDie('ZZTEST-MULTI-3-6000', 96, 3, 99.600);
    // Die 5: 98T, 3 ups, 101.717 mm -> repeat 311.150, 3*101.717=305.151 -> Pool = 5.999 mm (REJECTED in Cfg1, WARN in Cfg2)
    DieIDs[5] := InsertMultiUpsDie('ZZTEST-MULTI-3-5999', 98, 3, 101.717);
    // Die 6: 94T, 3 ups, 97.484 mm -> repeat 298.450, 3*97.484=292.452 -> Pool = 5.998 mm (REJECTED in Cfg1, WARN in Cfg2)
    DieIDs[6] := InsertMultiUpsDie('ZZTEST-MULTI-3-5998', 94, 3, 97.484);

    // AROUND_UPS = 2
    // Min gap threshold = 3.000 mm -> pool threshold = 6.000 mm
    // Die 7: 96T, 2 ups, 149.400 mm -> repeat 304.800, 2*149.400=298.800 -> Pool = 6.000 mm (APPROVED)
    DieIDs[7] := InsertMultiUpsDie('ZZTEST-MULTI-2-6000', 96, 2, 149.400);
    // Die 8: 98T, 2 ups, 152.576 mm -> repeat 311.150, 2*152.576=305.152 -> Pool = 5.998 mm (WARNING)
    DieIDs[8] := InsertMultiUpsDie('ZZTEST-MULTI-2-5999', 98, 2, 152.576);
    // Hard block threshold = 2.000 mm -> pool threshold = 4.000 mm
    // Die 9: 96T, 2 ups, 150.400 mm -> repeat 304.800, 2*150.400=300.800 -> Pool = 4.000 mm (WARNING)
    DieIDs[9] := InsertMultiUpsDie('ZZTEST-MULTI-2-4000', 96, 2, 150.400);
    // Die 10: 98T, 2 ups, 153.576 mm -> repeat 311.150, 2*153.576=307.152 -> Pool = 3.998 mm (REJECTED in Cfg1, WARN in Cfg2)
    DieIDs[10] := InsertMultiUpsDie('ZZTEST-MULTI-2-3999', 98, 2, 153.576);

    // AROUND_UPS = 4
    // Min gap threshold = 3.000 mm -> pool threshold = 12.000 mm
    // Die 11: 96T, 4 ups, 73.200 mm -> repeat 304.800, 4*73.200=292.800 -> Pool = 12.000 mm (APPROVED)
    DieIDs[11] := InsertMultiUpsDie('ZZTEST-MULTI-4-12000', 96, 4, 73.200);
    // Die 12: 98T, 4 ups, 74.788 mm -> repeat 311.150, 4*74.788=299.152 -> Pool = 11.998 mm (WARNING)
    DieIDs[12] := InsertMultiUpsDie('ZZTEST-MULTI-4-11999', 98, 4, 74.788);
    // Hard block threshold = 2.000 mm -> pool threshold = 8.000 mm
    // Die 13: 96T, 4 ups, 74.200 mm -> repeat 304.800, 4*74.200=296.800 -> Pool = 8.000 mm (WARNING)
    DieIDs[13] := InsertMultiUpsDie('ZZTEST-MULTI-4-8000', 96, 4, 74.200);
    // Die 14: 98T, 4 ups, 75.788 mm -> repeat 311.150, 4*75.788=303.152 -> Pool = 7.998 mm (REJECTED in Cfg1, WARN in Cfg2)
    DieIDs[14] := InsertMultiUpsDie('ZZTEST-MULTI-4-7999', 98, 4, 75.788);

    try
      // CONFIGURATION 1: MIN_AROUND_GAP_UM = 3000, HARD_BLOCK_GAP_UM = 2000
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''3000'' WHERE SETTING_KEY = ''MIN_AROUND_GAP_UM''');
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''2000'' WHERE SETTING_KEY = ''HARD_BLOCK_GAP_UM''');

      VerifyDie(DieIDs[1], 96, 3, 98.600, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[2], 98, 3, 100.717, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[3], 94, 3, 96.484, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[4], 96, 3, 99.600, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[5], 98, 3, 101.717, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[6], 94, 3, 97.484, 3000, 2000, 'Config 1');

      VerifyDie(DieIDs[7], 96, 2, 149.400, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[8], 98, 2, 152.576, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[9], 96, 2, 150.400, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[10], 98, 2, 153.576, 3000, 2000, 'Config 1');

      VerifyDie(DieIDs[11], 96, 4, 73.200, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[12], 98, 4, 74.788, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[13], 96, 4, 74.200, 3000, 2000, 'Config 1');
      VerifyDie(DieIDs[14], 98, 4, 75.788, 3000, 2000, 'Config 1');

      // CONFIGURATION 2: MIN_AROUND_GAP_UM = 3000, HARD_BLOCK_GAP_UM = 0 (disabled)
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''3000'' WHERE SETTING_KEY = ''MIN_AROUND_GAP_UM''');
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''0'' WHERE SETTING_KEY = ''HARD_BLOCK_GAP_UM''');

      VerifyDie(DieIDs[1], 96, 3, 98.600, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[2], 98, 3, 100.717, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[3], 94, 3, 96.484, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[4], 96, 3, 99.600, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[5], 98, 3, 101.717, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[6], 94, 3, 97.484, 3000, 0, 'Config 2');

      VerifyDie(DieIDs[7], 96, 2, 149.400, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[8], 98, 2, 152.576, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[9], 96, 2, 150.400, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[10], 98, 2, 153.576, 3000, 0, 'Config 2');

      VerifyDie(DieIDs[11], 96, 4, 73.200, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[12], 98, 4, 74.788, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[13], 96, 4, 74.200, 3000, 0, 'Config 2');
      VerifyDie(DieIDs[14], 98, 4, 75.788, 3000, 0, 'Config 2');
    finally
      // Restore settings
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''3000'' WHERE SETTING_KEY = ''MIN_AROUND_GAP_UM''');
      Qry.ExecSQL('UPDATE APP_SETTING SET SETTING_VALUE = ''0'' WHERE SETTING_KEY = ''HARD_BLOCK_GAP_UM''');
      Qry.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-MULTI-%'')');
      Qry.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-MULTI-%''');
    end;
  finally
    Qry.Free;
  end;
end;

procedure TDieVixDatabaseTests.TestAuditSerialColumnAndBackfill;
var
  Qry: TFDQuery;
  DieID: Integer;
  Die: TDie;
  Log: TList<TDieAuditEntry>;
  AuditID: Integer;
  ValidCustID, ValidMediaID: Integer;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT FIRST 1 ID FROM CUSTOMER';
    Qry.Open;
    ValidCustID := Qry.Fields[0].AsInteger;
    Qry.Close;

    Qry.SQL.Text := 'SELECT FIRST 1 ID FROM MEDIA';
    Qry.Open;
    ValidMediaID := Qry.Fields[0].AsInteger;
    Qry.Close;

    // 1. Create a die and verify new audit row carries serial number in DIE_SERIAL_NO
    Die := TDie.CreateNew('ZZTEST-AUDIT-COL-001', 96, 98.0, 50.0, 3, 2);
    Die.CustomerID := ValidCustID;
    Die.MediaID := ValidMediaID;
    DieID := FDieRepo.Insert(Die);
  finally
    Qry.Free;
  end;
  try
    Assert.IsTrue(DieID > 0, 'Die record must be created');

    // Assert DIE_SERIAL_NO column is populated directly in DIE_AUDIT_LOG
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := FConn;
      Qry.SQL.Text := 'SELECT DIE_SERIAL_NO FROM DIE_AUDIT_LOG WHERE DIE_ID = :ID AND ACTION = ''CREATE''';
      Qry.ParamByName('ID').AsInteger := DieID;
      Qry.Open;
      Assert.IsFalse(Qry.IsEmpty, 'CREATE audit row must exist');
      Assert.AreEqual('ZZTEST-AUDIT-COL-001', Qry.FieldByName('DIE_SERIAL_NO').AsString,
        'DIE_SERIAL_NO column must be populated on audit insert');
      Qry.Close;

      // 2. Perform actions (Status Change) and assert DIE_SERIAL_NO is populated
      FDieRepo.ChangeStatus(DieID, 'REPAIR', 'Testing audit column', 'TESTER');
      Qry.SQL.Text := 'SELECT DIE_SERIAL_NO FROM DIE_AUDIT_LOG WHERE DIE_ID = :ID AND ACTION = ''STATUS_CHANGE''';
      Qry.ParamByName('ID').AsInteger := DieID;
      Qry.Open;
      Assert.AreEqual('ZZTEST-AUDIT-COL-001', Qry.FieldByName('DIE_SERIAL_NO').AsString,
        'STATUS_CHANGE audit row must carry DIE_SERIAL_NO');
      Qry.Close;

      // 3. Test backfill: Insert an audit row with NULL DIE_SERIAL_NO (simulating pre-V008 record)
      Qry.SQL.Text :=
        'INSERT INTO DIE_AUDIT_LOG (DIE_ID, DIE_SERIAL_NO, ACTION, DETAILS, CHANGED_BY, CHANGED_AT) ' +
        'VALUES (:ID, NULL, ''LEGACY_TEST'', ''Backfill test entry'', ''SYSTEM'', CURRENT_TIMESTAMP) ' +
        'RETURNING ID';
      Qry.ParamByName('ID').AsInteger := DieID;
      Qry.Open;
      AuditID := Qry.Fields[0].AsInteger;
      Qry.Close;

      // Execute V008 backfill logic
      Qry.SQL.Text :=
        'UPDATE DIE_AUDIT_LOG A ' +
        'SET A.DIE_SERIAL_NO = (SELECT D.SERIAL_NO FROM DIE D WHERE D.ID = A.DIE_ID) ' +
        'WHERE A.ID = :AID AND A.DIE_SERIAL_NO IS NULL';
      Qry.ParamByName('AID').AsInteger := AuditID;
      Qry.ExecSQL;

      // Assert backfill populated DIE_SERIAL_NO
      Qry.SQL.Text := 'SELECT DIE_SERIAL_NO FROM DIE_AUDIT_LOG WHERE ID = :AID';
      Qry.ParamByName('AID').AsInteger := AuditID;
      Qry.Open;
      Assert.AreEqual('ZZTEST-AUDIT-COL-001', Qry.FieldByName('DIE_SERIAL_NO').AsString,
        'Backfill query must populate DIE_SERIAL_NO from parent DIE record');
      Qry.Close;

      // 4. Delete the die and verify audit rows still show the serial number directly via GetAuditLog without DETAILS parsing
      Assert.IsTrue(FDieRepo.PermanentlyDelete(DieID), 'PermanentlyDelete must succeed');

      Log := FDieRepo.GetAuditLog(DieID);
      try
        Assert.IsTrue(Log.Count >= 3, 'Audit rows must be preserved after permanent delete');
        Assert.AreEqual('ZZTEST-AUDIT-COL-001', Log[0].SerialNumber,
          'Audit row must resolve serial number directly from DIE_SERIAL_NO');
      finally
        Log.Free;
      end;
    finally
      Qry.Free;
    end;
  finally
    FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID = ' + IntToStr(DieID));
    FConn.ExecSQL('DELETE FROM DIE WHERE ID = ' + IntToStr(DieID));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixDatabaseTests);

end.
