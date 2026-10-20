import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/reclamation_model.dart';
import '../models/support_message_model.dart';
import 'auth_service.dart' show ApiException;

class SupportService {
  SupportService(this.baseUrl);
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers(String? token, {bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<List<ReclamationModel>> fetchQueue({String? token}) async {
    final response = await http
        .get(_uri('/api/support/queue'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = body['data'] ?? body['reclamations'] ?? body;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(ReclamationModel.fromJson)
            .toList();
      }
      return [];
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<List<ReclamationModel>> fetchAssigned({String? token}) async {
    final response = await http
        .get(_uri('/api/support/assigned'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = body['data'] ?? body['reclamations'] ?? body;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(ReclamationModel.fromJson)
            .toList();
      }
      return [];
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<List<ReclamationModel>> fetchReclamations({String? token}) async {
    final response = await http
        .get(_uri('/api/support/reclamations'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = body['data'] ?? body['reclamations'] ?? body;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(ReclamationModel.fromJson)
            .toList();
      }
      return [];
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<ReclamationModel> createReclamation({
    required String token,
    required String subject,
    required String message,
  }) async {
    final response = await http
        .post(
          _uri('/api/support/reclamations'),
          headers: _headers(token),
          body: jsonEncode({
            'subject': subject,
            'title': subject,
            'message': message,
            'body': message,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      return ReclamationModel.fromJson(data);
    }
    throw ApiException.fromResponse(response.statusCode, decoded);
  }

  Future<ReclamationModel> fetchReclamation({
    required String token,
    required String id,
  }) async {
    final response = await http
        .get(
          _uri('/api/support/reclamations/$id'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      return ReclamationModel.fromJson(data);
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<SupportMessageModel> sendMessage({
    required String token,
    required String reclamationId,
    required String body,
  }) async {
    final response = await http
        .post(
          _uri('/api/support/reclamations/$reclamationId/messages'),
          headers: _headers(token),
          body: jsonEncode({'body': body, 'message': body}),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      return SupportMessageModel.fromJson(data);
    }
    throw ApiException.fromResponse(response.statusCode, decoded);
  }

  Future<void> closeReclamation({
    required String token,
    required String id,
  }) async {
    final response = await http
        .post(
          _uri('/api/support/reclamations/$id/close'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException.fromResponse(response.statusCode, _decode(response.body));
  }

  Future<List<SupportMessageModel>> fetchMessages({
    required String token,
    required String reclamationId,
  }) async {
    final response = await http
        .get(
          _uri('/api/support/reclamations/$reclamationId/messages'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = body['data'] ?? body['messages'] ?? body;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(SupportMessageModel.fromJson)
            .toList();
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
