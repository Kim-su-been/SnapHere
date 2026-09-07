import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:snap_here/src/core/ui/paged_sliver.dart';
import 'package:snap_here/src/features/explore/application/explore_providers.dart';
import 'package:snap_here/src/features/home/application/home_map_providers.dart';
import 'package:snap_here/src/features/map/presentation/snap_map.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regions = ref.watch(mapRegionsProvider);
    final markers = <Marker>{};
    for (final region in regions.value ?? []) {
      if (region.latitude == null || region.longitude == null) continue;
      final icon = ref
          .watch(
            countMarkerProvider((count: region.postCount, selected: false)),
          )
          .value;
      if (icon == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('region-${region.areaCode}'),
          position: LatLng(region.latitude!, region.longitude!),
          icon: icon,
          anchor: const Offset(.5, .5),
          infoWindow: InfoWindow(
            title: region.name,
            snippet: '게시글 ${region.postCount}개',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('SnapHere'), toolbarHeight: 52),
      body: Stack(
        children: [
          Positioned.fill(child: SnapMap(markers: markers)),
          if (regions.isLoading) const LinearProgressIndicator(),
          if (regions.hasError)
            RetryMessage(
              message: '지역 데이터를 불러오지 못했어요',
              onRetry: () => ref.invalidate(mapRegionsProvider),
            ),
        ],
      ),
    );
  }
}
