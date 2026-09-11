/// One person in a team, with what they have contributed to it.
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.name,
    required this.isOwner,
    required this.totalPoints,
    required this.sessionCount,
    this.avatarUrl,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      isOwner: json['is_owner'] as bool? ?? false,
      totalPoints: _parseNumber(json['total_points'])?.toInt() ?? 0,
      sessionCount: _parseNumber(json['session_count'])?.toInt() ?? 0,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String userId;
  final String name;

  /// The person who created the team, and so who approves requests to join it.
  final bool isOwner;

  /// Points over everything they have logged, not only collective sports: the
  /// roster describes the people, while the team standing above it describes
  /// what the team did together.
  final int totalPoints;
  final int sessionCount;
  final String? avatarUrl;
}

num? _parseNumber(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
