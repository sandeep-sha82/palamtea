-- Juniper & Bloom storefront schema. Run this in the Supabase SQL editor.
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  price numeric(10,2) not null default 0 check (price >= 0),
  image_url text not null,
  active boolean not null default true,
  available_for_purchase boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text not null default '',
  description text not null default '',
  image_url text not null,
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.site_settings (
  id integer primary key check (id = 1),
  business_name text not null default 'Juniper & Bloom',
  logo_text text not null default 'J',
  logo_url text not null default '',
  origin_kicker text not null default 'OUR HAPPY PLACE',
  origin_title text not null default 'Between the garden & the great outdoors.',
  origin_description text not null default 'Rain-washed leaves, mountain air, and afternoons that last a little longer. Palampur isn’t just where we’re from—it’s in every cup we make.',
  origin_image_url text not null default 'https://images.unsplash.com/photo-1563911892437-1feda0179e1b?auto=format&fit=crop&w=1500&q=85',
  origin_button_text text not null default 'A note from the hills',
  contact_email text not null default 'aurumkangratea@gmail.com',
  facebook_url text not null default '',
  instagram_url text not null default ''
);
alter table public.products add column if not exists available_for_purchase boolean not null default true;
alter table public.site_settings add column if not exists logo_text text not null default 'J';
alter table public.site_settings add column if not exists logo_url text not null default '';
alter table public.site_settings add column if not exists origin_kicker text not null default 'OUR HAPPY PLACE';
alter table public.site_settings add column if not exists origin_title text not null default 'Between the garden & the great outdoors.';
alter table public.site_settings add column if not exists origin_description text not null default 'Rain-washed leaves, mountain air, and afternoons that last a little longer. Palampur isn’t just where we’re from—it’s in every cup we make.';
alter table public.site_settings add column if not exists origin_image_url text not null default 'https://images.unsplash.com/photo-1563911892437-1feda0179e1b?auto=format&fit=crop&w=1500&q=85';
alter table public.site_settings add column if not exists origin_button_text text not null default 'A note from the hills';
alter table public.site_settings add column if not exists contact_email text not null default 'aurumkangratea@gmail.com';
alter table public.site_settings add column if not exists facebook_url text not null default '';
alter table public.site_settings add column if not exists instagram_url text not null default '';
insert into public.site_settings(id,business_name) values (1,'Juniper & Bloom') on conflict(id) do nothing;
create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- Public image delivery, admin-only image management.
insert into storage.buckets (id, name, public)
values ('store-images', 'store-images', true)
on conflict (id) do update set public = true;

alter table public.products enable row level security;
alter table public.banners enable row level security;
alter table public.site_settings enable row level security;
alter table public.store_admins enable row level security;

-- Public visitors can only read published content.
drop policy if exists "Published products are public" on public.products;
create policy "Published products are public" on public.products for select using (active = true or exists (select 1 from public.store_admins where user_id = (select auth.uid())));
drop policy if exists "Admins manage products" on public.products;
create policy "Admins manage products" on public.products for all to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) with check (exists (select 1 from public.store_admins where user_id = (select auth.uid())));
drop policy if exists "Published banners are public" on public.banners;
create policy "Published banners are public" on public.banners for select using (active = true or exists (select 1 from public.store_admins where user_id = (select auth.uid())));
drop policy if exists "Admins manage banners" on public.banners;
create policy "Admins manage banners" on public.banners for all to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) with check (exists (select 1 from public.store_admins where user_id = (select auth.uid())));
drop policy if exists "Settings are public" on public.site_settings;
create policy "Settings are public" on public.site_settings for select using (true);
drop policy if exists "Admins manage settings" on public.site_settings;
create policy "Admins manage settings" on public.site_settings for all to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) with check (exists (select 1 from public.store_admins where user_id = (select auth.uid())));
drop policy if exists "Admins can view admin list" on public.store_admins;
create policy "Admins can view admin list" on public.store_admins for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Store images are publicly readable" on storage.objects;
create policy "Store images are publicly readable" on storage.objects for select using (bucket_id = 'store-images');
drop policy if exists "Admins upload store images" on storage.objects;
create policy "Admins upload store images" on storage.objects for insert to authenticated with check (bucket_id = 'store-images' and exists (select 1 from public.store_admins where user_id = (select auth.uid())));
drop policy if exists "Admins update store images" on storage.objects;
create policy "Admins update store images" on storage.objects for update to authenticated using (bucket_id = 'store-images' and exists (select 1 from public.store_admins where user_id = (select auth.uid()))) with check (bucket_id = 'store-images' and exists (select 1 from public.store_admins where user_id = (select auth.uid())));
drop policy if exists "Admins delete store images" on storage.objects;
create policy "Admins delete store images" on storage.objects for delete to authenticated using (bucket_id = 'store-images' and exists (select 1 from public.store_admins where user_id = (select auth.uid())));

-- After creating the first user in Supabase Authentication, run this once with that user's UUID:
-- insert into public.store_admins(user_id) values ('PASTE_AUTH_USER_UUID_HERE');
-- Enable email/password sign-ups in Supabase Authentication for customer accounts.

-- Customer and guest orders. Guests may submit orders, but only signed-in customers
-- can view their own history; store admins can view all orders for reporting.
create table if not exists public.customer_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  customer_name text not null,
  customer_email text not null,
  customer_phone text not null,
  delivery_address text not null,
  order_total numeric(10,2) not null check (order_total >= 0),
  status text not null default 'pending' check (status in ('pending','confirmed','fulfilled','cancelled')),
  created_at timestamptz not null default now()
);
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.customer_orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price numeric(10,2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  created_at timestamptz not null default now()
);
create index if not exists customer_orders_created_at_idx on public.customer_orders(created_at desc);
create index if not exists customer_orders_user_id_idx on public.customer_orders(user_id);
alter table public.customer_orders enable row level security;
alter table public.order_items enable row level security;
grant select, update on public.customer_orders to authenticated;
grant select on public.order_items to authenticated;

drop policy if exists "Customers and admins read orders" on public.customer_orders;
create policy "Customers and admins read orders" on public.customer_orders
for select to authenticated using (
  user_id = (select auth.uid())
  or exists (select 1 from public.store_admins where user_id = (select auth.uid()))
);
drop policy if exists "Admins update orders" on public.customer_orders;
create policy "Admins update orders" on public.customer_orders
for update to authenticated using (
  exists (select 1 from public.store_admins where user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.store_admins where user_id = (select auth.uid()))
);
drop policy if exists "Customers and admins read order items" on public.order_items;
create policy "Customers and admins read order items" on public.order_items
for select to authenticated using (
  exists (
    select 1 from public.customer_orders o
    where o.id = order_id
      and (
        o.user_id = (select auth.uid())
        or exists (select 1 from public.store_admins where user_id = (select auth.uid()))
      )
  )
);

create or replace function public.place_customer_order(
  p_customer_name text,
  p_customer_email text,
  p_customer_phone text,
  p_delivery_address text,
  p_items jsonb
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_item_count integer;
  v_available_count integer;
  v_order_total numeric(10,2);
begin
  if nullif(trim(p_customer_name), '') is null
    or nullif(trim(p_customer_email), '') is null
    or nullif(trim(p_customer_phone), '') is null
    or nullif(trim(p_delivery_address), '') is null then
    raise exception 'Please complete all delivery details.';
  end if;
  if trim(p_customer_email) !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'Enter a valid email address.';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Your cart is empty.';
  end if;
  if exists (
    select 1 from jsonb_to_recordset(p_items) as item(product_id uuid, quantity integer)
    where item.product_id is null or item.quantity is null or item.quantity < 1 or item.quantity > 50
  ) then
    raise exception 'One or more order quantities are invalid.';
  end if;

  with requested as (
    select item.product_id, sum(item.quantity)::integer as quantity
    from jsonb_to_recordset(p_items) as item(product_id uuid, quantity integer)
    group by item.product_id
  )
  select count(*)::integer, count(p.id)::integer, coalesce(sum(p.price * requested.quantity), 0)::numeric(10,2)
  into v_item_count, v_available_count, v_order_total
  from requested
  left join public.products p on p.id = requested.product_id
    and p.active = true and p.available_for_purchase = true;

  if v_item_count = 0 or v_item_count > 25 or v_available_count <> v_item_count then
    raise exception 'A product in your cart is unavailable. Please refresh your cart and try again.';
  end if;
  if exists (
    select 1
    from (
      select sum(item.quantity)::integer as quantity
      from jsonb_to_recordset(p_items) as item(product_id uuid, quantity integer)
      group by item.product_id
    ) grouped
    where grouped.quantity > 50
  ) then
    raise exception 'An order can include at most 50 of each product.';
  end if;

  insert into public.customer_orders (
    user_id, customer_name, customer_email, customer_phone, delivery_address, order_total
  ) values (
    auth.uid(), trim(p_customer_name), lower(trim(p_customer_email)),
    trim(p_customer_phone), trim(p_delivery_address), v_order_total
  ) returning id into v_order_id;

  insert into public.order_items (order_id, product_id, product_name, unit_price, quantity)
  select v_order_id, p.id, p.name, p.price, requested.quantity
  from (
    select item.product_id, sum(item.quantity)::integer as quantity
    from jsonb_to_recordset(p_items) as item(product_id uuid, quantity integer)
    group by item.product_id
  ) requested
  join public.products p on p.id = requested.product_id
  where p.active = true and p.available_for_purchase = true;

  return v_order_id;
end;
$$;
revoke all on function public.place_customer_order(text,text,text,text,jsonb) from public;
grant execute on function public.place_customer_order(text,text,text,text,jsonb) to anon, authenticated;

-- Lightweight, first-party reporting for the admin panel.
create table if not exists public.customer_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.website_visitors (
  visitor_id uuid primary key,
  first_seen_at timestamptz not null default now()
);
create index if not exists website_visitors_first_seen_idx on public.website_visitors(first_seen_at desc);
alter table public.customer_profiles enable row level security;
alter table public.website_visitors enable row level security;
revoke all on public.customer_profiles, public.website_visitors from public, anon, authenticated;

create or replace function public.record_customer_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.customer_profiles(user_id, created_at)
  values (new.id, new.created_at)
  on conflict (user_id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_customer_profile on auth.users;
create trigger on_auth_user_created_customer_profile
after insert on auth.users
for each row execute function public.record_customer_signup();

-- Backfill registrations that existed before this report migration.
insert into public.customer_profiles(user_id, created_at)
select id, created_at from auth.users
on conflict (user_id) do nothing;

create or replace function public.record_site_visit(p_visitor_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_visitor_id is null then
    raise exception 'A visitor identifier is required.';
  end if;
  insert into public.website_visitors(visitor_id)
  values (p_visitor_id)
  on conflict (visitor_id) do nothing;
end;
$$;
revoke all on function public.record_site_visit(uuid) from public;
grant execute on function public.record_site_visit(uuid) to anon, authenticated;

create or replace function public.get_store_reports()
returns table(customer_count bigint, unique_visitor_count bigint)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.store_admins
    where user_id = (select auth.uid())
  ) then
    raise exception 'Admin access required.';
  end if;
  return query
  select
    (select count(*) from public.customer_profiles cp
      where not exists (select 1 from public.store_admins sa where sa.user_id = cp.user_id)),
    (select count(*) from public.website_visitors);
end;
$$;
revoke all on function public.get_store_reports() from public;
grant execute on function public.get_store_reports() to authenticated;
