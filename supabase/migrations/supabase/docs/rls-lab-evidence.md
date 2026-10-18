Row-Level Security Lab: properties table

Project: property-listings-app, backed by Supabase (PostgreSQL + PostgREST). Migration: supabase/migrations/001_properties_rls.sql Test script: supabase/test_rls.sh

1. Target table and RLS definition

Table: public.properties

Columns: id, owner_id, address, price, bedrooms, bathrooms, sqft, property_type, image_url, status, created_at. These map to the Property type in src/types.ts, plus owner_id (who owns the listing) and status (draft or published).
alter table public.properties enable row level security;
alter table public.properties force row level security;

revoke all on public.properties from anon, authenticated;
grant select on public.properties to anon;
grant select, insert, delete on public.properties to authenticated;
grant update (address, price, bedrooms, bathrooms, sqft, property_type, image_url, status)
  on public.properties to authenticated;   -- owner_id and id are NOT updatable

create policy "properties_select_published_or_own" on public.properties
  for select to anon, authenticated
  using (status = 'published' or auth.uid() = owner_id);

create policy "properties_insert_own" on public.properties
  for insert to authenticated
  with check (auth.uid() = owner_id);

create policy "properties_update_own" on public.properties
  for update to authenticated
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "properties_delete_own" on public.properties
  for delete to authenticated
  using (auth.uid() = owner_id);

create policy "properties_admin_all" on public.properties
  for all to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean, false))
  with check (coalesce((auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean, false));service_role has BYPASSRLS, so it needs no policy.

Live policies in the database (select policyname, cmd, roles, qual, with_check from pg_policies where tablename = 'properties';):

Show Image

Policy	Command	Roles	Predicate
properties_select_published_or_own	SELECT	anon, authenticated	status = 'published' OR auth.uid() = owner_id
properties_insert_own	INSERT	authenticated	WITH CHECK (auth.uid() = owner_id)
properties_update_own	UPDATE	authenticated	USING and WITH CHECK (auth.uid() = owner_id)
properties_delete_own	DELETE	authenticated	USING (auth.uid() = owner_id)
properties_admin_all	ALL	authenticated	app_metadata.is_admin = true
2. Role operations matrix
Role	Permitted operation and predicate	Denied operation and predicate
Anonymous (anon)	SELECT where status = 'published'	INSERT: anon has no INSERT privilege and no INSERT policy
Resource owner	UPDATE where auth.uid() = owner_id, limited to the granted columns	UPDATE owner_id: column privilege not granted. Also INSERT with owner_id <> auth.uid() fails WITH CHECK
Other authenticated user	SELECT where status = 'published'	UPDATE or DELETE on another user's row: USING (auth.uid() = owner_id) is false, so 0 rows match
Administrator	Any operation where app_metadata.is_admin = true, or service_role, which bypasses RLS	A normal user granting themselves admin: app_metadata is writable only server-side, so the claim can't be forged

The administrator role was not exercised in the live test. It follows from the properties_admin_all policy and from service_role having BYPASSRLS.

3. Verification evidence

Test data: two users, owner@test.com (User A) and other@test.com (User B). User A created one published listing (b0ebe9eb-36d4-40db-8e2b-3c80e5bccbbc) and one draft (82ce1f21-6d76-47ea-9085-2439e3c49a41). User A's id is c4344a60-c4d5-41cd-b2cb-a7a292f7d1b9.

In the commands below, $URL is the project's REST base URL, $ANON is the project's anon key, and $JWT_B is User B's access token from /auth/v1/token?grant_type=password.

Anonymous user

Auth header state: Authorization: Bearer $ANON. This is the anon role, with no user JWT.

Write blocked: INSERT

bash
curl -s -w "\nHTTP STATUS: %{http_code}\n" -X POST "$URL/rest/v1/properties" \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" -H "Content-Type: application/json" \
  -d '{"address":"hacked","price":1,"bedrooms":1,"bathrooms":1,"sqft":1,"property_type":"house"}'
{"code":"42501","details":null,"hint":"Grant the required privileges to the current role with: GRANT INSERT ON public.properties TO anon;","message":"permission denied for table properties"}
HTTP STATUS: 401

Draft hidden: SELECT of User A's draft

bash
curl -s -w "\nHTTP STATUS: %{http_code}\n" "$URL/rest/v1/properties?id=eq.82ce1f21-6d76-47ea-9085-2439e3c49a41" \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
[]
HTTP STATUS: 200

Only published rows visible: SELECT all

bash
curl -s -w "\nHTTP STATUS: %{http_code}\n" "$URL/rest/v1/properties?select=id,address,status" \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
[{"id":"b0ebe9eb-36d4-40db-8e2b-3c80e5bccbbc","address":"123 Maple St","status":"published"}]
HTTP STATUS: 200
Other authenticated user (User B)

Auth header state: Authorization: Bearer $JWT_B. This is a logged-in user who does not own the target rows.

Cross-user UPDATE

bash
curl -s -w "\nHTTP STATUS: %{http_code}\n" -X PATCH "$URL/rest/v1/properties?id=eq.b0ebe9eb-36d4-40db-8e2b-3c80e5bccbbc" \
  -H "apikey: $ANON" -H "Authorization: Bearer $JWT_B" -H "Content-Type: application/json" \
  -H "Prefer: return=representation" -d '{"address":"owned by B now"}'
[]
HTTP STATUS: 200

Cross-user DELETE

bash
curl -s -w "\nHTTP STATUS: %{http_code}\n" -X DELETE "$URL/rest/v1/properties?id=eq.b0ebe9eb-36d4-40db-8e2b-3c80e5bccbbc" \
  -H "apikey: $ANON" -H "Authorization: Bearer $JWT_B" -H "Prefer: return=representation"
[]
HTTP STATUS: 200

Cross-user read of User A's draft

bash
curl -s -w "\nHTTP STATUS: %{http_code}\n" "$URL/rest/v1/properties?id=eq.82ce1f21-6d76-47ea-9085-2439e3c49a41" \
  -H "apikey: $ANON" -H "Authorization: Bearer $JWT_B"
[]
HTTP STATUS: 200

Spoofed INSERT (owner_id set to User A)

bash
curl -s -w "\nHTTP STATUS: %{http_code}\n" -X POST "$URL/rest/v1/properties" \
  -H "apikey: $ANON" -H "Authorization: Bearer $JWT_B" -H "Content-Type: application/json" \
  -d '{"owner_id":"c4344a60-c4d5-41cd-b2cb-a7a292f7d1b9","address":"spoof","price":1,"bedrooms":1,"bathrooms":1,"sqft":1,"property_type":"house"}'
{"code":"42501","details":null,"hint":null,"message":"new row violates row-level security policy for table \"properties\""}
HTTP STATUS: 403

Proof the row was untouched: User A's later update of the same row returned it with the address still 123 Maple St. The attempted address change and delete by User B had no effect.

Resource owner (User A): allowed and denied

Allowed: UPDATE own row

[{"id":"b0ebe9eb-36d4-40db-8e2b-3c80e5bccbbc","owner_id":"c4344a60-c4d5-41cd-b2cb-a7a292f7d1b9","address":"123 Maple St","price":430000,"bedrooms":3,"bathrooms":2,"sqft":1600,"property_type":"house","image_url":null,"status":"published","created_at":"2026-10-18T01:22:04.098511+00:00"}]
HTTP STATUS: 200

Denied: UPDATE owner_id, which is blocked by column-level privilege

{"code":"42501","details":null,"hint":"Grant the required privileges to the current role with: GRANT UPDATE ON public.properties TO authenticated;","message":"permission denied for table properties"}
HTTP STATUS: 403

Full terminal output of the test run:

Show Image

4. Security implication: [] vs. 403
401 vs. 403: PostgREST returns 401 when the caller is the unauthenticated anon role and 403 when the caller is authenticated but not permitted. This tells a client whether to prompt a login or show "not allowed."
Empty array [] with 200: RLS silently filters the rows out instead of rejecting the request. This is good for secrecy. An attacker can't tell whether a record exists or is merely hidden, which prevents enumeration of IDs and draft listings. The risk is that [] is ambiguous. It could mean no data, a block by RLS, or a policy bug. A client can also mistake a 200 for success when an update changed nothing, so application code must check that the affected row count is above zero.
Explicit 401/403: The failure is unambiguous and easier to debug and audit. The downside is that it confirms the table and policy exist, which helps an attacker map the schema. A 403 appears only for writes that violate WITH CHECK or privileges, never for filtered reads.
If an unauthenticated user got [] where this lab expected 403: that is fine for reads, since the data is hidden. For writes, it would mean the request was filtered rather than rejected, so the caller never learns the write failed. That is why the anonymous INSERT here is blocked at the privilege level and returns an explicit 401.
The dangerous case is neither of these. If RLS were disabled or a policy were too permissive (using (true)), an unauthenticated user would receive real data with a 200. The anonymous SELECT above returned only the published listing, which confirms that is not happening.
  
