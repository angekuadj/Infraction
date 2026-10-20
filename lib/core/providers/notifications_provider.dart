import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._baseUrl);
  String? _baseUrl;

  List<NotificationModel> _notifications = [];
  bool _loading = false;
  String? _error;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  NotificationApiService? get _service =>
      _baseUrl == null || _baseUrl!.isEmpty
          ? null
          : NotificationApiService(_baseUrl!);

  void updateBaseUrl(String? baseUrl) {
    if (_baseUrl != baseUrl) {
      _baseUrl = baseUrl;
      notifyListeners();
    }
  }

  Future<void> load({String? token, bool unreadOnly = false}) async {
    final service = _service;
    if (service == null || token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications =
          await service.fetchNotifications(token: token, unreadOnly: unreadOnly);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead({String? token}) async {
    final service = _service;
    if (service == null || token == null) return;
    try {
      await service.markAllRead(token: token);
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markRead({String? token, required String id}) async {
    final service = _service;
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
    }
    if (service == null || token == null) return;
    try {
      await service.markRead(token: token, id: id);
    } catch (_) {}
  }

  void addLocal(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
