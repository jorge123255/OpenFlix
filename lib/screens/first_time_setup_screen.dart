import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/profile_storage_service.dart';
import 'avatar_selection_screen.dart';

/// First-time setup screen for creating the initial profile
class FirstTimeSetupScreen extends StatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  int _selectedAvatarId = 0;
  bool _isKidsProfile = false;
  bool _autoplay = true;
  bool _isSaving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate name
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep++);
        _fadeController.forward();
      });
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep--);
        _fadeController.forward();
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final storage = await ProfileStorageService.getInstance();
      final profile = await storage.createProfile(
        name: _nameController.text.trim(),
        avatarId: _selectedAvatarId,
        isKidsProfile: _isKidsProfile,
        autoplay: _autoplay,
      );

      // Set as active profile
      await storage.setActiveProfile(profile.id);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create profile: $e')),
        );
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _currentStep
                              ? Colors.blue
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCurrentStep(),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _previousStep,
                      child: Text(
                        'Back',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Get Started' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildAvatarStep();
      case 2:
        return _buildSettingsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.waving_hand,
            size: 64,
            color: Colors.amber,
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Let's create your profile.\nWhat should we call you?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              onSubmitted: (_) => _nextStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStep() {
    final avatar = AvatarData.getAvatarById(_selectedAvatarId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose your avatar',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: _selectAvatar,
            child: Stack(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [avatar.primaryColor, avatar.secondaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: avatar.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      avatar.icon,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0D0D0D),
                        width: 4,
                      ),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _selectAvatar,
            child: const Text(
              'Tap to change avatar',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsStep() {
    final avatar = AvatarData.getAvatarById(_selectedAvatarId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Profile preview
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [avatar.primaryColor, avatar.secondaryColor],
              ),
            ),
            child: Center(
              child: Icon(
                avatar.icon,
                size: 48,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Almost done! Customize your experience.',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Settings
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  'Autoplay',
                  'Automatically play next episode',
                  Switch(
                    value: _autoplay,
                    onChanged: (v) => setState(() => _autoplay = v),
                    activeColor: Colors.blue,
                  ),
                ),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                _buildSettingTile(
                  'Kids Mode',
                  'Child-friendly content only',
                  Switch(
                    value: _isKidsProfile,
                    onChanged: (v) => setState(() => _isKidsProfile = v),
                    activeColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
