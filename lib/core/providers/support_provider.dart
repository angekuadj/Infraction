import 'package:flutter/foundation.dart';

import '../models/reclamation_model.dart';
import '../models/support_message_model.dart';
import '../services/support_service.dart';

class SupportProvider extends ChangeNotifier {
  SupportProvider(this._baseUrl);
  String? _baseUrl;

  List<ReclamationModel> _queue = [];
  List<ReclamationModel> _assigned = [];
  List<ReclamationModel> _reclamations = [];
  final Map<String, List<SupportMessageModel>> _messages = {};
  bool _loading = false;
  String? _error;

  List<ReclamationModel> get queue => List.unmodifiable(_queue);
  List<ReclamationModel> get assigned => List.unmodifiable(_assigned);
  List<ReclamationModel> get reclamations => List.unmodifiable(_reclamations);
  bool get isLoading => _loading;
  String? get error => _error;

  List<SupportMessageModel> messagesFor(String reclamationId) =>
      List.unmodifiable(_messages[reclamationId] ?? const []);

  SupportService? get _service =>
      _baseUrl == null || _baseUrl!.isEmpty ? null : SupportService(_baseUrl!);

  void updateBaseUrl(String? baseUrl) {
    if (_baseUrl != baseUrl) {
      _baseUrl = baseUrl;
      notifyListeners();
    }
  }

  Future<void> loadQueue({String? token}) async {
    final service = _service;
    if (service == null || token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _queue = await service.fetchQueue(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAssigned({String? token}) async {
    final service = _service;
    if (service == null || token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _assigned = await service.fetchAssigned(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadReclamations({String? token}) async {
    final service = _service;
    if (service == null || token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _reclamations = await service.fetchReclamations(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll({String? token}) async {
    await Future.wait([
      loadQueue(token: token),
      loadAssigned(token: token),
      loadReclamations(token: token),
    ]);
  }

  Future<ReclamationModel?> createReclamation({
    required String token,
    required String subject,
    required String message,
  }) async {
    final service = _service;
    if (service == null) return null;
    try {
      final reclamation = await service.createReclamation(
        token: token,
        subject: subject,
        message: message,
      );
      _reclamations = [reclamation, ..._reclamations];
      notifyListeners();
      return reclamation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMessages({
    required String token,
    required String reclamationId,
  }) async {
    final service = _service;
    if (service == null) return;
    try {
      final list = await service.fetchMessages(
        token: token,
        reclamationId: reclamationId,
      );
      _messages[reclamationId] = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<SupportMessageModel?> sendMessage({
    required String token,
    required String reclamationId,
    required String body,
  }) async {
    final service = _service;
    if (service == null) return null;
    try {
      final message = await service.sendMessage(
        token: token,
        reclamationId: reclamationId,
        body: body,
      );
      final list = _messages[reclamationId] ?? [];
      _messages[reclamationId] = [...list, message];
      notifyListeners();
      return message;
    } catch (_) {
      return null;
    }
  }

  Future<bool> closeReclamation({
    required String token,
    required String id,
  }) async {
    final service = _service;
    if (service == null) return false;
    try {
      await service.closeReclamation(token: token, id: id);
      _queue = _queue.map((r) {
        if (r.id == id) {
          return ReclamationModel.fromJson({...r.toJson(), 'closed': true});
        }
        return r;
      }).toList();
      _assigned = _assigned.where((r) => r.id != id).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
