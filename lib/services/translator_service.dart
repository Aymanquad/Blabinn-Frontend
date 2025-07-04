import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/constants.dart';

class TranslatorService {
  static final TranslatorService _instance = TranslatorService._internal();
  factory TranslatorService() => _instance;
  TranslatorService._internal();

  final String _apiKey = AppConfig.googleTranslateApiKey;
  final String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese (Simplified)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'nl': 'Dutch',
    'pl': 'Polish',
    'tr': 'Turkish',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'fi': 'Finnish',
    'cs': 'Czech',
    'sk': 'Slovak',
    'hu': 'Hungarian',
    'ro': 'Romanian',
    'bg': 'Bulgarian',
    'hr': 'Croatian',
    'sl': 'Slovenian',
    'et': 'Estonian',
    'lv': 'Latvian',
    'lt': 'Lithuanian',
    'mt': 'Maltese',
    'el': 'Greek',
    'he': 'Hebrew',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'id': 'Indonesian',
    'ms': 'Malay',
    'tl': 'Filipino',
    'bn': 'Bengali',
    'ur': 'Urdu',
    'fa': 'Persian',
    'am': 'Amharic',
    'sw': 'Swahili',
    'zu': 'Zulu',
    'af': 'Afrikaans',
    'sq': 'Albanian',
    'hy': 'Armenian',
    'az': 'Azerbaijani',
    'be': 'Belarusian',
    'bs': 'Bosnian',
    'ca': 'Catalan',
    'cy': 'Welsh',
    'eo': 'Esperanto',
    'eu': 'Basque',
    'fo': 'Faroese',
    'gl': 'Galician',
    'ka': 'Georgian',
    'gu': 'Gujarati',
    'ha': 'Hausa',
    'haw': 'Hawaiian',
    'is': 'Icelandic',
    'ig': 'Igbo',
    'ga': 'Irish',
    'jv': 'Javanese',
    'kn': 'Kannada',
    'kk': 'Kazakh',
    'km': 'Khmer',
    'rw': 'Kinyarwanda',
    'ky': 'Kyrgyz',
    'lo': 'Lao',
    'la': 'Latin',
    'lb': 'Luxembourgish',
    'mk': 'Macedonian',
    'mg': 'Malagasy',
    'ml': 'Malayalam',
    'mi': 'Maori',
    'mr': 'Marathi',
    'mn': 'Mongolian',
    'my': 'Myanmar (Burmese)',
    'ne': 'Nepali',
    'or': 'Odia',
    'ps': 'Pashto',
    'pa': 'Punjabi',
    'qu': 'Quechua',
    'sm': 'Samoan',
    'gd': 'Scottish Gaelic',
    'sr': 'Serbian',
    'st': 'Sesotho',
    'sn': 'Shona',
    'sd': 'Sindhi',
    'si': 'Sinhala',
    'so': 'Somali',
    'su': 'Sundanese',
    'tg': 'Tajik',
    'ta': 'Tamil',
    'tt': 'Tatar',
    'te': 'Telugu',
    'tk': 'Turkmen',
    'uk': 'Ukrainian',
    'ug': 'Uyghur',
    'uz': 'Uzbek',
    'xh': 'Xhosa',
    'yi': 'Yiddish',
    'yo': 'Yoruba',
  };

  // Get supported languages
  Map<String, String> getSupportedLanguages() {
    return supportedLanguages;
  }

  // Get language name by code
  String? getLanguageName(String languageCode) {
    return supportedLanguages[languageCode.toLowerCase()];
  }

  // Get language code by name
  String? getLanguageCode(String languageName) {
    for (final entry in supportedLanguages.entries) {
      if (entry.value.toLowerCase() == languageName.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  // Detect language of text
  Future<String?> detectLanguage(String text) async {
    if (text.trim().isEmpty) return 'unknown';
    if (_apiKey.isEmpty) {
      throw Exception('Google Translate API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'key': _apiKey,
        'q': text,
      };

      final uri = Uri.parse('https://translation.googleapis.com/language/translate/v2/detect').replace(queryParameters: queryParams);
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final detections = data['data']['detections'] as List;
        
        if (detections.isNotEmpty && detections.first.isNotEmpty) {
          return detections.first.first['language'] as String;
        } else {
          return 'unknown';
        }
      } else {
        final errorData = jsonDecode(response.body);
        final error = errorData['error']?['message'] ?? 'Language detection failed';
        throw Exception(error);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Language detection failed: $e');
    }
  }

  // Translate text
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (!AppConfig.hasValidApiKey) {
      throw TranslatorException('Google Translate API key not configured');
    }

    if (text.trim().isEmpty) {
      return text;
    }

    try {
      final queryParams = <String, String>{
        'key': _apiKey,
        'q': text,
        'target': targetLanguage,
      };

      if (sourceLanguage != null) {
        queryParams['source'] = sourceLanguage;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translations = data['data']['translations'] as List;
        
        if (translations.isNotEmpty) {
          return translations.first['translatedText'] as String;
        }
      }

      throw Exception('Translation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Translation error: $e');
    }
  }

  // Translate multiple texts
  Future<List<String>> translateMultipleTexts(List<String> texts, String targetLanguage, {String? sourceLanguage}) async {
    if (texts.isEmpty) return texts;
    if (_apiKey.isEmpty) {
      throw Exception('Google Translate API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'key': _apiKey,
        'target': targetLanguage,
      };

      if (sourceLanguage != null && sourceLanguage.isNotEmpty) {
        queryParams['source'] = sourceLanguage;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      final body = {
        'q': texts,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translations = data['data']['translations'] as List;
        
        return translations.map((t) => t['translatedText'] as String).toList();
      } else {
        final errorData = jsonDecode(response.body);
        final error = errorData['error']?['message'] ?? 'Translation failed';
        throw Exception(error);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Translation failed: $e');
    }
  }

  // Get supported languages from API
  Future<Map<String, String>> getSupportedLanguagesFromAPI() async {
    if (_apiKey.isEmpty) {
      throw Exception('Google Translate API key not configured');
    }

    try {
      final response = await http.get(
        Uri.parse('https://translation.googleapis.com/language/translate/v2/languages?key=$_apiKey'),
      ).timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final languages = data['data']['languages'] as List;
        
        final Map<String, String> languageMap = {};
        for (final lang in languages) {
          languageMap[lang['language'] as String] = lang['name'] as String;
        }
        
        return languageMap;
      } else {
        throw Exception('Failed to get supported languages: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting supported languages: $e');
    }
  }

  // Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode.toLowerCase());
  }

  // Get default target language (English)
  String getDefaultTargetLanguage() {
    return 'en';
  }

  // Get user's preferred language from device
  String getUserPreferredLanguage() {
    // This would typically get the device locale
    // For now, return English as default
    return 'en';
  }

  // Format language for display
  String formatLanguageForDisplay(String languageCode) {
    final languageName = getLanguageName(languageCode);
    if (languageName != null) {
      return languageName;
    }
    return languageCode.toUpperCase();
  }

  // Get language flag emoji (basic implementation)
  String getLanguageFlagEmoji(String languageCode) {
    // This is a simplified implementation
    // In a real app, you might want to use a proper flag emoji library
    final flagMap = {
      'en': '🇺🇸',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'ru': '🇷🇺',
      'zh': '🇨🇳',
      'ja': '🇯🇵',
      'ko': '🇰🇷',
      'ar': '🇸🇦',
      'hi': '🇮🇳',
    };

    return flagMap[languageCode] ?? '🌐';
  }

  // Check if API is available
  bool get isAvailable => _apiKey.isNotEmpty;

  // Get API key status
  String get apiKeyStatus {
    if (_apiKey.isEmpty) return 'Not configured';
    if (_apiKey.length < 10) return 'Invalid';
    return 'Configured';
  }
}

class Language {
  final String code;
  final String name;

  Language({
    required this.code,
    required this.name,
  });

  @override
  String toString() => '$name ($code)';
}

class TranslatedMessage {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;

  TranslatedMessage({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  @override
  String toString() => 'TranslatedMessage(original: $originalText, translated: $translatedText)';
}

class TranslatorException implements Exception {
  final String message;

  TranslatorException(this.message);

  @override
  String toString() => 'TranslatorException: $message';
} 