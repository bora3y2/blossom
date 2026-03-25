-- Migration: Add countries and states tables, add location FK columns to profiles

-- 1. Countries lookup table
create table if not exists public.countries (
  id         serial primary key,
  name       text not null unique,
  created_at timestamptz not null default timezone('utc', now())
);

-- 2. States lookup table (each state belongs to a country, carries lat/lon for weather)
create table if not exists public.states (
  id         serial primary key,
  country_id int not null references public.countries(id) on delete cascade,
  name       text not null,
  latitude   double precision not null,
  longitude  double precision not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (country_id, name)
);

create index if not exists states_country_id_idx on public.states(country_id);

-- 3. Add optional location FK columns to user profiles
alter table public.profiles
  add column if not exists country_id int references public.countries(id) on delete set null,
  add column if not exists state_id   int references public.states(id) on delete set null;
