unit DieVix.FlatbedDieService;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Flatbed Die Application Service Layer
  Orchestrates flatbed tooling business rules, category classification (Rollform
  vs Sheetform), bi-directional rotation evaluation, dimensional matching,
  plate/feed boundary validation, duplicate detection, and optimistic concurrency.
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DieVix.Domain,
  DieVix.Repositories,
  DieVix.CalculationEngine;

type
  { Custom Business & Concurrency Exceptions }
  EDieVixValidationException = DieVix.Domain.EDieVixValidationException;
  EDieVixConcurrencyException = DieVix.Domain.EDieVixConcurrencyException;
  EDieVixDuplicateException = DieVix.Domain.EDieVixDuplicateException;

  { Flatbed Die Application Service }
  TFlatbedDieService = class
  private
    FFlatbedRepo: IFlatbedDieRepository;
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FStatusRepo: IDieStatusRepository;
    FLastGeneratedBase: string;
    FLastGeneratedCounter: Integer;
  public
    constructor Create(
      AFlatbedRepo: IFlatbedDieRepository = nil;
      FCustomerRepo: ICustomerRepository = nil;
      FMediaRepo: IMediaRepository = nil;
      FStatusRepo: IDieStatusRepository = nil
    );

    { Calculation & Footprint Helpers }
    procedure CalculateFootprint(var ADie: TFlatbedDie);
    function CanRotate(const ADie: TFlatbedDie): Boolean;

    { Serial Number Generation }
    function GenerateSerialNumber: string;

    { Validation }
    function ValidateFlatbedDie(const ADie: TFlatbedDie; out AErrors: TArray<string>): Boolean;

    { Persistence & Transactional Actions }
    function SaveFlatbedDie(var ADie: TFlatbedDie; const AOperator: string = ''): Integer;
    function DeleteFlatbedDie(const AID: Integer): Boolean;
    function ArchiveFlatbedDie(
      const AID: Integer;
      const AReason: string;
      const AOperator: string = '';
      const AExpectedVersion: Integer = 0
    ): Boolean;
    function RestoreFlatbedDie(
      const AID: Integer;
      const AReason: string = '';
      const AOperator: string = '';
      const AExpectedVersion: Integer = 0
    ): Boolean;
    function CanPermanentlyDeleteFlatbedDie(
      const AID: Integer;
      out ARefusalReason: string
    ): Boolean;
    function PermanentlyDeleteFlatbedDie(
      const AID: Integer;
      const AAuthorized: Boolean = False
    ): Boolean;

    { Lookups & Search }
    function GetFlatbedDieByID(const AID: Integer): TFlatbedDie;
    function GetFlatbedDieBySerial(const ASerialNo: string): TFlatbedDie;
    function SearchFlatbedDies(const AFilter: TFlatbedDieSearchFilter): TList<TFlatbedDie>;
    function GetAllFlatbedDies: TList<TFlatbedDie>;

    { Dimensional Matching with Bi-Directional Rotation Support }
    function FindMatchingFlatbedDies(
      const ATargetAroundMm, ATargetAcrossMm: Double;
      const ACategory: string = '';
      const AToleranceMm: Double = 0.500;
      const AAllowRotation: Boolean = True;
      const AActiveOnly: Boolean = True
    ): TList<TFlatbedDieSearchResult>;

    { Status and Inventory Movement }
    function ChangeFlatbedDieStatus(
      const AID: Integer;
      const ANewStatusCode, AReason: string;
      const AOperator: string = ''
    ): Boolean;

    function UpdateFlatbedDieLocation(
      const AID: Integer;
      const ARack, AShelf, ABin, ANotes: string;
      const AOperator: string = ''
    ): Boolean;

    { Duplicate Detection }
    function CheckDuplicateSerial(const ASerialNo: string; const AExcludeID: Integer = 0): Boolean;

    { Audit History }
    function GetFlatbedDieAuditHistory(const AID: Integer): TList<TFlatbedDieAuditEntry>;

    { Master Data Access for Combos }
    function GetActiveCustomers: TList<TCustomer>;
    function GetActiveMedia: TList<TMedia>;
    function GetAllStatuses: TList<TDieStatus>;

    property FlatbedRepo: IFlatbedDieRepository read FFlatbedRepo;
  end;

implementation

{ TFlatbedDieService }

constructor TFlatbedDieService.Create(
  AFlatbedRepo: IFlatbedDieRepository;
  FCustomerRepo: ICustomerRepository;
  FMediaRepo: IMediaRepository;
  FStatusRepo: IDieStatusRepository
);
begin
  inherited Create;
  if Assigned(AFlatbedRepo) then FFlatbedRepo := AFlatbedRepo else FFlatbedRepo := TFlatbedDieRepository.Create;
  if Assigned(FCustomerRepo) then Self.FCustomerRepo := FCustomerRepo else Self.FCustomerRepo := TCustomerRepository.Create;
  if Assigned(FMediaRepo) then Self.FMediaRepo := FMediaRepo else Self.FMediaRepo := TMediaRepository.Create;
  if Assigned(FStatusRepo) then Self.FStatusRepo := FStatusRepo else Self.FStatusRepo := TDieStatusRepository.Create;
end;

procedure TFlatbedDieService.CalculateFootprint(var ADie: TFlatbedDie);
begin
  if ADie.AroundUps < 1 then ADie.AroundUps := 1;
  if ADie.AcrossUps < 1 then ADie.AcrossUps := 1;

  ADie.TotalUps := ADie.AroundUps * ADie.AcrossUps;
  ADie.TotalCutAroundMm := (ADie.AroundUps * ADie.AroundSizeMm) + ((ADie.AroundUps - 1) * ADie.AroundGapMm);
  ADie.TotalCutAcrossMm := (ADie.AcrossUps * ADie.AcrossSizeMm) + ((ADie.AcrossUps - 1) * ADie.AcrossGapMm);

  ADie.CanRotate := CanRotate(ADie);
  if ADie.CanRotate then
    ADie.RotationSupport := 'BI_DIRECTIONAL'
  else
    ADie.RotationSupport := 'FIXED_DIRECTION';
end;

function TFlatbedDieService.CanRotate(const ADie: TFlatbedDie): Boolean;
begin
  Result := CanFlatbedDieRotate(ADie.Category, ADie.AroundUps, ADie.AcrossUps, ADie.AroundSizeMm, ADie.AcrossSizeMm);
end;

function TFlatbedDieService.ValidateFlatbedDie(const ADie: TFlatbedDie; out AErrors: TArray<string>): Boolean;
var
  ErrList: TList<string>;
  NormSerial, NormCat: string;
begin
  ErrList := TList<string>.Create;
  try
    NormSerial := Trim(ADie.SerialNo);
    if NormSerial = '' then
      ErrList.Add('Flatbed Die Serial Number cannot be empty.');

    NormCat := UpperCase(Trim(ADie.Category));
    if (NormCat <> 'ROLL_FORM') and (NormCat <> 'SHEET_FORM') and
       (NormCat <> 'ROLLFORM') and (NormCat <> 'SHEETFORM') then
      ErrList.Add('Category must be either ROLL_FORM (rollform cutting) or SHEET_FORM (sheetform/booklets).');

    if ADie.AroundSizeMm <= 0.0 then
      ErrList.Add('Around cavity dimension must be greater than 0 mm.');

    if ADie.AcrossSizeMm <= 0.0 then
      ErrList.Add('Across cavity dimension must be greater than 0 mm.');

    if ADie.AroundUps < 1 then
      ErrList.Add('Around ups must be at least 1.');

    if ADie.AcrossUps < 1 then
      ErrList.Add('Across ups must be at least 1.');

    if ADie.AroundGapMm < 0.0 then
      ErrList.Add('Around gap cannot be negative.');

    if ADie.AcrossGapMm < 0.0 then
      ErrList.Add('Across gap cannot be negative.');

    if (ADie.PlateWidthMm > 0.0) and (ADie.TotalCutAcrossMm > ADie.PlateWidthMm) then
      ErrList.Add(Format(
        'Total cutting width (%.3f mm) exceeds maximum plate width (%.3f mm).',
        [ADie.TotalCutAcrossMm, ADie.PlateWidthMm]
      ));

    if (ADie.PlateLengthMm > 0.0) and (ADie.TotalCutAroundMm > ADie.PlateLengthMm) then
      ErrList.Add(Format(
        'Total cutting length (%.3f mm) exceeds maximum plate length (%.3f mm).',
        [ADie.TotalCutAroundMm, ADie.PlateLengthMm]
      ));

    if (ADie.MaxFeedStrokeMm > 0.0) and (ADie.TotalCutAroundMm > ADie.MaxFeedStrokeMm) then
      ErrList.Add(Format(
        'Total cutting length (%.3f mm) exceeds machine maximum feed stroke (%.3f mm).',
        [ADie.TotalCutAroundMm, ADie.MaxFeedStrokeMm]
      ));

    AErrors := ErrList.ToArray;
    Result := (Length(AErrors) = 0);
  finally
    ErrList.Free;
  end;
end;

function TFlatbedDieService.GenerateSerialNumber: string;
var
  BaseSerial: string;
  Candidate: string;
begin
  BaseSerial := 'FBD-' + FormatDateTime('YYMMDD-HHNNSS', Now);
  if BaseSerial = FLastGeneratedBase then
  begin
    Inc(FLastGeneratedCounter);
    Candidate := Format('%s-%d', [BaseSerial, FLastGeneratedCounter]);
  end
  else
  begin
    FLastGeneratedBase := BaseSerial;
    FLastGeneratedCounter := 1;
    Candidate := BaseSerial;
  end;

  while CheckDuplicateSerial(Candidate, 0) do
  begin
    Inc(FLastGeneratedCounter);
    Candidate := Format('%s-%d', [BaseSerial, FLastGeneratedCounter]);
  end;
  Result := Candidate;
end;

function TFlatbedDieService.CheckDuplicateSerial(const ASerialNo: string; const AExcludeID: Integer): Boolean;
begin
  if Assigned(FFlatbedRepo) then
    Result := FFlatbedRepo.SerialExists(ASerialNo, AExcludeID)
  else
    Result := False;
end;

function TFlatbedDieService.SaveFlatbedDie(var ADie: TFlatbedDie; const AOperator: string): Integer;
var
  Errors: TArray<string>;
  NormSerial, NormCat: string;
  UpdatedOK: Boolean;
begin
  NormSerial := Trim(ADie.SerialNo);
  if (ADie.ID = 0) and (NormSerial = '') then
    NormSerial := GenerateSerialNumber;
  ADie.SerialNo := NormSerial;

  NormCat := UpperCase(Trim(ADie.Category));
  if (NormCat = 'ROLL_FORM') or (NormCat = 'ROLLFORM') then
    ADie.Category := 'ROLL_FORM'
  else
    ADie.Category := 'SHEET_FORM';

  // Compute total cut footprints and bi-directional capability
  CalculateFootprint(ADie);

  if not ValidateFlatbedDie(ADie, Errors) then
    raise EDieVixValidationException.Create(string.Join(sLineBreak, Errors));

  if CheckDuplicateSerial(ADie.SerialNo, ADie.ID) then
    raise EDieVixDuplicateException.Create(Format('A flatbed die with Serial Number "%s" already exists.', [ADie.SerialNo]));

  if Trim(AOperator) <> '' then
  begin
    ADie.UpdatedBy := Trim(AOperator);
    if ADie.ID = 0 then
      ADie.CreatedBy := Trim(AOperator);
  end;

  if ADie.ID = 0 then
  begin
    Result := FFlatbedRepo.Insert(ADie);
  end
  else
  begin
    UpdatedOK := FFlatbedRepo.Update(ADie);
    if not UpdatedOK then
      raise EDieVixConcurrencyException.Create(
        'Concurrency conflict: The flatbed die record was modified or deleted by another user. Please reload and try again.'
      );
    Result := ADie.ID;
  end;
end;

function TFlatbedDieService.DeleteFlatbedDie(const AID: Integer): Boolean;
begin
  Result := FFlatbedRepo.Delete(AID);
end;

function TFlatbedDieService.CanPermanentlyDeleteFlatbedDie(
  const AID: Integer;
  out ARefusalReason: string
): Boolean;
begin
  Result := FFlatbedRepo.CanPermanentlyDelete(AID, ARefusalReason);
end;

function TFlatbedDieService.PermanentlyDeleteFlatbedDie(
  const AID: Integer;
  const AAuthorized: Boolean
): Boolean;
var
  RefusalReason: string;
begin
  if not AAuthorized then
    raise EDieVixValidationException.Create('Authorization required to permanently delete flatbed tooling.');

  if not CanPermanentlyDeleteFlatbedDie(AID, RefusalReason) then
    raise EDieVixValidationException.Create('Permanent delete blocked: ' + RefusalReason + ' Use Archive instead.');

  Result := FFlatbedRepo.PermanentlyDelete(AID);
end;

function TFlatbedDieService.ArchiveFlatbedDie(
  const AID: Integer;
  const AReason: string;
  const AOperator: string;
  const AExpectedVersion: Integer
): Boolean;
var
  CleanReason: string;
begin
  CleanReason := Trim(AReason);
  if CleanReason = '' then
    raise EDieVixValidationException.Create('A reason is mandatory to archive a flatbed die.');

  Result := FFlatbedRepo.Archive(AID, CleanReason, AOperator, AExpectedVersion);
end;

function TFlatbedDieService.RestoreFlatbedDie(
  const AID: Integer;
  const AReason: string;
  const AOperator: string;
  const AExpectedVersion: Integer
): Boolean;
var
  CleanReason: string;
begin
  CleanReason := Trim(AReason);
  if CleanReason = '' then
    CleanReason := 'Restored to Active Inventory';

  Result := FFlatbedRepo.Restore(AID, CleanReason, AOperator, AExpectedVersion);
end;

function TFlatbedDieService.GetFlatbedDieByID(const AID: Integer): TFlatbedDie;
begin
  Result := FFlatbedRepo.GetByID(AID);
end;

function TFlatbedDieService.GetFlatbedDieBySerial(const ASerialNo: string): TFlatbedDie;
begin
  Result := FFlatbedRepo.GetBySerial(ASerialNo);
end;

function TFlatbedDieService.SearchFlatbedDies(const AFilter: TFlatbedDieSearchFilter): TList<TFlatbedDie>;
begin
  Result := FFlatbedRepo.Search(AFilter);
end;

function TFlatbedDieService.GetAllFlatbedDies: TList<TFlatbedDie>;
begin
  Result := FFlatbedRepo.GetAll;
end;

function TFlatbedDieService.FindMatchingFlatbedDies(
  const ATargetAroundMm, ATargetAcrossMm: Double;
  const ACategory: string;
  const AToleranceMm: Double;
  const AAllowRotation: Boolean;
  const AActiveOnly: Boolean
): TList<TFlatbedDieSearchResult>;
begin
  Result := FFlatbedRepo.SearchMatchingDimensions(
    ATargetAroundMm, ATargetAcrossMm, ACategory, AToleranceMm, AAllowRotation, AActiveOnly
  );
end;

function TFlatbedDieService.ChangeFlatbedDieStatus(
  const AID: Integer;
  const ANewStatusCode, AReason: string;
  const AOperator: string
): Boolean;
begin
  Result := FFlatbedRepo.ChangeStatus(AID, ANewStatusCode, AReason, AOperator);
end;

function TFlatbedDieService.UpdateFlatbedDieLocation(
  const AID: Integer;
  const ARack, AShelf, ABin, ANotes: string;
  const AOperator: string
): Boolean;
begin
  Result := FFlatbedRepo.UpdateLocation(AID, ARack, AShelf, ABin, ANotes, AOperator);
end;

function TFlatbedDieService.GetFlatbedDieAuditHistory(const AID: Integer): TList<TFlatbedDieAuditEntry>;
begin
  Result := FFlatbedRepo.GetAuditLog(AID);
end;

function TFlatbedDieService.GetActiveCustomers: TList<TCustomer>;
begin
  Result := FCustomerRepo.GetAll(True);
end;

function TFlatbedDieService.GetActiveMedia: TList<TMedia>;
begin
  Result := FMediaRepo.GetAll(True);
end;

function TFlatbedDieService.GetAllStatuses: TList<TDieStatus>;
begin
  Result := FStatusRepo.GetAll;
end;

end.
