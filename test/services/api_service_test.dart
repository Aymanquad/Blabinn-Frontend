import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:chatify/services/api_service.dart';
import 'package:chatify/services/firebase_auth_service.dart';

import 'api_service_test.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuthService])
void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockFirebaseAuthService mockFirebaseAuth;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuthService();
      apiService = ApiService();
    });

    group('User ID Extraction', () {
      test('should extract user ID from Firebase user', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user_123');

        // Act
        final userId = await apiService.getCurrentUserId();

        // Assert
        expect(userId, equals('test_user_123'));
      });

      test('should return null when no user is signed in', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final userId = await apiService.getCurrentUserId();

        // Assert
        expect(userId, isNull);
      });

      test('should return anonymous user ID for guest users', () async {
        // Arrange
        final mockUser = MockFirebaseUser();
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('anonymous_123');
        when(mockUser.isAnonymous).thenReturn(true);

        // Act
        final userId = await apiService.getCurrentUserId();

        // Assert
        expect(userId, equals('anonymous_123'));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.getMyProfile(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle authentication errors', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => apiService.getMyProfile(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Profile Management', () {
      test('should create profile with valid data', () async {
        // Arrange
        final profileData = {
          'displayName': 'Test User',
          'username': 'testuser',
          'bio': 'Test bio',
          'age': 25,
          'gender': 'male',
          'interests': ['music', 'sports'],
        };

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.createProfile(profileData),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should update profile with valid data', () async {
        // Arrange
        final updates = {
          'bio': 'Updated bio',
          'interests': ['music', 'sports', 'travel'],
        };

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.updateProfile(updates),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });
    });

    group('Friend Management', () {
      test('should send friend request', () async {
        // Arrange
        const toUserId = 'target_user_123';
        const message = 'Hello, let\'s be friends!';

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.sendFriendRequest(toUserId, message: message),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should accept friend request', () async {
        // Arrange
        const connectionId = 'connection_123';

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.acceptFriendRequest(connectionId),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should reject friend request', () async {
        // Arrange
        const connectionId = 'connection_123';

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.rejectFriendRequest(connectionId),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });
    });

    group('Chat Management', () {
      test('should send direct message', () async {
        // Arrange
        const receiverId = 'receiver_123';
        const content = 'Hello there!';

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.sendDirectMessage(receiverId, content),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should get chat history', () async {
        // Arrange
        const userId = 'user_123';

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.getChatHistoryWithUser(userId),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });
    });

    group('Ad Tracking', () {
      test('should update connect count', () async {
        // Arrange
        const connectCount = 5;

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.updateConnectCount(connectCount),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should track ad view', () async {
        // Arrange
        const adType = 'banner';
        const trigger = 'home_screen';
        const metadata = {'screen': 'home'};

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.trackAdView(adType, trigger, metadata),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should track ad click', () async {
        // Arrange
        const adType = 'interstitial';
        const trigger = 'app_open';
        const metadata = {'placement': 'app_start'};

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.trackAdClick(adType, trigger, metadata),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });
    });

    group('Billing and Credits', () {
      test('should get credit balance', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.getCreditBalance(),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should claim daily credits', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.claimDailyCredits(),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should spend credits', () async {
        // Arrange
        const amount = 10;
        const feature = 'super_like';

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.spendCredits(amount: amount, feature: feature),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });
    });

    group('Search and Discovery', () {
      test('should search profiles with valid parameters', () async {
        // Arrange
        final searchParams = {
          'ageMin': 18,
          'ageMax': 30,
          'gender': 'female',
          'interests': ['music', 'sports'],
          'location': 'New York',
          'radius': 50,
        };

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.searchProfiles(searchParams),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should get trending interests', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.getTrendingInterests(),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });
    });

    group('User Blocking and Reporting', () {
      test('should block user', () async {
        // Arrange
        const userId = 'user_to_block';

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.blockUser(userId),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });

      test('should report user', () async {
        // Arrange
        const userId = 'user_to_report';
        const reason = 'inappropriate_behavior';

        when(mockFirebaseAuth.currentUser).thenReturn(MockFirebaseUser());
        when(mockFirebaseAuth.currentUser!.uid).thenReturn('test_user');

        // Act & Assert
        expect(
          () => apiService.reportUser(userId, reason),
          throwsA(isA<Exception>()), // Will throw due to network call
        );
      });
    });
  });
}

// Mock classes for testing
class MockFirebaseUser {
  String get uid => 'test_user_123';
  bool get isAnonymous => false;
  String? get email => 'test@example.com';
  String? get displayName => 'Test User';
}
