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

end.
