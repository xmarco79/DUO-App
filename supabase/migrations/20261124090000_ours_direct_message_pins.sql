create table if not exists public.ours_direct_message_pins (
  message_id uuid not null references public.duo_direct_messages(id) on delete cascade,
  conversation_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create index if not exists ours_direct_message_pins_user_conversation_idx
  on public.ours_direct_message_pins(user_id, conversation_id, created_at desc);

alter table public.ours_direct_message_pins enable row level security;

drop policy if exists ours_direct_message_pins_select on public.ours_direct_message_pins;
create policy ours_direct_message_pins_select
on public.ours_direct_message_pins for select to authenticated
using (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.duo_conversation_members cm
    where cm.conversation_id = ours_direct_message_pins.conversation_id
      and cm.user_id = (select auth.uid())
  )
);

drop policy if exists ours_direct_message_pins_insert on public.ours_direct_message_pins;
create policy ours_direct_message_pins_insert
on public.ours_direct_message_pins for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.duo_conversation_members cm
    where cm.conversation_id = ours_direct_message_pins.conversation_id
      and cm.user_id = (select auth.uid())
  )
  and exists (
    select 1 from public.duo_direct_messages m
    where m.id = ours_direct_message_pins.message_id
      and m.conversation_id = ours_direct_message_pins.conversation_id
  )
);

drop policy if exists ours_direct_message_pins_delete on public.ours_direct_message_pins;
create policy ours_direct_message_pins_delete
on public.ours_direct_message_pins for delete to authenticated
using (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.duo_conversation_members cm
    where cm.conversation_id = ours_direct_message_pins.conversation_id
      and cm.user_id = (select auth.uid())
  )
);

grant select, insert, delete on public.ours_direct_message_pins to authenticated;
