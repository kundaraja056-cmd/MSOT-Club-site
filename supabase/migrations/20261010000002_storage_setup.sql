-- MSOT CLUB ACTIVITIES TRACKER — STORAGE BUCKETS & POLICIES
-- Database: PostgreSQL (Supabase Storage)
-- Version: 20261010000002_storage_setup.sql

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('submissions', 'submissions', false, 52428800, ARRAY['application/pdf', 'application/zip', 'application/x-zip-compressed', 'image/png', 'image/jpeg']),
    ('event-media', 'event-media', false, 104857600, ARRAY['image/png', 'image/jpeg', 'image/webp', 'video/mp4']),
    ('certificates', 'certificates', false, 10485760, ARRAY['application/pdf']),
    ('club-assets', 'club-assets', true, 10485760, ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE POLICY "submission_upload_policy" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'submissions' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "submission_read_policy" ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'submissions' AND (
            (storage.foldername(name))[1] = auth.uid()::text
            OR public.is_admin(auth.uid())
            OR public.has_any_role(auth.uid(), ARRAY['FACULTY_ADVISOR'::app_role, 'CAMPUS_MANAGER'::app_role, 'STUDENT_COORDINATOR'::app_role])
        )
    );

CREATE POLICY "event_media_upload_policy" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'event-media');

CREATE POLICY "event_media_read_policy" ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'event-media' AND (
            (storage.foldername(name))[1] = 'published'
            OR public.is_admin(auth.uid())
            OR public.has_any_role(auth.uid(), ARRAY['CAMPUS_MANAGER'::app_role, 'FACULTY_ADVISOR'::app_role, 'STUDENT_COORDINATOR'::app_role])
            OR (storage.foldername(name))[2] = auth.uid()::text
        )
    );

CREATE POLICY "certificates_read_policy" ON storage.objects FOR SELECT
    USING (
        bucket_id = 'certificates' AND (
            (storage.foldername(name))[1] = auth.uid()::text
            OR public.is_admin(auth.uid())
            OR public.has_any_role(auth.uid(), ARRAY['CAMPUS_MANAGER'::app_role, 'FACULTY_ADVISOR'::app_role])
        )
    );

CREATE POLICY "club_assets_public_read" ON storage.objects FOR SELECT USING (bucket_id = 'club-assets');

CREATE POLICY "club_assets_staff_write" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'club-assets' AND (
            public.is_admin(auth.uid())
            OR public.has_any_role(auth.uid(), ARRAY['CAMPUS_MANAGER'::app_role, 'FACULTY_ADVISOR'::app_role, 'STUDENT_COORDINATOR'::app_role])
        )
    );
