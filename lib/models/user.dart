class User {
  final String id;
  final String username;
  final String? email;
  final String? bio;
  final String? profileImage;
  final List<String> interests;
  final String language;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isPremium;
  final bool adsFree; // Ads-free status for premium users
  final int credits; // Credits for in-app purchases
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBlocked;
  final bool isFriend;
  final String? deviceId; // For guest users
  final int? age; // New field for age
  final String? gender; // New field for gender

  User({
    required this.id,
    required this.username,
    this.email,
    this.bio,
    this.profileImage,
    this.interests = const [],
    this.language = 'en',
    this.location,
    this.latitude,
    this.longitude,
    this.isOnline = false,
    this.lastSeen,
    this.isPremium = false,
    this.adsFree = false, // Default to showing ads
    this.credits = 100, // Default credits for new users
    required this.createdAt,
    required this.updatedAt,
    this.isBlocked = false,
    this.isFriend = false,
    this.deviceId,
    this.age,
    this.gender,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? bio,
    String? profileImage,
    List<String>? interests,
    String? language,
    String? location,
    double? latitude,
    double? longitude,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isPremium,
    bool? adsFree,
    int? credits,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBlocked,
    bool? isFriend,
    String? deviceId,
    int? age,
    String? gender,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      interests: interests ?? this.interests,
      language: language ?? this.language,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isPremium: isPremium ?? this.isPremium,
      adsFree: adsFree ?? this.adsFree,
      credits: credits ?? this.credits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBlocked: isBlocked ?? this.isBlocked,
      isFriend: isFriend ?? this.isFriend,
      deviceId: deviceId ?? this.deviceId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'bio': bio,
      'profileImage': profileImage,
      'interests': interests,
      'language': language,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
             'isOnline': isOnline,
       'lastSeen': lastSeen?.toIso8601String(),
       'isPremium': isPremium,
       'adsFree': adsFree,
       'credits': credits,
       'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isBlocked': isBlocked,
      'isFriend': isFriend,
      'deviceId': deviceId,
      'age': age,
      'gender': gender,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Add debugging to see what data we're receiving
    // print('🔍 DEBUG: User.fromJson called with: $json');

    // Handle backend response format (uid, displayName, photoURL)
    // vs the expected model format (id, username, profileImage)

    try {
      final String? userIdRaw = json['uid'] ?? json['id'] ?? json['userId'];
      if (userIdRaw == null || userIdRaw.isEmpty) {
        throw Exception('User ID is required but not provided in JSON: $json');
      }
      final String userId = userIdRaw;

      // Safely extract string values with fallbacks
      String userName = 'Anonymous User';
      if (json['displayName'] != null && json['displayName'] is String) {
        userName = json['displayName'] as String;
      } else if (json['username'] != null && json['username'] is String) {
        userName = json['username'] as String;
      }

      String? userEmail;
      if (json['email'] != null && json['email'] is String) {
        userEmail = json['email'] as String;
      }

      String? userProfileImage;
      if (json['photoURL'] != null && json['photoURL'] is String) {
        userProfileImage = json['photoURL'] as String;
      } else if (json['profileImage'] != null &&
          json['profileImage'] is String) {
        userProfileImage = json['profileImage'] as String;
      } else if (json['profilePicture'] != null &&
          json['profilePicture'] is String) {
        userProfileImage = json['profilePicture'] as String;
      }

      // print('🔍 DEBUG: Profile image URL extracted: $userProfileImage');

      // Keep for future use if needed
      // final bool isAnonymousUser = json['isAnonymous'] as bool? ?? false;

      // print(
      //     '🔍 DEBUG: Extracted user data - ID: $userId, Name: $userName, Email: $userEmail');

      // Handle DateTime fields that might be Firestore timestamps
      DateTime createdAtDate = DateTime.now();
      if (json['createdAt'] != null) {
        // print(
        //     '🔍 DEBUG: createdAt type: ${json['createdAt'].runtimeType}, value: ${json['createdAt']}');
        if (json['createdAt'] is String) {
          createdAtDate = DateTime.parse(json['createdAt'] as String);
        } else if (json['createdAt'] is Map) {
          // Handle Firestore timestamp format
          final timestamp = json['createdAt'] as Map<String, dynamic>;
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            createdAtDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
            // print('🔍 DEBUG: Converted createdAt timestamp: $createdAtDate');
          }
        }
      }

      DateTime updatedAtDate = DateTime.now();
      if (json['updatedAt'] != null) {
        // print(
        //     '🔍 DEBUG: updatedAt type: ${json['updatedAt'].runtimeType}, value: ${json['updatedAt']}');
        if (json['updatedAt'] is String) {
          updatedAtDate = DateTime.parse(json['updatedAt'] as String);
        } else if (json['updatedAt'] is Map) {
          // Handle Firestore timestamp format
          final timestamp = json['updatedAt'] as Map<String, dynamic>;
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            updatedAtDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
            // print('🔍 DEBUG: Converted updatedAt timestamp: $updatedAtDate');
          }
        }
      }

      // Handle lastSeen which might also be a timestamp
      DateTime? lastSeenDate;
      if (json['lastSeen'] != null) {
        // print(
        //     '🔍 DEBUG: lastSeen type: ${json['lastSeen'].runtimeType}, value: ${json['lastSeen']}');
        if (json['lastSeen'] is String) {
          lastSeenDate = DateTime.parse(json['lastSeen'] as String);
        } else if (json['lastSeen'] is Map) {
          // Handle Firestore timestamp format
          final timestamp = json['lastSeen'] as Map<String, dynamic>;
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            lastSeenDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
            // print('🔍 DEBUG: Converted lastSeen timestamp: $lastSeenDate');
          }
        }
      }

      // Handle lastLoginAt which might also be a timestamp
      if (json['lastLoginAt'] != null) {
        // print(
        //     '🔍 DEBUG: lastLoginAt type: ${json['lastLoginAt'].runtimeType}, value: ${json['lastLoginAt']}');
        // We don't store lastLoginAt in the User model, but we should handle it gracefully
      }

      return User(
        id: userId,
        username: userName,
        email: userEmail,
        bio: json['bio'] as String?,
        profileImage: userProfileImage,
        interests: List<String>.from(json['interests'] ?? []),
        language: json['language'] as String? ?? 'en',
        location: json['location'] as String?,
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
                 isOnline: json['isOnline'] as bool? ?? false,
         lastSeen: lastSeenDate,
         isPremium: json['isPremium'] as bool? ?? false,
         adsFree: json['adsFree'] as bool? ?? false, // Default to showing ads
         credits: json['credits'] as int? ?? 100, // Default 100 credits for all users
         createdAt: createdAtDate,
        updatedAt: updatedAtDate,
        isBlocked: json['isBlocked'] as bool? ?? false,
        isFriend: json['isFriend'] as bool? ?? false,
        deviceId: json['deviceId'] as String?,
        age: json['age'] as int?,
        gender: json['gender'] as String?,
      );
    } catch (e) {
      // print('❌ ERROR: User.fromJson failed - $e');
      // print('🔍 DEBUG: JSON data was: $json');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, isOnline: $isOnline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  bool get isGuest => deviceId != null;
  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  String get displayName => username;

  // Check if user has completed mandatory profile fields
  bool get hasCompletedProfile {
    return username.isNotEmpty &&
        age != null &&
        gender != null &&
        gender!.isNotEmpty;
  }

  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    }
    return 'Offline';
  }
}
