-- ============================================================================
-- WorshipFlow: Sprint 3 E2E Seed Data for Leader Scheduling Matrix
-- ============================================================================

SET FEEDBACK OFF;
SET DEFINE OFF;
SET SERVEROUTPUT ON;

DECLARE
    v_service_id   NUMBER;
    v_lucas_id     NUMBER;
    v_service_date DATE := TRUNC(SYSDATE) + 21;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Seeding Sprint 3 E2E Leader Matrix test data...');

    -- 1. Remove previous Sprint 3 test services
    DELETE FROM ws_services WHERE name = 'Sunday Worship Gathering - Sprint 3';
    COMMIT;

    -- 2. Create clean DRAFT service with no initial slots
    INSERT INTO ws_services (
        name,
        service_date,
        start_time,
        status,
        notes
    ) VALUES (
        'Sunday Worship Gathering - Sprint 3',
        v_service_date,
        '10:30',
        'DRAFT',
        'Sprint 3 Automated Leader Matrix Testing'
    ) RETURNING id INTO v_service_id;

    -- 3. Add blockout for Marcus (Bass) on this date to verify Smart LOV flag
    SELECT id INTO v_lucas_id FROM ws_members WHERE UPPER(username) = 'MARCUS_BASS';
    
    DELETE FROM ws_member_blockouts 
     WHERE member_id = v_lucas_id 
       AND start_date <= v_service_date 
       AND end_date >= v_service_date;

    INSERT INTO ws_member_blockouts (
        member_id,
        start_date,
        end_date,
        reason
    ) VALUES (
        v_lucas_id,
        v_service_date - 2,
        v_service_date + 2,
        'Out of Town Conference'
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Sprint 3 Seed Data ready: Service ID = ' || v_service_id);
END;
/
