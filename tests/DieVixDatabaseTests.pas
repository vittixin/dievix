unit DieVixDatabaseTests;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  DUnitX Integration Test Suite: Firebird 5.0, FireDAC, Repositories & Services
  Operates on disposable test database: dievix_disposable_test.fdb
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  DieVix.Domain,
  DieVix.ConnectionManager,
  DieVix.Repositories,
  DieVix.MasterDataService;

type
  [TestFixture]
  TDieVixDatabaseTests = class
  private
    FConn: TFDConnection;
    FService: TMasterDataService;
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FCylinderRepo: ICylinderRepository;
    FMachineRepo: IMachineRepository;
    FMachineCylinderRepo: IMachineCylinderRepository;
    FSettingRepo: IAppSettingRepository;
  public
    [SetupFixture]
    procedure SetupFixture;

    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure TestFireDACConnection;

    [Test]
    procedure TestCylinderFleetSeededSixteenSizes;

    [Test]
    procedure TestDuplicateCylinderTeethRejected;

    [Test]
    procedure TestCustomerCrudLifecycle;

    [Test]
    procedure TestDuplicateCustomerCodeRejected;

    [Test]
    procedure TestMediaCrudLifecycle;

    [Test]
    procedure TestMachineCrudAndValidation;

    [Test]
    procedure TestMachineCylinderAssignmentMatrix;

    [Test]
    procedure TestTransactionRollbackIntegrity;

    [Test]
    procedure TestExactNumericRoundTrip;

    [Test]
    procedure TestApplicationSettingsPersistence;
  end;

implementation

{ TDieVixDatabaseTests }

procedure TDieVixDatabaseTests.SetupFixture;
var
  Mgr: TDieVixConnectionManager;
  Cfg: TDatabaseConfig;
begin
  Mgr := TDieVixConnectionManager.Instance;
  Cfg := TDatabaseConfig.DefaultServer;
  Cfg.Database := 'D:\ketan\github\DieVix\tmp\dievix_disposable_test.fdb';
  Cfg.UserName := 'SYSDBA';
  Cfg.Password := 'masterkey';
  Cfg.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll';
  Mgr.Config := Cfg;

  FConn := Mgr.GetConnection;

  FCustomerRepo := TCustomerRepository.Create(FConn);
  FMediaRepo := TMediaRepository.Create(FConn);
  FCylinderRepo := TCylinderRepository.Create(FConn);
  FMachineRepo := TMachineRepository.Create(FConn);
  FMachineCylinderRepo := TMachineCylinderRepository.Create(FConn);
  FSettingRepo := TAppSettingRepository.Create(FConn);

  FService := TMasterDataService.Create(
    FCustomerRepo, FMediaRepo, nil, FCylinderRepo, FMachineRepo, FMachineCylinderRepo, FSettingRepo
  );
end;

procedure TDieVixDatabaseTests.TearDownFixture;
begin
  FService.Free;
end;

procedure TDieVixDatabaseTests.TestFireDACConnection;
begin
  Assert.IsNotNull(FConn, 'Connection object must be allocated');
  Assert.IsTrue(FConn.Connected, 'FireDAC must be connected to Firebird 5');
end;

procedure TDieVixDatabaseTests.TestCylinderFleetSeededSixteenSizes;
var
  Cyls: TList<TCylinder>;
  Expected: TArray<Integer>;
  I: Integer;
begin
  Expected := [66, 68, 72, 76, 82, 86, 90, 94, 96, 98, 102, 106, 112, 120, 126, 132];
  Cyls := FService.GetAllCylinders(False);
  try
    Assert.AreEqual(16, Cyls.Count, 'Fleet must contain exactly 16 seeded sizes');
    for I := 0 to 15 do
    begin
      Assert.AreEqual(Expected[I], Cyls[I].Teeth, Format('Index %d must be %dT', [I, Expected[I]]));
      Assert.AreEqual(3175, Cyls[I].PitchUm, 'Default pitch must be 3175 um');
      Assert.IsTrue(Cyls[I].RepeatMm > 0.0, 'Repeat mm must be positive');
    end;
  finally
    Cyls.Free;
  end;
end;

procedure TDieVixDatabaseTests.TestDuplicateCylinderTeethRejected;
var
  DupCyl: TCylinder;
  ExceptionThrown: Boolean;
begin
  DupCyl := TCylinder.CreateNew(96, 3175);
  ExceptionThrown := False;
  try
    FService.SaveCylinder(DupCyl, True); // IsNew = True
  except
    on E: EDieVixValidationException do
      ExceptionThrown := True;
  end;

  Assert.IsTrue(ExceptionThrown, 'Inserting duplicate cylinder teeth must raise validation exception');
end;

procedure TDieVixDatabaseTests.TestCustomerCrudLifecycle;
var
  Cust: TCustomer;
  NewID: Integer;
  Fetched: TCustomer;
begin
  Cust := TCustomer.CreateNew('TEST-CUST01', 'Test Customer Pvt Ltd');
  Cust.ContactPerson := 'John Doe';
  Cust.Phone := '+91 9876543210';
  Cust.City := 'Ahmedabad';

  NewID := FService.SaveCustomer(Cust);
  Assert.IsTrue(NewID > 0, 'Customer ID must be generated');

  Fetched := FCustomerRepo.GetByID(NewID);
  Assert.AreEqual('TEST-CUST01', Fetched.Code);
  Assert.AreEqual('Test Customer Pvt Ltd', Fetched.Name);
  Assert.AreEqual('John Doe', Fetched.ContactPerson);

  // Update
  Fetched.ContactPerson := 'Jane Smith';
  FService.SaveCustomer(Fetched);

  Fetched := FCustomerRepo.GetByID(NewID);
  Assert.AreEqual('Jane Smith', Fetched.ContactPerson);

  // Clean up
  Assert.IsTrue(FService.DeleteCustomer(NewID), 'Delete must succeed');
end;

procedure TDieVixDatabaseTests.TestDuplicateCustomerCodeRejected;
var
  C1, C2: TCustomer;
  ID1: Integer;
  ExceptionThrown: Boolean;
begin
  C1 := TCustomer.CreateNew('DUP-CODE', 'First Company');
  ID1 := FService.SaveCustomer(C1);

  C2 := TCustomer.CreateNew('DUP-CODE', 'Second Company');
  ExceptionThrown := False;
  try
    FService.SaveCustomer(C2);
  except
    on E: EDieVixValidationException do
      ExceptionThrown := True;
  end;

  FService.DeleteCustomer(ID1);
  Assert.IsTrue(ExceptionThrown, 'Duplicate customer code must be rejected');
end;

procedure TDieVixDatabaseTests.TestMediaCrudLifecycle;
var
  M: TMedia;
  NewID: Integer;
  Fetched: TMedia;
begin
  M := TMedia.CreateNew('TEST-POLY', 'Poly White Test Substrate');
  M.FaceMaterial := 'Polypropylene 50um';
  M.LinerMaterial := 'PET 23um';
  M.TotalCaliperUm := 85;

  NewID := FService.SaveMedia(M);
  Assert.IsTrue(NewID > 0, 'Media ID must be generated');

  Fetched := FMediaRepo.GetByID(NewID);
  Assert.AreEqual('TEST-POLY', Fetched.Code);
  Assert.AreEqual(85, Fetched.TotalCaliperUm);

  Assert.IsTrue(FService.DeleteMedia(NewID));
end;

procedure TDieVixDatabaseTests.TestMachineCrudAndValidation;
var
  Mach: TMachine;
  NewID: Integer;
  InvalidMach: TMachine;
  ExceptionThrown: Boolean;
begin
  Mach := TMachine.CreateNew('TEST-M01', 'Test Flexo 10"', 254.0);
  Mach.MinWebWidthMm := 60.0;
  Mach.DefaultMarginMm := 4.0;
  NewID := FService.SaveMachine(Mach);
  Assert.IsTrue(NewID > 0, 'Machine ID must be generated');

  // Test validation: max web < min web
  InvalidMach := TMachine.CreateNew('TEST-ERR', 'Invalid Machine', 50.0);
  InvalidMach.MinWebWidthMm := 100.0; // Error: max < min
  ExceptionThrown := False;
  try
    FService.SaveMachine(InvalidMach);
  except
    on E: EDieVixValidationException do
      ExceptionThrown := True;
  end;
  Assert.IsTrue(ExceptionThrown, 'Max web width < Min web width must be rejected');

  FService.DeleteMachine(NewID);
end;

procedure TDieVixDatabaseTests.TestMachineCylinderAssignmentMatrix;
var
  Mach: TMachine;
  MachID: Integer;
  Assigned: TList<Integer>;
begin
  Mach := TMachine.CreateNew('MATRIX-M1', 'Matrix Press Test', 254.0);
  MachID := FService.SaveMachine(Mach);

  // Assign 66, 96, 112
  FService.SaveMachineCylinderAssignments(MachID, [66, 96, 112]);

  Assigned := FService.GetAssignedCylindersForMachine(MachID);
  try
    Assert.AreEqual(3, Assigned.Count);
    Assert.AreEqual(66, Assigned[0]);
    Assert.AreEqual(96, Assigned[1]);
    Assert.AreEqual(112, Assigned[2]);
  finally
    Assigned.Free;
  end;

  // Toggle off 66
  FService.ToggleAssignment(MachID, 66, False);
  Assert.IsFalse(FMachineCylinderRepo.IsAssigned(MachID, 66));
  Assert.IsTrue(FMachineCylinderRepo.IsAssigned(MachID, 96));

  FService.DeleteMachine(MachID);
end;

procedure TDieVixDatabaseTests.TestTransactionRollbackIntegrity;
var
  Cust: TCustomer;
  CheckCust: TCustomer;
begin
  FConn.StartTransaction;
  try
    Cust := TCustomer.CreateNew('ROLLBACK-CUST', 'Rollback Candidate');
    FCustomerRepo.Insert(Cust);
    // Explicit rollback
    FConn.Rollback;
  except
    FConn.Rollback;
  end;

  CheckCust := FCustomerRepo.GetByCode('ROLLBACK-CUST');
  Assert.AreEqual(0, CheckCust.ID, 'Record must not exist after transaction rollback');
end;

procedure TDieVixDatabaseTests.TestExactNumericRoundTrip;
var
  Mach: TMachine;
  MachID: Integer;
  Fetched: TMachine;
begin
  // NUMERIC(9,3) exact 3 decimal places
  Mach := TMachine.CreateNew('NUM-TEST', 'Numeric Precision Press', 330.125);
  Mach.MinWebWidthMm := 75.375;
  Mach.DefaultMarginMm := 4.875;
  MachID := FService.SaveMachine(Mach);

  Fetched := FMachineRepo.GetByID(MachID);
  Assert.AreEqual(330.125, Fetched.MaxWebWidthMm, 0.0001);
  Assert.AreEqual(75.375, Fetched.MinWebWidthMm, 0.0001);
  Assert.AreEqual(4.875, Fetched.DefaultMarginMm, 0.0001);

  FService.DeleteMachine(MachID);
end;

procedure TDieVixDatabaseTests.TestApplicationSettingsPersistence;
var
  MinGap: Int64;
  HardBlock: Int64;
begin
  MinGap := FService.GetMinAroundGapUm;
  Assert.AreEqual(Int64(3000), MinGap, 'Default min around gap must be 3000 um (3.0 mm)');

  HardBlock := FService.GetHardBlockGapUm;
  Assert.AreEqual(Int64(0), HardBlock, 'Default hard block must be 0 (disabled)');

  // Save new settings
  FService.SaveSettings(3500, 2000, 3.5, 2.5);
  Assert.AreEqual(Int64(3500), FService.GetMinAroundGapUm);
  Assert.AreEqual(Int64(2000), FService.GetHardBlockGapUm);
  Assert.AreEqual(3.5, FService.GetDefaultAcrossGapMm, 0.001);

  // Restore defaults
  FService.SaveSettings(3000, 0, 3.0, 2.0);
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixDatabaseTests);

end.
