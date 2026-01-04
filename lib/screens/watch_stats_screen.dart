import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../services/watch_stats_service.dart';
import '../i18n/strings.g.dart';

/// Screen displaying watch time statistics
class WatchStatsScreen extends StatefulWidget {
  const WatchStatsScreen({super.key});

  @override
  State<WatchStatsScreen> createState() => _WatchStatsScreenState();
}

class _WatchStatsScreenState extends State<WatchStatsScreen> {
  bool _isLoading = true;
  WatchStats? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final multiServer = context.read<MultiServerProvider>();
      final allItems = <MediaItem>[];

      // Gather watched items from all servers
      for (final server in multiServer.servers) {
        final client = multiServer.getClientForServer(server);
        if (client != null) {
          // Get all libraries
          final libraries = await client.getLibraries();
          for (final library in libraries) {
            // Get all items from library
            final items = await client.getAllLibraryItems(library.key);
            allItems.addAll(items);
          }
        }
      }

      final stats = WatchStatsService.calculateStats(allItems);

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.stats.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStats,
              child: Text(t.common.retry),
            ),
          ],
        ),
      );
    }

    if (_stats == null || _stats!.totalItems == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              t.stats.noData,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.stats.startWatching,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total watch time hero card
            _buildHeroCard(),
            const SizedBox(height: 24),

            // Stats grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Top genres
            if (_stats!.topGenres.isNotEmpty) ...[
              Text(
                t.stats.topGenres,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildGenresChart(),
              const SizedBox(height: 24),
            ],

            // Monthly activity
            if (_stats!.monthlyWatchTime.isNotEmpty) ...[
              Text(
                t.stats.monthlyActivity,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildMonthlyChart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.timer, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            _stats!.formattedWatchTime,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.stats.totalWatchTime,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (_stats!.totalDays >= 1) ...[
            const SizedBox(height: 8),
            Text(
              '${_stats!.totalDays.toStringAsFixed(1)} ${t.stats.days}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.movie,
            value: _stats!.moviesWatched.toString(),
            label: t.stats.moviesWatched,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.tv,
            value: _stats!.episodesWatched.toString(),
            label: t.stats.episodesWatched,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            value: _stats!.averagePerDay,
            label: t.stats.avgPerDay,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildGenresChart() {
    final maxMinutes = _stats!.topGenres.first.value.toDouble();

    return Column(
      children: _stats!.topGenres.map((entry) {
        final percentage = entry.value / maxMinutes;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    '${(entry.value / 60).toStringAsFixed(1)} h',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyChart() {
    final maxMinutes = _stats!.monthlyWatchTime
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _stats!.monthlyWatchTime.length,
        itemBuilder: (context, index) {
          final entry = _stats!.monthlyWatchTime[index];
          final percentage = entry.value / maxMinutes;
          final parts = entry.key.split('-');
          final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
          final monthName = DateFormat.MMM().format(date);

          return Container(
            width: 50,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${(entry.value / 60).round()}h',
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 30,
                      height: percentage * 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthName,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
