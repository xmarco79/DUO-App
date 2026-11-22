drop policy if exists "OURS members create canvas strokes" on public.ours_canvas_strokes;
create policy "OURS members create canvas strokes"
on public.ours_canvas_strokes
for insert
to authenticated
with check (
  exists (
    select 1 from public.duo_members m
    where m.space_id=ours_canvas_strokes.space_id
      and m.user_id=(select auth.uid())
  )
  and owner_id=(select auth.uid())
  and scope in ('personal','shared')
);

drop policy if exists "OURS owners delete own canvas strokes" on public.ours_canvas_strokes;
create policy "OURS members delete own canvas strokes"
on public.ours_canvas_strokes
for delete
to authenticated
using (
  exists (
    select 1 from public.duo_members m
    where m.space_id=ours_canvas_strokes.space_id
      and m.user_id=(select auth.uid())
  )
  and owner_id=(select auth.uid())
  and scope in ('personal','shared')
);