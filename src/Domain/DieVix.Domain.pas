unit DieVix.Domain;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Domain Entities, Value Objects, and Repository Interfaces
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DieVix.CalculationEngine;

type
  { Customer Entity }
  TCustomer = record
    ID: Integer;
    Code: string;
    Name: string;
    ContactPerson: string;
    Phone: string;
    Email: string;
    City: string;
    Notes: string;
    IsActive: Boolean;
    CreatedAt: TDateTime;
    UpdatedAt: TDateTime;
    class function CreateNew(const ACode, AName: string): TCustomer; static;
  end;

  { Media Substrate Entity }
  TMedia = record
    ID: Integer;
    Code: string;
    Name: string;
    FaceMaterial: string;
    LinerMaterial: string;
    AdhesiveType: string;
    TotalCaliperUm: Integer;
    Notes: string;
    IsActive: Boolean;
    class function CreateNew(const ACode, AName: string): TMedia; static;
  end;

  { Die Status Code Entity }
  TDieStatus = record
    Code: string;
    Description: string;
    IsUsable: Boolean;
    BadgeColor: string;
    SortOrder: Integer;
    class function CreateNew(const ACode, ADescription: string; AIsUsable: Boolean = True): TDieStatus; static;
  end;

  { Cylinder Fleet Size Entity }
  TCylinder = record
    Teeth: Integer;
    PitchUm: Integer;
    RepeatMm: Double;
    RepeatInch: Double;
    IsActive: Boolean;
    Notes: string;
    class function CreateNew(ATeeth: Integer; APitchUm: Integer = 3175): TCylinder; static;
  end;

  { Machine Entity }
  TMachine = record
    ID: Integer;
    Code: string;
    Name: string;
    MaxWebWidthMm: Double;
    MinWebWidthMm: Double;
    DefaultMarginMm: Double;
    PrintMethod: string;
    Notes: string;
    IsActive: Boolean;
    class function CreateNew(const ACode, AName: string; AMaxWebMm: Double = 254.0): TMachine; static;
  end;

  { Machine-Cylinder Link Entity }
  TMachineCylinderAssignment = record
    MachineID: Integer;
    Teeth: Integer;
    MachineName: string;
    MaxWebWidthMm: Double;
    IsAssigned: Boolean;
  end;

  { Application Setting Entity }
  TAppSetting = record
    Key: string;
    Value: string;
    Description: string;
  end;

  { Die Tooling Entity }
  TDie = record
    ID: Integer;
    SerialNo: string;
    Description: string;
    InternalRef: string;
    CustomerRef: string;
    CustomerID: Integer;
    CustomerName: string;
    MediaID: Integer;
    MediaName: string;
    Teeth: Integer;
    PitchUm: Integer;
    AroundSizeMm: Double;
    AcrossSizeMm: Double;
    AroundUps: Integer;
    AcrossUps: Integer;
    AroundGapMm: Double;
    AcrossGapMm: Double;
    CornerRadiusMm: Double;
    Shape: string;
    CutType: string;
    StorageLocation: string;
    StorageRack: string;
    StorageShelf: string;
    StorageBin: string;
    StatusCode: string;
    StatusName: string;
    BadgeColor: string;
    OverrideReason: string;
    GapPolicyStatus: string;
    PurchaseDate: TDateTime;
    ReceivedDate: TDateTime;
    DieMaker: string;
    SupplierRef: string;
    TotalRunMetres: Integer;
    Notes: string;
    Version: Integer;
    CreatedBy: string;
    CreatedAt: TDateTime;
    UpdatedBy: string;
    UpdatedAt: TDateTime;
    RepeatMm: Double;
    RepeatInch: Double;
    class function CreateNew(
      const ASerialNo: string;
      ATeeth: Integer;
      AAroundMm, AAcrossMm: Double;
      AAroundUps: Integer = 1;
      AAcrossUps: Integer = 1
    ): TDie; static;
  end;

  { Die Audit Entry }
  TDieAuditEntry = record
    ID: Integer;
    DieID: Integer;
    Action: string;
    FieldName: string;
    OldValue: string;
    NewValue: string;
    OverrideReason: string;
    Details: string;
    ChangedBy: string;
    ChangedAt: TDateTime;
    class function CreateEntry(
      ADieID: Integer;
      const AAction, ADetails: string;
      const AChangedBy: string = 'OPERATOR'
    ): TDieAuditEntry; static;
  end;

  { Die Search / Filter Criteria }
  TDieSearchFilter = record
    SearchText: string;
    CustomerID: Integer;
    Teeth: Integer;
    MediaID: Integer;
    StatusCode: string;
    Shape: string;
    StorageLocation: string;
    OnlySub3mm: Boolean;
    ActiveOnly: Boolean;
    class function Default: TDieSearchFilter; static;
  end;

  { Similar Die Match Classification }
  TSimilarDieMatchType = (smtExact, smtReusableAlternative, smtIncompatible);

  { Similar Die Search Match Result }
  TSimilarDieResult = record
    Die: TDie;
    MatchType: TSimilarDieMatchType;
    AroundDiffMm: Double;
    AcrossDiffMm: Double;
    MatchDescription: string;
  end;

  { Smart Die Size Search Match Classification }
  TSmartDieMatchClass = (
    sdmExactMatch,            // Group 1: Exact dimensions (0 um difference)
    sdmNearMatchTier1,        // Group 2: Around diff <= 1.000 mm AND Across diff <= 1.000 mm
    sdmNearMatchTier2,        // Group 3: Around diff <= Tol mm AND Across diff <= Tol mm
    sdmSlittingCandidate,     // Group 4: Around diff <= Tol mm, Across requires slitting review
    sdmExcluded               // Out of tolerance
  );

  { Smart Die Size Finder Search Criteria }
  TSmartDieSizeFilter = record
    TargetAroundMm: Double;
    TargetAcrossMm: Double;
    ToleranceMm: Double;
    IncludeSlitting: Boolean;
    Teeth: Integer;
    MachineID: Integer;
    StatusCode: string;
    ActiveOnly: Boolean;
    Shape: string;
    CornerRadiusMm: Double;
    CornerRadiusTolMm: Double;
    CutType: string;
    Page: Integer;
    PageSize: Integer;
    class function CreateDefault(
      const AAroundMm, AAcrossMm: Double;
      const AToleranceMm: Double = 2.0
    ): TSmartDieSizeFilter; static;
  end;

  { Smart Die Size Finder Search Result }
  TSmartDieSearchResult = record
    Die: TDie;
    AroundDiffUm: Int64;
    AcrossDiffUm: Int64;
    AbsAroundDiffUm: Int64;
    AbsAcrossDiffUm: Int64;
    AroundDiffMm: Double;
    AcrossDiffMm: Double;
    MatchClass: TSmartDieMatchClass;
    MatchClassName: string;
    ReusabilityNote: string;
  end;

  { Keyline Scanning Mode }
  TUpsScanMode = (usmAutoScan, usmFixedUps);

  { Keyline Recommendation Category }
  TKeylineRecommendationCategory = (
    krcPreferred,           // Optimal / best legal repeat on compatible press (>= MinGap)
    krcValidAlternative,    // Larger or alternate valid repeat on compatible press (>= MinGap)
    krcSubStandardWarning,  // Below-minimum gap (< MinGap), requires production override reason
    krcMachineIncompatible, // Cylinder unsupported on machine or layout exceeds press web width
    krcMechanicallyRejected // Physically impossible (cut > repeat or gap < hard block)
  );

  { Machine Fit Status }
  TMachineFitStatus = (
    mfsCompatible,          // Cylinder assigned to machine AND web width fits
    mfsUnsupportedCylinder, // Cylinder not in machine's assigned fleet
    mfsExceedsWebWidth,     // Tooling + margins exceeds machine's max web width
    mfsNoMachineSelected,   // No machine specified (generic calculation)
    mfsNotVerified          // Missing web width configuration
  );

  { Keyline Calculator Input Parameters }
  TKeylineInput = record
    LabelAroundMm: Double;
    LabelAcrossMm: Double;
    MachineID: Integer;
    UpsMode: TUpsScanMode;
    MaxAroundUps: Integer;
    FixedAroundUps: Integer;
    AcrossUps: Integer;
    MinAroundGapMm: Double;
    HardBlockGapMm: Double;
    AcrossGapMm: Double;
    LeftMarginMm: Double;
    RightMarginMm: Double;
    Shape: string;
    CornerRadiusMm: Double;
    MediaID: Integer;
    ActiveCylindersOnly: Boolean;
    PitchUm: Integer;
    class function CreateDefault(
      const AAroundMm, AAcrossMm: Double;
      const AMachineID: Integer = 0
    ): TKeylineInput; static;
  end;

  { Single Keyline Recommendation Result }
  TKeylineRecommendation = record
    AroundUps: Integer;
    AcrossUps: Integer;
    Teeth: Integer;
    PitchUm: Integer;
    RepeatMm: Double;
    RepeatInch: Double;
    AroundGapMm: Double;
    AroundGapUm: Int64;
    RemainderUm: Integer;
    CircumferentialGapPercent: Double; // (RemainingUm / RepeatUm) * 100
    GapStatus: TGapStatus;
    RequiresOverrideReason: Boolean;
    MachineStatus: TMachineFitStatus;
    MachineStatusText: string;
    Category: TKeylineRecommendationCategory;
    CategoryText: string;
    RecommendationReason: string;
    ToolingWidthMm: Double;
    TotalWebWidthMm: Double;
    MachineMaxWebWidthMm: Double;
    RemainingWebWidthMm: Double;
    ExistingDieCount: Integer;
    IsEligible: Boolean;
    RankingScore: Integer;
  end;

  { Complete Keyline Calculation Result }
  TKeylineCalculationResult = record
    Input: TKeylineInput;
    Machine: TMachine;
    Recommendations: TArray<TKeylineRecommendation>;
    PreferredCount: Integer;
    AlternativeCount: Integer;
    WarningCount: Integer;
    IncompatibleCount: Integer;
  end;

  function KeylineCategoryToString(const ACat: TKeylineRecommendationCategory): string;
  function MachineFitStatusToString(const AStatus: TMachineFitStatus): string;

  { Repository Interfaces }

type
  ICustomerRepository = interface
    ['{B1001001-A101-4A01-8A01-000000000001}']
    function GetAll(const ActiveOnly: Boolean = False): TList<TCustomer>;
    function GetByID(const AID: Integer): TCustomer;
    function GetByCode(const ACode: string): TCustomer;
    function Insert(const ACustomer: TCustomer): Integer;
    function Update(const ACustomer: TCustomer): Boolean;
    function Delete(const AID: Integer): Boolean;
  end;

  IMediaRepository = interface
    ['{B1001002-A101-4A01-8A01-000000000002}']
    function GetAll(const ActiveOnly: Boolean = False): TList<TMedia>;
    function GetByID(const AID: Integer): TMedia;
    function GetByCode(const ACode: string): TMedia;
    function Insert(const AMedia: TMedia): Integer;
    function Update(const AMedia: TMedia): Boolean;
    function Delete(const AID: Integer): Boolean;
  end;

  IDieStatusRepository = interface
    ['{B1001003-A101-4A01-8A01-000000000003}']
    function GetAll: TList<TDieStatus>;
    function GetByCode(const ACode: string): TDieStatus;
    function Save(const AStatus: TDieStatus): Boolean;
    function Delete(const ACode: string): Boolean;
  end;

  ICylinderRepository = interface
    ['{B1001004-A101-4A01-8A01-000000000004}']
    function GetAll(const ActiveOnly: Boolean = False): TList<TCylinder>;
    function GetByTeeth(const ATeeth: Integer): TCylinder;
    function Insert(const ACylinder: TCylinder): Boolean;
    function Update(const ACylinder: TCylinder): Boolean;
    function Delete(const ATeeth: Integer): Boolean;
    function IsReferencedByDies(const ATeeth: Integer): Boolean;
  end;

  IMachineRepository = interface
    ['{B1001005-A101-4A01-8A01-000000000005}']
    function GetAll(const ActiveOnly: Boolean = False): TList<TMachine>;
    function GetByID(const AID: Integer): TMachine;
    function GetByCode(const ACode: string): TMachine;
    function Insert(const AMachine: TMachine): Integer;
    function Update(const AMachine: TMachine): Boolean;
    function Delete(const AID: Integer): Boolean;
  end;

  IMachineCylinderRepository = interface
    ['{B1001006-A101-4A01-8A01-000000000006}']
    function GetCylindersForMachine(const AMachineID: Integer): TList<Integer>;
    function GetMachinesForCylinder(const ATeeth: Integer): TList<Integer>;
    function AssignCylinder(const AMachineID: Integer; const ATeeth: Integer): Boolean;
    function UnassignCylinder(const AMachineID: Integer; const ATeeth: Integer): Boolean;
    function SetAssignments(const AMachineID: Integer; const ATeethList: TArray<Integer>): Boolean;
    function IsAssigned(const AMachineID: Integer; const ATeeth: Integer): Boolean;
  end;

  IAppSettingRepository = interface
    ['{B1001007-A101-4A01-8A01-000000000007}']
    function GetAll: TList<TAppSetting>;
    function GetValue(const AKey: string; const ADefault: string = ''): string;
    function GetInt(const AKey: string; const ADefault: Integer = 0): Integer;
    function GetFloat(const AKey: string; const ADefault: Double = 0.0): Double;
    function SetValue(const AKey, AValue: string; const ADescription: string = ''): Boolean;
  end;

  IDieRepository = interface
    ['{B1001008-A101-4A01-8A01-000000000008}']
    function GetAll: TList<TDie>;
    function GetByID(const AID: Integer): TDie;
    function GetBySerial(const ASerialNo: string): TDie;
    function Search(const AFilter: TDieSearchFilter): TList<TDie>;
    function Insert(var ADie: TDie): Integer;
    function Update(const ADie: TDie): Boolean;
    function Delete(const AID: Integer): Boolean;
    function SerialExists(const ASerialNo: string; const AExcludeID: Integer = 0): Boolean;
    function ChangeStatus(const AID: Integer; const ANewStatusCode, AReason, AUser: string): Boolean;
    function UpdateLocation(const AID: Integer; const ARack, AShelf, ABin, ANotes, AUser: string): Boolean;
    function FindSimilarDies(
      const ATeeth: Integer;
      const AAroundSizeMm, AAcrossSizeMm: Double;
      const AAroundUps, AAcrossUps: Integer;
      const AShape: string;
      const AToleranceMm: Double = 0.5;
      const AExcludeID: Integer = 0
    ): TList<TSimilarDieResult>;
    function SmartSearchDies(
      const AFilter: TSmartDieSizeFilter;
      out ATotalCount: Integer
    ): TList<TSmartDieSearchResult>;
    function GetAuditLog(const ADieID: Integer): TList<TDieAuditEntry>;
    function AddAuditEntry(const AEntry: TDieAuditEntry): Boolean;
  end;

implementation

{ TCustomer }

class function TCustomer.CreateNew(const ACode, AName: string): TCustomer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Code := ACode;
  Result.Name := AName;
  Result.IsActive := True;
  Result.CreatedAt := Now;
  Result.UpdatedAt := Now;
end;

{ TMedia }

class function TMedia.CreateNew(const ACode, AName: string): TMedia;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Code := ACode;
  Result.Name := AName;
  Result.IsActive := True;
end;

{ TDieStatus }

class function TDieStatus.CreateNew(const ACode, ADescription: string; AIsUsable: Boolean): TDieStatus;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Code := ACode;
  Result.Description := ADescription;
  Result.IsUsable := AIsUsable;
  Result.BadgeColor := 'Green';
end;

{ TCylinder }

class function TCylinder.CreateNew(ATeeth, APitchUm: Integer): TCylinder;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Teeth := ATeeth;
  Result.PitchUm := APitchUm;
  Result.RepeatMm := (ATeeth * APitchUm) / 1000.0;
  Result.RepeatInch := ATeeth / 8.0;
  Result.IsActive := True;
end;

{ TMachine }

class function TMachine.CreateNew(const ACode, AName: string; AMaxWebMm: Double): TMachine;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Code := ACode;
  Result.Name := AName;
  Result.MaxWebWidthMm := AMaxWebMm;
  Result.MinWebWidthMm := 50.0;
  Result.DefaultMarginMm := 5.0;
  Result.IsActive := True;
end;

{ TDie }

class function TDie.CreateNew(
  const ASerialNo: string;
  ATeeth: Integer;
  AAroundMm, AAcrossMm: Double;
  AAroundUps, AAcrossUps: Integer
): TDie;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.SerialNo := ASerialNo;
  Result.Teeth := ATeeth;
  Result.PitchUm := 3175;
  Result.AroundSizeMm := AAroundMm;
  Result.AcrossSizeMm := AAcrossMm;
  Result.AroundUps := AAroundUps;
  Result.AcrossUps := AAcrossUps;
  Result.AcrossGapMm := 3.000;
  Result.CornerRadiusMm := 2.000;
  Result.Shape := 'RECTANGLE';
  Result.CutType := 'ROTARY';
  Result.StatusCode := 'ACTIVE';
  Result.StatusName := 'Active';
  Result.BadgeColor := 'Green';
  Result.Version := 1;
  Result.CreatedBy := 'OPERATOR';
  Result.UpdatedBy := 'OPERATOR';
  Result.CreatedAt := Now;
  Result.UpdatedAt := Now;
  Result.RepeatMm := (ATeeth * 3175) / 1000.0;
  Result.RepeatInch := ATeeth / 8.0;
  if AAroundUps > 0 then
    Result.AroundGapMm := (Result.RepeatMm - (AAroundUps * AAroundMm)) / AAroundUps
  else
    Result.AroundGapMm := 0.0;
end;

{ TDieAuditEntry }

class function TDieAuditEntry.CreateEntry(
  ADieID: Integer;
  const AAction, ADetails: string;
  const AChangedBy: string
): TDieAuditEntry;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.DieID := ADieID;
  Result.Action := AAction;
  Result.Details := ADetails;
  Result.ChangedBy := AChangedBy;
  Result.ChangedAt := Now;
end;

{ TDieSearchFilter }

class function TDieSearchFilter.Default: TDieSearchFilter;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.SearchText := '';
  Result.CustomerID := 0;
  Result.Teeth := 0;
  Result.MediaID := 0;
  Result.StatusCode := '';
  Result.Shape := '';
  Result.StorageLocation := '';
  Result.OnlySub3mm := False;
  Result.ActiveOnly := False;
end;

{ TSmartDieSizeFilter }

class function TSmartDieSizeFilter.CreateDefault(
  const AAroundMm, AAcrossMm: Double;
  const AToleranceMm: Double
): TSmartDieSizeFilter;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.TargetAroundMm := AAroundMm;
  Result.TargetAcrossMm := AAcrossMm;
  if AToleranceMm > 0 then
    Result.ToleranceMm := AToleranceMm
  else
    Result.ToleranceMm := 2.000;
  Result.IncludeSlitting := False;
  Result.Teeth := 0;
  Result.MachineID := 0;
  Result.StatusCode := '';
  Result.ActiveOnly := True;
  Result.Shape := '';
  Result.CornerRadiusMm := -1.0;
  Result.CornerRadiusTolMm := 0.5;
  Result.CutType := '';
  Result.Page := 1;
  Result.PageSize := 100;
end;

{ TKeylineInput }

class function TKeylineInput.CreateDefault(
  const AAroundMm, AAcrossMm: Double;
  const AMachineID: Integer
): TKeylineInput;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.LabelAroundMm := AAroundMm;
  Result.LabelAcrossMm := AAcrossMm;
  Result.MachineID := AMachineID;
  Result.UpsMode := usmAutoScan;
  Result.MaxAroundUps := 8;
  Result.FixedAroundUps := 1;
  Result.AcrossUps := 1;
  Result.MinAroundGapMm := 3.000;
  Result.HardBlockGapMm := 0.000;
  Result.AcrossGapMm := 3.000;
  Result.LeftMarginMm := 5.000;
  Result.RightMarginMm := 5.000;
  Result.Shape := 'RECTANGLE';
  Result.CornerRadiusMm := 2.000;
  Result.MediaID := 0;
  Result.ActiveCylindersOnly := True;
  Result.PitchUm := 3175;
end;

function KeylineCategoryToString(const ACat: TKeylineRecommendationCategory): string;
begin
  case ACat of
    krcPreferred:           Result := 'Preferred (Best Legal Repeat)';
    krcValidAlternative:    Result := 'Valid Alternative';
    krcSubStandardWarning:  Result := 'Sub-Standard Warning (< 3mm)';
    krcMachineIncompatible: Result := 'Machine Incompatible';
    krcMechanicallyRejected:Result := 'Mechanically Rejected';
  else
    Result := 'Unknown';
  end;
end;

function MachineFitStatusToString(const AStatus: TMachineFitStatus): string;
begin
  case AStatus of
    mfsCompatible:          Result := 'Compatible';
    mfsUnsupportedCylinder: Result := 'Unsupported Cylinder';
    mfsExceedsWebWidth:     Result := 'Exceeds Usable Web Width';
    mfsNoMachineSelected:   Result := 'No Machine Selected';
    mfsNotVerified:         Result := 'Not Verified';
  else
    Result := 'Unknown';
  end;
end;

end.
