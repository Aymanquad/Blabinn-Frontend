
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBlocked;
  final bool isFriend;
  final String? deviceId; // For guest users

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
    required this.createdAt,
    required this.updatedAt,
    this.isBlocked = false,
    this.isFriend = false,
    this.deviceId,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBlocked,
    bool? isFriend,
    String? deviceId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBlocked: isBlocked ?? this.isBlocked,
      isFriend: isFriend ?? this.isFriend,
      deviceId: deviceId ?? this.deviceId,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isBlocked': isBlocked,
      'isFriend': isFriend,
      'deviceId': deviceId,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      profileImage: json['profileImage'] as String?,
      interests: List<String>.from(json['interests'] ?? []),
      language: json['language'] as String? ?? 'en',
      location: json['location'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isBlocked: json['isBlocked'] as bool? ?? false,
      isFriend: json['isFriend'] as bool? ?? false,
      deviceId: json['deviceId'] as String?,
    );
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