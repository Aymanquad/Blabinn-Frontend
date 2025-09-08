import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme_extensions.dart';

/// A custom bottom navigation bar with a capsule indicator for the active tab
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  final EdgeInsets? padding;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        boxShadow: tokens?.softShadows ?? [],
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _buildNavItem(
                context,
                index,
                tokens,
                theme,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    AppThemeTokens? tokens,
    ThemeData theme,
  ) {
    final isSelected = index == currentIndex;
    final item = items[index];
    
    return Semantics(
      label: '${item.label}${isSelected ? ' (selected)' : ''}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? tokens?.primaryGradient : null,
          borderRadius: BorderRadius.circular(
            tokens?.radiusLarge ?? 20,
          ),
          boxShadow: isSelected ? tokens?.softShadows : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle both IconData and Widget icons
            if (item.icon is IconData)
              Icon(
                item.icon as IconData,
                color: isSelected
                    ? Colors.white
                    : unselectedItemColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              )
            else if (item.icon is Widget)
              SizedBox(
                width: 24,
                height: 24,
                child: item.icon as Widget,
              ),
            const SizedBox(height: 4),
            Text(
              item.label ?? '',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : unselectedItemColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// A bottom navigation bar that wraps the custom implementation
/// for easy integration with existing code
class ModernBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  final EdgeInsets? padding;

  const ModernBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      elevation: elevation,
      padding: padding,
    );
  }
}
