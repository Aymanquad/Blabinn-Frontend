import 'dart:io';
import 'package:flutter/foundation.dart';
import 'env_config.dart';

class AppConfig {
  // Environment
  static const String environment = EnvConfig.environment;

  // Platform-specific API Configuration
  static String get _platformApiBaseUrl {
    // For web builds, use localhost
    if (kIsWeb) {
      return EnvConfig.apiBaseUrlWeb;
    }

    // For mobile platforms
    if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      // For physical devices, use the computer's IP address
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: EnvConfig.apiBaseUrlAndroid,
      );
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: EnvConfig.apiBaseUrlIos,
      );
    } else {
      // Fallback for other platforms
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: EnvConfig.apiBaseUrlDefault,
      );
    }
  }

  // API Configuration - Now uses platform-specific URL
  static String get apiBaseUrl => _platformApiBaseUrl;

  static const String apiVersion = EnvConfig.apiVersion;

  // WebSocket Configuration - Updated to match backend
  static String get wsBaseUrl {
    if (kIsWeb) {
      return EnvConfig.wsUrlWeb;
    }

    if (Platform.isAndroid) {
      return const String.fromEnvironment(
        'WS_URL',
        defaultValue: EnvConfig.wsUrlAndroid,
      );
    } else if (Platform.isIOS) {
      return const String.fromEnvironment(
        'WS_URL',
        defaultValue: EnvConfig.wsUrlIos,
      );
    } else {
      return const String.fromEnvironment(
        'WS_URL',
        defaultValue: EnvConfig.wsUrlDefault,
      );
    }
  }

  // Alternative URLs for physical devices (use your computer's IP)
  // To find your IP: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String _physicalDeviceIP = EnvConfig.physicalDeviceIp;

  static String get physicalDeviceApiUrl => 'http://$_physicalDeviceIP:3000';

  // Google Translate API
  static const String googleTranslateApiKey = EnvConfig.googleTranslateApiKey;

  // Cloudinary Configuration (for image uploads)
  static const String cloudinaryCloudName = EnvConfig.cloudinaryCloudName;

  static const String cloudinaryApiKey = EnvConfig.cloudinaryApiKey;

  static const String cloudinaryApiSecret = EnvConfig.cloudinaryApiSecret;

  // Agora Configuration (for video calls)
  static const String agoraAppId = EnvConfig.agoraAppId;

  static const String agoraAppToken = EnvConfig.agoraAppToken;

  // Feature Flags
  static const bool enableVideoCalls = EnvConfig.enableVideoCalls;

  static const bool enableTranslation = EnvConfig.enableTranslation;

  static const bool enableLocationSharing = EnvConfig.enableLocationSharing;

  static const bool enablePremiumFeatures = EnvConfig.enablePremiumFeatures;

  // Debug Settings
  static const bool enableDebugLogs = EnvConfig.enableDebugLogs;

  static const bool enableMockData = EnvConfig.enableMockData;

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
