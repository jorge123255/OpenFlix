// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => MediaItem(
  ratingKey: const StringOrIntConverter().fromJson(json['ratingKey']),
  key: const StringOrIntConverter().fromJson(json['key']),
  guid: json['guid'] as String?,
  studio: json['studio'] as String?,
  type: json['type'] as String,
  title: json['title'] as String,
  contentRating: json['contentRating'] as String?,
  summary: json['summary'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  audienceRating: (json['audienceRating'] as num?)?.toDouble(),
  year: (json['year'] as num?)?.toInt(),
  thumb: json['thumb'] as String?,
  art: json['art'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  addedAt: (json['addedAt'] as num?)?.toInt(),
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  lastViewedAt: (json['lastViewedAt'] as num?)?.toInt(),
  grandparentTitle: json['grandparentTitle'] as String?,
  grandparentThumb: json['grandparentThumb'] as String?,
  grandparentArt: json['grandparentArt'] as String?,
  grandparentRatingKey: const NullableStringOrIntConverter().fromJson(
    json['grandparentRatingKey'],
  ),
  parentTitle: json['parentTitle'] as String?,
  parentThumb: json['parentThumb'] as String?,
  parentRatingKey: const NullableStringOrIntConverter().fromJson(
    json['parentRatingKey'],
  ),
  parentIndex: (json['parentIndex'] as num?)?.toInt(),
  index: (json['index'] as num?)?.toInt(),
  grandparentTheme: json['grandparentTheme'] as String?,
  viewOffset: (json['viewOffset'] as num?)?.toInt(),
  viewCount: (json['viewCount'] as num?)?.toInt(),
  leafCount: (json['leafCount'] as num?)?.toInt(),
  viewedLeafCount: (json['viewedLeafCount'] as num?)?.toInt(),
  childCount: (json['childCount'] as num?)?.toInt(),
  role: (json['Role'] as List<dynamic>?)
      ?.map((e) => Role.fromJson(e as Map<String, dynamic>))
      .toList(),
  audioLanguage: json['audioLanguage'] as String?,
  subtitleLanguage: json['subtitleLanguage'] as String?,
  playlistItemID: (json['playlistItemID'] as num?)?.toInt(),
  playQueueItemID: (json['playQueueItemID'] as num?)?.toInt(),
  librarySectionID: (json['librarySectionID'] as num?)?.toInt(),
);

Map<String, dynamic> _$MediaItemToJson(MediaItem instance) => <String, dynamic>{
  'ratingKey': const StringOrIntConverter().toJson(instance.ratingKey),
  'key': const StringOrIntConverter().toJson(instance.key),
  'guid': instance.guid,
  'studio': instance.studio,
  'type': instance.type,
  'title': instance.title,
  'contentRating': instance.contentRating,
  'summary': instance.summary,
  'rating': instance.rating,
  'audienceRating': instance.audienceRating,
  'year': instance.year,
  'thumb': instance.thumb,
  'art': instance.art,
  'duration': instance.duration,
  'addedAt': instance.addedAt,
  'updatedAt': instance.updatedAt,
  'lastViewedAt': instance.lastViewedAt,
  'grandparentTitle': instance.grandparentTitle,
  'grandparentThumb': instance.grandparentThumb,
  'grandparentArt': instance.grandparentArt,
  'grandparentRatingKey': const NullableStringOrIntConverter().toJson(
    instance.grandparentRatingKey,
  ),
  'parentTitle': instance.parentTitle,
  'parentThumb': instance.parentThumb,
  'parentRatingKey': const NullableStringOrIntConverter().toJson(
    instance.parentRatingKey,
  ),
  'parentIndex': instance.parentIndex,
  'index': instance.index,
  'grandparentTheme': instance.grandparentTheme,
  'viewOffset': instance.viewOffset,
  'viewCount': instance.viewCount,
  'leafCount': instance.leafCount,
  'viewedLeafCount': instance.viewedLeafCount,
  'childCount': instance.childCount,
  'Role': instance.role,
  'audioLanguage': instance.audioLanguage,
  'subtitleLanguage': instance.subtitleLanguage,
  'playlistItemID': instance.playlistItemID,
  'playQueueItemID': instance.playQueueItemID,
  'librarySectionID': instance.librarySectionID,
};
