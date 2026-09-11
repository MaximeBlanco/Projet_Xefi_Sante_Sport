import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/venue.dart';
import '../providers/venue_provider.dart';

/// Lets the user attach a place to a session, either picked from the venues
/// OpenStreetMap knows about nearby or typed by hand.
///
/// The venue is always optional: a session recorded without one stays valid,
/// so nothing here can block the form.
class VenuePicker extends StatelessWidget {
  const VenuePicker({
    super.key,
    required this.venue,
    required this.enabled,
    required this.onChanged,
  });

  final Venue? venue;
  final bool enabled;
  final ValueChanged<Venue?> onChanged;

  Future<void> _choose(BuildContext context) async {
    final chosen = await showModalBottomSheet<Venue>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _VenueSheet(),
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final venue = this.venue;

    if (venue == null) {
      return OutlinedButton.icon(
        onPressed: enabled ? () => _choose(context) : null,
        icon: const Icon(Icons.place_outlined),
        label: const Text('Ajouter un lieu'),
      );
    }

    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Lieu'),
      child: Row(
        children: [
          Expanded(child: Text(venue.label)),
          IconButton(
            tooltip: 'Changer de lieu',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: enabled ? () => _choose(context) : null,
          ),
          IconButton(
            tooltip: 'Retirer le lieu',
            icon: const Icon(Icons.close, size: 18),
            onPressed: enabled ? () => onChanged(null) : null,
          ),
        ],
      ),
    );
  }
}

class _VenueSheet extends ConsumerStatefulWidget {
  const _VenueSheet();

  @override
  ConsumerState<_VenueSheet> createState() => _VenueSheetState();
}

class _VenueSheetState extends ConsumerState<_VenueSheet> {
  final _typedNameController = TextEditingController();

  @override
  void dispose() {
    _typedNameController.dispose();
    super.dispose();
  }

  void _submitTypedName() {
    final name = _typedNameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(Venue.typedByUser(name));
  }

  @override
  Widget build(BuildContext context) {
    final nearby = ref.watch(nearbyVenuesProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Où avez-vous fait cette séance ?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _typedNameController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Saisir un lieu',
                hintText: 'Chez moi, forêt de Brocéliande…',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Utiliser ce lieu',
                  onPressed: _submitTypedName,
                ),
              ),
              onSubmitted: (_) => _submitTypedName(),
            ),
            const SizedBox(height: 16),
            Text('À proximité', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: nearby.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _SheetNotice(
                  message: '$error',
                  onRetry: () => ref.invalidate(nearbyVenuesProvider),
                ),
                data: (venues) => venues.isEmpty
                    ? const _SheetNotice(
                        message: 'Aucun lieu sportif référencé autour de vous. '
                            'Saisissez-le vous-même ci-dessus.',
                      )
                    : _VenueList(venues: venues),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueList extends StatelessWidget {
  const _VenueList({required this.venues});

  final List<Venue> venues;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: venues.length,
      itemBuilder: (context, index) {
        final venue = venues[index];
        return ListTile(
          dense: true,
          leading: Text(
            venue.kind?.emoji ?? '📍',
            style: const TextStyle(fontSize: 20),
          ),
          title: Text(venue.name),
          subtitle: Text(
            [venue.kind?.label, _describeDistance(venue.distanceM)]
                .whereType<String>()
                .join(' · '),
          ),
          onTap: () => Navigator.of(context).pop(venue),
        );
      },
    );
  }

  static String? _describeDistance(double? meters) {
    if (meters == null) return null;
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _SheetNotice extends StatelessWidget {
  const _SheetNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.secondaryText),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
