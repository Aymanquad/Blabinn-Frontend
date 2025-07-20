// Environment Configuration File
// This file contains all environment-specific URLs and IP addresses
// Update these values according to your environment

class EnvConfig {
  // Environment
  static const String environment = 'production';

  // ===== HISHAM PC CONFIG (COMMENTED OUT) =====
  // API Configuration
  // static const String apiBaseUrlAndroid = 'http://192.168.0.105:3000';
  // static const String apiBaseUrlIos = 'http://localhost:3000';
  // static const String apiBaseUrlWeb = 'http://localhost:3000';
  // static const String apiBaseUrlDefault = 'http://localhost:3000';

  // WebSocket Configuration
  // static const String wsUrlAndroid = 'ws://192.168.0.105:3000';
  // static const String wsUrlIos = 'ws://localhost:3000';
  // static const String wsUrlWeb = 'ws://localhost:3000';
  // static const String wsUrlDefault = 'ws://localhost:3000';

  // Physical Device IP (for Android physical devices)
  // static const String physicalDeviceIp = '192.168.0.105';

  // ===== AYMAN PC CONFIG (COMMENTED OUT) =====
  // API Configuration
  // static const String apiBaseUrlAndroid = 'http://192.168.1.5:3000';  // Updated to correct IP
  // static const String apiBaseUrlIos = 'http://localhost:3000';
  // static const String apiBaseUrlWeb = 'http://localhost:3000';
  // static const String apiBaseUrlDefault = 'http://localhost:3000';
  // static const String apiVersion = 'v1';

  // WebSocket Configuration - Socket.IO uses HTTP URLs, not WS URLs
  // static const String wsUrlAndroid = 'http://192.168.1.5:3000';  // Updated to correct IP
  // static const String wsUrlIos = 'http://localhost:3000';
  // static const String wsUrlWeb = 'http://localhost:3000';
  // static const String wsUrlDefault = 'http://localhost:3000';

  // Physical Device IP (for Android physical devices)
  // static const String physicalDeviceIp = '192.168.1.5';  // Updated to correct IP

  // ===== DEPLOYED BACKEND CONFIG =====
  // API Configuration
  static const String apiBaseUrlAndroid =
      'https://blabbin-backend.onrender.com';
  static const String apiBaseUrlIos = 'https://blabbin-backend.onrender.com';
  static const String apiBaseUrlWeb = 'https://blabbin-backend.onrender.com';
  static const String apiBaseUrlDefault =
      'https://blabbin-backend.onrender.com';
  static const String apiVersion = 'v1';

  // WebSocket Configuration - Socket.IO uses HTTP URLs, not WS URLs
  static const String wsUrlAndroid = 'https://blabbin-backend.onrender.com';
  static const String wsUrlIos = 'https://blabbin-backend.onrender.com';
  static const String wsUrlWeb = 'https://blabbin-backend.onrender.com';
  static const String wsUrlDefault = 'https://blabbin-backend.onrender.com';

  // Physical Device IP (for Android physical devices) - Not needed for deployed backend
  // static const String physicalDeviceIp = '';

  // Third-party API Keys
  static const String googleTranslateApiKey = '';
  static const String cloudinaryCloudName = '';
  static const String cloudinaryApiKey = '';
  static const String cloudinaryApiSecret = '';
  static const String agoraAppId = '';
  static const String agoraAppToken = '';

  // Feature Flags
  static const bool enableVideoCalls = true;
  static const bool enableTranslation = true;
  static const bool enableLocationSharing = true;
  static const bool enablePremiumFeatures = true;

  // Debug Settings
  static const bool enableDebugLogs = true;
  static const bool enableMockData = false;
}
