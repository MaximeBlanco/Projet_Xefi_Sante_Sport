import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:monapp/app.dart';
import 'package:monapp/data/session_repository.dart';

void main() {
  testWidgets('Shows the empty state when there are no sessions',
      (WidgetTester tester) async {
    Hive.init(Directory.systemTemp.createTempSync('hive_test').path);
    final repository = SessionRepository();
    await repository.init();

    await tester.pumpWidget(XefiSportApp(repository: repository));

    expect(find.text('Mes séances'), findsOneWidget);
    expect(find.text('Aucune séance pour l\'instant'), findsOneWidget);
  });
}
