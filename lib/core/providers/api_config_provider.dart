import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/endpoint_discovery_service.dart';

/// Fournit et persiste l'URL de base de l'API.
class ApiConfigProvider extends ChangeNotifier {
  static const String prefKeyBaseUrl = 'api_base_url';
  static const String prefKeyAutoDiscovery = 'api_auto_discovery';

  static const String placeholderVotreApi = 'https://votre-api.com';
  static const String placeholderExemple = 'https://api.exemple.com';

  String? _baseUrl;
  bool _autoDiscovery = true;
  bool _loading = false;
  String? _lastDetected;
  final EndpointDiscoveryService _discovery = EndpointDiscoveryService();

  String? get baseUrl => _baseUrl;
  bool get hasConfiguredBaseUrl =>
      _baseUrl != null && _baseUrl!.isNotEmpty && !_isPlaceholder(_baseUrl!);
  bool get autoDiscovery => _autoDiscovery;
  bool get isLoading => _loading;
  String? get lastDetected => _lastDetected;

  static bool _isPlaceholder(String url) =>
      url == placeholderVotreApi || url == placeholderExemple;

  /// URL effective : configurée, détectée, ou null.
  String? get effectiveBaseUrl =>
      hasConfiguredBaseUrl ? _baseUrl : _lastDetected;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(prefKeyBaseUrl);
    _autoDiscovery = prefs.getBool(prefKeyAutoDiscovery) ?? true;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim();
    _baseUrl = trimmed.isEmpty ? null : _trimmedUrl(trimmed);
    final prefs = await SharedPreferences.getInstance();
    if (_baseUrl == null) {
      await prefs.remove(prefKeyBaseUrl);
    } else {
      await prefs.setString(prefKeyBaseUrl, _baseUrl!);
    }
    notifyListeners();
  }

  Future<void> setAutoDiscovery(bool value) async {
    _autoDiscovery = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyAutoDiscovery, value);
    notifyListeners();
  }

  /// Tente une auto-détection sur le réseau local.
  Future<String?> discover() async {
    _loading = true;
    notifyListeners();
    try {
      final found = await _discovery.discoverLocalServer();
      _lastDetected = found;
      if (found != null && !hasConfiguredBaseUrl) {
        // Mémorise la détection sans écraser la config manuelle.
        notifyListeners();
      }
      return found;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static String _trimmedUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
