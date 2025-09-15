import 'package:flutter/material.dart';
import '../tokens.dart';

/// V1 Theme Colors - Enhanced dark theme with vibrant purple palette
class V1Colors {
  // Primary palette - Vibrant purple theme
  static const Color primary = Color(0xFF8B5CF6); // More vibrant purple
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF5B21B6); // Darker purple for containers
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // Secondary palette - Light purple accent
  static const Color secondary = Color(0xFFC4B5FD); // Light purple for accents
  static const Color onSecondary = Color(0xFF1E1B4B); // Dark text on light purple
  static const Color secondaryContainer = Color(0xFF7C3AED); // Medium purple
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);

  // Surface colors - Enhanced dark backgrounds
  static const Color surface = Color(0xFF0F172A); // Very dark blue-gray
  static const Color onSurface = Color(0xFFF8FAFC); // Almost white text
  static const Color surfaceVariant = Color(0xFF1E293B); // Slightly lighter surface
  static const Color onSurfaceVariant = Color(0xFF94A3B8); // Better contrast gray

  // Additional surfaces
  static const Color surfaceContainer = Color(0xFF334155); // Better contrast
  static const Color surfaceContainerHigh = Color(0xFF475569); // Lighter variant

  // Status colors - Modern vibrant colors
  static const Color success = Color(0xFF10B981); // Vibrant green
  static const Color warning = Color(0xFFF59E0B); // Vibrant amber
  static const Color error = Color(0xFFEF4444); // Vibrant red

  // Accent color - Purple accent
  static const Color accent = Color(0xFFA855F7); // Purple accent

  // Text colors - Better contrast
  static const Color textPrimary = Color(0xFFF8FAFC); // Almost white
  static const Color textSecondary = Color(0xFF94A3B8); // Better gray
  static const Color textMuted = Color(0xFF64748B); // Muted gray

  // Chat specific colors
  static const Color chatSent = primary;
  static const Color chatReceived = Color(0xFF334155); // Better contrast
  static const Color chatSentText = Color(0xFFFFFFFF);
  static const Color chatReceivedText = textPrimary;

  // Status indicator colors
  static const Color online = Color(0xFF10B981); // Vibrant green
  static const Color offline = Color(0xFF64748B); // Better gray
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

