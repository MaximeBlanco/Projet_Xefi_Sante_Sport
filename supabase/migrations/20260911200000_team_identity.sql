-- A team gets a face and a roster.
--
-- A coloured dot says which row is which and nothing else. A photograph is what
-- makes a team feel like a group of people rather than a label, and the roster
-- is the obvious question a standing raises: who is actually in it.

alter table teams add column if not exists image_url text;

comment on column teams.image_url is
  'Public URL of the team photo, in the team-logos bucket. Null falls back to '
  'the team colour and initials.';

-- Renaming a team or giving it a photo is the owner's to do, and only theirs:
-- a team is shared, and one member should not be able to restyle what the
-- others joined. There was no update policy at all before, so nobody could.
drop policy if exists "Owners can update their team" on teams;
create policy "Owners can update their team" on teams
  for update to authenticated
  using (created_by = auth.uid())
  with check (created_by = auth.uid());

insert into storage.buckets (id, name, public)
values ('team-logos', 'team-logos', true)
on conflict (id) do nothing;

drop policy if exists "Team logos are readable by anyone" on storage.objects;
create policy "Team logos are readable by anyone" on storage.objects
  for select using (bucket_id = 'team-logos');

-- Keyed on the folder being a team the caller owns, the same shape as the
-- avatars bucket keys on the folder being the caller's own id.
drop policy if exists "Owners can upload their team logo" on storage.objects;
create policy "Owners can upload their team logo" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'team-logos'
    and exists (
      select 1 from teams
      where teams.created_by = auth.uid()
        and teams.id::text = (storage.foldername(name))[1]
    )
  );

drop policy if exists "Owners can replace their team logo" on storage.objects;
create policy "Owners can replace their team logo" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'team-logos'
    and exists (
      select 1 from teams
      where teams.created_by = auth.uid()
        and teams.id::text = (storage.foldername(name))[1]
    )
  );

drop policy if exists "Owners can delete their team logo" on storage.objects;
create policy "Owners can delete their team logo" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'team-logos'
    and exists (
      select 1 from teams
      where teams.created_by = auth.uid()
        and teams.id::text = (storage.foldername(name))[1]
    )
  );

-- Who is in a team, and what each has contributed.
--
-- Ordered by points so the roster reads as a standing within the team, which
-- is the second question after "who is in it".
create view team_members with (security_invoker = true) as
select
  profiles.team_id,
  profiles.id as user_id,
  profiles.name,
  profiles.avatar_url,
  teams.created_by = profiles.id as is_owner,
  coalesce(sum(sessions.points), 0)::bigint as total_points,
  count(sessions.id) as session_count
from profiles
join teams on teams.id = profiles.team_id
left join sessions on sessions.user_id = profiles.id
group by profiles.team_id, profiles.id, profiles.name, profiles.avatar_url,
         teams.created_by
order by total_points desc, profiles.name asc;

grant select on team_members to authenticated, anon;
