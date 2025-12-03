import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/dvr.dart';
import '../models/livetv_channel.dart';
import '../providers/plex_client_provider.dart';
import '../utils/app_logger.dart';

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
      final client = context.read<PlexClientProvider>().client;
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
        title: const Text('Delete Recording?'),
        content: Text('Delete "${recording.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final client = context.read<PlexClientProvider>().client;
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
        title: const Text('Delete Series Rule?'),
        content: Text('Delete rule for "${rule.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final client = context.read<PlexClientProvider>().client;
      if (client != null) {
        final success = await client.deleteSeriesRule(rule.id);
        if (success) {
          _loadData();
        }
      }
    }
  }

  Future<void> _toggleRuleEnabled(DVRSeriesRule rule) async {
    final client = context.read<PlexClientProvider>().client;
    if (client != null) {
      await client.updateSeriesRule(rule.id, enabled: !rule.enabled);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DVR'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recordings', icon: Icon(Icons.fiber_manual_record)),
            Tab(text: 'Series Rules', icon: Icon(Icons.repeat)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                        label: const Text('Retry'),
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
    if (_recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No recordings',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule recordings from the Live TV guide',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Group recordings by status
    final scheduled = _recordings.where((r) => r.isScheduled).toList();
    final recording = _recordings.where((r) => r.isRecording).toList();
    final completed = _recordings.where((r) => r.isCompleted).toList();
    final failed = _recordings.where((r) => r.isFailed).toList();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (recording.isNotEmpty) ...[
          _buildSectionHeader('Recording Now', Icons.fiber_manual_record, Colors.red),
          ...recording.map((r) => _buildRecordingTile(r)),
        ],
        if (scheduled.isNotEmpty) ...[
          _buildSectionHeader('Scheduled', Icons.schedule, Colors.orange),
          ...scheduled.map((r) => _buildRecordingTile(r)),
        ],
        if (completed.isNotEmpty) ...[
          _buildSectionHeader('Completed', Icons.check_circle, Colors.green),
          ...completed.map((r) => _buildRecordingTile(r)),
        ],
        if (failed.isNotEmpty) ...[
          _buildSectionHeader('Failed', Icons.error, Colors.grey),
          ...failed.map((r) => _buildRecordingTile(r)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
        trailing: recording.isRecording
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteRecording(recording),
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
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildRulesList() {
    if (_rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No series rules',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Create rules to auto-record series',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
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

    final client = context.read<PlexClientProvider>().client;
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
      title: const Text('Schedule Recording'),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Schedule'),
        ),
      ],
    );
  }
}
