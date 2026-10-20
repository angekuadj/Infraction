import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/infraction_report.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/infraction_provider.dart';
import '../../../core/providers/incivi_type_provider.dart';

class InfractionVideoScreen extends StatefulWidget {
  const InfractionVideoScreen({super.key, required this.id});

  final String id;

  @override
  State<InfractionVideoScreen> createState() => _InfractionVideoScreenState();
}

class _InfractionVideoScreenState extends State<InfractionVideoScreen> {
  VideoPlayerController? _controller;
  InfractionReport? _report;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<InfractionProvider>();
    final local = [...provider.localReports, ...provider.serverReports]
        .where((r) => r.id == widget.id || r.localId == widget.id)
        .toList();
    var report = local.isEmpty ? null : local.first;
    report ??= await provider.fetchById(
      token: context.read<AuthProvider>().token ?? '',
      id: widget.id,
    );
    if (!mounted) return;
    _report = report;
    final path = report?.videoPath;
    final url = report?.videoUrl;
    try {
      if (path != null && File(path).existsSync()) {
        _controller = VideoPlayerController.file(File(path));
        await _controller!.initialize();
      } else if (url != null && url.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await _controller!.initialize();
      }
      _controller?.setLooping(true);
    } catch (e) {
      _error = 'Impossible de lire la vidéo : $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = context
        .watch<InciviTypeProvider>()
        .byId(_report?.typeId ?? _report?.inciviTypeId);
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(type?.nom ?? 'Vidéo du signalement')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : controller != null &&
                                controller.value.isInitialized
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio: controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  ),
                                  IconButton(
                                    iconSize: 64,
                                    color: Colors.white,
                                    icon: Icon(
                                      controller.value.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                    ),
                                    onPressed: () {
                                      if (controller.value.isPlaying) {
                                        controller.pause();
                                      } else {
                                        controller.play();
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ],
                              )
                            : const Center(
                                child: Icon(
                                  Icons.videocam_off,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                  ),
                ),
                if (_report != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _report!.plaqueImmatriculation ??
                              _report!.numeroImmatriculation ??
                              'Plaque non renseignée',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_report!.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_report!.description!),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Retour'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
