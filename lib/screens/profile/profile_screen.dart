import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/domain/body_weight_range.dart';
import '../../core/domain/session_duration.dart';
import '../../core/domain/stats_period.dart';
import '../../core/localization/app_locale.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../models/profile_stats.dart';
import '../../providers/profile_editing_controller.dart';
import '../../providers/profile_provider.dart';
import '../../providers/profile_stats_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/profile_avatar.dart';

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
        .changeAvatar(picked, pickedAt: DateTime.now());
    if (!mounted) return;
    _reportOutcome(succeeded, 'Photo de profil mise à jour');
  }

  Future<void> _editName(Profile profile) async {
    final name = await _promptForText(
      title: 'Votre nom',
      initialValue: profile.name,
      hintText: 'Nom affiché dans le classement',
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Nom obligatoire'
          : null,
    );
    if (name == null || !mounted) return;

    final succeeded =
        await ref.read(profileEditingControllerProvider.notifier).renameTo(name);
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
        final weightKg = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
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
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
    required this.profile,
    required this.isSaving,
    required this.onPickAvatar,
    required this.onEditName,
    required this.onEditWeight,
  });

  final Profile profile;
  final bool isSaving;
  final VoidCallback onPickAvatar;
  final VoidCallback onEditName;
  final VoidCallback onEditWeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);
    final period = ref.watch(statsPeriodProvider);

    return RefreshIndicator(
      // The stats derive from the sessions, so refreshing them means refetching
      // those rather than invalidating a value that only ever recomputes.
      onRefresh: () async {
        ref.invalidate(currentProfileProvider);
        ref.invalidate(userSessionsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          Center(
            child: _EditableAvatar(
              profile: profile,
              isSaving: isSaving,
              onTap: isSaving ? null : onPickAvatar,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: _NameHeading(name: profile.name, onEdit: onEditName),
          ),
          const SizedBox(height: 8),
          Center(child: _WeightLine(profile: profile, onEdit: onEditWeight)),
          const SizedBox(height: 40),
          const _SectionLabel('Statistiques'),
          const SizedBox(height: 12),
          // Outside the AsyncValueView so the control the user just tapped does
          // not vanish underneath them while the numbers behind it settle.
          _PeriodSelector(
            selected: period,
            onSelected: (period) =>
                ref.read(statsPeriodProvider.notifier).state = period,
          ),
          const SizedBox(height: 20),
          AsyncValueView<ProfileStats>(
            value: stats,
            onRetry: () => ref.invalidate(userSessionsProvider),
            builder: (data) => _StatsSection(stats: data, period: period),
          ),
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.profile,
    required this.isSaving,
    required this.onTap,
  });

  final Profile profile;
  final bool isSaving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Changer la photo de profil',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ProfileAvatar(
              name: profile.name,
              avatarUrl: profile.avatarUrl,
              radius: 56,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const ShapeDecoration(
                color: AppColors.primary,
                shape: CircleBorder(),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera,
                      size: 16,
                      color: AppColors.white,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameHeading extends StatelessWidget {
  const _NameHeading({required this.name, required this.onEdit});

  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: 'Modifier le nom',
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _WeightLine extends StatelessWidget {
  const _WeightLine({required this.profile, required this.onEdit});

  final Profile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final weightKg = profile.weightKg;
    return TextButton.icon(
      onPressed: onEdit,
      icon: const Icon(Icons.monitor_weight_outlined, size: 18),
      label: Text(
        weightKg == null
            ? 'Ajouter votre poids'
            : '${weightKg.toStringAsFixed(weightKg.truncateToDouble() == weightKg ? 0 : 1)} kg',
      ),
    );
  }
}

/// Lets the profile answer "what have I done" over a week, a month or the whole
/// history without three separate screens saying the same thing.
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});

  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatsPeriod>(
      segments: [
        for (final period in StatsPeriod.values)
          ButtonSegment<StatsPeriod>(
            value: period,
            label: Text(period.label),
          ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelected(selection.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats, required this.period});

  final ProfileStats stats;
  final StatsPeriod period;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasSessions) {
      return Text(
        period.emptyMessage,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatGrid(stats: stats),
        const SizedBox(height: 32),
        const _SectionLabel('Répartition par sport'),
        const SizedBox(height: 16),
        for (final tally in stats.sportBreakdown)
          _SportBar(tally: tally, totalDurationMin: stats.totalDurationMin),
        // Only over the whole history: the first session of a filtered week is
        // just its oldest one, which this sentence would misname.
        if (period == StatsPeriod.allTime && stats.firstSessionDate != null) ...[
          const SizedBox(height: 24),
          Text(
            'Premier entraînement le '
            '${DateFormat('d MMMM yyyy', AppLocale.french).format(stats.firstSessionDate!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final totalDistanceKm = stats.totalDistanceKm;
    final tiles = <Widget>[
      _StatTile(value: '${stats.totalPoints}', label: 'points'),
      _StatTile(value: '${stats.sessionCount}', label: 'séances'),
      _StatTile(
        value: SessionDuration.describeMinutes(stats.totalDurationMin),
        label: 'de sport',
      ),
      _StatTile(
        value: SessionDuration.describeMinutes(stats.averageDurationMin),
        label: 'en moyenne',
      ),
      _StatTile(
        value: SessionDuration.describeMinutes(stats.longestSessionMin),
        label: 'plus longue',
      ),
      _StatTile(
        value: stats.hasCaloriesData
            ? '${stats.totalCaloriesBurned.round()}'
            : _missingValuePlaceholder,
        label: 'kcal',
      ),
      if (totalDistanceKm != null)
        _StatTile(
          value: totalDistanceKm.toStringAsFixed(1),
          label: 'km parcourus',
        ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            child: Text(
              value,
              style: textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: textTheme.bodySmall, maxLines: 1),
        ],
      ),
    );
  }
}

class _SportBar extends StatelessWidget {
  const _SportBar({required this.tally, required this.totalDurationMin});

  final SportTally tally;
  final int totalDurationMin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final share = totalDurationMin == 0
        ? 0.0
        : tally.totalDurationMin / totalDurationMin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tally.emoji, style: textTheme.titleMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tally.label,
                  style: textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                SessionDuration.describeMinutes(tally.totalDurationMin),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              backgroundColor: AppColors.black.withValues(alpha: 0.06),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
    );
  }
}
