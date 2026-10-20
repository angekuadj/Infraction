import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/plate_overlay_zone.dart';
import '../plate/cote_ivoire_plate.dart';
import 'plate_detection_service.dart';
import 'plate_recognizer_service.dart';

class MediaPlateAnalysisResult {
  const MediaPlateAnalysisResult({
    this.plate,
    this.score,
    this.plateImagePath,
    this.framePath,
    this.zones = const [],
  });

  final String? plate;
  final double? score;

  /// Recadrage de la plaque détectée dans la vidéo / la photo.
  final String? plateImagePath;

  /// Frame d'origine utilisée pour le recadrage.
  final String? framePath;
  final List<PlateOverlayZone> zones;

  bool get detected => plate != null && plate!.isNotEmpty;
}

/// Analyse IA d'une vidéo ou d'une photo pour extraire automatiquement
/// la plaque d'immatriculation et recadrer la zone de la plaque.
///
/// Pipeline :
/// 1. Extraction de plusieurs frames (vidéo) ou de la photo.
/// 2. Détection TFLite des zones de plaque.
/// 3. OCR ML Kit sur la frame entière ET sur le recadrage agrandi de la zone
///    (multi-échelle) pour maximiser la reconnaissance.
/// 4. Vote pondéré entre frames pour élire la meilleure plaque.
/// 5. (Optionnel) fusion avec le service externe PlateRecognizer.
class MediaPlateAnalysisService {
  MediaPlateAnalysisService({PlateDetectionService? detection})
      : _detection = detection ?? PlateDetectionService();

  final PlateDetectionService _detection;

  Future<MediaPlateAnalysisResult> analyze({
    String? videoPath,
    String? photoPath,
    int sampleCount = 6,
  }) async {
    if (photoPath != null && File(photoPath).existsSync()) {
      return _analyzeFrame(photoPath);
    }
    if (videoPath != null && File(videoPath).existsSync()) {
      return _analyzeVideo(videoPath, sampleCount);
    }
    return const MediaPlateAnalysisResult();
  }

  Future<MediaPlateAnalysisResult> _analyzeVideo(
    String videoPath,
    int sampleCount,
  ) async {
    final dir = await getTemporaryDirectory();
    final votes = <String, double>{};
    final candidates =
        <String, ({String frame, PlateOverlayZone? zone, double? score})>{};

    for (var i = 0; i < sampleCount; i++) {
      final timeMs = (i * 900) + 400;
      final framePath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: '${dir.path}/recap_frame_$i.jpg',
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1080,
        quality: 92,
        timeMs: timeMs,
      );
      if (framePath == null || !File(framePath).existsSync()) continue;

      final result = await _analyzeFrame(framePath);
      if (!result.detected) continue;
      final plate = result.plate!;
      final weight = 1.0 + (result.score ?? 0);
      votes[plate] = (votes[plate] ?? 0) + weight;

      final zone = result.zones.isEmpty ? null : result.zones.first;
      final previous = candidates[plate];
      final score = result.score ?? 0;
      if (previous == null || score > (previous.score ?? 0)) {
        candidates[plate] = (
          frame: framePath,
          zone: zone,
          score: result.score,
        );
      }
    }

    if (votes.isEmpty) return const MediaPlateAnalysisResult();

    final best = votes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final candidate = candidates[best.key];
    String? cropPath;
    if (candidate != null) {
      cropPath = await _cropPlate(
        candidate.frame,
        candidate.zone,
        enhance: true,
      );
    }
    return MediaPlateAnalysisResult(
      plate: CoteIvoirePlate.normalize(best.key),
      score: candidate?.score ??
          (votes.length == 1 ? 0.6 : 0.5 + best.value / (votes.length * 2)),
      plateImagePath: cropPath,
      framePath: candidate?.frame,
      zones: candidate?.zone != null ? [candidate!.zone!] : const [],
    );
  }

  Future<MediaPlateAnalysisResult> _analyzeFrame(String imagePath) async {
    final result = await _detection.detect(imagePath: imagePath);

    PlateOverlayZone? bestZone;
    for (final z in result.zones) {
      if (bestZone == null ||
          (z.confidence ?? 0) > (bestZone.confidence ?? 0)) {
        bestZone = z;
      }
    }

    // OCR multi-échelle : sur la frame complète puis sur la zone agrandie.
    final plates = <String>[];
    plates.addAll(result.plates);
    String? enhancedCrop;
    if (bestZone != null) {
      enhancedCrop = await _cropPlate(imagePath, bestZone, enhance: true);
      if (enhancedCrop != null) {
        final zoomed =
            await _detection.recognizePlatesInImage(enhancedCrop);
        plates.insertAll(0, zoomed);
      }
    }

    if (plates.isEmpty) {
      return MediaPlateAnalysisResult(framePath: imagePath);
    }

    // Choisit la meilleure plaque parmi tous les candidats.
    final plate = _bestPlate(plates);
    if (plate == null) {
      return MediaPlateAnalysisResult(framePath: imagePath);
    }

    final cropPath =
        enhancedCrop ?? await _cropPlate(imagePath, bestZone);
    return MediaPlateAnalysisResult(
      plate: plate,
      score: bestZone?.confidence,
      plateImagePath: cropPath,
      framePath: imagePath,
      zones: result.zones,
    );
  }

  String? _bestPlate(List<String> plates) {
    if (plates.isEmpty) return null;
    final seen = <String>{};
    for (final raw in plates) {
      final normalized = CoteIvoirePlate.normalize(raw);
      if (!CoteIvoirePlate.isValid(normalized)) continue;
      if (seen.add(normalized)) return normalized;
    }
    return plates.isEmpty
        ? null
        : CoteIvoirePlate.normalize(plates.first);
  }

  /// Recadre la zone de la plaque. Si [enhance], agrandit l'image et
  /// augmente le contraste pour améliorer l'OCR.
  Future<String?> _cropPlate(
    String imagePath,
    PlateOverlayZone? zone, {
    bool enhance = false,
  }) async {
    if (zone == null) return null;
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final marginX = zone.width * 0.08;
      final marginY = zone.height * 0.18;
      final left = (zone.left - marginX).clamp(0, decoded.width - 1).toInt();
      final top = (zone.top - marginY).clamp(0, decoded.height - 1).toInt();
      final right = (zone.left + zone.width + marginX)
          .clamp(left + 1, decoded.width)
          .toInt();
      final bottom = (zone.top + zone.height + marginY)
          .clamp(top + 1, decoded.height)
          .toInt();

      var cropped = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: right - left,
        height: bottom - top,
      );

      if (enhance) {
        // Agrandit x3 (interpolation lanczos) puis renforce le contraste.
        final targetWidth = (cropped.width * 3).clamp(1, 1200);
        cropped = img.copyResize(
          cropped,
          width: targetWidth,
          interpolation: img.Interpolation.cubic,
        );
        cropped = img.adjustColor(cropped, contrast: 1.35, saturation: 0.8);
      }

      final dir = await getTemporaryDirectory();
      final outPath =
          '${dir.path}/plate_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath)
          .writeAsBytes(img.encodeJpg(cropped, quality: enhance ? 95 : 90));
      return outPath;
    } catch (_) {
      return null;
    }
  }

  /// Fusionne un résultat externe (PlateRecognizer) avec le local.
  /// Le résultat externe est prioritaire quand il est valide.
  MediaPlateAnalysisResult mergeExternal(
    MediaPlateAnalysisResult local,
    List<PlateRecognition> external,
  ) {
    for (final recognition in external) {
      final normalized = CoteIvoirePlate.normalize(recognition.plate);
      if (CoteIvoirePlate.isValid(normalized)) {
        return MediaPlateAnalysisResult(
          plate: normalized,
          score: recognition.score,
          plateImagePath: local.plateImagePath,
          framePath: local.framePath,
          zones: local.zones,
        );
      }
    }
    return local;
  }

  Future<void> dispose() => _detection.dispose();
}
