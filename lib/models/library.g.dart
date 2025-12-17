// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Library _$LibraryFromJson(Map<String, dynamic> json) => Library(
  key: const StringOrIntConverter().fromJson(json['key']),
  title: json['title'] as String,
  type: json['type'] as String,
  agent: json['agent'] as String?,
  scanner: json['scanner'] as String?,
  language: json['language'] as String?,
  uuid: json['uuid'] as String?,
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  createdAt: (json['createdAt'] as num?)?.toInt(),
  hidden: (json['hidden'] as num?)?.toInt(),
);

Map<String, dynamic> _$LibraryToJson(Library instance) => <String, dynamic>{
  'key': const StringOrIntConverter().toJson(instance.key),
  'title': instance.title,
  'type': instance.type,
  'agent': instance.agent,
  'scanner': instance.scanner,
  'language': instance.language,
  'uuid': instance.uuid,
  'updatedAt': instance.updatedAt,
  'createdAt': instance.createdAt,
  'hidden': instance.hidden,
};
