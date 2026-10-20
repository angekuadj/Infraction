import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/infraction_report.dart';
import '../services/auth_service.dart' show ApiException;
import '../services/infraction_upload_service.dart';

class InfractionProvider extends ChangeNotifier {
  InfractionProvider(this._baseUrl);
  String? _baseUrl;

  static const _uuid = Uuid();

  final List<InfractionReport> _localReports = [];
  final List<InfractionReport> _serverReports = [];
  InfractionReport? _pendingRecap;
  bool _loading = false;
  String? _error;

  List<InfractionReport> get localReports => List.unmodifiable(_localReports);
  List<InfractionReport> get serverReports => List.unmodifiable(_serverReports);
  InfractionReport? get pendingRecap => _pendingRecap;
  bool get isLoading => _loading;
  String? get error => _error;

  InfractionUploadService? get _service =>
      _baseUrl == null || _baseUrl!.isEmpty ? null : InfractionUploadService(_baseUrl!);

  void updateBaseUrl(String? baseUrl) {
    if (_baseUrl != baseUrl) {
      _baseUrl = baseUrl;
      notifyListeners();
    }
  }

  void setPendingRecap(InfractionReport? report) {
    _pendingRecap = report;
    notifyListeners();
  }

  InfractionReport createLocalReport({
    required String typeId,
    String? plaque,
    String? description,
    String? lieu,
    double? latitude,
    double? longitude,
    String? videoPath,
    String? photoPath,
    String? plateImagePath,
    String? trimStart,
    String? trimEnd,
    bool enPanne = false,
    String? panneStart,
    String? panneEnd,
  }) {
    final report = InfractionReport(
      id: _uuid.v4(),
      localId: _uuid.v4(),
      typeId: typeId,
      inciviTypeId: typeId,
      plaqueImmatriculation: plaque,
      numeroImmatriculation: plaque,
      description: description,
      lieu: lieu,
      latitude: latitude,
      longitude: longitude,
      videoPath: videoPath,
      photoPath: photoPath,
      plateImagePath: plateImagePath,
      trimStart: trimStart,
      trimEnd: trimEnd,
      status: 'pending',
      statut: 'pending',
      isPending: true,
      isQueued: videoPath != null || photoPath != null,
      createdAt: DateTime.now(),
      reportedAt: DateTime.now(),
      enPanne: enPanne,
      panneStart: panneStart,
      panneEnd: panneEnd,
    );
    _localReports.insert(0, report);
    notifyListeners();
    return report;
  }

  void updateLocalReport(String localId, InfractionReport updated) {
    final index = _localReports.indexWhere((r) => r.localId == localId || r.id == localId);
    if (index >= 0) {
      _localReports[index] = updated;
      notifyListeners();
    }
  }

  Future<void> loadMyReports({String? token}) async {
    final service = _service;
    if (service == null || token == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await service.fetchMyReports(token: token);
      _serverReports
        ..clear()
        ..addAll(raw.map(InfractionReport.fromJson));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadForMyPlate({
    required String token,
    required String plaque,
  }) async {
    final service = _service;
    if (service == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await service.fetchForMyPlate(token: token, plaque: plaque);
      _serverReports
        ..clear()
        ..addAll(raw.map(InfractionReport.fromJson));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<InfractionReport?> fetchById({
    required String token,
    required String id,
  }) async {
    final service = _service;
    if (service == null) return null;
    try {
      final body = await service.fetchById(token: token, id: id);
      final data =
          body['data'] is Map<String, dynamic> ? body['data'] : body;
      return InfractionReport.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Soumet un signalement au serveur. Retourne le rapport mis à jour.
  Future<InfractionReport?> submit({
    required String token,
    required InfractionReport report,
    File? video,
    File? photo,
    File? plateImage,
  }) async {
    final service = _service;
    if (service == null) return null;
    final index =
        _localReports.indexWhere((r) => r.localId == report.localId);
    if (index >= 0) {
      _localReports[index] = report.copyWith(isUploading: true);
      notifyListeners();
    }
    try {
      final body = await service.submitReport(
        token: token,
        fields: {
          'typeId': report.typeId,
          'inciviTypeId': report.inciviTypeId ?? report.typeId,
          'plaqueImmatriculation': report.plaqueImmatriculation,
          'numeroImmatriculation': report.numeroImmatriculation,
          'description': report.description,
          'commentaire': report.commentaire,
          'lieu': report.lieu,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'trimStart': report.trimStart,
          'trimEnd': report.trimEnd,
          'enPanne': report.enPanne,
        },
        video: video,
        photo: photo,
        plateImage: plateImage,
      );
      final data =
          body['data'] is Map<String, dynamic> ? body['data'] : body;
      final submitted =
          InfractionReport.fromJson(data as Map<String, dynamic>).copyWith(
        localId: report.localId,
        isPending: false,
        isUploading: false,
        sentAt: DateTime.now(),
      );
      if (index >= 0) {
        _localReports[index] = submitted;
      }
      _serverReports.insert(0, submitted);
      notifyListeners();
      return submitted;
    } on ApiException catch (e) {
      if (index >= 0) {
        _localReports[index] = report.copyWith(
          isUploading: false,
          retryCount: (report.retryCount ?? 0) + 1,
        );
      }
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      if (index >= 0) {
        _localReports[index] = report.copyWith(
          isUploading: false,
          retryCount: (report.retryCount ?? 0) + 1,
        );
      }
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteLocal(String localId) async {
    _localReports.removeWhere((r) => r.localId == localId || r.id == localId);
    notifyListeners();
    return true;
  }

  Future<bool> deleteServer({
    required String token,
    required String id,
  }) async {
    final service = _service;
    if (service == null) return false;
    try {
      await service.deleteReport(token: token, id: id);
      _serverReports.removeWhere((r) => r.id == id || r.serverId == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
