unit DieVix.KeylineService;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Keyline Calculator & Cylinder Optimization Application Service
  Orchestrates integer-micrometre rotary calculations, machine web-fit
  verification, cylinder fleet recommendations, and existing die reuse discovery.
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults,
  DieVix.Domain,
  DieVix.Repositories,
  DieVix.CalculationEngine;

type
  { Keyline Application Service }
  TKeylineService = class
  private
    FCylinderRepo: ICylinderRepository;
    FMachineRepo: IMachineRepository;
    FMachineCylinderRepo: IMachineCylinderRepository;
    FDieRepo: IDieRepository;
    FSettingRepo: IAppSettingRepository;
  public
    constructor Create(
      ACylinderRepo: ICylinderRepository = nil;
      AMachineRepo: IMachineRepository = nil;
      AMachineCylinderRepo: IMachineCylinderRepository = nil;
      ADieRepo: IDieRepository = nil;
      ASettingRepo: IAppSettingRepository = nil
    );

    { Core Keyline Optimization }
    function Calculate(const AInput: TKeylineInput): TKeylineCalculationResult;

    { Web Fit Verification }
    function CalculateWebFit(
      const ALabelAcrossMm: Double;
      const AAcrossUps: Integer;
      const AAcrossGapMm: Double;
      const ALeftMarginMm, ARightMarginMm: Double;
      const AMachineID: Integer
    ): TWebFitResult;

    { Existing Die Reuse Match Search for a specific Cylinder }
    function FindMatchingDies(
      const ATeeth: Integer;
      const AAroundMm, AAcrossMm: Double;
      const AToleranceMm: Double = 2.0
    ): TList<TSmartDieSearchResult>;

    { Draft Die Creation from Recommendation }
    function CreateDraftDie(
      const ARec: TKeylineRecommendation;
      const AInput: TKeylineInput;
      const ACustomerID: Integer = 0
    ): TDie;

    { Master Data Access }
    function GetActiveMachines: TList<TMachine>;
    function GetActiveCylinders: TList<TCylinder>;

    property CylinderRepo: ICylinderRepository read FCylinderRepo;
    property MachineRepo: IMachineRepository read FMachineRepo;
    property MachineCylinderRepo: IMachineCylinderRepository read FMachineCylinderRepo;
    property DieRepo: IDieRepository read FDieRepo;
    property SettingRepo: IAppSettingRepository read FSettingRepo;
  end;

implementation

{ TKeylineService }

constructor TKeylineService.Create(
  ACylinderRepo: ICylinderRepository;
  AMachineRepo: IMachineRepository;
  AMachineCylinderRepo: IMachineCylinderRepository;
  ADieRepo: IDieRepository;
  ASettingRepo: IAppSettingRepository
);
begin
  inherited Create;
  if Assigned(ACylinderRepo) then FCylinderRepo := ACylinderRepo else FCylinderRepo := TCylinderRepository.Create;
  if Assigned(AMachineRepo) then FMachineRepo := AMachineRepo else FMachineRepo := TMachineRepository.Create;
  if Assigned(AMachineCylinderRepo) then FMachineCylinderRepo := AMachineCylinderRepo else FMachineCylinderRepo := TMachineCylinderRepository.Create;
  if Assigned(ADieRepo) then FDieRepo := ADieRepo else FDieRepo := TDieRepository.Create;
  if Assigned(ASettingRepo) then FSettingRepo := ASettingRepo else FSettingRepo := TAppSettingRepository.Create;
end;

function TKeylineService.GetActiveMachines: TList<TMachine>;
begin
  Result := FMachineRepo.GetAll(True);
end;

function TKeylineService.GetActiveCylinders: TList<TCylinder>;
begin
  Result := FCylinderRepo.GetAll(True);
end;

function TKeylineService.CalculateWebFit(
  const ALabelAcrossMm: Double;
  const AAcrossUps: Integer;
  const AAcrossGapMm: Double;
  const ALeftMarginMm, ARightMarginMm: Double;
  const AMachineID: Integer
): TWebFitResult;
var
  Mach: TMachine;
  MaxWeb: Double;
begin
  MaxWeb := 0.0;
  if AMachineID > 0 then
  begin
    Mach := FMachineRepo.GetByID(AMachineID);
    MaxWeb := Mach.MaxWebWidthMm;
  end;

  Result := CheckAcrossFit(
    ALabelAcrossMm,
    AAcrossUps,
    AAcrossGapMm,
    (ALeftMarginMm + ARightMarginMm) / 2.0, // average for engine check
    MaxWeb
  );

  // Re-adjust exact separate margins
  Result.RequiredWebWidthMm := Result.ToolingWidthMm + ALeftMarginMm + ARightMarginMm;
  if MaxWeb > 0 then
  begin
    Result.Fits := Result.RequiredWebWidthMm <= MaxWeb;
    if not Result.Fits then
      Result.ExcessMm := Result.RequiredWebWidthMm - MaxWeb
    else
      Result.ExcessMm := 0.0;
  end;
end;

function TKeylineService.FindMatchingDies(
  const ATeeth: Integer;
  const AAroundMm, AAcrossMm: Double;
  const AToleranceMm: Double
): TList<TSmartDieSearchResult>;
var
  Filter: TSmartDieSizeFilter;
  TotalCount: Integer;
begin
  Filter := TSmartDieSizeFilter.CreateDefault(AAroundMm, AAcrossMm, AToleranceMm);
  Filter.Teeth := ATeeth;
  Filter.IncludeSlitting := True;
  Filter.ActiveOnly := True;
  Result := FDieRepo.SmartSearchDies(Filter, TotalCount);
end;

function TKeylineService.CreateDraftDie(
  const ARec: TKeylineRecommendation;
  const AInput: TKeylineInput;
  const ACustomerID: Integer
): TDie;
var
  SerialCandidate: string;
  Counter: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);

  // Generate unique draft serial candidate
  Counter := 1;
  repeat
    SerialCandidate := Format('DIE-%dT-%dx%d-%d', [
      ARec.Teeth,
      Trunc(AInput.LabelAroundMm),
      Trunc(AInput.LabelAcrossMm),
      Counter
    ]);
    Inc(Counter);
  until not FDieRepo.SerialExists(SerialCandidate, 0);

  Result := TDie.CreateNew(
    SerialCandidate,
    ARec.Teeth,
    AInput.LabelAroundMm,
    AInput.LabelAcrossMm,
    ARec.AroundUps,
    AInput.AcrossUps
  );

  Result.PitchUm := ARec.PitchUm;
  Result.AcrossGapMm := AInput.AcrossGapMm;
  Result.CornerRadiusMm := AInput.CornerRadiusMm;
  Result.Shape := AInput.Shape;
  Result.MediaID := AInput.MediaID;
  Result.CustomerID := ACustomerID;
  Result.StatusCode := 'AVAILABLE';
  Result.Description := Format('Keyline %0.1fx%0.1f (%dT %dx%d ups)', [
    AInput.LabelAroundMm,
    AInput.LabelAcrossMm,
    ARec.Teeth,
    ARec.AroundUps,
    AInput.AcrossUps
  ]);

  if ARec.RequiresOverrideReason then
    Result.OverrideReason := 'Sub-3mm around gap accepted from Keyline Calculator';
end;

function TKeylineService.Calculate(const AInput: TKeylineInput): TKeylineCalculationResult;
var
  CylList: TList<TCylinder>;
  AssignedTeeth: TList<Integer>;
  Mach: TMachine;
  ExistingDiesFilter: TSmartDieSizeFilter;
  AllExistingDies: TList<TSmartDieSearchResult>;
  TotalDieCount: Integer;
  RecommendationsList: TList<TKeylineRecommendation>;
  Rec: TKeylineRecommendation;
  StartUps, EndUps, Ups, I, T: Integer;
  LabelAroundUm, LabelAcrossUm, MinGapUm, HardBlockGapUm, AcrossGapUm: Int64;
  LeftMarginUm, RightMarginUm: Int64;
  ToolingWidthUm, TotalWebWidthUm: Int64;
  ToolingWidthMm, TotalWebWidthMm: Double;
  Pitch: Integer;
  Cyl: TCylinder;
  CylTeeth: Integer;
  RepeatUm, RequiredCutUm, RemainingUm: Int64;
  GapUm: Int64;
  RemainderUm: Integer;
  GapMm, WastePct: Double;
  GapStatus: TGapStatus;
  ReqOverride: Boolean;
  Category: TKeylineRecommendationCategory;
  MachStatus: TMachineFitStatus;
  MachText, ReasonText: string;
  IsMachAssigned: Boolean;
  WebFits: Boolean;
  MatchingDieCount: Integer;
  Score: Integer;

  // Trackers per ups for recommendation strategy
  SmallestLegalFound: Boolean;
  NextLargerFound: Boolean;
  BelowMinCandidateFound: Boolean;
  BelowMinRec: TKeylineRecommendation;
  UpsCandidates: TList<TKeylineRecommendation>;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Input := AInput;

  // Basic validation: positive dimensions required
  if (AInput.LabelAroundMm <= 0.0) or (AInput.LabelAcrossMm <= 0.0) then
    Exit;

  RecommendationsList := TList<TKeylineRecommendation>.Create;
  UpsCandidates := TList<TKeylineRecommendation>.Create;
  try
    // 1. Load active cylinders from database
    CylList := FCylinderRepo.GetAll(AInput.ActiveCylindersOnly);
    try
      if CylList.Count = 0 then
        Exit;

      // Sort cylinders strictly by teeth count
      CylList.Sort(TComparer<TCylinder>.Construct(
        function(const Left, Right: TCylinder): Integer
        begin
          Result := Left.Teeth - Right.Teeth;
        end
      ));

      // 2. Load machine context if specified
      AssignedTeeth := nil;
      FillChar(Mach, SizeOf(Mach), 0);
      if AInput.MachineID > 0 then
      begin
        Mach := FMachineRepo.GetByID(AInput.MachineID);
        Result.Machine := Mach;
        AssignedTeeth := FMachineCylinderRepo.GetCylindersForMachine(AInput.MachineID);
      end;

      try
        // 3. Fast pre-query of existing dies near target dimensions
        ExistingDiesFilter := TSmartDieSizeFilter.CreateDefault(AInput.LabelAroundMm, AInput.LabelAcrossMm, 2.000);
        ExistingDiesFilter.IncludeSlitting := True;
        ExistingDiesFilter.ActiveOnly := True;
        AllExistingDies := FDieRepo.SmartSearchDies(ExistingDiesFilter, TotalDieCount);
        try
          // Conversions to integer micrometres
          LabelAroundUm := MmToUm(AInput.LabelAroundMm);
          LabelAcrossUm := MmToUm(AInput.LabelAcrossMm);
          MinGapUm := MmToUm(AInput.MinAroundGapMm);
          if MinGapUm <= 0 then MinGapUm := DEFAULT_MIN_GAP_UM;
          HardBlockGapUm := MmToUm(AInput.HardBlockGapMm);
          AcrossGapUm := MmToUm(AInput.AcrossGapMm);
          LeftMarginUm := MmToUm(AInput.LeftMarginMm);
          RightMarginUm := MmToUm(AInput.RightMarginMm);

          // Calculate across tooling width and web width
          ToolingWidthUm := Int64(AInput.AcrossUps) * LabelAcrossUm;
          if AInput.AcrossUps > 1 then
            ToolingWidthUm := ToolingWidthUm + (Int64(AInput.AcrossUps - 1) * AcrossGapUm);
          TotalWebWidthUm := ToolingWidthUm + LeftMarginUm + RightMarginUm;
          ToolingWidthMm := UmToMm(ToolingWidthUm);
          TotalWebWidthMm := UmToMm(TotalWebWidthUm);

          // Web fit status
          WebFits := True;
          if (AInput.MachineID > 0) and (Mach.MaxWebWidthMm > 0.0) then
            WebFits := TotalWebWidthMm <= Mach.MaxWebWidthMm;

          // Pitch selection
          if AInput.PitchUm > 0 then
            Pitch := AInput.PitchUm
          else
            Pitch := STANDARD_PITCH_UM;

          // Determine ups range
          if AInput.UpsMode = usmFixedUps then
          begin
            StartUps := Max(1, AInput.FixedAroundUps);
            EndUps := StartUps;
          end
          else
          begin
            StartUps := 1;
            EndUps := Max(1, Min(AInput.MaxAroundUps, 20));
          end;

          // 4. Iterate ups counts
          for Ups := StartUps to EndUps do
          begin
            UpsCandidates.Clear;
            SmallestLegalFound := False;
            NextLargerFound := False;
            BelowMinCandidateFound := False;
            FillChar(BelowMinRec, SizeOf(BelowMinRec), 0);

            RequiredCutUm := Int64(Ups) * LabelAroundUm;

            for I := 0 to CylList.Count - 1 do
            begin
              Cyl := CylList[I];
              CylTeeth := Cyl.Teeth;
              RepeatUm := TeethToRepeatUm(CylTeeth, Pitch);
              RemainingUm := RepeatUm - RequiredCutUm;

              // Check existing dies for this teeth count
              MatchingDieCount := 0;
              for T := 0 to AllExistingDies.Count - 1 do
              begin
                if AllExistingDies[T].Die.Teeth = CylTeeth then
                  Inc(MatchingDieCount);
              end;

              // Check machine cylinder assignment
              IsMachAssigned := True;
              if (AInput.MachineID > 0) and Assigned(AssignedTeeth) then
                IsMachAssigned := AssignedTeeth.Contains(CylTeeth);

              // Initialize recommendation record
              FillChar(Rec, SizeOf(Rec), 0);
              Rec.AroundUps := Ups;
              Rec.AcrossUps := AInput.AcrossUps;
              Rec.Teeth := CylTeeth;
              Rec.PitchUm := Pitch;
              Rec.RepeatMm := TeethToRepeatMm(CylTeeth, Pitch);
              Rec.RepeatInch := TeethToRepeatInch(CylTeeth);
              Rec.ToolingWidthMm := ToolingWidthMm;
              Rec.TotalWebWidthMm := TotalWebWidthMm;
              if AInput.MachineID > 0 then
              begin
                Rec.MachineMaxWebWidthMm := Mach.MaxWebWidthMm;
                Rec.RemainingWebWidthMm := Mach.MaxWebWidthMm - TotalWebWidthMm;
              end;
              Rec.ExistingDieCount := MatchingDieCount;

              // Physical geometry checks
              if RemainingUm < 0 then
              begin
                // Required cut exceeds cylinder circumference -> Mechanically impossible
                Rec.AroundGapUm := 0;
                Rec.AroundGapMm := 0.0;
                Rec.RemainderUm := 0;
                Rec.CircumferentialGapPercent := 0.0;
                Rec.GapStatus := gsMechanicallyRejected;
                Rec.RequiresOverrideReason := False;
                Rec.Category := krcMechanicallyRejected;
                Rec.CategoryText := 'Mechanically Rejected';
                Rec.IsEligible := False;
                Rec.RecommendationReason := Format('Cut (%0.1f mm) exceeds cylinder repeat (%0.1f mm)', [
                  UmToMm(RequiredCutUm), Rec.RepeatMm
                ]);
              end
              else
              begin
                // Viable circumference
                GapUm := RemainingUm div Ups;
                RemainderUm := RemainingUm mod Ups;
                GapMm := RemainingUm / (Ups * 1000.0);
                if RepeatUm > 0 then
                  WastePct := (RemainingUm / RepeatUm) * 100.0
                else
                  WastePct := 0.0;

                Rec.AroundGapUm := GapUm;
                Rec.AroundGapMm := GapMm;
                Rec.RemainderUm := RemainderUm;
                Rec.CircumferentialGapPercent := WastePct;

                // Gap evaluation
                if (HardBlockGapUm > 0) and (RemainingUm < Int64(Ups) * HardBlockGapUm) then
                begin
                  Rec.GapStatus := gsMechanicallyRejected;
                  Rec.RequiresOverrideReason := False;
                  Rec.Category := krcMechanicallyRejected;
                  Rec.CategoryText := 'Hard Blocked Gap';
                  Rec.IsEligible := False;
                  Rec.RecommendationReason := Format('Gap (%0.3f mm) below hard mechanical limit (%0.3f mm)', [
                    GapMm, UmToMm(HardBlockGapUm)
                  ]);
                end
                else if RemainingUm >= (Int64(Ups) * MinGapUm) then
                begin
                  // Legal preferred gap
                  Rec.GapStatus := gsOptimal;
                  Rec.RequiresOverrideReason := False;
                  Rec.IsEligible := True;

                  if not SmallestLegalFound then
                  begin
                    Rec.Category := krcPreferred;
                    Rec.CategoryText := 'Preferred (Best Legal Repeat)';
                    Rec.RecommendationReason := Format('Tightest legal around gap (%0.3f mm) for %d ups (%0.1f%% gap pool)', [
                      GapMm, Ups, WastePct
                    ]);
                    SmallestLegalFound := True;
                  end
                  else if not NextLargerFound then
                  begin
                    Rec.Category := krcValidAlternative;
                    Rec.CategoryText := 'Valid Alternative (Next Larger)';
                    Rec.RecommendationReason := Format('Next larger cylinder (%dT, gap %0.3f mm)', [
                      CylTeeth, GapMm
                    ]);
                    NextLargerFound := True;
                  end
                  else
                  begin
                    Rec.Category := krcValidAlternative;
                    Rec.CategoryText := 'Valid Alternative';
                    Rec.RecommendationReason := Format('Larger cylinder with legal gap (%0.3f mm)', [GapMm]);
                  end;
                end
                else
                begin
                  // Sub-standard gap (e.g. 2.4 - 2.999mm)
                  Rec.GapStatus := gsSubStandardWarning;
                  Rec.RequiresOverrideReason := True;
                  Rec.IsEligible := True;
                  Rec.Category := krcSubStandardWarning;
                  Rec.CategoryText := 'Sub-Standard Warning (< 3mm)';
                  Rec.RecommendationReason := Format('Gap (%0.3f mm) below %0.3f mm minimum (requires override reason)', [
                    GapMm, UmToMm(MinGapUm)
                  ]);

                  // Track largest cylinder below minimum gap
                  BelowMinCandidateFound := True;
                  BelowMinRec := Rec;
                end;
              end;

              // Machine compatibility classification
              if AInput.MachineID > 0 then
              begin
                if not IsMachAssigned then
                begin
                  Rec.MachineStatus := mfsUnsupportedCylinder;
                  Rec.MachineStatusText := Format('Cylinder %dT not assigned to %s', [CylTeeth, Mach.Name]);
                  if Rec.Category in [krcPreferred, krcValidAlternative] then
                  begin
                    Rec.Category := krcMachineIncompatible;
                    Rec.CategoryText := 'Machine Incompatible';
                    Rec.RecommendationReason := Rec.MachineStatusText;
                  end;
                end
                else if not WebFits then
                begin
                  Rec.MachineStatus := mfsExceedsWebWidth;
                  Rec.MachineStatusText := Format('Layout (%0.1f mm) exceeds max web (%0.1f mm)', [
                    TotalWebWidthMm, Mach.MaxWebWidthMm
                  ]);
                  if Rec.Category in [krcPreferred, krcValidAlternative] then
                  begin
                    Rec.Category := krcMachineIncompatible;
                    Rec.CategoryText := 'Exceeds Press Web Width';
                    Rec.RecommendationReason := Rec.MachineStatusText;
                  end;
                end
                else
                begin
                  Rec.MachineStatus := mfsCompatible;
                  Rec.MachineStatusText := Format('Compatible with %s (%0.1f mm remaining)', [
                    Mach.Name, Mach.MaxWebWidthMm - TotalWebWidthMm
                  ]);
                end;
              end
              else
              begin
                Rec.MachineStatus := mfsNoMachineSelected;
                Rec.MachineStatusText := 'All Machines';
              end;

              // Note existing tooling
              if MatchingDieCount > 0 then
                Rec.RecommendationReason := Rec.RecommendationReason + Format(' [%d existing die candidate(s)]', [MatchingDieCount]);

              // Calculate ranking score
              Score := 0;
              case Rec.Category of
                krcPreferred:           Score := 1000;
                krcValidAlternative:    Score := 2000;
                krcSubStandardWarning:  Score := 3000;
                krcMachineIncompatible: Score := 4000;
                krcMechanicallyRejected:Score := 5000;
              end;

              // Existing die bonus: prioritizes reuse
              if Rec.ExistingDieCount > 0 then
                Dec(Score, 150);

              // Machine compatibility bonus
              if Rec.MachineStatus = mfsCompatible then
                Dec(Score, 50);

              Rec.RankingScore := Score;
              UpsCandidates.Add(Rec);
            end;

            // Strategy selection for this ups:
            if AInput.UpsMode = usmAutoScan then
            begin
              // In Auto scan mode, add preferred, next larger, and sub-min reference candidate
              for I := 0 to UpsCandidates.Count - 1 do
              begin
                if UpsCandidates[I].Category in [krcPreferred, krcValidAlternative] then
                  RecommendationsList.Add(UpsCandidates[I]);
              end;

              // If below-minimum reference candidate was found, add it for engineering comparison
              if BelowMinCandidateFound and (BelowMinRec.Teeth > 0) then
                RecommendationsList.Add(BelowMinRec);
            end
            else
            begin
              // In Fixed ups mode, include all calculated candidates for operator inspection
              for I := 0 to UpsCandidates.Count - 1 do
                RecommendationsList.Add(UpsCandidates[I]);
            end;
          end;

          // 5. Global sorting of recommendations
          // 1. Ranking score (Preferred -> Alternative -> Warning -> Incompatible -> Rejected)
          // 2. Circumferential gap percentage (waste efficiency)
          // 3. Around Ups
          // 4. Cylinder Teeth
          RecommendationsList.Sort(TComparer<TKeylineRecommendation>.Construct(
            function(const Left, Right: TKeylineRecommendation): Integer
            begin
              if Left.RankingScore <> Right.RankingScore then
                Exit(Left.RankingScore - Right.RankingScore);

              if Left.CircumferentialGapPercent <> Right.CircumferentialGapPercent then
              begin
                if Left.CircumferentialGapPercent < Right.CircumferentialGapPercent then
                  Exit(-1)
                else
                  Exit(1);
              end;

              if Left.AroundUps <> Right.AroundUps then
                Exit(Left.AroundUps - Right.AroundUps);

              Result := Left.Teeth - Right.Teeth;
            end
          ));

          // 6. Aggregate counts and pack result
          SetLength(Result.Recommendations, RecommendationsList.Count);
          for I := 0 to RecommendationsList.Count - 1 do
          begin
            Result.Recommendations[I] := RecommendationsList[I];
            case RecommendationsList[I].Category of
              krcPreferred:           Inc(Result.PreferredCount);
              krcValidAlternative:    Inc(Result.AlternativeCount);
              krcSubStandardWarning:  Inc(Result.WarningCount);
              krcMachineIncompatible: Inc(Result.IncompatibleCount);
            end;
          end;

        finally
          AllExistingDies.Free;
        end;
      finally
        AssignedTeeth.Free;
      end;
    finally
      CylList.Free;
    end;
  finally
    RecommendationsList.Free;
    UpsCandidates.Free;
  end;
end;

end.
