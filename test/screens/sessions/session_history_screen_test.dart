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
      // Twice each: once on the filter chip, once on the card.
      expect(find.text('Course à pied'), findsNWidgets(2));
      expect(find.text('Vélo'), findsNWidgets(2));
      expect(find.text('Tous'), findsOneWidget);
    });

    testWidgets('narrows the list to the sport whose chip was tapped',
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

      // The chip, not the card: the first match is the one in the filter bar.
      await tester.tap(find.text('Vélo').first);
      await tester.pumpAndSettle();

      expect(find.byType(SessionTile), findsOneWidget);
      expect(find.text('Course à pied'), findsOneWidget);

      await tester.tap(find.text('Tous'));
      await tester.pumpAndSettle();

      expect(find.byType(SessionTile), findsNWidgets(2));
    });

    testWidgets('offers a chip only for sports actually recorded',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          overrides: [
            userSessionsProvider.overrideWith(
              (ref) => [
                buildSession(
                  sport: buildSport(name: 'Course à pied', emoji: '🏃'),
                ),
              ],
            ),
          ],
          child: const SessionHistoryScreen(),
        ),
      );
      await tester.pump();

      // A chip for a sport never practised would only ever empty the list.
      expect(find.text('Natation'), findsNothing);
      expect(find.text('Course à pied'), findsNWidgets(2));
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
