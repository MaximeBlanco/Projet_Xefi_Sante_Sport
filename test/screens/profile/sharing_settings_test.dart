import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:monapp/data/profile_repository.dart';
import 'package:monapp/models/profile.dart';
import 'package:monapp/models/session.dart';
import 'package:monapp/providers/auth_provider.dart';
import 'package:monapp/providers/profile_provider.dart';
import 'package:monapp/providers/session_provider.dart';
import 'package:monapp/providers/weekly_health_provider.dart';
import 'package:monapp/screens/profile/profile_screen.dart';

import '../../support/test_fixtures.dart';

/// Keeps the two switches the way the profiles table does, so a toggle is read
/// back from the store rather than from whatever the screen last drew.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.refusesWrites = false});

  final bool refusesWrites;
  final List<(SharingPreference, bool)> writes = [];

  bool sharesHistory = true;
  bool sharesLocations = false;

  @override
  Future<Profile?> fetchProfile(String userId) async {
    return buildProfile(
      sharesHistory: sharesHistory,
      sharesLocations: sharesLocations,
    );
  }

  @override
  Future<void> updateSharing({
    required String userId,
    required SharingPreference preference,
    required bool isOpen,
  }) async {
    if (refusesWrites) {
      throw Exception('la base a refusé la mise à jour');
    }
    writes.add((preference, isOpen));
    switch (preference) {
      case SharingPreference.history:
        sharesHistory = isOpen;
      case SharingPreference.locations:
        sharesLocations = isOpen;
    }
  }

  @override
  Future<void> updateName({required String userId, required String name}) =>
      throw UnimplementedError();

  @override
  Future<void> updateWeight({
    required String userId,
    required double weightKg,
  }) => throw UnimplementedError();

  @override
  Future<String> uploadAvatar({
    required String userId,
    required XFile file,
    required DateTime uploadedAt,
  }) => throw UnimplementedError();
}

Widget buildScreen(FakeProfileRepository repository) {
  return buildTestApp(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repository),
      currentUserProvider.overrideWithValue(buildSignedInUser()),
      todayProvider.overrideWithValue(DateTime(2026, 3, 20)),
      userSessionsProvider.overrideWith((ref) async => <Session>[]),
    ],
    child: const Scaffold(body: ProfileScreen()),
  );
}

Finder switchFor(SharingPreference preference) {
  return find.descendant(
    of: find.widgetWithText(InkWell, preference.label),
    matching: find.byType(Switch),
  );
}

bool isOn(WidgetTester tester, SharingPreference preference) {
  return tester.widget<Switch>(switchFor(preference)).value;
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Réglages'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(SharingPreference.locations.label));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('Réglages de partage', () {
    testWidgets('a fresh account shares its history and no location at all',
        (tester) async {
      await tester.pumpWidget(buildScreen(FakeProfileRepository()));
      await openSettings(tester);

      expect(isOn(tester, SharingPreference.history), isTrue);
      expect(isOn(tester, SharingPreference.locations), isFalse);
    });

    testWidgets('each row says what it hands over, not just its name',
        (tester) async {
      await tester.pumpWidget(buildScreen(FakeProfileRepository()));
      await openSettings(tester);

      expect(find.text(SharingPreference.history.exposes), findsOneWidget);
      expect(find.text(SharingPreference.locations.exposes), findsOneWidget);
      // The one that matters: opening it tells the reader where and when, which
      // is the part a label like "lieux et trajets" leaves out.
      expect(find.textContaining('où et quand'), findsOneWidget);
    });

    testWidgets('opening the locations switch records it and the row follows',
        (tester) async {
      final repository = FakeProfileRepository();
      await tester.pumpWidget(buildScreen(repository));
      await openSettings(tester);

      await tester.tap(switchFor(SharingPreference.locations));
      await tester.pumpAndSettle();

      expect(repository.writes, [(SharingPreference.locations, true)]);
      expect(isOn(tester, SharingPreference.locations), isTrue);
      // Independent switches: opening one leaves the other where it was.
      expect(isOn(tester, SharingPreference.history), isTrue);
      expect(find.textContaining('visible par vos contacts'), findsOneWidget);
    });

    testWidgets('closing the history switch records it and the row follows',
        (tester) async {
      final repository = FakeProfileRepository();
      await tester.pumpWidget(buildScreen(repository));
      await openSettings(tester);

      await tester.tap(switchFor(SharingPreference.history));
      await tester.pumpAndSettle();

      expect(repository.writes, [(SharingPreference.history, false)]);
      expect(isOn(tester, SharingPreference.history), isFalse);
      expect(isOn(tester, SharingPreference.locations), isFalse);
    });

    testWidgets('closing one switch then the other leaves both closed',
        (tester) async {
      final repository = FakeProfileRepository()..sharesLocations = true;
      await tester.pumpWidget(buildScreen(repository));
      await openSettings(tester);

      await tester.tap(switchFor(SharingPreference.locations));
      await tester.pumpAndSettle();
      await tester.tap(switchFor(SharingPreference.history));
      await tester.pumpAndSettle();

      expect(repository.writes, [
        (SharingPreference.locations, false),
        (SharingPreference.history, false),
      ]);
      expect(isOn(tester, SharingPreference.history), isFalse);
      expect(isOn(tester, SharingPreference.locations), isFalse);
    });

    testWidgets('a refused write leaves the switch shut and says so',
        (tester) async {
      await tester.pumpWidget(
        buildScreen(FakeProfileRepository(refusesWrites: true)),
      );
      await openSettings(tester);

      await tester.tap(switchFor(SharingPreference.locations));
      await tester.pumpAndSettle();

      // Nothing was broadcast, so the switch must not claim otherwise.
      expect(isOn(tester, SharingPreference.locations), isFalse);
      expect(find.textContaining('a échoué'), findsOneWidget);
    });
  });
}
