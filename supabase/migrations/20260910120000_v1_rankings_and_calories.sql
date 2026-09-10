-- V1 rankings and calories. Additive follow-up to 20260910000000_create_core_schema.sql,
-- which is already applied on the live project and must not be edited.

-- The Calories Burned API is a third party that can fail or rate-limit us. Storing a
-- fabricated 0 would lie in the history and in the ranking totals, so the column becomes
-- nullable and the UI renders a placeholder instead.
alter table sessions alter column calories_burned drop not null;

-- The French display name is what the user picks; the API only matches English activity
-- names, so the mapping lives next to the sport instead of being hardcoded in Dart.
alter table sports add column if not exists external_activity_name text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.sports'::regclass
      and conname = 'sports_name_key'
  ) then
    alter table sports add constraint sports_name_key unique (name);
  end if;
end;
$$;

-- Fixed list of 10 sports (spec section 3): no external catalogue in V1.
-- points_per_unit stays 1 everywhere because points = duration_min.
insert into sports (name, emoji, points_per_unit, external_activity_name, is_gps_trackable)
values
  ('Course à pied', '🏃', 1, 'running', true),
  ('Vélo', '🚴', 1, 'cycling', true),
  ('Marche', '🚶', 1, 'walking', true),
  ('Natation', '🏊', 1, 'swimming', false),
  ('Musculation', '🏋️', 1, 'weight lifting', false),
  ('Football', '⚽', 1, 'football', false),
  ('Basket-ball', '🏀', 1, 'basketball', false),
  ('Tennis', '🎾', 1, 'tennis', false),
  ('Rameur', '🚣', 1, 'rowing', false),
  ('Yoga', '🧘', 1, 'yoga', false)
on conflict (name) do update
set emoji = excluded.emoji,
    points_per_unit = excluded.points_per_unit,
    external_activity_name = excluded.external_activity_name,
    is_gps_trackable = excluded.is_gps_trackable;

-- Signup now carries the weight needed by the calories call, so the profile row created
-- by the auth trigger stores it right away instead of forcing a second round trip.
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  raw_weight_kg text := new.raw_user_meta_data ->> 'weight_kg';
  parsed_weight_kg numeric;
begin
  -- Metadata is client-supplied: an unparseable value must leave weight empty rather than
  -- raise and make the whole signup fail.
  if raw_weight_kg ~ '^[0-9]+(\.[0-9]+)?$' then
    parsed_weight_kg := raw_weight_kg::numeric;
  end if;

  insert into public.profiles (id, name, weight_kg)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', new.email),
    parsed_weight_kg
  );
  return new;
end;
$$;

-- Deriving points from duration_min is only worth anything if duration_min is itself bounded
-- server-side: PostgREST exposes sessions directly, so the 1440-minute cap in the Flutter form
-- is not a control, it is a suggestion an attacker never sees.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.sessions'::regclass
      and conname = 'sessions_duration_min_within_one_day'
  ) then
    alter table sessions
      add constraint sessions_duration_min_within_one_day
      check (duration_min <= 1440);
  end if;
end;
$$;

-- Points are derived, never sent by the client, otherwise anyone could inflate their rank
-- through the auto-generated REST API. sessions.points is NOT NULL with no default, and a
-- BEFORE ROW trigger rewrites the pending row before NOT NULL and CHECK constraints are
-- evaluated, so an insert that omits the column still succeeds.
--
-- The future-date rule lives here rather than in a CHECK constraint because current_date is
-- not immutable, and a constraint built on it would be re-evaluated against historical rows
-- on a dump/restore.
create or replace function enforce_session_invariants()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.date > current_date then
    raise exception 'A session cannot be dated in the future (got %)', new.date
      using errcode = 'check_violation';
  end if;

  new.points := new.duration_min;
  return new;
end;
$$;

drop trigger if exists set_session_points_on_write on sessions;

create trigger enforce_session_invariants_on_write
  before insert or update on sessions
  for each row execute procedure enforce_session_invariants();

-- security_invoker keeps the caller's RLS in effect; profiles and sessions are both
-- world-readable, so the ranking stays visible without widening anyone's access.
create or replace view rankings_global with (security_invoker = true) as
select
  profiles.id as user_id,
  profiles.name,
  coalesce(sum(sessions.points), 0)::bigint as total_points,
  coalesce(sum(sessions.duration_min), 0)::bigint as total_duration_min,
  coalesce(sum(sessions.calories_burned), 0)::numeric as total_calories_burned,
  count(sessions.id) as session_count
from profiles
left join sessions on sessions.user_id = profiles.id
group by profiles.id, profiles.name
order by total_points desc, profiles.name asc;

grant select on rankings_global to authenticated, anon;
