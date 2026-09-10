import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sport_session.dart';
import '../theme/app_theme.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session});

  final SportSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(session.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.sportName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd('fr_FR').format(session.date),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.durationMin} min',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (session.distanceKm != null)
                  Text(
                    '${session.distanceKm!.toStringAsFixed(2)} km',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                if (session.caloriesBurned != null)
                  Text(
                    '${session.caloriesBurned!.round()} kcal',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
