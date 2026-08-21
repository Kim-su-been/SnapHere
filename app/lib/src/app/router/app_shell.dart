import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navigationIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            context.push('/upload');
            return;
          }
          final branchIndex = index > 2 ? index - 1 : index;
          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            label: '랭킹',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: '업로드',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: '지도'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '마이'),
        ],
      ),
    );
  }

  int get _navigationIndex {
    final index = navigationShell.currentIndex;
    return index > 1 ? index + 1 : index;
  }
}
