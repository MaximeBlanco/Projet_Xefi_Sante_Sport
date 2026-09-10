import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/session.dart';

Map<String, dynamic> buildSessionRow({
  Object? caloriesBurned = 380.5,
  Object? durationMin = 45,
  Object? points = 45,
  Object? embeddedSport,
}) {
  return <String, dynamic>{
    'id': 'session-1',
    'user_id': 'user-1',
    'sport_id': 'sport-running',
    'date': '2026-03-14',
    'duration_min': durationMin,
    'points': points,
    'calories_burned': caloriesBurned,
    'distance_km': null,
    'elevation_gain_m': null,
    'route': null,
    'created_at': '2026-03-14T18:30:00.000Z',
    'sports': ?embeddedSport,
  };
}

void main() {
  group('Session.fromJson', () {
    test('reads a row selected without its sport', () {
      final session = Session.fromJson(buildSessionRow());

      expect(session.id, 'session-1');
      expect(session.userId, 'user-1');
      expect(session.sportId, 'sport-running');
      expect(session.date, DateTime(2026, 3, 14));
      expect(session.durationMin, 45);
      expect(session.points, 45);
      expect(session.caloriesBurned, 380.5);
      expect(session.distanceKm, isNull);
      expect(session.route, isNull);
      expect(session.sport, isNull);
    });

    test('accepts numeric columns serialized as strings', () {
      final session = Session.fromJson(
        buildSessionRow(
          durationMin: '45',
          points: '45',
          caloriesBurned: '380.5',
        ),
      );

      expect(session.durationMin, 45);
      expect(session.points, 45);
      expect(session.caloriesBurned, 380.5);
    });

    test('keeps calories null when the external API could not answer', () {
      final session = Session.fromJson(buildSessionRow(caloriesBurned: null));

      expect(session.caloriesBurned, isNull);
    });

    test('reads the sport embedded by the "*, sports(*)" select', () {
      final session = Session.fromJson(
        buildSessionRow(
          embeddedSport: <String, dynamic>{
            'id': 'sport-running',
            'name': 'Course à pied',
            'emoji': '🏃',
            'points_per_unit': 1,
            'wger_id': null,
            'is_gps_trackable': true,
            'external_activity_name': 'running',
          },
        ),
      );

      expect(session.sport, isNotNull);
      expect(session.sport!.name, 'Course à pied');
      expect(session.sport!.emoji, '🏃');
      expect(session.sport!.externalActivityName, 'running');
    });
  });
}
