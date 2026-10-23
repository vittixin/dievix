unit DieVix.Repositories;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  FireDAC Data Access Repositories for Firebird 5.0
  Fully parameterized SQL with transaction safety and clean mapping.
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  Data.DB,
  DieVix.Domain,
  DieVix.ConnectionManager;

type
  { Base Repository }
  TBaseRepository = class(TInterfacedObject)
  protected
    FConnection: TFDConnection;
    function GetConn: TFDConnection; virtual;
    function CreateQuery: TFDQuery;
  public
    constructor Create(AConn: TFDConnection = nil); virtual;
  end;

  { Customer Repository }
  TCustomerRepository = class(TBaseRepository, ICustomerRepository)
  public
    function GetAll(const ActiveOnly: Boolean = False): TList<TCustomer>;
    function GetByID(const AID: Integer): TCustomer;
    function GetByCode(const ACode: string): TCustomer;
    function Insert(const ACustomer: TCustomer): Integer;
    function Update(const ACustomer: TCustomer): Boolean;
    function Delete(const AID: Integer): Boolean;
  end;

  { Media Substrate Repository }
  TMediaRepository = class(TBaseRepository, IMediaRepository)
  public
    function GetAll(const ActiveOnly: Boolean = False): TList<TMedia>;
    function GetByID(const AID: Integer): TMedia;
    function GetByCode(const ACode: string): TMedia;
    function Insert(const AMedia: TMedia): Integer;
    function Update(const AMedia: TMedia): Boolean;
    function Delete(const AID: Integer): Boolean;
  end;

  { Die Status Repository }
  TDieStatusRepository = class(TBaseRepository, IDieStatusRepository)
  public
    function GetAll: TList<TDieStatus>;
    function GetByCode(const ACode: string): TDieStatus;
    function Save(const AStatus: TDieStatus): Boolean;
    function Delete(const ACode: string): Boolean;
  end;

  { Cylinder Fleet Repository }
  TCylinderRepository = class(TBaseRepository, ICylinderRepository)
  public
    function GetAll(const ActiveOnly: Boolean = False): TList<TCylinder>;
    function GetByTeeth(const ATeeth: Integer): TCylinder;
    function Insert(const ACylinder: TCylinder): Boolean;
    function Update(const ACylinder: TCylinder): Boolean;
    function Delete(const ATeeth: Integer): Boolean;
    function IsReferencedByDies(const ATeeth: Integer): Boolean;
  end;

  { Machine Repository }
  TMachineRepository = class(TBaseRepository, IMachineRepository)
  public
    function GetAll(const ActiveOnly: Boolean = False): TList<TMachine>;
    function GetByID(const AID: Integer): TMachine;
    function GetByCode(const ACode: string): TMachine;
    function Insert(const AMachine: TMachine): Integer;
    function Update(const AMachine: TMachine): Boolean;
    function Delete(const AID: Integer): Boolean;
  end;

  { Machine-Cylinder Compatibility Repository }
  TMachineCylinderRepository = class(TBaseRepository, IMachineCylinderRepository)
  public
    function GetCylindersForMachine(const AMachineID: Integer): TList<Integer>;
    function GetMachinesForCylinder(const ATeeth: Integer): TList<Integer>;
    function AssignCylinder(const AMachineID: Integer; const ATeeth: Integer): Boolean;
    function UnassignCylinder(const AMachineID: Integer; const ATeeth: Integer): Boolean;
    function SetAssignments(const AMachineID: Integer; const ATeethList: TArray<Integer>): Boolean;
    function IsAssigned(const AMachineID: Integer; const ATeeth: Integer): Boolean;
  end;

  { App Setting Repository }
  TAppSettingRepository = class(TBaseRepository, IAppSettingRepository)
  public
    function GetAll: TList<TAppSetting>;
    function GetValue(const AKey: string; const ADefault: string = ''): string;
    function GetInt(const AKey: string; const ADefault: Integer = 0): Integer;
    function GetFloat(const AKey: string; const ADefault: Double = 0.0): Double;
    function SetValue(const AKey, AValue: string; const ADescription: string = ''): Boolean;
  end;

  { Die Tooling Repository }
  TDieRepository = class(TBaseRepository, IDieRepository)
  private
    function MapFromQuery(Qry: TFDQuery): TDie;
  public
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

{ TBaseRepository }

constructor TBaseRepository.Create(AConn: TFDConnection);
begin
  inherited Create;
  FConnection := AConn;
end;

function TBaseRepository.GetConn: TFDConnection;
begin
  if Assigned(FConnection) then
    Result := FConnection
  else
    Result := TDieVixConnectionManager.Instance.GetConnection;
end;

function TBaseRepository.CreateQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := GetConn;
end;

{ -----------------------------------------------------------------------------
  TCustomerRepository
----------------------------------------------------------------------------- }

function TCustomerRepository.GetAll(const ActiveOnly: Boolean): TList<TCustomer>;
var
  Qry: TFDQuery;
  Cust: TCustomer;
begin
  Result := TList<TCustomer>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT ID, CODE, NAME, CONTACT_PERSON, PHONE, EMAIL, CITY, NOTES, IS_ACTIVE, CREATED_AT, UPDATED_AT ' +
                    'FROM CUSTOMER ';
    if ActiveOnly then
      Qry.SQL.Text := Qry.SQL.Text + 'WHERE IS_ACTIVE = 1 ';
    Qry.SQL.Text := Qry.SQL.Text + 'ORDER BY NAME';
    Qry.Open;

    while not Qry.Eof do
    begin
      FillChar(Cust, SizeOf(Cust), 0);
      Cust.ID := Qry.FieldByName('ID').AsInteger;
      Cust.Code := Qry.FieldByName('CODE').AsString;
      Cust.Name := Qry.FieldByName('NAME').AsString;
      Cust.ContactPerson := Qry.FieldByName('CONTACT_PERSON').AsString;
      Cust.Phone := Qry.FieldByName('PHONE').AsString;
      Cust.Email := Qry.FieldByName('EMAIL').AsString;
      Cust.City := Qry.FieldByName('CITY').AsString;
      Cust.Notes := Qry.FieldByName('NOTES').AsString;
      Cust.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
      Cust.CreatedAt := Qry.FieldByName('CREATED_AT').AsDateTime;
      Cust.UpdatedAt := Qry.FieldByName('UPDATED_AT').AsDateTime;
      Result.Add(Cust);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TCustomerRepository.GetByID(const AID: Integer): TCustomer;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT ID, CODE, NAME, CONTACT_PERSON, PHONE, EMAIL, CITY, NOTES, IS_ACTIVE, CREATED_AT, UPDATED_AT ' +
                    'FROM CUSTOMER WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.ID := Qry.FieldByName('ID').AsInteger;
      Result.Code := Qry.FieldByName('CODE').AsString;
      Result.Name := Qry.FieldByName('NAME').AsString;
      Result.ContactPerson := Qry.FieldByName('CONTACT_PERSON').AsString;
      Result.Phone := Qry.FieldByName('PHONE').AsString;
      Result.Email := Qry.FieldByName('EMAIL').AsString;
      Result.City := Qry.FieldByName('CITY').AsString;
      Result.Notes := Qry.FieldByName('NOTES').AsString;
      Result.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
      Result.CreatedAt := Qry.FieldByName('CREATED_AT').AsDateTime;
      Result.UpdatedAt := Qry.FieldByName('UPDATED_AT').AsDateTime;
    end;
  finally
    Qry.Free;
  end;
end;

function TCustomerRepository.GetByCode(const ACode: string): TCustomer;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT ID, CODE, NAME, CONTACT_PERSON, PHONE, EMAIL, CITY, NOTES, IS_ACTIVE, CREATED_AT, UPDATED_AT ' +
                    'FROM CUSTOMER WHERE CODE = :CODE';
    Qry.ParamByName('CODE').AsString := Trim(ACode);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.ID := Qry.FieldByName('ID').AsInteger;
      Result.Code := Qry.FieldByName('CODE').AsString;
      Result.Name := Qry.FieldByName('NAME').AsString;
      Result.ContactPerson := Qry.FieldByName('CONTACT_PERSON').AsString;
      Result.Phone := Qry.FieldByName('PHONE').AsString;
      Result.Email := Qry.FieldByName('EMAIL').AsString;
      Result.City := Qry.FieldByName('CITY').AsString;
      Result.Notes := Qry.FieldByName('NOTES').AsString;
      Result.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
      Result.CreatedAt := Qry.FieldByName('CREATED_AT').AsDateTime;
      Result.UpdatedAt := Qry.FieldByName('UPDATED_AT').AsDateTime;
    end;
  finally
    Qry.Free;
  end;
end;

function TCustomerRepository.Insert(const ACustomer: TCustomer): Integer;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'INSERT INTO CUSTOMER (CODE, NAME, CONTACT_PERSON, PHONE, EMAIL, CITY, NOTES, IS_ACTIVE) ' +
      'VALUES (:CODE, :NAME, :CONTACT_PERSON, :PHONE, :EMAIL, :CITY, :NOTES, :IS_ACTIVE) ' +
      'RETURNING ID';
    Qry.ParamByName('CODE').AsString := Trim(ACustomer.Code);
    Qry.ParamByName('NAME').AsString := Trim(ACustomer.Name);
    Qry.ParamByName('CONTACT_PERSON').AsString := Trim(ACustomer.ContactPerson);
    Qry.ParamByName('PHONE').AsString := Trim(ACustomer.Phone);
    Qry.ParamByName('EMAIL').AsString := Trim(ACustomer.Email);
    Qry.ParamByName('CITY').AsString := Trim(ACustomer.City);
    Qry.ParamByName('NOTES').AsString := Trim(ACustomer.Notes);
    if ACustomer.IsActive then
      Qry.ParamByName('IS_ACTIVE').AsInteger := 1
    else
      Qry.ParamByName('IS_ACTIVE').AsInteger := 0;
    Qry.Open;
    Result := Qry.Fields[0].AsInteger;
  finally
    Qry.Free;
  end;
end;

function TCustomerRepository.Update(const ACustomer: TCustomer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'UPDATE CUSTOMER SET ' +
      '  CODE = :CODE, ' +
      '  NAME = :NAME, ' +
      '  CONTACT_PERSON = :CONTACT_PERSON, ' +
      '  PHONE = :PHONE, ' +
      '  EMAIL = :EMAIL, ' +
      '  CITY = :CITY, ' +
      '  NOTES = :NOTES, ' +
      '  IS_ACTIVE = :IS_ACTIVE, ' +
      '  UPDATED_AT = CURRENT_TIMESTAMP ' +
      'WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := ACustomer.ID;
    Qry.ParamByName('CODE').AsString := Trim(ACustomer.Code);
    Qry.ParamByName('NAME').AsString := Trim(ACustomer.Name);
    Qry.ParamByName('CONTACT_PERSON').AsString := Trim(ACustomer.ContactPerson);
    Qry.ParamByName('PHONE').AsString := Trim(ACustomer.Phone);
    Qry.ParamByName('EMAIL').AsString := Trim(ACustomer.Email);
    Qry.ParamByName('CITY').AsString := Trim(ACustomer.City);
    Qry.ParamByName('NOTES').AsString := Trim(ACustomer.Notes);
    if ACustomer.IsActive then
      Qry.ParamByName('IS_ACTIVE').AsInteger := 1
    else
      Qry.ParamByName('IS_ACTIVE').AsInteger := 0;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

function TCustomerRepository.Delete(const AID: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'DELETE FROM CUSTOMER WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

{ -----------------------------------------------------------------------------
  TMediaRepository
----------------------------------------------------------------------------- }

function TMediaRepository.GetAll(const ActiveOnly: Boolean): TList<TMedia>;
var
  Qry: TFDQuery;
  M: TMedia;
begin
  Result := TList<TMedia>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT ID, CODE, NAME, FACE_MATERIAL, LINER_MATERIAL, ADHESIVE_TYPE, TOTAL_CALIPER_UM, NOTES, IS_ACTIVE ' +
                    'FROM MEDIA ';
    if ActiveOnly then
      Qry.SQL.Text := Qry.SQL.Text + 'WHERE IS_ACTIVE = 1 ';
    Qry.SQL.Text := Qry.SQL.Text + 'ORDER BY NAME';
    Qry.Open;

    while not Qry.Eof do
    begin
      FillChar(M, SizeOf(M), 0);
      M.ID := Qry.FieldByName('ID').AsInteger;
      M.Code := Qry.FieldByName('CODE').AsString;
      M.Name := Qry.FieldByName('NAME').AsString;
      M.FaceMaterial := Qry.FieldByName('FACE_MATERIAL').AsString;
      M.LinerMaterial := Qry.FieldByName('LINER_MATERIAL').AsString;
      M.AdhesiveType := Qry.FieldByName('ADHESIVE_TYPE').AsString;
      M.TotalCaliperUm := Qry.FieldByName('TOTAL_CALIPER_UM').AsInteger;
      M.Notes := Qry.FieldByName('NOTES').AsString;
      M.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
      Result.Add(M);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TMediaRepository.GetByID(const AID: Integer): TMedia;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT ID, CODE, NAME, FACE_MATERIAL, LINER_MATERIAL, ADHESIVE_TYPE, TOTAL_CALIPER_UM, NOTES, IS_ACTIVE ' +
                    'FROM MEDIA WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.ID := Qry.FieldByName('ID').AsInteger;
      Result.Code := Qry.FieldByName('CODE').AsString;
      Result.Name := Qry.FieldByName('NAME').AsString;
      Result.FaceMaterial := Qry.FieldByName('FACE_MATERIAL').AsString;
      Result.LinerMaterial := Qry.FieldByName('LINER_MATERIAL').AsString;
      Result.AdhesiveType := Qry.FieldByName('ADHESIVE_TYPE').AsString;
      Result.TotalCaliperUm := Qry.FieldByName('TOTAL_CALIPER_UM').AsInteger;
      Result.Notes := Qry.FieldByName('NOTES').AsString;
      Result.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
    end;
  finally
    Qry.Free;
  end;
end;

function TMediaRepository.GetByCode(const ACode: string): TMedia;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT ID, CODE, NAME, FACE_MATERIAL, LINER_MATERIAL, ADHESIVE_TYPE, TOTAL_CALIPER_UM, NOTES, IS_ACTIVE ' +
                    'FROM MEDIA WHERE CODE = :CODE';
    Qry.ParamByName('CODE').AsString := Trim(ACode);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.ID := Qry.FieldByName('ID').AsInteger;
      Result.Code := Qry.FieldByName('CODE').AsString;
      Result.Name := Qry.FieldByName('NAME').AsString;
      Result.FaceMaterial := Qry.FieldByName('FACE_MATERIAL').AsString;
      Result.LinerMaterial := Qry.FieldByName('LINER_MATERIAL').AsString;
      Result.AdhesiveType := Qry.FieldByName('ADHESIVE_TYPE').AsString;
      Result.TotalCaliperUm := Qry.FieldByName('TOTAL_CALIPER_UM').AsInteger;
      Result.Notes := Qry.FieldByName('NOTES').AsString;
      Result.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
    end;
  finally
    Qry.Free;
  end;
end;

function TMediaRepository.Insert(const AMedia: TMedia): Integer;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'INSERT INTO MEDIA (CODE, NAME, FACE_MATERIAL, LINER_MATERIAL, ADHESIVE_TYPE, TOTAL_CALIPER_UM, NOTES, IS_ACTIVE) ' +
      'VALUES (:CODE, :NAME, :FACE, :LINER, :ADHESIVE, :CALIPER, :NOTES, :IS_ACTIVE) ' +
      'RETURNING ID';
    Qry.ParamByName('CODE').AsString := Trim(AMedia.Code);
    Qry.ParamByName('NAME').AsString := Trim(AMedia.Name);
    Qry.ParamByName('FACE').AsString := Trim(AMedia.FaceMaterial);
    Qry.ParamByName('LINER').AsString := Trim(AMedia.LinerMaterial);
    Qry.ParamByName('ADHESIVE').AsString := Trim(AMedia.AdhesiveType);
    Qry.ParamByName('CALIPER').AsInteger := AMedia.TotalCaliperUm;
    Qry.ParamByName('NOTES').AsString := Trim(AMedia.Notes);
    if AMedia.IsActive then
      Qry.ParamByName('IS_ACTIVE').AsInteger := 1
    else
      Qry.ParamByName('IS_ACTIVE').AsInteger := 0;
    Qry.Open;
    Result := Qry.Fields[0].AsInteger;
  finally
    Qry.Free;
  end;
end;

function TMediaRepository.Update(const AMedia: TMedia): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'UPDATE MEDIA SET ' +
      '  CODE = :CODE, ' +
      '  NAME = :NAME, ' +
      '  FACE_MATERIAL = :FACE, ' +
      '  LINER_MATERIAL = :LINER, ' +
      '  ADHESIVE_TYPE = :ADHESIVE, ' +
      '  TOTAL_CALIPER_UM = :CALIPER, ' +
      '  NOTES = :NOTES, ' +
      '  IS_ACTIVE = :IS_ACTIVE, ' +
      '  UPDATED_AT = CURRENT_TIMESTAMP ' +
      'WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AMedia.ID;
    Qry.ParamByName('CODE').AsString := Trim(AMedia.Code);
    Qry.ParamByName('NAME').AsString := Trim(AMedia.Name);
    Qry.ParamByName('FACE').AsString := Trim(AMedia.FaceMaterial);
    Qry.ParamByName('LINER').AsString := Trim(AMedia.LinerMaterial);
    Qry.ParamByName('ADHESIVE').AsString := Trim(AMedia.AdhesiveType);
    Qry.ParamByName('CALIPER').AsInteger := AMedia.TotalCaliperUm;
    Qry.ParamByName('NOTES').AsString := Trim(AMedia.Notes);
    if AMedia.IsActive then
      Qry.ParamByName('IS_ACTIVE').AsInteger := 1
    else
      Qry.ParamByName('IS_ACTIVE').AsInteger := 0;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

function TMediaRepository.Delete(const AID: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'DELETE FROM MEDIA WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

{ -----------------------------------------------------------------------------
  TDieStatusRepository
----------------------------------------------------------------------------- }

function TDieStatusRepository.GetAll: TList<TDieStatus>;
var
  Qry: TFDQuery;
  S: TDieStatus;
begin
  Result := TList<TDieStatus>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR, SORT_ORDER FROM DIE_STATUS ORDER BY SORT_ORDER, CODE';
    Qry.Open;
    while not Qry.Eof do
    begin
      FillChar(S, SizeOf(S), 0);
      S.Code := Qry.FieldByName('CODE').AsString;
      S.Description := Qry.FieldByName('DESCRIPTION').AsString;
      S.IsUsable := Qry.FieldByName('IS_USABLE').AsInteger = 1;
      S.BadgeColor := Qry.FieldByName('BADGE_COLOR').AsString;
      S.SortOrder := Qry.FieldByName('SORT_ORDER').AsInteger;
      Result.Add(S);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TDieStatusRepository.GetByCode(const ACode: string): TDieStatus;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR, SORT_ORDER FROM DIE_STATUS WHERE CODE = :C';
    Qry.ParamByName('C').AsString := Trim(ACode);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.Code := Qry.FieldByName('CODE').AsString;
      Result.Description := Qry.FieldByName('DESCRIPTION').AsString;
      Result.IsUsable := Qry.FieldByName('IS_USABLE').AsInteger = 1;
      Result.BadgeColor := Qry.FieldByName('BADGE_COLOR').AsString;
      Result.SortOrder := Qry.FieldByName('SORT_ORDER').AsInteger;
    end;
  finally
    Qry.Free;
  end;
end;

function TDieStatusRepository.Save(const AStatus: TDieStatus): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'UPDATE OR INSERT INTO DIE_STATUS (CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR, SORT_ORDER) ' +
      'VALUES (:CODE, :DESCRIPTION, :IS_USABLE, :BADGE_COLOR, :SORT_ORDER) MATCHING (CODE)';
    Qry.ParamByName('CODE').AsString := Trim(AStatus.Code);
    Qry.ParamByName('DESCRIPTION').AsString := Trim(AStatus.Description);
    if AStatus.IsUsable then
      Qry.ParamByName('IS_USABLE').AsInteger := 1
    else
      Qry.ParamByName('IS_USABLE').AsInteger := 0;
    Qry.ParamByName('BADGE_COLOR').AsString := Trim(AStatus.BadgeColor);
    Qry.ParamByName('SORT_ORDER').AsInteger := AStatus.SortOrder;
    Qry.ExecSQL;
    Result := True;
  finally
    Qry.Free;
  end;
end;

function TDieStatusRepository.Delete(const ACode: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'DELETE FROM DIE_STATUS WHERE CODE = :C';
    Qry.ParamByName('C').AsString := Trim(ACode);
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

{ -----------------------------------------------------------------------------
  TCylinderRepository
----------------------------------------------------------------------------- }

function TCylinderRepository.GetAll(const ActiveOnly: Boolean): TList<TCylinder>;
var
  Qry: TFDQuery;
  Cyl: TCylinder;
begin
  Result := TList<TCylinder>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT TEETH, PITCH_UM, REPEAT_MM, REPEAT_INCH, IS_ACTIVE, NOTES FROM CYLINDER_SIZE ';
    if ActiveOnly then
      Qry.SQL.Text := Qry.SQL.Text + 'WHERE IS_ACTIVE = 1 ';
    Qry.SQL.Text := Qry.SQL.Text + 'ORDER BY TEETH ASC';
    Qry.Open;

    while not Qry.Eof do
    begin
      FillChar(Cyl, SizeOf(Cyl), 0);
      Cyl.Teeth := Qry.FieldByName('TEETH').AsInteger;
      Cyl.PitchUm := Qry.FieldByName('PITCH_UM').AsInteger;
      Cyl.RepeatMm := Qry.FieldByName('REPEAT_MM').AsFloat;
      Cyl.RepeatInch := Qry.FieldByName('REPEAT_INCH').AsFloat;
      Cyl.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
      Cyl.Notes := Qry.FieldByName('NOTES').AsString;
      Result.Add(Cyl);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TCylinderRepository.GetByTeeth(const ATeeth: Integer): TCylinder;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT TEETH, PITCH_UM, REPEAT_MM, REPEAT_INCH, IS_ACTIVE, NOTES FROM CYLINDER_SIZE WHERE TEETH = :T';
    Qry.ParamByName('T').AsInteger := ATeeth;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.Teeth := Qry.FieldByName('TEETH').AsInteger;
      Result.PitchUm := Qry.FieldByName('PITCH_UM').AsInteger;
      Result.RepeatMm := Qry.FieldByName('REPEAT_MM').AsFloat;
      Result.RepeatInch := Qry.FieldByName('REPEAT_INCH').AsFloat;
      Result.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
      Result.Notes := Qry.FieldByName('NOTES').AsString;
    end;
  finally
    Qry.Free;
  end;
end;

function TCylinderRepository.Insert(const ACylinder: TCylinder): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'INSERT INTO CYLINDER_SIZE (TEETH, PITCH_UM, IS_ACTIVE, NOTES) ' +
      'VALUES (:T, :P, :A, :N)';
    Qry.ParamByName('T').AsInteger := ACylinder.Teeth;
    Qry.ParamByName('P').AsInteger := ACylinder.PitchUm;
    if ACylinder.IsActive then
      Qry.ParamByName('A').AsInteger := 1
    else
      Qry.ParamByName('A').AsInteger := 0;
    Qry.ParamByName('N').AsString := Trim(ACylinder.Notes);
    Qry.ExecSQL;
    Result := True;
  finally
    Qry.Free;
  end;
end;

function TCylinderRepository.Update(const ACylinder: TCylinder): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'UPDATE CYLINDER_SIZE SET ' +
      '  PITCH_UM = :P, ' +
      '  IS_ACTIVE = :A, ' +
      '  NOTES = :N ' +
      'WHERE TEETH = :T';
    Qry.ParamByName('T').AsInteger := ACylinder.Teeth;
    Qry.ParamByName('P').AsInteger := ACylinder.PitchUm;
    if ACylinder.IsActive then
      Qry.ParamByName('A').AsInteger := 1
    else
      Qry.ParamByName('A').AsInteger := 0;
    Qry.ParamByName('N').AsString := Trim(ACylinder.Notes);
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

function TCylinderRepository.Delete(const ATeeth: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'DELETE FROM CYLINDER_SIZE WHERE TEETH = :T';
    Qry.ParamByName('T').AsInteger := ATeeth;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

function TCylinderRepository.IsReferencedByDies(const ATeeth: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT COUNT(*) FROM DIE WHERE TEETH = :T';
    Qry.ParamByName('T').AsInteger := ATeeth;
    Qry.Open;
    Result := Qry.Fields[0].AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

{ -----------------------------------------------------------------------------
  TMachineRepository
----------------------------------------------------------------------------- }

function TMachineRepository.GetAll(const ActiveOnly: Boolean): TList<TMachine>;
var
  Qry: TFDQuery;
  M: TMachine;
begin
  Result := TList<TMachine>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ID, CODE, NAME, MAX_WEB_WIDTH_MM, MIN_WEB_WIDTH_MM, DEFAULT_MARGIN_MM, PRINT_METHOD, NOTES, IS_ACTIVE ' +
      'FROM MACHINE ';
    if ActiveOnly then
      Qry.SQL.Text := Qry.SQL.Text + 'WHERE IS_ACTIVE = 1 ';
    Qry.SQL.Text := Qry.SQL.Text + 'ORDER BY NAME';
    Qry.Open;

    while not Qry.Eof do
    begin
      FillChar(M, SizeOf(M), 0);
      M.ID := Qry.FieldByName('ID').AsInteger;
      M.Code := Qry.FieldByName('CODE').AsString;
      M.Name := Qry.FieldByName('NAME').AsString;
      M.MaxWebWidthMm := Qry.FieldByName('MAX_WEB_WIDTH_MM').AsFloat;
      M.MinWebWidthMm := Qry.FieldByName('MIN_WEB_WIDTH_MM').AsFloat;
      M.DefaultMarginMm := Qry.FieldByName('DEFAULT_MARGIN_MM').AsFloat;
      M.PrintMethod := Qry.FieldByName('PRINT_METHOD').AsString;
      M.Notes := Qry.FieldByName('NOTES').AsString;
      M.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
      Result.Add(M);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TMachineRepository.GetByID(const AID: Integer): TMachine;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ID, CODE, NAME, MAX_WEB_WIDTH_MM, MIN_WEB_WIDTH_MM, DEFAULT_MARGIN_MM, PRINT_METHOD, NOTES, IS_ACTIVE ' +
      'FROM MACHINE WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.ID := Qry.FieldByName('ID').AsInteger;
      Result.Code := Qry.FieldByName('CODE').AsString;
      Result.Name := Qry.FieldByName('NAME').AsString;
      Result.MaxWebWidthMm := Qry.FieldByName('MAX_WEB_WIDTH_MM').AsFloat;
      Result.MinWebWidthMm := Qry.FieldByName('MIN_WEB_WIDTH_MM').AsFloat;
      Result.DefaultMarginMm := Qry.FieldByName('DEFAULT_MARGIN_MM').AsFloat;
      Result.PrintMethod := Qry.FieldByName('PRINT_METHOD').AsString;
      Result.Notes := Qry.FieldByName('NOTES').AsString;
      Result.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
    end;
  finally
    Qry.Free;
  end;
end;

function TMachineRepository.GetByCode(const ACode: string): TMachine;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT ID, CODE, NAME, MAX_WEB_WIDTH_MM, MIN_WEB_WIDTH_MM, DEFAULT_MARGIN_MM, PRINT_METHOD, NOTES, IS_ACTIVE ' +
      'FROM MACHINE WHERE CODE = :CODE';
    Qry.ParamByName('CODE').AsString := Trim(ACode);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.ID := Qry.FieldByName('ID').AsInteger;
      Result.Code := Qry.FieldByName('CODE').AsString;
      Result.Name := Qry.FieldByName('NAME').AsString;
      Result.MaxWebWidthMm := Qry.FieldByName('MAX_WEB_WIDTH_MM').AsFloat;
      Result.MinWebWidthMm := Qry.FieldByName('MIN_WEB_WIDTH_MM').AsFloat;
      Result.DefaultMarginMm := Qry.FieldByName('DEFAULT_MARGIN_MM').AsFloat;
      Result.PrintMethod := Qry.FieldByName('PRINT_METHOD').AsString;
      Result.Notes := Qry.FieldByName('NOTES').AsString;
      Result.IsActive := Qry.FieldByName('IS_ACTIVE').AsInteger = 1;
    end;
  finally
    Qry.Free;
  end;
end;

function TMachineRepository.Insert(const AMachine: TMachine): Integer;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'INSERT INTO MACHINE (CODE, NAME, MAX_WEB_WIDTH_MM, MIN_WEB_WIDTH_MM, DEFAULT_MARGIN_MM, PRINT_METHOD, NOTES, IS_ACTIVE) ' +
      'VALUES (:CODE, :NAME, :MAX_W, :MIN_W, :DEF_M, :PM, :NOTES, :IS_ACTIVE) ' +
      'RETURNING ID';
    Qry.ParamByName('CODE').AsString := Trim(AMachine.Code);
    Qry.ParamByName('NAME').AsString := Trim(AMachine.Name);
    Qry.ParamByName('MAX_W').AsFloat := AMachine.MaxWebWidthMm;
    Qry.ParamByName('MIN_W').AsFloat := AMachine.MinWebWidthMm;
    Qry.ParamByName('DEF_M').AsFloat := AMachine.DefaultMarginMm;
    Qry.ParamByName('PM').AsString := Trim(AMachine.PrintMethod);
    Qry.ParamByName('NOTES').AsString := Trim(AMachine.Notes);
    if AMachine.IsActive then
      Qry.ParamByName('IS_ACTIVE').AsInteger := 1
    else
      Qry.ParamByName('IS_ACTIVE').AsInteger := 0;
    Qry.Open;
    Result := Qry.Fields[0].AsInteger;
  finally
    Qry.Free;
  end;
end;

function TMachineRepository.Update(const AMachine: TMachine): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'UPDATE MACHINE SET ' +
      '  CODE = :CODE, ' +
      '  NAME = :NAME, ' +
      '  MAX_WEB_WIDTH_MM = :MAX_W, ' +
      '  MIN_WEB_WIDTH_MM = :MIN_W, ' +
      '  DEFAULT_MARGIN_MM = :DEF_M, ' +
      '  PRINT_METHOD = :PM, ' +
      '  NOTES = :NOTES, ' +
      '  IS_ACTIVE = :IS_ACTIVE, ' +
      '  UPDATED_AT = CURRENT_TIMESTAMP ' +
      'WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AMachine.ID;
    Qry.ParamByName('CODE').AsString := Trim(AMachine.Code);
    Qry.ParamByName('NAME').AsString := Trim(AMachine.Name);
    Qry.ParamByName('MAX_W').AsFloat := AMachine.MaxWebWidthMm;
    Qry.ParamByName('MIN_W').AsFloat := AMachine.MinWebWidthMm;
    Qry.ParamByName('DEF_M').AsFloat := AMachine.DefaultMarginMm;
    Qry.ParamByName('PM').AsString := Trim(AMachine.PrintMethod);
    Qry.ParamByName('NOTES').AsString := Trim(AMachine.Notes);
    if AMachine.IsActive then
      Qry.ParamByName('IS_ACTIVE').AsInteger := 1
    else
      Qry.ParamByName('IS_ACTIVE').AsInteger := 0;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

function TMachineRepository.Delete(const AID: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'DELETE FROM MACHINE WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

{ -----------------------------------------------------------------------------
  TMachineCylinderRepository
----------------------------------------------------------------------------- }

function TMachineCylinderRepository.GetCylindersForMachine(const AMachineID: Integer): TList<Integer>;
var
  Qry: TFDQuery;
begin
  Result := TList<Integer>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT TEETH FROM MACHINE_CYLINDER WHERE MACHINE_ID = :MID ORDER BY TEETH ASC';
    Qry.ParamByName('MID').AsInteger := AMachineID;
    Qry.Open;
    while not Qry.Eof do
    begin
      Result.Add(Qry.Fields[0].AsInteger);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TMachineCylinderRepository.GetMachinesForCylinder(const ATeeth: Integer): TList<Integer>;
var
  Qry: TFDQuery;
begin
  Result := TList<Integer>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT MACHINE_ID FROM MACHINE_CYLINDER WHERE TEETH = :T ORDER BY MACHINE_ID ASC';
    Qry.ParamByName('T').AsInteger := ATeeth;
    Qry.Open;
    while not Qry.Eof do
    begin
      Result.Add(Qry.Fields[0].AsInteger);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TMachineCylinderRepository.AssignCylinder(const AMachineID, ATeeth: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'UPDATE OR INSERT INTO MACHINE_CYLINDER (MACHINE_ID, TEETH) VALUES (:M, :T) MATCHING (MACHINE_ID, TEETH)';
    Qry.ParamByName('M').AsInteger := AMachineID;
    Qry.ParamByName('T').AsInteger := ATeeth;
    Qry.ExecSQL;
    Result := True;
  finally
    Qry.Free;
  end;
end;

function TMachineCylinderRepository.UnassignCylinder(const AMachineID, ATeeth: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'DELETE FROM MACHINE_CYLINDER WHERE MACHINE_ID = :M AND TEETH = :T';
    Qry.ParamByName('M').AsInteger := AMachineID;
    Qry.ParamByName('T').AsInteger := ATeeth;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

function TMachineCylinderRepository.IsAssigned(const AMachineID, ATeeth: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT COUNT(*) FROM MACHINE_CYLINDER WHERE MACHINE_ID = :M AND TEETH = :T';
    Qry.ParamByName('M').AsInteger := AMachineID;
    Qry.ParamByName('T').AsInteger := ATeeth;
    Qry.Open;
    Result := Qry.Fields[0].AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

function TMachineCylinderRepository.SetAssignments(
  const AMachineID: Integer;
  const ATeethList: TArray<Integer>
): Boolean;
var
  Qry: TFDQuery;
  T: Integer;
begin
  Result := False;
  GetConn.StartTransaction;
  try
    Qry := CreateQuery;
    try
      // Clear current assignments
      Qry.SQL.Text := 'DELETE FROM MACHINE_CYLINDER WHERE MACHINE_ID = :M';
      Qry.ParamByName('M').AsInteger := AMachineID;
      Qry.ExecSQL;

      // Insert new
      Qry.SQL.Text := 'INSERT INTO MACHINE_CYLINDER (MACHINE_ID, TEETH) VALUES (:M, :T)';
      for T in ATeethList do
      begin
        Qry.ParamByName('M').AsInteger := AMachineID;
        Qry.ParamByName('T').AsInteger := T;
        Qry.ExecSQL;
      end;
    finally
      Qry.Free;
    end;
    GetConn.Commit;
    Result := True;
  except
    GetConn.Rollback;
    raise;
  end;
end;

{ -----------------------------------------------------------------------------
  TAppSettingRepository
----------------------------------------------------------------------------- }

function TAppSettingRepository.GetAll: TList<TAppSetting>;
var
  Qry: TFDQuery;
  S: TAppSetting;
begin
  Result := TList<TAppSetting>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT SETTING_KEY, SETTING_VALUE, DESCRIPTION FROM APP_SETTING ORDER BY SETTING_KEY';
    Qry.Open;
    while not Qry.Eof do
    begin
      FillChar(S, SizeOf(S), 0);
      S.Key := Qry.FieldByName('SETTING_KEY').AsString;
      S.Value := Qry.FieldByName('SETTING_VALUE').AsString;
      S.Description := Qry.FieldByName('DESCRIPTION').AsString;
      Result.Add(S);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TAppSettingRepository.GetValue(const AKey, ADefault: string): string;
var
  Qry: TFDQuery;
begin
  Result := ADefault;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT SETTING_VALUE FROM APP_SETTING WHERE SETTING_KEY = :K';
    Qry.ParamByName('K').AsString := Trim(AKey);
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.Fields[0].AsString;
  finally
    Qry.Free;
  end;
end;

function TAppSettingRepository.GetInt(const AKey: string; const ADefault: Integer): Integer;
var
  ValStr: string;
begin
  ValStr := GetValue(AKey, '');
  if ValStr <> '' then
    Result := StrToIntDef(ValStr, ADefault)
  else
    Result := ADefault;
end;

function TAppSettingRepository.GetFloat(const AKey: string; const ADefault: Double): Double;
var
  ValStr: string;
begin
  ValStr := GetValue(AKey, '');
  if ValStr <> '' then
    Result := StrToFloatDef(ValStr, ADefault)
  else
    Result := ADefault;
end;

function TAppSettingRepository.SetValue(const AKey, AValue, ADescription: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'UPDATE OR INSERT INTO APP_SETTING (SETTING_KEY, SETTING_VALUE, DESCRIPTION) ' +
      'VALUES (:K, :V, :D) MATCHING (SETTING_KEY)';
    Qry.ParamByName('K').AsString := Trim(AKey);
    Qry.ParamByName('V').AsString := Trim(AValue);
    Qry.ParamByName('D').AsString := Trim(ADescription);
    Qry.ExecSQL;
    Result := True;
  finally
    Qry.Free;
  end;
end;

{ -----------------------------------------------------------------------------
  TDieRepository
----------------------------------------------------------------------------- }

function TDieRepository.MapFromQuery(Qry: TFDQuery): TDie;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.ID := Qry.FieldByName('ID').AsInteger;
  Result.SerialNo := Qry.FieldByName('SERIAL_NO').AsString;
  Result.Description := Qry.FieldByName('DESCRIPTION').AsString;
  Result.InternalRef := Qry.FieldByName('INTERNAL_REF').AsString;
  Result.CustomerRef := Qry.FieldByName('CUSTOMER_REF').AsString;

  if not Qry.FieldByName('CUSTOMER_ID').IsNull then
    Result.CustomerID := Qry.FieldByName('CUSTOMER_ID').AsInteger
  else
    Result.CustomerID := 0;
  Result.CustomerName := Qry.FieldByName('CUSTOMER_NAME').AsString;

  if not Qry.FieldByName('MEDIA_ID').IsNull then
    Result.MediaID := Qry.FieldByName('MEDIA_ID').AsInteger
  else
    Result.MediaID := 0;
  Result.MediaName := Qry.FieldByName('MEDIA_NAME').AsString;

  Result.Teeth := Qry.FieldByName('TEETH').AsInteger;
  Result.PitchUm := Qry.FieldByName('PITCH_UM').AsInteger;
  if Result.PitchUm = 0 then
    Result.PitchUm := 3175;

  Result.RepeatMm := Qry.FieldByName('REPEAT_MM').AsFloat;
  Result.RepeatInch := Qry.FieldByName('REPEAT_INCH').AsFloat;
  Result.AroundSizeMm := Qry.FieldByName('AROUND_SIZE_MM').AsFloat;
  Result.AcrossSizeMm := Qry.FieldByName('ACROSS_SIZE_MM').AsFloat;
  Result.AroundUps := Qry.FieldByName('AROUND_UPS').AsInteger;
  Result.AcrossUps := Qry.FieldByName('ACROSS_UPS').AsInteger;
  Result.AroundGapMm := Qry.FieldByName('AROUND_GAP_MM').AsFloat;
  Result.AcrossGapMm := Qry.FieldByName('ACROSS_GAP_MM').AsFloat;
  Result.CornerRadiusMm := Qry.FieldByName('CORNER_RADIUS_MM').AsFloat;
  Result.Shape := Qry.FieldByName('SHAPE').AsString;
  Result.CutType := Qry.FieldByName('CUT_TYPE').AsString;

  Result.StorageLocation := Qry.FieldByName('STORAGE_LOCATION').AsString;
  Result.StorageRack := Qry.FieldByName('STORAGE_RACK').AsString;
  Result.StorageShelf := Qry.FieldByName('STORAGE_SHELF').AsString;
  Result.StorageBin := Qry.FieldByName('STORAGE_BIN').AsString;

  Result.StatusCode := Qry.FieldByName('STATUS_CODE').AsString;
  Result.StatusName := Qry.FieldByName('STATUS_NAME').AsString;
  Result.BadgeColor := Qry.FieldByName('BADGE_COLOR').AsString;
  Result.OverrideReason := Qry.FieldByName('OVERRIDE_REASON').AsString;
  Result.GapPolicyStatus := Qry.FieldByName('GAP_POLICY_STATUS').AsString;

  if not Qry.FieldByName('PURCHASE_DATE').IsNull then
    Result.PurchaseDate := Qry.FieldByName('PURCHASE_DATE').AsDateTime
  else
    Result.PurchaseDate := 0;

  if not Qry.FieldByName('RECEIVED_DATE').IsNull then
    Result.ReceivedDate := Qry.FieldByName('RECEIVED_DATE').AsDateTime
  else
    Result.ReceivedDate := 0;

  Result.DieMaker := Qry.FieldByName('DIE_MAKER').AsString;
  Result.SupplierRef := Qry.FieldByName('SUPPLIER_REF').AsString;
  Result.TotalRunMetres := Qry.FieldByName('TOTAL_RUN_METRES').AsInteger;
  Result.Notes := Qry.FieldByName('NOTES').AsString;
  Result.Version := Qry.FieldByName('VERSION').AsInteger;
  Result.CreatedBy := Qry.FieldByName('CREATED_BY').AsString;
  Result.CreatedAt := Qry.FieldByName('CREATED_AT').AsDateTime;
  Result.UpdatedBy := Qry.FieldByName('UPDATED_BY').AsString;
  Result.UpdatedAt := Qry.FieldByName('UPDATED_AT').AsDateTime;
end;

function TDieRepository.GetAll: TList<TDie>;
var
  Qry: TFDQuery;
begin
  Result := TList<TDie>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT * FROM V_DIE_CATALOG ORDER BY SERIAL_NO ASC';
    Qry.Open;
    while not Qry.Eof do
    begin
      Result.Add(MapFromQuery(Qry));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TDieRepository.GetByID(const AID: Integer): TDie;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT * FROM V_DIE_CATALOG WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := MapFromQuery(Qry);
  finally
    Qry.Free;
  end;
end;

function TDieRepository.GetBySerial(const ASerialNo: string): TDie;
var
  Qry: TFDQuery;
begin
  FillChar(Result, SizeOf(Result), 0);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT * FROM V_DIE_CATALOG WHERE UPPER(SERIAL_NO) = :S';
    Qry.ParamByName('S').AsString := UpperCase(Trim(ASerialNo));
    Qry.Open;
    if not Qry.IsEmpty then
      Result := MapFromQuery(Qry);
  finally
    Qry.Free;
  end;
end;

function TDieRepository.Search(const AFilter: TDieSearchFilter): TList<TDie>;
var
  Qry: TFDQuery;
  Sql: string;
begin
  Result := TList<TDie>.Create;
  Qry := CreateQuery;
  try
    Sql := 'SELECT * FROM V_DIE_CATALOG WHERE (1 = 1) ';

    if Trim(AFilter.SearchText) <> '' then
    begin
      Sql := Sql +
        ' AND (UPPER(SERIAL_NO) LIKE :ST ' +
        '  OR UPPER(DESCRIPTION) LIKE :ST ' +
        '  OR UPPER(INTERNAL_REF) LIKE :ST ' +
        '  OR UPPER(CUSTOMER_REF) LIKE :ST ' +
        '  OR UPPER(CUSTOMER_NAME) LIKE :ST) ';
    end;

    if AFilter.CustomerID > 0 then
      Sql := Sql + ' AND (CUSTOMER_ID = :CUSTID) ';

    if AFilter.Teeth > 0 then
      Sql := Sql + ' AND (TEETH = :TEETH) ';

    if AFilter.MediaID > 0 then
      Sql := Sql + ' AND (MEDIA_ID = :MEDIAID) ';

    if Trim(AFilter.StatusCode) <> '' then
      Sql := Sql + ' AND (STATUS_CODE = :STATUS) ';

    if Trim(AFilter.Shape) <> '' then
      Sql := Sql + ' AND (SHAPE = :SHAPE) ';

    if Trim(AFilter.StorageLocation) <> '' then
    begin
      Sql := Sql +
        ' AND (UPPER(STORAGE_LOCATION) LIKE :LOC ' +
        '  OR UPPER(STORAGE_RACK) LIKE :LOC ' +
        '  OR UPPER(STORAGE_SHELF) LIKE :LOC ' +
        '  OR UPPER(STORAGE_BIN) LIKE :LOC) ';
    end;

    if AFilter.OnlySub3mm then
      Sql := Sql + ' AND (AROUND_GAP_MM < 3.000) ';

    if AFilter.ActiveOnly then
      Sql := Sql + ' AND (STATUS_CODE IN (''ACTIVE'', ''AVAILABLE'', ''IN_USE'')) ';

    Sql := Sql + ' ORDER BY SERIAL_NO ASC';

    Qry.SQL.Text := Sql;

    if Trim(AFilter.SearchText) <> '' then
      Qry.ParamByName('ST').AsString := '%' + UpperCase(Trim(AFilter.SearchText)) + '%';
    if AFilter.CustomerID > 0 then
      Qry.ParamByName('CUSTID').AsInteger := AFilter.CustomerID;
    if AFilter.Teeth > 0 then
      Qry.ParamByName('TEETH').AsInteger := AFilter.Teeth;
    if AFilter.MediaID > 0 then
      Qry.ParamByName('MEDIAID').AsInteger := AFilter.MediaID;
    if Trim(AFilter.StatusCode) <> '' then
      Qry.ParamByName('STATUS').AsString := Trim(AFilter.StatusCode);
    if Trim(AFilter.Shape) <> '' then
      Qry.ParamByName('SHAPE').AsString := Trim(AFilter.Shape);
    if Trim(AFilter.StorageLocation) <> '' then
      Qry.ParamByName('LOC').AsString := '%' + UpperCase(Trim(AFilter.StorageLocation)) + '%';

    Qry.Open;
    while not Qry.Eof do
    begin
      Result.Add(MapFromQuery(Qry));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TDieRepository.Insert(var ADie: TDie): Integer;
var
  Qry: TFDQuery;
  Audit: TDieAuditEntry;
begin
  Result := 0;
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'INSERT INTO DIE (' +
      '  SERIAL_NO, DESCRIPTION, INTERNAL_REF, CUSTOMER_REF, ' +
      '  CUSTOMER_ID, MEDIA_ID, TEETH, PITCH_UM, ' +
      '  AROUND_SIZE_MM, ACROSS_SIZE_MM, AROUND_UPS, ACROSS_UPS, ' +
      '  ACROSS_GAP_MM, CORNER_RADIUS_MM, SHAPE, CUT_TYPE, ' +
      '  STORAGE_LOCATION, STORAGE_RACK, STORAGE_SHELF, STORAGE_BIN, ' +
      '  STATUS_CODE, OVERRIDE_REASON, PURCHASE_DATE, RECEIVED_DATE, ' +
      '  DIE_MAKER, SUPPLIER_REF, TOTAL_RUN_METRES, NOTES, ' +
      '  CREATED_BY, UPDATED_BY, VERSION' +
      ') VALUES (' +
      '  :SERIAL_NO, :DESCRIPTION, :INTERNAL_REF, :CUSTOMER_REF, ' +
      '  :CUSTOMER_ID, :MEDIA_ID, :TEETH, :PITCH_UM, ' +
      '  :AROUND_SIZE_MM, :ACROSS_SIZE_MM, :AROUND_UPS, :ACROSS_UPS, ' +
      '  :ACROSS_GAP_MM, :CORNER_RADIUS_MM, :SHAPE, :CUT_TYPE, ' +
      '  :STORAGE_LOCATION, :STORAGE_RACK, :STORAGE_SHELF, :STORAGE_BIN, ' +
      '  :STATUS_CODE, :OVERRIDE_REASON, :PURCHASE_DATE, :RECEIVED_DATE, ' +
      '  :DIE_MAKER, :SUPPLIER_REF, :TOTAL_RUN_METRES, :NOTES, ' +
      '  :CREATED_BY, :UPDATED_BY, 1' +
      ') RETURNING ID';

    Qry.ParamByName('SERIAL_NO').AsString := Trim(ADie.SerialNo);
    Qry.ParamByName('DESCRIPTION').AsString := Trim(ADie.Description);
    Qry.ParamByName('INTERNAL_REF').AsString := Trim(ADie.InternalRef);
    Qry.ParamByName('CUSTOMER_REF').AsString := Trim(ADie.CustomerRef);

    if ADie.CustomerID > 0 then
      Qry.ParamByName('CUSTOMER_ID').AsInteger := ADie.CustomerID
    else
      Qry.ParamByName('CUSTOMER_ID').Clear;

    if ADie.MediaID > 0 then
      Qry.ParamByName('MEDIA_ID').AsInteger := ADie.MediaID
    else
      Qry.ParamByName('MEDIA_ID').Clear;

    Qry.ParamByName('TEETH').AsInteger := ADie.Teeth;

    if ADie.PitchUm <= 0 then
      ADie.PitchUm := 3175;
    Qry.ParamByName('PITCH_UM').AsInteger := ADie.PitchUm;

    Qry.ParamByName('AROUND_SIZE_MM').AsFloat := ADie.AroundSizeMm;
    Qry.ParamByName('ACROSS_SIZE_MM').AsFloat := ADie.AcrossSizeMm;
    Qry.ParamByName('AROUND_UPS').AsInteger := ADie.AroundUps;
    Qry.ParamByName('ACROSS_UPS').AsInteger := ADie.AcrossUps;
    Qry.ParamByName('ACROSS_GAP_MM').AsFloat := ADie.AcrossGapMm;
    Qry.ParamByName('CORNER_RADIUS_MM').AsFloat := ADie.CornerRadiusMm;
    Qry.ParamByName('SHAPE').AsString := Trim(ADie.Shape);
    if ADie.CutType <> '' then
      Qry.ParamByName('CUT_TYPE').AsString := Trim(ADie.CutType)
    else
      Qry.ParamByName('CUT_TYPE').AsString := 'ROTARY';

    Qry.ParamByName('STORAGE_LOCATION').AsString := Trim(ADie.StorageLocation);
    Qry.ParamByName('STORAGE_RACK').AsString := Trim(ADie.StorageRack);
    Qry.ParamByName('STORAGE_SHELF').AsString := Trim(ADie.StorageShelf);
    Qry.ParamByName('STORAGE_BIN').AsString := Trim(ADie.StorageBin);

    if Trim(ADie.StatusCode) <> '' then
      Qry.ParamByName('STATUS_CODE').AsString := Trim(ADie.StatusCode)
    else
      Qry.ParamByName('STATUS_CODE').AsString := 'ACTIVE';

    Qry.ParamByName('OVERRIDE_REASON').AsString := Trim(ADie.OverrideReason);

    if ADie.PurchaseDate > 0 then
      Qry.ParamByName('PURCHASE_DATE').AsDate := Trunc(ADie.PurchaseDate)
    else
      Qry.ParamByName('PURCHASE_DATE').Clear;

    if ADie.ReceivedDate > 0 then
      Qry.ParamByName('RECEIVED_DATE').AsDate := Trunc(ADie.ReceivedDate)
    else
      Qry.ParamByName('RECEIVED_DATE').Clear;

    Qry.ParamByName('DIE_MAKER').AsString := Trim(ADie.DieMaker);
    Qry.ParamByName('SUPPLIER_REF').AsString := Trim(ADie.SupplierRef);
    Qry.ParamByName('TOTAL_RUN_METRES').AsInteger := ADie.TotalRunMetres;
    Qry.ParamByName('NOTES').AsString := Trim(ADie.Notes);

    if Trim(ADie.CreatedBy) <> '' then
      Qry.ParamByName('CREATED_BY').AsString := Trim(ADie.CreatedBy)
    else
      Qry.ParamByName('CREATED_BY').AsString := 'OPERATOR';

    if Trim(ADie.UpdatedBy) <> '' then
      Qry.ParamByName('UPDATED_BY').AsString := Trim(ADie.UpdatedBy)
    else
      Qry.ParamByName('UPDATED_BY').AsString := 'OPERATOR';

    Qry.Open;
    Result := Qry.Fields[0].AsInteger;
    ADie.ID := Result;
    ADie.Version := 1;
    Qry.Close;

    // Log Creation Audit Entry
    Audit := TDieAuditEntry.CreateEntry(Result, 'CREATE', 'Die tooling registered', ADie.CreatedBy);
    Audit.OverrideReason := ADie.OverrideReason;
    AddAuditEntry(Audit);
  finally
    Qry.Free;
  end;
end;

function TDieRepository.Update(const ADie: TDie): Boolean;
var
  Qry: TFDQuery;
  Audit: TDieAuditEntry;
begin
  Result := False;
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'UPDATE DIE SET ' +
      '  SERIAL_NO = :SERIAL_NO, ' +
      '  DESCRIPTION = :DESCRIPTION, ' +
      '  INTERNAL_REF = :INTERNAL_REF, ' +
      '  CUSTOMER_REF = :CUSTOMER_REF, ' +
      '  CUSTOMER_ID = :CUSTOMER_ID, ' +
      '  MEDIA_ID = :MEDIA_ID, ' +
      '  TEETH = :TEETH, ' +
      '  PITCH_UM = :PITCH_UM, ' +
      '  AROUND_SIZE_MM = :AROUND_SIZE_MM, ' +
      '  ACROSS_SIZE_MM = :ACROSS_SIZE_MM, ' +
      '  AROUND_UPS = :AROUND_UPS, ' +
      '  ACROSS_UPS = :ACROSS_UPS, ' +
      '  ACROSS_GAP_MM = :ACROSS_GAP_MM, ' +
      '  CORNER_RADIUS_MM = :CORNER_RADIUS_MM, ' +
      '  SHAPE = :SHAPE, ' +
      '  CUT_TYPE = :CUT_TYPE, ' +
      '  STORAGE_LOCATION = :STORAGE_LOCATION, ' +
      '  STORAGE_RACK = :STORAGE_RACK, ' +
      '  STORAGE_SHELF = :STORAGE_SHELF, ' +
      '  STORAGE_BIN = :STORAGE_BIN, ' +
      '  STATUS_CODE = :STATUS_CODE, ' +
      '  OVERRIDE_REASON = :OVERRIDE_REASON, ' +
      '  PURCHASE_DATE = :PURCHASE_DATE, ' +
      '  RECEIVED_DATE = :RECEIVED_DATE, ' +
      '  DIE_MAKER = :DIE_MAKER, ' +
      '  SUPPLIER_REF = :SUPPLIER_REF, ' +
      '  TOTAL_RUN_METRES = :TOTAL_RUN_METRES, ' +
      '  NOTES = :NOTES, ' +
      '  UPDATED_BY = :UPDATED_BY, ' +
      '  UPDATED_AT = CURRENT_TIMESTAMP, ' +
      '  VERSION = VERSION + 1 ' +
      'WHERE ID = :ID AND VERSION = :ORIG_VER';

    Qry.ParamByName('SERIAL_NO').AsString := Trim(ADie.SerialNo);
    Qry.ParamByName('DESCRIPTION').AsString := Trim(ADie.Description);
    Qry.ParamByName('INTERNAL_REF').AsString := Trim(ADie.InternalRef);
    Qry.ParamByName('CUSTOMER_REF').AsString := Trim(ADie.CustomerRef);

    if ADie.CustomerID > 0 then
      Qry.ParamByName('CUSTOMER_ID').AsInteger := ADie.CustomerID
    else
      Qry.ParamByName('CUSTOMER_ID').Clear;

    if ADie.MediaID > 0 then
      Qry.ParamByName('MEDIA_ID').AsInteger := ADie.MediaID
    else
      Qry.ParamByName('MEDIA_ID').Clear;

    Qry.ParamByName('TEETH').AsInteger := ADie.Teeth;

    if ADie.PitchUm <= 0 then
      Qry.ParamByName('PITCH_UM').AsInteger := 3175
    else
      Qry.ParamByName('PITCH_UM').AsInteger := ADie.PitchUm;

    Qry.ParamByName('AROUND_SIZE_MM').AsFloat := ADie.AroundSizeMm;
    Qry.ParamByName('ACROSS_SIZE_MM').AsFloat := ADie.AcrossSizeMm;
    Qry.ParamByName('AROUND_UPS').AsInteger := ADie.AroundUps;
    Qry.ParamByName('ACROSS_UPS').AsInteger := ADie.AcrossUps;
    Qry.ParamByName('ACROSS_GAP_MM').AsFloat := ADie.AcrossGapMm;
    Qry.ParamByName('CORNER_RADIUS_MM').AsFloat := ADie.CornerRadiusMm;
    Qry.ParamByName('SHAPE').AsString := Trim(ADie.Shape);
    if ADie.CutType <> '' then
      Qry.ParamByName('CUT_TYPE').AsString := Trim(ADie.CutType)
    else
      Qry.ParamByName('CUT_TYPE').AsString := 'ROTARY';

    Qry.ParamByName('STORAGE_LOCATION').AsString := Trim(ADie.StorageLocation);
    Qry.ParamByName('STORAGE_RACK').AsString := Trim(ADie.StorageRack);
    Qry.ParamByName('STORAGE_SHELF').AsString := Trim(ADie.StorageShelf);
    Qry.ParamByName('STORAGE_BIN').AsString := Trim(ADie.StorageBin);
    Qry.ParamByName('STATUS_CODE').AsString := Trim(ADie.StatusCode);
    Qry.ParamByName('OVERRIDE_REASON').AsString := Trim(ADie.OverrideReason);

    if ADie.PurchaseDate > 0 then
      Qry.ParamByName('PURCHASE_DATE').AsDate := Trunc(ADie.PurchaseDate)
    else
      Qry.ParamByName('PURCHASE_DATE').Clear;

    if ADie.ReceivedDate > 0 then
      Qry.ParamByName('RECEIVED_DATE').AsDate := Trunc(ADie.ReceivedDate)
    else
      Qry.ParamByName('RECEIVED_DATE').Clear;

    Qry.ParamByName('DIE_MAKER').AsString := Trim(ADie.DieMaker);
    Qry.ParamByName('SUPPLIER_REF').AsString := Trim(ADie.SupplierRef);
    Qry.ParamByName('TOTAL_RUN_METRES').AsInteger := ADie.TotalRunMetres;
    Qry.ParamByName('NOTES').AsString := Trim(ADie.Notes);

    if Trim(ADie.UpdatedBy) <> '' then
      Qry.ParamByName('UPDATED_BY').AsString := Trim(ADie.UpdatedBy)
    else
      Qry.ParamByName('UPDATED_BY').AsString := 'OPERATOR';

    Qry.ParamByName('ID').AsInteger := ADie.ID;
    Qry.ParamByName('ORIG_VER').AsInteger := ADie.Version;

    Qry.ExecSQL;
    Result := (Qry.RowsAffected > 0);

    if Result then
    begin
      Audit := TDieAuditEntry.CreateEntry(ADie.ID, 'UPDATE', 'Die tooling specifications updated', ADie.UpdatedBy);
      Audit.OverrideReason := ADie.OverrideReason;
      AddAuditEntry(Audit);
    end;
  finally
    Qry.Free;
  end;
end;

function TDieRepository.Delete(const AID: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'DELETE FROM DIE WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.ExecSQL;
    Result := (Qry.RowsAffected > 0);
  finally
    Qry.Free;
  end;
end;

function TDieRepository.SerialExists(const ASerialNo: string; const AExcludeID: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT COUNT(*) FROM DIE WHERE UPPER(SERIAL_NO) = :S AND (:EX_ID = 0 OR ID <> :EX_ID)';
    Qry.ParamByName('S').AsString := UpperCase(Trim(ASerialNo));
    Qry.ParamByName('EX_ID').AsInteger := AExcludeID;
    Qry.Open;
    Result := (Qry.Fields[0].AsInteger > 0);
  finally
    Qry.Free;
  end;
end;

function TDieRepository.ChangeStatus(
  const AID: Integer;
  const ANewStatusCode, AReason, AUser: string
): Boolean;
var
  Qry: TFDQuery;
  OldStatus: string;
  Audit: TDieAuditEntry;
begin
  Result := False;
  Qry := CreateQuery;
  try
    // 1. Get old status
    Qry.SQL.Text := 'SELECT STATUS_CODE FROM DIE WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.Open;
    if Qry.IsEmpty then
      Exit;
    OldStatus := Qry.Fields[0].AsString;
    Qry.Close;

    // 2. Update status
    Qry.SQL.Text :=
      'UPDATE DIE SET ' +
      '  STATUS_CODE = :NEW_STATUS, ' +
      '  UPDATED_BY = :USER, ' +
      '  UPDATED_AT = CURRENT_TIMESTAMP, ' +
      '  VERSION = VERSION + 1 ' +
      'WHERE ID = :ID';
    Qry.ParamByName('NEW_STATUS').AsString := Trim(ANewStatusCode);
    Qry.ParamByName('USER').AsString := Trim(AUser);
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.ExecSQL;
    Result := (Qry.RowsAffected > 0);

    if Result then
    begin
      Audit := TDieAuditEntry.CreateEntry(AID, 'STATUS_CHANGE', 'Status changed from ' + OldStatus + ' to ' + ANewStatusCode, AUser);
      Audit.FieldName := 'STATUS_CODE';
      Audit.OldValue := OldStatus;
      Audit.NewValue := ANewStatusCode;
      Audit.OverrideReason := AReason;
      AddAuditEntry(Audit);
    end;
  finally
    Qry.Free;
  end;
end;

function TDieRepository.UpdateLocation(
  const AID: Integer;
  const ARack, AShelf, ABin, ANotes, AUser: string
): Boolean;
var
  Qry: TFDQuery;
  OldLoc: string;
  NewLoc: string;
  Audit: TDieAuditEntry;
begin
  Result := False;
  NewLoc := Format('Rack %s, Shelf %s, Bin %s', [Trim(ARack), Trim(AShelf), Trim(ABin)]);
  Qry := CreateQuery;
  try
    Qry.SQL.Text := 'SELECT STORAGE_LOCATION FROM DIE WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.Open;
    if not Qry.IsEmpty then
      OldLoc := Qry.Fields[0].AsString
    else
      OldLoc := '';
    Qry.Close;

    Qry.SQL.Text :=
      'UPDATE DIE SET ' +
      '  STORAGE_RACK = :RACK, ' +
      '  STORAGE_SHELF = :SHELF, ' +
      '  STORAGE_BIN = :BIN, ' +
      '  STORAGE_LOCATION = :LOC, ' +
      '  UPDATED_BY = :USER, ' +
      '  UPDATED_AT = CURRENT_TIMESTAMP, ' +
      '  VERSION = VERSION + 1 ' +
      'WHERE ID = :ID';
    Qry.ParamByName('RACK').AsString := Trim(ARack);
    Qry.ParamByName('SHELF').AsString := Trim(AShelf);
    Qry.ParamByName('BIN').AsString := Trim(ABin);
    Qry.ParamByName('LOC').AsString := NewLoc;
    Qry.ParamByName('USER').AsString := Trim(AUser);
    Qry.ParamByName('ID').AsInteger := AID;
    Qry.ExecSQL;
    Result := (Qry.RowsAffected > 0);

    if Result then
    begin
      Audit := TDieAuditEntry.CreateEntry(AID, 'LOCATION_CHANGE', 'Storage location moved to ' + NewLoc, AUser);
      Audit.FieldName := 'STORAGE_LOCATION';
      Audit.OldValue := OldLoc;
      Audit.NewValue := NewLoc;
      Audit.Details := ANotes;
      AddAuditEntry(Audit);
    end;
  finally
    Qry.Free;
  end;
end;

function TDieRepository.FindSimilarDies(
  const ATeeth: Integer;
  const AAroundSizeMm, AAcrossSizeMm: Double;
  const AAroundUps, AAcrossUps: Integer;
  const AShape: string;
  const AToleranceMm: Double;
  const AExcludeID: Integer
): TList<TSimilarDieResult>;
var
  Qry: TFDQuery;
  Item: TSimilarDieResult;
  AroundDiff, AcrossDiff: Double;
begin
  Result := TList<TSimilarDieResult>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT * FROM V_DIE_CATALOG ' +
      'WHERE TEETH = :TEETH ' +
      '  AND SHAPE = :SHAPE ' +
      '  AND ABS(AROUND_SIZE_MM - :AROUND) <= :TOL ' +
      '  AND ABS(ACROSS_SIZE_MM - :ACROSS) <= :TOL ' +
      '  AND (:EX_ID = 0 OR ID <> :EX_ID) ' +
      'ORDER BY (ABS(AROUND_SIZE_MM - :AROUND) + ABS(ACROSS_SIZE_MM - :ACROSS)) ASC';

    Qry.ParamByName('TEETH').AsInteger := ATeeth;
    Qry.ParamByName('SHAPE').AsString := Trim(AShape);
    Qry.ParamByName('AROUND').AsFloat := AAroundSizeMm;
    Qry.ParamByName('ACROSS').AsFloat := AAcrossSizeMm;
    Qry.ParamByName('TOL').AsFloat := AToleranceMm;
    Qry.ParamByName('EX_ID').AsInteger := AExcludeID;

    Qry.Open;
    while not Qry.Eof do
    begin
      Item.Die := MapFromQuery(Qry);
      AroundDiff := Abs(Item.Die.AroundSizeMm - AAroundSizeMm);
      AcrossDiff := Abs(Item.Die.AcrossSizeMm - AAcrossSizeMm);
      Item.AroundDiffMm := AroundDiff;
      Item.AcrossDiffMm := AcrossDiff;

      if (AroundDiff < 0.001) and (AcrossDiff < 0.001) and
         (Item.Die.AroundUps = AAroundUps) and (Item.Die.AcrossUps = AAcrossUps) then
      begin
        Item.MatchType := smtExact;
        Item.MatchDescription := 'Exact geometry match';
      end
      else if (Item.Die.AroundUps = AAroundUps) and (Item.Die.AcrossUps = AAcrossUps) then
      begin
        Item.MatchType := smtReusableAlternative;
        Item.MatchDescription := Format('Compatible ups; diff around %0.2fmm, across %0.2fmm', [AroundDiff, AcrossDiff]);
      end
      else
      begin
        Item.MatchType := smtIncompatible;
        Item.MatchDescription := Format('Ups mismatch: existing %dx%d (requested %dx%d)', [Item.Die.AroundUps, Item.Die.AcrossUps, AAroundUps, AAcrossUps]);
      end;

      Result.Add(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TDieRepository.GetAuditLog(const ADieID: Integer): TList<TDieAuditEntry>;
var
  Qry: TFDQuery;
  Entry: TDieAuditEntry;
begin
  Result := TList<TDieAuditEntry>.Create;
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'SELECT * FROM DIE_AUDIT_LOG WHERE DIE_ID = :ID ORDER BY CHANGED_AT DESC, ID DESC';
    Qry.ParamByName('ID').AsInteger := ADieID;
    Qry.Open;
    while not Qry.Eof do
    begin
      FillChar(Entry, SizeOf(Entry), 0);
      Entry.ID := Qry.FieldByName('ID').AsInteger;
      Entry.DieID := Qry.FieldByName('DIE_ID').AsInteger;
      Entry.Action := Qry.FieldByName('ACTION').AsString;
      Entry.FieldName := Qry.FieldByName('FIELD_NAME').AsString;
      Entry.OldValue := Qry.FieldByName('OLD_VALUE').AsString;
      Entry.NewValue := Qry.FieldByName('NEW_VALUE').AsString;
      Entry.OverrideReason := Qry.FieldByName('OVERRIDE_REASON').AsString;
      Entry.Details := Qry.FieldByName('DETAILS').AsString;
      Entry.ChangedBy := Qry.FieldByName('CHANGED_BY').AsString;
      Entry.ChangedAt := Qry.FieldByName('CHANGED_AT').AsDateTime;
      Result.Add(Entry);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TDieRepository.AddAuditEntry(const AEntry: TDieAuditEntry): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := CreateQuery;
  try
    Qry.SQL.Text :=
      'INSERT INTO DIE_AUDIT_LOG (' +
      '  DIE_ID, ACTION, FIELD_NAME, OLD_VALUE, NEW_VALUE, OVERRIDE_REASON, DETAILS, CHANGED_BY, CHANGED_AT' +
      ') VALUES (' +
      '  :DIE_ID, :ACTION, :FIELD_NAME, :OLD_VALUE, :NEW_VALUE, :OVERRIDE_REASON, :DETAILS, :CHANGED_BY, CURRENT_TIMESTAMP' +
      ')';
    Qry.ParamByName('DIE_ID').AsInteger := AEntry.DieID;
    Qry.ParamByName('ACTION').AsString := Trim(AEntry.Action);
    Qry.ParamByName('FIELD_NAME').AsString := Trim(AEntry.FieldName);
    Qry.ParamByName('OLD_VALUE').AsString := Trim(AEntry.OldValue);
    Qry.ParamByName('NEW_VALUE').AsString := Trim(AEntry.NewValue);
    Qry.ParamByName('OVERRIDE_REASON').AsString := Trim(AEntry.OverrideReason);
    Qry.ParamByName('DETAILS').AsString := Trim(AEntry.Details);
    if Trim(AEntry.ChangedBy) <> '' then
      Qry.ParamByName('CHANGED_BY').AsString := Trim(AEntry.ChangedBy)
    else
      Qry.ParamByName('CHANGED_BY').AsString := 'OPERATOR';

    Qry.ExecSQL;
    Result := True;
  finally
    Qry.Free;
  end;
end;

function TDieRepository.SmartSearchDies(
  const AFilter: TSmartDieSizeFilter;
  out ATotalCount: Integer
): TList<TSmartDieSearchResult>;
var
  Qry: TFDQuery;
  Sql: string;
  TargetAroundUm, TargetAcrossUm, TolUm: Int64;
  MinAroundMm, MaxAroundMm: Double;
  MinAcrossMm, MaxAcrossMm: Double;
  Die: TDie;
  DieAroundUm, DieAcrossUm: Int64;
  DiffAroundUm, DiffAcrossUm: Int64;
  AbsAroundUm, AbsAcrossUm: Int64;
  MatchClass: TSmartDieMatchClass;
  MatchClassName: string;
  ReusabilityNote: string;
  Item: TSmartDieSearchResult;
  Candidates: TList<TSmartDieSearchResult>;
  I, StartIdx, EndIdx: Integer;
begin
  Result := TList<TSmartDieSearchResult>.Create;
  ATotalCount := 0;

  TargetAroundUm := Round(AFilter.TargetAroundMm * 1000.0);
  TargetAcrossUm := Round(AFilter.TargetAcrossMm * 1000.0);
  TolUm := Round(AFilter.ToleranceMm * 1000.0);
  if TolUm <= 0 then
    TolUm := 2000;

  MinAroundMm := (TargetAroundUm - TolUm) / 1000.0;
  MaxAroundMm := (TargetAroundUm + TolUm) / 1000.0;
  MinAcrossMm := (TargetAcrossUm - TolUm) / 1000.0;
  MaxAcrossMm := (TargetAcrossUm + TolUm) / 1000.0;

  Candidates := TList<TSmartDieSearchResult>.Create;
  Qry := CreateQuery;
  try
    Sql := 'SELECT * FROM V_DIE_CATALOG ' +
           'WHERE (AROUND_SIZE_MM >= :MIN_AROUND AND AROUND_SIZE_MM <= :MAX_AROUND) ';

    if not AFilter.IncludeSlitting then
      Sql := Sql + ' AND (ACROSS_SIZE_MM >= :MIN_ACROSS AND ACROSS_SIZE_MM <= :MAX_ACROSS) '
    else
      Sql := Sql + ' AND (ACROSS_SIZE_MM >= :MIN_ACROSS) ';

    if AFilter.Teeth > 0 then
      Sql := Sql + ' AND (TEETH = :TEETH) ';

    if AFilter.MachineID > 0 then
      Sql := Sql + ' AND (TEETH IN (SELECT TEETH FROM MACHINE_CYLINDER WHERE MACHINE_ID = :MACH_ID)) ';

    if AFilter.ActiveOnly then
      Sql := Sql + ' AND (STATUS_CODE IN (''ACTIVE'', ''AVAILABLE'', ''IN_USE'')) '
    else if Trim(AFilter.StatusCode) <> '' then
      Sql := Sql + ' AND (STATUS_CODE = :STATUS_CODE) ';

    if Trim(AFilter.Shape) <> '' then
      Sql := Sql + ' AND (UPPER(SHAPE) = :SHAPE) ';

    if Trim(AFilter.CutType) <> '' then
      Sql := Sql + ' AND (UPPER(CUT_TYPE) = :CUT_TYPE) ';

    if AFilter.CornerRadiusMm >= 0 then
      Sql := Sql + ' AND (ABS(CORNER_RADIUS_MM - :CR_TARGET) <= :CR_TOL) ';

    Qry.SQL.Text := Sql;

    Qry.ParamByName('MIN_AROUND').AsFloat := MinAroundMm;
    Qry.ParamByName('MAX_AROUND').AsFloat := MaxAroundMm;
    Qry.ParamByName('MIN_ACROSS').AsFloat := MinAcrossMm;
    if not AFilter.IncludeSlitting then
      Qry.ParamByName('MAX_ACROSS').AsFloat := MaxAcrossMm;

    if AFilter.Teeth > 0 then
      Qry.ParamByName('TEETH').AsInteger := AFilter.Teeth;

    if AFilter.MachineID > 0 then
      Qry.ParamByName('MACH_ID').AsInteger := AFilter.MachineID;

    if (not AFilter.ActiveOnly) and (Trim(AFilter.StatusCode) <> '') then
      Qry.ParamByName('STATUS_CODE').AsString := Trim(AFilter.StatusCode);

    if Trim(AFilter.Shape) <> '' then
      Qry.ParamByName('SHAPE').AsString := UpperCase(Trim(AFilter.Shape));

    if Trim(AFilter.CutType) <> '' then
      Qry.ParamByName('CUT_TYPE').AsString := UpperCase(Trim(AFilter.CutType));

    if AFilter.CornerRadiusMm >= 0 then
    begin
      Qry.ParamByName('CR_TARGET').AsFloat := AFilter.CornerRadiusMm;
      Qry.ParamByName('CR_TOL').AsFloat := AFilter.CornerRadiusTolMm;
    end;

    Qry.Open;
    while not Qry.Eof do
    begin
      Die := MapFromQuery(Qry);
      DieAroundUm := Round(Die.AroundSizeMm * 1000.0);
      DieAcrossUm := Round(Die.AcrossSizeMm * 1000.0);
      DiffAroundUm := DieAroundUm - TargetAroundUm;
      DiffAcrossUm := DieAcrossUm - TargetAcrossUm;
      AbsAroundUm := Abs(DiffAroundUm);
      AbsAcrossUm := Abs(DiffAcrossUm);

      if AbsAroundUm <= TolUm then
      begin
        if (AbsAroundUm = 0) and (AbsAcrossUm = 0) then
        begin
          MatchClass := sdmExactMatch;
          MatchClassName := '1. Exact Dimension Match';
          ReusabilityNote := 'Exact label size match. Geometrical match only — verify web layout, machine clearance & cavity gap before production.';
        end
        else if (AbsAroundUm <= 1000) and (AbsAcrossUm <= 1000) then
        begin
          MatchClass := sdmNearMatchTier1;
          MatchClassName := '2. Near Match (Within ±1.0mm)';
          ReusabilityNote := 'Near label size within ±1.0mm. Geometrical candidate — customer artwork & dimensional approval required.';
        end
        else if (AbsAroundUm <= TolUm) and (AbsAcrossUm <= TolUm) then
        begin
          MatchClass := sdmNearMatchTier2;
          MatchClassName := Format('3. Near Match (Within ±%0.1fmm)', [AFilter.ToleranceMm]);
          ReusabilityNote := Format('Near dimensions within ±%0.1fmm tolerance. Customer dimensional approval & keyline sign-off required.', [AFilter.ToleranceMm]);
        end
        else if AFilter.IncludeSlitting and (DieAcrossUm >= TargetAcrossUm) then
        begin
          MatchClass := sdmSlittingCandidate;
          MatchClassName := '4. Slitting Candidate (Review Required)';
          ReusabilityNote := 'Across width or lane count differs — REVIEW REQUIRED: A larger Across Size is not sufficient proof of compatibility; inspect actual lane and cut geometry before marking reusable.';
        end
        else
          MatchClass := sdmExcluded;

        if MatchClass <> sdmExcluded then
        begin
          FillChar(Item, SizeOf(Item), 0);
          Item.Die := Die;
          Item.AroundDiffUm := DiffAroundUm;
          Item.AcrossDiffUm := DiffAcrossUm;
          Item.AbsAroundDiffUm := AbsAroundUm;
          Item.AbsAcrossDiffUm := AbsAcrossUm;
          Item.AroundDiffMm := DiffAroundUm / 1000.0;
          Item.AcrossDiffMm := DiffAcrossUm / 1000.0;
          Item.MatchClass := MatchClass;
          Item.MatchClassName := MatchClassName;
          Item.ReusabilityNote := ReusabilityNote;
          Candidates.Add(Item);
        end;
      end;

      Qry.Next;
    end;

    // Sort order: MatchClass ASC, Around proximity ASC, Across proximity ASC, Teeth, SerialNo
    Candidates.Sort(TComparer<TSmartDieSearchResult>.Construct(
      function(const Left, Right: TSmartDieSearchResult): Integer
      begin
        if Left.MatchClass <> Right.MatchClass then
          Exit(Ord(Left.MatchClass) - Ord(Right.MatchClass));

        if Left.AbsAroundDiffUm <> Right.AbsAroundDiffUm then
          Exit(Left.AbsAroundDiffUm - Right.AbsAroundDiffUm);

        if Left.AbsAcrossDiffUm <> Right.AbsAcrossDiffUm then
          Exit(Left.AbsAcrossDiffUm - Right.AbsAcrossDiffUm);

        if Left.Die.Teeth <> Right.Die.Teeth then
          Exit(Left.Die.Teeth - Right.Die.Teeth);

        Result := CompareStr(Left.Die.SerialNo, Right.Die.SerialNo);
      end
    ));

    ATotalCount := Candidates.Count;

    if (AFilter.Page > 0) and (AFilter.PageSize > 0) then
    begin
      StartIdx := (AFilter.Page - 1) * AFilter.PageSize;
      EndIdx := StartIdx + AFilter.PageSize - 1;
      if EndIdx >= Candidates.Count then
        EndIdx := Candidates.Count - 1;

      for I := StartIdx to EndIdx do
        Result.Add(Candidates[I]);
    end
    else
    begin
      for I := 0 to Candidates.Count - 1 do
        Result.Add(Candidates[I]);
    end;

  finally
    Candidates.Free;
    Qry.Free;
  end;
end;

end.
