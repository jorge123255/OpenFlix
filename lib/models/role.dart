import 'package:json_annotation/json_annotation.dart';

part 'role.g.dart';

@JsonSerializable()
class Role {
  final int? id;
  final String? filter;
  final String tag;
  final String? tagKey;
  final String? role;
  final String? thumb;
  final int? count;

  Role({
    this.id,
    this.filter,
    required this.tag,
    this.tagKey,
    this.role,
    this.thumb,
    this.count,
  });

  factory Role.fromJson(Map<String, dynamic> json) =>
      _$RoleFromJson(json);

  Map<String, dynamic> toJson() => _$RoleToJson(this);
}
