-- OURS chat-media refinements: private MP4 uploads and view-limited media metadata.
alter table public.duo_direct_messages
  add column if not exists media_view_mode text not null default 'normal',
  add column if not exists media_views_used integer not null default 0;
alter table public.duo_direct_messages
  drop constraint if exists duo_direct_messages_media_view_mode_check;
alter table public.duo_direct_messages
  add constraint duo_direct_messages_media_view_mode_check
  check (media_view_mode in ('normal','once','twice') and media_views_used >= 0);

update storage.buckets
set file_size_limit=20971520,
    allowed_mime_types=array_append(coalesce(allowed_mime_types,'{}'::text[]),'video/mp4')
where id='ours-direct-media';

drop policy if exists "direct conversation members read media" on storage.objects;
create policy "direct conversation members read media" on storage.objects for select to authenticated
using (
 bucket_id='ours-direct-media'
 and exists (select 1 from public.duo_conversation_members m
   where m.conversation_id=(storage.foldername(name))[1]::uuid and m.user_id=(select auth.uid()))
 and not exists (select 1 from public.duo_direct_messages dm
   where dm.body=name and dm.media_view_mode in ('once','twice') and dm.sender_id<>(select auth.uid())
 );

create or replace function public.ours_consume_direct_media(p_message_id uuid)
returns text
language plpgsql
security definer
set search_path = pg_catalog, public, storage
as $$
declare
  v_path text;
  v_sender uuid;
  v_mode text;
  v_used integer;
  v_url text;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select body, sender_id, media_view_mode, media_views_used
    into v_path, v_sender, v_mode, v_used
  from public.duo_direct_messages
  where id=p_message_id and message_type in ('image','file');
  if v_path is null then raise exception 'Media not found'; end if;
  if not exists(select 1 from public.duo_conversation_members m
    where m.conversation_id=(select conversation_id from public.duo_direct_messages where id=p_message_id)
      and m.user_id=auth.uid()) then raise exception 'Not a conversation member' using errcode='42501'; end if;
  if v_mode='normal' or v_sender=auth.uid() then
    select signedURL into v_url from storage.create_signed_url(v_path,60);
    return v_url;
  end if;
  update public.duo_direct_messages
  set media_views_used=media_views_used+1
  where id=p_message_id and media_view_mode in ('once','twice')
    and media_views_used < case media_view_mode when 'once' then 1 when 'twice' then 2 else 0 end
  returning body into v_path;
  if v_path is null then raise exception 'View limit reached'; end if;
  select signedURL into v_url from storage.create_signed_url(v_path,15);
  return v_url;
end;
$$;
alter function public.ours_consume_direct_media(uuid) owner to postgres;
revoke all on function public.ours_consume_direct_media(uuid) from public, anon;
grant execute on function public.ours_consume_direct_media(uuid) to authenticated;
