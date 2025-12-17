import 'package:flutter/material.dart';
import '../../models/media_item.dart';
import '../../utils/library_refresh_notifier.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/adaptive_media_grid.dart';
import 'base_library_tab.dart';

/// Collections tab for library screen
/// Shows collections for the current library
class LibraryCollectionsTab extends BaseLibraryTab<MediaItem> {
  const LibraryCollectionsTab({
    super.key,
    required super.library,
    super.viewMode,
    super.density,
  });

  @override
  State<LibraryCollectionsTab> createState() => _LibraryCollectionsTabState();
}

class _LibraryCollectionsTabState
    extends BaseLibraryTabState<MediaItem, LibraryCollectionsTab> {
  /// Focus node for the first item in the grid
  final FocusNode _firstItemFocusNode = FocusNode(
    debugLabel: 'CollectionsFirstItem',
  );

  @override
  void dispose() {
    _firstItemFocusNode.dispose();
    super.dispose();
  }

  @override
  IconData get emptyIcon => Icons.collections;

  @override
  String get emptyMessage => t.libraries.noCollections;

  @override
  String get errorContext => t.collections.title;

  @override
  Stream<void>? getRefreshStream() =>
      LibraryRefreshNotifier().collectionsStream;

  @override
  Future<List<MediaItem>> loadData() async {
    // Use server-specific client for this library
    final client = getClientForLibrary();

    // Collections are automatically tagged with server info by MediaClient
    return await client.getLibraryCollections(widget.library.key);
  }

  @override
  void focusFirstItem() {
    if (items.isNotEmpty) {
      _firstItemFocusNode.requestFocus();
    }
  }

  @override
  Widget buildContent(List<MediaItem> items) {
    return AdaptiveMediaGrid(
      items: items,
      onRefresh: loadItems,
      firstItemFocusNode: _firstItemFocusNode,
    );
  }
}
