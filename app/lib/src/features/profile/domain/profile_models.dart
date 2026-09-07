import 'package:flutter/foundation.dart';

@immutable
class ProfileStats {
  const ProfileStats({
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    required this.badgeCount,
  });

  final int postCount;
  final int followerCount;
  final int followingCount;
  final int badgeCount;
}

@immutable
class ProfileSnapshot {
  const ProfileSnapshot({required this.stats, this.bio});

  final ProfileStats stats;
  final String? bio;
}
