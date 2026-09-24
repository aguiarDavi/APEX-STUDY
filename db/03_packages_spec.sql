-- ============================================================================
-- WorshipFlow: Sprint 1 - PL/SQL Business API Packages (Specifications)
-- Script: db/03_packages_spec.sql
-- Description: Core package specifications for Scheduler, Service Mgmt, and Musician Portal.
-- Target: Oracle Database 23ai / 19c+ (Prefix: WS_PKG_)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. WS_PKG_SCHEDULER
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE ws_pkg_scheduler AS
    /**
     * Instantiates empty roster slots for a service based on a service template.
     * Prevents duplicate slots for the same instrument and slot number.
     */
    PROCEDURE apply_template (
        p_service_id  IN NUMBER,
        p_template_id IN NUMBER
    );

    /**
     * Executes the smart auto-assignment randomizer algorithm to populate empty
     * or declined slots. Enforces blockout checking, double-booking exclusion,
     * same-day service collision prevention, and volunteer monthly fatigue caps.
     */
    PROCEDURE auto_assign_roster (
        p_service_id IN NUMBER
    );

    /**
     * Assigns members of a pre-defined band into matching service slots.
     */
    PROCEDURE assign_band (
        p_service_id IN NUMBER,
        p_band_id    IN NUMBER
    );

    /**
     * Clears all roster assignments for a service (resets slots to unassigned).
     */
    PROCEDURE clear_roster (
        p_service_id IN NUMBER
    );
END ws_pkg_scheduler;
/

-- ----------------------------------------------------------------------------
-- 2. WS_PKG_SERVICE_MGMT
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE ws_pkg_service_mgmt AS
    /**
     * Creates a new worship service and optionally applies an initial template.
     * Returns the generated service_id.
     */
    FUNCTION create_service (
        p_name         IN VARCHAR2,
        p_service_date IN DATE,
        p_start_time   IN VARCHAR2 DEFAULT '10:00',
        p_template_id  IN NUMBER   DEFAULT NULL,
        p_notes        IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    /**
     * Updates service attributes with optimistic concurrency validation.
     */
    PROCEDURE update_service (
        p_service_id   IN NUMBER,
        p_name         IN VARCHAR2,
        p_service_date IN DATE,
        p_start_time   IN VARCHAR2,
        p_notes        IN VARCHAR2,
        p_row_version  IN NUMBER
    );

    /**
     * Transitions service lifecycle to PUBLISHED. Makes roster visible to musicians.
     */
    PROCEDURE publish_service (
        p_service_id IN NUMBER
    );

    /**
     * Marks service as COMPLETED.
     */
    PROCEDURE complete_service (
        p_service_id IN NUMBER
    );

    /**
     * Cancels an upcoming service.
     */
    PROCEDURE cancel_service (
        p_service_id IN NUMBER
    );

    /**
     * Adds a song to the service setlist, auto-sequencing play order.
     */
    PROCEDURE add_setlist_song (
        p_service_id  IN NUMBER,
        p_song_id     IN NUMBER,
        p_service_key IN VARCHAR2,
        p_notes       IN VARCHAR2 DEFAULT NULL
    );

    /**
     * Removes a song from the service setlist and compacts play order.
     */
    PROCEDURE remove_setlist_song (
        p_setlist_id IN NUMBER
    );
END ws_pkg_service_mgmt;
/

-- ----------------------------------------------------------------------------
-- 3. WS_PKG_MUSICIAN_PORTAL
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE ws_pkg_musician_portal AS
    /**
     * Registers a volunteer blockout date range.
     */
    PROCEDURE register_blockout (
        p_member_id  IN NUMBER,
        p_start_date IN DATE,
        p_end_date   IN DATE,
        p_reason     IN VARCHAR2 DEFAULT NULL
    );

    /**
     * Deletes a registered blockout with member ownership verification.
     */
    PROCEDURE delete_blockout (
        p_blockout_id IN NUMBER,
        p_member_id   IN NUMBER
    );

    /**
     * 1-Click invitation acceptance by musician with optimistic locking protection.
     */
    PROCEDURE accept_invitation (
        p_roster_id   IN NUMBER,
        p_row_version IN NUMBER
    );

    /**
     * 1-Click invitation decline with reason and optimistic locking protection.
     */
    PROCEDURE decline_invitation (
        p_roster_id   IN NUMBER,
        p_reason      IN VARCHAR2,
        p_row_version IN NUMBER
    );

    /**
     * Unified pipeline processing either ACCEPTED or DECLINED response.
     */
    PROCEDURE process_roster_response (
        p_roster_id   IN NUMBER,
        p_response    IN VARCHAR2,
        p_reason      IN VARCHAR2 DEFAULT NULL,
        p_row_version IN NUMBER   DEFAULT NULL
    );
END ws_pkg_musician_portal;
/
