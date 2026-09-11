import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/team_repository.dart';
import '../models/team.dart';
import 'auth_provider.dart';
import 'profile_editing_controller.dart';
import 'profile_provider.dart';
import 'ranking_provider.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(ref.watch(supabaseClientProvider));
});

/// Every team, for the picker. Kept separate from the leaderboard: a team with
/// no matches yet still has to be joinable.
final teamsProvider = FutureProvider<List<Team>>((ref) {
  return ref.watch(teamRepositoryProvider).fetchTeams();
});

/// The team the signed-in user belongs to, or null.
final currentTeamProvider = FutureProvider<Team?>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  final teamId = profile?.teamId;
  if (teamId == null) return null;

  final teams = await ref.watch(teamsProvider.future);
  // A lookup rather than a second query: the list is already loaded for the
  // picker, and a team that vanished should read as "no team" rather than
  // throw.
  for (final team in teams) {
    if (team.id == teamId) return team;
  }
  return null;
});

/// Joining, leaving and creating a team, with the invalidations each implies.
class TeamMembershipController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> join(String teamId) => _run((userId) async {
    await ref
        .read(teamRepositoryProvider)
        .setTeam(userId: userId, teamId: teamId);
  });

  Future<bool> leave() => _run((userId) async {
    await ref.read(teamRepositoryProvider).setTeam(userId: userId, teamId: null);
  });

  /// Creates the team and joins it in one go: someone creating a team is
  /// always creating the one they mean to play for, and leaving them outside
  /// it would only be a second step nobody wants.
  Future<bool> createAndJoin({
    required String name,
    required int colorValue,
  }) {
    return _run((userId) async {
      final repository = ref.read(teamRepositoryProvider);
      final team = await repository.createTeam(
        name: name,
        colorValue: colorValue,
      );
      await repository.setTeam(userId: userId, teamId: team.id);
    });
  }

  Future<bool> _run(Future<void> Function(String userId) write) async {
    state = const AsyncValue<void>.loading();
    final keepAliveLink = ref.keepAlive();
    try {
      final signedInUser = ref.read(currentUserProvider);
      if (signedInUser == null) {
        state = AsyncValue<void>.error(
          const SignedOutWhileEditingException(),
          StackTrace.current,
        );
        return false;
      }

      await write(signedInUser.id);

      // The profile carries team_id, the teams list may have gained a row, and
      // both leaderboards change the moment somebody joins or leaves.
      ref.invalidate(currentProfileProvider);
      ref.invalidate(teamsProvider);
      ref.invalidate(teamRankingProvider);

      state = const AsyncValue<void>.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
      return false;
    } finally {
      keepAliveLink.close();
    }
  }
}

final teamMembershipControllerProvider =
    AutoDisposeAsyncNotifierProvider<TeamMembershipController, void>(
      TeamMembershipController.new,
    );
