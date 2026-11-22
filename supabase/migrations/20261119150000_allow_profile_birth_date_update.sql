-- Allow users to save their own birth date through profile settings.
-- Existing profile RLS policies continue to restrict rows to auth.uid().
grant update (birth_date)
on table public.duo_profiles to authenticated;
