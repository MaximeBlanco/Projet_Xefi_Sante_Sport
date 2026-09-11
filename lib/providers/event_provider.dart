import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/event_repository.dart';
import '../models/app_event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(supabaseClientProvider));
});

/// What is coming up. Its own provider rather than part of the home summary:
/// the events are the same for everyone, and a slow read of them must not hold
/// up the score.
final upcomingEventsProvider = FutureProvider<List<AppEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).fetchUpcoming();
});
