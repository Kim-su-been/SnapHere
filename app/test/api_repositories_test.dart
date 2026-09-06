import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snap_here/src/core/network/api_client.dart';
import 'package:snap_here/src/features/community/data/api_community_repository.dart';
import 'package:snap_here/src/features/community/domain/community_models.dart';
import 'package:snap_here/src/features/explore/data/api_explore_repository.dart';

void main() {
  test(
    'ApiClient unwraps UTF-8 API envelopes and normalizes the root',
    () async {
      final api = ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/regions');
          return http.Response.bytes(
            utf8.encode(jsonEncode({'success': true, 'data': '서울'})),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      expect(await api.get('/regions'), '서울');
    },
  );

  test(
    'community repository loads summaries and hydrates post content',
    () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/feeds/recent')) {
          return _json({
            'data': {
              'items': [_summary()],
              'nextCursor': null,
              'hasNext': false,
            },
          });
        }
        if (request.url.path.endsWith('/posts/1')) {
          return _json({
            'data': {'content': '경복궁의 가을\n정말 아름다웠어요.'},
          });
        }
        fail('unexpected request: ${request.url}');
      });
      final repository = ApiCommunityRepository(
        api: ApiClient(baseUrl: 'http://test', client: client),
      );

      final feed = await repository.fetchFeed(
        tab: CommunityFeedTab.all,
        sort: CommunitySort.latest,
      );

      expect(feed.posts.single.title, '경복궁의 가을');
      expect(feed.posts.single.author.nickname, '여행자');
      expect(feed.posts.single.placeName, '경복궁');
    },
  );

  test('explore repository maps region aggregates', () async {
    final repository = ApiExploreRepository(
      api: ApiClient(
        baseUrl: 'http://test/api/v1',
        client: MockClient(
          (request) async => _json({
            'data': [
              {
                'region': {
                  'areaCode': 1,
                  'nameKo': '서울',
                  'nameEn': 'Seoul',
                  'representativeImageUrl': null,
                },
                'postCount': 12,
                'contributorCount': 4,
                'representativePost': null,
              },
            ],
          }),
        ),
      ),
    );

    final regions = await repository.fetchMapRegions();

    expect(regions.single.name, '서울');
    expect(regions.single.postCount, 12);
    expect(regions.single.contributorCount, 4);
  });
}

http.Response _json(Object body, {int status = 200}) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _summary() => {
  'postId': '1',
  'author': {'userId': 'user-1', 'nickname': '여행자', 'profileImageUrl': null},
  'place': {'placeId': 'plc_1', 'title': '경복궁', 'addr1': '서울 종로구'},
  'thumbnailUrl': null,
  'imageCount': 1,
  'likeCount': 3,
  'commentCount': 1,
  'createdAt': '2026-09-06T10:00:00+09:00',
};
