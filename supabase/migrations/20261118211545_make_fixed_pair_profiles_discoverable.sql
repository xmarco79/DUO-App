-- The OURS installation has one fixed pair of accounts: naif and zoi.
-- Allow only those two authenticated users to read each other's profile,
-- even before either account joins a shared space. No other profiles become discoverable.
drop policy if exists "fixed OURS pair can see each other's profiles"
  on public.duo_profiles;

create policy "fixed OURS pair can see each other's profiles"
on public.duo_profiles
for select
to authenticated
using (
  user_id in (
    'b771a6d1-3180-4f50-b81c-66924665151a'::uuid,
    '01d9c50a-98fe-4998-ae79-c48fd5ac3fd3'::uuid
  )
  and (select auth.uid()) in (
    'b771a6d1-3180-4f50-b81c-66924665151a'::uuid,
    '01d9c50a-98fe-4998-ae79-c48fd5ac3fd3'::uuid
  )
);
