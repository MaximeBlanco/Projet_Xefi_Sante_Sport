-- What a member lets their contacts see.
--
-- Two switches rather than one: a session says what somebody did, a route says
-- where they were and at what time. Lumping them together would force a member
-- to give away the second in order to share the first.
--
-- The defaults are opposite on purpose. A position is sensitive, so nobody
-- broadcasts one without having chosen to; a history situates no one, and
-- closing it by default would leave every profile empty on a fresh install and
-- make the feature look broken.
--
-- They are column defaults, not client-side ones: an account created by the app,
-- by a script or from Studio shares no location either way.

alter table profiles
  add column if not exists shares_history boolean not null default true,
  add column if not exists shares_locations boolean not null default false;

-- Nobody can be their own contact.
alter table contacts
  drop constraint if exists contacts_not_self;

alter table contacts
  add constraint contacts_not_self check (requester_id <> addressee_id);

-- One link per pair, whichever way the request went. V1 already carried a
-- contacts_unique_pair index, but a directional one on (requester, addressee):
-- it let Camille ask Théo while Théo asked Camille, leaving two symmetric rows
-- that the leaderboard counts twice.
--
-- It is dropped rather than kept beside the new one, which subsumes it. The new
-- name is deliberately different: `create index if not exists` matches on the
-- name alone, so reusing it would have silently skipped this.
-- It is backed by a unique constraint, so it is dropped as one.
alter table contacts drop constraint if exists contacts_unique_pair;

create unique index if not exists contacts_unique_pair_either_way
  on contacts (least(requester_id, addressee_id), greatest(requester_id, addressee_id));
