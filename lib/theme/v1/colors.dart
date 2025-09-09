import 'package:flutter/material.dart';
import '../tokens.dart';

/// V1 Theme Colors - Current dark theme with purple/teal palette
class V1Colors {
  // Primary palette - Purple theme
  static const Color primary = Color(0xFFA259FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF7B2CBF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // Secondary palette - Teal accent
  static const Color secondary = Color(0xFF4DD4C9);
  static const Color onSecondary = Color(0xFF000000);
  static const Color secondaryContainer = Color(0xFF36A3A0);
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);

  // Surface colors - Dark backgrounds
  static const Color surface = Color(0xFF1E1B2E);
  static const Color onSurface = Color(0xFFFDFCFB);
  static const Color surfaceVariant = Color(0xFF2A2A3E);
  static const Color onSurfaceVariant = Color(0xFFB8B8B8);

  // Additional surfaces
  static const Color surfaceContainer = Color(0xFF3A3A4E);
  static const Color surfaceContainerHigh = Color(0xFF4A4A5E);

  // Status colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);

  // Accent color
  static const Color accent = Color(0xFFFF6F91);

  // Text colors
  static const Color textPrimary = Color(0xFFFDFCFB);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textMuted = Color(0xFF8A8A8A);

  // Chat specific colors
  static const Color chatSent = primary;
  static const Color chatReceived = Color(0xFF4A4A5E);
  static const Color chatSentText = Color(0xFFFFFFFF);
  static const Color chatReceivedText = textPrimary;

  // Status indicator colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
}

/// V1 Brand Colors Extension
BrandColors get v1BrandColors => const BrandColors(
      primary: V1Colors.primary,
      onPrimary: V1Colors.onPrimary,
      secondary: V1Colors.secondary,
      onSecondary: V1Colors.onSecondary,
      surface: V1Colors.surface,
      onSurface: V1Colors.onSurface,
      surfaceVariant: V1Colors.surfaceVariant,
      success: V1Colors.success,
      warning: V1Colors.warning,
      error: V1Colors.error,
      accent: V1Colors.accent,
    );

/// V1 Spacing Extension
BrandSpacing get v1BrandSpacing => const BrandSpacing(
      xs: EdgeInsets.all(BrandTokens.spaceXs),
      sm: EdgeInsets.all(BrandTokens.spaceSm),
      md: EdgeInsets.all(BrandTokens.spaceMd),
      lg: EdgeInsets.all(BrandTokens.spaceLg),
      xl: EdgeInsets.all(BrandTokens.spaceXl),
      xxl: EdgeInsets.all(BrandTokens.spaceXxl),
    );

/// V1 Radii Extension
BrandRadii get v1BrandRadii => const BrandRadii(
      sm: BorderRadius.all(Radius.circular(BrandTokens.radiusSm)),
      md: BorderRadius.all(Radius.circular(BrandTokens.radiusMd)),
      lg: BorderRadius.all(Radius.circular(BrandTokens.radiusLg)),
      xl: BorderRadius.all(Radius.circular(BrandTokens.radiusXl)),
    );

/// V1 Shadows Extension
BrandShadows get v1BrandShadows => BrandShadows(
      level1: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      level2: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      level3: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );

