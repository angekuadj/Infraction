class NotificationModel {
  final String? id;
  final String? notificationId;
  final String? title;
  final String? body;
  final String? message;
  final String? subject;
  final String? type;
  final bool read;
  final bool seen;
  final DateTime? createdAt;
  final DateTime? seenAt;
  final Map<String, dynamic>? data;

  const NotificationModel({
    this.id,
    this.notificationId,
    this.title,
    this.body,
    this.message,
    this.subject,
    this.type,
    this.read = false,
    this.seen = false,
    this.createdAt,
    this.seenAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? json['_id'])?.toString(),
      notificationId:
          (json['notificationId'] ?? json['notification_id'])?.toString(),
      title: (json['title'] ?? json['subject'])?.toString(),
      body: (json['body'] ?? json['message'])?.toString(),
      message: json['message']?.toString(),
      subject: json['subject']?.toString(),
      type: json['type']?.toString(),
      read: json['read'] as bool? ?? json['isRead'] as bool? ?? false,
      seen: json['seen'] as bool? ?? false,
      createdAt: _dt(json['createdAt'] ?? json['created_at'] ?? json['date']),
      seenAt: _dt(json['seenAt'] ?? json['seen_at']),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (notificationId != null) 'notificationId': notificationId,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (message != null) 'message': message,
        if (subject != null) 'subject': subject,
        if (type != null) 'type': type,
        'read': read,
        'seen': seen,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (seenAt != null) 'seenAt': seenAt!.toIso8601String(),
        if (data != null) 'data': data,
      };

  NotificationModel copyWith({
    String? id,
    String? notificationId,
    String? title,
    String? body,
    String? message,
    String? subject,
    String? type,
    bool? read,
    bool? seen,
    DateTime? createdAt,
    DateTime? seenAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      body: body ?? this.body,
      message: message ?? this.message,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      read: read ?? this.read,
      seen: seen ?? this.seen,
      createdAt: createdAt ?? this.createdAt,
      seenAt: seenAt ?? this.seenAt,
      data: data ?? this.data,
    );
  }

  String get displayTitle => title ?? subject ?? 'Notification';
  String get displayBody => body ?? message ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
