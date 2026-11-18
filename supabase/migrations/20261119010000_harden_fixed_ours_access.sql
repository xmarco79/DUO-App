-- Lock the backend to the fixed OURS pair and retire the old invitation,
-- friend-discovery, and game entry points without deleting historical data.

revoke all on function public.create_duo_space() from public, anon, authenticated;
revoke all on function public.create_duo_invite() from public, anon, authenticated;
revoke all on function public.redeem_duo_invite(text) from public, anon, authenticated;
revoke all on function public.search_ours_people(text) from public, anon, authenticated;
revoke all on function public.respond_to_duo_friend_request(uuid, boolean) from public, anon, authenticated;
revoke all on function public.ours_make_ttt_move(uuid, integer) from public, anon, authenticated;

revoke all on table public.duo_invites from anon, authenticated;
revoke all on table public.duo_friend_requests from anon, authenticated;
revoke all on table public.duo_friendships from anon, authenticated;
revoke all on table public.duo_game_sessions from anon, authenticated;
revoke all on table public.duo_game_moves from anon, authenticated;

drop policy if exists "users can send friend requests as themselves"
  on public.duo_friend_requests;
drop policy if exists "users can view their own friend requests"
  on public.duo_friend_requests;
drop policy if exists "duo members can read each other's profiles"
  on public.duo_profiles;
drop policy if exists "Space members create game sessions"
  on public.duo_game_sessions;
drop policy if exists "Space members read game sessions"
  on public.duo_game_sessions;
drop policy if exists "Players add own game moves"
  on public.duo_game_moves;
drop policy if exists "Space members read game moves"
  on public.duo_game_moves;
