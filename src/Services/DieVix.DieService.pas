unit DieVix.DieService;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Die Application Service Layer
  Orchestrates tooling business rules, integer micrometre gap validation,
  duplicate detection, similar die reuse search, and optimistic concurrency.
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  DieVix.Domain,
  DieVix.Repositories,
  DieVix.CalculationEngine;

type
  { Custom Business & Concurrency Exceptions }
  EDieVixValidationException = DieVix.Domain.EDieVixValidationException;
  EDieVixConcurrencyException = DieVix.Domain.EDieVixConcurrencyException;
  EDieVixDuplicateException = DieVix.Domain.EDieVixDuplicateException;

  { Die Application Service }
  TDieService = class
  private
    FDieRepo: IDieRepository;
    FSettingRepo: IAppSettingRepository;
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FCylinderRepo: ICylinderRepository;
    FMachineRepo: IMachineRepository;
    FStatusRepo: IDieStatusRepository;
  public
    constructor Create(
      ADieRepo: IDieRepository = nil;
      ASettingRepo: IAppSettingRepository = nil;
      ACustomerRepo: ICustomerRepository = nil;
      AMediaRepo: IMediaRepository = nil;
      ACylinderRepo: ICylinderRepository = nil;
      AStatusRepo: IDieStatusRepository = nil;
      AMachineRepo: IMachineRepository = nil
    );

    { Settings helpers }
    function GetMinAroundGapUm: Int64;
    function GetHardBlockGapUm: Int64;

    { Live geometry calculations }
    function CalculateDieGeometry(
      const ATeeth: Integer;
      const AAroundSizeMm: Double;
      const AAroundUps: Integer;
      const APitchUm: Integer = STANDARD_PITCH_UM
    ): TGapResult;

    { Validation }
    function ValidateDie(const ADie: TDie; out AErrors: TArray<string>): Boolean;

    { Persistence & Transactional Actions }
    function SaveDie(var ADie: TDie; const AOperator: string = ''): Integer;
    function DeleteDie(const AID: Integer): Boolean;
    function ArchiveDie(
      const AID: Integer;
      const AReason: string;
      const AOperator: string = '';
      const AExpectedVersion: Integer = 0
    ): Boolean;
    function RestoreDie(
      const AID: Integer;
      const AReason: string = '';
      const AOperator: string = '';
      const AExpectedVersion: Integer = 0
    ): Boolean;
    function CanPermanentlyDeleteDie(
      const AID: Integer;
      out ARefusalReason: string
    ): Boolean;
    function PermanentlyDeleteDie(
      const AID: Integer;
      const AAuthorized: Boolean = False
    ): Boolean;

    { Lookups & Search }
    function GetDieByID(const AID: Integer): TDie;
    function GetDieBySerial(const ASerialNo: string): TDie;
    function SearchDies(const AFilter: TDieSearchFilter): TList<TDie>;
    function GetAllDies: TList<TDie>;

    { Status and Inventory Movement }
    function ChangeDieStatus(
      const AID: Integer;
      const ANewStatusCode, AReason: string;
      const AOperator: string = ''
    ): Boolean;

    function UpdateDieLocation(
      const AID: Integer;
      const ARack, AShelf, ABin, ANotes: string;
      const AOperator: string = ''
    ): Boolean;

    { Duplicate and Similar Die Detection }
    function CheckDuplicateSerial(const ASerialNo: string; const AExcludeID: Integer = 0): Boolean;

    function FindSimilarDies(
      const ATeeth: Integer;
      const AAroundSizeMm, AAcrossSizeMm: Double;
      const AAroundUps, AAcrossUps: Integer;
      const AShape: string;
      const AToleranceMm: Double = 0.5;
      const AExcludeID: Integer = 0
    ): TList<TSimilarDieResult>;

    { Smart Die Size Finder }
    function SmartSearchDies(
      const AFilter: TSmartDieSizeFilter;
      out ATotalCount: Integer
    ): TList<TSmartDieSearchResult>;

    { Audit History }
    function GetDieAuditHistory(const AID: Integer): TList<TDieAuditEntry>;

    { Master Data Access for Combos }
    function GetActiveCustomers: TList<TCustomer>;
    function GetActiveMedia: TList<TMedia>;
    function GetActiveCylinders: TList<TCylinder>;
    function GetActiveMachines: TList<TMachine>;
    function GetAllStatuses: TList<TDieStatus>;

    property DieRepo: IDieRepository read FDieRepo;
    property SettingRepo: IAppSettingRepository read FSettingRepo;
  end;

implementation

{ TDieService }

constructor TDieService.Create(
  ADieRepo: IDieRepository;
  ASettingRepo: IAppSettingRepository;
  ACustomerRepo: ICustomerRepository;
  AMediaRepo: IMediaRepository;
  ACylinderRepo: ICylinderRepository;
  AStatusRepo: IDieStatusRepository;
  AMachineRepo: IMachineRepository
);
begin
  inherited Create;
  if Assigned(ADieRepo) then FDieRepo := ADieRepo else FDieRepo := TDieRepository.Create;
  if Assigned(ASettingRepo) then FSettingRepo := ASettingRepo else FSettingRepo := TAppSettingRepository.Create;
  if Assigned(ACustomerRepo) then FCustomerRepo := ACustomerRepo else FCustomerRepo := TCustomerRepository.Create;
  if Assigned(AMediaRepo) then FMediaRepo := AMediaRepo else FMediaRepo := TMediaRepository.Create;
  if Assigned(ACylinderRepo) then FCylinderRepo := ACylinderRepo else FCylinderRepo := TCylinderRepository.Create;
  if Assigned(AStatusRepo) then FStatusRepo := AStatusRepo else FStatusRepo := TDieStatusRepository.Create;
  if Assigned(AMachineRepo) then FMachineRepo := AMachineRepo else FMachineRepo := TMachineRepository.Create;
end;

function TDieService.GetMinAroundGapUm: Int64;
begin
  Result := FSettingRepo.GetInt('MIN_AROUND_GAP_UM', DEFAULT_MIN_GAP_UM);
  if Result <= 0 then
    Result := DEFAULT_MIN_GAP_UM;
end;

function TDieService.GetHardBlockGapUm: Int64;
begin
  Result := FSettingRepo.GetInt('HARD_BLOCK_GAP_UM', DEFAULT_HARD_BLOCK_GAP_UM);
  if Result < 0 then
    Result := DEFAULT_HARD_BLOCK_GAP_UM;
end;

function TDieService.CalculateDieGeometry(
  const ATeeth: Integer;
  const AAroundSizeMm: Double;
  const AAroundUps: Integer;
  const APitchUm: Integer
): TGapResult;
var
  MinGapUm, HardBlockUm: Int64;
  ActualPitch: Integer;
begin
  MinGapUm := GetMinAroundGapUm;
  HardBlockUm := GetHardBlockGapUm;
  if APitchUm <= 0 then
    ActualPitch := STANDARD_PITCH_UM
  else
    ActualPitch := APitchUm;

  Result := CalculateAroundGap(
    ATeeth,
    MmToUm(AAroundSizeMm),
    AAroundUps,
    MinGapUm,
    HardBlockUm,
    ActualPitch
  );
end;

function TDieService.ValidateDie(const ADie: TDie; out AErrors: TArray<string>): Boolean;
var
  ErrList: TList<string>;
  NormSerial: string;
  GapRes: TGapResult;
begin
  ErrList := TList<string>.Create;
  try
    NormSerial := Trim(ADie.SerialNo);
    if NormSerial = '' then
      ErrList.Add('Die Serial Number cannot be empty.');

    if ADie.Teeth <= 0 then
      ErrList.Add('Cylinder Teeth count must be greater than zero.');

    if ADie.AroundSizeMm <= 0.0 then
      ErrList.Add('Around label dimension must be greater than 0 mm.');

    if ADie.AcrossSizeMm <= 0.0 then
      ErrList.Add('Across label dimension must be greater than 0 mm.');

    if ADie.AroundUps < 1 then
      ErrList.Add('Around ups must be at least 1.');

    if ADie.AcrossUps < 1 then
      ErrList.Add('Across ups must be at least 1.');

    // Geometry Calculation Check
    if (ADie.Teeth > 0) and (ADie.AroundSizeMm > 0) and (ADie.AroundUps > 0) then
    begin
      GapRes := CalculateDieGeometry(ADie.Teeth, ADie.AroundSizeMm, ADie.AroundUps, ADie.PitchUm);
      if GapRes.Status = gsMechanicallyRejected then
        ErrList.Add(Format('Mechanical error: %s', [GapRes.StatusMessage]))
      else if GapRes.RequiresOverrideReason and (Trim(ADie.OverrideReason) = '') then
        ErrList.Add(Format('Around gap (%0.3f mm) is below recommended %0.3f mm minimum. An Override Reason is required to save.', [GapRes.AroundGapMm, UmToMm(GetMinAroundGapUm)]));
    end;

    AErrors := ErrList.ToArray;
    Result := (Length(AErrors) = 0);
  finally
    ErrList.Free;
  end;
end;

function TDieService.CheckDuplicateSerial(const ASerialNo: string; const AExcludeID: Integer): Boolean;
begin
  Result := FDieRepo.SerialExists(ASerialNo, AExcludeID);
end;

function TDieService.SaveDie(var ADie: TDie; const AOperator: string): Integer;
var
  Errors: TArray<string>;
  NormSerial: string;
  GapRes: TGapResult;
  UpdatedOK: Boolean;
begin
  NormSerial := Trim(ADie.SerialNo);
  ADie.SerialNo := NormSerial;

  // 1. Check duplicate serial
  if CheckDuplicateSerial(NormSerial, ADie.ID) then
    raise EDieVixDuplicateException.CreateFmt('Die Serial "%s" already exists in the system.', [NormSerial]);

  // 2. Perform live calculation
  GapRes := CalculateDieGeometry(ADie.Teeth, ADie.AroundSizeMm, ADie.AroundUps, ADie.PitchUm);
  if GapRes.Status = gsMechanicallyRejected then
    raise EDieVixValidationException.CreateFmt('Mechanically rejected: %s', [GapRes.StatusMessage]);

  if GapRes.RequiresOverrideReason and (Trim(ADie.OverrideReason) = '') then
    raise EDieVixValidationException.CreateFmt(
      'Tooling around gap (%0.3f mm) is below the configured minimum (%0.3f mm). An override reason is required.',
      [GapRes.AroundGapMm, UmToMm(GetMinAroundGapUm)]
    );

  // 3. Field validation
  if not ValidateDie(ADie, Errors) then
    raise EDieVixValidationException.Create('Validation failed: ' + string.Join('; ', Errors));

  // 4. Update audit actor
  var Actor := Trim(AOperator);
  if (Actor = '') or SameText(Actor, 'OPERATOR') then
    Actor := GetCurrentAppUser;

  if ADie.ID = 0 then
  begin
    if (Trim(ADie.CreatedBy) = '') or SameText(Trim(ADie.CreatedBy), 'OPERATOR') then
      ADie.CreatedBy := Actor;
    ADie.UpdatedBy := Actor;
    Result := FDieRepo.Insert(ADie);
  end
  else
  begin
    ADie.UpdatedBy := Actor;
    UpdatedOK := FDieRepo.Update(ADie);
    if not UpdatedOK then
      raise EDieVixConcurrencyException.Create(
        'Concurrency conflict: The die record has been modified by another user or session. Please reload and review before saving.'
      );
    Result := ADie.ID;
  end;
end;

function TDieService.DeleteDie(const AID: Integer): Boolean;
begin
  Result := PermanentlyDeleteDie(AID, True);
end;

function TDieService.ArchiveDie(
  const AID: Integer;
  const AReason: string;
  const AOperator: string;
  const AExpectedVersion: Integer
): Boolean;
var
  Die: TDie;
  Op: string;
begin
  if Trim(AReason) = '' then
    raise EDieVixValidationException.Create('An archive reason is required to archive a tooling record.');

  Die := GetDieByID(AID);
  if Die.ID = 0 then
    raise EDieVixValidationException.Create('Die record not found.');

  if (AExpectedVersion > 0) and (Die.Version <> AExpectedVersion) then
    raise EDieVixConcurrencyException.Create(
      'Concurrency conflict: The die record has been modified by another user or session. Please reload and review before archiving.'
    );

  if SameText(Die.StatusCode, 'ARCHIVED') then
    raise EDieVixValidationException.Create(Format('Die "%s" is already archived.', [Die.SerialNo]));

  Op := Trim(AOperator);
  if (Op = '') or SameText(Op, 'OPERATOR') then
    Op := GetCurrentAppUser;

  Result := FDieRepo.Archive(AID, Trim(AReason), Op, AExpectedVersion);
end;

function TDieService.RestoreDie(
  const AID: Integer;
  const AReason: string;
  const AOperator: string;
  const AExpectedVersion: Integer
): Boolean;
var
  Die: TDie;
  Op: string;
begin
  Die := GetDieByID(AID);
  if Die.ID = 0 then
    raise EDieVixValidationException.Create('Die record not found.');

  if (AExpectedVersion > 0) and (Die.Version <> AExpectedVersion) then
    raise EDieVixConcurrencyException.Create(
      'Concurrency conflict: The die record has been modified by another user or session. Please reload and review before restoring.'
    );

  if not SameText(Die.StatusCode, 'ARCHIVED') then
    raise EDieVixValidationException.Create(
      Format('Only archived dies can be restored. Current status is "%s".', [Die.StatusCode])
    );

  Op := Trim(AOperator);
  if (Op = '') or SameText(Op, 'OPERATOR') then
    Op := GetCurrentAppUser;

  Result := FDieRepo.Restore(AID, Trim(AReason), Op, AExpectedVersion);
end;

function TDieService.CanPermanentlyDeleteDie(
  const AID: Integer;
  out ARefusalReason: string
): Boolean;
begin
  Result := FDieRepo.CanPermanentlyDelete(AID, ARefusalReason);
end;

function TDieService.PermanentlyDeleteDie(
  const AID: Integer;
  const AAuthorized: Boolean
): Boolean;
var
  RefusalReason: string;
begin
  if not AAuthorized then
    raise EDieVixValidationException.Create('Permanent deletion requires explicit operator authorization.');

  if not CanPermanentlyDeleteDie(AID, RefusalReason) then
    raise EDieVixValidationException.Create('Cannot permanently delete die: ' + RefusalReason);

  Result := FDieRepo.PermanentlyDelete(AID);
end;

function TDieService.GetDieByID(const AID: Integer): TDie;
begin
  Result := FDieRepo.GetByID(AID);
end;

function TDieService.GetDieBySerial(const ASerialNo: string): TDie;
begin
  Result := FDieRepo.GetBySerial(ASerialNo);
end;

function TDieService.SearchDies(const AFilter: TDieSearchFilter): TList<TDie>;
begin
  Result := FDieRepo.Search(AFilter);
end;

function TDieService.GetAllDies: TList<TDie>;
begin
  Result := FDieRepo.GetAll;
end;

function TDieService.ChangeDieStatus(
  const AID: Integer;
  const ANewStatusCode, AReason, AOperator: string
): Boolean;
var
  Op: string;
begin
  Op := Trim(AOperator);
  if (Op = '') or SameText(Op, 'OPERATOR') then
    Op := GetCurrentAppUser;
  Result := FDieRepo.ChangeStatus(AID, ANewStatusCode, AReason, Op);
end;

function TDieService.UpdateDieLocation(
  const AID: Integer;
  const ARack, AShelf, ABin, ANotes, AOperator: string
): Boolean;
var
  Op: string;
begin
  Op := Trim(AOperator);
  if (Op = '') or SameText(Op, 'OPERATOR') then
    Op := GetCurrentAppUser;
  Result := FDieRepo.UpdateLocation(AID, ARack, AShelf, ABin, ANotes, Op);
end;

function TDieService.FindSimilarDies(
  const ATeeth: Integer;
  const AAroundSizeMm, AAcrossSizeMm: Double;
  const AAroundUps, AAcrossUps: Integer;
  const AShape: string;
  const AToleranceMm: Double;
  const AExcludeID: Integer
): TList<TSimilarDieResult>;
begin
  Result := FDieRepo.FindSimilarDies(
    ATeeth, AAroundSizeMm, AAcrossSizeMm, AAroundUps, AAcrossUps, AShape, AToleranceMm, AExcludeID
  );
end;

function TDieService.GetDieAuditHistory(const AID: Integer): TList<TDieAuditEntry>;
begin
  Result := FDieRepo.GetAuditLog(AID);
end;

function TDieService.GetActiveCustomers: TList<TCustomer>;
begin
  Result := FCustomerRepo.GetAll(True);
end;

function TDieService.GetActiveMedia: TList<TMedia>;
begin
  Result := FMediaRepo.GetAll(True);
end;

function TDieService.GetActiveCylinders: TList<TCylinder>;
begin
  Result := FCylinderRepo.GetAll(True);
end;

function TDieService.SmartSearchDies(
  const AFilter: TSmartDieSizeFilter;
  out ATotalCount: Integer
): TList<TSmartDieSearchResult>;
begin
  Result := FDieRepo.SmartSearchDies(AFilter, ATotalCount);
end;

function TDieService.GetActiveMachines: TList<TMachine>;
begin
  Result := FMachineRepo.GetAll(True);
end;

function TDieService.GetAllStatuses: TList<TDieStatus>;
begin
  Result := FStatusRepo.GetAll;
end;

end.
