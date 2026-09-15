/// The kinds of place a session can happen in, as the app names them.
///
/// OpenStreetMap has far more tags than this, and its vocabulary is not ours:
/// the mapping below is the anticorruption layer, so a change in OSM tagging
/// touches one place and never reaches the database or the screens.
enum VenueKind {
  fitnessCentre('fitness_centre', 'Salle de sport', '🏋️'),
  sportsCentre('sports_centre', 'Complexe sportif', '🏟️'),
  sportsHall('sports_hall', 'Gymnase', '🤾'),
  stadium('stadium', 'Stade', '🏟️'),
  pitch('pitch', 'Terrain', '⚽'),
  swimmingPool('swimming_pool', 'Piscine', '🏊'),
  park('park', 'Parc', '🌳'),
  track('track', "Piste d'athlétisme", '🏃'),
  other('other', 'Autre lieu', '📍');

  const VenueKind(this.storageValue, this.label, this.emoji);

  /// What goes in `sessions.venue_kind`. Kept separate from [name] so renaming
  /// a Dart constant never silently orphans the rows already stored.
  final String storageValue;

  final String label;
  final String emoji;

  static VenueKind? fromStorage(String? value) {
    if (value == null) return null;
    for (final kind in values) {
      if (kind.storageValue == value) return kind;
    }
    return other;
  }

  /// OSM describes a place across several tags, and the useful one differs by
  /// place: `leisure` covers most, `building` catches indoor halls.
  static VenueKind fromOsmTags(Map<String, dynamic> tags) {
    final leisure = tags['leisure'] as String?;
    final building = tags['building'] as String?;
    final sport = tags['sport'] as String?;

    if (leisure == 'fitness_centre') return VenueKind.fitnessCentre;
    if (leisure == 'sports_centre') return VenueKind.sportsCentre;
    if (leisure == 'stadium') return VenueKind.stadium;
    if (leisure == 'swimming_pool') return VenueKind.swimmingPool;
    if (leisure == 'park' || leisure == 'garden') return VenueKind.park;
    if (leisure == 'track') return VenueKind.track;
    if (leisure == 'sports_hall') return VenueKind.sportsHall;
    if (leisure == 'pitch') {
      return sport == 'swimming' ? VenueKind.swimmingPool : VenueKind.pitch;
    }
    if (building == 'sports_hall') return VenueKind.sportsHall;

    return VenueKind.other;
  }

  /// The Overpass filters that produce these kinds. Declared next to the
  /// mapping so a kind can never be searched for without being recognised.
  static const List<String> overpassSelectors = [
    '["leisure"="fitness_centre"]',
    '["leisure"="sports_centre"]',
    '["leisure"="sports_hall"]',
    '["leisure"="stadium"]',
    '["leisure"="pitch"]',
    '["leisure"="track"]',
    '["leisure"="swimming_pool"]',
    '["leisure"="park"]',
    '["building"="sports_hall"]',
  ];
}
