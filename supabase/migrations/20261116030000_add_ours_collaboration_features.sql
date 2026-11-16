-- OURS collaboration foundation: private notifications, message reactions,
-- photo albums/media metadata, and turn-based multiplayer game sessions.

create table if not exists public.duo_notifications (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  notification_type text not null check (notification_type in ('message','world_item','reaction','game')),
  title text not null,
  body text not null default '',
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists duo_notifications_user_created_idx on public.duo_notifications(user_id, created_at desc);
create index if not exists duo_notifications_space_idx on public.duo_notifications(space_id, created_at desc);
alter table public.duo_notifications enable row level security;
create policy "Users read their own notifications" on public.duo_notifications for select to authenticated using (user_id = (select auth.uid()));
create policy "Users update their own notifications" on public.duo_notifications for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create table if not exists public.duo_message_reactions (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.duo_messages(id) on delete cascade,
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  emoji text not null check (char_length(emoji) between 1 and 16),
  created_at timestamptz not null default now(),
  unique(message_id, user_id, emoji)
);
create index if not exists duo_message_reactions_message_idx on public.duo_message_reactions(message_id);
alter table public.duo_message_reactions enable row level security;
create policy "Space members read message reactions" on public.duo_message_reactions for select to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_message_reactions.space_id and m.user_id = (select auth.uid())));
create policy "Members add their own reactions" on public.duo_message_reactions for insert to authenticated with check (user_id = (select auth.uid()) and exists (select 1 from public.duo_members m where m.space_id = duo_message_reactions.space_id and m.user_id = (select auth.uid())) and exists (select 1 from public.duo_messages msg where msg.id = duo_message_reactions.message_id and msg.space_id = duo_message_reactions.space_id));
create policy "Members remove their own reactions" on public.duo_message_reactions for delete to authenticated using (user_id = (select auth.uid()));

create table if not exists public.duo_albums (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  description text not null default '',
  cover_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists duo_albums_space_created_idx on public.duo_albums(space_id, created_at desc);
alter table public.duo_albums enable row level security;
create policy "Space members read albums" on public.duo_albums for select to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_albums.space_id and m.user_id = (select auth.uid())));
create policy "Space members create albums" on public.duo_albums for insert to authenticated with check (created_by = (select auth.uid()) and exists (select 1 from public.duo_members m where m.space_id = duo_albums.space_id and m.user_id = (select auth.uid())));
create policy "Space members update albums" on public.duo_albums for update to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_albums.space_id and m.user_id = (select auth.uid()))) with check (exists (select 1 from public.duo_members m where m.space_id = duo_albums.space_id and m.user_id = (select auth.uid())));
create policy "Space members delete albums" on public.duo_albums for delete to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_albums.space_id and m.user_id = (select auth.uid())));

create table if not exists public.duo_album_media (
  id uuid primary key default gen_random_uuid(),
  album_id uuid not null references public.duo_albums(id) on delete cascade,
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  media_type text not null default 'image' check (media_type in ('image','video')),
  caption text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists duo_album_media_album_created_idx on public.duo_album_media(album_id, created_at desc);
alter table public.duo_album_media enable row level security;
create policy "Space members read album media" on public.duo_album_media for select to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_album_media.space_id and m.user_id = (select auth.uid())));
create policy "Space members upload album media" on public.duo_album_media for insert to authenticated with check (uploaded_by = (select auth.uid()) and exists (select 1 from public.duo_members m where m.space_id = duo_album_media.space_id and m.user_id = (select auth.uid())) and exists (select 1 from public.duo_albums a where a.id = duo_album_media.album_id and a.space_id = duo_album_media.space_id));
create policy "Space members delete album media" on public.duo_album_media for delete to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_album_media.space_id and m.user_id = (select auth.uid())));

create table if not exists public.duo_game_sessions (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  game_type text not null check (game_type in ('tic_tac_toe','quiz','guess_word','this_or_that','who_knows_who')),
  created_by uuid not null references auth.users(id) on delete cascade,
  status text not null default 'waiting' check (status in ('waiting','active','completed','cancelled')),
  current_turn_user_id uuid references auth.users(id) on delete set null,
  winner_user_id uuid references auth.users(id) on delete set null,
  state jsonb not null default '{}'::jsonb,
  turn_number integer not null default 0 check (turn_number >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists duo_game_sessions_space_updated_idx on public.duo_game_sessions(space_id, updated_at desc);
alter table public.duo_game_sessions enable row level security;
create policy "Space members read game sessions" on public.duo_game_sessions for select to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_game_sessions.space_id and m.user_id = (select auth.uid())));
create policy "Space members create game sessions" on public.duo_game_sessions for insert to authenticated with check (created_by = (select auth.uid()) and exists (select 1 from public.duo_members m where m.space_id = duo_game_sessions.space_id and m.user_id = (select auth.uid())));
create policy "Space members update game sessions" on public.duo_game_sessions for update to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_game_sessions.space_id and m.user_id = (select auth.uid()))) with check (exists (select 1 from public.duo_members m where m.space_id = duo_game_sessions.space_id and m.user_id = (select auth.uid())));

create table if not exists public.duo_game_moves (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.duo_game_sessions(id) on delete cascade,
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  player_id uuid not null references auth.users(id) on delete cascade,
  turn_number integer not null check (turn_number > 0),
  move jsonb not null,
  created_at timestamptz not null default now(),
  unique(session_id, turn_number)
);
create index if not exists duo_game_moves_session_idx on public.duo_game_moves(session_id, turn_number);
alter table public.duo_game_moves enable row level security;
create policy "Space members read game moves" on public.duo_game_moves for select to authenticated using (exists (select 1 from public.duo_members m where m.space_id = duo_game_moves.space_id and m.user_id = (select auth.uid())));
create policy "Players add own game moves" on public.duo_game_moves for insert to authenticated with check (player_id = (select auth.uid()) and exists (select 1 from public.duo_members m where m.space_id = duo_game_moves.space_id and m.user_id = (select auth.uid())) and exists (select 1 from public.duo_game_sessions s where s.id = duo_game_moves.session_id and s.space_id = duo_game_moves.space_id));

create or replace function public.ours_notify_partner()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_space_id uuid; v_actor_id uuid; v_type text; v_title text; v_body text; v_entity_id uuid; v_member record;
begin
  if tg_table_name = 'duo_messages' then
    v_space_id := new.space_id; v_actor_id := new.sender_id; v_type := 'message'; v_title := 'رسالة جديدة'; v_body := 'لديك رسالة جديدة في OURS'; v_entity_id := new.id;
  else
    v_space_id := new.space_id; v_actor_id := new.created_by; v_type := 'world_item'; v_title := 'إضافة جديدة'; v_body := 'تمت إضافة شيء جديد إلى عالمكما'; v_entity_id := new.id;
  end if;
  for v_member in select m.user_id from public.duo_members m where m.space_id = v_space_id and m.user_id <> v_actor_id loop
    insert into public.duo_notifications(space_id,user_id,actor_id,notification_type,title,body,data)
    values (v_space_id,v_member.user_id,v_actor_id,v_type,v_title,v_body,jsonb_build_object('entity_id',v_entity_id,'source_table',tg_table_name));
  end loop;
  return new;
end;
$$;
drop trigger if exists ours_notify_message_partner on public.duo_messages;
create trigger ours_notify_message_partner after insert on public.duo_messages for each row execute function public.ours_notify_partner();
drop trigger if exists ours_notify_world_item_partner on public.duo_world_items;
create trigger ours_notify_world_item_partner after insert on public.duo_world_items for each row execute function public.ours_notify_partner();

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.duo_notifications;
    alter publication supabase_realtime add table public.duo_message_reactions;
    alter publication supabase_realtime add table public.duo_albums;
    alter publication supabase_realtime add table public.duo_album_media;
    alter publication supabase_realtime add table public.duo_game_sessions;
    alter publication supabase_realtime add table public.duo_game_moves;
  end if;
exception when duplicate_object then null;
end $$;
