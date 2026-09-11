-- Profile pictures. Additive follow-up; the earlier migrations are applied and
-- must not be edited.

alter table profiles add column if not exists avatar_url text;

-- Avatars are shown next to every name in the ranking, so the bucket is public:
-- a signed URL per row would expire while the leaderboard is on screen, and an
-- avatar is not a secret.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

-- Each user owns the folder named after their id, which is what keeps one
-- person from overwriting another's picture through the storage API.
drop policy if exists "Avatars are readable by anyone" on storage.objects;
create policy "Avatars are readable by anyone" on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists "Users can upload their own avatar" on storage.objects;
create policy "Users can upload their own avatar" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can replace their own avatar" on storage.objects;
create policy "Users can replace their own avatar" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can delete their own avatar" on storage.objects;
create policy "Users can delete their own avatar" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- The ranking carries the avatar so the leaderboard needs one request, not one
-- per row. A new column may only be appended by create or replace view.
create or replace view rankings_global with (security_invoker = true) as
select
  profiles.id as user_id,
  profiles.name,
  coalesce(sum(sessions.points), 0)::bigint as total_points,
  coalesce(sum(sessions.duration_min), 0)::bigint as total_duration_min,
  coalesce(sum(sessions.calories_burned), 0)::numeric as total_calories_burned,
  count(sessions.id) as session_count,
  profiles.avatar_url
from profiles
left join sessions on sessions.user_id = profiles.id
group by profiles.id, profiles.name, profiles.avatar_url
order by total_points desc, profiles.name asc;

grant select on rankings_global to authenticated, anon;
