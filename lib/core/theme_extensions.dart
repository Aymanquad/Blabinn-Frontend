import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

/// AppThemeTokens holds design tokens that are not covered by Material ThemeData
/// such as gradients, radii, spacing, and shadows. This enables consistent
/// styling and easy iteration across the app.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final Gradient primaryGradient;
  final Gradient secondaryGradient;
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final EdgeInsets spacingSmall;
  final EdgeInsets spacingMedium;
  final EdgeInsets spacingLarge;
  final List<BoxShadow> softShadows;
  final Color glassTint; // translucent overlay for glass surfaces
  final Color surfaceTint; // subtle tint for elevated surfaces
  final Color overlayTint; // overlay for modals and dialogs
  final List<BoxShadow> microShadows; // subtle shadows for small elements
  final List<BoxShadow> macroShadows; // prominent shadows for large elements

  const AppThemeTokens({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.spacingSmall,
    required this.spacingMedium,
    required this.spacingLarge,
    required this.softShadows,
    required this.glassTint,
    required this.surfaceTint,
    required this.overlayTint,
    required this.microShadows,
    required this.macroShadows,
  });

  static AppThemeTokens get instance => AppThemeTokens(
        primaryGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFC4B5FD)], // Vibrant purple gradient
        ),
        secondaryGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)], // Dark to light purple
        ),
        radiusSmall: 12, // More rounded for modern look
        radiusMedium: 20, // Increased for better visual appeal
        radiusLarge: 28, // More prominent rounded corners
        spacingSmall: const EdgeInsets.all(8),
        spacingMedium: const EdgeInsets.all(16),
        spacingLarge: const EdgeInsets.all(24),
        softShadows: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.15), // Purple-tinted shadow
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        glassTint: const Color(0xFF8B5CF6).withOpacity(0.10), // Purple glass tint
        surfaceTint: const Color(0xFF8B5CF6).withOpacity(0.05), // Subtle purple tint
        overlayTint: const Color(0xFF000000).withOpacity(0.50), // Darker overlay
        microShadows: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.10), // Purple micro shadow
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        macroShadows: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.20), // Purple macro shadow
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      );

  @override
  AppThemeTokens copyWith({
    Gradient? primaryGradient,
    Gradient? secondaryGradient,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    EdgeInsets? spacingSmall,
    EdgeInsets? spacingMedium,
    EdgeInsets? spacingLarge,
    List<BoxShadow>? softShadows,
    Color? glassTint,
    Color? surfaceTint,
    Color? overlayTint,
    List<BoxShadow>? microShadows,
    List<BoxShadow>? macroShadows,
  }) {
    return AppThemeTokens(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      spacingSmall: spacingSmall ?? this.spacingSmall,
      spacingMedium: spacingMedium ?? this.spacingMedium,
      spacingLarge: spacingLarge ?? this.spacingLarge,
      softShadows: softShadows ?? this.softShadows,
      glassTint: glassTint ?? this.glassTint,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      overlayTint: overlayTint ?? this.overlayTint,
      microShadows: microShadows ?? this.microShadows,
      macroShadows: macroShadows ?? this.macroShadows,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      primaryGradient: Gradient.lerp(primaryGradient, other.primaryGradient, t)!
          as Gradient,
      secondaryGradient:
          Gradient.lerp(secondaryGradient, other.secondaryGradient, t)!
              as Gradient,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
      spacingSmall: EdgeInsets.lerp(spacingSmall, other.spacingSmall, t)!,
      spacingMedium: EdgeInsets.lerp(spacingMedium, other.spacingMedium, t)!,
      spacingLarge: EdgeInsets.lerp(spacingLarge, other.spacingLarge, t)!,
      softShadows: other.softShadows, // keep target set
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      overlayTint: Color.lerp(overlayTint, other.overlayTint, t)!,
      microShadows: other.microShadows, // keep target set
      macroShadows: other.macroShadows, // keep target set
    );
  }
}

