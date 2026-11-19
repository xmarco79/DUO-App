-- OURS chat-media upgrade: MP4 uploads and server-enforced once/twice views.
update storage.buckets
set file_size_limit=20971520,
    allowed_mime_types=array(select distinct unnest(coalesce(allowed_mime_types,'{}'::text[])||array['video/mp4']))
where id='ours-direct-media';

create or replace function public.ours_consume_limited_media(p_message_id uuid)
returns text language plpgsql security definer
set search_path=pg_catalog,public,storage
as $$
declare v_path text; v_sender uuid; v_type text; v_viewed_at timestamptz; v_views integer; v_conversation uuid; v_url text;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 select body,sender_id,message_type,viewed_at,view_count,conversation_id
 into v_path,v_sender,v_type,v_viewed_at,v_views,v_conversation
 from public.duo_direct_messages where id=p_message_id for update;
 if not found or not exists(select 1 from public.duo_conversation_members where conversation_id=v_conversation and user_id=auth.uid()) then
  raise exception 'Media not found or access denied' using errcode='42501';
 end if;
 if v_type='view_once' then
  if v_sender=auth.uid() then v_path=coalesce((select view_once_storage_path from public.duo_direct_messages where id=p_message_id),v_path);
  elsif v_viewed_at is not null then return null;
  else update public.duo_direct_messages set viewed_at=now(),viewed_by=auth.uid(),view_once_storage_path=v_path,view_count=1,body='[viewed]' where id=p_message_id; end if;
 elsif v_type='view_twice' then
  if v_sender<>auth.uid() then
   if v_views>=2 then return null; end if;
   update public.duo_direct_messages set view_count=view_count+1,view_once_storage_path=coalesce(view_once_storage_path,body),body=case when view_count+1>=2 then '[viewed]' else body end where id=p_message_id;
  else v_path=coalesce((select view_once_storage_path from public.duo_direct_messages where id=p_message_id),v_path); end if;
 end if;
 if v_path='[viewed]' then v_path=coalesce((select view_once_storage_path from public.duo_direct_messages where id=p_message_id),v_path); end if;
 if v_path is null or v_path='[viewed]' then return null; end if;
 select signedURL into v_url from storage.create_signed_url(v_path,15); return v_url;
end $$;
alter function public.ours_consume_limited_media(uuid) owner to postgres;
revoke all on function public.ours_consume_limited_media(uuid) from public,anon;
grant execute on function public.ours_consume_limited_media(uuid) to authenticated;

drop policy if exists "direct conversation members read media" on storage.objects;
create policy "direct conversation members read media" on storage.objects for select to authenticated
using (bucket_id='ours-direct-media'
 and exists(select 1 from public.duo_conversation_members cm where cm.conversation_id=(storage.foldername(name))[1]::uuid and cm.user_id=(select auth.uid()))
 and not exists(select 1 from public.duo_direct_messages dm where (dm.body=name or dm.view_once_storage_path=name) and dm.message_type in ('view_once','view_twice') and dm.sender_id<>(select auth.uid())));
