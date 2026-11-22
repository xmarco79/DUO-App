update storage.buckets
set allowed_mime_types = array(
  select distinct mime
  from unnest(
    coalesce(allowed_mime_types, array[]::text[])
    || array['image/gif','video/mp4','video/quicktime','video/webm']::text[]
  ) as mime
)
where id = 'ours-direct-media';
