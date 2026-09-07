import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/social/data/api_social_repository.dart';

final socialRepositoryProvider = Provider<ApiSocialRepository>(
  (ref) => ApiSocialRepository(
    accessToken: ref.watch(authControllerProvider).value?.accessToken,
  ),
);
