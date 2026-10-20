import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/client/screens/client_dashboard_screen.dart';
import '../../features/client/screens/incivi_item_screen.dart';
import '../../features/client/screens/infraction_detail_screen.dart';
import '../../features/client/screens/infraction_list_screen.dart';
import '../../features/client/screens/infraction_recap_screen.dart';
import '../../features/client/screens/infraction_type_screen.dart';
import '../../features/client/screens/infraction_video_screen.dart';
import '../../features/client/screens/notifications_screen.dart';
import '../../features/client/screens/plate_selection_screen.dart';
import '../../features/client/screens/processing_queue_screen.dart';
import '../../features/client/screens/record_infraction_screen.dart';
import '../../features/client/screens/video_plate_reader_screen.dart';
import '../../features/client/screens/video_trim_screen.dart';
import '../../features/client/screens/wallet_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/service_client/screens/service_client_queue_screen.dart';
import '../../features/settings/screens/endpoint_setup_screen.dart';
import '../../features/settings/screens/floating_bubble_onboarding_screen.dart';
import '../../features/settings/screens/plate_recognizer_setup_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/support/screens/support_chat_screen.dart';
import '../../features/support/screens/support_list_screen.dart';
import '../../features/widget/screens/widget_onboarding_screen.dart';
import '../providers/auth_provider.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const client = '/client';
  static const settings = '/settings';
  static const support = '/support';
  static const serviceClientQueue = '/service-client/queue';
  static const notifications = '/client/notifications';
  static const wallet = '/client/wallet';
  static const infractions = '/client/infractions';
  static const myPlateInfractions = '/client/infractions/my-plate';
  static const myReports = '/client/infractions/my-reports';
  static const infractionType = '/client/infraction/type';
  static const infractionCamera = '/client/infraction/camera';
  static const infractionRecord = '/client/infraction/record';
  static const infractionRecordWithType = '/client/infraction/record/:typeId';
  static const infractionTrim = '/client/infraction/trim';
  static const infractionRecap = '/client/infraction/recap';
  static const infractionItems = '/client/infraction/items';
  static const plateSelection = '/client/infraction/plate-selection';
  static const processingQueue = '/client/infraction/processing-queue';
  static const videoReader = '/client/video-reader';
  static const endpointSetup = '/settings/endpoint';
  static const floatingBubbleOnboarding = '/settings/floating-bubble';
  static const plateRecognizerSetup = '/settings/plate-recognizer';
  static const widgetOnboarding = '/widget/onboarding';

  static GoRouter createAppRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: auth,
      redirect: (context, state) {
        final path = state.matchedLocation;
        final isAuthRoute = path == splash ||
            path == login ||
            path == register ||
            path == endpointSetup;
        if (!auth.initialized) {
          return path == splash ? null : splash;
        }
        if (!auth.isAuthenticated && !isAuthRoute) {
          return login;
        }
        if (auth.isAuthenticated &&
            (path == login || path == register || path == splash)) {
          return home;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: client,
          builder: (context, state) => const ClientDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.infractions,
          builder: (context, state) => const InfractionListScreen(),
        ),
        GoRoute(
          path: AppRoutes.myPlateInfractions,
          builder: (context, state) =>
              const InfractionListScreen(mode: InfractionListMode.myPlate),
        ),
        GoRoute(
          path: AppRoutes.myReports,
          builder: (context, state) =>
              const InfractionListScreen(mode: InfractionListMode.myReports),
        ),
        GoRoute(
          path: '/client/infractions/:id',
          builder: (context, state) => InfractionDetailScreen(
            id: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/client/infractions/:id/video',
          builder: (context, state) => InfractionVideoScreen(
            id: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.infractionType,
          builder: (context, state) => const InfractionTypeScreen(),
        ),
        GoRoute(
          path: AppRoutes.infractionCamera,
          builder: (context, state) => const RecordInfractionScreen(),
        ),
        GoRoute(
          path: AppRoutes.infractionRecordWithType,
          builder: (context, state) => RecordInfractionScreen(
            typeId: state.pathParameters['typeId'],
          ),
        ),
        GoRoute(
          path: AppRoutes.infractionTrim,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return VideoTrimScreen(
              videoPath: extra?['videoPath'] as String?,
              typeId: extra?['typeId'] as String?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.infractionRecap,
          builder: (context, state) => const InfractionRecapScreen(),
        ),
        GoRoute(
          path: AppRoutes.infractionItems,
          builder: (context, state) => const InciviItemScreen(),
        ),
        GoRoute(
          path: AppRoutes.plateSelection,
          builder: (context, state) => const PlateSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.processingQueue,
          builder: (context, state) => const ProcessingQueueScreen(),
        ),
        GoRoute(
          path: AppRoutes.videoReader,
          builder: (context, state) => const VideoPlateReaderScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.wallet,
          builder: (context, state) => const WalletScreen(),
        ),
        GoRoute(
          path: support,
          builder: (context, state) => const SupportListScreen(),
        ),
        GoRoute(
          path: '/support/:id',
          builder: (context, state) => SupportChatScreen(
            reclamationId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.serviceClientQueue,
          builder: (context, state) => const ServiceClientQueueScreen(),
        ),
        GoRoute(
          path: settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.endpointSetup,
          builder: (context, state) => const EndpointSetupScreen(),
        ),
        GoRoute(
          path: AppRoutes.floatingBubbleOnboarding,
          builder: (context, state) => const FloatingBubbleOnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.plateRecognizerSetup,
          builder: (context, state) => const PlateRecognizerSetupScreen(),
        ),
        GoRoute(
          path: AppRoutes.widgetOnboarding,
          builder: (context, state) => const WidgetOnboardingScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page introuvable: ${state.uri}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper pour lire l'AuthProvider depuis n'importe où.
AuthProvider authOf(BuildContext context) => context.read<AuthProvider>();
