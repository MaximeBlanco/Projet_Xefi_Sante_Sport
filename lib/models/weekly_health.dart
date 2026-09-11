import 'session.dart';

/// The health half of the app, next to the competitive half.
///
/// The leaderboard rewards volume: one long session outranks five short ones.
/// Public health guidance works the other way round — the World Health
/// Organization recommends 150 to 300 minutes of moderate aerobic activity per
/// week for adults, spread across the week rather than concentrated. So this
/// tracks two things the ranking cannot express: how much of that weekly floor
/// is done, and on how many separate days.
class WeeklyHealth {
  const WeeklyHealth({
    required this.weekStart,
    required this.activeMinutes,
    required this.minutesPerWeekday,
  });

  /// The lower bound of the WHO recommendation for adults. Deliberately the
  /// floor and not the 300-minute upper bound: a target nobody reaches stops
  /// being a target.
  static const goalMinutes = 150;

  static const daysPerWeek = DateTime.daysPerWeek;

  factory WeeklyHealth.fromSessions(List<Session> sessions, DateTime today) {
    final weekStart = startOfWeekFor(today);
    final weekEnd = weekStart.add(const Duration(days: daysPerWeek));

    final minutesPerWeekday = List<int>.filled(daysPerWeek, 0);
    var activeMinutes = 0;

    for (final session in sessions) {
      final date = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      if (date.isBefore(weekStart) || !date.isBefore(weekEnd)) continue;

      minutesPerWeekday[date.weekday - 1] += session.durationMin;
      activeMinutes += session.durationMin;
    }

    return WeeklyHealth(
      weekStart: weekStart,
      activeMinutes: activeMinutes,
      minutesPerWeekday: minutesPerWeekday,
    );
  }

  /// Weeks run Monday to Sunday, which is both the French convention and how
  /// the WHO expresses the recommendation.
  static DateTime startOfWeekFor(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
  }

  final DateTime weekStart;
  final int activeMinutes;

  /// Seven entries, Monday first.
  final List<int> minutesPerWeekday;

  double get progress =>
      (activeMinutes / goalMinutes).clamp(0.0, 1.0).toDouble();

  bool get isGoalReached => activeMinutes >= goalMinutes;

  int get remainingMinutes => isGoalReached ? 0 : goalMinutes - activeMinutes;

  int get activeDayCount =>
      minutesPerWeekday.where((minutes) => minutes > 0).length;

  bool isDayActive(int weekdayIndex) => minutesPerWeekday[weekdayIndex] > 0;

  /// Spreading the same total over more days is what the guidance actually
  /// asks for, so this is reported separately rather than folded into a single
  /// score that would hide which of the two is lacking.
  bool get isSpreadAcrossWeek => activeDayCount >= 3;
}
