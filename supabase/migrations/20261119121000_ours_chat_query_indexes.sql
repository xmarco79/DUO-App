create index if not exists duo_direct_messages_reply_to_idx
  on public.duo_direct_messages(reply_to) where reply_to is not null;
create index if not exists ours_direct_message_hides_user_hidden_idx
  on public.ours_direct_message_hides(user_id,hidden_at desc);