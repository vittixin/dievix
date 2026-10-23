program DieVixTests;

{$APPTYPE CONSOLE}

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Automated DUnitX Test Suite Runner
==============================================================================}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.TestRunner,
  DUnitX.Loggers.Console,
  DieVix.CalculationEngine in '..\src\Engine\DieVix.CalculationEngine.pas',
  DieVixCalculationTests in 'DieVixCalculationTests.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
begin
  try
    Writeln('=================================================================');
    Writeln('  DieVix – Rotary Die & Keyline Manager : Automated Test Runner  ');
    Writeln('=================================================================');
    Writeln;

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
