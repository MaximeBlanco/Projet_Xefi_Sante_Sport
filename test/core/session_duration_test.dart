import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/session_duration.dart';

void main() {
  group('SessionDuration.fromHoursAndMinutes', () {
    test('combines the two wheels into minutes', () {
      expect(SessionDuration.fromHoursAndMinutes(1, 30), 90);
      expect(SessionDuration.fromHoursAndMinutes(0, 45), 45);
      expect(SessionDuration.fromHoursAndMinutes(2, 0), 120);
    });

    test('reaches the database ceiling exactly at 24 h', () {
      expect(
        SessionDuration.fromHoursAndMinutes(SessionDuration.maximumHours, 0),
        SessionDuration.maximumMinutes,
      );
    });
  });

  group('SessionDuration.validationMessage', () {
    test('accepts any duration the wheels can produce below the ceiling', () {
      expect(SessionDuration.validationMessage(1), isNull);
      expect(SessionDuration.validationMessage(90), isNull);
      expect(
          SessionDuration.validationMessage(SessionDuration.maximumMinutes),
          isNull);
    });

    test('rejects a duration of zero, the one the wheels can still reach', () {
      expect(
        SessionDuration.validationMessage(0),
        'La durée doit être supérieure à 0',
      );
    });

    test('rejects going past 24 h, matching the database constraint', () {
      expect(
        SessionDuration.validationMessage(SessionDuration.maximumMinutes + 1),
        'La durée ne peut pas dépasser 24h',
      );
      // 24 h on the hour wheel plus any minutes is the only way to overshoot.
      expect(
        SessionDuration.validationMessage(
          SessionDuration.fromHoursAndMinutes(SessionDuration.maximumHours, 30),
        ),
        isNotNull,
      );
    });
  });

  group('SessionDuration.describeMinutes', () {
    test('shows minutes alone below an hour', () {
      expect(SessionDuration.describeMinutes(45), '45 min');
    });

    test('drops the minutes on a whole number of hours', () {
      expect(SessionDuration.describeMinutes(120), '2 h');
    });

    test('pads the minutes so 1 h 05 does not read as 1 h 5', () {
      expect(SessionDuration.describeMinutes(65), '1 h 05');
      expect(SessionDuration.describeMinutes(90), '1 h 30');
    });

    test('never renders the 1,30 ambiguity that the text field allowed', () {
      // Typing "1,30" used to parse as 1.3 h, so 78 minutes. The wheels can
      // only produce 1 h and 30 min, and that reads back as 90.
      expect(SessionDuration.fromHoursAndMinutes(1, 30), 90);
      expect(SessionDuration.describeMinutes(90), '1 h 30');
    });
  });
}
