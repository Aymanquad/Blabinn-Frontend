import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/v2/heading_tokens.dart';

class GlassHeadingBar extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final List<Widget>? trailing;
  const GlassHeadingBar({super.key, required this.leading, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<HeadingTokens>() ?? HeadingTokens.defaults();
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.glassRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: t.glassBlurSigma, sigmaY: t.glassBlurSigma),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.glassTint, t.glassTint.withOpacity(0.4)],
            ),
            border: Border.all(color: t.glassBorder, width: t.glassBorderWidth),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.8),
                            ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class GradientHeading extends StatelessWidget {
  final String text;
  final bool underline;
  const GradientHeading({super.key, required this.text, this.underline = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<HeadingTokens>() ?? HeadingTokens.defaults();
    final gradient = t.headingGradient;
    final paint = Paint()..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 600, 80));
    final baseStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white, // fallback if foreground not supported
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: baseStyle?.copyWith(foreground: paint),
        ),
        if (underline)
          Container(
            margin: const EdgeInsets.only(top: 6),
            height: 3,
            width: 72,
            decoration: BoxDecoration(
              gradient: t.underlineGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

