import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/domain/body_weight_range.dart';
import 'package:monapp/screens/auth/sign_up_screen.dart';

import '../../support/test_fixtures.dart';

const String _nameLabel = 'Nom';
const String _emailLabel = 'Email';
const String _passwordLabel = 'Mot de passe';
const String _weightLabel = 'Poids (kg)';
const String _submitLabel = "S'inscrire";
// Read from the domain constant rather than retyped: the bounds must track the
// range the calories Edge Function accepts, and a literal here would let the
// two drift apart silently again.
final String _outOfRangeWeightMessage = BodyWeightRange.invalidMessage;
final String _weightBelowRange = (BodyWeightRange.minimumKg - 1).toString();
final String _weightAboveRange = (BodyWeightRange.maximumKg + 1).toString();

Future<void> submitFormWithWeight(WidgetTester tester, String weight) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, _nameLabel),
    'Alice',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, _emailLabel),
    'alice@xefi.fr',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, _passwordLabel),
    'motdepasse',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, _weightLabel),
    weight,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, _submitLabel));
  await tester.pump();
}

void main() {
  group('SignUpScreen', () {
    testWidgets('asks for the name and the weight on top of the credentials',
        (tester) async {
      await tester.pumpWidget(buildTestApp(child: const SignUpScreen()));

      expect(find.text(_nameLabel), findsOneWidget);
      expect(find.text(_emailLabel), findsOneWidget);
      expect(find.text(_passwordLabel), findsOneWidget);
      expect(find.text(_weightLabel), findsOneWidget);
    });

    testWidgets('rejects a weight that is not a number', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const SignUpScreen()));

      await submitFormWithWeight(tester, 'soixante-dix');

      expect(find.text('Poids invalide'), findsOneWidget);
    });

    testWidgets('rejects a weight below the accepted range', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const SignUpScreen()));

      await submitFormWithWeight(tester, _weightBelowRange);

      expect(find.text(_outOfRangeWeightMessage), findsOneWidget);
    });

    testWidgets('rejects a weight above the accepted range', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const SignUpScreen()));

      await submitFormWithWeight(tester, _weightAboveRange);

      expect(find.text(_outOfRangeWeightMessage), findsOneWidget);
    });

    testWidgets('rejects an empty weight', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const SignUpScreen()));

      await submitFormWithWeight(tester, '');

      expect(find.text('Poids obligatoire'), findsOneWidget);
    });

    testWidgets('rejects an empty name', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const SignUpScreen()));

      await tester.enterText(
        find.widgetWithText(TextFormField, _weightLabel),
        'x',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, _submitLabel));
      await tester.pump();

      expect(find.text('Nom obligatoire'), findsOneWidget);
    });
  });
}
