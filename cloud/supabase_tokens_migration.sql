-- =============================================================================
-- CABINEX AI - TOKENS & COMPLEXITY PRICING SCHEMA
-- Run this in your Supabase SQL Editor
-- =============================================================================

-- 1. Ensure cabinex_subscriptions has token balance columns
alter table if exists public.cabinex_subscriptions 
  add column if not exists tokens_total integer default 100,
  add column if not exists tokens_used integer default 0,
  add column if not exists tokens_balance integer default 100;

-- 2. Ensure cabinex_licenses has token balance columns
alter table if exists public.cabinex_licenses 
  add column if not exists tokens_total integer default 100,
  add column if not exists tokens_used integer default 0,
  add column if not exists tokens_balance integer default 100;

-- 3. Ensure cabinex_activity_logs records token cost & complexity
alter table if exists public.cabinex_activity_logs 
  add column if not exists tokens_consumed integer default 1,
  add column if not exists tokens_remaining integer default 99,
  add column if not exists complexity_level text default 'STANDARD';

-- 4. Initial Top-up for test user asanke1@gmail.com (100 Tokens)
insert into public.cabinex_subscriptions (id, email, subscription_status, tokens_total, tokens_used, tokens_balance, expires_at)
values (
  (select id from auth.users where email = 'asanke1@gmail.com' limit 1),
  'asanke1@gmail.com',
  'active',
  100,
  0,
  100,
  now() + interval '365 days'
)
on conflict (id) do update 
set tokens_total = 100,
    tokens_balance = 100,
    subscription_status = 'active';
