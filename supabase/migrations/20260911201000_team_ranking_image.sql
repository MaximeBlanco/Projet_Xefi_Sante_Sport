-- The team leaderboard carries the team photo.
--
-- Appended as the last column so create or replace is enough: replacing a view
-- may add columns at the end but may not reorder or retype the ones already
-- there, and recreating it would drop the grants with it.
create or replace view rankings_teams with (security_invoker = true) as
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
    teams.image_url,
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
  group by teams.id, teams.name, teams.color_value, teams.image_url,
           members.member_count
)
select
  team_id,
  name,
  color_value,
  member_count,
  total_points,
  total_duration_min,
  session_count,
  rank() over (order by total_points desc, name asc)::int as current_rank,
  rank() over (order by points_before_this_week desc, name asc)::int
    as previous_rank,
  image_url
from totals
order by total_points desc, name asc;
