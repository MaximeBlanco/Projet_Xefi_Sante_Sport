import '../core/domain/venue_kind.dart';

/// A place a session happened in.
///
/// [osmId] null means the user typed the name instead of picking it off the
/// map, which is the only way to record a place OpenStreetMap does not know.
class Venue {
  const Venue({
    required this.name,
    this.osmId,
    this.kind,
    this.distanceM,
  });

  factory Venue.typedByUser(String name) => Venue(name: name.trim());

  final String name;
  final String? osmId;
  final VenueKind? kind;
  final double? distanceM;

  bool get isFromMap => osmId != null;

  String get label => kind == null ? name : '${kind!.emoji}  $name';

  static Venue? fromSessionJson(Map<String, dynamic> json) {
    final name = json['venue_name'] as String?;
    if (name == null || name.trim().isEmpty) return null;
    return Venue(
      name: name,
      osmId: json['venue_osm_id'] as String?,
      kind: VenueKind.fromStorage(json['venue_kind'] as String?),
    );
  }

  Map<String, dynamic> toSessionColumns() {
    return {
      'venue_name': name,
      'venue_osm_id': osmId,
      'venue_kind': kind?.storageValue,
    };
  }
}
