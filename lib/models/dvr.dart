/// DVR Recording model
class DVRRecording {
  final int id;
  final int userId;
  final int channelId;
  final int? programId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // scheduled, recording, completed, failed, cancelled
  final String? filePath;
  final int? fileSize;
  final int? seriesRuleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DVRRecording({
    required this.id,
    required this.userId,
    required this.channelId,
    this.programId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.filePath,
    this.fileSize,
    this.seriesRuleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DVRRecording.fromJson(Map<String, dynamic> json) {
    return DVRRecording(
      id: json['id'] as int,
      userId: json['userId'] as int,
      channelId: json['channelId'] as int,
      programId: json['programId'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: json['status'] as String,
      filePath: json['filePath'] as String?,
      fileSize: json['fileSize'] as int?,
      seriesRuleId: json['seriesRuleId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'channelId': channelId,
      'programId': programId,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'filePath': filePath,
      'fileSize': fileSize,
      'seriesRuleId': seriesRuleId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Whether the recording is currently in progress
  bool get isRecording => status == 'recording';

  /// Whether the recording is scheduled for the future
  bool get isScheduled => status == 'scheduled';

  /// Whether the recording has completed successfully
  bool get isCompleted => status == 'completed';

  /// Whether the recording failed
  bool get isFailed => status == 'failed';

  /// Duration of the recording
  Duration get duration => endTime.difference(startTime);

  /// File size in MB
  double get fileSizeMB => (fileSize ?? 0) / (1024 * 1024);

  /// Status display text
  String get statusText {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'recording':
        return 'Recording';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Commercial segment detected in a recording
class CommercialSegment {
  final int id;
  final int recordingId;
  final double startTime; // seconds from beginning
  final double endTime; // seconds from beginning
  final double duration; // seconds

  CommercialSegment({
    required this.id,
    required this.recordingId,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  factory CommercialSegment.fromJson(Map<String, dynamic> json) {
    return CommercialSegment(
      id: json['id'] as int,
      recordingId: json['recordingId'] as int,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordingId': recordingId,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
    };
  }

  /// Check if a given position (in seconds) is within this commercial
  bool containsPosition(double positionSeconds) {
    return positionSeconds >= startTime && positionSeconds < endTime;
  }

  /// Duration as a formatted string
  String get durationText {
    final minutes = (duration / 60).floor();
    final seconds = (duration % 60).round();
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

/// Commercial segments response with metadata
class CommercialSegmentsResponse {
  final int recordingId;
  final List<CommercialSegment> segments;
  final int totalCommercials;
  final double commercialSeconds;

  CommercialSegmentsResponse({
    required this.recordingId,
    required this.segments,
    required this.totalCommercials,
    required this.commercialSeconds,
  });

  factory CommercialSegmentsResponse.fromJson(Map<String, dynamic> json) {
    final segmentsList = json['segments'] as List<dynamic>? ?? [];
    return CommercialSegmentsResponse(
      recordingId: json['recordingId'] as int,
      segments: segmentsList
          .map((s) => CommercialSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      totalCommercials: json['totalCommercials'] as int? ?? 0,
      commercialSeconds: (json['commercialSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Total commercial time as formatted string
  String get commercialTimeText {
    final minutes = (commercialSeconds / 60).floor();
    final seconds = (commercialSeconds % 60).round();
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Check if a given position is within any commercial segment
  CommercialSegment? getCommercialAtPosition(double positionSeconds) {
    for (final segment in segments) {
      if (segment.containsPosition(positionSeconds)) {
        return segment;
      }
    }
    return null;
  }

  /// Get the next commercial segment after a given position
  CommercialSegment? getNextCommercial(double positionSeconds) {
    for (final segment in segments) {
      if (segment.startTime > positionSeconds) {
        return segment;
      }
    }
    return null;
  }
}

/// DVR Series Recording Rule model
class DVRSeriesRule {
  final int id;
  final int userId;
  final String title;
  final int? channelId;
  final String? keywords;
  final String? timeSlot;
  final String? daysOfWeek;
  final int keepCount; // 0 = keep all
  final int prePadding; // minutes
  final int postPadding; // minutes
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  DVRSeriesRule({
    required this.id,
    required this.userId,
    required this.title,
    this.channelId,
    this.keywords,
    this.timeSlot,
    this.daysOfWeek,
    this.keepCount = 0,
    this.prePadding = 0,
    this.postPadding = 0,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DVRSeriesRule.fromJson(Map<String, dynamic> json) {
    return DVRSeriesRule(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      channelId: json['channelId'] as int?,
      keywords: json['keywords'] as String?,
      timeSlot: json['timeSlot'] as String?,
      daysOfWeek: json['daysOfWeek'] as String?,
      keepCount: json['keepCount'] as int? ?? 0,
      prePadding: json['prePadding'] as int? ?? 0,
      postPadding: json['postPadding'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'channelId': channelId,
      'keywords': keywords,
      'timeSlot': timeSlot,
      'daysOfWeek': daysOfWeek,
      'keepCount': keepCount,
      'prePadding': prePadding,
      'postPadding': postPadding,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Days of week as list of integers (1=Monday, 7=Sunday)
  List<int> get daysOfWeekList {
    if (daysOfWeek == null || daysOfWeek!.isEmpty) return [];
    return daysOfWeek!.split(',').map((d) => int.tryParse(d.trim()) ?? 0).where((d) => d > 0).toList();
  }

  /// Human-readable days of week
  String get daysOfWeekText {
    final days = daysOfWeekList;
    if (days.isEmpty) return 'Any day';
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d]).join(', ');
  }

  /// Human-readable keep policy
  String get keepPolicyText {
    if (keepCount == 0) return 'Keep all';
    return 'Keep $keepCount episode${keepCount == 1 ? '' : 's'}';
  }

  /// Human-readable padding
  String get paddingText {
    if (prePadding == 0 && postPadding == 0) return 'No padding';
    final parts = <String>[];
    if (prePadding > 0) parts.add('$prePadding min before');
    if (postPadding > 0) parts.add('$postPadding min after');
    return parts.join(', ');
  }
}
