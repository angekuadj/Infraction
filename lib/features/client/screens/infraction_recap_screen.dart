import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/infraction_report.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/incivi_type_provider.dart';
import '../../../core/providers/infraction_provider.dart';
import '../../../core/providers/recap_pending_provider.dart';
import '../../../core/providers/submission_queue_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/location_permission_service.dart';
import '../../../core/services/media_plate_analysis_service.dart';
import '../../../core/services/plate_recognizer_service.dart';
import '../../../core/theme/app_theme.dart';

class InfractionRecapScreen extends StatefulWidget {
  const InfractionRecapScreen({super.key});

  @override
  State<InfractionRecapScreen> createState() => _InfractionRecapScreenState();
}

class _InfractionRecapScreenState extends State<InfractionRecapScreen> {
  final _plaqueCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _locationService = LocationPermissionService();
  final _analysis = MediaPlateAnalysisService();

  bool _submitting = false;
  bool _analyzing = false;
  bool _locating = false;
  String? _analysisError;
  bool _locationLocked = false;

  @override
  void initState() {
    super.initState();
    final recap = context.read<RecapPendingProvider>();
    final pending = recap.pending;
    _plaqueCtrl.text = recap.detectedPlate ??
        pending?.plaqueImmatriculation ??
        context.read<AuthProvider>().user?.plaqueImmatriculation ??
        '';
    _descriptionCtrl.text = pending?.description ?? '';
    _lieuCtrl.text = pending?.lieu ?? '';
    _locationLocked = (pending?.lieu?.isNotEmpty ?? false) &&
        pending?.latitude != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAiAnalysis();
      if (!_locationLocked) _runLocation();
    });
  }

  @override
  void dispose() {
    _plaqueCtrl.dispose();
    _descriptionCtrl.dispose();
    _lieuCtrl.dispose();
    _analysis.dispose();
    super.dispose();
  }

  /// Analyse IA : lit la vidéo ou la photo, détecte la plaque,
  /// la saisit automatiquement et recadre la photo de la plaque.
  Future<void> _runAiAnalysis() async {
    final recap = context.read<RecapPendingProvider>();
    final report = recap.pending;
    if (report == null || _analyzing) return;

    final videoPath = report.videoPath;
    final photoPath = report.photoPath;
    final hasMedia = (videoPath != null && File(videoPath).existsSync()) ||
        (photoPath != null && File(photoPath).existsSync());
    if (!hasMedia) return;

    setState(() {
      _analyzing = true;
      _analysisError = null;
    });
    recap.setProcessing(true);
    try {
      var result = await _analysis.analyze(
        videoPath: videoPath,
        photoPath: photoPath,
      );

      // Fusion optionnelle avec le service externe PlateRecognizer.
      try {
        final token = await PlateRecognizerConfig.loadToken();
        final external = PlateRecognizerService(apiToken: token);
        if (external.isConfigured) {
          final frame = result.framePath;
          if (frame != null && File(frame).existsSync()) {
            final region = await PlateRecognizerConfig.loadRegion();
            final remote =
                await external.recognizeFile(File(frame), region: region);
            if (remote.isNotEmpty) {
              result = _analysis.mergeExternal(result, remote);
            }
          }
        }
      } catch (_) {
        // Le service externe est une amélioration, jamais bloquant.
      }

      if (!mounted) return;
      recap.applyAnalysis(
        plate: result.plate,
        score: result.score,
        plateImagePath: result.plateImagePath,
      );
      if (result.detected && _plaqueCtrl.text.trim().isEmpty) {
        _plaqueCtrl.text = result.plate!;
      }
      if (!result.detected) {
        setState(() => _analysisError =
            'Aucune plaque détectée automatiquement, saisissez-la manuellement.');
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _analysisError = 'Analyse IA indisponible : $e');
      }
      recap.applyAnalysis(plate: null);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  /// Lieu : position GPS + reverse geocoding, champ grisé.
  Future<void> _runLocation() async {
    final recap = context.read<RecapPendingProvider>();
    if (recap.pending == null || _locating) return;
    setState(() => _locating = true);
    try {
      final position = await _locationService.currentPosition();
      if (position == null || !mounted) return;

      String label;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final p = placemarks.isNotEmpty ? placemarks.first : null;
        final parts = [
          if (p != null && (p.street?.isNotEmpty ?? false)) p.street!,
          if (p != null && (p.subLocality?.isNotEmpty ?? false))
            p.subLocality!,
          if (p != null && (p.locality?.isNotEmpty ?? false)) p.locality!,
        ];
        label = parts.isNotEmpty
            ? parts.join(', ')
            : '${position.latitude.toStringAsFixed(5)}, '
                '${position.longitude.toStringAsFixed(5)}';
      } catch (_) {
        label = '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      }

      if (!mounted) return;
      setState(() {
        _lieuCtrl.text = label;
        _locationLocked = true;
      });
      recap.applyLocation(
        lieu: label,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Localisation indisponible : le champ reste éditable.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    final recap = context.read<RecapPendingProvider>();
    final report = recap.pending;
    if (report == null) return;

    final updated = report.copyWith(
      plaqueImmatriculation: _plaqueCtrl.text.trim().isEmpty
          ? null
          : _plaqueCtrl.text.trim(),
      numeroImmatriculation: _plaqueCtrl.text.trim().isEmpty
          ? null
          : _plaqueCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      lieu: _lieuCtrl.text.trim(),
    );

    final auth = context.read<AuthProvider>();
    final provider = context.read<InfractionProvider>();
    final queue = context.read<SubmissionQueueProvider>();

    setState(() => _submitting = true);
    final token = auth.token;
    if (token == null) {
      _enqueue(queue, updated);
      if (mounted) _finish('Signalement enregistré pour envoi.');
      return;
    }

    final result = await provider.submit(
      token: token,
      report: updated,
      video: updated.videoPath != null && File(updated.videoPath!).existsSync()
          ? File(updated.videoPath!)
          : null,
      photo: updated.photoPath != null && File(updated.photoPath!).existsSync()
          ? File(updated.photoPath!)
          : null,
      plateImage: updated.plateImagePath != null &&
              File(updated.plateImagePath!).existsSync()
          ? File(updated.plateImagePath!)
          : null,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result != null) {
      recap.clear();
      _finish('Signalement envoyé avec succès.');
    } else {
      _enqueue(queue, updated);
      _finish('Signalement enregistré pour envoi.');
    }
  }

  void _enqueue(SubmissionQueueProvider queue, InfractionReport report) {
    queue.enqueue(
      reportJson: report.toJson(),
      videoPath: report.videoPath,
      photoPath: report.photoPath,
    );
  }

  void _finish(String message) {
    final recap = context.read<RecapPendingProvider>();
    recap.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.success),
    );
    context.go(AppRoutes.myReports);
  }

  String _getPlateHelperText(bool plateLocked, bool isOwner, bool hasDetectedPlate) {
    if (plateLocked) {
      if (hasDetectedPlate) {
        return 'Remplie automatiquement par l\'IA';
      }
      return 'Remplie automatiquement';
    }
    if (isOwner) {
      return 'Saisissez la plaque du véhicule concerné (pas la vôtre)';
    }
    return 'Saisie manuelle';
  }

  @override
  Widget build(BuildContext context) {
    final recap = context.watch<RecapPendingProvider>();
    final auth = context.watch<AuthProvider>();
    final type =
        context.watch<InciviTypeProvider>().byId(recap.pending?.typeId);
    final report = recap.pending;

    // Si propriétaire et plaque non détectée par IA, le champ reste vide et éditable
    final isOwner = auth.isProprietaire;
    final hasDetectedPlate = recap.detectedPlate?.isNotEmpty ?? false;
    final plateLocked = _analyzing || hasDetectedPlate;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Récapitulatif')),
        body: const Center(child: Text('Aucun signalement en cours.')),
      );
    }

    final plateImagePath = recap.plateImagePath;
    final hasPlateImage =
        plateImagePath != null && File(plateImagePath).existsSync();

    // Si propriétaire, s'assurer que sa propre plaque n'est jamais utilisée
    if (isOwner && _plaqueCtrl.text.trim().isEmpty) {
      // Ne PAS remplir avec la plaque du propriétaire
      // Le champ reste vide pour saisie manuelle d'une autre plaque
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Récapitulatif'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Infraction Type Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.report_problem_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type?.nom ?? 'Infraction',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.videoPath != null
                            ? 'Vidéo jointe (${report.trimStart ?? 0}–${report.trimEnd ?? 0} ms)'
                            : report.photoPath != null
                                ? 'Photo jointe'
                                : 'Aucun média joint',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Analysis Status
          if (_analyzing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'IA en cours : lecture de la vidéo et détection de la plaque…',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Plate Image Detection Result
          if (hasPlateImage && !_analyzing) ...[
            const SizedBox(height: 16),
            Container(
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(plateImagePath),
                      width: 140,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 18, color: AppTheme.success),
                            const SizedBox(width: 8),
                            const Text(
                              'Plaque lue par l\'IA',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recap.detectedPlate ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        if (recap.score != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Confiance : ${(recap.score! * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Analysis Error
          if (_analysisError != null && !_analyzing) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _analysisError!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Plate Input Field
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      plateLocked ? Icons.lock_outline : Icons.confirmation_number_outlined,
                      color: plateLocked ? AppTheme.success : AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Plaque du véhicule',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (plateLocked) ...[
                      const Spacer(),
                      const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _plaqueCtrl,
                  enabled: !plateLocked,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: plateLocked
                        ? null
                        : 'Saisie automatique en cours ou manuelle',
                    filled: true,
                    fillColor: plateLocked
                        ? AppTheme.success.withValues(alpha: 0.05)
                        : AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.success.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getPlateHelperText(plateLocked, isOwner, hasDetectedPlate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Location Field
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _locationLocked ? Icons.lock_outline : Icons.place_outlined,
                      color: _locationLocked ? AppTheme.success : AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lieu de l\'infraction',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (_locating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_locationLocked)
                      const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lieuCtrl,
                  enabled: !_locationLocked,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _locationLocked
                        ? AppTheme.success.withValues(alpha: 0.05)
                        : AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.success.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _locationLocked
                      ? 'Position GPS capturée automatiquement'
                      : _locating
                          ? 'Localisation en cours…'
                          : 'Localisation automatique indisponible',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description Field
          Container(
            padding: const EdgeInsets.all(20),
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
            child: TextField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optionnel)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // AI Analysis Complete Indicator
          if (recap.analyzed && !_analyzing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.success, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Analyse IA terminée.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Submit Button
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(_submitting ? 'Envoi…' : 'Envoyer le signalement'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _submitting
                ? null
                : () {
                    recap.clear();
                    context.pop();
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
