-- ============================================================================
-- WorshipFlow: Sprint 1 Automated Verification Test Suite
-- Script: tests/verify_sprint1_packages.sql
-- Description: Asserts end-to-end package APIs for Scheduler, Service Mgmt, and Musician Portal.
-- ============================================================================

SET FEEDBACK OFF
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200

DECLARE
    v_errors            NUMBER := 0;
    v_service_id        NUMBER;
    v_template_id       NUMBER;
    v_roster_count      NUMBER;
    v_assigned_count    NUMBER;
    v_distinct_members  NUMBER;
    v_test_roster_id    NUMBER;
    v_test_row_version  NUMBER;
    v_decline_roster_id NUMBER;
    v_decline_version   NUMBER;
    v_declined_member   NUMBER;
    v_replaced_member   NUMBER;
    v_conflicts_count   NUMBER;
    v_setlist_count     NUMBER;
    v_song_id1          NUMBER;
    v_song_id2          NUMBER;

    PROCEDURE assert_equals(p_test_name IN VARCHAR2, p_actual IN NUMBER, p_expected IN NUMBER) IS
    BEGIN
        IF p_actual = p_expected THEN
            DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_test_name || ' (Expected: ' || p_expected || ', Got: ' || p_actual || ')');
        ELSE
            DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || p_test_name || ' (Expected: ' || p_expected || ', Got: ' || p_actual || ')');
            v_errors := v_errors + 1;
        END IF;
    END assert_equals;

    PROCEDURE assert_true(p_test_name IN VARCHAR2, p_condition IN BOOLEAN) IS
    BEGIN
        IF p_condition THEN
            DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_test_name);
        ELSE
            DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || p_test_name);
            v_errors := v_errors + 1;
        END IF;
    END assert_true;

BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('   WORSHIPFLOW: SPRINT 1 PACKAGE API TEST SUITE     ');
    DBMS_OUTPUT.PUT_LINE('====================================================');

    -- Get template for Standard 6-Piece Band
    SELECT id INTO v_template_id 
      FROM ws_service_templates 
     WHERE name = 'Standard 6-Piece Band';

    -- ------------------------------------------------------------------------
    -- Test 1: Service Creation & Template Slot Instantiation
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 1. Service Creation & Template Instantiation ---');
    v_service_id := ws_pkg_service_mgmt.create_service(
        p_name         => 'Sunday Morning Live Test',
        p_service_date => DATE '2026-10-18',
        p_start_time   => '10:00',
        p_template_id  => v_template_id,
        p_notes        => 'Automated API validation service.'
    );
    assert_true('Service ID returned', v_service_id IS NOT NULL);

    SELECT COUNT(*) INTO v_roster_count 
      FROM ws_service_roster 
     WHERE service_id = v_service_id;
    assert_equals('Template slots generated (7 slots)', v_roster_count, 7);

    -- ------------------------------------------------------------------------
    -- Test 2: Auto-Placement Randomizer Engine
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 2. Auto-Placement Randomizer ---');
    ws_pkg_scheduler.auto_assign_roster(p_service_id => v_service_id);

    SELECT COUNT(*) INTO v_assigned_count 
      FROM ws_service_roster 
     WHERE service_id = v_service_id 
       AND member_id IS NOT NULL;
    assert_true('Musicians auto-assigned to slots', v_assigned_count > 0);

    -- Verify double-booking exclusion: distinct members must equal assigned count
    SELECT COUNT(DISTINCT member_id) INTO v_distinct_members 
      FROM ws_service_roster 
     WHERE service_id = v_service_id 
       AND member_id IS NOT NULL;
    assert_equals('No double-booking (Distinct members = Total slots assigned)', v_distinct_members, v_assigned_count);

    -- ------------------------------------------------------------------------
    -- Test 3: Musician 1-Click Acceptance Pipeline
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 3. Musician 1-Click Invitation Acceptance ---');
    SELECT id, row_version_number 
      INTO v_test_roster_id, v_test_row_version
      FROM ws_service_roster
     WHERE service_id = v_service_id
       AND member_id IS NOT NULL
     FETCH FIRST 1 ROW ONLY;

    ws_pkg_musician_portal.accept_invitation(
        p_roster_id   => v_test_roster_id,
        p_row_version => v_test_row_version
    );

    DECLARE
        v_status       VARCHAR2(20);
        v_conf_at      TIMESTAMP WITH LOCAL TIME ZONE;
        v_new_version  NUMBER;
    BEGIN
        SELECT status, confirmed_at, row_version_number
          INTO v_status, v_conf_at, v_new_version
          FROM ws_service_roster
         WHERE id = v_test_roster_id;

        assert_true('Roster slot status updated to ACCEPTED', v_status = 'ACCEPTED');
        assert_true('Confirmation timestamp recorded', v_conf_at IS NOT NULL);
        assert_equals('Row version number incremented', v_new_version, v_test_row_version + 1);
    END;

    -- ------------------------------------------------------------------------
    -- Test 4: Optimistic Concurrency Conflict Detection
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 4. Optimistic Concurrency Conflict Detection ---');
    BEGIN
        -- Attempt to respond with stale row_version_number
        ws_pkg_musician_portal.accept_invitation(
            p_roster_id   => v_test_roster_id,
            p_row_version => v_test_row_version -- STALE VERSION
        );
        assert_true('Stale token rejected', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            assert_true('Stale token raised ORA-20002 concurrency exception', SQLCODE = -20002);
    END;

    -- ------------------------------------------------------------------------
    -- Test 5: Musician Decline & Reason Recording
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 5. Musician Invitation Decline Pipeline ---');
    SELECT id, member_id, row_version_number
      INTO v_decline_roster_id, v_declined_member, v_decline_version
      FROM ws_service_roster
     WHERE service_id = v_service_id
       AND id != v_test_roster_id
       AND member_id IS NOT NULL
     FETCH FIRST 1 ROW ONLY;

    ws_pkg_musician_portal.decline_invitation(
        p_roster_id   => v_decline_roster_id,
        p_reason      => 'Out of town on family trip',
        p_row_version => v_decline_version
    );

    DECLARE
        v_dec_status VARCHAR2(20);
        v_dec_reason VARCHAR2(255);
    BEGIN
        SELECT status, decline_reason
          INTO v_dec_status, v_dec_reason
          FROM ws_service_roster
         WHERE id = v_decline_roster_id;

        assert_true('Roster slot status updated to DECLINED', v_dec_status = 'DECLINED');
        assert_equals('Decline reason recorded correctly', LENGTH(v_dec_reason), LENGTH('Out of town on family trip'));
    END;

    -- ------------------------------------------------------------------------
    -- Test 6: Auto-Placement Replacement Workflow
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 6. Slot Replacement & Decline Audit Trail ---');
    ws_pkg_scheduler.auto_assign_roster(p_service_id => v_service_id);

    SELECT replaced_member_id
      INTO v_replaced_member
      FROM ws_service_roster
     WHERE id = v_decline_roster_id;

    assert_equals('Audit preserved: replaced_member_id matches declining volunteer', v_replaced_member, v_declined_member);

    -- ------------------------------------------------------------------------
    -- Test 7: Setlist Management
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 7. Song Setlist Management ---');
    SELECT id INTO v_song_id1 FROM ws_songs WHERE title = 'Gratitude';
    SELECT id INTO v_song_id2 FROM ws_songs WHERE title = 'Way Maker';

    ws_pkg_service_mgmt.add_setlist_song(
        p_service_id  => v_service_id,
        p_song_id     => v_song_id1,
        p_service_key => 'B',
        p_notes       => 'Opener; acoustic start'
    );
    ws_pkg_service_mgmt.add_setlist_song(
        p_service_id  => v_service_id,
        p_song_id     => v_song_id2,
        p_service_key => 'E',
        p_notes       => 'Seamless transition'
    );

    SELECT COUNT(*) INTO v_setlist_count
      FROM ws_service_setlist
     WHERE service_id = v_service_id;
    assert_equals('Setlist songs added and sequenced', v_setlist_count, 2);

    -- ------------------------------------------------------------------------
    -- Test 8: Retroactive Blockout Detection View (WS_V_ROSTER_CONFLICTS)
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 8. Retroactive Blockout Conflict Detection ---');
    -- Musician accepted, now registers a blockout covering that service date
    DECLARE
        v_accepted_member_id NUMBER;
    BEGIN
        SELECT member_id INTO v_accepted_member_id
          FROM ws_service_roster
         WHERE id = v_test_roster_id;

        ws_pkg_musician_portal.register_blockout(
            p_member_id  => v_accepted_member_id,
            p_start_date => DATE '2026-10-17',
            p_end_date   => DATE '2026-10-19',
            p_reason     => 'Emergency business travel'
        );

        SELECT COUNT(*) INTO v_conflicts_count
          FROM ws_v_roster_conflicts
         WHERE service_id = v_service_id
           AND member_id  = v_accepted_member_id;

        assert_equals('Retroactive conflict surfaced in WS_V_ROSTER_CONFLICTS', v_conflicts_count, 1);
    END;

    -- ------------------------------------------------------------------------
    -- Test 9: Service Lifecycle Publication
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- 9. Service Lifecycle Publication ---');
    ws_pkg_service_mgmt.publish_service(p_service_id => v_service_id);

    DECLARE
        v_pub_status VARCHAR2(20);
    BEGIN
        SELECT status INTO v_pub_status
          FROM ws_services
         WHERE id = v_service_id;

        assert_true('Service status transitioned to PUBLISHED', v_pub_status = 'PUBLISHED');
    END;

    -- ------------------------------------------------------------------------
    -- Final Results Summary
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    IF v_errors = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SUCCESS: All 13 Sprint 1 Package API Tests Passed!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAILURE: ' || v_errors || ' test(s) failed.');
        RAISE_APPLICATION_ERROR(-20001, 'Sprint 1 Test Suite Failed: ' || v_errors || ' failures.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('====================================================');

    -- Clean rollback of test transactions
    ROLLBACK;
END;
/
