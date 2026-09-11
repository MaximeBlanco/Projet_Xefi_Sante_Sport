import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/domain/session_duration.dart';
import '../../core/theme/app_colors.dart';
import '../../models/sport.dart';
import '../../models/venue.dart';
import '../../providers/record_session_controller.dart';
import '../../providers/sport_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/duration_wheel_picker.dart';
import '../../widgets/route_map.dart';
import '../../widgets/venue_picker.dart';
import 'track_route_screen.dart';

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
  TrackedRoute? _trackedRoute;
  Venue? _venue;

  String? get _durationError => SessionDuration.validationMessage(_durationMin);

  /// A tracked route belongs to the sport it was recorded for, so switching
  /// sports drops it rather than attaching a bike ride to a swim.
  void _selectSport(Sport? sport) {
    setState(() {
      _selectedSport = sport;
      if (sport == null || !sport.isGpsTrackable) {
        _trackedRoute = null;
      }
    });
  }

  Future<void> _trackRoute(Sport sport) async {
    final trackedRoute = await Navigator.of(context).push<TrackedRoute>(
      MaterialPageRoute(builder: (_) => TrackRouteScreen(sport: sport)),
    );

    if (trackedRoute == null || !mounted) return;
    setState(() {
      _trackedRoute = trackedRoute;
      _durationMin = trackedRoute.durationMin;
    });
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
    if (!_formKey.currentState!.validate() ||
        selectedSport == null ||
        _durationError != null) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _errorMessage = null);

    final trackedRoute = _trackedRoute;
    final wasRecorded =
        await ref.read(recordSessionControllerProvider.notifier).submit(
              sport: selectedSport,
              date: _selectedDate,
              durationMin: _durationMin,
              route: trackedRoute?.route,
              distanceKm: trackedRoute?.distanceKm,
              elevationGainM: trackedRoute?.elevationGainM,
              venue: _venue,
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

  /// Points equal the duration in minutes, so reading the wheels back tells
  /// the user what they are about to score before they commit to it.
  String get _durationSummary =>
      '${SessionDuration.describeMinutes(_durationMin)} · $_durationMin pts';

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
                  onChanged: isSubmitting ? null : _selectSport,
                  validator: (sport) =>
                      sport == null ? 'Choisissez un sport' : null,
                ),
                if (_selectedSport?.isGpsTrackable ?? false) ...[
                  const SizedBox(height: 16),
                  _RouteSection(
                    trackedRoute: _trackedRoute,
                    enabled: !isSubmitting,
                    onTrack: () => _trackRoute(_selectedSport!),
                  ),
                ],
                const SizedBox(height: 16),
                InputDecorator(
                  isEmpty: false,
                  decoration: InputDecoration(
                    labelText: 'Durée',
                    errorText: _durationError,
                    helperText:
                        _durationError == null ? _durationSummary : null,
                  ),
                  child: DurationWheelPicker(
                    durationMin: _durationMin,
                    enabled: !isSubmitting,
                    onDurationChanged: (durationMin) =>
                        setState(() => _durationMin = durationMin),
                  ),
                ),
                const SizedBox(height: 16),
                VenuePicker(
                  venue: _venue,
                  enabled: !isSubmitting,
                  onChanged: (venue) => setState(() => _venue = venue),
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

/// Offered only for the sports the catalogue marks as GPS-trackable, so a
/// swimmer is never asked to record a route.
class _RouteSection extends StatelessWidget {
  const _RouteSection({
    required this.trackedRoute,
    required this.enabled,
    required this.onTrack,
  });

  final TrackedRoute? trackedRoute;
  final bool enabled;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final trackedRoute = this.trackedRoute;

    if (trackedRoute == null) {
      return OutlinedButton.icon(
        onPressed: enabled ? onTrack : null,
        icon: const Icon(Icons.my_location),
        label: const Text('Suivre le parcours en direct'),
      );
    }

    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Parcours'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 160,
              child: RouteMap(route: trackedRoute.route, interactive: false),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${trackedRoute.distanceKm.toStringAsFixed(2)} km · '
            '${trackedRoute.elevationGainM.round()} m D+',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton(
            onPressed: enabled ? onTrack : null,
            child: const Text('Refaire le parcours'),
          ),
        ],
      ),
    );
  }
}
