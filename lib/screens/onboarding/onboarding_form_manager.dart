import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

/// Manages the onboarding form data and validation
class OnboardingFormManager extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Form data
  String _displayName = '';
  String _username = '';
  String _bio = '';
  String _selectedGender = 'prefer-not-to-say';
  int _age = 25;
  List<String> _interests = [];
  File? _profilePicture;
  List<File> _galleryImages = [];

  // Validation states
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;
  String? _usernameError;

  // Getters
  String get displayName => _displayName;
  String get username => _username;
  String get bio => _bio;
  String get selectedGender => _selectedGender;
  int get age => _age;
  List<String> get interests => List.unmodifiable(_interests);
  File? get profilePicture => _profilePicture;
  List<File> get galleryImages => List.unmodifiable(_galleryImages);
  bool get isUsernameAvailable => _isUsernameAvailable;
  bool get isCheckingUsername => _isCheckingUsername;
  String? get usernameError => _usernameError;

  // Setters
  void setDisplayName(String value) {
    _displayName = value;
    notifyListeners();
  }

  void setUsername(String value) {
    _username = value;
    _isUsernameAvailable = false;
    _usernameError = null;
    notifyListeners();
  }

  void setBio(String value) {
    _bio = value;
    notifyListeners();
  }

  void setGender(String value) {
    _selectedGender = value;
    notifyListeners();
  }

  void setAge(int value) {
    _age = value;
    notifyListeners();
  }

  void addInterest(String interest) {
    if (!_interests.contains(interest)) {
      _interests.add(interest);
      notifyListeners();
    }
  }

  void removeInterest(String interest) {
    _interests.remove(interest);
    notifyListeners();
  }

  void setProfilePicture(File? file) {
    _profilePicture = file;
    notifyListeners();
  }

  void addGalleryImage(File file) {
    _galleryImages.add(file);
    notifyListeners();
  }

  void removeGalleryImage(int index) {
    if (index >= 0 && index < _galleryImages.length) {
      _galleryImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Check if username is available
  Future<void> checkUsernameAvailability() async {
    if (_username.isEmpty) {
      _usernameError = 'Username is required';
      _isUsernameAvailable = false;
      notifyListeners();
      return;
    }

    if (_username.length < 3) {
      _usernameError = 'Username must be at least 3 characters';
      _isUsernameAvailable = false;
      notifyListeners();
      return;
    }

    _isCheckingUsername = true;
    _usernameError = null;
    notifyListeners();

    try {
      final result = await _apiService.checkUsernameAvailability(_username);
      _isUsernameAvailable = result['available'] == true;
      if (!_isUsernameAvailable) {
        _usernameError = 'Username is already taken';
      }
    } catch (e) {
      _usernameError = 'Error checking username availability';
      _isUsernameAvailable = false;
    } finally {
      _isCheckingUsername = false;
      notifyListeners();
    }
  }

  /// Validate the current form data
  Map<String, String> validateForm() {
    final errors = <String, String>{};

    if (_displayName.trim().isEmpty) {
      errors['displayName'] = 'Display name is required';
    }

    if (_username.trim().isEmpty) {
      errors['username'] = 'Username is required';
    } else if (_username.length < 3) {
      errors['username'] = 'Username must be at least 3 characters';
    } else if (!_isUsernameAvailable) {
      errors['username'] = 'Username is not available';
    }

    if (_bio.trim().isEmpty) {
      errors['bio'] = 'Bio is required';
    }

    if (_age < 18) {
      errors['age'] = 'You must be at least 18 years old';
    }

    if (_interests.isEmpty) {
      errors['interests'] = 'Please select at least one interest';
    }

    return errors;
  }

  /// Check if the form is valid
  bool get isFormValid {
    final errors = validateForm();
    return errors.isEmpty;
  }

  /// Get form data as a map for API submission
  Map<String, dynamic> getFormData() {
    return {
      'displayName': _displayName.trim(),
      'username': _username.trim(),
      'bio': _bio.trim(),
      'gender': _selectedGender,
      'age': _age,
      'interests': _interests,
    };
  }

  /// Reset the form
  void reset() {
    _displayName = '';
    _username = '';
    _bio = '';
    _selectedGender = 'prefer-not-to-say';
    _age = 25;
    _interests.clear();
    _profilePicture = null;
    _galleryImages.clear();
    _isUsernameAvailable = false;
    _isCheckingUsername = false;
    _usernameError = null;
    notifyListeners();
  }
}

/// Onboarding step configuration
class OnboardingStep {
  final String title;
  final String subtitle;
  final OnboardingStepType type;

  const OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

/// Types of onboarding steps
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

/// Predefined onboarding steps
class OnboardingSteps {
  static const List<OnboardingStep> steps = [
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
}
