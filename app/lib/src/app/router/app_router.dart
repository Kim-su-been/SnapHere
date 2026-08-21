import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/app/router/app_shell.dart';
import 'package:snap_here/src/core/ui/feature_placeholder.dart';
import 'package:snap_here/src/features/auth/presentation/login_screen.dart';
import 'package:snap_here/src/features/auth/presentation/onboarding_screen.dart';
import 'package:snap_here/src/features/auth/presentation/permissions_screen.dart';
import 'package:snap_here/src/features/home/presentation/home_screen.dart';
import 'package:snap_here/src/features/map/presentation/map_screen.dart';
import 'package:snap_here/src/features/profile/presentation/profile_screen.dart';
import 'package:snap_here/src/features/rankings/presentation/rankings_screen.dart';
import 'package:snap_here/src/features/upload/presentation/upload_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/permissions',
        builder: (_, _) => const PermissionsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rankings',
                builder: (_, _) => const RankingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/upload', builder: (_, _) => const UploadScreen()),
      GoRoute(
        path: '/search',
        builder: (_, _) => const FeaturePlaceholder(
          title: '관광지 검색',
          description: 'TourAPI 키워드 검색과 추천 검색어를 연결할 화면입니다.',
          icon: Icons.search,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const FeaturePlaceholder(
          title: '알림',
          description: '추천, 댓글, 랭킹 알림에서 관련 콘텐츠로 이동합니다.',
          icon: Icons.notifications_none,
        ),
      ),
      GoRoute(
        path: '/regions/:regionId',
        builder: (_, state) => FeaturePlaceholder(
          title: '${state.pathParameters['regionId']} 커뮤니티',
          description: '17개 시도별 사진 피드와 추천 관광지를 제공합니다.',
          icon: Icons.groups_outlined,
        ),
      ),
      GoRoute(
        path: '/photos/:photoId',
        builder: (_, _) => const FeaturePlaceholder(
          title: '사진 상세',
          description: '사진 추천, 댓글, 저장, 태그와 연결 관광지를 보여줍니다.',
          icon: Icons.photo_outlined,
        ),
      ),
      GoRoute(
        path: '/places/:placeId',
        builder: (_, _) => const FeaturePlaceholder(
          title: '관광지 상세',
          description: '공식 관광정보, 이용자 사진, 촬영지 메타데이터를 결합합니다.',
          icon: Icons.place_outlined,
        ),
      ),
      GoRoute(
        path: '/k-culture',
        builder: (_, _) => const FeaturePlaceholder(
          title: 'K-컬처',
          description: '드라마, 영화, 예능 촬영지 피드와 테마별 랭킹을 제공합니다.',
          icon: Icons.movie_filter_outlined,
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
