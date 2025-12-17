import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';
import 'mixins/multi_server_fields.dart';

part 'library.g.dart';

@JsonSerializable()
class Library with MultiServerFields {
  @StringOrIntConverter()
  final String key;
  final String title;
  final String type;
  final String? agent;
  final String? scanner;
  final String? language;
  final String? uuid;
  final int? updatedAt;
  final int? createdAt;
  final int? hidden;

  // Multi-server support fields (from MultiServerFields mixin)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverName;

  /// Global unique identifier across all servers (serverId:key)
  String get globalKey => serverId != null ? '$serverId:$key' : key;

  Library({
    required this.key,
    required this.title,
    required this.type,
    this.agent,
    this.scanner,
    this.language,
    this.uuid,
    this.updatedAt,
    this.createdAt,
    this.hidden,
    this.serverId,
    this.serverName,
  });

  factory Library.fromJson(Map<String, dynamic> json) =>
      _$LibraryFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryToJson(this);

  /// Create a copy of this library with optional field overrides
  Library copyWith({
    String? key,
    String? title,
    String? type,
    String? agent,
    String? scanner,
    String? language,
    String? uuid,
    int? updatedAt,
    int? createdAt,
    int? hidden,
    String? serverId,
    String? serverName,
  }) {
    return Library(
      key: key ?? this.key,
      title: title ?? this.title,
      type: type ?? this.type,
      agent: agent ?? this.agent,
      scanner: scanner ?? this.scanner,
      language: language ?? this.language,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      hidden: hidden ?? this.hidden,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
    );
  }
}
