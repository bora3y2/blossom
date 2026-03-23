create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create index if not exists plants_created_by_user_id_idx on public.plants (created_by_user_id);
create index if not exists community_post_likes_user_id_idx on public.community_post_likes (user_id);
create index if not exists ai_settings_updated_by_idx on public.ai_settings (updated_by);
create index if not exists admin_audit_logs_admin_user_id_idx on public.admin_audit_logs (admin_user_id);
create index if not exists plant_identification_events_plant_id_idx on public.plant_identification_events (plant_id);

drop policy if exists profiles_select_own_or_admin on public.profiles;
create policy profiles_select_own_or_admin
on public.profiles
for select
to authenticated
using (id = (select auth.uid()) or public.is_admin());

drop policy if exists profiles_update_own_or_admin on public.profiles;
create policy profiles_update_own_or_admin
on public.profiles
for update
to authenticated
using (id = (select auth.uid()) or public.is_admin())
with check (id = (select auth.uid()) or public.is_admin());

drop policy if exists plants_select_authenticated on public.plants;
create policy plants_select_authenticated
on public.plants
for select
to authenticated
using (is_active = true or public.is_admin());

drop policy if exists plants_admin_write on public.plants;
create policy plants_admin_insert
on public.plants
for insert
to authenticated
with check (public.is_admin());

create policy plants_admin_update
on public.plants
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy plants_admin_delete
on public.plants
for delete
to authenticated
using (public.is_admin());

drop policy if exists user_plants_select_own_or_admin on public.user_plants;
create policy user_plants_select_own_or_admin
on public.user_plants
for select
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists user_plants_insert_own_or_admin on public.user_plants;
create policy user_plants_insert_own_or_admin
on public.user_plants
for insert
to authenticated
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists user_plants_update_own_or_admin on public.user_plants;
create policy user_plants_update_own_or_admin
on public.user_plants
for update
to authenticated
using (user_id = (select auth.uid()) or public.is_admin())
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists user_plants_delete_own_or_admin on public.user_plants;
create policy user_plants_delete_own_or_admin
on public.user_plants
for delete
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

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
      and (up.user_id = (select auth.uid()) or public.is_admin())
  )
);

drop policy if exists care_tasks_write_own_or_admin on public.care_tasks;
create policy care_tasks_insert_own_or_admin
on public.care_tasks
for insert
to authenticated
with check (
  exists (
    select 1
    from public.user_plants up
    where up.id = care_tasks.user_plant_id
      and (up.user_id = (select auth.uid()) or public.is_admin())
  )
);

create policy care_tasks_update_own_or_admin
on public.care_tasks
for update
to authenticated
using (
  exists (
    select 1
    from public.user_plants up
    where up.id = care_tasks.user_plant_id
      and (up.user_id = (select auth.uid()) or public.is_admin())
  )
)
with check (
  exists (
    select 1
    from public.user_plants up
    where up.id = care_tasks.user_plant_id
      and (up.user_id = (select auth.uid()) or public.is_admin())
  )
);

create policy care_tasks_delete_own_or_admin
on public.care_tasks
for delete
to authenticated
using (
  exists (
    select 1
    from public.user_plants up
    where up.id = care_tasks.user_plant_id
      and (up.user_id = (select auth.uid()) or public.is_admin())
  )
);

drop policy if exists community_posts_insert_own on public.community_posts;
create policy community_posts_insert_own
on public.community_posts
for insert
to authenticated
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists community_posts_update_own_or_admin on public.community_posts;
create policy community_posts_update_own_or_admin
on public.community_posts
for update
to authenticated
using (user_id = (select auth.uid()) or public.is_admin())
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists community_posts_delete_own_or_admin on public.community_posts;
create policy community_posts_delete_own_or_admin
on public.community_posts
for delete
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists community_comments_insert_own on public.community_comments;
create policy community_comments_insert_own
on public.community_comments
for insert
to authenticated
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists community_comments_update_own_or_admin on public.community_comments;
create policy community_comments_update_own_or_admin
on public.community_comments
for update
to authenticated
using (user_id = (select auth.uid()) or public.is_admin())
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists community_comments_delete_own_or_admin on public.community_comments;
create policy community_comments_delete_own_or_admin
on public.community_comments
for delete
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists community_post_likes_insert_own on public.community_post_likes;
create policy community_post_likes_insert_own
on public.community_post_likes
for insert
to authenticated
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists community_post_likes_delete_own_or_admin on public.community_post_likes;
create policy community_post_likes_delete_own_or_admin
on public.community_post_likes
for delete
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists device_tokens_select_own_or_admin on public.device_tokens;
create policy device_tokens_select_own_or_admin
on public.device_tokens
for select
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists device_tokens_insert_own_or_admin on public.device_tokens;
create policy device_tokens_insert_own_or_admin
on public.device_tokens
for insert
to authenticated
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists device_tokens_update_own_or_admin on public.device_tokens;
create policy device_tokens_update_own_or_admin
on public.device_tokens
for update
to authenticated
using (user_id = (select auth.uid()) or public.is_admin())
with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists device_tokens_delete_own_or_admin on public.device_tokens;
create policy device_tokens_delete_own_or_admin
on public.device_tokens
for delete
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists plant_identification_events_select_own_or_admin on public.plant_identification_events;
create policy plant_identification_events_select_own_or_admin
on public.plant_identification_events
for select
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists plant_identification_events_insert_own_or_admin on public.plant_identification_events;
create policy plant_identification_events_insert_own_or_admin
on public.plant_identification_events
for insert
to authenticated
with check (user_id = (select auth.uid()) or public.is_admin());
