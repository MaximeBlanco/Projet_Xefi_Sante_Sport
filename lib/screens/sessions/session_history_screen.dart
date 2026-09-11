import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/session.dart';
import '../../providers/session_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/motion.dart';
import '../../widgets/session_tile.dart';

const _ground = Color(0xFFF4F4F6);
const _timelineColumnWidth = 34.0;

class SessionHistoryScreen extends ConsumerStatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  ConsumerState<SessionHistoryScreen> createState() =>
      _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends ConsumerState<SessionHistoryScreen> {
  /// Null means "Tous".
  String? _sportIdFilter;

  Future<void> _refreshSessions() async {
    ref.invalidate(userSessionsProvider);
    try {
      await ref.read(userSessionsProvider.future);
    } catch (_) {
      // The rebuilt view already shows the error state and its retry action.
    }
  }

  /// Built from the sports actually recorded rather than from the catalogue, so
  /// no filter can lead to an empty list.
  List<Session> _distinctSports(List<Session> sessions) {
    final seen = <String>{};
    return [
      for (final session in sessions)
        if (session.sport != null && seen.add(session.sportId)) session,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userSessions = ref.watch(userSessionsProvider);

    return ColoredBox(
      color: _ground,
      child: AsyncValueView<List<Session>>(
        value: userSessions,
        onRetry: () => ref.invalidate(userSessionsProvider),
        emptyMessage:
            'Aucune séance enregistrée pour le moment.\n'
            'Appuyez sur + pour enregistrer la première.',
        isEmpty: (sessions) => sessions.isEmpty,
        builder: (sessions) {
          final filtered = _sportIdFilter == null
              ? sessions
              : sessions
                    .where((session) => session.sportId == _sportIdFilter)
                    .toList();

          return Column(
            children: [
              _SportFilterBar(
                sportsInHistory: _distinctSports(sessions),
                selectedSportId: _sportIdFilter,
                onSelected: (sportId) =>
                    setState(() => _sportIdFilter = sportId),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshSessions,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => SlideIn(
                      delay: staggerFor(index),
                      child: _TimelineEntry(
                        isFirst: index == 0,
                        isLast: index == filtered.length - 1,
                        child: SessionTile(session: filtered[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The rail and its dots, drawn beside each card so the history reads as one
/// thread through time rather than as a stack of unrelated cards.
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.child,
    required this.isFirst,
    required this.isLast,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timelineColumnWidth,
            child: CustomPaint(
              painter: _TimelinePainter(isFirst: isFirst, isLast: isLast),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({required this.isFirst, required this.isLast});

  static const _dotRadius = 5.0;
  static const _dotCentreY = 34.0;

  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final centreX = size.width / 2;
    final rail = Paint()
      ..color = AppColors.black.withValues(alpha: 0.10)
      ..strokeWidth = 1.5;

    // The rail stops at the first dot and after the last, so the thread has
    // ends rather than running off the screen at both edges.
    canvas.drawLine(
      Offset(centreX, isFirst ? _dotCentreY : 0),
      Offset(centreX, isLast ? _dotCentreY : size.height),
      rail,
    );

    canvas.drawCircle(
      Offset(centreX, _dotCentreY),
      _dotRadius,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) =>
      oldDelegate.isFirst != isFirst || oldDelegate.isLast != isLast;
}

class _SportFilterBar extends StatelessWidget {
  const _SportFilterBar({
    required this.sportsInHistory,
    required this.selectedSportId,
    required this.onSelected,
  });

  /// One session per distinct sport, carrying the sport to label the chip.
  final List<Session> sportsInHistory;
  final String? selectedSportId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _FilterChip(
            label: 'Tous',
            isSelected: selectedSportId == null,
            onTap: () => onSelected(null),
          ),
          for (final session in sportsInHistory)
            _FilterChip(
              label: session.sport!.name,
              isSelected: selectedSportId == session.sportId,
              onTap: () => onSelected(session.sportId),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? AppColors.black : AppColors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? AppColors.black
                    : AppColors.black.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
