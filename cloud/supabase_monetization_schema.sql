-- =============================================================================
-- CABINEX AI - MONETIZATION, LICENSE TOKENS & ACTIVITY AUDIT SYSTEM
-- Run this in your Supabase SQL Editor (Safe namespaced tables)
-- =============================================================================

-- 1. License Tokens Table (For Monetization & Resale)
create table if not exists public.cabinex_licenses (
  id uuid default gen_random_uuid() primary key,
  license_key text unique not null,               -- e.g. "CBX-PRO-8492-7102"
  client_name text not null,                      -- Customer or Studio Name
  client_email text,                              -- Registered contact email
  plan_type text default 'PRO',                   -- 'TRIAL', 'STARTER', 'PRO', 'ENTERPRISE'
  duration_days integer default 30,               -- Duration in days
  max_kitchens integer default 100,               -- Quota limit per billing cycle
  kitchens_used integer default 0,                -- Real-time counter
  status text default 'ACTIVE',                   -- 'ACTIVE', 'SUSPENDED', 'EXPIRED'
  expires_at timestamp with time zone default (now() + interval '30 days'),
  created_at timestamp with time zone default now()
);

-- 2. Activity & Telemetry Audit Log Table
create table if not exists public.cabinex_activity_logs (
  id uuid default gen_random_uuid() primary key,
  user_identifier text not null,                  -- Email or License Key
  action_type text not null,                      -- 'LOGIN', '3D_KITCHEN_GENERATED', 'QUOTATION_EXPORTED'
  project_name text,                              -- Name of the kitchen project
  wall_a_mm integer,                              -- Wall A length in mm
  wall_b_mm integer,                              -- Wall B length in mm
  total_linear_ft numeric,                        -- Kitchen covered linear length
  quoted_amount_lkr numeric,                      -- Total customer quotation in LKR
  details jsonb,                                  -- Extra metadata (modules, style, etc.)
  created_at timestamp with time zone default now()
);

-- 3. Row Level Security
alter table public.cabinex_licenses enable row level security;
alter table public.cabinex_activity_logs enable row level security;

-- Allow public service role / authenticated access
create policy "Allow license lookup" on public.cabinex_licenses for select using (true);
create policy "Allow activity insert" on public.cabinex_activity_logs for insert with check (true);
create policy "Allow activity read" on public.cabinex_activity_logs for select using (true);
