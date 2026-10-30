unit DieVixBackupTests;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  DUnitX Test Suite: Database & Report Backup Service
==============================================================================}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Zip,
  System.JSON,
  DUnitX.TestFramework,
  DieVix.Domain,
  DieVix.ConnectionManager,
  DieVix.BackupService;

type
  [TestFixture]
  TDieVixBackupTests = class
  private
    FBackupService: TDieVixBackupService;
    FTestWorkDir: string;
    FReportsDir: string;
  public
    [SetupFixture]
    procedure SetupFixture;

    [TearDownFixture]
    procedure TearDownFixture;

    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAvailableReportTemplatesDiscovery;

    [Test]
    procedure TestBackupReportsToZip;

    [Test]
    procedure TestVerifyReportsArchive;

    [Test]
    procedure TestBackupReportsToFolder;

    [Test]
    procedure TestRestoreReportsFromZip;

    [Test]
    procedure TestRestoreReportsRejectsCorruptTemplate;

    [Test]
    procedure TestDatabaseBackupToFbk;

    [Test]
    procedure TestVerifyDatabaseBackup;

    [Test]
    procedure TestPhysicalHotBackup;

    [Test]
    procedure TestFullSystemBackupBundleAndManifest;

    [Test]
    procedure TestEnumerateBackupsCatalog;
  end;

implementation

{ TDieVixBackupTests }

procedure TDieVixBackupTests.SetupFixture;
var
  ExeDir: string;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  FTestWorkDir := TPath.Combine(ExeDir, 'test_backup_sandbox');
  if DirectoryExists(FTestWorkDir) then
    TDirectory.Delete(FTestWorkDir, True);
  ForceDirectories(FTestWorkDir);

  // Discover reports directory
  FReportsDir := TPath.Combine(ExeDir, 'reports');
  if not DirectoryExists(FReportsDir) then
    FReportsDir := TPath.Combine(ExeDir, '..\reports');
  if not DirectoryExists(FReportsDir) then
    FReportsDir := TPath.Combine(ExeDir, '..\..\reports');

  FBackupService := TDieVixBackupService.Create(FReportsDir, FTestWorkDir);
end;

procedure TDieVixBackupTests.TearDownFixture;
begin
  FBackupService.Free;
  if DirectoryExists(FTestWorkDir) then
  begin
    try
      TDirectory.Delete(FTestWorkDir, True);
    except
      // Ignore cleanup lock
    end;
  end;
end;

procedure TDieVixBackupTests.Setup;
begin
  // Per-test setup
end;

procedure TDieVixBackupTests.TearDown;
begin
  // Per-test teardown
end;

procedure TDieVixBackupTests.TestAvailableReportTemplatesDiscovery;
var
  Templates: TArray<TReportTemplateInfo>;
  I: Integer;
  FoundCard, FoundCatalog, FoundMatrix: Boolean;
begin
  Templates := FBackupService.GetAvailableReportTemplates;
  Assert.IsTrue(Length(Templates) >= 3, 'Must discover at least 3 standard .vrt report templates');

  FoundCard := False;
  FoundCatalog := False;
  FoundMatrix := False;

  for I := 0 to High(Templates) do
  begin
    Assert.IsTrue(Templates[I].IsValid, 'Discovered template must be valid JSON: ' + Templates[I].FileName);
    Assert.IsTrue(Templates[I].FileSizeBytes > 0, 'Template file size must be non-zero');

    if SameText(Templates[I].FileName, 'die_tooling_card.vrt') then
      FoundCard := True
    else if SameText(Templates[I].FileName, 'die_register_catalog.vrt') then
      FoundCatalog := True
    else if SameText(Templates[I].FileName, 'cylinder_fleet_matrix.vrt') then
      FoundMatrix := True;
  end;

  Assert.IsTrue(FoundCard, 'die_tooling_card.vrt must be discovered');
  Assert.IsTrue(FoundCatalog, 'die_register_catalog.vrt must be discovered');
  Assert.IsTrue(FoundMatrix, 'cylinder_fleet_matrix.vrt must be discovered');
end;

procedure TDieVixBackupTests.TestBackupReportsToZip;
var
  TargetZip: string;
  Res: TBackupResult;
begin
  TargetZip := TPath.Combine(FTestWorkDir, 'test_reports_backup.zip');
  if FileExists(TargetZip) then
    TFile.Delete(TargetZip);

  Res := FBackupService.BackupReportsToZip(TargetZip);
  Assert.IsTrue(Res.Success, 'BackupReportsToZip must succeed: ' + Res.ErrorMessage);
  Assert.IsTrue(FileExists(TargetZip), 'Backup ZIP file must exist on disk');
  Assert.IsTrue(Res.ItemCount >= 3, 'Must have archived at least 3 report templates');
  Assert.IsTrue(Res.FileSizeBytes > 0, 'ZIP archive size must be greater than zero');
  Assert.AreEqual(TargetZip, Res.TargetFilePath, 'TargetFilePath must match requested destination');
end;

procedure TDieVixBackupTests.TestVerifyReportsArchive;
var
  TargetZip, Details: string;
  Count: Integer;
  Res: TBackupResult;
  Valid: Boolean;
begin
  TargetZip := TPath.Combine(FTestWorkDir, 'test_reports_verify.zip');
  Res := FBackupService.BackupReportsToZip(TargetZip);
  Assert.IsTrue(Res.Success, 'Prerequisite backup must succeed');

  Valid := FBackupService.VerifyReportsArchive(TargetZip, Count, Details);
  Assert.IsTrue(Valid, 'Reports archive verification must succeed');
  Assert.IsTrue(Count >= 3, 'Verified archive must report at least 3 templates');
  Assert.IsTrue(Pos('template', Details) > 0, 'Details message must describe verified contents');
end;

procedure TDieVixBackupTests.TestBackupReportsToFolder;
var
  TargetDir: string;
  Res: TBackupResult;
  Files: TArray<string>;
begin
  TargetDir := TPath.Combine(FTestWorkDir, 'folder_backup_test');
  Res := FBackupService.BackupReportsToFolder(TargetDir);
  Assert.IsTrue(Res.Success, 'BackupReportsToFolder must succeed: ' + Res.ErrorMessage);
  Assert.IsTrue(DirectoryExists(TargetDir), 'Target backup folder must exist');

  Files := TDirectory.GetFiles(TargetDir, '*.vrt');
  Assert.IsTrue(Length(Files) >= 3, 'Target folder must contain all .vrt template files');
end;

procedure TDieVixBackupTests.TestRestoreReportsFromZip;
var
  TargetZip, RestoreDir: string;
  BackupRes: TBackupResult;
  RestRes: TRestoreResult;
  Files: TArray<string>;
begin
  TargetZip := TPath.Combine(FTestWorkDir, 'reports_for_restore.zip');
  BackupRes := FBackupService.BackupReportsToZip(TargetZip);
  Assert.IsTrue(BackupRes.Success, 'Backup step must succeed');

  RestoreDir := TPath.Combine(FTestWorkDir, 'restore_from_zip_target');
  RestRes := FBackupService.RestoreReportsFromZip(TargetZip, RestoreDir, True);
  Assert.IsTrue(RestRes.Success, 'RestoreReportsFromZip must succeed: ' + RestRes.ErrorMessage);
  Assert.IsTrue(RestRes.RestoredCount >= 3, 'Must restore at least 3 templates');

  Files := TDirectory.GetFiles(RestoreDir, '*.vrt');
  Assert.IsTrue(Length(Files) >= 3, 'Restored directory must contain at least 3 .vrt files');
end;

procedure TDieVixBackupTests.TestRestoreReportsRejectsCorruptTemplate;
var
  ZipPath, RestoreDir: string;
  Zip: TZipFile;
  RestRes: TRestoreResult;
  ValidContent, CorruptContent: string;
begin
  ZipPath := TPath.Combine(FTestWorkDir, 'test_corrupt_template.zip');
  RestoreDir := TPath.Combine(FTestWorkDir, 'corrupt_test_target');
  if FileExists(ZipPath) then
    TFile.Delete(ZipPath);

  ValidContent := '{"Version":2,"Title":"Valid Test Report","Objects":[],"PageSettings":{}}';
  CorruptContent := '{"This is not valid json report: missing bracket';

  Zip := TZipFile.Create;
  try
    Zip.Open(ZipPath, zmWrite);
    Zip.Add(TEncoding.UTF8.GetBytes(ValidContent), 'valid_report.vrt');
    Zip.Add(TEncoding.UTF8.GetBytes(CorruptContent), 'corrupt_report.vrt');
    Zip.Close;
  finally
    Zip.Free;
  end;

  RestRes := FBackupService.RestoreReportsFromZip(ZipPath, RestoreDir, True);
  Assert.IsTrue(RestRes.Success, 'Restore must proceed and recover valid templates while rejecting corrupt ones');
  Assert.AreEqual(1, RestRes.RestoredCount, 'Exactly 1 valid template must be restored');
  Assert.IsTrue(FileExists(TPath.Combine(RestoreDir, 'valid_report.vrt')), 'valid_report.vrt must exist');
  Assert.IsFalse(FileExists(TPath.Combine(RestoreDir, 'corrupt_report.vrt')), 'corrupt_report.vrt must not be restored');
end;

procedure TDieVixBackupTests.TestDatabaseBackupToFbk;
var
  TargetFbk: string;
  Res: TBackupResult;
begin
  TargetFbk := TPath.Combine(FTestWorkDir, 'dievix_unit_test.fbk');
  if FileExists(TargetFbk) then
    TFile.Delete(TargetFbk);

  Res := FBackupService.BackupDatabase(TargetFbk, True, False);
  Assert.IsTrue(Res.Success, 'BackupDatabase must succeed: ' + Res.ErrorMessage);
  Assert.IsTrue(FileExists(TargetFbk), 'Target .fbk file must exist on disk');
  Assert.IsTrue(Res.FileSizeBytes > 1024, 'Backup archive must be greater than 1KB');
  Assert.AreEqual(btDatabaseFbk, Res.BackupType, 'BackupType must be btDatabaseFbk');
end;

procedure TDieVixBackupTests.TestVerifyDatabaseBackup;
var
  TargetFbk, Details: string;
  Res: TBackupResult;
  Valid: Boolean;
begin
  TargetFbk := TPath.Combine(FTestWorkDir, 'dievix_unit_test_verify.fbk');
  Res := FBackupService.BackupDatabase(TargetFbk, False, False);
  Assert.IsTrue(Res.Success, 'Prerequisite database backup must succeed');

  Valid := FBackupService.VerifyDatabaseBackup(TargetFbk, Details);
  Assert.IsTrue(Valid, 'VerifyDatabaseBackup must return True for valid .fbk file');
  Assert.IsTrue(Pos('Valid Firebird backup archive', Details) > 0, 'Verification details must confirm valid archive');
end;

procedure TDieVixBackupTests.TestPhysicalHotBackup;
var
  TargetBak: string;
  Res: TBackupResult;
begin
  TargetBak := TPath.Combine(FTestWorkDir, 'dievix_physical_test.fdb.bak');
  if FileExists(TargetBak) then
    TFile.Delete(TargetBak);

  Res := FBackupService.BackupDatabasePhysical(TargetBak);
  Assert.IsTrue(Res.Success, 'BackupDatabasePhysical must succeed: ' + Res.ErrorMessage);
  Assert.IsTrue(FileExists(TargetBak), 'Physical snapshot file must exist on disk');
  Assert.IsTrue(Res.FileSizeBytes > 1024, 'Physical snapshot must be non-trivial in size');
  Assert.AreEqual(btDatabasePhysical, Res.BackupType, 'BackupType must be btDatabasePhysical');
end;

procedure TDieVixBackupTests.TestFullSystemBackupBundleAndManifest;
var
  BundleZip: string;
  Res: TBackupResult;
  Zip: TZipFile;
  ManifestBytes: TBytes;
  ManifestStr: string;
  Val: TJSONValue;
  Obj: TJSONObject;
  RepArr: TJSONArray;
begin
  BundleZip := TPath.Combine(FTestWorkDir, 'dievix_full_system_test.zip');
  if FileExists(BundleZip) then
    TFile.Delete(BundleZip);

  Res := FBackupService.BackupFullSystem(BundleZip, 'QA_AUTOMATION');
  Assert.IsTrue(Res.Success, 'BackupFullSystem must succeed: ' + Res.ErrorMessage);
  Assert.IsTrue(FileExists(BundleZip), 'Full system bundle ZIP must exist');
  Assert.AreEqual(btFullSystemBundle, Res.BackupType);

  // Validate ZIP contents and manifest
  Zip := TZipFile.Create;
  try
    Zip.Open(BundleZip, zmRead);
    Assert.IsTrue(Zip.IndexOf('backup_manifest.json') >= 0, 'Bundle must contain backup_manifest.json');
    Assert.IsTrue(Zip.IndexOf('database/dievix.fbk') >= 0, 'Bundle must contain database/dievix.fbk');

    Zip.Read('backup_manifest.json', ManifestBytes);
    ManifestStr := TEncoding.UTF8.GetString(ManifestBytes);
    Val := TJSONObject.ParseJSONValue(ManifestStr);
    Assert.IsNotNull(Val, 'Manifest must be valid JSON');
    Obj := TJSONObject(Val);
    try
      Assert.AreEqual('DieVix Rotary Die & Keyline Manager', Obj.Values['Application'].Value);
      Assert.AreEqual('QA_AUTOMATION', Obj.Values['Operator'].Value);
      Assert.AreEqual('database/dievix.fbk', Obj.Values['DatabaseBackupFile'].Value);
      Assert.IsTrue(Obj.Values['Reports'] is TJSONArray, 'Manifest must include Reports array');
      RepArr := TJSONArray(Obj.Values['Reports']);
      Assert.IsTrue(RepArr.Count >= 3, 'Manifest must record at least 3 report templates');
    finally
      Obj.Free;
    end;
    Zip.Close;
  finally
    Zip.Free;
  end;
end;

procedure TDieVixBackupTests.TestEnumerateBackupsCatalog;
var
  CatDir: string;
  Items: TArray<TBackupItemInfo>;
  FoundFbk, FoundPhysical, FoundReportsZip: Boolean;
  I: Integer;
begin
  CatDir := TPath.Combine(FTestWorkDir, 'catalog_test_dir');
  ForceDirectories(CatDir);

  // Create representative mock backup files
  TFile.WriteAllText(TPath.Combine(CatDir, 'DieVix_DB_20261027_010000.fbk'), 'FBK_DUMMY_HEADER_BYTES');
  TFile.WriteAllText(TPath.Combine(CatDir, 'DieVix_DB_Physical_20261027_020000.fdb.bak'), 'FDB_BAK_BYTES');
  TFile.WriteAllText(TPath.Combine(CatDir, 'DieVix_Reports_20261027_030000.zip'), 'ZIP_BYTES');

  Items := FBackupService.EnumerateBackups(CatDir);
  Assert.IsTrue(Length(Items) >= 3, 'Must enumerate all 3 mock backup files');

  FoundFbk := False;
  FoundPhysical := False;
  FoundReportsZip := False;

  for I := 0 to High(Items) do
  begin
    if (Items[I].BackupType = btDatabaseFbk) then
      FoundFbk := True
    else if (Items[I].BackupType = btDatabasePhysical) then
      FoundPhysical := True
    else if (Items[I].BackupType = btReportsZip) then
      FoundReportsZip := True;
  end;

  Assert.IsTrue(FoundFbk, 'Must categorize .fbk as btDatabaseFbk');
  Assert.IsTrue(FoundPhysical, 'Must categorize .fdb.bak as btDatabasePhysical');
  Assert.IsTrue(FoundReportsZip, 'Must categorize reports zip as btReportsZip');
end;

initialization
  TDUnitX.RegisterTestFixture(TDieVixBackupTests);

end.
