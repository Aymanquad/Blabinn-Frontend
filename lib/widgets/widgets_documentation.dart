/// # Widgets Documentation
/// 
/// This document provides comprehensive documentation for all custom widgets and UI components
/// used in the Chatify application.

/// ## Optimized Image Widgets
/// 
/// These widgets provide advanced image loading and caching capabilities.

/// ### OptimizedImage
/// 
/// A smart image widget with multiple loading strategies and caching.
/// 
/// **Properties:**
/// - `imageUrl` (String): URL of the image to load
/// - `width` (double?): Image width
/// - `height` (double?): Image height
/// - `fit` (BoxFit): How to fit the image (default: BoxFit.cover)
/// - `placeholder` (Widget?): Widget to show while loading
/// - `errorWidget` (Widget?): Widget to show on error
/// - `imageType` (ImageType): Type of image for caching strategy
/// - `enableMemoryCache` (bool): Enable memory caching (default: true)
/// - `enableDiskCache` (bool): Enable disk caching (default: true)
/// - `enableThumbnail` (bool): Enable thumbnail generation (default: false)
/// - `thumbnailWidth` (int?): Thumbnail width
/// - `thumbnailHeight` (int?): Thumbnail height
/// - `borderRadius` (BorderRadius?): Image border radius
/// - `boxShadow` (List<BoxShadow>?): Image shadow
/// - `backgroundColor` (Color?): Background color
/// - `fadeInDuration` (Duration): Fade-in animation duration
/// - `enableFadeIn` (bool): Enable fade-in animation (default: true)
/// 
/// **Usage Example:**
/// ```dart
/// OptimizedImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
///   fit: BoxFit.cover,
///   placeholder: CircularProgressIndicator(),
///   errorWidget: Icon(Icons.broken_image),
///   borderRadius: BorderRadius.circular(12),
///   enableThumbnail: true,
///   thumbnailWidth: 100,
///   thumbnailHeight: 100,
/// )
/// ```

/// ### OptimizedProfileImage
/// 
/// A circular profile image widget with fallback support.
/// 
/// **Properties:**
/// - `imageUrl` (String?): URL of the profile image
/// - `size` (double): Size of the circular image (default: 50)
/// - `fallbackText` (String?): Text to show when image fails to load
/// - `backgroundColor` (Color?): Background color for fallback
/// - `textColor` (Color?): Text color for fallback
/// - `enableCache` (bool): Enable caching (default: true)
/// 
/// **Usage Example:**
/// ```dart
/// OptimizedProfileImage(
///   imageUrl: user.profileImage,
///   size: 60,
///   fallbackText: user.username[0].toUpperCase(),
///   backgroundColor: Colors.blue,
///   textColor: Colors.white,
/// )
/// ```

/// ### OptimizedGalleryImage
/// 
/// A gallery image widget with thumbnail support.
/// 
/// **Properties:**
/// - `imageUrl` (String): URL of the gallery image
/// - `width` (double?): Image width
/// - `height` (double?): Image height
/// - `onTap` (VoidCallback?): Callback when image is tapped
/// - `enableThumbnail` (bool): Enable thumbnail generation (default: true)
/// 
/// **Usage Example:**
/// ```dart
/// OptimizedGalleryImage(
///   imageUrl: 'https://example.com/gallery/image.jpg',
///   width: 150,
///   height: 150,
///   onTap: () => showFullScreenImage(),
///   enableThumbnail: true,
/// )
/// ```

/// ### OptimizedChatImage
/// 
/// A chat image widget optimized for messaging.
/// 
/// **Properties:**
/// - `imageUrl` (String): URL of the chat image
/// - `width` (double?): Image width
/// - `height` (double?): Image height
/// - `onTap` (VoidCallback?): Callback when image is tapped
/// 
/// **Usage Example:**
/// ```dart
/// OptimizedChatImage(
///   imageUrl: 'https://example.com/chat/image.jpg',
///   width: 200,
///   height: 200,
///   onTap: () => showFullScreenImage(),
/// )
/// ```

/// ## State Management Widgets
/// 
/// These widgets provide granular state management with efficient rebuilding.

/// ### StateSelector<T>
/// 
/// A widget that rebuilds only when specific parts of the state change.
/// 
/// **Properties:**
/// - `notifier` (ValueNotifier<T>): The state notifier to listen to
/// - `builder` (Widget Function(BuildContext, T)): Builder function
/// - `initialValue` (T?): Initial value for the notifier
/// 
/// **Usage Example:**
/// ```dart
/// StateSelector<String>(
///   notifier: AppState().username,
///   builder: (context, username) {
///     return Text('Hello $username');
///   },
/// )
/// ```

/// ### UserSelector
/// 
/// A widget that rebuilds only when the current user changes.
/// 
/// **Properties:**
/// - `builder` (Widget Function(BuildContext, User?)): Builder function
/// 
/// **Usage Example:**
/// ```dart
/// UserSelector(
///   builder: (context, user) {
///     if (user == null) {
///       return LoginScreen();
///     }
///     return ProfileScreen(user: user);
///   },
/// )
/// ```

/// ### AuthSelector
/// 
/// A widget that rebuilds only when authentication status changes.
/// 
/// **Properties:**
/// - `builder` (Widget Function(BuildContext, bool)): Builder function
/// 
/// **Usage Example:**
/// ```dart
/// AuthSelector(
///   builder: (context, isAuthenticated) {
///     return isAuthenticated ? HomeScreen() : LoginScreen();
///   },
/// )
/// ```

/// ### CreditsSelector
/// 
/// A widget that rebuilds only when credits change.
/// 
/// **Properties:**
/// - `builder` (Widget Function(BuildContext, int)): Builder function
/// 
/// **Usage Example:**
/// ```dart
/// CreditsSelector(
///   builder: (context, credits) {
///     return Text('Credits: $credits');
///   },
/// )
/// ```

/// ### ChatsSelector
/// 
/// A widget that rebuilds only when chats list changes.
/// 
/// **Properties:**
/// - `builder` (Widget Function(BuildContext, List<Chat>)): Builder function
/// 
/// **Usage Example:**
/// ```dart
/// ChatsSelector(
///   builder: (context, chats) {
///     return ListView.builder(
///       itemCount: chats.length,
///       itemBuilder: (context, index) {
///         return ChatItem(chat: chats[index]);
///       },
///     );
///   },
/// )
/// ```

/// ### UnreadCountSelector
/// 
/// A widget that rebuilds only when total unread count changes.
/// 
/// **Properties:**
/// - `builder` (Widget Function(BuildContext, int)): Builder function
/// 
/// **Usage Example:**
/// ```dart
/// UnreadCountSelector(
///   builder: (context, unreadCount) {
///     return Badge(
///       count: unreadCount,
///       child: Icon(Icons.chat),
///     );
///   },
/// )
/// ```

/// ## UI Component Widgets
/// 
/// These widgets provide reusable UI components.

/// ### GlassContainer
/// 
/// A container with glass morphism effect.
/// 
/// **Properties:**
/// - `child` (Widget): Child widget
/// - `blur` (double): Blur intensity (default: 10.0)
/// - `opacity` (double): Background opacity (default: 0.1)
/// - `borderRadius` (BorderRadius?): Border radius
/// - `border` (Border?): Border
/// - `gradient` (Gradient?): Background gradient
/// 
/// **Usage Example:**
/// ```dart
/// GlassContainer(
///   blur: 15.0,
///   opacity: 0.2,
///   borderRadius: BorderRadius.circular(16),
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Glass effect'),
///   ),
/// )
/// ```

/// ### BannerAdWidget
/// 
/// A widget for displaying banner ads.
/// 
/// **Properties:**
/// - `height` (double): Ad height (default: 50)
/// - `margin` (EdgeInsets?): Ad margin
/// - `onAdLoaded` (VoidCallback?): Callback when ad loads
/// - `onAdFailedToLoad` (VoidCallback?): Callback when ad fails to load
/// 
/// **Usage Example:**
/// ```dart
/// BannerAdWidget(
///   height: 60,
///   margin: EdgeInsets.all(16),
///   onAdLoaded: () => print('Ad loaded'),
///   onAdFailedToLoad: () => print('Ad failed to load'),
/// )
/// ```

/// ### SkeletonList
/// 
/// A skeleton loading widget for lists.
/// 
/// **Properties:**
/// - `itemCount` (int): Number of skeleton items (default: 5)
/// - `itemHeight` (double): Height of each skeleton item (default: 60)
/// - `spacing` (double): Spacing between items (default: 8)
/// 
/// **Usage Example:**
/// ```dart
/// SkeletonList(
///   itemCount: 10,
///   itemHeight: 80,
///   spacing: 12,
/// )
/// ```

/// ## Error Handling Widgets
/// 
/// These widgets provide error handling and fallback UI.

/// ### ErrorBoundary
/// 
/// A widget that catches errors within its child tree and displays a fallback UI.
/// 
/// **Properties:**
/// - `child` (Widget): Child widget to wrap
/// - `fallback` (Widget?): Fallback widget to show on error
/// - `onError` (Function(Object, StackTrace)?): Error callback
/// 
/// **Usage Example:**
/// ```dart
/// ErrorBoundary(
///   fallback: Text('Something went wrong'),
///   onError: (error, stackTrace) {
///     print('Error caught: $error');
///   },
///   child: MyWidget(),
/// )
/// ```

/// ## Performance Optimization Widgets
/// 
/// These widgets provide performance optimizations.

/// ### RepaintBoundary
/// 
/// A widget that creates a separate repaint boundary.
/// 
/// **Usage Example:**
/// ```dart
/// RepaintBoundary(
///   child: ExpensiveWidget(),
/// )
/// ```

/// ### PerformanceOptimizedMixin
/// 
/// A mixin that provides performance optimization methods.
/// 
/// **Methods:**
/// - `debounce(key, callback, delay)`: Debounce function calls
/// - `throttle(key, callback, delay)`: Throttle function calls
/// - `withRepaintBoundary(widget)`: Wrap widget with RepaintBoundary
/// 
/// **Usage Example:**
/// ```dart
/// class MyWidget extends StatefulWidget with PerformanceOptimizedMixin {
///   @override
///   Widget build(BuildContext context) {
///     return withRepaintBoundary(
///       ExpensiveWidget(),
///     );
///   }
/// }
/// ```

/// ## Widget Best Practices
/// 
/// ### 1. Use const Constructors
/// Use const constructors whenever possible to improve performance:
/// 
/// ```dart
/// // Good
/// const Text('Hello World')
/// 
/// // Avoid
/// Text('Hello World')
/// ```
/// 
/// ### 2. Optimize Rebuilds
/// Use specific selectors to minimize rebuilds:
/// 
/// ```dart
/// // Good - Only rebuilds when credits change
/// CreditsSelector(
///   builder: (context, credits) => Text('$credits'),
/// )
/// 
/// // Avoid - Rebuilds when any user data changes
/// UserSelector(
///   builder: (context, user) => Text('${user?.credits}'),
/// )
/// ```
/// 
/// ### 3. Use RepaintBoundary
/// Wrap expensive widgets with RepaintBoundary:
/// 
/// ```dart
/// RepaintBoundary(
///   child: ComplexChart(),
/// )
/// ```
/// 
/// ### 4. Handle Loading States
/// Always provide loading and error states:
/// 
/// ```dart
/// OptimizedImage(
///   imageUrl: url,
///   placeholder: CircularProgressIndicator(),
///   errorWidget: Icon(Icons.broken_image),
/// )
/// ```
/// 
/// ### 5. Use Appropriate Image Types
/// Use specific image types for better caching:
/// 
/// ```dart
/// // Good
/// OptimizedImage(
///   imageUrl: url,
///   imageType: ImageType.profile,
/// )
/// 
/// // Avoid
/// OptimizedImage(
///   imageUrl: url,
///   imageType: ImageType.profile, // Same type for everything
/// )
/// ```

/// ## Widget Testing
/// 
/// ### Unit Tests
/// Test widget behavior and state:
/// 
/// ```dart
/// testWidgets('OptimizedImage shows placeholder while loading', (tester) async {
///   await tester.pumpWidget(
///     MaterialApp(
///       home: OptimizedImage(
///         imageUrl: 'https://example.com/image.jpg',
///         placeholder: Text('Loading...'),
///       ),
///     ),
///   );
///   
///   expect(find.text('Loading...'), findsOneWidget);
/// });
/// ```
/// 
/// ### Integration Tests
/// Test widget interactions:
/// 
/// ```dart
/// testWidgets('UserSelector updates when user changes', (tester) async {
///   await tester.pumpWidget(
///     StateProvider(
///       child: UserSelector(
///         builder: (context, user) => Text(user?.username ?? 'No user'),
///       ),
///     ),
///   );
///   
///   expect(find.text('No user'), findsOneWidget);
///   
///   // Update user state
///   AppState().setCurrentUser(User(id: '1', username: 'test'));
///   await tester.pump();
///   
///   expect(find.text('test'), findsOneWidget);
/// });
/// ```

/// ## Widget Performance Tips
/// 
/// ### 1. Minimize Rebuilds
/// - Use specific state selectors
/// - Avoid unnecessary setState calls
/// - Use const constructors
/// 
/// ### 2. Optimize Images
/// - Use appropriate image types
/// - Enable thumbnails for large images
/// - Preload images when possible
/// 
/// ### 3. Handle Memory
/// - Dispose resources properly
/// - Use RepaintBoundary for expensive widgets
/// - Implement proper error handling
/// 
/// ### 4. Improve UX
/// - Show loading states
/// - Provide error fallbacks
/// - Use smooth animations
/// - Handle edge cases gracefully
