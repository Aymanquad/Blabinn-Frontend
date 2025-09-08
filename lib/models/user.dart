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
  
  // Chatify User Type System
  final String userType; // 'guest', 'signed_up_free', 'premium'
  final bool isVerified; // Verification status for signed-up/premium users
  final DateTime? verificationDate; // When user was verified
  final int connectCount; // Track number of connects for ad triggers
  final int pageSwitchCount; // Track page switches for ad triggers
  final DateTime? lastPageSwitchTime; // Reset counter periodically
  final int dailyAdViews; // Track daily reward ad views
  final DateTime? lastAdViewDate; // Reset daily counter
  final int superLikesUsed; // Track superlikes used this period
  final int boostsUsed; // Track boosts used this period
  final int friendsCount; // Track friends count for premium limits
  final int whoLikedViews; // Track "Who Liked You" views
  final DateTime? lastWhoLikedViewDate; // Reset daily counter

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
    this.userType = 'guest', // Default to guest
    this.isVerified = false,
    this.verificationDate,
    this.connectCount = 0,
    this.pageSwitchCount = 0,
    this.lastPageSwitchTime,
    this.dailyAdViews = 0,
    this.lastAdViewDate,
    this.superLikesUsed = 0,
    this.boostsUsed = 0,
    this.friendsCount = 0,
    this.whoLikedViews = 0,
    this.lastWhoLikedViewDate,
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
    String? userType,
    bool? isVerified,
    DateTime? verificationDate,
    int? connectCount,
    int? pageSwitchCount,
    DateTime? lastPageSwitchTime,
    int? dailyAdViews,
    DateTime? lastAdViewDate,
    int? superLikesUsed,
    int? boostsUsed,
    int? friendsCount,
    int? whoLikedViews,
    DateTime? lastWhoLikedViewDate,
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
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      verificationDate: verificationDate ?? this.verificationDate,
      connectCount: connectCount ?? this.connectCount,
      pageSwitchCount: pageSwitchCount ?? this.pageSwitchCount,
      lastPageSwitchTime: lastPageSwitchTime ?? this.lastPageSwitchTime,
      dailyAdViews: dailyAdViews ?? this.dailyAdViews,
      lastAdViewDate: lastAdViewDate ?? this.lastAdViewDate,
      superLikesUsed: superLikesUsed ?? this.superLikesUsed,
      boostsUsed: boostsUsed ?? this.boostsUsed,
      friendsCount: friendsCount ?? this.friendsCount,
      whoLikedViews: whoLikedViews ?? this.whoLikedViews,
      lastWhoLikedViewDate: lastWhoLikedViewDate ?? this.lastWhoLikedViewDate,
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
      'userType': userType,
      'isVerified': isVerified,
      'verificationDate': verificationDate?.toIso8601String(),
      'connectCount': connectCount,
      'pageSwitchCount': pageSwitchCount,
      'lastPageSwitchTime': lastPageSwitchTime?.toIso8601String(),
      'dailyAdViews': dailyAdViews,
      'lastAdViewDate': lastAdViewDate?.toIso8601String(),
      'superLikesUsed': superLikesUsed,
      'boostsUsed': boostsUsed,
      'friendsCount': friendsCount,
      'whoLikedViews': whoLikedViews,
      'lastWhoLikedViewDate': lastWhoLikedViewDate?.toIso8601String(),
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

      // Handle new user type fields
      DateTime? verificationDate;
      if (json['verificationDate'] != null) {
        if (json['verificationDate'] is String) {
          verificationDate = DateTime.parse(json['verificationDate'] as String);
        } else if (json['verificationDate'] is Map) {
          final timestamp = json['verificationDate'] as Map<String, dynamic>;
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            verificationDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
      }

      DateTime? lastPageSwitchTime;
      if (json['lastPageSwitchTime'] != null) {
        if (json['lastPageSwitchTime'] is String) {
          lastPageSwitchTime = DateTime.parse(json['lastPageSwitchTime'] as String);
        } else if (json['lastPageSwitchTime'] is Map) {
          final timestamp = json['lastPageSwitchTime'] as Map<String, dynamic>;
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            lastPageSwitchTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
      }

      DateTime? lastAdViewDate;
      if (json['lastAdViewDate'] != null) {
        if (json['lastAdViewDate'] is String) {
          lastAdViewDate = DateTime.parse(json['lastAdViewDate'] as String);
        } else if (json['lastAdViewDate'] is Map) {
          final timestamp = json['lastAdViewDate'] as Map<String, dynamic>;
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            lastAdViewDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
      }

      DateTime? lastWhoLikedViewDate;
      if (json['lastWhoLikedViewDate'] != null) {
        if (json['lastWhoLikedViewDate'] is String) {
          lastWhoLikedViewDate = DateTime.parse(json['lastWhoLikedViewDate'] as String);
        } else if (json['lastWhoLikedViewDate'] is Map) {
          final timestamp = json['lastWhoLikedViewDate'] as Map<String, dynamic>;
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            lastWhoLikedViewDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
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
        userType: json['userType'] as String? ?? 'guest',
        isVerified: json['isVerified'] as bool? ?? false,
        verificationDate: verificationDate,
        connectCount: json['connectCount'] as int? ?? 0,
        pageSwitchCount: json['pageSwitchCount'] as int? ?? 0,
        lastPageSwitchTime: lastPageSwitchTime,
        dailyAdViews: json['dailyAdViews'] as int? ?? 0,
        lastAdViewDate: lastAdViewDate,
        superLikesUsed: json['superLikesUsed'] as int? ?? 0,
        boostsUsed: json['boostsUsed'] as int? ?? 0,
        friendsCount: json['friendsCount'] as int? ?? 0,
        whoLikedViews: json['whoLikedViews'] as int? ?? 0,
        lastWhoLikedViewDate: lastWhoLikedViewDate,
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

  // User type helper methods
  bool get isGuestUser => userType == 'guest';
  bool get isSignedUpFree => userType == 'signed_up_free';
  bool get isPremiumUser => userType == 'premium';

  // Get user type badge information
  Map<String, dynamic> get userTypeBadge {
    switch (userType) {
      case 'guest':
        return {
          'type': 'guest',
          'label': 'Anonymous',
          'color': 0xFF6B7280, // Gray
          'icon': '👤'
        };
      case 'signed_up_free':
        return {
          'type': 'signed_up_free',
          'label': 'Free',
          'color': 0xFF3B82F6, // Blue
          'icon': '⭐'
        };
      case 'premium':
        return {
          'type': 'premium',
          'label': 'Premium',
          'color': 0xFFF59E0B, // Amber
          'icon': '👑'
        };
      default:
        return {
          'type': 'guest',
          'label': 'Anonymous',
          'color': 0xFF6B7280,
          'icon': '👤'
        };
    }
  }

  // Check if user can match with another user type
  bool canMatchWith(String otherUserType) {
    switch (userType) {
      case 'guest':
        return otherUserType == 'guest';
      case 'signed_up_free':
        return otherUserType == 'signed_up_free' || otherUserType == 'premium';
      case 'premium':
        return true; // Premium users can match with everyone
      default:
        return false;
    }
  }

  // Check if user has access to a feature
  bool hasFeatureAccess(String feature) {
    // Special rule: Women get all features free (except ads)
    if (gender == 'female' && feature != 'ads_free') {
      return true;
    }

    switch (feature) {
      case 'add_friends':
        return userType != 'guest';
      case 'send_images':
        return userType != 'guest';
      case 'instant_match':
        return userType == 'premium';
      case 'unlimited_friends':
        return userType == 'premium';
      case 'unlimited_who_liked':
        return userType == 'premium';
      case 'ads_free':
        return userType == 'premium';
      case 'boosts':
        return userType == 'premium';
      case 'superlikes':
        return userType == 'premium';
      default:
        return false;
    }
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
