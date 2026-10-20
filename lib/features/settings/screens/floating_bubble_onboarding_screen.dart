import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/floating_bubble_service.dart';
import '../../../core/theme/app_theme.dart';

class FloatingBubbleOnboardingScreen extends StatefulWidget {
  const FloatingBubbleOnboardingScreen({super.key});

  @override
  State<FloatingBubbleOnboardingScreen> createState() =>
      _FloatingBubbleOnboardingScreenState();
}

class _FloatingBubbleOnboardingScreenState
    extends State<FloatingBubbleOnboardingScreen> {
  final _service = FloatingBubbleService();
  bool _active = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _service.isActive().then((value) {
      if (mounted) setState(() => _active = value);
    });
  }

  Future<void> _toggle() async {
    if (_active) {
      final ok = await _service.hide();
      if (!mounted) return;
      setState(() {
        _active = !ok;
        _message = ok ? 'Bulle masquée.' : 'Bulle masquée.';
      });
      return;
    }

    final overlay = await Permission.systemAlertWindow.request();
    if (!overlay.isGranted) {
      if (!mounted) return;
      setState(() {
        _message = 'Permission « Afficher par-dessus les autres applications » '
            'requise.';
      });
      return;
    }
    final ok = await _service.show();
    if (!mounted) return;
    setState(() {
      _active = ok;
      _message = ok
          ? 'Bulle flottante activée.'
          : 'Impossible d\'activer la bulle sur cet appareil.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Bulle flottante'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bubble_chart_outlined,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Signalez plus rapidement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'La bulle flottante reste visible par-dessus les autres '
            'applications et vous permet d\'ouvrir la caméra de signalement '
            'en un geste.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _FeatureItem(
                  icon: Icons.touch_app_outlined,
                  title: 'Appuyez sur la bulle',
                  subtitle: 'Ouvre le signalement d\'infraction.',
                ),
                const Divider(height: 32),
                _FeatureItem(
                  icon: Icons.open_with,
                  title: 'Déplacez-la',
                  subtitle: 'Positionnez-la où vous voulez.',
                ),
                const Divider(height: 32),
                _FeatureItem(
                  icon: Icons.close,
                  title: 'Masquez-la',
                  subtitle: 'Désactivez-la à tout moment.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _toggle,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(_active ? Icons.stop_circle_outlined : Icons.play_circle),
            label: Text(_active ? 'Désactiver la bulle' : 'Activer la bulle'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _message!.contains('Permission')
                    ? AppTheme.warning.withValues(alpha: 0.1)
                    : AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
