# DieVix – Rotary Die & Keyline Manager

> **Precision in Every Repeat.**  
> Industrial rotary tooling management, keyline optimization, and press compatibility system for label converting.

---

## 1. System Overview

**DieVix** is a high-performance Windows desktop application built with **Delphi 12.2 Athens (VCL)** and **Firebird 5.0**. It eliminates floating-point rounding errors in label rotary die layout planning by computing all dimensions in exact integer micrometres ($\mu\text{m}$).

### Core Capabilities
- **Integer Micrometre Precision:** $1/8"$ circular pitch is exactly $3,175\text{ }\mu\text{m}$, eliminating $2.99999999\text{ mm}$ false rejections.
- **Shop-Floor Tolerance Strategy:** Standard $\ge 3.000\text{ mm}$ approval; warning with required override reason for legacy $2.400 - 2.999\text{ mm}$ tooling; hard mechanical block for $< 2.400\text{ mm}$ (when configured).
- **Cylinder Fleet Management:** Direct support for the 16 fleet sizes: **66, 68, 72, 76, 82, 86, 90, 94, 96, 98, 102, 106, 112, 120, 126, 132 Teeth**.
- **Machine Fleet Matrix:** Interactive 2D cross-tab matrix connecting printing presses to supported cylinder tooling.
- **Master Data Registries:** Standardized Media Substrates (Face & Liner layer separation), Customer accounts, Machine press specifications, and Die Status codes.
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
│   └── V004__die_archive_and_safety.sql # Phase 5 Safe tooling archiving & deletion safeguards
├── src/
│   ├── Engine/
│   │   └── DieVix.CalculationEngine.pas # Pure Pascal integer micrometre engine (Zero UI/DB dependency)
│   ├── Domain/
│   │   └── DieVix.Domain.pas            # Domain entities, records, and repository interfaces
│   ├── Database/
│   │   ├── DieVix_Schema_Firebird5.sql  # Consolidated DDL script
│   │   └── DieVix.ConnectionManager.pas # FireDAC connection manager (Server & Embedded modes)
│   ├── Repositories/
│   │   └── DieVix.Repositories.pas      # FireDAC repository implementations with parameterized SQL
│   ├── Services/
│   │   ├── DieVix.MasterDataService.pas # Master Data application service & business integrity guards
│   │   └── DieVix.DieService.pas        # Die tooling service, live calculations, duplicate & reuse detection
│   └── Forms/                           # VCL Forms & DFM resources
│       ├── frmMain.pas / .dfm           # Modern desktop shell & KPI dashboard
│       ├── frmDieRegister.pas / .dfm    # Searchable & filterable Die Master Register
│       ├── frmDieEditor.pas / .dfm      # Die tooling editor with live calculations & similar reuse scanner
│       ├── frmCylinderMaster.pas / .dfm # Cylinder fleet register
│       ├── frmMachineMaster.pas / .dfm  # Press specifications
│       ├── frmMachineCylinderMatrix.pas # 2D machine-cylinder compatibility grid
│       ├── frmCustomerMaster.pas / .dfm # Customer directory
│       ├── frmMediaMaster.pas / .dfm    # Media substrate register
│       ├── frmDieStatusMaster.pas / .dfm# Tooling statuses
│       └── frmSettings.pas / .dfm       # Application preferences & gap policy
├── tests/
│   ├── DieVixTests.dpr                  # DUnitX test suite runner
│   ├── DieVixTests.dproj                # Delphi 12 project file
│   ├── DieVixCalculationTests.pas       # Engine tests (boundary, noise, fit, recommendation)
│   ├── DieVixDatabaseTests.pas          # Database integration tests (CRUD, transactions, matrix)
│   ├── DieVixDieTests.pas               # Phase 3 Die tests (CRUD, duplicate serial, sub-3mm override, concurrency)
│   └── build_and_run_tests.bat          # Command-line compilation & execution
├── DieVix.dpr                           # Desktop Application project file
├── DieVix.dproj                         # Delphi 12 project file
├── DieVix.ini                           # Database connection settings
├── build_app.bat                        # Desktop application build script
├── bin/                                 # Compiled binaries (DieVix.exe, DieVixTests.exe)
└── dcu/                                 # Intermediate compilation units
```

---

## 3. Database Initialization & Configuration

### Firebird 5 Setup
DieVix uses Firebird 5.0 (`DIEVIX.FDB`) with `UTF8` character set and `NUMERIC(9,3)` dimension storage.

To initialize a database using Firebird's `isql.exe`:
```cmd
"C:\Program Files (x86)\Firebird\Firebird_5_0\isql.exe"
SQL> CREATE DATABASE 'localhost:D:/ketan/github/DieVix/data/DIEVIX.FDB' USER 'SYSDBA' PASSWORD 'masterkey' DEFAULT CHARACTER SET UTF8;
SQL> IN D:/ketan/github/DieVix/migrations/V001__initial_schema.sql;
SQL> IN D:/ketan/github/DieVix/migrations/V002__seed_fleet_and_masters.sql;
SQL> QUIT;
```

### Connection Configuration (`DieVix.ini`)
Place `DieVix.ini` beside `DieVix.exe`:
```ini
[Database]
Mode=Server
Server=localhost
Port=3050
Database=D:\ketan\github\DieVix\tmp\dievix_disposable_test.fdb
UserName=SYSDBA
Password=masterkey
VendorLib=C:\Program Files (x86)\Firebird\Firebird_5_0\fbclient.dll
CharacterSet=UTF8
Timeout=15
```

---

## 4. Building and Running

### Build Desktop Application
```cmd
build_app.bat
```
Produces `bin\DieVix.exe`.

### Build & Run Automated Test Suite
```cmd
cd tests
build_and_run_tests.bat
```
Compiles and executes all 107 DUnitX test fixtures covering calculation math, database repositories, die tooling lifecycle, duplicate detection, optimistic locking, and gap validation.
