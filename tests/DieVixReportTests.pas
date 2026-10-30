unit DieVixReportTests;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  DUnitX Test Suite: Phase 5 VittixReport Reporting & Export Architecture
  
  Validates automated generation and headless vector PDF and Excel XLSX exports for:
    1. Die Tooling Job Bag Card (die_tooling_card.vrt)
    2. Die Master Register Catalog (die_register_catalog.vrt)
    3. Machine Fleet Cylinder Tooling Matrix (cylinder_fleet_matrix.vrt)
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  DieVix.Domain,
  DieVix.ConnectionManager,
  DieVix.Repositories,
  DieVix.DieService,
  DieVix.ReportService,
  DieVix.CalculationEngine;

type
  [TestFixture]
  TDieVixReportTests = class
  private
    FConn: TFDConnection;
    FReportService: TDieVixReportService;
    FDieService: TDieService;
    FDieRepo: IDieRepository;
    FCustomerRepo: ICustomerRepository;
    FMediaRepo: IMediaRepository;
    FCylinderRepo: ICylinderRepository;
    FStatusRepo: IDieStatusRepository;
    FSettingRepo: IAppSettingRepository;
    FFlatbedRepo: IFlatbedDieRepository;
    FTestDieID: Integer;
    FFlatbedDieID: Integer;
    FTestCustID: Integer;
    FTestMediaID: Integer;
    FOutDir: string;
    function ReadFileSignature(const AFilePath: string; const ACount: Integer): TBytes;
  public
    [SetupFixture]
    procedure SetupFixture;

    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure Test01_ExportToolingCardPdf;

    [Test]
    procedure Test02_ExportRegisterCatalogPdf;

    [Test]
    procedure Test03_ExportRegisterCatalogXlsx;

    [Test]
    procedure Test04_ExportFleetMatrixPdf;

    [Test]
    procedure Test05_ExportFleetMatrixXlsx;

    [Test]
    procedure Test06_FilteredCatalogReportPdf;

    [Test]
    procedure Test07_NonExistentDieThrowsException;

    [Test]
    procedure Test08_TemplateResolutionAndEmbeddedFallback;

    [Test]
    procedure Test09_ExportFlatbedToolingCardPdf;

    [Test]
    procedure Test10_ExportFlatbedRegisterCatalogPdf;

    [Test]
    procedure Test11_ExportFlatbedRegisterCatalogXlsx;

    [Test]
    procedure Test12_FilteredFlatbedCatalogReportPdf;

    [Test]
    procedure Test13_FlatbedEmbeddedFallback;
  end;

implementation

function TDieVixReportTests.ReadFileSignature(const AFilePath: string; const ACount: Integer): TBytes;
var
  FS: TFileStream;
  BytesToRead: Integer;
begin
  SetLength(Result, 0);
  if not TFile.Exists(AFilePath) then Exit;
  FS := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
  try
    BytesToRead := ACount;
    if BytesToRead > FS.Size then
      BytesToRead := FS.Size;
    SetLength(Result, BytesToRead);
    if BytesToRead > 0 then
      FS.ReadBuffer(Result[0], BytesToRead);
  finally
    FS.Free;
  end;
end;

procedure TDieVixReportTests.SetupFixture;
var
  Mgr: TDieVixConnectionManager;
  AppCount: Integer;
  LogStr: string;
  Cust: TCustomer;
  Med: TMedia;
  Die: TDie;
  FBDie: TFlatbedDie;
begin
  Mgr := TDieVixConnectionManager.Instance;
  FConn := Mgr.GetConnection;

  // Apply migrations if not already applied
  Mgr.ApplyMigrations(
    TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\migrations')),
    AppCount,
    LogStr
  );

  // Setup repositories
  FCustomerRepo := TCustomerRepository.Create(FConn);
  FMediaRepo := TMediaRepository.Create(FConn);
  FCylinderRepo := TCylinderRepository.Create(FConn);
  FStatusRepo := TDieStatusRepository.Create(FConn);
  FSettingRepo := TAppSettingRepository.Create(FConn);
  FDieRepo := TDieRepository.Create(FConn);
  FFlatbedRepo := TFlatbedDieRepository.Create(FConn);

  FDieService := TDieService.Create(
    FDieRepo, FSettingRepo, FCustomerRepo, FMediaRepo, FCylinderRepo, FStatusRepo
  );

  FReportService := TDieVixReportService.Create(FConn);

  // Output directory for test exports
  FOutDir := TPath.Combine(TPath.GetTempPath, 'DieVixReportTests_' + FormatDateTime('yyyymmdd_hhnnss', Now));
  if not TDirectory.Exists(FOutDir) then
    TDirectory.CreateDirectory(FOutDir);

  // Clean up any old test dies
  FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-REP-%'')');
  FConn.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-REP-%''');
  FConn.ExecSQL('DELETE FROM FLATBED_DIE_AUDIT_LOG WHERE DIE_SERIAL_NO LIKE ''ZZTEST-FB-%''');
  FConn.ExecSQL('DELETE FROM FLATBED_DIE WHERE SERIAL_NO LIKE ''ZZTEST-FB-%''');
  FConn.ExecSQL('DELETE FROM CUSTOMER WHERE CODE = ''ZZTEST_CUST_REP''');
  FConn.ExecSQL('DELETE FROM MEDIA WHERE CODE = ''ZZTEST_MED_REP''');

  // Create test customer
  Cust := TCustomer.CreateNew('ZZTEST_CUST_REP', 'PharmaCare Solutions Ltd');
  Cust.ContactPerson := 'Sarah Jenkins';
  Cust.City := 'Manchester';
  FTestCustID := FCustomerRepo.Insert(Cust);

  // Create test media
  Med := TMedia.CreateNew('ZZTEST_MED_REP', 'Gloss White PP 60um / Glassine');
  Med.FaceMaterial := 'Polypropylene 60um';
  Med.LinerMaterial := 'Glassine 54gsm';
  Med.AdhesiveType := 'Permanent Acrylic';
  Med.TotalCaliperUm := 125;
  FTestMediaID := FMediaRepo.Insert(Med);

  // Create test tooling die
  Die := TDie.CreateNew(
    'ZZTEST-REP-001',
    96,           // Teeth
    98.000,       // AroundSizeMm
    48.000,       // AcrossSizeMm
    3,            // AroundUps
    3             // AcrossUps
  );
  Die.AcrossGapMm := 2.500;
  Die.CornerRadiusMm := 1.500;
  Die.Shape := 'RECTANGLE';
  Die.CustomerID := FTestCustID;
  Die.MediaID := FTestMediaID;
  Die.CutType := 'ROTARY';
  Die.StatusCode := 'AVAILABLE';
  Die.StorageLocation := 'RACK-B-04';
  Die.StorageRack := 'B';
  Die.StorageShelf := '04';
  Die.StorageBin := '12';
  Die.DieMaker := 'RotoMetrics Tooling GmbH';
  Die.SupplierRef := 'RM-99421-A';
  Die.Notes := 'Phase 5 VittixReport Verification Tooling';

  FTestDieID := FDieService.SaveDie(Die, 'ReportTestRunner');
  Assert.IsTrue(FTestDieID > 0, 'Failed to insert test die for reporting tests');

  // Create test flatbed die
  FBDie := TFlatbedDie.CreateNew('ZZTEST-FB-REP01', 'ROLL_FORM', 50.0, 50.0, 1, 1);
  FBDie.CustomerID := FTestCustID;
  FBDie.MediaID := FTestMediaID;
  FBDie.Description := 'Test Flatbed Rollform Die';
  FBDie.AroundGapMm := 3.0;
  FBDie.AcrossGapMm := 3.0;
  FBDie.CornerRadiusMm := 1.0;
  FBDie.Shape := 'SQUARE';
  FBDie.PlateWidthMm := 150.0;
  FBDie.PlateLengthMm := 150.0;
  FBDie.MaxFeedStrokeMm := 160.0;
  FBDie.CanRotate := True;
  FBDie.RotationSupport := 'BI_DIRECTIONAL';
  FBDie.StorageLocation := 'FB-RACK-01';
  FBDie.StorageRack := 'FBR1';
  FBDie.StorageShelf := '01';
  FBDie.StorageBin := 'A';
  FBDie.StatusCode := 'AVAILABLE';
  FBDie.DieMaker := 'Flatbed Die Maker Inc';
  FBDie.SupplierRef := 'FB-SUPP-01';
  FBDie.CustomerRef := 'CUST-FB-REF';
  FBDie.InternalRef := 'INT-FB-01';
  FBDie.Notes := 'Test flatbed tooling report notes';
  FFlatbedDieID := FFlatbedRepo.Insert(FBDie);
  Assert.IsTrue(FFlatbedDieID > 0, 'Failed to insert test flatbed die for reporting tests');
end;

procedure TDieVixReportTests.TearDownFixture;
begin
  try
    if FConn.Connected then
    begin
      FConn.ExecSQL('DELETE FROM DIE_AUDIT_LOG WHERE DIE_ID IN (SELECT ID FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-REP-%'')');
      FConn.ExecSQL('DELETE FROM DIE WHERE SERIAL_NO LIKE ''ZZTEST-REP-%''');
      FConn.ExecSQL('DELETE FROM FLATBED_DIE_AUDIT_LOG WHERE DIE_SERIAL_NO LIKE ''ZZTEST-FB-%''');
      FConn.ExecSQL('DELETE FROM FLATBED_DIE WHERE SERIAL_NO LIKE ''ZZTEST-FB-%''');
      if FTestCustID > 0 then
        FConn.ExecSQL('DELETE FROM CUSTOMER WHERE ID = ' + IntToStr(FTestCustID));
      if FTestMediaID > 0 then
        FConn.ExecSQL('DELETE FROM MEDIA WHERE ID = ' + IntToStr(FTestMediaID));
    end;
  except
    // Suppress teardown db exceptions
  end;

  FReportService.Free;
  FDieService.Free;

  // Clean up temp exported report files
  try
    if TDirectory.Exists(FOutDir) then
      TDirectory.Delete(FOutDir, True);
  except
    // Suppress cleanup locked file exceptions
  end;
end;

procedure TDieVixReportTests.Test01_ExportToolingCardPdf;
var
  OutPdf: string;
  Success: Boolean;
  Sig: TBytes;
  SigStr: string;
  FileInfo: TSearchRec;
begin
  OutPdf := TPath.Combine(FOutDir, 'Test01_DieToolingCard.pdf');
  Success := FReportService.ExportToolingCardPdf(FTestDieID, OutPdf);

  Assert.IsTrue(Success, 'ExportToolingCardPdf returned False');
  Assert.IsTrue(TFile.Exists(OutPdf), 'Tooling card PDF was not generated on disk: ' + OutPdf);

  // Validate PDF header
  Sig := ReadFileSignature(OutPdf, 5);
  SigStr := TEncoding.ANSI.GetString(Sig);
  Assert.AreEqual('%PDF-', SigStr, 'Output file is not a valid vector PDF (missing %PDF- header)');

  // Validate file has substantial vector content (> 1000 bytes)
  if FindFirst(OutPdf, faAnyFile, FileInfo) = 0 then
  begin
    try
      Assert.IsTrue(FileInfo.Size > 1000, Format('PDF file is too small (%d bytes)', [FileInfo.Size]));
    finally
      FindClose(FileInfo);
    end;
  end;
end;

procedure TDieVixReportTests.Test02_ExportRegisterCatalogPdf;
var
  OutPdf: string;
  Success: Boolean;
  Sig: TBytes;
  SigStr: string;
  FileInfo: TSearchRec;
  Filter: TDieSearchFilter;
begin
  OutPdf := TPath.Combine(FOutDir, 'Test02_DieRegisterCatalog.pdf');
  Filter := TDieSearchFilter.Default;

  Success := FReportService.ExportRegisterCatalogPdf(Filter, OutPdf);

  Assert.IsTrue(Success, 'ExportRegisterCatalogPdf returned False');
  Assert.IsTrue(TFile.Exists(OutPdf), 'Catalog report PDF was not generated on disk: ' + OutPdf);

  Sig := ReadFileSignature(OutPdf, 5);
  SigStr := TEncoding.ANSI.GetString(Sig);
  Assert.AreEqual('%PDF-', SigStr, 'Output catalog file is not a valid vector PDF (missing %PDF- header)');

  if FindFirst(OutPdf, faAnyFile, FileInfo) = 0 then
  begin
    try
      Assert.IsTrue(FileInfo.Size > 1000, Format('Catalog PDF file is too small (%d bytes)', [FileInfo.Size]));
    finally
      FindClose(FileInfo);
    end;
  end;
end;

procedure TDieVixReportTests.Test03_ExportRegisterCatalogXlsx;
var
  OutXlsx: string;
  Success: Boolean;
  Sig: TBytes;
  FileInfo: TSearchRec;
  Filter: TDieSearchFilter;
begin
  OutXlsx := TPath.Combine(FOutDir, 'Test03_DieRegisterCatalog.xlsx');
  Filter := TDieSearchFilter.Default;

  Success := FReportService.ExportRegisterCatalogXlsx(Filter, OutXlsx);

  Assert.IsTrue(Success, 'ExportRegisterCatalogXlsx returned False');
  Assert.IsTrue(TFile.Exists(OutXlsx), 'Catalog report XLSX was not generated on disk: ' + OutXlsx);

  // Validate ZIP / XLSX openxml container magic bytes: $50 $4B $03 $04 (PK..)
  Sig := ReadFileSignature(OutXlsx, 4);
  Assert.IsTrue(Length(Sig) >= 2, 'XLSX file is empty');
  Assert.AreEqual(Byte($50), Sig[0], 'First byte of XLSX is not $50 ("P")');
  Assert.AreEqual(Byte($4B), Sig[1], 'Second byte of XLSX is not $4B ("K")');

  if FindFirst(OutXlsx, faAnyFile, FileInfo) = 0 then
  begin
    try
      Assert.IsTrue(FileInfo.Size > 500, Format('XLSX file is too small (%d bytes)', [FileInfo.Size]));
    finally
      FindClose(FileInfo);
    end;
  end;
end;

procedure TDieVixReportTests.Test04_ExportFleetMatrixPdf;
var
  OutPdf: string;
  Success: Boolean;
  Sig: TBytes;
  SigStr: string;
  FileInfo: TSearchRec;
begin
  OutPdf := TPath.Combine(FOutDir, 'Test04_CylinderFleetMatrix.pdf');
  Success := FReportService.ExportFleetMatrixPdf(OutPdf);

  Assert.IsTrue(Success, 'ExportFleetMatrixPdf returned False');
  Assert.IsTrue(TFile.Exists(OutPdf), 'Fleet matrix PDF was not generated on disk: ' + OutPdf);

  Sig := ReadFileSignature(OutPdf, 5);
  SigStr := TEncoding.ANSI.GetString(Sig);
  Assert.AreEqual('%PDF-', SigStr, 'Fleet matrix file is not a valid vector PDF');

  if FindFirst(OutPdf, faAnyFile, FileInfo) = 0 then
  begin
    try
      Assert.IsTrue(FileInfo.Size > 1000, Format('Fleet matrix PDF file is too small (%d bytes)', [FileInfo.Size]));
    finally
      FindClose(FileInfo);
    end;
  end;
end;

procedure TDieVixReportTests.Test05_ExportFleetMatrixXlsx;
var
  OutXlsx: string;
  Success: Boolean;
  Sig: TBytes;
  FileInfo: TSearchRec;
begin
  OutXlsx := TPath.Combine(FOutDir, 'Test05_CylinderFleetMatrix.xlsx');
  Success := FReportService.ExportFleetMatrixXlsx(OutXlsx);

  Assert.IsTrue(Success, 'ExportFleetMatrixXlsx returned False');
  Assert.IsTrue(TFile.Exists(OutXlsx), 'Fleet matrix XLSX was not generated on disk: ' + OutXlsx);

  Sig := ReadFileSignature(OutXlsx, 4);
  Assert.IsTrue(Length(Sig) >= 2, 'Fleet matrix XLSX file is empty');
  Assert.AreEqual(Byte($50), Sig[0], 'First byte of XLSX is not $50 ("P")');
  Assert.AreEqual(Byte($4B), Sig[1], 'Second byte of XLSX is not $4B ("K")');

  if FindFirst(OutXlsx, faAnyFile, FileInfo) = 0 then
  begin
    try
      Assert.IsTrue(FileInfo.Size > 500, Format('Fleet matrix XLSX file is too small (%d bytes)', [FileInfo.Size]));
    finally
      FindClose(FileInfo);
    end;
  end;
end;

procedure TDieVixReportTests.Test06_FilteredCatalogReportPdf;
var
  OutPdf: string;
  Success: Boolean;
  Filter: TDieSearchFilter;
begin
  OutPdf := TPath.Combine(FOutDir, 'Test06_FilteredCatalog.pdf');
  Filter := TDieSearchFilter.Default;
  Filter.SearchText := 'ZZTEST-REP-001';
  Filter.Teeth := 96;

  Success := FReportService.ExportRegisterCatalogPdf(Filter, OutPdf);

  Assert.IsTrue(Success, 'Filtered ExportRegisterCatalogPdf returned False');
  Assert.IsTrue(TFile.Exists(OutPdf), 'Filtered catalog PDF was not created: ' + OutPdf);
end;

procedure TDieVixReportTests.Test07_NonExistentDieThrowsException;
var
  OutPdf: string;
  Raised: Boolean;
begin
  OutPdf := TPath.Combine(FOutDir, 'Test07_InvalidDie.pdf');
  Raised := False;
  try
    FReportService.ExportToolingCardPdf(99999999, OutPdf);
  except
    on E: Exception do
      Raised := True;
  end;
  Assert.IsTrue(Raised, 'Expected exception was not raised for non-existent die ID');
end;

procedure TDieVixReportTests.Test08_TemplateResolutionAndEmbeddedFallback;
var
  RepSvc: TDieVixReportService;
  OutPdf: string;
  Success: Boolean;
begin
  // Create report service pointing to non-existent directory to test embedded fallback
  RepSvc := TDieVixReportService.Create(FConn, 'C:\NonExistent_Report_Directory_XYZ_123');
  try
    OutPdf := TPath.Combine(FOutDir, 'Test08_EmbeddedFallback.pdf');
    Success := RepSvc.ExportToolingCardPdf(FTestDieID, OutPdf);

    Assert.IsTrue(Success, 'Export using embedded fallback template failed');
    Assert.IsTrue(TFile.Exists(OutPdf), 'PDF using fallback template was not generated');
  finally
    RepSvc.Free;
  end;
end;

procedure TDieVixReportTests.Test09_ExportFlatbedToolingCardPdf;
var
  OutPdf: string;
  Success: Boolean;
  Sig: TBytes;
  SigStr: string;
  FileInfo: TSearchRec;
begin
  OutPdf := TPath.Combine(FOutDir, 'Test09_FlatbedToolingCard.pdf');
  Success := FReportService.ExportFlatbedToolingCardPdf(FFlatbedDieID, OutPdf);

  Assert.IsTrue(Success, 'ExportFlatbedToolingCardPdf returned False');
  Assert.IsTrue(TFile.Exists(OutPdf), 'Flatbed Tooling Card PDF was not generated on disk: ' + OutPdf);

  Sig := ReadFileSignature(OutPdf, 5);
  SigStr := TEncoding.ANSI.GetString(Sig);
  Assert.AreEqual('%PDF-', SigStr, 'Generated flatbed file is not a valid vector PDF format');

  if FindFirst(OutPdf, faAnyFile, FileInfo) = 0 then
  begin
    try
      Assert.IsTrue(FileInfo.Size > 1000, Format('Flatbed tooling card PDF file is too small (%d bytes)', [FileInfo.Size]));
    finally
      FindClose(FileInfo);
    end;
  end;
end;

procedure TDieVixReportTests.Test10_ExportFlatbedRegisterCatalogPdf;
var
  OutPdf: string;
  Success: Boolean;
  Sig: TBytes;
  SigStr: string;
  FileInfo: TSearchRec;
  Filter: TFlatbedDieSearchFilter;
begin
  OutPdf := TPath.Combine(FOutDir, 'Test10_FlatbedRegisterCatalog.pdf');
  Filter := TFlatbedDieSearchFilter.Default;
  Filter.IncludeArchived := True;
  Success := FReportService.ExportFlatbedRegisterCatalogPdf(Filter, OutPdf);

  Assert.IsTrue(Success, 'ExportFlatbedRegisterCatalogPdf returned False');
  Assert.IsTrue(TFile.Exists(OutPdf), 'Flatbed register catalog PDF was not generated on disk: ' + OutPdf);

  Sig := ReadFileSignature(OutPdf, 5);
  SigStr := TEncoding.ANSI.GetString(Sig);
  Assert.AreEqual('%PDF-', SigStr, 'Generated flatbed catalog is not a valid vector PDF format');

  if FindFirst(OutPdf, faAnyFile, FileInfo) = 0 then
  begin
    try
      Assert.IsTrue(FileInfo.Size > 1000, Format('Flatbed catalog PDF file is too small (%d bytes)', [FileInfo.Size]));
    finally
      FindClose(FileInfo);
    end;
  end;
end;

procedure TDieVixReportTests.Test11_ExportFlatbedRegisterCatalogXlsx;
var
  OutXlsx: string;
  Success: Boolean;
  Sig: TBytes;
  FileInfo: TSearchRec;
  Filter: TFlatbedDieSearchFilter;
begin
  OutXlsx := TPath.Combine(FOutDir, 'Test11_FlatbedRegisterCatalog.xlsx');
  Filter := TFlatbedDieSearchFilter.Default;
  Filter.IncludeArchived := True;
  Success := FReportService.ExportFlatbedRegisterCatalogXlsx(Filter, OutXlsx);

  Assert.IsTrue(Success, 'ExportFlatbedRegisterCatalogXlsx returned False');
  Assert.IsTrue(TFile.Exists(OutXlsx), 'Flatbed register catalog XLSX was not generated on disk: ' + OutXlsx);

  Sig := ReadFileSignature(OutXlsx, 4);
  Assert.IsTrue(Length(Sig) >= 2, 'Flatbed register catalog XLSX file is empty');
  Assert.AreEqual(Byte($50), Sig[0], 'First byte of XLSX is not $50 ("P")');
  Assert.AreEqual(Byte($4B), Sig[1], 'Second byte of XLSX is not $4B ("K")');

  if FindFirst(OutXlsx, faAnyFile, FileInfo) = 0 then
  begin
    try
      Assert.IsTrue(FileInfo.Size > 500, Format('Flatbed catalog XLSX file is too small (%d bytes)', [FileInfo.Size]));
    finally
      FindClose(FileInfo);
    end;
  end;
end;

procedure TDieVixReportTests.Test12_FilteredFlatbedCatalogReportPdf;
var
  OutPdf: string;
  Success: Boolean;
  Filter: TFlatbedDieSearchFilter;
begin
  OutPdf := TPath.Combine(FOutDir, 'Test12_FilteredFlatbedCatalog.pdf');
  Filter := TFlatbedDieSearchFilter.Default;
  Filter.SearchText := 'ZZTEST-FB-REP01';
  Filter.Category := 'ROLL_FORM';

  Success := FReportService.ExportFlatbedRegisterCatalogPdf(Filter, OutPdf);

  Assert.IsTrue(Success, 'Filtered ExportFlatbedRegisterCatalogPdf returned False');
  Assert.IsTrue(TFile.Exists(OutPdf), 'Filtered flatbed catalog PDF was not created: ' + OutPdf);
end;

procedure TDieVixReportTests.Test13_FlatbedEmbeddedFallback;
var
  RepSvc: TDieVixReportService;
  OutPdf: string;
  Success: Boolean;
begin
  RepSvc := TDieVixReportService.Create(FConn, 'C:\NonExistent_Report_Directory_XYZ_123');
  try
    OutPdf := TPath.Combine(FOutDir, 'Test13_FlatbedEmbeddedFallback.pdf');
    Success := RepSvc.ExportFlatbedToolingCardPdf(FFlatbedDieID, OutPdf);

    Assert.IsTrue(Success, 'Export using flatbed embedded fallback template failed');
    Assert.IsTrue(TFile.Exists(OutPdf), 'Flatbed PDF using fallback template was not generated');
  finally
    RepSvc.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixReportTests);

end.
