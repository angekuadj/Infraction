import 'package:flutter/services.dart';

/// Contrôle de la bulle flottante Android (service natif FloatingBubbleService).
/// Utilise un MethodChannel vers le code natif de l'application.
class FloatingBubbleService {
  static const MethodChannel _channel =
      MethodChannel('net.circulation.ci.circulation/floating_bubble');
  static const EventChannel _events = EventChannel(
    'net.circulation.ci.circulation/floating_bubble_events',
  );

  static const String actionShow = 'show';
  static const String actionHide = 'hide';
  static const String actionToggle = 'toggle';
  static const String actionIsActive = 'isActive';

  /// Routes demandées par la bulle native (ex: ouverture du signalement).
  Stream<String> get routeEvents => _events
      .receiveBroadcastStream()
      .where((event) => event is String)
      .cast<String>();

  Future<bool> show() => _invoke(actionShow);
  Future<bool> hide() => _invoke(actionHide);
  Future<bool> toggle() => _invoke(actionToggle);

  Future<bool> isActive() async {
    try {
      final result = await _channel.invokeMethod<bool>(actionIsActive);
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _invoke(String action) async {
    try {
      final result = await _channel.invokeMethod<bool>(action);
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
