import 'package:flutter/material.dart';

class HeadingTokens extends ThemeExtension<HeadingTokens> {
  final double glassBlurSigma;
  final Color glassTint;
  final Color glassBorder;
  final double glassBorderWidth;
  final double glassRadius;
  final LinearGradient headingGradient;
  final LinearGradient underlineGradient;

  const HeadingTokens({
    required this.glassBlurSigma,
    required this.glassTint,
    required this.glassBorder,
    required this.glassBorderWidth,
    required this.glassRadius,
    required this.headingGradient,
    required this.underlineGradient,
  });

  factory HeadingTokens.defaults() => HeadingTokens(
        glassBlurSigma: 18.0,
        glassTint: Colors.white.withOpacity(0.06),
        glassBorder: Colors.white.withOpacity(0.22),
        glassBorderWidth: 1.0,
        glassRadius: 16.0,
        headingGradient: const LinearGradient(
          colors: [Color(0xFFB483FF), Color(0xFFE8B3FF)],
        ),
        underlineGradient: const LinearGradient(
          colors: [Color(0xFFB483FF), Color(0xFFE8B3FF)],
        ),
      );

  @override
  HeadingTokens copyWith({
    double? glassBlurSigma,
    Color? glassTint,
    Color? glassBorder,
    double? glassBorderWidth,
    double? glassRadius,
    LinearGradient? headingGradient,
    LinearGradient? underlineGradient,
  }) {
    return HeadingTokens(
      glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
      glassTint: glassTint ?? this.glassTint,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBorderWidth: glassBorderWidth ?? this.glassBorderWidth,
      glassRadius: glassRadius ?? this.glassRadius,
      headingGradient: headingGradient ?? this.headingGradient,
      underlineGradient: underlineGradient ?? this.underlineGradient,
    );
  }

  @override
  HeadingTokens lerp(ThemeExtension<HeadingTokens>? other, double t) {
    if (other is! HeadingTokens) return this;
    return HeadingTokens(
      glassBlurSigma: _lerpDouble(glassBlurSigma, other.glassBlurSigma, t),
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBorderWidth:
          _lerpDouble(glassBorderWidth, other.glassBorderWidth, t),
      glassRadius: _lerpDouble(glassRadius, other.glassRadius, t),
      headingGradient: other.headingGradient,
      underlineGradient: other.underlineGradient,
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

