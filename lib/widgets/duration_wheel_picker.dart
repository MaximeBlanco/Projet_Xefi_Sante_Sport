import 'package:flutter/material.dart';

import '../core/domain/session_duration.dart';
import '../core/theme/app_colors.dart';

const double _itemExtent = 44;
const double _wheelHeight = 176;
const double _wheelWidth = 88;

/// Two scroll wheels, hours and minutes, replacing a typed duration.
///
/// A text field forced the user to reconcile two notations: "1,30" reads as an
/// hour and a half but parses as 1.3 hours, which is 78 minutes. Wheels remove
/// the notation entirely, and they cannot produce a value outside their range.
class DurationWheelPicker extends StatefulWidget {
  const DurationWheelPicker({
    super.key,
    required this.durationMin,
    required this.onDurationChanged,
    this.enabled = true,
  });

  final int durationMin;
  final ValueChanged<int> onDurationChanged;
  final bool enabled;

  @override
  State<DurationWheelPicker> createState() => _DurationWheelPickerState();
}

class _DurationWheelPickerState extends State<DurationWheelPicker> {
  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;

  int get _selectedHours => widget.durationMin ~/ Duration.minutesPerHour;

  int get _selectedMinutes => widget.durationMin % Duration.minutesPerHour;

  @override
  void initState() {
    super.initState();
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController =
        FixedExtentScrollController(initialItem: _selectedMinutes);
  }

  @override
  void didUpdateWidget(covariant DurationWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _alignWheel(_hoursController, _selectedHours);
    _alignWheel(_minutesController, _selectedMinutes);
  }

  /// Only moves a wheel the user is not already sitting on, so a value the
  /// parent echoes back does not fight the finger that produced it.
  void _alignWheel(FixedExtentScrollController controller, int item) {
    if (!controller.hasClients) return;
    if (controller.selectedItem == item) return;
    controller.jumpToItem(item);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _changeHours(int hours) {
    widget.onDurationChanged(
      SessionDuration.fromHoursAndMinutes(hours, _selectedMinutes),
    );
  }

  void _changeMinutes(int minutes) {
    widget.onDurationChanged(
      SessionDuration.fromHoursAndMinutes(_selectedHours, minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _wheelHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _SelectionBand(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Wheel(
                controller: _hoursController,
                itemCount: SessionDuration.maximumHours + 1,
                onSelectedItemChanged: _changeHours,
                enabled: widget.enabled,
                semanticsLabel: 'Heures',
              ),
              const _UnitLabel('h'),
              _Wheel(
                controller: _minutesController,
                itemCount: Duration.minutesPerHour,
                onSelectedItemChanged: _changeMinutes,
                enabled: widget.enabled,
                semanticsLabel: 'Minutes',
                padWithLeadingZero: true,
              ),
              const _UnitLabel('min'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionBand extends StatelessWidget {
  const _SelectionBand();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: _itemExtent,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _UnitLabel extends StatelessWidget {
  const _UnitLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 12),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.itemCount,
    required this.onSelectedItemChanged,
    required this.enabled,
    required this.semanticsLabel,
    this.padWithLeadingZero = false,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final ValueChanged<int> onSelectedItemChanged;
  final bool enabled;
  final String semanticsLabel;
  final bool padWithLeadingZero;

  String _label(int value) =>
      padWithLeadingZero ? value.toString().padLeft(2, '0') : '$value';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: _wheelWidth,
        height: _wheelHeight,
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: _itemExtent,
          diameterRatio: 1.6,
          perspective: 0.004,
          overAndUnderCenterOpacity: 0.35,
          physics: enabled
              ? const FixedExtentScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          onSelectedItemChanged: enabled ? onSelectedItemChanged : null,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) => Center(
              child: Text(
                _label(index),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
