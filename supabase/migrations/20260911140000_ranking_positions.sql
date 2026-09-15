-- The leaderboard gains its positions and the movement since Monday.
--
-- The arrow next to a name has to mean something, and no history of past
-- standings is stored. It does not need to be: a rank as of the start of the
-- week is just the same aggregate restricted to sessions dated before Monday,
-- so the movement is derived from the sessions table rather than from
-- snapshots nobody is writing.
--
-- Recreated rather than replaced because create or replace view may only append
-- columns, and the ranks belong next to the name.
drop view if exists rankings_global;

create view rankings_global with (security_invoker = true) as
with totals as (
  select
    profiles.id as user_id,
    profiles.name,
    profiles.avatar_url,
    coalesce(sum(sessions.points), 0)::bigint as total_points,
    coalesce(sum(sessions.duration_min), 0)::bigint as total_duration_min,
    coalesce(sum(sessions.calories_burned), 0)::numeric as total_calories_burned,
    count(sessions.id) as session_count,
    coalesce(
      sum(sessions.points) filter (
        where sessions.date < date_trunc('week', current_date)
      ),
      0
    )::bigint as points_before_this_week
  from profiles
  left join sessions on sessions.user_id = profiles.id
  group by profiles.id, profiles.name, profiles.avatar_url
)
select
  user_id,
  name,
  total_points,
  total_duration_min,
  total_calories_burned,
  session_count,
  avatar_url,
  -- rank() rather than row_number(): two people on the same score share a
  -- position, which is what a leaderboard means by a tie.
  rank() over (order by total_points desc, name asc)::int as current_rank,
  rank() over (order by points_before_this_week desc, name asc)::int
    as previous_rank
from totals
order by total_points desc, name asc;

grant select on rankings_global to authenticated, anon;
