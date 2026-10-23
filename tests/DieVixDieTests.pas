unit DieVixDieTests;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  DUnitX Test Suite: Phase 3 Die Master Register, Inventory & Validation
  Comprehensive Firebird 5.0 integration tests operating on disposable database.
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  DieVix.Domain,
  DieVix.ConnectionManager,
  DieVix.Repositories,
  DieVix.MasterDataService,
  DieVix.DieService,
  DieVix.CalculationEngine;

type
  [TestFixture]
  TDieVixDieTests = class
  private
    FConn: TFDConnection;
    FDieService: TDieService;
    FMasterService: TMasterDataService;
    FDieRepo: IDieRepository;
    FSettingRepo: IAppSettingRepository;
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FCylinderRepo: ICylinderRepository;
    FStatusRepo: IDieStatusRepository;
    FTestDieID: Integer;
    FTestCustID: Integer;
    FTestMediaID: Integer;
  public
    [SetupFixture]
    procedure SetupFixture;

    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure Test01_MigrationApplicationAndIdempotence;

    [Test]
    procedure Test02_DieCreation;

    [Test]
    procedure Test03_DieRetrieval;

    [Test]
    procedure Test04_DieUpdate;

    [Test]
    procedure Test05_UniqueSerialEnforcement;

    [Test]
    procedure Test06_ConcurrentDuplicateSerialAttempts;

    [Test]
    procedure Test07_Exact3000mmGap;

    [Test]
    procedure Test08_BelowMinimumWarningAndOverrideReasonRequired;

    [Test]
    procedure Test09_ConfigurableHardBlockBehavior;

    [Test]
    procedure Test10_NegativeGapRejection;

    [Test]
    procedure Test11_HistoricalCylinderPitchPreservation;

    [Test]
    procedure Test12_FractionalMicrometreGapComparison;

    [Test]
    procedure Test13_SimilarDieSearchAndReuse;

    [Test]
    procedure Test14_NonReusableSimilarDieClassification;

    [Test]
    procedure Test15_CustomerAndMediaForeignKeys;

    [Test]
    procedure Test16_StorageLocationPersistence;

    [Test]
    procedure Test17_StatusChangeAndAudit;

    [Test]
    procedure Test18_AuditRecordCreation;

    [Test]
    procedure Test19_AtomicRollbackOfDataAndAudit;

    [Test]
    procedure Test20_OptimisticConcurrencyConflicts;

    [Test]
    procedure Test21_SaveReopenGeometryConsistency;

    [Test]
    procedure Test22_SearchFilterCorrectness;

    [Test]
    procedure Test23_InvalidDimensionHandling;

    [Test]
    procedure Test24_LargeNumberOverflowSafety;

    [Test]
    procedure Test25_DeleteAndCleanup;

    { Smart Die Size Finder Tests }
    [Test]
    procedure Test26_SmartSearch_ExactMatch_150x100;

    [Test]
    procedure Test27_SmartSearch_NearMatchTier1_149x100;

    [Test]
    procedure Test28_SmartSearch_NearMatchTier2_151_5x102;

    [Test]
    procedure Test29_SmartSearch_ExcludedBeyondTolerance_153x100;

    [Test]
    procedure Test30_SmartSearch_AroundPriorityOverAcrossProximity;

    [Test]
    procedure Test31_SmartSearch_AcrossSlittingCandidateReviewRequired;

    [Test]
    procedure Test32_SmartSearch_InactiveOrScrappedDieFiltering;

    [Test]
    procedure Test33_SmartSearch_IntegerMicrometreBoundaryHandling;

    [Test]
    procedure Test34_SmartSearch_SqlParameterizationAndPagination;
  private
    function CreateAndSaveTestDie(
      const ASerial: string;
      const ATeeth: Integer;
      const AAroundMm, AAcrossMm: Double;
      const AAroundUps, AAcrossUps: Integer;
      const AStatus: string = 'AVAILABLE';
      const AShape: string = 'RECTANGLE';
      const ACutType: string = 'ROTARY';
      const ARadiusMm: Double = 0.0;
      const AOverrideReason: string = ''
    ): Integer;
  end;

implementation

{ TDieVixDieTests }

procedure TDieVixDieTests.SetupFixture;
var
  Mgr: TDieVixConnectionManager;
  Cfg: TDatabaseConfig;
  AppCount: Integer;
  LogStr: string;
  Cust: TCustomer;
  Med: TMedia;
begin
  Mgr := TDieVixConnectionManager.Instance;
  Cfg := TDatabaseConfig.DefaultServer;
  Cfg.Database := 'D:\ketan\github\DieVix\tmp\dievix_disposable_test.fdb';
  Cfg.UserName := 'SYSDBA';
  Cfg.Password := 'masterkey';
  Cfg.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll';
  Mgr.Config := Cfg;

  FConn := Mgr.GetConnection;

  // Apply all pending migrations including V003
  Mgr.ApplyMigrations('D:\ketan\github\DieVix\migrations', AppCount, LogStr);

  FCustomerRepo := TCustomerRepository.Create(FConn);
  FMediaRepo := TMediaRepository.Create(FConn);
  FCylinderRepo := TCylinderRepository.Create(FConn);
  FStatusRepo := TDieStatusRepository.Create(FConn);
  FSettingRepo := TAppSettingRepository.Create(FConn);
  FDieRepo := TDieRepository.Create(FConn);

  FMasterService := TMasterDataService.Create(
    FCustomerRepo, FMediaRepo, FStatusRepo, FCylinderRepo, nil, nil, FSettingRepo
  );

  FDieService := TDieService.Create(
    FDieRepo, FSettingRepo, FCustomerRepo, FMediaRepo, FCylinderRepo, FStatusRepo
  );

  // Ensure standard status codes are initialized
  FStatusRepo.Save(TDieStatus.CreateNew('ACTIVE', 'Active / Ready for Press', True));
  FStatusRepo.Save(TDieStatus.CreateNew('AVAILABLE', 'Available / Ready for Press', True));
  FStatusRepo.Save(TDieStatus.CreateNew('IN_USE', 'Mounted on Press', True));
  FStatusRepo.Save(TDieStatus.CreateNew('REPAIR', 'Under Repair / Sharpening', False));
  FStatusRepo.Save(TDieStatus.CreateNew('IN_REPAIR', 'Under Repair / Sharpening', False));
  FStatusRepo.Save(TDieStatus.CreateNew('SCRAPPED', 'Damaged / Retired', False));

  // Setup test customer and media
  Cust := TCustomer.CreateNew('TEST-CUST-PH3', 'Phase 3 Test Customer');
  FTestCustID := FCustomerRepo.Insert(Cust);

  Med := TMedia.CreateNew('TEST-MED-PH3', 'Semi-Gloss 80g / Glassine 62g');
  FTestMediaID := FMediaRepo.Insert(Med);

  FTestDieID := 0;
end;

procedure TDieVixDieTests.TearDownFixture;
begin
  if FTestCustID > 0 then
    FCustomerRepo.Delete(FTestCustID);
  if FTestMediaID > 0 then
    FMediaRepo.Delete(FTestMediaID);

  FDieService.Free;
  FMasterService.Free;
end;

procedure TDieVixDieTests.Test01_MigrationApplicationAndIdempotence;
var
  AppCount: Integer;
  LogStr: string;
  OK: Boolean;
begin
  // Calling migration runner again should find 0 pending scripts and return True (idempotent)
  OK := TDieVixConnectionManager.Instance.ApplyMigrations('D:\ketan\github\DieVix\migrations', AppCount, LogStr);
  Assert.IsTrue(OK, 'Migration runner must succeed');
  Assert.AreEqual(0, AppCount, 'Second run must apply 0 scripts (idempotent)');
end;

procedure TDieVixDieTests.Test02_DieCreation;
var
  Die: TDie;
begin
  // Create a standard compliant rotary die: 96T, 98.0mm around, 50.0mm across, 3 around ups
  // Repeat = 96 * 3.175 = 304.8 mm. Total cut = 3 * 98 = 294 mm. Pool = 10.8 mm. Gap = 3.600 mm.
  Die := TDie.CreateNew('DIE-PH3-001', 96, 98.0, 50.0, 3, 2);
  Die.CustomerID := FTestCustID;
  Die.MediaID := FTestMediaID;
  Die.Description := 'Ph3 Main Product Label 98x50';
  Die.InternalRef := 'INT-9850';
  Die.CustomerRef := 'CUST-PO-1001';
  Die.StorageRack := 'RACK-A';
  Die.StorageShelf := 'SHELF-01';
  Die.StorageBin := 'BIN-12';
  Die.DieMaker := 'Kocher+Beck';
  Die.SupplierRef := 'KB-99214';

  FTestDieID := FDieService.SaveDie(Die, 'ARCHITECT');
  Assert.IsTrue(FTestDieID > 0, 'Die ID must be greater than zero after insert');
  Assert.AreEqual(1, Die.Version, 'Initial die version must be 1');
end;

procedure TDieVixDieTests.Test03_DieRetrieval;
var
  DieByID, DieBySerial: TDie;
begin
  Assert.IsTrue(FTestDieID > 0, 'TestDieID must be set');

  DieByID := FDieService.GetDieByID(FTestDieID);
  Assert.AreEqual(FTestDieID, DieByID.ID, 'Die ID must match');
  Assert.AreEqual('DIE-PH3-001', DieByID.SerialNo, 'Serial must match');
  Assert.AreEqual(96, DieByID.Teeth, 'Teeth must be 96');
  Assert.AreEqual(3, DieByID.AroundUps, 'Around ups must be 3');
  Assert.AreEqual(2, DieByID.AcrossUps, 'Across ups must be 2');
  Assert.AreEqual(304.800, DieByID.RepeatMm, 0.001, 'Repeat mm must be 304.800');
  Assert.AreEqual(3.600, DieByID.AroundGapMm, 0.001, 'Around gap mm must be 3.600');
  Assert.AreEqual('RACK-A', DieByID.StorageRack, 'Storage rack must match');

  DieBySerial := FDieService.GetDieBySerial('die-ph3-001');
  Assert.AreEqual(FTestDieID, DieBySerial.ID, 'Serial lookup must be case-insensitive');
  Assert.AreEqual('Ph3 Main Product Label 98x50', DieBySerial.Description, 'Description must match');
end;

procedure TDieVixDieTests.Test04_DieUpdate;
var
  Die: TDie;
  UpdatedID: Integer;
begin
  Die := FDieService.GetDieByID(FTestDieID);
  Assert.AreEqual(1, Die.Version, 'Original version must be 1');

  Die.Description := 'Ph3 Updated Product Label 98x50 (Rev B)';
  Die.TotalRunMetres := 15000;
  UpdatedID := FDieService.SaveDie(Die, 'OPERATOR_BOB');

  Assert.AreEqual(FTestDieID, UpdatedID, 'Updated ID must match');

  Die := FDieService.GetDieByID(FTestDieID);
  Assert.AreEqual('Ph3 Updated Product Label 98x50 (Rev B)', Die.Description, 'Description must be updated');
  Assert.AreEqual(15000, Die.TotalRunMetres, 'Total run metres must update');
  Assert.AreEqual(2, Die.Version, 'Version must increment to 2 after update');
  Assert.AreEqual('OPERATOR_BOB', Die.UpdatedBy, 'UpdatedBy must be recorded');
end;

procedure TDieVixDieTests.Test05_UniqueSerialEnforcement;
var
  DupDie: TDie;
  RaisedDup: Boolean;
begin
  RaisedDup := False;
  DupDie := TDie.CreateNew('DIE-PH3-001', 96, 98.0, 50.0, 3, 2);
  try
    FDieService.SaveDie(DupDie);
  except
    on E: EDieVixDuplicateException do
      RaisedDup := True;
  end;
  Assert.IsTrue(RaisedDup, 'Saving duplicate serial number must raise EDieVixDuplicateException');
end;

procedure TDieVixDieTests.Test06_ConcurrentDuplicateSerialAttempts;
var
  Exists: Boolean;
begin
  Exists := FDieService.CheckDuplicateSerial('die-ph3-001');
  Assert.IsTrue(Exists, 'CheckDuplicateSerial must detect existing serial case-insensitively');

  Exists := FDieService.CheckDuplicateSerial('NON_EXISTENT_SERIAL');
  Assert.IsFalse(Exists, 'CheckDuplicateSerial must return False for unused serial');
end;

procedure TDieVixDieTests.Test07_Exact3000mmGap;
var
  Die: TDie;
  SavedID: Integer;
begin
  // 96T * 3.175 = 304.8 mm. With 3 ups, repeat / 3 = 101.6 mm.
  // Around size = 98.600 mm -> Around gap = exactly 3.000 mm.
  Die := TDie.CreateNew('DIE-PH3-EXACT3MM', 96, 98.600, 40.0, 3, 1);
  SavedID := FDieService.SaveDie(Die);
  try
    Assert.IsTrue(SavedID > 0, 'Exact 3.000 mm die must save without error');
    Die := FDieService.GetDieByID(SavedID);
    Assert.AreEqual(3.000, Die.AroundGapMm, 0.0001, 'Computed gap must be exactly 3.000 mm');
    Assert.AreEqual('APPROVED', Die.GapPolicyStatus, 'Gap status must be APPROVED');
  finally
    FDieService.DeleteDie(SavedID);
  end;
end;

procedure TDieVixDieTests.Test08_BelowMinimumWarningAndOverrideReasonRequired;
var
  Die: TDie;
  RaisedMissingReason: Boolean;
  SavedID: Integer;
begin
  // 96T * 3.175 = 304.8 mm. 3 ups of 98.700 mm -> Total cut = 296.1 mm. Gap pool = 8.7 mm.
  // Around gap = 8.7 / 3 = 2.900 mm (< 3.000 mm minimum)
  Die := TDie.CreateNew('DIE-PH3-SUB3MM', 96, 98.700, 40.0, 3, 1);

  // 1. Attempt save without override reason
  RaisedMissingReason := False;
  try
    FDieService.SaveDie(Die);
  except
    on E: EDieVixValidationException do
      RaisedMissingReason := True;
  end;
  Assert.IsTrue(RaisedMissingReason, 'Saving sub-3mm die without override reason must be rejected');

  // 2. Provide override reason and save
  Die.OverrideReason := 'Approved for legacy flexo printing job on 96T';
  SavedID := FDieService.SaveDie(Die);
  try
    Assert.IsTrue(SavedID > 0, 'Sub-3mm die with override reason must save successfully');
    Die := FDieService.GetDieByID(SavedID);
    Assert.AreEqual(2.900, Die.AroundGapMm, 0.001, 'Around gap must be 2.900 mm');
    Assert.AreEqual('Approved for legacy flexo printing job on 96T', Die.OverrideReason, 'Override reason must persist');
  finally
    FDieService.DeleteDie(SavedID);
  end;
end;

procedure TDieVixDieTests.Test09_ConfigurableHardBlockBehavior;
var
  Die: TDie;
  RaisedHardBlock: Boolean;
begin
  // Configure HARD_BLOCK_GAP_UM = 2500 (2.500 mm)
  FSettingRepo.SetValue('HARD_BLOCK_GAP_UM', '2500', 'Hard block mechanical threshold in um');
  try
    // 96T * 3.175 = 304.8 mm. 3 ups of 99.200 mm -> total cut = 297.6 mm.
    // Pool = 7.2 mm. Gap = 7.2 / 3 = 2.400 mm (< 2.500 mm hard block limit)
    Die := TDie.CreateNew('DIE-PH3-HARDBLOCK', 96, 99.200, 40.0, 3, 1);
    Die.OverrideReason := 'Attempting to override mechanical hard block';

    RaisedHardBlock := False;
    try
      FDieService.SaveDie(Die);
    except
      on E: EDieVixValidationException do
        RaisedHardBlock := True;
    end;
    Assert.IsTrue(RaisedHardBlock, 'Hard block violation must be rejected even with override reason');
  finally
    // Reset to default 0 (disabled)
    FSettingRepo.SetValue('HARD_BLOCK_GAP_UM', '0', 'Hard block mechanical threshold in um');
  end;
end;

procedure TDieVixDieTests.Test10_NegativeGapRejection;
var
  Die: TDie;
  RaisedNeg: Boolean;
begin
  // 96T * 3.175 = 304.8 mm. 3 ups of 110.0 mm -> total cut = 330.0 mm (> 304.8 mm circumference)
  Die := TDie.CreateNew('DIE-PH3-OVERSIZE', 96, 110.0, 40.0, 3, 1);
  RaisedNeg := False;
  try
    FDieService.SaveDie(Die);
  except
    on E: EDieVixValidationException do
      RaisedNeg := True;
  end;
  Assert.IsTrue(RaisedNeg, 'Physically impossible dimensions exceeding repeat must be rejected');
end;

procedure TDieVixDieTests.Test11_HistoricalCylinderPitchPreservation;
var
  Die: TDie;
  SavedID: Integer;
begin
  // Verify that an existing die retains its historical pitch snapshot
  Die := TDie.CreateNew('DIE-PH3-HISTORICAL', 96, 98.0, 50.0, 3, 1);
  Die.PitchUm := 3175;
  SavedID := FDieService.SaveDie(Die);
  try
    Die := FDieService.GetDieByID(SavedID);
    Assert.AreEqual(3175, Die.PitchUm, 'Historical pitch snapshot must be 3175 um');
    Assert.AreEqual(304.800, Die.RepeatMm, 0.001, 'Repeat must be calculated from historical snapshot');
  finally
    FDieService.DeleteDie(SavedID);
  end;
end;

procedure TDieVixDieTests.Test12_FractionalMicrometreGapComparison;
var
  GapRes: TGapResult;
begin
  // Test rational gap comparison:
  // 112T * 3175 um = 355600 um.
  // 3 ups of 116000 um (116.000 mm) = 348000 um cut length.
  // Gap pool = 7600 um.
  // 7600 / 3 = 2533.3333... um (2.533 mm with remainder 1 um).
  GapRes := CalculateAroundGap(112, 116000, 3, 3000, 0, 3175);
  Assert.AreEqual(Int64(2533), GapRes.AroundGapUm, 'Integer quotient must be 2533 um');
  Assert.AreEqual(1, GapRes.RemainderUm, 'Integer remainder must be 1 um');
  Assert.IsTrue(GapRes.RequiresOverrideReason, '2533 um is below 3000 um and must require override reason');
end;

procedure TDieVixDieTests.Test13_SimilarDieSearchAndReuse;
var
  Matches: TList<TSimilarDieResult>;
begin
  // Existing die is 96T, 98.000 mm around, 50.000 mm across, 3x2 ups, RECTANGLE
  Matches := FDieService.FindSimilarDies(96, 98.000, 50.000, 3, 2, 'RECTANGLE', 0.5);
  try
    Assert.IsTrue(Matches.Count > 0, 'Must find existing die with identical geometry');
    Assert.AreEqual(TSimilarDieMatchType.smtExact, Matches[0].MatchType, 'Must classify as exact match');
    Assert.AreEqual('DIE-PH3-001', Matches[0].Die.SerialNo, 'Serial must match');
  finally
    Matches.Free;
  end;
end;

procedure TDieVixDieTests.Test14_NonReusableSimilarDieClassification;
var
  Matches: TList<TSimilarDieResult>;
begin
  // Query with same dimensions but 3x1 ups (existing is 3x2)
  Matches := FDieService.FindSimilarDies(96, 98.000, 50.000, 3, 1, 'RECTANGLE', 0.5);
  try
    Assert.IsTrue(Matches.Count > 0, 'Must return die within dimensional tolerance');
    Assert.AreEqual(TSimilarDieMatchType.smtIncompatible, Matches[0].MatchType, 'Ups mismatch must classify as incompatible');
  finally
    Matches.Free;
  end;
end;

procedure TDieVixDieTests.Test15_CustomerAndMediaForeignKeys;
var
  Die: TDie;
begin
  Die := FDieService.GetDieByID(FTestDieID);
  Assert.AreEqual('Phase 3 Test Customer', Die.CustomerName, 'Joined CustomerName must match');
  Assert.AreEqual('Semi-Gloss 80g / Glassine 62g', Die.MediaName, 'Joined MediaName must match');
end;

procedure TDieVixDieTests.Test16_StorageLocationPersistence;
var
  OK: Boolean;
  Die: TDie;
begin
  OK := FDieService.UpdateDieLocation(FTestDieID, 'RACK-B', 'SHELF-04', 'BIN-99', 'Relocated for routine maintenance', 'STOREKEEPER');
  Assert.IsTrue(OK, 'UpdateDieLocation must return True');

  Die := FDieService.GetDieByID(FTestDieID);
  Assert.AreEqual('RACK-B', Die.StorageRack, 'Storage rack must be RACK-B');
  Assert.AreEqual('SHELF-04', Die.StorageShelf, 'Storage shelf must be SHELF-04');
  Assert.AreEqual('BIN-99', Die.StorageBin, 'Storage bin must be BIN-99');
  Assert.IsTrue(Pos('BIN-99', Die.StorageLocation) > 0, 'Location text must contain BIN-99');
end;

procedure TDieVixDieTests.Test17_StatusChangeAndAudit;
var
  OK: Boolean;
  Die: TDie;
begin
  OK := FDieService.ChangeDieStatus(FTestDieID, 'REPAIR', 'Re-sharpening cylinder blades', 'MAINT_ENG');
  Assert.IsTrue(OK, 'ChangeDieStatus must succeed');

  Die := FDieService.GetDieByID(FTestDieID);
  Assert.AreEqual('REPAIR', Die.StatusCode, 'StatusCode must be updated to REPAIR');

  // Change back to ACTIVE
  FDieService.ChangeDieStatus(FTestDieID, 'ACTIVE', 'Re-sharpening verified and returned to service', 'MAINT_ENG');
  Die := FDieService.GetDieByID(FTestDieID);
  Assert.AreEqual('ACTIVE', Die.StatusCode, 'StatusCode must be returned to ACTIVE');
end;

procedure TDieVixDieTests.Test18_AuditRecordCreation;
var
  AuditList: TList<TDieAuditEntry>;
  FoundStatusChange, FoundLocationChange: Boolean;
  I: Integer;
begin
  AuditList := FDieService.GetDieAuditHistory(FTestDieID);
  try
    Assert.IsTrue(AuditList.Count >= 3, 'Audit history must contain CREATE, UPDATE, LOCATION, and STATUS entries');
    FoundStatusChange := False;
    FoundLocationChange := False;
    for I := 0 to AuditList.Count - 1 do
    begin
      if AuditList[I].Action = 'STATUS_CHANGE' then
        FoundStatusChange := True;
      if AuditList[I].Action = 'LOCATION_CHANGE' then
        FoundLocationChange := True;
      Assert.IsTrue(AuditList[I].ChangedBy <> '', 'Audit actor identity must not be empty');
      Assert.IsTrue(AuditList[I].ChangedAt > 0, 'Audit timestamp must be recorded');
    end;
    Assert.IsTrue(FoundStatusChange, 'Status change audit record must be present');
    Assert.IsTrue(FoundLocationChange, 'Location change audit record must be present');
  finally
    AuditList.Free;
  end;
end;

procedure TDieVixDieTests.Test19_AtomicRollbackOfDataAndAudit;
var
  Trans: TFDTransaction;
  Qry: TFDQuery;
  InitialCount: Integer;
begin
  Qry := TFDQuery.Create(nil);
  Trans := TFDTransaction.Create(nil);
  try
    Qry.Connection := FConn;
    Trans.Connection := FConn;
    FConn.Transaction := Trans;

    Qry.SQL.Text := 'SELECT COUNT(*) FROM DIE';
    Qry.Open;
    InitialCount := Qry.Fields[0].AsInteger;
    Qry.Close;

    // Start explicit transaction and insert a temp die
    Trans.StartTransaction;
    Qry.SQL.Text :=
      'INSERT INTO DIE (SERIAL_NO, TEETH, AROUND_SIZE_MM, ACROSS_SIZE_MM, CREATED_BY) ' +
      'VALUES (''DIE-ROLLBACK-TEST'', 96, 50.0, 50.0, ''TEST'')';
    Qry.ExecSQL;

    // Rollback
    Trans.Rollback;

    Qry.SQL.Text := 'SELECT COUNT(*) FROM DIE';
    Qry.Open;
    Assert.AreEqual(InitialCount, Qry.Fields[0].AsInteger, 'Count must remain identical after rollback');
    Qry.Close;
  finally
    Trans.Free;
    Qry.Free;
  end;
end;

procedure TDieVixDieTests.Test20_OptimisticConcurrencyConflicts;
var
  DieA, DieB: TDie;
  RaisedConflict: Boolean;
begin
  // Load record into instance A and instance B
  DieA := FDieService.GetDieByID(FTestDieID);
  DieB := FDieService.GetDieByID(FTestDieID);

  Assert.AreEqual(DieA.Version, DieB.Version, 'Both instances must start with the same version');

  // User A updates record
  DieA.Description := 'Concurrent Update by User A';
  FDieService.SaveDie(DieA, 'USER_A');

  // User B tries to update using stale version
  DieB.Description := 'Concurrent Update by User B';
  RaisedConflict := False;
  try
    FDieService.SaveDie(DieB, 'USER_B');
  except
    on E: EDieVixConcurrencyException do
      RaisedConflict := True;
  end;
  Assert.IsTrue(RaisedConflict, 'Saving stale version must raise EDieVixConcurrencyException');
end;

procedure TDieVixDieTests.Test21_SaveReopenGeometryConsistency;
var
  Die: TDie;
  SavedID: Integer;
begin
  Die := TDie.CreateNew('DIE-PH3-GEOM-TEST', 106, 75.321, 62.456, 4, 3);
  Die.AcrossGapMm := 3.250;
  Die.CornerRadiusMm := 1.750;
  Die.Shape := 'OVAL';
  Die.CutType := 'FLEXIBLE';

  SavedID := FDieService.SaveDie(Die);
  try
    Die := FDieService.GetDieByID(SavedID);
    Assert.AreEqual(75.321, Die.AroundSizeMm, 0.0001, 'Around size mm must match exactly');
    Assert.AreEqual(62.456, Die.AcrossSizeMm, 0.0001, 'Across size mm must match exactly');
    Assert.AreEqual(3.250, Die.AcrossGapMm, 0.0001, 'Across gap mm must match exactly');
    Assert.AreEqual(1.750, Die.CornerRadiusMm, 0.0001, 'Corner radius mm must match exactly');
    Assert.AreEqual('OVAL', Die.Shape, 'Shape must be OVAL');
    Assert.AreEqual('FLEXIBLE', Die.CutType, 'Cut type must be FLEXIBLE');
  finally
    FDieService.DeleteDie(SavedID);
  end;
end;

procedure TDieVixDieTests.Test22_SearchFilterCorrectness;
var
  Filter: TDieSearchFilter;
  Results: TList<TDie>;
begin
  Filter := TDieSearchFilter.Default;
  Filter.SearchText := 'PH3-001'; // Matches serial DIE-PH3-001
  Results := FDieService.SearchDies(Filter);
  try
    Assert.IsTrue(Results.Count > 0, 'Search text filter must return matching dies');
    Assert.AreEqual(FTestDieID, Results[0].ID, 'Search text must find TestDieID');
  finally
    Results.Free;
  end;

  Filter := TDieSearchFilter.Default;
  Filter.Teeth := 96;
  Results := FDieService.SearchDies(Filter);
  try
    Assert.IsTrue(Results.Count > 0, 'Teeth filter must return 96T dies');
  finally
    Results.Free;
  end;
end;

procedure TDieVixDieTests.Test23_InvalidDimensionHandling;
var
  Die: TDie;
  RaisedZeroAround: Boolean;
begin
  Die := TDie.CreateNew('DIE-PH3-ZERO-DIM', 96, 0.0, 50.0, 1, 1);
  RaisedZeroAround := False;
  try
    FDieService.SaveDie(Die);
  except
    on E: EDieVixValidationException do
      RaisedZeroAround := True;
  end;
  Assert.IsTrue(RaisedZeroAround, 'Zero around dimension must be rejected');
end;

procedure TDieVixDieTests.Test24_LargeNumberOverflowSafety;
var
  Die: TDie;
  RaisedOverflow: Boolean;
begin
  // Huge dimensions that would overflow cylinder circumference
  Die := TDie.CreateNew('DIE-PH3-HUGE', 132, 999999.0, 50.0, 1, 1);
  RaisedOverflow := False;
  try
    FDieService.SaveDie(Die);
  except
    on E: EDieVixValidationException do
      RaisedOverflow := True;
  end;
  Assert.IsTrue(RaisedOverflow, 'Outsized dimensions must be safely caught without crashing');
end;

procedure TDieVixDieTests.Test25_DeleteAndCleanup;
var
  DeletedOK: Boolean;
  Die: TDie;
begin
  Assert.IsTrue(FTestDieID > 0, 'TestDieID must be set');
  DeletedOK := FDieService.DeleteDie(FTestDieID);
  Assert.IsTrue(DeletedOK, 'DeleteDie must return True');

  Die := FDieService.GetDieByID(FTestDieID);
  Assert.AreEqual(0, Die.ID, 'Deleted die must no longer be found');
  FTestDieID := 0;
end;

function TDieVixDieTests.CreateAndSaveTestDie(
  const ASerial: string;
  const ATeeth: Integer;
  const AAroundMm, AAcrossMm: Double;
  const AAroundUps, AAcrossUps: Integer;
  const AStatus: string;
  const AShape: string;
  const ACutType: string;
  const ARadiusMm: Double;
  const AOverrideReason: string
): Integer;
var
  Die, Existing: TDie;
begin
  Existing := FDieService.GetDieBySerial(ASerial);
  if Existing.ID > 0 then
    FDieService.DeleteDie(Existing.ID);

  Die := TDie.CreateNew(ASerial, ATeeth, AAroundMm, AAcrossMm, AAroundUps, AAcrossUps);
  Die.CustomerID := FTestCustID;
  Die.MediaID := FTestMediaID;
  Die.StatusCode := AStatus;
  Die.Shape := AShape;
  Die.CutType := ACutType;
  Die.CornerRadiusMm := ARadiusMm;
  Die.OverrideReason := AOverrideReason;
  Result := FDieService.SaveDie(Die);
end;

procedure TDieVixDieTests.Test26_SmartSearch_ExactMatch_150x100;
var
  DieID: Integer;
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
begin
  DieID := CreateAndSaveTestDie('DIE-SS-26-EXACT', 98, 150.0, 100.0, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Assert.IsTrue(Results.Count > 0, 'Exact match must return at least one die');
      Assert.AreEqual('DIE-SS-26-EXACT', Results[0].Die.SerialNo, 'Exact match must be ranked first');
      Assert.IsTrue(Results[0].MatchClass = sdmExactMatch, 'MatchClass must be sdmExactMatch');
      Assert.AreEqual(Int64(0), Results[0].AroundDiffUm, 'AroundDiffUm must be 0');
      Assert.AreEqual(Int64(0), Results[0].AcrossDiffUm, 'AcrossDiffUm must be 0');
      Assert.AreEqual(0.0, Results[0].AroundDiffMm, 0.0001, 'AroundDiffMm must be 0.0');
      Assert.AreEqual(0.0, Results[0].AcrossDiffMm, 0.0001, 'AcrossDiffMm must be 0.0');
    finally
      Results.Free;
    end;
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixDieTests.Test27_SmartSearch_NearMatchTier1_149x100;
var
  DieID: Integer;
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
  Found: Boolean;
  I: Integer;
begin
  DieID := CreateAndSaveTestDie('DIE-SS-27-NEAR1', 98, 149.0, 100.0, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'DIE-SS-27-NEAR1' then
        begin
          Found := True;
          Assert.IsTrue(Results[I].MatchClass = sdmNearMatchTier1, '149x100 must be classified as Tier 1 near match');
          Assert.AreEqual(Int64(-1000), Results[I].AroundDiffUm, 'Around diff must be -1000 um');
          Assert.AreEqual(Int64(0), Results[I].AcrossDiffUm, 'Across diff must be 0 um');
          Assert.AreEqual(-1.0, Results[I].AroundDiffMm, 0.0001, 'Around diff mm must be -1.0');
          Assert.AreEqual(0.0, Results[I].AcrossDiffMm, 0.0001, 'Across diff mm must be 0.0');
        end;
      end;
      Assert.IsTrue(Found, 'DIE-SS-27-NEAR1 must be found in search results');
    finally
      Results.Free;
    end;
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixDieTests.Test28_SmartSearch_NearMatchTier2_151_5x102;
var
  DieID: Integer;
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
  Found: Boolean;
  I: Integer;
begin
  DieID := CreateAndSaveTestDie('DIE-SS-28-NEAR2', 98, 151.5, 102.0, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'DIE-SS-28-NEAR2' then
        begin
          Found := True;
          Assert.IsTrue(Results[I].MatchClass = sdmNearMatchTier2, '151.5x102 must be classified as Tier 2 near match');
          Assert.AreEqual(Int64(1500), Results[I].AroundDiffUm, 'Around diff must be +1500 um');
          Assert.AreEqual(Int64(2000), Results[I].AcrossDiffUm, 'Across diff must be +2000 um');
          Assert.AreEqual(1.5, Results[I].AroundDiffMm, 0.0001, 'Around diff mm must be +1.5');
          Assert.AreEqual(2.0, Results[I].AcrossDiffMm, 0.0001, 'Across diff mm must be +2.0');
        end;
      end;
      Assert.IsTrue(Found, 'DIE-SS-28-NEAR2 must be found in search results');
    finally
      Results.Free;
    end;
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixDieTests.Test29_SmartSearch_ExcludedBeyondTolerance_153x100;
var
  DieID: Integer;
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
  Found: Boolean;
  I: Integer;
begin
  DieID := CreateAndSaveTestDie('DIE-SS-29-EXCL', 98, 153.0, 100.0, 2, 1, 'AVAILABLE', 'RECTANGLE', 'ROTARY', 0.0, 'Sub3mm gap override');
  try
    // Tolerance = 2.0 mm -> Must be excluded
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
        if Results[I].Die.SerialNo = 'DIE-SS-29-EXCL' then
          Found := True;
      Assert.IsFalse(Found, '153x100 must be excluded when tolerance is 2.0 mm');
    finally
      Results.Free;
    end;

    // Expand tolerance to 3.5 mm -> Must now be included
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 3.5);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
        if Results[I].Die.SerialNo = 'DIE-SS-29-EXCL' then
          Found := True;
      Assert.IsTrue(Found, '153x100 must be included when operator explicitly expands tolerance to 3.5 mm');
    finally
      Results.Free;
    end;
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixDieTests.Test30_SmartSearch_AroundPriorityOverAcrossProximity;
var
  DieA_ID, DieB_ID: Integer;
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
  IdxA, IdxB, I: Integer;
begin
  // Candidate A: Around diff +0.100 mm (100 um), Across diff +0.800 mm (800 um)
  // Candidate B: Around diff +0.500 mm (500 um), Across diff +0.050 mm (50 um)
  // Both are within 1.0 mm (Tier 1). Across proximity alone would pick B,
  // but Around has the highest search priority, so A MUST rank before B!
  DieA_ID := CreateAndSaveTestDie('DIE-SS-30-PRIO-A', 98, 150.100, 100.800, 2, 1);
  DieB_ID := CreateAndSaveTestDie('DIE-SS-30-PRIO-B', 98, 150.500, 100.050, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      IdxA := -1;
      IdxB := -1;
      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'DIE-SS-30-PRIO-A' then
          IdxA := I;
        if Results[I].Die.SerialNo = 'DIE-SS-30-PRIO-B' then
          IdxB := I;
      end;

      Assert.IsTrue(IdxA >= 0, 'Candidate A must be found');
      Assert.IsTrue(IdxB >= 0, 'Candidate B must be found');
      Assert.IsTrue(IdxA < IdxB, Format('Candidate A (Around diff 0.1mm) must rank before B (Around diff 0.5mm). IdxA=%d, IdxB=%d', [IdxA, IdxB]));
    finally
      Results.Free;
    end;
  finally
    FDieService.DeleteDie(DieA_ID);
    FDieService.DeleteDie(DieB_ID);
  end;
end;

procedure TDieVixDieTests.Test31_SmartSearch_AcrossSlittingCandidateReviewRequired;
var
  DieID: Integer;
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
  Found: Boolean;
  I: Integer;
begin
  DieID := CreateAndSaveTestDie('DIE-SS-31-SLIT', 98, 150.0, 108.0, 2, 1);
  try
    // 1. With IncludeSlitting = True
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Filter.IncludeSlitting := True;
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'DIE-SS-31-SLIT' then
        begin
          Found := True;
          Assert.IsTrue(Results[I].MatchClass = sdmSlittingCandidate, 'Must be classified as sdmSlittingCandidate');
          Assert.IsTrue(Pos('REVIEW REQUIRED', UpperCase(Results[I].ReusabilityNote)) > 0, 'Reusability note must indicate review is required');
        end;
      end;
      Assert.IsTrue(Found, 'Slitting candidate must be returned when IncludeSlitting is True');
    finally
      Results.Free;
    end;

    // 2. With IncludeSlitting = False
    Filter.IncludeSlitting := False;
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
        if Results[I].Die.SerialNo = 'DIE-SS-31-SLIT' then
          Found := True;
      Assert.IsFalse(Found, 'Slitting candidate must be excluded when IncludeSlitting is False');
    finally
      Results.Free;
    end;
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixDieTests.Test32_SmartSearch_InactiveOrScrappedDieFiltering;
var
  DieID: Integer;
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
  Found: Boolean;
  I: Integer;
begin
  DieID := CreateAndSaveTestDie('DIE-SS-32-SCRAP', 98, 150.0, 100.0, 2, 1, 'SCRAPPED');
  try
    // ActiveOnly = True -> Must be excluded
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Filter.ActiveOnly := True;
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
        if Results[I].Die.SerialNo = 'DIE-SS-32-SCRAP' then
          Found := True;
      Assert.IsFalse(Found, 'Scrapped die must be excluded when ActiveOnly is True');
    finally
      Results.Free;
    end;

    // Explicitly searching for SCRAPPED status -> Must be found
    Filter.ActiveOnly := False;
    Filter.StatusCode := 'SCRAPPED';
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
        if Results[I].Die.SerialNo = 'DIE-SS-32-SCRAP' then
          Found := True;
      Assert.IsTrue(Found, 'Scrapped die must be found when explicitly filtered by status');
    finally
      Results.Free;
    end;
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixDieTests.Test33_SmartSearch_IntegerMicrometreBoundaryHandling;
var
  DieIn1_ID, DieOut1_ID, DieIn2_ID, DieOut2_ID: Integer;
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
  FoundIn1, FoundOut1, FoundIn2, FoundOut2: Boolean;
  I: Integer;
begin
  DieIn1_ID := CreateAndSaveTestDie('DIE-SS-33-IN1', 98, 152.000, 100.0, 2, 1);
  DieOut1_ID := CreateAndSaveTestDie('DIE-SS-33-OUT1', 98, 152.001, 100.0, 2, 1);
  DieIn2_ID := CreateAndSaveTestDie('DIE-SS-33-IN2', 98, 148.000, 100.0, 2, 1);
  DieOut2_ID := CreateAndSaveTestDie('DIE-SS-33-OUT2', 98, 147.999, 100.0, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.000);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      FoundIn1 := False;
      FoundOut1 := False;
      FoundIn2 := False;
      FoundOut2 := False;

      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'DIE-SS-33-IN1' then FoundIn1 := True;
        if Results[I].Die.SerialNo = 'DIE-SS-33-OUT1' then FoundOut1 := True;
        if Results[I].Die.SerialNo = 'DIE-SS-33-IN2' then FoundIn2 := True;
        if Results[I].Die.SerialNo = 'DIE-SS-33-OUT2' then FoundOut2 := True;
      end;

      Assert.IsTrue(FoundIn1, '152.000 (+2000 um) must be included within 2.000 mm tolerance');
      Assert.IsFalse(FoundOut1, '152.001 (+2001 um) must be excluded from 2.000 mm tolerance');
      Assert.IsTrue(FoundIn2, '148.000 (-2000 um) must be included within 2.000 mm tolerance');
      Assert.IsFalse(FoundOut2, '147.999 (-2001 um) must be excluded from 2.000 mm tolerance');
    finally
      Results.Free;
    end;
  finally
    FDieService.DeleteDie(DieIn1_ID);
    FDieService.DeleteDie(DieOut1_ID);
    FDieService.DeleteDie(DieIn2_ID);
    FDieService.DeleteDie(DieOut2_ID);
  end;
end;

procedure TDieVixDieTests.Test34_SmartSearch_SqlParameterizationAndPagination;
var
  Die1_ID, Die2_ID, Die3_ID: Integer;
  Filter: TSmartDieSizeFilter;
  Page1, Page2: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
begin
  Die1_ID := CreateAndSaveTestDie('DIE-SS-34-PAG1', 98, 150.0, 100.0, 2, 1);
  Die2_ID := CreateAndSaveTestDie('DIE-SS-34-PAG2', 98, 150.2, 100.1, 2, 1);
  Die3_ID := CreateAndSaveTestDie('DIE-SS-34-PAG3', 98, 150.4, 100.2, 2, 1);
  try
    // Test Page 1 with PageSize = 2
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Filter.Page := 1;
    Filter.PageSize := 2;

    Page1 := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Assert.AreEqual(2, Page1.Count, 'Page 1 must return exactly 2 items');
      Assert.IsTrue(TotalCount >= 3, 'TotalCount must be at least 3');

      // Test Page 2 with PageSize = 2
      Filter.Page := 2;
      Filter.PageSize := 2;
      Page2 := FDieService.SmartSearchDies(Filter, TotalCount);
      try
        Assert.IsTrue(Page2.Count >= 1, 'Page 2 must return remaining items');
        Assert.AreNotEqual(Page1[0].Die.SerialNo, Page2[0].Die.SerialNo, 'Page 2 must have distinct items from Page 1');
      finally
        Page2.Free;
      end;
    finally
      Page1.Free;
    end;

    // Test SQL parameterization safety: injection strings in filters should not crash
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Filter.StatusCode := '''; DROP TABLE DIE; --';
    Filter.Shape := 'RECT''ANGLE';
    Filter.CutType := 'ROTARY"';
    Page1 := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      // Parameterized query must succeed and return 0 safely
      Assert.AreEqual(0, Page1.Count, 'Safe parameterized query with injection characters must return 0 without error');
    finally
      Page1.Free;
    end;
  finally
    FDieService.DeleteDie(Die1_ID);
    FDieService.DeleteDie(Die2_ID);
    FDieService.DeleteDie(Die3_ID);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixDieTests);

end.
