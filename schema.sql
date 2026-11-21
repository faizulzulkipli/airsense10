-- =====================================================================
-- CPAP Data Manager (ResMed AirSense 10) - Supabase schema
-- Run this once in: Supabase Dashboard > SQL Editor > New query > Run
-- Safe to re-run (uses IF NOT EXISTS / DROP POLICY IF EXISTS).
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- 1. Patients (each row belongs to the logged-in user who created it)
-- ---------------------------------------------------------------------
create table if not exists public.patients (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  full_name        text not null,
  ic_or_ref        text,                       -- IC number / clinic reference
  date_of_birth    date,
  device_model     text default 'AirSense 10',
  device_serial    text,
  mask_type        text,                       -- optional: Nasal / Full face / Nasal pillows (overrides the machine setting in reports)
  notes            text,
  created_at       timestamptz not null default now()
);
create index if not exists patients_owner_idx on public.patients(owner_id);

-- ---------------------------------------------------------------------
-- 2. Sessions = one row per therapy night (noon-to-noon day, as ResMed does)
--    Leak is stored in L/min, pressure in cmH2O.
-- ---------------------------------------------------------------------
create table if not exists public.sessions (
  id               uuid primary key default gen_random_uuid(),
  patient_id       uuid not null references public.patients(id) on delete cascade,
  session_date     date not null,              -- the day the night started (noon-to-noon)
  first_on         timestamp,                  -- device local time
  last_off         timestamp,
  usage_minutes    numeric(8,1) not null default 0,
  mask_sessions    int not null default 0,     -- number of mask-on/off periods
  ahi              numeric(5,2),
  ai               numeric(5,2),
  hi               numeric(5,2),
  oai              numeric(5,2),
  cai              numeric(5,2),
  uai              numeric(5,2),
  leak_50          numeric(6,2),
  leak_95          numeric(6,2),
  leak_max         numeric(6,2),
  press_50         numeric(5,2),
  press_95         numeric(5,2),
  press_max        numeric(5,2),
  resp_rate_50     numeric(5,1),
  min_vent_50      numeric(5,1),
  oa_count         int,                        -- event counts from the EVE file (null = no event file imported)
  ca_count         int,
  h_count          int,
  ua_count         int,
  rera_count       int,
  csr_minutes      numeric(7,1),               -- Cheyne-Stokes respiration minutes (CSL file)
  stats            jsonb,                      -- per-signal min/p50/p90/p95/max/avg computed from full-resolution (2 s) data
  settings         jsonb,                      -- device settings that night (Mode, EPR, pressure range, ramp ...)
  series           jsonb,                      -- per-minute curves: {"t":[min since noon],"mp":[],"epr":[],"tp":[],"lk":[],"rr":[],"tv":[],"mv":[],"sn":[],"fl":[]}
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (patient_id, session_date)
);
create index if not exists sessions_patient_date_idx on public.sessions(patient_id, session_date);

-- Upgrade path: safe to run on a database created with the first version of this schema
alter table public.patients add column if not exists mask_type text;
alter table public.sessions add column if not exists oa_count   int;
alter table public.sessions add column if not exists ca_count   int;
alter table public.sessions add column if not exists h_count    int;
alter table public.sessions add column if not exists ua_count   int;
alter table public.sessions add column if not exists rera_count int;
alter table public.sessions add column if not exists csr_minutes numeric(7,1);
alter table public.sessions add column if not exists stats      jsonb;
alter table public.sessions add column if not exists settings   jsonb;

-- ---------------------------------------------------------------------
-- 3. Events (apneas, hypopneas, arousals) from the *_EVE.edf files
--    onset_sec = seconds since 12:00 noon of session_date
-- ---------------------------------------------------------------------
create table if not exists public.events (
  id               bigint generated always as identity primary key,
  session_id       uuid not null references public.sessions(id) on delete cascade,
  patient_id       uuid not null references public.patients(id) on delete cascade,
  event_type       text not null,
  onset_sec        numeric(10,1) not null,
  duration_sec     numeric(7,1) not null default 0
);
create index if not exists events_session_idx on public.events(session_id);
create index if not exists events_patient_idx on public.events(patient_id);

-- ---------------------------------------------------------------------
-- 4. Import log (audit trail of SD card imports)
-- ---------------------------------------------------------------------
create table if not exists public.imports (
  id               bigint generated always as identity primary key,
  patient_id       uuid not null references public.patients(id) on delete cascade,
  nights_count     int not null,
  date_from        date,
  date_to          date,
  imported_at      timestamptz not null default now()
);
create index if not exists imports_patient_idx on public.imports(patient_id);

-- ---------------------------------------------------------------------
-- 5. Keep updated_at fresh
-- ---------------------------------------------------------------------
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists sessions_touch on public.sessions;
create trigger sessions_touch before update on public.sessions
for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------
-- 6. Row Level Security: every user only sees their own patients' data
-- ---------------------------------------------------------------------
alter table public.patients enable row level security;
alter table public.sessions enable row level security;
alter table public.events   enable row level security;
alter table public.imports  enable row level security;

drop policy if exists patients_owner on public.patients;
create policy patients_owner on public.patients
  for all to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists sessions_owner on public.sessions;
create policy sessions_owner on public.sessions
  for all to authenticated
  using (patient_id in (select id from public.patients where owner_id = auth.uid()))
  with check (patient_id in (select id from public.patients where owner_id = auth.uid()));

drop policy if exists events_owner on public.events;
create policy events_owner on public.events
  for all to authenticated
  using (patient_id in (select id from public.patients where owner_id = auth.uid()))
  with check (patient_id in (select id from public.patients where owner_id = auth.uid()));

drop policy if exists imports_owner on public.imports;
create policy imports_owner on public.imports
  for all to authenticated
  using (patient_id in (select id from public.patients where owner_id = auth.uid()))
  with check (patient_id in (select id from public.patients where owner_id = auth.uid()));

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
