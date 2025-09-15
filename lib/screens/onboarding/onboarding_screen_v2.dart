import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/error_boundary.dart';
import 'onboarding_form_manager.dart';
import 'onboarding_step_widgets.dart';

/// Simplified onboarding screen using extracted components
class OnboardingScreenV2 extends StatefulWidget {
  const OnboardingScreenV2({super.key});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < OnboardingSteps.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formManager = context.read<OnboardingFormManager>();
      
      // Create user profile
      final profileData = formManager.getFormData();
      await _apiService.createProfile(profileData);

      // Upload profile picture if available
      if (formManager.profilePicture != null) {
        await _apiService.uploadProfilePicture(formManager.profilePicture!);
      }

      // Upload gallery images
      for (final image in formManager.galleryImages) {
        await _apiService.addGalleryPicture(image);
      }

      // Navigate to main app
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          title: 'Onboarding Failed',
          message: 'Failed to complete setup. Please try again.',
          error: e,
          onRetry: _completeOnboarding,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStepContent(OnboardingStep step, OnboardingFormManager formManager) {
    switch (step.type) {
      case OnboardingStepType.displayName:
        return DisplayNameStepWidget(formManager: formManager);
      case OnboardingStepType.username:
        return UsernameStepWidget(formManager: formManager);
      case OnboardingStepType.bio:
        return BioStepWidget(formManager: formManager);
      case OnboardingStepType.gender:
        return GenderStepWidget(formManager: formManager);
      case OnboardingStepType.age:
        return AgeStepWidget(formManager: formManager);
      case OnboardingStepType.profilePicture:
        return ProfilePictureStepWidget(formManager: formManager);
      case OnboardingStepType.interests:
        return InterestsStepWidget(formManager: formManager);
      case OnboardingStepType.gallery:
        return GalleryStepWidget(formManager: formManager);
    }
  }

  bool _canProceed(OnboardingStep step, OnboardingFormManager formManager) {
    switch (step.type) {
      case OnboardingStepType.displayName:
        return formManager.displayName.trim().isNotEmpty;
      case OnboardingStepType.username:
        return formManager.isUsernameAvailable;
      case OnboardingStepType.bio:
        return formManager.bio.trim().isNotEmpty;
      case OnboardingStepType.gender:
        return formManager.selectedGender.isNotEmpty;
      case OnboardingStepType.age:
        return formManager.age >= 18;
      case OnboardingStepType.profilePicture:
        return true; // Optional step
      case OnboardingStepType.interests:
        return formManager.interests.isNotEmpty;
      case OnboardingStepType.gallery:
        return true; // Optional step
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingFormManager(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Step ${_currentStep + 1} of ${OnboardingSteps.steps.length}'),
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                )
              : null,
        ),
        body: Consumer<OnboardingFormManager>(
          builder: (context, formManager, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / OnboardingSteps.steps.length,
                  ),
                  
                  // Step content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentStep = index;
                        });
                      },
                      itemCount: OnboardingSteps.steps.length,
                      itemBuilder: (context, index) {
                        final step = OnboardingSteps.steps[index];
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step title and subtitle
                              Text(
                                step.title,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step.subtitle,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Step content
                              Expanded(
                                child: ErrorBoundary(
                                  child: _buildStepContent(step, formManager),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousStep,
                              child: const Text('Previous'),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _canProceed(OnboardingSteps.steps[_currentStep], formManager)
                                    ? _nextStep
                                    : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_currentStep == OnboardingSteps.steps.length - 1
                                    ? 'Complete'
                                    : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
