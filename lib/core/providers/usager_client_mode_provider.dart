import 'package:flutter/foundation.dart';

/// Mode d'affichage usager/client combiné (usagerclient / clientusager).
enum UsagerClientMode { usager, client, both, unset }

class UsagerClientModeProvider extends ChangeNotifier {
  static const String prefKeyMode = 'usager_client_mode';

  UsagerClientMode _mode = UsagerClientMode.unset;

  UsagerClientMode get mode => _mode;
  bool get isUnset => _mode == UsagerClientMode.unset;
  bool get showUsager =>
      _mode == UsagerClientMode.usager || _mode == UsagerClientMode.both;
  bool get showClient =>
      _mode == UsagerClientMode.client || _mode == UsagerClientMode.both;

  Future<void> loadFromPrefs(Future<bool> Function(String key) containsKey,
      String? Function(String key) getString) async {
    final raw = getString(prefKeyMode);
    _mode = fromString(raw);
    notifyListeners();
  }

  void setMode(UsagerClientMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setFromString(String? value) {
    _mode = fromString(value);
    notifyListeners();
  }

  static UsagerClientMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'usager':
        return UsagerClientMode.usager;
      case 'client':
        return UsagerClientMode.client;
      case 'both':
      case 'usagerclient':
      case 'clientusager':
        return UsagerClientMode.both;
      default:
        return UsagerClientMode.unset;
    }
  }

  String? toStorageString() {
    switch (_mode) {
      case UsagerClientMode.usager:
        return 'usager';
      case UsagerClientMode.client:
        return 'client';
      case UsagerClientMode.both:
        return 'both';
      case UsagerClientMode.unset:
        return null;
    }
  }
}
