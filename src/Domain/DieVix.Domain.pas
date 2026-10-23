unit DieVix.Domain;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Domain Entities, Value Objects, and Repository Interfaces
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

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
    CustomerID: Integer;
    CustomerName: string;
    MediaID: Integer;
    MediaName: string;
    Teeth: Integer;
    AroundSizeMm: Double;
    AcrossSizeMm: Double;
    AroundUps: Integer;
    AcrossUps: Integer;
    AroundGapMm: Double;
    AcrossGapMm: Double;
    CornerRadiusMm: Double;
    Shape: string;
    StorageLocation: string;
    StatusCode: string;
    StatusName: string;
    OverrideReason: string;
    PurchaseDate: TDateTime;
    DieMaker: string;
    TotalRunMetres: Integer;
    Notes: string;
    CreatedAt: TDateTime;
    UpdatedAt: TDateTime;
  end;

  { Repository Interfaces }

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

end.
