-- ============================================================================
-- WorshipFlow: Sprint 0 Automated Verification Test
-- Script: tests/verify_sprint0_db.sql
-- Description: Asserts tables, constraints, indexes, views, and seed data.
-- ============================================================================

SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200

DECLARE
    v_errors   NUMBER := 0;
    v_count    NUMBER;
    v_expected NUMBER;

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
    DBMS_OUTPUT.PUT_LINE('   WORSHIPFLOW: SPRINT 0 DATABASE INTEGRITY SUITE   ');
    DBMS_OUTPUT.PUT_LINE('====================================================');

    -- 1. Table Count Verification
    SELECT COUNT(*) INTO v_count 
      FROM user_tables 
     WHERE table_name LIKE 'WS_%';
    assert_equals('Total WS_ Tables Created', v_count, 12);

    -- 2. View Count Verification
    SELECT COUNT(*) INTO v_count 
      FROM user_views 
     WHERE view_name = 'WS_V_ROSTER_CONFLICTS';
    assert_equals('Retroactive Conflict View (WS_V_ROSTER_CONFLICTS) Created', v_count, 1);

    -- 3. Primary Key Count Verification
    SELECT COUNT(*) INTO v_count
      FROM user_constraints
     WHERE constraint_name LIKE 'PK_WS_%'
       AND constraint_type = 'P'
       AND status = 'ENABLED';
    assert_equals('Primary Keys Enabled', v_count, 12);

    -- 4. Foreign Key Count Verification
    SELECT COUNT(*) INTO v_count
      FROM user_constraints
     WHERE constraint_name LIKE 'FK_WS_%'
       AND constraint_type = 'R'
       AND status = 'ENABLED';
    assert_equals('Foreign Keys Enabled', v_count, 17);

    -- 5. Performance Indexes
    SELECT COUNT(*) INTO v_count
      FROM user_indexes
     WHERE index_name LIKE 'IDX_WS_%'
       AND status = 'VALID';
    assert_true('Performance Indexes Created and Valid', v_count >= 10);

    -- 6. Seed Data Counts
    DBMS_OUTPUT.PUT_LINE('--- Verifying Seed Data ---');
    
    SELECT COUNT(*) INTO v_count FROM ws_instruments;
    assert_equals('Seed Instruments Count', v_count, 8);

    SELECT COUNT(*) INTO v_count FROM ws_service_templates;
    assert_equals('Seed Service Templates Count', v_count, 2);

    SELECT COUNT(*) INTO v_count FROM ws_service_template_slots;
    assert_equals('Seed Template Slots Count', v_count, 10);

    SELECT COUNT(*) INTO v_count FROM ws_members;
    assert_equals('Seed Members Count', v_count, 7);

    SELECT COUNT(*) INTO v_count FROM ws_member_instruments;
    assert_equals('Seed Member Instruments Mapping Count', v_count, 12);

    SELECT COUNT(*) INTO v_count FROM ws_songs;
    assert_equals('Seed Song Repertoire Count', v_count, 5);

    -- 7. Musical Key Constraint Verification
    BEGIN
        INSERT INTO ws_songs (title, artist, default_key) VALUES ('Invalid Key Test', 'Test', 'H');
        assert_true('Invalid Musical Key Rejected', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            assert_true('Invalid Musical Key Rejected by Check Constraint (ORA-02290)', SQLCODE = -2290);
    END;

    -- 8. Blockout Date Range Constraint Verification
    BEGIN
        INSERT INTO ws_member_blockouts (member_id, start_date, end_date) 
        SELECT id, DATE '2026-10-20', DATE '2026-10-15' FROM ws_members WHERE ROWNUM = 1;
        assert_true('Invalid Blockout Date Range Rejected', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            assert_true('Invalid Blockout Date Range (start > end) Rejected', SQLCODE = -2290);
    END;

    -- Final Results Summary
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    IF v_errors = 0 THEN
        DBMS_OUTPUT.PUT_LINE('SUCCESS: All Sprint 0 Database Integrity Tests Passed!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAILURE: ' || v_errors || ' test(s) failed.');
        RAISE_APPLICATION_ERROR(-20001, 'Sprint 0 Test Suite Failed: ' || v_errors || ' failures.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/
EXIT;
