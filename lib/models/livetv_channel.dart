/// Represents a Live TV channel
class LiveTVChannel {
  final int id;
  final String channelId;
  final String name;
  final String? logo;
  final String streamUrl;
  final int? number;
  final String? group;
  final bool enabled;
  final LiveTVProgram? nowPlaying;
  final LiveTVProgram? nextProgram;

  LiveTVChannel({
    required this.id,
    required this.channelId,
    required this.name,
    this.logo,
    required this.streamUrl,
    this.number,
    this.group,
    this.enabled = true,
    this.nowPlaying,
    this.nextProgram,
  });

  factory LiveTVChannel.fromJson(Map<String, dynamic> json) {
    return LiveTVChannel(
      id: json['id'] as int,
      channelId: json['channelId'] as String,
      name: json['name'] as String,
      logo: json['logo'] as String?,
      streamUrl: json['streamUrl'] as String,
      number: json['number'] as int?,
      group: json['group'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      nowPlaying: json['nowPlaying'] != null
          ? LiveTVProgram.fromJson(json['nowPlaying'] as Map<String, dynamic>)
          : null,
      nextProgram: json['nextProgram'] != null
          ? LiveTVProgram.fromJson(json['nextProgram'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'name': name,
      'logo': logo,
      'streamUrl': streamUrl,
      'number': number,
      'group': group,
      'enabled': enabled,
      'nowPlaying': nowPlaying?.toJson(),
      'nextProgram': nextProgram?.toJson(),
    };
  }

  LiveTVChannel copyWith({
    int? id,
    String? channelId,
    String? name,
    String? logo,
    String? streamUrl,
    int? number,
    String? group,
    bool? enabled,
    LiveTVProgram? nowPlaying,
    LiveTVProgram? nextProgram,
  }) {
    return LiveTVChannel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      streamUrl: streamUrl ?? this.streamUrl,
      number: number ?? this.number,
      group: group ?? this.group,
      enabled: enabled ?? this.enabled,
      nowPlaying: nowPlaying ?? this.nowPlaying,
      nextProgram: nextProgram ?? this.nextProgram,
    );
  }
}

/// Represents a TV program in the EPG
class LiveTVProgram {
  final int id;
  final String channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? icon;
  final String? category;
  final String? episodeNum;

  LiveTVProgram({
    required this.id,
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.icon,
    this.category,
    this.episodeNum,
  });

  factory LiveTVProgram.fromJson(Map<String, dynamic> json) {
    return LiveTVProgram(
      id: json['id'] as int,
      channelId: json['channelId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      icon: json['icon'] as String?,
      category: json['category'] as String?,
      episodeNum: json['episodeNum'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'title': title,
      'description': description,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'icon': icon,
      'category': category,
      'episodeNum': episodeNum,
    };
  }

  /// Returns the duration of the program in minutes
  int get durationMinutes => end.difference(start).inMinutes;

  /// Returns true if the program is currently airing
  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Returns the progress percentage (0.0 to 1.0) if live, 0 if not started, 1 if ended
  double get progress {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;
    final elapsed = now.difference(start).inSeconds;
    final total = end.difference(start).inSeconds;
    return total > 0 ? elapsed / total : 0.0;
  }
}

/// Represents EPG guide data for a time range
class LiveTVGuideData {
  final List<LiveTVChannel> channels;
  final Map<String, List<LiveTVProgram>> programs; // channelId -> programs
  final DateTime startTime;
  final DateTime endTime;

  LiveTVGuideData({
    required this.channels,
    required this.programs,
    required this.startTime,
    required this.endTime,
  });

  factory LiveTVGuideData.fromJson(Map<String, dynamic> json) {
    final channelsList = (json['channels'] as List)
        .map((c) => LiveTVChannel.fromJson(c as Map<String, dynamic>))
        .toList();

    final programsMap = <String, List<LiveTVProgram>>{};
    if (json['programs'] != null) {
      final programsJson = json['programs'] as Map<String, dynamic>;
      for (final entry in programsJson.entries) {
        programsMap[entry.key] = (entry.value as List)
            .map((p) => LiveTVProgram.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    }

    return LiveTVGuideData(
      channels: channelsList,
      programs: programsMap,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
    );
  }
}

/// Represents an M3U source configuration
class LiveTVSource {
  final int id;
  final String name;
  final String url;
  final String? epgUrl;
  final bool enabled;
  final int channelCount;
  final DateTime? lastFetched;

  LiveTVSource({
    required this.id,
    required this.name,
    required this.url,
    this.epgUrl,
    this.enabled = true,
    this.channelCount = 0,
    this.lastFetched,
  });

  factory LiveTVSource.fromJson(Map<String, dynamic> json) {
    return LiveTVSource(
      id: json['id'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
      epgUrl: json['epgUrl'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      channelCount: json['channelCount'] as int? ?? 0,
      lastFetched: json['lastFetched'] != null
          ? DateTime.parse(json['lastFetched'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'epgUrl': epgUrl,
      'enabled': enabled,
      'channelCount': channelCount,
      'lastFetched': lastFetched?.toIso8601String(),
    };
  }
}
