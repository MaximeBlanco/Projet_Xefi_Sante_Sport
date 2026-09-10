/// The unit a duration is typed in. Sessions are always stored in minutes,
/// because `points = duration_min` and the database derives them, so hours are
/// a data entry convenience that never reaches persistence.
enum DurationUnit {
  minutes,
  hours;

  String get label => switch (this) {
        DurationUnit.minutes => 'Minutes',
        DurationUnit.hours => 'Heures',
      };

  String get fieldSuffix => switch (this) {
        DurationUnit.minutes => 'min',
        DurationUnit.hours => 'h',
      };
}

abstract final class SessionDuration {
  /// Matches the `sessions_duration_min_within_one_day` database constraint.
  /// Keeping the two in step matters: the server rejects anything above this,
  /// and a form that let it through would fail on submit instead of on typing.
  static const maximumMinutes = 1440;

  /// Converts what the user typed into whole minutes, or null when the input
  /// is not a usable duration. Hours accept a decimal part, written with a
  /// comma or a dot, since a French keyboard offers the comma.
  static int? parseToMinutes(String? rawValue, DurationUnit unit) {
    final normalized = (rawValue ?? '').trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;

    return switch (unit) {
      DurationUnit.minutes => int.tryParse(normalized),
      DurationUnit.hours => _hoursToMinutes(double.tryParse(normalized)),
    };
  }

  static int? _hoursToMinutes(double? hours) {
    if (hours == null || !hours.isFinite) return null;
    return (hours * Duration.minutesPerHour).round();
  }

  /// The French message to show under the field, or null when the input is
  /// acceptable.
  static String? validationMessage(String? rawValue, DurationUnit unit) {
    final durationMin = parseToMinutes(rawValue, unit);
    if (durationMin == null) {
      return switch (unit) {
        DurationUnit.minutes => 'Indiquez une durée en minutes',
        DurationUnit.hours => 'Indiquez une durée en heures',
      };
    }
    if (durationMin <= 0) {
      return 'La durée doit être supérieure à 0';
    }
    if (durationMin > maximumMinutes) {
      return 'La durée ne peut pas dépasser 24 h';
    }
    return null;
  }

  /// Reads back a duration the way the history screen will show it, so the
  /// form can confirm what is about to be recorded before it is sent.
  static String describeMinutes(int durationMin) {
    final hours = durationMin ~/ Duration.minutesPerHour;
    final minutes = durationMin % Duration.minutesPerHour;

    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';
    return '$hours h ${minutes.toString().padLeft(2, '0')}';
  }
}
