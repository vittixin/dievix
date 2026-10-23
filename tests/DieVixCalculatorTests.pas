unit DieVixCalculatorTests;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  DUnitX Test Suite: Phase 4 Keyline Calculator & Cylinder Optimization
  Validates pure integer-micrometre rotary geometry, machine web-fit,
  cylinder fleet recommendations, die reuse, and draft die creation.
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
  DieVix.KeylineService,
  DieVix.CalculationEngine;

type
  [TestFixture]
  TDieVixCalculatorTests = class
  private
    FConn: TFDConnection;
    FKeylineService: TKeylineService;
    FDieService: TDieService;
    FMasterService: TMasterDataService;
    FDieRepo: IDieRepository;
    FSettingRepo: IAppSettingRepository;
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FCylinderRepo: ICylinderRepository;
    FMachineRepo: IMachineRepository;
    FMachineCylinderRepo: IMachineCylinderRepository;
    FStatusRepo: IDieStatusRepository;
    FTestMachID: Integer;
    FTestCustID: Integer;
    FTestMediaID: Integer;
  public
    [SetupFixture]
    procedure SetupFixture;

    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure Test01_RepeatFormula_96Tx3175um;

    [Test]
    procedure Test02_AroundGap_96T_98mm_3ups;

    [Test]
    procedure Test03_Exact3000mmBoundary;

    [Test]
    procedure Test04_FractionalMicrometreGapComparison;

    [Test]
    procedure Test05_CylinderSelectionNonUniformFleet;

    [Test]
    procedure Test06_AutomaticUpsScan;

    [Test]
    procedure Test07_FixedUpsRecommendation;

    [Test]
    procedure Test08_NextLargerCylinderRecommendation;

    [Test]
    procedure Test09_BelowMinimumReferenceCandidate;

    [Test]
    procedure Test10_MechanicallyImpossibleLayoutExclusion;

    [Test]
    procedure Test11_MachineSpecificCylinderAssignments;

    [Test]
    procedure Test12_InactiveMachineAndCylinderFiltering;

    [Test]
    procedure Test13_AcrossWebFitBoundary;

    [Test]
    procedure Test14_AcrossGapFormula_UpsMinus1;

    [Test]
    procedure Test15_EdgeMarginCalculations;

    [Test]
    procedure Test16_MissingMachineWidthHandling;

    [Test]
    procedure Test17_IntegerOverflowSafety;

    [Test]
    procedure Test18_CircumferentialGapPercentage;

    [Test]
    procedure Test19_ExistingDieMatchLookup;

    [Test]
    procedure Test20_AroundPriorityPreservation;

    [Test]
    procedure Test21_SlittingCandidateClassification;

    [Test]
    procedure Test22_ScrappedDieExclusion;

    [Test]
    procedure Test23_CreateDieFromSelectionDraftMapping;

    [Test]
    procedure Test24_CancelWithoutPersistence;

    [Test]
    procedure Test25_SaveWithValidationAndAuditHistory;

    [Test]
    procedure Test26_SameCalculationResultAfterSaveReopen;

    [Test]
    procedure Test27_InvalidZeroNegativeInputs;

    [Test]
    procedure Test28_NoDuplicateGeometryCalculations;

    [Test]
    procedure Test29_PaginationAndRecommendationOrdering;

    [Test]
    procedure Test30_RegressionOfExistingDieMaster;
  end;

implementation

{ TDieVixCalculatorTests }

procedure TDieVixCalculatorTests.SetupFixture;
var
  Mgr: TDieVixConnectionManager;
  Cfg: TDatabaseConfig;
  AppCount: Integer;
  LogStr: string;
  Cust: TCustomer;
  Med: TMedia;
  Mach: TMachine;
begin
  Mgr := TDieVixConnectionManager.Instance;
  Cfg := TDatabaseConfig.DefaultServer;
  Cfg.Database := 'D:\ketan\github\DieVix\tmp\dievix_disposable_test.fdb';
  Cfg.UserName := 'SYSDBA';
  Cfg.Password := 'masterkey';
  Cfg.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll';
  Mgr.Config := Cfg;

  FConn := Mgr.GetConnection;
  Mgr.ApplyMigrations('D:\ketan\github\DieVix\migrations', AppCount, LogStr);

  FCustomerRepo := TCustomerRepository.Create(FConn);
  FMediaRepo := TMediaRepository.Create(FConn);
  FCylinderRepo := TCylinderRepository.Create(FConn);
  FMachineRepo := TMachineRepository.Create(FConn);
  FMachineCylinderRepo := TMachineCylinderRepository.Create(FConn);
  FStatusRepo := TDieStatusRepository.Create(FConn);
  FSettingRepo := TAppSettingRepository.Create(FConn);
  FDieRepo := TDieRepository.Create(FConn);

  FMasterService := TMasterDataService.Create(
    FCustomerRepo, FMediaRepo, FStatusRepo, FCylinderRepo, FMachineRepo, FMachineCylinderRepo, FSettingRepo
  );

  FDieService := TDieService.Create(
    FDieRepo, FSettingRepo, FCustomerRepo, FMediaRepo, FCylinderRepo, FStatusRepo, FMachineRepo
  );

  FKeylineService := TKeylineService.Create(
    FCylinderRepo, FMachineRepo, FMachineCylinderRepo, FDieRepo, FSettingRepo
  );

  // Setup test customer, media, and machine
  Cust := TCustomer.CreateNew('TEST-CUST-PH4', 'Phase 4 Calculator Test Customer');
  FTestCustID := FCustomerRepo.Insert(Cust);

  Med := TMedia.CreateNew('TEST-MED-PH4', 'Phase 4 Test Substrate');
  FTestMediaID := FMediaRepo.Insert(Med);

  Mach := TMachine.CreateNew('TEST-MACH-PH4', 'Phase 4 Test Press 250mm', 250.0);
  Mach.MinWebWidthMm := 50.0;
  Mach.DefaultMarginMm := 5.0;
  FTestMachID := FMachineRepo.Insert(Mach);

  // Assign cylinders 66T, 72T, 96T, 98T, 112T to this test press
  FMachineCylinderRepo.AssignCylinder(FTestMachID, 66);
  FMachineCylinderRepo.AssignCylinder(FTestMachID, 72);
  FMachineCylinderRepo.AssignCylinder(FTestMachID, 96);
  FMachineCylinderRepo.AssignCylinder(FTestMachID, 98);
  FMachineCylinderRepo.AssignCylinder(FTestMachID, 112);
end;

procedure TDieVixCalculatorTests.TearDownFixture;
begin
  if FTestMachID > 0 then
    FMachineRepo.Delete(FTestMachID);
  if FTestCustID > 0 then
    FCustomerRepo.Delete(FTestCustID);
  if FTestMediaID > 0 then
    FMediaRepo.Delete(FTestMediaID);

  FKeylineService.Free;
  FDieService.Free;
  FMasterService.Free;
end;

procedure TDieVixCalculatorTests.Test01_RepeatFormula_96Tx3175um;
var
  RepeatUm: Int64;
  RepeatMm: Double;
  RepeatInch: Double;
begin
  RepeatUm := TeethToRepeatUm(96, 3175);
  Assert.AreEqual(Int64(304800), RepeatUm, '96T x 3175 um must equal exactly 304800 um');

  RepeatMm := TeethToRepeatMm(96, 3175);
  Assert.AreEqual(304.800, RepeatMm, 0.0001, 'Repeat mm must be 304.800 mm');

  RepeatInch := TeethToRepeatInch(96);
  Assert.AreEqual(12.000, RepeatInch, 0.0001, '96T / 8 must be exactly 12.0 inches');
end;

procedure TDieVixCalculatorTests.Test02_AroundGap_96T_98mm_3ups;
var
  GapRes: TGapResult;
begin
  // Repeat = 304.8 mm. Cut = 3 * 98 = 294 mm. Pool = 10.8 mm. Gap = 3.600 mm.
  GapRes := CalculateAroundGapFromMm(96, 98.0, 3, 3.0, 0.0, 3175);
  Assert.AreEqual(3.600, GapRes.AroundGapMm, 0.0001, 'Around gap must be 3.600 mm');
  Assert.AreEqual(Int64(3600), GapRes.AroundGapUm, 'Around gap um must be 3600 um');
  Assert.AreEqual(0, GapRes.RemainderUm, 'Remainder must be 0 um');
  Assert.IsTrue(GapRes.Status in [gsOptimal, gsStandardApproved], 'Gap >= 3.0 mm must be approved');
  Assert.IsFalse(GapRes.RequiresOverrideReason, 'Approved gap does not require override reason');
end;

procedure TDieVixCalculatorTests.Test03_Exact3000mmBoundary;
var
  GapRes: TGapResult;
begin
  // 50T: Repeat = 50 * 3.175 = 158.750 mm. Label = 155.750 mm. 1 Up.
  // Pool = 158.750 - 155.750 = 3.000 mm.
  GapRes := CalculateAroundGapFromMm(50, 155.750, 1, 3.000, 0.0, 3175);
  Assert.AreEqual(3.000, GapRes.AroundGapMm, 0.0001, 'Exact 3.000 mm boundary must be achieved');
  Assert.AreEqual(Int64(3000), GapRes.AroundGapUm, 'Around gap must be 3000 um');
  Assert.IsTrue(GapRes.Status in [gsOptimal, gsStandardApproved], 'Exact 3.000 mm boundary must be approved');
  Assert.IsFalse(GapRes.RequiresOverrideReason, 'Exact 3.000 mm boundary does not require override');
end;

procedure TDieVixCalculatorTests.Test04_FractionalMicrometreGapComparison;
var
  GapRes: TGapResult;
begin
  // 100T repeat = 317,500 um. 3 ups of 103.000 mm = 309,000 um cut.
  // Remaining pool = 8,500 um.
  // Gap = 8500 / 3 = 2833 um, remainder = 1 um. Floating gap = 2.833 mm.
  GapRes := CalculateAroundGapFromMm(100, 103.000, 3, 3.000, 0.0, 3175);
  Assert.AreEqual(Int64(2833), GapRes.AroundGapUm, 'Integer gap must be 2833 um');
  Assert.AreEqual(1, GapRes.RemainderUm, 'Remainder must be 1 um');
  Assert.AreEqual(2.833, GapRes.AroundGapMm, 0.001, 'Floating representation must be ~2.833 mm');
  Assert.AreEqual(gsSubStandardWarning, GapRes.Status, 'Sub-3mm gap must trigger sub-standard warning');
  Assert.IsTrue(GapRes.RequiresOverrideReason, 'Sub-3mm gap must require override reason');
end;

procedure TDieVixCalculatorTests.Test05_CylinderSelectionNonUniformFleet;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  Found96, Found98: Boolean;
  I: Integer;
begin
  Input := TKeylineInput.CreateDefault(150.0, 100.0);
  Input.UpsMode := usmFixedUps;
  Input.FixedAroundUps := 2;

  ResultData := FKeylineService.Calculate(Input);
  Assert.IsTrue(Length(ResultData.Recommendations) > 0, 'Must return recommendations for 2 ups');

  Found96 := False;
  Found98 := False;
  for I := 0 to High(ResultData.Recommendations) do
  begin
    if ResultData.Recommendations[I].Teeth = 96 then Found96 := True;
    if ResultData.Recommendations[I].Teeth = 98 then Found98 := True;
  end;

  // Discrete cylinders 96 and 98 exist in fleet
  Assert.IsTrue(Found96, '96T cylinder must be present in calculations');
  Assert.IsTrue(Found98, '98T cylinder must be present in calculations');
end;

procedure TDieVixCalculatorTests.Test06_AutomaticUpsScan;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  UpsFound: TList<Integer>;
  I: Integer;
begin
  Input := TKeylineInput.CreateDefault(50.0, 50.0);
  Input.UpsMode := usmAutoScan;
  Input.MaxAroundUps := 5;

  ResultData := FKeylineService.Calculate(Input);
  Assert.IsTrue(Length(ResultData.Recommendations) > 0, 'Auto scan must return recommendations');

  UpsFound := TList<Integer>.Create;
  try
    for I := 0 to High(ResultData.Recommendations) do
    begin
      if not UpsFound.Contains(ResultData.Recommendations[I].AroundUps) then
        UpsFound.Add(ResultData.Recommendations[I].AroundUps);
    end;
    Assert.IsTrue(UpsFound.Count >= 3, 'Auto scan must produce candidates across multiple ups counts');
  finally
    UpsFound.Free;
  end;
end;

procedure TDieVixCalculatorTests.Test07_FixedUpsRecommendation;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  I: Integer;
begin
  Input := TKeylineInput.CreateDefault(75.0, 50.0);
  Input.UpsMode := usmFixedUps;
  Input.FixedAroundUps := 3;

  ResultData := FKeylineService.Calculate(Input);
  Assert.IsTrue(Length(ResultData.Recommendations) > 0, 'Fixed ups must return recommendations');

  for I := 0 to High(ResultData.Recommendations) do
    Assert.AreEqual(3, ResultData.Recommendations[I].AroundUps, 'All candidates must have exactly 3 around ups');
end;

procedure TDieVixCalculatorTests.Test08_NextLargerCylinderRecommendation;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  FoundPreferred, FoundNextLarger: Boolean;
  I: Integer;
begin
  Input := TKeylineInput.CreateDefault(98.0, 50.0);
  Input.UpsMode := usmFixedUps;
  Input.FixedAroundUps := 3;

  ResultData := FKeylineService.Calculate(Input);
  FoundPreferred := False;
  FoundNextLarger := False;

  for I := 0 to High(ResultData.Recommendations) do
  begin
    if ResultData.Recommendations[I].Category = krcPreferred then
      FoundPreferred := True;
    if (ResultData.Recommendations[I].Category = krcValidAlternative) and
       (Pos('Next Larger', ResultData.Recommendations[I].CategoryText) > 0) then
      FoundNextLarger := True;
  end;

  Assert.IsTrue(FoundPreferred, 'Must recommend a Preferred cylinder');
  Assert.IsTrue(FoundNextLarger, 'Must recommend a Next Larger cylinder alternative');
end;

procedure TDieVixCalculatorTests.Test09_BelowMinimumReferenceCandidate;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  FoundWarning: Boolean;
  I: Integer;
begin
  // For 150 mm label and 2 ups: Cut = 300 mm.
  // 96T repeat is 304.8 mm -> Gap is 2.400 mm (< 3.000 mm).
  // 96T is below 3.000 mm, so it serves as the below-minimum reference candidate!
  Input := TKeylineInput.CreateDefault(150.0, 50.0);
  Input.UpsMode := usmAutoScan;
  Input.MaxAroundUps := 2;

  ResultData := FKeylineService.Calculate(Input);
  FoundWarning := False;

  for I := 0 to High(ResultData.Recommendations) do
  begin
    if (ResultData.Recommendations[I].Teeth = 96) and (ResultData.Recommendations[I].AroundUps = 2) then
    begin
      Assert.AreEqual(krcSubStandardWarning, ResultData.Recommendations[I].Category, '96T 2 ups must be sub-standard warning');
      Assert.IsTrue(ResultData.Recommendations[I].RequiresOverrideReason, 'Sub-standard candidate requires override');
      FoundWarning := True;
    end;
  end;

  Assert.IsTrue(FoundWarning, 'Below-minimum reference candidate must be present in recommendations');
end;

procedure TDieVixCalculatorTests.Test10_MechanicallyImpossibleLayoutExclusion;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  I: Integer;
begin
  // Label around 200 mm, 2 ups = 400 mm cut.
  // 66T repeat is 209.55 mm.
  Input := TKeylineInput.CreateDefault(200.0, 50.0);
  Input.UpsMode := usmFixedUps;
  Input.FixedAroundUps := 2;

  ResultData := FKeylineService.Calculate(Input);

  for I := 0 to High(ResultData.Recommendations) do
  begin
    if ResultData.Recommendations[I].Teeth = 66 then
    begin
      Assert.AreEqual(krcMechanicallyRejected, ResultData.Recommendations[I].Category, '66T must be mechanically rejected');
      Assert.IsFalse(ResultData.Recommendations[I].IsEligible, 'Mechanically impossible layout must not be eligible');
    end;
  end;
end;

procedure TDieVixCalculatorTests.Test11_MachineSpecificCylinderAssignments;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  I: Integer;
  AssignedCount, UnassignedCount: Integer;
begin
  // Press FTestMachID has 66, 72, 96, 98, 112 assigned.
  // 68, 76, 82, 90, etc. are NOT assigned.
  Input := TKeylineInput.CreateDefault(70.0, 50.0, FTestMachID);
  Input.UpsMode := usmFixedUps;
  Input.FixedAroundUps := 2;

  ResultData := FKeylineService.Calculate(Input);
  AssignedCount := 0;
  UnassignedCount := 0;

  for I := 0 to High(ResultData.Recommendations) do
  begin
    if ResultData.Recommendations[I].MachineStatus = mfsCompatible then
      Inc(AssignedCount)
    else if ResultData.Recommendations[I].MachineStatus = mfsUnsupportedCylinder then
      Inc(UnassignedCount);
  end;

  Assert.IsTrue(AssignedCount > 0, 'Must have compatible assigned cylinders');
  Assert.IsTrue(UnassignedCount > 0, 'Must identify unsupported cylinders on the press');
end;

procedure TDieVixCalculatorTests.Test12_InactiveMachineAndCylinderFiltering;
var
  Cyl: TCylinder;
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  I: Integer;
  Found66: Boolean;
begin
  // Deactivate 66T temporarily
  Cyl := FCylinderRepo.GetByTeeth(66);
  Cyl.IsActive := False;
  FCylinderRepo.Update(Cyl);
  try
    Input := TKeylineInput.CreateDefault(50.0, 50.0);
    Input.ActiveCylindersOnly := True;
    ResultData := FKeylineService.Calculate(Input);

    Found66 := False;
    for I := 0 to High(ResultData.Recommendations) do
      if ResultData.Recommendations[I].Teeth = 66 then Found66 := True;

    Assert.IsFalse(Found66, 'Inactive cylinder must be excluded when ActiveCylindersOnly is True');
  finally
    Cyl.IsActive := True;
    FCylinderRepo.Update(Cyl);
  end;
end;

procedure TDieVixCalculatorTests.Test13_AcrossWebFitBoundary;
var
  FitRes: TWebFitResult;
begin
  // Press width is 250.0 mm.
  // 3 across ups of 70 mm = 210 mm. Across gap (2 gaps) = 6 mm. Total tooling = 216 mm.
  // Left margin 5 mm + Right margin 5 mm = 10 mm.
  // Total web = 216 + 10 = 226 mm <= 250 mm -> Fits!
  FitRes := FKeylineService.CalculateWebFit(70.0, 3, 3.0, 5.0, 5.0, FTestMachID);
  Assert.IsTrue(FitRes.Fits, '226.0 mm must fit within 250.0 mm press width');
  Assert.AreEqual(226.000, FitRes.RequiredWebWidthMm, 0.001, 'Required web width must be 226.0 mm');
  Assert.AreEqual(0.0, FitRes.ExcessMm, 0.001, 'Excess must be 0 mm');

  // 4 across ups of 70 mm = 280 mm > 250 mm -> Fails!
  FitRes := FKeylineService.CalculateWebFit(70.0, 4, 3.0, 5.0, 5.0, FTestMachID);
  Assert.IsFalse(FitRes.Fits, '4 ups of 70mm must exceed 250 mm press width');
  Assert.IsTrue(FitRes.ExcessMm > 0.0, 'Excess must be positive when exceeding web width');
end;

procedure TDieVixCalculatorTests.Test14_AcrossGapFormula_UpsMinus1;
var
  FitRes: TWebFitResult;
begin
  // Tooling width for N ups has (N - 1) internal gaps
  // 3 ups of 50.0 mm with 3.0 mm gap:
  // Tooling width = (3 * 50) + ((3 - 1) * 3) = 150 + 6 = 156.0 mm
  FitRes := FKeylineService.CalculateWebFit(50.0, 3, 3.0, 0.0, 0.0, 0);
  Assert.AreEqual(156.000, FitRes.ToolingWidthMm, 0.001, '3 ups of 50mm with 3mm gap must equal 156.0 mm tooling width');
end;

procedure TDieVixCalculatorTests.Test15_EdgeMarginCalculations;
var
  FitRes: TWebFitResult;
begin
  // Tooling width 156 mm + Left Margin 6.0 mm + Right Margin 4.0 mm = 166.0 mm
  FitRes := FKeylineService.CalculateWebFit(50.0, 3, 3.0, 6.0, 4.0, 0);
  Assert.AreEqual(166.000, FitRes.RequiredWebWidthMm, 0.001, 'Total web must include both margins exactly');
end;

procedure TDieVixCalculatorTests.Test16_MissingMachineWidthHandling;
var
  FitRes: TWebFitResult;
begin
  // Machine ID = 0 (no machine specified)
  FitRes := FKeylineService.CalculateWebFit(50.0, 2, 3.0, 5.0, 5.0, 0);
  Assert.IsTrue(FitRes.Fits, 'Missing machine width must default to fitting without crashing');
  Assert.AreEqual(0.0, FitRes.MaxWebWidthMm, 0.001, 'MaxWebWidthMm must be 0');
end;

procedure TDieVixCalculatorTests.Test17_IntegerOverflowSafety;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
begin
  // Extreme dimensions: 999999.0 mm
  Input := TKeylineInput.CreateDefault(999999.0, 999999.0);
  Input.MaxAroundUps := 10;
  ResultData := FKeylineService.Calculate(Input);
  // Must execute safely and reject without crashing
  Assert.AreEqual(0, ResultData.PreferredCount, 'Huge dimensions must produce 0 preferred candidates');
end;

procedure TDieVixCalculatorTests.Test18_CircumferentialGapPercentage;
var
  GapRes: TGapResult;
  ExpectedPct: Double;
begin
  // 96T repeat = 304.8 mm. Cut = 3 * 98 = 294 mm. Pool = 10.8 mm.
  // Waste % = 10.8 / 304.8 * 100 = 3.543%
  GapRes := CalculateAroundGapFromMm(96, 98.0, 3, 3.0, 0.0, 3175);
  ExpectedPct := (10.8 / 304.8) * 100.0;
  Assert.AreEqual(ExpectedPct, GapRes.WastePercent, 0.01, 'Circumferential gap percent must match (Remaining / Repeat) * 100');
end;

procedure TDieVixCalculatorTests.Test19_ExistingDieMatchLookup;
var
  TestDie: TDie;
  DieID: Integer;
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  FoundMatch: Boolean;
  I: Integer;
begin
  // Insert an existing die on 98T: 150.0 x 100.0 mm, 2 ups
  TestDie := TDie.CreateNew('DIE-CALC-MATCH-01', 98, 150.0, 100.0, 2, 1);
  TestDie.CustomerID := FTestCustID;
  TestDie.MediaID := FTestMediaID;
  DieID := FDieService.SaveDie(TestDie);
  try
    Input := TKeylineInput.CreateDefault(150.0, 100.0);
    Input.UpsMode := usmFixedUps;
    Input.FixedAroundUps := 2;

    ResultData := FKeylineService.Calculate(Input);
    FoundMatch := False;

    for I := 0 to High(ResultData.Recommendations) do
    begin
      if ResultData.Recommendations[I].Teeth = 98 then
      begin
        Assert.IsTrue(ResultData.Recommendations[I].ExistingDieCount >= 1, 'Must find existing die on 98T');
        Assert.IsTrue(Pos('existing die candidate', ResultData.Recommendations[I].RecommendationReason) > 0,
          'Recommendation reason must mention existing tooling');
        FoundMatch := True;
      end;
    end;

    Assert.IsTrue(FoundMatch, '98T candidate must be evaluated and matched');
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixCalculatorTests.Test20_AroundPriorityPreservation;
var
  Matches: TList<TSmartDieSearchResult>;
  DieA_ID, DieB_ID: Integer;
  DieA, DieB: TDie;
  IdxA, IdxB, I: Integer;
begin
  // Candidate A: Around diff 0.1 mm, Across diff 0.8 mm
  // Candidate B: Around diff 0.5 mm, Across diff 0.05 mm
  DieA := TDie.CreateNew('DIE-CALC-PRIO-A', 98, 150.100, 100.800, 2, 1);
  DieB := TDie.CreateNew('DIE-CALC-PRIO-B', 98, 150.500, 100.050, 2, 1);
  DieA.CustomerID := FTestCustID;
  DieB.CustomerID := FTestCustID;
  DieA.MediaID := FTestMediaID;
  DieB.MediaID := FTestMediaID;
  DieA_ID := FDieService.SaveDie(DieA);
  DieB_ID := FDieService.SaveDie(DieB);
  try
    Matches := FKeylineService.FindMatchingDies(98, 150.0, 100.0, 2.0);
    try
      IdxA := -1;
      IdxB := -1;
      for I := 0 to Matches.Count - 1 do
      begin
        if Matches[I].Die.SerialNo = 'DIE-CALC-PRIO-A' then IdxA := I;
        if Matches[I].Die.SerialNo = 'DIE-CALC-PRIO-B' then IdxB := I;
      end;

      Assert.IsTrue(IdxA >= 0, 'Candidate A must be found');
      Assert.IsTrue(IdxB >= 0, 'Candidate B must be found');
      Assert.IsTrue(IdxA < IdxB, 'Candidate A (Around diff 0.1mm) must rank before Candidate B (Around diff 0.5mm)');
    finally
      Matches.Free;
    end;
  finally
    FDieService.DeleteDie(DieA_ID);
    FDieService.DeleteDie(DieB_ID);
  end;
end;

procedure TDieVixCalculatorTests.Test21_SlittingCandidateClassification;
var
  DieID: Integer;
  TestDie: TDie;
  Matches: TList<TSmartDieSearchResult>;
  FoundSlit: Boolean;
  I: Integer;
begin
  // Across size 108.0 mm (> 100.0 + 2.0 mm tolerance) -> Slitting candidate
  TestDie := TDie.CreateNew('DIE-CALC-SLIT-01', 98, 150.0, 108.0, 2, 1);
  TestDie.CustomerID := FTestCustID;
  TestDie.MediaID := FTestMediaID;
  DieID := FDieService.SaveDie(TestDie);
  try
    Matches := FKeylineService.FindMatchingDies(98, 150.0, 100.0, 2.0);
    try
      FoundSlit := False;
      for I := 0 to Matches.Count - 1 do
      begin
        if Matches[I].Die.SerialNo = 'DIE-CALC-SLIT-01' then
        begin
          Assert.AreEqual(sdmSlittingCandidate, Matches[I].MatchClass, 'Must be classified as sdmSlittingCandidate');
          Assert.IsTrue(Pos('REVIEW REQUIRED', UpperCase(Matches[I].ReusabilityNote)) > 0, 'Reusability note must indicate review is required');
          FoundSlit := True;
        end;
      end;
      Assert.IsTrue(FoundSlit, 'Slitting candidate must be discovered in reuse lookup');
    finally
      Matches.Free;
    end;
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixCalculatorTests.Test22_ScrappedDieExclusion;
var
  DieID: Integer;
  TestDie: TDie;
  Matches: TList<TSmartDieSearchResult>;
  FoundScrap: Boolean;
  I: Integer;
begin
  TestDie := TDie.CreateNew('DIE-CALC-SCRAP-01', 98, 150.0, 100.0, 2, 1);
  TestDie.CustomerID := FTestCustID;
  TestDie.MediaID := FTestMediaID;
  TestDie.StatusCode := 'SCRAPPED';
  DieID := FDieService.SaveDie(TestDie);
  try
    Matches := FKeylineService.FindMatchingDies(98, 150.0, 100.0, 2.0);
    try
      FoundScrap := False;
      for I := 0 to Matches.Count - 1 do
        if Matches[I].Die.SerialNo = 'DIE-CALC-SCRAP-01' then FoundScrap := True;
      Assert.IsFalse(FoundScrap, 'Scrapped die must be excluded from reusable die lookup');
    finally
      Matches.Free;
    end;
  finally
    FDieService.DeleteDie(DieID);
  end;
end;

procedure TDieVixCalculatorTests.Test23_CreateDieFromSelectionDraftMapping;
var
  Input: TKeylineInput;
  Rec: TKeylineRecommendation;
  DraftDie: TDie;
begin
  Input := TKeylineInput.CreateDefault(150.0, 100.0);
  Input.AcrossUps := 2;
  Input.AcrossGapMm := 3.5;
  Input.CornerRadiusMm := 1.5;
  Input.Shape := 'RECTANGLE';
  Input.MediaID := FTestMediaID;

  FillChar(Rec, SizeOf(Rec), 0);
  Rec.Teeth := 98;
  Rec.PitchUm := 3175;
  Rec.AroundUps := 2;
  Rec.RepeatMm := 311.15;

  DraftDie := FKeylineService.CreateDraftDie(Rec, Input, FTestCustID);
  Assert.AreEqual(98, DraftDie.Teeth, 'Draft teeth must be 98');
  Assert.AreEqual(150.0, DraftDie.AroundSizeMm, 0.001, 'Around size must match input');
  Assert.AreEqual(100.0, DraftDie.AcrossSizeMm, 0.001, 'Across size must match input');
  Assert.AreEqual(2, DraftDie.AroundUps, 'Around ups must be 2');
  Assert.AreEqual(2, DraftDie.AcrossUps, 'Across ups must be 2');
  Assert.AreEqual(3.5, DraftDie.AcrossGapMm, 0.001, 'Across gap must be 3.5 mm');
  Assert.AreEqual(1.5, DraftDie.CornerRadiusMm, 0.001, 'Corner radius must be 1.5 mm');
  Assert.AreEqual('RECTANGLE', DraftDie.Shape, 'Shape must match');
  Assert.AreEqual(FTestCustID, DraftDie.CustomerID, 'Customer ID must match');
  Assert.AreEqual(FTestMediaID, DraftDie.MediaID, 'Media ID must match');
  Assert.IsTrue(Length(DraftDie.SerialNo) > 0, 'Unique serial candidate must be generated');
end;

procedure TDieVixCalculatorTests.Test24_CancelWithoutPersistence;
var
  Input: TKeylineInput;
  Rec: TKeylineRecommendation;
  DraftDie: TDie;
  FoundDie: TDie;
begin
  Input := TKeylineInput.CreateDefault(150.0, 100.0);
  FillChar(Rec, SizeOf(Rec), 0);
  Rec.Teeth := 98;
  Rec.AroundUps := 2;

  // Create draft die but do NOT call SaveDie (operator cancels modal)
  DraftDie := FKeylineService.CreateDraftDie(Rec, Input, FTestCustID);
  FoundDie := FDieService.GetDieBySerial(DraftDie.SerialNo);
  Assert.AreEqual(0, FoundDie.ID, 'Draft die must NOT exist in the database before explicit operator save');
end;

procedure TDieVixCalculatorTests.Test25_SaveWithValidationAndAuditHistory;
var
  Input: TKeylineInput;
  Rec: TKeylineRecommendation;
  DraftDie: TDie;
  SavedID: Integer;
  AuditList: TList<TDieAuditEntry>;
begin
  Input := TKeylineInput.CreateDefault(150.0, 100.0);
  Input.AcrossUps := 1;
  FillChar(Rec, SizeOf(Rec), 0);
  Rec.Teeth := 98;
  Rec.PitchUm := 3175;
  Rec.AroundUps := 2;

  DraftDie := FKeylineService.CreateDraftDie(Rec, Input, FTestCustID);
  DraftDie.MediaID := FTestMediaID;
  SavedID := FDieService.SaveDie(DraftDie, 'KEYLINE_OP');
  try
    Assert.IsTrue(SavedID > 0, 'Saved die ID must be greater than zero');
    Assert.AreEqual(1, DraftDie.Version, 'Initial version must be 1');

    AuditList := FDieService.GetDieAuditHistory(SavedID);
    try
      Assert.IsTrue(AuditList.Count > 0, 'Audit history must record initial creation');
      Assert.AreEqual('CREATE', AuditList[0].Action, 'First action must be CREATE');
    finally
      AuditList.Free;
    end;
  finally
    FDieService.DeleteDie(SavedID);
  end;
end;

procedure TDieVixCalculatorTests.Test26_SameCalculationResultAfterSaveReopen;
var
  Input: TKeylineInput;
  Rec: TKeylineRecommendation;
  DraftDie, ReopenedDie: TDie;
  SavedID: Integer;
begin
  Input := TKeylineInput.CreateDefault(150.0, 100.0);
  FillChar(Rec, SizeOf(Rec), 0);
  Rec.Teeth := 98;
  Rec.PitchUm := 3175;
  Rec.AroundUps := 2;

  DraftDie := FKeylineService.CreateDraftDie(Rec, Input, FTestCustID);
  DraftDie.MediaID := FTestMediaID;
  SavedID := FDieService.SaveDie(DraftDie, 'KEYLINE_OP');
  try
    ReopenedDie := FDieService.GetDieByID(SavedID);
    Assert.AreEqual(98, ReopenedDie.Teeth, 'Reopened teeth must match');
    Assert.AreEqual(150.0, ReopenedDie.AroundSizeMm, 0.001, 'Reopened around size must match');
    Assert.AreEqual(100.0, ReopenedDie.AcrossSizeMm, 0.001, 'Reopened across size must match');
    Assert.AreEqual(5.575, ReopenedDie.AroundGapMm, 0.001, 'Reopened around gap must match (5.575 mm)');
    Assert.AreEqual(311.150, ReopenedDie.RepeatMm, 0.001, 'Reopened repeat mm must match');
  finally
    FDieService.DeleteDie(SavedID);
  end;
end;

procedure TDieVixCalculatorTests.Test27_InvalidZeroNegativeInputs;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
begin
  Input := TKeylineInput.CreateDefault(-50.0, 0.0);
  ResultData := FKeylineService.Calculate(Input);
  Assert.AreEqual(0, Length(ResultData.Recommendations), 'Invalid zero or negative dimensions must return 0 recommendations');
end;

procedure TDieVixCalculatorTests.Test28_NoDuplicateGeometryCalculations;
var
  Input: TKeylineInput;
  Run1, Run2: TKeylineCalculationResult;
begin
  Input := TKeylineInput.CreateDefault(100.0, 75.0);
  Input.UpsMode := usmFixedUps;
  Input.FixedAroundUps := 3;

  Run1 := FKeylineService.Calculate(Input);
  Run2 := FKeylineService.Calculate(Input);

  Assert.AreEqual(Length(Run1.Recommendations), Length(Run2.Recommendations), 'Results must be deterministic across runs');
  if Length(Run1.Recommendations) > 0 then
  begin
    Assert.AreEqual(Run1.Recommendations[0].Teeth, Run2.Recommendations[0].Teeth, 'Top recommendation must be identical');
    Assert.AreEqual(Run1.Recommendations[0].AroundGapMm, Run2.Recommendations[0].AroundGapMm, 0.0001, 'Gap must be identical');
  end;
end;

procedure TDieVixCalculatorTests.Test29_PaginationAndRecommendationOrdering;
var
  Input: TKeylineInput;
  ResultData: TKeylineCalculationResult;
  I: Integer;
begin
  Input := TKeylineInput.CreateDefault(80.0, 60.0);
  Input.UpsMode := usmAutoScan;
  Input.MaxAroundUps := 4;

  ResultData := FKeylineService.Calculate(Input);
  Assert.IsTrue(Length(ResultData.Recommendations) > 1, 'Multiple recommendations expected');

  // Verify that Preferred candidates appear before SubStandard or Rejected candidates
  for I := 0 to High(ResultData.Recommendations) - 1 do
  begin
    Assert.IsTrue(
      ResultData.Recommendations[I].RankingScore <= ResultData.Recommendations[I + 1].RankingScore,
      'Recommendations must be ordered by ranking score ascending'
    );
  end;
end;

procedure TDieVixCalculatorTests.Test30_RegressionOfExistingDieMaster;
var
  AllDies: TList<TDie>;
  AllMachs: TList<TMachine>;
  AllCyls: TList<TCylinder>;
begin
  // Ensure master services and repositories remain fully operational
  AllDies := FDieService.GetAllDies;
  try
    Assert.IsTrue(Assigned(AllDies), 'Die register retrieval must succeed');
  finally
    AllDies.Free;
  end;

  AllMachs := FMasterService.GetAllMachines;
  try
    Assert.IsTrue(AllMachs.Count > 0, 'Machine fleet retrieval must succeed');
  finally
    AllMachs.Free;
  end;

  AllCyls := FMasterService.GetAllCylinders;
  try
    Assert.IsTrue(AllCyls.Count > 0, 'Cylinder fleet retrieval must succeed');
  finally
    AllCyls.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixCalculatorTests);

end.
