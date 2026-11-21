alter table public.duo_direct_messages
  add column if not exists file_name text,
  add column if not exists file_size bigint,
  add column if not exists mime_type text;

create index if not exists duo_direct_messages_file_type_idx
  on public.duo_direct_messages(conversation_id, message_type, created_at desc)
  where message_type in ('file','audio','video','image','sticker');
