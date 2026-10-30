# DieVix - Rotary Die & Keyline Manager

> **Precision in Every Repeat.**  
> Industrial rotary tooling management, keyline optimization, and press compatibility system for label converting.

---

## 1. System Overview

**DieVix** is a high-performance Windows desktop application built with **Delphi 12.2 Athens (VCL)** and **Firebird 5.0**. It eliminates floating-point rounding errors in label rotary die layout planning by computing all dimensions in exact integer micrometres ($\mu\text{m}$).

### Core Capabilities
- **Integer Micrometre Precision:** $1/8"$ circular pitch is exactly $3,175\text{ }\mu\text{m}$, eliminating $2.99999999\text{ mm}$ false rejections. All mathematical rounding uses commercial round half away from zero.
- **Shop-Floor Tolerance Strategy:** Standard $\ge 3.000\text{ mm}$ approval; warning with required override reason for legacy $2.400 - 2.999\text{ mm}$ tooling; hard mechanical block for $< 2.400\text{ mm}$ (when configured). Single source of truth driven directly by the calculation engine and database settings.
- **Cylinder Fleet Management:** Direct support for the 16 fleet sizes: **66, 68, 72, 76, 82, 86, 90, 94, 96, 98, 102, 106, 112, 120, 126, 132 Teeth**.
- **Machine Fleet Matrix:** Interactive 2D cross-tab matrix connecting printing presses to supported cylinder tooling.
- **Keyline & Stepping Calculator:** Automatic multi-up stepped layouts, press web fit verification, and 2D vector CAD export (DXF and SVG).
- **Master Data Registries:** Standardized Media Substrates (Face & Liner layer separation), Customer accounts, Machine press specifications, and Die Status codes.
- **Audit History & Safeguards:** Comprehensive change auditing capturing the active Windows user, non-destructive tooling archiving, and foreign-key integrity preserving audit logs upon tooling deletion.
- **Database Architecture:** Firebird 5.0 with FireDAC supporting both **Server mode** (LAN multi-user) and **Embedded mode** (single workstation).

---

## 2. Repository Layout

```
DieVix/
├── docs/
│   └── DIEVIX_DESIGN_SPECIFICATION.md   # Complete architecture & design blueprint
├── migrations/
│   ├── V001__initial_schema.sql         # Core Firebird 5.0 schema & DDL
│   ├── V002__seed_fleet_and_masters.sql # Seed data for 16 cylinders, settings, presses
│   ├── V003__die_inventory_extension.sql# Phase 3 Die inventory, physical storage, and audit trail
│   ├── V004__die_archive_and_safety.sql # Phase 5 Safe tooling archiving & deletion safeguards
│   ├── V005__fix_pitch_and_gap_policy.sql # Pitch consistency, division scale, dynamic gap view
│   └── V006__audit_log_integrity.sql    # Non-cascading FK & audit history preservation
├── reports/
│   ├── die_tooling_card.vrt             # Job Bag Card template with Barcode/QR, geometry, substrate
│   ├── die_register_catalog.vrt         # Tooling inventory register catalog report template
│   └── cylinder_fleet_matrix.vrt        # Press cylinder matrix & tooling availability template
├── scripts/
│   ├── regenerate_schema.bat            # Rebuilds consolidated schema from migrations
│   └── regenerate_schema.ps1            # PowerShell engine for schema concatenation
├── src/
│   ├── Engine/
│   │   └── DieVix.CalculationEngine.pas # Pure Pascal integer micrometre engine (Zero UI/DB dependency)
│   ├── Domain/
│   │   └── DieVix.Domain.pas            # Domain entities, records, and repository interfaces
│   ├── Database/
│   │   ├── DieVix_Schema_Firebird5.sql  # Consolidated DDL script (Auto-generated from migrations/)
│   │   └── DieVix.ConnectionManager.pas # FireDAC connection manager & transactional migration runner
│   ├── Repositories/
│   │   └── DieVix.Repositories.pas      # FireDAC repository implementations with parameterized SQL
│   ├── Services/
│   │   ├── DieVix.MasterDataService.pas # Master Data application service & business integrity guards
│   │   ├── DieVix.DieService.pas        # Die tooling service, live calculations, duplicate detection
│   │   ├── DieVix.KeylineService.pas    # Keyline generator service, DXF/SVG export, stepping & margins
│   │   ├── DieVix.ReportService.pas     # VittixReport reporting service, vector PDF & Excel XLSX exports
│   │   └── DieVix.BackupService.pas     # Database & Report Backup Service (gbak, hot copy, ZIP, manifests)
│   └── Forms/                           # VCL Forms & DFM resources
│       ├── frmMain.pas / .dfm           # Modern desktop shell & KPI dashboard
│       ├── frmDieRegister.pas / .dfm    # Searchable & filterable Die Master Register with print actions
│       ├── frmDieEditor.pas / .dfm      # Die tooling editor with live calculations & Job Card printing
│       ├── frmKeylineCalculator.pas/.dfm# Interactive keyline calculator & CAD/vector export interface
│       ├── frmCylinderMaster.pas / .dfm # Cylinder fleet register
│       ├── frmMachineMaster.pas / .dfm  # Press specifications
│       ├── frmMachineCylinderMatrix.pas # 2D machine-cylinder compatibility grid
│       ├── frmCustomerMaster.pas / .dfm # Customer directory
│       ├── frmMediaMaster.pas / .dfm    # Media substrate register
│       ├── frmDieStatusMaster.pas / .dfm# Tooling statuses
│       ├── frmSettings.pas / .dfm       # Application preferences & gap policy
│       └── frmBackup.pas / .dfm         # Database & Report backup and restore console
├── tests/
│   ├── DieVixTests.dpr                  # DUnitX test suite runner
│   ├── DieVixTests.dproj                # Delphi 12 project file
│   ├── DieVixCalculationTests.pas       # Engine tests (boundary, rounding, integer fit, recommendation)
│   ├── DieVixCalculatorTests.pas        # Keyline calculation, stepping, and geometry integration tests
│   ├── DieVixDatabaseTests.pas          # Database integration & migration runner tests
│   ├── DieVixDieTests.pas               # Die tooling lifecycle, audit trail, concurrency, user capture
│   ├── DieVixReportTests.pas            # VittixReport Job Bag Card, catalog, fleet matrix & export tests
│   ├── DieVixBackupTests.pas            # Database & Report backup, restore, ZIP archive & manifest tests
│   └── build_and_run_tests.bat          # Command-line test compilation & execution
├── DieVix.dpr                           # Desktop Application project file
├── DieVix.dproj                         # Delphi 12 project file
├── DieVix.ini.example                   # Database connection settings template
├── build_app.bat                        # Desktop application build script
├── CONTRIBUTING.md                      # Architecture rules & developer contribution guide
└── LICENSE                              # MIT License
```

---

## 3. Database Initialization & Configuration

### Firebird 5 Setup
DieVix uses Firebird 5.0 (`DIEVIX.FDB`) with `UTF8` character set and `NUMERIC(9,3)` / `NUMERIC(18,3)` dimension storage.

#### Recommended: Automated Migration Runner
1. Create a blank database:
   ```cmd
   "C:\Program Files\Firebird\Firebird_5_0\isql.exe"
   SQL> CREATE DATABASE 'localhost:C:/DieVix/data/DIEVIX.FDB' USER 'SYSDBA' PASSWORD 'your_password' DEFAULT CHARACTER SET UTF8;
   SQL> QUIT;
   ```
2. Configure `DieVix.ini` (see below) pointing to `C:/DieVix/data/DIEVIX.FDB`.
3. Launch `DieVix.exe`. The application's built-in migration runner will automatically apply all migrations (`V001` through `V008`) in version order, each within an isolated transaction, and track applied versions in `SCHEMA_VERSION`.

#### Alternative: Manual Migration via `isql`
To apply migrations manually:
```cmd
"C:\Program Files\Firebird\Firebird_5_0\isql.exe" -user SYSDBA -password your_password localhost:C:/DieVix/data/DIEVIX.FDB
SQL> IN migrations/V001__initial_schema.sql;
SQL> IN migrations/V002__seed_fleet_and_masters.sql;
SQL> IN migrations/V003__die_inventory_extension.sql;
SQL> IN migrations/V004__die_archive_and_safety.sql;
SQL> IN migrations/V005__fix_pitch_and_gap_policy.sql;
SQL> IN migrations/V006__audit_log_integrity.sql;
SQL> IN migrations/V007__reconcile_gap_policy_and_audit_fk.sql;
SQL> IN migrations/V008__audit_serial_and_pool_gap_policy.sql;
SQL> QUIT;
```

> [!NOTE]
> **One-Time Backfill for Manual Legacy Databases:**  
> If your database was previously initialized manually via `isql` with only V001 and V002 prior to the migration runner, run the following one-time backfill SQL to populate `SCHEMA_VERSION`:
> ```sql
> INSERT INTO SCHEMA_VERSION (VERSION_NUM, SCRIPT_NAME) VALUES (1, 'V001__initial_schema.sql');
> INSERT INTO SCHEMA_VERSION (VERSION_NUM, SCRIPT_NAME) VALUES (2, 'V002__seed_fleet_and_masters.sql');
> COMMIT;
> ```
> This prevents primary-key duplicate errors and ensures future migrations are recognized seamlessly.

---

### Connection Configuration (`DieVix.ini`)
Copy `DieVix.ini.example` to `DieVix.ini` beside `DieVix.exe` (or let the application generate it automatically on first run):
```ini
[Database]
Mode=Server
Server=localhost
Port=3050
Database=C:\DieVix\data\DIEVIX.FDB
UserName=SYSDBA
Password=your_password_here
VendorLib=C:\Program Files\Firebird\Firebird_5_0\fbclient.dll
CharacterSet=UTF8
Timeout=15
```

> [!WARNING]
> **Security Warning:** `DieVix.ini` stores database connection parameters, including the password, in plain text on the local filesystem. Protect this file using Windows file permissions (NTFS ACLs) and never commit `DieVix.ini` into version control.

---

## 4. Building and Running

### Build Desktop Application
```cmd
build_app.bat
```
Produces `bin\DieVix.exe`.

### Build & Run Automated Test Suite
Before running the tests, copy `DieVixTests.ini.example` to `DieVixTests.ini` (which is gitignored) and configure a dedicated disposable test database.
```cmd
copy DieVixTests.ini.example DieVixTests.ini
cd tests
build_and_run_tests.bat
```
> [!IMPORTANT]
> **Test Safety Guard:** The test runner startup guard verifies that the database path in `DieVixTests.ini` contains `disposable` or `test` (case-insensitive) and is distinct from the production database specified in `DieVix.ini`. If either condition is not met, execution halts immediately with a non-zero exit code to guarantee real data is never touched.

Compiles and executes all **144 DUnitX tests** covering calculation math, integer micrometre precision, commercial rounding, database repositories, migration runner atomicity, die tooling lifecycle, duplicate detection, optimistic locking, gap validation, VittixReport reporting architecture (Job Bag Cards, master register catalogs, and machine fleet matrix with native vector PDF & Excel XLSX exports), and full database & report backup/restore services (Firebird .fbk gbak streams, online physical snapshots, ZIP report replication, corruption guards, and bundle manifests).

### Regenerate Consolidated Schema
To regenerate `src/Database/DieVix_Schema_Firebird5.sql` after adding or updating migrations in `migrations/`:
```cmd
scripts\regenerate_schema.bat
```
*(Note: `DieVix_Schema_Firebird5.sql` is auto-generated. Do not edit it directly.)*

---

## 5. Contributing & License

- See [CONTRIBUTING.md](file:///d:/ketan/github/DieVix/CONTRIBUTING.md) for architecture rules, calculation engine constraints, and coding standards.
- Distributed under the [MIT License](file:///d:/ketan/github/DieVix/LICENSE).
