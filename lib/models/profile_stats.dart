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

/// Points scored in one calendar month, for the six-month chart.
class MonthlyPoints {
  const MonthlyPoints({required this.month, required this.points});

  /// The first day of the month.
  final DateTime month;
  final int points;
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
    required this.currentStreakDays,
    required this.monthSessionCount,
    required this.monthPoints,
    required this.monthActiveDays,
    required this.monthDurationMin,
    required this.lastSixMonths,
    required this.bestWeekPoints,
    this.firstSessionDate,
  });

  static const monthsCharted = 6;

  factory ProfileStats.fromSessions(List<Session> sessions, DateTime today) {
    final dateOnlyToday = DateTime(today.year, today.month, today.day);
    final monthStart = DateTime(today.year, today.month);

    if (sessions.isEmpty) {
      return ProfileStats(
        sessionCount: 0,
        totalDurationMin: 0,
        totalPoints: 0,
        totalCaloriesBurned: 0,
        longestSessionMin: 0,
        sportBreakdown: const [],
        currentStreakDays: 0,
        monthSessionCount: 0,
        monthPoints: 0,
        monthActiveDays: 0,
        monthDurationMin: 0,
        lastSixMonths: _emptyMonths(monthStart),
        bestWeekPoints: 0,
      );
    }

    var totalDurationMin = 0;
    var totalPoints = 0;
    var totalCaloriesBurned = 0.0;
    var longestSessionMin = 0;
    var monthSessionCount = 0;
    var monthPoints = 0;
    var monthDurationMin = 0;
    DateTime? firstSessionDate;

    final tallies = <String, SportTally>{};
    final activeDays = <DateTime>{};
    final monthActiveDays = <DateTime>{};
    final pointsByMonth = <DateTime, int>{};
    final pointsByWeek = <DateTime, int>{};

    for (final session in sessions) {
      final date = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );

      totalDurationMin += session.durationMin;
      totalPoints += session.points;
      totalCaloriesBurned += session.caloriesBurned ?? 0;
      if (session.durationMin > longestSessionMin) {
        longestSessionMin = session.durationMin;
      }
      if (firstSessionDate == null || date.isBefore(firstSessionDate)) {
        firstSessionDate = date;
      }

      activeDays.add(date);

      if (!date.isBefore(monthStart)) {
        monthSessionCount += 1;
        monthPoints += session.points;
        monthDurationMin += session.durationMin;
        monthActiveDays.add(date);
      }

      final month = DateTime(date.year, date.month);
      pointsByMonth[month] = (pointsByMonth[month] ?? 0) + session.points;

      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      pointsByWeek[weekStart] = (pointsByWeek[weekStart] ?? 0) + session.points;

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
      currentStreakDays: _streakEndingAt(dateOnlyToday, activeDays),
      monthSessionCount: monthSessionCount,
      monthPoints: monthPoints,
      monthActiveDays: monthActiveDays.length,
      monthDurationMin: monthDurationMin,
      lastSixMonths: _chartMonths(monthStart, pointsByMonth),
      bestWeekPoints: pointsByWeek.values.fold(0, (a, b) => a > b ? a : b),
      firstSessionDate: firstSessionDate,
    );
  }

  /// Consecutive days up to today with at least one session.
  ///
  /// A day still in progress does not break the run: someone who trained
  /// yesterday and has not yet trained today keeps their streak until the day
  /// is out, which is how anyone counting would describe it.
  static int _streakEndingAt(DateTime today, Set<DateTime> activeDays) {
    var cursor = activeDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    if (!activeDays.contains(cursor)) return 0;

    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static List<MonthlyPoints> _chartMonths(
    DateTime currentMonth,
    Map<DateTime, int> pointsByMonth,
  ) {
    return [
      for (var back = monthsCharted - 1; back >= 0; back--)
        () {
          final month = DateTime(
            currentMonth.year,
            currentMonth.month - back,
          );
          return MonthlyPoints(
            month: month,
            points: pointsByMonth[month] ?? 0,
          );
        }(),
    ];
  }

  static List<MonthlyPoints> _emptyMonths(DateTime currentMonth) =>
      _chartMonths(currentMonth, const {});

  final int sessionCount;
  final int totalDurationMin;
  final int totalPoints;
  final double totalCaloriesBurned;
  final int longestSessionMin;
  final List<SportTally> sportBreakdown;

  /// Consecutive days trained, ending today or yesterday.
  final int currentStreakDays;

  final int monthSessionCount;
  final int monthPoints;
  final int monthActiveDays;
  final int monthDurationMin;

  /// Six entries, oldest first, the last being the current month.
  final List<MonthlyPoints> lastSixMonths;

  final int bestWeekPoints;
  final DateTime? firstSessionDate;

  bool get hasSessions => sessionCount > 0;

  /// Zero across real sessions means the calories provider never answered, not
  /// that nothing was burnt, so the screen shows a placeholder instead.
  bool get hasCaloriesData => totalCaloriesBurned > 0;

  int get averageDurationMin =>
      sessionCount == 0 ? 0 : (totalDurationMin / sessionCount).round();

  /// The tallest bar in the chart, so the others can be drawn as a share of it.
  int get bestMonthPoints =>
      lastSixMonths.fold(0, (best, m) => m.points > best ? m.points : best);

  /// The sport with the most time logged, which is a fairer "favourite" than
  /// the most frequent one: ten-minute warm-ups should not outrank long rides.
  SportTally? get favouriteSport =>
      sportBreakdown.isEmpty ? null : sportBreakdown.first;
}
