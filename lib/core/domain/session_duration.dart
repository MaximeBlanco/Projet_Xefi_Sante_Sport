abstract final class SessionDuration {
  /// Matches the `sessions_duration_min_within_one_day` database constraint.
  /// Keeping the two in step matters: the server rejects anything above this,
  /// and a form that let it through would fail on submit instead of on entry.
  static const maximumMinutes = 1440;

  static const maximumHours = maximumMinutes ~/ Duration.minutesPerHour;

  static const defaultMinutes = 30;

  static int fromHoursAndMinutes(int hours, int minutes) =>
      hours * Duration.minutesPerHour + minutes;

  /// The French message to show under the picker, or null when the duration is
  /// acceptable.
  static String? validationMessage(int durationMin) {
    if (durationMin <= 0) {
      return 'La durée doit être supérieure à 0';
    }
    if (durationMin > maximumMinutes) {
      return 'La durée ne peut pas dépasser ${maximumHours}h';
    }
    return null;
  }

  /// Reads a duration back the way the history screen shows it, so the form can
  /// confirm what is about to be recorded before it is sent.
  static String describeMinutes(int durationMin) {
    final hours = durationMin ~/ Duration.minutesPerHour;
    final minutes = durationMin % Duration.minutesPerHour;

    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';
    return '$hours h ${minutes.toString().padLeft(2, '0')}';
  }
}
