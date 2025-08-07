import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:io' show Platform;
import '../core/constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/premium_service.dart';
import '../providers/user_provider.dart';
import '../widgets/simple_image_cropper.dart';
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
  final _imagePicker = ImagePicker();

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
      backgroundColor: const Color(0xFF2D1B69), // Dark purple background
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/general-overlay.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildForm(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // Title in center
          const Expanded(
            child: Text(
              'Profile Management',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Save button
          TextButton(
            onPressed: _isUpdatingProfile ? null : _saveProfile,
            child: _isUpdatingProfile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture Section
          _buildProfilePictureSection(),
          const SizedBox(height: 24),
          
          // Basic Information Section
          _buildBasicInformationSection(),
          const SizedBox(height: 24),
          
          // Interests Section
          _buildInterestsSection(),
          const SizedBox(height: 24),
          
          // Gallery Section
          _buildGallerySection(),
          const SizedBox(height: 32),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isUpdatingProfile ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: _isUpdatingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Profile Picture',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Profile Picture Display
          GestureDetector(
            onTap: _pickProfilePicture,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: _profilePicture != null
                    ? Image.file(
                        _profilePicture!,
                        fit: BoxFit.cover,
                      )
                    : _existingProfilePictureUrl != null
                        ? Image.network(
                            _existingProfilePictureUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultProfilePicture(),
                          )
                        : _buildDefaultProfilePicture(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          TextButton.icon(
            onPressed: _pickProfilePicture,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text(
              'Change Photo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultProfilePicture() {
    return Container(
      color: const Color(0xFF8B5CF6),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Display Name
          _buildTextField(
            controller: _displayNameController,
            label: 'Display Name',
            hint: 'Enter your display name',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          
          // Username
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Enter your username',
            icon: Icons.alternate_email,
            onChanged: (value) => _checkUsernameAvailability(),
            errorText: _usernameError,
            suffix: _isCheckingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _isUsernameAvailable
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
          ),
          const SizedBox(height: 16),
          
          // Bio
          _buildTextField(
            controller: _bioController,
            label: 'Bio',
            hint: 'Tell us about yourself',
            icon: Icons.info,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Age
          _buildTextField(
            controller: _ageController,
            label: 'Age',
            hint: 'Enter your age',
            icon: Icons.cake,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          // Gender
          _buildGenderSelector(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? errorText,
    Widget? suffix,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: Colors.white),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF2D1B69),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: [
              DropdownMenuItem(value: 'male', child: const Text('Male')),
              DropdownMenuItem(value: 'female', child: const Text('Female')),
              DropdownMenuItem(value: 'other', child: const Text('Other')),
              DropdownMenuItem(value: 'prefer-not-to-say', child: const Text('Prefer not to say')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gallery',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _pickGalleryImages,
                icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                label: const Text(
                  'Add Photos',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_galleryImages.isNotEmpty || _existingGalleryImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _galleryImages.length + _existingGalleryImages.length,
              itemBuilder: (context, index) {
                if (index < _galleryImages.length) {
                  return _buildGalleryImageTile(_galleryImages[index], isNew: true);
                } else {
                  final existingIndex = index - _galleryImages.length;
                  return _buildGalleryImageTile(_existingGalleryImages[existingIndex], isNew: false);
                }
              },
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No photos yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryImageTile(dynamic image, {required bool isNew}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            isNew
                ? Image.file(
                    image as File,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Image.network(
                    image['url'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.withOpacity(0.3),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 32,
                        ),
                      );
                    },
                  ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeGalleryImage(image, isNew),
                child: Container(
                  padding: const EdgeInsets.all(4),
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
  }

  // Add missing methods
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isUpdatingProfile) {
      return;
    }

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final profileData = {
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': _selectedGender,
        'interests': _interests,
      };

      if (_hasExistingProfile) {
        await _apiService.updateProfile(profileData);
        _showSuccess('Profile updated successfully!');
      } else {
        await _apiService.createProfile(profileData);
        _showSuccess('Profile created successfully!');
        setState(() {
          _hasExistingProfile = true;
        });
      }

      // Reload the profile to get the latest data
      await _loadExistingProfile();
    } catch (e) {
      _showError('Failed to save profile: $e');
    } finally {
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  void _removeGalleryImage(dynamic image, bool isNew) {
    if (isNew) {
      setState(() {
        _galleryImages.remove(image);
      });
    } else {
      // For existing images, we need to call the API to remove them
      final index = _existingGalleryImages.indexOf(image);
      if (index != -1) {
        _removeExistingGalleryImage(index);
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      // Check permissions first
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          _showError('Photo permission is required to change profile picture');
          return;
        }
      }

      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final imageFile = File(image.path);
        
        // Show editing options
        final editedFile = await _showImageEditingOptions(imageFile, true);
        
        if (editedFile != null) {
          // Upload the profile picture
          await _uploadProfilePicture(editedFile);
        }
      }
    } catch (e) {
      _showError('Failed to pick profile picture: $e');
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      // Check permissions first
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          _showError('Photo permission is required to add gallery images');
          return;
        }
      }

      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final imageFile = File(image.path);
        
        // Show editing options
        final editedFile = await _showGalleryImageEditingOptions(imageFile);
        
        if (editedFile != null) {
          // Upload the image
          await _uploadGalleryImage(editedFile);
        }
      }
    } catch (e) {
      _showError('Failed to pick gallery image: $e');
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

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _ageController.dispose();

    super.dispose();
  }
}
