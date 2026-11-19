create index if not exists duo_direct_messages_viewed_by_idx
  on public.duo_direct_messages(viewed_by) where viewed_by is not null;
create index if not exists duo_sticker_favorites_user_id_idx
  on public.duo_sticker_favorites(user_id);
create index if not exists duo_stickers_created_by_idx
  on public.duo_stickers(created_by);
