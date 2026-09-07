import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/app/theme/app_tokens.dart';
import 'package:snap_here/src/core/ui/design_icon.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var index = 0; index < 5; index++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: index == _navigationIndex,
                      label: const ['홈', '커뮤니티', '업로드', '이벤트', '마이'][index],
                      child: InkResponse(
                        onTap: () {
                          if (index == 2) {
                            context.push('/upload');
                            return;
                          }
                          final branchIndex = index > 2 ? index - 1 : index;
                          navigationShell.goBranch(
                            branchIndex,
                            initialLocation:
                                branchIndex == navigationShell.currentIndex,
                          );
                        },
                        child: SizedBox(
                          height: 64,
                          child: Center(
                            child: index == 2
                                ? Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.brand,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const DesignIcon(
                                      'plus',
                                      color: Colors.white,
                                    ),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DesignIcon(
                                        const [
                                          'home',
                                          'community',
                                          '',
                                          'events',
                                          'profile',
                                        ][index],
                                        color: index == _navigationIndex
                                            ? AppColors.brand
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        const [
                                          '홈',
                                          '커뮤니티',
                                          '',
                                          '이벤트',
                                          '마이',
                                        ][index],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: index == _navigationIndex
                                              ? AppColors.brand
                                              : AppColors.textSecondary,
                                          fontWeight: index == _navigationIndex
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get _navigationIndex {
    final index = navigationShell.currentIndex;
    return index > 1 ? index + 1 : index;
  }
}
