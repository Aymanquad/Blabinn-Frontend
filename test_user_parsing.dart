// Test script to verify User.fromJson handles Firestore timestamps correctly
import 'dart:convert';
import 'lib/models/user.dart';

void main() {
  print('🧪 Testing User.fromJson with Firestore timestamp format...');
  
  // Test data that matches the format from your debug output
  final testUserData = {
    'uid': 'IGUU5kLDc5OaTcEQs7QkCypSixh2',
    'email': 'kira.note7799@gmail.com',
    'displayName': 'Ayman Quadri',
    'photoURL': 'https://lh3.googleusercontent.com/a/ACg8ocIbKpmKiC20Q7VXmAr8lGLISZN2s5BcExGVljlCDY74DAnE=s96-c',
    'isAnonymous': false,
    'createdAt': {
      '_seconds': 1751819484,
      '_nanoseconds': 109000000
    },
    'lastLoginAt': {
      '_seconds': 1751820785,
      '_nanoseconds': 850000000
    }
  };
  
  try {
    print('📋 Test data: ${jsonEncode(testUserData)}');
    
    // Test User.fromJson
    final user = User.fromJson(testUserData);
    
    print('✅ SUCCESS: User created successfully!');
    print('👤 User ID: ${user.id}');
    print('📛 Username: ${user.username}');
    print('📧 Email: ${user.email}');
    print('🖼️ Profile Image: ${user.profileImage}');
    print('📅 Created At: ${user.createdAt}');
    print('📅 Updated At: ${user.updatedAt}');
    print('🔗 Is Guest: ${user.isGuest}');
    
  } catch (e) {
    print('❌ ERROR: User.fromJson failed - $e');
    print('🔍 This indicates the fix needs more work.');
  }
  
  print('\n🏁 Test completed!');
} 