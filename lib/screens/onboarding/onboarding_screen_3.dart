import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme_extensions.dart';
import '../../widgets/glass_container.dart';

/// Onboarding Screen 3: Profile Setup (Photos, Bio, Basic Info)
class OnboardingScreen3 extends StatefulWidget {
  final String userType;
  final Function(Map<String, dynamic> profileData) onProfileComplete;

  const OnboardingScreen3({
    Key? key,
    required this.userType,
    required this.onProfileComplete,
  }) : super(key: key);

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  
  String? _selectedGender;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: tokens.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  
                  // Header
                  Text(
                    'Complete Your Profile',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Add some details to help others connect with you',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Profile Image
                  _buildProfileImageSection(theme, tokens),
                  
                  const SizedBox(height: 32),
                  
                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildDisplayNameField(theme, tokens),
                          const SizedBox(height: 20),
                          _buildAgeField(theme, tokens),
                          const SizedBox(height: 20),
                          _buildGenderField(theme, tokens),
                          const SizedBox(height: 20),
                          _buildBioField(theme, tokens),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _validateAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusL),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Back Button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Back',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(ThemeData theme, AppThemeTokens tokens) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _profileImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(58),
                    child: Image.file(
                      _profileImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.white.withOpacity(0.7),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add profile photo',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayNameField(ThemeData theme, AppThemeTokens tokens) {
    return GlassContainer(
      child: TextFormField(
        controller: _displayNameController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Display Name',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintText: 'Enter your display name',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: tokens.primaryColor),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Display name is required';
          }
          if (value.trim().length < 2) {
            return 'Display name must be at least 2 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAgeField(ThemeData theme, AppThemeTokens tokens) {
    return GlassContainer(
      child: TextFormField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Age',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintText: 'Enter your age',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: tokens.primaryColor),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Age is required';
          }
          final age = int.tryParse(value.trim());
          if (age == null) {
            return 'Please enter a valid age';
          }
          if (age < 13 || age > 120) {
            return 'Age must be between 13 and 120';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderField(ThemeData theme, AppThemeTokens tokens) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption('male', 'Male', Icons.male, theme, tokens),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderOption('female', 'Female', Icons.female, theme, tokens),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon, ThemeData theme, AppThemeTokens tokens) {
    final isSelected = _selectedGender == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.primaryColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(tokens.radiusM),
          border: Border.all(
            color: isSelected ? tokens.primaryColor : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? tokens.primaryColor : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? tokens.primaryColor : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioField(ThemeData theme, AppThemeTokens tokens) {
    return GlassContainer(
      child: TextFormField(
        controller: _bioController,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Bio (Optional)',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintText: 'Tell others about yourself...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            borderSide: BorderSide(color: tokens.primaryColor),
          ),
        ),
        validator: (value) {
          if (value != null && value.trim().length > 500) {
            return 'Bio must be less than 500 characters';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _validateAndContinue() {
    if (_formKey.currentState!.validate() && _selectedGender != null) {
      final profileData = {
        'displayName': _displayNameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender!,
        'bio': _bioController.text.trim(),
        'profileImage': _profileImage,
      };
      
      widget.onProfileComplete(profileData);
    } else if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
