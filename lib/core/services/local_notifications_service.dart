import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notifications locales (rappels, accusés de réception, panne, etc.).
class LocalNotificationsService {
  static const String channelIncoming = 'nouvelle_infraction_signalee';
  static const String channelQueue = 'submission_queue';
  static const String channelGeneral = 'circulation_general';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    try {
      await _plugin.initialize(settings);
      await _createChannels();
      _initialized = true;
    } catch (_) {}
  }

  Future<void> _createChannels() async {
    const channels = [
      AndroidNotificationChannel(
        channelIncoming,
        'Nouvelles infractions',
        description: 'Notifications lors de nouveaux signalements',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        channelQueue,
        'File d\'envoi',
        description: 'État des signalements en attente d\'envoi',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        channelGeneral,
        'Général',
        description: 'Notifications générales de l\'application',
        importance: Importance.defaultImportance,
      ),
    ];
    for (final channel in channels) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> requestPermission() async {
    await Permission.notification.request();
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String channel = channelGeneral,
  }) async {
    await init();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel == channelIncoming
              ? 'Nouvelles infractions'
              : channel == channelQueue
                  ? 'File d\'envoi'
                  : 'Général',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}
