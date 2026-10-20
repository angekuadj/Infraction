import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/submission_queue_item.dart';
import '../models/video_processing_queue_item.dart';

/// File d'attente locale des signalements en attente d'envoi
/// (mode hors ligne / retries).
class SubmissionQueueProvider extends ChangeNotifier {
  static const String prefKeyQueue = 'submission_queue';
  static const int maxRetries = 3;

  static const _uuid = Uuid();

  final List<SubmissionQueueItem> _items = [];
  bool _loading = false;
  bool _processing = false;

  List<SubmissionQueueItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isProcessing => _processing;
  int get pendingCount => _items.where((i) => i.isPending).length;
  bool get hasPending => pendingCount > 0;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefKeyQueue);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(list
              .whereType<Map<String, dynamic>>()
              .map(SubmissionQueueItem.fromJson));
      }
    } catch (_) {
      _items.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefKeyQueue,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<SubmissionQueueItem> enqueue({
    required Map<String, dynamic> reportJson,
    String? videoPath,
    String? photoPath,
  }) async {
    final item = SubmissionQueueItem(
      id: _uuid.v4(),
      localId: _uuid.v4(),
      status: 'pending',
      isPending: true,
      createdAt: DateTime.now(),
      videoPath: videoPath,
      photoPath: photoPath,
      retryCount: 0,
    );
    // Conserve le rapport dans error-free extra via toJson imbriqué.
    _items.insert(0, item.copyWith(
      // stockage du rapport via champ non exposé : on réutilise error pour
      // pas perdre les données, mais mieux : map séparée.
    ));
    await _saveReport(item.localId!, reportJson);
    await _persist();
    notifyListeners();
    return item;
  }

  Future<void> _saveReport(String localId, Map<String, dynamic> report) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/queued_reports/$localId.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(report));
  }

  Future<Map<String, dynamic>?> readReport(String localId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/queued_reports/$localId.json');
    if (!await file.exists()) return null;
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> markUploading(String localId) async {
    final index = _items.indexWhere((i) => i.localId == localId);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      status: 'uploading',
      isUploading: true,
      isPending: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> markProcessed(String localId) async {
    final index = _items.indexWhere((i) => i.localId == localId);
    if (index < 0) return;
    final item = _items[index];
    _items[index] = item.copyWith(
      status: 'processed',
      isUploading: false,
      isPending: false,
      sentAt: DateTime.now(),
    );
    await _deleteReportFile(localId);
    await _persist();
    notifyListeners();
  }

  Future<void> markFailed(String localId, {String? error}) async {
    final index = _items.indexWhere((i) => i.localId == localId);
    if (index < 0) return;
    final item = _items[index];
    final retries = (item.retryCount ?? 0) + 1;
    _items[index] = item.copyWith(
      status: retries >= maxRetries ? 'failed' : 'pending',
      isUploading: false,
      isPending: retries < maxRetries,
      retryCount: retries,
      error: error,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String localId) async {
    _items.removeWhere((i) => i.localId == localId);
    await _deleteReportFile(localId);
    await _persist();
    notifyListeners();
  }

  Future<void> clearProcessed() async {
    _items.removeWhere((i) => !i.isPending && i.status == 'processed');
    await _persist();
    notifyListeners();
  }

  Future<void> _deleteReportFile(String localId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/queued_reports/$localId.json');
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  void setProcessing(bool value) {
    _processing = value;
    notifyListeners();
  }
}

/// File d'attente de traitement des vidéos (lecture/détection plaques).
class VideoProcessingQueueProvider extends ChangeNotifier {
  static const String prefKeyQueue = 'video_processing_queue';
  static const _uuid = Uuid();

  final List<VideoProcessingQueueItem> _items = [];
  bool _loading = false;

  List<VideoProcessingQueueItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  int get activeCount =>
      _items.where((i) => i.status == 'pending' || i.status == 'processing').length;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefKeyQueue);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(list
              .whereType<Map<String, dynamic>>()
              .map(VideoProcessingQueueItem.fromJson));
      }
    } catch (_) {
      _items.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefKeyQueue,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<VideoProcessingQueueItem> enqueue(String videoPath) async {
    final item = VideoProcessingQueueItem(
      id: _uuid.v4(),
      localId: _uuid.v4(),
      videoPath: videoPath,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _items.insert(0, item);
    await _persist();
    notifyListeners();
    return item;
  }

  Future<void> markProcessing(String localId) async {
    final index = _items.indexWhere((i) => i.localId == localId);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      status: 'processing',
      isProcessing: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> markAnalyzed(
    String localId, {
    String? plate,
    double? score,
  }) async {
    final index = _items.indexWhere((i) => i.localId == localId);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      status: 'analyzed',
      isProcessing: false,
      plate: plate,
      score: score,
      processedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> markFailed(String localId, {String? error}) async {
    final index = _items.indexWhere((i) => i.localId == localId);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      status: 'failed',
      isProcessing: false,
      error: error,
      processedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String localId) async {
    _items.removeWhere((i) => i.localId == localId);
    await _persist();
    notifyListeners();
  }
}
