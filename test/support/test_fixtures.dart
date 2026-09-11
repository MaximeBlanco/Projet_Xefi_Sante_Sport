import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monapp/models/ranking_entry.dart';
import 'package:monapp/models/session.dart';
import 'package:monapp/models/sport.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

Sport buildSport({
  String id = 'sport-running',
  String name = 'Course à pied',
  String emoji = '🏃',
  int pointsPerUnit = 1,
  int? wgerId,
  bool isGpsTrackable = false,
  String? externalActivityName = 'running',
}) {
  return Sport(
    id: id,
    name: name,
    emoji: emoji,
    pointsPerUnit: pointsPerUnit,
    wgerId: wgerId,
    isGpsTrackable: isGpsTrackable,
    externalActivityName: externalActivityName,
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
  DateTime? createdAt,
  Sport? sport,
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
    createdAt: createdAt ?? DateTime(2026, 3, 14, 18, 30),
    sport: withEmbeddedSport ? (sport ?? buildSport(id: sportId)) : null,
  );
}

RankingEntry buildRankingEntry({
  String userId = 'user-1',
  String name = 'Alice',
  int totalPoints = 120,
  int totalDurationMin = 120,
  double totalCaloriesBurned = 900.0,
  int sessionCount = 3,
}) {
  return RankingEntry(
    userId: userId,
    name: name,
    totalPoints: totalPoints,
    totalDurationMin: totalDurationMin,
    totalCaloriesBurned: totalCaloriesBurned,
    sessionCount: sessionCount,
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
