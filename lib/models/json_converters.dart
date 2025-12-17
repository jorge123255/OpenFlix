import 'package:json_annotation/json_annotation.dart';

/// Converter that handles both String and int values, converting to String.
/// This is needed because OpenFlix server returns numeric IDs as integers
/// while Plex API returns them as strings.
class StringOrIntConverter implements JsonConverter<String, dynamic> {
  const StringOrIntConverter();

  @override
  String fromJson(dynamic json) {
    if (json is String) return json;
    if (json is int) return json.toString();
    if (json is num) return json.toString();
    return json?.toString() ?? '';
  }

  @override
  dynamic toJson(String object) => object;
}

/// Converter that handles both String and int values, converting to String?
/// This is needed because OpenFlix server returns numeric IDs as integers
/// while Plex API returns them as strings.
class NullableStringOrIntConverter implements JsonConverter<String?, dynamic> {
  const NullableStringOrIntConverter();

  @override
  String? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) return json;
    if (json is int) return json.toString();
    if (json is num) return json.toString();
    return json?.toString();
  }

  @override
  dynamic toJson(String? object) => object;
}
