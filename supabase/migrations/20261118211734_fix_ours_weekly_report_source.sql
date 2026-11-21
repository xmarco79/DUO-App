-- Report statistics must follow the actual chat used by the OURS home screen.
-- ChatPage stores shared messages in duo_messages, not duo_direct_messages.
create or replace function public.generate_ours_weekly_report()
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

alter function public.generate_ours_weekly_report() owner to postgres;
revoke all on function public.generate_ours_weekly_report() from public,anon;
grant execute on function public.generate_ours_weekly_report() to authenticated;
