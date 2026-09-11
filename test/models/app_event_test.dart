import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/app_event.dart';

final _now = DateTime(2026, 9, 11, 14, 0);

Map<String, dynamic> row({
  String kind = 'tournament',
  String startsAt = '2026-09-13T18:30:00+00:00',
  Object? homeTeamName = 'Les Rouges',
  Object? awayTeamName = 'Agence Lyon',
  Object? homeColour = -2097152,
}) {
  return <String, dynamic>{
    'id': 'event-1',
    'title': 'Tournoi de basket',
    'kind': kind,
    'starts_at': startsAt,
    'location': 'Gymnase Bellecour',
    'description': null,
    'sport_id': 'sport-1',
    'sport_name': 'Basket-ball',
    'sport_emoji': '🏀',
    'external_activity_name': 'basketball',
    'home_team_id': 'team-1',
    'home_team_name': homeTeamName,
    'home_team_color': homeColour,
    'away_team_id': 'team-2',
    'away_team_name': awayTeamName,
    'away_team_color': -13948862,
  };
}

void main() {
  group('AppEvent.fromJson', () {
    test('reads the row the view returns', () {
      final event = AppEvent.fromJson(row());

      expect(event.id, 'event-1');
      expect(event.title, 'Tournoi de basket');
      expect(event.kind, EventKind.tournament);
      expect(event.externalActivityName, 'basketball');
      expect(event.location, 'Gymnase Bellecour');
    });

    test('falls back to a session for an unknown kind', () {
      // The check constraint keeps the column to three values, but a value
      // added later must not crash an older build.
      expect(AppEvent.fromJson(row(kind: 'hackathon')).kind, EventKind.training);
      expect(AppEvent.fromJson(row(kind: 'gaming')).kind, EventKind.gaming);
    });

    test('reads the team colours the integer column stores', () {
      final event = AppEvent.fromJson(row());

      expect(event.homeTeamColour, isNotNull);
      expect(event.homeTeamColour!.a, 1.0);
    });
  });

  group('fixtures', () {
    test('needs both sides to be one', () {
      expect(AppEvent.fromJson(row()).isFixture, isTrue);
      expect(AppEvent.fromJson(row(awayTeamName: null)).isFixture, isFalse);
      expect(AppEvent.fromJson(row(homeTeamName: null)).isFixture, isFalse);
    });
  });

  group('the countdown', () {
    AppEvent at(String startsAt) => AppEvent.fromJson(row(startsAt: startsAt));

    test('counts whole days, not hours', () {
      // Twenty-three hours away but on the next calendar day: a person calls
      // that tomorrow, and so does the label.
      expect(at('2026-09-12T13:00:00Z').countdownLabel(_now), 'Demain');
    });

    test('names today and the days after', () {
      expect(at('2026-09-11T20:00:00Z').countdownLabel(_now), "Aujourd'hui");
      expect(at('2026-09-14T20:00:00Z').countdownLabel(_now), 'Dans 3 jours');
    });

    test('says nothing beyond a week, where the date speaks for itself', () {
      expect(at('2026-09-18T20:00:00Z').countdownLabel(_now), 'Dans 7 jours');
      expect(at('2026-09-19T20:00:00Z').countdownLabel(_now), isNull);
    });

    test('marks an event already started as in progress', () {
      expect(at('2026-09-10T20:00:00Z').countdownLabel(_now), 'En cours');
    });
  });
}
