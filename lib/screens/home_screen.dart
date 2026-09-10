import 'package:flutter/material.dart';

import '../data/session_repository.dart';
import '../models/sport_session.dart';
import '../widgets/session_card.dart';
import 'add_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final SessionRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<SportSession> _sessions = widget.repository.getAllSessions();

  Future<void> _openAddSession() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddSessionScreen(repository: widget.repository),
      ),
    );
    if (saved == true) {
      setState(() => _sessions = widget.repository.getAllSessions());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes séances')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSession,
        child: const Icon(Icons.add),
      ),
      body: _sessions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏃', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune séance pour l\'instant',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoute ta première séance de sport.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: _sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => SessionCard(session: _sessions[index]),
            ),
    );
  }
}
