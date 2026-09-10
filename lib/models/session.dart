class Session {
  const Session({
    required this.id,
    required this.userId,
    required this.sportId,
    required this.date,
    required this.durationMin,
    required this.points,
    required this.caloriesBurned,
    required this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sportId: json['sport_id'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMin: json['duration_min'] as int,
      points: json['points'] as int,
      caloriesBurned: (json['calories_burned'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String sportId;
  final DateTime date;
  final int durationMin;
  final int points;
  final double caloriesBurned;
  final DateTime createdAt;
}
