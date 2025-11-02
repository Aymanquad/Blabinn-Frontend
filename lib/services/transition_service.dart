import 'package:flutter/material.dart';

class TransitionService {
  static const Duration _transitionDuration = Duration(milliseconds: 1200);
  static const Duration _logoMoveDuration = Duration(milliseconds: 800);
  static const Duration _fadeInDuration = Duration(milliseconds: 600);

  /// Creates a seamless transition from splash to login screen
  /// The logo moves from center to top-left position while the login UI fades in
  static Route<void> createSplashToLoginTransition(Widget loginScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => loginScreen,
      transitionDuration: _transitionDuration,
      reverseTransitionDuration: _transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _SplashToLoginTransition(
          animation: animation,
          child: child,
        );
      },
    );
  }

  /// Creates a fade transition for general use
  static Route<void> createFadeTransition(Widget screen, {Duration? duration}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionDuration: duration ?? const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Creates a slide transition from bottom
  static Route<void> createSlideFromBottomTransition(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

class _SplashToLoginTransition extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;

  const _SplashToLoginTransition({
    required this.animation,
    required this.child,
  });

  @override
  State<_SplashToLoginTransition> createState() =>
      _SplashToLoginTransitionState();
}

class _SplashToLoginTransitionState extends State<_SplashToLoginTransition>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;

  late Animation<Offset> _logoPositionAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _backgroundFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: TransitionService._logoMoveDuration,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: TransitionService._fadeInDuration,
      vsync: this,
    );

    // Logo moves from center to top-left and scales down
    _logoPositionAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0), // Center
      end: const Offset(-0.3, -0.6), // Top-left area
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOutCubic,
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.4, // Smaller size
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOutCubic,
    ));

    // Logo fades out during transition
    _logoFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    // Background fades from splash to login
    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));
  }

  void _startAnimations() {
    // Listen to main animation progress
    widget.animation.addListener(() {
      if (widget.animation.value > 0.1 && !_logoController.isAnimating) {
        _logoController.forward();
      }
      if (widget.animation.value > 0.5 && !_fadeController.isAnimating) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.animation,
        _logoController,
        _fadeController,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            // Splash screen background (fades out)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1F1941),
                    Color(0xFF2D1B69),
                    Color(0xFF1F1941),
                  ],
                ),
              ),
            ),

            // Login screen (fades in)
            Opacity(
              opacity: _backgroundFadeAnimation.value,
              child: widget.child,
            ),

            // Animated logo overlay
            if (_logoFadeAnimation.value > 0.01)
              Positioned.fill(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(
                      _logoPositionAnimation.value.dx *
                          MediaQuery.of(context).size.width,
                      _logoPositionAnimation.value.dy *
                          MediaQuery.of(context).size.height,
                    ),
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Opacity(
                        opacity: _logoFadeAnimation.value,
                        child: Image.asset(
                          'assets/images/chatify_purple_logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
