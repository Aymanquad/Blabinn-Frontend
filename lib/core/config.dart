class AppConfig {
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-backend-url.railway.app',
  );
  
  static const String apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );
  
  // WebSocket Configuration
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://your-backend-url.railway.app',
  );
  
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
    defaultValue: false,
  );
  
  static const bool enableMockData = bool.fromEnvironment(
    'ENABLE_MOCK_DATA',
    defaultValue: false,
  );
  
  // App Settings
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // Validation
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  
  // API URLs
  static String get apiUrl => '$apiBaseUrl/api/$apiVersion';
  static String get wsEndpoint => '$wsUrl/socket.io';
  
  // Feature availability
  static bool get hasGoogleTranslate => googleTranslateApiKey.isNotEmpty;
  static bool get hasCloudinary => 
      cloudinaryCloudName.isNotEmpty && 
      cloudinaryApiKey.isNotEmpty && 
      cloudinaryApiSecret.isNotEmpty;
  static bool get hasAgora => 
      agoraAppId.isNotEmpty && 
      agoraAppToken.isNotEmpty;
} 