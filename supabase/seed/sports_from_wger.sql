-- Placeholder seed so the app has sports to select from during early dev.
-- Will be replaced by the output of tool/sync_sports_from_wger.dart once
-- that script exists (see CAHIER_DES_CHARGES.md section 4).
insert into sports (name, emoji, points_per_unit, is_gps_trackable) values
  ('Course à pied', '🏃', 1, true),
  ('Vélo', '🚴', 1, true),
  ('Marche', '🚶', 1, true),
  ('Musculation', '🏋️', 1, false),
  ('Natation', '🏊', 1, false),
  ('Football', '⚽', 1, false),
  ('Yoga', '🧘', 1, false);
