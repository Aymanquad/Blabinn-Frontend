import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeVersionKey = 'theme_version';
  static const String _themeModeKey = 'theme_mode';

  ThemeVersion _themeVersion = ThemeVersion.v1;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isInitialized = false;

  ThemeVersion get themeVersion => _themeVersion;
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Get current light theme based on version
  ThemeData get lightTheme => AppTheme.light(_themeVersion);

  /// Get current dark theme based on version
  ThemeData get darkTheme => AppTheme.dark(_themeVersion);

  /// Initialize theme from preferences and environment
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for startup environment flag first
      const envSkin = String.fromEnvironment('APP_SKIN', defaultValue: 'v2');
      final startupVersion =
          envSkin == 'v2' ? ThemeVersion.v2 : ThemeVersion.v1;

      // Get saved version from preferences, fallback to environment
      final savedVersionString = prefs.getString(_themeVersionKey);
      ThemeVersion savedVersion = startupVersion;

      if (savedVersionString != null) {
        savedVersion =
            savedVersionString == 'v2' ? ThemeVersion.v2 : ThemeVersion.v1;
      }

      // Get saved theme mode
      final savedModeString = prefs.getString(_themeModeKey);
      ThemeMode savedMode = ThemeMode.dark;

      if (savedModeString != null) {
        switch (savedModeString) {
          case 'light':
            savedMode = ThemeMode.light;
            break;
          case 'system':
            savedMode = ThemeMode.system;
            break;
          default:
            savedMode = ThemeMode.dark;
        }
      }

      _themeVersion = savedVersion;
      _themeMode = savedMode;
      _isInitialized = true;

      debugPrint(
          '🎨 Theme initialized: ${_themeVersion.name} ${_themeMode.name}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize theme: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Switch between v1 and v2 themes
  Future<void> setThemeVersion(ThemeVersion version) async {
    if (_themeVersion == version) return;

    _themeVersion = version;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeVersionKey, version.name);
      debugPrint('🎨 Theme version changed to: ${version.name}');
    } catch (e) {
      debugPrint('❌ Failed to save theme version: $e');
    }
  }

  /// Toggle between v1 and v2
  Future<void> toggleThemeVersion() async {
    final newVersion =
        _themeVersion == ThemeVersion.v1 ? ThemeVersion.v2 : ThemeVersion.v1;
    await setThemeVersion(newVersion);
  }

  /// Set theme mode (light/dark/system)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
      debugPrint('🎨 Theme mode changed to: ${mode.name}');
    } catch (e) {
      debugPrint('❌ Failed to save theme mode: $e');
    }
  }

  /// Get theme version display name
  String get themeVersionDisplayName {
    switch (_themeVersion) {
      case ThemeVersion.v1:
        return 'Classic (V1)';
      case ThemeVersion.v2:
        return 'Modern (V2)';
    }
  }

  /// Get theme mode display name
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Check if using v2 theme
  bool get isV2Theme => _themeVersion == ThemeVersion.v2;

  /// Check if using v1 theme
  bool get isV1Theme => _themeVersion == ThemeVersion.v1;
}





