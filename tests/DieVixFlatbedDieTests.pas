unit DieVixFlatbedDieTests;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  DUnitX Test Suite: Flatbed Die Inventory & Bi-directional Directional Rules
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  Data.DB,
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  DieVix.Domain,
  DieVix.ConnectionManager,
  DieVix.Repositories,
  DieVix.FlatbedDieService,
  DieVix.CalculationEngine;

type
  [TestFixture]
  TDieVixFlatbedDieTests = class
  private
    FConn: TFDConnection;
    FFlatbedService: TFlatbedDieService;
    FFlatbedRepo: IFlatbedDieRepository;
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FStatusRepo: IDieStatusRepository;
    FTestCustID: Integer;
    FTestMediaID: Integer;
  public
    [SetupFixture]
    procedure SetupFixture;

    [TearDownFixture]
    procedure TearDownFixture;

    { Pure Engine Calculation & Rotation Tests }
    [Test]
    procedure Test01_CanRotate_RollForm1x1;

    [Test]
    procedure Test02_CanRotate_RollFormMultiUpsSquare;

    [Test]
    procedure Test03_CanRotate_RollFormMultiUpsRectangular;

    [Test]
    procedure Test04_CanRotate_SheetFormAlwaysFixed;

    [Test]
    procedure Test05_MatchesFlatbedDimensions_StandardOrientation;

    [Test]
    procedure Test06_MatchesFlatbedDimensions_RotatedOrientationWhenAllowed;

    [Test]
    procedure Test07_MatchesFlatbedDimensions_RotatedOrientationRejectedWhenNotAllowed;

    { Database & Service Integration Tests }
    [Test]
    procedure Test08_DatabaseMigrationV009Applied;

    [Test]
    procedure Test09_ValidationEnforcesCategoryAndDimensions;

    [Test]
    procedure Test10_ValidationEnforcesPlateAndFeedBoundaries;

    [Test]
    procedure Test11_CreateRollForm1x1Die;

    [Test]
    procedure Test12_CreateRollFormMultiUpsDie;

    [Test]
    procedure Test13_CreateSheetFormDie;

    [Test]
    procedure Test14_UpdateAndOptimisticConcurrency;

    [Test]
    procedure Test15_DuplicateSerialDetection;

    [Test]
    procedure Test16_FindMatchingFlatbedDiesWithRotation;

    [Test]
    procedure Test17_ArchiveRestoreLifecycle;

    [Test]
    procedure Test18_AuditLogIntegrity;

    [Test]
    procedure Test19_GenerateSerialNumber_FormatAndSeconds;

    [Test]
    procedure Test20_GenerateSerialNumber_HandlesRapidDuplicatesWithoutCollision;

    [Test]
    procedure Test21_SaveFlatbedDie_AutoGeneratesSerialIfEmpty;
  end;

implementation

{ TDieVixFlatbedDieTests }

procedure TDieVixFlatbedDieTests.SetupFixture;
var
  Mgr: TDieVixConnectionManager;
  AppCount: Integer;
  LogStr: string;
  Cust: TCustomer;
  Med: TMedia;
begin
  Mgr := TDieVixConnectionManager.Instance;
  FConn := Mgr.GetConnection;

  // Apply all pending migrations (including V009)
  Mgr.ApplyMigrations(TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\migrations')), AppCount, LogStr);

  // Refresh V_FLATBED_DIE_CATALOG definition
  FConn.ExecSQL(
    'CREATE OR ALTER VIEW V_FLATBED_DIE_CATALOG AS ' +
    'SELECT ' +
    '    F.ID, F.SERIAL_NO, F.DESCRIPTION, F.CATEGORY, ' +
    '    F.CUSTOMER_ID, C.NAME AS CUSTOMER_NAME, ' +
    '    F.MEDIA_ID, M.NAME AS MEDIA_NAME, ' +
    '    F.CUSTOMER_REF, F.SUPPLIER_REF, F.INTERNAL_REF, ' +
    '    F.AROUND_SIZE_MM, F.ACROSS_SIZE_MM, ' +
    '    F.AROUND_UPS, F.ACROSS_UPS, ' +
    '    (F.AROUND_UPS * F.ACROSS_UPS) AS TOTAL_UPS, ' +
    '    F.AROUND_GAP_MM, F.ACROSS_GAP_MM, ' +
    '    F.CORNER_RADIUS_MM, F.SHAPE, ' +
    '    F.PLATE_WIDTH_MM, F.PLATE_LENGTH_MM, F.MAX_FEED_STROKE_MM, ' +
    '    F.TOTAL_CUT_AROUND_MM, F.TOTAL_CUT_ACROSS_MM, ' +
    '    F.CAN_ROTATE, ' +
    '    CASE WHEN F.CAN_ROTATE = 1 THEN ''BI_DIRECTIONAL'' ELSE ''FIXED_DIRECTION'' END AS ROTATION_SUPPORT, ' +
    '    F.STORAGE_LOCATION, F.STORAGE_RACK, F.STORAGE_SHELF, F.STORAGE_BIN, ' +
    '    F.STATUS_CODE, S.DESCRIPTION AS STATUS_NAME, S.BADGE_COLOR, ' +
    '    F.PURCHASE_DATE, F.RECEIVED_DATE, F.DIE_MAKER, ' +
    '    F.TOTAL_IMPRESSIONS, F.NOTES, F.VERSION, ' +
    '    F.CREATED_BY, F.UPDATED_BY, F.CREATED_AT, F.UPDATED_AT ' +
    'FROM FLATBED_DIE F ' +
    'LEFT JOIN CUSTOMER C ON C.ID = F.CUSTOMER_ID ' +
    'LEFT JOIN MEDIA M ON M.ID = F.MEDIA_ID ' +
    'LEFT JOIN DIE_STATUS S ON S.CODE = F.STATUS_CODE'
  );

  // Clean up any test records from previous runs
  FConn.ExecSQL('DELETE FROM FLATBED_DIE_AUDIT_LOG WHERE DIE_SERIAL_NO LIKE ''ZZTEST-FB-%''');
  FConn.ExecSQL('DELETE FROM FLATBED_DIE WHERE SERIAL_NO LIKE ''ZZTEST-FB-%''');

  FCustomerRepo := TCustomerRepository.Create(FConn);
  FMediaRepo := TMediaRepository.Create(FConn);
  FStatusRepo := TDieStatusRepository.Create(FConn);
  FFlatbedRepo := TFlatbedDieRepository.Create(FConn);

  FFlatbedService := TFlatbedDieService.Create(
    FFlatbedRepo, FCustomerRepo, FMediaRepo, FStatusRepo
  );

  // Ensure test customer exists
  Cust := FCustomerRepo.GetByCode('ZZTEST_FB_CUST');
  if Cust.ID = 0 then
  begin
    Cust := TCustomer.CreateNew('ZZTEST_FB_CUST', 'Flatbed Test Customer');
    FTestCustID := FCustomerRepo.Insert(Cust);
  end
  else
    FTestCustID := Cust.ID;

  // Ensure test media exists
  Med := FMediaRepo.GetByCode('ZZTEST_FB_MED');
  if Med.ID = 0 then
  begin
    Med := TMedia.CreateNew('ZZTEST_FB_MED', 'Flatbed Test Media');
    FTestMediaID := FMediaRepo.Insert(Med);
  end
  else
    FTestMediaID := Med.ID;
end;

procedure TDieVixFlatbedDieTests.TearDownFixture;
begin
  if Assigned(FConn) and FConn.Connected then
  begin
    FConn.ExecSQL('DELETE FROM FLATBED_DIE_AUDIT_LOG WHERE DIE_SERIAL_NO LIKE ''ZZTEST-FB-%''');
    FConn.ExecSQL('DELETE FROM FLATBED_DIE WHERE SERIAL_NO LIKE ''ZZTEST-FB-%''');
    if FTestCustID > 0 then
      FConn.ExecSQL('DELETE FROM CUSTOMER WHERE ID = ' + IntToStr(FTestCustID));
    if FTestMediaID > 0 then
      FConn.ExecSQL('DELETE FROM MEDIA WHERE ID = ' + IntToStr(FTestMediaID));
  end;

  FFlatbedService.Free;
end;

{ Pure Engine Calculation & Rotation Tests }

procedure TDieVixFlatbedDieTests.Test01_CanRotate_RollForm1x1;
begin
  // 1x1 Rollform die can be used in both directions (bi-directional rotation)
  Assert.IsTrue(CanFlatbedDieRotate(fcRollForm, 1, 1, 75.0, 50.0), '1x1 Rollform die must rotate bi-directionally');
  Assert.IsTrue(CanFlatbedDieRotate('ROLL_FORM', 1, 1, 120.0, 45.0), '1x1 Rollform die string category must rotate');
end;

procedure TDieVixFlatbedDieTests.Test02_CanRotate_RollFormMultiUpsSquare;
begin
  // Multi-ups Rollform die can rotate ONLY if around and across sizes are identical
  Assert.IsTrue(CanFlatbedDieRotate(fcRollForm, 2, 2, 50.0, 50.0), '2x2 square Rollform die must rotate bi-directionally');
  Assert.IsTrue(CanFlatbedDieRotate(fcRollForm, 4, 3, 25.4, 25.4), '4x3 identical dimension Rollform die must rotate');
end;

procedure TDieVixFlatbedDieTests.Test03_CanRotate_RollFormMultiUpsRectangular;
begin
  // Multi-ups Rollform die with differing around/across dimensions CANNOT rotate
  Assert.IsFalse(CanFlatbedDieRotate(fcRollForm, 2, 1, 75.0, 50.0), '2x1 rectangular Rollform die cannot rotate');
  Assert.IsFalse(CanFlatbedDieRotate(fcRollForm, 1, 2, 75.0, 50.0), '1x2 rectangular Rollform die cannot rotate');
  Assert.IsFalse(CanFlatbedDieRotate(fcRollForm, 2, 2, 80.0, 60.0), '2x2 rectangular Rollform die cannot rotate');
end;

procedure TDieVixFlatbedDieTests.Test04_CanRotate_SheetFormAlwaysFixed;
begin
  // Sheetform/Booklets die is ALWAYS fixed orientation, regardless of ups or dimensions
  Assert.IsFalse(CanFlatbedDieRotate(fcSheetForm, 1, 1, 50.0, 50.0), '1x1 Sheetform die cannot rotate');
  Assert.IsFalse(CanFlatbedDieRotate(fcSheetForm, 1, 1, 75.0, 50.0), '1x1 rectangular Sheetform die cannot rotate');
  Assert.IsFalse(CanFlatbedDieRotate('SHEET_FORM', 2, 2, 40.0, 40.0), 'Multi-ups Sheetform die cannot rotate');
end;

procedure TDieVixFlatbedDieTests.Test05_MatchesFlatbedDimensions_StandardOrientation;
var
  Rotated: Boolean;
begin
  // Exact match in standard orientation
  Assert.IsTrue(MatchesFlatbedDimensions(75.0, 50.0, 75.0, 50.0, False, Rotated, 0.050));
  Assert.IsFalse(Rotated, 'Standard match must not report rotated');

  // Match within tolerance
  Assert.IsTrue(MatchesFlatbedDimensions(75.020, 49.980, 75.0, 50.0, False, Rotated, 0.050));
  Assert.IsFalse(Rotated);

  // Out of tolerance
  Assert.IsFalse(MatchesFlatbedDimensions(75.200, 50.0, 75.0, 50.0, False, Rotated, 0.050));
end;

procedure TDieVixFlatbedDieTests.Test06_MatchesFlatbedDimensions_RotatedOrientationWhenAllowed;
var
  Rotated: Boolean;
begin
  // Die is 75mm Around x 50mm Across. Target is 50mm Around x 75mm Across.
  // When CanRotate = True, this must match in rotated orientation.
  Assert.IsTrue(MatchesFlatbedDimensions(75.0, 50.0, 50.0, 75.0, True, Rotated, 0.050));
  Assert.IsTrue(Rotated, 'MatchesFlatbedDimensions must report IsRotated = True for 90-degree swap');
end;

procedure TDieVixFlatbedDieTests.Test07_MatchesFlatbedDimensions_RotatedOrientationRejectedWhenNotAllowed;
var
  Rotated: Boolean;
begin
  // Die is 75mm Around x 50mm Across. Target is 50mm Around x 75mm Across.
  // When CanRotate = False, rotated match must be rejected.
  Assert.IsFalse(MatchesFlatbedDimensions(75.0, 50.0, 50.0, 75.0, False, Rotated, 0.050));
  Assert.IsFalse(Rotated);
end;

{ Database & Service Integration Tests }

procedure TDieVixFlatbedDieTests.Test08_DatabaseMigrationV009Applied;
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT COUNT(*) FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = ''FLATBED_DIE''';
    Qry.Open;
    Assert.AreEqual(1, Qry.Fields[0].AsInteger, 'FLATBED_DIE table must exist');
    Qry.Close;

    Qry.SQL.Text := 'SELECT COUNT(*) FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = ''FLATBED_DIE_AUDIT_LOG''';
    Qry.Open;
    Assert.AreEqual(1, Qry.Fields[0].AsInteger, 'FLATBED_DIE_AUDIT_LOG table must exist');
    Qry.Close;

    Qry.SQL.Text := 'SELECT COUNT(*) FROM RDB$VIEW_RELATIONS WHERE RDB$VIEW_NAME = ''V_FLATBED_DIE_CATALOG''';
    Qry.Open;
    Assert.IsTrue(Qry.Fields[0].AsInteger > 0, 'V_FLATBED_DIE_CATALOG view must exist');
  finally
    Qry.Free;
  end;
end;

procedure TDieVixFlatbedDieTests.Test09_ValidationEnforcesCategoryAndDimensions;
var
  Die: TFlatbedDie;
  Errors: TArray<string>;
begin
  Die := TFlatbedDie.CreateNew('', 'INVALID_CAT', 0, 0, 0, 0);
  Assert.IsFalse(FFlatbedService.ValidateFlatbedDie(Die, Errors));
  Assert.IsTrue(Length(Errors) >= 4, 'Must report serial, category, dimensions, and ups errors');
end;

procedure TDieVixFlatbedDieTests.Test10_ValidationEnforcesPlateAndFeedBoundaries;
var
  Die: TFlatbedDie;
  Errors: TArray<string>;
begin
  Die := TFlatbedDie.CreateNew('ZZTEST-FB-BOUND', 'ROLL_FORM', 150.0, 100.0, 2, 2);
  Die.PlateWidthMm := 150.0; // Total across cut = 2*100 + 3 = 203mm > 150mm plate width
  Die.PlateLengthMm := 200.0; // Total around cut = 2*150 + 3 = 303mm > 200mm plate length
  Die.MaxFeedStrokeMm := 250.0; // Total around cut = 303mm > 250mm feed stroke

  FFlatbedService.CalculateFootprint(Die);
  Assert.IsFalse(FFlatbedService.ValidateFlatbedDie(Die, Errors));
  Assert.IsTrue(Length(Errors) >= 3, 'Must report plate width, plate length, and max feed stroke violations');
end;

procedure TDieVixFlatbedDieTests.Test11_CreateRollForm1x1Die;
var
  Die, Fetched: TFlatbedDie;
  SavedID: Integer;
begin
  Die := TFlatbedDie.CreateNew('ZZTEST-FB-001', 'ROLL_FORM', 75.0, 50.0, 1, 1);
  Die.Description := 'Test Rollform 1x1 Die';
  Die.CustomerID := FTestCustID;
  Die.MediaID := FTestMediaID;
  Die.StorageLocation := 'Main Warehouse';
  Die.StorageRack := 'FB-01';
  Die.StorageShelf := 'A';
  Die.StorageBin := '01';

  SavedID := FFlatbedService.SaveFlatbedDie(Die, 'TEST_RUNNER');
  Assert.IsTrue(SavedID > 0, 'Flatbed die must save and return positive ID');

  Fetched := FFlatbedService.GetFlatbedDieByID(SavedID);
  Assert.AreEqual('ZZTEST-FB-001', Fetched.SerialNo);
  Assert.AreEqual('ROLL_FORM', Fetched.Category);
  Assert.AreEqual(75.0, Fetched.AroundSizeMm, 0.001);
  Assert.AreEqual(50.0, Fetched.AcrossSizeMm, 0.001);
  Assert.AreEqual(1, Fetched.AroundUps);
  Assert.AreEqual(1, Fetched.AcrossUps);
  Assert.AreEqual(1, Fetched.TotalUps);
  Assert.AreEqual(75.0, Fetched.TotalCutAroundMm, 0.001);
  Assert.AreEqual(50.0, Fetched.TotalCutAcrossMm, 0.001);
  Assert.IsTrue(Fetched.CanRotate, '1x1 Rollform die must have CanRotate = True in database');
  Assert.AreEqual('BI_DIRECTIONAL', Fetched.RotationSupport);
  Assert.AreEqual('ACTIVE', Fetched.StatusCode);
  Assert.AreEqual('TEST_RUNNER', Fetched.CreatedBy);
end;

procedure TDieVixFlatbedDieTests.Test12_CreateRollFormMultiUpsDie;
var
  Die, Fetched: TFlatbedDie;
  SavedID: Integer;
begin
  Die := TFlatbedDie.CreateNew('ZZTEST-FB-002', 'ROLL_FORM', 75.0, 50.0, 2, 1);
  Die.AroundGapMm := 3.0;
  Die.AcrossGapMm := 3.0;
  Die.Description := 'Test Rollform 2x1 Rectangular Die';

  SavedID := FFlatbedService.SaveFlatbedDie(Die, 'TEST_RUNNER');
  Assert.IsTrue(SavedID > 0);

  Fetched := FFlatbedService.GetFlatbedDieByID(SavedID);
  Assert.AreEqual(2, Fetched.AroundUps);
  Assert.AreEqual(1, Fetched.AcrossUps);
  Assert.AreEqual(2, Fetched.TotalUps);
  // Total around = 2 * 75 + 1 * 3 = 153 mm
  Assert.AreEqual(153.0, Fetched.TotalCutAroundMm, 0.001);
  Assert.AreEqual(50.0, Fetched.TotalCutAcrossMm, 0.001);
  Assert.IsFalse(Fetched.CanRotate, 'Multi-ups rectangular Rollform die cannot rotate');
  Assert.AreEqual('FIXED_DIRECTION', Fetched.RotationSupport);
end;

procedure TDieVixFlatbedDieTests.Test13_CreateSheetFormDie;
var
  Die, Fetched: TFlatbedDie;
  SavedID: Integer;
begin
  Die := TFlatbedDie.CreateNew('ZZTEST-FB-003', 'SHEET_FORM', 100.0, 150.0, 1, 1);
  Die.Description := 'Test Sheetform Booklet Die';

  SavedID := FFlatbedService.SaveFlatbedDie(Die, 'TEST_RUNNER');
  Assert.IsTrue(SavedID > 0);

  Fetched := FFlatbedService.GetFlatbedDieByID(SavedID);
  Assert.AreEqual('SHEET_FORM', Fetched.Category);
  Assert.IsFalse(Fetched.CanRotate, 'Sheetform die must always be fixed direction');
  Assert.AreEqual('FIXED_DIRECTION', Fetched.RotationSupport);
end;

procedure TDieVixFlatbedDieTests.Test14_UpdateAndOptimisticConcurrency;
var
  Die, OtherSession: TFlatbedDie;
begin
  Die := FFlatbedService.GetFlatbedDieBySerial('ZZTEST-FB-001');
  Assert.IsTrue(Die.ID > 0);
  Assert.AreEqual(1, Die.Version);

  // Update die
  Die.Description := 'Updated 1x1 Rollform Die Description';
  FFlatbedService.SaveFlatbedDie(Die, 'TEST_RUNNER');

  Die := FFlatbedService.GetFlatbedDieByID(Die.ID);
  Assert.AreEqual(2, Die.Version, 'Version must increment to 2');
  Assert.AreEqual('Updated 1x1 Rollform Die Description', Die.Description);

  // Simulate stale update
  OtherSession := Die;
  OtherSession.Version := 1; // Stale version
  OtherSession.Description := 'Stale edit should fail';
  Assert.WillRaise(
    procedure
    begin
      FFlatbedService.SaveFlatbedDie(OtherSession, 'OTHER_USER');
    end,
    EDieVixConcurrencyException
  );
end;

procedure TDieVixFlatbedDieTests.Test15_DuplicateSerialDetection;
var
  DupDie: TFlatbedDie;
begin
  DupDie := TFlatbedDie.CreateNew('ZZTEST-FB-001', 'ROLL_FORM', 80.0, 40.0, 1, 1);
  Assert.WillRaise(
    procedure
    begin
      FFlatbedService.SaveFlatbedDie(DupDie, 'TEST_RUNNER');
    end,
    EDieVixDuplicateException
  );
end;

procedure TDieVixFlatbedDieTests.Test16_FindMatchingFlatbedDiesWithRotation;
var
  Results: TList<TFlatbedDieSearchResult>;
  FoundRotated001: Boolean;
  Found002: Boolean;
  I: Integer;
begin
  // Target: 50mm Around x 75mm Across
  // ZZTEST-FB-001 is 75mm Around x 50mm Across (1x1 Rollform -> CanRotate = True)
  // ZZTEST-FB-002 is 75mm Around x 50mm Across (2x1 Rollform -> CanRotate = False)
  Results := FFlatbedService.FindMatchingFlatbedDies(50.0, 75.0, 'ROLL_FORM', 0.500, True, True);
  try
    FoundRotated001 := False;
    Found002 := False;

    for I := 0 to Results.Count - 1 do
    begin
      if Results[I].Die.SerialNo = 'ZZTEST-FB-001' then
      begin
        FoundRotated001 := True;
        Assert.IsTrue(Results[I].IsRotated, 'ZZTEST-FB-001 must be recognized as 90-degree rotated match');
        Assert.AreEqual(0.0, Results[I].AroundDiffMm, 0.001);
        Assert.AreEqual(0.0, Results[I].AcrossDiffMm, 0.001);
      end;
      if Results[I].Die.SerialNo = 'ZZTEST-FB-002' then
        Found002 := True;
    end;

    Assert.IsTrue(FoundRotated001, 'ZZTEST-FB-001 must be returned as bi-directional match');
    Assert.IsFalse(Found002, 'ZZTEST-FB-002 (multi-ups rectangular) must NOT be returned because it cannot rotate');
  finally
    Results.Free;
  end;
end;

procedure TDieVixFlatbedDieTests.Test17_ArchiveRestoreLifecycle;
var
  Die: TFlatbedDie;
begin
  Die := FFlatbedService.GetFlatbedDieBySerial('ZZTEST-FB-003');
  Assert.IsTrue(Die.ID > 0);

  // Archive
  Assert.IsTrue(FFlatbedService.ArchiveFlatbedDie(Die.ID, 'Testing archiving', 'TEST_RUNNER', Die.Version));

  Die := FFlatbedService.GetFlatbedDieByID(Die.ID);
  Assert.AreEqual('ARCHIVED', Die.StatusCode);

  // Restore
  Assert.IsTrue(FFlatbedService.RestoreFlatbedDie(Die.ID, 'Testing restore', 'TEST_RUNNER', Die.Version));

  Die := FFlatbedService.GetFlatbedDieByID(Die.ID);
  Assert.AreEqual('ACTIVE', Die.StatusCode);
end;

procedure TDieVixFlatbedDieTests.Test18_AuditLogIntegrity;
var
  Die: TFlatbedDie;
  Audit: TList<TFlatbedDieAuditEntry>;
  HasCreate, HasUpdate: Boolean;
  I: Integer;
begin
  Die := FFlatbedService.GetFlatbedDieBySerial('ZZTEST-FB-001');
  Assert.IsTrue(Die.ID > 0);

  Audit := FFlatbedService.GetFlatbedDieAuditHistory(Die.ID);
  try
    Assert.IsTrue(Audit.Count >= 2, 'Audit log must have at least CREATE and UPDATE entries');
    HasCreate := False;
    HasUpdate := False;

    for I := 0 to Audit.Count - 1 do
    begin
      if Audit[I].Action = 'CREATE' then
        HasCreate := True;
      if Audit[I].Action = 'UPDATE' then
        HasUpdate := True;
    end;

    Assert.IsTrue(HasCreate, 'Audit log must include CREATE record');
    Assert.IsTrue(HasUpdate, 'Audit log must include UPDATE record');
  finally
    Audit.Free;
  end;
end;

procedure TDieVixFlatbedDieTests.Test19_GenerateSerialNumber_FormatAndSeconds;
var
  Serial: string;
begin
  Serial := FFlatbedService.GenerateSerialNumber;
  Assert.IsTrue(Serial.StartsWith('FBD-'), 'Serial must start with FBD- prefix');
  Assert.IsTrue(Length(Serial) >= 17, 'Serial must have at least 17 characters including seconds: ' + Serial);
  Assert.AreEqual('-', Serial[4], 'Expected dash at index 4 in ' + Serial);
  Assert.AreEqual('-', Serial[11], 'Expected dash at index 11 in ' + Serial);
end;

procedure TDieVixFlatbedDieTests.Test20_GenerateSerialNumber_HandlesRapidDuplicatesWithoutCollision;
var
  Die1, Die2: TFlatbedDie;
  ID1, ID2: Integer;
  Serial1, Serial2: string;
begin
  ID1 := 0;
  ID2 := 0;
  try
    Serial1 := FFlatbedService.GenerateSerialNumber;
    Die1 := TFlatbedDie.CreateNew(Serial1, 'ROLL_FORM', 60.0, 40.0, 1, 1);
    ID1 := FFlatbedService.SaveFlatbedDie(Die1, 'TEST_RUNNER');
    Assert.IsTrue(ID1 > 0, 'First die must save successfully');

    Serial2 := FFlatbedService.GenerateSerialNumber;
    Assert.AreNotEqual(Serial1, Serial2, 'Consecutive serial generations must never produce duplicate serials');

    Die2 := TFlatbedDie.CreateNew(Serial2, 'ROLL_FORM', 60.0, 40.0, 1, 1);
    ID2 := FFlatbedService.SaveFlatbedDie(Die2, 'TEST_RUNNER');
    Assert.IsTrue(ID2 > 0, 'Second die must save successfully without duplicate serial exception');
  finally
    if ID1 > 0 then
      FConn.ExecSQL('DELETE FROM FLATBED_DIE WHERE ID = ' + IntToStr(ID1));
    if ID2 > 0 then
      FConn.ExecSQL('DELETE FROM FLATBED_DIE WHERE ID = ' + IntToStr(ID2));
  end;
end;

procedure TDieVixFlatbedDieTests.Test21_SaveFlatbedDie_AutoGeneratesSerialIfEmpty;
var
  Die, Fetched: TFlatbedDie;
  SavedID: Integer;
begin
  SavedID := 0;
  try
    Die := TFlatbedDie.CreateNew('', 'ROLL_FORM', 55.0, 35.0, 1, 1);
    SavedID := FFlatbedService.SaveFlatbedDie(Die, 'TEST_RUNNER');
    Assert.IsTrue(SavedID > 0, 'Die with blank serial should auto-generate serial and save successfully');

    Fetched := FFlatbedService.GetFlatbedDieByID(SavedID);
    Assert.IsTrue(Fetched.SerialNo.StartsWith('FBD-'), 'Auto-generated serial must start with FBD-');
    Assert.IsTrue(Length(Fetched.SerialNo) >= 17, 'Auto-generated serial must include seconds');
  finally
    if SavedID > 0 then
      FConn.ExecSQL('DELETE FROM FLATBED_DIE WHERE ID = ' + IntToStr(SavedID));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixFlatbedDieTests);

end.
