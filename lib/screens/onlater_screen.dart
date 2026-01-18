import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/onlater.dart';
import '../providers/media_client_provider.dart';
import '../utils/app_logger.dart';

// Simple color constants for On Later screen
class _OnLaterColors {
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFF6366F1);
}

/// On Later screen - browse upcoming content from EPG
class OnLaterScreen extends StatefulWidget {
  const OnLaterScreen({super.key});

  @override
  State<OnLaterScreen> createState() => _OnLaterScreenState();
}

class _OnLaterScreenState extends State<OnLaterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OnLaterStats? _stats;
  bool _isLoading = true;

  // Content by category
  List<OnLaterItem> _tonightItems = [];
  List<OnLaterItem> _moviesItems = [];
  List<OnLaterItem> _sportsItems = [];
  List<OnLaterItem> _kidsItems = [];
  List<OnLaterItem> _premieresItems = [];

  // Search
  final _searchController = TextEditingController();
  List<OnLaterItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadStats();
    _loadTonight();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTabContent(_tabController.index);
    }
  }

  Future<void> _loadStats() async {
    final client = context.read<MediaClientProvider>().client;
    if (client == null) return;

    final stats = await client.getOnLaterStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  Future<void> _loadTabContent(int index) async {
    final client = context.read<MediaClientProvider>().client;
    if (client == null) return;

    setState(() => _isLoading = true);

    try {
      OnLaterResponse? response;
      switch (index) {
        case 0:
          response = await client.getOnLaterTonight();
          if (mounted && response != null) {
            setState(() => _tonightItems = response!.items);
          }
          break;
        case 1:
          response = await client.getOnLaterMovies(hours: 168); // 7 days
          if (mounted && response != null) {
            setState(() => _moviesItems = response!.items);
          }
          break;
        case 2:
          response = await client.getOnLaterSports(hours: 168);
          if (mounted && response != null) {
            setState(() => _sportsItems = response!.items);
          }
          break;
        case 3:
          response = await client.getOnLaterKids(hours: 48);
          if (mounted && response != null) {
            setState(() => _kidsItems = response!.items);
          }
          break;
        case 4:
          response = await client.getOnLaterPremieres(hours: 168);
          if (mounted && response != null) {
            setState(() => _premieresItems = response!.items);
          }
          break;
      }
    } catch (e) {
      appLogger.e('Failed to load On Later content', error: e);
      if (mounted) {
        appLogger.e('Failed to load content');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTonight() async {
    await _loadTabContent(0);
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final client = context.read<MediaClientProvider>().client;
    if (client == null) return;

    final response = await client.searchOnLater(query, hours: 168);
    if (mounted && response != null) {
      setState(() {
        _searchResults = response.items;
        _isSearching = false;
      });
    }
  }

  Future<void> _scheduleRecording(OnLaterItem item) async {
    final client = context.read<MediaClientProvider>().client;
    if (client == null) return;

    // Schedule recording from program
    try {
      final result = await client.scheduleRecording(
        channelId: int.tryParse(item.program.channelId) ?? 0,
        programId: item.program.id,
        title: item.program.title,
        startTime: item.program.start,
        endTime: item.program.end,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result != null ? 'Recording scheduled' : 'Failed to schedule recording'),
            backgroundColor: result != null ? Colors.green : Colors.red,
          ),
        );
        // Refresh current tab
        _loadTabContent(_tabController.index);
      }
    } catch (e) {
      appLogger.e('Failed to schedule recording', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OnLaterColors.background,
      appBar: AppBar(
        backgroundColor: _OnLaterColors.surface,
        title: const Text('On Later'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            _buildTab('Tonight', _stats?.movies),
            _buildTab('Movies', _stats?.movies),
            _buildTab('Sports', _stats?.sports),
            _buildTab('Kids', _stats?.kids),
            _buildTab('Premieres', _stats?.premieres),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: _searchController.text.isNotEmpty
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContentList(_tonightItems, 'Nothing on tonight'),
                _buildContentList(_moviesItems, 'No upcoming movies'),
                _buildContentList(_sportsItems, 'No upcoming sports'),
                _buildContentList(_kidsItems, 'No kids content'),
                _buildContentList(_premieresItems, 'No upcoming premieres'),
              ],
            ),
    );
  }

  Widget _buildTab(String title, int? count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (count != null && count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _OnLaterColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: _OnLaterColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentList(List<OnLaterItem> items, String emptyMessage) {
    if (_isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTabContent(_tabController.index),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildProgramCard(items[index]),
      ),
    );
  }

  Widget _buildProgramCard(OnLaterItem item) {
    final program = item.program;
    final channel = item.channel;
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');

    return Card(
      color: _OnLaterColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProgramDetails(item),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program image
            SizedBox(
              width: program.isMovie ? 100 : 160,
              height: program.isMovie ? 150 : 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (program.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: program.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: Icon(
                          program.isMovie ? Icons.movie : Icons.tv,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey[800],
                      child: Icon(
                        program.isMovie ? Icons.movie : Icons.tv,
                        color: Colors.grey[600],
                        size: 40,
                      ),
                    ),
                  // Channel logo overlay
                  if (channel?.logo != null)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: CachedNetworkImage(
                          imageUrl: channel!.logo!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Program info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    if (program.badges.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Wrap(
                          spacing: 4,
                          children: program.badges.map((badge) => _buildBadge(badge)).toList(),
                        ),
                      ),
                    // Title
                    Text(
                      program.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Episode info
                    if (program.episodeInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          program.episodeInfo!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    // Time and channel
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(program.start)} ${timeFormat.format(program.start)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${program.durationMinutes}m',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    // Channel name
                    if (channel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          channel.name,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ),
                    // Sports teams
                    if (program.isSports && program.teams != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.sports, size: 14, color: _OnLaterColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                program.teams!,
                                style: TextStyle(fontSize: 12, color: _OnLaterColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Record button
            Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: Icon(
                  item.hasRecording ? Icons.fiber_manual_record : Icons.add_circle_outline,
                  color: item.hasRecording ? Colors.red : Colors.white,
                ),
                onPressed: item.hasRecording ? null : () => _scheduleRecording(item),
                tooltip: item.hasRecording ? 'Already scheduled' : 'Schedule recording',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String badge) {
    Color color;
    switch (badge) {
      case 'NEW':
        color = Colors.green;
        break;
      case 'PREMIERE':
        color = Colors.orange;
        break;
      case 'FINALE':
        color = Colors.purple;
        break;
      case 'LIVE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        badge,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildProgramCard(_searchResults[index]),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _OnLaterColors.surface,
        title: const Text('Search'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search programs...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _search(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
              setState(() {
                _searchResults = [];
              });
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _search(_searchController.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showProgramDetails(OnLaterItem item) {
    final program = item.program;
    final channel = item.channel;
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    showModalBottomSheet(
      context: context,
      backgroundColor: _OnLaterColors.surface,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with image
                if (program.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: program.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                // Badges
                if (program.badges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      children: program.badges.map((b) => _buildBadge(b)).toList(),
                    ),
                  ),
                // Title
                Text(
                  program.displayTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Episode info
                if (program.episodeInfo != null)
                  Text(
                    program.episodeInfo!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                const SizedBox(height: 16),
                // Time info
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: _OnLaterColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(program.start),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: _OnLaterColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${timeFormat.format(program.start)} - ${timeFormat.format(program.end)} (${program.durationMinutes} min)',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Channel
                if (channel != null)
                  Row(
                    children: [
                      Icon(Icons.tv, size: 18, color: _OnLaterColors.primary),
                      const SizedBox(width: 8),
                      if (channel.logo != null)
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 8),
                          child: CachedNetworkImage(
                            imageUrl: channel.logo!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      Text(
                        channel.name,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                // Sports info
                if (program.isSports && program.teams != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.sports, size: 18, color: _OnLaterColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          program.teams!,
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (program.league != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        program.league!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ),
                ],
                // Rating
                if (program.rating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        program.rating!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
                // Description
                if (program.description != null && program.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    program.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                  ),
                ],
                const SizedBox(height: 24),
                // Record button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: item.hasRecording ? null : () {
                      Navigator.pop(context);
                      _scheduleRecording(item);
                    },
                    icon: Icon(item.hasRecording ? Icons.check : Icons.fiber_manual_record),
                    label: Text(item.hasRecording ? 'Recording Scheduled' : 'Schedule Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.hasRecording ? Colors.grey : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
