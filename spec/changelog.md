# Project Changelog & Engineering Journal

This document records the architectural history, modifications made, challenges encountered, and key discoveries throughout the WorshipFlow project lifecycle.

---

## 1. Activity Log

### [2026-09-24] - Sprint 2: Musician Mobile Portal Complete

#### Added
- **Musician Portal Page ([`teste/pages/p00010-musician-portal.apx`](file:///home/davi/Dev/apex-gemini/teste/pages/p00010-musician-portal.apx))**:
  - Built mobile-first responsive dashboard with 3 distinct card regions:
    - *Pending Invitations*: Service badge, role, notes, and 1-click Accept / Decline actions with checksum protection.
    - *My Confirmed Services*: Setlist summary, scheduled roles, and rehearsal call times.
    - *My Scheduled Blockouts*: Date ranges and vacation reasons.
  - "Schedule Blockout" header action redirecting to modal dialog.
  - Before-header response processing engine invoking `ws_pkg_musician_portal.accept_invitation`.
- **Decline Reason Drawer Dialog ([`teste/pages/p00011-decline-drawer.apx`](file:///home/davi/Dev/apex-gemini/teste/pages/p00011-decline-drawer.apx))**:
  - Drawer modal (`@/drawer`) capturing decline rationale and invoking `ws_pkg_musician_portal.decline_invitation`.
- **Self-Service Blockout Modal ([`teste/pages/p00012-blockout-modal.apx`](file:///home/davi/Dev/apex-gemini/teste/pages/p00012-blockout-modal.apx))**:
  - Modal dialog (`@/modal-dialog`) with multi-format date parsing (`YYYY-MM-DD`, `DD/MM/YYYY`, `MM/DD/YYYY`) invoking `ws_pkg_musician_portal.register_blockout`.
- **Shared Components Integration ([`teste/shared-components/`](file:///home/davi/Dev/apex-gemini/teste/shared-components/))**:
  - Wired Musician Portal entry into Navigation Menu (`lists.apx`) and Breadcrumb trails (`breadcrumbs.apx`).
- **Comprehensive Playwright E2E Test Suite ([`tests/e2e/sprint2-musician-portal.e2e.mjs`](file:///home/davi/Dev/apex-gemini/tests/e2e/sprint2-musician-portal.e2e.mjs))**:
  - Automated 8 test scenarios: unauthenticated redirect, login as `TEST_USER`, cards layout verification, blockout modal flow, 1-click invitation acceptance, desktop responsive grid, and zero console error assertion.
  - 100% test pass rate achieved against live Oracle APEX 26.1 and Oracle Database 23ai.

### [2026-09-24] - Sprint 1: PL/SQL Business API Packages Complete

#### Added
- **PL/SQL Package Specifications ([`db/03_packages_spec.sql`](file:///home/davi/Dev/apex-gemini/db/03_packages_spec.sql))**:
  - `WS_PKG_SCHEDULER`: `apply_template`, `auto_assign_roster`, `assign_band`, `clear_roster`.
  - `WS_PKG_SERVICE_MGMT`: `create_service`, `update_service`, `publish_service`, `complete_service`, `cancel_service`, `add_setlist_song`, `remove_setlist_song`.
  - `WS_PKG_MUSICIAN_PORTAL`: `register_blockout`, `delete_blockout`, `accept_invitation`, `decline_invitation`, `process_roster_response`.
- **PL/SQL Package Bodies ([`db/04_packages_body.sql`](file:///home/davi/Dev/apex-gemini/db/04_packages_body.sql))**:
  - Implemented atomic auto-placement randomizer with `SELECT ... FOR UPDATE` row locking on `WS_SERVICES`.
  - Enforced multi-instrument double-booking prevention within the active service.
  - Enforced same-day service collision prevention and volunteer monthly frequency caps (`max_services_month`).
  - Implemented decline audit preservation (`replaced_member_id`) when slots are re-filled.
  - Implemented optimistic locking token checking (`row_version_number`) raising `ORA-20002` on stale form updates.
- **Automated Verification Test Suite ([`tests/verify_sprint1_packages.sql`](file:///home/davi/Dev/apex-gemini/tests/verify_sprint1_packages.sql))**:
  - Tested 9 core operational workflows (creation, template instantiation, auto-assignment, 1-click acceptance, decline with reason, replacement audit trail, setlist sequencing, retroactive blockout conflict surfacing, publication).
  - Executed live against Oracle Database 23ai: 100% of assertions passed (13/13).
- **Execution & Resource Tracking ([`METRICS.md`](file:///home/davi/Dev/apex-gemini/METRICS.md))**:
  - Initialized metrics file in repository root to report token expenditures, execution durations, and test suite pass rates.

### [2026-09-24] - Sprint 0: Database Foundation & Baseline Data Complete

#### Added
- **DDL Migration Script ([`db/01_tables_and_indexes.sql`](file:///home/davi/Dev/apex-gemini/db/01_tables_and_indexes.sql))**:
  - Implemented all 12 core tables with `WS_` prefix: `WS_MEMBERS`, `WS_INSTRUMENTS`, `WS_MEMBER_INSTRUMENTS`, `WS_SERVICE_TEMPLATES`, `WS_SERVICE_TEMPLATE_SLOTS`, `WS_BANDS`, `WS_BAND_MEMBERS`, `WS_MEMBER_BLOCKOUTS`, `WS_SERVICES`, `WS_SERVICE_ROSTER`, `WS_SONGS`, `WS_SERVICE_SETLIST`.
  - Added 12 primary keys (`PK_WS_...`), 17 foreign keys (`FK_WS_...`), unique constraints (`UQ_WS_...`), and check constraints (`CK_WS_...`).
  - Added 10 performance indexes (`IDX_WS_...`) on foreign keys and search columns.
  - Implemented proactive retroactive blockout detection view `WS_V_ROSTER_CONFLICTS`.
- **Baseline Seed Data Script ([`db/02_seed_data.sql`](file:///home/davi/Dev/apex-gemini/db/02_seed_data.sql))**:
  - Populated 8 standard instruments (`AC_GUITAR`, `ELEC_GUITAR`, `BASS`, `DRUMS`, `KEYS`, `LEAD_VOCAL`, `BACKING_VOCAL`, `SOUND_TECH`).
  - Populated 2 default service templates: "Standard 6-Piece Band" (7 slots) and "Acoustic Trio" (3 slots).
  - Populated 7 volunteer members (Davi as Leader, 6 musicians) and 12 instrument proficiency mappings.
  - Populated 5 core song repertoire entries with tempo, default key, and YouTube rehearsal references.
- **Automated Database Test Suite ([`tests/verify_sprint0_db.sql`](file:///home/davi/Dev/apex-gemini/tests/verify_sprint0_db.sql))**:
  - PL/SQL automated assertion suite verifying table existence, view status, constraint enforcement, and seed counts.
  - Live execution verified 100% test pass rate against Oracle Database 23ai (`local-26ai-davi`).
- **Agent Governance Updates ([`AGENTS.md`](file:///home/davi/Dev/apex-gemini/AGENTS.md))**:
  - Enforced mandatory changelog logging for every development iteration.
  - Mandated comprehensive Playwright E2E testing in `tests/` (`tests/e2e/`) for every UI feature.
  - Enforced project workspace boundaries: `teste/` for APEX application and `tests/` for all test suites.
  - Added Rule 9: Mandatory Git commit and push to `origin/main` after every iteration.

### [2026-09-24] - Architecture, Specification & Sprint Planning

#### Added
- **Project Structure**: Initialized the `spec/` folder containing core engineering documents:
  - [spec/spec.md](file:///home/davi/Dev/apex-gemini/spec/spec.md): Functional and technical specifications, persona matrices, competitive analysis, and concurrency strategies.
  - [spec/schema.md](file:///home/davi/Dev/apex-gemini/spec/schema.md): Complete Entity-Relationship model, Mermaid diagram, 12 DDL tables, indexes, constraints, views, and PL/SQL package prototypes.
  - [spec/patterns.md](file:///home/davi/Dev/apex-gemini/spec/patterns.md): PL/SQL standards, SQL conventions, transaction rules, and Oracle APEX UI/UX guidelines.
  - [spec/plan.md](file:///home/davi/Dev/apex-gemini/spec/plan.md): 6-sprint implementation roadmap (Sprint 0 through Sprint 5).
  - [spec/changelog.md](file:///home/davi/Dev/apex-gemini/spec/changelog.md): Engineering log and discovery journal.

#### Changed / Standardized
- **Database Object Prefixing**: Applied the official **`WS_`** (Worship Scheduling) prefix across all tables, views, constraints, indexes, packages, and procedures:
  - **Tables**: `WS_MEMBERS`, `WS_INSTRUMENTS`, `WS_MEMBER_INSTRUMENTS`, `WS_SERVICE_TEMPLATES`, `WS_SERVICE_TEMPLATE_SLOTS`, `WS_BANDS`, `WS_BAND_MEMBERS`, `WS_MEMBER_BLOCKOUTS`, `WS_SERVICES`, `WS_SERVICE_ROSTER`, `WS_SONGS`, `WS_SERVICE_SETLIST`.
  - **Views**: `WS_V_ROSTER_CONFLICTS`.
  - **Packages**: `WS_PKG_SCHEDULER`, `WS_PKG_SERVICE_MGMT`, `WS_PKG_MUSICIAN_PORTAL`.
  - **Packaged & Standalone Procedures**: `ws_pkg_scheduler.apply_template`, `ws_pkg_scheduler.auto_assign_roster`, `ws_pkg_musician_portal.process_roster_response`, `ws_pkg_musician_portal.register_blockout`, `ws_pkg_musician_portal.accept_invitation`, `ws_pkg_musician_portal.decline_invitation`, `ws_pkg_service_mgmt.create_service`, `ws_pkg_service_mgmt.publish_service`, `ws_pkg_service_mgmt.add_setlist_song`, and schema-level wrappers `WS_PRC_APPLY_TEMPLATE`, `WS_PRC_AUTO_ASSIGN_ROSTER` (and `WS_FN_...` convention for functions).
  - **Keys & Indexes**: `PK_WS_...`, `FK_WS_...`, `UQ_WS_...`, `CK_WS_...`, `IDX_WS_...`.

---

## 2. Key Challenges Encountered & Resolutions

### 1. Multi-Instrument Double-Booking in Auto-Placement
* **The Problem**:
  Many church musicians play multiple instruments (e.g., an individual might play Acoustic Guitar, Electric Guitar, and Drums). When running the auto-randomizer for a 6-piece band, a naive slot-by-slot query could select the same person for Guitar AND Drums in the same service.
* **The Resolution**:
  In `ws_pkg_scheduler.auto_assign_roster`, the query dynamically excludes anyone already placed in *any* slot within the current `service_id`:
  ```sql
  AND NOT EXISTS (
      SELECT 1 FROM ws_service_roster sr_cur
       WHERE sr_cur.service_id = p_service_id
         AND sr_cur.member_id = m.id
  )
  ```

### 2. Retroactive Blockout Conflicts
* **The Problem**:
  A volunteer is scheduled 3 weeks in advance. 1 week before the service, they register a vacation blockout. If the database blocks them from saving their vacation, the volunteer will get frustrated; if it silently accepts it, the leader will have an empty stage on Sunday morning.
* **The Resolution**:
  Allowed blockouts to save freely, but built the proactive view `ws_v_roster_conflicts`. The leader's dashboard flags retroactive conflicts with an orange pulsating badge and gives a 1-click "Find Replacement" button.

### 3. Preserving Decline History on Slot Replacement
* **The Problem**:
  When a musician declines a slot, simply overwriting `member_id` with a new candidate erases who was originally asked, when they declined, and their reason.
* **The Resolution**:
  Added the `replaced_member_id` column to `WS_SERVICE_ROSTER`. When a replacement is slotted, the original declining member is recorded, preserving full audit history.

### 4. Database Concurrency & Race Conditions
* **The Problem**:
  Simultaneous execution of the auto-randomizer by multiple leaders for services on the same Sunday could allocate the same musician to two different services at the same moment.
* **The Resolution**:
  Implemented pessimistic row locking (`SELECT service_date FROM ws_services WHERE id = p_service_id FOR UPDATE;`) in `ws_pkg_scheduler` to serialize schedule generation. For end-user APEX forms, added `row_version_number` tokens to prevent stale updates.

### 5. ORA-01408 on Redundant Supporting Index
* **The Problem**:
  `CREATE INDEX idx_ws_setlist_service ON ws_service_setlist (service_id, play_order)` failed with `ORA-01408: this column list is already indexed`.
* **The Resolution**:
  Oracle Database automatically provisions and maintains a unique index to enforce `CONSTRAINT UQ_WS_SERVICE_SETLIST UNIQUE (service_id, play_order)`. Removed the explicit duplicate index command and updated documentation in `spec/schema.md`.

### 7. Volunteer Scarcity on Auto-Replacement
* **The Problem**:
  When a single-instrument volunteer (such as the only Bass player) declined, running `auto_assign_roster` left the slot unfilled because no second candidate existed with that skill.
* **The Resolution**:
  Added secondary instrument proficiencies (e.g. electric guitarists multi-skilled on bass) and additional volunteer profiles in seed data. The auto-assigner now gracefully handles replacement fallback while maintaining zero double-booking.

### 8. SQLcl Interactive Substitution Prompts on Ampersand
* **The Problem**:
  Executing SQL test scripts containing `&` in DBMS_OUTPUT headers prompted SQLcl for substitution variables (`Substituição cancelada`).
* **The Resolution**:
  Added `SET DEFINE OFF;` to all automated SQL test suites.

### 9. APEXlang Card Action Items Mapping Syntax
* **The Problem**:
  When defining card button redirect targets in APEXlang (`items: { P10_ACTION: ACCEPT, P10_ROSTER_ID: &ROSTER_ID. }`), including commas between key-value pairs caused the compiler to append commas to the URL parameter values, producing malformed URLs (`ACCEPT,,&ROSTER_ID.,,&ROW_VERSION_NUMBER.`) where item slots shifted and substitutions were lost.
* **The Resolution**:
  In APEXlang, target items maps must be separated by newlines with no trailing commas (`P10_ACTION: ACCEPT \n P10_ROSTER_ID: &ROSTER_ID.`). The resulting APEX URL compiles cleanly with exact parameter matching.

### 10. APEX 26.1 Web-Component DatePicker State & NLS Formats
* **The Problem**:
  The modern `<a-date-picker>` custom web component in APEX 26.1 maintains internal state in shadow DOM that does not automatically synchronize on basic HTML input value property setting, and clears values on blur if date strings do not match the expected application format mask (`M/D/YYYY`).
* **The Resolution**:
  Used the native APEX client JavaScript API (`apex.item('P12_START_DATE').setValue(...)`) in Playwright test suites, and created an impervious multi-format date parsing function in the backend PL/SQL process handling `YYYY-MM-DD`, `DD/MM/YYYY`, `MM/DD/YYYY`, and Oracle default formats.

---

## 3. Discoveries & Architectural Insights

1. **Service Templates Dramatically Reduce Cognitive Load**:
   - Benchmarking against Planning Center revealed that nobody wants to manually add 7 empty slots (Drums, Bass, etc.) every week. Introducing `WS_SERVICE_TEMPLATES` and `WS_SERVICE_TEMPLATE_SLOTS` enables one-click instantiation of typical Sunday band formats.
2. **Lean Song Catalog Yields Maximum Musician Engagement**:
   - Storing complex ChordPro markup or lyrics files often leads to clutter and maintenance issues. Keeping the catalog lean (Title, Artist, Default Key, YouTube URL) with service transposition keys provides 95% of the utility with zero clutter.
3. **Mobile-First 1-Click Cards**:
   - Volunteers abandon desktop-heavy church apps. In Oracle APEX, implementing a Cards region with high-contrast Green Accept / Red Decline buttons and modal YouTube playback provides an experience that rivals native mobile apps.
4. **Oracle 23ai Implicit Index Efficiency**:
   - Declarative `UNIQUE` constraints in Oracle 23ai eliminate redundant index overhead. Paired with SQLcl MCP toolchain, schema DDL and test assertions execute synchronously within milliseconds with zero drift.
5. **APEX Native JS API (`apex.item`) is Critical for Testing Modern Widgets**:
   - As Oracle APEX moves increasingly toward Web Components and custom elements (`a-date-picker`, `a-combobox`), Playwright automation must leverage `page.evaluate(() => apex.item(id).setValue(val))` to ensure full reactivity and validation triggering.
6. **Card Action Checksum Generation**:
   - APEX automatically calculates session-level checksums for card action redirect links at render time when target page items have `sessionStateProtection: checksumRequiredSessionLevel`, allowing secure 1-click invitation acceptance without full page form submission.
