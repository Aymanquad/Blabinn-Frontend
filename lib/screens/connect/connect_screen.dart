import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/boosted_profiles_widget.dart';

class ConnectScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ConnectScreen({super.key, this.onNavigateToTab});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final GlobalKey<BoostedProfilesWidgetState> _boostedProfilesKey =
      GlobalKey<BoostedProfilesWidgetState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh boosted profiles when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _boostedProfilesKey.currentState?.refreshBoostedProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              16, 100, 16, 100), // Increased padding for transparent bars
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Connect section moved to top
              _AnimatedConnectNowSection(onConnect: () {
                widget.onNavigateToTab?.call(2); // Navigate to Connect tab
              }),
              const SizedBox(height: 16),
              // Boosted profiles section
              BoostedProfilesWidget(key: _boostedProfilesKey),
              const SizedBox(height: 16),
              // Banner Ad at the bottom
              const BannerAdWidget(
                height: 50,
                margin: EdgeInsets.only(bottom: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- New Animated Connect Now Section ---
class _AnimatedConnectNowSection extends StatefulWidget {
  final VoidCallback onConnect;
  const _AnimatedConnectNowSection({required this.onConnect});
  @override
  State<_AnimatedConnectNowSection> createState() =>
      _AnimatedConnectNowSectionState();
}

class _AnimatedConnectNowSectionState extends State<_AnimatedConnectNowSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.25, // Reduced height since it's now at the top
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Enhanced image container with background
            Container(
              width: height * 0.10, // Reduced size
              height: height * 0.10, // Reduced size
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/search-people-removebg-preview.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Enhanced connect button section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Connect?',
                    style: TextStyle(
                      fontSize: 22, // Increased from 18 for better readability
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find and chat with new people around you',
                    style: TextStyle(
                      fontSize:
                          16, // Increased from 13 for much better readability
                      fontWeight:
                          FontWeight.w500, // Added weight for better visibility
                      color: theme.colorScheme.onSurface.withOpacity(
                          0.9), // Increased opacity for better contrast
                      height: 1.3, // Added line height for better text flow
                    ),
                  ),
                  const SizedBox(height: 12),
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: ElevatedButton(
                      onPressed: widget.onConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12, // Reduced padding
                          horizontal: 18, // Reduced padding
                        ),
                        textStyle: const TextStyle(
                          fontSize:
                              16, // Increased from 14 for better readability
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                      child: const Text('Connect Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
