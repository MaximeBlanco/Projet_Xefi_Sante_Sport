import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/sports.dart';
import '../data/calories_api.dart';
import '../data/session_repository.dart';
import '../models/sport_session.dart';
import 'gps_tracking_screen.dart';
import 'weight_prompt_dialog.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key, required this.repository});

  final SessionRepository repository;

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  SportDefinition? _selectedSport;
  final _durationController = TextEditingController(text: '30');
  bool _isSaving = false;

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<double?> _ensureWeightKg() async {
    final existing = widget.repository.weightKg;
    if (existing != null) return existing;

    final entered = await showDialog<double>(
      context: context,
      builder: (context) => const WeightPromptDialog(),
    );
    if (entered != null) await widget.repository.setWeightKg(entered);
    return entered;
  }

  Future<void> _startGpsTracking(SportDefinition sport) async {
    final weightKg = await _ensureWeightKg();
    if (!mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GpsTrackingScreen(
          sport: sport,
          repository: widget.repository,
          weightKg: weightKg,
        ),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _submit() async {
    final sport = _selectedSport;
    final duration = int.tryParse(_durationController.text);
    if (sport == null || duration == null || duration <= 0) return;

    setState(() => _isSaving = true);

    final weightKg = await _ensureWeightKg();
    double? caloriesBurned;
    if (weightKg != null) {
      caloriesBurned = await CaloriesApiClient().caloriesBurned(
        activity: sport.caloriesApiActivity,
        weightKg: weightKg,
        durationMin: duration,
      );
    }

    final session = SportSession(
      id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}',
      sportName: sport.name,
      emoji: sport.emoji,
      date: DateTime.now(),
      durationMin: duration,
      caloriesBurned: caloriesBurned,
    );

    await widget.repository.saveSession(session);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle séance')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sport', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sport in availableSports)
                  ChoiceChip(
                    label: Text('${sport.emoji} ${sport.name}'),
                    selected: _selectedSport == sport,
                    onSelected: (_) => setState(() => _selectedSport = sport),
                  ),
              ],
            ),
            if (_selectedSport != null && !_selectedSport!.isGpsTrackable) ...[
              const SizedBox(height: 24),
              const Text('Durée (minutes)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(suffixText: 'min'),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSport == null || _isSaving
                    ? null
                    : _selectedSport!.isGpsTrackable
                        ? () => _startGpsTracking(_selectedSport!)
                        : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _selectedSport?.isGpsTrackable ?? false
                            ? 'Démarrer le suivi GPS'
                            : 'Enregistrer',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
