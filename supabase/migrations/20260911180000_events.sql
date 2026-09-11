-- Upcoming events: what the company has planned, on the home screen.
--
-- A table rather than a list in the app, because an event is organisational
-- data: it is announced by somebody, it concerns teams that already exist, and
-- it stops being relevant the moment it has happened. None of that survives in
-- a hard-coded list.

create table events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  kind text not null check (kind in ('tournament', 'training', 'gaming')),
  starts_at timestamptz not null,
  location text,
  description text,
  -- The sport gives the card its photograph, through the same
  -- external_activity_name the session photos already key on.
  sport_id uuid references sports (id) on delete set null,
  -- A fixture between two teams. Both are optional: a training session has
  -- neither, a tournament may name only the host.
  home_team_id uuid references teams (id) on delete set null,
  away_team_id uuid references teams (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint events_title_not_blank check (length(btrim(title)) > 0),
  constraint events_opponents_differ check (
    home_team_id is null or away_team_id is null or home_team_id <> away_team_id
  )
);

create index events_starts_at_idx on events (starts_at);

alter table events enable row level security;

create policy "Events are readable by anyone" on events
  for select using (true);

create policy "Authenticated users can create events" on events
  for insert to authenticated with check (true);

-- Named teams and sport, already filtered to what is still ahead.
--
-- The two-hour grace keeps a fixture on the home screen while it is being
-- played, which is exactly when people look it up.
create view upcoming_events with (security_invoker = true) as
select
  events.id,
  events.title,
  events.kind,
  events.starts_at,
  events.location,
  events.description,
  events.sport_id,
  sports.name as sport_name,
  sports.emoji as sport_emoji,
  sports.external_activity_name,
  events.home_team_id,
  home_team.name as home_team_name,
  home_team.color_value as home_team_color,
  events.away_team_id,
  away_team.name as away_team_name,
  away_team.color_value as away_team_color
from events
left join sports on sports.id = events.sport_id
left join teams as home_team on home_team.id = events.home_team_id
left join teams as away_team on away_team.id = events.away_team_id
where events.starts_at >= now() - interval '2 hours'
order by events.starts_at;

grant select on upcoming_events to authenticated, anon;
