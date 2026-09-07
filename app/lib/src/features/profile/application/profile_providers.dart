import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/profile/data/api_profile_repository.dart';
import 'package:snap_here/src/features/profile/domain/profile_models.dart';

final profileSnapshotProvider = FutureProvider<ProfileSnapshot?>((ref) {
  final token = ref.watch(authControllerProvider).value?.accessToken;
  if (token == null) return Future.value(null);
  return ApiProfileRepository(accessToken: token).fetchMe();
});
