-- Keep the public RPC surface as SECURITY INVOKER wrappers.
-- Privileged implementations live in the non-exposed private schema and
-- validate auth.uid() before touching fixed-pair data.

create or replace function private.ensure_ours_pair_space_impl()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_naif constant uuid := 'b771a6d1-3180-4f50-b81c-66924665151a';
  v_zoi constant uuid := '01d9c50a-98fe-4998-ae79-c48fd5ac3fd3';
  v_uid uuid := auth.uid();
  v_space uuid;
  v_space_count integer;
  v_conversation uuid;
begin
  if v_uid is null or v_uid not in (v_naif,v_zoi) then
    raise exception 'Access denied' using errcode='42501';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('ours-fixed-pair-space',0));

  select count(distinct space_id)
    into v_space_count
  from public.duo_members
  where user_id in (v_naif,v_zoi);

  select space_id into v_space
  from public.duo_members
  where user_id in (v_naif,v_zoi)
  order by joined_at
  limit 1;

  if v_space_count > 1 then
    raise exception 'The two approved accounts are attached to different spaces; manual reconciliation is required';
  elsif v_space is null then
    insert into public.duo_spaces(owner_id) values(v_naif)
      on conflict(owner_id) do update set owner_id=excluded.owner_id
      returning id into v_space;
  end if;

  insert into public.duo_members(space_id,user_id,role)
    values(v_space,v_naif,'owner')
    on conflict(user_id) do nothing;
  insert into public.duo_members(space_id,user_id,role)
    values(v_space,v_zoi,'member')
    on conflict(user_id) do nothing;

  if exists (
    select 1 from public.duo_members
    where user_id in (v_naif,v_zoi) and space_id<>v_space
  ) then
    raise exception 'Account membership conflict; manual reconciliation is required';
  end if;

  select cm.conversation_id into v_conversation
  from public.duo_conversation_members cm
  where cm.user_id in (v_naif,v_zoi)
  group by cm.conversation_id
  having count(distinct cm.user_id)=2
  limit 1;

  if v_conversation is null then
    insert into public.duo_conversations default values returning id into v_conversation;
    insert into public.duo_conversation_members(conversation_id,user_id)
      values(v_conversation,v_naif),(v_conversation,v_zoi)
      on conflict(conversation_id,user_id) do nothing;
  end if;

  return jsonb_build_object('space_id',v_space,'conversation_id',v_conversation);
end;
$$;

create or replace function private.generate_ours_weekly_report_impl()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_naif constant uuid := 'b771a6d1-3180-4f50-b81c-66924665151a';
  v_zoi constant uuid := '01d9c50a-98fe-4998-ae79-c48fd5ac3fd3';
  v_uid uuid := auth.uid();
  v_space uuid;
  v_start timestamptz := date_trunc('week',now()) - interval '1 week';
  v_end timestamptz := date_trunc('week',now());
  v_naif_stats jsonb;
  v_zoi_stats jsonb;
  v_shared jsonb;
  v_report jsonb;
begin
  if v_uid is null or v_uid not in (v_naif,v_zoi) then
    raise exception 'Access denied' using errcode='42501';
  end if;

  select space_id into v_space from public.duo_members where user_id=v_uid;
  if v_space is null or not exists (
    select 1 from public.duo_members
    where space_id=v_space and user_id in (v_naif,v_zoi)
    group by space_id having count(*)=2
  ) then
    raise exception 'OURS pair space is not ready';
  end if;

  select jsonb_build_object(
    'messages',(select count(*) from public.duo_messages where space_id=v_space and sender_id=v_naif and created_at>=v_start and created_at<v_end and deleted_at is null),
    'media',(select count(*) from public.duo_messages where space_id=v_space and sender_id=v_naif and message_type in ('image','file','audio') and created_at>=v_start and created_at<v_end and deleted_at is null),
    'drawings',(select count(*) from public.ours_canvas_strokes where space_id=v_space and scope='personal' and owner_id=v_naif and created_at>=v_start and created_at<v_end),
    'watch_sessions',(select count(*) from public.ours_watch_sessions where space_id=v_space and created_by=v_naif and created_at>=v_start and created_at<v_end)
  ) into v_naif_stats;

  select jsonb_build_object(
    'messages',(select count(*) from public.duo_messages where space_id=v_space and sender_id=v_zoi and created_at>=v_start and created_at<v_end and deleted_at is null),
    'media',(select count(*) from public.duo_messages where space_id=v_space and sender_id=v_zoi and message_type in ('image','file','audio') and created_at>=v_start and created_at<v_end and deleted_at is null),
    'drawings',(select count(*) from public.ours_canvas_strokes where space_id=v_space and scope='personal' and owner_id=v_zoi and created_at>=v_start and created_at<v_end),
    'watch_sessions',(select count(*) from public.ours_watch_sessions where space_id=v_space and created_by=v_zoi and created_at>=v_start and created_at<v_end)
  ) into v_zoi_stats;

  select jsonb_build_object(
    'messages',(select count(*) from public.duo_messages where space_id=v_space and created_at>=v_start and created_at<v_end and deleted_at is null),
    'drawings',(select count(*) from public.ours_canvas_strokes where space_id=v_space and scope='shared' and created_at>=v_start and created_at<v_end),
    'watch_sessions',(select count(*) from public.ours_watch_sessions where space_id=v_space and created_at>=v_start and created_at<v_end)
  ) into v_shared;

  v_report:=jsonb_build_object(
    'week_start',v_start::date,
    'week_end',(v_end::date-1),
    'naif',v_naif_stats,
    'zoi',v_zoi_stats,
    'shared',v_shared
  );

  insert into public.ours_weekly_reports(space_id,week_start,report,generated_at)
    values(v_space,v_start::date,v_report,now())
    on conflict(space_id,week_start)
    do update set report=excluded.report,generated_at=excluded.generated_at;

  return v_report;
end;
$$;

create or replace function private.consume_ours_view_once_impl(p_message_id uuid)
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

alter function private.ensure_ours_pair_space_impl() owner to postgres;
alter function private.generate_ours_weekly_report_impl() owner to postgres;
alter function private.consume_ours_view_once_impl(uuid) owner to postgres;

revoke all on function private.ensure_ours_pair_space_impl() from public, anon;
revoke all on function private.generate_ours_weekly_report_impl() from public, anon;
revoke all on function private.consume_ours_view_once_impl(uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.ensure_ours_pair_space_impl() to authenticated;
grant execute on function private.generate_ours_weekly_report_impl() to authenticated;
grant execute on function private.consume_ours_view_once_impl(uuid) to authenticated;

create or replace function public.ensure_ours_pair_space()
returns jsonb
language sql
security invoker
set search_path = pg_catalog, public, private
as $$ select private.ensure_ours_pair_space_impl(); $$;

create or replace function public.generate_ours_weekly_report()
returns jsonb
language sql
security invoker
set search_path = pg_catalog, public, private
as $$ select private.generate_ours_weekly_report_impl(); $$;

create or replace function public.consume_ours_view_once(p_message_id uuid)
returns text
language sql
security invoker
set search_path = pg_catalog, public, private
as $$ select private.consume_ours_view_once_impl(p_message_id); $$;

revoke all on function public.ensure_ours_pair_space() from public, anon;
revoke all on function public.generate_ours_weekly_report() from public, anon;
revoke all on function public.consume_ours_view_once(uuid) from public, anon;
grant execute on function public.ensure_ours_pair_space() to authenticated;
grant execute on function public.generate_ours_weekly_report() to authenticated;
grant execute on function public.consume_ours_view_once(uuid) to authenticated;
