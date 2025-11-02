import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/v2/glass_tokens.dart';

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final g = Theme.of(context).extension<GlassTokens>() ??
        GlassTokens.forScheme(scheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(g.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: g.blurSigma, sigmaY: g.blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: g.glassGradient,
              color: g.glassTint,
              border: Border.all(color: g.borderColor, width: g.borderWidth),
              boxShadow: [g.shadow1, g.shadow2],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (i) {
                    final item = items[i];
                    final selected = i == currentIndex;
                    return _GlassNavItem(
                      icon: item.icon,
                      activeIcon: item.activeIcon ?? item.icon,
                      label: item.label ?? '',
                      selected: selected,
                      onTap: () => onTap(i),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatefulWidget {
  final Widget icon;
  final Widget activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_GlassNavItem> createState() => _GlassNavItemState();
}

class _GlassNavItemState extends State<_GlassNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final g = Theme.of(context).extension<GlassTokens>() ??
        GlassTokens.forScheme(scheme);

    final iconColor = widget.selected
        ? scheme.primary
        : scheme.onSurface.withOpacity(0.75);
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: widget.selected
              ? scheme.onSurface
              : scheme.onSurface.withOpacity(0.7),
          fontWeight:
              widget.selected ? FontWeight.w700 : FontWeight.w600,
        );

    return Expanded(
      child: Semantics(
        selected: widget.selected,
        button: true,
        label: widget.label,
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapCancel: () => _controller.reverse(),
          onTapUp: (_) => _controller.reverse(),
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: widget.selected ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 140),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft radial highlight under active icon
                  if (widget.selected)
                    Positioned(
                      top: 6,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              g.activeIconGlow,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconTheme(
                        data: IconThemeData(color: iconColor, size: 24),
                        child: widget.selected
                            ? widget.activeIcon
                            : widget.icon,
                      ),
                      const SizedBox(height: 6),
                      Text(widget.label, style: labelStyle),
                    ],
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

