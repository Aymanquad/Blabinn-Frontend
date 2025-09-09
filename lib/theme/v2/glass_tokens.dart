import 'package:flutter/material.dart';

class GlassTokens extends ThemeExtension<GlassTokens> {
  final double blurSigma;
  final LinearGradient glassGradient;
  final LinearGradient headerGradient;
  final Color glassTint;
  final Color borderColor;
  final double borderWidth;
  final double radiusLg;
  final double radiusHeader;
  final BoxShadow shadow1;
  final BoxShadow shadow2;
  final Color activeIconGlow;

  const GlassTokens({
    required this.blurSigma,
    required this.glassGradient,
    required this.headerGradient,
    required this.glassTint,
    required this.borderColor,
    required this.borderWidth,
    required this.radiusLg,
    required this.radiusHeader,
    required this.shadow1,
    required this.shadow2,
    required this.activeIconGlow,
  });

  static GlassTokens forScheme(ColorScheme scheme) {
    // Subtle top-to-bottom gradient with a faint tint for dark surfaces.
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(0.08),
        Colors.white.withOpacity(0.04),
      ],
    );
    final headerGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(0.10),
        Colors.white.withOpacity(0.03),
      ],
    );

    return GlassTokens(
      blurSigma: 18.0,
      glassGradient: gradient,
      headerGradient: headerGrad,
      glassTint: Colors.white.withOpacity(0.06),
      borderColor: Colors.white.withOpacity(0.25),
      borderWidth: 1.0,
      radiusLg: 28.0,
      radiusHeader: 20.0,
      shadow1: BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      shadow2: BoxShadow(
        color: Colors.black.withOpacity(0.35),
        blurRadius: 48,
        offset: const Offset(0, 24),
      ),
      activeIconGlow: Colors.white.withOpacity(0.25),
    );
  }

  @override
  GlassTokens copyWith({
    double? blurSigma,
    LinearGradient? glassGradient,
    LinearGradient? headerGradient,
    Color? glassTint,
    Color? borderColor,
    double? borderWidth,
    double? radiusLg,
    double? radiusHeader,
    BoxShadow? shadow1,
    BoxShadow? shadow2,
    Color? activeIconGlow,
  }) {
    return GlassTokens(
      blurSigma: blurSigma ?? this.blurSigma,
      glassGradient: glassGradient ?? this.glassGradient,
      headerGradient: headerGradient ?? this.headerGradient,
      glassTint: glassTint ?? this.glassTint,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusHeader: radiusHeader ?? this.radiusHeader,
      shadow1: shadow1 ?? this.shadow1,
      shadow2: shadow2 ?? this.shadow2,
      activeIconGlow: activeIconGlow ?? this.activeIconGlow,
    );
  }

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) return this;
    return GlassTokens(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      glassGradient: LinearGradient(
        begin: glassGradient.begin,
        end: glassGradient.end,
        colors: List<Color>.generate(glassGradient.colors.length, (i) {
          final a = glassGradient.colors[i];
          final b = other.glassGradient.colors[i];
          return Color.lerp(a, b, t)!;
        }),
      ),
      headerGradient: LinearGradient(
        begin: headerGradient.begin,
        end: headerGradient.end,
        colors: List<Color>.generate(headerGradient.colors.length, (i) {
          final a = headerGradient.colors[i];
          final b = other.headerGradient.colors[i];
          return Color.lerp(a, b, t)!;
        }),
      ),
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusHeader: lerpDouble(radiusHeader, other.radiusHeader, t)!,
      shadow1: BoxShadow.lerp(shadow1, other.shadow1, t)!,
      shadow2: BoxShadow.lerp(shadow2, other.shadow2, t)!,
      activeIconGlow: Color.lerp(activeIconGlow, other.activeIconGlow, t)!,
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
