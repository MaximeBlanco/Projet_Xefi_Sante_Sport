-- Yoga leaves the fixed catalogue.
--
-- Guarded rather than unconditional: sessions reference sports with
-- `on delete restrict`, so a plain delete would fail on any database where
-- someone had already logged a yoga session, and this migration has to run
-- everywhere. Where such a session exists the sport simply stays, which is the
-- right outcome — losing a recorded session to tidy a catalogue would be a poor
-- trade.
delete from sports
where name = 'Yoga'
  and not exists (
    select 1 from sessions where sessions.sport_id = sports.id
  );
