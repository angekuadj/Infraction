import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/plate_overlay_zone.dart';
import '../plate/cote_ivoire_plate.dart';

/// Détecte des plaques dans une image via TFLite (detect.tflite) puis OCR (ML Kit).
class PlateDetectionService {
  static const String modelAsset = 'assets/models/detect.tflite';

  Interpreter? _interpreter;
  bool _initFailed = false;

  Future<void> _ensureInterpreter() async {
    if (_interpreter != null || _initFailed) return;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(modelAsset, options: options);
    } catch (_) {
      _initFailed = true;
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Détecte les zones de plaques dans une image fichier.
  Future<({List<PlateOverlayZone> zones, List<String> plates})> detect({
    required String imagePath,
    double confidenceThreshold = 0.3,
  }) async {
    final zones = <PlateOverlayZone>[];
    final plates = <String>[];
    final file = File(imagePath);
    if (!await file.exists()) return (zones: zones, plates: plates);

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return (zones: zones, plates: plates);

    await _ensureInterpreter();
    if (_interpreter != null) {
      try {
        zones.addAll(_runDetector(decoded, confidenceThreshold));
      } catch (_) {}
    }

    final ocrPlates = await recognizePlatesInImage(imagePath);
    plates.addAll(ocrPlates);

    if (zones.isEmpty && plates.isNotEmpty) {
      for (final plate in plates) {
        zones.add(PlateOverlayZone(
          left: decoded.width * 0.25,
          top: decoded.height * 0.4,
          width: decoded.width * 0.5,
          height: decoded.height * 0.15,
          plate: plate,
        ));
      }
    }

    return (zones: zones, plates: plates);
  }

  List<PlateOverlayZone> _runDetector(img.Image image, double threshold) {
    const inputSize = 300;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Entrée [1, 300, 300, 3] normalisée 0..1 (format commun de detect.tflite).
    final input = [
      List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
        }),
      )
    ];

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final flatLen = outputShape.reduce((a, b) => a * b);
    final output = [List.filled(flatLen, 0.0)];

    _interpreter!.run(input, output);

    final zones = <PlateOverlayZone>[];
    final flat = output[0];
    // Format suppose [cx, cy, w, h, score] répété, ou [y1,x1,y2,x2,score,...].
    const stride = 5;
    for (var i = 0; i + stride <= flat.length; i += stride) {
      final a = flat[i];
      final b = flat[i + 1];
      final c = flat[i + 2];
      final d = flat[i + 3];
      final score = flat[i + 4];
      if (score < threshold || score > 1.0) continue;
      zones.add(PlateOverlayZone(
        left: a * image.width,
        top: b * image.height,
        width: (c - a).abs() * image.width,
        height: (d - b).abs() * image.height,
        confidence: score,
      ));
    }
    return zones;
  }

  /// Reconnaît les plaques via ML Kit Text Recognition sur une image.
  Future<List<String>> recognizePlatesInImage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(input);
      return extractPlates(result.text, blocks: result.blocks);
    } catch (_) {
      return [];
    } finally {
      await recognizer.close();
    }
  }

  /// Extrait les chaînes ressemblant à des plaques ivoiriennes d'un texte OCR.
  ///
  /// Traite chaque ligne, chaque mot et les paires de mots adjacentes,
  /// puis génère des candidats corrigés (confusions OCR) triés par score.
  List<String> extractPlates(
    String text, {
    List<TextBlock>? blocks,
  }) {
    final scored = <String, double>{};

    void consider(String raw) {
      for (final candidate in CoteIvoirePlate.candidates(raw)) {
        final score = _plateScore(candidate);
        if (!scored.containsKey(candidate) || score > scored[candidate]!) {
          scored[candidate] = score;
        }
      }
    }

    final lines = <String>[
      ...text.split(RegExp(r'[\r\n]+')),
      if (blocks != null) ...blocks.map((b) => b.text),
      if (blocks != null)
        ...blocks.expand((b) => b.lines.map((l) => l.text)),
    ];

    for (final line in lines) {
      final tokens = line
          .toUpperCase()
          .split(RegExp(r'[^A-Z0-9]+'))
          .where((w) => w.isNotEmpty)
          .toList();
      for (var i = 0; i < tokens.length; i++) {
        final token = tokens[i];
        if (token.length >= 3 && token.length <= 10) consider(token);
        // Fenêtres de 2 à 3 tokens adjacents : "AB 1234", "AB 1234 CD",
        // "AB-1234-CD" saisi en plusieurs mots.
        for (var span = 2; span <= 3; span++) {
          if (i + span > tokens.length) break;
          final joined = tokens.sublist(i, i + span).join();
          if (joined.length >= 4 && joined.length <= 10) consider(joined);
        }
      }
      // Ligne entière compactée : "AB - 1234 - CD".
      final compact = CoteIvoirePlate.normalize(line);
      if (compact.length >= 4 && compact.length <= 10) consider(compact);
    }

    if (scored.isEmpty) return [];
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  /// Score heuristique : privilégie les formats ivoiriens complets
  /// (2-3 lettres + 3-4 chiffres + suffixe lettres).
  double _plateScore(String plate) {
    final normalized = CoteIvoirePlate.normalize(plate);
    final match = RegExp(r'^([A-Z]{1,3})([0-9]{3,4})([A-Z]{0,2})$')
        .firstMatch(normalized);
    if (match == null) return 0;
    final letters = match.group(1)!;
    final digits = match.group(2)!;
    final suffix = match.group(3) ?? '';
    var score = 0.5;
    if (letters.length == 2) score += 0.2;
    if (digits.length == 4) score += 0.2;
    if (suffix.length == 2) score += 0.1;
    // Un mélange lettres/chiffres réel est plus probable qu'une correction.
    if (CoteIvoirePlate.isValid(normalized)) score += 0.05;
    return score;
  }
}
