import 'package:flutter/material.dart';
import '../services/catchup_service.dart';

/// Bottom sheet showing catch-up programs for a channel
class CatchUpTVSheet extends StatefulWidget {
  final int channelId;
  final String channelName;
  final void Function(CatchUpProgram program) onProgramSelected;

  const CatchUpTVSheet({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.onProgramSelected,
  });

  @override
  State<CatchUpTVSheet> createState() => _CatchUpTVSheetState();
}

class _CatchUpTVSheetState extends State<CatchUpTVSheet> {
  final CatchUpService _service = CatchUpService.instance;
  List<CatchUpProgram> _programs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final programs = await _service.getCatchUpPrograms(widget.channelId);
      if (mounted) {
        setState(() {
          _programs = programs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load programs';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catch Up TV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.channelName,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[600], size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPrograms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off, color: Colors.grey[600], size: 48),
            const SizedBox(height: 16),
            Text(
              'No catch-up programs available',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Programs will appear here as they air',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _programs.length,
      itemBuilder: (context, index) => _buildProgramCard(_programs[index]),
    );
  }

  Widget _buildProgramCard(CatchUpProgram program) {
    final isAvailable = program.available;

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isAvailable ? () => widget.onProgramSelected(program) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  image: program.thumb != null
                      ? DecorationImage(
                          image: NetworkImage(program.thumb!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: program.thumb == null
                    ? const Icon(Icons.movie, color: Colors.grey)
                    : null,
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      style: TextStyle(
                        color: isAvailable ? Colors.white : Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      program.timeRange,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          program.formattedDuration,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Play button or unavailable indicator
              if (isAvailable)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.blue,
                    size: 24,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Unavailable',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for the "Start Over" button in the live TV player
class StartOverButton extends StatefulWidget {
  final int channelId;
  final VoidCallback onStartOver;
  final bool compact;

  const StartOverButton({
    super.key,
    required this.channelId,
    required this.onStartOver,
    this.compact = false,
  });

  @override
  State<StartOverButton> createState() => _StartOverButtonState();
}

class _StartOverButtonState extends State<StartOverButton> {
  final CatchUpService _service = CatchUpService.instance;
  StartOverInfo? _info;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await _service.getStartOverInfo(widget.channelId);
    if (mounted) {
      setState(() {
        _info = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_info == null || !_info!.available) {
      return const SizedBox.shrink();
    }

    if (widget.compact) {
      return IconButton(
        icon: const Icon(Icons.restart_alt, color: Colors.white),
        tooltip: 'Start Over',
        onPressed: widget.onStartOver,
      );
    }

    return GestureDetector(
      onTap: widget.onStartOver,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restart_alt, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Start Over',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_info!.programTitle != null)
                  Text(
                    _info!.programTitle!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating "Start Over" prompt that appears when watching live TV
class StartOverPrompt extends StatelessWidget {
  final String programTitle;
  final VoidCallback onStartOver;
  final VoidCallback onDismiss;

  const StartOverPrompt({
    super.key,
    required this.programTitle,
    required this.onStartOver,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Watch from the beginning?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close, color: Colors.grey, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"$programTitle" has already started. You can start from the beginning.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                child: const Text('Watch Live'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onStartOver,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Start Over'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper to show the catch-up TV sheet
Future<CatchUpProgram?> showCatchUpTVSheet(
  BuildContext context, {
  required int channelId,
  required String channelName,
}) async {
  return showModalBottomSheet<CatchUpProgram>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CatchUpTVSheet(
      channelId: channelId,
      channelName: channelName,
      onProgramSelected: (program) {
        Navigator.of(context).pop(program);
      },
    ),
  );
}
