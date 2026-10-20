import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/submission_queue_item.dart';
import '../../../core/models/video_processing_queue_item.dart';
import '../../../core/providers/submission_queue_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProcessingQueueScreen extends StatelessWidget {
  const ProcessingQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('File d\'attente'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Signalements'),
              Tab(text: 'Vidéos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SubmissionQueueTab(),
            _VideoQueueTab(),
          ],
        ),
      ),
    );
  }
}

class _SubmissionQueueTab extends StatelessWidget {
  const _SubmissionQueueTab();

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<SubmissionQueueProvider>();

    if (queue.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (queue.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 24),
            Text(
              'Aucun signalement dans la file d\'envoi.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: queue.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: queue.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _SubmissionTile(item: queue.items[index]),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.item});

  final SubmissionQueueItem item;

  (Color, String, IconData) get _status {
    switch (item.queueStatus) {
      case QueueItemStatus.uploading:
        return (AppTheme.primary, 'Envoi en cours', Icons.cloud_upload);
      case QueueItemStatus.processed:
        return (AppTheme.success, 'Envoyé', Icons.check_circle);
      case QueueItemStatus.failed:
        return (AppTheme.error, 'Échec', Icons.error);
      case QueueItemStatus.rejected:
        return (AppTheme.error, 'Rejeté', Icons.block);
      case QueueItemStatus.pending:
        return (AppTheme.warning, 'En attente', Icons.schedule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _status;
    final queue = context.read<SubmissionQueueProvider>();

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.report?.plaqueImmatriculation ??
                        item.report?.numeroImmatriculation ??
                        'Signalement',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (item.error != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.error!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.error),
                    ),
                  ],
                  if (item.retryCount != null && item.retryCount! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tentatives : ${item.retryCount}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (item.localId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => queue.remove(item.localId!),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoQueueTab extends StatelessWidget {
  const _VideoQueueTab();

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<VideoProcessingQueueProvider>();

    if (queue.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (queue.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 24),
            Text(
              'Aucune vidéo en cours d\'analyse.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: queue.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: queue.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = queue.items[index];
          return _VideoTile(item: item, onRemove: queue.remove);
        },
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.item, required this.onRemove});

  final VideoProcessingQueueItem item;
  final Future<void> Function(String localId) onRemove;

  (Color, String, IconData) get _status {
    switch (item.videoStatus) {
      case VideoProcessingStatus.processing:
        return (AppTheme.primary, 'Analyse en cours', Icons.autorenew);
      case VideoProcessingStatus.analyzed:
        return (AppTheme.success, 'Analysée', Icons.check_circle);
      case VideoProcessingStatus.failed:
        return (AppTheme.error, 'Échec', Icons.error);
      case VideoProcessingStatus.pending:
        return (AppTheme.warning, 'En attente', Icons.schedule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _status;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.plate ?? 'Vidéo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (item.score != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Confiance : ${(item.score! * 100).toStringAsFixed(1)} %',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                  if (item.error != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.error!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.error),
                    ),
                  ],
                ],
              ),
            ),
            if (item.localId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onRemove(item.localId!),
              ),
          ],
        ),
      ),
    );
  }
}
