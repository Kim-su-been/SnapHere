import 'package:flutter/foundation.dart';

/// 커뮤니티 피드 탭. Figma `03_커뮤니티_전체` 상단 탭 2개.
enum CommunityFeedTab { all, following }

/// `03_커뮤니티_전체`의 정렬 드롭다운.
///
/// 검수 노트 "결정이 필요한 항목 2 — 커뮤니티 정렬 기준: 최신순 / 인기순 / 추천순
/// 추후 확정"에 따라 후보 3개를 그대로 두었다. 확정되면 값을 정리한다.
enum CommunitySort {
  latest('최신순'),
  popular('인기순'),
  recommended('추천순');

  const CommunitySort(this.label);

  final String label;
}

/// `03_커뮤니티_검색결과`의 필터 칩 4개.
enum CommunitySearchFilter {
  all('전체'),
  author('작성자'),
  region('지역'),
  place('장소');

  const CommunitySearchFilter(this.label);

  final String label;
}

/// 게시글 작성자. ERD `users`의 노출 필드만 담는다.
@immutable
class CommunityAuthor {
  const CommunityAuthor({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
  });

  final String userId;
  final String nickname;
  final String? profileImageUrl;

  /// 프로필 이미지가 없을 때 아바타에 넣는 짧은 이름.
  /// Figma는 닉네임 앞 2글자를 쓴다 (`민수_Kim` → `민수`).
  String get avatarLabel =>
      nickname.length <= 2 ? nickname : nickname.substring(0, 2);
}

/// 카드 우상단 배지. Figma `03_커뮤니티_전체`의 "스냅 챌린지".
@immutable
class CommunityBadge {
  const CommunityBadge({required this.label});

  final String label;
}

/// 커뮤니티 피드/검색 결과에 쓰는 게시글 카드 모델.
///
/// ERD `posts` + `post_images` + `places` + `users`를 화면이 필요한 만큼만
/// 합친 형태다. 서버 응답 형태가 확정되면 [CommunityRepository] 구현체에서
/// 이 모델로 변환한다.
@immutable
class CommunityPost {
  const CommunityPost({
    required this.postId,
    required this.author,
    required this.title,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.placeName,
    this.regionName,
    this.badge,
    this.thumbnailUrl,
    this.imageCount = 1,
  });

  final String postId;
  final CommunityAuthor author;
  final String title;
  final String content;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  /// ERD `places.title`.
  final String? placeName;

  /// ERD `regions.name_ko`.
  final String? regionName;

  final CommunityBadge? badge;

  /// ERD `post_images.thumbnail_url`. 아직 API가 없어 더미에서는 null이고,
  /// 화면은 자리 표시자를 그린다.
  final String? thumbnailUrl;

  /// 사진이 여러 장일 때 이미지 위 `+N` 칩에 쓴다.
  final int imageCount;

  /// Figma가 장소를 `경복궁 근정전 · 서울` 형태로 표시한다.
  String? get locationLabel {
    if (placeName == null && regionName == null) return null;
    return [placeName, regionName].whereType<String>().join(' · ');
  }
}

/// 커뮤니티 피드 한 페이지.
@immutable
class CommunityFeed {
  const CommunityFeed({required this.posts, this.sectionTitle});

  final List<CommunityPost> posts;

  /// Figma `03_커뮤니티_전체`의 목록 위 라벨 ("인기 스냅").
  final String? sectionTitle;

  bool get isEmpty => posts.isEmpty;
}

/// 검색 결과. `03_커뮤니티_검색결과`는 "검색 결과 24건"처럼 총 건수를 보여준다.
@immutable
class CommunitySearchResult {
  const CommunitySearchResult({required this.posts, required this.totalCount});

  const CommunitySearchResult.empty() : posts = const [], totalCount = 0;

  final List<CommunityPost> posts;
  final int totalCount;

  bool get isEmpty => posts.isEmpty;
}

/// `03_커뮤니티_검색_포커스`의 최근/추천 검색어.
@immutable
class CommunitySearchSuggestions {
  const CommunitySearchSuggestions({
    required this.recent,
    required this.recommended,
  });

  /// 삭제 가능한 칩.
  final List<String> recent;

  /// 삭제할 수 없는 제안 칩.
  final List<String> recommended;
}
