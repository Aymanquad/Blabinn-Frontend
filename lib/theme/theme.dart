import 'package:flutter/material.dart';
import 'tokens.dart';
import 'v1/colors.dart';
import 'v2/theme.dart' as v2_theme;

enum ThemeVersion { v1, v2 }

/// Main theme factory that creates Material 3 ThemeData for both v1 and v2
class AppTheme {
  static ThemeData light(ThemeVersion version) {
    switch (version) {
      case ThemeVersion.v1:
        return _buildV1LightTheme();
      case ThemeVersion.v2:
        return v2_theme.V2Theme.lightTheme;
    }
  }

  static ThemeData dark(ThemeVersion version) {
    switch (version) {
      case ThemeVersion.v1:
        return _buildV1DarkTheme();
      case ThemeVersion.v2:
        return v2_theme.V2Theme.darkTheme;
    }
  }

  // V2 Theme getters for direct access
  static ThemeData get lightThemeV2 => v2_theme.V2Theme.lightTheme;
  static ThemeData get darkThemeV2 => v2_theme.V2Theme.darkTheme;

  /// V1 Dark Theme (Current design)
  static ThemeData _buildV1DarkTheme() {
    const colorScheme = ColorScheme.dark(
      primary: V1Colors.primary,
      onPrimary: V1Colors.onPrimary,
      primaryContainer: V1Colors.primaryContainer,
      onPrimaryContainer: V1Colors.onPrimaryContainer,
      secondary: V1Colors.secondary,
      onSecondary: V1Colors.onSecondary,
      secondaryContainer: V1Colors.secondaryContainer,
      onSecondaryContainer: V1Colors.onSecondaryContainer,
      surface: V1Colors.surface,
      onSurface: V1Colors.onSurface,
      surfaceVariant: V1Colors.surfaceVariant,
      onSurfaceVariant: V1Colors.onSurfaceVariant,
      error: V1Colors.error,
      background: V1Colors.surface,
      onBackground: V1Colors.onSurface,
    );

    return _buildBaseTheme(colorScheme, v1BrandColors, v1BrandSpacing,
        v1BrandRadii, v1BrandShadows);
  }

  /// V1 Light Theme (Lighter version of current design)
  static ThemeData _buildV1LightTheme() {
    const colorScheme = ColorScheme.light(
      primary: V1Colors.primary,
      onPrimary: V1Colors.onPrimary,
      primaryContainer: Color(0xFFE8D5FF),
      onPrimaryContainer: Color(0xFF4A0E4E),
      secondary: V1Colors.secondary,
      onSecondary: Color(0xFF003D3A),
      secondaryContainer: Color(0xFFB2DFDB),
      onSecondaryContainer: Color(0xFF00201E),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A1A),
      surfaceVariant: Color(0xFFF5F5F5),
      onSurfaceVariant: Color(0xFF424242),
      error: V1Colors.error,
      background: Color(0xFFFAFAFA),
      onBackground: Color(0xFF1A1A1A),
    );

    return _buildBaseTheme(
        colorScheme,
        v1BrandColors.copyWith(
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF1A1A1A),
          surfaceVariant: const Color(0xFFF5F5F5),
        ),
        v1BrandSpacing,
        v1BrandRadii,
        v1BrandShadows);
  }

  /// Base theme builder with component themes
  static ThemeData _buildBaseTheme(
    ColorScheme colorScheme,
    BrandColors brandColors,
    BrandSpacing brandSpacing,
    BrandRadii brandRadii,
    BrandShadows brandShadows,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,

      // Text theme
      textTheme: _buildTextTheme(colorScheme),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: BrandTokens.fontSizeXxl,
          fontWeight: BrandTokens.fontWeightSemiBold,
          color: colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: BrandTokens.spaceXl,
            vertical: BrandTokens.spaceLg,
          ),
          shape: RoundedRectangleBorder(borderRadius: brandRadii.md),
          elevation: BrandTokens.elevationMd,
          textStyle: TextStyle(
            fontSize: BrandTokens.fontSizeLg,
            fontWeight: BrandTokens.fontWeightSemiBold,
            letterSpacing: 0.1,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: EdgeInsets.symmetric(
            horizontal: BrandTokens.spaceXl,
            vertical: BrandTokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(borderRadius: brandRadii.sm),
          elevation: BrandTokens.elevationSm,
          textStyle: TextStyle(
            fontSize: BrandTokens.fontSizeMd,
            fontWeight: BrandTokens.fontWeightSemiBold,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: BrandTokens.spaceXl,
            vertical: BrandTokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(borderRadius: brandRadii.sm),
          textStyle: TextStyle(
            fontSize: BrandTokens.fontSizeMd,
            fontWeight: BrandTokens.fontWeightSemiBold,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: EdgeInsets.symmetric(
            horizontal: BrandTokens.spaceLg,
            vertical: BrandTokens.spaceMd,
          ),
          textStyle: TextStyle(
            fontSize: BrandTokens.fontSizeMd,
            fontWeight: BrandTokens.fontWeightSemiBold,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: BrandTokens.elevationSm,
        shadowColor: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
        shape: RoundedRectangleBorder(borderRadius: brandRadii.lg),
        margin: brandSpacing.md,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: brandRadii.md,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: brandRadii.md,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: brandRadii.md,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: BrandTokens.spaceLg,
          vertical: BrandTokens.spaceLg,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightMedium,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightRegular,
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: brandRadii.xl),
        padding: EdgeInsets.symmetric(
          horizontal: BrandTokens.spaceMd,
          vertical: BrandTokens.spaceSm,
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: BrandTokens.fontSizeMd,
        ),
        shape: RoundedRectangleBorder(borderRadius: brandRadii.md),
        behavior: SnackBarBehavior.floating,
      ),

      // Bottom navigation theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: BrandTokens.elevationLg,
      ),

      // Theme extensions
      extensions: <ThemeExtension<dynamic>>[
        brandColors,
        brandSpacing,
        brandRadii,
        brandShadows,
        BackgroundTokensExtension.dark.copyWith(
          useBaseImage: true,
        ),
      ],
    );
  }

  /// Build consistent text theme
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: BrandTokens.fontSizeHero,
        fontWeight: BrandTokens.fontWeightBold,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: BrandTokens.fontWeightBold,
        color: colorScheme.onSurface,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: BrandTokens.fontSizeDisplay,
        fontWeight: BrandTokens.fontWeightBold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: BrandTokens.fontSizeXxl,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: BrandTokens.fontSizeXl,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
      ),
      headlineSmall: TextStyle(
        fontSize: BrandTokens.fontSizeLg,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: BrandTokens.fontSizeXxl,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: BrandTokens.fontSizeXl,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: BrandTokens.fontSizeLg,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontSize: BrandTokens.fontSizeLg,
        fontWeight: BrandTokens.fontWeightRegular,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: BrandTokens.fontSizeMd,
        fontWeight: BrandTokens.fontWeightRegular,
        color: colorScheme.onSurface,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: BrandTokens.fontSizeSm,
        fontWeight: BrandTokens.fontWeightRegular,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: BrandTokens.fontSizeMd,
        fontWeight: BrandTokens.fontWeightMedium,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: BrandTokens.fontSizeSm,
        fontWeight: BrandTokens.fontWeightMedium,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: BrandTokens.fontSizeXs,
        fontWeight: BrandTokens.fontWeightMedium,
        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
        letterSpacing: 0.5,
      ),
    );
  }
}
