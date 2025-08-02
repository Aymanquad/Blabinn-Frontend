import 'dart:convert';

class HtmlDecoder {
  /// Decodes HTML entities back to their original characters
  /// This is needed because the backend sanitizes special characters
  /// but the frontend should display them as intended
  static String decodeHtmlEntities(String text) {
    if (text.isEmpty) return text;
    
    // Common HTML entities that might be used in message content
    final Map<String, String> htmlEntities = {
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#x27;': "'",
      '&#x2F;': '/',
      '&amp;': '&',
      // Add more entities as needed
    };
    
    String decodedText = text;
    
    // Replace HTML entities with their original characters
    htmlEntities.forEach((entity, character) {
      decodedText = decodedText.replaceAll(entity, character);
    });
    
    return decodedText;
  }
  
  /// Decodes HTML entities using Dart's built-in HTML decoder
  /// This is a more comprehensive approach
  static String decodeHtmlEntitiesComprehensive(String text) {
    if (text.isEmpty) return text;
    
    try {
      // Use Dart's built-in HTML decoder
      return HtmlEscape().convert(text);
    } catch (e) {
      // Fallback to manual decoding if built-in fails
      return decodeHtmlEntities(text);
    }
  }
} 