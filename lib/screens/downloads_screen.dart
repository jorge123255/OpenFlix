import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/download_item.dart';
import '../providers/multi_server_provider.dart';
import '../services/download_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/desktop_app_bar.dart';

/// Screen for managing offline downloads
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  DownloadService? _downloadService;
  bool _isLoading = true;
  int _totalStorageBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadDownloadService();
  }

  Future<void> _loadDownloadService() async {
    final service = await DownloadService.getInstance();
    final storage = await service.getTotalStorageUsed();

    if (mounted) {
      setState(() {
        _downloadService = service;
        _totalStorageBytes = storage;
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _playDownload(DownloadItem download) async {
    if (!download.isComplete) return;

    await navigateToVideoPlayer(
      context,
      metadata: download.mediaItem,
      offlinePath: download.localPath,
    );
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.downloads.deleteAllTitle),
        content: Text(
          t.downloads.deleteAllMessage(
            count: (_downloadService?.downloads.length ?? 0).toString(),
            size: _formatBytes(_totalStorageBytes),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.downloads.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.downloads.deleteAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _downloadService?.deleteAllDownloads();
      setState(() {
        _totalStorageBytes = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: ListenableBuilder(
        listenable: _downloadService!,
        builder: (context, _) {
          final downloads = _downloadService!.downloads;
          final activeDownloads = _downloadService!.activeDownloads;
          final completedDownloads = _downloadService!.completedDownloads;

          return CustomScrollView(
            slivers: [
              DesktopSliverAppBar(
                title: Text(t.downloads.title),
                floating: true,
                actions: [
                  if (downloads.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      tooltip: t.downloads.deleteAll,
                      onPressed: _confirmDeleteAll,
                    ),
                ],
              ),

              // Storage info
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.storage,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        t.downloads.storageUsed(size: _formatBytes(_totalStorageBytes)),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // Active downloads section
              if (activeDownloads.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      t.downloads.downloading(count: activeDownloads.length.toString()),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _DownloadListTile(
                        download: activeDownloads[index],
                        downloadService: _downloadService!,
                        onTap: () {},
                      );
                    },
                    childCount: activeDownloads.length,
                  ),
                ),
              ],

              // Completed downloads section
              if (completedDownloads.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      t.downloads.downloaded(count: completedDownloads.length.toString()),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _DownloadListTile(
                        download: completedDownloads[index],
                        downloadService: _downloadService!,
                        onTap: () => _playDownload(completedDownloads[index]),
                      );
                    },
                    childCount: completedDownloads.length,
                  ),
                ),
              ],

              // Empty state
              if (downloads.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_for_offline_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.downloads.noDownloads,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.downloads.noDownloadsHint,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DownloadListTile extends StatelessWidget {
  final DownloadItem download;
  final DownloadService downloadService;
  final VoidCallback onTap;

  const _DownloadListTile({
    required this.download,
    required this.downloadService,
    required this.onTap,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaItem = download.mediaItem;

    String? thumbUrl;
    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );
      if (multiServerProvider.hasConnectedServers && download.serverId != null) {
        final client = context.getClientForServer(download.serverId!);
        if (mediaItem.thumb != null) {
          thumbUrl = client.getThumbnailUrl(mediaItem.thumb!);
        }
      }
    } catch (_) {}

    return Dismissible(
      key: Key(download.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.downloads.deleteDownloadTitle),
            content: Text(t.downloads.deleteDownloadMessage(title: mediaItem.title)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.downloads.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(t.downloads.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (download.isComplete) {
          downloadService.deleteDownload(download.id);
        } else {
          downloadService.cancelDownload(download.id);
        }
      },
      child: ListTile(
        onTap: download.isComplete ? onTap : null,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 60,
            height: 90,
            child: thumbUrl != null
                ? CachedNetworkImage(
                    imageUrl: thumbUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.movie),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.movie),
                  ),
          ),
        ),
        title: Text(
          mediaItem.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mediaItem.grandparentTitle != null)
              Text(
                mediaItem.grandparentTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            if (download.isDownloading || download.isPending) ...[
              LinearProgressIndicator(
                value: download.progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatBytes(download.downloadedBytes)} / ${_formatBytes(download.totalBytes)}',
                style: theme.textTheme.bodySmall,
              ),
            ] else if (download.isComplete)
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatBytes(download.totalBytes),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (mediaItem.duration != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(mediaItem.duration!),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              )
            else if (download.isFailed)
              Row(
                children: [
                  const Icon(Icons.error, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      download.error ?? t.downloads.downloadFailed,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else if (download.isPaused)
              Row(
                children: [
                  Icon(
                    Icons.pause_circle,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${t.downloads.paused} - ${_formatBytes(download.downloadedBytes)} / ${_formatBytes(download.totalBytes)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
        trailing: _buildTrailingActions(context),
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context) {
    if (download.isComplete) {
      return IconButton(
        icon: const Icon(Icons.play_circle_filled),
        onPressed: onTap,
      );
    }

    if (download.isDownloading) {
      return IconButton(
        icon: const Icon(Icons.pause),
        onPressed: () => downloadService.pauseDownload(download.id),
      );
    }

    if (download.isPaused) {
      return IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () => downloadService.resumeDownload(download.id),
      );
    }

    if (download.isFailed) {
      return IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => downloadService.retryDownload(download.id),
      );
    }

    if (download.isPending) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return const SizedBox.shrink();
  }
}
