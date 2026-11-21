alter table public.duo_stickers
  add column if not exists pack_name text not null default 'OURS',
  add column if not exists display_name text,
  add column if not exists is_animated boolean not null default false;

create index if not exists duo_stickers_space_pack_created_idx
  on public.duo_stickers(space_id, pack_name, created_at desc);

create table if not exists public.duo_sticker_favorites (
  sticker_id uuid not null references public.duo_stickers(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(sticker_id,user_id)
);
alter table public.duo_sticker_favorites enable row level security;
drop policy if exists "duo sticker favorites own rows" on public.duo_sticker_favorites;
create policy "duo sticker favorites own rows"
on public.duo_sticker_favorites for all to authenticated
using (
  user_id = (select auth.uid())
  and exists(select 1 from public.duo_stickers s where s.id=sticker_id and private.is_duo_member(s.space_id))
)
with check (
  user_id = (select auth.uid())
  and exists(select 1 from public.duo_stickers s where s.id=sticker_id and private.is_duo_member(s.space_id))
);
grant select,insert,delete on public.duo_sticker_favorites to authenticated;

update storage.buckets
set allowed_mime_types = array(
  select distinct mime
  from unnest(coalesce(allowed_mime_types,array[]::text[]) || array['image/gif']::text[]) as mime
)
where id='ours-stickers';
