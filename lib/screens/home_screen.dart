import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _AnimatedOpeningImageSection(),
            const SizedBox(height: 16),
            Expanded(
              child: _AnimatedConnectNowSection(onConnect: () {
                widget.onNavigateToTab?.call(2); // Navigate to Connect tab
              }),
            ),
            const SizedBox(height: 8),
            // Banner Ad at the bottom
            const BannerAdWidget(
              height: 50,
              margin: EdgeInsets.only(bottom: 8),
            ),
          ],
        ),
      ),
    );
  }
}

// --- New Animated Opening Image Section ---
class _AnimatedOpeningImageSection extends StatefulWidget {
  @override
  State<_AnimatedOpeningImageSection> createState() =>
      _AnimatedOpeningImageSectionState();
}

class _AnimatedOpeningImageSectionState
    extends State<_AnimatedOpeningImageSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
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
    return FadeTransition(
      opacity: _fadeAnim,
      child: SizedBox(
        height: height * 0.35, // Reduced to fit on one screen
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 8,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          theme.colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/opening-image-removebg-preview.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Overlay couple chat image for enhanced visual appeal
                  Positioned(
                    bottom: 25,
                    right: 25,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/couple-chatting-mobile_118167-7967-removebg-preview.png',
                          fit: BoxFit.contain,
                        ),
                      ),
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
      height: height * 0.32, // Reduced from 0.35 to 0.32
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
        padding: const EdgeInsets.all(16), // Reduced padding from 20 to 16
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Enhanced image container with background
            Container(
              width: height * 0.12, // Reduced from 0.15 to 0.12
              height: height * 0.12, // Reduced from 0.15 to 0.12
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
            const SizedBox(width: 16), // Reduced spacing from 20 to 16
            // Enhanced connect button section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Connect?',
                    style: TextStyle(
                      fontSize: 20, // Reduced from 22 to 20
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced from 8 to 6
                  Text(
                    'Find and chat with new people around you',
                    style: TextStyle(
                      fontSize: 14, // Reduced from 15 to 14
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 16 to 12
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: ElevatedButton(
                      onPressed: widget.onConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14, // Reduced from 16 to 14
                          horizontal: 20, // Reduced from 24 to 20
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16, // Reduced from 18 to 16
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              14), // Reduced from 16 to 14
                        ),
                        elevation: 6, // Reduced from 8 to 6
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
