alter table public.duo_profiles
  add column if not exists last_seen_at timestamptz;

create or replace function private.mark_ours_direct_messages_read_impl(p_conversation_id uuid)
returns integer language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare v_updated integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.duo_conversation_members cm
    where cm.conversation_id = p_conversation_id and cm.user_id = auth.uid()
  ) then
    raise exception 'Conversation access denied' using errcode = '42501';
  end if;
  update public.duo_direct_messages
     set read_at = now()
   where conversation_id = p_conversation_id
     and sender_id <> auth.uid()
     and read_at is null;
  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;
alter function private.mark_ours_direct_messages_read_impl(uuid) owner to postgres;
revoke all on function private.mark_ours_direct_messages_read_impl(uuid) from public, anon, authenticated;

create or replace function public.mark_ours_direct_messages_read(p_conversation_id uuid)
returns integer language sql security definer
set search_path = pg_catalog, public, private
as $$ select private.mark_ours_direct_messages_read_impl(p_conversation_id); $$;
alter function public.mark_ours_direct_messages_read(uuid) owner to postgres;
revoke all on function public.mark_ours_direct_messages_read(uuid) from public, anon;
grant execute on function public.mark_ours_direct_messages_read(uuid) to authenticated;

create or replace function private.touch_ours_presence_impl()
returns timestamptz language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare v_seen timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  update public.duo_profiles set last_seen_at = now()
   where user_id = auth.uid()
   returning last_seen_at into v_seen;
  return v_seen;
end;
$$;
alter function private.touch_ours_presence_impl() owner to postgres;
revoke all on function private.touch_ours_presence_impl() from public, anon, authenticated;

create or replace function public.touch_ours_presence()
returns timestamptz language sql security definer
set search_path = pg_catalog, public, private
as $$ select private.touch_ours_presence_impl(); $$;
alter function public.touch_ours_presence() owner to postgres;
revoke all on function public.touch_ours_presence() from public, anon;
grant execute on function public.touch_ours_presence() to authenticated;

create or replace function private.consume_ours_temporary_media_impl(p_message_id uuid)
returns text language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare v_path text; v_count smallint; v_max smallint;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  select m.body, m.view_count, m.max_views
    into v_path, v_count, v_max
  from public.duo_direct_messages m
  join public.duo_conversation_members cm
    on cm.conversation_id = m.conversation_id and cm.user_id = auth.uid()
  where m.id = p_message_id and m.message_type in ('view_once', 'view_twice')
  for update of m;
  if not found or v_count >= v_max or v_path is null or v_path = '[viewed]' then
    return null;
  end if;
  update public.duo_direct_messages
     set view_count = view_count + 1,
         view_once_storage_path = case when view_count + 1 >= max_views then v_path else view_once_storage_path end,
         viewed_at = case when view_count + 1 >= max_views then now() else viewed_at end,
         viewed_by = case when view_count + 1 >= max_views then auth.uid() else viewed_by end,
         body = case when view_count + 1 >= max_views then '[viewed]' else body end
   where id = p_message_id;
  return v_path;
end;
$$;
alter function private.consume_ours_temporary_media_impl(uuid) owner to postgres;
revoke all on function private.consume_ours_temporary_media_impl(uuid) from public, anon, authenticated;

drop policy if exists ours_direct_members_read_live_channel on realtime.messages;
create policy ours_direct_members_read_live_channel on realtime.messages
for select to authenticated using (
  extension in ('presence', 'broadcast')
  and realtime.topic() like 'ours-direct:%:live'
  and exists (
    select 1 from public.duo_conversation_members cm
    where cm.conversation_id = split_part(realtime.topic(), ':', 2)::uuid
      and cm.user_id = (select auth.uid())
  )
);
drop policy if exists ours_direct_members_send_live_channel on realtime.messages;
create policy ours_direct_members_send_live_channel on realtime.messages
for insert to authenticated with check (
  extension in ('presence', 'broadcast')
  and realtime.topic() like 'ours-direct:%:live'
  and exists (
    select 1 from public.duo_conversation_members cm
    where cm.conversation_id = split_part(realtime.topic(), ':', 2)::uuid
      and cm.user_id = (select auth.uid())
  )
);
