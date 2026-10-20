import 'infraction_report.dart';

enum SubmissionQueueStatus { pending, uploading, processed, failed, rejected }

enum QueueItemStatus { pending, uploading, processed, failed, rejected }

class SubmissionQueueItem {
  final String? id;
  final String? localId;
  final InfractionReport? report;
  final String? status;
  final int? retryCount;
  final DateTime? createdAt;
  final DateTime? sentAt;
  final String? error;
  final bool isUploading;
  final bool isPending;
  final String? videoPath;
  final String? photoPath;

  const SubmissionQueueItem({
    this.id,
    this.localId,
    this.report,
    this.status,
    this.retryCount,
    this.createdAt,
    this.sentAt,
    this.error,
    this.isUploading = false,
    this.isPending = true,
    this.videoPath,
    this.photoPath,
  });

  factory SubmissionQueueItem.fromJson(Map<String, dynamic> json) {
    return SubmissionQueueItem(
      id: (json['id'] ?? json['_id'])?.toString(),
      localId: (json['localId'] ?? json['local_id'])?.toString(),
      report: json['report'] is Map<String, dynamic>
          ? InfractionReport.fromJson(json['report'] as Map<String, dynamic>)
          : null,
      status: (json['status'] ?? json['statut'])?.toString(),
      retryCount: _i(json['retryCount'] ?? json['retry_count']),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      sentAt: _dt(json['sentAt'] ?? json['sent_at']),
      error: (json['error'] ?? json['userMessage'])?.toString(),
      isUploading: json['isUploading'] as bool? ?? false,
      isPending: json['isPending'] as bool? ?? true,
      videoPath: (json['videoPath'] ?? json['video_path'])?.toString(),
      photoPath: (json['photoPath'] ?? json['photo_path'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (localId != null) 'localId': localId,
        if (report != null) 'report': report!.toJson(),
        if (status != null) 'status': status,
        if (retryCount != null) 'retryCount': retryCount,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
        if (error != null) 'error': error,
        'isUploading': isUploading,
        'isPending': isPending,
        if (videoPath != null) 'videoPath': videoPath,
        if (photoPath != null) 'photoPath': photoPath,
      };

  SubmissionQueueItem copyWith({
    String? id,
    String? localId,
    InfractionReport? report,
    String? status,
    int? retryCount,
    DateTime? createdAt,
    DateTime? sentAt,
    String? error,
    bool? isUploading,
    bool? isPending,
    String? videoPath,
    String? photoPath,
  }) {
    return SubmissionQueueItem(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      report: report ?? this.report,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      error: error ?? this.error,
      isUploading: isUploading ?? this.isUploading,
      isPending: isPending ?? this.isPending,
      videoPath: videoPath ?? this.videoPath,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  QueueItemStatus get queueStatus {
    switch (status?.toLowerCase()) {
      case 'uploading':
        return QueueItemStatus.uploading;
      case 'processed':
        return QueueItemStatus.processed;
      case 'failed':
        return QueueItemStatus.failed;
      case 'rejected':
        return QueueItemStatus.rejected;
      case 'pending':
      default:
        return QueueItemStatus.pending;
    }
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
