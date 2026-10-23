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
    procedure TestMechanicalRejectionBelowThreshold;

    [Test]
    procedure TestNegativeGapCutExceedsRepeat;

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
  Res := CalculateAroundGapFromMm(96, 98.600, 3, 3.0, 2.4);

  Assert.AreEqual(Int64(304800), Res.CylinderRepeatUm);
  Assert.AreEqual(Int64(9000), Res.TotalGapPoolUm);
  Assert.AreEqual(Int64(3000), Res.AroundGapUm);
  Assert.AreEqual(0, Res.RemainderUm);
  Assert.AreEqual(3.000, Res.AroundGapMm, 0.0001);

  // Must be strictly APPROVED (not warned, not failed)
  Assert.IsTrue(Res.Status = gsStandardApproved, 'Gap of exactly 3.000 mm must pass legal check!');
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
  Res112 := CalculateAroundGapFromMm(112, 86.100, 4, 3.0, 2.4);
  Assert.AreEqual(2.800, Res112.AroundGapMm, 0.0001);
  Assert.IsTrue(Res112.Status = gsSubStandardWarning, '2.800 mm gap must trigger SubStandardWarning');

  // 96T (304.8 mm) with 3 ups:
  // If label is 98.7 mm -> 3 * 98.7 = 296.1 mm.
  // Gap pool = 304.8 - 296.1 = 8.7 mm -> Gap = 8.7 / 3 = 2.900 mm.
  Res96 := CalculateAroundGapFromMm(96, 98.700, 3, 3.0, 2.4);
  Assert.AreEqual(2.900, Res96.AroundGapMm, 0.0001);
  Assert.IsTrue(Res96.Status = gsSubStandardWarning, '2.900 mm gap must trigger SubStandardWarning');
end;

procedure TDieVixCalculationTests.TestMechanicalRejectionBelowThreshold;
var
  Res: TGapResult;
begin
  // 96T (304.8 mm) with 3 ups of 100.0 mm:
  // Cut = 300.0 mm. Total gap = 4.8 mm.
  // Gap = 1.600 mm (< 2.400 mm threshold)
  Res := CalculateAroundGapFromMm(96, 100.000, 3, 3.0, 2.4);

  Assert.AreEqual(1.600, Res.AroundGapMm, 0.0001);
  Assert.IsTrue(Res.Status = gsMechanicallyRejected, 'Gap below 2.4 mm must be mechanically rejected');
end;

procedure TDieVixCalculationTests.TestNegativeGapCutExceedsRepeat;
var
  Res: TGapResult;
begin
  // 66T repeat = 209.55 mm.
  // 3 ups of 75 mm = 225.0 mm (> 209.55 mm).
  Res := CalculateAroundGapFromMm(66, 75.000, 3, 3.0, 2.4);

  Assert.IsTrue(Res.TotalGapPoolUm < 0);
  Assert.IsTrue(Res.Status = gsMechanicallyRejected);
end;

procedure TDieVixCalculationTests.TestWastePercentageCalculation;
var
  Res: TGapResult;
begin
  // 96T repeat = 304.8 mm (304,800 um).
  // 3 ups of 98.6 mm -> total cut = 295.8 mm. Total gap pool = 9.0 mm (9,000 um).
  // Waste % = (9,000 / 304,800) * 100 = 2.9527559%
  Res := CalculateAroundGapFromMm(96, 98.600, 3, 3.0, 2.4);

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
  Rec := FindOptimalCylinderForUps(100.0, 3, nil, 3.0, 2.4);

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
  Recs := RecommendCylinders(100.0, 4, nil, 3.0, 2.4);

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
