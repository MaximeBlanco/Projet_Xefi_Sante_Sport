-- Removes everything seed_demo.sql added, and nothing else.
--
--   docker exec -i supabase_db_monapp psql -U postgres -d postgres < supabase/seed_demo_teardown.sql
--
-- Every demo row sits in a reserved id range, so this can be exact rather than
-- matching on names that a real team might one day share.

begin;

delete from events
where id >= '00000000-0000-0000-0000-000000006000'
  and id <= '00000000-0000-0000-0000-000000006fff';

delete from sessions
where id >= '00000000-0000-0000-0000-000000005000'
  and id <= '00000000-0000-0000-0000-000000005fff';

-- Deleting the auth user cascades to the profile, and the profile cascades to
-- anything of theirs not already removed above.
delete from auth.users
where id >= '00000000-0000-0000-0000-0000000000a0'
  and id <= '00000000-0000-0000-0000-0000000000af';

-- Last, because a real person may have joined one of these teams in the
-- meantime; the foreign key is "on delete set null", so they simply lose it
-- rather than being deleted with it.
delete from teams
where id >= '00000000-0000-0000-0000-0000000000d0'
  and id <= '00000000-0000-0000-0000-0000000000df';

commit;
