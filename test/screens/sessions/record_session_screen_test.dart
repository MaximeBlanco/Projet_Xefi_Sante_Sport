import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/session_duration.dart';
import 'package:monapp/models/sport.dart';
import 'package:monapp/providers/sport_provider.dart';
import 'package:monapp/screens/sessions/record_session_screen.dart';
import 'package:monapp/widgets/duration_wheel_picker.dart';
import 'package:monapp/widgets/sport_carousel.dart';

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
      expect(find.byType(SportCarousel), findsOneWidget);

      // The deck shows its neighbours, so the catalogue is visible without any
      // interaction at all — that is the point of replacing the dropdown.
      expect(find.text('Vélo'), findsOneWidget);
      expect(find.text('Course à pied'), findsOneWidget);
    });

    testWidgets('starts on the first sport so nothing is left unchosen',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            sportListProvider.overrideWith((ref) => buildSportCatalogue()),
          ],
          child: const RecordSessionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // The centred card is the answer, so there is no "choose a sport" error
      // left to trigger.
      expect(find.text('Choisissez un sport'), findsNothing);
    });

    testWidgets('offers wheels rather than a duration to type', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            sportListProvider.overrideWith((ref) => buildSportCatalogue()),
          ],
          child: const RecordSessionScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(DurationWheelPicker), findsOneWidget);
      // The screen used to expose the duration as free text, which let "1,30"
      // be read as 78 minutes. The only remaining text field is none at all.
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('starts on a usable duration and states what it scores',
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

      expect(
        find.text(
          '${SessionDuration.describeMinutes(SessionDuration.defaultMinutes)}'
          ' · ${SessionDuration.defaultMinutes} pts',
        ),
        findsOneWidget,
      );
      expect(find.text('La durée doit être supérieure à 0'), findsNothing);
    });

    testWidgets('scrolling the minute wheel updates what will be recorded',
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

      final minuteWheel = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Minutes',
      );
      expect(minuteWheel, findsOneWidget);

      // Two notches up from 30 minutes lands on 28.
      await tester.drag(minuteWheel, const Offset(0, 88));
      await tester.pumpAndSettle();

      expect(find.text('28 min · 28 pts'), findsOneWidget);
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
