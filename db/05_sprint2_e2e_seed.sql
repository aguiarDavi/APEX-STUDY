-- ============================================================================
-- WorshipFlow: Sprint 2 E2E Seed Data for Musician Portal
-- ============================================================================

SET FEEDBACK OFF;
SET DEFINE OFF;
SET SERVEROUTPUT ON;

DECLARE
    v_test_user_id   NUMBER;
    v_template_id    NUMBER;
    v_service_id1    NUMBER;
    v_service_id2    NUMBER;
    v_roster_id      NUMBER;
    v_inst_ac        NUMBER;
    v_inst_voc       NUMBER;
    v_song_id1       NUMBER;
    v_song_id2       NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Seeding Sprint 2 E2E Musician Portal data...');

    -- 1. Ensure TEST_USER exists in WS_MEMBERS
    MERGE INTO ws_members m
    USING (SELECT 'TEST_USER' AS username FROM dual) src
    ON (m.username = src.username)
    WHEN NOT MATCHED THEN
        INSERT (username, full_name, email, phone, member_role, is_active, max_services_month)
        VALUES ('TEST_USER', 'Test Musician User', 'test.musician@worshipflow.local', '+5511999990099', 'MUSICIAN', 'Y', 6);
    COMMIT;

    SELECT id INTO v_test_user_id FROM ws_members WHERE username = 'TEST_USER';
    SELECT id INTO v_inst_ac FROM ws_instruments WHERE code = 'AC_GUITAR';
    SELECT id INTO v_inst_voc FROM ws_instruments WHERE code = 'LEAD_VOCAL';

    -- 2. Ensure Instrument proficiencies
    MERGE INTO ws_member_instruments mi
    USING (SELECT v_test_user_id AS member_id, v_inst_ac AS instrument_id FROM dual) src
    ON (mi.member_id = src.member_id AND mi.instrument_id = src.instrument_id)
    WHEN NOT MATCHED THEN
        INSERT (member_id, instrument_id, skill_level, is_primary)
        VALUES (src.member_id, src.instrument_id, 'ADVANCED', 'Y');

    MERGE INTO ws_member_instruments mi
    USING (SELECT v_test_user_id AS member_id, v_inst_voc AS instrument_id FROM dual) src
    ON (mi.member_id = src.member_id AND mi.instrument_id = src.instrument_id)
    WHEN NOT MATCHED THEN
        INSERT (member_id, instrument_id, skill_level, is_primary)
        VALUES (src.member_id, src.instrument_id, 'ADVANCED', 'Y');
    COMMIT;

    -- 3. Clean up any previous E2E test services
    DELETE FROM ws_services WHERE name LIKE '%- E2E';
    DELETE FROM ws_member_blockouts WHERE member_id = v_test_user_id;
    COMMIT;

    -- 4. Get template
    SELECT id INTO v_template_id FROM ws_service_templates WHERE name = 'Acoustic Trio';
    SELECT MIN(id), MAX(id) INTO v_song_id1, v_song_id2 FROM ws_songs WHERE is_active = 'Y';

    -- 5. Service 1: Upcoming with PENDING invitation for TEST_USER
    v_service_id1 := ws_pkg_service_mgmt.create_service(
        p_name         => 'Sunday Morning Celebration - E2E',
        p_service_date => TRUNC(SYSDATE) + 7,
        p_start_time   => '10:00',
        p_template_id  => v_template_id,
        p_notes        => 'Rehearsal at 08:30 AM'
    );

    -- Assign TEST_USER to the first slot (Acoustic Guitar) as PENDING
    SELECT id INTO v_roster_id
      FROM ws_service_roster
     WHERE service_id = v_service_id1
       AND instrument_id = v_inst_ac
       AND ROWNUM = 1;

    UPDATE ws_service_roster
       SET member_id = v_test_user_id,
           status = 'PENDING',
           row_version_number = 1
     WHERE id = v_roster_id;

    -- Add songs to setlist
    ws_pkg_service_mgmt.add_setlist_song(p_service_id => v_service_id1, p_song_id => v_song_id1, p_service_key => 'G');
    ws_pkg_service_mgmt.add_setlist_song(p_service_id => v_service_id1, p_song_id => v_song_id2, p_service_key => 'D');

    -- Publish service so it's visible in Musician Portal
    ws_pkg_service_mgmt.publish_service(v_service_id1);

    -- 6. Service 2: Upcoming with ACCEPTED invitation for TEST_USER (for Confirmed Services card)
    v_service_id2 := ws_pkg_service_mgmt.create_service(
        p_name         => 'Sunday Evening Praise - E2E',
        p_service_date => TRUNC(SYSDATE) + 14,
        p_start_time   => '18:00',
        p_template_id  => v_template_id,
        p_notes        => 'Rehearsal at 16:30 PM'
    );

    SELECT id INTO v_roster_id
      FROM ws_service_roster
     WHERE service_id = v_service_id2
       AND instrument_id = v_inst_voc
       AND ROWNUM = 1;

    UPDATE ws_service_roster
       SET member_id = v_test_user_id,
           status = 'ACCEPTED',
           confirmed_at = LOCALTIMESTAMP,
           row_version_number = 2
     WHERE id = v_roster_id;

    ws_pkg_service_mgmt.add_setlist_song(p_service_id => v_service_id2, p_song_id => v_song_id2, p_service_key => 'E');
    ws_pkg_service_mgmt.publish_service(v_service_id2);

    -- 7. Add an existing blockout for TEST_USER
    ws_pkg_musician_portal.register_blockout(
        p_member_id  => v_test_user_id,
        p_start_date => TRUNC(SYSDATE) + 21,
        p_end_date   => TRUNC(SYSDATE) + 28,
        p_reason     => 'Annual Vacation Trip'
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Sprint 2 E2E Seed Data populated successfully!');
END;
/
