import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notification_model.dart';
import 'auth_service.dart' show ApiException;

class NotificationApiService {
  NotificationApiService(this.baseUrl);
  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Map<String, String> _headers(String? token) => {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<List<NotificationModel>> fetchNotifications({
    String? token,
    bool unreadOnly = false,
  }) async {
    final response = await http
        .get(
          _uri('/api/notifications', {
            if (unreadOnly) 'unreadOnly': 'true',
          }),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = body['data'] ?? body['notifications'] ?? body;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList();
      }
      return [];
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<void> markAllRead({String? token}) async {
    final response = await http
        .post(
          _uri('/api/notifications/read-all'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException.fromResponse(response.statusCode, _decode(response.body));
  }

  Future<void> markRead({
    String? token,
    required String id,
  }) async {
    final response = await http
        .post(
          _uri('/api/notifications/$id/read'),
          headers: _headers(token),
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
