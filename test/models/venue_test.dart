import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/venue_kind.dart';
import 'package:monapp/models/venue.dart';

void main() {
  group('Venue', () {
    test('reads a venue off a session row', () {
      final venue = Venue.fromSessionJson({
        'venue_name': 'Basic Fit',
        'venue_osm_id': 'node/1',
        'venue_kind': 'fitness_centre',
      });

      expect(venue!.name, 'Basic Fit');
      expect(venue.kind, VenueKind.fitnessCentre);
      expect(venue.isFromMap, isTrue);
    });

    test('treats a session without a venue as having none', () {
      expect(Venue.fromSessionJson({'venue_name': null}), isNull);
      expect(Venue.fromSessionJson({'venue_name': '   '}), isNull);
    });

    // A hand-typed venue is the "somewhere else" case. It has no OSM id, and
    // that absence is what the rest of the app reads.
    test('marks a hand-typed venue as not coming from the map', () {
      final venue = Venue.typedByUser('  Chez moi  ');

      expect(venue.name, 'Chez moi');
      expect(venue.isFromMap, isFalse);
      expect(venue.toSessionColumns()['venue_osm_id'], isNull);
      expect(venue.toSessionColumns()['venue_kind'], isNull);
    });

    // Storage values are decoupled from the Dart constant names so renaming a
    // constant cannot orphan rows already written.
    test('falls back to "other" for a kind it does not know', () {
      expect(VenueKind.fromStorage('velodrome'), VenueKind.other);
      expect(VenueKind.fromStorage(null), isNull);
    });

    test('recognises a swimming pitch as a pool, not a field', () {
      final kind = VenueKind.fromOsmTags({
        'leisure': 'pitch',
        'sport': 'swimming',
      });

      expect(kind, VenueKind.swimmingPool);
    });

    test('every searched selector maps to a kind that is not "other"', () {
      for (final selector in VenueKind.overpassSelectors) {
        final match = RegExp(r'\["(\w+)"="(\w+)"\]').firstMatch(selector)!;
        final kind = VenueKind.fromOsmTags({match.group(1)!: match.group(2)!});

        expect(
          kind,
          isNot(VenueKind.other),
          reason: 'searching for $selector yields an unlabelled venue',
        );
      }
    });
  });
}
