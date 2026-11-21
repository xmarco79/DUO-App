-- OURS is intentionally a private space for exactly two people.
-- Serialize membership inserts on the parent space row so concurrent joins
-- cannot overfill the same space.
create or replace function private.enforce_duo_space_member_limit()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_member_count integer;
begin
  perform 1
  from public.duo_spaces
  where id = new.space_id
  for update;

  if not found then
    raise exception 'DUO space does not exist';
  end if;

  select count(*)
    into v_member_count
  from public.duo_members
  where space_id = new.space_id;

  if v_member_count >= 2 then
    raise exception 'OURS spaces are limited to two accounts'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke all on function private.enforce_duo_space_member_limit() from public, anon, authenticated;

drop trigger if exists enforce_duo_space_member_limit on public.duo_members;
create trigger enforce_duo_space_member_limit
before insert on public.duo_members
for each row
execute function private.enforce_duo_space_member_limit();

-- Disable the former open people-discovery and friend-request path.
drop policy if exists "users can send friend requests as themselves"
  on public.duo_friend_requests;

revoke all on function public.search_ours_people(text) from public, anon, authenticated;
revoke all on function public.respond_to_duo_friend_request(uuid, boolean)
  from public, anon, authenticated;
