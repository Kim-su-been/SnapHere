import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:snap_here/src/features/map/presentation/count_marker.dart';

final countMarkerProvider = FutureProvider.autoDispose
    .family<BitmapDescriptor, ({int count, bool selected})>(
      (ref, args) => countMarker(args.count, selected: args.selected),
    );
