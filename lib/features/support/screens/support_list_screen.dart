import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/reclamation_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/support_provider.dart';
import '../../../core/theme/app_theme.dart';

class SupportListScreen extends StatefulWidget {
  const SupportListScreen({super.key});

  @override
  State<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends State<SupportListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<SupportProvider>();
    if (auth.isAgent || auth.isAdmin) {
      await provider.loadAll(token: auth.token);
    } else {
      await provider.loadReclamations(token: auth.token);
    }
  }

  Future<void> _create() async {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.support_agent, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Nouvelle réclamation'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectCtrl,
                decoration: InputDecoration(
                  labelText: 'Objet',
                  prefixIcon: const Icon(Icons.subject),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.message),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;
    if (subjectCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final created = await context.read<SupportProvider>().createReclamation(
          token: auth.token ?? '',
          subject: subjectCtrl.text.trim(),
          message: messageCtrl.text.trim(),
        );
    if (!mounted) return;
    if (created != null) {
      context.push('/support/${created.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de créer la réclamation.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<SupportProvider>();
    final isAgent = auth.isAgent || auth.isAdmin;

    final items = isAgent
        ? [...provider.assigned, ...provider.queue]
        : provider.reclamations;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Support'),
        elevation: 0,
      ),
      floatingActionButton: isAgent
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Réclamation'),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.isLoading && items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 60),
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
                            Icons.support_agent,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Aucune réclamation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          isAgent
                              ? 'Aucun ticket à traiter.'
                              : 'Commencez par créer une nouvelle réclamation.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _StatsCard(isAgent: isAgent, provider: provider),
                      const SizedBox(height: 16),
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
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.isAgent, required this.provider});

  final bool isAgent;
  final SupportProvider provider;

  @override
  Widget build(BuildContext context) {
    if (isAgent) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withValues(alpha: 0.1),
              AppTheme.primaryDark.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.assignment_turned_in,
                label: 'Assignés',
                value: provider.assigned.length.toString(),
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatItem(
                icon: Icons.inbox,
                label: 'En attente',
                value: provider.queue.length.toString(),
                color: AppTheme.warning,
              ),
            ),
          ],
        ),
      );
    }

    final total = provider.reclamations.length;
    final closed = provider.reclamations
        .where((r) => r.closed ||
            r.status?.toLowerCase() == 'closed' ||
            r.status?.toLowerCase() == 'fermee')
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.primaryDark.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.chat_bubble_outline,
              label: 'Total',
              value: total.toString(),
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_outline,
              label: 'Résolues',
              value: closed.toString(),
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ReclamationCard extends StatelessWidget {
  const _ReclamationCard({required this.item, this.onTap});

  final ReclamationModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final closed = item.closed ||
        item.status?.toLowerCase() == 'closed' ||
        item.status?.toLowerCase() == 'fermee';

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
                    color: (closed ? AppTheme.textSecondary : AppTheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    closed ? Icons.check_circle : Icons.support_agent,
                    color: closed ? AppTheme.textSecondary : AppTheme.primary,
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
                      if (item.displayMessage.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.displayMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: closed
                                  ? AppTheme.success.withValues(alpha: 0.1)
                                  : AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              closed ? 'Fermée' : (item.status ?? 'Ouverte'),
                              style: TextStyle(
                                fontSize: 11,
                                color: closed
                                    ? AppTheme.success
                                    : AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.createdAt != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(
                                item.createdAt!.toLocal(),
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
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
