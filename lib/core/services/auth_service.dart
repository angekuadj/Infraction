import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_error_response.dart';
import '../models/user_model.dart';

/// Service d'authentification : login, register, /me, plaque, activation, panne.
class AuthService {
  AuthService(this.baseUrl);
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<({UserModel user, String? token})> login({
    required String identifier,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri('/api/auth/login'),
          headers: _headers(),
          body: jsonEncode({
            'identifier': identifier,
            'email': identifier,
            'phone': identifier,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 30));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final user = UserModel.fromApiJson(body);
      return (user: user, token: user.token ?? user.accessToken);
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<({UserModel user, String? token})> register({
    required String nom,
    String? prenom,
    String? email,
    required String phone,
    required String password,
    String? role,
    String? cni,
    String? plaque,
    String? matricule,
  }) async {
    final response = await http
        .post(
          _uri('/api/auth/register'),
          headers: _headers(),
          body: jsonEncode({
            'nom': nom,
            'prenom': ?prenom,
            'email': ?email,
            'phone': phone,
            'telephone': phone,
            'password': password,
            'role': ?role,
            'cni': ?cni,
            'plaqueImmatriculation': ?plaque,
            'matricule': ?matricule,
          }),
        )
        .timeout(const Duration(seconds: 30));
    return _handleAuthResponse(response);
  }

  Future<({UserModel user, String? token})> registerWithPhoto({
    required String nom,
    String? prenom,
    String? email,
    required String phone,
    required String password,
    String? role,
    String? cni,
    String? plaque,
    String? matricule,
    required String cniPhotoPath,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/auth/register'));
    void field(String key, String? value) {
      if (value != null && value.isNotEmpty) request.fields[key] = value;
    }

    field('nom', nom);
    field('prenom', prenom);
    field('email', email);
    field('phone', phone);
    field('telephone', phone);
    field('password', password);
    field('role', role);
    field('cni', cni);
    field('plaqueImmatriculation', plaque);
    field('matricule', matricule);
    request.files
        .add(await http.MultipartFile.fromPath('cniPhoto', cniPhotoPath));

    final streamed =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _handleAuthResponse(response);
  }

  Future<({UserModel user, String? token})> _handleAuthResponse(
    http.Response response,
  ) async {
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final user = UserModel.fromApiJson(body);
      return (user: user, token: user.token ?? user.accessToken);
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<UserModel> me(String token) async {
    final response = await http
        .get(_uri('/api/auth/me'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return UserModel.fromApiJson(body);
    }
    throw ApiException.fromResponse(response.statusCode, body);
  }

  Future<void> submitPlaque({
    required String token,
    required String plaque,
  }) async {
    final response = await http
        .post(
          _uri('/api/auth/plaque'),
          headers: _headers(token),
          body: jsonEncode({
            'plaque': plaque,
            'plaqueImmatriculation': plaque,
            'numeroImmatriculation': plaque,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException.fromResponse(response.statusCode, _decode(response.body));
  }

  Future<void> activateClient({
    required String token,
    String? phone,
  }) async {
    final response = await http
        .post(
          _uri('/api/auth/activate-client'),
          headers: _headers(token),
          body: jsonEncode({'phone': ?phone}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException.fromResponse(response.statusCode, _decode(response.body));
  }

  Future<void> declarePanne({
    required String token,
    DateTime? start,
    DateTime? end,
  }) async {
    final response = await http
        .post(
          _uri('/api/auth/panne'),
          headers: _headers(token),
          body: jsonEncode({
            'start': (start ?? DateTime.now()).toIso8601String(),
            if (end != null) 'end': end.toIso8601String(),
          }),
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

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final ApiErrorResponse? details;

  ApiException(this.statusCode, this.message, [this.details]);

  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> body) {
    final error = ApiErrorResponse.fromJson(body);
    return ApiException(statusCode, error.displayMessage, error);
  }

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
