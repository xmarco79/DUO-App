-- Expand private direct messaging with video, stickers and one-time media.
alter table public.duo_direct_messages
  drop constraint if exists duo_direct_messages_message_type_check;
alter table public.duo_direct_messages
  add constraint duo_direct_messages_message_type_check
  check (message_type = any (array['text','image','file','audio','video','sticker','view_once']::text[]));

alter table public.duo_direct_messages
  add column if not exists viewed_at timestamptz,
  add column if not exists viewed_by uuid references auth.users(id) on delete set null,
  add column if not exists view_once_storage_path text;

alter table storage.buckets
  add column if not exists allowed_mime_types text[];

update storage.buckets
set allowed_mime_types = array[
  'image/jpeg','image/png','image/webp',
  'audio/mp4','audio/aac','audio/mpeg','audio/ogg','audio/webm',
  'video/mp4','video/webm','video/quicktime',
  'application/pdf','text/plain','text/csv','application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/zip'
]
where id='ours-direct-media';

create or replace function public.consume_ours_view_once(p_message_id uuid)
returns text
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_path text;
  v_sender uuid;
  v_viewed_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode='42501';
  end if;

  select m.body, m.sender_id, m.viewed_at
    into v_path, v_sender, v_viewed_at
  from public.duo_direct_messages m
  join public.duo_conversation_members cm
    on cm.conversation_id=m.conversation_id and cm.user_id=auth.uid()
  where m.id=p_message_id and m.message_type='view_once'
  for update of m;

  if not found then
    raise exception 'Message not found or access denied' using errcode='42501';
  end if;
  if v_sender=auth.uid() then
    raise exception 'Sender cannot consume own view-once media' using errcode='42501';
  end if;
  if v_viewed_at is not null then
    return null;
  end if;

  update public.duo_direct_messages
    set viewed_at=now(), viewed_by=auth.uid(), view_once_storage_path=v_path, body='[viewed]'
  where id=p_message_id;

  return v_path;
end;
$$;

alter function public.consume_ours_view_once(uuid) owner to postgres;
revoke all on function public.consume_ours_view_once(uuid) from public, anon;
grant execute on function public.consume_ours_view_once(uuid) to authenticated;

-- Private self-chat notes: visible only to the account that created them.
create table if not exists public.ours_self_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 10000),
  created_at timestamptz not null default now(),
  pinned boolean not null default false
);
alter table public.ours_self_messages enable row level security;
drop policy if exists "users manage their own self messages" on public.ours_self_messages;
create policy "users manage their own self messages"
on public.ours_self_messages for all to authenticated
using ((select auth.uid())=user_id)
with check ((select auth.uid())=user_id);
create index if not exists ours_self_messages_user_created_idx
on public.ours_self_messages(user_id, created_at desc);
grant select, insert, update, delete on public.ours_self_messages to authenticated;

-- The recipient may remove only the exact object consumed through the one-time view RPC.
drop policy if exists "recipient deletes consumed view once media" on storage.objects;
create policy "recipient deletes consumed view once media"
on storage.objects for delete to authenticated
using (
  bucket_id='ours-direct-media'
  and exists (
    select 1 from public.duo_direct_messages m
    join public.duo_conversation_members cm
      on cm.conversation_id=m.conversation_id and cm.user_id=(select auth.uid())
    where m.view_once_storage_path=storage.objects.name
      and m.viewed_by=(select auth.uid())
      and m.message_type='view_once'
  )
);
