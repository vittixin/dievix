program DieVixTests;

{$APPTYPE CONSOLE}

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Automated DUnitX Test Suite Runner
==============================================================================}

uses
  System.SysUtils,
  System.IOUtils,
  DUnitX.TestFramework,
  DUnitX.TestRunner,
  DUnitX.Loggers.Console,
  FireDAC.ConsoleUI.Wait,
  DieVix.CalculationEngine in '..\src\Engine\DieVix.CalculationEngine.pas',
  DieVix.Domain in '..\src\Domain\DieVix.Domain.pas',
  DieVix.ConnectionManager in '..\src\Database\DieVix.ConnectionManager.pas',
  DieVix.Repositories in '..\src\Repositories\DieVix.Repositories.pas',
  DieVix.MasterDataService in '..\src\Services\DieVix.MasterDataService.pas',
  DieVix.DieService in '..\src\Services\DieVix.DieService.pas',
  DieVix.KeylineService in '..\src\Services\DieVix.KeylineService.pas',
  DieVix.ReportService in '..\src\Services\DieVix.ReportService.pas',
  DieVix.BackupService in '..\src\Services\DieVix.BackupService.pas',
  DieVix.FlatbedDieService in '..\src\Services\DieVix.FlatbedDieService.pas',
  frmDieEditor in '..\src\Forms\frmDieEditor.pas' {frmDieEditor},
  frmDieRegister in '..\src\Forms\frmDieRegister.pas' {frmDieRegister},
  frmKeylineCalculator in '..\src\Forms\frmKeylineCalculator.pas' {frmKeylineCalculator},
  DieVixCalculationTests in 'DieVixCalculationTests.pas',
  DieVixDatabaseTests in 'DieVixDatabaseTests.pas',
  DieVixDieTests in 'DieVixDieTests.pas',
  DieVixCalculatorTests in 'DieVixCalculatorTests.pas',
  DieVixReportTests in 'DieVixReportTests.pas',
  DieVixBackupTests in 'DieVixBackupTests.pas',
  DieVixFlatbedDieTests in 'DieVixFlatbedDieTests.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  TestMgr: TDieVixConnectionManager;
  TestDbPath: string;
  AppIniPath: string;
  GuardReason: string;
begin
  try
    Writeln('=================================================================');
    Writeln('  DieVix - Rotary Die & Keyline Manager : Automated Test Runner  ');
    Writeln('=================================================================');
    Writeln;

    // Task F.1 & F.2: Configure tests to strictly use DieVixTests.ini and guard safety
    var ResolvedTestIni := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), 'DieVixTests.ini'));
    if not FileExists(ResolvedTestIni) and FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\DieVixTests.ini')) then
      ResolvedTestIni := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\DieVixTests.ini'))
    else if not FileExists(ResolvedTestIni) and FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\DieVixTests.ini')) then
      ResolvedTestIni := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\DieVixTests.ini'))
    else if not FileExists(ResolvedTestIni) and FileExists('DieVixTests.ini') then
      ResolvedTestIni := TPath.GetFullPath('DieVixTests.ini');

    TDieVixConnectionManager.SetDefaultIniFileName(ResolvedTestIni);
    TestMgr := TDieVixConnectionManager.Instance;
    TestDbPath := TestMgr.Config.Database;

    AppIniPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\DieVix.ini'));
    if not FileExists(AppIniPath) and FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\DieVix.ini')) then
      AppIniPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\DieVix.ini'))
    else if not FileExists(AppIniPath) and FileExists('DieVix.ini') then
      AppIniPath := TPath.GetFullPath('DieVix.ini');

    if not IsSafeTestDatabasePath(TestDbPath, AppIniPath, GuardReason) then
    begin
      Writeln('=================================================================');
      Writeln('  FATAL SECURITY GUARD: REFUSING TO RUN ON UNSAFE DATABASE       ');
      Writeln('=================================================================');
      Writeln('Target Database : ', TestDbPath);
      Writeln('Reason          : ', GuardReason);
      Writeln('Automated tests may ONLY execute against databases with "disposable"');
      Writeln('or "test" in their filename and strictly separate from DieVix.ini.');
      Writeln('Execution aborted.');
      System.ExitCode := 3;
      Exit;
    end;

    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);

    Results := Runner.Execute;

    if not Results.AllPassed then
      System.ExitCode := 1
    else
      System.ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 2;
    end;
  end;
end.
