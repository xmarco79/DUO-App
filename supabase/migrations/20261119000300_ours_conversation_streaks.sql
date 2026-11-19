-- Daily OURS conversation streaks, advanced by messages sent in the private chat.
create table if not exists public.duo_direct_streaks(
 conversation_id uuid primary key references public.duo_conversations(id) on delete cascade,
 current_days integer not null default 0 check(current_days>=0),
 longest_days integer not null default 0 check(longest_days>=current_days),
 last_activity_date date,
 updated_at timestamptz not null default now()
);
alter table public.duo_direct_streaks enable row level security;
drop policy if exists "conversation members read streak" on public.duo_direct_streaks;
create policy "conversation members read streak" on public.duo_direct_streaks for select to authenticated
using(exists(select 1 from public.duo_conversation_members cm where cm.conversation_id=duo_direct_streaks.conversation_id and cm.user_id=(select auth.uid())));

create or replace function public.ours_update_direct_streak()
returns trigger language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_day date:=timezone('Asia/Riyadh',now())::date;
begin
 if not exists(select 1 from public.duo_conversation_members cm where cm.conversation_id=new.conversation_id and cm.user_id=new.sender_id) then return new; end if;
 insert into public.duo_direct_streaks(conversation_id,current_days,longest_days,last_activity_date)
 values(new.conversation_id,1,1,v_day)
 on conflict(conversation_id) do update set
 current_days=case
  when duo_direct_streaks.last_activity_date=v_day then duo_direct_streaks.current_days
  when duo_direct_streaks.last_activity_date=v_day-1 then duo_direct_streaks.current_days+1
  else 1 end,
 longest_days=greatest(duo_direct_streaks.longest_days,case
  when duo_direct_streaks.last_activity_date=v_day then duo_direct_streaks.current_days
  when duo_direct_streaks.last_activity_date=v_day-1 then duo_direct_streaks.current_days+1
  else 1 end),
 last_activity_date=v_day,updated_at=now();
 return new;
end $$;
alter function public.ours_update_direct_streak() owner to postgres;
revoke all on function public.ours_update_direct_streak() from public,anon,authenticated;
drop trigger if exists ours_direct_streak_after_message on public.duo_direct_messages;
create trigger ours_direct_streak_after_message after insert on public.duo_direct_messages
for each row execute function public.ours_update_direct_streak();
