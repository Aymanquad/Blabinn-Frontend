import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class ChatModerationService {
  static final ChatModerationService _instance = ChatModerationService._internal();
  factory ChatModerationService() => _instance;
  ChatModerationService._internal();

  // Inappropriate words database
  final Set<String> _inappropriateWords = {
    // Racial slurs and offensive terms
    'nigger', 'nigga', 'faggot', 'fag', 'dyke', 'kike', 'spic', 'chink', 'gook', 'wop', 'dago', 'kraut', 'haji', 'raghead',
    'coon', 'jigaboo', 'spook', 'junglebunny', 'porchmonkey', 'mudshark',
    'cholo', 'beaner', 'wetback','greaser', 'taco', 'borderhopper', 'mexican',
     'slant',
    'towelhead', 'cameljockey', 'sandnigger', 'sandmonkey', 'dune',
    'honky', 'cracker', 'redneck', 'hillbilly',
    'polack', 'commie', 'red',  'nazi', 'hitler', 'german', 'fritz',
    'paddy', 'mick', 'frog', 'french', 
    'jew', 'jewish', 'hebrew', 'zionist', 'jewboy', 'jewess', 'yid', 'yiddish',
    
    // Terrorism and violence related
    'terrorist', 'terrorism', 'bomb', 'explosive', 'suicide', 'attack', 'kill', 'murder', 'assassinate',
    'jihad', 'jihadi', 'islamic', 'state', 'isis', 'isil', 'al', 'qaeda', 'taliban', 'extremist',
    'radical', 'fundamentalist', 'militant', 'insurgent', 'guerilla', 'terror', 'violence', 'hate',
    'racist', 'racism', 'bigot', 'bigotry', 'discrimination', 'prejudice', 'xenophobe', 'xenophobia',
    
    // General slurs and offensive terms
    'bitch', 'whore', 'slut', 'cunt', 'pussy', 'dick', 'cock', 'penis', 'vagina', 'asshole', 'bastard',
    'motherfucker', 'fuck', 'shit', 'damn', 'hell',
    'retard', 'retarded', 'idiot', 'stupid', 'dumb', 'moron', 'imbecile', 'cretin', 'handicapped',
    'cripple', 'gimp', 'spaz', 'autistic', 'asperger', 'down', 'syndrome', 'special', 'needs',
    
    // Gender and sexuality slurs
    'lesbian', 'queer', 'tranny', 'trans', 'shemale', 'ladyboy',
    'butch', 'femme', 'drag', 'queen', 'king', 'bear', 'twink', 'otter',
    
    // Religious slurs
    'infidel', 'kafir', 'mushrik', 'polytheist', 'idolater', 'heathen', 'pagan', 'heretic', 'blasphemer',
    'apostate', 'renegade', 'deceiver', 'liar', 'hypocrite', 'pharisee',
    
    // Political and social slurs
     'communist', 'socialist', 'liberal', 'conservative', 'republican', 'democrat', 'fascist',
    'stalin', 'mao', 'lenin', 'marx', 'engels', 'capitalist', 'imperialist',
    'colonialist', 'oppressor', 'exploiter', 'parasite', 'leech', 'bloodsucker', 'vampire',
    
    
    // Mental health slurs
    'psychotic', 'schizophrenic', 'bipolar',
    'manic', 'suicidal', 'homicidal', 'violent', 'aggressive', 'hostile',
    'paranoid', 'delusional', 'hallucinating', 'disordered', 'dysfunctional', 



    'himmler', 'göring', 'goebbels', 'pol pot', 'osama', 'bin laden', 'breivik', 'dylann', 'roof',

    '9/11', '911', 'holocaust', 'genocide', 'massacre', 'ethnic cleansing',  'kkk', 'klan', 'white power',

    'final solution', 'zionism', 'apartheid', 'slavery', 'lynching', 'gulag'

    //🏴‍☠️ Militant or Hate Group References
    'white supremacist', 'neo-nazi', 'alt-right', 'far-right', 'hate group', 'boogaloo', 'proud boys', 'antifa'

    //👶 Child Exploitation / CSA (Highly Sensitive — Strongly Ban These)
    'cp', 'child porn', 'pedo', 'pedophile', 'groomer', 'map', 'minor attracted', 'incest', 'lolicon', 'shota', 'loli'

    //💣 Mass Violence / School Shooting References
    'columbine', 'sandy hook', 'uvalde', 'mass shooter', 'school shooter', 'gunman', 'assault rifle', 'ar-15'

    //📵 Additional Slurs or Obscenities
    'twat', 'slag', 'skank', 'cum', 'jizz', 'nut', 'orgasm', 'rape', 'rapist', 'molest', 'molester',

    'titty', 'boob', 'boobs', 'tits', 'nipple', 'arse', 'jerkoff', 'wanker', 'tosser',

    'paki', 'gypsy', 'bimbo', 'camel humper', 'ape', 'nutter'

    //🔪 Graphic Violence Terms
    'stab', 'shoot', 'decapitate', 'torture', 'strangle', 'behead', 'slit throat', 'hang', 'lynch'

    //⚠️ Self-Harm References (Filter or flag for intervention)
    'cut myself', 'kill myself', 'end it all', 'no reason to live', 'I want to die', 'take my life'
    

  
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
  Future<bool> showWarningDialog(BuildContext context, List<String> inappropriateWords) async {
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    ) ?? false;
  }

  // Process message before sending
  Future<String?> processMessageForSending(BuildContext context, String message) async {
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