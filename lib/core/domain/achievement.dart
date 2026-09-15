import '../../models/profile_stats.dart';

/// What a badge measures.
///
/// The family is what lets one small table of definitions serve every badge:
/// the figure a badge is judged on is read once per family rather than being
/// carried as a closure per badge, which keeps the catalogue a plain constant
/// list that can be read top to bottom.
enum AchievementMetric {
  /// Sessions logged, ever.
  sessions,

  /// Points banked, ever. Points equal minutes of sport.
  points,

  /// Consecutive days trained, as the streak stands today.
  streak,

  /// How many different sports have been logged at least once.
  variety,

  /// The longest single session, in minutes.
  longestSession,
}

/// One badge, and what it takes to earn it.
///
/// Badges are derived from the sessions a user has, never stored: a figure that
/// is recomputed cannot drift away from the history it describes, and nothing
/// has to be backfilled when the catalogue grows. The cost is that a badge
/// could be lost again if its metric can fall, which is why the only falling
/// metric here, the streak, is worded as a run rather than as a trophy.
class Achievement {
  const Achievement({
    required this.id,
    required this.emoji,
    required this.label,
    required this.description,
    required this.metric,
    required this.target,
  });

  final String id;
  final String emoji;
  final String label;
  final String description;
  final AchievementMetric metric;
  final int target;
}

/// A badge together with where its owner stands on it.
class AchievementProgress {
  const AchievementProgress({required this.achievement, required this.value});

  final Achievement achievement;

  /// The figure the badge is judged on, as it stands now.
  final int value;

  bool get isEarned => value >= achievement.target;

  /// How far along, between 0 and 1. Earned badges sit at 1.
  double get progress =>
      achievement.target <= 0 ? 1 : (value / achievement.target).clamp(0.0, 1.0);

  /// What is left to do, zero once earned.
  int get remaining {
    final left = achievement.target - value;
    return left < 0 ? 0 : left;
  }
}

abstract final class Achievements {
  /// The catalogue, in the order a profile should read it within each family.
  static const all = <Achievement>[
    Achievement(
      id: 'first-session',
      emoji: '🎬',
      label: 'Première séance',
      description: 'Enregistrer une séance',
      metric: AchievementMetric.sessions,
      target: 1,
    ),
    Achievement(
      id: 'ten-sessions',
      emoji: '🏃',
      label: 'Lancé',
      description: '10 séances enregistrées',
      metric: AchievementMetric.sessions,
      target: 10,
    ),
    Achievement(
      id: 'fifty-sessions',
      emoji: '💪',
      label: 'Assidu',
      description: '50 séances enregistrées',
      metric: AchievementMetric.sessions,
      target: 50,
    ),
    Achievement(
      id: 'hundred-sessions',
      emoji: '🏆',
      label: 'Centurion',
      description: '100 séances enregistrées',
      metric: AchievementMetric.sessions,
      target: 100,
    ),
    Achievement(
      id: 'five-hundred-points',
      emoji: '⭐',
      label: 'Niveau 2',
      description: '500 points, soit plus de 8 h de sport',
      metric: AchievementMetric.points,
      target: 500,
    ),
    Achievement(
      id: 'two-thousand-points',
      emoji: '🌟',
      label: 'Habitué',
      description: '2 000 points cumulés',
      metric: AchievementMetric.points,
      target: 2000,
    ),
    Achievement(
      id: 'five-thousand-points',
      emoji: '💫',
      label: 'Pilier',
      description: '5 000 points cumulés',
      metric: AchievementMetric.points,
      target: 5000,
    ),
    Achievement(
      id: 'three-day-streak',
      emoji: '🔥',
      label: 'Sur la lancée',
      description: "3 jours de sport d'affilée",
      metric: AchievementMetric.streak,
      target: 3,
    ),
    Achievement(
      id: 'seven-day-streak',
      emoji: '📅',
      label: 'Semaine pleine',
      description: "7 jours de sport d'affilée",
      metric: AchievementMetric.streak,
      target: 7,
    ),
    Achievement(
      id: 'thirty-day-streak',
      emoji: '🗓️',
      label: 'Mois de fer',
      description: "30 jours de sport d'affilée",
      metric: AchievementMetric.streak,
      target: 30,
    ),
    Achievement(
      id: 'three-sports',
      emoji: '🎯',
      label: 'Polyvalent',
      description: '3 sports différents pratiqués',
      metric: AchievementMetric.variety,
      target: 3,
    ),
    Achievement(
      id: 'five-sports',
      emoji: '🎪',
      label: 'Touche-à-tout',
      description: '5 sports différents pratiqués',
      metric: AchievementMetric.variety,
      target: 5,
    ),
    Achievement(
      id: 'one-hour-session',
      emoji: '⏱️',
      label: 'Endurance',
      description: "Une séance d'une heure",
      metric: AchievementMetric.longestSession,
      target: 60,
    ),
    Achievement(
      id: 'two-hour-session',
      emoji: '⛰️',
      label: 'Longue distance',
      description: 'Une séance de deux heures',
      metric: AchievementMetric.longestSession,
      target: 120,
    ),
  ];

  static int _valueOf(AchievementMetric metric, ProfileStats stats) {
    return switch (metric) {
      AchievementMetric.sessions => stats.sessionCount,
      AchievementMetric.points => stats.totalPoints,
      AchievementMetric.streak => stats.currentStreakDays,
      AchievementMetric.variety => stats.sportBreakdown.length,
      AchievementMetric.longestSession => stats.longestSessionMin,
    };
  }

  /// The whole catalogue scored against one person's figures.
  ///
  /// Earned badges come first, newest achievement last within that block; the
  /// locked ones follow in the order they are closest to being earned, so the
  /// next one to go for is always the first grey tile.
  static List<AchievementProgress> evaluate(ProfileStats stats) {
    final scored = [
      for (final achievement in all)
        AchievementProgress(
          achievement: achievement,
          value: _valueOf(achievement.metric, stats),
        ),
    ];

    scored.sort((a, b) {
      if (a.isEarned != b.isEarned) return a.isEarned ? -1 : 1;
      if (a.isEarned) return a.achievement.target.compareTo(b.achievement.target);
      final byProgress = b.progress.compareTo(a.progress);
      return byProgress != 0
          ? byProgress
          : a.achievement.target.compareTo(b.achievement.target);
    });

    return scored;
  }

  static int earnedCount(ProfileStats stats) =>
      evaluate(stats).where((progress) => progress.isEarned).length;
}
