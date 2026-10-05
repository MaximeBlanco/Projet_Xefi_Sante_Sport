-- The access rules live in the database, so this is where they are proved.
-- A widget test cannot reach them, and the screen is not what enforces them.
--
--   docker exec -i supabase_db_monapp psql -U postgres -d postgres -v ON_ERROR_STOP=1 < test/sql/contact_access_test.sql
--
-- Camille is a1, Théo a2, Inès a3 — the demo seed's first three members.

\set camille '00000000-0000-0000-0000-0000000000a1'
\set theo    '00000000-0000-0000-0000-0000000000a2'
\set ines    '00000000-0000-0000-0000-0000000000a3'

create or replace function test_as(who uuid) returns void language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('sub', who, 'role', 'authenticated')::text, true);
end $$;

create or replace function expect(label text, got bigint, want bigint) returns void language plpgsql as $$
begin
  if got = want then
    raise notice 'OK   % (%).', label, got;
  else
    raise exception 'ECHEC % : attendu %, obtenu %', label, want, got;
  end if;
end $$;

begin;

-- No link at all: Camille sees only her own sessions.
select test_as(:'camille'::uuid);
select expect('sans lien, les seances de Theo sont invisibles',
              (select count(*) from sessions where user_id = :'theo'::uuid), 0);
select expect('ses propres seances restent lisibles',
              (select case when count(*) > 0 then 1 else 0 end from sessions where user_id = :'camille'::uuid), 1);

-- A pending request unlocks nothing.
reset role;
insert into contacts (requester_id, addressee_id, status)
values (:'camille'::uuid, :'theo'::uuid, 'pending');

select test_as(:'camille'::uuid);
select expect('une demande en attente ne donne acces a rien',
              (select count(*) from sessions where user_id = :'theo'::uuid), 0);

-- Accepted, and Théo shares his history.
reset role;
update contacts set status = 'accepted'
 where requester_id = :'camille'::uuid and addressee_id = :'theo'::uuid;

select test_as(:'camille'::uuid);
select expect('une fois accepte, les seances de Theo sont lisibles',
              (select case when count(*) > 0 then 1 else 0 end from sessions where user_id = :'theo'::uuid), 1);

-- Théo has not opened his locations: the view blanks them.
select expect('les lieux de Theo sont masques par defaut',
              (select count(*) from visible_sessions
                where user_id = :'theo'::uuid and venue_name is not null), 0);
select expect('ses seances restent visibles malgre tout',
              (select case when count(*) > 0 then 1 else 0 end from visible_sessions
                where user_id = :'theo'::uuid), 1);

-- He opens them.
reset role;
update profiles set shares_locations = true where id = :'theo'::uuid;

select test_as(:'camille'::uuid);
select expect('lieux ouverts, ils apparaissent',
              (select case when count(*) > 0 then 1 else 0 end from visible_sessions
                where user_id = :'theo'::uuid and venue_name is not null), 1);

-- He closes his history: everything goes, locations included.
reset role;
update profiles set shares_history = false where id = :'theo'::uuid;

select test_as(:'camille'::uuid);
select expect('historique ferme, plus aucune seance',
              (select count(*) from sessions where user_id = :'theo'::uuid), 0);

-- Camille always sees her own locations, whatever she shares.
reset role;
update profiles set shares_locations = false where id = :'camille'::uuid;

select test_as(:'camille'::uuid);
select expect('on voit toujours ses propres lieux',
              (select case when count(*) > 0 then 1 else 0 end from visible_sessions
                where user_id = :'camille'::uuid and venue_name is not null), 1);

-- The global leaderboard must survive the tightened policy.
select expect('le classement general liste toujours les 10 membres',
              (select count(*) from rankings_global), 10);

-- The contacts leaderboard holds the caller and their accepted contacts only.
reset role;
update profiles set shares_history = true where id = :'theo'::uuid;

select test_as(:'camille'::uuid);
select expect('le classement contacts contient Camille et Theo',
              (select count(*) from rankings_contacts), 2);

select test_as(:'ines'::uuid);
select expect('Ines, sans contact, n y voit qu elle-meme',
              (select count(*) from rankings_contacts), 1);

-- Nobody can be their own contact, and a pair cannot be duplicated.
reset role;
do $$
begin
  begin
    insert into contacts (requester_id, addressee_id, status)
    values ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a1', 'pending');
    raise exception 'ECHEC la demande a soi-meme a ete acceptee';
  exception when check_violation then
    raise notice 'OK   la demande a soi-meme est refusee.';
  end;
  begin
    insert into contacts (requester_id, addressee_id, status)
    values ('00000000-0000-0000-0000-0000000000a2', '00000000-0000-0000-0000-0000000000a1', 'pending');
    raise exception 'ECHEC le lien en double a ete accepte';
  exception when unique_violation then
    raise notice 'OK   le lien en double est refuse.';
  end;
end $$;

rollback;
