import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/domain/route_metrics.dart';
import '../core/domain/venue_kind.dart';
import '../models/venue.dart';

/// Raised when nearby venues cannot be listed. The message is written for the
/// user, so the screen shows it as-is instead of inventing its own wording.
class VenueLookupException implements Exception {
  const VenueLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads sports venues from OpenStreetMap through the Overpass API.
///
/// This class owns the whole outgoing call — endpoint, timeout, query shape and
/// the translation of OSM's vocabulary into [Venue]. Nothing above it knows that
/// OpenStreetMap exists, so swapping the provider touches this file alone.
class VenueRepository {
  VenueRepository({http.Client? client, Uri? endpoint})
      : _client = client ?? http.Client(),
        _endpoint = endpoint ?? Uri.parse(_defaultEndpoint);

  static const String _defaultEndpoint =
      'https://overpass-api.de/api/interpreter';

  /// Overpass is a donated public service under a fair-use policy. A tight
  /// server-side timeout and a capped result set keep a phone from asking it
  /// for a region-sized answer.
  static const Duration requestTimeout = Duration(seconds: 20);
  static const int overpassTimeoutSeconds = 15;
  static const int maxResults = 40;
  static const int searchRadiusMeters = 2000;
  static const int tooManyRequests = 429;

  /// OpenStreetMap's usage policy requires a User-Agent that identifies the
  /// application, and Overpass enforces it: the default `Dart/3.x (dart:io)`
  /// is answered with 406. Browsers refuse to let a page set this header and
  /// send their own, which is why the web build worked while Android did not.
  static const String userAgent =
      'XefiSport/1.0 (projet scolaire XEFI; https://github.com/MaximeBlanco/Projet_Xefi_Sante_Sport)';

  final http.Client _client;
  final Uri _endpoint;

  Future<List<Venue>> findNearby({
    required double lat,
    required double lng,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: const {'User-Agent': userAgent},
            body: {'data': _query(lat: lat, lng: lng)},
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const VenueLookupException(
        'La recherche de lieux a mis trop de temps. Réessayez, ou saisissez '
        'le lieu vous-même.',
      );
    } on Exception {
      throw const VenueLookupException(
        'Impossible de joindre le service de lieux. Vérifiez votre connexion, '
        'ou saisissez le lieu vous-même.',
      );
    }

    // 429 is Overpass saying the caller has used its share of a donated
    // service, and it is worth its own wording: waiting fixes it, whereas
    // "unavailable" invites the user to hammer the retry button.
    if (response.statusCode == tooManyRequests) {
      throw const VenueLookupException(
        'Trop de recherches de lieux coup sur coup. Patientez une minute, ou '
        'saisissez le lieu vous-même.',
      );
    }

    if (response.statusCode != 200) {
      throw const VenueLookupException(
        'Le service de lieux est momentanément indisponible. Saisissez le lieu '
        'vous-même.',
      );
    }

    return _parse(response.body, fromLat: lat, fromLng: lng);
  }

  String _query({required double lat, required double lng}) {
    final around = 'around:$searchRadiusMeters,$lat,$lng';
    final clauses = VenueKind.overpassSelectors
        .map((selector) => '  nwr$selector($around);')
        .join('\n');

    return '[out:json][timeout:$overpassTimeoutSeconds];\n'
        '(\n$clauses\n);\n'
        'out center tags $maxResults;';
  }

  /// Unnamed places are dropped: "(sans nom)" in a list of gyms helps nobody,
  /// and a session labelled with it would be worse than one with no venue.
  List<Venue> _parse(
    String body, {
    required double fromLat,
    required double fromLng,
  }) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];

    final elements = decoded['elements'];
    if (elements is! List) return const [];

    final venues = <Venue>[];
    final seenNames = <String>{};

    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;

      final tags = element['tags'];
      if (tags is! Map<String, dynamic>) continue;

      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      final coordinates = _coordinatesOf(element);
      if (coordinates == null) continue;

      // OSM often maps one venue as several objects (a building and its
      // grounds). The user does not care which, and two identical rows read
      // as a bug.
      if (!seenNames.add(name.toLowerCase())) continue;

      venues.add(
        Venue(
          name: name,
          osmId: '${element['type']}/${element['id']}',
          kind: VenueKind.fromOsmTags(tags),
          distanceM: RouteMetrics.metersBetween(
            fromLat: fromLat,
            fromLng: fromLng,
            toLat: coordinates.$1,
            toLng: coordinates.$2,
          ),
        ),
      );
    }

    venues.sort((a, b) => (a.distanceM ?? 0).compareTo(b.distanceM ?? 0));
    return venues;
  }

  /// A node carries its own position; a way or relation only has one because
  /// the query asked Overpass for `out center`.
  (double, double)? _coordinatesOf(Map<String, dynamic> element) {
    final lat = element['lat'];
    final lng = element['lon'];
    if (lat is num && lng is num) {
      return (lat.toDouble(), lng.toDouble());
    }

    final center = element['center'];
    if (center is Map<String, dynamic>) {
      final centerLat = center['lat'];
      final centerLng = center['lon'];
      if (centerLat is num && centerLng is num) {
        return (centerLat.toDouble(), centerLng.toDouble());
      }
    }

    return null;
  }
}
