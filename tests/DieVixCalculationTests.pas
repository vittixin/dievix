unit DieVixCalculationTests;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  DUnitX Test Suite: Rotary Die Engine & Integer Precision Verification
==============================================================================}

interface

uses
  DUnitX.TestFramework,
  DieVix.CalculationEngine;

type
  [TestFixture]
  TDieVixCalculationTests = class
  public
    [Test]
    procedure TestCylinderRepeatForFleet;

    [Test]
    procedure TestExactThreeMillimetreBoundaryNoFloatingPointNoise;

    [Test]
    procedure TestSubThreeMillimetreShopToleranceWarning;

    [Test]
    procedure TestFlexibleGapPolicyRequiresOverrideReason;

    [Test]
    procedure TestExplicitHardBlockThreshold;

    [Test]
    procedure TestNegativeGapCutExceedsRepeat;

    [Test]
    procedure TestUnsupportedCylinderSizeRejection;

    [Test]
    procedure TestInvalidInputs;

    [Test]
    procedure TestExtremeLargeDimensionSafety;

    [Test]
    procedure TestWastePercentageCalculation;

    [Test]
    procedure TestAcrossWebFitCheck;

    [Test]
    procedure TestAcrossWebFitOverflow;

    [Test]
    procedure TestOptimalCylinderRecommendation;

    [Test]
    procedure TestFullFleetRecommendationScan;
  end;

implementation

{ -----------------------------------------------------------------------------
  Test Implementations
----------------------------------------------------------------------------- }

procedure TDieVixCalculationTests.TestCylinderRepeatForFleet;
begin
  // Standard gear pitch: 1/8" = 3.175 mm = 3,175 um
  // 66T = 66 * 3.175 = 209.550 mm
  Assert.AreEqual(Int64(209550), TeethToRepeatUm(66));
  Assert.AreEqual(209.550, TeethToRepeatMm(66), 0.0001);

  // 96T = 96 * 3.175 = 304.800 mm = exactly 12.000 inches
  Assert.AreEqual(Int64(304800), TeethToRepeatUm(96));
  Assert.AreEqual(304.800, TeethToRepeatMm(96), 0.0001);
  Assert.AreEqual(12.0, TeethToRepeatInch(96), 0.0001);

  // 112T = 112 * 3.175 = 355.600 mm = exactly 14.000 inches
  Assert.AreEqual(Int64(355600), TeethToRepeatUm(112));
  Assert.AreEqual(355.600, TeethToRepeatMm(112), 0.0001);
  Assert.AreEqual(14.0, TeethToRepeatInch(112), 0.0001);

  // 120T = 120 * 3.175 = 381.000 mm = exactly 15.000 inches
  Assert.AreEqual(Int64(381000), TeethToRepeatUm(120));
  Assert.AreEqual(381.000, TeethToRepeatMm(120), 0.0001);
  Assert.AreEqual(15.0, TeethToRepeatInch(120), 0.0001);

  // 132T = 132 * 3.175 = 419.100 mm
  Assert.AreEqual(Int64(419100), TeethToRepeatUm(132));
  Assert.AreEqual(419.100, TeethToRepeatMm(132), 0.0001);
end;

procedure TDieVixCalculationTests.TestExactThreeMillimetreBoundaryNoFloatingPointNoise;
var
  Res: TGapResult;
begin
  { Floating-point hazard reproduction:
    In double precision, (304.8 - 3 * 98.6) / 3 can result in 2.9999999999999929.
    In DieVix integer micrometres:
      96T repeat = 304,800 um.
      3 ups * 98,600 um = 295,800 um.
      Gap pool = 304,800 - 295,800 = 9,000 um.
      Around gap = 9,000 / 3 = 3,000 um (exactly 3.000 mm). }
  Res := CalculateAroundGapFromMm(96, 98.600, 3, 3.0, 0.0);

  Assert.AreEqual(Int64(304800), Res.CylinderRepeatUm);
  Assert.AreEqual(Int64(9000), Res.TotalGapPoolUm);
  Assert.AreEqual(Int64(3000), Res.AroundGapUm);
  Assert.AreEqual(0, Res.RemainderUm);
  Assert.AreEqual(3.000, Res.AroundGapMm, 0.0001);

  // Must be strictly APPROVED (not warned, not failed)
  Assert.IsTrue(Res.Status = gsStandardApproved, 'Gap of exactly 3.000 mm must pass legal check!');
  Assert.IsFalse(Res.RequiresOverrideReason, 'Standard approved die must not require override reason');
end;

procedure TDieVixCalculationTests.TestSubThreeMillimetreShopToleranceWarning;
var
  Res112, Res96: TGapResult;
begin
  { Historical shop tooling frequently used 2.8 mm on 112T and 2.9 mm on 96T.
    These must generate a Warning (gsSubStandardWarning) to require an override reason,
    rather than a hard rejection. }

  // 112T (355.6 mm) with 4 ups:
  // If label is 86.1 mm -> 4 * 86.1 = 344.4 mm.
  // Gap pool = 355.6 - 344.4 = 11.2 mm -> Gap = 11.2 / 4 = 2.800 mm.
  Res112 := CalculateAroundGapFromMm(112, 86.100, 4, 3.0, 0.0);
  Assert.AreEqual(2.800, Res112.AroundGapMm, 0.0001);
  Assert.IsTrue(Res112.Status = gsSubStandardWarning, '2.800 mm gap must trigger SubStandardWarning');
  Assert.IsTrue(Res112.RequiresOverrideReason, 'Sub-3mm gap must require override reason');

  // 96T (304.8 mm) with 3 ups:
  // If label is 98.7 mm -> 3 * 98.7 = 296.1 mm.
  // Gap pool = 304.8 - 296.1 = 8.7 mm -> Gap = 8.7 / 3 = 2.900 mm.
  Res96 := CalculateAroundGapFromMm(96, 98.700, 3, 3.0, 0.0);
  Assert.AreEqual(2.900, Res96.AroundGapMm, 0.0001);
  Assert.IsTrue(Res96.Status = gsSubStandardWarning, '2.900 mm gap must trigger SubStandardWarning');
  Assert.IsTrue(Res96.RequiresOverrideReason, 'Sub-3mm gap must require override reason');
end;

procedure TDieVixCalculationTests.TestFlexibleGapPolicyRequiresOverrideReason;
var
  Res: TGapResult;
begin
  // When no hard block is configured (HardBlock = 0.0), even a 2.100 mm gap
  // is treated as a warning (not hard rejection), enabling shop flexibility with an override reason.
  Res := CalculateAroundGapFromMm(96, 99.500, 3, 3.0, 0.0);
  // Cut = 3 * 99.5 = 298.5 mm. Repeat = 304.8 mm. Total gap = 6.3 mm -> Gap = 2.100 mm.
  Assert.AreEqual(2.100, Res.AroundGapMm, 0.0001);
  Assert.IsTrue(Res.Status = gsSubStandardWarning);
  Assert.IsTrue(Res.RequiresOverrideReason);
end;

procedure TDieVixCalculationTests.TestExplicitHardBlockThreshold;
var
  ResPass, ResBlock: TGapResult;
begin
  // When an explicit hard block policy (e.g. 2.4 mm) IS requested by the business:
  // Gap = 2.5 mm -> Warning (above hard block, below 3.0)
  ResPass := CalculateAroundGapFromMm(96, 99.100, 3, 3.0, 2.4);
  // Cut = 3 * 99.1 = 297.3 mm. Total gap = 7.5 mm -> Gap = 2.500 mm.
  Assert.AreEqual(2.500, ResPass.AroundGapMm, 0.0001);
  Assert.IsTrue(ResPass.Status = gsSubStandardWarning);

  // Gap = 1.6 mm -> Hard rejection (below explicit 2.4 mm hard block)
  ResBlock := CalculateAroundGapFromMm(96, 100.000, 3, 3.0, 2.4);
  Assert.AreEqual(1.600, ResBlock.AroundGapMm, 0.0001);
  Assert.IsTrue(ResBlock.Status = gsMechanicallyRejected);
  Assert.IsFalse(ResBlock.RequiresOverrideReason); // Hard rejection cannot be overridden
end;

procedure TDieVixCalculationTests.TestNegativeGapCutExceedsRepeat;
var
  Res: TGapResult;
begin
  // 66T repeat = 209.55 mm.
  // 3 ups of 75 mm = 225.0 mm (> 209.55 mm).
  Res := CalculateAroundGapFromMm(66, 75.000, 3, 3.0, 0.0);

  Assert.IsTrue(Res.TotalGapPoolUm < 0);
  Assert.IsTrue(Res.Status = gsMechanicallyRejected);
end;

procedure TDieVixCalculationTests.TestUnsupportedCylinderSizeRejection;
var
  Fleet: TArray<Integer>;
  Res: TGapResult;
begin
  // Suppose active press only supports 96T and 112T:
  Fleet := [96, 112];

  // 96T supported:
  Res := CalculateAroundGapFromMm(96, 98.600, 3, 3.0, 0.0, 3175, Fleet);
  Assert.IsTrue(Res.Status = gsStandardApproved);

  // 70T not in fleet:
  Res := CalculateAroundGapFromMm(70, 60.000, 3, 3.0, 0.0, 3175, Fleet);
  Assert.IsTrue(Res.Status = gsMechanicallyRejected);
  Assert.IsTrue(Res.StatusMessage.Contains('not supported'));
end;

procedure TDieVixCalculationTests.TestInvalidInputs;
var
  Res1, Res2, Res3: TGapResult;
begin
  // Zero or negative teeth:
  Res1 := CalculateAroundGapFromMm(0, 50.0, 2);
  Assert.IsTrue(Res1.Status = gsMechanicallyRejected);

  // Zero or negative ups:
  Res2 := CalculateAroundGapFromMm(96, 50.0, 0);
  Assert.IsTrue(Res2.Status = gsMechanicallyRejected);

  // Zero or negative label size:
  Res3 := CalculateAroundGapFromMm(96, -10.0, 2);
  Assert.IsTrue(Res3.Status = gsMechanicallyRejected);
end;

procedure TDieVixCalculationTests.TestExtremeLargeDimensionSafety;
var
  Res: TGapResult;
begin
  // Test large label (e.g. 1000 mm on huge custom cylinder with 400T)
  Res := CalculateAroundGapFromMm(400, 600.0, 2, 3.0, 0.0);
  // Repeat = 400 * 3.175 = 1270.0 mm (1,270,000 um)
  // Cut = 2 * 600 = 1200.0 mm (1,200,000 um)
  // Gap = 70.0 / 2 = 35.0 mm (35,000 um)
  Assert.AreEqual(Int64(1270000), Res.CylinderRepeatUm);
  Assert.AreEqual(35.000, Res.AroundGapMm, 0.001);
  Assert.IsTrue(Res.Status = gsStandardApproved);
end;

procedure TDieVixCalculationTests.TestWastePercentageCalculation;
var
  Res: TGapResult;
begin
  // 96T repeat = 304.8 mm (304,800 um).
  // 3 ups of 98.6 mm -> total cut = 295.8 mm. Total gap pool = 9.0 mm (9,000 um).
  // Waste % = (9,000 / 304,800) * 100 = 2.9527559%
  Res := CalculateAroundGapFromMm(96, 98.600, 3, 3.0, 0.0);

  Assert.AreEqual(2.9528, Res.WastePercent, 0.001);
end;

procedure TDieVixCalculationTests.TestAcrossWebFitCheck;
var
  WebFit: TWebFitResult;
begin
  // Label Across = 60.0 mm, 3 Across Ups, 3.0 mm Across Gap, 5.0 mm Edge Margins
  // Tooling Width = 3 * 60 + 2 * 3 = 180 + 6 = 186.0 mm.
  // Required Web = 186.0 + 2 * 5.0 = 196.0 mm.
  // Press Max Web = 254.0 mm (10-inch Mark Andy).
  WebFit := CheckAcrossFit(60.0, 3, 3.0, 5.0, 254.0);

  Assert.AreEqual(186.0, WebFit.ToolingWidthMm, 0.001);
  Assert.AreEqual(196.0, WebFit.RequiredWebWidthMm, 0.001);
  Assert.IsTrue(WebFit.Fits, '196 mm tooling must fit comfortably on a 254 mm press');
  Assert.AreEqual(0.0, WebFit.ExcessMm, 0.001);
end;

procedure TDieVixCalculationTests.TestAcrossWebFitOverflow;
var
  WebFit: TWebFitResult;
begin
  // Label Across = 80.0 mm, 4 Across Ups, 3.0 mm Across Gap, 5.0 mm Edge Margins
  // Tooling Width = 4 * 80 + 3 * 3 = 320 + 9 = 329.0 mm.
  // Required Web = 329.0 + 10 = 339.0 mm.
  // Press Max Web = 254.0 mm.
  WebFit := CheckAcrossFit(80.0, 4, 3.0, 5.0, 254.0);

  Assert.IsFalse(WebFit.Fits, '339 mm tooling must exceed 254 mm press limit');
  Assert.AreEqual(85.0, WebFit.ExcessMm, 0.001);
end;

procedure TDieVixCalculationTests.TestOptimalCylinderRecommendation;
var
  Rec: TRecommendationResult;
begin
  { Label around = 100.0 mm, 3 ups, min gap = 3.0 mm.
    Required repeat = 3 * (100.0 + 3.0) = 309.0 mm.
    Available cylinders:
      96T = 304.8 mm (< 309 mm)
      98T = 311.15 mm (>= 309 mm) -> OPTIMAL!
      102T = 323.85 mm
    Optimal cylinder must be 98T.
    Repeat = 311.15 mm.
    Around Gap = (311.15 - 300.0) / 3 = 11.15 / 3 = 3.717 mm. }
  Rec := FindOptimalCylinderForUps(100.0, 3, nil, 3.0, 0.0);

  Assert.AreEqual(98, Rec.Teeth);
  Assert.AreEqual(311.150, Rec.RepeatMm, 0.001);
  Assert.AreEqual(3.717, Rec.AroundGapMm, 0.001);
  Assert.IsTrue(Rec.IsOptimal, '98T must be marked optimal recommendation');
  Assert.IsTrue(Rec.Status = gsOptimal);
end;

procedure TDieVixCalculationTests.TestFullFleetRecommendationScan;
var
  Recs: TArray<TRecommendationResult>;
  FoundOptimalForUps3: Boolean;
  I: Integer;
begin
  // Scan 1 to 4 ups for 100 mm label
  Recs := RecommendCylinders(100.0, 4, nil, 3.0, 0.0);

  Assert.IsTrue(Length(Recs) > 0, 'Recommendations must return candidates');

  FoundOptimalForUps3 := False;
  for I := 0 to High(Recs) do
  begin
    if (Recs[I].Ups = 3) and (Recs[I].IsOptimal) then
    begin
      Assert.AreEqual(98, Recs[I].Teeth);
      FoundOptimalForUps3 := True;
    end;
  end;

  Assert.IsTrue(FoundOptimalForUps3, 'Must discover 98T as optimal for 3 ups in full scan');
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixCalculationTests);

end.
