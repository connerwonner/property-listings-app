
-- Lab 5: Restrict owner updates to draft properties
-- Contributor: guillenemily4-debug

drop policy if exists "properties_update_own"
on public.properties;

create policy "properties_update_own"
on public.properties
for update
to authenticated
using (
  auth.uid() = owner_id
  and status = 'draft'
)
with check (
  auth.uid() = owner_id
  and status = 'draft'
);

-- Restrict owner deletions to draft properties

drop policy if exists "properties_delete_own"
on public.properties;

create policy "properties_delete_own"
on public.properties
for delete
to authenticated
using (
  auth.uid() = owner_id
  and status = 'draft'
);
