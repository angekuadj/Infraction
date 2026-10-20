import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlateRecognition {
  const PlateRecognition({
    required this.plate,
    required this.score,
    this.region,
  });

  final String plate;
  final double score;
  final String? region;
}

class PlateRecognizerException implements Exception {
  const PlateRecognizerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Clé et région de l'API PlateRecognizer, stockées localement.
class PlateRecognizerConfig {
  static const String _tokenKey = 'plate_recognizer_api_token';
  static const String _regionKey = 'plate_recognizer_region';
  static const String defaultRegion = 'ci';

  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey)?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<String> loadRegion() async {
    final prefs = await SharedPreferences.getInstance();
    final region = prefs.getString(_regionKey)?.trim();
    return region == null || region.isEmpty ? defaultRegion : region;
  }

  static Future<void> saveRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, region.trim().toLowerCase());
  }
}

/// Client de l'API externe PlateRecognizer (reconnaissance cloud).
class PlateRecognizerService {
  static const String endpoint =
      'https://api.platerecognizer.com/v1/plate-reader/';

  PlateRecognizerService({this.apiToken});
  final String? apiToken;

  bool get isConfigured => apiToken != null && apiToken!.trim().isNotEmpty;

  /// Envoie une image et renvoie les plaques reconnues, triées par score.
  /// Lève [PlateRecognizerException] si l'API refuse la requête.
  Future<List<PlateRecognition>> recognizeFile(
    File file, {
    String region = PlateRecognizerConfig.defaultRegion,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    if (!isConfigured) return const [];
    if (!await file.exists()) return const [];

    final request = http.MultipartRequest('POST', Uri.parse(endpoint))
      ..headers['Authorization'] = 'Token ${apiToken!.trim()}'
      ..fields['regions'] = region
      ..files.add(await http.MultipartFile.fromPath('upload', file.path));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(timeout);
    } on TimeoutException {
      throw const PlateRecognizerException(
        'Délai dépassé lors de la reconnaissance externe.',
      );
    } on SocketException {
      throw const PlateRecognizerException(
        'Connexion impossible à PlateRecognizer.',
      );
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlateRecognizerException(
        'PlateRecognizer a répondu ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    try {
      return parseResults(response.body);
    } on FormatException {
      throw const PlateRecognizerException(
        'Réponse PlateRecognizer illisible.',
      );
    }
  }

  /// Analyse le JSON renvoyé par l'API (exposé pour les tests).
  static List<PlateRecognition> parseResults(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final results = decoded['results'];
    if (results is! List) return const [];
    final recognized = <PlateRecognition>[];
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final plate = item['plate'];
      if (plate is! String || plate.trim().isEmpty) continue;
      final score = item['score'];
      final regionData = item['region'];
      recognized.add(
        PlateRecognition(
          plate: plate,
          score: score is num ? score.toDouble() : 0,
          region: regionData is Map<String, dynamic>
              ? regionData['code'] as String?
              : null,
        ),
      );
    }
    recognized.sort((a, b) => b.score.compareTo(a.score));
    return recognized;
  }
}
