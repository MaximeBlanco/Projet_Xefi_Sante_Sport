import 'session.dart';

/// Everything the home screen shows, assembled once so the screen itself never
/// cross-references the three providers it comes from.
class HomeSummary {
  const HomeSummary({
    required this.displayName,
    required this.totalPoints,
    required this.sessionCount,
    required this.totalDurationMin,
    required this.totalCaloriesBurned,
    required this.participantCount,
    this.rank,
    this.lastSession,
  });

  final String displayName;
  final int totalPoints;
  final int sessionCount;
  final int totalDurationMin;
  final double totalCaloriesBurned;
  final int participantCount;

  /// Null while the signed-in user is absent from the ranking view, which
  /// happens for the moment between signing up and the profile row landing.
  final int? rank;

  final Session? lastSession;

  bool get hasRecordedASession => sessionCount > 0;

  /// The ranking view sums calories with a coalesce, so sessions the calories
  /// provider never answered for arrive as zero. A total of zero across real
  /// sessions therefore means unknown, not burnt nothing, and the screen shows
  /// a placeholder instead of a figure nobody measured.
  bool get hasCaloriesData => totalCaloriesBurned > 0;

  /// The name alone, so the greeting stays short on a narrow screen: a profile
  /// falls back to the email when no name was given at sign-up, and an email is
  /// too long to greet someone with.
  String get greetingName {
    final firstWord = displayName.trim().split(RegExp(r'[\s@]')).first;
    return firstWord.isEmpty ? displayName : firstWord;
  }

  String? get rankLabel {
    final position = rank;
    if (position == null) return null;
    return position == 1 ? '1er' : '${position}e';
  }
}
