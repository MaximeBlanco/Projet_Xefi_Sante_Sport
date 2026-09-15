import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/team.dart';
import '../../providers/team_provider.dart';
import '../../widgets/async_value_view.dart';

/// Picking, creating or leaving a team.
///
/// A sheet rather than a screen: joining a team is a one-decision errand, and
/// the list of teams in a company is short enough to read in one go.
class TeamPickerSheet extends ConsumerStatefulWidget {
  const TeamPickerSheet({super.key, required this.currentTeamId});

  final String? currentTeamId;

  static Future<void> show(BuildContext context, {String? currentTeamId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => TeamPickerSheet(currentTeamId: currentTeamId),
    );
  }

  @override
  ConsumerState<TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends ConsumerState<TeamPickerSheet> {
  bool _isCreating = false;

  Future<void> _apply(Future<bool> Function() action, String successMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final succeeded = await action();
    if (!mounted) return;

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          succeeded ? successMessage : 'Opération impossible, réessayez.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final teams = ref.watch(teamsProvider);
    final isBusy = ref.watch(teamMembershipControllerProvider).isLoading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isCreating ? 'Nouvelle équipe' : 'Mon équipe',
                      style: textTheme.headlineMedium?.copyWith(fontSize: 20),
                    ),
                  ),
                  if (!_isCreating)
                    TextButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => setState(() => _isCreating = true),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Créer'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: _isCreating
                  ? _CreateTeamForm(
                      isBusy: isBusy,
                      onCancel: () => setState(() => _isCreating = false),
                      onSubmit: (name, colour) => _apply(
                        () => ref
                            .read(teamMembershipControllerProvider.notifier)
                            .createAndJoin(name: name, colorValue: colour),
                        'Équipe créée',
                      ),
                    )
                  : AsyncValueView<List<Team>>(
                      value: teams,
                      onRetry: () => ref.invalidate(teamsProvider),
                      isEmpty: (list) => list.isEmpty,
                      emptyMessage:
                          'Aucune équipe pour le moment.\n'
                          'Créez la première.',
                      builder: (list) => ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        children: [
                          for (final team in list)
                            _TeamOption(
                              team: team,
                              isCurrent: team.id == widget.currentTeamId,
                              onTap: isBusy
                                  ? null
                                  : () => _apply(
                                      () => ref
                                          .read(
                                            teamMembershipControllerProvider
                                                .notifier,
                                          )
                                          .join(team.id),
                                      'Vous avez rejoint ${team.name}',
                                    ),
                            ),
                          if (widget.currentTeamId != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () => _apply(
                                      () => ref
                                          .read(
                                            teamMembershipControllerProvider
                                                .notifier,
                                          )
                                          .leave(),
                                      'Vous avez quitté votre équipe',
                                    ),
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Quitter mon équipe'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamOption extends StatelessWidget {
  const _TeamOption({
    required this.team,
    required this.isCurrent,
    required this.onTap,
  });

  final Team team;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent
              ? AppColors.primary
              : AppColors.black.withValues(alpha: 0.07),
          width: isCurrent ? 2 : 1,
        ),
      ),
      leading: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: team.colour, shape: BoxShape.circle),
      ),
      title: Text(
        team.name,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: isCurrent ? AppColors.primary : AppColors.secondaryText,
        ),
      ),
      trailing: isCurrent
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }
}

class _CreateTeamForm extends StatefulWidget {
  const _CreateTeamForm({
    required this.isBusy,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isBusy;
  final VoidCallback onCancel;
  final void Function(String name, int colorValue) onSubmit;

  @override
  State<_CreateTeamForm> createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends State<_CreateTeamForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  int _colour = Team.palette.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_controller.text.trim(), _colour);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom de l’équipe',
                hintText: 'Les Rouges, Agence Lyon…',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nom obligatoire'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Text(
              'COULEUR',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                letterSpacing: 1,
                color: AppColors.secondaryText.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final value in Team.palette)
                  GestureDetector(
                    onTap: () => setState(() => _colour = value),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: value == _colour
                              ? AppColors.black
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: widget.isBusy ? null : widget.onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryText,
                  ),
                  child: const Text('Annuler'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: widget.isBusy ? null : _submit,
                  child: const Text('Créer et rejoindre'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
