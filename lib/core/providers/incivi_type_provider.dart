import 'package:flutter/foundation.dart';

import '../models/incivi_type.dart';
import '../services/auth_service.dart' show ApiException;
import '../services/infraction_upload_service.dart';

class InciviTypeProvider extends ChangeNotifier {
  InciviTypeProvider(this._baseUrl);
  String? _baseUrl;

  List<InciviType> _types = [];
  bool _loading = false;
  String? _error;

  List<InciviType> get types => _types;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isEmpty => _types.isEmpty;

  InciviType? byId(String? id) {
    if (id == null) return null;
    for (final t in _types) {
      if (t.id == id) return t;
    }
    return null;
  }

  void updateBaseUrl(String? baseUrl) {
    if (_baseUrl != baseUrl) {
      _baseUrl = baseUrl;
      _types = [];
      notifyListeners();
    }
  }

  Future<void> load({String? token}) async {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      _loadDefaults();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final service = InciviTypeService(_baseUrl!);
      final raw = await service.fetchTypes(token: token);
      final types = raw.map(InciviType.fromJson).where((t) => t.id.isNotEmpty).toList();
      types.sort((a, b) => (a.ordre ?? 0).compareTo(b.ordre ?? 0));
      _types = types.isNotEmpty ? types : _defaults();
    } on ApiException catch (e) {
      _error = e.message;
      _types = _defaults();
    } catch (e) {
      _error = e.toString();
      _types = _defaults();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _loadDefaults() {
    _types = _defaults();
    notifyListeners();
  }

  static List<InciviType> _defaults() {
    return InciviTypeDefaults.all
        .asMap()
        .entries
        .map((e) => InciviType(
              id: e.value['id']!,
              nom: e.value['nom']!,
              description: e.value['description'],
              ordre: e.key,
            ))
        .toList();
  }
}
