import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';

/// Renders the loading, error and empty states shared by every screen that
/// reads a Riverpod [AsyncValue], so screens only describe their happy path.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.emptyMessage,
    this.isEmpty,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? emptyMessage;
  final bool Function(T data)? isEmpty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorState(
        onRetry: onRetry,
        error: error,
      ),
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return _EmptyState(
            message: emptyMessage ?? 'Aucune donnée à afficher pour le moment.',
          );
        }
        return builder(data);
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.onRetry, this.error});

  final VoidCallback? onRetry;

  /// Shown only in debug builds. "Vérifie ta connexion" is the right thing to
  /// tell a user and the wrong thing to tell a developer, who otherwise has to
  /// go read the browser console to learn which query actually failed.
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            Text(
              'Une erreur est survenue.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Vérifie ta connexion puis réessaie.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            if (kDebugMode && error != null) ...[
              const SizedBox(height: 12),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
