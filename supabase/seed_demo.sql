-- Demo data: teams, colleagues, their sessions, and the events calendar.
--
-- NOT a migration, and deliberately not in supabase/migrations. Migrations
-- describe the shape of the database and run everywhere; this describes a
-- populated demo and must never reach production. Run it by hand:
--
--   docker exec -i supabase_db_monapp psql -U postgres -d postgres < supabase/seed_demo.sql
--
-- Every row uses a fixed id under the 0000...d0xx range, so seed_demo_teardown.sql
-- can remove exactly what this added and nothing else, and so running this twice
-- updates rather than duplicates.
--
-- The names and e-mail addresses are fictional, on a .local domain that cannot
-- receive mail.
--
-- The portraits are the placeholder set from randomuser.me, which is what this
-- kind of demo data normally uses. They are photographs of real people,
-- supplied for exactly this purpose, and that is the caveat: they are fine for
-- a local demo and must be replaced before anything ships, because attaching a
-- real identifiable face to an invented colleague in a leaderboard your actual
-- colleagues read is both a personality rights problem and misleading. The
-- avatar_url column takes any URL, so swapping in a licensed set is this one
-- column.

begin;

-- Signed 32-bit, the only form the integer column can hold; an opaque ARGB
-- colour is above the signed maximum.
create temporary table demo_teams (id uuid, name text, hex text) on commit drop;
insert into demo_teams values
  ('00000000-0000-0000-0000-0000000000d1', 'Les Rouges',   'FFE10600'),
  ('00000000-0000-0000-0000-0000000000d2', 'Agence Lyon',  'FF0F6FA8'),
  ('00000000-0000-0000-0000-0000000000d3', 'Agence Annecy','FF1B7F5C'),
  ('00000000-0000-0000-0000-0000000000d4', 'Team Dev',     'FF7A3FA0'),
  ('00000000-0000-0000-0000-0000000000d5', 'Les Chevaliers','FFC46A00');

insert into teams (id, name, color_value)
select id, name, ('x' || hex)::bit(32)::int from demo_teams
on conflict (id) do update
  set name = excluded.name, color_value = excluded.color_value;

-- The colleagues. Inserted through auth.users so the handle_new_user trigger
-- creates their profile exactly as a real signup would.
create temporary table demo_people (
  id uuid, name text, email text, weight_kg numeric, team_id uuid, avatar_seed text -- a portrait URL
) on commit drop;

insert into demo_people values
  ('00000000-0000-0000-0000-0000000000a1', 'Camille Roussel', 'camille.roussel@demo.xefi.local', 62, '00000000-0000-0000-0000-0000000000d1', 'https://randomuser.me/api/portraits/women/44.jpg'),
  ('00000000-0000-0000-0000-0000000000a2', 'Théo Marchand',   'theo.marchand@demo.xefi.local',   78, '00000000-0000-0000-0000-0000000000d1', 'https://randomuser.me/api/portraits/men/32.jpg'),
  ('00000000-0000-0000-0000-0000000000a3', 'Inès Barbier',    'ines.barbier@demo.xefi.local',    58, '00000000-0000-0000-0000-0000000000d2', 'https://randomuser.me/api/portraits/women/68.jpg'),
  ('00000000-0000-0000-0000-0000000000a4', 'Hugo Delaunay',   'hugo.delaunay@demo.xefi.local',   84, '00000000-0000-0000-0000-0000000000d2', 'https://randomuser.me/api/portraits/men/75.jpg'),
  ('00000000-0000-0000-0000-0000000000a5', 'Sarah Nguyen',    'sarah.nguyen@demo.xefi.local',    55, '00000000-0000-0000-0000-0000000000d3', 'https://randomuser.me/api/portraits/women/21.jpg'),
  ('00000000-0000-0000-0000-0000000000a6', 'Lucas Fontaine',  'lucas.fontaine@demo.xefi.local',  81, '00000000-0000-0000-0000-0000000000d3', 'https://randomuser.me/api/portraits/men/18.jpg'),
  ('00000000-0000-0000-0000-0000000000a7', 'Emma Leroy',      'emma.leroy@demo.xefi.local',      60, '00000000-0000-0000-0000-0000000000d4', 'https://randomuser.me/api/portraits/women/90.jpg'),
  ('00000000-0000-0000-0000-0000000000a8', 'Nathan Perrot',   'nathan.perrot@demo.xefi.local',   75, '00000000-0000-0000-0000-0000000000d4', 'https://randomuser.me/api/portraits/men/54.jpg'),
  ('00000000-0000-0000-0000-0000000000a9', 'Léa Mercier',     'lea.mercier@demo.xefi.local',     64, '00000000-0000-0000-0000-0000000000d5', 'https://randomuser.me/api/portraits/women/12.jpg'),
  ('00000000-0000-0000-0000-0000000000aa', 'Yanis Chevalier', 'yanis.chevalier@demo.xefi.local', 88, '00000000-0000-0000-0000-0000000000d5', 'https://randomuser.me/api/portraits/men/86.jpg');

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
  is_super_admin, confirmation_token, email_change, email_change_token_new,
  recovery_token
)
select
  '00000000-0000-0000-0000-000000000000',
  id,
  'authenticated',
  'authenticated',
  email,
  extensions.crypt('DemoXefi!2026', extensions.gen_salt('bf')),
  now(),
  -- Staggered joining dates, so "membre depuis" is not the same month for all.
  now() - (interval '1 month' * (row_number() over (order by name)) * 2),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('name', name, 'weight_kg', weight_kg),
  false, '', '', '', ''
from demo_people
on conflict (id) do nothing;

-- The trigger created the profiles; the team and the avatar are ours to set.
update profiles
set team_id = demo_people.team_id,
    name = demo_people.name,
    avatar_url = demo_people.avatar_seed
from demo_people
where profiles.id = demo_people.id;

-- Each team is owned by its first member, who is then the one who approves
-- requests to join it.
update teams
set created_by = (
  select id from demo_people
  where demo_people.team_id = teams.id
  order by demo_people.name
  limit 1
)
where teams.id in (select id from demo_teams);

-- Their history. Enough sessions, spread over the last five weeks, for the
-- individual leaderboard to have a shape and for the six-month chart to have
-- something in it. Football and basket-ball are what feed the team standings.
delete from sessions where id >= '00000000-0000-0000-0000-000000005000'
                       and id <= '00000000-0000-0000-0000-000000005fff';

insert into sessions (id, user_id, sport_id, date, duration_min, points, calories_burned)
select
  -- Numbered across people as well as sessions: keyed on n alone, the second
  -- person would collide with the first.
  (
    '00000000-0000-0000-0000-0000000050'
    || lpad(to_hex((person.rn - 1) * 9 + series.n), 2, '0')
  )::uuid,
  person.id,
  sport.id,
  (current_date - ((n * 3 + person.offset_days) % 34))::date,
  duration,
  duration,
  null
from (
  select id, row_number() over (order by name) as rn,
         (row_number() over (order by name) * 2)::int as offset_days
  from demo_people
) as person
cross join lateral (
  select generate_series(1, 9) as n
) as series
cross join lateral (
  -- Rotates through the sports, weighted so the two collective ones come up
  -- often enough for the team leaderboard to be worth looking at.
  select id from sports
  where name = (array['Football', 'Basket-ball', 'Course à pied', 'Musculation',
                      'Football', 'Basket-ball', 'Natation', 'Vélo', 'Tennis'])[series.n]
  limit 1
) as sport
cross join lateral (
  select (25 + ((person.rn * 7 + series.n * 11) % 8) * 10)::int as duration
) as d;

-- The calendar. Fixed ids so re-running replaces rather than piles up.
delete from events where id >= '00000000-0000-0000-0000-000000006000'
                     and id <= '00000000-0000-0000-0000-000000006fff';

insert into events (id, title, kind, starts_at, location, description, sport_id, home_team_id, away_team_id)
values
  (
    '00000000-0000-0000-0000-000000006001',
    'Tournoi de basket · quarts de finale',
    'tournament',
    date_trunc('day', now()) + interval '2 days 18 hours 30 minutes',
    'Gymnase Bellecour, Lyon',
    'Premier tour du tournoi inter-agences. Venez soutenir.',
    (select id from sports where name = 'Basket-ball'),
    '00000000-0000-0000-0000-0000000000d1',
    '00000000-0000-0000-0000-0000000000d2'
  ),
  (
    '00000000-0000-0000-0000-000000006002',
    'Séance musculation collective',
    'training',
    date_trunc('day', now()) + interval '4 days 12 hours 15 minutes',
    'Salle de sport, siège XEFI',
    'Circuit training encadré, ouvert à tous les niveaux.',
    (select id from sports where name = 'Musculation'),
    null,
    null
  ),
  (
    '00000000-0000-0000-0000-000000006003',
    'Tournoi CS · LAN XEFI',
    'gaming',
    date_trunc('day', now()) + interval '6 days 20 hours',
    'Salle événementielle, Annecy',
    'Counter-Strike en 5 contre 5, format double élimination.',
    null,
    '00000000-0000-0000-0000-0000000000d4',
    '00000000-0000-0000-0000-0000000000d5'
  ),
  (
    '00000000-0000-0000-0000-000000006004',
    'Tournoi de football · phase de poules',
    'tournament',
    date_trunc('day', now()) + interval '9 days 17 hours 45 minutes',
    'Stade municipal, Annecy',
    'Deux matchs de poule, puis les demi-finales la semaine suivante.',
    (select id from sports where name = 'Football'),
    '00000000-0000-0000-0000-0000000000d3',
    '00000000-0000-0000-0000-0000000000d5'
  ),
  (
    '00000000-0000-0000-0000-000000006005',
    'Sortie course à pied · 10 km',
    'training',
    date_trunc('day', now()) + interval '12 days 8 hours',
    'Parc de la Tête d''Or, Lyon',
    'Allure libre, trois groupes de niveau.',
    (select id from sports where name = 'Course à pied'),
    null,
    null
  ),
  (
    '00000000-0000-0000-0000-000000006006',
    'Tournoi de basket · finale',
    'tournament',
    date_trunc('day', now()) + interval '16 days 19 hours',
    'Gymnase Bellecour, Lyon',
    'La finale du tournoi inter-agences.',
    (select id from sports where name = 'Basket-ball'),
    '00000000-0000-0000-0000-0000000000d1',
    '00000000-0000-0000-0000-0000000000d4'
  );

commit;
