import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_projs/utils/html_decoder.dart';

void main() {
  group('HtmlDecoder Tests', () {
    test('should decode common HTML entities', () {
      // Test special characters that were causing issues
      expect(HtmlDecoder.decodeHtmlEntities('Hello: World; @user'), 'Hello: World; @user');
      expect(HtmlDecoder.decodeHtmlEntities('Test &amp; more'), 'Test & more');
      expect(HtmlDecoder.decodeHtmlEntities('&lt;script&gt;'), '<script>');
      expect(HtmlDecoder.decodeHtmlEntities('&quot;quoted&quot;'), '"quoted"');
      expect(HtmlDecoder.decodeHtmlEntities('&#x27;apostrophe&#x27;'), "'apostrophe'");
      expect(HtmlDecoder.decodeHtmlEntities('&#x2F;slash&#x2F;'), '/slash/');
    });

    test('should handle empty string', () {
      expect(HtmlDecoder.decodeHtmlEntities(''), '');
    });

    test('should handle string without HTML entities', () {
      expect(HtmlDecoder.decodeHtmlEntities('Hello World'), 'Hello World');
    });

    test('should handle mixed content', () {
      expect(HtmlDecoder.decodeHtmlEntities('Hello: &amp; World; @user'), 'Hello: & World; @user');
    });
  });
} 