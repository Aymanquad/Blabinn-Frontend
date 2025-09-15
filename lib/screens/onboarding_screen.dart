import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import '../core/constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/simple_image_cropper.dart';
import '../utils/permission_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _authService = AuthService();
  final _apiService = ApiService();

  // Form data
  String _displayName = '';
  String _username = '';
  String _bio = '';
  String _selectedGender = 'prefer-not-to-say';
  int _age = 25;
  List<String> _interests = [];
  File? _profilePicture;
  List<File> _galleryImages = [];

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;
  String? _usernameError;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: "What's your name?",
      subtitle: "This is how other users will see you",
      type: OnboardingStepType.displayName,
    ),
    OnboardingStep(
      title: "Choose a username",
      subtitle: "This will be your unique identifier",
      type: OnboardingStepType.username,
    ),
    OnboardingStep(
      title: "Tell us about yourself",
      subtitle: "Write a short bio to help others get to know you",
      type: OnboardingStepType.bio,
    ),
    OnboardingStep(
      title: "What's your gender?",
      subtitle: "Help others find you",
      type: OnboardingStepType.gender,
    ),
    OnboardingStep(
      title: "How old are you?",
      subtitle: "Your age helps us show you relevant matches",
      type: OnboardingStepType.age,
    ),
    OnboardingStep(
      title: "Add a profile picture",
      subtitle: "A great photo helps you get more matches",
      type: OnboardingStepType.profilePicture,
    ),
    OnboardingStep(
      title: "What are you into?",
      subtitle: "Select your interests to find like-minded people",
      type: OnboardingStepType.interests,
    ),
    OnboardingStep(
      title: "Add some photos",
      subtitle: "Show more of your personality with additional photos",
      type: OnboardingStepType.gallery,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _initializeApiService();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeApiService() async {
    await _apiService.initialize();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    }
  }

  bool _canProceed() {
    switch (_steps[_currentStep].type) {
      case OnboardingStepType.displayName:
        return _displayName.trim().isNotEmpty && _displayName.trim().length >= 2;
      case OnboardingStepType.username:
        return _username.trim().isNotEmpty && 
               _username.trim().length >= 3 && 
               _isUsernameAvailable;
      case OnboardingStepType.bio:
        return _bio.trim().isNotEmpty;
      case OnboardingStepType.gender:
        return _selectedGender.isNotEmpty;
      case OnboardingStepType.age:
        return _age >= 13 && _age <= 120;
      case OnboardingStepType.profilePicture:
        return true; // Optional step
      case OnboardingStepType.interests:
        return _interests.length >= AppConstants.minInterestsRequired;
      case OnboardingStepType.gallery:
        return true; // Optional step
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = {
        'displayName': _displayName.trim(),
        'username': _username.trim(),
        'bio': _bio.trim(),
        'gender': _selectedGender,
        'age': _age,
        'interests': _interests,
      };

      await _apiService.createProfile(profileData);

      // Upload profile picture if selected
      if (_profilePicture != null) {
        await _apiService.uploadProfilePicture(_profilePicture!);
      }

      // Upload gallery images if selected
      if (_galleryImages.isNotEmpty) {
        for (final imageFile in _galleryImages) {
          try {
            await _apiService.addGalleryPicture(imageFile);
          } catch (e) {
            // Continue with other images even if one fails
          }
        }
      }

      // Navigate to home screen
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      _showError('Error creating profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0A1A), // Very dark purple
              Color(0xFF1A0D2E), // Dark purple
              Color(0xFF0D0A1A), // Very dark purple
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildStepContent(_steps[index]),
                    );
                  },
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${((_currentStep + 1) / _steps.length * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
           LinearProgressIndicator(
             value: (_currentStep + 1) / _steps.length,
             backgroundColor: const Color(0xFF1A0D2E).withOpacity(0.8),
             valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
             minHeight: 6,
           ),
        ],
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Title and subtitle
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Step content
          Expanded(
            child: _buildStepWidget(step),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStepWidget(OnboardingStep step) {
    switch (step.type) {
      case OnboardingStepType.displayName:
        return _buildDisplayNameStep();
      case OnboardingStepType.username:
        return _buildUsernameStep();
      case OnboardingStepType.bio:
        return _buildBioStep();
      case OnboardingStepType.gender:
        return _buildGenderStep();
      case OnboardingStepType.age:
        return _buildAgeStep();
      case OnboardingStepType.profilePicture:
        return _buildProfilePictureStep();
      case OnboardingStepType.interests:
        return _buildInterestsStep();
      case OnboardingStepType.gallery:
        return _buildGalleryStep();
    }
  }

  Widget _buildDisplayNameStep() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _displayName = value;
        });
      },
      style: const TextStyle(
        fontSize: 18,
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your display name',
        hintStyle: TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.inputBackground.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }

  Widget _buildUsernameStep() {
    return Column(
      children: [
        TextField(
          onChanged: (value) {
            setState(() {
              _username = value;
              _isUsernameAvailable = false;
              _usernameError = null;
            });
            if (value.length >= 3) {
              _checkUsernameAvailability();
            }
          },
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Choose a username',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            filled: true,
            fillColor: const Color(0xFF1A0D2E).withOpacity(0.6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            suffixIcon: _isCheckingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _isUsernameAvailable
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
            errorText: _usernameError,
          ),
        ),
        if (_username.isNotEmpty && !_isUsernameAvailable && !_isCheckingUsername)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Username must be at least 3 characters and available',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBioStep() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _bio = value;
        });
      },
      maxLines: 6,
      maxLength: 500,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Tell us about yourself...',
        hintStyle: TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.inputBackground.withOpacity(0.8),
        contentPadding: const EdgeInsets.all(20),
        counterStyle: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildGenderStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildGenderOption('male', 'Male', Icons.male),
          const SizedBox(height: 12),
          _buildGenderOption('female', 'Female', Icons.female),
          const SizedBox(height: 12),
          _buildGenderOption('prefer-not-to-say', 'Prefer not to say', Icons.help_outline),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: isSelected ? AppColors.primary.withOpacity(0.3) : const Color(0xFF1A0D2E).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textMuted.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.text,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.text,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeStep() {
    return Column(
      children: [
        // Simple age display
        Text(
          '$_age',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'years old',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: 60),
        
        // Simple slider
        Slider(
          value: _age.toDouble(),
          min: 13,
          max: 120,
          divisions: 107,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.textMuted.withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _age = value.round();
            });
          },
        ),
        
        const SizedBox(height: 20),
        
        // Age range labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '13',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
            Text(
              '120',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 40),
        
        Text(
          'You can change this later in your profile settings',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  Widget _buildProfilePictureStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        
        // Profile picture container
        Center(
          child: GestureDetector(
            onTap: _pickProfilePicture,
            child: Container(
              width: 200,
              height: 200,
               decoration: BoxDecoration(
                 color: const Color(0xFF1A0D2E).withOpacity(0.6),
                 borderRadius: BorderRadius.circular(100),
                 border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
               ),
              child: _profilePicture != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.file(
                        _profilePicture!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Skip text
        Center(
          child: Text(
            'You can skip this step and add a photo later',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const Spacer(),
      ],
    );
  }

  Widget _buildInterestsStep() {
    return Column(
      children: [
        Text(
          'Select at least ${AppConstants.minInterestsRequired} interests',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppConstants.availableInterests.map((interest) {
                final isSelected = _interests.contains(interest);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _interests.remove(interest);
                      } else {
                        _interests.add(interest);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                       color: isSelected ? AppColors.primary : const Color(0xFF1A0D2E).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.textMuted.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryStep() {
    return Column(
      children: [
        Text(
          'Add up to 5 photos to your gallery',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _galleryImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _galleryImages.length) {
                return GestureDetector(
                  onTap: _galleryImages.length < 5 ? _pickGalleryImages : null,
                  child: Container(
                     decoration: BoxDecoration(
                       color: _galleryImages.length < 5 
                           ? const Color(0xFF1A0D2E).withOpacity(0.6)
                           : const Color(0xFF0D0A1A).withOpacity(0.8),
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                     ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: _galleryImages.length < 5 
                              ? AppColors.textMuted 
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _galleryImages.length < 5 ? 'Add Photo' : 'Gallery Full',
                          style: TextStyle(
                            color: _galleryImages.length < 5 
                                ? AppColors.textMuted 
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.file(
                        _galleryImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _galleryImages.removeAt(index);
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'You can skip this step and add photos later',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: BorderSide(color: AppColors.textMuted.withOpacity(0.7)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canProceed() ? (_isLoading ? null : _nextStep) : null,
              style: ElevatedButton.styleFrom(
                 backgroundColor: _canProceed() ? AppColors.primary : const Color(0xFF1A0D2E).withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _canProceed() ? 4 : 1,
                shadowColor: _canProceed() ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == _steps.length - 1 ? 'Complete' : 'Continue',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkUsernameAvailability() async {
    if (_username.trim().length < 3) return;

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final response = await _apiService.checkUsernameAvailability(_username.trim());
      final isAvailable = response['available'] ?? false;
      setState(() {
        _isUsernameAvailable = isAvailable;
        _isCheckingUsername = false;
        if (!isAvailable) {
          _usernameError = 'Username is already taken';
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingUsername = false;
        _usernameError = 'Error checking username availability';
      });
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final hasPermission = await PermissionHelper.requestGalleryPermission(context);
      if (!hasPermission) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final editedFile = await _showImageEditingOptions(imageFile, true);

        if (editedFile != null) {
          setState(() {
            _profilePicture = editedFile;
          });
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final hasPermission = await PermissionHelper.requestGalleryPermission(context);
      if (!hasPermission) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final editedFile = await _showImageEditingOptions(imageFile, false);

        if (editedFile != null) {
          setState(() {
            _galleryImages.add(editedFile);
          });
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<File?> _showImageEditingOptions(File imageFile, bool isProfilePicture) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Edit Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textMuted),
                borderRadius: BorderRadius.circular(isProfilePicture ? 100 : 8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isProfilePicture ? 100 : 8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose an option:',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(imageFile);
            },
            child: const Text('Use As Is'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final rotatedFile = await SimpleImageCropper.showImageEditor(
                context: context,
                imageFile: imageFile,
                title: 'Rotate Image',
              );
              if (rotatedFile != null) {
                Navigator.of(context).pop(rotatedFile);
              } else {
                Navigator.of(context).pop(imageFile);
              }
            },
            child: const Text('Rotate'),
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final OnboardingStepType type;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

enum OnboardingStepType {
  displayName,
  username,
  bio,
  gender,
  age,
  profilePicture,
  interests,
  gallery,
}

