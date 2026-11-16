-- Keep username immutable from the client API; only display_name is user-editable.
revoke update on table public.duo_profiles from authenticated;
grant update (display_name) on table public.duo_profiles to authenticated;
