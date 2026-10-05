import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monapp/data/ranking_repository.dart';

import '../support/test_fixtures.dart';

late List<http.BaseRequest> sentRequests;

RankingRepository buildRepository() {
  return RankingRepository(
    buildStubSupabaseClient((request) async {
      sentRequests.add(request);
      return http.Response(
        jsonEncode(const <Map<String, dynamic>>[]),
        200,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
    }),
  );
}

void main() {
  setUp(() => sentRequests = <http.BaseRequest>[]);

  group('RankingRepository', () {
    // The circle is drawn in the database, by a view that reads auth.uid(). An
    // app that queried the global view and filtered the rows itself would hand
    // every member's total to anyone who asked the API directly.
    test('reads the contacts leaderboard from the view that filters itself',
        () async {
      await buildRepository().fetchContactsRanking();

      final query = sentRequests.single;
      expect(query.url.path, endsWith('/rankings_contacts'));
      expect(
        Uri.decodeFull(query.url.query),
        contains('order=total_points.desc'),
      );
    });

    test('leaves the company leaderboard on its own view', () async {
      await buildRepository().fetchGlobalRanking();

      expect(sentRequests.single.url.path, endsWith('/rankings_global'));
    });
  });
}
