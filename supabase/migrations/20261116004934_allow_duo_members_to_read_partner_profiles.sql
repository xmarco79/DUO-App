-- Allow members of the same private space to see each other's public profile labels.
-- Profile rows expose only username and display_name through the app query.
create policy "duo members can read each other's profiles"
on public.duo_profiles
for select
to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1
    from public.duo_members as viewer
    join public.duo_members as subject
      on subject.space_id = viewer.space_id
    where viewer.user_id = (select auth.uid())
      and subject.user_id = duo_profiles.user_id
  )
);
