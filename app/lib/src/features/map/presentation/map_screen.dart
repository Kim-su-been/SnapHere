import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지도 탐색')),
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 72),
                SizedBox(height: 12),
                Text('지도 SDK 연동 영역'),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 112,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.place_outlined),
                title: const Text('내 주변 관광지'),
                subtitle: const Text('TourAPI 위치 기반 결과가 표시됩니다.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/places/nearby-sample'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
