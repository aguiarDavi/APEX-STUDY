-- ============================================================================
-- WorshipFlow: Sprint 1 - PL/SQL Business API Packages (Bodies)
-- Script: db/04_packages_body.sql
-- Description: Core package bodies for Scheduler, Service Mgmt, and Musician Portal.
-- Target: Oracle Database 23ai / 19c+ (Prefix: WS_PKG_)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. WS_PKG_SCHEDULER BODY
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY ws_pkg_scheduler AS

    PROCEDURE apply_template (
        p_service_id  IN NUMBER,
        p_template_id IN NUMBER
    ) IS
    BEGIN
        INSERT INTO ws_service_roster (service_id, instrument_id, slot_number, status)
        SELECT p_service_id, sts.instrument_id, sts.slot_number, 'PENDING'
          FROM ws_service_template_slots sts
         WHERE sts.template_id = p_template_id
           AND NOT EXISTS (
               SELECT 1 FROM ws_service_roster sr
                WHERE sr.service_id    = p_service_id
                  AND sr.instrument_id = sts.instrument_id
                  AND sr.slot_number   = sts.slot_number
           );
    END apply_template;

    PROCEDURE auto_assign_roster (
        p_service_id IN NUMBER
    ) IS
        v_service_date       DATE;
        v_selected_member_id NUMBER;
    BEGIN
        -- Pessimistic row locking on parent service to serialize auto-placement
        SELECT service_date
          INTO v_service_date
          FROM ws_services
         WHERE id = p_service_id
           FOR UPDATE;

        -- Iterate over unfilled or declined slots
        FOR r_slot IN (
            SELECT id, instrument_id, member_id
              FROM ws_service_roster
             WHERE service_id = p_service_id
               AND (member_id IS NULL OR status = 'DECLINED')
             ORDER BY slot_number ASC, id ASC
        ) LOOP
            v_selected_member_id := NULL;

            -- Select best eligible candidate
            BEGIN
                SELECT mi.member_id
                  INTO v_selected_member_id
                  FROM ws_member_instruments mi
                  JOIN ws_members m ON m.id = mi.member_id
                 WHERE mi.instrument_id = r_slot.instrument_id
                   AND m.is_active = 'Y'
                   -- 1. Not in a blockout on this service date
                   AND NOT EXISTS (
                       SELECT 1 FROM ws_member_blockouts mb
                        WHERE mb.member_id = m.id
                          AND TRUNC(v_service_date) BETWEEN TRUNC(mb.start_date) AND TRUNC(mb.end_date)
                   )
                   -- 2. NOT already assigned to THIS service (prevents double-booking same musician)
                   AND NOT EXISTS (
                       SELECT 1 FROM ws_service_roster sr_cur
                        WHERE sr_cur.service_id = p_service_id
                          AND sr_cur.member_id  = m.id
                   )
                   -- 3. NOT already scheduled in another service on the same date
                   AND NOT EXISTS (
                       SELECT 1 FROM ws_service_roster sr_other
                       JOIN ws_services s_other ON s_other.id = sr_other.service_id
                        WHERE sr_other.member_id = m.id
                          AND s_other.id        != p_service_id
                          AND TRUNC(s_other.service_date) = TRUNC(v_service_date)
                   )
                   -- 4. Monthly fatigue cap
                   AND (
                       SELECT COUNT(*)
                         FROM ws_service_roster sr_cnt
                         JOIN ws_services s_cnt ON s_cnt.id = sr_cnt.service_id
                        WHERE sr_cnt.member_id = m.id
                          AND TO_CHAR(s_cnt.service_date, 'YYYY-MM') = TO_CHAR(v_service_date, 'YYYY-MM')
                          AND sr_cnt.status IN ('PENDING', 'ACCEPTED')
                   ) < m.max_services_month
                 ORDER BY DBMS_RANDOM.VALUE
                 FETCH FIRST 1 ROW ONLY;

                -- If replacing a previously declined member, track replaced_member_id
                UPDATE ws_service_roster
                   SET replaced_member_id = CASE WHEN status = 'DECLINED' THEN member_id ELSE replaced_member_id END,
                       member_id          = v_selected_member_id,
                       status             = 'PENDING',
                       decline_reason     = NULL,
                       confirmed_at       = NULL,
                       row_version_number = row_version_number + 1
                 WHERE id = r_slot.id;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- Leave slot unfilled if no eligible candidate exists
                    NULL;
            END;
        END LOOP;
    END auto_assign_roster;

    PROCEDURE assign_band (
        p_service_id IN NUMBER,
        p_band_id    IN NUMBER
    ) IS
    BEGIN
        -- Match band members into available slots of matching instruments
        FOR r_bm IN (
            SELECT member_id, instrument_id
              FROM ws_band_members
             WHERE band_id = p_band_id
        ) LOOP
            UPDATE ws_service_roster
               SET member_id          = r_bm.member_id,
                   status             = 'PENDING',
                   decline_reason     = NULL,
                   row_version_number = row_version_number + 1
             WHERE id = (
                 SELECT id FROM ws_service_roster
                  WHERE service_id    = p_service_id
                    AND instrument_id = r_bm.instrument_id
                    AND member_id IS NULL
                  ORDER BY slot_number ASC
                  FETCH FIRST 1 ROW ONLY
             );
        END LOOP;

        UPDATE ws_services
           SET band_id = p_band_id,
               row_version_number = row_version_number + 1
         WHERE id = p_service_id;
    END assign_band;

    PROCEDURE clear_roster (
        p_service_id IN NUMBER
    ) IS
    BEGIN
        UPDATE ws_service_roster
           SET member_id          = NULL,
               status             = 'PENDING',
               decline_reason     = NULL,
               confirmed_at       = NULL,
               row_version_number = row_version_number + 1
         WHERE service_id = p_service_id;
    END clear_roster;

END ws_pkg_scheduler;
/

-- ----------------------------------------------------------------------------
-- 2. WS_PKG_SERVICE_MGMT BODY
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY ws_pkg_service_mgmt AS

    FUNCTION create_service (
        p_name         IN VARCHAR2,
        p_service_date IN DATE,
        p_start_time   IN VARCHAR2 DEFAULT '10:00',
        p_template_id  IN NUMBER   DEFAULT NULL,
        p_notes        IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_service_id NUMBER;
    BEGIN
        INSERT INTO ws_services (
            name, service_date, start_time, template_id, notes, status, row_version_number
        ) VALUES (
            p_name, p_service_date, p_start_time, p_template_id, p_notes, 'DRAFT', 1
        ) RETURNING id INTO v_service_id;

        IF p_template_id IS NOT NULL THEN
            ws_pkg_scheduler.apply_template(
                p_service_id  => v_service_id,
                p_template_id => p_template_id
            );
        END IF;

        RETURN v_service_id;
    END create_service;

    PROCEDURE update_service (
        p_service_id   IN NUMBER,
        p_name         IN VARCHAR2,
        p_service_date IN DATE,
        p_start_time   IN VARCHAR2,
        p_notes        IN VARCHAR2,
        p_row_version  IN NUMBER
    ) IS
        v_current_version NUMBER;
    BEGIN
        SELECT row_version_number
          INTO v_current_version
          FROM ws_services
         WHERE id = p_service_id
           FOR UPDATE;

        IF v_current_version != p_row_version THEN
            RAISE_APPLICATION_ERROR(-20002, 'Service record was modified by another session. Please refresh.');
        END IF;

        UPDATE ws_services
           SET name               = p_name,
               service_date       = p_service_date,
               start_time         = p_start_time,
               notes              = p_notes,
               row_version_number = row_version_number + 1,
               updated_at         = LOCALTIMESTAMP
         WHERE id = p_service_id;
    END update_service;

    PROCEDURE publish_service (
        p_service_id IN NUMBER
    ) IS
    BEGIN
        UPDATE ws_services
           SET status             = 'PUBLISHED',
               row_version_number = row_version_number + 1,
               updated_at         = LOCALTIMESTAMP
         WHERE id = p_service_id;
    END publish_service;

    PROCEDURE complete_service (
        p_service_id IN NUMBER
    ) IS
    BEGIN
        UPDATE ws_services
           SET status             = 'COMPLETED',
               row_version_number = row_version_number + 1,
               updated_at         = LOCALTIMESTAMP
         WHERE id = p_service_id;
    END complete_service;

    PROCEDURE cancel_service (
        p_service_id IN NUMBER
    ) IS
    BEGIN
        UPDATE ws_services
           SET status             = 'CANCELLED',
               row_version_number = row_version_number + 1,
               updated_at         = LOCALTIMESTAMP
         WHERE id = p_service_id;
    END cancel_service;

    PROCEDURE add_setlist_song (
        p_service_id  IN NUMBER,
        p_song_id     IN NUMBER,
        p_service_key IN VARCHAR2,
        p_notes       IN VARCHAR2 DEFAULT NULL
    ) IS
        v_next_order NUMBER;
    BEGIN
        SELECT COALESCE(MAX(play_order), 0) + 1
          INTO v_next_order
          FROM ws_service_setlist
         WHERE service_id = p_service_id;

        INSERT INTO ws_service_setlist (
            service_id, song_id, play_order, service_key, notes
        ) VALUES (
            p_service_id, p_song_id, v_next_order, p_service_key, p_notes
        );
    END add_setlist_song;

    PROCEDURE remove_setlist_song (
        p_setlist_id IN NUMBER
    ) IS
        v_service_id NUMBER;
        v_order      NUMBER;
    BEGIN
        SELECT service_id, play_order
          INTO v_service_id, v_order
          FROM ws_service_setlist
         WHERE id = p_setlist_id;

        DELETE FROM ws_service_setlist WHERE id = p_setlist_id;

        -- Compact sequence orders
        UPDATE ws_service_setlist
           SET play_order = play_order - 1
         WHERE service_id = v_service_id
           AND play_order > v_order;
    END remove_setlist_song;

END ws_pkg_service_mgmt;
/

-- ----------------------------------------------------------------------------
-- 3. WS_PKG_MUSICIAN_PORTAL BODY
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY ws_pkg_musician_portal AS

    PROCEDURE register_blockout (
        p_member_id  IN NUMBER,
        p_start_date IN DATE,
        p_end_date   IN DATE,
        p_reason     IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        IF p_start_date > p_end_date THEN
            RAISE_APPLICATION_ERROR(-20003, 'Blockout start date must be before or equal to end date.');
        END IF;

        INSERT INTO ws_member_blockouts (
            member_id, start_date, end_date, reason
        ) VALUES (
            p_member_id, p_start_date, p_end_date, p_reason
        );
    END register_blockout;

    PROCEDURE delete_blockout (
        p_blockout_id IN NUMBER,
        p_member_id   IN NUMBER
    ) IS
    BEGIN
        DELETE FROM ws_member_blockouts
         WHERE id        = p_blockout_id
           AND member_id = p_member_id;
    END delete_blockout;

    PROCEDURE accept_invitation (
        p_roster_id   IN NUMBER,
        p_row_version IN NUMBER
    ) IS
    BEGIN
        process_roster_response(
            p_roster_id   => p_roster_id,
            p_response    => 'ACCEPTED',
            p_reason      => NULL,
            p_row_version => p_row_version
        );
    END accept_invitation;

    PROCEDURE decline_invitation (
        p_roster_id   IN NUMBER,
        p_reason      IN VARCHAR2,
        p_row_version IN NUMBER
    ) IS
    BEGIN
        process_roster_response(
            p_roster_id   => p_roster_id,
            p_response    => 'DECLINED',
            p_reason      => p_reason,
            p_row_version => p_row_version
        );
    END decline_invitation;

    PROCEDURE process_roster_response (
        p_roster_id   IN NUMBER,
        p_response    IN VARCHAR2,
        p_reason      IN VARCHAR2 DEFAULT NULL,
        p_row_version IN NUMBER   DEFAULT NULL
    ) IS
        v_current_version NUMBER;
        v_current_status  VARCHAR2(20);
    BEGIN
        IF p_response NOT IN ('ACCEPTED', 'DECLINED') THEN
            RAISE_APPLICATION_ERROR(-20004, 'Invalid response status: must be ACCEPTED or DECLINED.');
        END IF;

        SELECT row_version_number, status
          INTO v_current_version, v_current_status
          FROM ws_service_roster
         WHERE id = p_roster_id
           FOR UPDATE;

        IF p_row_version IS NOT NULL AND v_current_version != p_row_version THEN
            RAISE_APPLICATION_ERROR(-20002, 'This invitation was updated or cancelled by another session.');
        END IF;

        UPDATE ws_service_roster
           SET status             = p_response,
               decline_reason     = CASE WHEN p_response = 'DECLINED' THEN p_reason ELSE NULL END,
               confirmed_at       = LOCALTIMESTAMP,
               row_version_number = row_version_number + 1
         WHERE id = p_roster_id;
    END process_roster_response;

END ws_pkg_musician_portal;
/
