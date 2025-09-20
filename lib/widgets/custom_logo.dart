import 'package:flutter/material.dart';

class CustomLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const CustomLogo({
    super.key,
    this.size = 120,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showGlow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: ChatifyLogoPainter(),
      ),
    );
  }
}

class ChatifyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create a circular background with gradient
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3D2A7A),
          const Color(0xFF2D1B69),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, backgroundPaint);

    // Create the "C" shape that fills the circle properly
    final cRadius = radius * 0.7;
    final strokeWidth = radius * 0.3;

    // Define the C path - a proper C that fills the circle
    final cPath = Path();
    final startAngle = -3.14 / 3; // -60 degrees
    final endAngle = 3.14 + 3.14 / 3; // 240 degrees

    // Create the outer arc of the C
    cPath.addArc(
      Rect.fromCircle(center: center, radius: cRadius),
      startAngle,
      endAngle,
    );

    // Create the inner arc to complete the C shape
    final innerRadius = cRadius - strokeWidth;
    cPath.addArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      endAngle,
    );

    // Close the path to create a proper C shape
    cPath.close();

    // Create gradient for the C
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFFF6B6B), // Red
          const Color(0xFF9B59B6), // Purple
          const Color(0xFF3498DB), // Blue
          const Color(0xFFF39C12), // Orange
          const Color(0xFFFF6B6B), // Red (to complete the circle)
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: cRadius));

    canvas.drawPath(cPath, gradientPaint);

    // Add inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final highlightPath = Path();
    highlightPath.addArc(
      Rect.fromCircle(center: center, radius: cRadius - strokeWidth / 2),
      startAngle + 0.1,
      endAngle - 0.2,
    );

    canvas.drawPath(highlightPath, highlightPaint);

    // Add outer glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final glowPath = Path();
    glowPath.addArc(
      Rect.fromCircle(center: center, radius: cRadius + 2),
      startAngle,
      endAngle,
    );

    canvas.drawPath(glowPath, glowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
