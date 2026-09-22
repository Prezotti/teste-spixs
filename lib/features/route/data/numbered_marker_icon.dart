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

  static Future<BitmapDescriptor> arrow() async {
    const pixelRatio = 3.0;
    const logicalSize = 44.0;
    final size = (logicalSize * pixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final path = Path()
      ..moveTo(size * 0.50, size * 0.08)
      ..lineTo(size * 0.86, size * 0.82)
      ..lineTo(size * 0.50, size * 0.64)
      ..lineTo(size * 0.14, size * 0.82)
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.brand);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.onBrand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round,
    );

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }
}
