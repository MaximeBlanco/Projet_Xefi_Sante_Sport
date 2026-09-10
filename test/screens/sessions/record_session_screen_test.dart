import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/sport.dart';
import 'package:monapp/providers/sport_provider.dart';
import 'package:monapp/screens/sessions/record_session_screen.dart';

import '../../support/test_fixtures.dart';

List<Sport> buildSportCatalogue() {
  return <Sport>[
    buildSport(id: 'sport-cycling', name: 'Vélo', emoji: '🚴'),
    buildSport(name: 'Course à pied', emoji: '🏃'),
  ];
}

void main() {
  group('RecordSessionScreen', () {
    testWidgets('lists the sports of the catalogue', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            sportListProvider.overrideWith((ref) => buildSportCatalogue()),
          ],
          child: const RecordSessionScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Nouvelle séance'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<Sport>), findsOneWidget);

      // A closed dropdown only renders its hint, so the catalogue is only
      // observable once the menu is open.
      await tester.tap(find.byType(DropdownButtonFormField<Sport>));
      await tester.pumpAndSettle();

      expect(find.textContaining('Vélo'), findsWidgets);
      expect(find.textContaining('Course à pied'), findsWidgets);
    });

    testWidgets('refuses a duration that is not a positive integer',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            sportListProvider.overrideWith((ref) => buildSportCatalogue()),
          ],
          child: const RecordSessionScreen(),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Enregistrer la séance'),
      );
      await tester.pump();

      expect(find.text('Indiquez une durée en minutes'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '0');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Enregistrer la séance'),
      );
      await tester.pump();

      expect(find.text('La durée doit être supérieure à 0'), findsOneWidget);
    });

    testWidgets('shows the French empty state when no sport is available',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            sportListProvider.overrideWith((ref) => const <Sport>[]),
          ],
          child: const RecordSessionScreen(),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Aucun sport disponible'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<Sport>), findsNothing);
    });
  });
}
