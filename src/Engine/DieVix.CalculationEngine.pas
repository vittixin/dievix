unit DieVix.CalculationEngine;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
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
  STANDARD_PITCH_UM: Integer = 3175;

  { Millimetres per inch }
  MM_PER_INCH: Double = 25.4;

  { Default gap policy thresholds in micrometres }
  DEFAULT_MIN_GAP_UM: Int64 = 3000;   // 3.000 mm (Standard approved threshold)
  DEFAULT_WARN_GAP_UM: Int64 = 2400;  // 2.400 mm (Shop tolerance override threshold)

  { Standard production cylinder tooth counts (16 sizes in fleet) }
  DEFAULT_CYLINDER_FLEET: array[0..15] of Integer = (
    66, 68, 72, 76, 82, 86, 90, 94, 96, 98, 102, 106, 112, 120, 126, 132
  );

type
  { Classification for gap legal status }
  TGapStatus = (
    gsOptimal,             // Tightest approved legal gap (>= MinGap)
    gsStandardApproved,    // Fully approved (>= MinGap)
    gsSubStandardWarning,  // Below MinGap, but within shop tolerance (e.g., 2.4 mm to 2.999 mm)
    gsMechanicallyRejected // Below WarnGap or negative (< 2.4 mm, stripping failure risk)
  );

  { Detailed result of an around gap computation }
  TGapResult = record
    Teeth: Integer;
    AroundUps: Integer;
    LabelAroundUm: Int64;
    CylinderRepeatUm: Int64;
    TotalGapPoolUm: Int64;      // Available substrate - (ups * label_size)
    AroundGapUm: Int64;         // Integer gap per label
    RemainderUm: Integer;       // Remainder from integer division
    AroundGapMm: Double;        // Floating point presentation (3 decimal places)
    CylinderRepeatMm: Double;
    CylinderRepeatInch: Double;
    WastePercent: Double;       // Total gap pool / repeat * 100
    Status: TGapStatus;
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

  { Cylinder repeat functions }
  function TeethToRepeatUm(const ATeeth: Integer; const APitchUm: Integer = 3175): Int64; inline;
  function TeethToRepeatMm(const ATeeth: Integer; const APitchUm: Integer = 3175): Double; inline;
  function TeethToRepeatInch(const ATeeth: Integer): Double; inline;

  { Around gap computation }
  function CalculateAroundGap(
    const ATeeth: Integer;
    const ALabelAroundUm: Int64;
    const AAroundUps: Integer;
    const AMinGapUm: Int64 = 3000;
    const AWarnGapUm: Int64 = 2400;
    const APitchUm: Integer = 3175
  ): TGapResult;

  function CalculateAroundGapFromMm(
    const ATeeth: Integer;
    const ALabelAroundMm: Double;
    const AAroundUps: Integer;
    const AMinGapMm: Double = 3.0;
    const AWarnGapMm: Double = 2.4;
    const APitchUm: Integer = 3175
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
    const AMinGapMm: Double = 3.0;
    const AWarnGapMm: Double = 2.4;
    const APitchUm: Integer = 3175
  ): TArray<TRecommendationResult>;

  { Find optimal single cylinder recommendation for a specific ups }
  function FindOptimalCylinderForUps(
    const ALabelAroundMm: Double;
    const AUps: Integer;
    const AAvailableTeeth: TArray<Integer>;
    const AMinGapMm: Double = 3.0;
    const AWarnGapMm: Double = 2.4;
    const APitchUm: Integer = 3175
  ): TRecommendationResult;

implementation

{ -----------------------------------------------------------------------------
  Conversions
----------------------------------------------------------------------------- }

function MmToUm(const AMm: Double): Int64;
begin
  // Standard rounding to nearest whole micrometre (e.g., 3.0001 -> 3000, 3.0009 -> 3001)
  Result := Round(AMm * 1000.0);
end;

function UmToMm(const AUm: Int64): Double;
begin
  Result := AUm / 1000.0;
end;

{ -----------------------------------------------------------------------------
  Cylinder Repeat
----------------------------------------------------------------------------- }

function TeethToRepeatUm(const ATeeth: Integer; const APitchUm: Integer): Int64;
begin
  if ATeeth <= 0 then
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
  const AWarnGapUm: Int64;
  const APitchUm: Integer
): TGapResult;
var
  TotalCutUm: Int64;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Teeth := ATeeth;
  Result.AroundUps := AAroundUps;
  Result.LabelAroundUm := ALabelAroundUm;

  if (ATeeth <= 0) or (AAroundUps <= 0) or (ALabelAroundUm <= 0) then
  begin
    Result.Status := gsMechanicallyRejected;
    Result.StatusMessage := 'Invalid input parameters (must be > 0)';
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
    Result.StatusMessage := 'Cut size exceeds cylinder repeat';
    Exit;
  end;

  // Integer micrometres division
  Result.AroundGapUm := Result.TotalGapPoolUm div AAroundUps;
  Result.RemainderUm := Result.TotalGapPoolUm mod AAroundUps;
  
  // High-precision millimetre output including fractional remainder
  Result.AroundGapMm := Result.TotalGapPoolUm / (Double(AAroundUps) * 1000.0);

  // Waste percentage: (Total gap / Repeat) * 100
  if Result.CylinderRepeatUm > 0 then
    Result.WastePercent := (Double(Result.TotalGapPoolUm) / Double(Result.CylinderRepeatUm)) * 100.0
  else
    Result.WastePercent := 0.0;

  // Rational integer comparison: eliminates floating-point noise
  // TotalGapPoolUm >= AroundUps * MinGapUm
  if Result.TotalGapPoolUm >= (Int64(AAroundUps) * AMinGapUm) then
  begin
    Result.Status := gsStandardApproved;
    Result.StatusMessage := 'Approved (>= ' + FormatFloat('0.000', AMinGapUm / 1000.0) + ' mm)';
  end
  else if Result.TotalGapPoolUm >= (Int64(AAroundUps) * AWarnGapUm) then
  begin
    Result.Status := gsSubStandardWarning;
    Result.StatusMessage := 'Warning: Sub-standard gap (Shop override required)';
  end
  else
  begin
    Result.Status := gsMechanicallyRejected;
    Result.StatusMessage := 'Rejected: Gap below minimum mechanical threshold (< ' + 
                            FormatFloat('0.000', AWarnGapUm / 1000.0) + ' mm)';
  end;
end;

function CalculateAroundGapFromMm(
  const ATeeth: Integer;
  const ALabelAroundMm: Double;
  const AAroundUps: Integer;
  const AMinGapMm: Double;
  const AWarnGapMm: Double;
  const APitchUm: Integer
): TGapResult;
begin
  Result := CalculateAroundGap(
    ATeeth,
    MmToUm(ALabelAroundMm),
    AAroundUps,
    MmToUm(AMinGapMm),
    MmToUm(AWarnGapMm),
    APitchUm
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
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.AcrossUps := AAcrossUps;
  Result.LabelAcrossMm := ALabelAcrossMm;
  Result.AcrossGapMm := AAcrossGapMm;
  Result.EdgeMarginMm := AEdgeMarginMm;
  Result.MaxWebWidthMm := AMaxWebWidthMm;

  if (AAcrossUps <= 0) or (ALabelAcrossMm <= 0) then
  begin
    Result.Fits := False;
    Exit;
  end;

  // Tooling width = (ups * label_width) + ((ups - 1) * across_gap)
  Result.ToolingWidthMm := (AAcrossUps * ALabelAcrossMm);
  if AAcrossUps > 1 then
    Result.ToolingWidthMm := Result.ToolingWidthMm + ((AAcrossUps - 1) * AAcrossGapMm);

  // Total web required = Tooling width + 2 * edge margins
  Result.RequiredWebWidthMm := Result.ToolingWidthMm + (2.0 * AEdgeMarginMm);

  if AMaxWebWidthMm <= 0 then
    Result.Fits := True
  else
  begin
    Result.Fits := Result.RequiredWebWidthMm <= AMaxWebWidthMm;
    if not Result.Fits then
      Result.ExcessMm := Result.RequiredWebWidthMm - AMaxWebWidthMm
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
  const AWarnGapMm: Double;
  const APitchUm: Integer
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
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Ups := AUps;

  if Length(AAvailableTeeth) > 0 then
    TeethList := Copy(AAvailableTeeth)
  else
  begin
    SetLength(TeethList, Length(DEFAULT_CYLINDER_FLEET));
    for I := 0 to High(DEFAULT_CYLINDER_FLEET) do
      TeethList[I] := DEFAULT_CYLINDER_FLEET[I];
  end;

  // Sort teeth ascending
  TArray.Sort<Integer>(TeethList);

  RequiredRepeatUm := Int64(AUps) * (MmToUm(ALabelAroundMm) + MmToUm(AMinGapMm));
  Found := False;
  BestTeeth := 0;

  for Teeth in TeethList do
  begin
    CandidateRepeatUm := TeethToRepeatUm(Teeth, APitchUm);
    if CandidateRepeatUm >= RequiredRepeatUm then
    begin
      GapRes := CalculateAroundGapFromMm(Teeth, ALabelAroundMm, AUps, AMinGapMm, AWarnGapMm, APitchUm);
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
    Result.StatusText := 'Optimal (Tightest Legal Gap)';
  end
  else
  begin
    // Fallback: Check if the largest available cylinder can at least fit with a warning
    if Length(TeethList) > 0 then
    begin
      Teeth := TeethList[High(TeethList)];
      GapRes := CalculateAroundGapFromMm(Teeth, ALabelAroundMm, AUps, AMinGapMm, AWarnGapMm, APitchUm);
      Result.Teeth := Teeth;
      Result.RepeatMm := GapRes.CylinderRepeatMm;
      Result.RepeatInch := GapRes.CylinderRepeatInch;
      Result.AroundGapMm := GapRes.AroundGapMm;
      Result.AroundGapUm := GapRes.AroundGapUm;
      Result.WastePercent := GapRes.WastePercent;
      Result.Status := GapRes.Status;
      Result.IsOptimal := False;
      Result.StatusText := GapRes.StatusMessage;
    end;
  end;
end;

function RecommendCylinders(
  const ALabelAroundMm: Double;
  const AMaxUps: Integer;
  const AAvailableTeeth: TArray<Integer>;
  const AMinGapMm: Double;
  const AWarnGapMm: Double;
  const APitchUm: Integer
): TArray<TRecommendationResult>;
var
  TeethList: TArray<Integer>;
  Ups, Teeth, I: Integer;
  GapRes: TGapResult;
  CandidateList: TList<TRecommendationResult>;
  Rec: TRecommendationResult;
  SmallestLegalFoundForUps: Boolean;
begin
  if Length(AAvailableTeeth) > 0 then
    TeethList := Copy(AAvailableTeeth)
  else
  begin
    SetLength(TeethList, Length(DEFAULT_CYLINDER_FLEET));
    for I := 0 to High(DEFAULT_CYLINDER_FLEET) do
      TeethList[I] := DEFAULT_CYLINDER_FLEET[I];
  end;

  TArray.Sort<Integer>(TeethList);
  SetLength(Result, 0);

  CandidateList := TList<TRecommendationResult>.Create;
  try
    for Ups := 1 to AMaxUps do
    begin
      SmallestLegalFoundForUps := False;

      for Teeth in TeethList do
      begin
        GapRes := CalculateAroundGapFromMm(Teeth, ALabelAroundMm, Ups, AMinGapMm, AWarnGapMm, APitchUm);
        
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

end.
