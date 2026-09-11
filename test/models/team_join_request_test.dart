import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/models/team_join_request.dart';

Map<String, dynamic> row({
  String status = 'pending',
  Object? applicant,
  Object? team,
}) {
  return <String, dynamic>{
    'id': 'request-1',
    'team_id': 'team-1',
    'user_id': 'user-1',
    'status': status,
    'created_at': '2026-09-11T10:00:00+00:00',
    'applicant': applicant,
    'team': team,
  };
}

void main() {
  group('TeamJoinRequest.fromJson', () {
    test('reads the request itself without the embedded rows', () {
      // The owner's query embeds the applicant and the member's query embeds
      // the team; neither is present in the other, and the request is complete
      // without either.
      final request = TeamJoinRequest.fromJson(row());

      expect(request.id, 'request-1');
      expect(request.teamId, 'team-1');
      expect(request.userId, 'user-1');
      expect(request.applicantName, isNull);
      expect(request.teamName, isNull);
    });

    test('reads the applicant when the query asked for it', () {
      final request = TeamJoinRequest.fromJson(
        row(
          applicant: <String, dynamic>{
            'name': 'Yanis Chevalier',
            'avatar_url': 'https://example.test/y.jpg',
          },
        ),
      );

      expect(request.applicantName, 'Yanis Chevalier');
      expect(request.applicantAvatarUrl, 'https://example.test/y.jpg');
    });

    test('reads the team when the query asked for it', () {
      final request = TeamJoinRequest.fromJson(
        row(team: <String, dynamic>{'name': 'Les Rouges'}),
      );

      expect(request.teamName, 'Les Rouges');
    });
  });

  group('status', () {
    test('recognises each of the three the constraint allows', () {
      expect(
        TeamJoinRequest.fromJson(row()).status,
        JoinRequestStatus.pending,
      );
      expect(
        TeamJoinRequest.fromJson(row(status: 'accepted')).status,
        JoinRequestStatus.accepted,
      );
      expect(
        TeamJoinRequest.fromJson(row(status: 'declined')).status,
        JoinRequestStatus.declined,
      );
    });

    test('treats anything else as still waiting', () {
      // Safer than throwing: a status added later must leave the request
      // showing as undecided rather than crash an older build.
      expect(
        TeamJoinRequest.fromJson(row(status: 'withdrawn')).status,
        JoinRequestStatus.pending,
      );
    });

    test('only a pending request counts as waiting', () {
      expect(TeamJoinRequest.fromJson(row()).isPending, isTrue);
      expect(
        TeamJoinRequest.fromJson(row(status: 'declined')).isPending,
        isFalse,
      );
    });
  });
}
