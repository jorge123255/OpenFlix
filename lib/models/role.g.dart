// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Role _$RoleFromJson(Map<String, dynamic> json) => Role(
  id: (json['id'] as num?)?.toInt(),
  filter: json['filter'] as String?,
  tag: json['tag'] as String,
  tagKey: json['tagKey'] as String?,
  role: json['role'] as String?,
  thumb: json['thumb'] as String?,
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$RoleToJson(Role instance) => <String, dynamic>{
  'id': instance.id,
  'filter': instance.filter,
  'tag': instance.tag,
  'tagKey': instance.tagKey,
  'role': instance.role,
  'thumb': instance.thumb,
  'count': instance.count,
};
