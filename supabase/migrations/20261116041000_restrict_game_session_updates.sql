drop policy if exists "Space members update game sessions" on public.duo_game_sessions;
revoke update on public.duo_game_sessions from authenticated;
