import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monapp/data/contact_repository.dart';
import 'package:monapp/models/contact.dart';
import 'package:monapp/providers/auth_provider.dart';
import 'package:monapp/providers/contact_provider.dart';
import 'package:monapp/screens/contacts/contacts_screen.dart';
import 'package:monapp/screens/contacts/member_search_screen.dart';
import 'package:monapp/widgets/member_row.dart';

import '../../support/test_fixtures.dart';

late List<http.BaseRequest> sentRequests;

List<Override> overridesFor(List<Contact> contacts) {
  return [
    currentUserProvider.overrideWithValue(buildSignedInUser()),
    contactsProvider.overrideWith((ref) => contacts),
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
  ];
}

Future<void> pumpContactsScreen(
  WidgetTester tester, {
  List<Contact> contacts = const [],
}) async {
  await tester.pumpWidget(
    buildTestApp(
      overrides: overridesFor(contacts),
      child: const ContactsScreen(),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => sentRequests = <http.BaseRequest>[]);

  group('ContactsScreen', () {
    testWidgets('lists the accepted contacts', (tester) async {
      await pumpContactsScreen(
        tester,
        contacts: [
          buildContact(peerName: 'Théo Marchand'),
          buildContact(
            id: 'contact-2',
            requesterId: 'user-3',
            peerName: 'Inès Barbier',
          ),
        ],
      );

      expect(find.byType(MemberRow), findsNWidgets(2));
      expect(find.text('Théo Marchand'), findsOneWidget);
      expect(find.text('Inès Barbier'), findsOneWidget);
      expect(find.text('Demandes reçues'), findsNothing);
    });

    testWidgets('puts the requests received first, with a way to answer them',
        (tester) async {
      await pumpContactsScreen(
        tester,
        contacts: [
          buildContact(peerName: 'Théo Marchand'),
          buildContact(
            id: 'contact-2',
            requesterId: 'user-3',
            status: ContactStatus.pending,
            peerName: 'Inès Barbier',
          ),
        ],
      );

      expect(find.text('Demandes reçues'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Accepter'), findsOneWidget);

      final rows = tester.widgetList<MemberRow>(find.byType(MemberRow));
      expect(rows.first.name, 'Inès Barbier');
    });

    // A pending link is not a contact, and the one it is waiting on is the
    // other member. Offering to accept it here would be offering to answer
    // oneself.
    testWidgets('shows a request it sent as waiting, not as answerable',
        (tester) async {
      await pumpContactsScreen(
        tester,
        contacts: [
          buildContact(
            requesterId: 'user-1',
            addresseeId: 'user-2',
            status: ContactStatus.pending,
            peerName: 'Théo Marchand',
          ),
        ],
      );

      expect(find.text('Demandes reçues'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Accepter'), findsNothing);
      expect(find.text('Demandes envoyées'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget);
      expect(find.textContaining('Aucun contact accepté'), findsOneWidget);
    });

    testWidgets('accepts a request and says whose it was', (tester) async {
      await pumpContactsScreen(
        tester,
        contacts: [
          buildContact(status: ContactStatus.pending, peerName: 'Théo Marchand'),
        ],
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Accepter'));
      await tester.pump();
      await tester.pump();

      final update = sentRequests.whereType<http.Request>().single;
      expect(update.method, 'PATCH');
      expect(jsonDecode(update.body), {'status': 'accepted'});
      expect(Uri.decodeFull(update.url.query), contains('id=eq.contact-1'));
      expect(
        find.textContaining('Théo Marchand fait maintenant partie'),
        findsOneWidget,
      );
    });

    testWidgets('says how to fill an empty contact list', (tester) async {
      await pumpContactsScreen(tester);

      expect(find.byType(MemberRow), findsNothing);
      expect(find.textContaining('Cherchez un collègue'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Chercher un collègue'));
      await tester.pumpAndSettle();

      expect(find.byType(MemberSearchScreen), findsOneWidget);
    });
  });
}
