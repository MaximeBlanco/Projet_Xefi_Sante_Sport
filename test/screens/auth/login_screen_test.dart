import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/screens/auth/login_screen.dart';

import '../../support/test_fixtures.dart';

void main() {
  testWidgets('LoginScreen shows the login form', (tester) async {
    await tester.pumpWidget(buildTestApp(child: const LoginScreen()));

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
