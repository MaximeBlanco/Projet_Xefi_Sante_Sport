import 'session.dart';
import 'sport.dart';

/// How much of one sport a user has done, for the profile breakdown.
class SportTally {
  const SportTally({
    required this.sportId,
    required this.sessionCount,
    required this.totalDurationMin,
    this.sport,
  });

  final String sportId;
  final int sessionCount;
  final int totalDurationMin;

  /// Absent when the session rows were fetched without their embedded sport.
  final Sport? sport;

  String get label => sport?.name ?? 'Sport inconnu';

  String get emoji => sport?.emoji ?? '🏅';
}

/// The personal numbers on the profile screen, derived entirely from the
/// user's own sessions.
///
/// This is deliberately separate from the ranking view: the leaderboard answers
/// "how do I compare", these answer "what have I actually done", and only the
/// second needs a per-sport breakdown that would be wasteful to compute for
/// every user at once.
class ProfileStats {
  const ProfileStats({
    required this.sessionCount,
    required this.totalDurationMin,
    required this.totalPoints,
    required this.totalCaloriesBurned,
    required this.longestSessionMin,
    required this.sportBreakdown,
    this.firstSessionDate,
  });

  factory ProfileStats.fromSessions(List<Session> sessions) {
    if (sessions.isEmpty) {
      return const ProfileStats(
        sessionCount: 0,
        totalDurationMin: 0,
        totalPoints: 0,
        totalCaloriesBurned: 0,
        longestSessionMin: 0,
        sportBreakdown: [],
      );
    }

    var totalDurationMin = 0;
    var totalPoints = 0;
    var totalCaloriesBurned = 0.0;
    var longestSessionMin = 0;
    DateTime? firstSessionDate;
    final tallies = <String, SportTally>{};

    for (final session in sessions) {
      totalDurationMin += session.durationMin;
      totalPoints += session.points;
      totalCaloriesBurned += session.caloriesBurned ?? 0;
      if (session.durationMin > longestSessionMin) {
        longestSessionMin = session.durationMin;
      }
      if (firstSessionDate == null || session.date.isBefore(firstSessionDate)) {
        firstSessionDate = session.date;
      }

      final existing = tallies[session.sportId];
      tallies[session.sportId] = SportTally(
        sportId: session.sportId,
        sessionCount: (existing?.sessionCount ?? 0) + 1,
        totalDurationMin:
            (existing?.totalDurationMin ?? 0) + session.durationMin,
        sport: session.sport ?? existing?.sport,
      );
    }

    final breakdown = tallies.values.toList()
      ..sort((a, b) {
        final byDuration = b.totalDurationMin.compareTo(a.totalDurationMin);
        return byDuration != 0 ? byDuration : a.label.compareTo(b.label);
      });

    return ProfileStats(
      sessionCount: sessions.length,
      totalDurationMin: totalDurationMin,
      totalPoints: totalPoints,
      totalCaloriesBurned: totalCaloriesBurned,
      longestSessionMin: longestSessionMin,
      sportBreakdown: breakdown,
      firstSessionDate: firstSessionDate,
    );
  }

  final int sessionCount;
  final int totalDurationMin;
  final int totalPoints;
  final double totalCaloriesBurned;
  final int longestSessionMin;
  final List<SportTally> sportBreakdown;
  final DateTime? firstSessionDate;

  bool get hasSessions => sessionCount > 0;

  /// Zero across real sessions means the calories provider never answered, not
  /// that nothing was burnt, so the screen shows a placeholder instead.
  bool get hasCaloriesData => totalCaloriesBurned > 0;

  int get averageDurationMin =>
      sessionCount == 0 ? 0 : (totalDurationMin / sessionCount).round();

  /// The sport with the most time logged, which is a fairer "favourite" than
  /// the most frequent one: ten-minute warm-ups should not outrank long rides.
  SportTally? get favouriteSport =>
      sportBreakdown.isEmpty ? null : sportBreakdown.first;
}
