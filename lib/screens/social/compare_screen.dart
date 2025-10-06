import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/theme.dart';
import '../../theme/extensions.dart';
import '../auth/login_screen.dart';
import '../chat/chat_list_screen.dart';
import '../home/home_screen.dart';

/// Screen that shows side-by-side comparison of V1 vs V2 themes
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  int _selectedScreenIndex = 0;

  final List<ComparisonScreen> _availableScreens = [
    ComparisonScreen(
      name: 'Login',
      icon: Icons.login,
      builder: (context) => const LoginScreen(),
    ),
    ComparisonScreen(
      name: 'Chat List',
      icon: Icons.chat,
      builder: (context) => const ChatListScreen(),
    ),
    ComparisonScreen(
      name: 'Home',
      icon: Icons.home,
      builder: (context) => HomeScreen(onNavigateToTab: (_) {}),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Comparison'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Screen selector
          _buildScreenSelector(),

          // Comparison view
          Expanded(
            child: _buildComparisonView(),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenSelector() {
    return Container(
      padding: context.brandSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Screen to Compare',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableScreens.length,
              itemBuilder: (context, index) {
                final screen = _availableScreens[index];
                final isSelected = index == _selectedScreenIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedScreenIndex = index;
                        });
                      }
                    },
                    avatar: Icon(
                      screen.icon,
                      size: 20,
                      color: isSelected
                          ? context.colorScheme.onPrimary
                          : context.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(screen.name),
                    backgroundColor: isSelected
                        ? context.colorScheme.primary
                        : context.colorScheme.surfaceVariant,
                    selectedColor: context.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? context.colorScheme.onPrimary
                          : context.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView() {
    final selectedScreen = _availableScreens[_selectedScreenIndex];

    return Row(
      children: [
        // V1 Theme (Left side)
        Expanded(
          child: _buildThemePreview(
            title: 'Classic (V1)',
            theme: AppTheme.dark(ThemeVersion.v1),
            child: selectedScreen.builder(context),
          ),
        ),

        // Divider
        Container(
          width: 2,
          color: context.colorScheme.outline.withOpacity(0.3),
        ),

        // V2 Theme (Right side)
        Expanded(
          child: _buildThemePreview(
            title: 'Modern (V2)',
            theme: AppTheme.dark(ThemeVersion.v2),
            child: selectedScreen.builder(context),
          ),
        ),
      ],
    );
  }

  Widget _buildThemePreview({
    required String title,
    required ThemeData theme,
    required Widget child,
  }) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceVariant,
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Preview content
        Expanded(
          child: Theme(
            data: theme,
            child: Builder(
              builder: (themedContext) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: ClipRect(
                    child: IgnorePointer(
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Design Comparison'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This screen shows side-by-side comparison of the Classic (V1) and Modern (V2) themes.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• Select different screens to compare'),
            Text('• V1: Current purple/teal theme'),
            Text('• V2: Modern blue/green theme'),
            Text('• Improved spacing and shadows in V2'),
            Text('• More rounded corners in V2'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Data class for comparison screens
class ComparisonScreen {
  final String name;
  final IconData icon;
  final Widget Function(BuildContext) builder;

  const ComparisonScreen({
    required this.name,
    required this.icon,
    required this.builder,
  });
}

/// Widget that provides theme switching controls
class ThemeComparisonControls extends StatelessWidget {
  const ThemeComparisonControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          margin: context.brandSpacing.md,
          child: Padding(
            padding: context.brandSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Controls',
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Theme version toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Theme:',
                      style: context.textTheme.bodyLarge,
                    ),
                    SegmentedButton<ThemeVersion>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeVersion.v1,
                          label: Text('V1'),
                          icon: Icon(Icons.palette_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeVersion.v2,
                          label: Text('V2'),
                          icon: Icon(Icons.auto_awesome),
                        ),
                      ],
                      selected: {themeProvider.themeVersion},
                      onSelectionChanged: (selection) {
                        themeProvider.setThemeVersion(selection.first);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quick toggle button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: themeProvider.toggleThemeVersion,
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(
                      'Switch to ${themeProvider.isV1Theme ? 'Modern (V2)' : 'Classic (V1)'}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
