import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class ChatModerationService {
  static final ChatModerationService _instance =
      ChatModerationService._internal();
  factory ChatModerationService() => _instance;
  ChatModerationService._internal();

  // Inappropriate words database
  final Set<String> _inappropriateWords = {
    // Racial slurs and offensive terms
    "nigger",
    "nigga",
    "faggot",
    "fag",
    "dyke",
    "kike",
    "spic",
    "chink",
    "gook",
    "wop",
    "dago",
    "coon",
    "jigaboo",
    "spook",
    "beaner",
    "wetback",
    "haji",
    "raghead",
    "kafir",
    "mushrik",
    "polytheist",
    "infidel",
    "heathen",
    "commie",
    "socialist",
    "fascist",
    "neo-nazi",
    "alt-right",
    "terrorist",
    "terrorism",
    "bomb",
    "explosive",
    "suicide",
    "jihad",
    "isis",
    "taliban",
    "extremist",
    "homicidal",
    "violence",
    "hate",
    "kill",
    "murder",
    "assassinate",
    "hitler",
    "nazism",
    "goebbels",
    "pol pot",
    "bin laden",
    "holocaust",
    "genocide",
    "kkk",
    "white power",
    "child porn",
    "pedo",
    "pedophile",
    "groomer",
    "incest",
    "lolicon",
    "shota",
    "loli",
    "stab",
    "molester",
    "self-harm",
    "suicidal"
  };

  // Check if text contains inappropriate content
  bool containsInappropriateContent(String text) {
    if (text.isEmpty) return false;

    final words = text.toLowerCase().split(RegExp(r'\s+'));
    return words.any((word) => _inappropriateWords.contains(word));
  }

  // Filter inappropriate content by replacing with asterisks
  String filterInappropriateContent(String text) {
    if (text.isEmpty) return text;

    final words = text.split(RegExp(r'\s+'));
    final filteredWords = words.map((word) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      if (_inappropriateWords.contains(cleanWord)) {
        return '*' * word.length;
      }
      return word;
    }).toList();

    return filteredWords.join(' ');
  }

  // Get list of inappropriate words found in text
  List<String> getInappropriateWords(String text) {
    if (text.isEmpty) return [];

    final words = text.toLowerCase().split(RegExp(r'\s+'));
    return words.where((word) => _inappropriateWords.contains(word)).toList();
  }

  // Show warning dialog for inappropriate content
  Future<bool> showWarningDialog(
      BuildContext context, List<String> inappropriateWords) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text('Content Warning'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your message contains inappropriate content that has been filtered out.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Please be respectful and avoid using offensive language.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (inappropriateWords.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text(
                      'Filtered words:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      inappropriateWords.join(', '),
                      style: TextStyle(fontSize: 12, color: Colors.red[600]),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Send Anyway'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Process message before sending
  Future<String?> processMessageForSending(
      BuildContext context, String message) async {
    if (message.trim().isEmpty) return null;

    final inappropriateWords = getInappropriateWords(message);

    if (inappropriateWords.isNotEmpty) {
      final shouldSend = await showWarningDialog(context, inappropriateWords);
      if (!shouldSend) {
        return null; // User cancelled
      }

      // Return filtered message
      return filterInappropriateContent(message);
    }

    return message; // No inappropriate content found
  }

  // Check if message needs moderation (for received messages)
  String moderateReceivedMessage(String message) {
    return filterInappropriateContent(message);
  }
}
