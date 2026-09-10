-- Fixed sports list for V1 (see CAHIER_DES_CHARGES.md section 3 — no
-- external catalog sync in this scope, wger.de sync is backlog).
insert into sports (name, emoji, points_per_unit) values
  ('Running', '🏃', 1),
  ('Cycling', '🚴', 1),
  ('Swimming', '🏊', 1),
  ('Walking', '🚶', 1),
  ('Football', '⚽', 1),
  ('Basketball', '🏀', 1),
  ('Tennis', '🎾', 1),
  ('Yoga', '🧘', 1),
  ('Weight training', '🏋️', 1),
  ('Boxing', '🥊', 1);
