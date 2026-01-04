import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Avatar category with character options
class AvatarCategory {
  final String name;
  final List<AvatarOption> avatars;

  const AvatarCategory({required this.name, required this.avatars});
}

/// Individual avatar option
class AvatarOption {
  final int id;
  final String name;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  const AvatarOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

/// All available avatars organized by category
class AvatarData {
  static const List<AvatarCategory> categories = [
    AvatarCategory(
      name: 'Featured',
      avatars: [
        AvatarOption(id: 0, name: 'Fox', icon: Icons.pets, primaryColor: Color(0xFFFF6B35), secondaryColor: Color(0xFFCC4D1A)),
        AvatarOption(id: 1, name: 'Owl', icon: Icons.nightlight_round, primaryColor: Color(0xFF6B5B95), secondaryColor: Color(0xFF4A3F6B)),
        AvatarOption(id: 2, name: 'Bear', icon: Icons.forest, primaryColor: Color(0xFF8B4513), secondaryColor: Color(0xFF5D2E0A)),
      ],
    ),
    AvatarCategory(
      name: 'Animals',
      avatars: [
        AvatarOption(id: 3, name: 'Penguin', icon: Icons.ac_unit, primaryColor: Color(0xFF2C3E50), secondaryColor: Color(0xFF1A252F)),
        AvatarOption(id: 4, name: 'Cat', icon: Icons.catching_pokemon, primaryColor: Color(0xFFE91E63), secondaryColor: Color(0xFFAD1457)),
        AvatarOption(id: 5, name: 'Dog', icon: Icons.cruelty_free, primaryColor: Color(0xFF4CAF50), secondaryColor: Color(0xFF2E7D32)),
        AvatarOption(id: 6, name: 'Bunny', icon: Icons.grass, primaryColor: Color(0xFFFFB6C1), secondaryColor: Color(0xFFFF69B4)),
        AvatarOption(id: 7, name: 'Bird', icon: Icons.flutter_dash, primaryColor: Color(0xFF03A9F4), secondaryColor: Color(0xFF0288D1)),
        AvatarOption(id: 8, name: 'Fish', icon: Icons.water, primaryColor: Color(0xFF00BCD4), secondaryColor: Color(0xFF0097A7)),
      ],
    ),
    AvatarCategory(
      name: 'Fantasy',
      avatars: [
        AvatarOption(id: 9, name: 'Dragon', icon: Icons.local_fire_department, primaryColor: Color(0xFF9C27B0), secondaryColor: Color(0xFF6A1B9A)),
        AvatarOption(id: 10, name: 'Unicorn', icon: Icons.star, primaryColor: Color(0xFFFF4081), secondaryColor: Color(0xFFC51162)),
        AvatarOption(id: 11, name: 'Wizard', icon: Icons.auto_fix_high, primaryColor: Color(0xFF3F51B5), secondaryColor: Color(0xFF283593)),
        AvatarOption(id: 12, name: 'Fairy', icon: Icons.spa, primaryColor: Color(0xFFE040FB), secondaryColor: Color(0xFFAA00FF)),
      ],
    ),
    AvatarCategory(
      name: 'Space',
      avatars: [
        AvatarOption(id: 13, name: 'Robot', icon: Icons.smart_toy, primaryColor: Color(0xFF00BCD4), secondaryColor: Color(0xFF0097A7)),
        AvatarOption(id: 14, name: 'Alien', icon: Icons.rocket_launch, primaryColor: Color(0xFF7CB342), secondaryColor: Color(0xFF558B2F)),
        AvatarOption(id: 15, name: 'Astronaut', icon: Icons.public, primaryColor: Color(0xFF607D8B), secondaryColor: Color(0xFF455A64)),
        AvatarOption(id: 16, name: 'UFO', icon: Icons.blur_circular, primaryColor: Color(0xFF8BC34A), secondaryColor: Color(0xFF689F38)),
      ],
    ),
    AvatarCategory(
      name: 'Sports',
      avatars: [
        AvatarOption(id: 17, name: 'Soccer', icon: Icons.sports_soccer, primaryColor: Color(0xFF4CAF50), secondaryColor: Color(0xFF388E3C)),
        AvatarOption(id: 18, name: 'Basketball', icon: Icons.sports_basketball, primaryColor: Color(0xFFFF9800), secondaryColor: Color(0xFFF57C00)),
        AvatarOption(id: 19, name: 'Tennis', icon: Icons.sports_tennis, primaryColor: Color(0xFFCDDC39), secondaryColor: Color(0xFFAFB42B)),
      ],
    ),
    AvatarCategory(
      name: 'Nature',
      avatars: [
        AvatarOption(id: 20, name: 'Mountain', icon: Icons.landscape, primaryColor: Color(0xFF795548), secondaryColor: Color(0xFF5D4037)),
        AvatarOption(id: 21, name: 'Ocean', icon: Icons.waves, primaryColor: Color(0xFF2196F3), secondaryColor: Color(0xFF1976D2)),
        AvatarOption(id: 22, name: 'Sun', icon: Icons.wb_sunny, primaryColor: Color(0xFFFFEB3B), secondaryColor: Color(0xFFFBC02D)),
        AvatarOption(id: 23, name: 'Moon', icon: Icons.dark_mode, primaryColor: Color(0xFF9E9E9E), secondaryColor: Color(0xFF616161)),
        AvatarOption(id: 24, name: 'Flower', icon: Icons.local_florist, primaryColor: Color(0xFFE91E63), secondaryColor: Color(0xFFC2185B)),
      ],
    ),
  ];

  static AvatarOption getAvatarById(int id) {
    for (final category in categories) {
      for (final avatar in category.avatars) {
        if (avatar.id == id) return avatar;
      }
    }
    return categories.first.avatars.first;
  }
}

/// Disney+ style avatar selection screen
class AvatarSelectionScreen extends StatefulWidget {
  final int? currentAvatarId;

  const AvatarSelectionScreen({super.key, this.currentAvatarId});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  int? _selectedAvatarId;
  int _focusedIndex = 0;
  final List<FocusNode> _focusNodes = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.currentAvatarId;

    // Create focus nodes for all avatars
    int totalAvatars = 0;
    for (final category in AvatarData.categories) {
      totalAvatars += category.avatars.length;
    }
    for (int i = 0; i < totalAvatars; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  int _getTotalAvatarCount() {
    int count = 0;
    for (final category in AvatarData.categories) {
      count += category.avatars.length;
    }
    return count;
  }

  AvatarOption _getAvatarAtIndex(int index) {
    int count = 0;
    for (final category in AvatarData.categories) {
      if (index < count + category.avatars.length) {
        return category.avatars[index - count];
      }
      count += category.avatars.length;
    }
    return AvatarData.categories.first.avatars.first;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final totalAvatars = _getTotalAvatarCount();
    const columns = 3;

    if (key == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _focusedIndex = (_focusedIndex + 1) % totalAvatars;
        _focusNodes[_focusedIndex].requestFocus();
      });
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _focusedIndex = (_focusedIndex - 1 + totalAvatars) % totalAvatars;
        _focusNodes[_focusedIndex].requestFocus();
      });
    } else if (key == LogicalKeyboardKey.arrowDown) {
      final newIndex = _focusedIndex + columns;
      if (newIndex < totalAvatars) {
        setState(() {
          _focusedIndex = newIndex;
          _focusNodes[_focusedIndex].requestFocus();
        });
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      final newIndex = _focusedIndex - columns;
      if (newIndex >= 0) {
        setState(() {
          _focusedIndex = newIndex;
          _focusNodes[_focusedIndex].requestFocus();
        });
      }
    } else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      final avatar = _getAvatarAtIndex(_focusedIndex);
      _selectAvatar(avatar);
    }
  }

  void _selectAvatar(AvatarOption avatar) {
    setState(() {
      _selectedAvatarId = avatar.id;
    });
    Navigator.pop(context, avatar.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Avatar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: AvatarData.categories.length,
          itemBuilder: (context, categoryIndex) {
            final category = AvatarData.categories[categoryIndex];
            int startIndex = 0;
            for (int i = 0; i < categoryIndex; i++) {
              startIndex += AvatarData.categories[i].avatars.length;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 8),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: category.avatars.asMap().entries.map((entry) {
                    final avatarIndex = startIndex + entry.key;
                    final avatar = entry.value;
                    final isFocused = _focusedIndex == avatarIndex;
                    final isSelected = _selectedAvatarId == avatar.id;

                    return Focus(
                      focusNode: _focusNodes[avatarIndex],
                      onFocusChange: (hasFocus) {
                        if (hasFocus) {
                          setState(() => _focusedIndex = avatarIndex);
                        }
                      },
                      child: GestureDetector(
                        onTap: () => _selectAvatar(avatar),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [avatar.primaryColor, avatar.secondaryColor],
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : isFocused
                                      ? Colors.white
                                      : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: avatar.primaryColor.withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              avatar.icon,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
