create extension if not exists pgcrypto;

create type public.user_role as enum ('admin');
create type public.property_purpose as enum ('venda', 'aluguel');
create type public.property_status as enum ('rascunho', 'publicado', 'reservado', 'vendido', 'alugado', 'indisponivel');
create type public.location_precision as enum ('exata', 'aproximada');
create type public.lead_status as enum ('novo', 'em_atendimento', 'convertido', 'arquivado');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role public.user_role not null default 'admin',
  created_at timestamptz not null default now()
);

create table public.properties (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 5 and 160),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text not null,
  property_type text not null,
  purpose public.property_purpose not null,
  status public.property_status not null default 'rascunho',
  sale_price numeric(14,2) check (sale_price >= 0),
  rent_price numeric(14,2) check (rent_price >= 0),
  condo_fee numeric(12,2) check (condo_fee >= 0),
  iptu numeric(12,2) check (iptu >= 0),
  total_area numeric(10,2) check (total_area >= 0),
  built_area numeric(10,2) check (built_area >= 0),
  bedrooms smallint check (bedrooms >= 0),
  suites smallint check (suites >= 0),
  bathrooms smallint check (bathrooms >= 0),
  parking_spaces smallint check (parking_spaces >= 0),
  address text,
  neighborhood text,
  city text not null,
  state text not null default 'MA',
  zip_code text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  location_precision public.location_precision not null default 'aproximada',
  featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  check ((purpose = 'venda' and sale_price is not null) or (purpose = 'aluguel' and rent_price is not null))
);
create index properties_public_search on public.properties (status, purpose, property_type, city, neighborhood, created_at desc);

create table public.property_images (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  storage_path text not null unique,
  public_url text not null,
  alt_text text,
  sort_order smallint not null default 0 check (sort_order >= 0),
  is_cover boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index property_one_cover on public.property_images(property_id) where is_cover;

create table public.property_videos (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  storage_path text not null unique,
  thumbnail_url text,
  sort_order smallint not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

create table public.property_features (
  id uuid primary key default gen_random_uuid(), name text not null unique
);
create table public.property_feature_relations (
  property_id uuid references public.properties(id) on delete cascade,
  feature_id uuid references public.property_features(id) on delete cascade,
  primary key (property_id, feature_id)
);

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references public.properties(id) on delete set null,
  name text not null check (char_length(name) between 2 and 120),
  email text check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  phone text not null check (char_length(phone) between 8 and 30),
  message text,
  source text not null default 'site',
  status public.lead_status not null default 'novo',
  created_at timestamptz not null default now()
);

create table public.testimonials (
  id uuid primary key default gen_random_uuid(), name text not null, city text, content text not null,
  image_url text, published boolean not null default false, created_at timestamptz not null default now()
);
create table public.blog_posts (
  id uuid primary key default gen_random_uuid(), title text not null, slug text not null unique,
  excerpt text not null, content text not null, cover_image text, published boolean not null default false,
  published_at timestamptz, meta_title text, meta_description text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;
create function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
create trigger properties_updated before update on public.properties for each row execute function public.touch_updated_at();
create trigger blog_posts_updated before update on public.blog_posts for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.properties enable row level security;
alter table public.property_images enable row level security;
alter table public.property_videos enable row level security;
alter table public.property_features enable row level security;
alter table public.property_feature_relations enable row level security;
alter table public.leads enable row level security;
alter table public.testimonials enable row level security;
alter table public.blog_posts enable row level security;

create policy "public reads published properties" on public.properties for select using (status in ('publicado','vendido','alugado'));
create policy "public reads media of published properties" on public.property_images for select using (exists (select 1 from public.properties p where p.id = property_id and p.status in ('publicado','vendido','alugado')));
create policy "public reads videos of published properties" on public.property_videos for select using (exists (select 1 from public.properties p where p.id = property_id and p.status in ('publicado','vendido','alugado')));
create policy "public reads features" on public.property_features for select using (true);
create policy "public reads published testimonials" on public.testimonials for select using (published);
create policy "public reads published posts" on public.blog_posts for select using (published);
create policy "admin manages profiles" on public.profiles for all using (public.is_admin()) with check (public.is_admin());
create policy "admin manages properties" on public.properties for all using (public.is_admin()) with check (public.is_admin());
create policy "admin manages images" on public.property_images for all using (public.is_admin()) with check (public.is_admin());
create policy "admin manages videos" on public.property_videos for all using (public.is_admin()) with check (public.is_admin());
create policy "admin manages features" on public.property_features for all using (public.is_admin()) with check (public.is_admin());
create policy "admin manages feature relations" on public.property_feature_relations for all using (public.is_admin()) with check (public.is_admin());
create policy "admin manages leads" on public.leads for all using (public.is_admin()) with check (public.is_admin());
create policy "admin manages testimonials" on public.testimonials for all using (public.is_admin()) with check (public.is_admin());
create policy "admin manages posts" on public.blog_posts for all using (public.is_admin()) with check (public.is_admin());

-- Execute lead creation through a server-side API route; do not create an anonymous INSERT policy here.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('property-images', 'property-images', true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('property-videos', 'property-videos', false, 52428800, array['video/mp4','video/webm'])
on conflict (id) do nothing;
create policy "admins manage property image objects" on storage.objects for all using (bucket_id = 'property-images' and public.is_admin()) with check (bucket_id = 'property-images' and public.is_admin());
create policy "public reads property images" on storage.objects for select using (bucket_id = 'property-images');
create policy "admins manage property video objects" on storage.objects for all using (bucket_id = 'property-videos' and public.is_admin()) with check (bucket_id = 'property-videos' and public.is_admin());
