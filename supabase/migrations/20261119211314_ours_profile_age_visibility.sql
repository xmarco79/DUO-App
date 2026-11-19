alter table public.duo_profiles
  add column if not exists show_age boolean not null default false;

grant update(show_age) on public.duo_profiles to authenticated;
