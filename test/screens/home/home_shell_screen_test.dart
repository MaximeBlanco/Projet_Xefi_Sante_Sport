import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/ranking_entry.dart';
import 'package:monapp/models/session.dart';
import 'package:monapp/providers/auth_provider.dart';
import 'package:monapp/providers/ranking_provider.dart';
import 'package:monapp/providers/session_provider.dart';
import 'package:monapp/screens/home/home_shell_screen.dart';

import '../../support/test_fixtures.dart';

List<Override> buildEmptyDataOverrides() {
  return [
    userSessionsProvider.overrideWith((ref) => const <Session>[]),
    globalRankingProvider.overrideWith((ref) => const <RankingEntry>[]),
    currentUserProvider.overrideWithValue(buildSignedInUser()),
  ];
}

void main() {
  group('HomeShellScreen', () {
    testWidgets('exposes exactly the sessions and ranking tabs',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: buildEmptyDataOverrides(),
          child: const HomeShellScreen(),
        ),
      );
      await tester.pump();

      final bottomBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomBar.items.length, 2);
      expect(find.text('Séances'), findsOneWidget);
      expect(find.text('Classement'), findsOneWidget);
      expect(find.text('Contacts'), findsNothing);
    });

    testWidgets('keeps the logout action in the app bar', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: buildEmptyDataOverrides(),
          child: const HomeShellScreen(),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('offers the record button on the sessions tab only',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: buildEmptyDataOverrides(),
          child: const HomeShellScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.text('Classement'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
