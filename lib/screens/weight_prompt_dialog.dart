import 'package:flutter/material.dart';

class WeightPromptDialog extends StatefulWidget {
  const WeightPromptDialog({super.key});

  @override
  State<WeightPromptDialog> createState() => _WeightPromptDialogState();
}

class _WeightPromptDialogState extends State<WeightPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) return;
    Navigator.of(context).pop(weight);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ton poids'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nécessaire pour calculer les calories brûlées.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(suffixText: 'kg'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        ElevatedButton(onPressed: _submit, child: const Text('Valider')),
      ],
    );
  }
}
