import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/member_summary.dart';
import '../../providers/contact_provider.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/content_width.dart';
import '../../widgets/member_row.dart';
import 'contact_action.dart';

const _ground = Color(0xFFF4F4F6);

/// Below this, the search would return most of the company and help nobody.
const _minimumQueryLength = 2;

/// Long enough that a name is typed rather than queried letter by letter, short
/// enough that the list feels like it follows the keyboard.
const _typingPause = Duration(milliseconds: 350);

/// Finding a colleague by name, and asking to be their contact.
///
/// Everybody here is a colleague — the app is internal — so the search is not
/// restricted by team or by site. It still never matches on the e-mail address,
/// which the app does not display and which this screen would otherwise turn
/// into a directory.
class MemberSearchScreen extends ConsumerStatefulWidget {
  const MemberSearchScreen({super.key});

  @override
  ConsumerState<MemberSearchScreen> createState() => _MemberSearchScreenState();
}

class _MemberSearchScreenState extends ConsumerState<MemberSearchScreen> {
  final _typedName = TextEditingController();
  Timer? _pendingSearch;
  String _searchedName = '';

  @override
  void dispose() {
    _pendingSearch?.cancel();
    _typedName.dispose();
    super.dispose();
  }

  void _onNameTyped(String value) {
    _pendingSearch?.cancel();
    _pendingSearch = Timer(_typingPause, () {
      if (!mounted) return;
      setState(() => _searchedName = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un contact')),
      body: ColoredBox(
        color: _ground,
        child: ContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _typedName,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onNameTyped,
                  decoration: const InputDecoration(
                    labelText: 'Nom du collègue',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(child: _Results(searchedName: _searchedName)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.searchedName});

  final String searchedName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (searchedName.length < _minimumQueryLength) {
      return const _Hint(
        'Saisissez au moins deux lettres du nom d\'un collègue pour le '
        'trouver.',
      );
    }

    return AsyncValueView<List<MemberSummary>>(
      value: ref.watch(memberSearchProvider(searchedName)),
      onRetry: () => ref.invalidate(memberSearchProvider(searchedName)),
      isEmpty: (members) => members.isEmpty,
      emptyMessage:
          'Aucun membre ne correspond à « $searchedName ».\n'
          'Vérifiez l\'orthographe du nom.',
      builder: (members) => ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: members.length,
        itemBuilder: (context, index) =>
            _SearchResultRow(member: members[index]),
      ),
    );
  }
}

class _SearchResultRow extends ConsumerWidget {
  const _SearchResultRow({required this.member});

  final MemberSummary member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MemberRow(
      name: member.name,
      avatarUrl: member.avatarUrl,
      trailing: ContactAction(member: member),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.secondaryText.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
