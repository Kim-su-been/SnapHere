import 'package:snap_here/src/core/network/api_client.dart';
import 'package:snap_here/src/features/profile/domain/profile_models.dart';

class ApiProfileRepository {
  ApiProfileRepository({required this.accessToken, ApiClient? api})
    : _api = api ?? ApiClient();

  final String accessToken;
  final ApiClient _api;

  Future<ProfileSnapshot> fetchMe() async {
    final data = jsonMap(await _api.get('/me', accessToken: accessToken));
    final profile = jsonMap(data['profile']);
    final user = jsonMap(profile['user']);
    final stats = jsonMap(profile['stats']);
    return ProfileSnapshot(
      bio: user['bio'] as String?,
      stats: ProfileStats(
        postCount: (stats['postCount'] as num? ?? 0).toInt(),
        followerCount: (stats['followerCount'] as num? ?? 0).toInt(),
        followingCount: (stats['followingCount'] as num? ?? 0).toInt(),
        badgeCount: (stats['badgeCount'] as num? ?? 0).toInt(),
      ),
    );
  }
}
