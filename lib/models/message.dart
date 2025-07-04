
enum MessageType {
  text,
  image,
  location,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? translatedContent;
  final String? originalLanguage;
  final String? translatedLanguage;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool isEdited;
  final DateTime? editedAt;
  final List<String> readBy;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.translatedContent,
    this.originalLanguage,
    this.translatedLanguage,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    this.isEdited = false,
    this.editedAt,
    this.readBy = const [],
  });

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? translatedContent,
    String? originalLanguage,
    String? translatedLanguage,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isEdited,
    DateTime? editedAt,
    List<String>? readBy,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      translatedContent: translatedContent ?? this.translatedContent,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      translatedLanguage: translatedLanguage ?? this.translatedLanguage,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      readBy: readBy ?? this.readBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'translatedContent': translatedContent,
      'originalLanguage': originalLanguage,
      'translatedLanguage': translatedLanguage,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'readBy': readBy,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      translatedContent: json['translatedContent'] as String?,
      originalLanguage: json['originalLanguage'] as String?,
      translatedLanguage: json['translatedLanguage'] as String?,
      imageUrl: json['imageUrl'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationName: json['locationName'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null 
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      readBy: List<String>.from(json['readBy'] ?? []),
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, content: $content, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isLocation => type == MessageType.location;
  bool get isSystem => type == MessageType.system;
  
  bool get isFromMe => senderId == 'currentUserId'; // This will be set by provider
  bool get isRead => readBy.isNotEmpty;
  bool get hasTranslation => translatedContent != null && translatedContent!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  
  String get displayContent {
    if (hasTranslation) {
      return translatedContent!;
    }
    return content;
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
  
  String get statusText {
    switch (status) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }
} 