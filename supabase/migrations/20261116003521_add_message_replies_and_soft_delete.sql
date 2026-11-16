-- Add reply relationships and soft deletion for chat messages.
alter table public.duo_messages
  add column if not exists reply_to uuid null
    references public.duo_messages(id) on delete set null,
  add column if not exists deleted_at timestamptz null;

create index if not exists duo_messages_reply_to_idx
  on public.duo_messages(reply_to)
  where reply_to is not null;
