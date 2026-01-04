import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../i18n/strings.g.dart';
import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../services/settings_service.dart';
import '../utils/video_player_navigation.dart';

/// Virtual Channels - custom 24/7 playlists that play continuously
class VirtualChannelsScreen extends StatefulWidget {
  const VirtualChannelsScreen({super.key});

  @override
  State<VirtualChannelsScreen> createState() => _VirtualChannelsScreenState();
}

class _VirtualChannelsScreenState extends State<VirtualChannelsScreen> {
  SettingsService? _settingsService;
  List<Map<String, dynamic>> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    _settingsService = await SettingsService.getInstance();
    if (mounted) {
      setState(() {
        _channels = _settingsService!.getVirtualChannels();
        _isLoading = false;
      });
    }
  }

  Future<void> _createChannel() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const VirtualChannelEditorScreen(),
      ),
    );

    if (result != null && _settingsService != null) {
      await _settingsService!.addVirtualChannel(result);
      if (mounted) {
        setState(() {
          _channels = _settingsService!.getVirtualChannels();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.virtualChannels.channelCreated)),
        );
      }
    }
  }

  Future<void> _editChannel(int index) async {
    final channel = _channels[index];
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => VirtualChannelEditorScreen(channel: channel),
      ),
    );

    if (result != null && _settingsService != null) {
      await _settingsService!.updateVirtualChannel(channel['id'], result);
      if (mounted) {
        setState(() {
          _channels = _settingsService!.getVirtualChannels();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.virtualChannels.channelUpdated)),
        );
      }
    }
  }

  Future<void> _deleteChannel(int index) async {
    final channel = _channels[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.virtualChannels.deleteChannel),
        content: Text(t.virtualChannels.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && _settingsService != null) {
      await _settingsService!.deleteVirtualChannel(channel['id']);
      if (mounted) {
        setState(() {
          _channels = _settingsService!.getVirtualChannels();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.virtualChannels.channelDeleted)),
        );
      }
    }
  }

  Future<void> _playChannel(Map<String, dynamic> channel) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VirtualChannelPlayerScreen(channel: channel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.virtualChannels.title),
        actions: [
          IconButton(
            onPressed: _createChannel,
            icon: const Icon(Icons.add),
            tooltip: t.virtualChannels.createChannel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _channels.isEmpty
              ? _buildEmptyState()
              : _buildChannelList(),
      floatingActionButton: _channels.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _createChannel,
              icon: const Icon(Icons.add),
              label: Text(t.virtualChannels.createChannel),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            t.virtualChannels.noChannels,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            t.virtualChannels.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _createChannel,
            icon: const Icon(Icons.add),
            label: Text(t.virtualChannels.createFirst),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _channels.length,
      itemBuilder: (context, index) {
        final channel = _channels[index];
        final mediaItems = (channel['mediaItems'] as List?)?.length ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _playChannel(channel),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.live_tv,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel['name'] ?? 'Unnamed Channel',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$mediaItems items',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (channel['shuffle'] == true)
                              _buildChip(Icons.shuffle, t.virtualChannels.shuffle),
                            if (channel['loop'] == true)
                              _buildChip(Icons.repeat, t.virtualChannels.loop),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editChannel(index);
                      } else if (value == 'delete') {
                        _deleteChannel(index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            Text(t.virtualChannels.editChannel),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              t.virtualChannels.deleteChannel,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Editor for creating/editing virtual channels
class VirtualChannelEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? channel;

  const VirtualChannelEditorScreen({super.key, this.channel});

  @override
  State<VirtualChannelEditorScreen> createState() => _VirtualChannelEditorScreenState();
}

class _VirtualChannelEditorScreenState extends State<VirtualChannelEditorScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _shuffle = false;
  bool _loop = true;
  List<Map<String, dynamic>> _selectedMedia = [];
  bool _isLoadingMedia = false;
  List<MediaItem> _availableMedia = [];

  @override
  void initState() {
    super.initState();
    if (widget.channel != null) {
      _nameController.text = widget.channel!['name'] ?? '';
      _shuffle = widget.channel!['shuffle'] ?? false;
      _loop = widget.channel!['loop'] ?? true;
      _selectedMedia = List<Map<String, dynamic>>.from(
        widget.channel!['mediaItems'] ?? [],
      );
    }
    _loadAvailableMedia();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableMedia() async {
    setState(() => _isLoadingMedia = true);

    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      final allItems = <MediaItem>[];

      for (final serverId in multiServerProvider.onlineServerIds) {
        final client = multiServerProvider.getClientForServer(serverId);
        if (client == null) continue;

        final libraries = await client.getLibraries();

        for (final library in libraries) {
          if (library.type != 'movie' && library.type != 'show') continue;

          final content = await client.getLibraryContent(library.key);
          allItems.addAll(content);
        }
      }

      if (mounted) {
        setState(() {
          _availableMedia = allItems;
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMedia = false);
      }
    }
  }

  void _addMedia() async {
    final selected = await showDialog<List<MediaItem>>(
      context: context,
      builder: (context) => _MediaPickerDialog(
        availableMedia: _availableMedia,
        selectedIds: _selectedMedia.map((m) => m['id'] as String).toSet(),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (final item in selected) {
          _selectedMedia.add({
            'id': item.ratingKey,
            'title': item.title,
            'type': item.type,
            'serverId': item.serverId,
            'thumb': item.thumb,
          });
        }
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _saveChannel() {
    if (_formKey.currentState!.validate()) {
      final channel = {
        'id': widget.channel?['id'] ?? const Uuid().v4(),
        'name': _nameController.text.trim(),
        'shuffle': _shuffle,
        'loop': _loop,
        'mediaItems': _selectedMedia,
        'createdAt': widget.channel?['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      Navigator.pop(context, channel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.channel != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? t.virtualChannels.editChannel : t.virtualChannels.createChannel,
        ),
        actions: [
          TextButton(
            onPressed: _saveChannel,
            child: Text(t.common.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Channel Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: t.virtualChannels.channelName,
                hintText: t.virtualChannels.channelNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a channel name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Options
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.shuffle),
                    title: Text(t.virtualChannels.shuffle),
                    value: _shuffle,
                    onChanged: (value) => setState(() => _shuffle = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.repeat),
                    title: Text(t.virtualChannels.loop),
                    value: _loop,
                    onChanged: (value) => setState(() => _loop = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Media Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.virtualChannels.selectContent,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!_isLoadingMedia)
                  FilledButton.icon(
                    onPressed: _addMedia,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(t.virtualChannels.addMedia),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingMedia)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_selectedMedia.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.video_library,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No media selected',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add movies and shows to your channel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedMedia.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _selectedMedia.removeAt(oldIndex);
                    _selectedMedia.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final media = _selectedMedia[index];
                  return Card(
                    key: ValueKey(media['id']),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: media['thumb'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                media['thumb'],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.movie),
                                ),
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                media['type'] == 'movie' ? Icons.movie : Icons.tv,
                              ),
                            ),
                      title: Text(media['title'] ?? 'Unknown'),
                      subtitle: Text(media['type'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeMedia(index),
                            tooltip: t.virtualChannels.removeMedia,
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for picking media to add to a virtual channel
class _MediaPickerDialog extends StatefulWidget {
  final List<MediaItem> availableMedia;
  final Set<String> selectedIds;

  const _MediaPickerDialog({
    required this.availableMedia,
    required this.selectedIds,
  });

  @override
  State<_MediaPickerDialog> createState() => _MediaPickerDialogState();
}

class _MediaPickerDialogState extends State<_MediaPickerDialog> {
  final Set<MediaItem> _selected = {};
  String _searchQuery = '';

  List<MediaItem> get _filteredMedia {
    if (_searchQuery.isEmpty) return widget.availableMedia;
    return widget.availableMedia.where((item) {
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              t.virtualChannels.selectContent,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: t.screens.search,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMedia.length,
                itemBuilder: (context, index) {
                  final item = _filteredMedia[index];
                  final isAlreadyAdded = widget.selectedIds.contains(item.ratingKey);
                  final isSelected = _selected.contains(item);

                  return CheckboxListTile(
                    value: isSelected,
                    enabled: !isAlreadyAdded,
                    onChanged: isAlreadyAdded
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selected.add(item);
                              } else {
                                _selected.remove(item);
                              }
                            });
                          },
                    secondary: item.thumb != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.thumb!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.movie),
                            ),
                          )
                        : Icon(item.type == 'movie' ? Icons.movie : Icons.tv),
                    title: Text(
                      item.title,
                      style: isAlreadyAdded
                          ? TextStyle(color: Theme.of(context).disabledColor)
                          : null,
                    ),
                    subtitle: Text(
                      isAlreadyAdded ? 'Already added' : item.type,
                      style: TextStyle(
                        color: isAlreadyAdded
                            ? Theme.of(context).disabledColor
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.common.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selected.toList()),
                  child: Text('Add ${_selected.length} items'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Player screen for virtual channels
class VirtualChannelPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> channel;

  const VirtualChannelPlayerScreen({super.key, required this.channel});

  @override
  State<VirtualChannelPlayerScreen> createState() => _VirtualChannelPlayerScreenState();
}

class _VirtualChannelPlayerScreenState extends State<VirtualChannelPlayerScreen> {
  List<Map<String, dynamic>> _playlist = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
  }

  void _initializePlaylist() {
    final mediaItems = List<Map<String, dynamic>>.from(
      widget.channel['mediaItems'] ?? [],
    );

    if (widget.channel['shuffle'] == true) {
      mediaItems.shuffle(Random());
    }

    setState(() {
      _playlist = mediaItems;
      _isLoading = false;
    });

    if (_playlist.isNotEmpty) {
      _playCurrentItem();
    }
  }

  Future<void> _playCurrentItem() async {
    if (_currentIndex >= _playlist.length) {
      if (widget.channel['loop'] == true) {
        setState(() {
          _currentIndex = 0;
          if (widget.channel['shuffle'] == true) {
            _playlist.shuffle(Random());
          }
        });
      } else {
        Navigator.pop(context);
        return;
      }
    }

    final mediaItem = _playlist[_currentIndex];

    // Fetch the actual MediaItem from the server
    final multiServerProvider = Provider.of<MultiServerProvider>(
      context,
      listen: false,
    );

    final client = multiServerProvider.getClientForServer(mediaItem['serverId']);
    if (client == null) {
      _nextItem();
      return;
    }

    try {
      final item = await client.getMetadata(mediaItem['id']);
      if (!mounted || item == null) return;

      final result = await navigateToVideoPlayer(
        context,
        metadata: item,
      );

      if (mounted) {
        if (result == true) {
          // Video finished or was skipped - play next
          setState(() => _currentIndex++);
          _playCurrentItem();
        } else {
          // User pressed back - exit
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _nextItem();
    }
  }

  void _nextItem() {
    setState(() => _currentIndex++);
    _playCurrentItem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Center(
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      'Loading ${widget.channel['name']}...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 18,
                      ),
                    ),
                  ],
                )
              : _playlist.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No content in this channel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.live_tv,
                          color: Colors.white,
                          size: 80,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.channel['name'] ?? 'Virtual Channel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_playlist.length} items in playlist',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
