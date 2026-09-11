import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../../providers/session_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/session_tile.dart';
import '../../widgets/xefi_backdrop.dart';

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  static const _listPadding = EdgeInsets.fromLTRB(16, 16, 16, 96);

  Future<void> _refreshSessions(WidgetRef ref) async {
    ref.invalidate(userSessionsProvider);
    try {
      await ref.read(userSessionsProvider.future);
    } catch (_) {
      // The rebuilt view already shows the error state and its retry action.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSessions = ref.watch(userSessionsProvider);

    return XefiBackdrop(
      child: AsyncValueView<List<Session>>(
        value: userSessions,
        onRetry: () => ref.invalidate(userSessionsProvider),
        emptyMessage:
            'Aucune séance enregistrée pour le moment.\n'
            'Appuyez sur + pour enregistrer la première.',
        isEmpty: (sessions) => sessions.isEmpty,
        builder: (sessions) => RefreshIndicator(
          onRefresh: () => _refreshSessions(ref),
          child: ListView.separated(
            padding: _listPadding,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                SessionTile(session: sessions[index]),
          ),
        ),
      ),
    );
  }
}
