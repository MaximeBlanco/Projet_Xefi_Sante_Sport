import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/domain/achievement.dart';
import '../../core/domain/body_weight_range.dart';
import '../../core/domain/session_duration.dart';
import '../../core/localization/app_locale.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../models/profile_stats.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_editing_controller.dart';
import '../../providers/profile_provider.dart';
import '../../providers/profile_stats_provider.dart';
import '../../providers/team_provider.dart';
import '../../widgets/achievement_tile.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/member_card.dart';
import '../../widgets/monthly_points_chart.dart';
import '../../widgets/motion.dart';
import 'team_picker_sheet.dart';

const String _missingValuePlaceholder = '—';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _imagePicker = ImagePicker();

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final succeeded = await ref
        .read(profileEditingControllerProvider.notifier)
        .changeAvatar(File(picked.path), pickedAt: DateTime.now());
    if (!mounted) return;
    _reportOutcome(succeeded, 'Photo de profil mise à jour');
  }

  Future<void> _editName(Profile profile) async {
    final name = await _promptForText(
      title: 'Votre nom',
      initialValue: profile.name,
      hintText: 'Nom affiché dans le classement',
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Nom obligatoire' : null,
    );
    if (name == null || !mounted) return;

    final succeeded = await ref
        .read(profileEditingControllerProvider.notifier)
        .renameTo(name);
    if (!mounted) return;
    _reportOutcome(succeeded, 'Nom mis à jour');
  }

  Future<void> _editWeight(Profile profile) async {
    final rawWeight = await _promptForText(
      title: 'Votre poids',
      initialValue: profile.weightKg?.toString() ?? '',
      hintText: 'En kilogrammes',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final weightKg = double.tryParse(
          (value ?? '').trim().replaceAll(',', '.'),
        );
        if (weightKg == null) return 'Poids invalide';
        return BodyWeightRange.contains(weightKg)
            ? null
            : BodyWeightRange.invalidMessage;
      },
    );
    if (rawWeight == null || !mounted) return;

    final weightKg = double.parse(rawWeight.trim().replaceAll(',', '.'));
    final succeeded = await ref
        .read(profileEditingControllerProvider.notifier)
        .updateWeight(weightKg);
    if (!mounted) return;
    _reportOutcome(succeeded, 'Poids mis à jour');
  }

  Future<String?> _promptForText({
    required String title,
    required String initialValue,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextPromptDialog(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await _confirm(
      title: 'Se déconnecter ?',
      message:
          'Vous devrez saisir à nouveau votre e-mail et votre mot de '
          'passe pour revenir.',
      confirmLabel: 'Se déconnecter',
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // gotrue clears the local session before its network call, so the screen
      // returns to the login page either way; only the remote revocation is in
      // doubt, and that is worth saying.
      messenger.showSnackBar(
        const SnackBar(content: Text('Déconnexion partielle, réessayez.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _confirm(
      title: 'Supprimer le compte ?',
      message:
          'Votre profil, vos séances, vos points et votre photo seront '
          'supprimés définitivement. Vous disparaîtrez du classement. Cette '
          'action est irréversible.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final succeeded = await ref
        .read(profileEditingControllerProvider.notifier)
        .deleteAccount();
    // On success the auth listener has already replaced this screen, so there
    // is nothing left to tell: only a failure needs a word.
    if (succeeded || !mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('La suppression a échoué, réessayez plus tard.'),
      ),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          // Explicitly neutral: the theme paints every text button red, which
          // on a destructive dialog made backing out look exactly as grave as
          // going through with it.
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryText,
            ),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: isDestructive
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _reportOutcome(bool succeeded, String successMessage) {
    final error = ref.read(profileEditingControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? successMessage
              : 'La mise à jour a échoué${error is SignedOutWhileEditingException ? ' : $error' : ', réessayez.'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final isSaving = ref.watch(profileEditingControllerProvider).isLoading;

    return AsyncValueView<Profile?>(
      value: profile,
      onRetry: () => ref.invalidate(currentProfileProvider),
      emptyMessage: 'Profil introuvable.',
      isEmpty: (data) => data == null,
      builder: (data) => _ProfileBody(
        profile: data!,
        isSaving: isSaving,
        onPickAvatar: _pickAvatar,
        onEditName: () => _editName(data),
        onEditWeight: () => _editWeight(data),
        onSignOut: _signOut,
        onDeleteAccount: _deleteAccount,
      ),
    );
  }
}

/// Owns its own controller so it is disposed with the route.
///
/// Disposing a controller from the caller once `showDialog` completes fires
/// while the closing animation still has the field mounted, and the framework
/// asserts on the field depending on a disposed controller.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.validator,
    this.keyboardType,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: widget.hintText),
          validator: widget.validator,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}

/// The two faces of the profile: what you have done, and what you can change.
///
/// They are tabs rather than one long scroll because the settings are visited
/// rarely and would otherwise push the numbers off the first screen.
class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({
    required this.profile,
    required this.isSaving,
    required this.onPickAvatar,
    required this.onEditName,
    required this.onEditWeight,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final Profile profile;
  final bool isSaving;
  final VoidCallback onPickAvatar;
  final VoidCallback onEditName;
  final VoidCallback onEditWeight;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  _ProfileTab _tab = _ProfileTab.activity;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(profileStatsProvider);

    return AsyncValueView<ProfileStats>(
      value: stats,
      onRetry: () => ref.invalidate(profileStatsProvider),
      builder: (data) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          ScaleIn(
            child: MemberCard(
              profile: widget.profile,
              stats: data,
              onTapAvatar: widget.isSaving ? null : widget.onPickAvatar,
            ),
          ),
          const SizedBox(height: 20),
          RiseIn(
            delay: staggerFor(1),
            child: _TabSelector(
              current: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
          ),
          const SizedBox(height: 16),
          // Keyed on the tab so the entrance animations replay when you switch,
          // which is what makes the swap read as a change of content.
          KeyedSubtree(
            key: ValueKey(_tab),
            child: switch (_tab) {
              _ProfileTab.activity => _ActivityTab(stats: data),
              _ProfileTab.badges => _BadgesTab(stats: data),
              _ProfileTab.settings => _SettingsTab(
                profile: widget.profile,
                isSaving: widget.isSaving,
                onPickAvatar: widget.onPickAvatar,
                onEditName: widget.onEditName,
                onEditWeight: widget.onEditWeight,
                onSignOut: widget.onSignOut,
                onDeleteAccount: widget.onDeleteAccount,
              ),
            },
          ),
        ],
      ),
    );
  }
}

enum _ProfileTab {
  activity('Activité'),
  badges('Badges'),
  settings('Réglages');

  const _ProfileTab(this.label);

  final String label;
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.current, required this.onChanged});

  final _ProfileTab current;
  final ValueChanged<_ProfileTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final tab in _ProfileTab.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(tab),
                child: AnimatedContainer(
                  duration: animate
                      ? const Duration(milliseconds: 220)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: tab == current
                        ? AppColors.black
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Semantics(
                    selected: tab == current,
                    child: Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tab == current
                            ? AppColors.white
                            : AppColors.secondaryText.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.stats});

  final ProfileStats stats;

  String get _monthLabel {
    final month = stats.lastSixMonths.last.month;
    try {
      return DateFormat('MMMM yyyy', AppLocale.french).format(month);
    } on Exception {
      return DateFormat('MM/yyyy').format(month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final panels = <Widget>[
      _Panel(
        title: 'Résumé du mois',
        subtitle: _monthLabel,
        child: _MonthSummary(stats: stats),
      ),
      _Panel(
        title: 'Six derniers mois',
        subtitle: 'Points par mois',
        child: MonthlyPointsChart(
          months: stats.lastSixMonths,
          best: stats.bestMonthPoints,
        ),
      ),
      _Panel(
        title: 'Records personnels',
        child: _PersonalRecords(stats: stats),
      ),
      if (stats.sportBreakdown.isNotEmpty)
        _Panel(
          title: 'Répartition par sport',
          subtitle: 'Temps cumulé',
          child: Column(
            children: [
              for (final tally in stats.sportBreakdown.take(6))
                _SportBar(
                  tally: tally,
                  best: stats.sportBreakdown.first.totalDurationMin,
                ),
            ],
          ),
        ),
    ];

    return Column(
      children: [
        if (!stats.hasSessions) ...[
          const _EmptyActivityNote(),
          const SizedBox(height: 14),
        ],
        for (var index = 0; index < panels.length; index++) ...[
          RiseIn(delay: staggerFor(index + 2), child: panels[index]),
          if (index < panels.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final progressList = Achievements.evaluate(stats);
    final earned = progressList.where((entry) => entry.isEarned).length;
    final nextUp = progressList.firstWhere(
      (entry) => !entry.isEarned,
      orElse: () => progressList.last,
    );

    return Column(
      children: [
        RiseIn(
          delay: staggerFor(2),
          child: _Panel(
            title: 'Mes badges',
            subtitle: '$earned sur ${progressList.length}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressList.isEmpty
                        ? 0
                        : earned / progressList.length,
                    minHeight: 6,
                    backgroundColor: AppColors.black.withValues(alpha: 0.07),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  earned == progressList.length
                      ? 'Tous les badges sont débloqués. Bravo.'
                      : 'Prochain badge · ${nextUp.achievement.label} '
                            '(${nextUp.value}/${nextUp.achievement.target})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Two columns at a fixed aspect rather than a free-flowing wrap: badges
        // are compared against each other, and equal-sized tiles are what makes
        // a wall of them scannable.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: progressList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) => ScaleIn(
            delay: staggerFor(index + 3, step: 40),
            child: AchievementTile(progress: progressList[index]),
          ),
        ),
      ],
    );
  }
}

class _EmptyActivityNote extends StatelessWidget {
  const _EmptyActivityNote();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enregistrez une première séance pour voir vos statistiques se remplir.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SummaryCell(
              label: 'Séances',
              value: '${stats.monthSessionCount}',
              count: stats.monthSessionCount,
            ),
            const _CellDivider(),
            _SummaryCell(
              label: 'Temps',
              value: SessionDuration.describeMinutes(stats.monthDurationMin),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: AppColors.black.withValues(alpha: 0.07), height: 1),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SummaryCell(
              label: 'Points',
              value: '${stats.monthPoints}',
              count: stats.monthPoints,
            ),
            const _CellDivider(),
            _SummaryCell(
              label: 'Jours actifs',
              value: '${stats.monthActiveDays}',
              count: stats.monthActiveDays,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value, this.count});

  final String label;
  final String value;

  /// When set, the figure counts up instead of simply appearing.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final valueStyle = textTheme.headlineMedium?.copyWith(
      fontSize: 24,
      color: AppColors.black,
    );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.bodySmall?.copyWith(
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.secondaryText.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          count == null
              ? Text(value, style: valueStyle)
              : AnimatedCounter(value: count!, style: valueStyle),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    // Fixed rather than stretched: the cells sit in a ListView, where a
    // stretching row would be asked to lay out against an infinite height.
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.black.withValues(alpha: 0.07),
    );
  }
}

class _PersonalRecords extends StatelessWidget {
  const _PersonalRecords({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The two standing figures lead: they used to sit on the member card,
        // which now carries identity only, and they belong somewhere.
        _RecordRow(
          icon: Icons.stars_outlined,
          label: 'Points au total',
          value: '${stats.totalPoints} pts',
        ),
        _RecordRow(
          icon: Icons.bolt_outlined,
          label: 'Série en cours',
          value: stats.currentStreakDays == 1
              ? '1 jour'
              : '${stats.currentStreakDays} jours',
        ),
        _RecordRow(
          icon: Icons.timer_outlined,
          label: 'Plus longue séance',
          value: SessionDuration.describeMinutes(stats.longestSessionMin),
        ),
        _RecordRow(
          icon: Icons.calendar_view_week_outlined,
          label: 'Meilleure semaine',
          value: '${stats.bestWeekPoints} pts',
        ),
        _RecordRow(
          icon: Icons.calendar_month_outlined,
          // Named for the window it covers: the chart only holds six months, so
          // claiming an all-time best here would be a claim we cannot make.
          label: 'Meilleur mois (6 derniers)',
          value: '${stats.bestMonthPoints} pts',
        ),
        _RecordRow(
          icon: Icons.speed_outlined,
          label: 'Séance moyenne',
          value: SessionDuration.describeMinutes(stats.averageDurationMin),
        ),
        _RecordRow(
          icon: Icons.local_fire_department_outlined,
          label: 'Calories brûlées',
          value: stats.hasCaloriesData
              ? '${stats.totalCaloriesBurned.round()} kcal'
              : _missingValuePlaceholder,
          isLast: true,
        ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.secondaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _SportBar extends StatelessWidget {
  const _SportBar({required this.tally, required this.best});

  final SportTally tally;
  final int best;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final share = best <= 0
        ? 0.0
        : (tally.totalDurationMin / best).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tally.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tally.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Text(
                SessionDuration.describeMinutes(tally.totalDurationMin),
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: animate ? 0 : share, end: share),
              duration: animate
                  ? const Duration(milliseconds: 650)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.black.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.profile,
    required this.isSaving,
    required this.onPickAvatar,
    required this.onEditName,
    required this.onEditWeight,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final Profile profile;
  final bool isSaving;
  final VoidCallback onPickAvatar;
  final VoidCallback onEditName;
  final VoidCallback onEditWeight;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RiseIn(
          delay: staggerFor(2),
          child: _Panel(
            title: 'Mon compte',
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.photo_camera_outlined,
                  label: 'Photo de profil',
                  value: profile.avatarUrl == null ? 'Ajouter' : 'Modifier',
                  onTap: isSaving ? null : onPickAvatar,
                ),
                _SettingRow(
                  icon: Icons.badge_outlined,
                  label: 'Nom',
                  value: profile.name,
                  onTap: isSaving ? null : onEditName,
                ),
                _SettingRow(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Poids',
                  value: profile.weightKg == null
                      ? _missingValuePlaceholder
                      : '${profile.weightKg!.toStringAsFixed(0)} kg',
                  onTap: isSaving ? null : onEditWeight,
                ),
                _TeamSettingRow(profile: profile, isSaving: isSaving),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Its own panel, below the edits: leaving and deleting are not settings
        // among others, and putting them one tap away from the weight field is
        // how they get hit by accident.
        RiseIn(
          delay: staggerFor(3),
          child: _Panel(
            title: 'Session',
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.logout,
                  label: 'Déconnexion',
                  onTap: isSaving ? null : onSignOut,
                ),
                _SettingRow(
                  icon: Icons.delete_outline,
                  label: 'Supprimer mon compte',
                  isDestructive: true,
                  onTap: isSaving ? null : onDeleteAccount,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        if (isSaving) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }
}

/// The team row, which has to read the team list to name the current team.
///
/// Its own widget so the rest of the settings stay a plain layout: only this
/// one line depends on a provider that can still be loading.
class _TeamSettingRow extends ConsumerWidget {
  const _TeamSettingRow({required this.profile, required this.isSaving});

  final Profile profile;
  final bool isSaving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(currentTeamProvider).valueOrNull;
    final waiting =
        ref.watch(pendingJoinRequestsProvider).valueOrNull?.length ?? 0;

    return _SettingRow(
      icon: Icons.groups_outlined,
      label: 'Mon équipe',
      // Requests are decided inside the sheet, which nobody opens without a
      // reason to: the count is that reason, and without it an owner would
      // leave people waiting indefinitely.
      value: waiting > 0
          ? (waiting == 1 ? '1 demande' : '$waiting demandes')
          : team?.name ?? 'Aucune',
      isValueUrgent: waiting > 0,
      onTap: isSaving
          ? null
          : () => TeamPickerSheet.show(context, currentTeamId: profile.teamId),
      isLast: true,
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.isDestructive = false,
    this.isValueUrgent = false,
    this.isLast = false,
  });

  /// Draws the value in red rather than grey, for the one case where it is
  /// something waiting on you rather than a setting you can read past.
  final bool isValueUrgent;

  final IconData icon;
  final String label;

  /// Absent on a row that is an action rather than a value you can read.
  final String? value;
  final VoidCallback? onTap;

  /// Draws the row in the primary red, which the identity reserves for calls to
  /// action and, here, for the one action nothing undoes.
  final bool isDestructive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelColour = isDestructive
        ? AppColors.primary
        : AppColors.secondaryText;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: isDestructive
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: labelColour,
                  ),
                ),
              ),
              if (value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: isValueUrgent
                          ? FontWeight.w800
                          : FontWeight.w400,
                      color: isValueUrgent
                          ? AppColors.primary
                          : AppColors.secondaryText.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFB0B2BE),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A white card with a titled header, the unit the activity tab is built from.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.black,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
