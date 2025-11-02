/// # Models Documentation
/// 
/// This document provides comprehensive documentation for all data models used in the Chatify application.
/// Models represent the core data structures and provide serialization/deserialization capabilities.

/// ## User Model
/// 
/// The `User` model represents a user account in the Chatify application.
/// 
/// ### Properties
/// 
/// | Property | Type | Description | Required |
/// |----------|------|-------------|----------|
/// | `id` | String | Unique user identifier | Yes |
/// | `username` | String | User's unique username | Yes |
/// | `email` | String? | User's email address | No |
/// | `displayName` | String? | User's display name | No |
/// | `bio` | String? | User's bio text | No |
/// | `profileImage` | String? | URL to user's profile image | No |
/// | `interests` | List<String> | List of user interests | No |
/// | `credits` | int | User's credit balance | No |
/// | `isPremium` | bool | Whether user has premium subscription | No |
/// | `isOnline` | bool | Whether user is currently online | No |
/// | `location` | String? | User's location | No |
/// | `age` | int? | User's age | No |
/// | `gender` | String? | User's gender | No |
/// | `language` | String? | User's preferred language | No |
/// | `createdAt` | DateTime? | Account creation timestamp | No |
/// | `updatedAt` | DateTime? | Last update timestamp | No |
/// 
/// ### Usage Example
/// 
/// ```dart
/// // Create a new user
/// final user = User(
///   id: 'user_123',
///   username: 'john_doe',
///   email: 'john@example.com',
///   displayName: 'John Doe',
///   bio: 'Hello world!',
///   interests: ['music', 'travel'],
///   credits: 100,
///   isPremium: false,
///   isOnline: true,
/// );
/// 
/// // Convert to JSON
/// final json = user.toJson();
/// 
/// // Create from JSON
/// final userFromJson = User.fromJson(json);
/// 
/// // Update user
/// final updatedUser = user.copyWith(
///   bio: 'Updated bio',
///   credits: 150,
/// );
/// ```
/// 
/// ### Helper Methods
/// 
/// - `copyWith()`: Creates a copy with updated fields
/// - `toJson()`: Converts to JSON map
/// - `fromJson()`: Creates from JSON map
/// - `get initials`: Returns user's initials
/// - `get hasProfileImage`: Checks if user has profile image
/// - `get isComplete`: Checks if profile is complete

/// ## Chat Model
/// 
/// The `Chat` model represents a chat conversation between users.
/// 
/// ### Properties
/// 
/// | Property | Type | Description | Required |
/// |----------|------|-------------|----------|
/// | `id` | String | Unique chat identifier | Yes |
/// | `participant1Id` | String | ID of first participant | Yes |
/// | `participant2Id` | String | ID of second participant | Yes |
/// | `type` | ChatType | Type of chat (random, friend, group) | Yes |
/// | `status` | ChatStatus | Current chat status | Yes |
/// | `createdAt` | DateTime | Chat creation timestamp | Yes |
/// | `lastMessage` | Message? | Last message in chat | No |
/// | `lastMessageAt` | DateTime? | Timestamp of last message | No |
/// | `unreadCount` | int | Number of unread messages | No |
/// | `endedAt` | DateTime? | Chat end timestamp | No |
/// | `reason` | String? | Reason for chat ending | No |
/// 
/// ### Chat Types
/// 
/// - `ChatType.random`: Random chat with strangers
/// - `ChatType.friend`: Chat with friends
/// - `ChatType.group`: Group chat
/// 
/// ### Chat Status
/// 
/// - `ChatStatus.active`: Chat is active
/// - `ChatStatus.ended`: Chat has ended
/// - `ChatStatus.blocked`: Chat is blocked
/// - `ChatStatus.reported`: Chat has been reported
/// 
/// ### Usage Example
/// 
/// ```dart
/// // Create a new chat
/// final chat = Chat(
///   id: 'chat_123',
///   participant1Id: 'user_1',
///   participant2Id: 'user_2',
///   type: ChatType.random,
///   status: ChatStatus.active,
///   createdAt: DateTime.now(),
///   unreadCount: 0,
/// );
/// 
/// // Get other participant ID
/// final otherParticipantId = chat.getOtherParticipantId('user_1');
/// 
/// // Update chat
/// final updatedChat = chat.copyWith(
///   unreadCount: 5,
///   lastMessageAt: DateTime.now(),
/// );
/// ```

/// ## Message Model
/// 
/// The `Message` model represents a message in a chat conversation.
/// 
/// ### Properties
/// 
/// | Property | Type | Description | Required |
/// |----------|------|-------------|----------|
/// | `id` | String | Unique message identifier | Yes |
/// | `chatId` | String | ID of the chat this message belongs to | Yes |
/// | `senderId` | String | ID of the message sender | Yes |
/// | `receiverId` | String | ID of the message receiver | Yes |
/// | `content` | String | Message content | Yes |
/// | `type` | MessageType | Type of message | Yes |
/// | `timestamp` | DateTime | Message timestamp | Yes |
/// | `isRead` | bool | Whether message has been read | No |
/// | `readAt` | DateTime? | When message was read | No |
/// | `metadata` | Map<String, dynamic>? | Additional message data | No |
/// 
/// ### Message Types
/// 
/// - `MessageType.text`: Text message
/// - `MessageType.image`: Image message
/// - `MessageType.audio`: Audio message
/// - `MessageType.video`: Video message
/// - `MessageType.file`: File message
/// - `MessageType.system`: System message
/// 
/// ### Usage Example
/// 
/// ```dart
/// // Create a text message
/// final message = Message(
///   id: 'msg_123',
///   chatId: 'chat_123',
///   senderId: 'user_1',
///   receiverId: 'user_2',
///   content: 'Hello!',
///   type: MessageType.text,
///   timestamp: DateTime.now(),
///   isRead: false,
/// );
/// 
/// // Create an image message
/// final imageMessage = Message(
///   id: 'msg_124',
///   chatId: 'chat_123',
///   senderId: 'user_1',
///   receiverId: 'user_2',
///   content: 'https://example.com/image.jpg',
///   type: MessageType.image,
///   timestamp: DateTime.now(),
///   metadata: {
///     'width': 800,
///     'height': 600,
///     'size': 1024000,
///   },
/// );
/// ```

/// ## Connection Model
/// 
/// The `Connection` model represents a friend request or connection between users.
/// 
/// ### Properties
/// 
/// | Property | Type | Description | Required |
/// |----------|------|-------------|----------|
/// | `id` | String | Unique connection identifier | Yes |
/// | `fromUserId` | String | ID of user who sent request | Yes |
/// | `toUserId` | String | ID of user who received request | Yes |
/// | `status` | ConnectionStatus | Current connection status | Yes |
/// | `message` | String? | Optional message with request | No |
/// | `createdAt` | DateTime | Request creation timestamp | Yes |
/// | `updatedAt` | DateTime? | Last update timestamp | No |
/// | `acceptedAt` | DateTime? | When request was accepted | No |
/// | `rejectedAt` | DateTime? | When request was rejected | No |
/// 
/// ### Connection Status
/// 
/// - `ConnectionStatus.pending`: Request is pending
/// - `ConnectionStatus.accepted`: Request was accepted
/// - `ConnectionStatus.rejected`: Request was rejected
/// - `ConnectionStatus.cancelled`: Request was cancelled
/// 
/// ### Usage Example
/// 
/// ```dart
/// // Create a friend request
/// final connection = Connection(
///   id: 'conn_123',
///   fromUserId: 'user_1',
///   toUserId: 'user_2',
///   status: ConnectionStatus.pending,
///   message: 'Hi! I\'d like to connect with you.',
///   createdAt: DateTime.now(),
/// );
/// 
/// // Accept the request
/// final acceptedConnection = connection.copyWith(
///   status: ConnectionStatus.accepted,
///   acceptedAt: DateTime.now(),
/// );
/// ```

/// ## Notification Model
/// 
/// The `Notification` model represents a push notification or in-app notification.
/// 
/// ### Properties
/// 
/// | Property | Type | Description | Required |
/// |----------|------|-------------|----------|
/// | `id` | String | Unique notification identifier | Yes |
/// | `userId` | String | ID of user who receives notification | Yes |
/// | `title` | String | Notification title | Yes |
/// | `body` | String | Notification body text | Yes |
/// | `type` | NotificationType | Type of notification | Yes |
/// | `data` | Map<String, dynamic>? | Additional notification data | No |
/// | `isRead` | bool | Whether notification has been read | No |
/// | `createdAt` | DateTime | Notification creation timestamp | Yes |
/// | `readAt` | DateTime? | When notification was read | No |
/// 
/// ### Notification Types
/// 
/// - `NotificationType.message`: New message received
/// - `NotificationType.friendRequest`: Friend request received
/// - `NotificationType.match`: New match found
/// - `NotificationType.system`: System notification
/// - `NotificationType.promotion`: Promotional notification
/// 
/// ### Usage Example
/// 
/// ```dart
/// // Create a message notification
/// final notification = Notification(
///   id: 'notif_123',
///   userId: 'user_1',
///   title: 'New Message',
///   body: 'You have a new message from John',
///   type: NotificationType.message,
///   data: {
///     'chatId': 'chat_123',
///     'senderId': 'user_2',
///   },
///   createdAt: DateTime.now(),
///   isRead: false,
/// );
/// ```

/// ## Match Model
/// 
/// The `Match` model represents a match found during the matching process.
/// 
/// ### Properties
/// 
/// | Property | Type | Description | Required |
/// |----------|------|-------------|----------|
/// | `id` | String | Unique match identifier | Yes |
/// | `sessionId` | String | ID of the matching session | Yes |
/// | `participant1Id` | String | ID of first participant | Yes |
/// | `participant2Id` | String | ID of second participant | Yes |
/// | `status` | MatchStatus | Current match status | Yes |
/// | `createdAt` | DateTime | Match creation timestamp | Yes |
/// | `expiresAt` | DateTime? | When match expires | No |
/// | `chatId` | String? | ID of created chat | No |
/// | `metadata` | Map<String, dynamic>? | Additional match data | No |
/// 
/// ### Match Status
/// 
/// - `MatchStatus.pending`: Match is pending acceptance
/// - `MatchStatus.accepted`: Match was accepted
/// - `MatchStatus.rejected`: Match was rejected
/// - `MatchStatus.expired`: Match has expired
/// 
/// ### Usage Example
/// 
/// ```dart
/// // Create a match
/// final match = Match(
///   id: 'match_123',
///   sessionId: 'session_123',
///   participant1Id: 'user_1',
///   participant2Id: 'user_2',
///   status: MatchStatus.pending,
///   createdAt: DateTime.now(),
///   expiresAt: DateTime.now().add(Duration(minutes: 5)),
/// );
/// ```

/// ## Purchase Model
/// 
/// The `Purchase` model represents an in-app purchase.
/// 
/// ### Properties
/// 
/// | Property | Type | Description | Required |
/// |----------|------|-------------|----------|
/// | `id` | String | Unique purchase identifier | Yes |
/// | `userId` | String | ID of user who made purchase | Yes |
/// | `productId` | String | Product identifier | Yes |
/// | `platform` | String | Platform (android/ios) | Yes |
/// | `purchaseType` | PurchaseType | Type of purchase | Yes |
/// | `amount` | double | Purchase amount | Yes |
/// | `currency` | String | Currency code | Yes |
/// | `status` | PurchaseStatus | Purchase status | Yes |
/// | `purchaseToken` | String? | Platform purchase token | No |
/// | `orderId` | String? | Platform order ID | No |
/// | `purchasedAt` | DateTime | Purchase timestamp | Yes |
/// | `verifiedAt` | DateTime? | When purchase was verified | No |
/// 
/// ### Purchase Types
/// 
/// - `PurchaseType.consumable`: One-time purchase (credits)
/// - `PurchaseType.subscription`: Recurring subscription (premium)
/// 
/// ### Purchase Status
/// 
/// - `PurchaseStatus.pending`: Purchase is pending
/// - `PurchaseStatus.verified`: Purchase is verified
/// - `PurchaseStatus.failed`: Purchase failed
/// - `PurchaseStatus.refunded`: Purchase was refunded
/// 
/// ### Usage Example
/// 
/// ```dart
/// // Create a purchase
/// final purchase = Purchase(
///   id: 'purchase_123',
///   userId: 'user_1',
///   productId: 'credits_100',
///   platform: 'android',
///   purchaseType: PurchaseType.consumable,
///   amount: 4.99,
///   currency: 'USD',
///   status: PurchaseStatus.pending,
///   purchaseToken: 'token_123',
///   orderId: 'order_123',
///   purchasedAt: DateTime.now(),
/// );
/// ```

/// ## Report Model
/// 
/// The `Report` model represents a user report or complaint.
/// 
/// ### Properties
/// 
/// | Property | Type | Description | Required |
/// |----------|------|-------------|----------|
/// | `id` | String | Unique report identifier | Yes |
/// | `reporterId` | String | ID of user who made report | Yes |
/// | `reportedUserId` | String | ID of user being reported | Yes |
/// | `type` | ReportType | Type of report | Yes |
/// | `reason` | String | Report reason | Yes |
/// | `description` | String? | Additional details | No |
/// | `status` | ReportStatus | Report status | Yes |
/// | `createdAt` | DateTime | Report creation timestamp | Yes |
/// | `resolvedAt` | DateTime? | When report was resolved | No |
/// | `resolvedBy` | String? | ID of admin who resolved | No |
/// | `action` | String? | Action taken | No |
/// 
/// ### Report Types
/// 
/// - `ReportType.inappropriate`: Inappropriate content/behavior
/// - `ReportType.spam`: Spam or fake account
/// - `ReportType.harassment`: Harassment or bullying
/// - `ReportType.underage`: Underage user
/// - `ReportType.other`: Other reason
/// 
/// ### Report Status
/// 
/// - `ReportStatus.pending`: Report is pending review
/// - `ReportStatus.investigating`: Report is being investigated
/// - `ReportStatus.resolved`: Report has been resolved
/// - `ReportStatus.dismissed`: Report was dismissed
/// 
/// ### Usage Example
/// 
/// ```dart
/// // Create a report
/// final report = Report(
///   id: 'report_123',
///   reporterId: 'user_1',
///   reportedUserId: 'user_2',
///   type: ReportType.inappropriate,
///   reason: 'Inappropriate messages',
///   description: 'User sent inappropriate messages in chat',
///   status: ReportStatus.pending,
///   createdAt: DateTime.now(),
/// );
/// ```

/// ## Model Best Practices
/// 
/// ### 1. Immutability
/// Models should be immutable. Use `copyWith()` methods to create updated instances:
/// 
/// ```dart
/// // Good
/// final updatedUser = user.copyWith(credits: user.credits + 10);
/// 
/// // Avoid
/// user.credits += 10; // This would be bad if User was mutable
/// ```
/// 
/// ### 2. Null Safety
/// Use nullable types appropriately and handle null values:
/// 
/// ```dart
/// // Good
/// final displayName = user.displayName ?? user.username;
/// 
/// // Avoid
/// final displayName = user.displayName!; // Could throw if null
/// ```
/// 
/// ### 3. JSON Serialization
/// Always handle JSON serialization errors gracefully:
/// 
/// ```dart
/// try {
///   final user = User.fromJson(jsonData);
/// } catch (e) {
///   // Handle parsing error
///   print('Failed to parse user: $e');
/// }
/// ```
/// 
/// ### 4. Validation
/// Validate data when creating models:
/// 
/// ```dart
/// User createUser(Map<String, dynamic> data) {
///   if (data['id'] == null || data['username'] == null) {
///     throw ArgumentError('User ID and username are required');
///   }
///   return User.fromJson(data);
/// }
/// ```
/// 
/// ### 5. Helper Methods
/// Add helper methods for common operations:
/// 
/// ```dart
/// extension UserExtensions on User {
///   bool get isComplete => 
///     displayName != null && 
///     bio != null && 
///     profileImage != null;
///   
///   String get displayNameOrUsername => displayName ?? username;
/// }
/// ```

/// ## Model Testing
/// 
/// ### Unit Tests
/// Test model serialization, deserialization, and helper methods:
/// 
/// ```dart
/// test('User model serialization', () {
///   final user = User(
///     id: 'test_id',
///     username: 'test_user',
///     credits: 100,
///   );
///   
///   final json = user.toJson();
///   final fromJson = User.fromJson(json);
///   
///   expect(fromJson.id, equals('test_id'));
///   expect(fromJson.username, equals('test_user'));
///   expect(fromJson.credits, equals(100));
/// });
/// ```
/// 
/// ### Integration Tests
/// Test models with real API responses:
/// 
/// ```dart
/// test('User model with API response', () async {
///   final response = await apiService.getMyProfile();
///   final user = User.fromJson(response);
///   
///   expect(user.id, isNotNull);
///   expect(user.username, isNotNull);
/// });
/// ```
