import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_here/src/app.dart';

void main() {
  testWidgets('onboarding reaches the main navigation shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SnapHereApp()));

    expect(find.text('찍고, 발견하고, 함께 떠나요'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('다시 만나 반가워요'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('로그인'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('앱 권한 안내'), findsOneWidget);

    await tester.tap(find.text('확인하고 홈으로'));
    await tester.pumpAndSettle();

    expect(find.text('어디의 순간을 볼까요?'), findsOneWidget);
    expect(find.text('업로드'), findsOneWidget);
  });
}
