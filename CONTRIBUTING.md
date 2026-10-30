# Contributing to DieVix

Thank you for your interest in contributing to DieVix!

## Development Environment Requirements
- **Embarcadero Delphi 12.2 Athens** (or later) with VCL and FireDAC.
- **Firebird 5.0** (64-bit or 32-bit server or embedded client library `fbclient.dll`).
- **Operating System:** Windows 10 / Windows 11 / Windows Server 2019+.

## Architecture Principles
1. **Integer Micrometre Precision:**
   - All internal geometric calculations in `src/Engine/DieVix.CalculationEngine.pas` must be in integer micrometres ($\mu\text{m}$, `Int64`).
   - Millimetres (`Double`) are strictly for UI display and DFM entry points.
   - The Calculation Engine must remain **100% pure Pascal** with zero dependencies on UI (VCL) or database (FireDAC/SQL).
2. **Single Source of Truth:**
   - Pitch and gap tolerances are defined by the engine and application settings (`STANDARD_PITCH_UM`, `MIN_AROUND_GAP_UM`, `HARD_BLOCK_GAP_UM`). Never hardcode magic numbers (such as `3000`, `2400`, `3175`, `3.0`) in forms or queries.
3. **Database Migrations:**
   - Never modify released migrations. Always add new versioned SQL files (`migrations/V00x__<description>.sql`).
   - Run `scripts\regenerate_schema.bat` whenever new migrations are added to keep the consolidated `src/Database/DieVix_Schema_Firebird5.sql` in sync.
4. **Configuration & Credentials:**
   - Never commit sensitive database credentials or local paths. Use `DieVix.ini.example` as a template and ensure local `DieVix.ini` remains ignored in `.gitignore`.

## Building the Application
To build the desktop application from the command line:
```cmd
build_app.bat
```
The output executable will be placed in `bin\DieVix.exe`.

## Running the Automated Tests
Before submitting a pull request, ensure all DUnitX tests pass:

1. **Configure Dedicated Test Database:**
   - Copy `DieVixTests.ini.example` to `DieVixTests.ini` in the repository root or application directory (this file is ignored by version control).
   - Point the `Database` parameter to a dedicated, disposable Firebird database (e.g., `tmp\dievix_disposable_test.fdb`).
   - **Automated Safety Guard:** The test runner startup guard (`IsSafeTestDatabasePath`) enforces strict isolation:
     - The target database file name must contain `disposable` or `test` (case-insensitive).
     - The target database must NOT match the database path configured in `DieVix.ini`.
     - If either condition is violated, the test runner immediately aborts execution with a non-zero exit code to prevent touching or deleting real production data.
   - All test records created during test runs use strictly isolated prefixes (`ZZTEST-` for serials, `ZZTEST` for codes).

2. **Build and Run Suite:**
   ```cmd
   cd tests
   build_and_run_tests.bat
   ```
Every behavioral change or new calculation feature must be accompanied by corresponding DUnitX tests.

## Coding Style
- Follow standard Delphi coding conventions (PascalCase for identifiers, prefix `T` for types, `F` for private fields, `A` for routine parameters).
- Keep pull requests focused on specific issues or features.
