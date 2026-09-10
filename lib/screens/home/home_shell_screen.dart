import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import 'coming_soon_tab.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    ComingSoonTab(label: 'Mes séances'),
    ComingSoonTab(label: 'Classement'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XEFI Sport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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
