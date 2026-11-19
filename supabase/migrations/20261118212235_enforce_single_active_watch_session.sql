-- A space may have only one active shared viewing session at a time.
-- This prevents simultaneous starts from creating competing session records.
create unique index if not exists ours_watch_one_active_per_space
  on public.ours_watch_sessions(space_id)
  where status='active';
