# DieVix - Rotary Die & Keyline Manager
## Application Design Specification & Architecture Blueprint
**Version:** 1.0  
**Target Platform:** Windows 11 Desktop (Delphi 12.2 Athens VCL)  
**Database:** Firebird 5.0 (FireDAC, Embedded and LAN Server modes)  
**Reporting Engine:** VittixReport (FastReport fallback)  
**Tagline:** *Precision in Every Repeat.*

---

## 1. Executive Summary & Purpose

**DieVix** is a specialized, production-grade Windows desktop application purpose-built for label printing and converting plants. In flexographic and digital roll-to-roll label printing, rotary dies cut printed substrates against magnetic or solid cylinders. 

A recurring challenge in production planning is:
1. Selecting the optimal cylinder tooth count ($T$) and repeat length ($R$) for a given label size and ups.
2. Ensuring the around (inter-label) gap meets mechanical cut tolerances (standard $\ge 3.000\text{ mm}$) without excessive substrate waste.
3. Managing real-world shop-floor tolerances (where legacy dies with $2.40 - 2.95\text{ mm}$ gaps must be preserved and warned, not blocked).
4. Preventing floating-point rounding errors (e.g., $2.99999999999999\text{ mm}$) that cause exact $3.000\text{ mm}$ dies to falsely fail validation.
5. Verifying machine web-width fit across label lanes.
6. Promoting rotary die reuse by instantly matching active stock dies against customer label requests.

DieVix replaces ad-hoc spreadsheets and fragile manual calculations with a robust, zero-rounding-error calculation engine, a centralized Firebird 5 database, and a modern, high-productivity Delphi VCL interface.

---

## 2. Mathematical Foundation & Precision Architecture

### 2.1 The 1/8" Standard Circular Pitch
Rotary die cylinders in the label industry adhere to the standard 1/8-inch gear pitch (CP):
$$\text{Pitch} = \frac{1}{8}\text{ inch} = \frac{25.4\text{ mm}}{8} = 3.175\text{ mm}$$

### 2.2 Integer Micrometre ($\mu\text{m}$) Arithmetic
In IEEE-754 double precision floating-point, values like $3.175$ and fractional divisions accumulate rounding noise, leading to discrepancies such as:
$$96 \times 3.175 = 304.79999999999995\text{ mm}$$
$$(304.8 - 3 \times 98.6) / 3 = 2.99999999999999\text{ mm} < 3.000\text{ mm} \implies \text{False Validation Failure!}$$

**The DieVix Solution:**
All linear dimensions in the calculation engine are strictly represented as **integer micrometres** ($\mu\text{m}$), where $1\text{ mm} = 1,000\text{ }\mu\text{m}$.
- $\text{Standard Pitch } P_{\mu m} = 3,175\text{ }\mu\text{m}$ (exact integer, zero precision loss).
- $\text{Cylinder Repeat } R_{\mu m} = \text{Teeth} \times 3,175\text{ }\mu\text{m}$.
- $\text{Repeat in Millimetres } R_{mm} = R_{\mu m} / 1000.0$.
- $\text{Repeat in Inches } R_{inch} = \text{Teeth} / 8.0$.

### 2.3 Around Gap Calculation Formula
For a label of around size $L_{\mu m}$ and $N$ around-ups on cylinder with $T$ teeth:
$$\text{Available Substrate Length } R_{\mu m} = T \times 3175$$
$$\text{Total Cut Size } C_{\mu m} = N \times L_{\mu m}$$
$$\text{Total Gap Pool } \Delta_{\mu m} = R_{\mu m} - C_{\mu m}$$

If $\Delta_{\mu m} < 0$, the label layout is physically impossible on this cylinder.

The individual around gap $G$ between each label is:
$$G_{\mu m} = \left\lfloor \frac{\Delta_{\mu m}}{N} \right\rfloor$$
$$\text{Remainder } r = \Delta_{\mu m} \pmod N$$

### 2.4 Rational Comparison (No Division Rounding)
To check if a gap meets the minimum threshold (e.g., $\text{MinGap}_{\mu m} = 3,000\text{ }\mu\text{m}$):
$$\Delta_{\mu m} \ge N \times \text{MinGap}_{\mu m}$$
This comparison is **exact, integer-based, and eliminates all floating-point operations**.

### 2.5 Waste Percentage Calculation
Waste percentage represents the ratio of non-printed matrix gap to total cylinder repeat:
$$\text{Waste \%} = \frac{\Delta_{\mu m}}{R_{\mu m}} \times 100 = \frac{G_{\mu m}}{L_{\mu m} + G_{\mu m}} \times 100$$
Calculated to two decimal places for operator display.

### 2.6 Across Fit & Web Width Verification
For across ups $K$, label across size $W_{\mu m}$, across gap $S_{\mu m}$, and machine edge margins $M_{left}, M_{right}$:
$$\text{Total Tooling Width } W_{\text{tool}} = (K \times W_{\mu m}) + ((K - 1) \times S_{\mu m})$$
$$\text{Required Minimum Web Width } W_{\text{web}} = W_{\text{tool}} + M_{left} + M_{right}$$
$$\text{Fit Condition: } W_{\text{web}} \le \text{Machine.MaxWebWidth}_{\mu m}$$

---

## 3. Business Policies & Tolerance Strategy

### 3.1 Sub-3 mm Die Handling (Real-World Shop Policy)
Analysis of historical shop tooling revealed dozens of legacy dies operating at $2.40 - 2.95\text{ mm}$ around gaps (predominantly $2.8\text{ mm}$ on 112T and $2.9\text{ mm}$ on 96T).

DieVix implements a **3-tier gap policy**:
| Gap Range ($\mu\text{m}$) | Status | System Action |
|---|---|---|
| $\ge 3,000\text{ }\mu\text{m}$ ($\ge 3.000\text{ mm}$) | **Standard Compliant** | Fully approved, green indicator in calculator and die entry. |
| $2,400\text{ }\mu\text{m}$ to $2,999\text{ }\mu\text{m}$ ($2.400 - 2.999\text{ mm}$) | **Sub-Standard Warning** | Allowed with warning banner. Die record prompts for an `OVERRIDE_REASON` (e.g., "Legacy tooling standard - approved by production"). |
| $< 2,400\text{ }\mu\text{m}$ ($< 2.400\text{ mm}$) | **Mechanically Rejected** | Hard block. Rotary die blades cannot physically strip matrix reliably below $2.4\text{ mm}$. |

### 3.2 Cylinder Fleet Seed Data
The existing shop fleet comprises 16 specific tooth sizes:
**66, 68, 72, 76, 82, 86, 90, 94, 96, 98, 102, 106, 112, 120, 126, 132**

Because these are not evenly spaced arithmetic steps, cylinder sizes are stored as discrete, editable database records in `CYLINDER_SIZE` with active/inactive flags.

---

## 4. Database Schema (Firebird 5.0 DDL)

All physical dimensions are stored as `NUMERIC(9,3)` (millimetres with 3 decimal places / micrometre fidelity) to maintain clarity while supporting exact mapping to $\mu\text{m}$ integers ($value \times 1000$).

```sql
/* =====================================================================
   DieVix – Firebird 5.0 Database Schema
   ===================================================================== */

-- 1. Application Settings
CREATE TABLE APP_SETTING (
    SETTING_KEY VARCHAR(50) NOT NULL PRIMARY KEY,
    SETTING_VALUE VARCHAR(255) NOT NULL,
    DESCRIPTION VARCHAR(255)
);

-- Seed Settings
INSERT INTO APP_SETTING (SETTING_KEY, SETTING_VALUE, DESCRIPTION) 
VALUES ('MIN_AROUND_GAP_UM', '3000', 'Default minimum around gap in micrometres (3.000 mm)');
INSERT INTO APP_SETTING (SETTING_KEY, SETTING_VALUE, DESCRIPTION) 
VALUES ('WARN_AROUND_GAP_UM', '2400', 'Lowest allowable around gap requiring override reason (2.400 mm)');
INSERT INTO APP_SETTING (SETTING_KEY, SETTING_VALUE, DESCRIPTION) 
VALUES ('DEFAULT_ACROSS_GAP_MM', '3.000', 'Default across gap in mm');
INSERT INTO APP_SETTING (SETTING_KEY, SETTING_VALUE, DESCRIPTION) 
VALUES ('DEFAULT_CORNER_RADIUS_MM', '2.000', 'Default die corner radius in mm');
INSERT INTO APP_SETTING (SETTING_KEY, SETTING_VALUE, DESCRIPTION) 
VALUES ('DEFAULT_EDGE_MARGIN_MM', '5.000', 'Default edge margin per side in mm');

-- 2. Customer Master
CREATE TABLE CUSTOMER (
    ID INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CODE VARCHAR(20) NOT NULL UNIQUE,
    NAME VARCHAR(100) NOT NULL,
    CONTACT_PERSON VARCHAR(100),
    PHONE VARCHAR(50),
    EMAIL VARCHAR(100),
    CITY VARCHAR(50),
    IS_ACTIVE SMALLINT DEFAULT 1 NOT NULL,
    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 3. Media Substrates (Face & Liner Separation)
CREATE TABLE MEDIA (
    ID INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NAME VARCHAR(100) NOT NULL,
    FACE_MATERIAL VARCHAR(80),      -- e.g., Semi-Gloss Paper, PP White, PE Clear, Direct Thermal
    LINER_MATERIAL VARCHAR(80),     -- e.g., Glassine 62gsm, PET 30um, Kraft
    ADHESIVE_TYPE VARCHAR(50),      -- e.g., Acrylic Permanent, Hotmelt, Removable
    TOTAL_CALIPER_UM INTEGER,       -- Total thickness in micrometres
    NOTES VARCHAR(255),
    IS_ACTIVE SMALLINT DEFAULT 1 NOT NULL
);

-- 4. Die Status Codes
CREATE TABLE DIE_STATUS (
    CODE VARCHAR(20) NOT NULL PRIMARY KEY,
    DESCRIPTION VARCHAR(50) NOT NULL,
    IS_USABLE SMALLINT DEFAULT 1 NOT NULL,
    BADGE_COLOR VARCHAR(20) DEFAULT 'Green'
);

INSERT INTO DIE_STATUS (CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR) VALUES ('ACTIVE', 'In Stock / Active', 1, 'Green');
INSERT INTO DIE_STATUS (CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR) VALUES ('IN_REPAIR', 'Out for Sharpening / Repair', 0, 'Orange');
INSERT INTO DIE_STATUS (CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR) VALUES ('ON_ORDER', 'New Tooling on Order', 0, 'Blue');
INSERT INTO DIE_STATUS (CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR) VALUES ('SCRAPPED', 'Damaged / Retired', 0, 'Red');
INSERT INTO DIE_STATUS (CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR) VALUES ('RESERVED', 'Reserved for Job', 1, 'Purple');

-- 5. Cylinder Fleet
CREATE TABLE CYLINDER_SIZE (
    TEETH INTEGER NOT NULL PRIMARY KEY,
    PITCH_UM INTEGER DEFAULT 3175 NOT NULL,
    REPEAT_MM COMPUTED BY (TEETH * PITCH_UM / 1000.0),
    REPEAT_INCH COMPUTED BY (TEETH / 8.0),
    IS_ACTIVE SMALLINT DEFAULT 1 NOT NULL,
    NOTES VARCHAR(100)
);

-- 6. Machine Master
CREATE TABLE MACHINE (
    ID INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CODE VARCHAR(20) NOT NULL UNIQUE,
    NAME VARCHAR(80) NOT NULL,
    MAX_WEB_WIDTH_MM NUMERIC(9,3) NOT NULL,
    MIN_WEB_WIDTH_MM NUMERIC(9,3) DEFAULT 50.000 NOT NULL,
    DEFAULT_MARGIN_MM NUMERIC(9,3) DEFAULT 5.000 NOT NULL,
    PRINT_METHOD VARCHAR(50),       -- Flexo, Digital Hybrid, Offset
    NOTES VARCHAR(255),
    IS_ACTIVE SMALLINT DEFAULT 1 NOT NULL
);

-- 7. Machine-Cylinder Compatibility Assignment
CREATE TABLE MACHINE_CYLINDER (
    MACHINE_ID INTEGER NOT NULL REFERENCES MACHINE(ID) ON DELETE CASCADE,
    TEETH INTEGER NOT NULL REFERENCES CYLINDER_SIZE(TEETH) ON DELETE CASCADE,
    PRIMARY KEY (MACHINE_ID, TEETH)
);

-- 8. Die Master Register
CREATE TABLE DIE (
    ID INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    SERIAL_NO VARCHAR(30) NOT NULL UNIQUE,
    CUSTOMER_ID INTEGER REFERENCES CUSTOMER(ID),
    MEDIA_ID INTEGER REFERENCES MEDIA(ID),
    TEETH INTEGER NOT NULL REFERENCES CYLINDER_SIZE(TEETH),
    AROUND_SIZE_MM NUMERIC(9,3) NOT NULL,
    ACROSS_SIZE_MM NUMERIC(9,3) NOT NULL,
    AROUND_UPS INTEGER DEFAULT 1 NOT NULL,
    ACROSS_UPS INTEGER DEFAULT 1 NOT NULL,
    ACROSS_GAP_MM NUMERIC(9,3) DEFAULT 3.000 NOT NULL,
    CORNER_RADIUS_MM NUMERIC(9,3) DEFAULT 2.000 NOT NULL,
    SHAPE VARCHAR(30) DEFAULT 'RECTANGLE' NOT NULL, -- RECTANGLE, CIRCLE, OVAL, SPECIAL
    STORAGE_LOCATION VARCHAR(50),
    STATUS_CODE VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL REFERENCES DIE_STATUS(CODE),
    OVERRIDE_REASON VARCHAR(255),                  -- Required if calculated around gap < 3.000 mm
    PURCHASE_DATE DATE,
    DIE_MAKER VARCHAR(100),
    TOTAL_RUN_METRES INTEGER DEFAULT 0,
    NOTES BLOB SUB_TYPE TEXT,
    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UPDATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Calculated Virtual Dimension in Firebird
    COMPUTED_REPEAT_MM COMPUTED BY (TEETH * 3.175),
    COMPUTED_AROUND_GAP_MM COMPUTED BY (
        (TEETH * 3.175 - (AROUND_UPS * AROUND_SIZE_MM)) / NULLIF(AROUND_UPS, 0)
    )
);

CREATE INDEX IDX_DIE_DIMS ON DIE (AROUND_SIZE_MM, ACROSS_SIZE_MM, TEETH, AROUND_UPS);
CREATE INDEX IDX_DIE_STATUS ON DIE (STATUS_CODE);

-- 9. Legacy Keyline Staging Table (For Clean Migration)
CREATE TABLE STAGING_LEGACY_KEYLINE (
    ID INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    RAW_SERIAL VARCHAR(100),
    RAW_CUSTOMER VARCHAR(150),
    RAW_MEDIA VARCHAR(255),
    RAW_TEETH VARCHAR(50),
    RAW_AROUND_SIZE VARCHAR(50),
    RAW_ACROSS_SIZE VARCHAR(50),
    RAW_AROUND_UPS VARCHAR(50),
    RAW_ACROSS_UPS VARCHAR(50),
    RAW_AROUND_GAP VARCHAR(50),
    RAW_ACROSS_GAP VARCHAR(50),
    RAW_RADIUS VARCHAR(50),
    IMPORT_STATUS VARCHAR(30) DEFAULT 'PENDING',  -- PENDING, IMPORTED, REJECTED, WARNING_SUB3MM
    CLEANED_DIE_ID INTEGER REFERENCES DIE(ID),
    VALIDATION_NOTE VARCHAR(255)
);
```

---

## 5. Screen Layouts & User Experience Design

### 5.1 Main Application Shell & Navigation
- **Architecture:** Windows 11 Modern VCL Theme, standard high-DPI scaling (Per-Monitor V2).
- **Navigation Sidebar:**
  1. 📊 **Dashboard** (Fleet statistics, active dies, shortcut launcher)
  2. ⚡ **Keyline Calculator** (Production engine, recommendation grid, visual cut preview)
  3. 🏷️ **Die Master** (Complete tooling inventory, advanced search, live gap badge)
  4. ⚙️ **Cylinder & Machine Master** (Matrix assignment grid)
  5. 👥 **Customers & Substrates** (Face/liner master records)
  6. 📑 **Reports** (Die Cards, Inventory Listings, Matrix PDF/Excel)
  7. 🛠️ **Settings** (Gap policies, tolerances, database backup)

### 5.2 Keyline Calculator — The Core Screen
The calculator is engineered for rapid sub-second operator decisions.

```
+---------------------------------------------------------------------------------------------------------+
|  ⚡ KEYLINE CALCULATOR — Rotary Die Layout Optimization                                                  |
+---------------------------------------------------------------------------------------------------------+
|  INPUT PARAMETERS                                    |  MACHINE SELECTION & LIMITS                     |
|  Label Around (mm): [ 100.000 ]                     |  Target Machine: [ Mark Andy 2200 - 10"  v ]     |
|  Label Across (mm): [  60.000 ]                     |  Usable Web Width: 254.000 mm                    |
|  Across Ups:        [ 3       ]                     |  Edge Margin (ea): 5.000 mm                      |
|  Across Gap (mm):   [ 3.000   ]                     |  Required Web:     196.000 mm [ FIT APPROVED ]   |
|  Min Around Gap:    [ 3.000   ]                     |  Scan Ups Range:   [ 1 ] to [ 6 ]                |
+---------------------------------------------------------------------------------------------------------+
|  OPTIMAL CYLINDER RECOMMENDATIONS (Pitch: 3.175 mm / 1/8" CP)                                            |
|  Ups | Teeth | Repeat mm | Repeat in | Around Gap  | Waste % | Status           | Machines Supported    |
|------+-------+-----------+-----------+-------------+---------+------------------+-----------------------|
|   3  |  98T  |  311.150  |  12.250"  |   3.717 mm  |  3.58%  | ⭐ OPTIMAL (Best)| MA-2200, Nilpeter FB3 |
|   3  | 102T  |  323.850  |  12.750"  |   7.950 mm  |  7.36%  | Acceptable       | MA-2200               |
|   3  | 106T  |  336.550  |  13.250"  |  12.183 mm  | 10.86%  | Acceptable       | MA-2200, Gallus ECS   |
|   3  |  96T  |  304.800  |  12.000"  |   1.600 mm  |  1.57%  | ⚠️ Gap Too Small | MA-2200, Nilpeter FB3 |
+---------------------------------------------------------------------------------------------------------+
|  MATCHING EXISTING DIES IN STOCK (For Selected 98T - 3 Ups)                                             |
|  Serial No  | Customer            | Shape     | Across | Corner Rad | Location | Status    | Action    |
|  RD-00412   | Sun Pharma Ltd      | Rectangle | 60 mm  | R 2.0 mm   | Rack B-04| ACTIVE    | [USE DIE] |
|  RD-00891   | Varni Healthcare    | Rectangle | 59.5mm | R 1.5 mm   | Rack C-12| ACTIVE    | [USE DIE] |
+---------------------------------------------------------------------------------------------------------+
|  [ 📐 Visual Layout Preview ]   [ 🖨️ Print Keyline Sheet ]   [ ➕ Create New Die From Selection ]        |
+---------------------------------------------------------------------------------------------------------+
```

### 5.3 Die Master Add / Edit Form — Validation & Warning Flow
- When user enters `Around Size`, `Teeth`, and `Around Ups`:
  - Instant live recalculation of `Around Gap` with integer precision.
  - **Badge Display:**
    - If `Gap >= 3.000 mm`: 🟢 **Legal Gap: 3.717 mm (Approved)**
    - If `2.400 mm <= Gap < 3.000 mm`: 🟡 **Sub-3mm Gap: 2.800 mm (Warning - Override Required)**
      - Form automatically expands an `Override Reason` input box (required to save).
    - If `Gap < 2.400 mm`: 🔴 **Gap Mechanically Rejected: 1.600 mm (Strip failure risk)**
      - Save button disabled.
  - **Duplicate Serial Detection:** Live asynchronous database validation against existing serial numbers.

### 5.4 Machine-Cylinder Matrix Screen
A responsive 2D cross-tab grid:
- Rows: Production Machines (e.g., Mark Andy, Nilpeter, Gallus).
- Columns: Cylinder Teeth (66T, 68T, 72T ... 132T).
- Fast click-toggle to assign or unassign cylinders per press, stored instantly in `MACHINE_CYLINDER`.

---

## 6. Reporting Architecture (VittixReport)

1. **Die Tooling Card (Job Bag Card):**
   - Serial number, Barcode / QR Code.
   - Cylinder specifications: Teeth, Repeat mm, Repeat in.
   - Label dimensions: Around, Across, Around Gap, Across Gap, Corner Radius.
   - Compatible presses and rack storage location.
   - Vector preview diagram of repeat cut layout.
2. **Die Master Register List:**
   - Filtered inventory reports grouped by Teeth, Customer, or Status.
3. **Machine Fleet Cylinder Matrix:**
   - Printable tooling availability sheet for production planners.

---

## 7. Implementation Roadmap & Milestones

1. **Phase 1: Foundation (Core Engine & Data Schema)**
   - Delphi calculation engine unit (`DieVix.CalculationEngine.pas`) using pure integer micrometres.
   - DUnitX unit test suite validating boundary conditions, 3.000 mm thresholds, sub-3mm warnings, and floating-point elimination.
   - Firebird 5.0 DDL database script with seed data for the 16 cylinder sizes and application settings.

2. **Phase 2: Master Management Modules**
   - FireDAC Database Connection Manager (supporting both Embedded and LAN Server modes).
   - Entity models and repository layer.
   - Master VCL Forms: Cylinders, Machines, Machine-Cylinder Assignment Grid, Customers, Media (face/liner), Die Statuses.

3. **Phase 3: Die Master & Inventory Register**
   - Searchable, high-performance VirtualTreeView / DBGrid die list with instant filtering.
   - Die Add/Edit form with live gap badge, duplicate serial validation, and override reason capture.

4. **Phase 4: Keyline Calculator & Tooling Reuse Finder**
   - Multi-ups cylinder recommendation engine.
   - Machine web-width and edge margin validation.
   - Live existing die match drawer.
   - Visual keyline vector preview component.
   - "Create Die from Selection" transfer workflow.

5. **Phase 5: Reporting & Export**
   - VittixReport integration for Die Production Cards and Tooling Catalogs.
   - PDF export and Excel export.

6. **Phase 6: Legacy Keyline Data Migration & Hardening**
   - Staging table import script for historical dump rows.
   - Automated cleaning of customer, media, and gap values.
   - System deployment package.
