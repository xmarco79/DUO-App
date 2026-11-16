create or replace function public.ours_make_ttt_move(p_session_id uuid, p_cell integer)
returns public.duo_game_sessions language plpgsql security definer set search_path = ''
as $$
declare
  v_game public.duo_game_sessions; v_board jsonb; v_mark text; v_winner text; v_next_user uuid; v_moves integer;
  v_user_id uuid := auth.uid(); v_cells text[]; v_line integer[];
  v_lines integer[][] := array[array[0,1,2],array[3,4,5],array[6,7,8],array[0,3,6],array[1,4,7],array[2,5,8],array[0,4,8],array[2,4,6]];
begin
  if v_user_id is null then raise exception 'يجب تسجيل الدخول'; end if;
  if p_cell < 0 or p_cell > 8 then raise exception 'مربع غير صالح'; end if;
  select * into v_game from public.duo_game_sessions where id=p_session_id and game_type='tic_tac_toe' for update;
  if not found then raise exception 'اللعبة غير موجودة'; end if;
  if v_game.status not in ('waiting','active') then raise exception 'انتهت اللعبة'; end if;
  if v_game.current_turn_user_id <> v_user_id then raise exception 'ليس دورك الآن'; end if;
  if not exists(select 1 from public.duo_members m where m.space_id=v_game.space_id and m.user_id=v_user_id) then raise exception 'ليس لديك صلاحية لهذه اللعبة'; end if;
  v_board := coalesce(v_game.state->'board','["","","","","","","","",""]'::jsonb);
  v_cells := array(select coalesce(value #>> '{}','') from jsonb_array_elements(v_board) with ordinality order by ordinality);
  if array_length(v_cells,1) <> 9 then raise exception 'حالة اللوحة غير صالحة'; end if;
  if v_cells[p_cell+1] <> '' then raise exception 'هذا المربع محجوز'; end if;
  v_mark := case when v_user_id=v_game.created_by then 'X' else 'O' end;
  v_cells[p_cell+1] := v_mark; v_board := to_jsonb(v_cells); v_winner := null;
  foreach v_line slice 1 in array v_lines loop
    if v_cells[v_line[1]+1] <> '' and v_cells[v_line[1]+1]=v_cells[v_line[2]+1] and v_cells[v_line[2]+1]=v_cells[v_line[3]+1] then
      v_winner := v_cells[v_line[1]+1]; exit;
    end if;
  end loop;
  v_moves := coalesce(v_game.turn_number,0)+1;
  insert into public.duo_game_moves(session_id,space_id,player_id,turn_number,move)
  values(v_game.id,v_game.space_id,v_user_id,v_moves,jsonb_build_object('cell',p_cell,'mark',v_mark));
  v_next_user := case when v_user_id=v_game.created_by
    then (select m.user_id from public.duo_members m where m.space_id=v_game.space_id and m.user_id<>v_user_id limit 1)
    else v_game.created_by end;
  update public.duo_game_sessions
  set state=jsonb_build_object('board',v_board,'winner_mark',v_winner),
      turn_number=v_moves,
      current_turn_user_id=case when v_winner is not null or v_moves>=9 then null else v_next_user end,
      winner_user_id=case when v_winner='X' then v_game.created_by when v_winner='O' then v_user_id else null end,
      status=case when v_winner is not null or v_moves>=9 then 'completed' else 'active' end,
      updated_at=now()
  where id=v_game.id returning * into v_game;
  return v_game;
end;
$$;
revoke all on function public.ours_make_ttt_move(uuid,integer) from public,anon;
grant execute on function public.ours_make_ttt_move(uuid,integer) to authenticated;
