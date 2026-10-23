# DieVix – Rotary Die & Keyline Manager

> **Precision in Every Repeat.**  
> Industrial rotary tooling management, keyline optimization, and press compatibility system for label converting.

---

## Overview

**DieVix** is a high-performance Windows desktop application built with **Delphi 12.2 Athens (VCL)** and **Firebird 5.0**. It eliminates floating-point rounding errors in label rotary die layout planning by computing all dimensions in exact integer micrometres ($\mu\text{m}$).

### Core Capabilities
- **Integer Micrometre Precision:** $1/8"$ circular pitch is exactly $3,175\text{ }\mu\text{m}$, eliminating $2.99999999\text{ mm}$ false rejections.
- **Shop-Floor Tolerance Strategy:** Standard $\ge 3.000\text{ mm}$ approval; warning with required override reason for legacy $2.400 - 2.999\text{ mm}$ tooling; hard mechanical block for $< 2.400\text{ mm}$.
- **Cylinder Fleet Management:** Direct support for the 16 fleet sizes: **66, 68, 72, 76, 82, 86, 90, 94, 96, 98, 102, 106, 112, 120, 126, 132 Teeth**.
- **Interactive Keyline Calculator:** Instant multi-ups recommendation matrix, waste percentage optimization, and web-width fit validation.
- **Die Reuse Finder:** Matches active die inventory against label requests to minimize new tooling expenses.
- **Reporting Engine:** Native **VittixReport** support with PDF and label card generation.

---

## Repository Structure

```
DieVix/
├── docs/
│   └── DIEVIX_DESIGN_SPECIFICATION.md   # Complete architecture & design blueprint
├── src/
│   ├── Engine/
│   │   └── DieVix.CalculationEngine.pas # Pure Pascal integer micrometre engine
│   └── Database/
│       └── DieVix_Schema_Firebird5.sql  # Firebird 5.0 DDL & seed dataset
├── tests/
│   ├── DieVixTests.dpr                  # DUnitX test suite runner
│   ├── DieVixTests.dproj                # Delphi 12 project file
│   ├── DieVixCalculationTests.pas       # Unit tests (boundary, noise, fit, recommendation)
│   └── build_and_run_tests.bat          # Command-line compilation & execution
├── bin/                                 # Compiled binaries
└── dcu/                                 # Intermediate compilation units
```

---

## Running the Automated Tests

The test suite validates the calculation engine against floating-point boundary noise, fleet repeats, and cylinder recommendation algorithms using DUnitX:

```cmd
cd tests
build_and_run_tests.bat
```

All 10 tests execute synchronously and output full verification results directly to the console.
