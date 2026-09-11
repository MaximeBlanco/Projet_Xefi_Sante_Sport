-- A team leaderboard, scored on the sports a team actually plays together.
--
-- The teams table and profiles.team_id have existed since the core schema and
-- have never been used. What was missing was a reason to join one: this adds
-- the ranking that gives a team a score, and the flag that decides which
-- sessions count towards it.
--
-- Only collective sports count. A team standing built on everybody's solo runs
-- would rank the team with the keenest individual runner, which says nothing
-- about the team, and would make a football tournament invisible in a
-- leaderboard that is supposed to be about it.

alter table sports
  add column if not exists is_team_sport boolean not null default false;

comment on column sports.is_team_sport is
  'Whether sessions in this sport count towards the team leaderboard. '
  'Collective sports only: a solo run is not a team result.';

-- Matched on the seeded French names. Tennis is deliberately out: it is played
-- against someone, not with a team, and counting it would let a single strong
-- player carry a team standing. Flipping that is one update away.
update sports
set is_team_sport = true
where name in ('Football', 'Basket-ball');

-- A team must be named, and two teams sharing a name make the leaderboard
-- unreadable.
create unique index if not exists teams_name_unique_idx on teams (lower(name));

alter table teams
  drop constraint if exists teams_name_not_blank;
alter table teams
  add constraint teams_name_not_blank check (length(btrim(name)) > 0);

drop view if exists rankings_teams;

create view rankings_teams with (security_invoker = true) as
with team_sessions as (
  select
    profiles.team_id,
    sessions.points,
    sessions.duration_min,
    sessions.date
  from profiles
  join sessions on sessions.user_id = profiles.id
  join sports on sports.id = sessions.sport_id
  where profiles.team_id is not null
    and sports.is_team_sport
),
members as (
  select team_id, count(*)::int as member_count
  from profiles
  where team_id is not null
  group by team_id
),
totals as (
  select
    teams.id as team_id,
    teams.name,
    teams.color_value,
    coalesce(members.member_count, 0) as member_count,
    coalesce(sum(team_sessions.points), 0)::bigint as total_points,
    coalesce(sum(team_sessions.duration_min), 0)::bigint as total_duration_min,
    count(team_sessions.points) as session_count,
    coalesce(
      sum(team_sessions.points) filter (
        where team_sessions.date < date_trunc('week', current_date)
      ),
      0
    )::bigint as points_before_this_week
  from teams
  left join team_sessions on team_sessions.team_id = teams.id
  left join members on members.team_id = teams.id
  group by teams.id, teams.name, teams.color_value, members.member_count
)
select
  team_id,
  name,
  color_value,
  member_count,
  total_points,
  total_duration_min,
  session_count,
  -- rank() rather than row_number(), so two teams on the same score share a
  -- place, as the individual leaderboard already does.
  rank() over (order by total_points desc, name asc)::int as current_rank,
  rank() over (order by points_before_this_week desc, name asc)::int
    as previous_rank
from totals
order by total_points desc, name asc;

grant select on rankings_teams to authenticated, anon;

-- Leaving a team is updating your own profile, which the existing policy on
-- profiles already allows. Creating one is already allowed too. What was not
-- allowed was renaming or deleting a team, and it stays that way: a team is
-- shared, and one member should not be able to rename what the others joined.
