import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/infraction_report.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/infraction_provider.dart';
import '../../../core/providers/incivi_type_provider.dart';
import '../../../core/theme/app_theme.dart';

enum InfractionListMode { all, myPlate, myReports }

class InfractionListScreen extends StatefulWidget {
  const InfractionListScreen({super.key, this.mode = InfractionListMode.all});

  final InfractionListMode mode;

  @override
  State<InfractionListScreen> createState() => _InfractionListScreenState();
}

class _InfractionListScreenState extends State<InfractionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<InfractionProvider>();
    if (widget.mode == InfractionListMode.myReports) {
      await provider.loadMyReports(token: auth.token);
    } else if (widget.mode == InfractionListMode.myPlate) {
      final plaque = auth.user?.plaqueImmatriculation ??
          auth.user?.numeroImmatriculation;
      if (plaque != null && plaque.isNotEmpty) {
        await provider.loadForMyPlate(token: auth.token!, plaque: plaque);
      }
    }
  }

  String get _title {
    switch (widget.mode) {
      case InfractionListMode.myReports:
        return 'Mes signalements';
      case InfractionListMode.myPlate:
        return 'Infractions pour ma plaque';
      case InfractionListMode.all:
        return 'Signalements';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InfractionProvider>();
    final types = context.watch<InciviTypeProvider>();

    final reports = <InfractionReport>[
      if (widget.mode == InfractionListMode.myReports) ...provider.localReports,
      ...provider.serverReports,
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_title),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : reports.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(
                        Icons.inbox_outlined,
                        size: 80,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Aucun signalement pour le moment.',
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
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final type = types.byId(report.typeId) ??
                          types.byId(report.inciviTypeId);
                      return _ReportCard(
                        report: report,
                        typeName: type?.nom ?? 'Infraction',
                        onTap: () {
                          final id = report.id ?? report.localId;
                          if (id != null) {
                            context.push('/client/infractions/$id');
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.typeName,
    required this.onTap,
  });

  final InfractionReport report;
  final String typeName;
  final VoidCallback onTap;

  Color get _statusColor {
    if (report.isPending) return AppTheme.warning;
    if (report.isRejetee) return AppTheme.error;
    if (report.isAcceptee || report.isTraitee) return AppTheme.success;
    return AppTheme.primary;
  }

  String get _statusLabel {
    if (report.isPending) return 'En attente';
    if (report.isRejetee) return 'Rejetée';
    if (report.isAcceptee) return 'Acceptée';
    if (report.isTraitee) return 'Traitée';
    return report.status ?? 'Envoyée';
  }

  @override
  Widget build(BuildContext context) {
    final date = report.createdAt ?? report.reportedAt ?? report.sentAt;
    final plaque =
        report.plaqueImmatriculation ?? report.numeroImmatriculation;

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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      typeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (plaque != null && plaque.isNotEmpty)
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      plaque.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              if (report.lieu != null && report.lieu!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        report.lieu!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (date != null) ...[
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(date.toLocal()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
