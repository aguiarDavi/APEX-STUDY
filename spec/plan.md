# WorshipFlow: Development Sprint Plan

This plan organizes the implementation of the WorshipFlow system into focused, iterative sprints from database architecture to production-ready Oracle APEX application.

---

## Sprint Overview Roadmap

```mermaid
flowchart LR
    S0[Sprint 0: DB Foundation & DDL] --> S1[Sprint 1: PL/SQL Core APIs]
    S1 --> S2[Sprint 2: Musician Mobile Portal]
    S2 --> S3[Sprint 3: Leader Scheduling Matrix]
    S3 --> S4[Sprint 4: Repertoire & Setlists]
    S4 --> S5[Sprint 5: Auth, Polish & Verification]
```

| Sprint | Focus Area | Deliverables | Est. Scope |
| :--- | :--- | :--- | :--- |
| **Sprint 0** | **Database DDL & Baseline Data** | DDL migration scripts, tables, constraints, indexes, views, seed data | 100% DB |
| **Sprint 1** | **PL/SQL Business API Packages** | `ws_pkg_scheduler`, `ws_pkg_service_mgmt`, `ws_pkg_musician_portal` | 100% PL/SQL |
| **Sprint 2** | **Musician Mobile Portal (APEX)** | Mobile dashboard, card invites (Accept/Decline), blockout management | APEX UI + DB |
| **Sprint 3** | **Leader Scheduling Matrix (APEX)**| Service templates, smart LOVs, auto-placement button, conflict views | APEX UI + DB |
| **Sprint 4** | **Song Repertoire & Setlist Builder**| Songs catalog, YouTube preview modal, service transposition keys | APEX UI |
| **Sprint 5** | **Security, Testing & Verification**| APEX Authorization Schemes, concurrency hardening, UAT test suite | QA + Polish |

---

## Detailed Sprint Specifications

### Sprint 0: Database Foundation & Baseline Data
* **Objective**: Create the entire declarative database layer in Oracle Database using the `WS_` prefix.
* **Tasks**:
  1. Write and execute DDL script `01_tables_and_indexes.sql`:
     - Tables: `WS_MEMBERS`, `WS_INSTRUMENTS`, `WS_MEMBER_INSTRUMENTS`, `WS_SERVICE_TEMPLATES`, `WS_SERVICE_TEMPLATE_SLOTS`, `WS_BANDS`, `WS_BAND_MEMBERS`, `WS_MEMBER_BLOCKOUTS`, `WS_SERVICES`, `WS_SERVICE_ROSTER`, `WS_SONGS`, `WS_SERVICE_SETLIST`.
     - Primary Keys, Foreign Keys with cascading rules, Unique constraints, and Check constraints (e.g. valid musical keys, dates).
     - Performance indexes on foreign keys, dates, and lookup codes.
  2. Create view `ws_v_roster_conflicts` for retroactive blockout detection.
  3. Write seed script `02_seed_data.sql`:
     - Standard Instruments (`AC_GUITAR`, `ELEC_GUITAR`, `BASS`, `DRUMS`, `KEYS`, `LEAD_VOCAL`, `BACKING_VOCAL`).
     - Default Service Templates ("Standard 6-Piece Band", "Acoustic Trio").
     - Sample members, instruments, and demo songs with YouTube links.
* **Exit Criteria**: All 12 tables and 1 view compiled without errors; seed data queryable.

---

### Sprint 1: PL/SQL Business API Packages
* **Objective**: Encapsulate all business logic, transactions, and scheduling algorithms in autonomous packages.
* **Tasks**:
  1. Build package `ws_pkg_scheduler`:
     - `apply_template(p_service_id, p_template_id)`: Instantiates roster slots from templates.
     - `auto_assign_roster(p_service_id)`: Atomic randomizer with `SELECT ... FOR UPDATE`, multi-slot exclusion, blockout check, and monthly service cap.
  2. Build package `ws_pkg_service_mgmt`:
     - Service CRUD lifecycle (`DRAFT` $\rightarrow$ `PUBLISHED` $\rightarrow$ `COMPLETED`).
     - Setlist management (reordering songs, adding songs, setting service key).
  3. Build package `ws_pkg_musician_portal`:
     - `register_blockout(p_member_id, p_start_date, p_end_date, p_reason)`.
     - `accept_invitation(p_roster_id, p_row_version)`.
     - `decline_invitation(p_roster_id, p_reason, p_row_version)`.
* **Exit Criteria**: Unit tests pass verifying auto-placement, decline handling, and row version conflict detection.

---

### Sprint 2: Musician Mobile Portal (APEX UI)
* **Objective**: Deliver a frictionless mobile-first experience for musicians to control availability and respond to invitations.
* **Tasks**:
  1. Create Musician Portal page (Page 1 / `/musician`):
     - Filtered by `:APP_USER = m.username`.
     - Actionable Cards Region for pending invitations with prominent Green Accept & Red Decline buttons.
  2. Create Decline Drawer Dialog (Page 2):
     - Captures optional decline reason and executes `ws_pkg_musician_portal.decline_invitation`.
  3. Create My Upcoming Services Region:
     - Shows confirmed dates, band members, and setlist with direct YouTube rehearsal links.
  4. Create Self-Service Blockout Modal (Page 3):
     - Date-range picker for musicians to record vacations or off-Sundays.
* **Exit Criteria**: Musician can log in on mobile, register a blockout, and accept/decline an invite in under 5 seconds.

---

### Sprint 3: Leader Scheduling Matrix & Management (APEX UI)
* **Objective**: Provide worship leaders with an efficient dashboard to create services, auto-fill bands, and resolve conflicts.
* **Tasks**:
  1. Build Leader Overview Dashboard (Page 10 / `/leader`):
     - KPI cards: Upcoming Services, Unfilled Slots, Pending Confirmations, Conflicts count.
     - Interactive Report of upcoming services.
  2. Build Service Detail & Scheduling Matrix (Page 20):
     - Header: Service details, status badge, date, notes.
     - Matrix Grid: Lists all instrument slots with real-time status badges (`PENDING`, `ACCEPTED`, `DECLINED`, `CONFLICT`).
     - Toolbar buttons:
       - *"Instantiate Template"* (modal to pick template).
       - *"Auto-Fill Available Musicians"* (calls `ws_pkg_scheduler.auto_assign_roster`).
       - *"Publish Roster"* (switches status to `PUBLISHED`).
  3. Implement Smart LOV in Grid:
     - Shows eligible musicians, tagging who is blocked out or already playing.
  4. Conflict Resolution Panel:
     - Region querying `ws_v_roster_conflicts` with quick "Find Replacement" button.
* **Exit Criteria**: Leader can instantiate a template, auto-fill a band, and resolve declined slots seamlessly.

---

### Sprint 4: Song Repertoire & Setlist Builder (APEX UI)
* **Objective**: Streamline song management and setlist execution.
* **Tasks**:
  1. Repertoire Management (Page 30 / `/songs`):
     - Searchable Cards / Interactive Report with Title, Artist, Default Key, BPM, and YouTube link badge.
     - Modal form to add/edit songs with valid musical key LOV.
  2. Service Setlist Sub-region (on Page 20):
     - Add songs to the active service.
     - Transposition Key selector (`service_key`).
     - Inline YouTube player modal or pop-out drawer to listen to song arrangements.
* **Exit Criteria**: Leader can add songs to a service, assign custom keys, and volunteers can listen to the YouTube link directly.

---

### Sprint 5: Security, APEX Authorization, Testing & Hardening
* **Objective**: Enforce role-based access control, run concurrency tests, and polish user experience.
* **Tasks**:
  1. Implement APEX Authorization Schemes:
     - `WS_AUTH_LEADER`: Access to service creation, scheduling matrix, template management.
     - `WS_AUTH_MUSICIAN`: Access to personal portal, invitations, and blockout calendar.
  2. Concurrency & Stress Testing:
     - Test concurrent auto-placement runs on simultaneous services.
     - Verify optimistic locking prevents stale updates on musician response.
     - Verify retroactive blockouts trigger dashboard badges.
  3. UI/UX Polishing:
     - Responsive mobile check, Universal Theme icon alignments, feedback messages.
* **Exit Criteria**: Zero authorization bypasses; all edge cases tested and verified; app ready for pilot.
