import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/widgets/async_value_view.dart';

import '../support/test_fixtures.dart';

Widget buildViewUnderTest({
  required AsyncValue<List<String>> value,
  VoidCallback? onRetry,
  String? emptyMessage,
  bool Function(List<String> data)? isEmpty,
}) {
  return buildTestAppWithScaffold(
    child: AsyncValueView<List<String>>(
      value: value,
      onRetry: onRetry,
      emptyMessage: emptyMessage,
      isEmpty: isEmpty,
      builder: (data) => Text(data.join(' & ')),
    ),
  );
}

void main() {
  group('AsyncValueView', () {
    testWidgets('shows a spinner while loading', (tester) async {
      await tester.pumpWidget(
        buildViewUnderTest(value: const AsyncValue<List<String>>.loading()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows a retry action only when a callback is provided',
        (tester) async {
      final failure = AsyncValue<List<String>>.error(
        Exception('offline'),
        StackTrace.empty,
      );

      await tester.pumpWidget(buildViewUnderTest(value: failure));

      expect(find.text('Une erreur est survenue.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Réessayer'), findsNothing);

      var retryCount = 0;
      await tester.pumpWidget(
        buildViewUnderTest(value: failure, onRetry: () => retryCount++),
      );
      await tester.tap(find.widgetWithText(TextButton, 'Réessayer'));

      expect(retryCount, 1);
    });

    testWidgets('shows the empty message when the data is empty',
        (tester) async {
      await tester.pumpWidget(
        buildViewUnderTest(
          value: const AsyncValue<List<String>>.data(<String>[]),
          emptyMessage: 'Aucune séance enregistrée.',
          isEmpty: (data) => data.isEmpty,
        ),
      );

      expect(find.text('Aucune séance enregistrée.'), findsOneWidget);
    });

    testWidgets('builds the data when it is not empty', (tester) async {
      await tester.pumpWidget(
        buildViewUnderTest(
          value: const AsyncValue<List<String>>.data(<String>['Alice']),
          emptyMessage: 'Aucune séance enregistrée.',
          isEmpty: (data) => data.isEmpty,
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Aucune séance enregistrée.'), findsNothing);
    });
  });
}
