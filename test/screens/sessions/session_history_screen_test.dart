import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/session.dart';
import 'package:monapp/providers/session_provider.dart';
import 'package:monapp/screens/sessions/session_history_screen.dart';
import 'package:monapp/widgets/session_tile.dart';

import '../../support/test_fixtures.dart';

void main() {
  group('SessionHistoryScreen', () {
    testWidgets('renders one tile per session of the signed-in user',
        (tester) async {
      final sessions = <Session>[
        buildSession(
          id: 'session-1',
          sport: buildSport(name: 'Course à pied', emoji: '🏃'),
        ),
        buildSession(
          id: 'session-2',
          sportId: 'sport-cycling',
          sport: buildSport(id: 'sport-cycling', name: 'Vélo', emoji: '🚴'),
        ),
      ];

      await tester.pumpWidget(
        buildTestAppWithScaffold(
          overrides: [userSessionsProvider.overrideWith((ref) => sessions)],
          child: const SessionHistoryScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SessionTile), findsNWidgets(2));
      expect(find.text('Course à pied'), findsOneWidget);
      expect(find.text('Vélo'), findsOneWidget);
    });

    testWidgets('shows the French empty state when no session was recorded',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          overrides: [
            userSessionsProvider.overrideWith((ref) => const <Session>[]),
          ],
          child: const SessionHistoryScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SessionTile), findsNothing);
      expect(
        find.textContaining('Aucune séance enregistrée'),
        findsOneWidget,
      );
    });
  });
}
