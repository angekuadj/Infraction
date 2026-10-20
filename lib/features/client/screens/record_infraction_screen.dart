import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/incivi_type_provider.dart';
import '../../../core/providers/infraction_provider.dart';
import '../../../core/providers/recap_pending_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class RecordInfractionScreen extends StatefulWidget {
  const RecordInfractionScreen({super.key, this.typeId});

  final String? typeId;

  @override
  State<RecordInfractionScreen> createState() => _RecordInfractionScreenState();
}

class _RecordInfractionScreenState extends State<RecordInfractionScreen>
    with WidgetsBindingObserver {
  static const Duration _maxDuration = Duration(minutes: 2);

  CameraController? _controller;
  bool _initializing = true;
  bool _recording = false;
  bool _capturing = false;
  bool _busy = false;
  String? _error;
  Duration _elapsed = Duration.zero;
  FlashMode _flashMode = FlashMode.off;
  bool _isFrontCamera = false;
  bool _showGrid = true;
  String _captureMode = 'video';
  double _zoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _zoomStart = 1.0;
  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // Camera initialization and lifecycle
  Future<void> _initCamera({bool front = false}) async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _initializing = false;
          _error = 'Permission caméra refusée.';
        });
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'Aucune caméra disponible.';
        });
        return;
      }
      final desired = front
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final description = cameras.firstWhere(
        (c) => c.lensDirection == desired,
        orElse: () => cameras.first,
      );
      final old = _controller;
      _controller = null;
      await old?.dispose();

      final controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _applyFlash(controller, _flashMode);
      double minZoom = 1.0;
      double maxZoom = 1.0;
      try {
        minZoom = await controller.getMinZoomLevel();
        maxZoom = await controller.getMaxZoomLevel();
      } catch (_) {
        // Zoom non supporté sur cet appareil.
      }
      setState(() {
        _controller = controller;
        _isFrontCamera = description.lensDirection == CameraLensDirection.front;
        _minZoom = minZoom;
        _maxZoom = maxZoom < minZoom ? minZoom : maxZoom;
        _zoom = minZoom;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Erreur caméra : $e';
      });
    }
  }

  // Camera controls
  Future<void> _applyFlash(CameraController controller, FlashMode mode) async {
    try {
      if (!controller.value.isInitialized) return;
      if (controller.description.lensDirection == CameraLensDirection.front &&
          mode == FlashMode.torch) {
        return;
      }
      await controller.setFlashMode(mode);
    } catch (_) {
      // Flash non supporté sur cet appareil.
    }
  }

  Future<void> _cycleFlash() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    final next = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
      _ => FlashMode.off,
    };
    await _applyFlash(controller, next);
    if (mounted) {
      setState(() {
        _flashMode = next;
        _busy = false;
      });
    }
  }

  Future<void> _setZoom(double value) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final clamped = value.clamp(_minZoom, _maxZoom).toDouble();
    setState(() => _zoom = clamped);
    try {
      await controller.setZoomLevel(clamped);
    } catch (_) {
      // Zoom non supporté.
    }
  }

  // Gesture handlers
  /// Pincement à deux doigts : cumule le facteur au zoom courant.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale == 1.0 && details.pointerCount < 2) return;
    final target = (_zoomStart * details.scale);
    _setZoom(target);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _zoomStart = _zoom;
  }

  void _onTapToFocus(TapDownDetails details, Size size) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final offset = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    try {
      controller.setFocusPoint(offset);
      controller.setExposurePoint(offset);
    } catch (_) {}
    setState(() => _focusPoint = offset);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _focusPoint = null);
    });
  }

  // Recording controls
  Future<void> _switchCamera() async {
    if (_busy || _recording || _initializing) return;
    setState(() => _busy = true);
    await _initCamera(front: !_isFrontCamera);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggleRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) return;

    if (_recording) {
      await _stopRecording();
      return;
    }

    try {
      await controller.startVideoRecording();
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
      });
      _tick();
    } catch (e) {
      setState(() => _error = 'Erreur démarrage enregistrement : $e');
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_recording) return;
    setState(() => _busy = true);
    try {
      final file = await controller.stopVideoRecording();
      setState(() {
        _recording = false;
        _elapsed = Duration.zero;
        _busy = false;
      });
      if (!mounted) return;
      context.push(
        AppRoutes.infractionTrim,
        extra: {
          'videoPath': file.path,
          'typeId': widget.typeId,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _recording = false;
          _busy = false;
          _error = 'Erreur arrêt enregistrement : $e';
        });
      }
    }
  }

  // Photo capture
  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing ||
        _recording) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/infraction_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = await controller.takePicture();
      final saved = await File(file.path).copy(path);
      if (!mounted) return;

      final report = context.read<InfractionProvider>().createLocalReport(
            typeId: widget.typeId ?? 'non_respect_code_route',
            photoPath: saved.path,
          );
      context.read<RecapPendingProvider>().setPending(report);
      context.push(AppRoutes.infractionRecap);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur photo : $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // Timer
  Future<void> _tick() async {
    while (_recording && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || !_recording) break;
      setState(() => _elapsed += const Duration(milliseconds: 500));
      if (_elapsed >= _maxDuration) {
        await _stopRecording();
        break;
      }
    }
  }

  // Getters
  String get _typeName {
    final type = context.read<InciviTypeProvider>().byId(widget.typeId);
    return type?.nom ?? 'Infraction';
  }

  IconData get _flashIcon => switch (_flashMode) {
        FlashMode.off => Icons.flash_off,
        FlashMode.auto => Icons.flash_auto,
        FlashMode.torch => Icons.flash_on,
        _ => Icons.flash_off,
      };

  // Build
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _AppBar(
        typeName: _typeName,
        showGrid: _showGrid,
        flashMode: _flashMode,
        flashIcon: _flashIcon,
        isRecording: _recording,
        isBusy: _busy,
        onToggleGrid: () => setState(() => _showGrid = !_showGrid),
        onCycleFlash: _cycleFlash,
        onSwitchCamera: _switchCamera,
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? _ErrorView(
                  error: _error!,
                  onRetry: () => _initCamera(front: _isFrontCamera),
                )
              : Column(
                  children: [
                    Expanded(
                      child: controller == null ||
                              !controller.value.isInitialized
                          ? const CircularProgressIndicator(color: Colors.white)
                          : _CameraPreview(
                              controller: controller,
                              showGrid: _showGrid,
                              isFrontCamera: _isFrontCamera,
                              focusPoint: _focusPoint,
                              isRecording: _recording,
                              elapsed: _elapsed,
                              maxDuration: _maxDuration,
                              zoom: _zoom,
                              minZoom: _minZoom,
                              maxZoom: _maxZoom,
                              onScaleStart: _onScaleStart,
                              onScaleUpdate: _onScaleUpdate,
                              onTapToFocus: _onTapToFocus,
                              onZoomChanged: _setZoom,
                            ),
                    ),
                    if (auth.isUsager && auth.user?.enPanne == true)
                      const _BreakdownBanner(),
                    _ControlsSection(
                      isRecording: _recording,
                      captureMode: _captureMode,
                      isCapturing: _capturing,
                      onToggleRecording: _toggleRecording,
                      onTakePhoto: _takePhoto,
                      onModeChanged: (mode) => setState(() => _captureMode = mode),
                    ),
                  ],
                ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({
    required this.typeName,
    required this.showGrid,
    required this.flashMode,
    required this.flashIcon,
    required this.isRecording,
    required this.isBusy,
    required this.onToggleGrid,
    required this.onCycleFlash,
    required this.onSwitchCamera,
  });

  final String typeName;
  final bool showGrid;
  final FlashMode flashMode;
  final IconData flashIcon;
  final bool isRecording;
  final bool isBusy;
  final VoidCallback onToggleGrid;
  final VoidCallback onCycleFlash;
  final VoidCallback onSwitchCamera;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(typeName),
      actions: [
        IconButton(
          tooltip: 'Grille',
          icon: Icon(
            Icons.grid_3x3,
            color: showGrid ? Colors.white : Colors.white38,
          ),
          onPressed: onToggleGrid,
        ),
        IconButton(
          tooltip: 'Flash',
          icon: Icon(
            flashIcon,
            color: flashMode == FlashMode.off
                ? Colors.white38
                : AppTheme.secondaryLight,
          ),
          onPressed: isBusy || isRecording ? null : onCycleFlash,
        ),
        IconButton(
          tooltip: 'Rotation caméra',
          icon: const Icon(Icons.cameraswitch_outlined),
          onPressed: isBusy || isRecording ? null : onSwitchCamera,
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: error.contains('Permission')
                  ? () => openAppSettings()
                  : onRetry,
              child: Text(error.contains('Permission')
                  ? 'Ouvrir les paramètres'
                  : 'Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({
    required this.controller,
    required this.showGrid,
    required this.isFrontCamera,
    required this.focusPoint,
    required this.isRecording,
    required this.elapsed,
    required this.maxDuration,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onTapToFocus,
    required this.onZoomChanged,
  });

  final CameraController controller;
  final bool showGrid;
  final bool isFrontCamera;
  final Offset? focusPoint;
  final bool isRecording;
  final Duration elapsed;
  final Duration maxDuration;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final void Function(ScaleStartDetails) onScaleStart;
  final void Function(ScaleUpdateDetails) onScaleUpdate;
  final void Function(TapDownDetails, Size) onTapToFocus;
  final ValueChanged<double> onZoomChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return GestureDetector(
              onScaleStart: onScaleStart,
              onScaleUpdate: onScaleUpdate,
              onTapDown: (d) => onTapToFocus(d, size),
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),
            );
          },
        ),
        if (showGrid && !isFrontCamera) const _GridOverlay(),
        if (focusPoint != null)
          Positioned(
            left: focusPoint!.dx - 30,
            top: focusPoint!.dy - 30,
            child: const _FocusReticle(),
          ),
        if (isRecording)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDuration(elapsed)} / ${_formatDuration(maxDuration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (maxZoom > minZoom)
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ZoomBar(
                zoom: zoom,
                minZoom: minZoom,
                maxZoom: maxZoom,
                onChanged: onZoomChanged,
              ),
            ),
          ),
        if (zoom > minZoom + 0.05)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${zoom.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _BreakdownBanner extends StatelessWidget {
  const _BreakdownBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.warning,
      padding: const EdgeInsets.all(8),
      child: const Text(
        'Véhicule en panne : les signalements sont ignorés.',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class _ControlsSection extends StatelessWidget {
  const _ControlsSection({
    required this.isRecording,
    required this.captureMode,
    required this.isCapturing,
    required this.onToggleRecording,
    required this.onTakePhoto,
    required this.onModeChanged,
  });

  final bool isRecording;
  final String captureMode;
  final bool isCapturing;
  final VoidCallback onToggleRecording;
  final VoidCallback onTakePhoto;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            if (!isRecording)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    selectedBackgroundColor: AppTheme.primary,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: Colors.white70,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'video',
                      label: Text('Vidéo'),
                      icon: Icon(Icons.videocam_outlined),
                    ),
                    ButtonSegment(
                      value: 'photo',
                      label: Text('Photo'),
                      icon: Icon(Icons.photo_camera_outlined),
                    ),
                  ],
                  selected: {isRecording ? 'video' : captureMode},
                  onSelectionChanged: (s) => onModeChanged(s.first),
                ),
              ),
            const SizedBox(height: 14),
            if (captureMode == 'video')
              GestureDetector(
                onTap: onToggleRecording,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isRecording ? 28 : 58,
                      height: isRecording ? 28 : 58,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(isRecording ? 4 : 29),
                      ),
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: isCapturing ? null : onTakePhoto,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: isCapturing
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera, color: Colors.white, size: 40),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              captureMode == 'video'
                  ? (isRecording
                      ? 'Appuyez pour arrêter (max 2 min)'
                      : 'Appuyez pour enregistrer la vidéo')
                  : 'Appuyez pour prendre la photo',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _FocusReticle extends StatelessWidget {
  const _FocusReticle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.secondaryLight, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onChanged,
  });

  final double zoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: 40,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: AppTheme.secondaryLight,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            min: minZoom,
            max: maxZoom,
            value: zoom.clamp(minZoom, maxZoom),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

