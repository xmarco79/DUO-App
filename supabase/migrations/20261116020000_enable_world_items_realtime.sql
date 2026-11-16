-- Enable live synchronization for the private shared-world feed.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'duo_world_items'
  ) then
    alter publication supabase_realtime add table public.duo_world_items;
  end if;
end
$$;
