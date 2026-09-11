import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/widgets/duration_wheel_picker.dart';

import '../support/test_fixtures.dart';

/// Drives the picker the way the record form does: the parent owns the
/// duration and feeds it back down.
class _PickerHost extends StatefulWidget {
  const _PickerHost({required this.initialDurationMin});

  final int initialDurationMin;

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  late int _durationMin = widget.initialDurationMin;

  void setDuration(int durationMin) =>
      setState(() => _durationMin = durationMin);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$_durationMin min'),
        DurationWheelPicker(
          durationMin: _durationMin,
          onDurationChanged: setDuration,
        ),
      ],
    );
  }
}

void main() {
  group('DurationWheelPicker', () {
    testWidgets('shows the duration it is given', (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: const _PickerHost(initialDurationMin: 30),
        ),
      );

      expect(find.text('30 min'), findsOneWidget);
    });

    // Regression: aligning the wheels from didUpdateWidget calls
    // onSelectedItemChanged synchronously, and reporting that back used to
    // call setState on the parent during build. Route tracking is what made a
    // duration arrive from outside the picker for the first time.
    testWidgets('accepts a duration set from outside without erroring',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: const _PickerHost(initialDurationMin: 30),
        ),
      );

      final host = tester.state<_PickerHostState>(find.byType(_PickerHost));
      host.setDuration(95);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('95 min'), findsOneWidget);
    });

    testWidgets('does not echo a programmatic alignment back as a change',
        (tester) async {
      await tester.pumpWidget(
        buildTestAppWithScaffold(
          child: const _PickerHost(initialDurationMin: 30),
        ),
      );

      final host = tester.state<_PickerHostState>(find.byType(_PickerHost));
      host.setDuration(95);
      await tester.pumpAndSettle();

      // 95 survives: had the wheels reported their own alignment, the hours
      // wheel landing on 1 would have overwritten it with 1 h + 30 min.
      expect(find.text('95 min'), findsOneWidget);
    });
  });
}
