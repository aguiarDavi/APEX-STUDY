# Project Changelog & Engineering Journal

This document records the architectural history, modifications made, challenges encountered, and key discoveries throughout the WorshipFlow project lifecycle.

---

## 1. Activity Log

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

---

## 3. Discoveries & Architectural Insights

1. **Service Templates Dramatically Reduce Cognitive Load**:
   - Benchmarking against Planning Center revealed that nobody wants to manually add 7 empty slots (Drums, Bass, etc.) every week. Introducing `WS_SERVICE_TEMPLATES` and `WS_SERVICE_TEMPLATE_SLOTS` enables one-click instantiation of typical Sunday band formats.
2. **Lean Song Catalog Yields Maximum Musician Engagement**:
   - Storing complex ChordPro markup or lyrics files often leads to clutter and maintenance issues. Keeping the catalog lean (Title, Artist, Default Key, YouTube URL) with service transposition keys provides 95% of the utility with zero clutter.
3. **Mobile-First 1-Click Cards**:
   - Volunteers abandon desktop-heavy church apps. In Oracle APEX, implementing a Cards region with high-contrast Green Accept / Red Decline buttons and modal YouTube playback provides an experience that rivals native mobile apps.
