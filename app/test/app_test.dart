import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_here/src/app.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/auth/data/session_store.dart';
import 'package:snap_here/src/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('auth and permission flow reaches the main navigation shell', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 893));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        ],
        child: const SnapHereApp(),
      ),
    );

    expect(find.text('지도에서 관광지를 탐색하세요'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('Google로 계속하기'), findsOneWidget);

    await tester.tap(find.text('Google로 계속하기'));
    await tester.pumpAndSettle();
    expect(find.text('프로필 설정'), findsOneWidget);

    final completeButton = find.text('완료');
    await tester.ensureVisible(completeButton);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '완료'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField).first, '여행토끼');
    await tester.tap(find.text('[필수] 서비스 이용약관 동의'));
    await tester.tap(find.text('[필수] 개인정보 수집·이용 동의'));
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '완료'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(completeButton);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
