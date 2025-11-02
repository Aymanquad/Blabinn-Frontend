/// # API Service Documentation
/// 
/// The `ApiService` class provides a centralized interface for all backend API communications
/// in the Chatify application. It handles authentication, request/response processing,
/// error handling, and provides methods for all major app features.
/// 
/// ## Overview
/// 
/// The API service is implemented as a singleton that manages:
/// - Firebase authentication tokens
/// - HTTP request/response handling
/// - Error parsing and user-friendly messages
/// - Request retry logic
/// - Logging and debugging
/// 
/// ## Authentication
/// 
/// The service uses Firebase Authentication for all API requests. It automatically:
/// - Refreshes Firebase tokens before each request
/// - Handles token expiration and retry logic
/// - Provides fallback authentication strategies
/// 
/// ## Base Configuration
/// 
/// - **Base URL**: Configured via `AppConfig.apiUrl`
/// - **Timeout**: Configured via `AppConfig.apiTimeout`
/// - **Content Type**: `application/json`
/// - **Accept**: `application/json`
/// 
/// ## Error Handling
/// 
/// The service provides comprehensive error handling with:
/// - HTTP status code interpretation
/// - Backend error message parsing
/// - User-friendly error messages
/// - Automatic retry for transient failures
/// 
/// ## Usage Example
/// 
/// ```dart
/// final apiService = ApiService();
/// await apiService.initialize();
/// 
/// try {
///   final profile = await apiService.getMyProfile();
///   print('Profile loaded: ${profile['username']}');
/// } catch (e) {
///   print('Error: $e');
/// }
/// ```

import 'api_service.dart';

/// ## Authentication Methods
/// 
/// These methods handle user authentication and token management.

class ApiServiceAuthDocs {
  /// ### verifyAuth()
  /// 
  /// Verifies the current authentication status with the backend.
  /// 
  /// **Endpoint**: `GET /auth/verify`
  /// 
  /// **Returns**: `Map<String, dynamic>` containing authentication status
  /// 
  /// **Example**:
  /// ```dart
  /// final authStatus = await apiService.verifyAuth();
  /// if (authStatus['authenticated'] == true) {
  ///   print('User is authenticated');
  /// }
  /// ```
  /// 
  /// **Throws**: `Exception` if verification fails
  void verifyAuth() {}

  /// ### logout()
  /// 
  /// Logs out the current user from the backend.
  /// 
  /// **Endpoint**: `POST /auth/logout`
  /// 
  /// **Returns**: `Map<String, dynamic>` containing logout confirmation
  /// 
  /// **Example**:
  /// ```dart
  /// await apiService.logout();
  /// print('User logged out successfully');
  /// ```
  /// 
  /// **Throws**: `Exception` if logout fails
  void logout() {}

  /// ### updateFcmToken(fcmToken)
  /// 
  /// Updates the Firebase Cloud Messaging token for push notifications.
  /// 
  /// **Endpoint**: `PUT /auth/fcm-token`
  /// 
  /// **Parameters**:
  /// - `fcmToken` (String): The FCM token to register
  /// 
  /// **Returns**: `Map<String, dynamic>` containing update confirmation
  /// 
  /// **Example**:
  /// ```dart
  /// await apiService.updateFcmToken('your-fcm-token');
  /// print('FCM token updated');
  /// ```
  /// 
  /// **Throws**: `Exception` if token update fails
  void updateFcmToken() {}
}

/// ## Profile Management Methods
/// 
/// These methods handle user profile operations.

class ApiServiceProfileDocs {
  /// ### getMyProfile()
  /// 
  /// Retrieves the current user's profile information.
  /// 
  /// **Endpoint**: `GET /profiles/me`
  /// 
  /// **Returns**: `Map<String, dynamic>` containing user profile data
  /// 
  /// **Profile Data Structure**:
  /// ```dart
  /// {
  ///   'id': 'user_id',
  ///   'username': 'username',
  ///   'email': 'user@example.com',
  ///   'displayName': 'Display Name',
  ///   'bio': 'User bio',
  ///   'profileImage': 'image_url',
  ///   'interests': ['interest1', 'interest2'],
  ///   'credits': 100,
  ///   'isPremium': false,
  ///   'isOnline': true,
  ///   'createdAt': '2023-01-01T00:00:00Z',
  ///   'updatedAt': '2023-01-01T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final profile = await apiService.getMyProfile();
  /// print('Username: ${profile['username']}');
  /// print('Credits: ${profile['credits']}');
  /// ```
  /// 
  /// **Throws**: `Exception` if profile retrieval fails
  void getMyProfile() {}

  /// ### updateProfile(updates)
  /// 
  /// Updates the current user's profile information.
  /// 
  /// **Endpoint**: `PUT /profiles/me`
  /// 
  /// **Parameters**:
  /// - `updates` (Map<String, dynamic>): Profile fields to update
  /// 
  /// **Updatable Fields**:
  /// - `username`: User's username
  /// - `displayName`: User's display name
  /// - `bio`: User's bio text
  /// - `interests`: List of user interests
  /// - `location`: User's location
  /// - `age`: User's age
  /// - `gender`: User's gender
  /// 
  /// **Returns**: `Map<String, dynamic>` containing updated profile data
  /// 
  /// **Example**:
  /// ```dart
  /// final updates = {
  ///   'bio': 'Updated bio text',
  ///   'interests': ['music', 'travel', 'photography']
  /// };
  /// final updatedProfile = await apiService.updateProfile(updates);
  /// print('Profile updated successfully');
  /// ```
  /// 
  /// **Throws**: `Exception` if profile update fails
  void updateProfile() {}

  /// ### deleteAccount()
  /// 
  /// Permanently deletes the current user's account.
  /// 
  /// **Endpoint**: `DELETE /profiles/me`
  /// 
  /// **Returns**: `Map<String, dynamic>` containing deletion confirmation
  /// 
  /// **Example**:
  /// ```dart
  /// await apiService.deleteAccount();
  /// print('Account deleted successfully');
  /// ```
  /// 
  /// **Throws**: `Exception` if account deletion fails
  /// 
  /// **Warning**: This action is irreversible!
  void deleteAccount() {}

  /// ### checkUsernameAvailability(username)
  /// 
  /// Checks if a username is available for registration.
  /// 
  /// **Endpoint**: `POST /profiles/check-username`
  /// 
  /// **Parameters**:
  /// - `username` (String): Username to check
  /// 
  /// **Returns**: `Map<String, dynamic>` containing availability status
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'available': true,
  ///   'suggestions': ['username1', 'username2'] // if not available
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final result = await apiService.checkUsernameAvailability('newusername');
  /// if (result['available']) {
  ///   print('Username is available');
  /// } else {
  ///   print('Username taken. Suggestions: ${result['suggestions']}');
  /// }
  /// ```
  /// 
  /// **Throws**: `Exception` if check fails
  void checkUsernameAvailability() {}

  /// ### createProfile(profileData)
  /// 
  /// Creates a new user profile.
  /// 
  /// **Endpoint**: `POST /profiles`
  /// 
  /// **Parameters**:
  /// - `profileData` (Map<String, dynamic>): Profile data to create
  /// 
  /// **Required Fields**:
  /// - `username`: User's username
  /// - `displayName`: User's display name
  /// - `email`: User's email address
  /// 
  /// **Optional Fields**:
  /// - `bio`: User's bio text
  /// - `interests`: List of user interests
  /// - `location`: User's location
  /// - `age`: User's age
  /// - `gender`: User's gender
  /// 
  /// **Returns**: `Map<String, dynamic>` containing created profile data
  /// 
  /// **Example**:
  /// ```dart
  /// final profileData = {
  ///   'username': 'newuser',
  ///   'displayName': 'New User',
  ///   'email': 'newuser@example.com',
  ///   'bio': 'Hello world!',
  ///   'interests': ['music', 'travel']
  /// };
  /// final profile = await apiService.createProfile(profileData);
  /// print('Profile created: ${profile['id']}');
  /// ```
  /// 
  /// **Throws**: `Exception` if profile creation fails
  void createProfile() {}

  /// ### getProfileStats()
  /// 
  /// Retrieves statistics for the current user's profile.
  /// 
  /// **Endpoint**: `GET /profiles/me/stats`
  /// 
  /// **Returns**: `Map<String, dynamic>` containing profile statistics
  /// 
  /// **Stats Structure**:
  /// ```dart
  /// {
  ///   'totalConnections': 50,
  ///   'totalMessages': 1000,
  ///   'profileViews': 200,
  ///   'lastActive': '2023-01-01T00:00:00Z',
  ///   'accountAge': 30 // days
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final stats = await apiService.getProfileStats();
  /// print('Total connections: ${stats['totalConnections']}');
  /// print('Profile views: ${stats['profileViews']}');
  /// ```
  /// 
  /// **Throws**: `Exception` if stats retrieval fails
  void getProfileStats() {}

  /// ### searchProfiles(searchParams)
  /// 
  /// Searches for user profiles based on specified criteria.
  /// 
  /// **Endpoint**: `GET /profiles/search`
  /// 
  /// **Parameters**:
  /// - `searchParams` (Map<String, dynamic>): Search criteria
  /// 
  /// **Search Parameters**:
  /// - `query`: Text search query
  /// - `interests`: List of interests to match
  /// - `ageMin`: Minimum age
  /// - `ageMax`: Maximum age
  /// - `gender`: Gender preference
  /// - `location`: Location preference
  /// - `limit`: Maximum number of results (default: 20)
  /// - `offset`: Number of results to skip (default: 0)
  /// 
  /// **Returns**: `List<Map<String, dynamic>>` containing matching profiles
  /// 
  /// **Example**:
  /// ```dart
  /// final searchParams = {
  ///   'interests': ['music', 'travel'],
  ///   'ageMin': 18,
  ///   'ageMax': 30,
  ///   'limit': 10
  /// };
  /// final profiles = await apiService.searchProfiles(searchParams);
  /// print('Found ${profiles.length} matching profiles');
  /// ```
  /// 
  /// **Throws**: `Exception` if search fails
  void searchProfiles() {}

  /// ### getTrendingInterests()
  /// 
  /// Retrieves the current trending interests across the platform.
  /// 
  /// **Endpoint**: `GET /profiles/trending-interests`
  /// 
  /// **Returns**: `List<String>` containing trending interest names
  /// 
  /// **Example**:
  /// ```dart
  /// final trending = await apiService.getTrendingInterests();
  /// print('Trending interests: $trending');
  /// ```
  /// 
  /// **Throws**: `Exception` if retrieval fails
  void getTrendingInterests() {}
}

/// ## Billing and Credits Methods
/// 
/// These methods handle credits, purchases, and billing operations.

class ApiServiceBillingDocs {
  /// ### getCreditBalance()
  /// 
  /// Retrieves the current user's credit balance.
  /// 
  /// **Endpoint**: `GET /billing/credits/balance`
  /// 
  /// **Returns**: `Map<String, dynamic>` containing credit information
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'balance': 100,
  ///   'totalEarned': 500,
  ///   'totalSpent': 400,
  ///   'lastUpdated': '2023-01-01T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final balance = await apiService.getCreditBalance();
  /// print('Current balance: ${balance['balance']} credits');
  /// ```
  /// 
  /// **Throws**: `Exception` if balance retrieval fails
  void getCreditBalance() {}

  /// ### claimDailyCredits()
  /// 
  /// Claims the daily free credits for the current user.
  /// 
  /// **Endpoint**: `POST /billing/credits/claim-daily`
  /// 
  /// **Returns**: `Map<String, dynamic>` containing claim result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'creditsAwarded': 10,
  ///   'newBalance': 110,
  ///   'nextClaimTime': '2023-01-02T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final result = await apiService.claimDailyCredits();
  /// print('Awarded ${result['creditsAwarded']} credits');
  /// print('New balance: ${result['newBalance']}');
  /// ```
  /// 
  /// **Throws**: `Exception` if claim fails or already claimed today
  void claimDailyCredits() {}

  /// ### grantAdCredits({amount, trigger})
  /// 
  /// Grants credits to the user for watching ads.
  /// 
  /// **Endpoint**: `POST /billing/credits/grant-ad`
  /// 
  /// **Parameters**:
  /// - `amount` (int): Number of credits to grant (default: 10)
  /// - `trigger` (String): Trigger identifier (default: 'credit_shop_reward')
  /// 
  /// **Returns**: `Map<String, dynamic>` containing grant result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'creditsAwarded': 10,
  ///   'newBalance': 120,
  ///   'trigger': 'credit_shop_reward'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final result = await apiService.grantAdCredits(
  ///   amount: 15,
  ///   trigger: 'interstitial_ad_completed'
  /// );
  /// print('Granted ${result['creditsAwarded']} credits');
  /// ```
  /// 
  /// **Throws**: `Exception` if grant fails
  void grantAdCredits() {}

  /// ### spendCredits({amount, feature})
  /// 
  /// Spends credits for a specific feature.
  /// 
  /// **Endpoint**: `POST /billing/credits/spend`
  /// 
  /// **Parameters**:
  /// - `amount` (int): Number of credits to spend
  /// - `feature` (String): Feature identifier
  /// 
  /// **Feature Identifiers**:
  /// - `premium_match`: Premium matching feature
  /// - `super_like`: Super like feature
  /// - `boost`: Profile boost feature
  /// - `unlimited_likes`: Unlimited likes feature
  /// 
  /// **Returns**: `Map<String, dynamic>` containing spend result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'creditsSpent': 5,
  ///   'newBalance': 115,
  ///   'feature': 'premium_match',
  ///   'expiresAt': '2023-01-02T00:00:00Z' // if applicable
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final result = await apiService.spendCredits(
  ///   amount: 5,
  ///   feature: 'premium_match'
  /// );
  /// print('Spent ${result['creditsSpent']} credits');
  /// print('New balance: ${result['newBalance']}');
  /// ```
  /// 
  /// **Throws**: `Exception` if spend fails or insufficient credits
  void spendCredits() {}

  /// ### verifyPurchase({platform, productId, purchaseType, purchaseToken, orderId})
  /// 
  /// Verifies a purchase with the backend for credits or premium features.
  /// 
  /// **Endpoint**: `POST /billing/verify`
  /// 
  /// **Parameters**:
  /// - `platform` (String): Platform identifier ('android' | 'ios')
  /// - `productId` (String): Product identifier
  /// - `purchaseType` (String): Purchase type ('consumable' | 'subscription')
  /// - `purchaseToken` (String?): Purchase token from platform
  /// - `orderId` (String?): Order ID from platform
  /// 
  /// **Product ID Examples**:
  /// - `8248-1325-3123-2424-credits-70`: 70 credits pack
  /// - `8248-1325-3123-2424-premium-monthly`: Monthly premium subscription
  /// 
  /// **Returns**: `Map<String, dynamic>` containing verification result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'verified': true,
  ///   'creditsAwarded': 70, // for credit purchases
  ///   'premiumActivated': true, // for premium purchases
  ///   'expiresAt': '2023-02-01T00:00:00Z', // for subscriptions
  ///   'newBalance': 170
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final result = await apiService.verifyPurchase(
  ///   platform: 'android',
  ///   productId: '8248-1325-3123-2424-credits-70',
  ///   purchaseType: 'consumable',
  ///   purchaseToken: 'purchase_token_here',
  ///   orderId: 'order_id_here'
  /// );
  /// if (result['verified']) {
  ///   print('Purchase verified successfully');
  /// }
  /// ```
  /// 
  /// **Throws**: `Exception` if verification fails
  void verifyPurchase() {}
}

/// ## File Upload Methods
/// 
/// These methods handle file uploads for profile pictures and gallery images.

class ApiServiceUploadDocs {
  /// ### uploadProfilePicture(imageFile)
  /// 
  /// Uploads a profile picture for the current user.
  /// 
  /// **Endpoint**: `POST /upload/profile-picture`
  /// 
  /// **Parameters**:
  /// - `imageFile` (File): The image file to upload
  /// 
  /// **Supported Formats**: JPEG, PNG, WebP
  /// **Maximum Size**: 5MB
  /// **Recommended Dimensions**: 400x400 pixels
  /// 
  /// **Returns**: `Map<String, dynamic>` containing upload result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'url': 'https://storage.example.com/profile-pictures/user_id.jpg',
  ///   'filename': 'user_id.jpg',
  ///   'size': 1024000,
  ///   'uploadedAt': '2023-01-01T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final imageFile = File('/path/to/image.jpg');
  /// final result = await apiService.uploadProfilePicture(imageFile);
  /// print('Profile picture uploaded: ${result['url']}');
  /// ```
  /// 
  /// **Throws**: `Exception` if upload fails
  void uploadProfilePicture() {}

  /// ### loadGallery()
  /// 
  /// Retrieves the current user's gallery images.
  /// 
  /// **Endpoint**: `GET /profiles/me/gallery`
  /// 
  /// **Returns**: `Map<String, dynamic>` containing gallery data
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'images': [
  ///     {
  ///       'id': 'image_id',
  ///       'url': 'https://storage.example.com/gallery/image_id.jpg',
  ///       'filename': 'image_id.jpg',
  ///       'isMain': true,
  ///       'uploadedAt': '2023-01-01T00:00:00Z',
  ///       'size': 1024000
  ///     }
  ///   ],
  ///   'totalCount': 5,
  ///   'maxImages': 10
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final gallery = await apiService.loadGallery();
  /// print('Gallery has ${gallery['totalCount']} images');
  /// for (final image in gallery['images']) {
  ///   print('Image: ${image['url']}');
  /// }
  /// ```
  /// 
  /// **Throws**: `Exception` if gallery retrieval fails
  void loadGallery() {}

  /// ### setMainPicture(filename)
  /// 
  /// Sets a gallery image as the main profile picture.
  /// 
  /// **Endpoint**: `PUT /profiles/me/gallery/{filename}/main`
  /// 
  /// **Parameters**:
  /// - `filename` (String): Filename of the image to set as main
  /// 
  /// **Returns**: `Map<String, dynamic>` containing update result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'newMainPicture': 'https://storage.example.com/gallery/filename.jpg',
  ///   'updatedAt': '2023-01-01T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// await apiService.setMainPicture('image_id.jpg');
  /// print('Main picture updated successfully');
  /// ```
  /// 
  /// **Throws**: `Exception` if update fails
  void setMainPicture() {}

  /// ### removeGalleryPicture(filename)
  /// 
  /// Removes an image from the user's gallery.
  /// 
  /// **Endpoint**: `DELETE /profiles/me/gallery/{filename}`
  /// 
  /// **Parameters**:
  /// - `filename` (String): Filename of the image to remove
  /// 
  /// **Returns**: `Map<String, dynamic>` containing removal result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'removedFilename': 'image_id.jpg',
  ///   'remainingCount': 4
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// await apiService.removeGalleryPicture('image_id.jpg');
  /// print('Image removed from gallery');
  /// ```
  /// 
  /// **Throws**: `Exception` if removal fails
  void removeGalleryPicture() {}
}

/// ## Connection and Friend Methods
/// 
/// These methods handle friend requests and connections.

class ApiServiceConnectionDocs {
  /// ### sendFriendRequest(toUserId, {message, type})
  /// 
  /// Sends a friend request to another user.
  /// 
  /// **Endpoint**: `POST /connections/friend-request`
  /// 
  /// **Parameters**:
  /// - `toUserId` (String): ID of the user to send request to
  /// - `message` (String?): Optional message with the request
  /// - `type` (String?): Request type identifier
  /// 
  /// **Returns**: `Map<String, dynamic>` containing request result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'requestId': 'request_id',
  ///   'toUserId': 'user_id',
  ///   'message': 'Hello!',
  ///   'sentAt': '2023-01-01T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// final result = await apiService.sendFriendRequest(
  ///   'user_id_here',
  ///   message: 'Hi! I\'d like to connect with you.'
  /// );
  /// print('Friend request sent: ${result['requestId']}');
  /// ```
  /// 
  /// **Throws**: `Exception` if request fails
  void sendFriendRequest() {}

  /// ### acceptFriendRequest(connectionId)
  /// 
  /// Accepts an incoming friend request.
  /// 
  /// **Endpoint**: `PUT /connections/friend-request/{connectionId}/accept`
  /// 
  /// **Parameters**:
  /// - `connectionId` (String): ID of the connection request
  /// 
  /// **Returns**: `Map<String, dynamic>` containing acceptance result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'connectionId': 'connection_id',
  ///   'friendId': 'friend_user_id',
  ///   'acceptedAt': '2023-01-01T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// await apiService.acceptFriendRequest('connection_id_here');
  /// print('Friend request accepted');
  /// ```
  /// 
  /// **Throws**: `Exception` if acceptance fails
  void acceptFriendRequest() {}

  /// ### rejectFriendRequest(connectionId)
  /// 
  /// Rejects an incoming friend request.
  /// 
  /// **Endpoint**: `PUT /connections/friend-request/{connectionId}/reject`
  /// 
  /// **Parameters**:
  /// - `connectionId` (String): ID of the connection request
  /// 
  /// **Returns**: `Map<String, dynamic>` containing rejection result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'connectionId': 'connection_id',
  ///   'rejectedAt': '2023-01-01T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// await apiService.rejectFriendRequest('connection_id_here');
  /// print('Friend request rejected');
  /// ```
  /// 
  /// **Throws**: `Exception` if rejection fails
  void rejectFriendRequest() {}

  /// ### cancelFriendRequest(connectionId)
  /// 
  /// Cancels an outgoing friend request.
  /// 
  /// **Endpoint**: `PUT /connections/friend-request/{connectionId}/cancel`
  /// 
  /// **Parameters**:
  /// - `connectionId` (String): ID of the connection request
  /// 
  /// **Returns**: `Map<String, dynamic>` containing cancellation result
  /// 
  /// **Response Structure**:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'connectionId': 'connection_id',
  ///   'cancelledAt': '2023-01-01T00:00:00Z'
  /// }
  /// ```
  /// 
  /// **Example**:
  /// ```dart
  /// await apiService.cancelFriendRequest('connection_id_here');
  /// print('Friend request cancelled');
  /// ```
  /// 
  /// **Throws**: `Exception` if cancellation fails
  void cancelFriendRequest() {}
}

/// ## Error Handling
/// 
/// The API service provides comprehensive error handling with user-friendly messages.
/// 
/// ### Common Error Scenarios
/// 
/// 1. **Authentication Errors (401)**
///    - Token expired or invalid
///    - User not authenticated
///    - Solution: Refresh token or re-authenticate
/// 
/// 2. **Permission Errors (403)**
///    - User doesn't have permission for the action
///    - Account suspended or restricted
///    - Solution: Check user permissions
/// 
/// 3. **Not Found Errors (404)**
///    - Resource doesn't exist
///    - User profile not found
///    - Solution: Verify resource exists
/// 
/// 4. **Rate Limiting (429)**
///    - Too many requests
///    - Solution: Wait and retry
/// 
/// 5. **Server Errors (5xx)**
///    - Backend service issues
///    - Solution: Retry later
/// 
/// ### Error Response Format
/// 
/// ```dart
/// {
///   'error': 'error_code',
///   'message': 'Human readable error message',
///   'details': 'Additional error details',
///   'timestamp': '2023-01-01T00:00:00Z'
/// }
/// ```
/// 
/// ### Retry Logic
/// 
/// The service automatically retries failed requests with exponential backoff:
/// - First retry: 1 second delay
/// - Second retry: 2 second delay
/// - Third retry: 4 second delay
/// 
/// Retries are only attempted for transient errors (5xx, network issues).

/// ## Best Practices
/// 
/// ### 1. Error Handling
/// ```dart
/// try {
///   final result = await apiService.getMyProfile();
///   // Handle success
/// } catch (e) {
///   // Handle error
///   print('Error: $e');
/// }
/// ```
/// 
/// ### 2. Token Management
/// The service automatically handles token refresh, but you should:
/// - Initialize the service before use
/// - Handle authentication errors gracefully
/// - Re-authenticate if needed
/// 
/// ### 3. Request Optimization
/// - Use appropriate endpoints for your needs
/// - Implement caching for frequently accessed data
/// - Handle network connectivity issues
/// 
/// ### 4. Security
/// - Never expose API tokens in client code
/// - Use HTTPS for all requests
/// - Validate user input before sending requests
