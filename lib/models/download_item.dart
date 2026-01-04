import 'dart:convert';

import 'media_item.dart';

/// Status of a download
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Represents a downloadable media item with its download state
class DownloadItem {
  final String id;
  final MediaItem mediaItem;
  final String videoUrl;
  final String localPath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final String? error;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? serverId;

  DownloadItem({
    required this.id,
    required this.mediaItem,
    required this.videoUrl,
    required this.localPath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.error,
    required this.createdAt,
    this.completedAt,
    this.serverId,
  });

  double get progress =>
      totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

  bool get isComplete => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isPending => status == DownloadStatus.pending;

  DownloadItem copyWith({
    String? id,
    MediaItem? mediaItem,
    String? videoUrl,
    String? localPath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    String? error,
    DateTime? createdAt,
    DateTime? completedAt,
    String? serverId,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      mediaItem: mediaItem ?? this.mediaItem,
      videoUrl: videoUrl ?? this.videoUrl,
      localPath: localPath ?? this.localPath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaItem': mediaItem.toJson(),
      'videoUrl': videoUrl,
      'localPath': localPath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.name,
      'error': error,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'serverId': serverId,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      mediaItem: MediaItem.fromJson(json['mediaItem'] as Map<String, dynamic>),
      videoUrl: json['videoUrl'] as String,
      localPath: json['localPath'] as String,
      totalBytes: json['totalBytes'] as int? ?? 0,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DownloadStatus.pending,
      ),
      error: json['error'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      serverId: json['serverId'] as String?,
    );
  }

  String toJsonString() => json.encode(toJson());

  static DownloadItem fromJsonString(String jsonString) =>
      DownloadItem.fromJson(json.decode(jsonString) as Map<String, dynamic>);
}
