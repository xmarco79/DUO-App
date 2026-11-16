-- Shared content foundation for the five OURS worlds.
create table if not exists public.duo_world_items (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  world text not null check (world in ('connect','universe','play','memories','together')),
  kind text not null check (length(kind) between 2 and 60),
  title text not null check (length(trim(title)) between 1 and 140),
  content text not null default '' check (length(content) <= 10000),
  payload jsonb not null default '{}'::jsonb,
  is_pinned boolean not null default false,
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists duo_world_items_space_world_created_idx
  on public.duo_world_items(space_id, world, created_at desc);
create index if not exists duo_world_items_space_kind_idx
  on public.duo_world_items(space_id, kind);
alter table public.duo_world_items enable row level security;
grant select, insert, update, delete on public.duo_world_items to authenticated;
drop policy if exists "Members can read world items" on public.duo_world_items;
create policy "Members can read world items" on public.duo_world_items
for select to authenticated
using (exists (select 1 from public.duo_members m
  where m.space_id = duo_world_items.space_id and m.user_id = (select auth.uid())));
drop policy if exists "Members can create world items" on public.duo_world_items;
create policy "Members can create world items" on public.duo_world_items
for insert to authenticated
with check (created_by = (select auth.uid()) and exists (
  select 1 from public.duo_members m
  where m.space_id = duo_world_items.space_id and m.user_id = (select auth.uid())));
drop policy if exists "Members can update world items" on public.duo_world_items;
create policy "Members can update world items" on public.duo_world_items
for update to authenticated
using (exists (select 1 from public.duo_members m
  where m.space_id = duo_world_items.space_id and m.user_id = (select auth.uid())))
with check (exists (select 1 from public.duo_members m
  where m.space_id = duo_world_items.space_id and m.user_id = (select auth.uid())));
drop policy if exists "Members can delete world items" on public.duo_world_items;
create policy "Members can delete world items" on public.duo_world_items
for delete to authenticated
using (exists (select 1 from public.duo_members m
  where m.space_id = duo_world_items.space_id and m.user_id = (select auth.uid())));
