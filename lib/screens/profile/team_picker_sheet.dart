import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/team.dart';
import '../../models/team_join_request.dart';
import '../../providers/team_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/profile_avatar.dart';

/// Asking to join a team, creating one, leaving, and — if you own one —
/// deciding who gets in.
///
/// A sheet rather than a screen: it is a one-decision errand, and the list of
/// teams in a company is short enough to read in one go.
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

  /// Runs an action and reports it, closing the sheet only when the errand is
  /// over. Deciding on a request is not: an owner with three people waiting
  /// should not have the sheet shut in their face after the first one.
  Future<void> _apply(
    Future<bool> Function() action,
    String successMessage, {
    bool closeOnSuccess = true,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final succeeded = await action();
    if (!mounted) return;

    if (succeeded && closeOnSuccess) navigator.pop();
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
    final myRequests = ref.watch(myJoinRequestsProvider).valueOrNull ?? const [];
    final toDecide =
        ref.watch(pendingJoinRequestsProvider).valueOrNull ?? const [];
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
                          if (toDecide.isNotEmpty) ...[
                            _PendingRequests(
                              requests: toDecide,
                              isBusy: isBusy,
                              onDecide: (request, accepted) => _apply(
                                () => ref
                                    .read(
                                      teamMembershipControllerProvider.notifier,
                                    )
                                    .decide(
                                      requestId: request.id,
                                      accepted: accepted,
                                    ),
                                accepted
                                    ? '${request.applicantName ?? "La demande"} a rejoint votre équipe'
                                    : 'Demande refusée',
                                closeOnSuccess: false,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          for (final team in list)
                            _TeamOption(
                              team: team,
                              isCurrent: team.id == widget.currentTeamId,
                              request: _requestFor(myRequests, team.id),
                              isBusy: isBusy,
                              hasTeam: widget.currentTeamId != null,
                              onAsk: () => _apply(
                                () => ref
                                    .read(
                                      teamMembershipControllerProvider.notifier,
                                    )
                                    .requestToJoin(team.id),
                                'Demande envoyée à ${team.name}',
                              ),
                              onWithdraw: (requestId) => _apply(
                                () => ref
                                    .read(
                                      teamMembershipControllerProvider.notifier,
                                    )
                                    .withdrawRequest(requestId),
                                'Demande annulée',
                                closeOnSuccess: false,
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

  static TeamJoinRequest? _requestFor(
    List<TeamJoinRequest> requests,
    String teamId,
  ) {
    for (final request in requests) {
      if (request.teamId == teamId) return request;
    }
    return null;
  }
}

/// What the owner of a team sees: who is waiting, and the two buttons.
class _PendingRequests extends StatelessWidget {
  const _PendingRequests({
    required this.requests,
    required this.isBusy,
    required this.onDecide,
  });

  final List<TeamJoinRequest> requests;
  final bool isBusy;
  final void Function(TeamJoinRequest request, bool accepted) onDecide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            requests.length == 1
                ? '1 DEMANDE EN ATTENTE'
                : '${requests.length} DEMANDES EN ATTENTE',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          for (final request in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: request.applicantName ?? '?',
                    avatarUrl: request.applicantAvatarUrl,
                    radius: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      request.applicantName ?? 'Quelqu\'un',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isBusy ? null : () => onDecide(request, false),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    tooltip: 'Refuser',
                    color: AppColors.secondaryText,
                  ),
                  IconButton(
                    onPressed: isBusy ? null : () => onDecide(request, true),
                    icon: const Icon(Icons.check_circle),
                    iconSize: 22,
                    tooltip: 'Accepter',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamOption extends StatelessWidget {
  const _TeamOption({
    required this.team,
    required this.isCurrent,
    required this.request,
    required this.isBusy,
    required this.hasTeam,
    required this.onAsk,
    required this.onWithdraw,
  });

  final Team team;
  final bool isCurrent;

  /// The signed-in user's own request for this team, if they have made one.
  final TeamJoinRequest? request;
  final bool isBusy;

  /// Somebody already in a team cannot ask to join another without leaving
  /// first; offering the button anyway would only produce a refusal.
  final bool hasTeam;
  final VoidCallback onAsk;
  final void Function(String requestId) onWithdraw;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWaiting = request?.isPending ?? false;
    final wasDeclined = request?.status == JoinRequestStatus.declined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: (isBusy || isCurrent || isWaiting || hasTeam) ? null : onAsk,
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
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isCurrent ? AppColors.primary : AppColors.secondaryText,
          ),
        ),
        subtitle: switch ((isCurrent, isWaiting, wasDeclined, hasTeam)) {
          (true, _, _, _) => null,
          (_, true, _, _) => const Text('Demande en attente'),
          (_, _, true, _) => const Text('Demande refusée'),
          (_, _, _, true) => const Text('Quittez votre équipe pour rejoindre'),
          _ => const Text('Toucher pour demander à rejoindre'),
        },
        trailing: isCurrent
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : isWaiting
            ? TextButton(
                onPressed: isBusy ? null : () => onWithdraw(request!.id),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryText,
                ),
                child: const Text('Annuler'),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
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
            const SizedBox(height: 16),
            Text(
              'Vous en serez le responsable : les demandes pour rejoindre '
              'votre équipe passeront par vous.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: AppColors.secondaryText.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
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
