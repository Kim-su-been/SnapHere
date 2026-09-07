import 'package:flutter/foundation.dart';
import 'package:snap_here/src/features/community/domain/community_models.dart';

@immutable
class RegionOverview {
  const RegionOverview({
    required this.areaCode,
    required this.name,
    this.imageUrl,
    this.postCount = 0,
    this.contributorCount = 0,
    this.representativePost,
  });

  final int areaCode;
  final String name;
  final String? imageUrl;
  final int postCount;
  final int contributorCount;
  final CommunityPost? representativePost;
}

abstract interface class ExploreRepository {
  Future<List<RegionOverview>> fetchRegions();
  Future<List<RegionOverview>> fetchMapRegions();
}
