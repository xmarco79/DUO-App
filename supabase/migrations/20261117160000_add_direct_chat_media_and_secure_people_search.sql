-- Secure prefix search and private media storage for one-to-one conversations.
create or replace function public.search_ours_people(p_query text)
returns table (user_id uuid, username text, display_name text, avatar_path text)
language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare v_query text := lower(btrim(coalesce(p_query, '')));
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if length(v_query) < 3 or length(v_query) > 20
     or v_query !~ '^[a-z0-9_]{3,20}$' then return; end if;
  return query
    select p.user_id, p.username, p.display_name, p.avatar_path
    from public.duo_profiles p
    where p.user_id <> auth.uid() and p.username like v_query || '%'
    order by p.username limit 15;
end;
$$;
alter function public.search_ours_people(text) owner to postgres;
revoke all on function public.search_ours_people(text) from public, anon;
grant execute on function public.search_ours_people(text) to authenticated;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('ours-direct-media','ours-direct-media',false,20971520,
array['image/jpeg','image/png','image/webp','audio/mp4','audio/aac','audio/mpeg','audio/ogg','audio/webm','application/pdf','text/plain','text/csv','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation','application/zip'])
on conflict (id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "direct conversation members read media" on storage.objects;
create policy "direct conversation members read media" on storage.objects for select to authenticated
using (bucket_id='ours-direct-media' and exists (
  select 1 from public.duo_conversation_members m
  where m.conversation_id=(storage.foldername(name))[1]::uuid and m.user_id=(select auth.uid())
));
drop policy if exists "direct conversation members upload own media" on storage.objects;
create policy "direct conversation members upload own media" on storage.objects for insert to authenticated
with check (bucket_id='ours-direct-media' and (storage.foldername(name))[2]=(select auth.uid())::text and exists (
  select 1 from public.duo_conversation_members m
  where m.conversation_id=(storage.foldername(name))[1]::uuid and m.user_id=(select auth.uid())
));
drop policy if exists "users delete own direct media" on storage.objects;
create policy "users delete own direct media" on storage.objects for delete to authenticated
using (bucket_id='ours-direct-media' and (storage.foldername(name))[2]=(select auth.uid())::text and exists (
  select 1 from public.duo_conversation_members m
  where m.conversation_id=(storage.foldername(name))[1]::uuid and m.user_id=(select auth.uid())
));
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime')
     and not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='duo_direct_messages') then
    alter publication supabase_realtime add table public.duo_direct_messages;
  end if;
end $$;
