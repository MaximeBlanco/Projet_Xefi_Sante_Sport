import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/testing.dart';
import 'package:monapp/models/contact.dart';
import 'package:monapp/models/gps_point.dart';
import 'package:monapp/models/member_summary.dart';
import 'package:monapp/models/profile.dart';
import 'package:monapp/models/ranking_entry.dart';
import 'package:monapp/models/session.dart';
import 'package:monapp/models/sport.dart';
import 'package:monapp/models/team_ranking_entry.dart';
import 'package:monapp/models/venue.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

Sport buildSport({
  String id = 'sport-running',
  String name = 'Course à pied',
  String emoji = '🏃',
  int pointsPerUnit = 1,
  int? wgerId,
  bool isGpsTrackable = false,
  String? externalActivityName = 'running',
  double met = 9.8,
}) {
  return Sport(
    id: id,
    name: name,
    emoji: emoji,
    pointsPerUnit: pointsPerUnit,
    wgerId: wgerId,
    isGpsTrackable: isGpsTrackable,
    externalActivityName: externalActivityName,
    met: met,
  );
}

/// The sharing defaults are the column defaults, so a profile built here is the
/// one a brand new account gets.
Profile buildProfile({
  String id = 'user-1',
  String name = 'Maxime Lenormand',
  double? weightKg = 78,
  String? teamId,
  String? avatarUrl,
  bool sharesHistory = true,
  bool sharesLocations = false,
  DateTime? createdAt,
}) {
  return Profile(
    id: id,
    name: name,
    weightKg: weightKg,
    teamId: teamId,
    avatarUrl: avatarUrl,
    sharesHistory: sharesHistory,
    sharesLocations: sharesLocations,
    createdAt: createdAt ?? DateTime(2026, 1, 8),
  );
}

Session buildSession({
  String id = 'session-1',
  String userId = 'user-1',
  String sportId = 'sport-running',
  DateTime? date,
  int durationMin = 45,
  int points = 45,
  double? caloriesBurned = 380.0,
  bool caloriesEstimated = false,
  double? distanceKm,
  double? elevationGainM,
  List<GpsPoint>? route,
  DateTime? createdAt,
  Sport? sport,
  Venue? venue,
  bool withEmbeddedSport = true,
}) {
  return Session(
    id: id,
    userId: userId,
    sportId: sportId,
    date: date ?? DateTime(2026, 3, 14),
    durationMin: durationMin,
    points: points,
    caloriesBurned: caloriesBurned,
    caloriesEstimated: caloriesEstimated,
    distanceKm: distanceKm,
    elevationGainM: elevationGainM,
    route: route,
    createdAt: createdAt ?? DateTime(2026, 3, 14, 18, 30),
    sport: withEmbeddedSport ? (sport ?? buildSport(id: sportId)) : null,
    venue: venue,
  );
}

RankingEntry buildRankingEntry({
  String userId = 'user-1',
  String name = 'Alice',
  int totalPoints = 120,
  int totalDurationMin = 120,
  double totalCaloriesBurned = 900.0,
  int sessionCount = 3,
  int? currentRank,
  int? previousRank,
}) {
  return RankingEntry(
    userId: userId,
    name: name,
    totalPoints: totalPoints,
    totalDurationMin: totalDurationMin,
    totalCaloriesBurned: totalCaloriesBurned,
    sessionCount: sessionCount,
    currentRank: currentRank,
    previousRank: previousRank,
  );
}

User buildSignedInUser({String id = 'user-1'}) {
  return User(
    id: id,
    appMetadata: const <String, dynamic>{},
    userMetadata: const <String, dynamic>{},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00.000Z',
  );
}

/// The tests deliberately stay on the default Material theme: the app theme
/// pulls Montserrat through google_fonts, which would try to download font
/// files at runtime.
Widget buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      // Entrance animations and the counting score would otherwise leave every
      // test asserting on a half-played frame. Declaring reduced motion gives
      // the end state on the first pump, and exercises the accessibility path
      // the widgets honour.
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: child,
      ),
    ),
  );
}

Widget buildTestAppWithScaffold({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return buildTestApp(
    overrides: overrides,
    child: Scaffold(body: child),
  );
}

TeamRankingEntry buildTeamRankingEntry({
  String teamId = 'team-1',
  String name = 'Les Rouges',
  int colorValue = 0xFFE10600,
  int memberCount = 3,
  int totalPoints = 168,
  int totalDurationMin = 168,
  int sessionCount = 2,
  int? currentRank = 1,
  int? previousRank = 1,
}) {
  return TeamRankingEntry(
    teamId: teamId,
    name: name,
    colorValue: colorValue,
    memberCount: memberCount,
    totalPoints: totalPoints,
    totalDurationMin: totalDurationMin,
    sessionCount: sessionCount,
    currentRank: currentRank,
    previousRank: previousRank,
  );
}


MemberSummary buildMemberSummary({
  String id = 'user-2',
  String name = 'Théo Marchand',
  String? avatarUrl,
}) {
  return MemberSummary(id: id, name: name, avatarUrl: avatarUrl);
}

/// A link seen from `user-1`, the member [buildSignedInUser] stands for.
///
/// The default is a request somebody else sent, because that is the only shape
/// of link the person looking at it can act on.
Contact buildContact({
  String id = 'contact-1',
  String requesterId = 'user-2',
  String addresseeId = 'user-1',
  ContactStatus status = ContactStatus.accepted,
  String peerName = 'Théo Marchand',
  String? peerAvatarUrl,
  DateTime? createdAt,
}) {
  const viewerId = 'user-1';

  return Contact(
    id: id,
    requesterId: requesterId,
    addresseeId: addresseeId,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 3, 10),
    peer: buildMemberSummary(
      id: requesterId == viewerId ? addresseeId : requesterId,
      name: peerName,
      avatarUrl: peerAvatarUrl,
    ),
  );
}

/// A Supabase client whose PostgREST calls are answered by [respond].
///
/// The repositories are the one layer that speaks to the database, so testing
/// them means answering for the database rather than mocking the query builder
/// they are made of: what travels on the wire is what the stub sees.
SupabaseClient buildStubSupabaseClient(MockClientHandler respond) {
  return SupabaseClient(
    'https://stub.supabase.co',
    'stub-anon-key',
    // Nothing signs in here, and a refresh timer would outlive the test.
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient(respond),
  );
}
