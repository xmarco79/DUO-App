create extension if not exists pg_net with schema extensions;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.dispatch_ours_push_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_secret text;
begin
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'ours_push_webhook_secret'
  limit 1;

  if v_secret is null or length(v_secret) < 32 then
    return new;
  end if;

  perform net.http_post(
    url := 'https://sthlcrgwpzqhxtpevqwg.supabase.co/functions/v1/send-ours-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-ours-webhook-secret', v_secret
    ),
    body := jsonb_build_object('record', to_jsonb(new)),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

revoke all on function private.dispatch_ours_push_notification() from public, anon, authenticated;
drop trigger if exists ours_push_after_notification_insert on public.duo_notifications;
create trigger ours_push_after_notification_insert
after insert on public.duo_notifications
for each row execute function private.dispatch_ours_push_notification();
