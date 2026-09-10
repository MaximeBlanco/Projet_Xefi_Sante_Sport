class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.weightKg,
    this.teamId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      teamId: json['team_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String name;
  final double? weightKg;
  final String? teamId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weight_kg': weightKg,
      'team_id': teamId,
    };
  }
}
