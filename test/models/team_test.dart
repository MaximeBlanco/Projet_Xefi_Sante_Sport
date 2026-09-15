import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/team.dart';

/// Postgres `integer` is signed 32-bit.
const _int4Min = -2147483648;
const _int4Max = 2147483647;

void main() {
  group('the colour written to the database', () {
    test('fits in the integer column for every palette entry', () {
      // An ARGB colour is unsigned, and every opaque one is above the signed
      // maximum: sending it raw makes Postgres refuse the insert outright with
      // "integer out of range", which is exactly how team creation first
      // failed.
      for (final colour in Team.palette) {
        final stored = Team.toDatabaseValue(colour);
        expect(
          stored,
          inInclusiveRange(_int4Min, _int4Max),
          reason: 'colour $colour would not fit the column',
        );
      }
    });

    test('survives the round trip back to the same colour', () {
      for (final colour in Team.palette) {
        final team = Team.fromJson(<String, dynamic>{
          'id': 'team-1',
          'name': 'Les Rouges',
          'color_value': Team.toDatabaseValue(colour),
        });

        expect(team.colour.toARGB32(), colour);
      }
    });

    test('leaves a value already in range alone', () {
      expect(Team.toDatabaseValue(1), 1);
      expect(Team.toDatabaseValue(-5), -5);
    });
  });

  group('Team.fromJson', () {
    test('reads a row as the database stores it', () {
      final team = Team.fromJson(<String, dynamic>{
        'id': 'team-1',
        'name': 'Agence Lyon',
        'color_value': -1962752,
      });

      expect(team.id, 'team-1');
      expect(team.name, 'Agence Lyon');
      // A negative column value is the signed form of an opaque colour, and it
      // converts straight back to the value the column holds.
      expect(Team.toDatabaseValue(team.colour.toARGB32()), -1962752);
      expect(team.colour.a, 1.0);
    });

    test('falls back to the primary rather than throwing on a missing colour',
        () {
      final team = Team.fromJson(<String, dynamic>{
        'id': 'team-1',
        'name': 'Sans couleur',
        'color_value': null,
      });

      expect(team.colour.toARGB32(), 0xFFE10600);
    });
  });
}
