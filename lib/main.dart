import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/api_config_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/incivi_type_provider.dart';
import 'core/providers/infraction_provider.dart';
import 'core/providers/notifications_provider.dart';
import 'core/providers/recap_pending_provider.dart';
import 'core/providers/submission_queue_provider.dart';
import 'core/providers/support_provider.dart';
import 'core/providers/usager_client_mode_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/floating_bubble_service.dart';
import 'core/services/local_notifications_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiConfig = ApiConfigProvider();
  try {
    await apiConfig.load().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Démarrage garanti même si SharedPreferences échoue.
  }

  final auth = AuthProvider(apiConfig.baseUrl);
  final localNotifications = LocalNotificationsService();
  try {
    await localNotifications.init().timeout(const Duration(seconds: 3));
  } catch (_) {
    // Notifications locales indisponibles : non bloquant.
  }

  runApp(
    CirculationApp(
      apiConfig: apiConfig,
      auth: auth,
      localNotifications: localNotifications,
    ),
  );
}

class CirculationApp extends StatefulWidget {
  const CirculationApp({
    super.key,
    required this.apiConfig,
    required this.auth,
    required this.localNotifications,
  });

  final ApiConfigProvider apiConfig;
  final AuthProvider auth;
  final LocalNotificationsService localNotifications;

  @override
  State<CirculationApp> createState() => _CirculationAppState();
}

class _CirculationAppState extends State<CirculationApp> {
  late final router = AppRoutes.createAppRouter(widget.auth);
  final _floatingBubble = FloatingBubbleService();
  StreamSubscription<String>? _bubbleRouteSubscription;
  String? _pendingBubbleRoute;

  @override
  void initState() {
    super.initState();
    widget.auth.init();
    widget.auth.addListener(_onAuthChanged);
    widget.apiConfig.addListener(_onApiConfigChanged);
    _bubbleRouteSubscription = _floatingBubble.routeEvents.listen(
      (route) {
        if (!mounted) return;
        if (widget.auth.isAuthenticated) {
          router.push(route);
        } else {
          _pendingBubbleRoute = route;
        }
      },
      onError: (_) {},
    );
  }

  void _onAuthChanged() {
    final route = _pendingBubbleRoute;
    if (route == null || !widget.auth.isAuthenticated) return;
    _pendingBubbleRoute = null;
    router.push(route);
  }

  void _onApiConfigChanged() {
    widget.auth.updateBaseUrl(widget.apiConfig.effectiveBaseUrl);
  }

  @override
  void dispose() {
    _bubbleRouteSubscription?.cancel();
    widget.auth.removeListener(_onAuthChanged);
    widget.apiConfig.removeListener(_onApiConfigChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.apiConfig),
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider(
          create: (_) => InciviTypeProvider(widget.apiConfig.effectiveBaseUrl)
            ..updateBaseUrl(widget.apiConfig.effectiveBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => InfractionProvider(widget.apiConfig.effectiveBaseUrl)
            ..updateBaseUrl(widget.apiConfig.effectiveBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NotificationsProvider(widget.apiConfig.effectiveBaseUrl)
                ..updateBaseUrl(widget.apiConfig.effectiveBaseUrl),
        ),
        ChangeNotifierProvider(create: (_) => RecapPendingProvider()),
        ChangeNotifierProvider(create: (_) => SubmissionQueueProvider()..load()),
        ChangeNotifierProvider(
          create: (_) => SupportProvider(widget.apiConfig.effectiveBaseUrl)
            ..updateBaseUrl(widget.apiConfig.effectiveBaseUrl),
        ),
        ChangeNotifierProvider(create: (_) => UsagerClientModeProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              VideoProcessingQueueProvider()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(widget.apiConfig.effectiveBaseUrl)
            ..updateBaseUrl(widget.apiConfig.effectiveBaseUrl),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Synchronise les providers quand l'URL change.
          context.watch<ApiConfigProvider>();
          final baseUrl = context.read<ApiConfigProvider>().effectiveBaseUrl;
          context.read<AuthProvider>().updateBaseUrl(baseUrl);
          context.read<InciviTypeProvider>().updateBaseUrl(baseUrl);
          context.read<InfractionProvider>().updateBaseUrl(baseUrl);
          context.read<NotificationsProvider>().updateBaseUrl(baseUrl);
          context.read<SupportProvider>().updateBaseUrl(baseUrl);
          context.read<WalletProvider>().updateBaseUrl(baseUrl);

          return MaterialApp.router(
            title: 'Circulation',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
