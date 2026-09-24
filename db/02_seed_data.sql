-- ============================================================================
-- WorshipFlow: Sprint 0 - Database Foundation & Baseline Data
-- Script: 02_seed_data.sql
-- Description: Baseline seed data for instruments, templates, members, and songs.
-- Target: Oracle Database 23ai / 19c+ (Prefix: WS_)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Seed Instruments
-- ----------------------------------------------------------------------------
INSERT INTO ws_instruments (name, code, category, display_order, is_active) VALUES
('Acoustic Guitar', 'AC_GUITAR', 'MELODY', 1, 'Y');
INSERT INTO ws_instruments (name, code, category, display_order, is_active) VALUES
('Electric Guitar', 'ELEC_GUITAR', 'MELODY', 2, 'Y');
INSERT INTO ws_instruments (name, code, category, display_order, is_active) VALUES
('Bass Guitar', 'BASS', 'RHYTHM', 3, 'Y');
INSERT INTO ws_instruments (name, code, category, display_order, is_active) VALUES
('Drums', 'DRUMS', 'RHYTHM', 4, 'Y');
INSERT INTO ws_instruments (name, code, category, display_order, is_active) VALUES
('Keyboard / Piano', 'KEYS', 'MELODY', 5, 'Y');
INSERT INTO ws_instruments (name, code, category, display_order, is_active) VALUES
('Lead Vocals', 'LEAD_VOCAL', 'VOCALS', 6, 'Y');
INSERT INTO ws_instruments (name, code, category, display_order, is_active) VALUES
('Backing Vocals', 'BACKING_VOCAL', 'VOCALS', 7, 'Y');
INSERT INTO ws_instruments (name, code, category, display_order, is_active) VALUES
('Sound Technician', 'SOUND_TECH', 'PRODUCTION', 8, 'Y');

-- ----------------------------------------------------------------------------
-- 2. Seed Service Templates & Slots
-- ----------------------------------------------------------------------------
-- Template A: Standard 6-Piece Band
INSERT INTO ws_service_templates (name, description, is_active) VALUES
('Standard 6-Piece Band', 'Full worship band with drums, bass, two guitars, keys, and 2 vocalists.', 'Y');

-- Slots for Standard 6-Piece Band
INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Standard 6-Piece Band' AND i.code = 'DRUMS';

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Standard 6-Piece Band' AND i.code = 'BASS';

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Standard 6-Piece Band' AND i.code = 'AC_GUITAR';

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Standard 6-Piece Band' AND i.code = 'ELEC_GUITAR';

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Standard 6-Piece Band' AND i.code = 'KEYS';

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Standard 6-Piece Band' AND i.code = 'LEAD_VOCAL';

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'N' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Standard 6-Piece Band' AND i.code = 'BACKING_VOCAL';

-- Template B: Acoustic Trio
INSERT INTO ws_service_templates (name, description, is_active) VALUES
('Acoustic Trio', 'Intimate acoustic setting: Acoustic Guitar, Keys, and Lead Vocal.', 'Y');

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Acoustic Trio' AND i.code = 'AC_GUITAR';

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Acoustic Trio' AND i.code = 'KEYS';

INSERT INTO ws_service_template_slots (template_id, instrument_id, slot_number, is_mandatory)
SELECT t.id, i.id, 1, 'Y' FROM ws_service_templates t, ws_instruments i WHERE t.name = 'Acoustic Trio' AND i.code = 'LEAD_VOCAL';

-- ----------------------------------------------------------------------------
-- 3. Seed Members (Musicians & Leaders)
-- ----------------------------------------------------------------------------
INSERT INTO ws_members (username, full_name, email, phone, member_role, max_services_month, is_active) VALUES
('DAVI', 'Davi Aguiar', 'davi@worshipflow.local', '+55 11 99999-0001', 'LEADER', 4, 'Y');

INSERT INTO ws_members (username, full_name, email, phone, member_role, max_services_month, is_active) VALUES
('SARAH_DRUMS', 'Sarah Jenkins', 'sarah.j@worshipflow.local', '+55 11 99999-0002', 'MUSICIAN', 3, 'Y');

INSERT INTO ws_members (username, full_name, email, phone, member_role, max_services_month, is_active) VALUES
('MARCUS_BASS', 'Marcus Miller', 'marcus.m@worshipflow.local', '+55 11 99999-0003', 'MUSICIAN', 4, 'Y');

INSERT INTO ws_members (username, full_name, email, phone, member_role, max_services_month, is_active) VALUES
('LUCAS_KEYS', 'Lucas Ribeiro', 'lucas.r@worshipflow.local', '+55 11 99999-0004', 'MUSICIAN', 4, 'Y');

INSERT INTO ws_members (username, full_name, email, phone, member_role, max_services_month, is_active) VALUES
('ANA_VOCAL', 'Ana Souza', 'ana.s@worshipflow.local', '+55 11 99999-0005', 'MUSICIAN', 3, 'Y');

INSERT INTO ws_members (username, full_name, email, phone, member_role, max_services_month, is_active) VALUES
('PEDRO_GUITAR', 'Pedro Costa', 'pedro.c@worshipflow.local', '+55 11 99999-0006', 'MUSICIAN', 4, 'Y');

INSERT INTO ws_members (username, full_name, email, phone, member_role, max_services_month, is_active) VALUES
('GABI_VOCAL', 'Gabriela Santos', 'gabi.s@worshipflow.local', '+55 11 99999-0007', 'MUSICIAN', 2, 'Y');

-- ----------------------------------------------------------------------------
-- 4. Member Instrument Associations
-- ----------------------------------------------------------------------------
-- Davi: Acoustic Guitar (Primary), Electric Guitar, Lead Vocal
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'Y', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'DAVI' AND i.code = 'AC_GUITAR';
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'N', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'DAVI' AND i.code = 'ELEC_GUITAR';
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'N', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'DAVI' AND i.code = 'LEAD_VOCAL';

-- Sarah: Drums
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'Y', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'SARAH_DRUMS' AND i.code = 'DRUMS';

-- Marcus: Bass
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'Y', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'MARCUS_BASS' AND i.code = 'BASS';

-- Lucas: Keys
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'Y', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'LUCAS_KEYS' AND i.code = 'KEYS';

-- Ana: Lead Vocal (Primary), Backing Vocal
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'Y', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'ANA_VOCAL' AND i.code = 'LEAD_VOCAL';
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'N', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'ANA_VOCAL' AND i.code = 'BACKING_VOCAL';

-- Pedro: Electric Guitar (Primary), Acoustic Guitar
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'Y', 'ADVANCED' FROM ws_members m, ws_instruments i WHERE m.username = 'PEDRO_GUITAR' AND i.code = 'ELEC_GUITAR';
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'N', 'INTERMEDIATE' FROM ws_members m, ws_instruments i WHERE m.username = 'PEDRO_GUITAR' AND i.code = 'AC_GUITAR';

-- Gabriela: Backing Vocal (Primary), Lead Vocal
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'Y', 'INTERMEDIATE' FROM ws_members m, ws_instruments i WHERE m.username = 'GABI_VOCAL' AND i.code = 'BACKING_VOCAL';
INSERT INTO ws_member_instruments (member_id, instrument_id, is_primary, skill_level)
SELECT m.id, i.id, 'N', 'INTERMEDIATE' FROM ws_members m, ws_instruments i WHERE m.username = 'GABI_VOCAL' AND i.code = 'LEAD_VOCAL';

-- ----------------------------------------------------------------------------
-- 5. Seed Song Repertoire
-- ----------------------------------------------------------------------------
INSERT INTO ws_songs (title, artist, default_key, bpm, youtube_url, is_active) VALUES
('Gratitude', 'Brandon Lake', 'B', 78, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'Y');

INSERT INTO ws_songs (title, artist, default_key, bpm, youtube_url, is_active) VALUES
('Way Maker', 'Sinach / Leeland', 'E', 68, 'https://www.youtube.com/watch?v=iJCV_2H9xD0', 'Y');

INSERT INTO ws_songs (title, artist, default_key, bpm, youtube_url, is_active) VALUES
('Goodness of God', 'Bethel Music / Jenn Johnson', 'Ab', 69, 'https://www.youtube.com/watch?v=-f4MUUMHaaE', 'Y');

INSERT INTO ws_songs (title, artist, default_key, bpm, youtube_url, is_active) VALUES
('What a Beautiful Name', 'Hillsong Worship', 'D', 68, 'https://www.youtube.com/watch?v=r5L6Qz33Ztw', 'Y');

INSERT INTO ws_songs (title, artist, default_key, bpm, youtube_url, is_active) VALUES
('Living Hope', 'Phil Wickham', 'Eb', 72, 'https://www.youtube.com/watch?v=u-1fwZtKJSM', 'Y');

-- Commit all baseline seed data
COMMIT;
