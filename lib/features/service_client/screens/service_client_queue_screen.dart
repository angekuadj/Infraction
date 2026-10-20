import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/reclamation_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/support_provider.dart';
import '../../../core/theme/app_theme.dart';

class ServiceClientQueueScreen extends StatefulWidget {
  const ServiceClientQueueScreen({super.key});

  @override
  State<ServiceClientQueueScreen> createState() =>
      _ServiceClientQueueScreenState();
}

class _ServiceClientQueueScreenState extends State<ServiceClientQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<SupportProvider>().loadAll(token: auth.token);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<SupportProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Service client'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
          bottom: TabBar(
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'File (${provider.queue.length})'),
              Tab(text: 'Assignées (${provider.assigned.length})'),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _QueueList(
                    items: provider.queue,
                    emptyLabel: 'Aucune réclamation en attente.',
                    emptyIcon: Icons.inbox_outlined,
                  ),
                  _QueueList(
                    items: provider.assigned,
                    emptyLabel: 'Aucune réclamation assignée.',
                    emptyIcon: Icons.assignment_turned_in,
                  ),
                ],
              ),
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({
    required this.items,
    required this.emptyLabel,
    required this.emptyIcon,
  });

  final List<ReclamationModel> items;
  final String emptyLabel;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                emptyIcon,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await context
            .read<SupportProvider>()
            .loadAll(token: context.read<AuthProvider>().token);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReclamationCard(
                  item: item,
                  onTap: item.id == null
                      ? null
                      : () => context.push('/support/${item.id}'),
                ),
              )),
        ],
      ),
    );
  }
}

class _ReclamationCard extends StatelessWidget {
  const _ReclamationCard({required this.item, this.onTap});

  final ReclamationModel item;
  final VoidCallback? onTap;

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
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.support_agent,
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
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (item.clientName != null) item.clientName!,
                          if (item.createdAt != null)
                            DateFormat('dd/MM HH:mm').format(
                              item.createdAt!.toLocal(),
                            ),
                        ].join(' • '),
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
