import 'dart:async';

import '../client/media_client.dart';
import '../models/hub.dart';
import '../models/library.dart';
import '../models/media_item.dart';
import '../utils/app_logger.dart';
import 'multi_server_manager.dart';
import 'plex_auth_service.dart';

/// Service for aggregating data from multiple Plex servers
class DataAggregationService {
  final MultiServerManager _serverManager;

  DataAggregationService(this._serverManager);

  /// Fetch libraries from all online servers
  /// Libraries are automatically tagged with server info by MediaClient
  Future<List<Library>> getLibrariesFromAllServers() async {
    return _perServer<Library>(
      operationName: 'fetching libraries',
      operation: (serverId, client, server) async {
        return await client.getLibraries();
      },
    );
  }

  /// Fetch "On Deck" (Continue Watching) from all servers and merge by recency
  /// Items are automatically tagged with server info by MediaClient
  Future<List<MediaItem>> getOnDeckFromAllServers({int? limit}) async {
    final allOnDeck = await _perServer<MediaItem>(
      operationName: 'fetching on deck',
      operation: (serverId, client, server) async {
        return await client.getOnDeck();
      },
    );

    // Sort by most recently viewed
    // Use lastViewedAt (when item was last viewed), falling back to updatedAt/addedAt if not available
    allOnDeck.sort((a, b) {
      final aTime = a.lastViewedAt ?? a.updatedAt ?? a.addedAt ?? 0;
      final bTime = b.lastViewedAt ?? b.updatedAt ?? b.addedAt ?? 0;
      return bTime.compareTo(aTime); // Descending (most recent first)
    });

    // Apply limit if specified
    final result = limit != null && limit < allOnDeck.length
        ? allOnDeck.sublist(0, limit)
        : allOnDeck;

    appLogger.i('Fetched ${result.length} on deck items from all servers');

    return result;
  }

  /// Fetch recommendation hubs from all servers
  Future<List<Hub>> getHubsFromAllServers({int? limit}) async {
    final clients = _serverManager.onlineClients;

    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching hubs');
      return [];
    }

    appLogger.d('Fetching hubs from ${clients.length} servers');

    final allHubs = <Hub>[];

    // Fetch from all servers in parallel
    final hubFutures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;

      try {
        // Get libraries for this server
        final libraries = await client.getLibraries();

        // Filter to only visible movie/show libraries
        final visibleLibraries = libraries.where((library) {
          if (library.type != 'movie' && library.type != 'show') {
            return false;
          }
          if (library.hidden != null && library.hidden != 0) {
            return false;
          }
          return true;
        }).toList();

        // Fetch hubs from all libraries in parallel
        final libraryHubFutures = visibleLibraries.map((library) async {
          try {
            // Hubs are now tagged with server info at the source
            return await client.getLibraryHubs(library.key);
          } catch (e) {
            appLogger.w(
              'Failed to fetch hubs for library ${library.title}: $e',
            );
            return <Hub>[];
          }
        });

        final libraryHubResults = await Future.wait(libraryHubFutures);

        // Flatten all library hubs
        final serverHubs = <Hub>[];
        for (final hubs in libraryHubResults) {
          serverHubs.addAll(hubs);
        }

        return serverHubs;
      } catch (e, stackTrace) {
        appLogger.e(
          'Failed to fetch hubs from server $serverId',
          error: e,
          stackTrace: stackTrace,
        );
        _serverManager.updateServerStatus(serverId, false);
        return <Hub>[];
      }
    });

    final results = await Future.wait(hubFutures);

    // Flatten results
    for (final hubs in results) {
      allHubs.addAll(hubs);
    }

    // Apply limit if specified
    final result = limit != null && limit < allHubs.length
        ? allHubs.sublist(0, limit)
        : allHubs;

    appLogger.i('Fetched ${result.length} hubs from all servers');

    return result;
  }

  /// Search across all online servers
  /// Results are automatically tagged with server info by MediaClient
  Future<List<MediaItem>> searchAcrossServers(
    String query, {
    int? limit,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final allResults = await _perServer<MediaItem>(
      operationName: 'searching for "$query"',
      operation: (serverId, client, server) async {
        return await client.search(query);
      },
    );

    // Apply limit if specified
    final result = limit != null && limit < allResults.length
        ? allResults.sublist(0, limit)
        : allResults;

    appLogger.i('Found ${result.length} search results across all servers');

    return result;
  }

  /// Get libraries for a specific server
  Future<List<Library>> getLibrariesForServer(String serverId) async {
    final client = _serverManager.getClient(serverId);

    if (client == null) {
      appLogger.w('No client found for server $serverId');
      return [];
    }

    try {
      // Libraries are automatically tagged with server info by MediaClient
      return await client.getLibraries();
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to fetch libraries for server $serverId',
        error: e,
        stackTrace: stackTrace,
      );
      _serverManager.updateServerStatus(serverId, false);
      return [];
    }
  }

  /// Group libraries by server
  Map<String, List<Library>> groupLibrariesByServer(
    List<Library> libraries,
  ) {
    final grouped = <String, List<Library>>{};

    for (final library in libraries) {
      final serverId = library.serverId;
      if (serverId != null) {
        grouped.putIfAbsent(serverId, () => []).add(library);
      }
    }

    return grouped;
  }

  // Private helper methods

  /// Higher-order helper for per-server fan-out operations
  ///
  /// Iterates over all online clients, executes the operation for each server,
  /// handles errors, updates server status, and aggregates results.
  ///
  /// Type parameter `T` is the item type returned by the operation
  /// [operationName] is used for logging (e.g., "fetching libraries")
  /// [operation] is the async function to run per server, returning `List<T>`
  Future<List<T>> _perServer<T>({
    required String operationName,
    required Future<List<T>> Function(
      String serverId,
      MediaClient client,
      PlexServer? server,
    )
    operation,
  }) async {
    final clients = _serverManager.onlineClients;

    if (clients.isEmpty) {
      appLogger.w('No online servers available for $operationName');
      return [];
    }

    appLogger.d('$operationName from ${clients.length} servers');

    final allResults = <T>[];

    // Execute operation on all servers in parallel
    final Iterable<Future<List<T>>> futures = clients.entries.map((
      entry,
    ) async {
      final serverId = entry.key;
      final client = entry.value;
      final server = _serverManager.getServer(serverId);

      try {
        return await operation(serverId, client, server);
      } catch (e, stackTrace) {
        appLogger.e(
          'Failed $operationName from server $serverId',
          error: e,
          stackTrace: stackTrace,
        );
        _serverManager.updateServerStatus(serverId, false);
        return <T>[];
      }
    });

    final List<List<T>> results = await Future.wait<List<T>>(futures);

    // Flatten results
    for (final items in results) {
      allResults.addAll(items);
    }

    return allResults;
  }
}
