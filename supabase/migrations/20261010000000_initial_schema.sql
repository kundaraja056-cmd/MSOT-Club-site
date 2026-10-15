-- MSOT CLUB ACTIVITIES TRACKER — SCHEMA MIGRATION
-- Database: PostgreSQL (Supabase)
-- Version: 20261010000000_initial_schema.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$ BEGIN
    CREATE TYPE app_role AS ENUM (
        'SYSTEM_ADMIN', 'PROGRAM_MANAGER', 'CAMPUS_MANAGER',
        'FACULTY_ADVISOR', 'STUDENT_COORDINATOR', 'STUDENT'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE leadership_role AS ENUM (
        'PRESIDENT', 'VICE_PRESIDENT', 'MENTOR',
        'FACULTY_COORDINATOR', 'TREASURER', 'SECRETARY'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE membership_status AS ENUM ('PENDING', 'ACTIVE', 'INACTIVE', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE activity_type AS ENUM ('WORKSHOP', 'COMPETITION', 'SESSION', 'PROJECT', 'BOOTCAMP', 'MEETING', 'OTHER');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE attendance_status AS ENUM ('PRESENT', 'LATE', 'EXCUSED', 'ABSENT');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE submission_status AS ENUM ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'GRADED', 'RESUBMISSION_REQUESTED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE event_status AS ENUM ('DRAFT', 'PUBLISHED', 'REGISTRATION_OPEN', 'REGISTRATION_CLOSED', 'ONGOING', 'COMPLETED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE registration_status AS ENUM ('REGISTERED', 'CONFIRMED', 'WAITLISTED', 'ATTENDED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE media_visibility AS ENUM ('PRIVATE_RAW', 'PENDING_APPROVAL', 'PUBLISHED_GALLERY');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE credential_status AS ENUM ('ISSUED', 'REVOKED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE OR REPLACE FUNCTION update_timestamp_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS campuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL UNIQUE,
    city TEXT,
    state TEXT,
    country TEXT DEFAULT 'India',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_campuses_modtime
    BEFORE UPDATE ON campuses
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    phone TEXT,
    student_id TEXT,
    campus_id UUID REFERENCES campuses(id) ON DELETE SET NULL,
    department TEXT,
    batch_year INTEGER,
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_profiles_modtime
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role app_role NOT NULL,
    campus_id UUID REFERENCES campuses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_role_campus UNIQUE (user_id, role, campus_id)
);

CREATE TABLE IF NOT EXISTS clubs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id UUID REFERENCES campuses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    subcategories TEXT[] NOT NULL DEFAULT '{}',
    banner_url TEXT,
    logo_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_clubs_campus_slug UNIQUE (campus_id, slug)
);

CREATE TRIGGER update_clubs_modtime
    BEFORE UPDATE ON clubs
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS club_leadership (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    role leadership_role NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    assigned_name TEXT,
    tenure_start DATE NOT NULL DEFAULT CURRENT_DATE,
    tenure_end DATE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_club_leadership_modtime
    BEFORE UPDATE ON club_leadership
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS club_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status membership_status NOT NULL DEFAULT 'ACTIVE',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_club_member UNIQUE (club_id, user_id)
);

CREATE TRIGGER update_club_memberships_modtime
    BEFORE UPDATE ON club_memberships
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    activity_type activity_type NOT NULL DEFAULT 'SESSION',
    points INTEGER NOT NULL DEFAULT 10 CHECK (points >= 0),
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ NOT NULL,
    venue TEXT,
    is_mandatory BOOLEAN NOT NULL DEFAULT false,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT check_activity_dates CHECK (scheduled_end >= scheduled_start)
);

CREATE TRIGGER update_activities_modtime
    BEFORE UPDATE ON activities
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS attendance_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID REFERENCES activities(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    session_code TEXT NOT NULL UNIQUE,
    qr_token TEXT NOT NULL UNIQUE,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    geo_lat DOUBLE PRECISION,
    geo_lng DOUBLE PRECISION,
    geo_radius_meters INTEGER DEFAULT 100,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT check_session_dates CHECK (valid_until >= valid_from)
);

CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES attendance_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status attendance_status NOT NULL DEFAULT 'PRESENT',
    scanned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verification_method TEXT NOT NULL DEFAULT 'QR_SCAN',
    verified_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    ip_address INET,
    CONSTRAINT uq_session_user_attendance UNIQUE (session_id, user_id)
);

CREATE TABLE IF NOT EXISTS rubrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID REFERENCES activities(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    max_score NUMERIC(5, 2) NOT NULL DEFAULT 100.00 CHECK (max_score > 0),
    criteria JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_rubrics_modtime
    BEFORE UPDATE ON rubrics
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status submission_status NOT NULL DEFAULT 'SUBMITTED',
    title TEXT,
    content_text TEXT,
    storage_file_paths TEXT[] NOT NULL DEFAULT '{}',
    repo_url TEXT,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_activity_user_submission UNIQUE (activity_id, user_id)
);

CREATE TRIGGER update_submissions_modtime
    BEFORE UPDATE ON submissions
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE UNIQUE,
    rubric_id UUID REFERENCES rubrics(id) ON DELETE SET NULL,
    evaluator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
    total_score NUMERIC(5, 2) NOT NULL CHECK (total_score >= 0),
    criteria_scores JSONB NOT NULL DEFAULT '{}'::jsonb,
    feedback TEXT,
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_evaluations_modtime
    BEFORE UPDATE ON evaluations
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id UUID NOT NULL REFERENCES campuses(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    venue TEXT NOT NULL,
    max_participants INTEGER CHECK (max_participants IS NULL OR max_participants > 0),
    status event_status NOT NULL DEFAULT 'PUBLISHED',
    cover_image_path TEXT,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_events_campus_slug UNIQUE (campus_id, slug),
    CONSTRAINT check_event_times CHECK (end_time >= start_time)
);

CREATE TRIGGER update_events_modtime
    BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status registration_status NOT NULL DEFAULT 'REGISTERED',
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    checked_in_at TIMESTAMPTZ,
    CONSTRAINT uq_event_user_registration UNIQUE (event_id, user_id)
);

CREATE TABLE IF NOT EXISTS event_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE SET NULL,
    storage_bucket TEXT NOT NULL DEFAULT 'event-media',
    storage_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    file_size_bytes BIGINT,
    visibility media_visibility NOT NULL DEFAULT 'PRIVATE_RAW',
    caption TEXT,
    uploaded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_event_media_modtime
    BEFORE UPDATE ON event_media
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TABLE IF NOT EXISTS certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certificate_number TEXT NOT NULL UNIQUE,
    verification_hash TEXT NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    activity_id UUID REFERENCES activities(id) ON DELETE SET NULL,
    club_id UUID REFERENCES clubs(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    pdf_storage_path TEXT NOT NULL,
    status credential_status NOT NULL DEFAULT 'ISSUED',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    issued_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url',
        NOW(),
        NOW()
    );
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'STUDENT');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.has_role(check_user_id UUID, required_role app_role)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = check_user_id AND role = required_role);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.has_any_role(check_user_id UUID, required_roles app_role[])
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = check_user_id AND role = ANY(required_roles));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_admin(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = check_user_id AND role IN ('SYSTEM_ADMIN', 'PROGRAM_MANAGER'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_campus_staff(check_user_id UUID, target_campus_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF public.is_admin(check_user_id) THEN RETURN true; END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = check_user_id
          AND role IN ('CAMPUS_MANAGER', 'FACULTY_ADVISOR')
          AND (campus_id = target_campus_id OR campus_id IS NULL)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_club_lead_or_staff(check_user_id UUID, target_club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE target_campus UUID;
BEGIN
    IF public.is_admin(check_user_id) THEN RETURN true; END IF;
    SELECT campus_id INTO target_campus FROM public.clubs WHERE id = target_club_id;
    IF public.is_campus_staff(check_user_id, target_campus) THEN RETURN true; END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.club_leadership
        WHERE club_id = target_club_id AND user_id = check_user_id AND is_active = true
    ) OR EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = check_user_id AND role = 'STUDENT_COORDINATOR' AND (campus_id = target_campus OR campus_id IS NULL)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
