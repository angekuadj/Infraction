import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart' show ApiException;

class InciviTypeService {
  InciviTypeService(this.baseUrl);
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<List<Map<String, dynamic>>> fetchTypes({String? token}) async {
    final response = await http
        .get(_uri('/api/infraction-types'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = body['data'] ?? body['types'] ?? body;
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  static Map<String, dynamic> _decode(String raw) {
    if (raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'data': decoded};
    } catch (_) {
      return {'message': raw};
    }
  }
}

class InfractionUploadService {
  InfractionUploadService(this.baseUrl);
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Envoie un signalement complet (multipart si vidéo/photo présents).
  Future<Map<String, dynamic>> submitReport({
    required String token,
    required Map<String, dynamic> fields,
    File? video,
    File? photo,
    File? plateImage,
    void Function(double progress)? onProgress,
  }) async {
    final hasFiles =
        video != null || photo != null || plateImage != null;
    if (!hasFiles) {
      final response = await http
          .post(
            _uri('/api/infractions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(fields),
          )
          .timeout(const Duration(minutes: 2));
      final body = _decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) return body;
      throw ApiException.fromResponse(response.statusCode, body);
    }

    final request = http.MultipartRequest('POST', _uri('/api/infractions'));
    request.headers['Authorization'] = 'Bearer $token';
    fields.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    if (video != null) {
      request.files.add(await http.MultipartFile.fromPath('video', video.path));
    }
    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }
    if (plateImage != null) {
      request.files
          .add(await http.MultipartFile.fromPath('plate', plateImage.path));
    }

    final streamed = await request.send().timeout(const Duration(minutes: 5));
    final response = await http.Response.fromStream(streamed);
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<List<Map<String, dynamic>>> fetchMyReports({String? token}) async {
    final response = await http
        .get(
          _uri('/api/infractions'),
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = body['data'] ?? body['infractions'] ?? body;
      if (list is List) return list.whereType<Map<String, dynamic>>().toList();
      return [];
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<List<Map<String, dynamic>>> fetchForMyPlate({
    required String token,
    required String plaque,
  }) async {
    final uri = _uri('/api/infractions/for-my-plate').replace(
      queryParameters: {'plaque': plaque},
    );
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = body['data'] ?? body['infractions'] ?? body;
      if (list is List) return list.whereType<Map<String, dynamic>>().toList();
      return [];
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<Map<String, dynamic>> fetchById({
    required String token,
    required String id,
  }) async {
    final response = await http
        .get(
          _uri('/api/infractions/$id'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<void> deleteReport({
    required String token,
    required String id,
  }) async {
    final response = await http
        .delete(
          _uri('/api/infractions/$id'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException.fromResponse(response.statusCode, _decode(response.body));
  }

  static Map<String, dynamic> _decode(String raw) {
    if (raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'data': decoded};
    } catch (_) {
      return {'message': raw};
    }
  }
}
