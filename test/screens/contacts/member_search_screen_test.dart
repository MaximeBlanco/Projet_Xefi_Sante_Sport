import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monapp/data/contact_repository.dart';
import 'package:monapp/models/contact.dart';
import 'package:monapp/models/member_summary.dart';
import 'package:monapp/providers/auth_provider.dart';
import 'package:monapp/providers/contact_provider.dart';
import 'package:monapp/screens/contacts/member_search_screen.dart';

import '../../support/test_fixtures.dart';

late List<http.BaseRequest> sentRequests;

/// Past the pause the screen waits out before querying anything, so a name is
/// typed rather than queried letter by letter.
const _afterTheTypingPause = Duration(milliseconds: 400);

Future<void> pumpSearchScreen(
  WidgetTester tester, {
  List<MemberSummary> results = const [],
  List<Contact> contacts = const [],
}) async {
  await tester.pumpWidget(
    buildTestApp(
      overrides: [
        currentUserProvider.overrideWithValue(buildSignedInUser()),
        contactsProvider.overrideWith((ref) => contacts),
        memberSearchProvider.overrideWith((ref, query) => results),
        contactRepositoryProvider.overrideWithValue(
          ContactRepository(
            buildStubSupabaseClient((request) async {
              sentRequests.add(request);
              return http.Response(
                jsonEncode(const <Map<String, dynamic>>[]),
                200,
                request: request,
                headers: const {'content-type': 'application/json'},
              );
            }),
          ),
        ),
      ],
      child: const MemberSearchScreen(),
    ),
  );
  await tester.pump();
}

Future<void> search(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField), name);
  await tester.pump(_afterTheTypingPause);
  await tester.pump();
}

void main() {
  setUp(() => sentRequests = <http.BaseRequest>[]);

  group('MemberSearchScreen', () {
    testWidgets('waits for two letters before searching anything',
        (tester) async {
      await pumpSearchScreen(
        tester,
        results: [buildMemberSummary(name: 'Théo Marchand')],
      );

      await search(tester, 'T');

      expect(find.textContaining('au moins deux lettres'), findsOneWidget);
      expect(find.text('Théo Marchand'), findsNothing);
    });

    testWidgets('offers to add a member who is not a contact yet',
        (tester) async {
      await pumpSearchScreen(
        tester,
        results: [buildMemberSummary(name: 'Théo Marchand')],
      );

      await search(tester, 'Théo');

      expect(find.text('Théo Marchand'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
      await tester.pump();
      await tester.pump();

      final insert = sentRequests
          .whereType<http.Request>()
          .where((request) => request.method == 'POST')
          .single;
      expect(jsonDecode(insert.body), {
        'requester_id': 'user-1',
        'addressee_id': 'user-2',
        'status': 'pending',
      });
      expect(find.textContaining('Demande envoyée à Théo'), findsOneWidget);
    });

    // FR-003 lands in the database, but a button that cannot work should not be
    // offered in the first place.
    testWidgets('shows the wait instead of a second request', (tester) async {
      await pumpSearchScreen(
        tester,
        results: [buildMemberSummary(name: 'Théo Marchand')],
        contacts: [
          buildContact(
            requesterId: 'user-1',
            addresseeId: 'user-2',
            status: ContactStatus.pending,
          ),
        ],
      );

      await search(tester, 'Théo');

      expect(find.text('En attente'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ajouter'), findsNothing);
    });

    testWidgets('names an existing contact as one', (tester) async {
      await pumpSearchScreen(
        tester,
        results: [buildMemberSummary(name: 'Théo Marchand')],
        contacts: [buildContact()],
      );

      await search(tester, 'Théo');

      expect(find.text('Contact'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ajouter'), findsNothing);
    });

    testWidgets('says nobody matched rather than showing an empty list',
        (tester) async {
      await pumpSearchScreen(tester);

      await search(tester, 'Zzz');

      expect(find.textContaining('Aucun membre ne correspond'), findsOneWidget);
      expect(find.textContaining('« Zzz »'), findsOneWidget);
    });
  });
}
