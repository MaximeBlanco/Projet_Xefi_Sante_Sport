import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/contact.dart';

Map<String, dynamic> buildRow({
  String requesterId = 'user-2',
  String addresseeId = 'user-1',
  String status = 'accepted',
  bool withMembers = true,
}) {
  return {
    'id': 'contact-1',
    'requester_id': requesterId,
    'addressee_id': addresseeId,
    'status': status,
    'created_at': '2026-03-10T09:00:00.000Z',
    if (withMembers) ...{
      'requester': {
        'id': requesterId,
        'name': 'Théo Marchand',
        'avatar_url': null,
      },
      'addressee': {
        'id': addresseeId,
        'name': 'Camille Roussel',
        'avatar_url': null,
      },
    },
  };
}

void main() {
  group('Contact', () {
    test('reads the link from the side of whoever is looking', () {
      final row = buildRow();

      expect(
        Contact.fromJson(row, viewerId: 'user-1').peer?.name,
        'Théo Marchand',
      );
      expect(
        Contact.fromJson(row, viewerId: 'user-2').peer?.name,
        'Camille Roussel',
      );
    });

    test('names the other member whichever way the request went', () {
      final received = Contact.fromJson(buildRow(), viewerId: 'user-1');
      final sent = Contact.fromJson(
        buildRow(requesterId: 'user-1', addresseeId: 'user-2'),
        viewerId: 'user-1',
      );

      expect(received.peerIdFor('user-1'), 'user-2');
      expect(sent.peerIdFor('user-1'), 'user-2');
    });

    // A request is only answerable by the member who received it, so the two
    // pending lists are not the same list read twice.
    test('tells a request sent apart from a request received', () {
      final received = Contact.fromJson(
        buildRow(status: 'pending'),
        viewerId: 'user-1',
      );

      expect(received.isPending, isTrue);
      expect(received.isAccepted, isFalse);
      expect(received.wasSentBy('user-1'), isFalse);
      expect(received.wasSentBy('user-2'), isTrue);
    });

    // The duplicate check asks whether a link exists, not who is on the far
    // end, and reads the row without joining the profiles.
    test('parses a row read without the members joined', () {
      final contact = Contact.fromJson(buildRow(withMembers: false));

      expect(contact.peer, isNull);
      expect(contact.isAccepted, isTrue);
    });
  });
}
