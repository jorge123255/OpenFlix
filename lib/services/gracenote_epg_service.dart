import 'dart:convert';
import 'package:http/http.dart' as http;

/// Gracenote EPG data models
class GracenoteChannel {
  final String callSign;
  final String affiliateName;
  final String channelId;
  final String channelNo;
  final String? thumbnail;
  final List<GracenoteEvent> events;

  GracenoteChannel({
    required this.callSign,
    required this.affiliateName,
    required this.channelId,
    required this.channelNo,
    this.thumbnail,
    required this.events,
  });

  factory GracenoteChannel.fromJson(Map<String, dynamic> json) {
    return GracenoteChannel(
      callSign: json['callSign'] ?? '',
      affiliateName: json['affiliateName'] ?? '',
      channelId: json['channelId'] ?? '',
      channelNo: json['channelNo'] ?? '',
      thumbnail: json['thumbnail'],
      events: (json['events'] as List?)
              ?.map((e) => GracenoteEvent.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class GracenoteEvent {
  final String duration;
  final String startTime;
  final String endTime;
  final String? thumbnail;
  final GracenoteProgram program;
  final List<String> flags;
  final List<String> tags;

  GracenoteEvent({
    required this.duration,
    required this.startTime,
    required this.endTime,
    this.thumbnail,
    required this.program,
    required this.flags,
    required this.tags,
  });

  factory GracenoteEvent.fromJson(Map<String, dynamic> json) {
    return GracenoteEvent(
      duration: json['duration'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      thumbnail: json['thumbnail'],
      program: GracenoteProgram.fromJson(json['program'] ?? {}),
      flags: List<String>.from(json['flag'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class GracenoteProgram {
  final String title;
  final String id;
  final String? tmsId;
  final String? shortDesc;
  final String? seriesId;
  final String? episodeTitle;

  GracenoteProgram({
    required this.title,
    required this.id,
    this.tmsId,
    this.shortDesc,
    this.seriesId,
    this.episodeTitle,
  });

  factory GracenoteProgram.fromJson(Map<String, dynamic> json) {
    return GracenoteProgram(
      title: json['title'] ?? '',
      id: json['id'] ?? '',
      tmsId: json['tmsId'],
      shortDesc: json['shortDesc'],
      seriesId: json['seriesId'],
      episodeTitle: json['episodeTitle'],
    );
  }
}

class GracenoteAffiliateProperties {
  final String defaultPostalCode;
  final String defaultHeadend;
  final String defaultCountry;
  final String defaultTimezone;
  final String headendName;
  final String device;

  GracenoteAffiliateProperties({
    required this.defaultPostalCode,
    required this.defaultHeadend,
    required this.defaultCountry,
    required this.defaultTimezone,
    required this.headendName,
    required this.device,
  });

  factory GracenoteAffiliateProperties.fromJson(Map<String, dynamic> json) {
    return GracenoteAffiliateProperties(
      defaultPostalCode: json['defaultpostalcode'] ?? '',
      defaultHeadend: json['defaultheadend'] ?? '',
      defaultCountry: json['defaultcountry'] ?? '',
      defaultTimezone: json['defaulttimezone'] ?? '',
      headendName: json['headendname'] ?? '',
      device: json['device'] ?? 'X',
    );
  }
}

/// In-memory cache for EPG data
class _EPGCache {
  final Map<String, _CachedData> _cache = {};

  T? get<T>(String key) {
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (DateTime.now().difference(cached.timestamp).inHours < 1) {
        return cached.data as T;
      }
      _cache.remove(key);
    }
    return null;
  }

  void set(String key, dynamic data) {
    _cache[key] = _CachedData(data, DateTime.now());
  }

  void clear() {
    _cache.clear();
  }
}

class _CachedData {
  final dynamic data;
  final DateTime timestamp;

  _CachedData(this.data, this.timestamp);
}

/// Service for fetching EPG data directly from Gracenote
class GracenoteEPGService {
  static const String _baseUrl = 'https://tvlistings.gracenote.com';
  static final _EPGCache _cache = _EPGCache();

  /// Fetch affiliate properties for a given affiliate ID
  Future<GracenoteAffiliateProperties> getAffiliateProperties(
    String affiliateId,
  ) async {
    final cacheKey = 'props_$affiliateId';
    final cached = _cache.get<GracenoteAffiliateProperties>(cacheKey);
    if (cached != null) return cached;

    final url =
        '$_baseUrl/gapzap_webapi/api/affiliates/getaffiliatesprop/$affiliateId/en-us';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; Plezy/1.0)',
        'Accept': 'application/json',
        'Referer': 'https://tvlistings.gracenote.com/',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get affiliate properties: ${response.statusCode}');
    }

    final props =
        GracenoteAffiliateProperties.fromJson(json.decode(response.body));
    _cache.set(cacheKey, props);
    return props;
  }

  /// Fetch TV listings for a given affiliate
  Future<List<GracenoteChannel>> getTVListings({
    required String affiliateId,
    String? postalCode,
    int hours = 6,
  }) async {
    // Get affiliate properties first
    final props = await getAffiliateProperties(affiliateId);
    final actualPostalCode = postalCode ?? props.defaultPostalCode;

    // Check cache
    final cacheKey = '${affiliateId}_${actualPostalCode}_$hours';
    final cached = _cache.get<List<GracenoteChannel>>(cacheKey);
    if (cached != null) return cached;

    // Build lineup ID
    final lineupId =
        '${props.defaultCountry}-${props.defaultHeadend}-DEFAULT';

    // Build query parameters
    final params = {
      'lineupId': lineupId,
      'headendId': props.defaultHeadend,
      'country': props.defaultCountry,
      'postalCode': actualPostalCode,
      'time': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      'timespan': hours.toString(),
      'device': props.device,
      'userId': '-',
      'aid': affiliateId,
      'languagecode': 'en-us',
    };

    final url = Uri.parse('$_baseUrl/api/grid').replace(queryParameters: params);

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; Plezy/1.0)',
        'Accept': 'application/json',
        'Referer': 'https://tvlistings.gracenote.com/',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get TV listings: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final channels = (data['channels'] as List)
        .map((c) => GracenoteChannel.fromJson(c))
        .toList();

    _cache.set(cacheKey, channels);
    return channels;
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }
}
