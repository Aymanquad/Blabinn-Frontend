import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:io';
import 'package:chatify/services/api_service.dart';
import 'package:chatify/screens/onboarding/onboarding_form_manager.dart';

import 'onboarding_form_manager_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  group('OnboardingFormManager Tests', () {
    late OnboardingFormManager formManager;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      formManager = OnboardingFormManager();
    });

    group('Form Data Management', () {
      test('should initialize with default values', () {
        expect(formManager.displayName, equals(''));
        expect(formManager.username, equals(''));
        expect(formManager.bio, equals(''));
        expect(formManager.selectedGender, equals('prefer-not-to-say'));
        expect(formManager.age, equals(25));
        expect(formManager.interests, isEmpty);
        expect(formManager.profilePicture, isNull);
        expect(formManager.galleryImages, isEmpty);
        expect(formManager.isUsernameAvailable, isFalse);
        expect(formManager.isCheckingUsername, isFalse);
        expect(formManager.usernameError, isNull);
      });

      test('should update display name', () {
        // Act
        formManager.setDisplayName('John Doe');

        // Assert
        expect(formManager.displayName, equals('John Doe'));
      });

      test('should update username', () {
        // Act
        formManager.setUsername('johndoe');

        // Assert
        expect(formManager.username, equals('johndoe'));
        expect(formManager.isUsernameAvailable, isFalse);
        expect(formManager.usernameError, isNull);
      });

      test('should update bio', () {
        // Act
        formManager.setBio('I love music and sports');

        // Assert
        expect(formManager.bio, equals('I love music and sports'));
      });

      test('should update gender', () {
        // Act
        formManager.setGender('male');

        // Assert
        expect(formManager.selectedGender, equals('male'));
      });

      test('should update age', () {
        // Act
        formManager.setAge(30);

        // Assert
        expect(formManager.age, equals(30));
      });

      test('should add interest', () {
        // Act
        formManager.addInterest('music');

        // Assert
        expect(formManager.interests, contains('music'));
        expect(formManager.interests.length, equals(1));
      });

      test('should not add duplicate interest', () {
        // Arrange
        formManager.addInterest('music');

        // Act
        formManager.addInterest('music');

        // Assert
        expect(formManager.interests.length, equals(1));
        expect(formManager.interests, contains('music'));
      });

      test('should remove interest', () {
        // Arrange
        formManager.addInterest('music');
        formManager.addInterest('sports');

        // Act
        formManager.removeInterest('music');

        // Assert
        expect(formManager.interests, isNot(contains('music')));
        expect(formManager.interests, contains('sports'));
        expect(formManager.interests.length, equals(1));
      });

      test('should set profile picture', () {
        // Arrange
        final file = File('test_image.jpg');

        // Act
        formManager.setProfilePicture(file);

        // Assert
        expect(formManager.profilePicture, equals(file));
      });

      test('should add gallery image', () {
        // Arrange
        final file1 = File('gallery1.jpg');
        final file2 = File('gallery2.jpg');

        // Act
        formManager.addGalleryImage(file1);
        formManager.addGalleryImage(file2);

        // Assert
        expect(formManager.galleryImages.length, equals(2));
        expect(formManager.galleryImages, contains(file1));
        expect(formManager.galleryImages, contains(file2));
      });

      test('should remove gallery image', () {
        // Arrange
        final file1 = File('gallery1.jpg');
        final file2 = File('gallery2.jpg');
        formManager.addGalleryImage(file1);
        formManager.addGalleryImage(file2);

        // Act
        formManager.removeGalleryImage(0);

        // Assert
        expect(formManager.galleryImages.length, equals(1));
        expect(formManager.galleryImages, contains(file2));
        expect(formManager.galleryImages, isNot(contains(file1)));
      });

      test('should not remove gallery image with invalid index', () {
        // Arrange
        final file = File('gallery1.jpg');
        formManager.addGalleryImage(file);

        // Act
        formManager.removeGalleryImage(-1);
        formManager.removeGalleryImage(5);

        // Assert
        expect(formManager.galleryImages.length, equals(1));
        expect(formManager.galleryImages, contains(file));
      });
    });

    group('Username Validation', () {
      test('should set error for empty username', () async {
        // Act
        await formManager.checkUsernameAvailability();

        // Assert
        expect(formManager.usernameError, equals('Username is required'));
        expect(formManager.isUsernameAvailable, isFalse);
        expect(formManager.isCheckingUsername, isFalse);
      });

      test('should set error for short username', () async {
        // Arrange
        formManager.setUsername('ab');

        // Act
        await formManager.checkUsernameAvailability();

        // Assert
        expect(formManager.usernameError, equals('Username must be at least 3 characters'));
        expect(formManager.isUsernameAvailable, isFalse);
        expect(formManager.isCheckingUsername, isFalse);
      });

      test('should handle successful username check', () async {
        // Arrange
        formManager.setUsername('validusername');
        when(mockApiService.checkUsernameAvailability('validusername'))
            .thenAnswer((_) async => {'available': true});

        // Act
        await formManager.checkUsernameAvailability();

        // Assert
        expect(formManager.isUsernameAvailable, isTrue);
        expect(formManager.usernameError, isNull);
        expect(formManager.isCheckingUsername, isFalse);
      });

      test('should handle username not available', () async {
        // Arrange
        formManager.setUsername('takenusername');
        when(mockApiService.checkUsernameAvailability('takenusername'))
            .thenAnswer((_) async => {'available': false});

        // Act
        await formManager.checkUsernameAvailability();

        // Assert
        expect(formManager.isUsernameAvailable, isFalse);
        expect(formManager.usernameError, equals('Username is already taken'));
        expect(formManager.isCheckingUsername, isFalse);
      });

      test('should handle API error during username check', () async {
        // Arrange
        formManager.setUsername('testusername');
        when(mockApiService.checkUsernameAvailability('testusername'))
            .thenThrow(Exception('Network error'));

        // Act
        await formManager.checkUsernameAvailability();

        // Assert
        expect(formManager.isUsernameAvailable, isFalse);
        expect(formManager.usernameError, equals('Error checking username availability'));
        expect(formManager.isCheckingUsername, isFalse);
      });
    });

    group('Form Validation', () {
      test('should validate complete form correctly', () {
        // Arrange
        formManager.setDisplayName('John Doe');
        formManager.setUsername('johndoe');
        formManager.setBio('I love music and sports');
        formManager.setGender('male');
        formManager.setAge(25);
        formManager.addInterest('music');
        formManager.addInterest('sports');

        // Act
        final errors = formManager.validateForm();

        // Assert
        expect(errors, isEmpty);
        expect(formManager.isFormValid, isTrue);
      });

      test('should validate form with missing display name', () {
        // Arrange
        formManager.setUsername('johndoe');
        formManager.setBio('I love music and sports');
        formManager.setGender('male');
        formManager.setAge(25);
        formManager.addInterest('music');

        // Act
        final errors = formManager.validateForm();

        // Assert
        expect(errors.containsKey('displayName'), isTrue);
        expect(errors['displayName'], equals('Display name is required'));
        expect(formManager.isFormValid, isFalse);
      });

      test('should validate form with missing username', () {
        // Arrange
        formManager.setDisplayName('John Doe');
        formManager.setBio('I love music and sports');
        formManager.setGender('male');
        formManager.setAge(25);
        formManager.addInterest('music');

        // Act
        final errors = formManager.validateForm();

        // Assert
        expect(errors.containsKey('username'), isTrue);
        expect(errors['username'], equals('Username is required'));
        expect(formManager.isFormValid, isFalse);
      });

      test('should validate form with short username', () {
        // Arrange
        formManager.setDisplayName('John Doe');
        formManager.setUsername('ab');
        formManager.setBio('I love music and sports');
        formManager.setGender('male');
        formManager.setAge(25);
        formManager.addInterest('music');

        // Act
        final errors = formManager.validateForm();

        // Assert
        expect(errors.containsKey('username'), isTrue);
        expect(errors['username'], equals('Username must be at least 3 characters'));
        expect(formManager.isFormValid, isFalse);
      });

      test('should validate form with missing bio', () {
        // Arrange
        formManager.setDisplayName('John Doe');
        formManager.setUsername('johndoe');
        formManager.setGender('male');
        formManager.setAge(25);
        formManager.addInterest('music');

        // Act
        final errors = formManager.validateForm();

        // Assert
        expect(errors.containsKey('bio'), isTrue);
        expect(errors['bio'], equals('Bio is required'));
        expect(formManager.isFormValid, isFalse);
      });

      test('should validate form with underage user', () {
        // Arrange
        formManager.setDisplayName('John Doe');
        formManager.setUsername('johndoe');
        formManager.setBio('I love music and sports');
        formManager.setGender('male');
        formManager.setAge(17);
        formManager.addInterest('music');

        // Act
        final errors = formManager.validateForm();

        // Assert
        expect(errors.containsKey('age'), isTrue);
        expect(errors['age'], equals('You must be at least 18 years old'));
        expect(formManager.isFormValid, isFalse);
      });

      test('should validate form with no interests', () {
        // Arrange
        formManager.setDisplayName('John Doe');
        formManager.setUsername('johndoe');
        formManager.setBio('I love music and sports');
        formManager.setGender('male');
        formManager.setAge(25);

        // Act
        final errors = formManager.validateForm();

        // Assert
        expect(errors.containsKey('interests'), isTrue);
        expect(errors['interests'], equals('Please select at least one interest'));
        expect(formManager.isFormValid, isFalse);
      });
    });

    group('Form Data Export', () {
      test('should export form data correctly', () {
        // Arrange
        formManager.setDisplayName('John Doe');
        formManager.setUsername('johndoe');
        formManager.setBio('I love music and sports');
        formManager.setGender('male');
        formManager.setAge(25);
        formManager.addInterest('music');
        formManager.addInterest('sports');

        // Act
        final formData = formManager.getFormData();

        // Assert
        expect(formData['displayName'], equals('John Doe'));
        expect(formData['username'], equals('johndoe'));
        expect(formData['bio'], equals('I love music and sports'));
        expect(formData['gender'], equals('male'));
        expect(formData['age'], equals(25));
        expect(formData['interests'], equals(['music', 'sports']));
      });

      test('should trim whitespace from form data', () {
        // Arrange
        formManager.setDisplayName('  John Doe  ');
        formManager.setUsername('  johndoe  ');
        formManager.setBio('  I love music and sports  ');

        // Act
        final formData = formManager.getFormData();

        // Assert
        expect(formData['displayName'], equals('John Doe'));
        expect(formData['username'], equals('johndoe'));
        expect(formData['bio'], equals('I love music and sports'));
      });
    });

    group('Form Reset', () {
      test('should reset form to initial state', () {
        // Arrange
        formManager.setDisplayName('John Doe');
        formManager.setUsername('johndoe');
        formManager.setBio('I love music and sports');
        formManager.setGender('male');
        formManager.setAge(30);
        formManager.addInterest('music');
        formManager.setProfilePicture(File('test.jpg'));
        formManager.addGalleryImage(File('gallery1.jpg'));

        // Act
        formManager.reset();

        // Assert
        expect(formManager.displayName, equals(''));
        expect(formManager.username, equals(''));
        expect(formManager.bio, equals(''));
        expect(formManager.selectedGender, equals('prefer-not-to-say'));
        expect(formManager.age, equals(25));
        expect(formManager.interests, isEmpty);
        expect(formManager.profilePicture, isNull);
        expect(formManager.galleryImages, isEmpty);
        expect(formManager.isUsernameAvailable, isFalse);
        expect(formManager.isCheckingUsername, isFalse);
        expect(formManager.usernameError, isNull);
      });
    });
  });
}
