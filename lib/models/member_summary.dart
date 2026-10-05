/// A member as a search result or a contact row shows them.
///
/// Deliberately thinner than a profile: finding somebody by name must not hand
/// out their weight or their team, and a non-contact is entitled to no more
/// than what the leaderboard already displays.
class MemberSummary {
  const MemberSummary({required this.id, required this.name, this.avatarUrl});

  factory MemberSummary.fromJson(Map<String, dynamic> json) {
    return MemberSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String id;
  final String name;
  final String? avatarUrl;
}
