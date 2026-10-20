import 'package:flutter/foundation.dart';

import '../models/infraction_report.dart';

/// Données de récapitulatif en attente de finalisation
/// (vidéo analysée -> écran recap avant envoi).
class RecapPendingProvider extends ChangeNotifier {
  InfractionReport? _pending;
  String? _detectedPlate;
  double? _score;
  String? _plateImagePath;
  bool _analyzed = false;
  bool _processing = false;

  InfractionReport? get pending => _pending;
  String? get detectedPlate => _detectedPlate;
  double? get score => _score;
  String? get plateImagePath =>
      _plateImagePath ?? _pending?.plateImagePath;
  bool get hasPending => _pending != null;
  bool get analyzed => _analyzed;
  bool get isProcessing => _processing;

  void setPending(
    InfractionReport report, {
    String? detectedPlate,
    double? score,
    String? plateImagePath,
    bool analyzed = false,
  }) {
    _pending = report;
    _detectedPlate = detectedPlate ?? report.plaqueImmatriculation;
    _score = score;
    _plateImagePath = plateImagePath ?? report.plateImagePath;
    _analyzed = analyzed;
    notifyListeners();
  }

  void setProcessing(bool value) {
    _processing = value;
    notifyListeners();
  }

  /// Résultat de l'analyse IA : plaque, score et photo recadrée.
  void applyAnalysis({
    required String? plate,
    double? score,
    String? plateImagePath,
  }) {
    if (plate != null && plate.isNotEmpty) {
      _detectedPlate = plate;
    }
    if (score != null) _score = score;
    if (plateImagePath != null) _plateImagePath = plateImagePath;
    _analyzed = true;
    _processing = false;
    if (_pending != null) {
      _pending = _pending!.copyWith(
        plaqueImmatriculation: plate ?? _pending!.plaqueImmatriculation,
        numeroImmatriculation: plate ?? _pending!.numeroImmatriculation,
        plateImagePath: plateImagePath ?? _pending!.plateImagePath,
        score: score ?? _pending!.score,
        isAnalyzed: true,
      );
    }
    notifyListeners();
  }

  /// Lieu récupéré automatiquement (GPS + géocodage).
  void applyLocation({
    required String lieu,
    double? latitude,
    double? longitude,
  }) {
    if (_pending == null) return;
    _pending = _pending!.copyWith(
      lieu: lieu,
      latitude: latitude,
      longitude: longitude,
    );
    notifyListeners();
  }

  void updatePlate(String plate) {
    _detectedPlate = plate;
    if (_pending != null) {
      _pending = _pending!.copyWith(
        plaqueImmatriculation: plate,
        numeroImmatriculation: plate,
      );
    }
    notifyListeners();
  }

  void clear() {
    _pending = null;
    _detectedPlate = null;
    _score = null;
    _plateImagePath = null;
    _analyzed = false;
    _processing = false;
    notifyListeners();
  }

  InfractionReport? takePending() {
    final p = _pending;
    clear();
    return p;
  }
}

typedef PendingRecapData = Map<String, dynamic>;

PendingRecapData toPendingRecapData(InfractionReport report) => report.toJson();

InfractionReport fromPendingRecapData(PendingRecapData json) =>
    InfractionReport.fromJson(json);
