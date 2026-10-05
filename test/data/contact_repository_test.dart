import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monapp/data/contact_repository.dart';

import '../support/test_fixtures.dart';

const _camille = 'user-1';
const _theo = 'user-2';

const _jsonHeaders = {'content-type': 'application/json'};

Map<String, dynamic> linkRow({String status = 'pending'}) {
  return {
    'id': 'contact-1',
    'requester_id': _theo,
    'addressee_id': _camille,
    'status': status,
    'created_at': '2026-03-10T09:00:00.000Z',
    'requester': {'id': _theo, 'name': 'Théo Marchand', 'avatar_url': null},
    'addressee': {'id': _camille, 'name': 'Camille Roussel', 'avatar_url': null},
  };
}

/// Everything the repository sends, so a test can assert on what never left.
late List<http.BaseRequest> sentRequests;

ContactRepository buildRepository({
  List<Map<String, dynamic>> rows = const [],
  String? writeRefusedWithCode,
}) {
  return ContactRepository(
    buildStubSupabaseClient((request) async {
      sentRequests.add(request);

      if (request.method == 'POST' && writeRefusedWithCode != null) {
        return http.Response(
          jsonEncode({
            'code': writeRefusedWithCode,
            'message': 'duplicate key value violates unique constraint',
            'details': null,
            'hint': null,
          }),
          409,
          request: request,
          headers: _jsonHeaders,
        );
      }

      return http.Response(
        jsonEncode(rows),
        200,
        request: request,
        headers: _jsonHeaders,
      );
    }),
  );
}

Iterable<http.BaseRequest> get writeRequests =>
    sentRequests.where((request) => request.method != 'GET');

void main() {
  setUp(() => sentRequests = <http.BaseRequest>[]);

  group('ContactRepository.sendRequest', () {
    test('refuses a request to oneself without asking the database', () async {
      final repository = buildRepository();

      await expectLater(
        repository.sendRequest(requesterId: _camille, addresseeId: _camille),
        throwsA(
          isA<ContactException>().having(
            (error) => error.message,
            'message',
            contains('vous-même'),
          ),
        ),
      );
      expect(sentRequests, isEmpty);
    });

    test('refuses a second request while the first is still pending', () async {
      final repository = buildRepository(rows: [linkRow()]);

      await expectLater(
        repository.sendRequest(requesterId: _camille, addresseeId: _theo),
        throwsA(
          isA<ContactException>().having(
            (error) => error.message,
            'message',
            contains('déjà en cours'),
          ),
        ),
      );
      expect(writeRequests, isEmpty);
    });

    test('refuses a request to someone who is already a contact', () async {
      final repository = buildRepository(rows: [linkRow(status: 'accepted')]);

      await expectLater(
        repository.sendRequest(requesterId: _camille, addresseeId: _theo),
        throwsA(
          isA<ContactException>().having(
            (error) => error.message,
            'message',
            contains('déjà en contact'),
          ),
        ),
      );
      expect(writeRequests, isEmpty);
    });

    // The read cannot see a request the other side sent a second earlier. The
    // unique index can, and what it says has to come back as French rather than
    // as a constraint name.
    test('turns the duplicate the index caught into a readable refusal',
        () async {
      final repository = buildRepository(writeRefusedWithCode: '23505');

      await expectLater(
        repository.sendRequest(requesterId: _camille, addresseeId: _theo),
        throwsA(
          isA<ContactException>().having(
            (error) => error.message,
            'message',
            contains('déjà en cours'),
          ),
        ),
      );
    });

    test('sends a pending link naming both members', () async {
      final repository = buildRepository();

      await repository.sendRequest(requesterId: _camille, addresseeId: _theo);

      final insert = writeRequests.single as http.Request;
      expect(insert.url.path, endsWith('/contacts'));
      expect(jsonDecode(insert.body), {
        'requester_id': _camille,
        'addressee_id': _theo,
        'status': 'pending',
      });
    });
  });

  group('ContactRepository.fetchContacts', () {
    test('asks for both directions in one query', () async {
      final repository = buildRepository(rows: [linkRow(status: 'accepted')]);

      await repository.fetchContacts(_camille);

      final query = Uri.decodeFull(sentRequests.single.url.query);
      expect(query, contains('requester_id.eq.$_camille'));
      expect(query, contains('addressee_id.eq.$_camille'));
    });

    test('names the member on the other end of each link', () async {
      final repository = buildRepository(rows: [linkRow(status: 'accepted')]);

      final contacts = await repository.fetchContacts(_camille);

      expect(contacts.single.peer?.name, 'Théo Marchand');
      expect(contacts.single.isAccepted, isTrue);
    });
  });

  group('ContactRepository.searchMembers', () {
    test('matches on the name and leaves out the member searching', () async {
      final repository = buildRepository(
        rows: [
          {'id': _theo, 'name': 'Théo Marchand', 'avatar_url': null},
        ],
      );

      final members = await repository.searchMembers(
        query: ' Théo ',
        excludingUserId: _camille,
      );

      final query = Uri.decodeFull(sentRequests.single.url.query);
      expect(query, contains('name=ilike.%Théo%'));
      expect(query, contains('id=neq.$_camille'));
      expect(members.single.name, 'Théo Marchand');
    });

    test('asks nothing of the database until something is typed', () async {
      final repository = buildRepository();

      expect(
        await repository.searchMembers(query: '   ', excludingUserId: _camille),
        isEmpty,
      );
      expect(sentRequests, isEmpty);
    });
  });
}
