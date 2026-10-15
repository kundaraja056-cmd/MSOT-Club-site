-- MSOT CLUB ACTIVITIES TRACKER — IDEMPOTENT DATABASE SEED
-- Database: PostgreSQL (Supabase)
-- Version: seed.sql

BEGIN;

INSERT INTO campuses (id, name, code, city, state, country, is_active)
VALUES
    ('c1111111-1111-1111-1111-111111111111', 'Rathinam Campus', 'RATHINAM', 'Coimbatore', 'Tamil Nadu', 'India', true),
    ('c2222222-2222-2222-2222-222222222222', 'Main Campus', 'MAIN', 'Coimbatore', 'Tamil Nadu', 'India', true),
    ('c3333333-3333-3333-3333-333333333333', 'City Campus', 'CITY', 'Coimbatore', 'Tamil Nadu', 'India', true)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    city = EXCLUDED.city,
    state = EXCLUDED.state,
    is_active = EXCLUDED.is_active;

DO $$
DECLARE
    target_campus_id UUID := 'c1111111-1111-1111-1111-111111111111';
    club_cc_id UUID := '11111111-0000-0000-0000-000000000001';
    club_nx_id UUID := '11111111-0000-0000-0000-000000000002';
    club_sp_id UUID := '11111111-0000-0000-0000-000000000003';
    club_tt_id UUID := '11111111-0000-0000-0000-000000000004';
BEGIN
    INSERT INTO clubs (id, campus_id, name, slug, category, description, subcategories, is_active)
    VALUES (
        club_cc_id, target_campus_id, 'CodeConnect', 'codeconnect', 'Coding and Technology',
        'Official Coding & Technology Club of MSOT under AI First Club initiative. Fostering development, competitive programming, and open-source contributions.',
        ARRAY['Coding competitions', 'Programming workshops', 'DSA', 'Web development', 'Open-source', 'Project demos', 'Hackathon prep'],
        true
    ) ON CONFLICT (campus_id, slug) DO UPDATE SET
        name = EXCLUDED.name, category = EXCLUDED.category, description = EXCLUDED.description, subcategories = EXCLUDED.subcategories, is_active = true;

    INSERT INTO clubs (id, campus_id, name, slug, category, description, subcategories, is_active)
    VALUES (
        club_nx_id, target_campus_id, 'Nexcell', 'nexcell', 'Entrepreneurship and Innovation',
        'Entrepreneurship and Innovation hub driving startup ventures, business modeling, market discovery, and pitching mastery.',
        ARRAY['Startup presentations', 'Business model challenges', 'Market research', 'Product ideation', 'Pitching competitions', 'Workshops'],
        true
    ) ON CONFLICT (campus_id, slug) DO UPDATE SET
        name = EXCLUDED.name, category = EXCLUDED.category, description = EXCLUDED.description, subcategories = EXCLUDED.subcategories, is_active = true;

    INSERT INTO clubs (id, campus_id, name, slug, category, description, subcategories, is_active)
    VALUES (
        club_sp_id, target_campus_id, 'Sports Club', 'sports-club', 'Sports and Athletics',
        'Official Sports and Athletics club promoting fitness, team spirit, athletic excellence, and competitive tournaments across sports.',
        ARRAY['Football', 'Basketball', 'Cricket', 'Badminton', 'Fitness', 'Tournaments', 'Team-building'],
        true
    ) ON CONFLICT (campus_id, slug) DO UPDATE SET
        name = EXCLUDED.name, category = EXCLUDED.category, description = EXCLUDED.description, subcategories = EXCLUDED.subcategories, is_active = true;

    INSERT INTO clubs (id, campus_id, name, slug, category, description, subcategories, is_active)
    VALUES (
        club_tt_id, target_campus_id, 'TechnoTribe', 'technotribe', 'Cultural and Creative Activities',
        'Creative arts, music, dance, stage theater, and cultural celebrations fostering artistic expression and collaborative performances.',
        ARRAY['Cultural festivals', 'Music & dance', 'Stage performances', 'Creative workshops', 'Photography', 'Art & design'],
        true
    ) ON CONFLICT (campus_id, slug) DO UPDATE SET
        name = EXCLUDED.name, category = EXCLUDED.category, description = EXCLUDED.description, subcategories = EXCLUDED.subcategories, is_active = true;

    DELETE FROM club_leadership WHERE club_id IN (club_cc_id, club_nx_id, club_sp_id, club_tt_id);

    INSERT INTO club_leadership (club_id, role, assigned_name, is_active)
    VALUES
        (club_cc_id, 'PRESIDENT', 'Sia Charan', true),
        (club_cc_id, 'VICE_PRESIDENT', 'Akshara', true),
        (club_cc_id, 'MENTOR', 'Harsh Bhaiya', true);

    INSERT INTO club_leadership (club_id, role, assigned_name, is_active)
    VALUES
        (club_nx_id, 'PRESIDENT', 'Rudra', true);

    INSERT INTO club_leadership (club_id, role, assigned_name, is_active)
    VALUES
        (club_sp_id, 'PRESIDENT', 'Astithwa', true),
        (club_sp_id, 'VICE_PRESIDENT', 'Piyush Tripathi', true),
        (club_sp_id, 'MENTOR', 'Aditya Bhaiya', true);

    INSERT INTO club_leadership (club_id, role, assigned_name, is_active)
    VALUES
        (club_tt_id, 'PRESIDENT', 'Sathwik Satya', true),
        (club_tt_id, 'VICE_PRESIDENT', 'Deepu', true),
        (club_tt_id, 'MENTOR', 'Syed Sir', true);

END $$;

COMMIT;
