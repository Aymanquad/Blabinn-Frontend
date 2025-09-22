import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class ModernGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationBarItem> items;
  static const double _navHeight = 76.0; // Optimized for better proportions
  static const double _selectorSize = 44.0; // Better visual balance
  static const double _iconSize = 26.0; // Slightly larger for better visibility

  const ModernGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final slotWidth = (MediaQuery.of(context).size.width - 40) / items.length;

    return Container(
      height: _navHeight,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Base glass effect
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withAlpha(51),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // 1. Sliding selector (background layer)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: currentIndex * slotWidth + (slotWidth - _selectorSize) / 2,
            top: (_navHeight - _selectorSize) / 2,
            child: IgnorePointer(
              child: Container(
                width: _selectorSize,
                height: _selectorSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1E55),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Icons row (foreground layer)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              items.length,
              (index) => Expanded(
                child: Center(
                  child: _NavItemAnimated(
                    selected: currentIndex == index,
                    icon: items[index].icon,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap(index);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemAnimated extends StatefulWidget {
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _NavItemAnimated({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_NavItemAnimated> createState() => _NavItemAnimatedState();
}

class _NavItemAnimatedState extends State<_NavItemAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_NavItemAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? Colors.white : Colors.white.withAlpha(140);

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final double scale = widget.selected ? _scale.value : 1.0;
            final double dy = widget.selected ? -1.0 : 0.0;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: Center(
            child: Icon(
              widget.icon,
              size: ModernGlassNavBar._iconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationBarItem {
  final IconData icon;
  final String label;

  const NavigationBarItem({
    required this.icon,
    required this.label,
  });
}
