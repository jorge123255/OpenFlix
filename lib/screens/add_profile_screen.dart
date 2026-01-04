import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'avatar_selection_screen.dart';
import '../services/profile_storage_service.dart';

/// Screen for adding or editing a profile
class AddProfileScreen extends StatefulWidget {
  final LocalProfile? existingProfile;

  const AddProfileScreen({super.key, this.existingProfile});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  int _selectedAvatarId = 0;
  bool _isKidsProfile = false;
  bool _autoplay = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existingProfile != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _nameController.text = widget.existingProfile!.name;
      _selectedAvatarId = widget.existingProfile!.avatarId;
      _isKidsProfile = widget.existingProfile!.isKidsProfile;
      _autoplay = widget.existingProfile!.autoplay;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a profile name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final storage = await ProfileStorageService.getInstance();

      if (_isEditing) {
        await storage.updateProfile(
          widget.existingProfile!.id,
          name: name,
          avatarId: _selectedAvatarId,
          isKidsProfile: _isKidsProfile,
          autoplay: _autoplay,
        );
      } else {
        await storage.createProfile(
          name: name,
          avatarId: _selectedAvatarId,
          isKidsProfile: _isKidsProfile,
          autoplay: _autoplay,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  Future<void> _deleteProfile() async {
    if (!_isEditing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Profile?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${widget.existingProfile!.name}"? This cannot be undone.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await ProfileStorageService.getInstance();
      await storage.deleteProfile(widget.existingProfile!.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _selectAvatar() async {
    final selectedId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarSelectionScreen(
          currentAvatarId: _selectedAvatarId,
        ),
      ),
    );

    if (selectedId != null) {
      setState(() => _selectedAvatarId = selectedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarData.getAvatarById(_selectedAvatarId);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          _isEditing ? 'Edit Profile' : 'Add Profile',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar selection
            GestureDetector(
              onTap: _selectAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [avatar.primaryColor, avatar.secondaryColor],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        avatar.icon,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0D0D0D), width: 3),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile name input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Profile Name',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveProfile(),
              ),
            ),
            const SizedBox(height: 32),

            // Settings section
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'PLAYBACK AND LANGUAGE SETTINGS',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _buildSettingRow(
                    'Autoplay',
                    'Enabling Autoplay allows for the next video in a series to play automatically.',
                    Switch(
                      value: _autoplay,
                      onChanged: (value) => setState(() => _autoplay = value),
                      activeColor: Colors.blue,
                    ),
                  ),
                  const Divider(color: Color(0xFF2A2A2A), height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'PROFILE SETTINGS',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _buildSettingRow(
                    'Kids Mode',
                    'Enable this for a child-friendly experience with restricted content.',
                    Switch(
                      value: _isKidsProfile,
                      onChanged: (value) => setState(() => _isKidsProfile = value),
                      activeColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button for existing profiles
            if (_isEditing) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: _deleteProfile,
                child: const Text(
                  'Delete Profile',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String title, String description, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
