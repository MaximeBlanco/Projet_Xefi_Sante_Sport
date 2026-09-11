import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/home_summary.dart';

HomeSummary buildSummary({
  String displayName = 'Maxime Lenormand',
  int totalPoints = 222,
  int sessionCount = 4,
  int? rank = 2,
  int participantCount = 6,
}) {
  return HomeSummary(
    displayName: displayName,
    totalPoints: totalPoints,
    sessionCount: sessionCount,
    totalDurationMin: 222,
    totalCaloriesBurned: 1855,
    participantCount: participantCount,
    rank: rank,
  );
}

void main() {
  group('HomeSummary.greetingName', () {
    test('greets with the first name only', () {
      expect(buildSummary().greetingName, 'Maxime');
    });

    test('does not greet someone with a whole email address', () {
      // The signup trigger falls back to the email when no name was given.
      expect(
        buildSummary(displayName: 'maxime@xefi.fr').greetingName,
        'maxime',
      );
    });

    test('keeps a single-word name unchanged', () {
      expect(buildSummary(displayName: 'XEFITEST').greetingName, 'XEFITEST');
    });
  });

  group('HomeSummary.rankLabel', () {
    test('uses the French ordinal for the first place', () {
      expect(buildSummary(rank: 1).rankLabel, '1er');
    });

    test('uses the short ordinal beyond the first place', () {
      expect(buildSummary(rank: 2).rankLabel, '2e');
      expect(buildSummary(rank: 11).rankLabel, '11e');
    });

    test('is absent while the user is not in the ranking yet', () {
      expect(buildSummary(rank: null).rankLabel, isNull);
    });
  });

  group('HomeSummary.hasRecordedASession', () {
    test('separates a new account from an active one', () {
      expect(buildSummary(sessionCount: 0).hasRecordedASession, isFalse);
      expect(buildSummary(sessionCount: 1).hasRecordedASession, isTrue);
    });
  });
}
