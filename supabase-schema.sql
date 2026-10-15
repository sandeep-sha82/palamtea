-- Juniper & Bloom storefront schema. Run this in the Supabase SQL editor.
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  price numeric(10,2) not null default 0 check (price >= 0),
  image_url text not null,
  active boolean not null default true,
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
  business_name text not null default 'Juniper & Bloom'
);
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
-- Keep public sign-ups disabled in Supabase Authentication settings.
