import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/providers/submission_queue_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final queue = context.watch<SubmissionQueueProvider>();
    final notifications = context.watch<NotificationsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Circulation'),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              if (notifications.hasUnread)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notifications.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Bonjour, ${auth.user?.displayName ?? 'Utilisateur'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Signaler des infractions, voir vos signalements, portefeuille',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (queue.hasPending) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${queue.pendingCount} signalement(s) en attente d\'envoi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _QuickActionCard(
            icon: Icons.videocam_outlined,
            title: 'Signaler une infraction par vidéo',
            subtitle: 'Choisissez le type, puis enregistrez une vidéo avec la caméra.',
            onTap: () => context.push(AppRoutes.infractionType),
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.list_alt_outlined,
            title: 'Mes signalements',
            subtitle: 'Historique et statut de vos signalements envoyés.',
            onTap: () => context.push(AppRoutes.myReports),
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.directions_car_outlined,
            title: 'Voir les infractions où ma plaque est concernée',
            subtitle: 'Infractions pour votre véhicule.',
            onTap: () => context.push(AppRoutes.myPlateInfractions),
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Portefeuille',
            subtitle: 'Solde et opérations.',
            onTap: () => context.push(AppRoutes.wallet),
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.support_agent_outlined,
            title: 'Support',
            subtitle: 'Réclamations et messagerie.',
            onTap: () => context.push(AppRoutes.support),
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.workspace_premium_outlined,
            title: 'Déclarer mon véhicule en panne',
            subtitle: 'Signalements ignorés pendant la durée.',
            onTap: () => _showPanneDialog(context),
          ),
          if (queue.hasPending) ...[
            const SizedBox(height: 12),
            _QuickActionCard(
              icon: Icons.cloud_upload_outlined,
              title: 'File d\'envoi',
              subtitle: '${queue.pendingCount} signalement(s) en attente.',
              onTap: () => context.push(AppRoutes.processingQueue),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPanneDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final hours = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.build_outlined, color: AppTheme.warning),
            ),
            const SizedBox(width: 12),
            const Text('Véhicule en panne'),
          ],
        ),
        content: const Text(
          'Déclarer mon véhicule en panne '
          '(signalements ignorés pendant la durée).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 24),
            child: const Text('24 heures'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 72),
            child: const Text('72 heures'),
          ),
        ],
      ),
    );
    if (hours == null || !context.mounted) return;
    final start = DateTime.now();
    final end = start.add(Duration(hours: hours));
    final ok = await auth.declarePanne(start: start, end: end);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Véhicule déclaré en panne jusqu\'à '
                  '${end.day}/${end.month} ${end.hour}h'
              : 'Erreur lors de la déclaration de panne',
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
