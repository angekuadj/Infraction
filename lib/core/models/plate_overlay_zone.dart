import 'dart:ui';

class PlateOverlayZone {
  final double left;
  final double top;
  final double width;
  final double height;
  final String? plate;
  final double? confidence;
  final Color? color;

  const PlateOverlayZone({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.plate,
    this.confidence,
    this.color,
  });

  factory PlateOverlayZone.fromJson(Map<String, dynamic> json) {
    return PlateOverlayZone(
      left: _d(json['left'] ?? json['x']) ?? 0,
      top: _d(json['top'] ?? json['y']) ?? 0,
      width: _d(json['width']) ?? 0,
      height: _d(json['height']) ?? 0,
      plate: json['plate']?.toString(),
      confidence: _d(json['confidence'] ?? json['score']),
      color: json['color'] is int ? Color(json['color'] as int) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        if (plate != null) 'plate': plate,
        if (confidence != null) 'confidence': confidence,
        if (color != null) 'color': color!.toARGB32(),
      };

  Rect get rect => Rect.fromLTWH(left, top, width, height);

  PlateOverlayZone copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    String? plate,
    double? confidence,
    Color? color,
  }) {
    return PlateOverlayZone(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      plate: plate ?? this.plate,
      confidence: confidence ?? this.confidence,
      color: color ?? this.color,
    );
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
