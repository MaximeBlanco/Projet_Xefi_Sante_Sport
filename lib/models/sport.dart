class Sport {
  const Sport({
    required this.id,
    required this.name,
    required this.emoji,
    required this.pointsPerUnit,
  });

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      pointsPerUnit: json['points_per_unit'] as int,
    );
  }

  final String id;
  final String name;
  final String emoji;
  final int pointsPerUnit;
}
