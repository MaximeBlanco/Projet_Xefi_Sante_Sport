import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/domain/session_duration.dart';
import '../../core/theme/app_colors.dart';
import '../../models/sport.dart';
import '../../providers/record_session_controller.dart';
import '../../providers/sport_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/duration_wheel_picker.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/sport_carousel.dart';

/// Matches the floating label an InputDecorator gives the other fields, so the
/// carousel does not look like it belongs to a different form.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppColors.secondaryText),
    );
  }
}

class RecordSessionScreen extends ConsumerStatefulWidget {
  const RecordSessionScreen({super.key});

  @override
  ConsumerState<RecordSessionScreen> createState() =>
      _RecordSessionScreenState();
}

class _RecordSessionScreenState extends ConsumerState<RecordSessionScreen> {
  static const _selectableYearsInThePast = 1;

  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  Sport? _selectedSport;
  int _durationMin = SessionDuration.defaultMinutes;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _errorMessage;

  String? get _durationError => SessionDuration.validationMessage(_durationMin);

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(
        today.year - _selectableYearsInThePast,
        today.month,
        today.day,
      ),
      lastDate: today,
      helpText: 'Date de la séance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      fieldLabelText: 'Date de la séance',
      errorFormatText: 'Format de date invalide',
      errorInvalidText: 'Date en dehors de la période autorisée',
    );

    if (pickedDate == null || !mounted) return;
    setState(() => _selectedDate = DateUtils.dateOnly(pickedDate));
  }

  Future<void> _submit() async {
    final selectedSport = _selectedSport;
    if (!_formKey.currentState!.validate() ||
        selectedSport == null ||
        _durationError != null) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _errorMessage = null);

    final wasRecorded = await ref
        .read(recordSessionControllerProvider.notifier)
        .submit(
          sport: selectedSport,
          date: _selectedDate,
          durationMin: _durationMin,
        );

    if (!mounted) return;

    if (wasRecorded) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Séance enregistrée')),
      );
      return;
    }

    setState(() {
      _errorMessage = _describeSubmissionFailure(
        ref.read(recordSessionControllerProvider).error,
      );
    });
  }

  /// Only errors whose text was written for a user get shown. Anything else —
  /// a PostgrestException carrying an RLS message and an SQLSTATE, say — is
  /// logged and replaced, rather than rendered raw inside the form.
  String _describeSubmissionFailure(Object? error) {
    if (error is SignedInUserRequiredException) {
      return '$error';
    }
    if (error != null) {
      developer.log(
        'Session recording failed',
        name: 'RecordSessionScreen',
        error: error,
      );
    }
    return "L'enregistrement de la séance a échoué, réessayez.";
  }

  @override
  Widget build(BuildContext context) {
    final sportCatalogue = ref.watch(sportListProvider);
    final isSubmitting = ref.watch(recordSessionControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle séance')),
      body: AsyncValueView<List<Sport>>(
        value: sportCatalogue,
        onRetry: () => ref.invalidate(sportListProvider),
        emptyMessage: 'Aucun sport disponible pour le moment.',
        isEmpty: (sports) => sports.isEmpty,
        builder: (sports) =>
            _buildForm(sports: sports, isSubmitting: isSubmitting),
      ),
    );
  }

  Widget _buildForm({required List<Sport> sports, required bool isSubmitting}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FadeSlideIn(child: _FieldLabel('Sport')),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: SportCarousel(
                    key: ObjectKey(sports),
                    sports: sports,
                    enabled: !isSubmitting,
                    onSportSelected: (sport) {
                      if (sport.id == _selectedSport?.id) return;
                      setState(() => _selectedSport = sport);
                    },
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FieldLabel('Durée'),
                      const SizedBox(height: 4),
                      DurationWheelPicker(
                        durationMin: _durationMin,
                        enabled: !isSubmitting,
                        onDurationChanged: (durationMin) =>
                            setState(() => _durationMin = durationMin),
                      ),
                      if (_durationError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _durationError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FieldLabel('Date'),
                      const SizedBox(height: 8),
                      _DateChip(
                        label: _dateFormat.format(_selectedDate),
                        onTap: isSubmitting ? null : _pickDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: _SessionRecap(
                    sportName: _selectedSport?.name,
                    durationMin: _durationMin,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Enregistrer la séance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
              const Icon(
                Icons.expand_more,
                size: 20,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Restates the whole form in one line, and animates when any part of it
/// changes.
///
/// The three inputs sit far apart on screen, so committing means remembering
/// what was picked at the top while looking at the button at the bottom. The
/// recap removes that, and since points equal the duration it is also where the
/// score becomes visible before it is earned.
class _SessionRecap extends StatelessWidget {
  const _SessionRecap({required this.sportName, required this.durationMin});

  final String? sportName;
  final int durationMin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                sportName == null
                    ? SessionDuration.describeMinutes(durationMin)
                    : '$sportName · ${SessionDuration.describeMinutes(durationMin)}',
                key: ValueKey('$sportName-$durationMin'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedCounter(
            value: durationMin,
            duration: const Duration(milliseconds: 400),
            style: textTheme.titleLarge?.copyWith(
              fontSize: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'pts',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
