import 'package:flutter/material.dart';

import '../models/download_item.dart';
import '../models/media_item.dart';
import '../services/download_service.dart';

/// A button that shows download status and allows downloading media for offline playback
class DownloadButton extends StatefulWidget {
  final MediaItem item;
  final String? videoUrl;
  final String? serverId;
  final bool showLabel;

  const DownloadButton({
    super.key,
    required this.item,
    this.videoUrl,
    this.serverId,
    this.showLabel = false,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  DownloadService? _downloadService;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final service = await DownloadService.getInstance();
    if (mounted) {
      setState(() {
        _downloadService = service;
        _isInitializing = false;
      });
    }
  }

  Future<void> _handleDownload() async {
    if (_downloadService == null || widget.videoUrl == null) return;

    final download = _downloadService!.getDownload(widget.item.ratingKey);

    if (download != null) {
      // Already has a download - show options
      _showDownloadOptions(download);
    } else {
      // Start new download
      await _downloadService!.startDownload(
        mediaItem: widget.item,
        videoUrl: widget.videoUrl!,
        serverId: widget.serverId,
      );
    }
  }

  void _showDownloadOptions(DownloadItem download) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (download.isComplete) ...[
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadService!.deleteDownload(download.id);
                },
              ),
            ] else if (download.isDownloading) ...[
              ListTile(
                leading: const Icon(Icons.pause),
                title: const Text('Pause Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadService!.pauseDownload(download.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadService!.cancelDownload(download.id);
                },
              ),
            ] else if (download.isPaused) ...[
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Resume Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadService!.resumeDownload(download.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadService!.cancelDownload(download.id);
                },
              ),
            ] else if (download.isFailed) ...[
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadService!.retryDownload(download.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadService!.cancelDownload(download.id);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || widget.videoUrl == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: _downloadService!,
      builder: (context, _) {
        final download = _downloadService!.getDownload(widget.item.ratingKey);

        if (widget.showLabel) {
          return _buildLabeledButton(download);
        }
        return _buildIconButton(download);
      },
    );
  }

  Widget _buildIconButton(DownloadItem? download) {
    final theme = Theme.of(context);

    if (download == null) {
      return IconButton(
        icon: const Icon(Icons.download_for_offline_outlined),
        tooltip: 'Download',
        onPressed: _handleDownload,
      );
    }

    if (download.isComplete) {
      return IconButton(
        icon: Icon(
          Icons.download_done,
          color: theme.colorScheme.primary,
        ),
        tooltip: 'Downloaded',
        onPressed: _handleDownload,
      );
    }

    if (download.isDownloading || download.isPending) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: download.progress > 0 ? download.progress : null,
              strokeWidth: 2,
            ),
            IconButton(
              icon: const Icon(Icons.pause, size: 16),
              onPressed: _handleDownload,
            ),
          ],
        ),
      );
    }

    if (download.isPaused) {
      return IconButton(
        icon: Icon(
          Icons.pause_circle_outline,
          color: theme.colorScheme.secondary,
        ),
        tooltip: 'Download Paused',
        onPressed: _handleDownload,
      );
    }

    if (download.isFailed) {
      return IconButton(
        icon: const Icon(Icons.error_outline, color: Colors.red),
        tooltip: 'Download Failed',
        onPressed: _handleDownload,
      );
    }

    return IconButton(
      icon: const Icon(Icons.download_for_offline_outlined),
      tooltip: 'Download',
      onPressed: _handleDownload,
    );
  }

  Widget _buildLabeledButton(DownloadItem? download) {
    final theme = Theme.of(context);

    if (download == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.download_for_offline_outlined),
        label: const Text('Download'),
        onPressed: _handleDownload,
      );
    }

    if (download.isComplete) {
      return FilledButton.icon(
        icon: const Icon(Icons.download_done),
        label: const Text('Downloaded'),
        onPressed: _handleDownload,
      );
    }

    if (download.isDownloading || download.isPending) {
      final percent = (download.progress * 100).toInt();
      return OutlinedButton.icon(
        icon: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            value: download.progress > 0 ? download.progress : null,
            strokeWidth: 2,
          ),
        ),
        label: Text('$percent%'),
        onPressed: _handleDownload,
      );
    }

    if (download.isPaused) {
      return OutlinedButton.icon(
        icon: Icon(Icons.pause, color: theme.colorScheme.secondary),
        label: const Text('Paused'),
        onPressed: _handleDownload,
      );
    }

    if (download.isFailed) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.error_outline, color: Colors.red),
        label: const Text('Failed'),
        onPressed: _handleDownload,
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(Icons.download_for_offline_outlined),
      label: const Text('Download'),
      onPressed: _handleDownload,
    );
  }
}
