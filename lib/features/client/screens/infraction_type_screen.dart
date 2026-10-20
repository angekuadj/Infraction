import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/incivi_type.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/incivi_type_provider.dart';
import '../../../core/theme/app_theme.dart';

class InfractionTypeScreen extends StatefulWidget {
  const InfractionTypeScreen({super.key});

  @override
  State<InfractionTypeScreen> createState() => _InfractionTypeScreenState();
}

class _InfractionTypeScreenState extends State<InfractionTypeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      context.read<InciviTypeProvider>().load(token: token);
    });
  }

  IconData _iconFor(String id) {
    final v = id.toLowerCase();
    if (v.contains('stationnement')) return Icons.local_parking;
    if (v.contains('code_route') || v.contains('route')) {
      return Icons.traffic;
    }
    if (v.contains('arret')) return Icons.pan_tool_outlined;
    if (v.contains('conduite')) return Icons.warning_amber_rounded;
    if (v.contains('vie_commune')) return Icons.volume_up_outlined;
    if (v.contains('tarif')) return Icons.price_change_outlined;
    if (v.contains('declar')) return Icons.storefront_outlined;
    if (v.contains('corruption')) return Icons.gavel_outlined;
    if (v.contains('pollution')) return Icons.eco_outlined;
    return Icons.report_problem_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InciviTypeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Type d\'infraction'),
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.types.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final type = provider.types[index];
                return _TypeCard(
                  type: type,
                  icon: _iconFor(type.id),
                  onTap: () => context.push(
                    '/client/infraction/record/${type.id}',
                  ),
                );
              },
            ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.icon,
    required this.onTap,
  });

  final InciviType type;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (type.description != null &&
                        type.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        type.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
