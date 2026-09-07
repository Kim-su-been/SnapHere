import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/app.dart';
import 'package:snap_here/src/app/router/app_router.dart';
import 'package:snap_here/src/app/router/login_navigation.dart';
import 'package:snap_here/src/core/network/cursor_page.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/auth/domain/auth_models.dart';
import 'package:snap_here/src/features/auth/presentation/login_required_screen.dart';
import 'package:snap_here/src/features/auth/presentation/login_screen.dart';
import 'package:snap_here/src/features/community/domain/community_models.dart';
import 'package:snap_here/src/features/explore/application/explore_providers.dart';
import 'package:snap_here/src/features/home/presentation/home_screen.dart';
import 'package:snap_here/src/features/map/application/map_configuration.dart';
import 'package:snap_here/src/features/profile/application/profile_providers.dart';
import 'package:snap_here/src/features/profile/data/api_profile_repository.dart';
import 'package:snap_here/src/features/profile/domain/profile_models.dart';

class _GuestAuth extends AuthController {
  @override
  Future<AuthSession?> build() async => const AuthSession.guest();

  @override
  Future<bool> signInWithGoogle() async => false;

  void finishLogin() => state = const AsyncData(
    AuthSession.authenticated(
      accessToken: 'test',
      refreshToken: 'test',
      user: AuthUser(
        id: 'u1',
        email: 'test@example.test',
        needsProfileSetup: false,
      ),
    ),
  );
}

class _Profiles extends ApiProfileRepository {
  ProfileSnapshot profile(String id) => ProfileSnapshot(
    userId: id,
    nickname: '테스트 여행자',
    stats: const ProfileStats(
      postCount: 0,
      followerCount: 1,
      followingCount: 2,
      badgeCount: 0,
    ),
  );
  @override
  Future<ProfileSnapshot> fetchMe() async => profile('u1');
  @override
  Future<ProfileSnapshot> fetchUser(String userId) async => profile(userId);
  @override
  Future<CursorPage<CommunityPost>> fetchPosts(
    String userId, {
    String? cursor,
  }) async => const CursorPage(items: []);
}

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    Size size = const Size(412, 893),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_GuestAuth.new),
        mapConfiguredProvider.overrideWith((_) async => false),
        mapRegionsProvider.overrideWith((_) async => const []),
        profileRepositoryProvider.overrideWithValue(_Profiles()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SnapHereApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  test('login return locations stay inside the app and avoid entry loops', () {
    for (final value in [
      null,
      '',
      'https://example.test',
      '//example.test',
      '/login',
      '/login-required',
      '/profile-setup',
      '/onboarding',
      r'/\example.test',
    ]) {
      expect(loginReturnLocation(value), '/home');
    }
    expect(loginReturnLocation('/users/u2?tab=posts'), '/users/u2?tab=posts');
  });

  testWidgets(
    'guest My prompt preserves home and opens a reachable login screen',
    (tester) async {
      final container = await mount(tester);
      final router = container.read(appRouterProvider);
      await tester.tap(find.text('마이'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginRequiredScreen), findsOneWidget);
      expect(find.text('전북 게시글'), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      await tester.tap(find.text('마이'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('로그인하러 가기'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Google로 계속하기'), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.byType(LoginScreen)))
            .uri
            .queryParameters['from'],
        '/profile',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('public profile follow prompt cancels back to the same profile', (
    tester,
  ) async {
    final container = await mount(tester);
    final router = container.read(appRouterProvider);
    router.push('/users/u2');
    await tester.pumpAndSettle();
    await tester.tap(find.text('팔로우'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LoginRequiredScreen>(find.byType(LoginRequiredScreen))
          .returnTo,
      '/users/u2',
    );
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(
      GoRouterState.of(tester.element(find.text('테스트 여행자'))).uri.path,
      '/users/u2',
    );
    expect(find.text('테스트 여행자'), findsOneWidget);
  });

  testWidgets('protected deep links stay guarded and resume only after login', (
    tester,
  ) async {
    final container = await mount(tester);
    final router = container.read(appRouterProvider);
    router.go('/profile');
    await tester.pumpAndSettle();
    expect(find.byType(LoginRequiredScreen), findsOneWidget);
    await tester.tap(find.text('로그인하러 가기'));
    await tester.pumpAndSettle();
    (container.read(authControllerProvider.notifier) as _GuestAuth)
        .finishLogin();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    expect(find.text('테스트 여행자'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login actions remain reachable in a short landscape viewport', (
    tester,
  ) async {
    final container = await mount(tester, size: const Size(740, 320));
    container.read(appRouterProvider).push('/login');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Google로 계속하기'));
    await tester.pumpAndSettle();
    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an incomplete Google sign-in gives feedback without leaving login',
    (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).push('/login');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Google로 계속하기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('로그인이 완료되지 않았어요.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(container.read(authControllerProvider).value?.isGuest, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
