import '../../models/session.dart';

/// The window the profile statistics are computed over.
///
/// Calendar periods rather than rolling windows: "cette semaine" resets on
/// Monday the way people talk about their week, so a Monday morning shows a
/// fresh slate instead of dragging in last Tuesday's ride.
enum StatsPeriod {
  week('Semaine'),
  month('Mois'),
  allTime('Tout');

  const StatsPeriod(this.label);

  final String label;

  /// French text for an empty period, so each option explains its own silence.
  String get emptyMessage => switch (this) {
        StatsPeriod.week => 'Aucune séance cette semaine.',
        StatsPeriod.month => 'Aucune séance ce mois-ci.',
        StatsPeriod.allTime =>
          'Vos statistiques apparaîtront dès votre première séance.',
      };

  /// Inclusive first day of the period, or null when it has no start.
  DateTime? startOf(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      // DateTime.weekday is 1 for Monday, so this lands on the Monday of the
      // week that contains [now].
      StatsPeriod.week => today.subtract(Duration(days: today.weekday - 1)),
      StatsPeriod.month => DateTime(now.year, now.month),
      StatsPeriod.allTime => null,
    };
  }

  bool includes(DateTime date, DateTime now) {
    final start = startOf(now);
    if (start == null) return true;
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start);
  }

  List<Session> filter(List<Session> sessions, {DateTime? now}) {
    if (this == StatsPeriod.allTime) return sessions;
    final reference = now ?? DateTime.now();
    return [
      for (final session in sessions)
        if (includes(session.date, reference)) session,
    ];
  }
}
