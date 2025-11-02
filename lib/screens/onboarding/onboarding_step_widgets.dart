import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../widgets/simple_image_cropper.dart';
import '../../utils/permission_helper.dart';
import 'onboarding_form_manager.dart';

/// Widget for display name input step
class DisplayNameStepWidget extends StatelessWidget {
  final OnboardingFormManager formManager;

  const DisplayNameStepWidget({
    super.key,
    required this.formManager,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: formManager.setDisplayName,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your display name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        Text(
          'This is how other users will see you in the app',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Widget for username input step
class UsernameStepWidget extends StatelessWidget {
  final OnboardingFormManager formManager;

  const UsernameStepWidget({
    super.key,
    required this.formManager,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: formManager.setUsername,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'Enter your username',
            border: const OutlineInputBorder(),
            suffixIcon: formManager.isCheckingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : formManager.isUsernameAvailable
                    ? const Icon(Icons.check, color: Colors.green)
                    : formManager.usernameError != null
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
            errorText: formManager.usernameError,
          ),
          textCapitalization: TextCapitalization.none,
          onSubmitted: (_) => formManager.checkUsernameAvailability(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: formManager.isCheckingUsername
              ? null
              : formManager.checkUsernameAvailability,
          child: const Text('Check Availability'),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a unique username that represents you',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Widget for bio input step
class BioStepWidget extends StatelessWidget {
  final OnboardingFormManager formManager;

  const BioStepWidget({
    super.key,
    required this.formManager,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: formManager.setBio,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell us about yourself...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        Text(
          'Write a short description about yourself (max 500 characters)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Widget for gender selection step
class GenderStepWidget extends StatelessWidget {
  final OnboardingFormManager formManager;

  const GenderStepWidget({
    super.key,
    required this.formManager,
  });

  @override
  Widget build(BuildContext context) {
    const genders = [
      {'value': 'male', 'label': 'Male'},
      {'value': 'female', 'label': 'Female'},
      {'value': 'non-binary', 'label': 'Non-binary'},
      {'value': 'prefer-not-to-say', 'label': 'Prefer not to say'},
    ];

    return Column(
      children: [
        ...genders.map((gender) => RadioListTile<String>(
              title: Text(gender['label']!),
              value: gender['value']!,
              groupValue: formManager.selectedGender,
              onChanged: (value) {
                if (value != null) {
                  formManager.setGender(value);
                }
              },
            )),
        const SizedBox(height: 16),
        Text(
          'This helps us show you relevant matches',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Widget for age selection step
class AgeStepWidget extends StatelessWidget {
  final OnboardingFormManager formManager;

  const AgeStepWidget({
    super.key,
    required this.formManager,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Age: ${formManager.age}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Slider(
          value: formManager.age.toDouble(),
          min: 18,
          max: 120,
          divisions: 102,
          label: formManager.age.toString(),
          onChanged: (value) {
            formManager.setAge(value.round());
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Your age helps us show you relevant matches',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Widget for profile picture selection step
class ProfilePictureStepWidget extends StatelessWidget {
  final OnboardingFormManager formManager;

  const ProfilePictureStepWidget({
    super.key,
    required this.formManager,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickProfilePicture(context),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 2),
              color: Colors.grey[100],
            ),
            child: formManager.profilePicture != null
                ? ClipOval(
                    child: Image.file(
                      formManager.profilePicture!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.add_a_photo,
                    size: 50,
                    color: Colors.grey,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _pickProfilePicture(context),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Choose Photo'),
        ),
        const SizedBox(height: 16),
        Text(
          'A great photo helps you get more matches',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Future<void> _pickProfilePicture(BuildContext context) async {
    final hasPermission = await PermissionHelper.requestCameraPermission();
    if (!hasPermission) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final croppedImage = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleImageCropper(
            imageFile: File(image.path),
            isCircular: true,
          ),
        ),
      );

      if (croppedImage != null) {
        formManager.setProfilePicture(croppedImage);
      }
    }
  }
}

/// Widget for interests selection step
class InterestsStepWidget extends StatelessWidget {
  final OnboardingFormManager formManager;

  const InterestsStepWidget({
    super.key,
    required this.formManager,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Selected Interests (${formManager.interests.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: formManager.interests
              .map((interest) => Chip(
                    label: Text(interest),
                    onDeleted: () => formManager.removeInterest(interest),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showInterestsDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Interests'),
        ),
        const SizedBox(height: 16),
        Text(
          'Select your interests to find like-minded people',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  void _showInterestsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Interests'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.predefinedInterests.map((interest) {
              final isSelected = formManager.interests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    formManager.addInterest(interest);
                  } else {
                    formManager.removeInterest(interest);
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

/// Widget for gallery images step
class GalleryStepWidget extends StatelessWidget {
  final OnboardingFormManager formManager;

  const GalleryStepWidget({
    super.key,
    required this.formManager,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Gallery Images (${formManager.galleryImages.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (formManager.galleryImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: formManager.galleryImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          formManager.galleryImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => formManager.removeGalleryImage(index),
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
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _pickGalleryImage(context),
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Photo'),
        ),
        const SizedBox(height: 16),
        Text(
          'Add more photos to show your personality',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Future<void> _pickGalleryImage(BuildContext context) async {
    final hasPermission = await PermissionHelper.requestCameraPermission();
    if (!hasPermission) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      formManager.addGalleryImage(File(image.path));
    }
  }
}
