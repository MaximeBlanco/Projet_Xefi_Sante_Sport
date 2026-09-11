-- Local fallback for the calories integration.
--
-- The Calories Burned API is the project's external dependency, and it can be down, rate-limited
-- or simply unconfigured (no CALORIES_API_KEY on a fresh local stack). Until now every one of
-- those cases stored a null and the history showed a dash. Storing the MET of each sport lets the
-- app compute calories itself with the standard formula, so a session is never left without them:
--
--   kcal = MET x weight_kg x duration_hours
--
-- Values come from the Compendium of Physical Activities, taken at the moderate intensity that
-- matches the single fixed entry per sport the V1 catalogue offers.
alter table sports add column if not exists met numeric;

update sports set met = values.met
from (
  values
    ('Course à pied', 9.8),
    ('Vélo', 7.5),
    ('Marche', 3.5),
    ('Natation', 8.0),
    ('Musculation', 5.0),
    ('Football', 7.0),
    ('Basket-ball', 6.5),
    ('Tennis', 7.3),
    ('Rameur', 7.0),
    ('Yoga', 2.5)
) as values (name, met)
where sports.name = values.name;

-- A sport added later without a MET would silently fall back to nothing, so the column carries a
-- default and a floor rather than staying nullable.
alter table sports alter column met set default 5.0;
update sports set met = 5.0 where met is null;
alter table sports alter column met set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.sports'::regclass
      and conname = 'sports_met_positive'
  ) then
    alter table sports add constraint sports_met_positive check (met > 0);
  end if;
end;
$$;

-- Which of the two sources produced the number, so the history can tell the user that a value is
-- a local estimate rather than letting it pass for a measured one.
alter table sessions
  add column if not exists calories_estimated boolean not null default false;
