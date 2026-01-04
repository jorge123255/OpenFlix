import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_item.dart';
import '../models/media_item.dart';
import '../utils/app_logger.dart';

/// Service for managing offline downloads
class DownloadService extends ChangeNotifier {
  static const String _downloadsKey = 'offline_downloads';
  static const int _maxConcurrentDownloads = 2;

  static DownloadService? _instance;
  late SharedPreferences _prefs;
  late Directory _downloadDir;
  final Dio _dio = Dio();

  final Map<String, DownloadItem> _downloads = {};
  final Map<String, CancelToken> _cancelTokens = {};
  int _activeDownloads = 0;

  DownloadService._();

  static Future<DownloadService> getInstance() async {
    if (_instance == null) {
      _instance = DownloadService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _downloadDir = await _getDownloadDirectory();
    await _loadDownloads();
    _resumePendingDownloads();
  }

  Future<Directory> _getDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// Get all downloads
  List<DownloadItem> get downloads => _downloads.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Get completed downloads
  List<DownloadItem> get completedDownloads =>
      downloads.where((d) => d.isComplete).toList();

  /// Get active downloads (pending, downloading, paused)
  List<DownloadItem> get activeDownloads =>
      downloads.where((d) => !d.isComplete && !d.isFailed).toList();

  /// Check if a media item is downloaded
  bool isDownloaded(String ratingKey) {
    return _downloads.values.any(
      (d) => d.mediaItem.ratingKey == ratingKey && d.isComplete,
    );
  }

  /// Check if a media item is being downloaded
  bool isDownloading(String ratingKey) {
    return _downloads.values.any(
      (d) =>
          d.mediaItem.ratingKey == ratingKey &&
          (d.isDownloading || d.isPending),
    );
  }

  /// Get download for a media item
  DownloadItem? getDownload(String ratingKey) {
    try {
      return _downloads.values.firstWhere(
        (d) => d.mediaItem.ratingKey == ratingKey,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get the local file path for a downloaded item
  String? getLocalPath(String ratingKey) {
    final download = getDownload(ratingKey);
    if (download != null && download.isComplete) {
      return download.localPath;
    }
    return null;
  }

  /// Start downloading a media item
  Future<DownloadItem?> startDownload({
    required MediaItem mediaItem,
    required String videoUrl,
    String? serverId,
  }) async {
    // Check if already downloading or downloaded
    if (isDownloaded(mediaItem.ratingKey) ||
        isDownloading(mediaItem.ratingKey)) {
      appLogger.w('Item already downloaded or downloading');
      return getDownload(mediaItem.ratingKey);
    }

    // Generate unique ID and file path
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final extension = _getFileExtension(videoUrl);
    final fileName = '${mediaItem.ratingKey}_$id$extension';
    final localPath = '${_downloadDir.path}/$fileName';

    final download = DownloadItem(
      id: id,
      mediaItem: mediaItem,
      videoUrl: videoUrl,
      localPath: localPath,
      createdAt: DateTime.now(),
      serverId: serverId,
    );

    _downloads[id] = download;
    await _saveDownloads();
    notifyListeners();

    // Start the download
    _queueDownload(download);

    return download;
  }

  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.mkv')) return '.mkv';
    if (path.endsWith('.avi')) return '.avi';
    if (path.endsWith('.mov')) return '.mov';
    if (path.endsWith('.wmv')) return '.wmv';
    return '.mp4'; // Default to mp4
  }

  void _queueDownload(DownloadItem download) {
    if (_activeDownloads >= _maxConcurrentDownloads) {
      // Already at max, it will be picked up when a slot opens
      return;
    }
    _startDownload(download);
  }

  Future<void> _startDownload(DownloadItem download) async {
    if (download.isComplete || download.isFailed) return;

    _activeDownloads++;
    final cancelToken = CancelToken();
    _cancelTokens[download.id] = cancelToken;

    // Update status to downloading
    _downloads[download.id] = download.copyWith(
      status: DownloadStatus.downloading,
    );
    await _saveDownloads();
    notifyListeners();

    try {
      final response = await _dio.head(download.videoUrl);
      final contentLength =
          int.tryParse(response.headers.value('content-length') ?? '0') ?? 0;

      _downloads[download.id] = _downloads[download.id]!.copyWith(
        totalBytes: contentLength,
      );
      notifyListeners();

      // Download the file
      await _dio.download(
        download.videoUrl,
        download.localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final current = _downloads[download.id];
          if (current != null && current.isDownloading) {
            _downloads[download.id] = current.copyWith(
              downloadedBytes: received,
              totalBytes: total > 0 ? total : current.totalBytes,
            );
            notifyListeners();
          }
        },
      );

      // Download completed successfully
      _downloads[download.id] = _downloads[download.id]!.copyWith(
        status: DownloadStatus.completed,
        downloadedBytes: _downloads[download.id]!.totalBytes,
        completedAt: DateTime.now(),
      );
      await _saveDownloads();
      notifyListeners();

      appLogger.i('Download completed: ${download.mediaItem.title}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        appLogger.i('Download cancelled: ${download.mediaItem.title}');
      } else {
        _downloads[download.id] = _downloads[download.id]!.copyWith(
          status: DownloadStatus.failed,
          error: e.message ?? 'Download failed',
        );
        await _saveDownloads();
        notifyListeners();
        appLogger.e('Download failed: ${download.mediaItem.title}', error: e);
      }
    } catch (e) {
      _downloads[download.id] = _downloads[download.id]!.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
      );
      await _saveDownloads();
      notifyListeners();
      appLogger.e('Download failed: ${download.mediaItem.title}', error: e);
    } finally {
      _activeDownloads--;
      _cancelTokens.remove(download.id);
      _processNextInQueue();
    }
  }

  void _processNextInQueue() {
    final pending = _downloads.values
        .where((d) => d.isPending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final download in pending) {
      if (_activeDownloads >= _maxConcurrentDownloads) break;
      _startDownload(download);
    }
  }

  void _resumePendingDownloads() {
    // Resume any downloads that were interrupted
    for (final download in _downloads.values) {
      if (download.isDownloading || download.isPending) {
        // Reset to pending and requeue
        _downloads[download.id] = download.copyWith(
          status: DownloadStatus.pending,
        );
      }
    }
    _processNextInQueue();
  }

  /// Pause a download
  Future<void> pauseDownload(String id) async {
    final cancelToken = _cancelTokens[id];
    if (cancelToken != null) {
      cancelToken.cancel('Paused by user');
    }

    final download = _downloads[id];
    if (download != null) {
      _downloads[id] = download.copyWith(status: DownloadStatus.paused);
      await _saveDownloads();
      notifyListeners();
    }
  }

  /// Resume a paused download
  Future<void> resumeDownload(String id) async {
    final download = _downloads[id];
    if (download != null && download.isPaused) {
      _downloads[id] = download.copyWith(status: DownloadStatus.pending);
      await _saveDownloads();
      notifyListeners();
      _queueDownload(_downloads[id]!);
    }
  }

  /// Cancel and remove a download
  Future<void> cancelDownload(String id) async {
    final cancelToken = _cancelTokens[id];
    if (cancelToken != null) {
      cancelToken.cancel('Cancelled by user');
    }

    final download = _downloads[id];
    if (download != null) {
      // Delete the partial file
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }

      _downloads.remove(id);
      await _saveDownloads();
      notifyListeners();
    }
  }

  /// Delete a completed download
  Future<void> deleteDownload(String id) async {
    final download = _downloads[id];
    if (download != null) {
      // Delete the file
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }

      _downloads.remove(id);
      await _saveDownloads();
      notifyListeners();
    }
  }

  /// Retry a failed download
  Future<void> retryDownload(String id) async {
    final download = _downloads[id];
    if (download != null && download.isFailed) {
      _downloads[id] = download.copyWith(
        status: DownloadStatus.pending,
        downloadedBytes: 0,
        error: null,
      );
      await _saveDownloads();
      notifyListeners();
      _queueDownload(_downloads[id]!);
    }
  }

  /// Get total storage used by downloads
  Future<int> getTotalStorageUsed() async {
    int total = 0;
    for (final download in _downloads.values) {
      if (download.isComplete) {
        final file = File(download.localPath);
        if (await file.exists()) {
          total += await file.length();
        }
      }
    }
    return total;
  }

  /// Delete all downloads
  Future<void> deleteAllDownloads() async {
    // Cancel active downloads
    for (final token in _cancelTokens.values) {
      token.cancel('Deleting all downloads');
    }
    _cancelTokens.clear();

    // Delete all files
    for (final download in _downloads.values) {
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _downloads.clear();
    await _saveDownloads();
    notifyListeners();
  }

  Future<void> _loadDownloads() async {
    final jsonString = _prefs.getString(_downloadsKey);
    if (jsonString != null) {
      try {
        final jsonList = json.decode(jsonString) as List<dynamic>;
        for (final item in jsonList) {
          final download =
              DownloadItem.fromJson(item as Map<String, dynamic>);
          _downloads[download.id] = download;
        }
      } catch (e) {
        appLogger.e('Failed to load downloads', error: e);
      }
    }
  }

  Future<void> _saveDownloads() async {
    final jsonList = _downloads.values.map((d) => d.toJson()).toList();
    await _prefs.setString(_downloadsKey, json.encode(jsonList));
  }
}
