import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Découvre automatiquement l'API sur le réseau local (port 8080)
/// et gère l'URL de base configurée manuellement.
class EndpointDiscoveryService {
  static const int defaultPort = 8080;
  static const List<String> fallbackHosts = [
    '10.0.2.2', // émulateur Android -> hôte
    '10.10.126.81',
    '192.168.1.14',
  ];

  /// Tente de détecter un serveur sur le réseau local.
  /// Retourne l'URL de base détectée ou null.
  Future<String?> discoverLocalServer({
    int port = defaultPort,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final candidates = <String>[
      ...await _localNetworkHosts(),
      ...fallbackHosts,
    ];
    final seen = <String>{};
    for (final host in candidates) {
      if (!seen.add(host)) continue;
      final url = 'http://$host:$port';
      final found = await _probe(url, timeout: timeout);
      if (found) return url;
    }
    return null;
  }

  Future<bool> _probe(String baseUrl, {Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/me');
      final response = await http.get(uri).timeout(timeout);
      return response.statusCode < 500;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Adresses IP locales candidates (best effort, sans plugins réseau).
  Future<List<String>> _localNetworkHosts() async {
    final hosts = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            // Adresses privées courantes : on teste .1 de chaque sous-réseau /24
            hosts.add('${parts[0]}.${parts[1]}.${parts[2]}.1');
            hosts.add(addr.address);
          }
        }
      }
    } catch (_) {}
    return hosts;
  }
}

/// Wrapper IO pour les opérations qui nécessitent dart:io explicitement.
class EndpointDiscoveryServiceIo extends EndpointDiscoveryService {
  Future<String?> discoverWithManualProbe(
    List<String> urls, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    for (final url in urls) {
      final found = await _probe(url, timeout: timeout);
      if (found) return url;
    }
    return null;
  }
}
