import 'member_summary.dart';

enum ContactStatus { pending, accepted }

ContactStatus contactStatusFromString(String value) {
  return ContactStatus.values.firstWhere((status) => status.name == value);
}

/// The link between two members, read from the side of whoever is looking.
///
/// The row itself is symmetric — one link per pair, whichever way the request
/// went — so every screen question ("who is this?", "is it mine to accept?")
/// is answered against a viewer rather than against the row alone.
class Contact {
  const Contact({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.peer,
  });

  /// [viewerId] picks which of the two embedded profiles is the other member.
  /// Without it the row still parses, which is what the duplicate check needs:
  /// it asks whether a link exists, not who is on the far end.
  factory Contact.fromJson(Map<String, dynamic> json, {String? viewerId}) {
    final requesterId = json['requester_id'] as String;
    final peerJson = viewerId == requesterId
        ? json['addressee']
        : json['requester'];

    return Contact(
      id: json['id'] as String,
      requesterId: requesterId,
      addresseeId: json['addressee_id'] as String,
      status: contactStatusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      peer: viewerId == null || peerJson == null
          ? null
          : MemberSummary.fromJson(peerJson as Map<String, dynamic>),
    );
  }

  final String id;
  final String requesterId;
  final String addresseeId;
  final ContactStatus status;
  final DateTime createdAt;

  /// The member on the other end, when the row was read with the profiles
  /// joined and for a known viewer.
  final MemberSummary? peer;

  bool get isPending => status == ContactStatus.pending;

  bool get isAccepted => status == ContactStatus.accepted;

  String peerIdFor(String viewerId) {
    return requesterId == viewerId ? addresseeId : requesterId;
  }

  /// Whether [viewerId] is the one waiting for an answer, as opposed to the one
  /// who owes it.
  bool wasSentBy(String viewerId) => requesterId == viewerId;
}
