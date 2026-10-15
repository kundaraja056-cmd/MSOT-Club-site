-- MSOT CLUB ACTIVITIES TRACKER — ROW LEVEL SECURITY POLICIES
-- Database: PostgreSQL (Supabase)
-- Version: 20261010000001_rls_policies.sql

ALTER TABLE campuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_leadership ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE rubrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "campuses_select_policy" ON campuses FOR SELECT TO authenticated
    USING (is_active = true OR public.is_admin(auth.uid()));
CREATE POLICY "campuses_insert_policy" ON campuses FOR INSERT TO authenticated
    WITH CHECK (public.is_admin(auth.uid()));
CREATE POLICY "campuses_update_policy" ON campuses FOR UPDATE TO authenticated
    USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
CREATE POLICY "campuses_delete_policy" ON campuses FOR DELETE TO authenticated
    USING (public.is_admin(auth.uid()));

CREATE POLICY "profiles_select_policy" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_update_policy" ON profiles FOR UPDATE TO authenticated
    USING (id = auth.uid() OR public.is_admin(auth.uid())) WITH CHECK (id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "user_roles_select_policy" ON user_roles FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.is_admin(auth.uid()) OR (campus_id IS NOT NULL AND public.is_campus_staff(auth.uid(), campus_id)));
CREATE POLICY "user_roles_insert_policy" ON user_roles FOR INSERT TO authenticated
    WITH CHECK (public.is_admin(auth.uid()) OR (campus_id IS NOT NULL AND public.is_campus_staff(auth.uid(), campus_id) AND role IN ('STUDENT_COORDINATOR', 'STUDENT')));
CREATE POLICY "user_roles_update_policy" ON user_roles FOR UPDATE TO authenticated
    USING (public.is_admin(auth.uid()) OR (campus_id IS NOT NULL AND public.is_campus_staff(auth.uid(), campus_id) AND role IN ('STUDENT_COORDINATOR', 'STUDENT')))
    WITH CHECK (public.is_admin(auth.uid()) OR (campus_id IS NOT NULL AND public.is_campus_staff(auth.uid(), campus_id) AND role IN ('STUDENT_COORDINATOR', 'STUDENT')));
CREATE POLICY "user_roles_delete_policy" ON user_roles FOR DELETE TO authenticated
    USING (public.is_admin(auth.uid()) OR (campus_id IS NOT NULL AND public.is_campus_staff(auth.uid(), campus_id)));

CREATE POLICY "clubs_select_policy" ON clubs FOR SELECT TO authenticated
    USING (is_active = true OR public.is_campus_staff(auth.uid(), campus_id));
CREATE POLICY "clubs_insert_policy" ON clubs FOR INSERT TO authenticated
    WITH CHECK (public.is_admin(auth.uid()) OR public.is_campus_staff(auth.uid(), campus_id));
CREATE POLICY "clubs_update_policy" ON clubs FOR UPDATE TO authenticated
    USING (public.is_campus_staff(auth.uid(), campus_id) OR public.is_club_lead_or_staff(auth.uid(), id))
    WITH CHECK (public.is_campus_staff(auth.uid(), campus_id) OR public.is_club_lead_or_staff(auth.uid(), id));
CREATE POLICY "clubs_delete_policy" ON clubs FOR DELETE TO authenticated
    USING (public.is_admin(auth.uid()) OR public.is_campus_staff(auth.uid(), campus_id));

CREATE POLICY "club_leadership_select_policy" ON club_leadership FOR SELECT TO authenticated USING (true);
CREATE POLICY "club_leadership_insert_policy" ON club_leadership FOR INSERT TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM clubs c WHERE c.id = club_id AND public.is_campus_staff(auth.uid(), c.campus_id)));
CREATE POLICY "club_leadership_update_policy" ON club_leadership FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM clubs c WHERE c.id = club_id AND public.is_campus_staff(auth.uid(), c.campus_id)))
    WITH CHECK (EXISTS (SELECT 1 FROM clubs c WHERE c.id = club_id AND public.is_campus_staff(auth.uid(), c.campus_id)));
CREATE POLICY "club_leadership_delete_policy" ON club_leadership FOR DELETE TO authenticated
    USING (EXISTS (SELECT 1 FROM clubs c WHERE c.id = club_id AND public.is_campus_staff(auth.uid(), c.campus_id)));

CREATE POLICY "club_memberships_select_policy" ON club_memberships FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "club_memberships_insert_policy" ON club_memberships FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() OR public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "club_memberships_update_policy" ON club_memberships FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR public.is_club_lead_or_staff(auth.uid(), club_id))
    WITH CHECK (user_id = auth.uid() OR public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "club_memberships_delete_policy" ON club_memberships FOR DELETE TO authenticated
    USING (user_id = auth.uid() OR public.is_club_lead_or_staff(auth.uid(), club_id));

CREATE POLICY "activities_select_policy" ON activities FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM club_memberships cm WHERE cm.club_id = activities.club_id AND cm.user_id = auth.uid() AND cm.status = 'ACTIVE') OR public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "activities_insert_policy" ON activities FOR INSERT TO authenticated
    WITH CHECK (public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "activities_update_policy" ON activities FOR UPDATE TO authenticated
    USING (public.is_club_lead_or_staff(auth.uid(), club_id)) WITH CHECK (public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "activities_delete_policy" ON activities FOR DELETE TO authenticated
    USING (public.is_club_lead_or_staff(auth.uid(), club_id));

CREATE POLICY "attendance_sessions_select_policy" ON attendance_sessions FOR SELECT TO authenticated
    USING ((is_active = true AND valid_until >= NOW()) OR public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "attendance_sessions_insert_policy" ON attendance_sessions FOR INSERT TO authenticated
    WITH CHECK (public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "attendance_sessions_update_policy" ON attendance_sessions FOR UPDATE TO authenticated
    USING (public.is_club_lead_or_staff(auth.uid(), club_id)) WITH CHECK (public.is_club_lead_or_staff(auth.uid(), club_id));

CREATE POLICY "attendance_records_select_policy" ON attendance_records FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM attendance_sessions s WHERE s.id = attendance_records.session_id AND public.is_club_lead_or_staff(auth.uid(), s.club_id)));
CREATE POLICY "attendance_records_insert_policy" ON attendance_records FOR INSERT TO authenticated
    WITH CHECK ((user_id = auth.uid() AND EXISTS (SELECT 1 FROM attendance_sessions s WHERE s.id = session_id AND s.is_active = true AND NOW() BETWEEN s.valid_from AND s.valid_until)) OR EXISTS (SELECT 1 FROM attendance_sessions s WHERE s.id = session_id AND public.is_club_lead_or_staff(auth.uid(), s.club_id)));
CREATE POLICY "attendance_records_update_policy" ON attendance_records FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM attendance_sessions s WHERE s.id = attendance_records.session_id AND public.is_club_lead_or_staff(auth.uid(), s.club_id)))
    WITH CHECK (EXISTS (SELECT 1 FROM attendance_sessions s WHERE s.id = attendance_records.session_id AND public.is_club_lead_or_staff(auth.uid(), s.club_id)));

CREATE POLICY "rubrics_select_policy" ON rubrics FOR SELECT TO authenticated USING (true);
CREATE POLICY "rubrics_insert_policy" ON rubrics FOR INSERT TO authenticated
    WITH CHECK (public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "rubrics_update_policy" ON rubrics FOR UPDATE TO authenticated
    USING (public.is_club_lead_or_staff(auth.uid(), club_id)) WITH CHECK (public.is_club_lead_or_staff(auth.uid(), club_id));
CREATE POLICY "rubrics_delete_policy" ON rubrics FOR DELETE TO authenticated
    USING (public.is_club_lead_or_staff(auth.uid(), club_id));

CREATE POLICY "submissions_select_policy" ON submissions FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM activities a WHERE a.id = submissions.activity_id AND public.is_club_lead_or_staff(auth.uid(), a.club_id)));
CREATE POLICY "submissions_insert_policy" ON submissions FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() AND EXISTS (SELECT 1 FROM activities a WHERE a.id = activity_id AND NOW() <= a.scheduled_end));
CREATE POLICY "submissions_update_policy" ON submissions FOR UPDATE TO authenticated
    USING ((user_id = auth.uid() AND status IN ('DRAFT', 'RESUBMISSION_REQUESTED', 'SUBMITTED')) OR EXISTS (SELECT 1 FROM activities a WHERE a.id = submissions.activity_id AND public.is_club_lead_or_staff(auth.uid(), a.club_id)))
    WITH CHECK ((user_id = auth.uid() AND status IN ('DRAFT', 'RESUBMISSION_REQUESTED', 'SUBMITTED')) OR EXISTS (SELECT 1 FROM activities a WHERE a.id = submissions.activity_id AND public.is_club_lead_or_staff(auth.uid(), a.club_id)));

CREATE POLICY "evaluations_select_policy" ON evaluations FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM submissions s WHERE s.id = evaluations.submission_id AND s.user_id = auth.uid()) OR EXISTS (SELECT 1 FROM submissions s JOIN activities a ON a.id = s.activity_id WHERE s.id = evaluations.submission_id AND public.is_club_lead_or_staff(auth.uid(), a.club_id)));
CREATE POLICY "evaluations_insert_policy" ON evaluations FOR INSERT TO authenticated
    WITH CHECK (evaluator_id = auth.uid() AND EXISTS (SELECT 1 FROM submissions s JOIN activities a ON a.id = s.activity_id WHERE s.id = submission_id AND public.is_club_lead_or_staff(auth.uid(), a.club_id)));
CREATE POLICY "evaluations_update_policy" ON evaluations FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM submissions s JOIN activities a ON a.id = s.activity_id WHERE s.id = evaluations.submission_id AND (evaluations.evaluator_id = auth.uid() OR public.is_campus_staff(auth.uid(), (SELECT campus_id FROM clubs WHERE id = a.club_id)))))
    WITH CHECK (EXISTS (SELECT 1 FROM submissions s JOIN activities a ON a.id = s.activity_id WHERE s.id = evaluations.submission_id AND (evaluations.evaluator_id = auth.uid() OR public.is_campus_staff(auth.uid(), (SELECT campus_id FROM clubs WHERE id = a.club_id)))));

CREATE POLICY "events_select_policy" ON events FOR SELECT TO authenticated
    USING (status != 'DRAFT' OR public.is_campus_staff(auth.uid(), campus_id) OR (club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), club_id)));
CREATE POLICY "events_insert_policy" ON events FOR INSERT TO authenticated
    WITH CHECK (public.is_campus_staff(auth.uid(), campus_id) OR (club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), club_id)));
CREATE POLICY "events_update_policy" ON events FOR UPDATE TO authenticated
    USING (public.is_campus_staff(auth.uid(), campus_id) OR (club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), club_id)))
    WITH CHECK (public.is_campus_staff(auth.uid(), campus_id) OR (club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), club_id)));
CREATE POLICY "events_delete_policy" ON events FOR DELETE TO authenticated
    USING (public.is_campus_staff(auth.uid(), campus_id));

CREATE POLICY "event_registrations_select_policy" ON event_registrations FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM events e WHERE e.id = event_registrations.event_id AND (public.is_campus_staff(auth.uid(), e.campus_id) OR (e.club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), e.club_id)))));
CREATE POLICY "event_registrations_insert_policy" ON event_registrations FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() AND EXISTS (SELECT 1 FROM events e WHERE e.id = event_id AND e.status IN ('PUBLISHED', 'REGISTRATION_OPEN')));
CREATE POLICY "event_registrations_update_policy" ON event_registrations FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM events e WHERE e.id = event_registrations.event_id AND (public.is_campus_staff(auth.uid(), e.campus_id) OR (e.club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), e.club_id)))))
    WITH CHECK (user_id = auth.uid() OR EXISTS (SELECT 1 FROM events e WHERE e.id = event_registrations.event_id AND (public.is_campus_staff(auth.uid(), e.campus_id) OR (e.club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), e.club_id)))));

CREATE POLICY "event_media_select_policy" ON event_media FOR SELECT TO authenticated
    USING (visibility = 'PUBLISHED_GALLERY' OR uploaded_by = auth.uid() OR EXISTS (SELECT 1 FROM events e WHERE e.id = event_media.event_id AND (public.is_campus_staff(auth.uid(), e.campus_id) OR (e.club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), e.club_id)))));
CREATE POLICY "event_media_insert_policy" ON event_media FOR INSERT TO authenticated
    WITH CHECK (uploaded_by = auth.uid() AND visibility IN ('PRIVATE_RAW', 'PENDING_APPROVAL'));
CREATE POLICY "event_media_update_policy" ON event_media FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM events e WHERE e.id = event_media.event_id AND (public.is_campus_staff(auth.uid(), e.campus_id) OR (e.club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), e.club_id)))))
    WITH CHECK (EXISTS (SELECT 1 FROM events e WHERE e.id = event_media.event_id AND (public.is_campus_staff(auth.uid(), e.campus_id) OR (e.club_id IS NOT NULL AND public.is_club_lead_or_staff(auth.uid(), e.club_id)))));
CREATE POLICY "event_media_delete_policy" ON event_media FOR DELETE TO authenticated
    USING (uploaded_by = auth.uid() OR EXISTS (SELECT 1 FROM events e WHERE e.id = event_media.event_id AND public.is_campus_staff(auth.uid(), e.campus_id)));

CREATE POLICY "certificates_select_policy" ON certificates FOR SELECT
    USING (user_id = auth.uid() OR status = 'ISSUED' OR public.is_admin(auth.uid()));
CREATE POLICY "certificates_insert_policy" ON certificates FOR INSERT TO authenticated
    WITH CHECK (public.is_admin(auth.uid()) OR public.has_any_role(auth.uid(), ARRAY['CAMPUS_MANAGER'::app_role, 'FACULTY_ADVISOR'::app_role]));
CREATE POLICY "certificates_update_policy" ON certificates FOR UPDATE TO authenticated
    USING (public.is_admin(auth.uid()) OR public.has_any_role(auth.uid(), ARRAY['CAMPUS_MANAGER'::app_role, 'FACULTY_ADVISOR'::app_role]))
    WITH CHECK (public.is_admin(auth.uid()) OR public.has_any_role(auth.uid(), ARRAY['CAMPUS_MANAGER'::app_role, 'FACULTY_ADVISOR'::app_role]));
