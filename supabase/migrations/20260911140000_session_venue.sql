-- Where a session took place.
--
-- Venues come from OpenStreetMap through the Overpass API, the same data behind the map tiles the
-- app already displays. Three columns rather than a venues table: a venue is a label on a session,
-- not an entity the app owns, and copying the name keeps history readable if OSM later renames or
-- deletes the place.
--
-- venue_osm_id null means the user typed the name themselves. That is the "somewhere else" case,
-- and it needs no extra boolean to be readable.
alter table sessions
  add column if not exists venue_name text,
  add column if not exists venue_osm_id text,
  add column if not exists venue_kind text;

-- No SQL enum: a string column indexed and cast to an enum in the client, so adding a kind is a
-- deployment rather than a type migration that locks the table.
create index if not exists sessions_venue_kind_idx on sessions (venue_kind);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.sessions'::regclass
      and conname = 'sessions_venue_name_not_blank'
  ) then
    alter table sessions add constraint sessions_venue_name_not_blank
      check (venue_name is null or length(btrim(venue_name)) > 0);
  end if;
end;
$$;

-- A venue identified on the map must say what it is, and a hand-typed one never can. Enforcing the
-- pair here stops a half-filled venue reaching the history.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.sessions'::regclass
      and conname = 'sessions_venue_is_complete'
  ) then
    alter table sessions add constraint sessions_venue_is_complete
      check (
        (venue_osm_id is null and venue_kind is null)
        or (venue_osm_id is not null and venue_kind is not null and venue_name is not null)
      );
  end if;
end;
$$;
