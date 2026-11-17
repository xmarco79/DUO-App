-- OURS UNIVERSE: secure, two-person virtual economy foundation.
-- Wallet balances and purchases are server-authoritative.

create table if not exists public.ours_universe_wallets (
  space_id uuid not null references public.duo_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  coins bigint not null default 100 check (coins >= 0),
  xp integer not null default 0 check (xp >= 0),
  level integer not null default 1 check (level between 1 and 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (space_id, user_id)
);

create table if not exists public.ours_universe_catalog (
  item_code text primary key check (item_code ~ '^[a-z0-9_]{2,48}$'),
  title_ar text not null,
  title_en text not null,
  description_ar text not null default '',
  description_en text not null default '',
  category text not null check (category in ('decor','avatar','companion','artifact')),
  rarity text not null check (rarity in ('common','rare','epic','legendary')),
  price integer not null check (price >= 0),
  level_required integer not null default 1 check (level_required >= 1),
  icon text not null default '✦',
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.ours_universe_inventory (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null,
  user_id uuid not null,
  item_code text not null references public.ours_universe_catalog(item_code),
  quantity integer not null default 1 check (quantity > 0),
  acquired_at timestamptz not null default now(),
  unique (space_id, user_id, item_code),
  foreign key (space_id, user_id)
    references public.ours_universe_wallets(space_id, user_id) on delete cascade
);
create index if not exists ours_universe_inventory_owner_idx
  on public.ours_universe_inventory(space_id, user_id, acquired_at desc);

create table if not exists public.ours_universe_transactions (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null,
  user_id uuid not null,
  transaction_type text not null check (transaction_type in ('daily_reward','purchase')),
  amount bigint not null,
  item_code text references public.ours_universe_catalog(item_code),
  reference_key text not null,
  created_at timestamptz not null default now(),
  unique (space_id, user_id, reference_key),
  foreign key (space_id, user_id)
    references public.ours_universe_wallets(space_id, user_id) on delete cascade
);
create index if not exists ours_universe_transactions_owner_idx
  on public.ours_universe_transactions(space_id, user_id, created_at desc);

insert into public.ours_universe_catalog
  (item_code,title_ar,title_en,description_ar,description_en,category,rarity,price,level_required,icon)
values
  ('starlight_lamp','مصباح ضوء النجوم','Starlight Lamp','مصباح يضيف وهجًا هادئًا إلى مساحتك.','A soft glowing lamp for your space.','decor','common',45,1,'💡'),
  ('cloud_cushion','وسادة السحاب','Cloud Cushion','قطعة ديكور ناعمة مستوحاة من السماء.','A soft sky-inspired decorative piece.','decor','common',60,1,'☁️'),
  ('violet_cape','عباءة بنفسجية','Violet Cape','إضافة مميزة لمظهر شخصيتك.','A distinctive avatar cosmetic.','avatar','rare',110,1,'🧥'),
  ('orbit_companion','رفيق المدار','Orbit Companion','رفيق صغير يدور حول شخصيتك.','A tiny companion that orbits your avatar.','companion','epic',180,2,'🪐'),
  ('ancient_sigil','ختم العوالم','Worlds Sigil','قطعة أثرية تحمل رمز العوالم.','An artifact marked with the worlds sigil.','artifact','rare',95,1,'🔮'),
  ('nebula_frame','إطار السديم','Nebula Frame','إطار كوني لملفك داخل العالم.','A cosmic profile frame.','avatar','epic',150,2,'🌌'),
  ('golden_constellation','كوكبة ذهبية','Golden Constellation','أثر نادر يخلّد تقدمك.','A rare keepsake of your progress.','artifact','legendary',260,4,'✨')
on conflict (item_code) do nothing;

alter table public.ours_universe_wallets enable row level security;
alter table public.ours_universe_catalog enable row level security;
alter table public.ours_universe_inventory enable row level security;
alter table public.ours_universe_transactions enable row level security;

drop policy if exists "Space members read universe wallets" on public.ours_universe_wallets;
create policy "Space members read universe wallets"
on public.ours_universe_wallets for select to authenticated
using (exists (select 1 from public.duo_members m
  where m.space_id = ours_universe_wallets.space_id and m.user_id = (select auth.uid())));

drop policy if exists "Authenticated users read universe catalog" on public.ours_universe_catalog;
create policy "Authenticated users read universe catalog"
on public.ours_universe_catalog for select to authenticated using (is_available = true);

drop policy if exists "Space members read universe inventory" on public.ours_universe_inventory;
create policy "Space members read universe inventory"
on public.ours_universe_inventory for select to authenticated
using (exists (select 1 from public.duo_members m
  where m.space_id = ours_universe_inventory.space_id and m.user_id = (select auth.uid())));

drop policy if exists "Space members read universe transactions" on public.ours_universe_transactions;
create policy "Space members read universe transactions"
on public.ours_universe_transactions for select to authenticated
using (exists (select 1 from public.duo_members m
  where m.space_id = ours_universe_transactions.space_id and m.user_id = (select auth.uid())));

revoke all on public.ours_universe_wallets from anon, authenticated;
revoke all on public.ours_universe_catalog from anon, authenticated;
revoke all on public.ours_universe_inventory from anon, authenticated;
revoke all on public.ours_universe_transactions from anon, authenticated;
grant select on public.ours_universe_wallets to authenticated;
grant select on public.ours_universe_catalog to authenticated;
grant select on public.ours_universe_inventory to authenticated;
grant select on public.ours_universe_transactions to authenticated;

create or replace function public.ours_universe_get_wallet(p_space_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_wallet public.ours_universe_wallets;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.duo_members m
    where m.space_id = p_space_id and m.user_id = v_user_id)
  then raise exception 'Not a member of this space'; end if;
  insert into public.ours_universe_wallets(space_id,user_id)
    values (p_space_id,v_user_id) on conflict (space_id,user_id) do nothing;
  select * into v_wallet from public.ours_universe_wallets
    where space_id = p_space_id and user_id = v_user_id;
  return jsonb_build_object('space_id',v_wallet.space_id,'user_id',v_wallet.user_id,
    'coins',v_wallet.coins,'xp',v_wallet.xp,'level',v_wallet.level);
end;
$$;

create or replace function public.ours_universe_claim_daily_reward(p_space_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_wallet public.ours_universe_wallets;
  v_key text := 'daily:' || to_char((now() at time zone 'UTC')::date,'YYYY-MM-DD');
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.duo_members m
    where m.space_id = p_space_id and m.user_id = v_user_id)
  then raise exception 'Not a member of this space'; end if;
  insert into public.ours_universe_wallets(space_id,user_id)
    values (p_space_id,v_user_id) on conflict (space_id,user_id) do nothing;
  select * into v_wallet from public.ours_universe_wallets
    where space_id = p_space_id and user_id = v_user_id for update;
  if exists (select 1 from public.ours_universe_transactions t
    where t.space_id = p_space_id and t.user_id = v_user_id and t.reference_key = v_key)
  then return jsonb_build_object('claimed',false,'coins',v_wallet.coins,'xp',v_wallet.xp,'level',v_wallet.level); end if;
  update public.ours_universe_wallets
    set coins = coins + 25, xp = xp + 10,
        level = least(1000, 1 + ((xp + 10) / 100)), updated_at = now()
    where space_id = p_space_id and user_id = v_user_id returning * into v_wallet;
  insert into public.ours_universe_transactions
    (space_id,user_id,transaction_type,amount,reference_key)
    values (p_space_id,v_user_id,'daily_reward',25,v_key);
  return jsonb_build_object('claimed',true,'coins',v_wallet.coins,'xp',v_wallet.xp,'level',v_wallet.level);
end;
$$;

create or replace function public.ours_universe_purchase_item(p_space_id uuid,p_item_code text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_wallet public.ours_universe_wallets;
  v_item public.ours_universe_catalog;
  v_quantity integer;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.duo_members m
    where m.space_id = p_space_id and m.user_id = v_user_id)
  then raise exception 'Not a member of this space'; end if;
  select * into v_item from public.ours_universe_catalog
    where item_code = p_item_code and is_available = true;
  if not found then raise exception 'Item is unavailable'; end if;
  insert into public.ours_universe_wallets(space_id,user_id)
    values (p_space_id,v_user_id) on conflict (space_id,user_id) do nothing;
  select * into v_wallet from public.ours_universe_wallets
    where space_id = p_space_id and user_id = v_user_id for update;
  if v_wallet.level < v_item.level_required then raise exception 'Level requirement not met'; end if;
  if v_wallet.coins < v_item.price then raise exception 'Not enough coins'; end if;
  update public.ours_universe_wallets set coins = coins - v_item.price, updated_at = now()
    where space_id = p_space_id and user_id = v_user_id returning * into v_wallet;
  insert into public.ours_universe_inventory(space_id,user_id,item_code,quantity)
    values (p_space_id,v_user_id,p_item_code,1)
    on conflict (space_id,user_id,item_code)
    do update set quantity = public.ours_universe_inventory.quantity + 1;
  insert into public.ours_universe_transactions
    (space_id,user_id,transaction_type,amount,item_code,reference_key)
    values (p_space_id,v_user_id,'purchase',-v_item.price,p_item_code,'purchase:' || gen_random_uuid()::text);
  select quantity into v_quantity from public.ours_universe_inventory
    where space_id = p_space_id and user_id = v_user_id and item_code = p_item_code;
  return jsonb_build_object('purchased',true,'coins',v_wallet.coins,'xp',v_wallet.xp,
    'level',v_wallet.level,'item_code',p_item_code,'quantity',v_quantity);
end;
$$;

revoke all on function public.ours_universe_get_wallet(uuid) from public, anon;
revoke all on function public.ours_universe_claim_daily_reward(uuid) from public, anon;
revoke all on function public.ours_universe_purchase_item(uuid,text) from public, anon;
grant execute on function public.ours_universe_get_wallet(uuid) to authenticated;
grant execute on function public.ours_universe_claim_daily_reward(uuid) to authenticated;
grant execute on function public.ours_universe_purchase_item(uuid,text) to authenticated;
