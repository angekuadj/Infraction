import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/providers/infraction_provider.dart';
import '../../../core/providers/recap_pending_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/video_trim_service.dart';
import '../../../core/theme/app_theme.dart';

class VideoTrimScreen extends StatefulWidget {
  const VideoTrimScreen({super.key, this.videoPath, this.typeId});

  final String? videoPath;
  final String? typeId;

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  VideoPlayerController? _controller;
  double _start = 0;
  double _end = 0;
  bool _ready = false;
  bool _trimming = false;

  final _trimService = VideoTrimService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final path = widget.videoPath;
    if (path == null || !File(path).existsSync()) {
      setState(() => _ready = true);
      return;
    }
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      _controller = controller;
      _end = controller.value.duration.inMilliseconds.toDouble();
      setState(() => _ready = true);
    } catch (_) {
      setState(() => _ready = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _fmt(double ms) {
    final d = Duration(milliseconds: ms.round());
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _continue() async {
    if (_trimming) return;
    final originalPath = widget.videoPath;
    var videoPath = originalPath;
    final startMs = _start.round();
    final endMs = _end.round();
    final durationMs = _controller?.value.duration.inMilliseconds ?? 0;
    final needsTrim = _controller?.value.isInitialized == true &&
        durationMs > 0 &&
        (startMs > 50 || endMs < durationMs - 100);

    if (originalPath != null &&
        needsTrim &&
        File(originalPath).existsSync() &&
        endMs > startMs) {
      setState(() => _trimming = true);
      try {
        final dir = await getTemporaryDirectory();
        final outputPath =
            '${dir.path}/infraction_trim_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final trimmed = await _trimService.trim(
          inputPath: originalPath,
          outputPath: outputPath,
          start: Duration(milliseconds: startMs),
          end: Duration(milliseconds: endMs),
        );
        if (trimmed != null && File(trimmed).existsSync()) {
          videoPath = trimmed;
        }
      } catch (_) {
        // En cas d'échec, la vidéo originale reste utilisée.
      } finally {
        if (mounted) setState(() => _trimming = false);
      }
    }

    if (!mounted) return;
    final report = context.read<InfractionProvider>().createLocalReport(
          typeId: widget.typeId ?? 'non_respect_code_route',
          videoPath: videoPath,
          trimStart: startMs.toString(),
          trimEnd: endMs.toString(),
        );
    context.read<RecapPendingProvider>().setPending(report);
    context.push(AppRoutes.infractionRecap);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final duration =
        controller?.value.duration.inMilliseconds.toDouble() ?? 0.0;
    final max = duration > 0 ? duration : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Découper la vidéo')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: controller != null && controller.value.isInitialized
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: VideoPlayer(controller),
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Vidéo indisponible',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Début : ${_fmt(_start)}   Fin : ${_fmt(_end)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: RangeValues(
                          _start.clamp(0, max),
                          _end.clamp(0, max),
                        ),
                        max: max,
                        onChanged: (v) {
                          setState(() {
                            _start = v.start;
                            _end = v.end;
                          });
                        },
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _trimming || controller == null
                                ? null
                                : () async {
                                    if (controller.value.isPlaying) {
                                      await controller.pause();
                                    } else {
                                      await controller.seekTo(
                                        Duration(milliseconds: _start.round()),
                                      );
                                      await controller.play();
                                    }
                                    setState(() {});
                                  },
                            icon: Icon(
                              controller?.value.isPlaying == true
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            label: const Text('Prévisualiser'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _trimming ? null : _continue,
                            child: _trimming
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Continuer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Utilisez les curseurs pour sélectionner la séquence '
                        'montrant l\'infraction.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
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
