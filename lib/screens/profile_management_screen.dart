import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/boost_profile_service.dart';
import '../widgets/simple_image_cropper.dart';
import '../widgets/consistent_app_bar.dart';
import '../utils/permission_helper.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _apiService = ApiService();
  // Remove unused instance; we create pickers inline where needed

  // Form controllers
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();

  // Form state
  String _selectedGender =
      'male'; // Initialize with male instead of prefer-not-to-say
  List<String> _interests = [];
  File? _profilePicture;
  String? _existingProfilePictureUrl;
  List<File> _galleryImages = []; // New images to upload
  List<Map<String, dynamic>> _existingGalleryImages =
      []; // Existing gallery images from backend
  bool _isLoading = false;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  bool _isUploadingGallery =
      false; // Flag to prevent multiple simultaneous uploads
  bool _isUpdatingProfile =
      false; // Flag to prevent multiple simultaneous profile updates

  User? _currentUser;
  bool _hasExistingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initializeApiService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if this is a guest user and pre-fill form
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['isGuestUser'] == true) {
      _prefillGuestUserForm();
    }
  }

  // Pre-fill form with default values for guest users
  void _prefillGuestUserForm() {
    if (_displayNameController.text.isEmpty) {
      _displayNameController.text = 'Guest User';
    }
    if (_usernameController.text.isEmpty) {
      _usernameController.text =
          'username${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
    if (_bioController.text.isEmpty) {
      _bioController.text = 'Hey there! I\'m new to this app.';
    }
    if (_ageController.text.isEmpty) {
      _ageController.text = '25';
    }

    setState(() {
      _selectedGender = 'prefer-not-to-say';
      // Add some default interests
      _interests = ['Movies & TV', 'Music & Arts']
          .where(
              (interest) => AppConstants.availableInterests.contains(interest))
          .toList();
    });

    // print('🎭 DEBUG: Pre-filled guest user form with default values');

  }

  Future<void> _initializeApiService() async {
    await _apiService.initialize();
  }

  Future<void> _loadCurrentUser() async {
    await _authService.initialize();
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
        _populateFormFromUser(user);
      });

      // Try to load existing profile
      await _loadExistingProfile();
    }
  }

  void _populateFormFromUser(User user) {
    _displayNameController.text = user.username;
    // Note: We'll populate more fields when we load the full profile
  }

  Future<void> _loadExistingProfile() async {
    try {
      final responseData = await _apiService.getMyProfile();
      if (responseData['profile'] != null) {
        setState(() {
          _hasExistingProfile = true;
          _populateFormFromProfile(responseData['profile']);
        });
      }
    } catch (e) {
      // print('No existing profile found: $e');
      setState(() {
        _hasExistingProfile = false;
      });
    }
  }

  void _populateFormFromProfile(Map<String, dynamic> profile) {
    _displayNameController.text = profile['displayName'] ?? '';
    _usernameController.text = profile['username'] ?? '';
    _bioController.text = profile['bio'] ?? '';

    // Handle age properly
    final age = profile['age'];
    _ageController.text = age != null ? age.toString() : '';
    // print('🔍 [PROFILE DEBUG] Setting age: $age');

    setState(() {
      // Handle gender properly - default to male if invalid or missing
      final gender = profile['gender']?.toString().toLowerCase().trim() ?? '';
      _selectedGender = ['male', 'female'].contains(gender) ? gender : 'male';
      print(
          '🔍 [PROFILE DEBUG] Setting gender: $gender (normalized to: $_selectedGender)');

      // Set existing profile picture URL if available
      _existingProfilePictureUrl = profile['profilePicture'] as String? ??
          profile['profileImage'] as String?;
      if (_existingProfilePictureUrl != null) {
        print(
            '🔍 [PROFILE DEBUG] Found existing profile picture: $_existingProfilePictureUrl');
      }

      // Load existing gallery images
      if (profile['profilePictures'] != null &&
          profile['profilePictures'] is List) {
        _existingGalleryImages = List<Map<String, dynamic>>.from(
          profile['profilePictures'].map((pic) => {
                'url': pic['url'],
                'filename': pic['filename'],
              }),
        );
        print(
            '🔍 [PROFILE DEBUG] Loaded ${_existingGalleryImages.length} existing gallery images');
      } else {
        _existingGalleryImages = [];
      }

      // Filter interests to only include valid predefined ones
      final existingInterests = List<String>.from(profile['interests'] ?? []);
      print(
          '🔍 [PROFILE DEBUG] Loading existing interests: $existingInterests');
      print(
          '🔍 [PROFILE DEBUG] Available predefined interests: ${AppConstants.availableInterests}');

      _interests = existingInterests
          .where(
              (interest) => AppConstants.availableInterests.contains(interest))
          .toList();

      // print('🔍 [PROFILE DEBUG] Filtered interests: $_interests');

      // Log if user had invalid interests that were cleared
      if (_interests.length != existingInterests.length) {
        print(
            '🔄 [PROFILE DEBUG] Cleared ${existingInterests.length - _interests.length} invalid interests');
        print(
            '🔄 [PROFILE DEBUG] Interests that were removed: ${existingInterests.where((i) => !AppConstants.availableInterests.contains(i)).toList()}');
        print(
            '🔄 [PROFILE DEBUG] User will need to select new interests from predefined list');
      }

      // Clear new gallery image selections to prevent duplicate uploads
      _galleryImages.clear();
    });
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters';
        _isUsernameAvailable = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final result = await _apiService.checkUsernameAvailability(username);
      setState(() {
        _isUsernameAvailable = result['available'] ?? false;
        _usernameError =
            _isUsernameAvailable ? null : 'Username is already taken';
      });
    } catch (e) {
      setState(() {
        _usernameError = 'Error checking username availability';
        _isUsernameAvailable = false;
      });
    } finally {
      setState(() {
        _isCheckingUsername = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Complete Your Profile',
        showBackButton: _hasExistingProfile,
      ),
      body: _currentUser == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '👤 Complete Your Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please fill out the required information to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create/Update Profile Section
                    Text(
                      'Required Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Display Name
                    _buildTextField(
                      controller: _displayNameController,
                      label: 'Display Name',
                      hint: 'Enter display name',
                      maxLength: 50,
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
                    const SizedBox(height: 16),

                    // Username with availability check
                    _buildUsernameField(),
                    const SizedBox(height: 16),

                    // Bio
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      hint: 'Tell us about yourself...',
                      maxLines: 4,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 16),

                    // Profile Picture
                    _buildProfilePictureSection(),
                    const SizedBox(height: 16),

                    // Photo Gallery
                    _buildGallerySection(),
                    const SizedBox(height: 16),

                    // Gender
                    _buildGenderField(),
                    const SizedBox(height: 16),

                    // Age
                    _buildAgeField(),
                    const SizedBox(height: 16),

                    // Interests
                    _buildInterestsSection(),
                    const SizedBox(height: 24),

                    // Action Buttons - Simplified for now
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterText: maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Enter username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.textMuted),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.textMuted),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.error, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  errorText: _usernameError,
                  suffixIcon: _isCheckingUsername
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isUsernameAvailable
                          ? const Icon(Icons.check, color: AppColors.success)
                          : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  if (value.length < 3 || value.length > 30) {
                    return 'Username must be 3-30 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return 'Username can only contain letters, numbers, and underscores';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed:
                  _isCheckingUsername ? null : _checkUsernameAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardBackground,
                foregroundColor: AppColors.text,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Check Availability'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Age:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter your age',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Age is required';
            }
            final age = int.tryParse(value);
            if (age == null) {
              return 'Please enter a valid number';
            }
            if (age < 13) {
              return 'Age must be at least 13';
            }
            if (age > 120) {
              return 'Age must be less than 120';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            if (!_hasExistingProfile) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete Profile'),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Profile'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          // Reset form to original values
                          _loadExistingProfile();
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textMuted,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
            if (_hasExistingProfile) ...[
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loadExistingProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: const Text('Reset to Original'),
                ),
              ),
            ],
          ],
        ),
        // Boost Profile Button
        if (_hasExistingProfile) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _showBoostProfileDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.star, size: 20),
              label: const Text(
                'Boost Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent multiple simultaneous profile creations
    if (_isUpdatingProfile) {
      //print('⚠️ DEBUG: Profile creation already in progress, skipping...');
      return;
    }

    // Validate mandatory fields
    if (_displayNameController.text.trim().isEmpty) {
      _showError('Display name is required');
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      _showError('Username is required');
      return;
    }

    if (_ageController.text.trim().isEmpty) {
      _showError('Age is required');
      return;
    }

    if (_selectedGender.isEmpty) {
      _showError('Gender is required');
      return;
    }

    // Validate interests selection
    if (_interests.length < AppConstants.minInterestsRequired) {
      _showError(
          'Please select at least ${AppConstants.minInterestsRequired} interests to continue');
      return;
    }

    setState(() {
      _isLoading = true;
      _isUpdatingProfile = true;
    });

    try {
      final profileData = {
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'age': int.parse(_ageController.text.trim()),
        'interests': _interests,
      };

      //print('🔄 [PROFILE DEBUG] Creating profile with data: $profileData');

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
            //print('Failed to upload gallery image: $e');
            // Continue with other images even if one fails
          }
        }
        // Clear the gallery images list after successful uploads
        setState(() {
          _galleryImages.clear();
        });
      }

      _showSuccess('Profile created successfully!');
      setState(() {
        _hasExistingProfile = true;
      });

      // Redirect to home screen after successful profile creation
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      _showError('Error creating profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isUpdatingProfile = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent multiple simultaneous profile updates
    if (_isUpdatingProfile) {
      //print('⚠️ DEBUG: Profile update already in progress, skipping...');
      return;
    }

    // Validate mandatory fields
    if (_displayNameController.text.trim().isEmpty) {
      _showError('Display name is required');
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      _showError('Username is required');
      return;
    }

    if (_ageController.text.trim().isEmpty) {
      _showError('Age is required');
      return;
    }

    if (_selectedGender.isEmpty) {
      _showError('Gender is required');
      return;
    }

    // Validate interests selection
    if (_interests.length < AppConstants.minInterestsRequired) {
      _showError(
          'Please select at least ${AppConstants.minInterestsRequired} interests to continue');
      return;
    }

    setState(() {
      _isLoading = true;
      _isUpdatingProfile = true;
    });

    try {
      final profileData = {
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'age': int.parse(_ageController.text.trim()),
        'interests': _interests,
      };

      print('🔄 [PROFILE DEBUG] Updating profile with data: $profileData');
      print(
          '🔄 [PROFILE DEBUG] Gallery images count: ${_galleryImages.length}');
      print(
          '🔄 [PROFILE DEBUG] Existing gallery images count: ${_existingGalleryImages.length}');

      await _apiService.updateProfile(profileData);

      // print('✅ [PROFILE DEBUG] Profile update result: $result');

      // Upload profile picture if selected
      if (_profilePicture != null) {
        await _apiService.uploadProfilePicture(_profilePicture!);
      }

      // Upload gallery images if selected
      if (_galleryImages.isNotEmpty) {
        print(
            '🔄 [PROFILE DEBUG] Uploading ${_galleryImages.length} gallery images');
        for (final imageFile in _galleryImages) {
          try {
            print(
                '🔄 [PROFILE DEBUG] Uploading gallery image: ${imageFile.path}');
            await _apiService.addGalleryPicture(imageFile);
            // print('✅ [PROFILE DEBUG] Gallery image uploaded successfully');
          } catch (e) {
            // print('❌ [PROFILE DEBUG] Failed to upload gallery image: $e');
            // Continue with other images even if one fails
          }
        }
        // Clear the gallery images list after successful uploads
        setState(() {
          _galleryImages.clear();
        });
        // print('🔄 [PROFILE DEBUG] Cleared gallery images list');
      } else {
        // print('🔄 [PROFILE DEBUG] No new gallery images to upload');
      }

      _showSuccess('Profile updated successfully!');
    } catch (e) {
      _showError('Error updating profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isUpdatingProfile = false;
      });
    }
  }

  // _clearForm removed (unused)

  Widget _buildProfilePictureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Picture:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textMuted),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.inputBackground,
                ),
                child: Center(
                  child: Text(
                    _profilePicture != null
                        ? 'New image selected'
                        : (_existingProfilePictureUrl != null
                            ? 'Current profile picture'
                            : 'No file chosen'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _pickProfilePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(_existingProfilePictureUrl != null
                  ? 'Change Picture'
                  : 'Upload Picture'),
            ),
          ],
        ),
        // Show image preview
        if (_profilePicture != null || _existingProfilePictureUrl != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textMuted),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _profilePicture != null
                  ? Image.file(_profilePicture!, fit: BoxFit.cover)
                  : (_existingProfilePictureUrl != null
                      ? Image.network(
                          _existingProfilePictureUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            );
                          },
                        )
                      : const SizedBox.shrink()),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGallerySection() {
    final totalImages = _existingGalleryImages.length + _galleryImages.length;
    final canAddMore = totalImages < 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Gallery (${totalImages}/5 pictures):',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textMuted),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.inputBackground,
                ),
                child: Center(
                  child: Text(
                    totalImages > 0
                        ? '$totalImages images in gallery'
                        : 'No images in gallery',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: canAddMore ? _pickGalleryImages : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(canAddMore ? 'Add to Gallery' : 'Gallery Full'),
            ),
          ],
        ),
        if (totalImages > 0) ...[
          const SizedBox(height: 16),
          Text(
            'Existing Gallery Images:',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingGalleryImages.length,
              itemBuilder: (context, index) {
                final image = _existingGalleryImages[index];
                return Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          image['url'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeExistingGalleryImage(index),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                _setAsMainProfilePicture(image['filename']),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
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
        ],
        if (_galleryImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'New Images to Upload:',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _galleryImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.file(_galleryImages[index], fit: BoxFit.cover),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _galleryImages.removeAt(index)),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
        ],
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Gender:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: 'Select gender',
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'prefer-not-to-say', child: Text('Prefer not to say')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a gender';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedGender = value ?? 'male';
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Interests:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Select at least ${AppConstants.minInterestsRequired})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Predefined interests selection
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.availableInterests.map((interest) {
            final isSelected = _interests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _interests.add(interest);
                  } else {
                    _interests.remove(interest);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.inputBackground,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.text,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
        if (_interests.length < AppConstants.minInterestsRequired)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least ${AppConstants.minInterestsRequired} interests',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickProfilePicture() async {
    try {
      // Request gallery permission
      final hasPermission = await PermissionHelper.requestGalleryPermission(context);
      if (!hasPermission) {
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        // Show editing options
        final editedFile = await _showImageEditingOptions(imageFile, true);

        if (editedFile != null) {
          await _uploadProfilePicture(editedFile);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickGalleryImages() async {
    // Prevent multiple simultaneous picks
    if (_isUploadingGallery || _isLoading) {
      // print('⚠️ DEBUG: Upload already in progress, skipping gallery pick...');
      return;
    }

    try {
      // Request gallery permission
      final hasPermission = await PermissionHelper.requestGalleryPermission(context);
      if (!hasPermission) {
        return;
      }

      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        print('📤 DEBUG: Picked ${pickedFiles.length} images for gallery');
        for (final pickedFile in pickedFiles) {
          final imageFile = File(pickedFile.path);

          // Show editing options for each image
          final editedFile = await _showGalleryImageEditingOptions(imageFile);

          if (editedFile != null) {
            await _uploadGalleryImage(editedFile);
          }
        }
      }
    } catch (e) {
      // print('❌ DEBUG: Error picking gallery images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<File?> _showImageEditingOptions(
      File imageFile, bool isProfilePicture) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isProfilePicture ? 'Edit Profile Picture' : 'Edit Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
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
              // Show rotation editor
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

  Future<File?> _showGalleryImageEditingOptions(File imageFile) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Gallery Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
            child: const Text('Skip'),
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
              // Show rotation editor
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

  Future<void> _uploadProfilePicture(File imageFile) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // print('📤 DEBUG: Starting profile picture upload...');

      // Upload image to Firebase Storage
      final uploadResult = await _apiService.uploadProfilePicture(imageFile);

      // print('✅ DEBUG: Profile picture uploaded successfully');
      // print('🔗 DEBUG: Upload result: $uploadResult');
      // print('🔗 DEBUG: Firebase URL: ${uploadResult['url']}');

      // Update user profile with new Firebase URL
      final firebaseUrl = uploadResult['url'] as String;
      await _apiService.updateProfile({
        'profileImage': firebaseUrl,
      });

      // print('✅ DEBUG: User profile updated with new image URL');

      // Update local user data
      if (_currentUser != null) {
        setState(() {
          _currentUser = _currentUser!.copyWith(profileImage: firebaseUrl);
          _existingProfilePictureUrl = firebaseUrl;
        });
      }

      _showSuccess('Profile picture updated successfully!');
    } catch (e) {
      // print('❌ DEBUG: Profile picture upload failed: $e');
      _showError('Failed to upload profile picture: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadGalleryImage(File imageFile) async {
    // Prevent multiple simultaneous uploads
    if (_isUploadingGallery) {
      // print('⚠️ DEBUG: Gallery upload already in progress, skipping...');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _isUploadingGallery = true;
      });

      // print('📤 DEBUG: Starting gallery image upload...');
      // print('📤 DEBUG: Image file path: ${imageFile.path}');
      // print('📤 DEBUG: Image file size: ${await imageFile.length()} bytes');

      // Check if this image is already in the gallery (by filename)
      final fileName = imageFile.path.split('/').last;
      final isAlreadyUploaded = _existingGalleryImages.any((img) =>
          img['filename'] == fileName || img['url'].contains(fileName));

      if (isAlreadyUploaded) {
        // print('⚠️ DEBUG: Image already exists in gallery: $fileName');
        _showError('This image is already in your gallery');
        return;
      }

      // Upload image to Firebase Storage
      final uploadResult = await _apiService.addGalleryPicture(imageFile);

      print('✅ DEBUG: Gallery image uploaded successfully');
      print('🔗 DEBUG: Upload result: $uploadResult');
      // Check if upload data exists in the response - handle both response structures
      Map<String, dynamic>? uploadData;
      if (uploadResult['upload'] != null) {
        uploadData = uploadResult['upload'];
        print('🔗 DEBUG: Found upload data in uploadResult[\'upload\']');
      } else if (uploadResult['data'] != null &&
          uploadResult['data']['upload'] != null) {
        uploadData = uploadResult['data']['upload'];
        print(
            '🔗 DEBUG: Found upload data in uploadResult[\'data\'][\'upload\']');
      } else if (uploadResult['data'] != null &&
          uploadResult['data'] is Map<String, dynamic>) {
        // Check if the data itself contains upload info
        final data = uploadResult['data'] as Map<String, dynamic>;
        if (data.containsKey('upload')) {
          uploadData = data['upload'];
          print(
              '🔗 DEBUG: Found upload data in uploadResult[\'data\'][\'upload\']');
        }
      }

      if (uploadData != null) {
        // print('🔗 DEBUG: Firebase URL: ${uploadData?['url'] ?? 'null'}');
        // print('🔗 DEBUG: Filename: ${uploadData?['filename'] ?? 'null'}');

        // Add to existing gallery images instead of _galleryImages to prevent re-upload
        setState(() {
          _existingGalleryImages.add({
            'url': uploadData?['url'] ?? '',
            'filename': uploadData?['filename'] ?? '',
          });
        });

        print(
            '✅ DEBUG: Added to existing gallery images. Total count: ${_existingGalleryImages.length}');
      } else {
        // print('❌ DEBUG: No upload data found in response: $uploadResult');
        _showError('Invalid response from server');
        return;
      }

      _showSuccess('Gallery image added successfully!');
    } catch (e) {
      // print('❌ DEBUG: Gallery image upload failed: $e');
      _showError('Failed to add gallery image: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isUploadingGallery = false;
      });
    }
  }

  Future<void> _removeExistingGalleryImage(int index) async {
    try {
      setState(() => _isLoading = true);

      final image = _existingGalleryImages[index];
      await _apiService.removeGalleryPicture(image['filename']);

      setState(() {
        _existingGalleryImages.removeAt(index);
      });

      _showSuccess('Gallery image removed successfully');
    } catch (e) {
      _showError('Failed to remove gallery image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setAsMainProfilePicture(String filename) async {
    try {
      setState(() => _isLoading = true);

      await _apiService.setMainPicture(filename);

      // Reload profile to get updated profile picture URL
      await _loadExistingProfile();

      _showSuccess('Main profile picture updated successfully');
    } catch (e) {
      _showError('Failed to update main profile picture: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showBoostProfileDialog() {
    final boostService = BoostProfileService();
    
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<bool>(
        future: boostService.isProfileBoosted(),
        builder: (context, snapshot) {
          final isBoosted = snapshot.data ?? false;
          
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Boost Profile'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                 if (isBoosted) ...[
                   FutureBuilder<double>(
                     future: boostService.getRemainingBoostTime(),
                     builder: (context, timeSnapshot) {
                       final remainingHours = timeSnapshot.data ?? 0.0;
                       return Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: Colors.amber.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(
                                 color: Colors.amber.withOpacity(0.3),
                               ),
                             ),
                             child: Row(
                               children: [
                                 Icon(
                                   Icons.timer,
                                   color: Colors.amber,
                                   size: 20,
                                 ),
                                 const SizedBox(width: 8),
                                 Text(
                                   'Your profile is currently boosted!',
                                   style: TextStyle(
                                     color: Colors.amber.shade700,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(height: 12),
                           Text(
                             'Your profile will appear in the "Popular Profiles" section for ${remainingHours.toStringAsFixed(1)} more hours.',
                             style: const TextStyle(fontSize: 14),
                           ),
                         ],
                       );
                     },
                   ),
                ] else ...[
                  Text(
                    'Boost your profile to get more visibility!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Boost Benefits:',
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('• Appear in "Popular Profiles" section'),
                        const Text('• Get 10x more profile views'),
                        const Text('• Higher priority in search results'),
                        const Text('• Gold star badge on your profile'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cost: ${BoostProfileService.boostCost} credits\nDuration: ${BoostProfileService.boostDurationHours} hours',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              if (!isBoosted)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _purchaseBoost();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Boost Now'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _purchaseBoost() async {
    try {
      setState(() => _isLoading = true);
      
      final boostService = BoostProfileService();
      final result = await boostService.purchaseBoost();
      
      if (result['success'] == true) {
        _showSuccess(result['message']);
        // Update user credits if available
        if (result['credits'] != null) {
          // You might want to update the user provider here
        }
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError('Failed to purchase boost: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _ageController.dispose();

    super.dispose();
  }
}
