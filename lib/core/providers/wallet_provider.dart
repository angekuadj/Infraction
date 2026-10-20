import 'package:flutter/foundation.dart';

import '../models/wallet.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider(this._baseUrl);
  String? _baseUrl;

  Wallet? _wallet;
  bool _loading = false;
  String? _error;

  Wallet? get wallet => _wallet;
  bool get isLoading => _loading;
  String? get error => _error;
  double get solde => _wallet?.solde ?? 0;
  List<WalletOperation> get operations => _wallet?.operations ?? const [];

  WalletService? get _service =>
      _baseUrl == null || _baseUrl!.isEmpty ? null : WalletService(_baseUrl!);

  void updateBaseUrl(String? baseUrl) {
    if (_baseUrl != baseUrl) {
      _baseUrl = baseUrl;
      notifyListeners();
    }
  }

  Future<void> loadForUserProfile({
    required String? token,
    required bool isUsager,
  }) async {
    final service = _service;
    if (service == null || token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _wallet = await service.fetchWallet(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({String? token}) async {
    final service = _service;
    if (service == null || token == null) return;
    try {
      _wallet = await service.fetchWallet(token: token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clear() {
    _wallet = null;
    _error = null;
    notifyListeners();
  }
}
