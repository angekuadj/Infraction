import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/providers/submission_queue_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/plaque_saisie_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        context.read<NotificationsProvider>().load(token: auth.token);
      }
    });
  }

  Future<void> _saisirPlaque() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlaqueSaisieScreen()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationsProvider>();
    final queue = context.watch<SubmissionQueueProvider>();
    final plaque = auth.user?.plaqueImmatriculation ??
        auth.user?.numeroImmatriculation;
    final needsPlaque =
        auth.isUsager && (plaque == null || plaque.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon espace'),
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
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
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
      body: RefreshIndicator(
        onRefresh: () async {
          final token = auth.token;
          if (token != null) {
            await context
                .read<NotificationsProvider>()
                .load(token: token);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _HeaderCard(
              displayName: auth.user?.displayName ?? 'Utilisateur',
              roleLabel: auth.role.label,
              plaque: (plaque != null && plaque.isNotEmpty)
                  ? plaque.toUpperCase()
                  : null,
              pendingCount: queue.pendingCount,
              showPending: queue.hasPending,
            ),
            if (needsPlaque) ...[
              const SizedBox(height: 12),
              _BannerCard(
                icon: Icons.warning_amber_rounded,
                iconColor: AppTheme.warning,
                backgroundColor:
                    AppTheme.warning.withValues(alpha: 0.10),
                title: 'Plaque requise',
                subtitle:
                    'Renseignez votre plaque pour consulter les '
                    'infractions liées à votre véhicule.',
                buttonLabel: 'Ajouter ma plaque',
                onTap: _saisirPlaque,
              ),
            ],
            if (queue.hasPending) ...[
              const SizedBox(height: 12),
              _BannerCard(
                icon: Icons.cloud_upload_outlined,
                iconColor: AppTheme.primary,
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.08),
                title: '${queue.pendingCount} signalement(s) en attente',
                subtitle:
                    'Ils seront envoyés dès que la connexion revient.',
                buttonLabel: 'Voir la file',
                onTap: () =>
                    context.push(AppRoutes.processingQueue),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Signaler une infraction'),
                onPressed: () =>
                    context.push(AppRoutes.infractionType),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Accès rapides',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _ActionCard(
                  icon: Icons.list_alt_outlined,
                  iconColor: AppTheme.primary,
                  title: 'Mes signalements',
                  subtitle: 'Statut et historique',
                  onTap: () => context.push(AppRoutes.myReports),
                ),
                _ActionCard(
                  icon: Icons.directions_car_outlined,
                  iconColor: AppTheme.primary,
                  title: 'Sur ma plaque',
                  subtitle: 'Infractions du véhicule',
                  onTap: () =>
                      context.push(AppRoutes.myPlateInfractions),
                ),
                _ActionCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppTheme.success,
                  title: 'Portefeuille',
                  subtitle: 'Solde et opérations',
                  onTap: () => context.push(AppRoutes.wallet),
                ),
                _ActionCard(
                  icon: Icons.account_tree_outlined,
                  iconColor: AppTheme.secondary,
                  title: 'Traitements vidéo',
                  subtitle: 'File d\'analyse',
                  onTap: () =>
                      context.push(AppRoutes.processingQueue),
                ),
                _ActionCard(
                  icon: Icons.support_agent_outlined,
                  iconColor: AppTheme.primaryLight,
                  title: 'Support',
                  subtitle: 'Réclamations et aide',
                  onTap: () => context.push(AppRoutes.support),
                ),
                _ActionCard(
                  icon: Icons.manage_search_outlined,
                  iconColor: AppTheme.secondaryLight,
                  title: 'Lire une plaque',
                  subtitle: 'Analyse d\'une vidéo',
                  onTap: () => context.push(AppRoutes.videoReader),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.displayName,
    required this.roleLabel,
    required this.plaque,
    required this.pendingCount,
    required this.showPending,
  });

  final String displayName;
  final String roleLabel;
  final String? plaque;
  final int pendingCount;
  final bool showPending;

  String get _initials {
    final parts = displayName
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .take(2)
        .map((p) => p.trim().characters.first.toUpperCase());
    return parts.isEmpty ? 'U' : parts.join();
  }

  @override
  Widget build(BuildContext context) {
    final plaque = this.plaque;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (plaque != null || showPending) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (plaque != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_car,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plaque,
                          style: const TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sync,
                          color: AppTheme.secondaryLight,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$pendingCount en attente d\'envoi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
