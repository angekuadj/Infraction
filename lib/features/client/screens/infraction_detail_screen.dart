import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/infraction_report.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/infraction_provider.dart';
import '../../../core/providers/incivi_type_provider.dart';
import '../../../core/theme/app_theme.dart';

class InfractionDetailScreen extends StatefulWidget {
  const InfractionDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<InfractionDetailScreen> createState() => _InfractionDetailScreenState();
}

class _InfractionDetailScreenState extends State<InfractionDetailScreen> {
  InfractionReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<InfractionProvider>();
    final auth = context.read<AuthProvider>();
    final local = [...provider.localReports, ...provider.serverReports]
        .where((r) => r.id == widget.id || r.localId == widget.id)
        .toList();
    if (local.isNotEmpty) {
      setState(() {
        _report = local.first;
        _loading = false;
      });
    }
    final fetched = await provider.fetchById(
      token: auth.token ?? '',
      id: widget.id,
    );
    if (mounted && fetched != null) {
      setState(() {
        _report = fetched;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeName = context
            .watch<InciviTypeProvider>()
            .byId(_report?.typeId ?? _report?.inciviTypeId)
            ?.nom ??
        'Infraction';
    final report = _report;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(typeName),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? const Center(child: Text('Signalement introuvable'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (report.videoUrl != null ||
                        report.videoPath != null ||
                        report.photoPath != null ||
                        report.imageUrl != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(color: Colors.black87),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Material(
                                  color: Colors.black54,
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.ondemand_video,
                                      color: Colors.white,
                                    ),
                                    title: const Text(
                                      'Voir la vidéo du signalement',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                    onTap: () => context.push(
                                      '/client/infractions/${widget.id}/video',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _InfoTile(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Plaque',
                      value: report.plaqueImmatriculation ??
                          report.numeroImmatriculation ??
                          '—',
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.place_outlined,
                      label: 'Lieu',
                      value: report.lieu ?? '—',
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.info_outline,
                      label: 'Statut',
                      value: _statusLabel(report),
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: (report.createdAt ??
                                  report.reportedAt ??
                                  report.sentAt)
                              ?.toLocal()
                              .let((d) => DateFormat('dd/MM/yyyy à HH:mm').format(d)) ??
                          '—',
                    ),
                    if (report.description != null &&
                        report.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.notes_outlined,
                        label: 'Description',
                        value: report.description!,
                      ),
                    ],
                    if (report.commentaire != null &&
                        report.commentaire!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.comment_outlined,
                        label: 'Commentaire',
                        value: report.commentaire!,
                      ),
                    ],
                    if (report.latitude != null && report.longitude != null) ...[
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.my_location,
                        label: 'Coordonnées',
                        value:
                            '${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
                      ),
                    ],
                    if (report.score != null) ...[
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.verified_outlined,
                        label: 'Confiance',
                        value: '${(report.score! * 100).toStringAsFixed(1)} %',
                      ),
                    ],
                    if (report.isPending) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: AppTheme.warning),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Ce signalement est en attente d\'envoi. '
                                'Il sera transmis dès que possible.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  String _statusLabel(InfractionReport r) {
    if (r.isPending) return 'En attente';
    if (r.isRejetee) return 'Rejetée';
    if (r.isAcceptee) return 'Acceptée';
    if (r.isTraitee) return 'Traitée';
    return r.status ?? r.statut ?? 'Envoyée';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
