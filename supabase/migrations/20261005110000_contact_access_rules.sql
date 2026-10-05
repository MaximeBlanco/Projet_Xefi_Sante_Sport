-- Close the sessions table, and keep the leaderboards standing.
--
-- Until now the SELECT policy on sessions was `using (true)`: any authenticated
-- account could read everyone's sessions — venues and GPS routes included —
-- straight from the API. The contacts feature would have been decoration on top
-- of that, so this is where it is actually enforced.

-- A session is yours, or it belongs to an accepted contact who shares their
-- history. Nothing else.
drop policy if exists "Sessions are readable by anyone" on sessions;
drop policy if exists "Sessions are readable by their owner and their contacts" on sessions;

create policy "Sessions are readable by their owner and their contacts"
  on sessions for select
  using (
    user_id = auth.uid()
    or exists (
      select 1
      from contacts c
      join profiles owner on owner.id = sessions.user_id
      where c.status = 'accepted'
        and owner.shares_history
        and (
          (c.requester_id = auth.uid() and c.addressee_id = sessions.user_id)
          or (c.addressee_id = auth.uid() and c.requester_id = sessions.user_id)
        )
    )
  );

-- The leaderboards aggregate sessions. They ran with security_invoker = true,
-- so with the caller's rights: closing the policy above would have collapsed
-- the global ranking to each member's own points.
--
-- Running them as their owner is sound rather than a loophole: a ranking view
-- only ever returns totals, never a session row, and those totals have been
-- public inside the app since V1 — showing them is the whole point of a
-- leaderboard.
alter view rankings_global set (security_invoker = false);
alter view rankings_teams set (security_invoker = false);

-- The same figures, limited to the caller and their accepted contacts. It needs
-- no parameter: it filters on auth.uid() itself.
create or replace view rankings_contacts
with (security_invoker = false) as
with circle as (
  select auth.uid() as user_id
  union
  select case
           when c.requester_id = auth.uid() then c.addressee_id
           else c.requester_id
         end
  from contacts c
  where c.status = 'accepted'
    and (c.requester_id = auth.uid() or c.addressee_id = auth.uid())
),
totals as (
  select profiles.id as user_id,
         profiles.name,
         profiles.avatar_url,
         coalesce(sum(sessions.points), 0::bigint) as total_points,
         coalesce(sum(sessions.duration_min), 0::bigint) as total_duration_min,
         coalesce(sum(sessions.calories_burned), 0::numeric) as total_calories_burned,
         count(sessions.id) as session_count,
         coalesce(sum(sessions.points) filter (
           where sessions.date < date_trunc('week', current_date::timestamptz)
         ), 0::bigint) as points_before_this_week
  from profiles
  join circle on circle.user_id = profiles.id
  left join sessions on sessions.user_id = profiles.id
  group by profiles.id, profiles.name, profiles.avatar_url
)
select user_id,
       name,
       total_points,
       total_duration_min,
       total_calories_burned,
       session_count,
       avatar_url,
       rank() over (order by total_points desc, name)::integer as current_rank,
       rank() over (order by points_before_this_week desc, name)::integer as previous_rank
from totals
order by total_points desc, name;

-- Row level security filters rows, not columns, and a per-member preference
-- cannot be expressed as a GRANT. So the place a session happened goes through
-- a view that blanks it when its owner has not opened it.
--
-- A null here means "not shared", and the screen says so rather than drawing an
-- empty map that would read as a bug.
create or replace view visible_sessions
with (security_invoker = true) as
select s.id,
       s.user_id,
       s.sport_id,
       s.date,
       s.duration_min,
       s.points,
       s.calories_burned,
       s.calories_estimated,
       s.distance_km,
       s.created_at,
       case when owner.shares_locations or s.user_id = auth.uid()
            then s.venue_name end as venue_name,
       case when owner.shares_locations or s.user_id = auth.uid()
            then s.venue_kind end as venue_kind,
       case when owner.shares_locations or s.user_id = auth.uid()
            then s.venue_osm_id end as venue_osm_id,
       case when owner.shares_locations or s.user_id = auth.uid()
            then s.route end as route,
       case when owner.shares_locations or s.user_id = auth.uid()
            then s.elevation_gain_m end as elevation_gain_m,
       owner.shares_locations
from sessions s
join profiles owner on owner.id = s.user_id;

grant select on rankings_contacts to anon, authenticated;
grant select on visible_sessions to anon, authenticated;
