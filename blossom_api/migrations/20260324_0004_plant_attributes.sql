-- Add location_type and caring_difficulty to plants catalog
-- These fields allow the add-plant questionnaire (Step 1) to filter
-- the plant catalog (Step 2) by the user's environment and care preferences.

alter table public.plants
  add column if not exists location_type text not null default 'Both'
    constraint plants_location_type_check check (location_type in ('Indoor', 'Outdoor', 'Both')),
  add column if not exists caring_difficulty text not null default 'low'
    constraint plants_caring_difficulty_check check (caring_difficulty in ('low', 'high'));

create index if not exists plants_location_type_idx on public.plants (location_type);
create index if not exists plants_caring_difficulty_idx on public.plants (caring_difficulty);

-- Also make the plant-images storage bucket public
update storage.buckets set public = true where id = 'plant-images';
