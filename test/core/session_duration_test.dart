import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/session_duration.dart';

void main() {
  group('SessionDuration.parseToMinutes', () {
    test('reads whole minutes unchanged', () {
      expect(SessionDuration.parseToMinutes('45', DurationUnit.minutes), 45);
    });

    test('converts hours to minutes', () {
      expect(SessionDuration.parseToMinutes('2', DurationUnit.hours), 120);
    });

    test('accepts a decimal comma, which is what a French keyboard offers', () {
      expect(SessionDuration.parseToMinutes('1,5', DurationUnit.hours), 90);
    });

    test('accepts a decimal dot as well', () {
      expect(SessionDuration.parseToMinutes('1.5', DurationUnit.hours), 90);
    });

    test('rounds a fractional minute rather than truncating it', () {
      expect(SessionDuration.parseToMinutes('0,51', DurationUnit.hours), 31);
    });

    test('rejects a decimal count of minutes', () {
      expect(SessionDuration.parseToMinutes('30,5', DurationUnit.minutes),
          isNull);
    });

    test('rejects text and blanks', () {
      expect(SessionDuration.parseToMinutes('abc', DurationUnit.hours), isNull);
      expect(SessionDuration.parseToMinutes('', DurationUnit.minutes), isNull);
      expect(SessionDuration.parseToMinutes(null, DurationUnit.hours), isNull);
    });

    test('reads the same duration typed in either unit', () {
      expect(
        SessionDuration.parseToMinutes('90', DurationUnit.minutes),
        SessionDuration.parseToMinutes('1,5', DurationUnit.hours),
      );
    });
  });

  group('SessionDuration.validationMessage', () {
    test('accepts a valid duration in each unit', () {
      expect(SessionDuration.validationMessage('45', DurationUnit.minutes),
          isNull);
      expect(
          SessionDuration.validationMessage('1,5', DurationUnit.hours), isNull);
    });

    test('names the unit the user is currently typing in', () {
      expect(
        SessionDuration.validationMessage('', DurationUnit.minutes),
        'Indiquez une durée en minutes',
      );
      expect(
        SessionDuration.validationMessage('', DurationUnit.hours),
        'Indiquez une durée en heures',
      );
    });

    test('rejects zero and negative durations', () {
      expect(
        SessionDuration.validationMessage('0', DurationUnit.minutes),
        'La durée doit être supérieure à 0',
      );
      expect(
        SessionDuration.validationMessage('-3', DurationUnit.hours),
        'La durée doit être supérieure à 0',
      );
    });

    test('enforces the same 24 h ceiling as the database constraint', () {
      expect(SessionDuration.validationMessage('1440', DurationUnit.minutes),
          isNull);
      expect(SessionDuration.validationMessage('24', DurationUnit.hours),
          isNull);
      expect(
        SessionDuration.validationMessage('1441', DurationUnit.minutes),
        'La durée ne peut pas dépasser 24 h',
      );
      expect(
        SessionDuration.validationMessage('24,5', DurationUnit.hours),
        'La durée ne peut pas dépasser 24 h',
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
  });
}
