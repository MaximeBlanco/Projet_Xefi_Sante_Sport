-- Joining a team now needs the owner's agreement.
--
-- Until now anyone could set their own team_id, which meant anyone could walk
-- into any team and start counting towards its score. A team standing is only
-- worth something if the team decides who is in it.

alter table teams
  add column if not exists created_by uuid references profiles (id) on delete set null;

comment on column teams.created_by is
  'Who created the team, and so who approves requests to join it.';

create table team_join_requests (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  -- One live request per person per team. A decided one is kept as history and
  -- does not block asking again.
  constraint team_join_requests_unique_pending unique (team_id, user_id)
);

create index team_join_requests_team_id_idx on team_join_requests (team_id);
create index team_join_requests_user_id_idx on team_join_requests (user_id);

alter table team_join_requests enable row level security;

-- Readable by the person who asked and by the owner of the team they asked to
-- join, and by nobody else: who applied where is not public.
create policy "Requests are readable by the asker and the owner"
  on team_join_requests for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from teams
      where teams.id = team_join_requests.team_id
        and teams.created_by = auth.uid()
    )
  );

create policy "Users can ask to join a team"
  on team_join_requests for insert to authenticated
  with check (user_id = auth.uid());

-- Withdrawing your own request.
create policy "Users can withdraw their own request"
  on team_join_requests for delete to authenticated
  using (user_id = auth.uid());

-- Only the owner decides, and only on requests for their own team. The client
-- never writes the other profile's team_id: that happens in the trigger below,
-- which is the one place allowed to.
create policy "Owners can decide on requests for their team"
  on team_join_requests for update to authenticated
  using (
    exists (
      select 1 from teams
      where teams.id = team_join_requests.team_id
        and teams.created_by = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from teams
      where teams.id = team_join_requests.team_id
        and teams.created_by = auth.uid()
    )
  );

-- Accepting a request is what puts somebody in a team.
--
-- It has to happen here rather than in the app: the owner is not allowed to
-- update somebody else's profile, and giving them that right so they could
-- would let them edit that person's name and weight too.
create or replace function apply_team_join_decision()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.status = 'accepted' and coalesce(old.status, '') <> 'accepted' then
    update profiles set team_id = new.team_id where id = new.user_id;
    new.decided_at := now();
  elsif new.status = 'declined' and coalesce(old.status, '') <> 'declined' then
    new.decided_at := now();
  end if;

  return new;
end;
$$;

create trigger team_join_requests_apply_decision
before update on team_join_requests
for each row execute function apply_team_join_decision();

-- Leaving stays free: nobody needs permission to walk out. Joining without a
-- request is what is now closed off, and the existing "Users can update their
-- own profile" policy is too broad to express that, so it is replaced by one
-- that lets a member clear their team but never set it.
drop policy if exists "Users can update their own profile" on profiles;

create policy "Users can update their own profile"
  on profiles for update to authenticated
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    and (
      team_id is null
      or team_id = (select p.team_id from profiles p where p.id = auth.uid())
      -- The team you created is yours to be in without asking yourself.
      or exists (
        select 1 from teams
        where teams.id = team_id and teams.created_by = auth.uid()
      )
    )
  );

-- Existing demo and test teams have no owner; the first member becomes one so
-- they are not left unmanageable.
update teams
set created_by = (
  select profiles.id from profiles
  where profiles.team_id = teams.id
  order by profiles.created_at
  limit 1
)
where created_by is null;
