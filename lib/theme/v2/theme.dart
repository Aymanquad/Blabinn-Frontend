import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens.dart';
import 'colors.dart';
import 'glass_tokens.dart';
import 'heading_tokens.dart';

/// V2 "Neon Night" Theme Builder - Dramatic Magenta/Cyan/Lime design system
class V2Theme {
  /// Light theme for V2
  static ThemeData get lightTheme => _buildTheme(
        colorScheme: v2LightColorScheme,
        brandColors: v2LightBrandColors,
        isDark: false,
      );

  /// Dark theme for V2
  static ThemeData get darkTheme => _buildTheme(
        colorScheme: v2DarkColorScheme,
        brandColors: v2DarkBrandColors,
        isDark: true,
      );

  /// Base theme builder with comprehensive component theming
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required BrandColors brandColors,
    required bool isDark,
  }) {
    final glass = GlassTokens.forScheme(colorScheme);
    final headings = HeadingTokens.defaults();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,

      // Typography with enhanced readability
      textTheme: _buildTextTheme(colorScheme),

      // AppBar theme - Neon night styling
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: BrandTokens.fontWeightSemiBold,
          color: colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        // Optional gradient overlay for selected tabs
        systemOverlayStyle: isDark
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
      ),

      // Button themes - Neon styling with focus rings
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          padding: EdgeInsets.symmetric(
            horizontal: BrandTokens.spaceXl,
            vertical: BrandTokens.spaceLg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: v2BrandRadii.md,
          ),
          elevation: BrandTokens.elevationMd,
          shadowColor: colorScheme.primary.withOpacity(0.4),
          textStyle: TextStyle(
            fontSize: BrandTokens.fontSizeLg,
            fontWeight: BrandTokens.fontWeightSemiBold,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return colorScheme.onPrimary.withOpacity(0.08);
            }
            if (states.contains(MaterialState.focused)) {
              return colorScheme.secondary.withOpacity(0.12); // Cyan focus ring
            }
            if (states.contains(MaterialState.pressed)) {
              return colorScheme.onPrimary.withOpacity(0.14);
            }
            return null;
          }),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          padding: EdgeInsets.symmetric(
            horizontal: BrandTokens.spaceXl,
            vertical: BrandTokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: v2BrandRadii.md,
          ),
          elevation: BrandTokens.elevationSm,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          textStyle: TextStyle(
            fontSize: BrandTokens.fontSizeMd,
            fontWeight: BrandTokens.fontWeightSemiBold,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.focused)) {
              return colorScheme.secondary.withOpacity(0.12); // Cyan focus ring
            }
            if (states.contains(MaterialState.pressed)) {
              return colorScheme.onPrimary.withOpacity(0.14);
            }
            return null;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          padding: EdgeInsets.symmetric(
            horizontal: BrandTokens.spaceXl,
            vertical: BrandTokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: v2BrandRadii.md,
          ),
          textStyle: TextStyle(
            fontSize: BrandTokens.fontSizeMd,
            fontWeight: BrandTokens.fontWeightSemiBold,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          side: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.focused)) {
              return BorderSide(
                color: colorScheme.secondary, // Cyan focus
                width: 2.0,
              );
            }
            if (states.contains(MaterialState.pressed)) {
              return BorderSide(
                color: colorScheme.primary,
                width: 2.0,
              );
            }
            if (states.contains(MaterialState.disabled)) {
              return BorderSide(
                color: colorScheme.onSurface.withOpacity(0.12),
                width: 1.5,
              );
            }
            return BorderSide(
              color: colorScheme.outline,
              width: 1.5,
            );
          }),
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return colorScheme.primary.withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
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

      // Card theme - subtle glass
      cardTheme: CardThemeData(
        color: colorScheme.surface.withOpacity(0.85),
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: BrandTokens.elevationSm,
        shadowColor: glass.shadow1.color,
        shape: RoundedRectangleBorder(
          borderRadius: v2BrandRadii.md,
          side: BorderSide(color: glass.borderColor, width: glass.borderWidth),
        ),
        margin: v2BrandSpacing.md,
      ),

      // Input decoration theme - Neon focused borders
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: v2BrandRadii.md,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: v2BrandRadii.md,
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: v2BrandRadii.md,
          borderSide: BorderSide(
            color: colorScheme.primary, // Magenta focus
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: v2BrandRadii.md,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: v2BrandRadii.md,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2.0,
          ),
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
          color: colorScheme.onSurface.withOpacity(0.6), // 60% opacity
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightRegular,
        ),
        errorStyle: TextStyle(
          color: colorScheme.error,
          fontSize: BrandTokens.fontSizeSm,
        ),
      ),

      // Chip theme - Pills with Cyan selection
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.secondary, // Cyan selection
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        deleteIconColor: colorScheme.onSurfaceVariant,
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightMedium,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onSecondary, // High contrast on Cyan
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Pill shape
        ),
        padding: EdgeInsets.symmetric(
          horizontal: BrandTokens.spaceMd,
          vertical: BrandTokens.spaceSm,
        ),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.5),
          width: 0.5,
        ),
      ),

      // SnackBar theme - Dark surface with colored stripe
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? colorScheme.surface : colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: isDark ? colorScheme.onSurface : colorScheme.onInverseSurface,
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightRegular,
        ),
        actionTextColor: colorScheme.secondary, // Cyan actions
        shape: RoundedRectangleBorder(
          borderRadius: v2BrandRadii.md,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: BrandTokens.elevationMd,
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: v2BrandRadii.md,
          boxShadow: v2BrandShadows.level2,
        ),
        textStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: BrandTokens.fontSizeSm,
          fontWeight: BrandTokens.fontWeightMedium,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: BrandTokens.spaceMd,
          vertical: BrandTokens.spaceSm,
        ),
      ),

      // Bottom navigation theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary, // Magenta selection
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: BrandTokens.elevationLg,
        selectedLabelStyle: TextStyle(
          fontSize: BrandTokens.fontSizeSm,
          fontWeight: BrandTokens.fontWeightSemiBold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: BrandTokens.fontSizeSm,
          fontWeight: BrandTokens.fontWeightMedium,
        ),
      ),

      // Navigation drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: BrandTokens.elevationXl,
        shape: const RoundedRectangleBorder(),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surface,
        selectedTileColor: colorScheme.primaryContainer,
        iconColor: colorScheme.onSurfaceVariant,
        selectedColor: colorScheme.onPrimaryContainer,
        textColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: BrandTokens.fontSizeLg,
          fontWeight: BrandTokens.fontWeightMedium,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightRegular,
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: BrandTokens.spaceLg,
          vertical: BrandTokens.spaceSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: v2BrandRadii.sm,
        ),
      ),

      // Dialog theme - subtle glass
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.88),
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: BrandTokens.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: v2BrandRadii.lg,
          side: BorderSide(color: glass.borderColor, width: glass.borderWidth),
        ),
        titleTextStyle: TextStyle(
          fontSize: BrandTokens.fontSizeXl,
          fontWeight: BrandTokens.fontWeightSemiBold,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: BrandTokens.fontSizeMd,
          fontWeight: BrandTokens.fontWeightRegular,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Bottom sheet theme - subtle glass
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: BrandTokens.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          side: BorderSide(color: glass.borderColor, width: glass.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Theme extensions
      extensions: <ThemeExtension<dynamic>>[
        brandColors,
        v2BrandSpacing,
        v2BrandRadii,
        v2BrandShadows,
        BackgroundTokensExtension.dark.copyWith(
          useBaseImage: false, // remove PNG for V2, keep glow layers
        ),
        glass,
        headings,
        V2BackgroundTokensExtension.dark, // Add V2 background tokens
      ],
    );
  }

  /// Build text theme with proper contrast ratios for neon theme
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: BrandTokens.fontSizeHero,
        fontWeight: BrandTokens.fontWeightBold,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: BrandTokens.fontWeightBold,
        color: colorScheme.onSurface,
        letterSpacing: -0.25,
        height: 1.3,
      ),
      displaySmall: TextStyle(
        fontSize: BrandTokens.fontSizeDisplay,
        fontWeight: BrandTokens.fontWeightBold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
        height: 1.3,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: BrandTokens.fontSizeXxl,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        fontSize: BrandTokens.fontSizeXl,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontSize: BrandTokens.fontSizeLg,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: BrandTokens.fontSizeXxl,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: BrandTokens.fontSizeXl,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: BrandTokens.fontSizeLg,
        fontWeight: BrandTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Body styles - Enhanced for better readability
      bodyLarge: TextStyle(
        fontSize: BrandTokens.fontSizeLg,
        fontWeight: BrandTokens
            .fontWeightMedium, // Increased weight for better readability
        color: colorScheme.onSurface,
        letterSpacing: 0.3, // Reduced for better spacing
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: BrandTokens.fontSizeMd,
        fontWeight: BrandTokens
            .fontWeightMedium, // Increased weight for better readability
        color: colorScheme.onSurface,
        letterSpacing: 0.2, // Reduced for better spacing
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: BrandTokens.fontSizeSm,
        fontWeight: BrandTokens
            .fontWeightMedium, // Increased weight for better readability
        color: colorScheme
            .onSurface, // Changed from onSurfaceVariant for better contrast
        letterSpacing: 0.3, // Reduced for better spacing
        height: 1.4,
      ),

      // Label styles - Enhanced for better readability
      labelLarge: TextStyle(
        fontSize: BrandTokens.fontSizeMd,
        fontWeight: BrandTokens.fontWeightSemiBold, // Increased weight
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: BrandTokens.fontSizeSm,
        fontWeight: BrandTokens.fontWeightSemiBold, // Increased weight
        color: colorScheme
            .onSurface, // Changed from onSurfaceVariant for better contrast
        letterSpacing: 0.3, // Reduced for better spacing
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: BrandTokens.fontSizeXs,
        fontWeight: BrandTokens.fontWeightSemiBold, // Increased weight
        color: colorScheme
            .onSurface, // Changed from onSurfaceVariant for better contrast
        letterSpacing: 0.3, // Reduced for better spacing
        height: 1.3,
      ),
    );
  }
}
