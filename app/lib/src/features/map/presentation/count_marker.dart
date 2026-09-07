import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:snap_here/src/app/theme/app_tokens.dart';

/// Figma count bubble: 32px outer height, 8px dot, 14px text.
/// 서버 통계를 canvas로 렌더링하므로 예시 수치를 담은 이미지가 필요하지 않다.
Future<BitmapDescriptor> countMarker(int count, {bool selected = false}) async {
  final label = count >= 1000
      ? '${(count / 1000).toStringAsFixed(1)}k'
      : '$count';
  final text = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = text.width + 34;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(3);
  final shape = RRect.fromRectAndRadius(
    Rect.fromLTWH(1, 1, width - 2, 30),
    const Radius.circular(16),
  );
  canvas.drawRRect(
    shape,
    Paint()..color = selected ? AppColors.brandSubtle : Colors.white,
  );
  canvas.drawRRect(
    shape,
    Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
  canvas.drawCircle(const Offset(14, 16), 4, Paint()..color = AppColors.brand);
  text.paint(canvas, Offset(24, (32 - text.height) / 2));
  final picture = recorder.endRecording();
  final raster = await picture.toImage((width * 3).ceil(), 96);
  final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
  final bitmap = BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    width: width,
    height: 32,
  );
  raster.dispose();
  picture.dispose();
  text.dispose();
  return bitmap;
}
