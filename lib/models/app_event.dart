import 'package:flutter/material.dart';

/// What kind of thing an event is, which decides how its card looks.
enum EventKind {
  /// A fixture, usually one team against another.
  tournament('Tournoi'),

  /// A session people turn up to together.
  training('Séance'),

  /// Not sport: the gaming nights the company also runs.
  gaming('Gaming');

  const EventKind(this.label);

  final String label;

  static EventKind parse(String? raw) {
    return switch (raw) {
      'tournament' => EventKind.tournament,
      'gaming' => EventKind.gaming,
      _ => EventKind.training,
    };
  }
}

/// One upcoming event, as the `upcoming_events` view returns it.
///
/// Named AppEvent rather than Event: Flutter already has several Events in
/// scope, and a model that collides with them makes every import ambiguous.
class AppEvent {
  const AppEvent({
    required this.id,
    required this.title,
    required this.kind,
    required this.startsAt,
    this.location,
    this.description,
    this.sportName,
    this.sportEmoji,
    this.externalActivityName,
    this.homeTeamName,
    this.homeTeamColorValue,
    this.awayTeamName,
    this.awayTeamColorValue,
  });

  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: EventKind.parse(json['kind'] as String?),
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      location: json['location'] as String?,
      description: json['description'] as String?,
      sportName: json['sport_name'] as String?,
      sportEmoji: json['sport_emoji'] as String?,
      externalActivityName: json['external_activity_name'] as String?,
      homeTeamName: json['home_team_name'] as String?,
      homeTeamColorValue: _parseNumber(json['home_team_color'])?.toInt(),
      awayTeamName: json['away_team_name'] as String?,
      awayTeamColorValue: _parseNumber(json['away_team_color'])?.toInt(),
    );
  }

  final String id;
  final String title;
  final EventKind kind;
  final DateTime startsAt;
  final String? location;
  final String? description;
  final String? sportName;
  final String? sportEmoji;
  final String? externalActivityName;
  final String? homeTeamName;
  final int? homeTeamColorValue;
  final String? awayTeamName;
  final int? awayTeamColorValue;

  /// True when the event names both sides, and so can be shown as a fixture.
  bool get isFixture => homeTeamName != null && awayTeamName != null;

  Color? get homeTeamColour =>
      homeTeamColorValue == null ? null : Color(homeTeamColorValue!);

  Color? get awayTeamColour =>
      awayTeamColorValue == null ? null : Color(awayTeamColorValue!);

  /// Whole days until it starts, counted from midnight to midnight so "demain"
  /// means tomorrow rather than "in less than 24 hours".
  int daysUntil(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(startsAt.year, startsAt.month, startsAt.day);
    return day.difference(today).inDays;
  }

  /// "Aujourd'hui", "Demain", "Dans 3 jours", or null when it is further off
  /// than a week and the date itself says more than a countdown would.
  String? countdownLabel(DateTime now) {
    final days = daysUntil(now);
    if (days < 0) return 'En cours';
    if (days == 0) return "Aujourd'hui";
    if (days == 1) return 'Demain';
    if (days <= 7) return 'Dans $days jours';
    return null;
  }
}

num? _parseNumber(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
