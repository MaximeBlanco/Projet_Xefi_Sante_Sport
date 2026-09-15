import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monapp/core/domain/venue_kind.dart';
import 'package:monapp/data/venue_repository.dart';

const double _lyonLat = 45.7578;
const double _lyonLng = 4.8320;

String _overpassBody(List<Map<String, dynamic>> elements) {
  return jsonEncode({'elements': elements});
}

Map<String, dynamic> _node({
  required int id,
  required String name,
  double lat = _lyonLat,
  double lng = _lyonLng,
  Map<String, String> tags = const {'leisure': 'fitness_centre'},
}) {
  return {
    'type': 'node',
    'id': id,
    'lat': lat,
    'lon': lng,
    'tags': {'name': name, ...tags},
  };
}

VenueRepository _repositoryReturning(String body, {int statusCode = 200}) {
  return VenueRepository(
    endpoint: Uri.parse('https://overpass.test/api'),
    client: MockClient((_) async => http.Response(body, statusCode)),
  );
}

void main() {
  group('VenueRepository', () {
    // Regression: without this header Overpass answers 406, which only showed
    // on Android — a browser sends its own User-Agent and forbids overriding
    // it, so the web build passed while the phone silently found no venue.
    test('identifies the app to Overpass, as the OSM policy requires',
        () async {
      String? sentUserAgent;
      final repository = VenueRepository(
        endpoint: Uri.parse('https://overpass.test/api'),
        client: MockClient((request) async {
          sentUserAgent = request.headers['user-agent'];
          return http.Response(_overpassBody([]), 200);
        }),
      );

      await repository.findNearby(lat: _lyonLat, lng: _lyonLng);

      expect(sentUserAgent, isNotNull);
      expect(sentUserAgent, contains('XefiSport'));
      expect(sentUserAgent, isNot(contains('Dart/')));
    });

    test('maps OSM tags onto the app\'s own vocabulary', () async {
      final repository = _repositoryReturning(
        _overpassBody([
          _node(id: 1, name: 'Basic Fit'),
          _node(id: 2, name: 'Parc de la Tête d\'Or',
              tags: {'leisure': 'park'}),
          _node(id: 3, name: 'Stade de Gerland',
              tags: {'leisure': 'stadium'}),
        ]),
      );

      final venues = await repository.findNearby(lat: _lyonLat, lng: _lyonLng);

      expect(venues.map((venue) => venue.kind), [
        VenueKind.fitnessCentre,
        VenueKind.park,
        VenueKind.stadium,
      ]);
    });

    // A venue with no name would show as a blank row, and a session labelled
    // with it would be worse than one with no venue at all.
    test('drops places OpenStreetMap has not named', () async {
      final repository = _repositoryReturning(
        _overpassBody([
          {
            'type': 'node',
            'id': 1,
            'lat': _lyonLat,
            'lon': _lyonLng,
            'tags': {'leisure': 'pitch'},
          },
          _node(id: 2, name: 'Halle Tony Garnier'),
        ]),
      );

      final venues = await repository.findNearby(lat: _lyonLat, lng: _lyonLng);

      expect(venues, hasLength(1));
      expect(venues.single.name, 'Halle Tony Garnier');
    });

    // OSM often maps one place twice, as a building and as its grounds. Two
    // identical rows in the picker read as a bug.
    test('keeps one entry when the same name is mapped twice', () async {
      final repository = _repositoryReturning(
        _overpassBody([
          _node(id: 1, name: 'Keep Cool'),
          _node(id: 2, name: 'keep cool'),
        ]),
      );

      final venues = await repository.findNearby(lat: _lyonLat, lng: _lyonLng);

      expect(venues, hasLength(1));
    });

    test('puts the closest venue first', () async {
      final repository = _repositoryReturning(
        _overpassBody([
          _node(id: 1, name: 'Loin', lat: _lyonLat + 0.01),
          _node(id: 2, name: 'Proche', lat: _lyonLat + 0.001),
        ]),
      );

      final venues = await repository.findNearby(lat: _lyonLat, lng: _lyonLng);

      expect(venues.map((venue) => venue.name), ['Proche', 'Loin']);
      expect(venues.first.distanceM, lessThan(venues.last.distanceM!));
    });

    // A way or a relation has no lat/lon of its own; the query asks Overpass
    // for `out center`, and dropping that branch would hide every gym mapped
    // as a building rather than as a point.
    test('reads the centre of a venue mapped as an area', () async {
      final repository = _repositoryReturning(
        _overpassBody([
          {
            'type': 'way',
            'id': 42,
            'center': {'lat': _lyonLat, 'lon': _lyonLng},
            'tags': {'name': 'Gymnase Bellecour', 'leisure': 'sports_hall'},
          },
        ]),
      );

      final venues = await repository.findNearby(lat: _lyonLat, lng: _lyonLng);

      expect(venues.single.osmId, 'way/42');
      expect(venues.single.kind, VenueKind.sportsHall);
    });

    // Overpass answers 429 when a caller has used its share of a donated
    // service. Telling that user the service is "unavailable" invites them to
    // hammer the retry button, which is the one thing that keeps it 429.
    test('tells the user to wait when Overpass rate-limits the app', () async {
      final repository = _repositoryReturning('rate limited', statusCode: 429);

      await expectLater(
        repository.findNearby(lat: _lyonLat, lng: _lyonLng),
        throwsA(
          isA<VenueLookupException>().having(
            (error) => error.message,
            'message',
            contains('Patientez'),
          ),
        ),
      );
    });

    test('reports a provider outage in words a user can act on', () async {
      final repository = _repositoryReturning('gateway timeout', statusCode: 504);

      await expectLater(
        repository.findNearby(lat: _lyonLat, lng: _lyonLng),
        throwsA(
          isA<VenueLookupException>().having(
            (error) => error.message,
            'message',
            contains('Saisissez le lieu'),
          ),
        ),
      );
    });

    test('turns a network failure into a message, never a raw exception',
        () async {
      final repository = VenueRepository(
        endpoint: Uri.parse('https://overpass.test/api'),
        client: MockClient((_) async => throw const SocketFailure()),
      );

      await expectLater(
        repository.findNearby(lat: _lyonLat, lng: _lyonLng),
        throwsA(isA<VenueLookupException>()),
      );
    });

    test('survives a body that is not the shape Overpass promises', () async {
      final repository = _repositoryReturning(jsonEncode({'nope': true}));

      expect(await repository.findNearby(lat: _lyonLat, lng: _lyonLng), isEmpty);
    });
  });
}

class SocketFailure implements Exception {
  const SocketFailure();
}
