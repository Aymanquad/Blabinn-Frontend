import 'package:flutter/material.dart';

// App Colors based on schemes.md
class AppColors {
  // Light Theme Colors (First Palette)
  static const Color text = Color(0xFF2C2C2C);
  static const Color background = Color(0xFFFFF9F9);
  static const Color primary = Color(0xFFFF7F8A);
  static const Color secondary = Color(0xFF5DADE2);
  static const Color accent = Color(0xFFFFD166);

  // Additional UI Colors
  static const Color cardBackground = Colors.white;
  static const Color inputBackground = Color(0xFFF8F9FA);
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);

  // Dark Theme Colors
  static const Color darkText = Color(0xFFFDFCFB);
  static const Color darkBackground = Color(0xFF1E1B2E);
  static const Color darkPrimary = Color(0xFFA259FF);
  static const Color darkSecondary = Color(0xFF4DD4C9);
  static const Color darkAccent = Color(0xFFFF6F91);

  // Dark Theme Additional Colors
  static const Color darkCardBackground = Color(0xFF2A2A3E);
  static const Color darkInputBackground = Color(0xFF3A3A4E);

  // Chat Colors
  static const Color sentMessage = primary;
  static const Color receivedMessage = Color(0xFFE8E8E8);
  static const Color darkSentMessage = darkPrimary;
  static const Color darkReceivedMessage = Color(0xFF4A4A5E);
  static const Color sentMessageText = Colors.white;
  static const Color receivedMessageText = text;

  // Status Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
}

// App Constants
class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://your-backend-url.railway.app';
  static const String apiVersion = '/api/v1';

  // WebSocket
  static const String wsUrl = 'wss://your-backend-url.railway.app';

  // App Settings
  static const String appName = 'Chatify';
  static const String appVersion = '1.0.0';

  // Timeouts - Reduced for faster failures
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);

  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];

  // Chat Settings
  static const int maxMessageLength = 1000;
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);

  // Location
  static const double defaultLatitude = 0.0;
  static const double defaultLongitude = 0.0;
  static const int locationUpdateInterval = 30000; // 30 seconds

  // Distance Ranges for Connection Filters
  static const List<Map<String, dynamic>> distanceRanges = [
    {'value': '1-5', 'label': '1-5 km', 'min': 1, 'max': 5},
    {'value': '5-10', 'label': '5-10 km', 'min': 5, 'max': 10},
    {'value': '10-25', 'label': '10-25 km', 'min': 10, 'max': 25},
    {'value': '25-50', 'label': '25-50 km', 'min': 25, 'max': 50},
    {'value': '50-100', 'label': '50-100 km', 'min': 50, 'max': 100},
    {'value': '100-250', 'label': '100-250 km', 'min': 100, 'max': 250},
    {'value': '250-500', 'label': '250-500 km', 'min': 250, 'max': 500},
  ];

  // Video Call Settings
  static const Duration callTimeout = Duration(minutes: 30);
  static const int maxParticipants = 2;

  // Translation Settings
  static const String defaultSourceLanguage = 'auto';
  static const String defaultTargetLanguage = 'en';

  // Premium Features
  static const List<String> premiumFeatures = [
    'Age Range Filters',
    'Interest-based Matching',
    'Unlimited Video Calls',
    'Priority Matching',
    'Chat History',
  ];

  // Predefined Interests (User must select minimum 2)
  static const List<String> availableInterests = [
    'Movies & TV',
    'Gaming',
    'Music & Arts',
    'Fitness & Lifestyle',
    'Books & Learning',
  ];

  // Interest constraints
  static const int minInterestsRequired = 2;
}

// Error Messages
class ErrorMessages {
  static const String networkError =
      'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String authenticationError =
      'Authentication failed. Please login again.';
  static const String unknownError =
      'An unknown error occurred. Please try again.';
  static const String invalidInput = 'Invalid input. Please check your data.';
  static const String fileTooLarge =
      'File size is too large. Please choose a smaller file.';
  static const String unsupportedFormat = 'File format is not supported.';
}

// Success Messages
class SuccessMessages {
  static const String messageSent = 'Message sent successfully.';
  static const String profileUpdated = 'Profile updated successfully.';
  static const String friendAdded = 'Friend added successfully.';
  static const String userBlocked = 'User blocked successfully.';
  static const String userReported = 'User reported successfully.';
}

class AppStrings {
  // General
  static const String appTitle = 'Chatify';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';

  // Navigation
  static const String home = 'Home';
  static const String connect = 'Discover';
  static const String chats = 'Chats';
  static const String media = 'Media';
  static const String friends = 'Friends';
  static const String profile = 'Profile';

  // Auth
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String logout = 'Logout';
  static const String continueAsGuest = 'Continue as Guest';

  // Chat
  static const String typeMessage = 'Type a message...';
  static const String send = 'Send';
  static const String typing = 'typing...';
  static const String online = 'Online';
  static const String offline = 'Offline';

  // Connect
  static const String findPeople = 'Find People';
  static const String startChat = 'Start Chat';
  static const String waitingForMatch = 'Waiting for match...';
  static const String matchFound = 'Match found!';

  // Profile
  static const String editProfile = 'Edit Profile';
  static const String addPhoto = 'Add Photo';
  static const String bio = 'Bio';
  static const String interests = 'Interests';
  static const String location = 'Location';
  static const String language = 'Language';

  // Settings
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String privacy = 'Privacy';
  static const String blockedUsers = 'Blocked Users';
  static const String premium = 'Premium';

  // Errors
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred.';
  static const String invalidInput = 'Invalid input. Please check your data.';
}

class AppIcons {
  static const IconData home = Icons.home;
  static const IconData connect = Icons.people;
  static const IconData chat = Icons.chat;
  static const IconData friends = Icons.people_outline;
  static const IconData profile = Icons.person;
  static const IconData send = Icons.send;
  static const IconData camera = Icons.camera_alt;
  static const IconData gallery = Icons.photo_library;
  static const IconData media = Icons.folder_outlined;
  static const IconData location = Icons.location_on;
  static const IconData settings = Icons.settings;
  static const IconData premium = Icons.star;
  static const IconData block = Icons.block;
  static const IconData report = Icons.report;
  static const IconData videoCall = Icons.videocam;
  static const IconData voiceCall = Icons.call;
  static const IconData translate = Icons.translate;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData add = Icons.add;
  static const IconData search = Icons.search;
  static const IconData close = Icons.close;
  static const IconData back = Icons.arrow_back;
  static const IconData next = Icons.arrow_forward;
  static const IconData menu = Icons.menu;
  static const IconData more = Icons.more_vert;
  static const IconData heart = Icons.favorite;
  static const IconData star = Icons.star;
  static const IconData notification = Icons.notifications;
  static const IconData language = Icons.language;
  static const IconData theme = Icons.brightness_6;
  static const IconData logout = Icons.logout;
}
