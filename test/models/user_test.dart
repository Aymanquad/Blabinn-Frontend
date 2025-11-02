import 'package:flutter_test/flutter_test.dart';
import 'package:chatify/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('should create user from valid JSON', () {
      // Arrange
      final json = {
        'id': 'test_user_123',
        'username': 'testuser',
        'email': 'test@example.com',
        'bio': 'Test bio',
        'profileImage': 'https://example.com/image.jpg',
        'interests': ['music', 'sports'],
        'language': 'en',
        'location': 'New York',
        'latitude': 40.7128,
        'longitude': -74.0060,
        'isOnline': true,
        'lastSeen': '2023-12-01T10:00:00Z',
        'isPremium': false,
        'adsFree': false,
        'credits': 100,
        'createdAt': '2023-01-01T00:00:00Z',
        'updatedAt': '2023-12-01T10:00:00Z',
        'isBlocked': false,
        'isFriend': false,
        'deviceId': 'device_123',
        'age': 25,
        'gender': 'male',
        'userType': 'registered',
        'isVerified': false,
        'connectCount': 5,
        'pageSwitchCount': 10,
        'dailyAdViews': 3,
        'superLikesUsed': 2,
        'boostsUsed': 1,
        'friendsCount': 15,
        'whoLikedViews': 8,
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, equals('test_user_123'));
      expect(user.username, equals('testuser'));
      expect(user.email, equals('test@example.com'));
      expect(user.bio, equals('Test bio'));
      expect(user.profileImage, equals('https://example.com/image.jpg'));
      expect(user.interests, equals(['music', 'sports']));
      expect(user.language, equals('en'));
      expect(user.location, equals('New York'));
      expect(user.latitude, equals(40.7128));
      expect(user.longitude, equals(-74.0060));
      expect(user.isOnline, isTrue);
      expect(user.isPremium, isFalse);
      expect(user.adsFree, isFalse);
      expect(user.credits, equals(100));
      expect(user.isBlocked, isFalse);
      expect(user.isFriend, isFalse);
      expect(user.deviceId, equals('device_123'));
      expect(user.age, equals(25));
      expect(user.gender, equals('male'));
      expect(user.userType, equals('registered'));
      expect(user.isVerified, isFalse);
      expect(user.connectCount, equals(5));
      expect(user.pageSwitchCount, equals(10));
      expect(user.dailyAdViews, equals(3));
      expect(user.superLikesUsed, equals(2));
      expect(user.boostsUsed, equals(1));
      expect(user.friendsCount, equals(15));
      expect(user.whoLikedViews, equals(8));
    });

    test('should handle Firebase format JSON', () {
      // Arrange
      final json = {
        'uid': 'firebase_user_123',
        'displayName': 'Firebase User',
        'email': 'firebase@example.com',
        'photoURL': 'https://example.com/firebase.jpg',
        'isAnonymous': false,
        'createdAt': '2023-01-01T00:00:00Z',
        'updatedAt': '2023-12-01T10:00:00Z',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, equals('firebase_user_123'));
      expect(user.username, equals('Firebase User'));
      expect(user.email, equals('firebase@example.com'));
      expect(user.profileImage, equals('https://example.com/firebase.jpg'));
      expect(user.isAnonymous, isFalse);
    });

    test('should handle guest user JSON', () {
      // Arrange
      final json = {
        'uid': 'guest_123456',
        'userType': 'guest',
        'isAnonymous': true,
        'createdAt': '2023-01-01T00:00:00Z',
        'updatedAt': '2023-12-01T10:00:00Z',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, equals('guest_123456'));
      expect(user.username, equals('Guest_123456'));
      expect(user.userType, equals('guest'));
      expect(user.isAnonymous, isTrue);
    });

    test('should handle Firestore timestamp format', () {
      // Arrange
      final json = {
        'id': 'timestamp_user',
        'username': 'timestampuser',
        'createdAt': {
          '_seconds': 1672531200, // 2023-01-01T00:00:00Z
        },
        'updatedAt': {
          '_seconds': 1701427200, // 2023-11-30T10:00:00Z
        },
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, equals('timestamp_user'));
      expect(user.username, equals('timestampuser'));
      expect(user.createdAt, equals(DateTime(2023, 1, 1)));
      expect(user.updatedAt, equals(DateTime(2023, 11, 30, 10)));
    });

    test('should throw exception for missing user ID', () {
      // Arrange
      final json = {
        'username': 'testuser',
        'email': 'test@example.com',
      };

      // Act & Assert
      expect(
        () => User.fromJson(json),
        throwsA(isA<Exception>()),
      );
    });

    test('should convert user to JSON correctly', () {
      // Arrange
      final user = User(
        id: 'test_user',
        username: 'testuser',
        email: 'test@example.com',
        bio: 'Test bio',
        profileImage: 'https://example.com/image.jpg',
        interests: ['music', 'sports'],
        language: 'en',
        location: 'New York',
        latitude: 40.7128,
        longitude: -74.0060,
        isOnline: true,
        lastSeen: DateTime(2023, 12, 1, 10),
        isPremium: false,
        adsFree: false,
        credits: 100,
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 12, 1, 10),
        isBlocked: false,
        isFriend: false,
        deviceId: 'device_123',
        age: 25,
        gender: 'male',
        userType: 'registered',
        isVerified: false,
        connectCount: 5,
        pageSwitchCount: 10,
        dailyAdViews: 3,
        superLikesUsed: 2,
        boostsUsed: 1,
        friendsCount: 15,
        whoLikedViews: 8,
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json['id'], equals('test_user'));
      expect(json['username'], equals('testuser'));
      expect(json['email'], equals('test@example.com'));
      expect(json['bio'], equals('Test bio'));
      expect(json['profileImage'], equals('https://example.com/image.jpg'));
      expect(json['interests'], equals(['music', 'sports']));
      expect(json['language'], equals('en'));
      expect(json['location'], equals('New York'));
      expect(json['latitude'], equals(40.7128));
      expect(json['longitude'], equals(-74.0060));
      expect(json['isOnline'], isTrue);
      expect(json['isPremium'], isFalse);
      expect(json['adsFree'], isFalse);
      expect(json['credits'], equals(100));
      expect(json['isBlocked'], isFalse);
      expect(json['isFriend'], isFalse);
      expect(json['deviceId'], equals('device_123'));
      expect(json['age'], equals(25));
      expect(json['gender'], equals('male'));
      expect(json['userType'], equals('registered'));
      expect(json['isVerified'], isFalse);
      expect(json['connectCount'], equals(5));
      expect(json['pageSwitchCount'], equals(10));
      expect(json['dailyAdViews'], equals(3));
      expect(json['superLikesUsed'], equals(2));
      expect(json['boostsUsed'], equals(1));
      expect(json['friendsCount'], equals(15));
      expect(json['whoLikedViews'], equals(8));
    });

    test('should handle copyWith correctly', () {
      // Arrange
      final user = User(
        id: 'test_user',
        username: 'testuser',
        email: 'test@example.com',
        bio: 'Test bio',
        interests: ['music'],
        language: 'en',
        isOnline: false,
        isPremium: false,
        adsFree: false,
        credits: 100,
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
        isBlocked: false,
        isFriend: false,
        userType: 'registered',
        isVerified: false,
        connectCount: 0,
        pageSwitchCount: 0,
        dailyAdViews: 0,
        superLikesUsed: 0,
        boostsUsed: 0,
        friendsCount: 0,
        whoLikedViews: 0,
      );

      // Act
      final updatedUser = user.copyWith(
        username: 'updateduser',
        bio: 'Updated bio',
        interests: ['music', 'sports'],
        isOnline: true,
        credits: 150,
      );

      // Assert
      expect(updatedUser.id, equals('test_user'));
      expect(updatedUser.username, equals('updateduser'));
      expect(updatedUser.email, equals('test@example.com'));
      expect(updatedUser.bio, equals('Updated bio'));
      expect(updatedUser.interests, equals(['music', 'sports']));
      expect(updatedUser.isOnline, isTrue);
      expect(updatedUser.credits, equals(150));
    });

    group('User Helper Methods', () {
      late User user;

      setUp(() {
        user = User(
          id: 'test_user',
          username: 'testuser',
          email: 'test@example.com',
          bio: 'Test bio',
          interests: ['music', 'sports'],
          language: 'en',
          isOnline: true,
          isPremium: true,
          adsFree: true,
          credits: 100,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
          isBlocked: false,
          isFriend: true,
          deviceId: 'device_123',
          age: 25,
          gender: 'male',
          userType: 'registered',
          isVerified: true,
          connectCount: 5,
          pageSwitchCount: 10,
          dailyAdViews: 3,
          superLikesUsed: 2,
          boostsUsed: 1,
          friendsCount: 15,
          whoLikedViews: 8,
        );
      });

      test('isGuest should return false for registered user', () {
        expect(user.isGuest, isFalse);
      });

      test('isGuest should return true for guest user', () {
        final guestUser = user.copyWith(userType: 'guest');
        expect(guestUser.isGuest, isTrue);
      });

      test('hasProfileImage should return true when profile image exists', () {
        final userWithImage = user.copyWith(profileImage: 'https://example.com/image.jpg');
        expect(userWithImage.hasProfileImage, isTrue);
      });

      test('hasProfileImage should return false when profile image is null', () {
        expect(user.hasProfileImage, isFalse);
      });

      test('hasCompletedProfile should return true for complete profile', () {
        expect(user.hasCompletedProfile, isTrue);
      });

      test('hasCompletedProfile should return false for incomplete profile', () {
        final incompleteUser = user.copyWith(bio: '', interests: []);
        expect(incompleteUser.hasCompletedProfile, isFalse);
      });

      test('isPremiumUser should return true for premium user', () {
        expect(user.isPremiumUser, isTrue);
      });

      test('isPremiumUser should return false for non-premium user', () {
        final nonPremiumUser = user.copyWith(isPremium: false);
        expect(nonPremiumUser.isPremiumUser, isFalse);
      });

      test('userTypeBadge should return correct badge for verified user', () {
        expect(user.userTypeBadge, equals('Verified'));
      });

      test('userTypeBadge should return correct badge for guest user', () {
        final guestUser = user.copyWith(userType: 'guest');
        expect(guestUser.userTypeBadge, equals('Guest'));
      });

      test('canMatchWith should return true for valid match', () {
        final otherUser = user.copyWith(id: 'other_user', gender: 'female');
        expect(user.canMatchWith(otherUser), isTrue);
      });

      test('canMatchWith should return false for same gender', () {
        final sameGenderUser = user.copyWith(id: 'other_user');
        expect(user.canMatchWith(sameGenderUser), isFalse);
      });

      test('hasFeatureAccess should return true for premium user', () {
        expect(user.hasFeatureAccess('premium_feature'), isTrue);
      });

      test('hasFeatureAccess should return false for non-premium user', () {
        final nonPremiumUser = user.copyWith(isPremium: false);
        expect(nonPremiumUser.hasFeatureAccess('premium_feature'), isFalse);
      });
    });
  });
}
