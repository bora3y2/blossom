-- Community content reports table
create table if not exists public.community_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.community_posts (id) on delete cascade,
  comment_id uuid references public.community_comments (id) on delete cascade,
  reporter_user_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null,
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'dismissed')),
  reviewed_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint community_reports_target_check check (post_id is not null or comment_id is not null)
);

create index if not exists community_reports_post_id_idx on public.community_reports (post_id);
create index if not exists community_reports_comment_id_idx on public.community_reports (comment_id);
create index if not exists community_reports_status_idx on public.community_reports (status);
create index if not exists community_reports_reporter_idx on public.community_reports (reporter_user_id);

drop trigger if exists set_community_reports_updated_at on public.community_reports;
create trigger set_community_reports_updated_at
before update on public.community_reports
for each row
execute function public.set_updated_at();

alter table public.community_reports enable row level security;

-- Users can insert their own reports
drop policy if exists community_reports_insert_own on public.community_reports;
create policy community_reports_insert_own
on public.community_reports
for insert
to authenticated
with check (reporter_user_id = auth.uid());

-- Users can see their own reports
drop policy if exists community_reports_select_own_or_admin on public.community_reports;
create policy community_reports_select_own_or_admin
on public.community_reports
for select
to authenticated
using (reporter_user_id = auth.uid() or public.is_admin());

-- Only admins can update reports (change status)
drop policy if exists community_reports_update_admin on public.community_reports;
create policy community_reports_update_admin
on public.community_reports
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());
