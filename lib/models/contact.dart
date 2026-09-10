enum ContactStatus { pending, accepted }

ContactStatus contactStatusFromString(String value) {
  return ContactStatus.values.firstWhere((status) => status.name == value);
}

class Contact {
  const Contact({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: contactStatusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String requesterId;
  final String addresseeId;
  final ContactStatus status;
  final DateTime createdAt;
}
