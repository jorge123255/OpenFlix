import '../models/media_item.dart';

/// Service for calculating watch time statistics
class WatchStatsService {
  /// Calculate total watch time from viewed items
  static WatchStats calculateStats(List<MediaItem> items) {
    int totalWatchTimeMs = 0;
    int moviesWatched = 0;
    int episodesWatched = 0;
    final Map<String, int> genreMinutes = {};
    final Map<String, int> monthlyMinutes = {};
    DateTime? earliestWatch;
    DateTime? latestWatch;

    for (final item in items) {
      final viewCount = item.viewCount ?? 0;
      if (viewCount == 0) continue;

      final duration = item.duration ?? 0;
      final watchTimeMs = duration * viewCount;
      totalWatchTimeMs += watchTimeMs;

      // Count by type
      final type = item.type.toLowerCase();
      if (type == 'movie') {
        moviesWatched += viewCount;
      } else if (type == 'episode') {
        episodesWatched += viewCount;
      }

      // Track genres
      if (item.genres != null) {
        for (final genre in item.genres!) {
          final genreName = genre.tag ?? '';
          if (genreName.isNotEmpty) {
            genreMinutes[genreName] =
                (genreMinutes[genreName] ?? 0) + (duration ~/ 60000);
          }
        }
      }

      // Track watch dates
      if (item.lastViewedAt != null) {
        final watchDate =
            DateTime.fromMillisecondsSinceEpoch(item.lastViewedAt! * 1000);
        final monthKey =
            '${watchDate.year}-${watchDate.month.toString().padLeft(2, '0')}';
        monthlyMinutes[monthKey] =
            (monthlyMinutes[monthKey] ?? 0) + (duration ~/ 60000);

        if (earliestWatch == null || watchDate.isBefore(earliestWatch)) {
          earliestWatch = watchDate;
        }
        if (latestWatch == null || watchDate.isAfter(latestWatch)) {
          latestWatch = watchDate;
        }
      }
    }

    // Sort genres by watch time
    final sortedGenres = genreMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sort monthly data
    final sortedMonths = monthlyMinutes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return WatchStats(
      totalWatchTimeMinutes: totalWatchTimeMs ~/ 60000,
      moviesWatched: moviesWatched,
      episodesWatched: episodesWatched,
      topGenres: sortedGenres.take(5).toList(),
      monthlyWatchTime: sortedMonths,
      earliestWatch: earliestWatch,
      latestWatch: latestWatch,
      totalItems: items.where((i) => (i.viewCount ?? 0) > 0).length,
    );
  }
}

/// Watch statistics data
class WatchStats {
  final int totalWatchTimeMinutes;
  final int moviesWatched;
  final int episodesWatched;
  final List<MapEntry<String, int>> topGenres;
  final List<MapEntry<String, int>> monthlyWatchTime;
  final DateTime? earliestWatch;
  final DateTime? latestWatch;
  final int totalItems;

  WatchStats({
    required this.totalWatchTimeMinutes,
    required this.moviesWatched,
    required this.episodesWatched,
    required this.topGenres,
    required this.monthlyWatchTime,
    this.earliestWatch,
    this.latestWatch,
    required this.totalItems,
  });

  /// Format total watch time as human-readable string
  String get formattedWatchTime {
    final hours = totalWatchTimeMinutes ~/ 60;
    final minutes = totalWatchTimeMinutes % 60;
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  /// Get total watch time in hours (for display)
  double get totalHours => totalWatchTimeMinutes / 60;

  /// Get total watch time in days
  double get totalDays => totalWatchTimeMinutes / (60 * 24);

  /// Average watch time per day (if we have date range)
  String get averagePerDay {
    if (earliestWatch == null || latestWatch == null) return '0 min';
    final days = latestWatch!.difference(earliestWatch!).inDays;
    if (days <= 0) return formattedWatchTime;
    final avgMinutes = totalWatchTimeMinutes ~/ days;
    if (avgMinutes >= 60) {
      return '${avgMinutes ~/ 60}h ${avgMinutes % 60}m';
    }
    return '$avgMinutes min';
  }
}
