alter table public.duo_direct_messages
  add column if not exists edited_at timestamptz;
