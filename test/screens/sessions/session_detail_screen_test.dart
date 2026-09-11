import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/gps_point.dart';
import 'package:monapp/screens/sessions/session_detail_screen.dart';

import '../../support/test_fixtures.dart';

void main() {
  group('SessionDetailScreen', () {
    testWidgets('draws the route of a tracked session', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: SessionDetailScreen(
            session: buildSession(
              distanceKm: 8.2,
              route: const [
                GpsPoint(lat: 45.75, lng: 4.85, altitude: 170, timestampMs: 0),
                GpsPoint(lat: 45.76, lng: 4.86, altitude: 175, timestampMs: 1),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Aucun parcours enregistré'), findsNothing);
    });

    // Regression: this used to be a Spacer, so a manually recorded session
    // opened onto a blank half-screen that read as a map failing to load.
    testWidgets('says so rather than leaving the map area blank',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: SessionDetailScreen(session: buildSession())),
      );
      await tester.pump();

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Aucun parcours enregistré'), findsOneWidget);
    });

    testWidgets('tells a GPS sport how to get a route next time',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: SessionDetailScreen(
            session: buildSession(
              sport: buildSport(name: 'Course à pied', isGpsTrackable: true),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Suivre le parcours en direct'), findsOneWidget);
    });

    // Pointing a swimmer at route tracking would advertise something the sport
    // never offers.
    testWidgets('spares a sport that cannot be tracked the suggestion',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: SessionDetailScreen(
            session: buildSession(
              sport: buildSport(name: 'Natation', isGpsTrackable: false),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Aucun parcours enregistré'), findsOneWidget);
      expect(find.textContaining('Suivre le parcours'), findsNothing);
    });
  });
}
