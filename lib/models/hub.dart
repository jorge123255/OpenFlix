import 'media_item.dart';

/// Represents a Plex hub/recommendation section (e.g., Trending Movies, Top Thrillers)
class Hub {
  final String hubKey;
  final String title;
  final String type;
  final String? hubIdentifier;
  final int size;
  final bool more;
  final List<MediaItem> items;

  // Multi-server support fields
  final String? serverId; // Server machine identifier
  final String? serverName; // Server display name

  Hub({
    required this.hubKey,
    required this.title,
    required this.type,
    this.hubIdentifier,
    required this.size,
    required this.more,
    required this.items,
    this.serverId,
    this.serverName,
  });

  factory Hub.fromJson(Map<String, dynamic> json) {
    final metadataList = <MediaItem>[];

    // Helper function to parse entries from a JSON list
    void parseEntries(List? entries) {
      if (entries == null) return;
      for (final item in entries) {
        try {
          metadataList.add(MediaItem.fromJson(item));
        } catch (e) {
          // Skip items that fail to parse
        }
      }
    }

    // Hubs can contain either Metadata or Directory entries
    parseEntries(json['Metadata'] as List?);
    parseEntries(json['Directory'] as List?);

    return Hub(
      hubKey: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'hub',
      hubIdentifier: json['hubIdentifier'] as String?,
      size: (json['size'] as num?)?.toInt() ?? metadataList.length,
      more: json['more'] == true || json['more'] == 1,
      items: metadataList,
    );
  }
}
