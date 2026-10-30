unit DieVix.CalculationEngine;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Precision Calculation Engine (Integer Micrometre Arithmetic)
  
  Description:
    Pure calculation engine with ZERO database or UI dependencies.
    All repeat, gap, and dimension calculations are executed in integer
    micrometres (um) where 1 mm = 1,000 um.
    
    Standard 1/8" circular pitch (CP) = 25.4 mm / 8 = 3.175 mm = 3,175 um.
    By using 3,175 um as an exact integer, all rounding errors, such as
    2.99999999999999 mm or 3.00000000000001 mm floating-point noise,
    are completely eliminated.
==============================================================================}

interface

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults;

const
  { Standard gear pitch: 1/8" circular pitch = 3.175 mm = 3,175 um }
  STANDARD_PITCH_UM = 3175;

  { Millimetres per inch }
  MM_PER_INCH = 25.4;

  { Default gap policy thresholds in micrometres }
  DEFAULT_MIN_GAP_UM = 3000;         // 3.000 mm (Standard recommended threshold)
  DEFAULT_HARD_BLOCK_GAP_UM = 0;     // 0 = Disabled by default (separate policy)
  DEFAULT_MIN_GAP_MM = 3.0;

  { Standard production cylinder tooth counts (16 sizes in fleet) }
  DEFAULT_CYLINDER_FLEET: array[0..15] of Integer = (
    66, 68, 72, 76, 82, 86, 90, 94, 96, 98, 102, 106, 112, 120, 126, 132
  );

type
  { Classification for gap legal status }
  TGapStatus = (
    gsOptimal,             // Tightest approved legal gap (>= MinGap)
    gsStandardApproved,    // Fully approved (>= MinGap)
    gsSubStandardWarning,  // Below MinGap; allowed with mandatory override reason
    gsMechanicallyRejected // Below HardBlock threshold (if enabled) or cut exceeds repeat
  );

  { Flatbed Tooling Categories }
  TFlatbedCategory = (fcRollForm, fcSheetForm);

  { Detailed result of an around gap computation }
  TGapResult = record
    Teeth: Integer;
    AroundUps: Integer;
    LabelAroundUm: Int64;
    CylinderRepeatUm: Int64;
    TotalGapPoolUm: Int64;           // Available substrate - (ups * label_size)
    AroundGapUm: Int64;              // Integer gap per label
    RemainderUm: Integer;            // Remainder from integer division
    AroundGapMm: Double;             // Floating point presentation (3 decimal places)
    CylinderRepeatMm: Double;
    CylinderRepeatInch: Double;
    WastePercent: Double;            // Total gap pool / repeat * 100
    Status: TGapStatus;
    RequiresOverrideReason: Boolean; // True when gap is below MinGap but approved to save with reason
    StatusMessage: string;
  end;

  { Recommendation record for layout scanner }
  TRecommendationResult = record
    Ups: Integer;
    Teeth: Integer;
    RepeatMm: Double;
    RepeatInch: Double;
    AroundGapMm: Double;
    AroundGapUm: Int64;
    WastePercent: Double;
    Status: TGapStatus;
    IsOptimal: Boolean;
    RequiresOverrideReason: Boolean;
    StatusText: string;
  end;

  { Machine web-width fit verification result }
  TWebFitResult = record
    AcrossUps: Integer;
    LabelAcrossMm: Double;
    AcrossGapMm: Double;
    EdgeMarginMm: Double;
    ToolingWidthMm: Double;
    RequiredWebWidthMm: Double;
    MaxWebWidthMm: Double;
    Fits: Boolean;
    ExcessMm: Double;
  end;

  { Conversion and arithmetic functions }
  function MmToUm(const AMm: Double): Int64; inline;
  function UmToMm(const AUm: Int64): Double; inline;

  { Cylinder fleet validation }
  function IsCylinderInFleet(const ATeeth: Integer; const AFleet: TArray<Integer> = nil): Boolean;

  { Cylinder repeat functions }
  function TeethToRepeatUm(const ATeeth: Integer; const APitchUm: Integer = STANDARD_PITCH_UM): Int64; inline;
  function TeethToRepeatMm(const ATeeth: Integer; const APitchUm: Integer = STANDARD_PITCH_UM): Double; inline;
  function TeethToRepeatInch(const ATeeth: Integer): Double; inline;

  { Around gap computation }
  function CalculateAroundGap(
    const ATeeth: Integer;
    const ALabelAroundUm: Int64;
    const AAroundUps: Integer;
    const AMinGapUm: Int64 = DEFAULT_MIN_GAP_UM;
    const AHardBlockGapUm: Int64 = DEFAULT_HARD_BLOCK_GAP_UM;
    const APitchUm: Integer = STANDARD_PITCH_UM;
    const AAllowedFleet: TArray<Integer> = nil
  ): TGapResult;

  function CalculateAroundGapFromMm(
    const ATeeth: Integer;
    const ALabelAroundMm: Double;
    const AAroundUps: Integer;
    const AMinGapMm: Double = DEFAULT_MIN_GAP_MM;
    const AHardBlockGapMm: Double = 0.0;
    const APitchUm: Integer = STANDARD_PITCH_UM;
    const AAllowedFleet: TArray<Integer> = nil
  ): TGapResult;

  { Web fit validation }
  function CheckAcrossFit(
    const ALabelAcrossMm: Double;
    const AAcrossUps: Integer;
    const AAcrossGapMm: Double;
    const AEdgeMarginMm: Double;
    const AMaxWebWidthMm: Double
  ): TWebFitResult;

  { Multi-ups cylinder recommendation algorithm }
  function RecommendCylinders(
    const ALabelAroundMm: Double;
    const AMaxUps: Integer;
    const AAvailableTeeth: TArray<Integer>;
    const AMinGapMm: Double = DEFAULT_MIN_GAP_MM;
    const AHardBlockGapMm: Double = 0.0;
    const APitchUm: Integer = STANDARD_PITCH_UM;
    const AAllowedFleet: TArray<Integer> = nil
  ): TArray<TRecommendationResult>;

  { Find optimal single cylinder recommendation for a specific ups }
  function FindOptimalCylinderForUps(
    const ALabelAroundMm: Double;
    const AUps: Integer;
    const AAvailableTeeth: TArray<Integer>;
    const AMinGapMm: Double = DEFAULT_MIN_GAP_MM;
    const AHardBlockGapMm: Double = 0.0;
    const APitchUm: Integer = STANDARD_PITCH_UM;
    const AAllowedFleet: TArray<Integer> = nil
  ): TRecommendationResult;

  { Evaluates whether a flatbed die can be used bi-directionally (rotated 90 degrees)
    Rule:
      1. Category must be Rollform (fcRollForm).
      2. If 1x1 ups: Can rotate in both directions.
      3. If multi-ups: Can rotate ONLY if around size and across size are identical. }
  function CanFlatbedDieRotate(
    const ACategory: TFlatbedCategory;
    const AAroundUps, AAcrossUps: Integer;
    const AAroundSizeMm, AAcrossSizeMm: Double
  ): Boolean; overload;

  function CanFlatbedDieRotate(
    const ACategoryStr: string;
    const AAroundUps, AAcrossUps: Integer;
    const AAroundSizeMm, AAcrossSizeMm: Double
  ): Boolean; overload;

  { Checks if flatbed die dimensions match a target dimension, evaluating both
    normal orientation and 90-degree rotated orientation when rotation is supported }
  function MatchesFlatbedDimensions(
    const ADieAroundMm, ADieAcrossMm: Double;
    const ATargetAroundMm, ATargetAcrossMm: Double;
    const ACanRotate: Boolean;
    out AIsRotated: Boolean;
    const AToleranceMm: Double = 0.050
  ): Boolean; overload;

  function MatchesFlatbedDimensions(
    const ADieAroundMm, ADieAcrossMm: Double;
    const ATargetAroundMm, ATargetAcrossMm: Double;
    const ACanRotate: Boolean;
    const AToleranceMm: Double = 0.050
  ): Boolean; overload;

implementation

{ -----------------------------------------------------------------------------
  Conversions
----------------------------------------------------------------------------- }

{ Converts millimetres (Double) to integer micrometres (Int64).
  Uses standard commercial rounding: round half away from zero,
  avoiding Delphi's default banker's rounding (round to nearest even) which rounds
  halfway values (like 0.5) to the nearest even number.
  Because fractional decimal values cannot always be represented exactly in binary
  floating point, their scaled values can fall infinitesimally below exact half-integers.
  In 64-bit IEEE 754 Double precision, 0.5005 * 1000.0 = 500.49999999999994 is a genuine
  example that falls slightly short of 500.5. In 32-bit x87 80-bit extended precision,
  values like 2.9995 * 1000.0 similarly produce representation deficits below 2999.5
  (whereas in plain IEEE Double, 2.9995 * 1000.0 equals exactly 2999.5).
  A sub-picometre epsilon (1E-9) applied with the sign of the input ensures that
  these decimal half-way boundaries round half away from zero as intended in shop-floor
  specifications, without affecting values even 1 nanometre below (such as 0.000499 mm).
  Examples:
    +0.5005 mm   -> +501 um (IEEE 754 double-precision representation deficit)
    -0.5005 mm   -> -501 um
    +2.9995 mm   -> +3000 um (x87 80-bit extended-precision representation deficit)
    -2.9995 mm   -> -3000 um
    +0.0005 mm   -> +1 um
    -0.0005 mm   -> -1 um
    +0.000499 mm -> 0 um
    -0.000499 mm -> 0 um
    0.0 mm       -> 0 um }
function MmToUm(const AMm: Double): Int64;
const
  Epsilon = 1E-9;
begin
  if AMm >= 0.0 then
    Result := Trunc(AMm * 1000.0 + 0.5 + Epsilon)
  else
    Result := Trunc(AMm * 1000.0 - 0.5 - Epsilon);
end;

function UmToMm(const AUm: Int64): Double;
begin
  Result := AUm / 1000.0;
end;

{ -----------------------------------------------------------------------------
  Fleet Validation
----------------------------------------------------------------------------- }

function IsCylinderInFleet(const ATeeth: Integer; const AFleet: TArray<Integer>): Boolean;
var
  T: Integer;
begin
  if Length(AFleet) > 0 then
  begin
    for T in AFleet do
      if T = ATeeth then
        Exit(True);
    Exit(False);
  end;

  for T in DEFAULT_CYLINDER_FLEET do
    if T = ATeeth then
      Exit(True);
  Result := False;
end;

{ -----------------------------------------------------------------------------
  Cylinder Repeat
----------------------------------------------------------------------------- }

function TeethToRepeatUm(const ATeeth: Integer; const APitchUm: Integer): Int64;
begin
  if (ATeeth <= 0) or (APitchUm <= 0) then
    Exit(0);
  Result := Int64(ATeeth) * Int64(APitchUm);
end;

function TeethToRepeatMm(const ATeeth: Integer; const APitchUm: Integer): Double;
begin
  Result := TeethToRepeatUm(ATeeth, APitchUm) / 1000.0;
end;

function TeethToRepeatInch(const ATeeth: Integer): Double;
begin
  if ATeeth <= 0 then
    Exit(0.0);
  Result := ATeeth / 8.0;
end;

{ -----------------------------------------------------------------------------
  Around Gap Calculation
----------------------------------------------------------------------------- }

function CalculateAroundGap(
  const ATeeth: Integer;
  const ALabelAroundUm: Int64;
  const AAroundUps: Integer;
  const AMinGapUm: Int64;
  const AHardBlockGapUm: Int64;
  const APitchUm: Integer;
  const AAllowedFleet: TArray<Integer>
): TGapResult;
var
  TotalCutUm: Int64;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Teeth := ATeeth;
  Result.AroundUps := AAroundUps;
  Result.LabelAroundUm := ALabelAroundUm;

  // Input validation
  if (ATeeth <= 0) or (AAroundUps <= 0) or (ALabelAroundUm <= 0) then
  begin
    Result.Status := gsMechanicallyRejected;
    Result.RequiresOverrideReason := False;
    Result.StatusMessage := 'Invalid input parameters (must be > 0)';
    Exit;
  end;

  // Fleet check if allowed fleet specified
  if (Length(AAllowedFleet) > 0) and (not IsCylinderInFleet(ATeeth, AAllowedFleet)) then
  begin
    Result.Status := gsMechanicallyRejected;
    Result.RequiresOverrideReason := False;
    Result.StatusMessage := 'Cylinder ' + IntToStr(ATeeth) + 'T is not supported in the active fleet';
    Exit;
  end;

  Result.CylinderRepeatUm := TeethToRepeatUm(ATeeth, APitchUm);
  Result.CylinderRepeatMm := Result.CylinderRepeatUm / 1000.0;
  Result.CylinderRepeatInch := TeethToRepeatInch(ATeeth);

  TotalCutUm := Int64(AAroundUps) * ALabelAroundUm;
  Result.TotalGapPoolUm := Result.CylinderRepeatUm - TotalCutUm;

  // If label cut length exceeds cylinder repeat, it physically cannot fit
  if Result.TotalGapPoolUm < 0 then
  begin
    Result.AroundGapUm := Result.TotalGapPoolUm div AAroundUps;
    Result.AroundGapMm := Result.AroundGapUm / 1000.0;
    Result.WastePercent := 0.0;
    Result.Status := gsMechanicallyRejected;
    Result.RequiresOverrideReason := False;
    Result.StatusMessage := 'Physically impossible: label cut length exceeds cylinder repeat';
    Exit;
  end;

  // Integer micrometres division
  Result.AroundGapUm := Result.TotalGapPoolUm div AAroundUps;
  Result.RemainderUm := Result.TotalGapPoolUm mod AAroundUps;
  
  // High-precision millimetre output including fractional remainder
  Result.AroundGapMm := Result.TotalGapPoolUm / (Double(AAroundUps) * 1000.0);

  // Waste percentage: (Total gap pool / Repeat) * 100
  if Result.CylinderRepeatUm > 0 then
    Result.WastePercent := (Double(Result.TotalGapPoolUm) / Double(Result.CylinderRepeatUm)) * 100.0
  else
    Result.WastePercent := 0.0;

  // Policy evaluation:
  // 1. Meets or exceeds configured minimum gap -> Standard Approved
  if Result.TotalGapPoolUm >= (Int64(AAroundUps) * AMinGapUm) then
  begin
    Result.Status := gsStandardApproved;
    Result.RequiresOverrideReason := False;
    Result.StatusMessage := 'Approved (>= ' + FormatFloat('0.000', AMinGapUm / 1000.0) + ' mm)';
  end
  // 2. Below hard-block threshold (if hard block is explicitly configured > 0)
  else if (AHardBlockGapUm > 0) and (Result.TotalGapPoolUm < (Int64(AAroundUps) * AHardBlockGapUm)) then
  begin
    Result.Status := gsMechanicallyRejected;
    Result.RequiresOverrideReason := False;
    Result.StatusMessage := 'Rejected: Gap below hard mechanical block threshold (< ' + 
                            FormatFloat('0.000', AHardBlockGapUm / 1000.0) + ' mm)';
  end
  // 3. Below minimum gap, but not hard blocked -> Warning requiring override reason
  else
  begin
    Result.Status := gsSubStandardWarning;
    Result.RequiresOverrideReason := True;
    Result.StatusMessage := 'Warning: Sub-standard gap (' + FormatFloat('0.000', Result.AroundGapMm) + 
                            ' mm < ' + FormatFloat('0.000', AMinGapUm / 1000.0) + ' mm). Override reason required.';
  end;
end;

function CalculateAroundGapFromMm(
  const ATeeth: Integer;
  const ALabelAroundMm: Double;
  const AAroundUps: Integer;
  const AMinGapMm: Double;
  const AHardBlockGapMm: Double;
  const APitchUm: Integer;
  const AAllowedFleet: TArray<Integer>
): TGapResult;
begin
  Result := CalculateAroundGap(
    ATeeth,
    MmToUm(ALabelAroundMm),
    AAroundUps,
    MmToUm(AMinGapMm),
    MmToUm(AHardBlockGapMm),
    APitchUm,
    AAllowedFleet
  );
end;

{ -----------------------------------------------------------------------------
  Web Fit Verification
----------------------------------------------------------------------------- }

function CheckAcrossFit(
  const ALabelAcrossMm: Double;
  const AAcrossUps: Integer;
  const AAcrossGapMm: Double;
  const AEdgeMarginMm: Double;
  const AMaxWebWidthMm: Double
): TWebFitResult;
var
  LabelAcrossUm, AcrossGapUm, EdgeMarginUm, MaxWebWidthUm: Int64;
  ToolingWidthUm, RequiredWebWidthUm, ExcessUm: Int64;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.AcrossUps := AAcrossUps;
  Result.LabelAcrossMm := ALabelAcrossMm;
  Result.AcrossGapMm := AAcrossGapMm;
  Result.EdgeMarginMm := AEdgeMarginMm;
  Result.MaxWebWidthMm := AMaxWebWidthMm;

  if (AAcrossUps <= 0) or (ALabelAcrossMm <= 0.0) then
  begin
    Result.Fits := False;
    Exit;
  end;

  LabelAcrossUm := MmToUm(ALabelAcrossMm);
  AcrossGapUm := MmToUm(AAcrossGapMm);
  EdgeMarginUm := MmToUm(AEdgeMarginMm);
  MaxWebWidthUm := MmToUm(AMaxWebWidthMm);

  // Tooling width = (ups * label_width) + ((ups - 1) * across_gap)
  ToolingWidthUm := Int64(AAcrossUps) * LabelAcrossUm;
  if AAcrossUps > 1 then
    ToolingWidthUm := ToolingWidthUm + (Int64(AAcrossUps - 1) * AcrossGapUm);

  // Total web required = Tooling width + 2 * edge margins
  RequiredWebWidthUm := ToolingWidthUm + (2 * EdgeMarginUm);

  Result.ToolingWidthMm := UmToMm(ToolingWidthUm);
  Result.RequiredWebWidthMm := UmToMm(RequiredWebWidthUm);

  if MaxWebWidthUm <= 0 then
  begin
    Result.Fits := True;
    Result.ExcessMm := 0.0;
  end
  else
  begin
    Result.Fits := (RequiredWebWidthUm <= MaxWebWidthUm);
    if not Result.Fits then
    begin
      ExcessUm := RequiredWebWidthUm - MaxWebWidthUm;
      Result.ExcessMm := UmToMm(ExcessUm);
    end
    else
      Result.ExcessMm := 0.0;
  end;
end;

{ -----------------------------------------------------------------------------
  Cylinder Recommendation Algorithm
----------------------------------------------------------------------------- }

function FindOptimalCylinderForUps(
  const ALabelAroundMm: Double;
  const AUps: Integer;
  const AAvailableTeeth: TArray<Integer>;
  const AMinGapMm: Double;
  const AHardBlockGapMm: Double;
  const APitchUm: Integer;
  const AAllowedFleet: TArray<Integer>
): TRecommendationResult;
var
  TeethList: TArray<Integer>;
  I, Teeth: Integer;
  GapRes: TGapResult;
  RequiredRepeatUm: Int64;
  CandidateRepeatUm: Int64;
  BestTeeth: Integer;
  BestGapRes: TGapResult;
  Found: Boolean;
  FilteredList: TList<Integer>;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Ups := AUps;

  if (AUps <= 0) or (ALabelAroundMm <= 0.0) then
  begin
    Result.Status := gsMechanicallyRejected;
    Result.StatusText := 'Invalid input parameters (ups and label dimension must be > 0)';
    Result.IsOptimal := False;
    Result.RequiresOverrideReason := False;
    Exit;
  end;

  if Length(AAvailableTeeth) > 0 then
    TeethList := Copy(AAvailableTeeth)
  else
  begin
    SetLength(TeethList, Length(DEFAULT_CYLINDER_FLEET));
    for I := 0 to High(DEFAULT_CYLINDER_FLEET) do
      TeethList[I] := DEFAULT_CYLINDER_FLEET[I];
  end;

  // Apply optional machine / fleet compatibility filter if provided
  if Length(AAllowedFleet) > 0 then
  begin
    FilteredList := TList<Integer>.Create;
    try
      for Teeth in TeethList do
        if IsCylinderInFleet(Teeth, AAllowedFleet) then
          FilteredList.Add(Teeth);
      TeethList := FilteredList.ToArray;
    finally
      FilteredList.Free;
    end;
  end;

  if Length(TeethList) = 0 then
  begin
    Result.Status := gsMechanicallyRejected;
    Result.StatusText := 'No cylinders available in specified fleet';
    Result.IsOptimal := False;
    Result.RequiresOverrideReason := False;
    Exit;
  end;

  TArray.Sort<Integer>(TeethList);

  RequiredRepeatUm := Int64(AUps) * (MmToUm(ALabelAroundMm) + MmToUm(AMinGapMm));
  Found := False;
  BestTeeth := 0;

  for Teeth in TeethList do
  begin
    CandidateRepeatUm := TeethToRepeatUm(Teeth, APitchUm);
    if CandidateRepeatUm >= RequiredRepeatUm then
    begin
      GapRes := CalculateAroundGapFromMm(Teeth, ALabelAroundMm, AUps, AMinGapMm, AHardBlockGapMm, APitchUm);
      if GapRes.Status in [gsStandardApproved, gsOptimal] then
      begin
        BestTeeth := Teeth;
        BestGapRes := GapRes;
        Found := True;
        Break; // Smallest cylinder >= required repeat gives the tightest approved gap!
      end;
    end;
  end;

  if Found then
  begin
    Result.Teeth := BestTeeth;
    Result.RepeatMm := BestGapRes.CylinderRepeatMm;
    Result.RepeatInch := BestGapRes.CylinderRepeatInch;
    Result.AroundGapMm := BestGapRes.AroundGapMm;
    Result.AroundGapUm := BestGapRes.AroundGapUm;
    Result.WastePercent := BestGapRes.WastePercent;
    Result.Status := gsOptimal;
    Result.IsOptimal := True;
    Result.RequiresOverrideReason := False;
    Result.StatusText := 'Optimal (Tightest Legal Gap)';
  end
  else
  begin
    // Fallback: Check if the largest available cylinder can at least fit with a warning
    Teeth := TeethList[High(TeethList)];
    GapRes := CalculateAroundGapFromMm(Teeth, ALabelAroundMm, AUps, AMinGapMm, AHardBlockGapMm, APitchUm);
    Result.Teeth := Teeth;
    Result.RepeatMm := GapRes.CylinderRepeatMm;
    Result.RepeatInch := GapRes.CylinderRepeatInch;
    Result.AroundGapMm := GapRes.AroundGapMm;
    Result.AroundGapUm := GapRes.AroundGapUm;
    Result.WastePercent := GapRes.WastePercent;
    Result.Status := GapRes.Status;
    Result.IsOptimal := False;
    Result.RequiresOverrideReason := GapRes.RequiresOverrideReason;
    Result.StatusText := GapRes.StatusMessage;
  end;
end;

function RecommendCylinders(
  const ALabelAroundMm: Double;
  const AMaxUps: Integer;
  const AAvailableTeeth: TArray<Integer>;
  const AMinGapMm: Double;
  const AHardBlockGapMm: Double;
  const APitchUm: Integer;
  const AAllowedFleet: TArray<Integer>
): TArray<TRecommendationResult>;
var
  TeethList: TArray<Integer>;
  Ups, Teeth, I: Integer;
  GapRes: TGapResult;
  CandidateList: TList<TRecommendationResult>;
  Rec: TRecommendationResult;
  SmallestLegalFoundForUps: Boolean;
  FilteredList: TList<Integer>;
begin
  if Length(AAvailableTeeth) > 0 then
    TeethList := Copy(AAvailableTeeth)
  else
  begin
    SetLength(TeethList, Length(DEFAULT_CYLINDER_FLEET));
    for I := 0 to High(DEFAULT_CYLINDER_FLEET) do
      TeethList[I] := DEFAULT_CYLINDER_FLEET[I];
  end;

  if Length(AAllowedFleet) > 0 then
  begin
    FilteredList := TList<Integer>.Create;
    try
      for Teeth in TeethList do
        if IsCylinderInFleet(Teeth, AAllowedFleet) then
          FilteredList.Add(Teeth);
      TeethList := FilteredList.ToArray;
    finally
      FilteredList.Free;
    end;
  end;

  TArray.Sort<Integer>(TeethList);
  SetLength(Result, 0);

  if Length(TeethList) = 0 then
    Exit;

  CandidateList := TList<TRecommendationResult>.Create;
  try
    for Ups := 1 to AMaxUps do
    begin
      SmallestLegalFoundForUps := False;

      for Teeth in TeethList do
      begin
        GapRes := CalculateAroundGapFromMm(Teeth, ALabelAroundMm, Ups, AMinGapMm, AHardBlockGapMm, APitchUm);
        
        // Exclude completely negative or physically unviable fits
        if GapRes.TotalGapPoolUm < 0 then
          Continue;

        FillChar(Rec, SizeOf(Rec), 0);
        Rec.Ups := Ups;
        Rec.Teeth := Teeth;
        Rec.RepeatMm := GapRes.CylinderRepeatMm;
        Rec.RepeatInch := GapRes.CylinderRepeatInch;
        Rec.AroundGapMm := GapRes.AroundGapMm;
        Rec.AroundGapUm := GapRes.AroundGapUm;
        Rec.WastePercent := GapRes.WastePercent;
        Rec.Status := GapRes.Status;
        Rec.RequiresOverrideReason := GapRes.RequiresOverrideReason;
        Rec.StatusText := GapRes.StatusMessage;

        // First cylinder with legal gap >= MinGap is marked Optimal for this ups
        if (GapRes.Status = gsStandardApproved) and not SmallestLegalFoundForUps then
        begin
          Rec.Status := gsOptimal;
          Rec.IsOptimal := True;
          Rec.StatusText := 'Optimal (Best Legal Repeat)';
          SmallestLegalFoundForUps := True;
        end;

        CandidateList.Add(Rec);
      end;
    end;

    Result := CandidateList.ToArray;
  finally
    CandidateList.Free;
  end;
end;

{ -----------------------------------------------------------------------------
  Flatbed Tooling Arithmetic & Orientation Evaluation
----------------------------------------------------------------------------- }

function CanFlatbedDieRotate(
  const ACategory: TFlatbedCategory;
  const AAroundUps, AAcrossUps: Integer;
  const AAroundSizeMm, AAcrossSizeMm: Double
): Boolean;
begin
  // Only Rollform tooling supports bi-directional rotation
  if (ACategory <> fcRollForm) then
    Exit(False);

  // 1x1 ups: always bi-directional (can be loaded around or across)
  if (AAroundUps = 1) and (AAcrossUps = 1) then
    Exit(True);

  // Multi-ups: only bi-directional if around and across sizes are identical
  Result := (Abs(AAroundSizeMm - AAcrossSizeMm) < 0.001);
end;

function CanFlatbedDieRotate(
  const ACategoryStr: string;
  const AAroundUps, AAcrossUps: Integer;
  const AAroundSizeMm, AAcrossSizeMm: Double
): Boolean;
var
  Cat: TFlatbedCategory;
begin
  if SameText(Trim(ACategoryStr), 'ROLL_FORM') or SameText(Trim(ACategoryStr), 'ROLLFORM') then
    Cat := fcRollForm
  else
    Cat := fcSheetForm;

  Result := CanFlatbedDieRotate(Cat, AAroundUps, AAcrossUps, AAroundSizeMm, AAcrossSizeMm);
end;

function MatchesFlatbedDimensions(
  const ADieAroundMm, ADieAcrossMm: Double;
  const ATargetAroundMm, ATargetAcrossMm: Double;
  const ACanRotate: Boolean;
  out AIsRotated: Boolean;
  const AToleranceMm: Double
): Boolean;
begin
  AIsRotated := False;

  // Direct orientation match
  if (Abs(ADieAroundMm - ATargetAroundMm) <= AToleranceMm) and
     (Abs(ADieAcrossMm - ATargetAcrossMm) <= AToleranceMm) then
    Exit(True);

  // 90-degree rotated match if die supports rotation
  if ACanRotate then
  begin
    if (Abs(ADieAroundMm - ATargetAcrossMm) <= AToleranceMm) and
       (Abs(ADieAcrossMm - ATargetAroundMm) <= AToleranceMm) then
    begin
      AIsRotated := True;
      Exit(True);
    end;
  end;

  Result := False;
end;

function MatchesFlatbedDimensions(
  const ADieAroundMm, ADieAcrossMm: Double;
  const ATargetAroundMm, ATargetAcrossMm: Double;
  const ACanRotate: Boolean;
  const AToleranceMm: Double
): Boolean;
var
  Rotated: Boolean;
begin
  Result := MatchesFlatbedDimensions(ADieAroundMm, ADieAcrossMm, ATargetAroundMm, ATargetAcrossMm, ACanRotate, Rotated, AToleranceMm);
end;

end.
