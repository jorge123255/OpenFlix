/// Represents an upcoming program with channel info
class OnLaterItem {
  final OnLaterProgram program;
  final OnLaterChannel? channel;
  final bool hasRecording;
  final int? recordingId;

  OnLaterItem({
    required this.program,
    this.channel,
    this.hasRecording = false,
    this.recordingId,
  });

  factory OnLaterItem.fromJson(Map<String, dynamic> json) {
    return OnLaterItem(
      program: OnLaterProgram.fromJson(json['program'] as Map<String, dynamic>),
      channel: json['channel'] != null
          ? OnLaterChannel.fromJson(json['channel'] as Map<String, dynamic>)
          : null,
      hasRecording: json['hasRecording'] as bool? ?? false,
      recordingId: json['recordingId'] as int?,
    );
  }
}

/// Represents an EPG program with content classification
class OnLaterProgram {
  final int id;
  final String channelId;
  final String title;
  final String? subtitle;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? icon;
  final String? art;
  final String? category;
  final String? episodeNum;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? rating;

  // Content classification flags
  final bool isMovie;
  final bool isSports;
  final bool isKids;
  final bool isNews;
  final bool isPremiere;
  final bool isNew;
  final bool isLive;
  final bool isFinale;

  // Sports-specific fields
  final String? teams;
  final String? league;

  // External IDs
  final String? seriesId;
  final String? programId;

  OnLaterProgram({
    required this.id,
    required this.channelId,
    required this.title,
    this.subtitle,
    this.description,
    required this.start,
    required this.end,
    this.icon,
    this.art,
    this.category,
    this.episodeNum,
    this.seasonNumber,
    this.episodeNumber,
    this.rating,
    this.isMovie = false,
    this.isSports = false,
    this.isKids = false,
    this.isNews = false,
    this.isPremiere = false,
    this.isNew = false,
    this.isLive = false,
    this.isFinale = false,
    this.teams,
    this.league,
    this.seriesId,
    this.programId,
  });

  factory OnLaterProgram.fromJson(Map<String, dynamic> json) {
    return OnLaterProgram(
      id: json['id'] as int? ?? 0,
      channelId: json['channelId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      icon: json['icon'] as String?,
      art: json['art'] as String?,
      category: json['category'] as String?,
      episodeNum: json['episodeNum'] as String?,
      seasonNumber: json['seasonNumber'] as int?,
      episodeNumber: json['episodeNumber'] as int?,
      rating: json['rating'] as String?,
      isMovie: json['isMovie'] as bool? ?? false,
      isSports: json['isSports'] as bool? ?? false,
      isKids: json['isKids'] as bool? ?? false,
      isNews: json['isNews'] as bool? ?? false,
      isPremiere: json['isPremiere'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
      isLive: json['isLive'] as bool? ?? false,
      isFinale: json['isFinale'] as bool? ?? false,
      teams: json['teams'] as String?,
      league: json['league'] as String?,
      seriesId: json['seriesId'] as String?,
      programId: json['programId'] as String?,
    );
  }

  /// Duration in minutes
  int get durationMinutes => end.difference(start).inMinutes;

  /// Display title with episode info
  String get displayTitle {
    if (subtitle != null && subtitle!.isNotEmpty) {
      return '$title: $subtitle';
    }
    return title;
  }

  /// Episode info string (e.g., "S1 E5")
  String? get episodeInfo {
    if (seasonNumber != null && episodeNumber != null) {
      return 'S$seasonNumber E$episodeNumber';
    }
    if (episodeNum != null && episodeNum!.isNotEmpty) {
      return episodeNum;
    }
    return null;
  }

  /// Best available image
  String? get imageUrl => art ?? icon;

  /// Content type badges
  List<String> get badges {
    final badges = <String>[];
    if (isNew) badges.add('NEW');
    if (isPremiere) badges.add('PREMIERE');
    if (isFinale) badges.add('FINALE');
    if (isLive) badges.add('LIVE');
    return badges;
  }

  /// Parse teams into list
  List<String> get teamsList {
    if (teams == null || teams!.isEmpty) return [];
    return teams!.split(',').map((t) => t.trim()).toList();
  }
}

/// Simplified channel info for On Later display
class OnLaterChannel {
  final int id;
  final String channelId;
  final String name;
  final String? logo;
  final int? number;

  OnLaterChannel({
    required this.id,
    required this.channelId,
    required this.name,
    this.logo,
    this.number,
  });

  factory OnLaterChannel.fromJson(Map<String, dynamic> json) {
    return OnLaterChannel(
      id: json['id'] as int? ?? 0,
      channelId: json['channelId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?,
      number: json['number'] as int?,
    );
  }
}

/// Response for On Later queries
class OnLaterResponse {
  final List<OnLaterItem> items;
  final int totalCount;
  final DateTime startTime;
  final DateTime endTime;

  OnLaterResponse({
    required this.items,
    required this.totalCount,
    required this.startTime,
    required this.endTime,
  });

  factory OnLaterResponse.fromJson(Map<String, dynamic> json) {
    return OnLaterResponse(
      items: (json['items'] as List)
          .map((i) => OnLaterItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
    );
  }
}

/// Statistics for On Later categories
class OnLaterStats {
  final int movies;
  final int sports;
  final int kids;
  final int news;
  final int premieres;

  OnLaterStats({
    required this.movies,
    required this.sports,
    required this.kids,
    required this.news,
    required this.premieres,
  });

  factory OnLaterStats.fromJson(Map<String, dynamic> json) {
    return OnLaterStats(
      movies: json['movies'] as int? ?? 0,
      sports: json['sports'] as int? ?? 0,
      kids: json['kids'] as int? ?? 0,
      news: json['news'] as int? ?? 0,
      premieres: json['premieres'] as int? ?? 0,
    );
  }
}

/// Represents a sports team
class SportsTeam {
  final String name;
  final String city;
  final String nickname;
  final String? league;
  final List<String> aliases;

  SportsTeam({
    required this.name,
    required this.city,
    required this.nickname,
    this.league,
    this.aliases = const [],
  });

  factory SportsTeam.fromJson(Map<String, dynamic> json) {
    return SportsTeam(
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      league: json['league'] as String?,
      aliases: (json['aliases'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// On Later category types
enum OnLaterCategory {
  tonight,
  movies,
  sports,
  kids,
  news,
  premieres,
  week,
}
