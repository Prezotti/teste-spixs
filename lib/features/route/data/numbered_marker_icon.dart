import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:teste_spixs/core/design/design.dart';

abstract final class NumberedMarkerIcon {
  static const _pixelRatio = 3.0;
  static const _logicalSize = 36.0;

  static Future<BitmapDescriptor> forNumber(int number) async {
    final size = (_logicalSize * _pixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      size / 2 - _pixelRatio,
      Paint()..color = AppColors.ink,
    );

    final label = TextPainter(
      text: TextSpan(
        text: '$number',
        style: AppTypography.bodyStrong.copyWith(
          color: AppColors.onBrand,
          fontSize: 15 * _pixelRatio,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    label.paint(
      canvas,
      center - Offset(label.width / 2, label.height / 2),
    );

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: _pixelRatio,
    );
  }
}
