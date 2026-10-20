import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../core/models/plate_overlay_zone.dart';
import '../../../core/plate/cote_ivoire_plate.dart';
import '../../../core/providers/incivi_type_provider.dart';
import '../../../core/providers/infraction_provider.dart';
import '../../../core/providers/recap_pending_provider.dart';
import '../../../core/providers/video_processing_queue_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/plate_detection_service.dart';
import '../../../core/services/plate_recognizer_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class VideoPlateReaderScreen extends StatefulWidget {
  const VideoPlateReaderScreen({super.key});

  @override
  State<VideoPlateReaderScreen> createState() => _VideoPlateReaderScreenState();
}

class _VideoPlateReaderScreenState extends State<VideoPlateReaderScreen> {
  final _detection = PlateDetectionService();
  VideoPlayerController? _controller;
  String? _videoPath;
  bool _analyzing = false;
  List<String> _plates = [];
  List<PlateOverlayZone> _zones = [];
  String? _error;
  String? _externalWarning;

  @override
  void dispose() {
    _controller?.dispose();
    _detection.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFile(type: FileType.video);
    final path = result?.path;
    if (path == null) return;
    await _controller?.dispose();
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
    } catch (e) {
      setState(() => _error = 'Vidéo illisible : $e');
      return;
    }
    setState(() {
      _videoPath = path;
      _controller = controller;
      _plates = [];
      _zones = [];
      _error = null;
    });
  }

  Future<void> _analyze() async {
    final path = _videoPath;
    if (path == null) return;
    setState(() {
      _analyzing = true;
      _error = null;
      _externalWarning = null;
    });

    final queue = context.read<VideoProcessingQueueProvider>();
    final item = await queue.enqueue(path);
    await queue.markProcessing(item.localId!);

    final plates = <String>{};
    final zones = <PlateOverlayZone>[];
    String? externalWarning;
    try {
      final token = await PlateRecognizerConfig.loadToken();
      final region = await PlateRecognizerConfig.loadRegion();
      final external = PlateRecognizerService(apiToken: token);
      final dir = await getTemporaryDirectory();
      final duration = _controller?.value.duration ?? const Duration(seconds: 5);
      final samples = <double>[
        0,
        duration.inMilliseconds / 3,
        (duration.inMilliseconds * 2) / 3,
      ];
      for (var i = 0; i < samples.length; i++) {
        final thumb = await VideoThumbnail.thumbnailFile(
          video: path,
          thumbnailPath: '${dir.path}/plate_frame_$i.jpg',
          imageFormat: ImageFormat.JPEG,
          maxHeight: 720,
          quality: 85,
          timeMs: samples[i].round(),
        );
        if (thumb == null) continue;
        final result = await _detection.detect(imagePath: thumb);
        plates.addAll(result.plates);
        zones.addAll(result.zones);

        if (external.isConfigured) {
          try {
            final remote = await external.recognizeFile(
              File(thumb),
              region: region,
            );
            for (final recognition in remote) {
              final normalized = CoteIvoirePlate.normalize(recognition.plate);
              if (CoteIvoirePlate.isValid(normalized)) {
                plates.add(normalized);
              }
            }
          } catch (e) {
            externalWarning ??= e.toString();
          }
        }
      }
      final list = plates.toList();
      await queue.markAnalyzed(
        item.localId!,
        plate: list.isEmpty ? null : list.first,
      );
      if (!mounted) return;
      setState(() {
        _plates = list;
        _zones = zones;
        _externalWarning = externalWarning;
        _analyzing = false;
      });
    } catch (e) {
      await queue.markFailed(item.localId!, error: e.toString());
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _error = 'Analyse impossible : $e';
      });
    }
  }

  void _usePlate(String plate) {
    final recap = context.read<RecapPendingProvider>();
    if (recap.hasPending) {
      recap.updatePlate(plate);
      context.push(AppRoutes.infractionRecap);
    } else {
      final type = context.read<InciviTypeProvider>().types.isNotEmpty
          ? context.read<InciviTypeProvider>().types.first.id
          : 'non_respect_code_route';
      final report = context
          .read<InfractionProvider>()
          .createLocalReport(typeId: type, plaque: plate, videoPath: _videoPath);
      recap.setPending(report, detectedPlate: plate);
      context.push(AppRoutes.infractionRecap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Lecture de plaque')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.video_file_outlined,
                      size: 64,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sélectionnez une vidéo pour détecter et lire '
                      'la plaque d\'immatriculation.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Choisir une vidéo'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                      setState(() {});
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: const Text('Lecture'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('Changer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _analyzing ? null : _analyze,
              icon: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _analyzing ? 'Analyse en cours…' : 'Analyser la plaque',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.error)),
            ],
            if (_externalWarning != null) ...[
              const SizedBox(height: 12),
              Text(
                'Reconnaissance externe indisponible : $_externalWarning',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (_zones.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${_zones.length} zone(s) détectée(s)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (_plates.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Plaques reconnues',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._plates.map(
                (plate) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppTheme.success,
                    ),
                    title: Text(
                      plate,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () => _usePlate(plate),
                      child: const Text('Utiliser'),
                    ),
                  ),
                ),
              ),
            ] else if (!_analyzing && _zones.isEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Aucune plaque détectée. Vous pouvez saisir la plaque '
                'manuellement dans le récapitulatif.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
