import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/dvr.dart';
import '../models/livetv_channel.dart';
import '../providers/media_client_provider.dart';
import '../utils/app_logger.dart';
import 'dvr_player_screen.dart';

/// DVR management screen showing recordings and series rules
class DVRScreen extends StatefulWidget {
  const DVRScreen({super.key});

  @override
  State<DVRScreen> createState() => _DVRScreenState();
}

class _DVRScreenState extends State<DVRScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DVRRecording> _recordings = [];
  List<DVRSeriesRule> _rules = [];
  bool _isLoading = true;
  String? _error;
  String _recordingStatusFilter = 'all'; // all, scheduled, recording, completed, failed
  String _sortBy = 'date'; // date, title, size

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = context.read<MediaClientProvider>().client;
      if (client == null) {
        setState(() {
          _error = 'Not connected to server';
          _isLoading = false;
        });
        return;
      }

      final recordings = await client.getDVRRecordings();
      final rules = await client.getSeriesRules();

      setState(() {
        _recordings = recordings;
        _rules = rules;
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('Failed to load DVR data', error: e);
      setState(() {
        _error = 'Failed to load DVR data';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecording(DVRRecording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.dvr.deleteRecording),
        content: Text('${t.common.delete} "${recording.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final client = context.read<MediaClientProvider>().client;
      if (client != null) {
        final success = await client.deleteDVRRecording(recording.id);
        if (success) {
          _loadData();
        }
      }
    }
  }

  Future<void> _deleteRule(DVRSeriesRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.dvr.deleteRule),
        content: Text('${t.common.delete} "${rule.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final client = context.read<MediaClientProvider>().client;
      if (client != null) {
        final success = await client.deleteSeriesRule(rule.id);
        if (success) {
          _loadData();
        }
      }
    }
  }

  Future<void> _toggleRuleEnabled(DVRSeriesRule rule) async {
    final client = context.read<MediaClientProvider>().client;
    if (client != null) {
      await client.updateSeriesRule(rule.id, enabled: !rule.enabled);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.dvr.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t.dvr.recordings, icon: const Icon(Icons.fiber_manual_record)),
            Tab(text: t.dvr.seriesRules, icon: const Icon(Icons.repeat)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.liveTV.refresh,
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: Text(t.common.retry),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecordingsList(),
                    _buildRulesList(),
                  ],
                ),
    );
  }

  Widget _buildRecordingsList() {
    final theme = Theme.of(context);

    if (_recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              t.dvr.noRecordings,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.dvr.scheduleFromGuide,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Filter recordings by status
    var filtered = _recordings;
    if (_recordingStatusFilter != 'all') {
      filtered = _recordings.where((r) => r.status == _recordingStatusFilter).toList();
    }

    // Sort recordings
    filtered = List.from(filtered);
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'size':
        filtered.sort((a, b) => (b.fileSize ?? 0).compareTo(a.fileSize ?? 0));
        break;
      case 'date':
      default:
        filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
    }

    // Calculate storage stats
    final totalSize = _recordings.where((r) => r.fileSize != null).fold<int>(
      0, (sum, r) => sum + (r.fileSize ?? 0));
    final totalSizeMB = totalSize / (1024 * 1024);

    return Column(
      children: [
        // Filter chips and stats
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Storage stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.storage, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${t.dvr.storage}: ${totalSizeMB.toStringAsFixed(1)} MB',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        t.dvr.recordingsCount(count: _recordings.length.toString()),
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Filter and sort options
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(t.dvr.all, 'all'),
                          _buildFilterChip(t.dvr.scheduled, 'scheduled'),
                          _buildFilterChip(t.liveTV.recording, 'recording'),
                          _buildFilterChip(t.dvr.completed, 'completed'),
                          _buildFilterChip(t.dvr.failed, 'failed'),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort),
                    tooltip: t.libraries.sort,
                    onSelected: (value) {
                      setState(() => _sortBy = value);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'date',
                        child: Row(
                          children: [
                            if (_sortBy == 'date') const Icon(Icons.check, size: 18),
                            if (_sortBy != 'date') const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(t.dvr.sortByDate),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'title',
                        child: Row(
                          children: [
                            if (_sortBy == 'title') const Icon(Icons.check, size: 18),
                            if (_sortBy != 'title') const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(t.dvr.sortByTitle),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'size',
                        child: Row(
                          children: [
                            if (_sortBy == 'size') const Icon(Icons.check, size: 18),
                            if (_sortBy != 'size') const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(t.dvr.sortBySize),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // Recordings list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No ${_recordingStatusFilter != 'all' ? _recordingStatusFilter : ''} recordings',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildRecordingTile(filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _recordingStatusFilter == value;
    final count = value == 'all'
        ? _recordings.length
        : _recordings.where((r) => r.status == value).length;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _recordingStatusFilter = value);
        },
      ),
    );
  }

  void _playRecording(DVRRecording recording) {
    if (!recording.isCompleted || recording.filePath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DVRPlayerScreen(recording: recording),
      ),
    );
  }

  Widget _buildRecordingTile(DVRRecording recording) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(recording),
        title: Text(
          recording.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateFormat.format(recording.startTime.toLocal())} ${timeFormat.format(recording.startTime.toLocal())} - ${timeFormat.format(recording.endTime.toLocal())}',
              style: theme.textTheme.bodySmall,
            ),
            if (recording.isCompleted && recording.fileSize != null)
              Text(
                '${recording.fileSizeMB.toStringAsFixed(1)} MB',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        onTap: recording.isCompleted ? () => _playRecording(recording) : null,
        trailing: recording.isRecording
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (recording.isCompleted)
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => _playRecording(recording),
                      tooltip: t.dvr.playRecording,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteRecording(recording),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusIcon(DVRRecording recording) {
    IconData icon;
    Color color;

    switch (recording.status) {
      case 'scheduled':
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case 'recording':
        icon = Icons.fiber_manual_record;
        color = Colors.red;
        break;
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildRulesList() {
    final theme = Theme.of(context);

    if (_rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              t.dvr.noRules,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.dvr.createRulesHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _rules.length,
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return _buildRuleTile(rule);
      },
    );
  }

  Widget _buildRuleTile(DVRSeriesRule rule) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rule.enabled
              ? theme.colorScheme.primaryContainer
              : Colors.grey[300],
          child: Icon(
            Icons.repeat,
            color: rule.enabled
                ? theme.colorScheme.onPrimaryContainer
                : Colors.grey,
          ),
        ),
        title: Text(
          rule.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: rule.enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rule.keywords != null && rule.keywords!.isNotEmpty)
              Text(
                'Keywords: ${rule.keywords}',
                style: theme.textTheme.bodySmall,
              ),
            Text(
              '${rule.keepPolicyText} \u2022 ${rule.paddingText}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: rule.enabled,
              onChanged: (_) => _toggleRuleEnabled(rule),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteRule(rule),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to schedule a recording from Live TV
class ScheduleRecordingDialog extends StatefulWidget {
  final LiveTVChannel channel;
  final LiveTVProgram? program;

  const ScheduleRecordingDialog({
    super.key,
    required this.channel,
    this.program,
  });

  @override
  State<ScheduleRecordingDialog> createState() => _ScheduleRecordingDialogState();
}

class _ScheduleRecordingDialogState extends State<ScheduleRecordingDialog> {
  late TextEditingController _titleController;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final program = widget.program;
    if (program != null) {
      _titleController = TextEditingController(text: program.title);
      _startTime = program.start;
      _endTime = program.end;
    } else {
      _titleController = TextEditingController(text: widget.channel.name);
      _startTime = DateTime.now();
      _endTime = DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final client = context.read<MediaClientProvider>().client;
    if (client != null) {
      final recording = await client.scheduleRecording(
        channelId: widget.channel.id,
        title: _titleController.text,
        startTime: _startTime,
        endTime: _endTime,
        programId: widget.program?.id,
        description: widget.program?.description,
      );

      if (mounted) {
        Navigator.pop(context, recording != null);
      }
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    return AlertDialog(
      title: Text(t.dvr.scheduleRecordingTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Channel: ${widget.channel.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start: ${dateFormat.format(_startTime.toLocal())} ${timeFormat.format(_startTime.toLocal())}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'End: ${dateFormat.format(_endTime.toLocal())} ${timeFormat.format(_endTime.toLocal())}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: Text(t.dvr.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.dvr.schedule),
        ),
      ],
    );
  }
}
