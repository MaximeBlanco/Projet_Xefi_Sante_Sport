import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/localization/app_locale.dart';
import '../../core/theme/app_colors.dart';
import '../../models/session.dart';
import '../../providers/delete_session_controller.dart';
import '../../widgets/route_map.dart';

/// Shows the route of a tracked session. Reached by tapping a history tile,
/// rather than embedding a map in every row: each map pulls its own tiles, and
/// a list of them would hammer the OSM servers for something nobody is looking
/// at yet.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.session});

  final Session session;

  static DateFormat _buildDateFormat() {
    try {
      return DateFormat('dd MMMM yyyy', AppLocale.french);
    } on Exception {
      return DateFormat('dd/MM/yyyy');
    }
  }

  /// A session is the unit the score is built from, and deleting one silently
  /// would change the user's rank without them asking twice.
  Future<bool> _confirmDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la séance ?'),
        content: const Text(
          'Elle disparaîtra de votre historique, et ses points seront retirés '
          'de votre total et du classement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await _confirmDeletion(context)) return;
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final wasDeleted = await ref
        .read(deleteSessionControllerProvider.notifier)
        .delete(session.id);

    if (!context.mounted) return;

    if (wasDeleted) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Séance supprimée')),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('La suppression a échoué, réessayez.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sport = session.sport;
    final route = session.route ?? const [];
    final distanceKm = session.distanceKm;
    final elevationGainM = session.elevationGainM;
    final caloriesBurned = session.caloriesBurned;
    final isDeleting = ref.watch(deleteSessionControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(sport == null ? 'Séance' : '${sport.emoji} ${sport.name}'),
        actions: [
          IconButton(
            icon: isDeleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline),
            tooltip: 'Supprimer la séance',
            onPressed: isDeleting ? null : () => _delete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (route.isNotEmpty)
            Expanded(child: RouteMap(route: route))
          else
            Expanded(child: _NoRouteNotice(isGpsTrackable: sport?.isGpsTrackable ?? false)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _buildDateFormat().format(session.date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (session.venue != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.venue!.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 32,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _DetailStat(
                        label: 'Durée',
                        value: '${session.durationMin} min',
                      ),
                      _DetailStat(label: 'Points', value: '${session.points}'),
                      if (caloriesBurned != null)
                        _DetailStat(
                          label: 'Calories',
                          value: '${session.caloriesEstimated ? '≈ ' : ''}'
                              '${caloriesBurned.round()} kcal',
                        ),
                      if (distanceKm != null)
                        _DetailStat(
                          label: 'Distance',
                          value: '${distanceKm.toStringAsFixed(2)} km',
                        ),
                      if (elevationGainM != null)
                        _DetailStat(
                          label: 'D+',
                          value: '${elevationGainM.round()} m',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the map on a session recorded without following a route,
/// which is every manually entered one. An empty white half-screen reads as a
/// map that failed to load, so it says which it is.
class _NoRouteNotice extends StatelessWidget {
  const _NoRouteNotice({required this.isGpsTrackable});

  /// Only a sport that could have been tracked gets told how to get a map;
  /// suggesting it for a swim would be pointing at a feature it never offers.
  final bool isGpsTrackable;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 40,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun parcours enregistré',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            if (isGpsTrackable) ...[
              const SizedBox(height: 8),
              Text(
                'Utilisez « Suivre le parcours en direct » au moment '
                "d'enregistrer pour voir votre trajet ici.",
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
