import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:monapp/models/profile.dart';
import 'package:monapp/models/profile_stats.dart';
import 'package:monapp/models/session.dart';
import 'package:monapp/providers/profile_provider.dart';
import 'package:monapp/providers/profile_stats_provider.dart';
import 'package:monapp/screens/profile/profile_screen.dart';
import 'package:monapp/widgets/member_card.dart';

import '../../support/test_fixtures.dart';

final _today = DateTime(2026, 3, 20);

Profile buildProfile({
  String name = 'Maxime Lenormand',
  double? weightKg = 78,
  String? avatarUrl,
}) {
  return Profile(
    id: 'user-1',
    name: name,
    weightKg: weightKg,
    avatarUrl: avatarUrl,
    createdAt: DateTime(2026, 1, 8),
  );
}

ProfileStats buildStats({List<Session>? sessions}) {
  return ProfileStats.fromSessions(
    sessions ??
        [
          buildSession(
            id: 'a',
            sportId: 'course',
            durationMin: 45,
            points: 45,
            date: DateTime(2026, 3, 19),
            sport: buildSport(id: 'course', name: 'Course à pied'),
          ),
          buildSession(
            id: 'b',
            sportId: 'velo',
            durationMin: 90,
            points: 90,
            date: DateTime(2026, 3, 20),
            sport: buildSport(id: 'velo', name: 'Vélo', emoji: '🚴'),
          ),
        ],
    _today,
  );
}

Widget buildScreen({Profile? profile, ProfileStats? stats}) {
  return buildTestApp(
    overrides: [
      currentProfileProvider.overrideWith((ref) => profile ?? buildProfile()),
      profileStatsProvider.overrideWith((ref) async => stats ?? buildStats()),
    ],
    child: const Scaffold(body: ProfileScreen()),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('ProfileScreen', () {
    testWidgets('leads with the member card', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('CARTE MEMBRE'), findsOneWidget);
      expect(find.text('Maxime Lenormand'), findsOneWidget);
      expect(find.text('Sport favori · Vélo'), findsOneWidget);
      // 135 points is still inside the first level.
      expect(find.text('NIVEAU 1 · DÉBUTANT'), findsOneWidget);
      expect(find.text('N° MEMBRE'), findsOneWidget);
      // The head of the real account id ("user-1" here), read in groups of four.
      expect(find.text('USER 1'), findsOneWidget);
    });

    testWidgets('leans under the finger and settles back flat', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      Matrix4 cardTransform() => tester
          .widget<Transform>(
            find.descendant(
              of: find.byType(MemberCard),
              matching: find.byType(Transform),
            ).first,
          )
          .transform;

      final atRest = cardTransform();

      final corner = tester.getTopLeft(find.byType(MemberCard));
      final gesture = await tester.startGesture(corner + const Offset(12, 12));
      await tester.pump();

      expect(cardTransform(), isNot(atRest), reason: 'the card should lean');

      await gesture.up();
      await tester.pumpAndSettle();

      expect(cardTransform(), atRest, reason: 'and come back flat');
    });

    testWidgets('never leans far enough to show an edge', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Dragged to the very corner, the lean stays far short of the quarter
      // turn that would take the card edge-on.
      final corner = tester.getBottomRight(find.byType(MemberCard));
      final gesture = await tester.startGesture(corner - const Offset(1, 1));
      await tester.pump();

      final transform = tester
          .widget<Transform>(
            find.descendant(
              of: find.byType(MemberCard),
              matching: find.byType(Transform),
            ).first,
          )
          .transform;
      // The x column of a Y-rotation holds cos(angle); staying above cos(30°)
      // keeps the face square to the reader.
      expect(transform.entry(0, 0).abs(), greaterThan(0.86));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('keeps the proportions of a real card', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final card = tester.getSize(find.byType(MemberCard));
      // ISO/IEC 7810 ID-1: 85.60 mm by 53.98 mm.
      expect(card.width / card.height, closeTo(85.60 / 53.98, 0.01));
    });

    testWidgets('opens on the activity tab', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Résumé du mois'), findsOneWidget);
      expect(find.text('Six derniers mois'), findsOneWidget);
      expect(find.text('Records personnels'), findsOneWidget);
      expect(find.text('Répartition par sport'), findsOneWidget);
      expect(find.text('Mon compte'), findsNothing);
    });

    testWidgets('reports the records it can actually derive', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Plus longue séance'), findsOneWidget);
      // Once as the longest session, once as the time logged on the bike.
      expect(find.text('1 h 30'), findsNWidgets(2));
      expect(find.text('2 h 15'), findsOneWidget);
      expect(find.text('Points au total'), findsOneWidget);
      expect(find.text('Série en cours'), findsOneWidget);
      // The total, the best week and the best month all land on 135.
      expect(find.text('135 pts'), findsNWidgets(3));
    });

    testWidgets('switches to the settings tab and back', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();

      expect(find.text('Mon compte'), findsOneWidget);
      expect(find.text('Photo de profil'), findsOneWidget);
      expect(find.text('78 kg'), findsOneWidget);
      expect(find.text('Résumé du mois'), findsNothing);

      await tester.tap(find.text('Activité'));
      await tester.pumpAndSettle();

      expect(find.text('Résumé du mois'), findsOneWidget);
    });

    testWidgets('offers to add a picture when there is none', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter'), findsOneWidget);
    });

    testWidgets('shows a dash rather than a made-up weight', (tester) async {
      await tester.pumpWidget(buildScreen(profile: buildProfile(weightKg: null)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('offers signing out and deleting the account', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();

      expect(find.text('Session'), findsOneWidget);
      expect(find.text('Déconnexion'), findsOneWidget);
      expect(find.text('Supprimer mon compte'), findsOneWidget);
    });

    testWidgets('asks before deleting, and does nothing when refused',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Supprimer mon compte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer mon compte'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer le compte ?'), findsOneWidget);
      expect(find.textContaining('irréversible'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Backing out leaves the settings exactly as they were; had the deletion
      // run, the repository override would have thrown.
      expect(find.text('Supprimer le compte ?'), findsNothing);
      expect(find.text('Mon compte'), findsOneWidget);
    });

    testWidgets('asks before signing out', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Déconnexion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Déconnexion'));
      await tester.pumpAndSettle();

      expect(find.text('Se déconnecter ?'), findsOneWidget);
    });

    testWidgets('invites a first session instead of showing empty panels',
        (tester) async {
      await tester.pumpWidget(
        buildScreen(stats: buildStats(sessions: const <Session>[])),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Enregistrez une première séance pour voir vos statistiques se remplir.',
        ),
        findsOneWidget,
      );
      // Nothing to break down, so that panel stays out of the way.
      expect(find.text('Répartition par sport'), findsNothing);
      expect(find.text('Six derniers mois'), findsOneWidget);
    });
  });
}
