import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Platform-specific API Configuration
  static String get _platformApiBaseUrl {
    // For web builds, use localhost
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    // For mobile platforms
    if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      // For physical devices, use the computer's IP address
      return const String.fromEnvironment(
        'API_BASE_URL',

        defaultValue: 'http://192.168.0.105:3000', // Updated to your current IP
      );
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      );
    } else {
      // Fallback for other platforms
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      );
    }
  }

  // API Configuration - Now uses platform-specific URL
  static String get apiBaseUrl => _platformApiBaseUrl;

  static const String apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );

  // WebSocket Configuration - Updated to match backend
  static String get wsBaseUrl {
    if (kIsWeb) {
      return 'ws://localhost:3000';
    }

    if (Platform.isAndroid) {
      return const String.fromEnvironment(
        'WS_URL',
        defaultValue: 'ws://192.168.0.105:3000',
      );
    } else if (Platform.isIOS) {
      return const String.fromEnvironment(
        'WS_URL',
        defaultValue: 'ws://localhost:3000',
      );
    } else {
      return const String.fromEnvironment(
        'WS_URL',
        defaultValue: 'ws://localhost:3000',
      );
    }
  }

  // Alternative URLs for physical devices (use your computer's IP)
  // To find your IP: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String _physicalDeviceIP = String.fromEnvironment(
    'PHYSICAL_DEVICE_IP',
    defaultValue: '192.168.0.105', // Updated to your current IP address
  );

  static String get physicalDeviceApiUrl => 'http://$_physicalDeviceIP:3000';

  // Google Translate API
  static const String googleTranslateApiKey = String.fromEnvironment(
    'GOOGLE_TRANSLATE_API_KEY',
    defaultValue: '',
  );

  // Cloudinary Configuration (for image uploads)
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );

  static const String cloudinaryApiKey = String.fromEnvironment(
    'CLOUDINARY_API_KEY',
    defaultValue: '',
  );

  static const String cloudinaryApiSecret = String.fromEnvironment(
    'CLOUDINARY_API_SECRET',
    defaultValue: '',
  );

  // Agora Configuration (for video calls)
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '',
  );

  static const String agoraAppToken = String.fromEnvironment(
    'AGORA_APP_TOKEN',
    defaultValue: '',
  );

  // Feature Flags
  static const bool enableVideoCalls = bool.fromEnvironment(
    'ENABLE_VIDEO_CALLS',
    defaultValue: true,
  );

  static const bool enableTranslation = bool.fromEnvironment(
    'ENABLE_TRANSLATION',
    defaultValue: true,
  );

  static const bool enableLocationSharing = bool.fromEnvironment(
    'ENABLE_LOCATION_SHARING',
    defaultValue: true,
  );

  static const bool enablePremiumFeatures = bool.fromEnvironment(
    'ENABLE_PREMIUM_FEATURES',
    defaultValue: true,
  );

  // Debug Settings
  static const bool enableDebugLogs = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: true, // Enable for development
  );

  static const bool enableMockData = bool.fromEnvironment(
    'ENABLE_MOCK_DATA',
    defaultValue: false,
  );

  // App Settings
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 30);

  // WebSocket Settings
  static const int wsMaxReconnectAttempts = 5;
  static const Duration wsReconnectDelay = Duration(seconds: 3);

  // API Key Validation
  static bool get hasValidApiKey => googleTranslateApiKey.isNotEmpty;

  // Validation
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';

  // API URLs - Updated to match backend structure
  static String get apiUrl => '$apiBaseUrl/api';
  static String get wsEndpoint => '$wsBaseUrl/socket.io';

  // Debug info
  static Map<String, dynamic> get debugInfo => {
        'platform': Platform.operatingSystem,
        'isWeb': kIsWeb,
        'apiBaseUrl': apiBaseUrl,
        'apiUrl': apiUrl,
        'wsBaseUrl': wsBaseUrl,
        'physicalDeviceApiUrl': physicalDeviceApiUrl,
      };

  // Feature availability
  static bool get hasGoogleTranslate => googleTranslateApiKey.isNotEmpty;
  static bool get hasCloudinary =>
      cloudinaryCloudName.isNotEmpty &&
      cloudinaryApiKey.isNotEmpty &&
      cloudinaryApiSecret.isNotEmpty;
  static bool get hasAgora => agoraAppId.isNotEmpty && agoraAppToken.isNotEmpty;
}
