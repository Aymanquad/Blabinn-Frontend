import 'package:flutter/material.dart';
import '../tokens.dart';
import '../v1/colors.dart';

/// V2 "Neon Night" Theme - Dramatic Magenta/Cyan/Lime palette
class V2Colors {
  // === PRIMARY PALETTE (Magenta) ===
  static const Color primary50 = Color(0xFFFFE7F9);
  static const Color primary100 = Color(0xFFFFCFF3);
  static const Color primary200 = Color(0xFFFFA7E8);
  static const Color primary300 = Color(0xFFFF7CDE);
  static const Color primary400 = Color(0xFFFF55D7);
  static const Color primary500 = Color(0xFFFF2BD3); // Base primary
  static const Color primary600 = Color(0xFFE122B8);
  static const Color primary700 = Color(0xFFB81D97);
  static const Color primary800 = Color(0xFF8F1976);
  static const Color primary900 = Color(0xFF6D145C);

  // === SECONDARY PALETTE (Cyan) ===
  static const Color secondary50 = Color(0xFFE6FCFF);
  static const Color secondary100 = Color(0xFFC8F8FF);
  static const Color secondary200 = Color(0xFF97F1FF);
  static const Color secondary300 = Color(0xFF63E9FF);
  static const Color secondary400 = Color(0xFF34E2FF);
  static const Color secondary500 = Color(0xFF00E5FF); // Base secondary
  static const Color secondary600 = Color(0xFF00C6E0);
  static const Color secondary700 = Color(0xFF00A2BB);
  static const Color secondary800 = Color(0xFF007E95);
  static const Color secondary900 = Color(0xFF005C70);

  // === ACCENT PALETTE (Lime) ===
  static const Color accent400 = Color(0xFF9EFF7F);
  static const Color accent500 = Color(0xFF7CFF4F); // Base accent
  static const Color accent600 = Color(0xFF55E62A);
  static const Color accent700 = Color(0xFF3DBA1D);

  // === SEMANTIC COLORS ===
  static const Color success = Color(0xFF1FE074);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF4D6D);
  static const Color info = Color(0xFF3AB8FF);

  // === DARK MODE SURFACES (Primary design) ===
  static const Color darkBackground = Color(0xFF0B0F15);
  static const Color darkSurface = Color(0xFF0B0F15);
  static const Color darkSurfaceVariant = Color(0xFF131A24);
  static const Color darkOnSurface = Color(0xFFE6F1FF);
  static const Color darkOnSurfaceVariant = Color(0xFFCAD6EA);
  static const Color darkOutline = Color(0xFF2B3A4B);
  static const Color darkOutlineVariant = Color(0xFF1A2530);

  // === LIGHT MODE SURFACES ===
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F6FB);
  static const Color lightOnSurface = Color(0xFF0C1320);
  static const Color lightOnSurfaceVariant = Color(0xFF475569);
  static const Color lightOutline = Color(0xFFCAD6EA);
  static const Color lightOutlineVariant = Color(0xFFE2E8F0);

  // === PRESENCE & STATUS ===
  static const Color presenceOnline = accent500; // Lime
  static const Color presenceOffline = Color(0xFF93A4BE);

  // === GRADIENTS ===
  static const Gradient brandPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, secondary500], // Magenta to Cyan
  );

  static const Gradient accentGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent500, secondary500], // Lime to Cyan
  );

  // Chat bubble glow effect
  static const Gradient chatBubbleGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary600], // Subtle magenta glow
  );
}

/// V2 Light ColorScheme - Neon Night Light Mode
ColorScheme get v2LightColorScheme => const ColorScheme.light(
      // Primary colors (align to V1 purple for buttons/elements)
      primary: V1Colors.primary,
      onPrimary: V1Colors.onPrimary,
      primaryContainer: V1Colors.primaryContainer,
      onPrimaryContainer: V1Colors.onPrimaryContainer,

      // Secondary colors (align to V1 teal)
      secondary: V1Colors.secondary,
      onSecondary: V1Colors.onSecondary,
      secondaryContainer: V1Colors.secondaryContainer,
      onSecondaryContainer: V1Colors.onSecondaryContainer,

      // Tertiary colors (Accent Lime)
      tertiary: V2Colors.accent500,
      onTertiary: Color(0xFF0B1609),
      tertiaryContainer: V2Colors.accent400,
      onTertiaryContainer: Color(0xFF071205),

      // Error colors
      error: V2Colors.error,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFE8EA),
      onErrorContainer: Color(0xFF5C0009),

      // Surface colors (keep V2 surfaces)
      background: V2Colors.lightBackground,
      onBackground: V2Colors.lightOnSurface,
      surface: V2Colors.lightSurface,
      onSurface: V2Colors.lightOnSurface,
      surfaceVariant: V2Colors.lightSurfaceVariant,
      onSurfaceVariant: V2Colors.lightOnSurfaceVariant,

      // Outline colors
      outline: V2Colors.lightOutline,
      outlineVariant: V2Colors.lightOutlineVariant,

      // Inverse colors
      inverseSurface: V2Colors.darkSurface,
      onInverseSurface: V2Colors.darkOnSurface,
      inversePrimary: V2Colors.primary300,

      // Shadow and surface tint
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      surfaceTint: V2Colors.primary500,
    );

/// V2 Dark ColorScheme - Neon Night Dark Mode (Primary design)
ColorScheme get v2DarkColorScheme => const ColorScheme.dark(
      // Primary colors (align to V1 purple)
      primary: V1Colors.primary,
      onPrimary: V1Colors.onPrimary,
      primaryContainer: V1Colors.primaryContainer,
      onPrimaryContainer: V1Colors.onPrimaryContainer,

      // Secondary colors (align to V1 teal)
      secondary: V1Colors.secondary,
      onSecondary: V1Colors.onSecondary,
      secondaryContainer: V1Colors.secondaryContainer,
      onSecondaryContainer: V1Colors.onSecondaryContainer,

      // Tertiary colors (Accent Lime)
      tertiary: V2Colors.accent500,
      onTertiary: Color(0xFF0B1609),
      tertiaryContainer: V2Colors.accent700,
      onTertiaryContainer: V2Colors.accent400,

      // Error colors
      error: V2Colors.error,
      onError: Color(0xFF000000),
      errorContainer: Color(0xFF8C1823),
      onErrorContainer: Color(0xFFFFB3BA),

      // Surface colors
      background: V2Colors.darkBackground,
      onBackground: V2Colors.darkOnSurface,
      surface: V2Colors.darkSurface,
      onSurface: V2Colors.darkOnSurface,
      surfaceVariant: V2Colors.darkSurfaceVariant,
      onSurfaceVariant: V2Colors.darkOnSurfaceVariant,

      // Outline colors
      outline: V2Colors.darkOutline,
      outlineVariant: V2Colors.darkOutlineVariant,

      // Inverse colors
      inverseSurface: V2Colors.lightSurface,
      onInverseSurface: V2Colors.lightOnSurface,
      inversePrimary: V2Colors.primary500,

      // Shadow and surface tint
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      surfaceTint: V2Colors.primary500,
    );

/// V2 Light Brand Colors Extension
BrandColors get v2LightBrandColors => const BrandColors(
      primary: V1Colors.primary,
      onPrimary: V1Colors.onPrimary,
      secondary: V1Colors.secondary,
      onSecondary: V1Colors.onSecondary,
      surface: V2Colors.lightSurface,
      onSurface: V2Colors.lightOnSurface,
      surfaceVariant: V2Colors.lightSurfaceVariant,
      success: V2Colors.success,
      warning: V2Colors.warning,
      error: V2Colors.error,
      accent: V1Colors.accent,
    );

/// V2 Dark Brand Colors Extension
BrandColors get v2DarkBrandColors => const BrandColors(
      primary: V1Colors.primary,
      onPrimary: V1Colors.onPrimary,
      secondary: V1Colors.secondary,
      onSecondary: V1Colors.onSecondary,
      surface: V2Colors.darkSurface,
      onSurface: V2Colors.darkOnSurface,
      surfaceVariant: V2Colors.darkSurfaceVariant,
      success: V2Colors.success,
      warning: V2Colors.warning,
      error: V2Colors.error,
      accent: V1Colors.accent,
    );

/// V2 Spacing Extension
BrandSpacing get v2BrandSpacing => const BrandSpacing(
      xs: EdgeInsets.all(BrandTokens.spaceXs),
      sm: EdgeInsets.all(BrandTokens.spaceSm),
      md: EdgeInsets.all(BrandTokens.spaceMd),
      lg: EdgeInsets.all(BrandTokens.spaceLg),
      xl: EdgeInsets.all(BrandTokens.spaceXl),
      xxl: EdgeInsets.all(BrandTokens.spaceXxl),
    );

/// V2 Radii Extension
BrandRadii get v2BrandRadii => const BrandRadii(
      sm: BorderRadius.all(Radius.circular(BrandTokens.radiusSm)),
      md: BorderRadius.all(Radius.circular(BrandTokens.radiusMd)),
      lg: BorderRadius.all(Radius.circular(BrandTokens.radiusLg)),
      xl: BorderRadius.all(Radius.circular(20.0)),
    );

/// V2 Shadows Extension - Dramatic shadows for neon effect
BrandShadows get v2BrandShadows => BrandShadows(
      level1: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      level2: [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
      level3: [
        BoxShadow(
          color: Colors.black.withOpacity(0.20),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ],
    );
