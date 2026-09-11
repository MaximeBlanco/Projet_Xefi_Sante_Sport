enum JoinRequestStatus {
  pending,
  accepted,
  declined;

  static JoinRequestStatus parse(String? raw) {
    return switch (raw) {
      'accepted' => JoinRequestStatus.accepted,
      'declined' => JoinRequestStatus.declined,
      _ => JoinRequestStatus.pending,
    };
  }

  String get value => name;
}

/// Somebody asking to join a team, and where that ask stands.
class TeamJoinRequest {
  const TeamJoinRequest({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.applicantName,
    this.applicantAvatarUrl,
    this.teamName,
  });

  factory TeamJoinRequest.fromJson(Map<String, dynamic> json) {
    // The applicant and the team arrive as embedded rows when the query asks
    // for them, and are absent when it does not; either way the request itself
    // is complete without them.
    final applicant = json['applicant'] as Map<String, dynamic>?;
    final team = json['team'] as Map<String, dynamic>?;

    return TeamJoinRequest(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      userId: json['user_id'] as String,
      status: JoinRequestStatus.parse(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      applicantName: applicant?['name'] as String?,
      applicantAvatarUrl: applicant?['avatar_url'] as String?,
      teamName: team?['name'] as String?,
    );
  }

  final String id;
  final String teamId;
  final String userId;
  final JoinRequestStatus status;
  final DateTime createdAt;
  final String? applicantName;
  final String? applicantAvatarUrl;
  final String? teamName;

  bool get isPending => status == JoinRequestStatus.pending;
}
