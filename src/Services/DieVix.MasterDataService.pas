unit DieVix.MasterDataService;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Master Data Application Service
  Orchestrates business validation, referential integrity guards, and transactions.
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
  { Custom Business Exceptions }
  EDieVixValidationException = class(Exception);
  EDieVixIntegrityException = class(Exception);

  { Master Data Service }
  TMasterDataService = class
  private
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FStatusRepo: IDieStatusRepository;
    FCylinderRepo: ICylinderRepository;
    FMachineRepo: IMachineRepository;
    FMachineCylinderRepo: IMachineCylinderRepository;
    FSettingRepo: IAppSettingRepository;
  public
    constructor Create(
      ACustomerRepo: ICustomerRepository = nil;
      AMediaRepo: IMediaRepository = nil;
      AStatusRepo: IDieStatusRepository = nil;
      ACylinderRepo: ICylinderRepository = nil;
      AMachineRepo: IMachineRepository = nil;
      AMachineCylinderRepo: IMachineCylinderRepository = nil;
      ASettingRepo: IAppSettingRepository = nil
    );

    { Customer operations }
    function GetAllCustomers(const ActiveOnly: Boolean = False): TList<TCustomer>;
    function SaveCustomer(const ACustomer: TCustomer): Integer;
    function DeleteCustomer(const AID: Integer): Boolean;

    { Media operations }
    function GetAllMedia(const ActiveOnly: Boolean = False): TList<TMedia>;
    function SaveMedia(const AMedia: TMedia): Integer;
    function DeleteMedia(const AID: Integer): Boolean;

    { Status operations }
    function GetAllStatuses: TList<TDieStatus>;
    function SaveStatus(const AStatus: TDieStatus): Boolean;

    { Cylinder operations }
    function GetAllCylinders(const ActiveOnly: Boolean = False): TList<TCylinder>;
    function SaveCylinder(const ACylinder: TCylinder; const IsNew: Boolean): Boolean;
    function DeleteCylinder(const ATeeth: Integer): Boolean;
    function CanSafelyModifyCylinder(const ATeeth: Integer; out AReason: string): Boolean;

    { Machine operations }
    function GetAllMachines(const ActiveOnly: Boolean = False): TList<TMachine>;
    function SaveMachine(const AMachine: TMachine): Integer;
    function DeleteMachine(const AID: Integer): Boolean;

    { Machine-Cylinder Matrix operations }
    function GetAssignedCylindersForMachine(const AMachineID: Integer): TList<Integer>;
    function SaveMachineCylinderAssignments(const AMachineID: Integer; const ATeethList: TArray<Integer>): Boolean;
    function ToggleAssignment(const AMachineID, ATeeth: Integer; const AAssign: Boolean): Boolean;

    { Settings operations }
    function GetMinAroundGapUm: Int64;
    function GetHardBlockGapUm: Int64;
    function GetDefaultAcrossGapMm: Double;
    function GetDefaultCornerRadiusMm: Double;
    function SaveSettings(
      const AMinAroundGapUm, AHardBlockGapUm: Int64;
      const ADefaultAcrossGapMm, ADefaultCornerRadiusMm: Double
    ): Boolean;

    property CustomerRepo: ICustomerRepository read FCustomerRepo;
    property MediaRepo: IMediaRepository read FMediaRepo;
    property StatusRepo: IDieStatusRepository read FStatusRepo;
    property CylinderRepo: ICylinderRepository read FCylinderRepo;
    property MachineRepo: IMachineRepository read FMachineRepo;
    property MachineCylinderRepo: IMachineCylinderRepository read FMachineCylinderRepo;
    property SettingRepo: IAppSettingRepository read FSettingRepo;
  end;

implementation

{ TMasterDataService }

constructor TMasterDataService.Create(
  ACustomerRepo: ICustomerRepository;
  AMediaRepo: IMediaRepository;
  AStatusRepo: IDieStatusRepository;
  ACylinderRepo: ICylinderRepository;
  AMachineRepo: IMachineRepository;
  AMachineCylinderRepo: IMachineCylinderRepository;
  ASettingRepo: IAppSettingRepository
);
begin
  inherited Create;
  if Assigned(ACustomerRepo) then FCustomerRepo := ACustomerRepo else FCustomerRepo := TCustomerRepository.Create;
  if Assigned(AMediaRepo) then FMediaRepo := AMediaRepo else FMediaRepo := TMediaRepository.Create;
  if Assigned(AStatusRepo) then FStatusRepo := AStatusRepo else FStatusRepo := TDieStatusRepository.Create;
  if Assigned(ACylinderRepo) then FCylinderRepo := ACylinderRepo else FCylinderRepo := TCylinderRepository.Create;
  if Assigned(AMachineRepo) then FMachineRepo := AMachineRepo else FMachineRepo := TMachineRepository.Create;
  if Assigned(AMachineCylinderRepo) then FMachineCylinderRepo := AMachineCylinderRepo else FMachineCylinderRepo := TMachineCylinderRepository.Create;
  if Assigned(ASettingRepo) then FSettingRepo := ASettingRepo else FSettingRepo := TAppSettingRepository.Create;
end;

{ Customers }

function TMasterDataService.GetAllCustomers(const ActiveOnly: Boolean): TList<TCustomer>;
begin
  Result := FCustomerRepo.GetAll(ActiveOnly);
end;

function TMasterDataService.SaveCustomer(const ACustomer: TCustomer): Integer;
var
  Existing: TCustomer;
begin
  if Trim(ACustomer.Code) = '' then
    raise EDieVixValidationException.Create('Customer Code is required.');
  if Trim(ACustomer.Name) = '' then
    raise EDieVixValidationException.Create('Customer Name is required.');

  Existing := FCustomerRepo.GetByCode(ACustomer.Code);
  if (Existing.ID <> 0) and (Existing.ID <> ACustomer.ID) then
    raise EDieVixValidationException.CreateFmt('Customer code "%s" is already assigned to "%s".', [ACustomer.Code, Existing.Name]);

  if ACustomer.ID = 0 then
    Result := FCustomerRepo.Insert(ACustomer)
  else
  begin
    if FCustomerRepo.Update(ACustomer) then
      Result := ACustomer.ID
    else
      Result := 0;
  end;
end;

function TMasterDataService.DeleteCustomer(const AID: Integer): Boolean;
begin
  if AID <= 0 then
    raise EDieVixValidationException.Create('Invalid Customer ID.');
  Result := FCustomerRepo.Delete(AID);
end;

{ Media }

function TMasterDataService.GetAllMedia(const ActiveOnly: Boolean): TList<TMedia>;
begin
  Result := FMediaRepo.GetAll(ActiveOnly);
end;

function TMasterDataService.SaveMedia(const AMedia: TMedia): Integer;
var
  Existing: TMedia;
begin
  if Trim(AMedia.Code) = '' then
    raise EDieVixValidationException.Create('Media Code is required.');
  if Trim(AMedia.Name) = '' then
    raise EDieVixValidationException.Create('Media Name is required.');

  Existing := FMediaRepo.GetByCode(AMedia.Code);
  if (Existing.ID <> 0) and (Existing.ID <> AMedia.ID) then
    raise EDieVixValidationException.CreateFmt('Media code "%s" is already assigned to "%s".', [AMedia.Code, Existing.Name]);

  if AMedia.ID = 0 then
    Result := FMediaRepo.Insert(AMedia)
  else
  begin
    if FMediaRepo.Update(AMedia) then
      Result := AMedia.ID
    else
      Result := 0;
  end;
end;

function TMasterDataService.DeleteMedia(const AID: Integer): Boolean;
begin
  Result := FMediaRepo.Delete(AID);
end;

{ Statuses }

function TMasterDataService.GetAllStatuses: TList<TDieStatus>;
begin
  Result := FStatusRepo.GetAll;
end;

function TMasterDataService.SaveStatus(const AStatus: TDieStatus): Boolean;
begin
  if Trim(AStatus.Code) = '' then
    raise EDieVixValidationException.Create('Status Code cannot be empty.');
  if Trim(AStatus.Description) = '' then
    raise EDieVixValidationException.Create('Status Description cannot be empty.');
  Result := FStatusRepo.Save(AStatus);
end;

{ Cylinders }

function TMasterDataService.GetAllCylinders(const ActiveOnly: Boolean): TList<TCylinder>;
begin
  Result := FCylinderRepo.GetAll(ActiveOnly);
end;

function TMasterDataService.CanSafelyModifyCylinder(const ATeeth: Integer; out AReason: string): Boolean;
begin
  AReason := '';
  if FCylinderRepo.IsReferencedByDies(ATeeth) then
  begin
    AReason := Format('Cylinder %dT is referenced by existing registered dies. Modifying teeth will break historical die records.', [ATeeth]);
    Result := False;
  end
  else
    Result := True;
end;

function TMasterDataService.SaveCylinder(const ACylinder: TCylinder; const IsNew: Boolean): Boolean;
var
  Existing: TCylinder;
  Reason: string;
begin
  if ACylinder.Teeth <= 0 then
    raise EDieVixValidationException.Create('Cylinder teeth must be greater than zero.');
  if ACylinder.PitchUm <= 0 then
    raise EDieVixValidationException.Create('Cylinder pitch must be greater than zero.');

  if IsNew then
  begin
    Existing := FCylinderRepo.GetByTeeth(ACylinder.Teeth);
    if Existing.Teeth <> 0 then
      raise EDieVixValidationException.CreateFmt('Cylinder with %d teeth already exists in the fleet.', [ACylinder.Teeth]);
    Result := FCylinderRepo.Insert(ACylinder);
  end
  else
  begin
    if not CanSafelyModifyCylinder(ACylinder.Teeth, Reason) then
    begin
      // Pitch modification on referenced cylinders warning
      Existing := FCylinderRepo.GetByTeeth(ACylinder.Teeth);
      if (Existing.Teeth <> 0) and (Existing.PitchUm <> ACylinder.PitchUm) then
        raise EDieVixIntegrityException.Create(Reason);
    end;
    Result := FCylinderRepo.Update(ACylinder);
  end;
end;

function TMasterDataService.DeleteCylinder(const ATeeth: Integer): Boolean;
var
  Reason: string;
begin
  if not CanSafelyModifyCylinder(ATeeth, Reason) then
    raise EDieVixIntegrityException.Create(Reason);
  Result := FCylinderRepo.Delete(ATeeth);
end;

{ Machines }

function TMasterDataService.GetAllMachines(const ActiveOnly: Boolean): TList<TMachine>;
begin
  Result := FMachineRepo.GetAll(ActiveOnly);
end;

function TMasterDataService.SaveMachine(const AMachine: TMachine): Integer;
var
  Existing: TMachine;
begin
  if Trim(AMachine.Code) = '' then
    raise EDieVixValidationException.Create('Machine Code is required.');
  if Trim(AMachine.Name) = '' then
    raise EDieVixValidationException.Create('Machine Name is required.');
  if AMachine.MaxWebWidthMm <= 0 then
    raise EDieVixValidationException.Create('Maximum Web Width must be greater than zero.');
  if AMachine.MaxWebWidthMm < AMachine.MinWebWidthMm then
    raise EDieVixValidationException.Create('Maximum Web Width cannot be smaller than Minimum Web Width.');

  Existing := FMachineRepo.GetByCode(AMachine.Code);
  if (Existing.ID <> 0) and (Existing.ID <> AMachine.ID) then
    raise EDieVixValidationException.CreateFmt('Machine code "%s" is already assigned to "%s".', [AMachine.Code, Existing.Name]);

  if AMachine.ID = 0 then
    Result := FMachineRepo.Insert(AMachine)
  else
  begin
    if FMachineRepo.Update(AMachine) then
      Result := AMachine.ID
    else
      Result := 0;
  end;
end;

function TMasterDataService.DeleteMachine(const AID: Integer): Boolean;
begin
  Result := FMachineRepo.Delete(AID);
end;

{ Matrix }

function TMasterDataService.GetAssignedCylindersForMachine(const AMachineID: Integer): TList<Integer>;
begin
  Result := FMachineCylinderRepo.GetCylindersForMachine(AMachineID);
end;

function TMasterDataService.SaveMachineCylinderAssignments(
  const AMachineID: Integer;
  const ATeethList: TArray<Integer>
): Boolean;
begin
  if AMachineID <= 0 then
    raise EDieVixValidationException.Create('Invalid Machine ID for cylinder assignment.');
  Result := FMachineCylinderRepo.SetAssignments(AMachineID, ATeethList);
end;

function TMasterDataService.ToggleAssignment(const AMachineID, ATeeth: Integer; const AAssign: Boolean): Boolean;
begin
  if AAssign then
    Result := FMachineCylinderRepo.AssignCylinder(AMachineID, ATeeth)
  else
    Result := FMachineCylinderRepo.UnassignCylinder(AMachineID, ATeeth);
end;

{ Settings }

function TMasterDataService.GetMinAroundGapUm: Int64;
begin
  Result := FSettingRepo.GetInt('MIN_AROUND_GAP_UM', DEFAULT_MIN_GAP_UM);
end;

function TMasterDataService.GetHardBlockGapUm: Int64;
begin
  Result := FSettingRepo.GetInt('HARD_BLOCK_GAP_UM', DEFAULT_HARD_BLOCK_GAP_UM);
end;

function TMasterDataService.GetDefaultAcrossGapMm: Double;
begin
  Result := FSettingRepo.GetFloat('DEFAULT_ACROSS_GAP_MM', 3.0);
end;

function TMasterDataService.GetDefaultCornerRadiusMm: Double;
begin
  Result := FSettingRepo.GetFloat('DEFAULT_CORNER_RADIUS_MM', 2.0);
end;

function TMasterDataService.SaveSettings(
  const AMinAroundGapUm, AHardBlockGapUm: Int64;
  const ADefaultAcrossGapMm, ADefaultCornerRadiusMm: Double
): Boolean;
begin
  if AMinAroundGapUm <= 0 then
    raise EDieVixValidationException.Create('Minimum around gap must be positive.');
  if (AHardBlockGapUm > 0) and (AHardBlockGapUm >= AMinAroundGapUm) then
    raise EDieVixValidationException.Create('Hard block threshold must be lower than standard minimum gap.');

  FSettingRepo.SetValue('MIN_AROUND_GAP_UM', IntToStr(AMinAroundGapUm), 'Standard recommended minimum around gap (um)');
  FSettingRepo.SetValue('HARD_BLOCK_GAP_UM', IntToStr(AHardBlockGapUm), 'Hard mechanical block threshold (um, 0=disabled)');
  FSettingRepo.SetValue('DEFAULT_ACROSS_GAP_MM', FormatFloat('0.000', ADefaultAcrossGapMm), 'Default across gap (mm)');
  FSettingRepo.SetValue('DEFAULT_CORNER_RADIUS_MM', FormatFloat('0.000', ADefaultCornerRadiusMm), 'Default corner radius (mm)');
  Result := True;
end;

end.
