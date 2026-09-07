import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/app/theme/app_theme.dart';
import 'package:snap_here/src/core/ui/remote_image.dart';
import 'package:snap_here/src/features/badges/application/badge_providers.dart';
import 'package:snap_here/src/features/badges/domain/badge_models.dart';
import 'package:snap_here/src/features/badges/presentation/badge_collection_screen.dart';
import 'package:snap_here/src/features/badges/presentation/visit_map_panel.dart';
import 'package:snap_here/src/features/map/application/map_configuration.dart';

const earnedBadge = CollectedBadge(id: 'bdg_1', name: '첫 여행', earned: true);
const visitMap = VisitMapSnapshot(
  points: [],
  regions: [],
  visitedRegionCount: 3,
  totalRegionCount: 17,
  progress: 3 / 17,
);

void main() {
  Future<void> mount(WidgetTester tester, {bool empty = false}) async {
    await tester.binding.setSurfaceSize(const Size(412, 893));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const BadgeCollectionScreen()),
        GoRoute(
          path: '/photos/pst_1',
          builder: (_, _) => const Scaffold(body: Text('source-post')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapConfiguredProvider.overrideWith((_) async => false),
          visitMapProvider.overrideWith((_) async => visitMap),
          badgeCollectionProvider.overrideWith(
            (_) async => BadgeCollection(
              items: empty
                  ? []
                  : [
                      earnedBadge,
                      const CollectedBadge(
                        id: 'bdg_2',
                        name: '아직 미획득',
                        earned: false,
                      ),
                    ],
              earnedCount: empty ? 0 : 1,
              obtainableCount: 2,
              progress: empty ? 0 : .5,
            ),
          ),
          badgeDetailProvider('bdg_1').overrideWith(
            (_) async => const BadgeDetail(
              badge: earnedBadge,
              currentValue: 1,
              targetValue: 1,
              earnedCount: 5,
              sourcePostId: 'pst_1',
            ),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'badge screen keeps 280px map, 40px earned icon and source-post navigation',
    (tester) async {
      await mount(tester);
      expect(tester.getSize(find.byType(VisitMapPanel)).height, 280);
      expect(tester.getSize(find.byType(RemoteImage)), const Size(40, 40));
      expect(find.text('3 / 17 지역 방문'), findsOneWidget);
      expect(find.text('아직 미획득'), findsNothing);
      await tester.tap(find.text('첫 여행'));
      await tester.pumpAndSettle();
      expect(find.text('진행 1 / 1 · 5명 획득'), findsOneWidget);
      await tester.tap(find.text('뱃지를 획득한 게시글 보기'));
      await tester.pumpAndSettle();
      expect(find.text('source-post'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty badges keep the visit-map section and empty guidance', (
    tester,
  ) async {
    await mount(tester, empty: true);
    expect(find.textContaining('아직 수집한 뱃지가 없어요'), findsOneWidget);
    expect(find.text('여행 사진을 올리면 방문 장소가 표시돼요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
