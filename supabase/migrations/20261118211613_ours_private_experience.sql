-- Permanent two-account OURS space and new creative/reporting features.
-- Applied to the OURS Supabase project.

create table if not exists public.ours_canvas_strokes (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  owner_id uuid references auth.users(id) on delete cascade,
  scope text not null check (scope in ('personal','shared')),
  points jsonb not null check (jsonb_typeof(points)='array' and jsonb_array_length(points) between 2 and 20000),
  color bigint not null default 3114454485,
  stroke_width numeric(5,2) not null default 4 check (stroke_width between 0.5 and 40),
  created_at timestamptz not null default now(),
  constraint ours_canvas_scope_owner_check check (
    (scope='personal' and owner_id is not null) or (scope='shared' and owner_id is null)
  )
);
create index if not exists ours_canvas_space_scope_created_idx
  on public.ours_canvas_strokes(space_id,scope,created_at desc);
create index if not exists ours_canvas_owner_created_idx
  on public.ours_canvas_strokes(owner_id,created_at desc) where owner_id is not null;
alter table public.ours_canvas_strokes enable row level security;
drop policy if exists "OURS members read canvas strokes" on public.ours_canvas_strokes;
create policy "OURS members read canvas strokes" on public.ours_canvas_strokes
  for select to authenticated
  using (
    exists (select 1 from public.duo_members m where m.space_id=ours_canvas_strokes.space_id and m.user_id=(select auth.uid()))
    and (scope='shared' or owner_id=(select auth.uid()))
  );
drop policy if exists "OURS members create canvas strokes" on public.ours_canvas_strokes;
create policy "OURS members create canvas strokes" on public.ours_canvas_strokes
  for insert to authenticated
  with check (
    exists (select 1 from public.duo_members m where m.space_id=ours_canvas_strokes.space_id and m.user_id=(select auth.uid()))
    and ((scope='personal' and owner_id=(select auth.uid())) or (scope='shared' and owner_id is null))
  );
drop policy if exists "OURS owners delete own canvas strokes" on public.ours_canvas_strokes;
create policy "OURS owners delete own canvas strokes" on public.ours_canvas_strokes
  for delete to authenticated
  using (
    exists (select 1 from public.duo_members m where m.space_id=ours_canvas_strokes.space_id and m.user_id=(select auth.uid()))
    and ((scope='personal' and owner_id=(select auth.uid())) or scope='shared')
  );
grant select,insert,delete on public.ours_canvas_strokes to authenticated;

create table if not exists public.ours_watch_sessions (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  source_url text not null check (source_url ~ '^https?://'),
  status text not null default 'active' check (status in ('active','ended')),
  position_ms bigint not null default 0 check (position_ms >= 0),
  is_playing boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists ours_watch_active_idx on public.ours_watch_sessions(space_id,updated_at desc) where status='active';
alter table public.ours_watch_sessions enable row level security;
drop policy if exists "OURS members manage watch sessions" on public.ours_watch_sessions;
create policy "OURS members manage watch sessions" on public.ours_watch_sessions
  for all to authenticated
  using (exists (select 1 from public.duo_members m where m.space_id=ours_watch_sessions.space_id and m.user_id=(select auth.uid())))
  with check (exists (select 1 from public.duo_members m where m.space_id=ours_watch_sessions.space_id and m.user_id=(select auth.uid())));
grant select,insert,update,delete on public.ours_watch_sessions to authenticated;


alter publication supabase_realtime add table public.ours_canvas_strokes;
alter publication supabase_realtime add table public.ours_watch_sessions;

create table if not exists public.ours_weekly_reports (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  week_start date not null,
  report jsonb not null,
  generated_at timestamptz not null default now(),
  unique(space_id,week_start)
);
alter table public.ours_weekly_reports enable row level security;
drop policy if exists "OURS members read weekly reports" on public.ours_weekly_reports;
create policy "OURS members read weekly reports" on public.ours_weekly_reports
  for select to authenticated
  using (exists (select 1 from public.duo_members m where m.space_id=ours_weekly_reports.space_id and m.user_id=(select auth.uid())));
grant select on public.ours_weekly_reports to authenticated;

create or replace function public.ensure_ours_pair_space()
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
  select space_id into v_space from public.duo_members where user_id in (v_naif,v_zoi) order by joined_at limit 1;

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
alter function public.ensure_ours_pair_space() owner to postgres;
revoke all on function public.ensure_ours_pair_space() from public,anon;
grant execute on function public.ensure_ours_pair_space() to authenticated;

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
  v_conversation uuid;
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
    select 1 from public.duo_members where space_id=v_space and user_id in (v_naif,v_zoi) group by space_id having count(*)=2
  ) then raise exception 'OURS pair space is not ready'; end if;

  select cm.conversation_id into v_conversation
  from public.duo_conversation_members cm
  where cm.user_id in (v_naif,v_zoi)
  group by cm.conversation_id having count(distinct cm.user_id)=2 limit 1;

  select jsonb_build_object(
    'messages',(select count(*) from public.duo_direct_messages where conversation_id=v_conversation and sender_id=v_naif and created_at>=v_start and created_at<v_end),
    'media',(select count(*) from public.duo_direct_messages where conversation_id=v_conversation and sender_id=v_naif and message_type in ('image','video','audio','file','view_once') and created_at>=v_start and created_at<v_end),
    'drawings',(select count(*) from public.ours_canvas_strokes where space_id=v_space and scope='personal' and owner_id=v_naif and created_at>=v_start and created_at<v_end),
    'watch_sessions',(select count(*) from public.ours_watch_sessions where space_id=v_space and created_by=v_naif and created_at>=v_start and created_at<v_end)
  ) into v_naif_stats;
  select jsonb_build_object(
    'messages',(select count(*) from public.duo_direct_messages where conversation_id=v_conversation and sender_id=v_zoi and created_at>=v_start and created_at<v_end),
    'media',(select count(*) from public.duo_direct_messages where conversation_id=v_conversation and sender_id=v_zoi and message_type in ('image','video','audio','file','view_once') and created_at>=v_start and created_at<v_end),
    'drawings',(select count(*) from public.ours_canvas_strokes where space_id=v_space and scope='personal' and owner_id=v_zoi and created_at>=v_start and created_at<v_end),
    'watch_sessions',(select count(*) from public.ours_watch_sessions where space_id=v_space and created_by=v_zoi and created_at>=v_start and created_at<v_end)
  ) into v_zoi_stats;
  select jsonb_build_object(
    'messages',(select count(*) from public.duo_messages where space_id=v_space and created_at>=v_start and created_at<v_end),
    'drawings',(select count(*) from public.ours_canvas_strokes where space_id=v_space and scope='shared' and created_at>=v_start and created_at<v_end),
    'watch_sessions',(select count(*) from public.ours_watch_sessions where space_id=v_space and created_at>=v_start and created_at<v_end)
  ) into v_shared;

  v_report:=jsonb_build_object('week_start',v_start::date,'week_end',(v_end::date-1),'naif',v_naif_stats,'zoi',v_zoi_stats,'shared',v_shared);
  insert into public.ours_weekly_reports(space_id,week_start,report,generated_at)
    values(v_space,v_start::date,v_report,now())
    on conflict(space_id,week_start) do update set report=excluded.report,generated_at=excluded.generated_at;
  return v_report;
end;
$$;
alter function public.generate_ours_weekly_report() owner to postgres;
revoke all on function public.generate_ours_weekly_report() from public,anon;
grant execute on function public.generate_ours_weekly_report() to authenticated;
