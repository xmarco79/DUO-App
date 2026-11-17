-- Allow authenticated users to update only their own profile's editable fields.
-- Row-level security still limits the affected row to auth.uid().
grant update (display_name, avatar_path, bio)
on table public.duo_profiles to authenticated;
