-- Private/shared drawing studios and synchronized direct-video watch rooms.
create table if not exists public.duo_studio_sessions(
 id uuid primary key default gen_random_uuid(),
 space_id uuid not null references public.duo_spaces(id) on delete cascade,
 created_by uuid not null references auth.users(id) on delete cascade,
 title text not null default 'Studio',
 created_at timestamptz not null default now()
);
create table if not exists public.duo_studio_strokes(
 id uuid primary key default gen_random_uuid(),
 session_id uuid not null references public.duo_studio_sessions(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 stroke jsonb not null,
 created_at timestamptz not null default now()
);
create table if not exists public.duo_watch_rooms(
 id uuid primary key default gen_random_uuid(),
 space_id uuid not null references public.duo_spaces(id) on delete cascade,
 created_by uuid not null references auth.users(id) on delete cascade,
 updated_by uuid references auth.users(id),
 title text not null default 'Watch together',
 video_url text not null,
 position_ms integer not null default 0 check(position_ms>=0),
 playing boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.duo_studio_sessions enable row level security;
alter table public.duo_studio_strokes enable row level security;
alter table public.duo_watch_rooms enable row level security;

drop policy if exists "studio sessions members read" on public.duo_studio_sessions;
create policy "studio sessions members read" on public.duo_studio_sessions for select to authenticated
using(exists(select 1 from public.duo_members m where m.space_id=duo_studio_sessions.space_id and m.user_id=(select auth.uid())));
drop policy if exists "studio sessions members create" on public.duo_studio_sessions;
create policy "studio sessions members create" on public.duo_studio_sessions for insert to authenticated
with check(created_by=(select auth.uid()) and exists(select 1 from public.duo_members m where m.space_id=duo_studio_sessions.space_id and m.user_id=(select auth.uid())));
drop policy if exists "studio sessions creator delete" on public.duo_studio_sessions;
create policy "studio sessions creator delete" on public.duo_studio_sessions for delete to authenticated using(created_by=(select auth.uid()));

drop policy if exists "studio strokes members read" on public.duo_studio_strokes;
create policy "studio strokes members read" on public.duo_studio_strokes for select to authenticated
using(exists(select 1 from public.duo_studio_sessions s join public.duo_members m on m.space_id=s.space_id where s.id=duo_studio_strokes.session_id and m.user_id=(select auth.uid())));
drop policy if exists "studio strokes members add" on public.duo_studio_strokes;
create policy "studio strokes members add" on public.duo_studio_strokes for insert to authenticated
with check(user_id=(select auth.uid()) and exists(select 1 from public.duo_studio_sessions s join public.duo_members m on m.space_id=s.space_id where s.id=duo_studio_strokes.session_id and m.user_id=(select auth.uid())));
drop policy if exists "studio strokes owner delete" on public.duo_studio_strokes;
create policy "studio strokes owner delete" on public.duo_studio_strokes for delete to authenticated using(user_id=(select auth.uid()));

drop policy if exists "watch room members read" on public.duo_watch_rooms;
create policy "watch room members read" on public.duo_watch_rooms for select to authenticated
using(exists(select 1 from public.duo_members m where m.space_id=duo_watch_rooms.space_id and m.user_id=(select auth.uid())));
drop policy if exists "watch room members create" on public.duo_watch_rooms;
create policy "watch room members create" on public.duo_watch_rooms for insert to authenticated
with check(created_by=(select auth.uid()) and updated_by=(select auth.uid()) and exists(select 1 from public.duo_members m where m.space_id=duo_watch_rooms.space_id and m.user_id=(select auth.uid())));
drop policy if exists "watch room members update" on public.duo_watch_rooms;
create policy "watch room members update" on public.duo_watch_rooms for update to authenticated
using(exists(select 1 from public.duo_members m where m.space_id=duo_watch_rooms.space_id and m.user_id=(select auth.uid())))
with check(updated_by=(select auth.uid()) and exists(select 1 from public.duo_members m where m.space_id=duo_watch_rooms.space_id and m.user_id=(select auth.uid())));
drop policy if exists "watch room creator delete" on public.duo_watch_rooms;
create policy "watch room creator delete" on public.duo_watch_rooms for delete to authenticated using(created_by=(select auth.uid()));

do $$begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='duo_studio_strokes') then alter publication supabase_realtime add table public.duo_studio_strokes;end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='duo_watch_rooms') then alter publication supabase_realtime add table public.duo_watch_rooms;end if;
end$$;
