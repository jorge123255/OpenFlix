import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/app_logger.dart';
import 'openflix_auth_service.dart';

/// Represents a discovered server on the local network
class DiscoveredServer {
  final String url;
  final String name;
  final String address;
  final int port;
  final Duration responseTime;

  DiscoveredServer({
    required this.url,
    required this.name,
    required this.address,
    required this.port,
    required this.responseTime,
  });

  @override
  String toString() => 'DiscoveredServer($name at $url)';
}

/// Service for discovering OpenFlix servers on the local network
class ServerDiscoveryService {
  /// Common ports where OpenFlix server might be running
  static const List<int> commonPorts = [32400, 8080, 3000, 8000, 80, 443];

  /// Timeout for individual connection attempts
  static const Duration connectionTimeout = Duration(milliseconds: 1500);

  /// Maximum concurrent connection attempts
  static const int maxConcurrent = 50;

  /// Stream controller for discovery progress
  final _progressController = StreamController<String>.broadcast();

  /// Stream of discovery progress messages
  Stream<String> get progressStream => _progressController.stream;

  /// Stream controller for discovered servers
  final _serversController = StreamController<DiscoveredServer>.broadcast();

  /// Stream of discovered servers
  Stream<DiscoveredServer> get serversStream => _serversController.stream;

  bool _isScanning = false;

  /// Whether discovery is currently in progress
  bool get isScanning => _isScanning;

  /// Check if the device is connected to a local network
  Future<bool> isOnLocalNetwork() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.ethernet);
  }

  /// Get the local IP address
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        // Skip loopback and link-local interfaces
        if (interface.name.contains('lo') ||
            interface.name.contains('docker') ||
            interface.name.contains('veth')) {
          continue;
        }

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      appLogger.e('Failed to get local IP address', error: e);
    }
    return null;
  }

  /// Extract subnet from IP address (e.g., "192.168.1.100" -> "192.168.1")
  String _getSubnet(String ipAddress) {
    final parts = ipAddress.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return ipAddress;
  }

  /// Discover servers on the local network
  /// Returns a list of discovered servers
  Future<List<DiscoveredServer>> discoverServers({
    void Function(String)? onProgress,
    void Function(DiscoveredServer)? onServerFound,
  }) async {
    if (_isScanning) {
      appLogger.w('Discovery already in progress');
      return [];
    }

    _isScanning = true;
    final discoveredServers = <DiscoveredServer>[];

    try {
      // Check network connectivity
      if (!await isOnLocalNetwork()) {
        _reportProgress('Not connected to local network', onProgress);
        return [];
      }

      // Get local IP
      final localIp = await getLocalIpAddress();
      if (localIp == null) {
        _reportProgress('Could not determine local IP address', onProgress);
        return [];
      }

      final subnet = _getSubnet(localIp);
      _reportProgress('Scanning network $subnet.0/24...', onProgress);
      appLogger.i('Starting server discovery on subnet: $subnet');

      // Create a list of all IP:port combinations to try
      final targets = <_ScanTarget>[];

      // For Android emulator, also check 10.0.2.2 which is the host machine
      if (Platform.isAndroid) {
        for (final port in commonPorts) {
          targets.add(_ScanTarget('10.0.2.2', port, priority: -1)); // Highest priority
        }
      }

      // Prioritize common server addresses (gateway, .1, .2, etc.)
      final priorityHosts = [1, 2, 100, 200, 254];
      for (final host in priorityHosts) {
        for (final port in commonPorts) {
          targets.add(_ScanTarget('$subnet.$host', port, priority: 0));
        }
      }

      // Then scan the rest of the subnet
      for (int i = 1; i <= 254; i++) {
        if (!priorityHosts.contains(i)) {
          // Only try the most common ports for non-priority hosts
          for (final port in [32400, 8080]) {
            targets.add(_ScanTarget('$subnet.$i', port, priority: 1));
          }
        }
      }

      // Sort by priority
      targets.sort((a, b) => a.priority.compareTo(b.priority));

      // Scan in batches
      int scanned = 0;
      final total = targets.length;

      for (int i = 0; i < targets.length; i += maxConcurrent) {
        final batch = targets.skip(i).take(maxConcurrent);
        final futures = batch.map((target) => _tryConnect(target));

        final results = await Future.wait(futures);

        for (final server in results) {
          if (server != null) {
            // Avoid duplicates by checking URL
            if (!discoveredServers.any((s) => s.url == server.url)) {
              discoveredServers.add(server);
              _serversController.add(server);
              onServerFound?.call(server);
              _reportProgress('Found server: ${server.name}', onProgress);
              appLogger.i('Discovered server: ${server.name} at ${server.url}');
            }
          }
        }

        scanned += batch.length;
        if (scanned % 100 == 0 || scanned == total) {
          _reportProgress(
            'Scanned $scanned of $total addresses...',
            onProgress,
          );
        }
      }

      _reportProgress(
        'Discovery complete. Found ${discoveredServers.length} server(s).',
        onProgress,
      );

      return discoveredServers;
    } finally {
      _isScanning = false;
    }
  }

  /// Try to connect to a specific IP:port and verify it's an OpenFlix server
  Future<DiscoveredServer?> _tryConnect(_ScanTarget target) async {
    final url = 'http://${target.ip}:${target.port}';
    final stopwatch = Stopwatch()..start();

    try {
      final authService = OpenFlixAuthService.create(url);
      final isValid = await authService
          .testConnection()
          .timeout(connectionTimeout, onTimeout: () => false);

      stopwatch.stop();

      if (isValid) {
        // Try to get server name (could be from the API)
        String serverName = 'OpenFlix Server';
        try {
          // The server name might be returned in the response
          // For now, use the IP address as the name
          serverName = 'OpenFlix @ ${target.ip}';
        } catch (_) {}

        return DiscoveredServer(
          url: url,
          name: serverName,
          address: target.ip,
          port: target.port,
          responseTime: stopwatch.elapsed,
        );
      }
    } catch (e) {
      // Connection failed - this is expected for most addresses
    }

    return null;
  }

  /// Quick check for a specific server URL
  Future<DiscoveredServer?> checkServer(String url) async {
    try {
      final uri = Uri.parse(url);
      final stopwatch = Stopwatch()..start();

      final authService = OpenFlixAuthService.create(url);
      final isValid = await authService
          .testConnection()
          .timeout(connectionTimeout, onTimeout: () => false);

      stopwatch.stop();

      if (isValid) {
        return DiscoveredServer(
          url: url,
          name: 'OpenFlix @ ${uri.host}',
          address: uri.host,
          port: uri.port,
          responseTime: stopwatch.elapsed,
        );
      }
    } catch (e) {
      appLogger.d('Server check failed for $url', error: e);
    }
    return null;
  }

  void _reportProgress(String message, void Function(String)? callback) {
    _progressController.add(message);
    callback?.call(message);
  }

  /// Cancel ongoing discovery
  void cancel() {
    _isScanning = false;
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _serversController.close();
  }
}

/// Internal class for scan targets
class _ScanTarget {
  final String ip;
  final int port;
  final int priority;

  _ScanTarget(this.ip, this.port, {this.priority = 0});
}
