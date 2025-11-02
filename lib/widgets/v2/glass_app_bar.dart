import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/v2/glass_tokens.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  const GlassAppBar({super.key, this.leading, this.actions, this.padding});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final g = Theme.of(context).extension<GlassTokens>() ??
        GlassTokens.forScheme(scheme);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: g.blurSigma, sigmaY: g.blurSigma),
        child: Container(
          padding: padding ?? EdgeInsets.zero,
          decoration: BoxDecoration(
            gradient: g.headerGradient,
            color: g.glassTint,
            border: Border(
              bottom: BorderSide(color: g.borderColor, width: g.borderWidth),
            ),
            boxShadow: [g.shadow1],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center logo with a faint radial highlight
                  Positioned.fill(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.06),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/chatify_logo2-removebg-preview.png',
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Leading on the left
                  Positioned(
                    left: 4,
                    child: leading ?? const SizedBox.shrink(),
                  ),
                  // Actions on the right
                  Positioned(
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions ?? const [],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
