import 'dart:io';

import 'package:flutter/services.dart';

/// Découpage vidéo natif Android (copie des pistes sans ré-encodage).
class VideoTrimService {
  static const MethodChannel _channel =
      MethodChannel('net.circulation.ci.circulation/video_trim');

  Future<String?> trim({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
  }) async {
    if (!Platform.isAndroid) return null;
    if (end <= start) return null;
    try {
      return await _channel.invokeMethod<String>('trim', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'startMs': start.inMilliseconds,
        'endMs': end.inMilliseconds,
      });
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
