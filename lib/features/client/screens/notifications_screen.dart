import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/notification_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load(
            token: context.read<AuthProvider>().token,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (provider.hasUnread)
            TextButton(
              onPressed: () => provider.markAllRead(
                token: context.read<AuthProvider>().token,
              ),
              child: const Text(
                'Tout lire',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(
          token: context.read<AuthProvider>().token,
        ),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.notifications.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Aucune notification.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = provider.notifications[index];
                      return _NotificationCard(
                        notification: n,
                        onTap: () {
                          if (n.id != null) {
                            provider.markRead(
                              token: context.read<AuthProvider>().token,
                              id: n.id!,
                            );
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = notification.title ?? notification.subject ?? 'Notification';
    final body = notification.body ?? notification.message ?? '';

    return Container(
      decoration: BoxDecoration(
        color: notification.read
            ? AppTheme.surface
            : AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: notification.read
            ? null
            : Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: notification.read
                            ? FontWeight.w600
                            : FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    if (notification.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm')
                            .format(notification.createdAt!.toLocal()),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
