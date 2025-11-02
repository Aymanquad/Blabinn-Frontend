import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CleanLogoGenerator {
  /// Generates a clean Chatify logo with just the purple "C" and transparent background
  static Future<Uint8List> generateCleanLogo({int size = 1024}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(size / 2, size / 2);
    final radius = size / 2.2; // Slightly smaller to ensure no clipping

    // Create the "C" path with proper proportions
    final strokeWidth = radius * 0.28;
    final cRadius = radius * 0.75;

    // Define the C shape angles (leaving gap on the right)
    const startAngle = -2.2; // Start angle (top-left)
    const sweepAngle = 4.4; // Sweep angle (leaves gap on right)

    // Create the "C" shape with gradient
    final cPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        cRadius,
        [
          const Color(0xFF9D4EDD), // Light purple
          const Color(0xFF7B2CBF), // Medium purple
          const Color(0xFF5A189A), // Dark purple
          const Color(0xFF240046), // Very dark purple
        ],
        [0.0, 0.3, 0.7, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the main "C" shape
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: cRadius),
      startAngle,
      sweepAngle,
      false,
      cPaint,
    );

    // Add inner glow effect
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        cRadius,
        [
          const Color(0xFFE0AAFF).withOpacity(0.8), // Light glow
          const Color(0xFFC77DFF).withOpacity(0.6), // Medium glow
          const Color(0xFF9D4EDD).withOpacity(0.3), // Outer glow
          Colors.transparent,
        ],
        [0.0, 0.4, 0.7, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: cRadius * 0.92),
      startAngle + 0.1,
      sweepAngle - 0.2,
      false,
      glowPaint,
    );

    // Add outer glow/shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF7B2CBF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: cRadius * 1.05),
      startAngle,
      sweepAngle,
      false,
      shadowPaint,
    );

    // Convert to image with transparency
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Save the clean logo to the assets directory
  static Future<void> saveCleanLogoToAssets() async {
    try {
      final logoBytes = await generateCleanLogo(size: 1024);

      // For now, just print success - in a real scenario you'd save to file system
      print('✅ Clean logo generated successfully: ${logoBytes.length} bytes');
      print('📁 Logo should be saved to: assets/logo/Good_logo_clean.png');

      // The actual file saving would need to be done manually or through a build script
      // since Flutter apps can't write to their asset directories at runtime
    } catch (e) {
      print('❌ Error generating clean logo: $e');
    }
  }
}
