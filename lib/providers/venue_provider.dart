import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/venue_repository.dart';
import '../models/venue.dart';
import 'route_tracking_controller.dart';

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepository();
});

/// How long a venue list stays good enough to reuse.
///
/// Overpass allows a caller two slots and answers 429 beyond that. Dropping the
/// list every time the picker closes turns "open the sheet, close it, open it
/// again" into three queries, which is precisely what earns the 429 — and gyms
/// do not move between two openings of the same form.
const Duration venueCacheDuration = Duration(minutes: 5);

final nearbyVenuesProvider =
    FutureProvider.autoDispose<List<Venue>>((ref) async {
  final position = await ref.read(locationTrackerProvider).currentPosition();
  final venues = await ref.read(venueRepositoryProvider).findNearby(
        lat: position.lat,
        lng: position.lng,
      );

  // Only a successful list is worth holding on to: caching a failure would
  // make the retry button do nothing for five minutes.
  final link = ref.keepAlive();
  final expiry = Timer(venueCacheDuration, link.close);
  ref.onDispose(expiry.cancel);

  return venues;
});
