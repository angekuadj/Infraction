class SupportMessageModel {
  final String? id;
  final String? reclamationId;
  final String? sender;
  final String? senderName;
  final String? receiver;
  final String? body;
  final String? message;
  final String? content;
  final bool fromClient;
  final bool fromAgent;
  final DateTime? createdAt;
  final DateTime? sentAt;

  const SupportMessageModel({
    this.id,
    this.reclamationId,
    this.sender,
    this.senderName,
    this.receiver,
    this.body,
    this.message,
    this.content,
    this.fromClient = false,
    this.fromAgent = false,
    this.createdAt,
    this.sentAt,
  });

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: (json['id'] ?? json['_id'])?.toString(),
      reclamationId:
          (json['reclamationId'] ?? json['reclamation_id'])?.toString(),
      sender: json['sender']?.toString(),
      senderName: (json['senderName'] ?? json['sender_name'])?.toString(),
      receiver: json['receiver']?.toString(),
      body: (json['body'] ?? json['message'] ?? json['content'])?.toString(),
      message: json['message']?.toString(),
      content: json['content']?.toString(),
      fromClient: json['fromClient'] as bool? ?? false,
      fromAgent: json['fromAgent'] as bool? ?? false,
      createdAt: _dt(json['createdAt'] ?? json['created_at'] ?? json['date']),
      sentAt: _dt(json['sentAt'] ?? json['sent_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (reclamationId != null) 'reclamationId': reclamationId,
        if (sender != null) 'sender': sender,
        if (senderName != null) 'senderName': senderName,
        if (receiver != null) 'receiver': receiver,
        if (body != null) 'body': body,
        if (message != null) 'message': message,
        if (content != null) 'content': content,
        'fromClient': fromClient,
        'fromAgent': fromAgent,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
      };

  String get displayBody => body ?? message ?? content ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
