create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  display_name text,
  avatar_path text,
  role text not null default 'user' check (role in ('user', 'admin')),
  notifications_enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create table if not exists public.plants (
  id uuid primary key default gen_random_uuid(),
  common_name text not null,
  scientific_name text,
  short_description text not null default '',
  image_path text,
  water_requirements text not null,
  light_requirements text not null,
  temperature text not null,
  pet_safe boolean not null default false,
  source text not null default 'admin' check (source in ('admin', 'ai_image_discovery')),
  ai_confidence numeric(5,2),
  created_by_user_id uuid references public.profiles (id) on delete set null,
  reviewed_by_admin boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_plants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  plant_id uuid not null references public.plants (id) on delete restrict,
  custom_name text,
  location_type text not null check (location_type in ('Indoor', 'Outdoor')),
  light_condition text not null check (light_condition in ('Low Light', 'Indirect', 'Direct Sunlight')),
  caring_style text not null check (caring_style in ('I''m a bit forgetful', 'I love caring for them daily')),
  pet_safety_priority text not null check (pet_safety_priority in ('Yes, keep it safe', 'No pets here')),
  created_via text not null default 'manual' check (created_via in ('manual', 'ai_image_discovery', 'admin')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.care_tasks (
  id uuid primary key default gen_random_uuid(),
  user_plant_id uuid not null references public.user_plants (id) on delete cascade,
  title text not null,
  description text,
  task_type text not null default 'custom' check (task_type in ('water', 'light', 'temperature', 'fertilize', 'custom')),
  due_at timestamptz,
  completed_at timestamptz,
  is_enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  content text not null default '',
  image_path text,
  hidden_by_admin boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint community_posts_content_or_image_check check (char_length(trim(content)) > 0 or image_path is not null)
);

create table if not exists public.community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  hidden_by_admin boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint community_comments_content_check check (char_length(trim(content)) > 0)
);

create table if not exists public.community_post_likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  constraint community_post_likes_post_user_key unique (post_id, user_id)
);

create table if not exists public.ai_settings (
  id integer primary key default 1 check (id = 1),
  provider text not null default 'gemini',
  model text not null default 'gemini-2.0-flash',
  system_prompt text not null default '',
  temperature numeric(3,2) not null default 0.40 check (temperature >= 0 and temperature <= 2),
  max_tokens integer not null default 1024 check (max_tokens > 0),
  is_enabled boolean not null default true,
  encrypted_api_key text,
  connection_last_tested_at timestamptz,
  connection_last_status text check (connection_last_status in ('success', 'failed')),
  updated_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  device_token text not null unique,
  platform text not null check (platform in ('ios', 'android', 'web')),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  last_seen_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid not null references public.profiles (id) on delete cascade,
  action text not null,
  entity_type text not null,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.plant_identification_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  plant_id uuid references public.plants (id) on delete set null,
  image_path text,
  detected_name text,
  source text not null default 'gemini',
  confidence numeric(5,2),
  created_new_plant boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists plants_common_name_idx on public.plants (common_name);
create index if not exists plants_scientific_name_idx on public.plants (scientific_name);
create index if not exists user_plants_user_id_idx on public.user_plants (user_id);
create index if not exists user_plants_plant_id_idx on public.user_plants (plant_id);
create index if not exists care_tasks_user_plant_id_idx on public.care_tasks (user_plant_id);
create index if not exists community_posts_user_id_idx on public.community_posts (user_id);
create index if not exists community_posts_created_at_idx on public.community_posts (created_at desc);
create index if not exists community_comments_post_id_idx on public.community_comments (post_id);
create index if not exists community_comments_user_id_idx on public.community_comments (user_id);
create index if not exists device_tokens_user_id_idx on public.device_tokens (user_id);
create index if not exists plant_identification_events_user_id_idx on public.plant_identification_events (user_id);

insert into public.ai_settings (id)
values (1)
on conflict (id) do nothing;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Blossom User'
    )
  )
  on conflict (id) do update
    set email = excluded.email;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists set_plants_updated_at on public.plants;
create trigger set_plants_updated_at
before update on public.plants
for each row
execute function public.set_updated_at();

drop trigger if exists set_user_plants_updated_at on public.user_plants;
create trigger set_user_plants_updated_at
before update on public.user_plants
for each row
execute function public.set_updated_at();

drop trigger if exists set_care_tasks_updated_at on public.care_tasks;
create trigger set_care_tasks_updated_at
before update on public.care_tasks
for each row
execute function public.set_updated_at();

drop trigger if exists set_community_posts_updated_at on public.community_posts;
create trigger set_community_posts_updated_at
before update on public.community_posts
for each row
execute function public.set_updated_at();

drop trigger if exists set_community_comments_updated_at on public.community_comments;
create trigger set_community_comments_updated_at
before update on public.community_comments
for each row
execute function public.set_updated_at();

drop trigger if exists set_ai_settings_updated_at on public.ai_settings;
create trigger set_ai_settings_updated_at
before update on public.ai_settings
for each row
execute function public.set_updated_at();

drop trigger if exists set_device_tokens_updated_at on public.device_tokens;
create trigger set_device_tokens_updated_at
before update on public.device_tokens
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.plants enable row level security;
alter table public.user_plants enable row level security;
alter table public.care_tasks enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;
alter table public.community_post_likes enable row level security;
alter table public.ai_settings enable row level security;
alter table public.device_tokens enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.plant_identification_events enable row level security;

drop policy if exists profiles_select_own_or_admin on public.profiles;
create policy profiles_select_own_or_admin
on public.profiles
for select
to authenticated
using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_update_own_or_admin on public.profiles;
create policy profiles_update_own_or_admin
on public.profiles
for update
to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

drop policy if exists plants_select_authenticated on public.plants;
create policy plants_select_authenticated
on public.plants
for select
to authenticated
using (is_active = true or public.is_admin());

drop policy if exists plants_admin_write on public.plants;
create policy plants_admin_write
on public.plants
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists user_plants_select_own_or_admin on public.user_plants;
create policy user_plants_select_own_or_admin
on public.user_plants
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists user_plants_insert_own_or_admin on public.user_plants;
create policy user_plants_insert_own_or_admin
on public.user_plants
for insert
to authenticated
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists user_plants_update_own_or_admin on public.user_plants;
create policy user_plants_update_own_or_admin
on public.user_plants
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists user_plants_delete_own_or_admin on public.user_plants;
create policy user_plants_delete_own_or_admin
on public.user_plants
for delete
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists care_tasks_select_own_or_admin on public.care_tasks;
create policy care_tasks_select_own_or_admin
on public.care_tasks
for select
to authenticated
using (
  exists (
    select 1
    from public.user_plants up
    where up.id = care_tasks.user_plant_id
      and (up.user_id = auth.uid() or public.is_admin())
  )
);

drop policy if exists care_tasks_write_own_or_admin on public.care_tasks;
create policy care_tasks_write_own_or_admin
on public.care_tasks
for all
to authenticated
using (
  exists (
    select 1
    from public.user_plants up
    where up.id = care_tasks.user_plant_id
      and (up.user_id = auth.uid() or public.is_admin())
  )
)
with check (
  exists (
    select 1
    from public.user_plants up
    where up.id = care_tasks.user_plant_id
      and (up.user_id = auth.uid() or public.is_admin())
  )
);

drop policy if exists community_posts_select_authenticated on public.community_posts;
create policy community_posts_select_authenticated
on public.community_posts
for select
to authenticated
using (hidden_by_admin = false or public.is_admin());

drop policy if exists community_posts_insert_own on public.community_posts;
create policy community_posts_insert_own
on public.community_posts
for insert
to authenticated
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists community_posts_update_own_or_admin on public.community_posts;
create policy community_posts_update_own_or_admin
on public.community_posts
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists community_posts_delete_own_or_admin on public.community_posts;
create policy community_posts_delete_own_or_admin
on public.community_posts
for delete
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists community_comments_select_authenticated on public.community_comments;
create policy community_comments_select_authenticated
on public.community_comments
for select
to authenticated
using (hidden_by_admin = false or public.is_admin());

drop policy if exists community_comments_insert_own on public.community_comments;
create policy community_comments_insert_own
on public.community_comments
for insert
to authenticated
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists community_comments_update_own_or_admin on public.community_comments;
create policy community_comments_update_own_or_admin
on public.community_comments
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists community_comments_delete_own_or_admin on public.community_comments;
create policy community_comments_delete_own_or_admin
on public.community_comments
for delete
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists community_post_likes_select_authenticated on public.community_post_likes;
create policy community_post_likes_select_authenticated
on public.community_post_likes
for select
to authenticated
using (true);

drop policy if exists community_post_likes_insert_own on public.community_post_likes;
create policy community_post_likes_insert_own
on public.community_post_likes
for insert
to authenticated
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists community_post_likes_delete_own_or_admin on public.community_post_likes;
create policy community_post_likes_delete_own_or_admin
on public.community_post_likes
for delete
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists ai_settings_admin_only on public.ai_settings;
create policy ai_settings_admin_only
on public.ai_settings
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists device_tokens_select_own_or_admin on public.device_tokens;
create policy device_tokens_select_own_or_admin
on public.device_tokens
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists device_tokens_insert_own_or_admin on public.device_tokens;
create policy device_tokens_insert_own_or_admin
on public.device_tokens
for insert
to authenticated
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists device_tokens_update_own_or_admin on public.device_tokens;
create policy device_tokens_update_own_or_admin
on public.device_tokens
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists device_tokens_delete_own_or_admin on public.device_tokens;
create policy device_tokens_delete_own_or_admin
on public.device_tokens
for delete
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists admin_audit_logs_admin_only on public.admin_audit_logs;
create policy admin_audit_logs_admin_only
on public.admin_audit_logs
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists plant_identification_events_select_own_or_admin on public.plant_identification_events;
create policy plant_identification_events_select_own_or_admin
on public.plant_identification_events
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists plant_identification_events_insert_own_or_admin on public.plant_identification_events;
create policy plant_identification_events_insert_own_or_admin
on public.plant_identification_events
for insert
to authenticated
with check (user_id = auth.uid() or public.is_admin());

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', false),
  ('post-images', 'post-images', false),
  ('plant-images', 'plant-images', false)
on conflict (id) do nothing;

drop policy if exists storage_authenticated_read_avatars on storage.objects;
create policy storage_authenticated_read_avatars
on storage.objects
for select
to authenticated
using (bucket_id = 'avatars');

drop policy if exists storage_authenticated_read_post_images on storage.objects;
create policy storage_authenticated_read_post_images
on storage.objects
for select
to authenticated
using (bucket_id = 'post-images');

drop policy if exists storage_authenticated_read_plant_images on storage.objects;
create policy storage_authenticated_read_plant_images
on storage.objects
for select
to authenticated
using (bucket_id = 'plant-images');

drop policy if exists storage_authenticated_insert_avatars on storage.objects;
create policy storage_authenticated_insert_avatars
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists storage_authenticated_update_avatars on storage.objects;
create policy storage_authenticated_update_avatars
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists storage_authenticated_delete_avatars on storage.objects;
create policy storage_authenticated_delete_avatars
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists storage_authenticated_insert_post_images on storage.objects;
create policy storage_authenticated_insert_post_images
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'post-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists storage_authenticated_update_post_images on storage.objects;
create policy storage_authenticated_update_post_images
on storage.objects
for update
to authenticated
using (
  bucket_id = 'post-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'post-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists storage_authenticated_delete_post_images on storage.objects;
create policy storage_authenticated_delete_post_images
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'post-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists storage_authenticated_insert_plant_images on storage.objects;
create policy storage_authenticated_insert_plant_images
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'plant-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists storage_authenticated_update_plant_images on storage.objects;
create policy storage_authenticated_update_plant_images
on storage.objects
for update
to authenticated
using (
  bucket_id = 'plant-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'plant-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists storage_authenticated_delete_plant_images on storage.objects;
create policy storage_authenticated_delete_plant_images
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'plant-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
