import 'package:flutter/material.dart';

/// Design tokens - atomic values used across both v1 and v2 themes
class BrandTokens {
  // Base spacing values
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // Base radius values
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  // Base elevation values
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // Typography scale
  static const double fontSizeXs = 10.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeLg = 16.0;
  static const double fontSizeXl = 18.0;
  static const double fontSizeXxl = 20.0;
  static const double fontSizeDisplay = 24.0;
  static const double fontSizeHero = 32.0;

  // Font weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Opacity values
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // State overlay opacities (Material 3)
  static const double stateHover = 0.08;
  static const double stateFocus = 0.12;
  static const double statePressed = 0.16;
  static const double stateDisabledText = 0.38;
  static const double stateDisabledFill = 0.12;
}

/// Theme extension for brand colors
class BrandColors extends ThemeExtension<BrandColors> {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color success;
  final Color warning;
  final Color error;
  final Color accent;

  const BrandColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.success,
    required this.warning,
    required this.error,
    required this.accent,
  });

  @override
  BrandColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? success,
    Color? warning,
    Color? error,
    Color? accent,
  }) {
    return BrandColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      accent: accent ?? this.accent,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// Theme extension for spacing
class BrandSpacing extends ThemeExtension<BrandSpacing> {
  final EdgeInsets xs;
  final EdgeInsets sm;
  final EdgeInsets md;
  final EdgeInsets lg;
  final EdgeInsets xl;
  final EdgeInsets xxl;

  const BrandSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  @override
  BrandSpacing copyWith({
    EdgeInsets? xs,
    EdgeInsets? sm,
    EdgeInsets? md,
    EdgeInsets? lg,
    EdgeInsets? xl,
    EdgeInsets? xxl,
  }) {
    return BrandSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  BrandSpacing lerp(ThemeExtension<BrandSpacing>? other, double t) {
    if (other is! BrandSpacing) return this;
    return BrandSpacing(
      xs: EdgeInsets.lerp(xs, other.xs, t)!,
      sm: EdgeInsets.lerp(sm, other.sm, t)!,
      md: EdgeInsets.lerp(md, other.md, t)!,
      lg: EdgeInsets.lerp(lg, other.lg, t)!,
      xl: EdgeInsets.lerp(xl, other.xl, t)!,
      xxl: EdgeInsets.lerp(xxl, other.xxl, t)!,
    );
  }
}

/// Theme extension for border radius
class BrandRadii extends ThemeExtension<BrandRadii> {
  final BorderRadius sm;
  final BorderRadius md;
  final BorderRadius lg;
  final BorderRadius xl;

  const BrandRadii({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  @override
  BrandRadii copyWith({
    BorderRadius? sm,
    BorderRadius? md,
    BorderRadius? lg,
    BorderRadius? xl,
  }) {
    return BrandRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  BrandRadii lerp(ThemeExtension<BrandRadii>? other, double t) {
    if (other is! BrandRadii) return this;
    return BrandRadii(
      sm: BorderRadius.lerp(sm, other.sm, t)!,
      md: BorderRadius.lerp(md, other.md, t)!,
      lg: BorderRadius.lerp(lg, other.lg, t)!,
      xl: BorderRadius.lerp(xl, other.xl, t)!,
    );
  }
}

/// Theme extension for shadows
class BrandShadows extends ThemeExtension<BrandShadows> {
  final List<BoxShadow> level1;
  final List<BoxShadow> level2;
  final List<BoxShadow> level3;

  const BrandShadows({
    required this.level1,
    required this.level2,
    required this.level3,
  });

  @override
  BrandShadows copyWith({
    List<BoxShadow>? level1,
    List<BoxShadow>? level2,
    List<BoxShadow>? level3,
  }) {
    return BrandShadows(
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      level3: level3 ?? this.level3,
    );
  }

  @override
  BrandShadows lerp(ThemeExtension<BrandShadows>? other, double t) {
    if (other is! BrandShadows) return this;
    // For shadows, we'll keep the target shadows rather than interpolating
    return t > 0.5 ? other : this;
  }
}

/// Background tokens for the global background system
class BackgroundTokens {
  // Neon color palette
  static const Color neonViolet = Color(0xFF7A3BFF);
  static const Color neonMagenta = Color(0xFFFF2BD3);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color deepBlack = Color(0xFF0B0F15);

  // Glow intensities
  static const double glowIntensityHigh = 0.35;
  static const double glowIntensityMedium = 0.25;
  static const double glowIntensityLow = 0.15;

  // Glow sizes
  static const double glowSizeLarge = 300.0;
  static const double glowSizeMedium = 250.0;
  static const double glowSizeSmall = 200.0;

  // Animation settings
  static const Duration pulseDuration = Duration(seconds: 12);
  static const double pulseMinValue = 0.95;
  static const double pulseMaxValue = 1.0;

  // Noise settings
  static const double noiseOpacity = 0.02;
  static const int noiseParticleCount = 1000;
}

/// Theme extension for background tokens
class BackgroundTokensExtension
    extends ThemeExtension<BackgroundTokensExtension> {
  final Color neonViolet;
  final Color neonMagenta;
  final Color neonCyan;
  final Color deepBlack;
  final double glowIntensityHigh;
  final double glowIntensityMedium;
  final double glowIntensityLow;
  final double glowSizeLarge;
  final double glowSizeMedium;
  final double glowSizeSmall;
  final bool useBaseImage; // whether to draw the base PNG layer

  const BackgroundTokensExtension({
    required this.neonViolet,
    required this.neonMagenta,
    required this.neonCyan,
    required this.deepBlack,
    required this.glowIntensityHigh,
    required this.glowIntensityMedium,
    required this.glowIntensityLow,
    required this.glowSizeLarge,
    required this.glowSizeMedium,
    required this.glowSizeSmall,
    this.useBaseImage = true,
  });

  static const BackgroundTokensExtension light = BackgroundTokensExtension(
    neonViolet: BackgroundTokens.neonViolet,
    neonMagenta: BackgroundTokens.neonMagenta,
    neonCyan: BackgroundTokens.neonCyan,
    deepBlack: BackgroundTokens.deepBlack,
    glowIntensityHigh: BackgroundTokens.glowIntensityHigh,
    glowIntensityMedium: BackgroundTokens.glowIntensityMedium,
    glowIntensityLow: BackgroundTokens.glowIntensityLow,
    glowSizeLarge: BackgroundTokens.glowSizeLarge,
    glowSizeMedium: BackgroundTokens.glowSizeMedium,
    glowSizeSmall: BackgroundTokens.glowSizeSmall,
    useBaseImage: true,
  );

  static const BackgroundTokensExtension dark = BackgroundTokensExtension(
    neonViolet: BackgroundTokens.neonViolet,
    neonMagenta: BackgroundTokens.neonMagenta,
    neonCyan: BackgroundTokens.neonCyan,
    deepBlack: BackgroundTokens.deepBlack,
    glowIntensityHigh: BackgroundTokens.glowIntensityHigh,
    glowIntensityMedium: BackgroundTokens.glowIntensityMedium,
    glowIntensityLow: BackgroundTokens.glowIntensityLow,
    glowSizeLarge: BackgroundTokens.glowSizeLarge,
    glowSizeMedium: BackgroundTokens.glowSizeMedium,
    glowSizeSmall: BackgroundTokens.glowSizeSmall,
    useBaseImage: true,
  );

  @override
  BackgroundTokensExtension copyWith({
    Color? neonViolet,
    Color? neonMagenta,
    Color? neonCyan,
    Color? deepBlack,
    double? glowIntensityHigh,
    double? glowIntensityMedium,
    double? glowIntensityLow,
    double? glowSizeLarge,
    double? glowSizeMedium,
    double? glowSizeSmall,
    bool? useBaseImage,
  }) {
    return BackgroundTokensExtension(
      neonViolet: neonViolet ?? this.neonViolet,
      neonMagenta: neonMagenta ?? this.neonMagenta,
      neonCyan: neonCyan ?? this.neonCyan,
      deepBlack: deepBlack ?? this.deepBlack,
      glowIntensityHigh: glowIntensityHigh ?? this.glowIntensityHigh,
      glowIntensityMedium: glowIntensityMedium ?? this.glowIntensityMedium,
      glowIntensityLow: glowIntensityLow ?? this.glowIntensityLow,
      glowSizeLarge: glowSizeLarge ?? this.glowSizeLarge,
      glowSizeMedium: glowSizeMedium ?? this.glowSizeMedium,
      glowSizeSmall: glowSizeSmall ?? this.glowSizeSmall,
      useBaseImage: useBaseImage ?? this.useBaseImage,
    );
  }

  @override
  BackgroundTokensExtension lerp(
      ThemeExtension<BackgroundTokensExtension>? other, double t) {
    if (other is! BackgroundTokensExtension) return this;
    return BackgroundTokensExtension(
      neonViolet: Color.lerp(neonViolet, other.neonViolet, t)!,
      neonMagenta: Color.lerp(neonMagenta, other.neonMagenta, t)!,
      neonCyan: Color.lerp(neonCyan, other.neonCyan, t)!,
      deepBlack: Color.lerp(deepBlack, other.deepBlack, t)!,
      glowIntensityHigh:
          glowIntensityHigh + (other.glowIntensityHigh - glowIntensityHigh) * t,
      glowIntensityMedium: glowIntensityMedium +
          (other.glowIntensityMedium - glowIntensityMedium) * t,
      glowIntensityLow:
          glowIntensityLow + (other.glowIntensityLow - glowIntensityLow) * t,
      glowSizeLarge: glowSizeLarge + (other.glowSizeLarge - glowSizeLarge) * t,
      glowSizeMedium:
          glowSizeMedium + (other.glowSizeMedium - glowSizeMedium) * t,
      glowSizeSmall: glowSizeSmall + (other.glowSizeSmall - glowSizeSmall) * t,
      useBaseImage: t < 0.5 ? useBaseImage : other.useBaseImage,
    );
  }
}

/// V2 Background Tokens - Purple→Black subtle gradients
class V2BackgroundTokens {
  // Core purple colors for V2 background
  static const Color v2PurpleCore = Color(0xFF3C1E75);
  static const Color v2PurpleMid = Color(0xFF5A2EA6);
  static const Color v2DeepBlack = Color(0xFF0B0F15);

  // Overlay opacity levels (subtle, no neon)
  static const double overlayOpacityHigh = 0.5; // 50% alpha
  static const double overlayOpacityMedium = 0.37; // 37% alpha
  static const double overlayOpacityLow = 0.25; // 25% alpha
  static const double overlayOpacityMinimal = 0.19; // 19% alpha

  // Vignette opacity
  static const double vignetteOpacity = 0.08;

  // Radial overlay sizes (as fractions of screen width)
  static const double overlaySizeLarge = 0.8;
  static const double overlaySizeMedium = 0.6;
  static const double overlaySizeSmall = 0.4;
}

/// Theme extension for V2 background tokens
class V2BackgroundTokensExtension
    extends ThemeExtension<V2BackgroundTokensExtension> {
  final Color purpleCore;
  final Color purpleMid;
  final Color deepBlack;
  final double overlayOpacityHigh;
  final double overlayOpacityMedium;
  final double overlayOpacityLow;
  final double overlayOpacityMinimal;
  final double vignetteOpacity;
  final double overlaySizeLarge;
  final double overlaySizeMedium;
  final double overlaySizeSmall;

  const V2BackgroundTokensExtension({
    required this.purpleCore,
    required this.purpleMid,
    required this.deepBlack,
    required this.overlayOpacityHigh,
    required this.overlayOpacityMedium,
    required this.overlayOpacityLow,
    required this.overlayOpacityMinimal,
    required this.vignetteOpacity,
    required this.overlaySizeLarge,
    required this.overlaySizeMedium,
    required this.overlaySizeSmall,
  });

  static const V2BackgroundTokensExtension light = V2BackgroundTokensExtension(
    purpleCore: V2BackgroundTokens.v2PurpleCore,
    purpleMid: V2BackgroundTokens.v2PurpleMid,
    deepBlack: V2BackgroundTokens.v2DeepBlack,
    overlayOpacityHigh: V2BackgroundTokens.overlayOpacityHigh,
    overlayOpacityMedium: V2BackgroundTokens.overlayOpacityMedium,
    overlayOpacityLow: V2BackgroundTokens.overlayOpacityLow,
    overlayOpacityMinimal: V2BackgroundTokens.overlayOpacityMinimal,
    vignetteOpacity: V2BackgroundTokens.vignetteOpacity,
    overlaySizeLarge: V2BackgroundTokens.overlaySizeLarge,
    overlaySizeMedium: V2BackgroundTokens.overlaySizeMedium,
    overlaySizeSmall: V2BackgroundTokens.overlaySizeSmall,
  );

  static const V2BackgroundTokensExtension dark = V2BackgroundTokensExtension(
    purpleCore: V2BackgroundTokens.v2PurpleCore,
    purpleMid: V2BackgroundTokens.v2PurpleMid,
    deepBlack: V2BackgroundTokens.v2DeepBlack,
    overlayOpacityHigh: V2BackgroundTokens.overlayOpacityHigh,
    overlayOpacityMedium: V2BackgroundTokens.overlayOpacityMedium,
    overlayOpacityLow: V2BackgroundTokens.overlayOpacityLow,
    overlayOpacityMinimal: V2BackgroundTokens.overlayOpacityMinimal,
    vignetteOpacity: V2BackgroundTokens.vignetteOpacity,
    overlaySizeLarge: V2BackgroundTokens.overlaySizeLarge,
    overlaySizeMedium: V2BackgroundTokens.overlaySizeMedium,
    overlaySizeSmall: V2BackgroundTokens.overlaySizeSmall,
  );

  @override
  V2BackgroundTokensExtension copyWith({
    Color? purpleCore,
    Color? purpleMid,
    Color? deepBlack,
    double? overlayOpacityHigh,
    double? overlayOpacityMedium,
    double? overlayOpacityLow,
    double? overlayOpacityMinimal,
    double? vignetteOpacity,
    double? overlaySizeLarge,
    double? overlaySizeMedium,
    double? overlaySizeSmall,
  }) {
    return V2BackgroundTokensExtension(
      purpleCore: purpleCore ?? this.purpleCore,
      purpleMid: purpleMid ?? this.purpleMid,
      deepBlack: deepBlack ?? this.deepBlack,
      overlayOpacityHigh: overlayOpacityHigh ?? this.overlayOpacityHigh,
      overlayOpacityMedium: overlayOpacityMedium ?? this.overlayOpacityMedium,
      overlayOpacityLow: overlayOpacityLow ?? this.overlayOpacityLow,
      overlayOpacityMinimal:
          overlayOpacityMinimal ?? this.overlayOpacityMinimal,
      vignetteOpacity: vignetteOpacity ?? this.vignetteOpacity,
      overlaySizeLarge: overlaySizeLarge ?? this.overlaySizeLarge,
      overlaySizeMedium: overlaySizeMedium ?? this.overlaySizeMedium,
      overlaySizeSmall: overlaySizeSmall ?? this.overlaySizeSmall,
    );
  }

  @override
  V2BackgroundTokensExtension lerp(
      ThemeExtension<V2BackgroundTokensExtension>? other, double t) {
    if (other is! V2BackgroundTokensExtension) return this;
    return V2BackgroundTokensExtension(
      purpleCore: Color.lerp(purpleCore, other.purpleCore, t)!,
      purpleMid: Color.lerp(purpleMid, other.purpleMid, t)!,
      deepBlack: Color.lerp(deepBlack, other.deepBlack, t)!,
      overlayOpacityHigh: overlayOpacityHigh +
          (other.overlayOpacityHigh - overlayOpacityHigh) * t,
      overlayOpacityMedium: overlayOpacityMedium +
          (other.overlayOpacityMedium - overlayOpacityMedium) * t,
      overlayOpacityLow:
          overlayOpacityLow + (other.overlayOpacityLow - overlayOpacityLow) * t,
      overlayOpacityMinimal: overlayOpacityMinimal +
          (other.overlayOpacityMinimal - overlayOpacityMinimal) * t,
      vignetteOpacity:
          vignetteOpacity + (other.vignetteOpacity - vignetteOpacity) * t,
      overlaySizeLarge:
          overlaySizeLarge + (other.overlaySizeLarge - overlaySizeLarge) * t,
      overlaySizeMedium:
          overlaySizeMedium + (other.overlaySizeMedium - overlaySizeMedium) * t,
      overlaySizeSmall:
          overlaySizeSmall + (other.overlaySizeSmall - overlaySizeSmall) * t,
    );
  }
}

/// App Gradients - V2 Neon Night gradients
class AppGradients {
  // V2 Neon Night gradients
  static const LinearGradient brandPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF2BD3), Color(0xFF00E5FF)], // Magenta to Cyan
  );

  static const LinearGradient accentGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7CFF4F), Color(0xFF00E5FF)], // Lime to Cyan
  );

  // Chat bubble glow for V2
  static const LinearGradient chatBubbleGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF2BD3), Color(0xFFE122B8)], // Magenta gradient
  );

  // V1 Legacy gradients (kept for compatibility)
  static const LinearGradient v1BrandPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF14B8A6)], // Indigo to Teal
  );

  static const LinearGradient v1AccentGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)], // Amber 400 to 600
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)], // Subtle surface gradient
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B0F15), Color(0xFF131A24)], // V2 Dark surface gradient
  );
}
