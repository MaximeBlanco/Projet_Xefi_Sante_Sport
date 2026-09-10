import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/profile.dart';

void main() {
  group('Profile.fromJson', () {
    test('reads the profile columns', () {
      final profile = Profile.fromJson(<String, dynamic>{
        'id': 'user-1',
        'name': 'Alice',
        'weight_kg': 68.5,
        'team_id': null,
        'created_at': '2026-01-01T08:00:00.000Z',
      });

      expect(profile.id, 'user-1');
      expect(profile.name, 'Alice');
      expect(profile.weightKg, 68.5);
      expect(profile.teamId, isNull);
      expect(profile.createdAt, DateTime.parse('2026-01-01T08:00:00.000Z'));
    });

    test('keeps a missing weight null so the calories call can be skipped', () {
      final profile = Profile.fromJson(<String, dynamic>{
        'id': 'user-2',
        'name': 'Bruno',
        'weight_kg': null,
        'created_at': '2026-01-02T08:00:00.000Z',
      });

      expect(profile.weightKg, isNull);
    });

    test('reads an integer weight as a double', () {
      final profile = Profile.fromJson(<String, dynamic>{
        'id': 'user-3',
        'name': 'Chloé',
        'weight_kg': 70,
        'created_at': '2026-01-03T08:00:00.000Z',
      });

      expect(profile.weightKg, 70.0);
    });
  });
}
