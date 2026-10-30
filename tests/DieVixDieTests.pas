unit DieVixDieTests;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  DUnitX Test Suite: Phase 3 Die Master Register, Inventory & Validation
  Comprehensive Firebird 5.0 integration tests operating on disposable database.
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
  DieVix.MasterDataService,
  DieVix.DieService,
  DieVix.CalculationEngine,
  frmDieRegister;

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

    { Phase 4 / Archive & Deletion Safety Tests }
    [Test]
    procedure Test35_ArchiveDieReferencedByLegacyStaging;

    [Test]
    procedure Test36_PreserveStagingReferences;

    [Test]
    procedure Test37_PreserveAuditHistory;

    [Test]
    procedure Test38_ArchivedDieExcludedFromActiveSearches;

    [Test]
    procedure Test39_ArchivedDieExcludedFromSmartDieFinder;

    [Test]
    procedure Test40_ArchivedDieExcludedFromKeylineCalculatorReuse;

    [Test]
    procedure Test41_ExplicitArchivedSearchIncludesArchivedDies;

    [Test]
    procedure Test42_RestoreArchivedDie;

    [Test]
    procedure Test43_ArchiveReasonValidation;

    [Test]
    procedure Test44_ConcurrencyConflictHandling;

    [Test]
    procedure Test45_PermanentDeletionBlockedWhenDependentRecordsExist;

    [Test]
    procedure Test46_PermanentDeletionBehaviorForUnreferencedDisposableDie;

    [Test]
    procedure Test47_TransactionRollback;

    [Test]
    procedure Test48_ExistingDieRegisterRegression;

    [Test]
    procedure Test49_ExistingKeylineCalculatorRegression;

    [Test]
    procedure Test50_WindowsUsernameCapturedAsDefaultActorAndAuditPreservedOnDelete;

    [Test]
    procedure Test51_DeletingDiePreservesAuditRowsUnchanged;

    [Test]
    procedure Test52_GenerateSerialNumber_FlexibleDie_IncludesSeconds;

    [Test]
    procedure Test53_GenerateSerialNumber_RotaryDie_Prefix;

    [Test]
    procedure Test54_SaveDie_AutoGeneratesSerialIfEmpty;
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
  AppCount: Integer;
  LogStr: string;
  Cust: TCustomer;
  Med: TMedia;
begin
  Mgr := TDieVixConnectionManager.Instance;
  FConn := Mgr.GetConnection;

  // Apply all pending migrations
  Mgr.ApplyMigrations(TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\migrations')), AppCount, LogStr);

  // Clean up any test dies from previous interrupted runs to ensure test hygiene
  FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-%'' OR CUSTOMER_ID IN (SELECT ID FROM CUSTOMER WHERE CODE = ''ZZTEST_CUST_PH3''))');
  FConn.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-%'' OR CUSTOMER_ID IN (SELECT ID FROM CUSTOMER WHERE CODE = ''ZZTEST_CUST_PH3'')');

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

  // Setup test customer and media (reuse if present from interrupted run)
  Cust := FCustomerRepo.GetByCode('ZZTEST_CUST_PH3');
  if Cust.ID > 0 then
    FTestCustID := Cust.ID
  else
  begin
    Cust := TCustomer.CreateNew('ZZTEST_CUST_PH3', 'Phase 3 Test Customer');
    FTestCustID := FCustomerRepo.Insert(Cust);
  end;

  Med := FMediaRepo.GetByCode('ZZTEST_MED_PH3');
  if Med.ID > 0 then
    FTestMediaID := Med.ID
  else
  begin
    Med := TMedia.CreateNew('ZZTEST_MED_PH3', 'Semi-Gloss 80g / Glassine 62g');
    FTestMediaID := FMediaRepo.Insert(Med);
  end;

  FTestDieID := 0;
end;

procedure TDieVixDieTests.TearDownFixture;
begin
  if Assigned(FConn) and FConn.Connected then
  begin
    try
      FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-%'' OR CUSTOMER_ID IN (SELECT ID FROM CUSTOMER WHERE CODE = ''ZZTEST_CUST_PH3''))');
      FConn.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-%'' OR CUSTOMER_ID IN (SELECT ID FROM CUSTOMER WHERE CODE = ''ZZTEST_CUST_PH3'')');
    except
    end;
  end;

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
  OK := TDieVixConnectionManager.Instance.ApplyMigrations(
    TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\migrations')), AppCount, LogStr);
  Assert.IsTrue(OK, 'Migration runner must succeed');
  Assert.AreEqual(0, AppCount, 'Second run must apply 0 scripts (idempotent)');
end;

procedure TDieVixDieTests.Test02_DieCreation;
var
  Die: TDie;
begin
  // Create a standard compliant rotary die: 96T, 98.0mm around, 50.0mm across, 3 around ups
  // Repeat = 96 * 3.175 = 304.8 mm. Total cut = 3 * 98 = 294 mm. Pool = 10.8 mm. Gap = 3.600 mm.
  Die := TDie.CreateNew('ZZTEST-PH3-001', 96, 98.0, 50.0, 3, 2);
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
  Assert.AreEqual('ZZTEST-PH3-001', DieByID.SerialNo, 'Serial must match');
  Assert.AreEqual(96, DieByID.Teeth, 'Teeth must be 96');
  Assert.AreEqual(3, DieByID.AroundUps, 'Around ups must be 3');
  Assert.AreEqual(2, DieByID.AcrossUps, 'Across ups must be 2');
  Assert.AreEqual(304.800, DieByID.RepeatMm, 0.001, 'Repeat mm must be 304.800');
  Assert.AreEqual(3.600, DieByID.AroundGapMm, 0.001, 'Around gap mm must be 3.600');
  Assert.AreEqual('RACK-A', DieByID.StorageRack, 'Storage rack must match');

  DieBySerial := FDieService.GetDieBySerial('zztest-ph3-001');
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
  DupDie := TDie.CreateNew('ZZTEST-PH3-001', 96, 98.0, 50.0, 3, 2);
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
  Exists := FDieService.CheckDuplicateSerial('zztest-ph3-001');
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
  Die := TDie.CreateNew('ZZTEST-PH3-EXACT3MM', 96, 98.600, 40.0, 3, 1);
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
  Die := TDie.CreateNew('ZZTEST-PH3-SUB3MM', 96, 98.700, 40.0, 3, 1);

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
    Die := TDie.CreateNew('ZZTEST-PH3-HARDBLOCK', 96, 99.200, 40.0, 3, 1);
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
  Die := TDie.CreateNew('ZZTEST-PH3-OVERSIZE', 96, 110.0, 40.0, 3, 1);
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
  Die := TDie.CreateNew('ZZTEST-PH3-HISTORICAL', 96, 98.0, 50.0, 3, 1);
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
    Assert.AreEqual('ZZTEST-PH3-001', Matches[0].Die.SerialNo, 'Serial must match');
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
    Qry.Transaction := Trans;

    Qry.SQL.Text := 'SELECT COUNT(*) FROM DIE';
    Qry.Open;
    InitialCount := Qry.Fields[0].AsInteger;
    Qry.Close;

    // Start explicit transaction and insert a temp die
    Trans.StartTransaction;
    Qry.SQL.Text :=
      'INSERT INTO DIE (SERIAL_NO, TEETH, AROUND_SIZE_MM, ACROSS_SIZE_MM, CREATED_BY) ' +
      'VALUES (''ZZTEST-ROLLBACK-001'', 96, 50.0, 50.0, ''TEST'')';
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
  Die := TDie.CreateNew('ZZTEST-PH3-GEOM-TEST', 106, 75.321, 62.456, 4, 3);
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
  Filter.SearchText := 'PH3-001'; // Matches serial ZZTEST-PH3-001
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
  Die := TDie.CreateNew('ZZTEST-PH3-ZERO-DIM', 96, 0.0, 50.0, 1, 1);
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
  Die := TDie.CreateNew('ZZTEST-PH3-HUGE', 132, 999999.0, 50.0, 1, 1);
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
  DieID := CreateAndSaveTestDie('ZZTEST-SS-26-EXACT', 98, 150.0, 100.0, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Assert.IsTrue(Results.Count > 0, 'Exact match must return at least one die');
      Assert.AreEqual('ZZTEST-SS-26-EXACT', Results[0].Die.SerialNo, 'Exact match must be ranked first');
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
  DieID := CreateAndSaveTestDie('ZZTEST-SS-27-NEAR1', 98, 149.0, 100.0, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'ZZTEST-SS-27-NEAR1' then
        begin
          Found := True;
          Assert.IsTrue(Results[I].MatchClass = sdmNearMatchTier1, '149x100 must be classified as Tier 1 near match');
          Assert.AreEqual(Int64(-1000), Results[I].AroundDiffUm, 'Around diff must be -1000 um');
          Assert.AreEqual(Int64(0), Results[I].AcrossDiffUm, 'Across diff must be 0 um');
          Assert.AreEqual(-1.0, Results[I].AroundDiffMm, 0.0001, 'Around diff mm must be -1.0');
          Assert.AreEqual(0.0, Results[I].AcrossDiffMm, 0.0001, 'Across diff mm must be 0.0');
        end;
      end;
      Assert.IsTrue(Found, 'ZZTEST-SS-27-NEAR1 must be found in search results');
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
  DieID := CreateAndSaveTestDie('ZZTEST-SS-28-NEAR2', 98, 151.5, 102.0, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'ZZTEST-SS-28-NEAR2' then
        begin
          Found := True;
          Assert.IsTrue(Results[I].MatchClass = sdmNearMatchTier2, '151.5x102 must be classified as Tier 2 near match');
          Assert.AreEqual(Int64(1500), Results[I].AroundDiffUm, 'Around diff must be +1500 um');
          Assert.AreEqual(Int64(2000), Results[I].AcrossDiffUm, 'Across diff must be +2000 um');
          Assert.AreEqual(1.5, Results[I].AroundDiffMm, 0.0001, 'Around diff mm must be +1.5');
          Assert.AreEqual(2.0, Results[I].AcrossDiffMm, 0.0001, 'Across diff mm must be +2.0');
        end;
      end;
      Assert.IsTrue(Found, 'ZZTEST-SS-28-NEAR2 must be found in search results');
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
  DieID := CreateAndSaveTestDie('ZZTEST-SS-29-EXCL', 98, 153.0, 100.0, 2, 1, 'AVAILABLE', 'RECTANGLE', 'ROTARY', 0.0, 'Sub3mm gap override');
  try
    // Tolerance = 2.0 mm -> Must be excluded
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
        if Results[I].Die.SerialNo = 'ZZTEST-SS-29-EXCL' then
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
        if Results[I].Die.SerialNo = 'ZZTEST-SS-29-EXCL' then
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
  DieA_ID := CreateAndSaveTestDie('ZZTEST-SS-30-PRIO-A', 98, 150.100, 100.800, 2, 1);
  DieB_ID := CreateAndSaveTestDie('ZZTEST-SS-30-PRIO-B', 98, 150.500, 100.050, 2, 1);
  try
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      IdxA := -1;
      IdxB := -1;
      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'ZZTEST-SS-30-PRIO-A' then
          IdxA := I;
        if Results[I].Die.SerialNo = 'ZZTEST-SS-30-PRIO-B' then
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
  DieID := CreateAndSaveTestDie('ZZTEST-SS-31-SLIT', 98, 150.0, 108.0, 2, 1);
  try
    // 1. With IncludeSlitting = True
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Filter.IncludeSlitting := True;
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
      begin
        if Results[I].Die.SerialNo = 'ZZTEST-SS-31-SLIT' then
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
        if Results[I].Die.SerialNo = 'ZZTEST-SS-31-SLIT' then
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
  DieID := CreateAndSaveTestDie('ZZTEST-SS-32-SCRAP', 98, 150.0, 100.0, 2, 1, 'SCRAPPED');
  try
    // ActiveOnly = True -> Must be excluded
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Filter.ActiveOnly := True;
    Results := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Found := False;
      for I := 0 to Results.Count - 1 do
        if Results[I].Die.SerialNo = 'ZZTEST-SS-32-SCRAP' then
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
        if Results[I].Die.SerialNo = 'ZZTEST-SS-32-SCRAP' then
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
  DieIn1_ID := CreateAndSaveTestDie('ZZTEST-SS-33-IN1', 98, 152.000, 100.0, 2, 1);
  DieOut1_ID := CreateAndSaveTestDie('ZZTEST-SS-33-OUT1', 98, 152.001, 100.0, 2, 1);
  DieIn2_ID := CreateAndSaveTestDie('ZZTEST-SS-33-IN2', 98, 148.000, 100.0, 2, 1);
  DieOut2_ID := CreateAndSaveTestDie('ZZTEST-SS-33-OUT2', 98, 147.999, 100.0, 2, 1);
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
        if Results[I].Die.SerialNo = 'ZZTEST-SS-33-IN1' then FoundIn1 := True;
        if Results[I].Die.SerialNo = 'ZZTEST-SS-33-OUT1' then FoundOut1 := True;
        if Results[I].Die.SerialNo = 'ZZTEST-SS-33-IN2' then FoundIn2 := True;
        if Results[I].Die.SerialNo = 'ZZTEST-SS-33-OUT2' then FoundOut2 := True;
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
  Die1_ID := CreateAndSaveTestDie('ZZTEST-SS-34-PAG1', 98, 150.0, 100.0, 2, 1);
  Die2_ID := CreateAndSaveTestDie('ZZTEST-SS-34-PAG2', 98, 150.2, 100.1, 2, 1);
  Die3_ID := CreateAndSaveTestDie('ZZTEST-SS-34-PAG3', 98, 150.4, 100.2, 2, 1);
  try
    // Test Page 1 with PageSize = 2
    Filter := TSmartDieSizeFilter.CreateDefault(150.0, 100.0, 2.0);
    Filter.Page := 1;
    Filter.PageSize := 2;

    Page1 := FDieService.SmartSearchDies(Filter, TotalCount);
    try
      Assert.AreEqual(2, Integer(Page1.Count), 'Page 1 must return exactly 2 items');
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
      Assert.AreEqual(0, Integer(Page1.Count), 'Safe parameterized query with injection characters must return 0 without error');
    finally
      Page1.Free;
    end;
  finally
    FDieService.DeleteDie(Die1_ID);
    FDieService.DeleteDie(Die2_ID);
    FDieService.DeleteDie(Die3_ID);
  end;
end;

procedure TDieVixDieTests.Test35_ArchiveDieReferencedByLegacyStaging;
var
  DieID: Integer;
  Die: TDie;
  Qry: TFDQuery;
begin
  // Create a die and link it to STAGING_LEGACY_KEYLINE
  DieID := CreateAndSaveTestDie('ZZTEST-ARC-STG-001', 96, 98.0, 50.0, 3, 2);
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'INSERT INTO STAGING_LEGACY_KEYLINE (RAW_SERIAL, IMPORT_STATUS, CLEANED_DIE_ID, VALIDATION_NOTE) ' +
                    'VALUES (''RAW-STG-001'', ''IMPORTED'', :DIE_ID, ''Legacy import test link'')';
    Qry.ParamByName('DIE_ID').AsInteger := DieID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;

  // Archive the die
  FDieService.ArchiveDie(DieID, 'Customer rebranded artwork - tooling retired to archive', 'OPERATOR_ARCHIVE');

  Die := FDieService.GetDieByID(DieID);
  Assert.AreEqual('ARCHIVED', Die.StatusCode, 'Die status must be ARCHIVED after archiving');
  Assert.AreEqual(2, Die.Version, 'Die version must increment after archiving');
end;

procedure TDieVixDieTests.Test36_PreserveStagingReferences;
var
  Die: TDie;
  Qry: TFDQuery;
  StagingCount: Integer;
begin
  Die := FDieService.GetDieBySerial('ZZTEST-ARC-STG-001');
  Assert.IsTrue(Die.ID > 0, 'Test die must exist');

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT COUNT(*) FROM STAGING_LEGACY_KEYLINE WHERE CLEANED_DIE_ID = :DIE_ID';
    Qry.ParamByName('DIE_ID').AsInteger := Die.ID;
    Qry.Open;
    StagingCount := Qry.Fields[0].AsInteger;
    Qry.Close;

    Assert.IsTrue(StagingCount > 0, 'Staging record reference must remain completely intact');
  finally
    Qry.Free;
  end;
end;

procedure TDieVixDieTests.Test37_PreserveAuditHistory;
var
  Die: TDie;
  Qry: TFDQuery;
  FoundArchiveAudit: Boolean;
begin
  Die := FDieService.GetDieBySerial('ZZTEST-ARC-STG-001');
  Assert.IsTrue(Die.ID > 0, 'Test die must exist');

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT ACTION, DETAILS, CHANGED_BY FROM DIE_AUDIT_LOG WHERE DIE_ID = :DIE_ID AND ACTION = ''ARCHIVE''';
    Qry.ParamByName('DIE_ID').AsInteger := Die.ID;
    Qry.Open;
    FoundArchiveAudit := not Qry.IsEmpty;
    if FoundArchiveAudit then
    begin
      Assert.AreEqual('ARCHIVE', Qry.FieldByName('ACTION').AsString);
      Assert.IsTrue(Pos('Customer rebranded artwork', Qry.FieldByName('DETAILS').AsString) > 0, 'Audit details must record archive reason');
      Assert.AreEqual('OPERATOR_ARCHIVE', Qry.FieldByName('CHANGED_BY').AsString);
    end;
    Qry.Close;

    Assert.IsTrue(FoundArchiveAudit, 'Audit log must record ARCHIVE action with reason and operator');
  finally
    Qry.Free;
  end;
end;

procedure TDieVixDieTests.Test38_ArchivedDieExcludedFromActiveSearches;
var
  Filter: TDieSearchFilter;
  Results: TList<TDie>;
  Found: Boolean;
  I: Integer;
begin
  Filter := TDieSearchFilter.Default;
  Filter.IncludeArchived := False;
  Filter.SearchText := 'ZZTEST-ARC-STG-001';

  Results := FDieService.SearchDies(Filter);
  try
    Found := False;
    for I := 0 to Results.Count - 1 do
      if Results[I].SerialNo = 'ZZTEST-ARC-STG-001' then
        Found := True;

    Assert.IsFalse(Found, 'Archived die must be excluded from default active searches');
  finally
    Results.Free;
  end;
end;

procedure TDieVixDieTests.Test39_ArchivedDieExcludedFromSmartDieFinder;
var
  Filter: TSmartDieSizeFilter;
  Results: TList<TSmartDieSearchResult>;
  TotalCount: Integer;
  Found: Boolean;
  I: Integer;
begin
  Filter := TSmartDieSizeFilter.CreateDefault(98.0, 50.0, 1.0);
  Filter.IncludeArchived := False;

  Results := FDieService.SmartSearchDies(Filter, TotalCount);
  try
    Found := False;
    for I := 0 to Results.Count - 1 do
      if Results[I].Die.SerialNo = 'ZZTEST-ARC-STG-001' then
        Found := True;

    Assert.IsFalse(Found, 'Archived die must be excluded from Smart Die Finder when IncludeArchived is False');
  finally
    Results.Free;
  end;
end;

procedure TDieVixDieTests.Test40_ArchivedDieExcludedFromKeylineCalculatorReuse;
var
  Similar: TList<TSimilarDieResult>;
  Found: Boolean;
  I: Integer;
begin
  Similar := FDieService.FindSimilarDies(96, 98.0, 50.0, 3, 2, 'RECTANGLE', 1.0);
  try
    Found := False;
    for I := 0 to Similar.Count - 1 do
      if Similar[I].Die.SerialNo = 'ZZTEST-ARC-STG-001' then
        Found := True;

    Assert.IsFalse(Found, 'Archived die must not be suggested for tooling reuse');
  finally
    Similar.Free;
  end;
end;

procedure TDieVixDieTests.Test41_ExplicitArchivedSearchIncludesArchivedDies;
var
  Filter: TDieSearchFilter;
  Results: TList<TDie>;
  Found: Boolean;
  I: Integer;
begin
  // Test 1: IncludeArchived = True
  Filter := TDieSearchFilter.Default;
  Filter.IncludeArchived := True;
  Filter.SearchText := 'ZZTEST-ARC-STG-001';

  Results := FDieService.SearchDies(Filter);
  try
    Found := False;
    for I := 0 to Results.Count - 1 do
      if Results[I].SerialNo = 'ZZTEST-ARC-STG-001' then
        Found := True;

    Assert.IsTrue(Found, 'Explicit search with IncludeArchived = True must find archived dies');
  finally
    Results.Free;
  end;

  // Test 2: Filter by StatusCode = 'ARCHIVED'
  Filter := TDieSearchFilter.Default;
  Filter.StatusCode := 'ARCHIVED';
  Filter.SearchText := 'ZZTEST-ARC-STG-001';

  Results := FDieService.SearchDies(Filter);
  try
    Found := False;
    for I := 0 to Results.Count - 1 do
      if Results[I].SerialNo = 'ZZTEST-ARC-STG-001' then
        Found := True;

    Assert.IsTrue(Found, 'Search with StatusCode = ARCHIVED must find archived dies');
  finally
    Results.Free;
  end;
end;

procedure TDieVixDieTests.Test42_RestoreArchivedDie;
var
  Die: TDie;
  Filter: TDieSearchFilter;
  Results: TList<TDie>;
  Qry: TFDQuery;
  FoundRestoreAudit: Boolean;
begin
  Die := FDieService.GetDieBySerial('ZZTEST-ARC-STG-001');
  Assert.IsTrue(Die.ID > 0, 'Test die must exist');
  Assert.AreEqual('ARCHIVED', Die.StatusCode);

  // Restore the die
  FDieService.RestoreDie(Die.ID, 'Customer re-activated original artwork', 'OPERATOR_RESTORE');

  Die := FDieService.GetDieByID(Die.ID);
  Assert.AreEqual('ACTIVE', Die.StatusCode, 'Restored die status must be ACTIVE');
  Assert.AreEqual(3, Die.Version, 'Restored die version must increment');

  // Verify RESTORE audit log
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT ACTION, DETAILS, CHANGED_BY FROM DIE_AUDIT_LOG WHERE DIE_ID = :DIE_ID AND ACTION = ''RESTORE''';
    Qry.ParamByName('DIE_ID').AsInteger := Die.ID;
    Qry.Open;
    FoundRestoreAudit := not Qry.IsEmpty;
    if FoundRestoreAudit then
    begin
      Assert.AreEqual('RESTORE', Qry.FieldByName('ACTION').AsString);
      Assert.IsTrue(Pos('Customer re-activated original artwork', Qry.FieldByName('DETAILS').AsString) > 0, 'Audit details must record restore reason');
      Assert.AreEqual('OPERATOR_RESTORE', Qry.FieldByName('CHANGED_BY').AsString);
    end;
    Qry.Close;

    Assert.IsTrue(FoundRestoreAudit, 'Audit log must record RESTORE action');
  finally
    Qry.Free;
  end;

  // Verify it appears in active searches again
  Filter := TDieSearchFilter.Default;
  Filter.IncludeArchived := False;
  Filter.SearchText := 'ZZTEST-ARC-STG-001';
  Results := FDieService.SearchDies(Filter);
  try
    Assert.IsTrue(Results.Count > 0, 'Restored die must appear in default active searches');
  finally
    Results.Free;
  end;
end;

procedure TDieVixDieTests.Test43_ArchiveReasonValidation;
var
  Die: TDie;
  RaisedEmpty: Boolean;
begin
  Die := FDieService.GetDieBySerial('ZZTEST-ARC-STG-001');
  Assert.IsTrue(Die.ID > 0, 'Test die must exist');

  RaisedEmpty := False;
  try
    FDieService.ArchiveDie(Die.ID, '   ', 'OPERATOR');
  except
    on E: EDieVixValidationException do
      RaisedEmpty := True;
  end;

  Assert.IsTrue(RaisedEmpty, 'Empty archive reason must raise EDieVixValidationException');
end;

procedure TDieVixDieTests.Test44_ConcurrencyConflictHandling;
var
  Die: TDie;
  Qry: TFDQuery;
  RaisedConflict: Boolean;
begin
  Die := FDieService.GetDieBySerial('ZZTEST-ARC-STG-001');
  Assert.IsTrue(Die.ID > 0, 'Test die must exist');

  // Simulate a concurrent modification by another user incrementing version in DB
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'UPDATE DIE SET VERSION = VERSION + 10 WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := Die.ID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;

  // Stale attempt to archive must detect version conflict because caller holds stale Die.Version
  RaisedConflict := False;
  try
    FDieService.ArchiveDie(Die.ID, 'Valid reason', 'OPERATOR', Die.Version);
  except
    on E: EDieVixConcurrencyException do
      RaisedConflict := True;
  end;

  Assert.IsTrue(RaisedConflict, 'Concurrency mismatch on die archive must raise EDieVixConcurrencyException');
end;

procedure TDieVixDieTests.Test45_PermanentDeletionBlockedWhenDependentRecordsExist;
var
  Die: TDie;
  CanDelete: Boolean;
  RefusalReason: string;
  RaisedValidation: Boolean;
  Qry: TFDQuery;
begin
  Die := FDieService.GetDieBySerial('ZZTEST-ARC-STG-001');
  Assert.IsTrue(Die.ID > 0, 'Test die must exist');

  // Pre-flight check
  CanDelete := FDieService.CanPermanentlyDeleteDie(Die.ID, RefusalReason);
  Assert.IsFalse(CanDelete, 'CanPermanentlyDeleteDie must return False when staging records exist');
  Assert.IsTrue(Pos('STAGING_LEGACY_KEYLINE', RefusalReason) > 0, 'Refusal reason must explain staging link');

  // Attempt permanent delete
  RaisedValidation := False;
  try
    FDieService.PermanentlyDeleteDie(Die.ID, True);
  except
    on E: EDieVixValidationException do
    begin
      RaisedValidation := True;
      Assert.IsTrue(Pos('STAGING_LEGACY_KEYLINE', E.Message) > 0, 'Validation exception must explain refusal reason');
    end;
  end;

  Assert.IsTrue(RaisedValidation, 'PermanentlyDeleteDie must raise EDieVixValidationException when dependent rows exist');

  // Clean up the staging row created for this test series so we leave database clean
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'DELETE FROM STAGING_LEGACY_KEYLINE WHERE CLEANED_DIE_ID = :ID';
    Qry.ParamByName('ID').AsInteger := Die.ID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;

  FDieService.DeleteDie(Die.ID);
end;

procedure TDieVixDieTests.Test46_PermanentDeletionBehaviorForUnreferencedDisposableDie;
var
  DieID: Integer;
  CanDelete: Boolean;
  RefusalReason: string;
  DeletedOK: Boolean;
  DeletedDie: TDie;
begin
  DieID := CreateAndSaveTestDie('ZZTEST-DISP-001', 98, 120.0, 60.0, 2, 2);

  CanDelete := FDieService.CanPermanentlyDeleteDie(DieID, RefusalReason);
  Assert.IsTrue(CanDelete, 'Unreferenced disposable die must be eligible for permanent deletion');
  Assert.AreEqual('', RefusalReason, 'Refusal reason must be empty when deletion is allowed');

  DeletedOK := FDieService.PermanentlyDeleteDie(DieID, True);
  Assert.IsTrue(DeletedOK, 'PermanentlyDeleteDie must return True for disposable die');

  DeletedDie := FDieService.GetDieByID(DieID);
  Assert.AreEqual(0, DeletedDie.ID, 'Deleted die must no longer exist in database');
end;

procedure TDieVixDieTests.Test47_TransactionRollback;
var
  DieID: Integer;
  OriginalDie, AfterDie: TDie;
  RaisedEx: Boolean;
begin
  DieID := CreateAndSaveTestDie('ZZTEST-TX-ROLL-001', 96, 98.0, 50.0, 3, 2);
  try
    OriginalDie := FDieService.GetDieByID(DieID);

    // Call ArchiveDie with invalid empty reason
    RaisedEx := False;
    try
      FDieService.ArchiveDie(DieID, '', 'OPERATOR');
    except
      on E: EDieVixValidationException do
        RaisedEx := True;
    end;
    Assert.IsTrue(RaisedEx, 'Validation exception expected');

    // Verify die remained in original status and version
    AfterDie := FDieService.GetDieByID(DieID);
    Assert.AreEqual(OriginalDie.StatusCode, AfterDie.StatusCode, 'Die status must not change after failed operation');
    Assert.AreEqual(OriginalDie.Version, AfterDie.Version, 'Die version must not increment after failed operation');
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixDieTests.Test48_ExistingDieRegisterRegression;
var
  Filter: TDieSearchFilter;
  Results: TList<TDie>;
  Form: TfrmDieRegister;
begin
  // Test Form construction and DFM loading
  Form := TfrmDieRegister.Create(nil);
  try
    Assert.IsNotNull(Form, 'frmDieRegister must be constructed successfully from DFM');
    Assert.IsNotNull(Form.chkIncludeArchived, 'chkIncludeArchived must be bound from DFM');
    Assert.IsNotNull(Form.btnArchive, 'btnArchive must be bound from DFM');
    Assert.IsNotNull(Form.btnRestore, 'btnRestore must be bound from DFM');
    Assert.IsNotNull(Form.btnPermanentDelete, 'btnPermanentDelete must be bound from DFM');
  finally
    Form.Free;
  end;

  // Test standard active search regression
  Filter := TDieSearchFilter.Default;
  Results := FDieService.SearchDies(Filter);
  try
    Assert.IsTrue(Results.Count > 0, 'Standard register search must return tooling records');
  finally
    Results.Free;
  end;
end;

procedure TDieVixDieTests.Test49_ExistingKeylineCalculatorRegression;
var
  GapRes: TGapResult;
begin
  GapRes := CalculateAroundGapFromMm(96, 98.0, 3);
  Assert.AreEqual(3.600, GapRes.AroundGapMm, 0.001, 'Around gap mm must be 3.600');
  Assert.AreEqual(304.800, GapRes.CylinderRepeatMm, 0.001, 'Cylinder repeat mm must be 304.800');
  Assert.IsTrue(GapRes.Status in [gsOptimal, gsStandardApproved], 'Gap status must be approved');
end;

procedure TDieVixDieTests.Test50_WindowsUsernameCapturedAsDefaultActorAndAuditPreservedOnDelete;
var
  Die: TDie;
  DieID: Integer;
  ExpectedUser: string;
  AuditList: TList<TDieAuditEntry>;
  Qry: TFDQuery;
  RetainedAuditCount: Integer;
begin
  ExpectedUser := GetCurrentAppUser;
  Assert.IsTrue(ExpectedUser <> '', 'Expected Windows username must not be empty');

  // 1. Create die without explicitly specifying actor
  Die := TDie.CreateNew('ZZTEST-ACTOR-TEST-001', 96, 98.0, 50.0, 3, 2);
  Die.CustomerID := FTestCustID;
  Die.MediaID := FTestMediaID;
  DieID := FDieService.SaveDie(Die);
  try
    Assert.IsTrue(DieID > 0, 'Die tooling record must be saved');

    // 2. Assert CreatedBy and UpdatedBy match current Windows user
    Die := FDieService.GetDieByID(DieID);
    Assert.AreEqual(ExpectedUser, Die.CreatedBy, 'CreatedBy must capture current Windows user');
    Assert.AreEqual(ExpectedUser, Die.UpdatedBy, 'UpdatedBy must capture current Windows user');

    // 3. Assert initial CREATE audit record captures current Windows user
    AuditList := FDieService.GetDieAuditHistory(DieID);
    try
      Assert.IsTrue(AuditList.Count > 0, 'Audit history must contain CREATE entry');
      Assert.AreEqual(ExpectedUser, AuditList[0].ChangedBy, 'CREATE audit record ChangedBy must match Windows user');
    finally
      AuditList.Free;
    end;

    // 4. Change status with default actor parameter and verify audit
    Assert.IsTrue(FDieService.ChangeDieStatus(DieID, 'REPAIR', 'Testing default actor propagation'));
    AuditList := FDieService.GetDieAuditHistory(DieID);
    try
      Assert.AreEqual(ExpectedUser, AuditList[AuditList.Count - 1].ChangedBy, 'STATUS_CHANGE audit record ChangedBy must match Windows user');
    finally
      AuditList.Free;
    end;
  finally
    // 5. Permanently delete the die
    Assert.IsTrue(FDieService.PermanentlyDeleteDie(DieID, True), 'PermanentlyDeleteDie must succeed');
  end;

  // 6. Assert die is deleted from DIE table
  Die := FDieService.GetDieByID(DieID);
  Assert.AreEqual(0, Die.ID, 'Deleted die must no longer exist in DIE table');

  // 7. Assert audit records still exist in DIE_AUDIT_LOG with original DIE_ID (Task B integrity)
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) FROM DIE_AUDIT_LOG ' +
      'WHERE DIE_ID = :ID AND CHANGED_BY = :USER';
    Qry.ParamByName('ID').AsInteger := DieID;
    Qry.ParamByName('USER').AsString := ExpectedUser;
    Qry.Open;
    RetainedAuditCount := Qry.Fields[0].AsInteger;
    Qry.Close;

    Assert.IsTrue(RetainedAuditCount >= 2, Format('Audit entries (%d) must be retained with original DIE_ID after die deletion', [RetainedAuditCount]));
  finally
    Qry.Free;
    FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID = ' + IntToStr(DieID));
  end;
end;

procedure TDieVixDieTests.Test51_DeletingDiePreservesAuditRowsUnchanged;
var
  Die: TDie;
  DieID: Integer;
  AuditEntry: TDieAuditEntry;
  LongDetails: string;
  BeforeRows: TList<TDieAuditEntry>;
  AfterRows: TList<TDieAuditEntry>;
  I, J: Integer;
  FoundPermDelete: Boolean;
  PermDeleteEntry: TDieAuditEntry;
  FoundMatch: Boolean;
begin
  // 1. Create a die
  Die := TDie.CreateNew('ZZTEST-AUDIT-PRESERVE-01', 96, 98.0, 50.0, 3, 2);
  Die.CustomerID := FTestCustID;
  Die.MediaID := FTestMediaID;
  DieID := FDieService.SaveDie(Die);
  Assert.IsTrue(DieID > 0, 'Die tooling record must be saved');

  // 2. Perform actions to generate multiple diverse audit rows
  FDieService.ChangeDieStatus(DieID, 'REPAIR', 'Routine inspection');
  FDieService.UpdateDieLocation(DieID, 'RACK-B', 'SHELF-02', 'BIN-05', 'Moved for staging');

  // 3. Add an audit row with near-500-character DETAILS (490 chars)
  LongDetails := StringOfChar('X', 490);
  AuditEntry := TDieAuditEntry.CreateEntry(DieID, 'MAINTENANCE_NOTE', LongDetails);
  AuditEntry.FieldName := 'NOTES';
  AuditEntry.OldValue := 'None';
  AuditEntry.NewValue := 'Maintenance scheduled';
  Assert.IsTrue(FDieRepo.AddAuditEntry(AuditEntry));

  // 4. Capture snapshot of all audit rows before deletion
  BeforeRows := FDieRepo.GetAuditLog(DieID);
  try
    Assert.IsTrue(BeforeRows.Count >= 4, 'Must have at least 4 audit rows before delete');

    // 5. Permanently delete the die (Task B requirement: no error with near-500 char details!)
    Assert.IsTrue(FDieService.PermanentlyDeleteDie(DieID, True),
      'PermanentlyDeleteDie must succeed without error even with near-500-char audit details');

    // 6. Assert die is deleted from DIE table
    Assert.AreEqual(0, FDieService.GetDieByID(DieID).ID, 'Die must no longer exist in DIE table');

    // 7. Retrieve audit rows after deletion
    AfterRows := FDieRepo.GetAuditLog(DieID);
    try
      // (a) Deleting a die leaves all its previous audit rows unchanged (compare before/after)
      // AfterRows contains all BeforeRows PLUS the new PERMANENT_DELETE row
      Assert.AreEqual(Integer(BeforeRows.Count) + 1, Integer(AfterRows.Count),
        'Audit row count after delete must be exactly BeforeRows.Count + 1');

      FoundPermDelete := False;
      PermDeleteEntry := Default(TDieAuditEntry);
      for I := 0 to AfterRows.Count - 1 do
      begin
        if AfterRows[I].Action = 'PERMANENT_DELETE' then
        begin
          FoundPermDelete := True;
          PermDeleteEntry := AfterRows[I];
        end;
      end;

      // (b) Assert PERMANENT_DELETE row exists, with correct DieID and serial number
      Assert.IsTrue(FoundPermDelete, 'A PERMANENT_DELETE audit row must exist');
      Assert.AreEqual(DieID, PermDeleteEntry.DieID, 'PERMANENT_DELETE row must have the original DieID');
      Assert.IsTrue(Pos('ZZTEST-AUDIT-PRESERVE-01', PermDeleteEntry.Details) > 0,
        'PERMANENT_DELETE row details must record the serial number');

      // Verify that every single row that existed before deletion is 100% identical after deletion
      for I := 0 to BeforeRows.Count - 1 do
      begin
        FoundMatch := False;
        for J := 0 to AfterRows.Count - 1 do
        begin
          if AfterRows[J].ID = BeforeRows[I].ID then
          begin
            FoundMatch := True;
            Assert.AreEqual(BeforeRows[I].DieID, AfterRows[J].DieID, 'DieID must remain original (not nulled)');
            Assert.AreEqual(BeforeRows[I].Action, AfterRows[J].Action, 'Action must be unchanged');
            Assert.AreEqual(BeforeRows[I].FieldName, AfterRows[J].FieldName, 'FieldName must be unchanged');
            Assert.AreEqual(BeforeRows[I].OldValue, AfterRows[J].OldValue, 'OldValue must be unchanged');
            Assert.AreEqual(BeforeRows[I].NewValue, AfterRows[J].NewValue, 'NewValue must be unchanged');
            Assert.AreEqual(BeforeRows[I].Details, AfterRows[J].Details, 'Details must NOT have been modified');
            Assert.AreEqual(BeforeRows[I].ChangedBy, AfterRows[J].ChangedBy, 'ChangedBy must be unchanged');
            Break;
          end;
        end;
        Assert.IsTrue(FoundMatch, Format('Before-deletion audit row ID %d must be found unchanged after deletion', [BeforeRows[I].ID]));
      end;

      // Also verify Task B.3 and Task H: GetAuditLog on deleted die displays serial directly from DIE_SERIAL_NO
      Assert.AreEqual('ZZTEST-AUDIT-PRESERVE-01', PermDeleteEntry.SerialNumber,
        'Deleted die audit entry must have serial number in SerialNumber field');
      for I := 0 to AfterRows.Count - 1 do
        Assert.AreEqual('ZZTEST-AUDIT-PRESERVE-01', AfterRows[I].SerialNumber,
          'All audit entries after die deletion must preserve SerialNumber');

    finally
      AfterRows.Free;
    end;
  finally
    BeforeRows.Free;
    // Cleanup audit records for test die
    FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID = ' + IntToStr(DieID));
  end;
end;

procedure TDieVixDieTests.Test52_GenerateSerialNumber_FlexibleDie_IncludesSeconds;
var
  Serial1, Serial2: string;
begin
  Serial1 := FDieService.GenerateSerialNumber('FLEXIBLE');
  Assert.IsTrue(Serial1.StartsWith('FLD-'), 'Flexible die serial must start with FLD-');
  Assert.IsTrue(Length(Serial1) >= 17, 'Serial must have at least 17 chars (FLD-YYMMDD-HHNNSS): ' + Serial1);
  Assert.AreEqual('-', Serial1[4], 'Expected dash after FLD');
  Assert.AreEqual('-', Serial1[11], 'Expected dash after date');

  Serial2 := FDieService.GenerateSerialNumber('FLEXIBLE');
  Assert.IsTrue(Serial2.StartsWith('FLD-'));
  Assert.AreNotEqual(Serial1, Serial2, 'Consecutive serial generations must produce distinct values');
end;

procedure TDieVixDieTests.Test53_GenerateSerialNumber_RotaryDie_Prefix;
var
  Serial: string;
begin
  Serial := FDieService.GenerateSerialNumber('ROTARY');
  Assert.IsTrue(Serial.StartsWith('DIE-'), 'Rotary die serial must start with DIE-');
  Assert.IsTrue(Length(Serial) >= 17, 'Serial must have at least 17 chars (DIE-YYMMDD-HHNNSS): ' + Serial);
end;

procedure TDieVixDieTests.Test54_SaveDie_AutoGeneratesSerialIfEmpty;
var
  Die, Fetched: TDie;
  SavedID: Integer;
begin
  SavedID := 0;
  try
    Die := TDie.CreateNew('', 96, 50.0, 50.0, 1, 1);
    Die.CutType := 'FLEXIBLE';
    Die.Description := 'Test Auto-generated Serial Flexi Die';
    SavedID := FDieService.SaveDie(Die, 'TEST_RUNNER');
    Assert.IsTrue(SavedID > 0, 'Die with empty serial must save successfully via auto-generation');

    Fetched := FDieService.GetDieByID(SavedID);
    Assert.IsTrue(Fetched.SerialNo.StartsWith('FLD-'), 'Auto-generated serial must start with FLD- for flexible die');
    Assert.IsTrue(Length(Fetched.SerialNo) >= 17, 'Auto-generated serial must include seconds');
  finally
    if SavedID > 0 then
      FDieService.PermanentlyDeleteDie(SavedID, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixDieTests);

end.
