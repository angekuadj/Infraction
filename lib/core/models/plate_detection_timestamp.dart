class PlateDetectionTimestamp {
  final String? plate;
  final DateTime? timestamp;
  final double? score;
  final String? imagePath;
  final double? confidence;

  const PlateDetectionTimestamp({
    this.plate,
    this.timestamp,
    this.score,
    this.imagePath,
    this.confidence,
  });

  factory PlateDetectionTimestamp.fromJson(Map<String, dynamic> json) {
    return PlateDetectionTimestamp(
      plate: (json['plate'] ?? json['plaque'])?.toString(),
      timestamp: _dt(json['timestamp'] ?? json['time'] ?? json['date']),
      score: _d(json['score'] ?? json['confidence']),
      imagePath: (json['imagePath'] ?? json['image_path'])?.toString(),
      confidence: _d(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (plate != null) 'plate': plate,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        if (score != null) 'score': score,
        if (imagePath != null) 'imagePath': imagePath,
        if (confidence != null) 'confidence': confidence,
      };

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
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
