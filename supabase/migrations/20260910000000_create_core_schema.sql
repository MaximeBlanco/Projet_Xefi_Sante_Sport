-- Core schema shared by both lots. See CAHIER_DES_CHARGES.md section 5.
-- Any change here must go through a dedicated PR reviewed by both devs.

create table teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  color_value integer not null,
  created_at timestamptz not null default now()
);

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  weight_kg numeric,
  team_id uuid references teams (id) on delete set null,
  created_at timestamptz not null default now()
);

create table contacts (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references profiles (id) on delete cascade,
  addressee_id uuid not null references profiles (id) on delete cascade,
  status text not null check (status in ('pending', 'accepted')) default 'pending',
  created_at timestamptz not null default now(),
  constraint contacts_no_self_request check (requester_id <> addressee_id),
  constraint contacts_unique_pair unique (requester_id, addressee_id)
);

create table sports (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  emoji text not null,
  points_per_unit integer not null default 1,
  wger_id integer unique,
  is_gps_trackable boolean not null default false
);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  sport_id uuid not null references sports (id) on delete restrict,
  date date not null,
  duration_min integer not null check (duration_min > 0),
  points integer not null,
  calories_burned numeric not null,
  distance_km numeric,
  elevation_gain_m numeric,
  route jsonb,
  created_at timestamptz not null default now()
);

create index sessions_user_id_idx on sessions (user_id);
create index sessions_sport_id_idx on sessions (sport_id);
create index contacts_requester_id_idx on contacts (requester_id);
create index contacts_addressee_id_idx on contacts (addressee_id);

-- A profile row is created automatically for every new auth.users row, since
-- Supabase Auth owns signup and the app never inserts into profiles directly.
create function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', new.email));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

alter table teams enable row level security;
alter table profiles enable row level security;
alter table contacts enable row level security;
alter table sports enable row level security;
alter table sessions enable row level security;

create policy "Teams are readable by anyone" on teams
  for select using (true);

create policy "Authenticated users can create teams" on teams
  for insert to authenticated with check (true);

create policy "Profiles are readable by anyone" on profiles
  for select using (true);

create policy "Users can update their own profile" on profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "Contacts are readable by participants" on contacts
  for select to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Users can send contact requests" on contacts
  for insert to authenticated with check (auth.uid() = requester_id);

create policy "Participants can update a contact request" on contacts
  for update to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id)
  with check (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Participants can delete a contact" on contacts
  for delete to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Sports are readable by anyone" on sports
  for select using (true);

create policy "Authenticated users can add sports" on sports
  for insert to authenticated with check (true);

create policy "Sessions are readable by anyone" on sessions
  for select using (true);

create policy "Users can manage their own sessions" on sessions
  for insert to authenticated with check (auth.uid() = user_id);

create policy "Users can update their own sessions" on sessions
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users can delete their own sessions" on sessions
  for delete to authenticated using (auth.uid() = user_id);
