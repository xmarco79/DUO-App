-- Make the fixed-pair bootstrap safe to call repeatedly.
-- The member-limit trigger runs before ON CONFLICT handling, so only insert
-- missing memberships; this keeps app startup and retry paths idempotent.

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

  if not exists (select 1 from public.duo_members where user_id=v_naif) then
    insert into public.duo_members(space_id,user_id,role)
      values(v_space,v_naif,'owner');
  end if;

  if not exists (select 1 from public.duo_members where user_id=v_zoi) then
    insert into public.duo_members(space_id,user_id,role)
      values(v_space,v_zoi,'member');
  end if;

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

alter function private.ensure_ours_pair_space_impl() owner to postgres;
revoke all on function private.ensure_ours_pair_space_impl() from public, anon;
grant execute on function private.ensure_ours_pair_space_impl() to authenticated;
