class Report {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String? description;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      reporterId: json['reporterId'] ?? '',
      reportedUserId: json['reportedUserId'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      reviewedAt: json['reviewedAt'] != null 
          ? DateTime.parse(json['reviewedAt']) 
          : null,
      reviewedBy: json['reviewedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
    };
  }

  String getReasonDisplayText() {
    const reasonMap = {
      'sexual_content': 'Sexual content',
      'violent_content': 'Violent or repulsive content',
      'hateful_content': 'Hateful or abusive content',
      'harmful_content': 'Harmful or dangerous acts',
      'spam_content': 'Spam or misleading',
      'child_abuse': 'Child abuse',
    };
    return reasonMap[reason] ?? reason;
  }

  String getStatusDisplayText() {
    const statusMap = {
      'pending': 'Pending',
      'reviewed': 'Reviewed',
      'resolved': 'Resolved',
      'dismissed': 'Dismissed',
    };
    return statusMap[status] ?? status;
  }

  Report copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? reason,
    String? description,
    String? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}

class ReportReason {
  static const String sexualContent = 'sexual_content';
  static const String violentContent = 'violent_content';
  static const String hatefulContent = 'hateful_content';
  static const String harmfulContent = 'harmful_content';
  static const String spamContent = 'spam_content';
  static const String childAbuse = 'child_abuse';

  static const List<String> allReasons = [
    sexualContent,
    violentContent,
    hatefulContent,
    harmfulContent,
    spamContent,
    childAbuse,
  ];

  static String getDisplayText(String reason) {
    const reasonMap = {
      sexualContent: 'Sexual content',
      violentContent: 'Violent or repulsive content',
      hatefulContent: 'Hateful or abusive content',
      harmfulContent: 'Harmful or dangerous acts',
      spamContent: 'Spam or misleading',
      childAbuse: 'Child abuse',
    };
    return reasonMap[reason] ?? reason;
  }
}
