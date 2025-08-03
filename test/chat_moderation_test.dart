import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/chat_moderation_service.dart';

void main() {
  group('ChatModerationService Tests', () {
    late ChatModerationService moderationService;

    setUp(() {
      moderationService = ChatModerationService();
    });

    group('Content Detection Tests', () {
      test('should detect inappropriate content', () {
        expect(moderationService.containsInappropriateContent('You are an idiot'), true);
        expect(moderationService.containsInappropriateContent('That is so stupid'), true);
        expect(moderationService.containsInappropriateContent('Hello world'), false);
        expect(moderationService.containsInappropriateContent(''), false);
      });

      test('should be case insensitive', () {
        expect(moderationService.containsInappropriateContent('YOU ARE AN IDIOT'), true);
        expect(moderationService.containsInappropriateContent('You Are An Idiot'), true);
        expect(moderationService.containsInappropriateContent('you are an idiot'), true);
      });

      test('should handle mixed case', () {
        expect(moderationService.containsInappropriateContent('You are an IdIoT'), true);
        expect(moderationService.containsInappropriateContent('StUpId person'), true);
      });
    });

    group('Content Filtering Tests', () {
      test('should filter inappropriate words with asterisks', () {
        expect(moderationService.filterInappropriateContent('You are an idiot'), 'You are an *****');
        expect(moderationService.filterInappropriateContent('That is so stupid'), 'That is so ******');
        expect(moderationService.filterInappropriateContent('Hello world'), 'Hello world');
        expect(moderationService.filterInappropriateContent(''), '');
      });

      test('should preserve message structure', () {
        expect(moderationService.filterInappropriateContent('You are an idiot!'), 'You are an *****!');
        expect(moderationService.filterInappropriateContent('That is so stupid.'), 'That is so ******.');
        expect(moderationService.filterInappropriateContent('Hello, idiot world'), 'Hello, ***** world');
      });

      test('should handle multiple inappropriate words', () {
        expect(moderationService.filterInappropriateContent('You are an idiot and stupid'), 
               'You are an ***** and ******');
      });

      test('should handle punctuation and special characters', () {
        expect(moderationService.filterInappropriateContent('You are an idiot!'), 'You are an *****!');
        expect(moderationService.filterInappropriateContent('That is so stupid.'), 'That is so ******.');
        expect(moderationService.filterInappropriateContent('Hello, idiot world'), 'Hello, ***** world');
      });
    });

    group('Inappropriate Words Detection Tests', () {
      test('should return list of inappropriate words', () {
        final words = moderationService.getInappropriateWords('You are an idiot and stupid');
        expect(words, contains('idiot'));
        expect(words, contains('stupid'));
        expect(words.length, 2);
      });

      test('should return empty list for clean content', () {
        final words = moderationService.getInappropriateWords('Hello world');
        expect(words, isEmpty);
      });

      test('should handle case insensitive word detection', () {
        final words = moderationService.getInappropriateWords('You are an IDIOT and STUPID');
        expect(words, contains('idiot'));
        expect(words, contains('stupid'));
      });
    });

    group('Racial Slurs Tests', () {
      test('should detect and filter racial slurs', () {
        expect(moderationService.containsInappropriateContent('nigger'), true);
        expect(moderationService.containsInappropriateContent('nigga'), true);
        expect(moderationService.containsInappropriateContent('faggot'), true);
        expect(moderationService.containsInappropriateContent('dyke'), true);
        expect(moderationService.containsInappropriateContent('kike'), true);
        expect(moderationService.containsInappropriateContent('spic'), true);
        expect(moderationService.containsInappropriateContent('chink'), true);
        expect(moderationService.containsInappropriateContent('gook'), true);
        expect(moderationService.containsInappropriateContent('wop'), true);
        expect(moderationService.containsInappropriateContent('dago'), true);
        expect(moderationService.containsInappropriateContent('kraut'), true);
        expect(moderationService.containsInappropriateContent('haji'), true);
        expect(moderationService.containsInappropriateContent('raghead'), true);
      });

      test('should filter racial slurs with asterisks', () {
        expect(moderationService.filterInappropriateContent('You are a nigger'), 'You are a *******');
        expect(moderationService.filterInappropriateContent('That faggot is here'), 'That ******* is here');
        expect(moderationService.filterInappropriateContent('The dyke over there'), 'The **** over there');
      });
    });

    group('Terrorism and Violence Tests', () {
      test('should detect terrorism-related content', () {
        expect(moderationService.containsInappropriateContent('terrorist'), true);
        expect(moderationService.containsInappropriateContent('terrorism'), true);
        expect(moderationService.containsInappropriateContent('bomb'), true);
        expect(moderationService.containsInappropriateContent('explosive'), true);
        expect(moderationService.containsInappropriateContent('suicide'), true);
        expect(moderationService.containsInappropriateContent('attack'), true);
        expect(moderationService.containsInappropriateContent('kill'), true);
        expect(moderationService.containsInappropriateContent('murder'), true);
        expect(moderationService.containsInappropriateContent('assassinate'), true);
      });

      test('should filter terrorism-related content', () {
        expect(moderationService.filterInappropriateContent('The terrorist is here'), 'The ********* is here');
        expect(moderationService.filterInappropriateContent('There is a bomb'), 'There is a ****');
        expect(moderationService.filterInappropriateContent('Suicide attack'), '******* attack');
      });
    });

    group('General Slurs Tests', () {
      test('should detect general offensive terms', () {
        expect(moderationService.containsInappropriateContent('bitch'), true);
        expect(moderationService.containsInappropriateContent('whore'), true);
        expect(moderationService.containsInappropriateContent('slut'), true);
        expect(moderationService.containsInappropriateContent('cunt'), true);
        expect(moderationService.containsInappropriateContent('pussy'), true);
        expect(moderationService.containsInappropriateContent('dick'), true);
        expect(moderationService.containsInappropriateContent('cock'), true);
        expect(moderationService.containsInappropriateContent('penis'), true);
        expect(moderationService.containsInappropriateContent('vagina'), true);
        expect(moderationService.containsInappropriateContent('asshole'), true);
        expect(moderationService.containsInappropriateContent('bastard'), true);
        expect(moderationService.containsInappropriateContent('motherfucker'), true);
        expect(moderationService.containsInappropriateContent('fuck'), true);
        expect(moderationService.containsInappropriateContent('shit'), true);
        expect(moderationService.containsInappropriateContent('damn'), true);
        expect(moderationService.containsInappropriateContent('hell'), true);
      });

      test('should filter general offensive terms', () {
        expect(moderationService.filterInappropriateContent('You are a bitch'), 'You are a *****');
        expect(moderationService.filterInappropriateContent('That whore is here'), 'That ***** is here');
        expect(moderationService.filterInappropriateContent('The slut over there'), 'The **** over there');
      });
    });

    group('Mental Health Slurs Tests', () {
      test('should detect mental health slurs', () {
        expect(moderationService.containsInappropriateContent('retard'), true);
        expect(moderationService.containsInappropriateContent('retarded'), true);
        expect(moderationService.containsInappropriateContent('idiot'), true);
        expect(moderationService.containsInappropriateContent('stupid'), true);
        expect(moderationService.containsInappropriateContent('dumb'), true);
        expect(moderationService.containsInappropriateContent('moron'), true);
        expect(moderationService.containsInappropriateContent('imbecile'), true);
        expect(moderationService.containsInappropriateContent('cretin'), true);
        expect(moderationService.containsInappropriateContent('handicapped'), true);
        expect(moderationService.containsInappropriateContent('cripple'), true);
        expect(moderationService.containsInappropriateContent('gimp'), true);
        expect(moderationService.containsInappropriateContent('spaz'), true);
        expect(moderationService.containsInappropriateContent('autistic'), true);
        expect(moderationService.containsInappropriateContent('asperger'), true);
        expect(moderationService.containsInappropriateContent('down'), true);
        expect(moderationService.containsInappropriateContent('syndrome'), true);
        expect(moderationService.containsInappropriateContent('special'), true);
        expect(moderationService.containsInappropriateContent('needs'), true);
      });

      test('should filter mental health slurs', () {
        expect(moderationService.filterInappropriateContent('You are a retard'), 'You are a ******');
        expect(moderationService.filterInappropriateContent('That idiot is here'), 'That ***** is here');
        expect(moderationService.filterInappropriateContent('The stupid person'), 'The ****** person');
      });
    });

    group('Edge Cases Tests', () {
      test('should handle empty strings', () {
        expect(moderationService.containsInappropriateContent(''), false);
        expect(moderationService.filterInappropriateContent(''), '');
        expect(moderationService.getInappropriateWords(''), isEmpty);
      });

      test('should handle whitespace only', () {
        expect(moderationService.containsInappropriateContent('   '), false);
        expect(moderationService.filterInappropriateContent('   '), '   ');
        expect(moderationService.getInappropriateWords('   '), isEmpty);
      });

      test('should handle single inappropriate word', () {
        expect(moderationService.containsInappropriateContent('idiot'), true);
        expect(moderationService.filterInappropriateContent('idiot'), '*****');
        expect(moderationService.getInappropriateWords('idiot'), ['idiot']);
      });

      test('should handle multiple spaces', () {
        expect(moderationService.containsInappropriateContent('You   are   an   idiot'), true);
        expect(moderationService.filterInappropriateContent('You   are   an   idiot'), 'You   are   an   *****');
      });

      test('should handle punctuation within words', () {
        expect(moderationService.containsInappropriateContent('idiot!'), true);
        expect(moderationService.filterInappropriateContent('idiot!'), '*****!');
        expect(moderationService.containsInappropriateContent('idiot.'), true);
        expect(moderationService.filterInappropriateContent('idiot.'), '*****.');
      });
    });

    group('Performance Tests', () {
      test('should handle long messages efficiently', () {
        final longMessage = 'This is a very long message with many words that should be processed efficiently. ' * 10;
        expect(moderationService.containsInappropriateContent(longMessage), false);
        expect(moderationService.filterInappropriateContent(longMessage), longMessage);
      });

      test('should handle messages with many inappropriate words', () {
        final badMessage = 'You are an idiot and stupid and dumb and a retard and a moron and an imbecile';
        expect(moderationService.containsInappropriateContent(badMessage), true);
        final filtered = moderationService.filterInappropriateContent(badMessage);
        expect(filtered, isNot(equals(badMessage)));
        expect(filtered.contains('*****'), true);
        expect(filtered.contains('******'), true);
      });
    });
  });
} 