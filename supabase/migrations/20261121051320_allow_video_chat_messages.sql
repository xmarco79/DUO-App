-- Add video message support to the legacy shared OURS chat.
-- Existing message types and rows are preserved.
ALTER TABLE public.duo_messages
  DROP CONSTRAINT IF EXISTS duo_messages_message_type_check;

ALTER TABLE public.duo_messages
  ADD CONSTRAINT duo_messages_message_type_check
  CHECK (message_type = ANY (ARRAY['text','image','file','audio','video','system','sticker']::text[]));
