-- OURS direct chat: reply metadata, per-user hides, sender deletion and temporary media views.
alter table public.duo_direct_messages
  add column if not exists reply_to uuid references public.duo_direct_messages(id) on delete set null,
  add column if not exists max_views smallint not null default 1,
  add column if not exists view_count smallint not null default 0;
alter table public.duo_direct_messages drop constraint if exists duo_direct_messages_message_type_check;
alter table public.duo_direct_messages add constraint duo_direct_messages_message_type_check
  check (message_type = any (array['text','image','file','audio','video','sticker','view_once','view_twice']::text[]));
alter table public.duo_direct_messages drop constraint if exists duo_direct_messages_view_count_check;
alter table public.duo_direct_messages add constraint duo_direct_messages_view_count_check
  check (max_views between 1 and 2 and view_count between 0 and max_views);

drop policy if exists "OURS sender deletes own direct messages" on public.duo_direct_messages;
create policy "OURS sender deletes own direct messages" on public.duo_direct_messages
for delete to authenticated using (
 sender_id=(select auth.uid()) and exists(
  select 1 from public.duo_conversation_members cm
  where cm.conversation_id=duo_direct_messages.conversation_id and cm.user_id=(select auth.uid())
 )
);
grant delete on public.duo_direct_messages to authenticated;

create table if not exists public.ours_direct_message_hides(
 message_id uuid not null references public.duo_direct_messages(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 hidden_at timestamptz not null default now(),
 primary key(message_id,user_id)
);
alter table public.ours_direct_message_hides enable row level security;
drop policy if exists "Users manage their own hidden direct messages" on public.ours_direct_message_hides;
create policy "Users manage their own hidden direct messages" on public.ours_direct_message_hides
for all to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
grant select,insert,delete on public.ours_direct_message_hides to authenticated;

create or replace function private.consume_ours_temporary_media_impl(p_message_id uuid)
returns text language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_path text; v_sender uuid; v_count smallint; v_max smallint;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 select m.body,m.sender_id,m.view_count,m.max_views into v_path,v_sender,v_count,v_max
 from public.duo_direct_messages m join public.duo_conversation_members cm
 on cm.conversation_id=m.conversation_id and cm.user_id=auth.uid()
 where m.id=p_message_id and m.message_type in ('view_once','view_twice') for update of m;
 if not found or v_sender=auth.uid() or v_count>=v_max then return null; end if;
 update public.duo_direct_messages set
  view_once_storage_path=case when view_count+1>=max_views then v_path else view_once_storage_path end,
  view_count=view_count+1,
  viewed_at=case when view_count+1>=max_views then now() else viewed_at end,
  viewed_by=case when view_count+1>=max_views then auth.uid() else viewed_by end,
  body=case when view_count+1>=max_views then '[viewed]' else body end
 where id=p_message_id;
 return v_path;
end; $$;
alter function private.consume_ours_temporary_media_impl(uuid) owner to postgres;
revoke all on function private.consume_ours_temporary_media_impl(uuid) from public,anon;
grant usage on schema private to authenticated;
grant execute on function private.consume_ours_temporary_media_impl(uuid) to authenticated;
create or replace function public.consume_ours_temporary_media(p_message_id uuid)
returns text language sql security invoker set search_path=pg_catalog,public,private
as $$ select private.consume_ours_temporary_media_impl(p_message_id); $$;
alter function public.consume_ours_temporary_media(uuid) owner to postgres;
revoke all on function public.consume_ours_temporary_media(uuid) from public,anon;
grant execute on function public.consume_ours_temporary_media(uuid) to authenticated;

drop policy if exists "recipient deletes consumed view once media" on storage.objects;
create policy "recipient deletes consumed temporary media" on storage.objects for delete to authenticated using(
 bucket_id='ours-direct-media' and exists(
  select 1 from public.duo_direct_messages m
  where m.view_once_storage_path=storage.objects.name and m.viewed_by=(select auth.uid())
  and m.message_type in ('view_once','view_twice') and m.body='[viewed]'
 )
);
