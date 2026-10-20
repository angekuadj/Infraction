import 'package:tflite_flutter/tflite_flutter.dart';

import 'plate_detection_service.dart';

/// Interpréteur TFLite dédié au modèle de détection de plaques.
class PlateTfliteDetector {
  PlateTfliteDetector(this.interpreter);
  final Interpreter interpreter;

  static Future<PlateTfliteDetector> load({
    String asset = PlateDetectionService.modelAsset,
  }) async {
    final options = InterpreterOptions()..threads = 2;
    final interpreter =
        await Interpreter.fromAsset(asset, options: options);
    return PlateTfliteDetector(interpreter);
  }

  bool get isLoaded => interpreter.isAllocated;

  void close() => interpreter.close();
}
