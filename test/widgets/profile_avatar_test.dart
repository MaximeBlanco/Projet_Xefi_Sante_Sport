import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/widgets/profile_avatar.dart';

import '../support/test_fixtures.dart';

void main() {
  group('ProfileAvatar initials', () {
    Future<void> pumpWith(WidgetTester tester, String name) {
      return tester.pumpWidget(
        buildTestAppWithScaffold(child: ProfileAvatar(name: name)),
      );
    }

    testWidgets('takes the first letter of the first two words',
        (tester) async {
      await pumpWith(tester, 'Maxime Lenormand');
      expect(find.text('ML'), findsOneWidget);
    });

    testWidgets('takes two letters from a single-word name', (tester) async {
      await pumpWith(tester, 'XEFITEST');
      expect(find.text('XE'), findsOneWidget);
    });

    testWidgets('splits an email, since sign-up falls back to it',
        (tester) async {
      await pumpWith(tester, 'maxime.lenormand@xefi.fr');
      expect(find.text('ML'), findsOneWidget);
    });

    testWidgets('never renders empty for a blank name', (tester) async {
      await pumpWith(tester, '   ');
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('falls back to initials when no picture is set',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: const ProfileAvatar(name: 'Alice Martin', avatarUrl: ''),
        ),
      );

      expect(find.text('AM'), findsOneWidget);
    });
  });
}
