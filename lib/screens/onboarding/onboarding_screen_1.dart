import 'package:flutter/material.dart';
import '../../core/theme_extensions.dart';

/// Onboarding Screen 1: Welcome & App Introduction
class OnboardingScreen1 extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingScreen1({
    Key? key,
    required this.onNext,
  }) : super(key: key);

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
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // App Logo/Icon with enhanced pulsing animation
                TweenAnimationBuilder(
                  duration: const Duration(seconds: 2),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      transform: Matrix4.identity()
                        ..scale(0.8 + (0.2 * value))
                        ..rotateZ(0.1 * (1 - value)),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFEAB308),
                              Color(0xFFF59E0B),
                              Color(0xFF84CC16)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            transform: GradientRotation(value * 0.5),
                          ),
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFEAB308)
                                  .withOpacity(0.4 + (0.2 * value)),
                              blurRadius: 25 + (15 * value),
                              spreadRadius: value * 5,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TweenAnimationBuilder(
                          duration: const Duration(seconds: 1),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, double iconValue, child) {
                            return Transform.scale(
                              scale: 0.5 + (0.5 * iconValue),
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 70,
                                color: Colors.white
                                    .withOpacity(0.9 + (0.1 * iconValue)),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // App Name with enhanced gradient text effect
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, double textValue, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - textValue)),
                      child: Opacity(
                        opacity: textValue,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFF1F5F9),
                              Color(0xFFE2E8F0),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: Text(
                            'Blabinn',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              fontSize: 48,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Tagline with modern styling
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Connect • Chat • Explore',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const Spacer(),

                // Description with better styling
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Welcome to Blabinn! 🚀\n\nThe ultimate platform for meaningful connections. Meet new people, start conversations, and build lasting friendships in a vibrant community.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 48),

                // Enhanced gradient button with hover effects
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 2000),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, double buttonValue, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - buttonValue)),
                      child: Opacity(
                        opacity: 0.3 + (0.7 * buttonValue),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFEAB308),
                                Color(0xFFF59E0B),
                                Color(0xFF84CC16),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: [0.0, 0.6, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFEAB308)
                                    .withOpacity(0.4 + (0.2 * buttonValue)),
                                blurRadius: 20 + (10 * buttonValue),
                                spreadRadius: buttonValue * 3,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Color(0xFF84CC16)
                                    .withOpacity(0.2 * buttonValue),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onNext,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: 18,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    TweenAnimationBuilder(
                                      duration: const Duration(seconds: 2),
                                      tween:
                                          Tween<double>(begin: 0.0, end: 1.0),
                                      builder:
                                          (context, double arrowValue, child) {
                                        return Transform.translate(
                                          offset: Offset(5 * arrowValue, 0),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white.withOpacity(
                                                0.9 + (0.1 * arrowValue)),
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Cool skip button
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
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Skip for now',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
