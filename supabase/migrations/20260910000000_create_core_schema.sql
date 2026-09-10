-- Core schema for the V1 scope. See CAHIER_DES_CHARGES.md sections 4-5.
-- Any change here must go through a dedicated PR reviewed by both devs.

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  weight_kg numeric,
  created_at timestamptz not null default now()
);

create table sports (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  emoji text not null,
  points_per_unit integer not null default 1
);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  sport_id uuid not null references sports (id) on delete restrict,
  date date not null,
  duration_min integer not null check (duration_min > 0),
  points integer not null,
  calories_burned numeric not null,
  created_at timestamptz not null default now()
);

create index sessions_user_id_idx on sessions (user_id);
create index sessions_sport_id_idx on sessions (sport_id);

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

create view rankings_global as
  select
    profiles.id as user_id,
    profiles.name,
    coalesce(sum(sessions.points), 0) as total_points
  from profiles
  left join sessions on sessions.user_id = profiles.id
  group by profiles.id, profiles.name
  order by total_points desc;

alter table profiles enable row level security;
alter table sports enable row level security;
alter table sessions enable row level security;

create policy "Profiles are readable by anyone" on profiles
  for select using (true);

create policy "Users can update their own profile" on profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "Sports are readable by anyone" on sports
  for select using (true);

create policy "Sessions are readable by anyone" on sessions
  for select using (true);

create policy "Users can create their own sessions" on sessions
  for insert to authenticated with check (auth.uid() = user_id);

create policy "Users can update their own sessions" on sessions
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users can delete their own sessions" on sessions
  for delete to authenticated using (auth.uid() = user_id);
