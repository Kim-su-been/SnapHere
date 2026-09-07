import 'package:snap_here/src/core/network/api_client.dart';
import 'package:snap_here/src/features/community/domain/community_models.dart';
import 'package:snap_here/src/features/community/domain/community_repository.dart';

class ApiCommunityRepository implements CommunityRepository {
  ApiCommunityRepository({ApiClient? api, this.accessToken})
    : _api = api ?? ApiClient();

  final ApiClient _api;
  final String? accessToken;
  final List<String> _recent = [];

  @override
  Future<CommunityFeed> fetchFeed({
    required CommunityFeedTab tab,
    required CommunitySort sort,
  }) async {
    if (tab == CommunityFeedTab.following) {
      return const CommunityFeed(posts: [], sectionTitle: '팔로잉 스냅');
    }
    final path = sort == CommunitySort.latest
        ? '/feeds/recent'
        : '/posts/popular';
    final query = <String, String>{'size': '30'};
    if (path.endsWith('popular')) query['period'] = 'WEEKLY';
    final page = jsonMap(
      await _api.get(path, query: query, accessToken: accessToken),
    );
    final summaries = jsonMapList(page['items']);
    final posts = await Future.wait(summaries.map(_hydrate));
    return CommunityFeed(
      sectionTitle: sort == CommunitySort.latest ? '최신 스냅' : '인기 스냅',
      posts: posts,
    );
  }

  Future<CommunityPost> _hydrate(Map<String, Object?> summary) async {
    final postId = summary['postId']! as String;
    try {
      final detail = jsonMap(
        await _api.get('/posts/$postId', accessToken: accessToken),
      );
      return _post(summary, content: detail['content'] as String? ?? '');
    } on ApiException {
      return _post(summary);
    }
  }

  CommunityPost _post(Map<String, Object?> json, {String content = ''}) {
    final author = jsonMap(json['author']);
    final place = json['place'] is Map ? jsonMap(json['place']) : null;
    final normalized = content.trim();
    final title = normalized.isEmpty
        ? (place?['title'] as String? ?? '여행 스냅')
        : normalized.split('\n').first;
    return CommunityPost(
      postId: json['postId']! as String,
      author: CommunityAuthor(
        userId: author['userId']! as String,
        nickname: author['nickname'] as String? ?? '여행자',
        profileImageUrl: author['profileImageUrl'] as String?,
      ),
      title: title,
      content: normalized,
      placeName: place?['title'] as String?,
      regionName: place?['addr1'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      imageCount: (json['imageCount'] as num? ?? 0).toInt(),
      likeCount: (json['likeCount'] as num? ?? 0).toInt(),
      commentCount: (json['commentCount'] as num? ?? 0).toInt(),
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }

  @override
  Future<CommunitySearchSuggestions> fetchSearchSuggestions() async {
    final tags = jsonMapList(
      await _api.get('/tags/popular', query: const {'limit': '10'}),
    );
    return CommunitySearchSuggestions(
      recent: List.unmodifiable(_recent),
      recommended: tags
          .map((tag) => tag['name'] as String? ?? '')
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
    );
  }

  @override
  Future<void> removeRecentKeyword(String keyword) async {
    _recent.remove(keyword);
  }

  @override
  Future<void> clearRecentKeywords() async => _recent.clear();

  @override
  Future<CommunitySearchResult> search({
    required String keyword,
    required CommunitySearchFilter filter,
  }) async {
    final value = keyword.trim();
    if (value.isEmpty) return const CommunitySearchResult.empty();
    _recent
      ..remove(value)
      ..insert(0, value);
    final page = jsonMap(
      await _api.get(
        '/posts',
        query: {
          'size': '50',
          if (filter == CommunitySearchFilter.all) 'tag': value,
        },
        accessToken: accessToken,
      ),
    );
    final hydrated = await Future.wait(
      jsonMapList(page['items']).map(_hydrate),
    );
    final lower = value.toLowerCase();
    final posts = hydrated
        .where((post) {
          final candidate = switch (filter) {
            CommunitySearchFilter.author => post.author.nickname,
            CommunitySearchFilter.region => post.regionName ?? '',
            CommunitySearchFilter.place => post.placeName ?? '',
            CommunitySearchFilter.all =>
              '${post.title} ${post.content} ${post.author.nickname} ${post.locationLabel ?? ''}',
          };
          return candidate.toLowerCase().contains(lower);
        })
        .toList(growable: false);
    return CommunitySearchResult(posts: posts, totalCount: posts.length);
  }
}
