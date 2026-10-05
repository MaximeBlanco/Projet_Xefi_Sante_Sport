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

    test('reads both sharing switches', () {
      final profile = Profile.fromJson(<String, dynamic>{
        'id': 'user-4',
        'name': 'Inès',
        'shares_history': false,
        'shares_locations': true,
        'created_at': '2026-01-04T08:00:00.000Z',
      });

      expect(profile.sharesHistory, isFalse);
      expect(profile.sharesLocations, isTrue);
      expect(profile.shares(SharingPreference.history), isFalse);
      expect(profile.shares(SharingPreference.locations), isTrue);
    });

    // A row read without the columns must not look like a member who opened
    // their locations: the fallback is the one the database would have applied.
    test('falls back to the column defaults when the columns are absent', () {
      final profile = Profile.fromJson(<String, dynamic>{
        'id': 'user-5',
        'name': 'Théo',
        'created_at': '2026-01-05T08:00:00.000Z',
      });

      expect(profile.sharesHistory, isTrue);
      expect(profile.sharesLocations, isFalse);
    });
  });

  group('Profile.toJson', () {
    test('writes both sharing switches under their column names', () {
      final json = Profile(
        id: 'user-6',
        name: 'Camille',
        createdAt: DateTime(2026),
        sharesHistory: false,
        sharesLocations: true,
      ).toJson();

      expect(json['shares_history'], isFalse);
      expect(json['shares_locations'], isTrue);
    });
  });
}
