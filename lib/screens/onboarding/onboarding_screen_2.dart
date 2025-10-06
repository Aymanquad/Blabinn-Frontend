import 'package:flutter/material.dart';
import '../../core/theme_extensions.dart';
import '../../widgets/glass_container.dart';

/// Onboarding Screen 2: User Type Selection
class OnboardingScreen2 extends StatefulWidget {
  final Function(String userType) onUserTypeSelected;

  const OnboardingScreen2({
    Key? key,
    required this.onUserTypeSelected,
  }) : super(key: key);

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2>
    with TickerProviderStateMixin {
  String? selectedUserType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: tokens.primaryGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header with emoji and modern styling
                  Column(
                    children: [
                      // Animated emoji
                      TweenAnimationBuilder(
                        duration: const Duration(seconds: 1),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: const Text(
                              '🎯',
                              style: TextStyle(fontSize: 60),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Choose Your Vibe',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Select how you\'d like to experience Blabinn ✨',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Enhanced user type cards with staggered animations
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, double cardValue, child) {
                              return Transform.translate(
                                offset: Offset(-50 * (1 - cardValue), 0),
                                child: Opacity(
                                  opacity: cardValue,
                                  child: _buildUserTypeOption(
                                    context,
                                    userType: 'guest',
                                    title: 'Anonymous Explorer',
                                    subtitle:
                                        'Quick start, no strings attached',
                                    emoji: '🕶️',
                                    gradientColors: [
                                      const Color(0xFF64748B),
                                      const Color(0xFF94A3B8)
                                    ],
                                    features: [
                                      'Match with other explorers',
                                      'Basic chat features',
                                      'No signup needed',
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, double cardValue, child) {
                              return Transform.translate(
                                offset: Offset(50 * (1 - cardValue), 0),
                                child: Opacity(
                                  opacity: cardValue,
                                  child: _buildUserTypeOption(
                                    context,
                                    userType: 'signed_up_free',
                                    title: 'Community Member',
                                    subtitle: 'Join the vibrant community',
                                    emoji: '🌟',
                                    gradientColors: [
                                      const Color(0xFF3B82F6),
                                      const Color(0xFF60A5FA)
                                    ],
                                    features: [
                                      'Match with free & premium users',
                                      'Build lasting connections',
                                      'Profile verification available',
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 1200),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, double cardValue, child) {
                              return Transform.translate(
                                offset: Offset(-50 * (1 - cardValue), 0),
                                child: Opacity(
                                  opacity: cardValue,
                                  child: _buildUserTypeOption(
                                    context,
                                    userType: 'premium',
                                    title: 'VIP Experience',
                                    subtitle: 'Unlock the full potential',
                                    emoji: '👑',
                                    gradientColors: [
                                      const Color(0xFFEAB308),
                                      const Color(0xFFF59E0B)
                                    ],
                                    features: [
                                      'Priority matching with everyone',
                                      'Ad-free premium experience',
                                      'Unlimited features & boosts',
                                      'Exclusive premium perks',
                                    ],
                                    isRecommended: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Modern Continue Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: selectedUserType != null
                          ? const LinearGradient(
                              colors: [Color(0xFF84CC16), Color(0xFF65A30D)],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.withOpacity(0.3),
                                Colors.grey.withOpacity(0.2),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: selectedUserType != null
                          ? [
                              BoxShadow(
                                color: const Color(0xFF84CC16).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: selectedUserType != null
                            ? () => widget.onUserTypeSelected(selectedUserType!)
                            : null,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                selectedUserType != null
                                    ? 'Continue'
                                    : 'Select an Option',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: selectedUserType != null
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  fontSize: 18,
                                ),
                              ),
                              if (selectedUserType != null) ...[
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Modern Back Button
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Back',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(
    BuildContext context, {
    required String userType,
    required String title,
    required String subtitle,
    required String emoji,
    required List<Color> gradientColors,
    required List<String> features,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedUserType == userType;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedUserType = userType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: gradientColors)
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with emoji and title
            Row(
              children: [
                // Emoji in a circular container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF84CC16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'POPULAR',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: gradientColors.first,
                      size: 20,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Features with cool icons
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
