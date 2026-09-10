import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/domain/session_duration.dart';
import '../../core/theme/app_colors.dart';
import '../../models/sport.dart';
import '../../providers/record_session_controller.dart';
import '../../providers/sport_provider.dart';
import '../../widgets/async_value_view.dart';

class RecordSessionScreen extends ConsumerStatefulWidget {
  const RecordSessionScreen({super.key});

  @override
  ConsumerState<RecordSessionScreen> createState() =>
      _RecordSessionScreenState();
}

class _RecordSessionScreenState extends ConsumerState<RecordSessionScreen> {
  static const _selectableYearsInThePast = 1;

  final _formKey = GlobalKey<FormState>();
  final _durationFieldKey = GlobalKey<FormFieldState<String>>();
  final _durationController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  Sport? _selectedSport;
  DurationUnit _durationUnit = DurationUnit.minutes;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _errorMessage;

  int? get _durationMin =>
      SessionDuration.parseToMinutes(_durationController.text, _durationUnit);

  void _changeDurationUnit(DurationUnit unit) {
    if (unit == _durationUnit) return;
    setState(() => _durationUnit = unit);
    // The same digits mean something else now, so any message already on the
    // field is about a value the user is no longer entering. Only this field
    // is revalidated: a form-wide pass would also flag a sport not yet chosen,
    // and an empty field is not a mistake until the user submits.
    if (_durationController.text.trim().isNotEmpty) {
      _durationFieldKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

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
    final durationMin = _durationMin;
    if (!_formKey.currentState!.validate() ||
        selectedSport == null ||
        durationMin == null) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _errorMessage = null);

    final wasRecorded =
        await ref.read(recordSessionControllerProvider.notifier).submit(
              sport: selectedSport,
              date: _selectedDate,
              durationMin: durationMin,
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

  String? _validateDuration(String? value) =>
      SessionDuration.validationMessage(value, _durationUnit);

  /// Points equal the duration in minutes, so showing the conversion tells the
  /// user what they are about to score before they commit to it.
  String? get _durationHelperText {
    final durationMin = _durationMin;
    if (durationMin == null || durationMin <= 0) return null;
    return '${SessionDuration.describeMinutes(durationMin)} · $durationMin pts';
  }

  Sport? _matchingSportInCatalogue(List<Sport> sports) {
    final selectedSportId = _selectedSport?.id;
    if (selectedSportId == null) return null;
    for (final sport in sports) {
      if (sport.id == selectedSportId) return sport;
    }
    return null;
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
                DropdownButtonFormField<Sport>(
                  key: ObjectKey(sports),
                  initialValue: _matchingSportInCatalogue(sports),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  hint: const Text('Choisissez un sport'),
                  items: [
                    for (final sport in sports)
                      DropdownMenuItem<Sport>(
                        value: sport,
                        child: Text('${sport.emoji}  ${sport.name}'),
                      ),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (sport) => setState(() => _selectedSport = sport),
                  validator: (sport) =>
                      sport == null ? 'Choisissez un sport' : null,
                ),
                const SizedBox(height: 16),
                SegmentedButton<DurationUnit>(
                  segments: [
                    for (final unit in DurationUnit.values)
                      ButtonSegment<DurationUnit>(
                        value: unit,
                        label: Text(unit.label),
                      ),
                  ],
                  selected: {_durationUnit},
                  onSelectionChanged: isSubmitting
                      ? null
                      : (selection) => _changeDurationUnit(selection.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: _durationFieldKey,
                  controller: _durationController,
                  enabled: !isSubmitting,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: _durationUnit == DurationUnit.hours,
                  ),
                  inputFormatters: [
                    if (_durationUnit == DurationUnit.hours)
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    else
                      FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Durée',
                    suffixText: _durationUnit.fieldSuffix,
                    helperText: _durationHelperText,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: _validateDuration,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: isSubmitting ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Row(
                      children: [
                        Expanded(child: Text(_dateFormat.format(_selectedDate))),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
