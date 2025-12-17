import 'package:package_info_plus/package_info_plus.dart';

class ClientConfig {
  final String baseUrl;
  final String? token;
  final String clientIdentifier;
  final String product;
  final String version;
  final String platform;
  final String? device;
  final bool acceptJson;
  final String? machineIdentifier;

  ClientConfig({
    required this.baseUrl,
    this.token,
    required this.clientIdentifier,
    required this.product,
    required this.version,
    this.platform = 'Flutter',
    this.device,
    this.acceptJson = true,
    this.machineIdentifier,
  });

  static Future<ClientConfig> create({
    required String baseUrl,
    String? token,
    required String clientIdentifier,
    String? product,
    String? platform,
    String? device,
    bool acceptJson = true,
    String? machineIdentifier,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    return ClientConfig(
      baseUrl: baseUrl,
      token: token,
      clientIdentifier: clientIdentifier,
      product: product ?? 'OpenFlix',
      version: packageInfo.version,
      platform: platform ?? 'Flutter',
      device: device,
      acceptJson: acceptJson,
      machineIdentifier: machineIdentifier,
    );
  }

  Map<String, String> get headers {
    final headers = {
      'X-Plex-Client-Identifier': clientIdentifier,
      'X-Plex-Product': product,
      'X-Plex-Version': version,
      'X-Plex-Platform': platform,
      if (device != null) 'X-Plex-Device': device!,
      if (acceptJson) 'Accept': 'application/json',
      'Accept-Charset': 'utf-8',
    };

    if (token != null) {
      headers['X-Plex-Token'] = token!;
    }

    return headers;
  }

  ClientConfig copyWith({
    String? baseUrl,
    String? token,
    String? clientIdentifier,
    String? product,
    String? version,
    String? platform,
    String? device,
    bool? acceptJson,
    String? machineIdentifier,
  }) {
    return ClientConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
      clientIdentifier: clientIdentifier ?? this.clientIdentifier,
      product: product ?? this.product,
      version: version ?? this.version,
      platform: platform ?? this.platform,
      device: device ?? this.device,
      acceptJson: acceptJson ?? this.acceptJson,
      machineIdentifier: machineIdentifier ?? this.machineIdentifier,
    );
  }
}
