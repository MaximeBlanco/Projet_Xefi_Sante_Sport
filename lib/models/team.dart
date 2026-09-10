class Team {
  const Team({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['color_value'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;
}
