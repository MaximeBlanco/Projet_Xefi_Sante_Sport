import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/sport.dart';

void main() {
  group('Sport.fromJson', () {
    test('reads every column of the sports table', () {
      final sport = Sport.fromJson(<String, dynamic>{
        'id': 'sport-running',
        'name': 'Course à pied',
        'emoji': '🏃',
        'points_per_unit': 1,
        'wger_id': 42,
        'is_gps_trackable': true,
        'external_activity_name': 'running',
      });

      expect(sport.id, 'sport-running');
      expect(sport.name, 'Course à pied');
      expect(sport.emoji, '🏃');
      expect(sport.pointsPerUnit, 1);
      expect(sport.wgerId, 42);
      expect(sport.isGpsTrackable, isTrue);
      expect(sport.externalActivityName, 'running');
    });

    test('accepts integer columns serialized as strings', () {
      final sport = Sport.fromJson(<String, dynamic>{
        'id': 'sport-swimming',
        'name': 'Natation',
        'emoji': '🏊',
        'points_per_unit': '3',
        'wger_id': '7',
        'is_gps_trackable': false,
        'external_activity_name': 'swimming',
      });

      expect(sport.pointsPerUnit, 3);
      expect(sport.wgerId, 7);
    });

    test('falls back when the optional columns are null or absent', () {
      final sport = Sport.fromJson(<String, dynamic>{
        'id': 'sport-yoga',
        'name': 'Yoga',
        'emoji': '🧘',
        'points_per_unit': null,
        'wger_id': null,
        'external_activity_name': null,
      });

      expect(sport.pointsPerUnit, 1);
      expect(sport.wgerId, isNull);
      expect(sport.isGpsTrackable, isFalse);
      expect(sport.externalActivityName, isNull);
    });
  });
}
