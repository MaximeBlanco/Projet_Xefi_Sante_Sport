import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/providers/auth_provider.dart';
import 'package:monapp/providers/record_session_controller.dart';

import '../support/test_fixtures.dart';

void main() {
  group('RecordSessionController', () {
    test('reports a failure instead of recording when nobody is signed in',
        () async {
      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        recordSessionControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final wasRecorded = await container
          .read(recordSessionControllerProvider.notifier)
          .submit(
            sport: buildSport(),
            date: DateTime(2026, 3, 14),
            durationMin: 30,
          );

      expect(wasRecorded, isFalse);
      expect(container.read(recordSessionControllerProvider).hasError, isTrue);
    });
  });
}
