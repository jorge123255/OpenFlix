import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/storage_service.dart';
import '../services/profile_storage_service.dart';
import '../services/openflix_auth_service.dart';
import '../client/media_client.dart';
import '../config/client_config.dart';
import '../providers/multi_server_provider.dart';
import '../providers/media_client_provider.dart';
import '../utils/app_logger.dart';
import 'main_screen.dart';
import 'add_profile_screen.dart';
import 'auth_screen.dart';
import 'avatar_selection_screen.dart';
import 'first_time_setup_screen.dart';

/// Disney+ style profile selection screen
class ProfileSelectionScreen extends StatefulWidget {
  final String serverUrl;
  final String? serverName;
  final bool manageMode;

  const ProfileSelectionScreen({
    super.key,
    required this.serverUrl,
    this.serverName,
    this.manageMode = false,
  });

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen>
    with TickerProviderStateMixin {
  List<LocalProfile> _profiles = [];
  int _focusedIndex = 0;
  bool _isLoading = true;
  bool _isConnecting = false;
  String? _errorMessage;

  final List<FocusNode> _focusNodes = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);

    try {
      final storage = await ProfileStorageService.getInstance();
      final profiles = storage.getProfiles();

      // If no profiles exist, go directly to create first profile
      if (profiles.isEmpty) {
        setState(() => _isLoading = false);
        _showFirstTimeSetup();
        return;
      }

      // Recreate focus nodes
      for (final node in _focusNodes) {
        node.dispose();
      }
      _focusNodes.clear();
      for (int i = 0; i < profiles.length + 1; i++) {
        _focusNodes.add(FocusNode());
      }

      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });

      // Focus first profile after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusNodes.isNotEmpty) {
          _focusNodes[0].requestFocus();
        }
      });
    } catch (e) {
      appLogger.e('Failed to load profiles', error: e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profiles';
      });
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final totalItems = _profiles.length + 1; // profiles + add button
    final columns = _calculateColumns();

    if (key == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _focusedIndex = (_focusedIndex + 1) % totalItems;
        _focusNodes[_focusedIndex].requestFocus();
      });
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _focusedIndex = (_focusedIndex - 1 + totalItems) % totalItems;
        _focusNodes[_focusedIndex].requestFocus();
      });
    } else if (key == LogicalKeyboardKey.arrowDown) {
      final newIndex = _focusedIndex + columns;
      if (newIndex < totalItems) {
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
    } else if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      // Handle D-pad center/Enter/Space to select
      _handleSelection();
    }
  }

  void _handleSelection() {
    if (_focusedIndex < _profiles.length) {
      if (widget.manageMode) {
        _editProfile(_profiles[_focusedIndex]);
      } else {
        _selectProfile(_profiles[_focusedIndex]);
      }
    } else {
      _addProfile();
    }
  }

  int _calculateColumns() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  Future<void> _selectProfile(LocalProfile profile) async {
    appLogger.i('Profile selected: ${profile.name}');
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Save the active profile
      final profileStorage = await ProfileStorageService.getInstance();
      await profileStorage.setActiveProfile(profile.id);
      appLogger.i('Active profile set, connecting to server...');

      // Connect to the server
      await _connectAndNavigate();
    } catch (e) {
      appLogger.e('Profile selection failed', error: e);
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Failed to select profile';
      });
    }
  }

  Future<void> _connectAndNavigate() async {
    if (!mounted) return;
    appLogger.i('_connectAndNavigate called');

    try {
      final storage = await StorageService.getInstance();

      // Get or create a client identifier
      String? clientId = storage.getClientIdentifier();
      if (clientId == null) {
        clientId = const Uuid().v4();
        await storage.saveClientIdentifier(clientId);
      }

      // Get saved token - if none exists, try without token first (local access)
      String? token = storage.getToken();

      // If token starts with 'local_profile_', it's a placeholder - treat as no token
      if (token != null && token.startsWith('local_profile_')) {
        token = null;
        await storage.clearToken();
      }

      // For local/home access, try connecting without a token first
      // Use empty string as token for anonymous local access
      final useToken = token ?? '';
      appLogger.i('Attempting connection with ${token == null ? "no token (local access)" : "saved token"}');

      // Try to connect - for local servers, this may work without auth
      final success = await _tryConnect(widget.serverUrl, useToken, clientId);

      if (!success && !mounted) return;

      // If connection failed and we didn't have a token, try showing login
      if (!success && (token == null || token.isEmpty)) {
        appLogger.i('Local access failed, showing login dialog');
        final loginResult = await _showLoginDialog();
        if (loginResult != true) {
          setState(() => _isConnecting = false);
          return;
        }

        // Retry with the new token
        final newToken = storage.getToken();
        if (newToken != null && newToken.isNotEmpty) {
          final retrySuccess = await _tryConnect(widget.serverUrl, newToken, clientId);
          if (!retrySuccess) {
            setState(() {
              _isConnecting = false;
              _errorMessage = 'Connection failed. Please try again.';
            });
          }
        }
      } else if (!success) {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Connection failed. Please try again.';
        });
      }
    } catch (e) {
      appLogger.e('Failed to connect after profile selection', error: e);
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Connection failed. Please try again.';
      });
    }
  }

  Future<bool> _tryConnect(String serverUrl, String token, String clientId) async {
    try {
      final config = await ClientConfig.create(
        baseUrl: serverUrl,
        token: token,
        clientIdentifier: clientId,
      );

      final client = MediaClient(
        config,
        serverId: serverUrl,
        serverName: widget.serverName,
      );

      // Test connection
      await client.getLibraries();

      if (!mounted) return false;
      final plexClientProvider = context.read<MediaClientProvider>();
      plexClientProvider.setClient(client);

      final multiServerProvider = context.read<MultiServerProvider>();
      multiServerProvider.serverManager.addDirectClient(
        serverUrl,
        client,
      );

      if (!mounted) return false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(client: client),
        ),
      );
      return true;
    } catch (e) {
      appLogger.e('Connection attempt failed', error: e);
      return false;
    }
  }

  Future<bool?> _showLoginDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Sign In',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your credentials to continue',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final username = usernameController.text.trim();
                      final password = passwordController.text;

                      if (username.isEmpty || password.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Please enter username and password';
                        });
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final authService = OpenFlixAuthService.create(widget.serverUrl);
                        final response = await authService.login(
                          username: username,
                          password: password,
                        );

                        final storage = await StorageService.getInstance();
                        await storage.saveToken(response.token);
                        await storage.saveUserProfile(response.user.toJson());

                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        appLogger.e('Login failed', error: e);
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = 'Login failed. Please check your credentials.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFirstTimeSetup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const FirstTimeSetupScreen(),
      ),
    );

    if (result == true) {
      _loadProfiles();
    }
  }

  Future<void> _addProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProfileScreen(),
      ),
    );

    if (result == true) {
      _loadProfiles();
    }
  }

  Future<void> _editProfile(LocalProfile profile) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProfileScreen(existingProfile: profile),
      ),
    );

    if (result == true) {
      _loadProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    widget.manageMode ? 'Manage Profiles' : "Who's watching?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.manageMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap a profile to edit',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),

                  // Profiles grid
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else if (_isConnecting)
                    const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Connecting...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  else
                    _buildProfilesGrid(),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Manage Profiles / Done button
                  if (widget.manageMode)
                    ElevatedButton(
                      onPressed: () {
                        // Navigate back to regular profile selection
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileSelectionScreen(
                              serverUrl: widget.serverUrl,
                              serverName: widget.serverName,
                              manageMode: false,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () {
                        // Show a bottom sheet with edit options
                        _showManageProfilesSheet();
                      },
                      child: Text(
                        'Manage Profiles',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showManageProfilesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profiles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._profiles.map((profile) {
              final avatar = AvatarData.getAvatarById(profile.avatarId);
              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [avatar.primaryColor, avatar.secondaryColor],
                    ),
                  ),
                  child: Icon(avatar.icon, color: Colors.white, size: 24),
                ),
                title: Text(profile.name, style: const TextStyle(color: Colors.white)),
                subtitle: profile.isKidsProfile
                    ? const Text('Kids Mode', style: TextStyle(color: Colors.blue))
                    : null,
                trailing: const Icon(Icons.edit, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  _editProfile(profile);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesGrid() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 32,
      children: [
        // Profile cards
        for (int i = 0; i < _profiles.length; i++)
          _buildProfileCard(_profiles[i], i),

        // Add Profile card
        _buildAddProfileCard(_profiles.length),
      ],
    );
  }

  Widget _buildProfileCard(LocalProfile profile, int index) {
    final isFocused = _focusedIndex == index;
    final avatar = AvatarData.getAvatarById(profile.avatarId);

    return Focus(
      focusNode: _focusNodes[index],
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          setState(() => _focusedIndex = index);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.manageMode) {
            _editProfile(profile);
          } else {
            _selectProfile(profile);
          }
        },
        onLongPress: () => _editProfile(profile),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = isFocused ? _pulseAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 140,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFocused ? Colors.white : Colors.transparent,
                      width: 4,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [avatar.primaryColor, avatar.secondaryColor],
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: avatar.primaryColor.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      avatar.icon,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  profile.name,
                  style: TextStyle(
                    color: isFocused ? Colors.white : Colors.grey[400],
                    fontSize: 16,
                    fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Kids indicator
                if (profile.isKidsProfile) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'KIDS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddProfileCard(int index) {
    final isFocused = _focusedIndex == index;

    return Focus(
      focusNode: _focusNodes[index],
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          setState(() => _focusedIndex = index);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _addProfile,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = isFocused ? _pulseAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 140,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add icon
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFocused ? Colors.white : Colors.grey[700]!,
                      width: isFocused ? 4 : 2,
                    ),
                    color: Colors.grey[900],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: 64,
                      color: isFocused ? Colors.white : Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Label
                Text(
                  'Add Profile',
                  style: TextStyle(
                    color: isFocused ? Colors.white : Colors.grey[400],
                    fontSize: 16,
                    fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
