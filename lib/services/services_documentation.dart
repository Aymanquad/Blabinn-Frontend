/// # Services Documentation
/// 
/// This document provides comprehensive documentation for all services used in the Chatify application.
/// Services handle business logic, API communication, and external integrations.

/// ## API Service
/// 
/// The `ApiService` is the central service for all backend API communications.
/// 
/// ### Key Features
/// - Firebase authentication integration
/// - Automatic token refresh
/// - Comprehensive error handling
/// - Request/response logging
/// - Retry logic for failed requests
/// 
/// ### Usage Example
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
/// 
/// ### Main Methods
/// - `getMyProfile()`: Get current user profile
/// - `updateProfile(updates)`: Update user profile
/// - `sendFriendRequest(userId)`: Send friend request
/// - `getChats()`: Get user's chats
/// - `sendMessage(chatId, content)`: Send message
/// - `uploadProfilePicture(file)`: Upload profile picture
/// - `getCreditBalance()`: Get credit balance
/// - `spendCredits(amount, feature)`: Spend credits

/// ## Auth Service
/// 
/// The `AuthService` handles user authentication using Firebase.
/// 
/// ### Key Features
/// - Firebase Authentication integration
/// - Google Sign-In support
/// - Apple Sign-In support
/// - Guest authentication
/// - Token management
/// - Auth state monitoring
/// 
/// ### Usage Example
/// ```dart
/// final authService = AuthService();
/// await authService.initialize();
/// 
/// // Sign in with Google
/// final result = await authService.signInWithGoogle();
/// if (result.user != null) {
///   print('Signed in: ${result.user!.username}');
/// }
/// ```
/// 
/// ### Main Methods
/// - `signInWithGoogle()`: Sign in with Google
/// - `signInWithApple()`: Sign in with Apple
/// - `signInAsGuest()`: Sign in as guest
/// - `signOut()`: Sign out user
/// - `getCurrentUser()`: Get current user
/// - `getIdToken()`: Get Firebase ID token
/// - `authStateChanges`: Stream of auth state changes

/// ## Socket Service
/// 
/// The `SocketService` handles real-time communication using Socket.IO.
/// 
/// ### Key Features
/// - Real-time messaging
/// - User status updates
/// - Typing indicators
/// - Match notifications
/// - Connection management
/// - Automatic reconnection
/// 
/// ### Usage Example
/// ```dart
/// final socketService = SocketService();
/// await socketService.initialize();
/// 
/// // Listen to messages
/// socketService.messageStream.listen((message) {
///   print('New message: ${message.content}');
/// });
/// 
/// // Send message
/// await socketService.sendMessage('chat_123', 'Hello!');
/// ```
/// 
/// ### Main Methods
/// - `connect()`: Connect to socket server
/// - `disconnect()`: Disconnect from server
/// - `sendMessage(chatId, content)`: Send message
/// - `joinChat(chatId)`: Join chat room
/// - `leaveChat(chatId)`: Leave chat room
/// - `sendTyping(chatId)`: Send typing indicator
/// - `startMatching()`: Start matching process
/// - `stopMatching()`: Stop matching process

/// ## Notification Service
/// 
/// The `NotificationService` handles push notifications and local notifications.
/// 
/// ### Key Features
/// - Firebase Cloud Messaging integration
/// - Local notifications
/// - Notification scheduling
/// - Badge management
/// - Permission handling
/// - Notification actions
/// 
/// ### Usage Example
/// ```dart
/// final notificationService = NotificationService();
/// await notificationService.initialize();
/// 
/// // Request permissions
/// final granted = await notificationService.requestPermissions();
/// if (granted) {
///   print('Notification permissions granted');
/// }
/// 
/// // Show local notification
/// await notificationService.showLocalNotification(
///   title: 'New Message',
///   body: 'You have a new message',
/// );
/// ```
/// 
/// ### Main Methods
/// - `initialize()`: Initialize notification service
/// - `requestPermissions()`: Request notification permissions
/// - `showLocalNotification(title, body)`: Show local notification
/// - `scheduleNotification(title, body, scheduledTime)`: Schedule notification
/// - `cancelNotification(id)`: Cancel notification
/// - `clearAllNotifications()`: Clear all notifications
/// - `setBadgeCount(count)`: Set app badge count

/// ## Billing Service
/// 
/// The `BillingService` handles in-app purchases and billing.
/// 
/// ### Key Features
/// - Google Play Billing integration
/// - App Store Connect integration
/// - Purchase verification
/// - Subscription management
/// - Receipt validation
/// - Purchase restoration
/// 
/// ### Usage Example
/// ```dart
/// final billingService = BillingService();
/// await billingService.initialize();
/// 
/// // Purchase credits
/// final result = await billingService.purchaseCredits(100);
/// if (result.success) {
///   print('Credits purchased successfully');
/// }
/// ```
/// 
/// ### Main Methods
/// - `initialize()`: Initialize billing service
/// - `purchaseCredits(amount)`: Purchase credits
/// - `purchasePremium(duration)`: Purchase premium subscription
/// - `restorePurchases()`: Restore previous purchases
/// - `getAvailableProducts()`: Get available products
/// - `verifyPurchase(purchase)`: Verify purchase with backend

/// ## Ad Service
/// 
/// The `AdService` handles Google AdMob integration.
/// 
/// ### Key Features
/// - Banner ads
/// - Interstitial ads
/// - Rewarded ads
/// - Ad loading and display
/// - Ad event handling
/// - Revenue tracking
/// 
/// ### Usage Example
/// ```dart
/// final adService = AdService();
/// await adService.initialize();
/// 
/// // Show banner ad
/// final bannerAd = await adService.createBannerAd();
/// 
/// // Show interstitial ad
/// await adService.showInterstitialAd();
/// 
/// // Show rewarded ad
/// final result = await adService.showRewardedAd();
/// if (result.rewarded) {
///   print('User earned ${result.amount} credits');
/// }
/// ```
/// 
/// ### Main Methods
/// - `initialize()`: Initialize AdMob
/// - `createBannerAd()`: Create banner ad
/// - `showInterstitialAd()`: Show interstitial ad
/// - `showRewardedAd()`: Show rewarded ad
/// - `loadAd(adId)`: Load specific ad
/// - `disposeAd(ad)`: Dispose ad resources

/// ## Image Cache Service
/// 
/// The `ImageCacheService` provides advanced image caching capabilities.
/// 
/// ### Key Features
/// - Multi-level caching (memory + disk)
/// - Thumbnail generation
/// - Automatic cache cleanup
/// - Cache statistics
/// - Image preloading
/// - Memory management
/// 
/// ### Usage Example
/// ```dart
/// final cacheService = ImageCacheService();
/// await cacheService.initialize();
/// 
/// // Cache image
/// final imageData = await cacheService.cacheImage('https://example.com/image.jpg');
/// 
/// // Get cached image
/// final cachedImage = await cacheService.getImage('https://example.com/image.jpg');
/// 
/// // Get cache statistics
/// final stats = await cacheService.getCacheStats();
/// print('Cache size: ${stats.formattedSize}');
/// ```
/// 
/// ### Main Methods
/// - `initialize()`: Initialize cache service
/// - `cacheImage(url, type)`: Cache image from URL
/// - `getImage(url, type)`: Get cached image
/// - `getOrCacheImage(url, type)`: Get or cache image
/// - `clearImage(url, type)`: Clear specific image
/// - `clearCache(type)`: Clear all cache
/// - `getCacheStats()`: Get cache statistics
/// - `preloadImages(urls, type)`: Preload multiple images

/// ## Image Preloader Service
/// 
/// The `ImagePreloader` service provides proactive image loading.
/// 
/// ### Key Features
/// - Batch image preloading
/// - Smart preloading strategies
/// - Preload statistics
/// - Memory management
/// - Error handling
/// 
/// ### Usage Example
/// ```dart
/// final preloader = ImagePreloader();
/// 
/// // Preload single image
/// await preloader.preloadImage('https://example.com/image.jpg');
/// 
/// // Preload multiple images
/// await preloader.preloadImages([
///   'https://example.com/image1.jpg',
///   'https://example.com/image2.jpg',
/// ]);
/// 
/// // Preload profile images
/// await preloader.preloadProfileImages(users);
/// ```
/// 
/// ### Main Methods
/// - `preloadImage(url, type)`: Preload single image
/// - `preloadImages(urls, type)`: Preload multiple images
/// - `preloadProfileImages(users)`: Preload user profile images
/// - `preloadGalleryImages(urls)`: Preload gallery images
/// - `preloadChatImages(urls)`: Preload chat images
/// - `isPreloaded(url)`: Check if image is preloaded
/// - `getStats()`: Get preload statistics

/// ## Firebase Auth Service
/// 
/// The `FirebaseAuthService` provides Firebase Authentication integration.
/// 
/// ### Key Features
/// - Firebase Authentication
/// - Google Sign-In
/// - Apple Sign-In
/// - Anonymous authentication
/// - Token management
/// - Auth state monitoring
/// 
/// ### Usage Example
/// ```dart
/// final firebaseAuth = FirebaseAuthService();
/// 
/// // Sign in with Google
/// final user = await firebaseAuth.signInWithGoogle();
/// 
/// // Get current user
/// final currentUser = firebaseAuth.currentUser;
/// 
/// // Listen to auth changes
/// firebaseAuth.authStateChanges.listen((user) {
///   if (user != null) {
///     print('User signed in: ${user.uid}');
///   } else {
///     print('User signed out');
///   }
/// });
/// ```
/// 
/// ### Main Methods
/// - `signInWithGoogle()`: Sign in with Google
/// - `signInWithApple()`: Sign in with Apple
/// - `signInAnonymously()`: Sign in anonymously
/// - `signOut()`: Sign out user
/// - `getCurrentUser()`: Get current user
/// - `getIdToken()`: Get ID token
/// - `authStateChanges`: Stream of auth state changes

/// ## Premium Service
/// 
/// The `PremiumService` handles premium features and subscriptions.
/// 
/// ### Key Features
/// - Premium status checking
/// - Feature access control
/// - Subscription management
/// - Premium benefits
/// - Usage tracking
/// 
/// ### Usage Example
/// ```dart
/// final premiumService = PremiumService();
/// 
/// // Check premium status
/// final isPremium = await premiumService.isPremium();
/// if (isPremium) {
///   print('User has premium access');
/// }
/// 
/// // Check feature access
/// final canAccess = await premiumService.canAccessFeature('premium_matching');
/// if (canAccess) {
///   // Use premium feature
/// }
/// ```
/// 
/// ### Main Methods
/// - `isPremium()`: Check if user has premium
/// - `canAccessFeature(feature)`: Check feature access
/// - `getPremiumFeatures()`: Get available premium features
/// - `getSubscriptionInfo()`: Get subscription information
/// - `upgradeToPremium()`: Upgrade to premium
/// - `cancelSubscription()`: Cancel subscription

/// ## Global Matching Service
/// 
/// The `GlobalMatchingService` handles the matching system.
/// 
/// ### Key Features
/// - Global matching state
/// - Match notifications
/// - Queue management
/// - Filter management
/// - Session management
/// 
/// ### Usage Example
/// ```dart
/// final matchingService = GlobalMatchingService();
/// 
/// // Start matching
/// await matchingService.startMatching();
/// 
/// // Listen to matches
/// matchingService.matchStream.listen((match) {
///   print('Match found: ${match['participantId']}');
/// });
/// 
/// // Set filters
/// matchingService.setFilters({
///   'ageRange': [18, 30],
///   'interests': ['music', 'travel'],
/// });
/// ```
/// 
/// ### Main Methods
/// - `startMatching()`: Start matching process
/// - `stopMatching()`: Stop matching process
/// - `setFilters(filters)`: Set matching filters
/// - `getQueueTime()`: Get current queue time
/// - `isMatching()`: Check if currently matching
/// - `matchStream`: Stream of match events

/// ## Service Best Practices
/// 
/// ### 1. Initialization
/// Always initialize services before use:
/// 
/// ```dart
/// final service = SomeService();
/// await service.initialize();
/// ```
/// 
/// ### 2. Error Handling
/// Handle errors gracefully:
/// 
/// ```dart
/// try {
///   final result = await service.performAction();
///   // Handle success
/// } catch (e) {
///   // Handle error
///   print('Error: $e');
/// }
/// ```
/// 
/// ### 3. Resource Management
/// Dispose resources when done:
/// 
/// ```dart
/// @override
/// void dispose() {
///   service.dispose();
///   super.dispose();
/// }
/// ```
/// 
/// ### 4. State Management
/// Use services with state management:
/// 
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   _MyWidgetState createState() => _MyWidgetState();
/// }
/// 
/// class _MyWidgetState extends State<MyWidget> {
///   final _service = SomeService();
///   
///   @override
///   void initState() {
///     super.initState();
///     _initializeService();
///   }
///   
///   Future<void> _initializeService() async {
///     await _service.initialize();
///     // Set up listeners
///   }
///   
///   @override
///   void dispose() {
///     _service.dispose();
///     super.dispose();
///   }
/// }
/// ```
/// 
/// ### 5. Testing
/// Mock services for testing:
/// 
/// ```dart
/// class MockApiService extends Mock implements ApiService {}
/// 
/// test('should load profile', () async {
///   final mockApiService = MockApiService();
///   when(mockApiService.getMyProfile()).thenAnswer(
///     (_) async => {'username': 'test_user'},
///   );
///   
///   final profile = await mockApiService.getMyProfile();
///   expect(profile['username'], equals('test_user'));
/// });
/// ```

/// ## Service Dependencies
/// 
/// ### Core Dependencies
/// - `ApiService` depends on `FirebaseAuthService`
/// - `SocketService` depends on `ApiService`
/// - `NotificationService` depends on `ApiService`
/// - `BillingService` depends on `ApiService`
/// 
/// ### External Dependencies
/// - Firebase Authentication
/// - Firebase Cloud Messaging
/// - Google Play Billing
/// - App Store Connect
/// - Google AdMob
/// - Socket.IO
/// 
/// ### Internal Dependencies
/// - Logger utility
/// - Global error handler
/// - App configuration
/// - Models

/// ## Service Lifecycle
/// 
/// ### 1. Initialization
/// Services are initialized when the app starts or when first used.
/// 
/// ### 2. Active State
/// Services remain active during app usage and handle requests.
/// 
/// ### 3. Background State
/// Some services continue running in the background (notifications, sockets).
/// 
/// ### 4. Disposal
/// Services are disposed when the app is closed or when no longer needed.
