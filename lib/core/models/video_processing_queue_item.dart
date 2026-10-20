enum VideoProcessingStatus { pending, processing, analyzed, failed }

class VideoProcessingQueueItem {
  final String? id;
  final String? localId;
  final String? videoPath;
  final String? status;
  final String? plate;
  final double? score;
  final DateTime? createdAt;
  final DateTime? processedAt;
  final String? error;
  final int? retryCount;
  final bool isProcessing;

  const VideoProcessingQueueItem({
    this.id,
    this.localId,
    this.videoPath,
    this.status,
    this.plate,
    this.score,
    this.createdAt,
    this.processedAt,
    this.error,
    this.retryCount,
    this.isProcessing = false,
  });

  factory VideoProcessingQueueItem.fromJson(Map<String, dynamic> json) {
    return VideoProcessingQueueItem(
      id: (json['id'] ?? json['_id'])?.toString(),
      localId: (json['localId'] ?? json['local_id'])?.toString(),
      videoPath: (json['videoPath'] ?? json['video_path'])?.toString(),
      status: (json['status'] ?? json['statut'])?.toString(),
      plate: (json['plate'] ?? json['plaque'])?.toString(),
      score: _d(json['score'] ?? json['confidence']),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      processedAt: _dt(json['processedAt'] ?? json['processed_at']),
      error: json['error']?.toString(),
      retryCount: _i(json['retryCount'] ?? json['retry_count']),
      isProcessing: json['isProcessing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (localId != null) 'localId': localId,
        if (videoPath != null) 'videoPath': videoPath,
        if (status != null) 'status': status,
        if (plate != null) 'plate': plate,
        if (score != null) 'score': score,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
        if (error != null) 'error': error,
        if (retryCount != null) 'retryCount': retryCount,
        'isProcessing': isProcessing,
      };

  VideoProcessingQueueItem copyWith({
    String? id,
    String? localId,
    String? videoPath,
    String? status,
    String? plate,
    double? score,
    DateTime? createdAt,
    DateTime? processedAt,
    String? error,
    int? retryCount,
    bool? isProcessing,
  }) {
    return VideoProcessingQueueItem(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      videoPath: videoPath ?? this.videoPath,
      status: status ?? this.status,
      plate: plate ?? this.plate,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      error: error ?? this.error,
      retryCount: retryCount ?? this.retryCount,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  VideoProcessingStatus get videoStatus {
    switch (status?.toLowerCase()) {
      case 'processing':
        return VideoProcessingStatus.processing;
      case 'analyzed':
      case 'done':
        return VideoProcessingStatus.analyzed;
      case 'failed':
        return VideoProcessingStatus.failed;
      case 'pending':
      default:
        return VideoProcessingStatus.pending;
    }
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
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
