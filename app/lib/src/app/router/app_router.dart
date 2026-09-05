import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/app/router/app_shell.dart';
import 'package:snap_here/src/core/ui/feature_placeholder.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/auth/domain/auth_models.dart';
import 'package:snap_here/src/features/auth/presentation/legal_document_screen.dart';
import 'package:snap_here/src/features/auth/presentation/login_screen.dart';
import 'package:snap_here/src/features/auth/presentation/login_required_screen.dart';
import 'package:snap_here/src/features/auth/presentation/onboarding_screen.dart';
import 'package:snap_here/src/features/auth/presentation/profile_setup_screen.dart';
import 'package:snap_here/src/features/community/presentation/community_screen.dart';
import 'package:snap_here/src/features/community/presentation/community_search_screen.dart';
import 'package:snap_here/src/features/event/presentation/event_detail_screen.dart';
import 'package:snap_here/src/features/event/presentation/event_screen.dart';
import 'package:snap_here/src/features/home/presentation/home_screen.dart';
import 'package:snap_here/src/features/map/presentation/map_screen.dart';
import 'package:snap_here/src/features/profile/presentation/profile_screen.dart';
import 'package:snap_here/src/features/rankings/presentation/rankings_screen.dart';
import 'package:snap_here/src/features/upload/presentation/upload_screen.dart';

final _authRouterRefreshProvider = Provider<_AuthRouterRefresh>((ref) {
  final refresh = _AuthRouterRefresh();
  ref.listen(authControllerProvider, (_, _) => refresh.notify());
  ref.onDispose(refresh.dispose);
  return refresh;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_authRouterRefreshProvider);
  final router = GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: refresh,
    redirect: (_, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;

      final path = state.uri.path;
      final session = auth.value;
      final isLegal = path.startsWith('/legal/');
      final isEntry = path == '/onboarding' || path == '/login';

      if (session == null) {
        final canVisitWithoutSession =
            isEntry || isLegal || path == '/login-required';
        return canVisitWithoutSession ? null : '/onboarding';
      }

      if (session.isGuest) {
        if (isEntry || path == '/profile-setup') return '/home';
        const guestProtected = {'/upload', '/notifications', '/profile'};
        if (guestProtected.contains(path)) return '/login-required';
        return null;
      }

      if (session.user!.needsProfileSetup) {
        if (path == '/profile-setup' || isLegal) return null;
        return '/profile-setup';
      }

      if (isEntry || path == '/profile-setup' || path == '/login-required') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/profile-setup',
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/login-required',
        builder: (_, _) => const LoginRequiredScreen(),
      ),
      GoRoute(
        path: '/legal/:type',
        builder: (_, state) {
          final type = LegalDocumentType.fromPath(
            state.pathParameters['type'] ?? '',
          );
          return LegalDocumentScreen(type: type);
        },
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
          // Figma `Wireframe_v3`의 하단 탭 2번째 자리는 커뮤니티다.
          // 기존 랭킹은 아래 최상위 라우트로 남겨 두었다.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (_, _) => const CommunityScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (_, _) => const CommunitySearchScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/events', builder: (_, _) => const EventScreen()),
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
      GoRoute(
        path: '/upload',
        builder: (_, state) =>
            UploadScreen(eventId: state.uri.queryParameters['eventId']),
      ),
      GoRoute(
        path: '/events/:eventId',
        builder: (_, state) =>
            EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
      // 하단 탭 4번째는 Wireframe_v3 기준 이벤트로 확정했고 랭킹 화면은
      // 기존 딥 링크 호환을 위해 최상위 라우트로 유지한다.
      GoRoute(path: '/rankings', builder: (_, _) => const RankingsScreen()),
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

class _AuthRouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
