import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../rankings/global_ranking_screen.dart';
import '../sessions/record_session_screen.dart';
import '../sessions/session_history_screen.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  static const _sessionsTabIndex = 0;

  int _selectedTabIndex = _sessionsTabIndex;

  void _openRecordSessionScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => const RecordSessionScreen()),
    );
  }

  /// gotrue clears the local session before its network call, so the UI always
  /// returns to the login screen. Left unawaited, a failing remote sign-out
  /// would surface only as an uncaught async error.
  Future<void> _signOut() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Déconnexion partielle, réessayez.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabScreens = <Widget>[
      const SessionHistoryScreen(),
      const GlobalRankingScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('XEFI Sport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _signOut,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedTabIndex, children: tabScreens),
      floatingActionButton: _selectedTabIndex == _sessionsTabIndex
          ? FloatingActionButton.extended(
              onPressed: _openRecordSessionScreen,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle séance'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Séances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Classement',
          ),
        ],
      ),
    );
  }
}
