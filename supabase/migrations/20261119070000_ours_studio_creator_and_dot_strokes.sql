alter table public.ours_canvas_strokes
  drop constraint if exists ours_canvas_scope_owner_check,
  drop constraint if exists ours_canvas_strokes_points_check;

alter table public.ours_canvas_strokes
  add constraint ours_canvas_scope_owner_check
    check ((scope='personal' and owner_id is not null) or scope='shared'),
  add constraint ours_canvas_strokes_points_check
    check (jsonb_typeof(points)='array' and jsonb_array_length(points)>=1 and jsonb_array_length(points)<=20000);