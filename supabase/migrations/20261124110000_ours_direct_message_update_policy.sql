drop policy if exists "OURS senders update their own direct messages" on public.duo_direct_messages;
create policy "OURS senders update their own direct messages"
on public.duo_direct_messages
for update to authenticated
using (
  sender_id = (select auth.uid())
  and exists (
    select 1 from public.duo_conversation_members cm
    where cm.conversation_id = duo_direct_messages.conversation_id
      and cm.user_id = (select auth.uid())
  )
)
with check (
  sender_id = (select auth.uid())
  and exists (
    select 1 from public.duo_conversation_members cm
    where cm.conversation_id = duo_direct_messages.conversation_id
      and cm.user_id = (select auth.uid())
  )
);