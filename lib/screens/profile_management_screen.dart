import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../core/constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';


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
  final _imagePicker = ImagePicker();

  // Form controllers
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();


  // Form state
  String _selectedGender = 'prefer-not-to-say';
  List<String> _interests = [];
  File? _profilePicture;
  List<File> _galleryImages = [];
  bool _isLoading = false;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;
  String? _usernameError;

  User? _currentUser;
  bool _hasExistingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initializeApiService();
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
      if (responseData != null && responseData['profile'] != null) {
        setState(() {
          _hasExistingProfile = true;
          _populateFormFromProfile(responseData['profile']);
        });
      }
    } catch (e) {
      print('No existing profile found: $e');
      setState(() {
        _hasExistingProfile = false;
      });
    }
  }

  void _populateFormFromProfile(Map<String, dynamic> profile) {
    _displayNameController.text = profile['displayName'] ?? '';
    _usernameController.text = profile['username'] ?? '';
    _bioController.text = profile['bio'] ?? '';
    _ageController.text = profile['age']?.toString() ?? '';

    setState(() {
      _selectedGender = profile['gender'] ?? 'prefer-not-to-say';
      
      // Filter interests to only include valid predefined ones
      final existingInterests = List<String>.from(profile['interests'] ?? []);
      print('🔍 [PROFILE DEBUG] Loading existing interests: $existingInterests');
      print('🔍 [PROFILE DEBUG] Available predefined interests: ${AppConstants.availableInterests}');
      
      _interests = existingInterests
          .where((interest) => AppConstants.availableInterests.contains(interest))
          .toList();
      
      print('🔍 [PROFILE DEBUG] Filtered interests: $_interests');
      
      // Log if user had invalid interests that were cleared
      if (_interests.length != existingInterests.length) {
        print('🔄 [PROFILE DEBUG] Cleared ${existingInterests.length - _interests.length} invalid interests');
        print('🔄 [PROFILE DEBUG] Interests that were removed: ${existingInterests.where((i) => !AppConstants.availableInterests.contains(i)).toList()}');
        print('🔄 [PROFILE DEBUG] User will need to select new interests from predefined list');
      }
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
      appBar: AppBar(
        title: const Text('Profile Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
                      child: const Text(
                        '👤 Profile Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create/Update Profile Section
                    Text(
                      'Create/Update Profile',
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
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      hint: 'Enter age',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final age = int.tryParse(value);
                        if (age == null || age < 13 || age > 120) {
                          return 'Age must be between 13 and 120';
                        }
                        return null;
                      },
                    ),
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
            border: const OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
                  errorText: _usernameError,
                  suffixIcon: _isCheckingUsername
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isUsernameAvailable
                          ? const Icon(Icons.check, color: Colors.green)
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
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Check Availability'),
            ),
          ],
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Profile'),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
            ],
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loadExistingProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Get My Profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate interests selection
    if (_interests.length < AppConstants.minInterestsRequired) {
      _showError(
          'Please select at least ${AppConstants.minInterestsRequired} interests to continue');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = {
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'interests': _interests,
      };

      final result = await _apiService.createProfile(profileData);

      // Upload profile picture if selected
      if (_profilePicture != null) {
        await _apiService.uploadProfilePicture(_profilePicture!);
      }

      _showSuccess('Profile created successfully!');
      setState(() {
        _hasExistingProfile = true;
      });
    } catch (e) {
      _showError('Error creating profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate interests selection
    if (_interests.length < AppConstants.minInterestsRequired) {
      _showError(
          'Please select at least ${AppConstants.minInterestsRequired} interests to continue');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = {
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'interests': _interests,
      };

      print('🔄 [PROFILE DEBUG] Updating profile with interests: $_interests');
      print('🔄 [PROFILE DEBUG] Full profile data: $profileData');

      final result = await _apiService.updateProfile(profileData);
      
      print('✅ [PROFILE DEBUG] Profile update result: $result');

      // Upload profile picture if selected
      if (_profilePicture != null) {
        await _apiService.uploadProfilePicture(_profilePicture!);
      }

      _showSuccess('Profile updated successfully!');
      
      // Reload profile to verify interests were saved correctly
      print('🔄 [PROFILE DEBUG] Reloading profile to verify interests...');
      await _loadExistingProfile();
    } catch (e) {
      _showError('Error updating profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  void _clearForm() {
    _displayNameController.clear();
    _usernameController.clear();
    _bioController.clear();
    _ageController.clear();
    setState(() {
      _selectedGender = 'prefer-not-to-say';
      _interests.clear();
      _profilePicture = null;
      _galleryImages.clear();
    });
  }

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
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    _profilePicture != null
                        ? 'Image selected'
                        : 'No file chosen',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _pickProfilePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload Picture'),
            ),
          ],
        ),
        if (_profilePicture != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_profilePicture!, fit: BoxFit.cover),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Gallery (Up to 5 pictures):',
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
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    _galleryImages.isNotEmpty
                        ? '${_galleryImages.length} images selected'
                        : 'No file chosen',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _galleryImages.length < 5 ? _pickGalleryImages : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add to Gallery'),
            ),
          ],
        ),
        if (_galleryImages.isNotEmpty) ...[
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
        Text(
          'Gender:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
            DropdownMenuItem(
                value: 'prefer-not-to-say', child: Text('Prefer not to say')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value ?? 'prefer-not-to-say';
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
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
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
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profilePicture = File(image.path);
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      // Limit to 5 images total
      final availableSlots = 5 - _galleryImages.length;
      final imagesToAdd =
          images.take(availableSlots).map((xfile) => File(xfile.path)).toList();

      setState(() {
        _galleryImages.addAll(imagesToAdd);
      });
    } catch (e) {
      _showError('Error picking images: $e');
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

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _ageController.dispose();

    super.dispose();
  }


}
