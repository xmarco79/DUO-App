alter table public.ours_self_messages
  add column if not exists message_type text not null default 'text'
    check (message_type in ('text','image','file','audio','sticker')),
  add column if not exists file_name text,
  add column if not exists file_size bigint,
  add column if not exists mime_type text,
  add column if not exists reply_to uuid references public.ours_self_messages(id) on delete set null;

create index if not exists ours_self_messages_reply_to_idx
  on public.ours_self_messages(reply_to) where reply_to is not null;

drop policy if exists ours_self_media_read_own on storage.objects;
create policy ours_self_media_read_own on storage.objects
for select to authenticated using (
  bucket_id = 'ours-direct-media'
  and (storage.foldername(name))[1] = 'self'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);

drop policy if exists ours_self_media_insert_own on storage.objects;
create policy ours_self_media_insert_own on storage.objects
for insert to authenticated with check (
  bucket_id = 'ours-direct-media'
  and (storage.foldername(name))[1] = 'self'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);

drop policy if exists ours_self_media_delete_own on storage.objects;
create policy ours_self_media_delete_own on storage.objects
for delete to authenticated using (
  bucket_id = 'ours-direct-media'
  and (storage.foldername(name))[1] = 'self'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'ours_self_messages'
  ) then
    alter publication supabase_realtime add table public.ours_self_messages;
  end if;
end
$$;
