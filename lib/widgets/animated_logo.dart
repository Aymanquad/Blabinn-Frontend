import 'package:flutter/material.dart';

class AnimatedLogo extends StatelessWidget {
  final double size;
  final bool inverted;
  final Duration? animationDuration;
  final Animation<double>? scaleAnimation;
  final Animation<double>? fadeAnimation;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.inverted = false,
    this.animationDuration,
    this.scaleAnimation,
    this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = CustomPaint(
      size: Size(size, size),
      painter: ChatifyLogoPainter(inverted: inverted),
    );

    // Apply animations if provided
    if (scaleAnimation != null) {
      logoWidget = ScaleTransition(
        scale: scaleAnimation!,
        child: logoWidget,
      );
    }

    if (fadeAnimation != null) {
      logoWidget = FadeTransition(
        opacity: fadeAnimation!,
        child: logoWidget,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: logoWidget,
    );
  }
}

class ChatifyLogoPainter extends CustomPainter {
  final bool inverted;

  ChatifyLogoPainter({this.inverted = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (inverted) {
      // Purple background circle
      final backgroundPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF8B5CF6), // Lighter purple
            const Color(0xFF6B46C1), // Main purple
            const Color(0xFF553C9A), // Darker purple
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, backgroundPaint);

      // White "C" shape
      _drawCShape(canvas, size, Colors.white);
    } else {
      // Transparent/no background, purple "C"
      _drawCShape(canvas, size, const Color(0xFF6B46C1));
    }

    // Add subtle glow effect
    if (inverted) {
      final glowPaint = Paint()
        ..color = const Color(0xFF6B46C1).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, radius + 2, glowPaint);
    }
  }

  void _drawCShape(Canvas canvas, Size size, Color color) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.25;
    final cRadius = radius * 0.65;

    // Create the "C" path
    final cPath = Path();

    // Define the C shape - open on the right side
    final startAngle = -2.5; // Start angle (top-left)
    final sweepAngle = 5.0; // Sweep angle (leaves gap on right)

    // Create outer arc
    cPath.addArc(
      Rect.fromCircle(center: center, radius: cRadius),
      startAngle,
      sweepAngle,
    );

    // Create inner arc (to make it hollow)
    final innerRadius = cRadius - strokeWidth;
    cPath.addArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      sweepAngle,
    );

    // Close the path to create the C shape
    cPath.close();

    // Draw the C
    final cPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(cPath, cPaint);

    // Add inner highlight for depth
    final highlightPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: cRadius - strokeWidth / 2),
      startAngle + 0.2,
      sweepAngle - 0.4,
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
