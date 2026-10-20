import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/providers/api_config_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final apiConfig = context.read<ApiConfigProvider>();
    final auth = context.read<AuthProvider>();

    // Auto-détection endpoint si activée et non configuré.
    if (apiConfig.autoDiscovery && !apiConfig.hasConfiguredBaseUrl) {
      await apiConfig.discover();
      auth.updateBaseUrl(apiConfig.effectiveBaseUrl);
    }

    // Attendre l'initialisation auth (max 5 s).
    final start = DateTime.now();
    while (!auth.initialized &&
        DateTime.now().difference(start) < const Duration(seconds: 5)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    if (auth.isAuthenticated) {
      final role = auth.role;
      switch (role) {
        case AppRole.usager:
        case AppRole.client:
          context.go(AppRoutes.client);
          break;
        case AppRole.agent:
          context.go(AppRoutes.serviceClientQueue);
          break;
        case AppRole.admin:
          context.go(AppRoutes.home);
          break;
      }
    } else {
      if (!apiConfig.hasConfiguredBaseUrl &&
          apiConfig.effectiveBaseUrl == null) {
        context.go(AppRoutes.endpointSetup);
      } else {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_police,
                size: 72,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Circulation',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Signalez les infractions, consultez vos signalements',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 64),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
