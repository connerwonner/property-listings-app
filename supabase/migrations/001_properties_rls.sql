-- 001_properties_rls.sql
-- Table + Row-Level Security for property-listings-app
-- Maps src/types.ts `Property` to a Postgres table, plus owner_id and status for access control.

create table if not exists public.properties (
  id             uuid primary key default gen_random_uuid(),
  owner_id       uuid not null references auth.users(id) on delete cascade default auth.uid(),
  address        text not null,
  price          numeric not null check (price >= 0),
  bedrooms       int  not null,
  bathrooms      numeric not null,
  sqft           int  not null,
  property_type  text not null,
  image_url      text,
  status         text not null default 'draft' check (status in ('draft','published')),
  created_at     timestamptz not null default now()
);

-- 1) Enable RLS (deny-by-default for anon/authenticated until a policy allows access)
alter table public.properties enable row level security;
alter table public.properties force row level security;

-- 2) Privilege-level hardening (column-level control)
revoke all on public.properties from anon, authenticated;
grant select on public.properties to anon;
grant select, insert, delete on public.properties to authenticated;
-- owner_id and id are intentionally NOT updatable by clients
grant update (address, price, bedrooms, bathrooms, sqft, property_type, image_url, status)
  on public.properties to authenticated;

-- 3) Policies
-- SELECT: anyone sees published listings; owners also see their own drafts
create policy "properties_select_published_or_own" on public.properties
  for select to anon, authenticated
  using (status = 'published' or auth.uid() = owner_id);

-- INSERT: authenticated users may only create rows owned by themselves
create policy "properties_insert_own" on public.properties
  for insert to authenticated
  with check (auth.uid() = owner_id);

-- UPDATE: owner only (row must be theirs before and after the change)
create policy "properties_update_own" on public.properties
  for update to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- DELETE: owner only
create policy "properties_delete_own" on public.properties
  for delete to authenticated
  using (auth.uid() = owner_id);

-- ADMIN: custom claim in app_metadata (only settable server-side / by service_role)
create policy "properties_admin_all" on public.properties
  for all to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean, false))
  with check (coalesce((auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean, false));

-- Note: service_role has BYPASSRLS, so it needs no policy.

-- (Optional) grant admin to a test user:
-- update auth.users
--   set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"is_admin": true}'
--   where email = 'admin@test.com';

-- Evidence for the lab: dump the live policies
-- select policyname, cmd, roles, qual, with_check from pg_policies where tablename = 'properties';
