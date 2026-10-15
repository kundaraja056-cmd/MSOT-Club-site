# MSOT CLUB ACTIVITIES TRACKER — ARCHITECTURE & PRODUCTION SPEC

## 1. PROJECT SCOPE & BOUNDARIES
Multi-campus student club and activities management platform with real authentication, RLS, file storage, QR-based attendance, assignment evaluation, and verifiable credentials.
- Strictly prohibited: Mock data, fake UI cards, unstyled generic AI landing pages, client-side role checks, inline base64 image storage in PostgreSQL.
- Access model: Role-Based Access Control (RBAC) enforced exclusively at the database (RLS) and server middleware layers.
- Campus clubs: Preserve existing "AI First Club" naming where referenced. No student-facing "Create Club" buttons.

## 2. MANDATORY SEED CLUBS (PERSISTENT & REPEATABLE)
Seed via an idempotent script or migration. Do not hallucinate missing roles.
1. CodeConnect (Coding and Technology)
   - President: Sia Charan | Vice President: Akshara | Mentor: Harsh Bhaiya
   - Categories: Coding competitions, Programming workshops, DSA, Web development, Open-source, Project demos, Hackathon prep.
2. Nexcell (Entrepreneurship and Innovation)
   - President: Rudra | Vice President: [Unassigned] | Mentor: [Unassigned]
   - Categories: Startup presentations, Business model challenges, Market research, Product ideation, Pitching competitions, Workshops.
3. Sports Club (Sports and Athletics)
   - President: Astithwa | Vice President: Piyush Tripathi | Mentor: Aditya Bhaiya
   - Categories: Football, Basketball, Cricket, Badminton, Fitness, Tournaments, Team-building.
4. TechnoTribe (Cultural and Creative Activities)
   - President: Sathwik Satya | Vice President: Deepu | Mentor: Syed Sir
   - Categories: Cultural festivals, Music & dance, Stage performances, Creative workshops, Photography, Art & design.

## 3. CORE TECHNICAL ARCHITECTURE
- Framework: Next.js (App Router), TypeScript (strict mode), Tailwind CSS.
- Database & Auth: PostgreSQL + Supabase Auth.
- Security: Row-Level Security (RLS) on every table; private object storage for submissions and raw event images; signed/public delivery for published gallery assets.
- Validation: Zod schemas shared between client forms (React Hook Form) and server actions/route handlers.
- Documents: Server-side PDF generation for certificates and transcripts.
- Testing: Vitest for core business logic, Playwright for end-to-end user journeys.

## 4. ROLE HIERARCHY & ROUTE ENFORCEMENT
Roles: SYSTEM_ADMIN, PROGRAM_MANAGER, CAMPUS_MANAGER, FACULTY_ADVISOR, STUDENT_COORDINATOR, STUDENT.
- Route protection: Enforced via Next.js middleware using verified server-side JWT claims.
- Data protection: Enforced via Postgres RLS policies based on auth.uid() and assigned role tables.
