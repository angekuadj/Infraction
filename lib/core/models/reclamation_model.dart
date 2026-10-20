class ReclamationModel {
  final String? id;
  final String? reclamationId;
  final String? subject;
  final String? title;
  final String? message;
  final String? body;
  final String? status;
  final String? clientId;
  final String? clientName;
  final String? userId;
  final String? userName;
  final String? assignedTo;
  final String? agentName;
  final bool closed;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;

  const ReclamationModel({
    this.id,
    this.reclamationId,
    this.subject,
    this.title,
    this.message,
    this.body,
    this.status,
    this.clientId,
    this.clientName,
    this.userId,
    this.userName,
    this.assignedTo,
    this.agentName,
    this.closed = false,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
  });

  factory ReclamationModel.fromJson(Map<String, dynamic> json) {
    return ReclamationModel(
      id: (json['id'] ?? json['_id'])?.toString(),
      reclamationId:
          (json['reclamationId'] ?? json['reclamation_id'])?.toString(),
      subject: json['subject']?.toString(),
      title: (json['title'] ?? json['subject'])?.toString(),
      message: (json['message'] ?? json['body'])?.toString(),
      body: json['body']?.toString(),
      status: (json['status'] ?? json['statut'])?.toString(),
      clientId: (json['clientId'] ?? json['client_id'])?.toString(),
      clientName: (json['clientName'] ?? json['client_name'])?.toString(),
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      userName: (json['userName'] ?? json['user_name'])?.toString(),
      assignedTo: (json['assignedTo'] ?? json['assigned_to'])?.toString(),
      agentName: (json['agentName'] ?? json['agent_name'])?.toString(),
      closed: json['closed'] as bool? ?? false,
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      updatedAt: _dt(json['updatedAt'] ?? json['updated_at']),
      closedAt: _dt(json['closedAt'] ?? json['closed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (reclamationId != null) 'reclamationId': reclamationId,
        if (subject != null) 'subject': subject,
        if (title != null) 'title': title,
        if (message != null) 'message': message,
        if (body != null) 'body': body,
        if (status != null) 'status': status,
        if (clientId != null) 'clientId': clientId,
        if (clientName != null) 'clientName': clientName,
        if (userId != null) 'userId': userId,
        if (userName != null) 'userName': userName,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (agentName != null) 'agentName': agentName,
        'closed': closed,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
      };

  String get displayTitle => title ?? subject ?? 'Réclamation';
  String get displayMessage => message ?? body ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
