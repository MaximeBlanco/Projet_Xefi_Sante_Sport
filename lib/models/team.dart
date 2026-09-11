import 'package:flutter/material.dart';

/// A team people can join, for the collective-sport leaderboard.
class Team {
  const Team({required this.id, required this.name, required this.colorValue});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: _parseNumber(json['color_value'])?.toInt() ?? _fallbackColour,
    );
  }

  /// Stored as an integer because the column predates this feature and is
  /// declared `integer not null`.
  static const _fallbackColour = 0xFFE10600;

  /// The palette offered when creating a team.
  ///
  /// A fixed set rather than a colour picker: the colour is only ever shown as
  /// a small chip next to a name, and eight distinguishable ones do that job
  /// without letting anybody pick a shade invisible against the page.
  static const palette = <int>[
    0xFFE10600,
    0xFF2B2D42,
    0xFF1B7F5C,
    0xFF0F6FA8,
    0xFF7A3FA0,
    0xFFC46A00,
    0xFF9B1B3C,
    0xFF3D6B1F,
  ];

  final String id;
  final String name;
  final int colorValue;

  Color get colour => Color(colorValue);
}

num? _parseNumber(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
