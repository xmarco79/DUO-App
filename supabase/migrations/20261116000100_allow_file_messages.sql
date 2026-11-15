-- Keep message types aligned with the Flutter client.
-- File paths are stored in duo_messages.body; the file bytes remain in private Storage.
alter table public.duo_messages
  drop constraint if exists duo_messages_message_type_check;

alter table public.duo_messages
  add constraint duo_messages_message_type_check
  check (
    message_type = any (
      array['text'::text, 'image'::text, 'file'::text, 'audio'::text, 'system'::text]
    )
  );
