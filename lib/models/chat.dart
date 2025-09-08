import 'message.dart';

enum ChatType {
  random, // Random match
  friend, // Friend chat
  group, // Group chat (future feature)
}

enum ChatStatus {
  active,
  archived,
  blocked,
  deleted,
  ended,
  reported,
}

class Chat {
  final String id;
  final String name;
  final List<String> participantIds;
  final ChatType type;
  final ChatStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;
  final int unreadCount;
  final bool isTyping;
  final List<String> typingUsers;
  final Map<String, DateTime> lastSeen;
  final String? imageUrl;
  final String? description;
  final String? participant1Id;
  final String? participant2Id;
  final DateTime? lastMessageAt;
  final DateTime? endedAt;
  final String? reason;

  Chat({
    required this.id,
    required this.name,
    required this.participantIds,
    this.type = ChatType.random,
    this.status = ChatStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isTyping = false,
    this.typingUsers = const [],
    this.lastSeen = const {},
    this.imageUrl,
    this.description,
    this.participant1Id,
    this.participant2Id,
    this.lastMessageAt,
    this.endedAt,
    this.reason,
  });

  Chat copyWith({
    String? id,
    String? name,
    List<String>? participantIds,
    ChatType? type,
    ChatStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Message? lastMessage,
    int? unreadCount,
    bool? isTyping,
    List<String>? typingUsers,
    Map<String, DateTime>? lastSeen,
    String? imageUrl,
    String? description,
    String? participant1Id,
    String? participant2Id,
    DateTime? lastMessageAt,
    DateTime? endedAt,
    String? reason,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      participantIds: participantIds ?? this.participantIds,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
      typingUsers: typingUsers ?? this.typingUsers,
      lastSeen: lastSeen ?? this.lastSeen,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      endedAt: endedAt ?? this.endedAt,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participantIds': participantIds,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'typingUsers': typingUsers,
      'lastSeen':
          lastSeen.map((key, value) => MapEntry(key, value.toIso8601String())),
      'imageUrl': imageUrl,
      'description': description,
      'participant1Id': participant1Id,
      'participant2Id': participant2Id,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'reason': reason,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      name: json['name'] as String,
      participantIds: List<String>.from(json['participantIds']),
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.random,
      ),
      status: ChatStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChatStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isTyping: json['isTyping'] as bool? ?? false,
      typingUsers: List<String>.from(json['typingUsers'] ?? []),
      lastSeen: (json['lastSeen'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, DateTime.parse(value as String)),
          ) ??
          {},
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      participant1Id: json['participant1Id'] as String?,
      participant2Id: json['participant2Id'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      reason: json['reason'] as String?,
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, name: $name, type: $type, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  bool get isRandomChat => type == ChatType.random;
  bool get isFriendChat => type == ChatType.friend;
  bool get isGroupChat => type == ChatType.group;

  bool get isActive => status == ChatStatus.active;
  bool get isArchived => status == ChatStatus.archived;
  bool get isBlocked => status == ChatStatus.blocked;
  bool get isDeleted => status == ChatStatus.deleted;

  bool get hasUnreadMessages => unreadCount > 0;
  bool get hasLastMessage => lastMessage != null;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  String get displayName {
    if (isRandomChat) {
      return 'Random Chat';
    }
    return name;
  }

  String get lastMessageText {
    if (lastMessage == null) return 'No messages yet';

    switch (lastMessage!.type) {
      case MessageType.text:
        return lastMessage!.displayContent;
      case MessageType.image:
        return '📷 Image';
      case MessageType.viewOnceImage:
        return '🕒 View-once image';
      case MessageType.viewOnceVideo:
        return '🕒 View-once video';
      case MessageType.location:
        return '📍 Location';
      case MessageType.system:
        return lastMessage!.displayContent;
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📎 File';
    }
  }

  String get lastMessageTime {
    if (lastMessage == null) return '';
    return lastMessage!.timeAgo;
  }

  bool isParticipant(String userId) {
    return participantIds.contains(userId);
  }

  bool isTypingBy(String userId) {
    return typingUsers.contains(userId);
  }

  DateTime? getLastSeen(String userId) {
    return lastSeen[userId];
  }

  String? getOtherParticipantId(String currentUserId) {
    if (participantIds.length != 2) return null;
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String get typingText {
    if (typingUsers.isEmpty) return '';
    if (typingUsers.length == 1) {
      return '${typingUsers.first} is typing...';
    }
    return '${typingUsers.length} people are typing...';
  }

  // Factory methods for different chat types
  factory Chat.random({
    required String id,
    required List<String> participantIds,
    DateTime? createdAt,
  }) {
    return Chat(
      id: id,
      name: 'Random Chat',
      participantIds: participantIds,
      type: ChatType.random,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: createdAt ?? DateTime.now(),
    );
  }

  factory Chat.friend({
    required String id,
    required String name,
    required List<String> participantIds,
    DateTime? createdAt,
  }) {
    return Chat(
      id: id,
      name: name,
      participantIds: participantIds,
      type: ChatType.friend,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: createdAt ?? DateTime.now(),
    );
  }

  factory Chat.group({
    required String id,
    required String name,
    required List<String> participantIds,
    DateTime? createdAt,
  }) {
    return Chat(
      id: id,
      name: name,
      participantIds: participantIds,
      type: ChatType.group,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: createdAt ?? DateTime.now(),
    );
  }

  // Helper methods for participant management
  bool hasParticipant(String userId) {
    return participantIds.contains(userId);
  }

  String getOtherParticipant(String currentUserId) {
    if (participantIds.length != 2) return '';
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  List<String> getOtherParticipants(String currentUserId) {
    return participantIds.where((id) => id != currentUserId).toList();
  }
}
