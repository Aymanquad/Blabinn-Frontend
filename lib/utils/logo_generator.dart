import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class LogoGenerator {
  /// Generates the inverted Chatify logo (white C on purple background)
  static Future<Uint8List> generateInvertedLogo({int size = 512}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    // Draw purple background circle with gradient
    paint.shader = ui.Gradient.radial(
      center,
      radius.toDouble(),
      [
        const Color(0xFF8B5CF6), // Lighter purple
        const Color(0xFF6B46C1), // Main purple
        const Color(0xFF553C9A), // Darker purple
      ],
      [0.0, 0.7, 1.0],
    );
    canvas.drawCircle(center, radius.toDouble(), paint);

    // Draw white "C" shape
    paint.shader = null;
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = radius * 0.25;
    paint.strokeCap = StrokeCap.round;

    final cRadius = radius * 0.65;
    const startAngle = -2.5;
    const sweepAngle = 5.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: cRadius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Add subtle inner shadow for depth
    paint.color = Colors.white.withOpacity(0.8);
    paint.strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: cRadius - (radius * 0.25) / 2),
      startAngle + 0.2,
      sweepAngle - 0.4,
      false,
      paint,
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Saves the generated logo to assets (for development use)
  static Future<void> saveInvertedLogoToAssets() async {
    try {
      final logoBytes = await generateInvertedLogo(size: 512);

      // In a real app, you would save this to the file system
      // For now, we'll just generate it in memory and use it in the widget
      print('Logo generated successfully: ${logoBytes.length} bytes');
    } catch (e) {
      print('Error generating logo: $e');
    }
  }
}

