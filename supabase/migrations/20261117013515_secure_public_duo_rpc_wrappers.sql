-- Public RPC entry points run as their trusted owner and call the private
-- implementations. The private schema remains unexposed to API clients.
create or replace function public.create_duo_space()
returns uuid
language sql
security definer
set search_path = pg_catalog, public, private
as $function$
  select private.create_duo_space();
$function$;

create or replace function public.create_duo_invite()
returns text
language sql
security definer
set search_path = pg_catalog, public, private
as $function$
  select private.create_duo_invite();
$function$;

create or replace function public.redeem_duo_invite(p_code text)
returns uuid
language sql
security definer
set search_path = pg_catalog, public, private
as $function$
  select private.redeem_duo_invite(p_code);
$function$;

alter function public.create_duo_space() owner to postgres;
alter function public.create_duo_invite() owner to postgres;
alter function public.redeem_duo_invite(text) owner to postgres;

revoke all on function public.create_duo_space() from public, anon;
revoke all on function public.create_duo_invite() from public, anon;
revoke all on function public.redeem_duo_invite(text) from public, anon;

grant execute on function public.create_duo_space() to authenticated;
grant execute on function public.create_duo_invite() to authenticated;
grant execute on function public.redeem_duo_invite(text) to authenticated;
