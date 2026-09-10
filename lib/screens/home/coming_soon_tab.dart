import 'package:flutter/material.dart';

class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label — bientôt disponible',
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
