import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wallet.dart';
import 'auth_service.dart' show ApiException;

class WalletService {
  WalletService(this.baseUrl);
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Wallet> fetchWallet({String? token}) async {
    final response = await http
        .get(
          _uri('/api/wallet'),
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final raw = response.body;
      if (raw.isEmpty) return const Wallet();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final data =
            decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded;
        return Wallet.fromJson(data as Map<String, dynamic>);
      }
      return const Wallet();
    }
    throw ApiException.fromResponse(
      response.statusCode,
      response.body.isEmpty ? {} : jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
