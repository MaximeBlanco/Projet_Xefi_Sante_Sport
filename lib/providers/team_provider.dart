import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../data/team_repository.dart';
import '../models/team.dart';
import '../models/team_join_request.dart';
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

/// The signed-in user's own requests, so the picker can show which team they
/// have already asked to join rather than offering to ask again.
final myJoinRequestsProvider = FutureProvider<List<TeamJoinRequest>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(teamRepositoryProvider).fetchMyRequests(userId: user.id);
});

/// Requests waiting on the signed-in user as a team owner. Empty for everybody
/// else, because row-level security returns them nothing.
final pendingJoinRequestsProvider = FutureProvider<List<TeamJoinRequest>>((
  ref,
) async {
  if (ref.watch(currentUserProvider) == null) return const [];
  return ref.watch(teamRepositoryProvider).fetchRequestsToDecide();
});

/// Asking, withdrawing, deciding, leaving and creating, with the invalidations
/// each implies.
class TeamMembershipController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> requestToJoin(String teamId) => _run((userId) async {
    await ref
        .read(teamRepositoryProvider)
        .requestToJoin(userId: userId, teamId: teamId);
  });

  Future<bool> withdrawRequest(String requestId) => _run((_) async {
    await ref.read(teamRepositoryProvider).withdrawRequest(requestId: requestId);
  });

  Future<bool> decide({required String requestId, required bool accepted}) {
    return _run((_) async {
      await ref
          .read(teamRepositoryProvider)
          .decide(requestId: requestId, accepted: accepted);
    });
  }

  Future<bool> leave() => _run((userId) async {
    await ref.read(teamRepositoryProvider).leaveTeam(userId: userId);
  });

  /// Creates the team and joins it in one go: someone creating a team is
  /// always creating the one they mean to play for, and leaving them outside
  /// it would only be a second step nobody wants.
  Future<bool> createAndJoin({
    required String name,
    required int colorValue,
  }) {
    return _run((userId) async {
      await ref.read(teamRepositoryProvider).createTeam(
        userId: userId,
        name: name,
        colorValue: colorValue,
      );
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

      // The profile carries team_id, the teams list may have gained a row, the
      // request lists change on every one of these, and both leaderboards move
      // the moment somebody joins or leaves.
      ref.invalidate(currentProfileProvider);
      ref.invalidate(teamsProvider);
      ref.invalidate(myJoinRequestsProvider);
      ref.invalidate(pendingJoinRequestsProvider);
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
