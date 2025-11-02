import 'package:flutter_test/flutter_test.dart';
import 'package:chatify/main.dart' as app;

/// Test configuration and utilities
class TestConfig {
  /// Initialize test environment
  static void initialize() {
    // Set up any global test configurations here
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Common test data
  static const Map<String, dynamic> testUserJson = {
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

  static const Map<String, dynamic> testFirebaseUserJson = {
    'uid': 'firebase_user_123',
    'displayName': 'Firebase User',
    'email': 'firebase@example.com',
    'photoURL': 'https://example.com/firebase.jpg',
    'isAnonymous': false,
    'createdAt': '2023-01-01T00:00:00Z',
    'updatedAt': '2023-12-01T10:00:00Z',
  };

  static const Map<String, dynamic> testGuestUserJson = {
    'uid': 'guest_123456',
    'userType': 'guest',
    'isAnonymous': true,
    'createdAt': '2023-01-01T00:00:00Z',
    'updatedAt': '2023-12-01T10:00:00Z',
  };

  static const Map<String, dynamic> testProfileData = {
    'displayName': 'Test User',
    'username': 'testuser',
    'bio': 'Test bio',
    'age': 25,
    'gender': 'male',
    'interests': ['music', 'sports'],
  };

  static const List<String> testInterests = [
    'music',
    'sports',
    'travel',
    'photography',
    'cooking',
    'reading',
    'gaming',
    'art',
    'dancing',
    'hiking',
  ];

  static const List<String> testGenders = [
    'male',
    'female',
    'non-binary',
    'prefer-not-to-say',
  ];

  /// Mock API responses
  static const Map<String, dynamic> mockApiSuccessResponse = {
    'success': true,
    'message': 'Operation completed successfully',
    'data': {},
  };

  static const Map<String, dynamic> mockApiErrorResponse = {
    'success': false,
    'message': 'Operation failed',
    'error': 'Error details',
  };

  static const Map<String, dynamic> mockUsernameAvailableResponse = {
    'available': true,
  };

  static const Map<String, dynamic> mockUsernameNotAvailableResponse = {
    'available': false,
  };

  static const Map<String, dynamic> mockSearchResultsResponse = {
    'profiles': [
      {
        'id': 'user1',
        'username': 'user1',
        'displayName': 'User One',
        'age': 25,
        'gender': 'female',
        'interests': ['music', 'sports'],
      },
      {
        'id': 'user2',
        'username': 'user2',
        'displayName': 'User Two',
        'age': 30,
        'gender': 'male',
        'interests': ['travel', 'photography'],
      },
    ],
  };

  static const Map<String, dynamic> mockFriendsResponse = {
    'friends': [
      {
        'id': 'friend1',
        'username': 'friend1',
        'displayName': 'Friend One',
        'profileImage': 'https://example.com/friend1.jpg',
        'isOnline': true,
        'lastSeen': '2023-12-01T10:00:00Z',
      },
      {
        'id': 'friend2',
        'username': 'friend2',
        'displayName': 'Friend Two',
        'profileImage': 'https://example.com/friend2.jpg',
        'isOnline': false,
        'lastSeen': '2023-11-30T15:30:00Z',
      },
    ],
  };

  static const Map<String, dynamic> mockChatHistoryResponse = {
    'messages': [
      {
        'id': 'msg1',
        'senderId': 'user1',
        'content': 'Hello there!',
        'timestamp': '2023-12-01T10:00:00Z',
        'type': 'text',
      },
      {
        'id': 'msg2',
        'senderId': 'user2',
        'content': 'Hi! How are you?',
        'timestamp': '2023-12-01T10:01:00Z',
        'type': 'text',
      },
    ],
  };

  static const Map<String, dynamic> mockCreditBalanceResponse = {
    'balance': 150,
    'lastUpdated': '2023-12-01T10:00:00Z',
  };

  static const Map<String, dynamic> mockAdStatsResponse = {
    'connectCount': 5,
    'pageSwitchCount': 10,
    'dailyAdViews': 3,
    'whoLikedViews': 8,
    'lastAdViewDate': '2023-12-01T10:00:00Z',
  };

  /// Test utilities
  static void expectUserEquals(dynamic actual, Map<String, dynamic> expected) {
    expect(actual.id, equals(expected['id']));
    expect(actual.username, equals(expected['username']));
    expect(actual.email, equals(expected['email']));
    expect(actual.bio, equals(expected['bio']));
    expect(actual.profileImage, equals(expected['profileImage']));
    expect(actual.interests, equals(expected['interests']));
    expect(actual.language, equals(expected['language']));
    expect(actual.location, equals(expected['location']));
    expect(actual.latitude, equals(expected['latitude']));
    expect(actual.longitude, equals(expected['longitude']));
    expect(actual.isOnline, equals(expected['isOnline']));
    expect(actual.isPremium, equals(expected['isPremium']));
    expect(actual.adsFree, equals(expected['adsFree']));
    expect(actual.credits, equals(expected['credits']));
    expect(actual.isBlocked, equals(expected['isBlocked']));
    expect(actual.isFriend, equals(expected['isFriend']));
    expect(actual.deviceId, equals(expected['deviceId']));
    expect(actual.age, equals(expected['age']));
    expect(actual.gender, equals(expected['gender']));
    expect(actual.userType, equals(expected['userType']));
    expect(actual.isVerified, equals(expected['isVerified']));
    expect(actual.connectCount, equals(expected['connectCount']));
    expect(actual.pageSwitchCount, equals(expected['pageSwitchCount']));
    expect(actual.dailyAdViews, equals(expected['dailyAdViews']));
    expect(actual.superLikesUsed, equals(expected['superLikesUsed']));
    expect(actual.boostsUsed, equals(expected['boostsUsed']));
    expect(actual.friendsCount, equals(expected['friendsCount']));
    expect(actual.whoLikedViews, equals(expected['whoLikedViews']));
  }

  static void expectApiResponseEquals(dynamic actual, Map<String, dynamic> expected) {
    expect(actual['success'], equals(expected['success']));
    expect(actual['message'], equals(expected['message']));
    if (expected.containsKey('data')) {
      expect(actual['data'], equals(expected['data']));
    }
  }

  /// Test constants
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration shortTimeout = Duration(seconds: 1);
  static const Duration longTimeout = Duration(seconds: 10);

  /// Test file paths
  static const String testImagePath = 'test/assets/test_image.jpg';
  static const String testVideoPath = 'test/assets/test_video.mp4';
  static const String testAudioPath = 'test/assets/test_audio.mp3';
}
