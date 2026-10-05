/// Mirrors the column defaults in `profiles`, so a row that was selected
/// without these columns reads the way the database would have answered rather
/// than silently opening a switch its owner never touched.
const bool _sharesHistoryByDefault = true;
const bool _sharesLocationsByDefault = false;

/// What a member lets their accepted contacts see.
///
/// Two switches rather than one: a session says what somebody did, a route says
/// where they were and at what time. Bundling them would force a member to give
/// away the second to share the first.
enum SharingPreference {
  history(
    column: 'shares_history',
    label: 'Mon historique de séances',
    exposes:
        'Vos contacts voient vos séances : le sport, la durée et la dépense '
        'de chacune.',
  ),
  locations(
    column: 'shares_locations',
    label: 'Mes lieux et mes trajets',
    exposes:
        'Vos contacts voient où et quand vous vous entraînez, et le tracé de '
        'vos parcours.',
  );

  const SharingPreference({
    required this.column,
    required this.label,
    required this.exposes,
  });

  /// The `profiles` column carrying the preference. The access rules read it in
  /// the database, so this name is the whole contract.
  final String column;

  final String label;

  /// Says what opening the switch hands over, because naming the setting twice
  /// tells nobody that a route publishes where they live.
  final String exposes;
}

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.weightKg,
    this.teamId,
    this.avatarUrl,
    this.sharesHistory = _sharesHistoryByDefault,
    this.sharesLocations = _sharesLocationsByDefault,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      teamId: json['team_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      sharesHistory:
          json['shares_history'] as bool? ?? _sharesHistoryByDefault,
      sharesLocations:
          json['shares_locations'] as bool? ?? _sharesLocationsByDefault,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String name;
  final double? weightKg;
  final String? teamId;
  final String? avatarUrl;
  final bool sharesHistory;
  final bool sharesLocations;
  final DateTime createdAt;

  bool shares(SharingPreference preference) {
    return switch (preference) {
      SharingPreference.history => sharesHistory,
      SharingPreference.locations => sharesLocations,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weight_kg': weightKg,
      'team_id': teamId,
      'avatar_url': avatarUrl,
      SharingPreference.history.column: sharesHistory,
      SharingPreference.locations.column: sharesLocations,
    };
  }
}
