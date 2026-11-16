create table if not exists public.duo_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null default 'android' check (platform in ('android')),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
create index if not exists duo_push_tokens_user_id_idx on public.duo_push_tokens(user_id);
alter table public.duo_push_tokens enable row level security;
revoke all on public.duo_push_tokens from anon;
grant select, insert, update, delete on public.duo_push_tokens to authenticated;
drop policy if exists "Users manage own push tokens" on public.duo_push_tokens;
create policy "Users manage own push tokens"
on public.duo_push_tokens for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
