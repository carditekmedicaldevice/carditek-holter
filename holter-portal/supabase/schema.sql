-- ============================================================
-- Carditek Holter Patient Portal — Database Schema
-- Run this once in Supabase: Dashboard → SQL Editor → New query → Run
-- ============================================================

create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- 1. PROFILES  (one row per login account, patient or admin)
--    id = the same id Supabase Auth gives the user
-- ------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'patient' check (role in ('admin','patient')),
  must_change_password boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2. PATIENTS  (one row per patient, links 1-to-1 to profiles)
-- ------------------------------------------------------------
create table public.patients (
  id uuid primary key references public.profiles(id) on delete cascade,
  patient_code text unique not null,
  full_name text not null,
  age int,
  sex text check (sex in ('male','female','other')),
  phone text,
  email text,
  referring_doctor text,
  device_serial text,
  medical_history text,
  monitoring_start_date date,
  monitoring_end_date date,
  study_status text not null default 'active' check (study_status in ('active','completed')),
  consent_given boolean not null default false,
  consent_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- auto-generate a patient code like CTK-000123 unless admin supplies one
create sequence if not exists public.patient_code_seq start 1;

create or replace function public.set_patient_code()
returns trigger language plpgsql as $$
begin
  if new.patient_code is null or new.patient_code = '' then
    new.patient_code := 'CTK-' || lpad(nextval('public.patient_code_seq')::text, 6, '0');
  end if;
  return new;
end;
$$;

create trigger trg_set_patient_code
  before insert on public.patients
  for each row execute function public.set_patient_code();

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_patients_updated_at
  before update on public.patients
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------
-- 3. SYMPTOM ENTRIES  (recurring health-condition log)
-- ------------------------------------------------------------
create table public.symptom_entries (
  id uuid primary key default uuid_generate_v4(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  entry_time timestamptz not null default now(),
  symptoms text[] not null default '{}',   -- e.g. {"Palpitations","Dizziness"}
  severity text check (severity in ('mild','moderate','severe')),
  activity text,                            -- what they were doing
  duration text,                            -- how long it lasted
  note text,                                -- optional free text
  created_at timestamptz not null default now()
);

create index idx_symptom_entries_patient on public.symptom_entries(patient_id, entry_time desc);

-- ------------------------------------------------------------
-- 4. Helper: is the current logged-in user an admin?
-- ------------------------------------------------------------
create or replace function public.is_admin()
returns boolean language sql stable as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ------------------------------------------------------------
-- 5. ROW LEVEL SECURITY — this is what keeps patient data private
--    even though the site's Supabase keys are publicly visible.
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.symptom_entries enable row level security;

-- profiles: a user can see their own profile row; admin sees all
create policy "profiles_select_own_or_admin" on public.profiles
  for select using (id = auth.uid() or public.is_admin());

create policy "profiles_update_own_or_admin" on public.profiles
  for update using (id = auth.uid() or public.is_admin());

-- patients: patient sees/edits only their own row; admin sees/edits all
create policy "patients_select_own_or_admin" on public.patients
  for select using (id = auth.uid() or public.is_admin());

create policy "patients_insert_own_or_admin" on public.patients
  for insert with check (id = auth.uid() or public.is_admin());

create policy "patients_update_own_or_admin" on public.patients
  for update using (id = auth.uid() or public.is_admin());

create policy "patients_delete_admin_only" on public.patients
  for delete using (public.is_admin());

-- symptom_entries: patient can add/see only their own entries; admin sees all
create policy "entries_select_own_or_admin" on public.symptom_entries
  for select using (patient_id = auth.uid() or public.is_admin());

create policy "entries_insert_own_or_admin" on public.symptom_entries
  for insert with check (patient_id = auth.uid() or public.is_admin());

-- ------------------------------------------------------------
-- 6. Auto-create a profile row whenever someone signs up
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'role', 'patient'));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 7. ONE-TIME: create your single admin account
--    Do this AFTER running the SQL above:
--    1. Supabase Dashboard → Authentication → Users → Add user
--       - email: your admin email
--       - password: a strong password (only you will know it)
--       - "Auto Confirm User": ON
--    2. Then come back here and run the two lines below,
--       replacing the email with the one you just created.
-- ============================================================
-- update public.profiles set role = 'admin'
-- where id = (select id from auth.users where email = 'admin@example.com');
