import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/openflix_auth_service.dart';
import '../services/server_discovery_service.dart';
import '../services/storage_service.dart';
import '../client/media_client.dart';
import '../config/client_config.dart';
import '../providers/multi_server_provider.dart';
import '../providers/media_client_provider.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import 'main_screen.dart';
import 'profile_selection_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

/// Connection mode for the auth screen
enum ConnectionMode {
  /// Initial mode selection (At Home / Away from Home)
  selection,
  /// At home - auto-discover servers on local network
  atHome,
  /// Away from home - manual server URL entry
  awayFromHome,
}

class _AuthScreenState extends State<AuthScreen> {
  // Connection mode
  ConnectionMode _connectionMode = ConnectionMode.selection;

  // Server discovery
  final ServerDiscoveryService _discoveryService = ServerDiscoveryService();
  List<DiscoveredServer> _discoveredServers = [];
  bool _isDiscovering = false;
  String? _discoveryProgress;

  // Server connection state
  String? _connectedServerUrl;
  String? _serverName;
  bool _isConnectingToServer = false;

  // Auth mode
  bool _isLoginMode = true;
  bool _isAuthenticating = false;
  String? _errorMessage;

  // Form controllers
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  // Form keys
  final _serverFormKey = GlobalKey<FormState>();
  final _authFormKey = GlobalKey<FormState>();

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedServerUrl();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _discoveryService.dispose();
    super.dispose();
  }

  /// Start server discovery on local network
  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredServers = [];
      _discoveryProgress = t.auth.checkingNetwork;
      _errorMessage = null;
    });

    try {
      final servers = await _discoveryService.discoverServers(
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _discoveryProgress = progress;
            });
          }
        },
        onServerFound: (server) {
          if (mounted) {
            setState(() {
              _discoveredServers = [..._discoveredServers, server];
            });

            // Auto-select the first server found immediately
            if (_discoveredServers.length == 1 && _connectedServerUrl == null) {
              // Small delay to show the UI briefly, then auto-connect
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _connectedServerUrl == null) {
                  _selectDiscoveredServer(server);
                }
              });
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _discoveredServers = servers;
          if (servers.isEmpty) {
            _errorMessage = t.auth.noServersFound;
          }
        });
      }
    } catch (e) {
      appLogger.e('Server discovery failed', error: e);
      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = t.auth.discoveryFailed(error: e.toString());
        });
      }
    }
  }

  /// Select a discovered server
  void _selectDiscoveredServer(DiscoveredServer server) {
    _serverUrlController.text = server.url;
    _connectToServerDirect(server.url, server.name);
  }

  /// Connect to server directly without form validation (used by discovery)
  Future<void> _connectToServerDirect(String serverUrl, String serverName) async {
    setState(() {
      _isConnectingToServer = true;
      _errorMessage = null;
    });

    try {
      final authService = OpenFlixAuthService.create(serverUrl);
      final isValid = await authService.testConnection();

      if (!isValid) {
        setState(() {
          _isConnectingToServer = false;
          _errorMessage = t.auth.serverConnectionFailed;
        });
        return;
      }

      // Save the server URL
      final storage = await StorageService.getInstance();
      await storage.saveServerUrl(serverUrl);

      // For "At Home" mode, go directly to profile selection (skip login)
      if (_connectionMode == ConnectionMode.atHome && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSelectionScreen(
              serverUrl: serverUrl,
              serverName: serverName,
            ),
          ),
        );
        return;
      }

      // Fall back to showing login form if profiles not available
      setState(() {
        _isConnectingToServer = false;
        _connectedServerUrl = serverUrl;
        _serverName = serverName;
      });
    } catch (e) {
      appLogger.e('Failed to connect to server', error: e);
      setState(() {
        _isConnectingToServer = false;
        _errorMessage = t.auth.serverConnectionFailed;
      });
    }
  }

  /// Go back to mode selection
  void _goBackToModeSelection() {
    setState(() {
      _connectionMode = ConnectionMode.selection;
      _discoveredServers = [];
      _isDiscovering = false;
      _discoveryProgress = null;
      _errorMessage = null;
    });
  }

  Future<void> _loadSavedServerUrl() async {
    final storage = await StorageService.getInstance();
    final savedUrl = storage.getServerUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _serverUrlController.text = savedUrl;
      // Try to reconnect to saved server - treat as "At Home" for profile selection
      setState(() {
        _connectionMode = ConnectionMode.atHome;
      });
      final serverName = Uri.tryParse(savedUrl)?.host ?? 'Server';
      _connectToServerDirect(savedUrl, serverName);
    }
  }

  Future<void> _connectToServer() async {
    if (!_serverFormKey.currentState!.validate()) return;

    final serverUrl = _serverUrlController.text.trim();

    setState(() {
      _isConnectingToServer = true;
      _errorMessage = null;
    });

    try {
      final authService = OpenFlixAuthService.create(serverUrl);
      final isValid = await authService.testConnection();

      if (!isValid) {
        setState(() {
          _isConnectingToServer = false;
          _errorMessage = t.auth.serverConnectionFailed;
        });
        return;
      }

      // Save the server URL
      final storage = await StorageService.getInstance();
      await storage.saveServerUrl(serverUrl);

      setState(() {
        _isConnectingToServer = false;
        _connectedServerUrl = serverUrl;
        _serverName = Uri.parse(serverUrl).host;
      });
    } catch (e) {
      appLogger.e('Failed to connect to server', error: e);
      setState(() {
        _isConnectingToServer = false;
        _errorMessage = t.auth.serverConnectionFailed;
      });
    }
  }

  void _disconnectServer() {
    setState(() {
      _connectedServerUrl = null;
      _serverName = null;
      _errorMessage = null;
    });
  }

  Future<void> _authenticate() async {
    if (!_authFormKey.currentState!.validate()) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final authService = OpenFlixAuthService.create(_connectedServerUrl!);
      AuthResponse response;

      if (_isLoginMode) {
        response = await authService.login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        response = await authService.register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : null,
        );
      }

      // Save token and user info
      final storage = await StorageService.getInstance();
      await storage.saveToken(response.token);
      await storage.saveUserProfile(response.user.toJson());

      // Create client and navigate
      if (mounted) {
        await _connectAndNavigate(response.token);
      }
    } on AuthException catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      appLogger.e('Authentication failed', error: e);
      setState(() {
        _isAuthenticating = false;
        _errorMessage = t.errors.authenticationFailed(error: e);
      });
    }
  }

  Future<void> _connectAndNavigate(String token) async {
    if (!mounted) return;

    try {
      // Get or create a client identifier
      final storage = await StorageService.getInstance();
      String? clientId = storage.getClientIdentifier();
      if (clientId == null) {
        clientId = const Uuid().v4();
        await storage.saveClientIdentifier(clientId);
      }

      // Create ClientConfig for the OpenFlix server
      final config = await ClientConfig.create(
        baseUrl: _connectedServerUrl!,
        token: token,
        clientIdentifier: clientId,
      );

      // Create Plex client with the OpenFlix server
      final client = MediaClient(
        config,
        serverId: _connectedServerUrl!,
        serverName: _serverName,
      );

      // Test the connection
      await client.getLibraries();

      // Set up providers
      if (!mounted) return;
      final plexClientProvider = context.read<MediaClientProvider>();
      plexClientProvider.setClient(client);

      // Also update multi-server provider
      final multiServerProvider = context.read<MultiServerProvider>();
      multiServerProvider.serverManager.addDirectClient(
        _connectedServerUrl!,
        client,
      );

      // Navigate to main screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(client: client),
        ),
      );
    } catch (e) {
      appLogger.e('Failed to connect to server after auth', error: e);
      setState(() {
        _isAuthenticating = false;
        _errorMessage = t.errors.connectionFailedGeneric;
      });
    }
  }

  String? _validateServerUrl(String? value) {
    if (value == null || value.isEmpty) {
      return t.auth.invalidServerUrl;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return t.auth.invalidServerUrl;
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return t.auth.usernameRequired;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return t.auth.emailRequired;
    }
    // Basic email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return t.auth.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return t.auth.passwordRequired;
    }
    if (value.length < 6) {
      return t.auth.passwordTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return t.auth.passwordMismatch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 800 : 400),
            padding: const EdgeInsets.all(24),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildBranding()),
                      const SizedBox(width: 48),
                      Expanded(child: _buildAuthContent()),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBranding(),
                      const SizedBox(height: 48),
                      _buildAuthContent(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/openflix.png',
          width: 120,
          height: 120,
        ),
        const SizedBox(height: 24),
        Text(
          t.app.title,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthContent() {
    if (_connectedServerUrl != null) {
      return _buildAuthForm();
    }

    switch (_connectionMode) {
      case ConnectionMode.selection:
        return _buildModeSelection();
      case ConnectionMode.atHome:
        return _buildDiscoveryView();
      case ConnectionMode.awayFromHome:
        return _buildServerForm();
    }
  }

  Widget _buildModeSelection() {
    final isTV = PlatformDetector.isTV(context);
    final buttonPadding = isTV
        ? const EdgeInsets.symmetric(vertical: 24, horizontal: 32)
        : const EdgeInsets.symmetric(vertical: 16, horizontal: 24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.auth.howConnecting,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // At Home button
        _FocusableCard(
          onTap: () {
            setState(() {
              _connectionMode = ConnectionMode.atHome;
            });
            _startDiscovery();
          },
          child: Padding(
            padding: buttonPadding,
            child: Row(
              children: [
                Icon(
                  Icons.home,
                  size: isTV ? 48 : 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.auth.atHome,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.auth.atHomeDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Away from Home button
        _FocusableCard(
          onTap: () {
            setState(() {
              _connectionMode = ConnectionMode.awayFromHome;
            });
          },
          child: Padding(
            padding: buttonPadding,
            child: Row(
              children: [
                Icon(
                  Icons.public,
                  size: isTV ? 48 : 40,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.auth.awayFromHome,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.auth.awayFromHomeDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with back button
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBackToModeSelection,
            ),
            Expanded(
              child: Text(
                t.auth.findYourServer,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48), // Balance the back button
          ],
        ),
        const SizedBox(height: 24),

        // Discovery status
        if (_isDiscovering) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(
            _discoveryProgress ?? t.auth.searching,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        // Discovered servers list
        if (_discoveredServers.isNotEmpty) ...[
          Text(
            t.auth.serversFound,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ..._discoveredServers.map((server) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FocusableCard(
              onTap: () => _selectDiscoveredServer(server),
              child: ListTile(
                leading: const Icon(Icons.dns),
                title: Text(server.name),
                subtitle: Text(server.url),
                trailing: Text(
                  '${server.responseTime.inMilliseconds}ms',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          )),
        ],

        // Error message
        if (_errorMessage != null && !_isDiscovering) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        // Retry / Manual entry buttons
        if (!_isDiscovering) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startDiscovery,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.auth.scanAgain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _connectionMode = ConnectionMode.awayFromHome;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(t.auth.enterManually),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildServerForm() {
    return Form(
      key: _serverFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToModeSelection,
              ),
              Expanded(
                child: Text(
                  t.auth.connectToServer,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _serverUrlController,
            decoration: InputDecoration(
              labelText: t.auth.serverUrl,
              hintText: t.auth.serverUrlHint,
              prefixIcon: const Icon(Icons.dns_outlined),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            validator: _validateServerUrl,
            enabled: !_isConnectingToServer,
            onFieldSubmitted: (_) => _connectToServer(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isConnectingToServer ? null : _connectToServer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isConnectingToServer
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(t.auth.connecting),
                    ],
                  )
                : Text(t.auth.connectToServer),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _authFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server info and change button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.auth.serverConnected(serverName: _serverName ?? ''),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _isAuthenticating ? null : _disconnectServer,
                  child: Text(t.auth.changeServer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Login/Register toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeButton(t.auth.signIn, true),
              const SizedBox(width: 16),
              _buildModeButton(t.auth.signUp, false),
            ],
          ),
          const SizedBox(height: 24),

          // Username field
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: t.auth.username,
              hintText: t.auth.usernameHint,
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: _validateUsername,
            enabled: !_isAuthenticating,
          ),
          const SizedBox(height: 16),

          // Email field (only for registration)
          if (!_isLoginMode) ...[
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: t.auth.email,
                hintText: t.auth.emailHint,
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
              enabled: !_isAuthenticating,
            ),
            const SizedBox(height: 16),
          ],

          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: t.auth.password,
              hintText: t.auth.passwordHint,
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: _isLoginMode ? TextInputAction.go : TextInputAction.next,
            validator: _validatePassword,
            enabled: !_isAuthenticating,
            onFieldSubmitted: _isLoginMode ? (_) => _authenticate() : null,
          ),
          const SizedBox(height: 16),

          // Confirm password and display name (only for registration)
          if (!_isLoginMode) ...[
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: t.auth.confirmPassword,
                hintText: t.auth.confirmPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.next,
              validator: _validateConfirmPassword,
              enabled: !_isAuthenticating,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: t.auth.displayName,
                hintText: t.auth.displayNameHint,
                prefixIcon: const Icon(Icons.badge_outlined),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.go,
              enabled: !_isAuthenticating,
              onFieldSubmitted: (_) => _authenticate(),
            ),
            const SizedBox(height: 8),
            Text(
              t.auth.firstUserNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Submit button
          ElevatedButton(
            onPressed: _isAuthenticating ? null : _authenticate,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isAuthenticating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(_isLoginMode ? t.auth.loggingIn : t.auth.registering),
                    ],
                  )
                : Text(_isLoginMode ? t.auth.signIn : t.auth.signUp),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],

          // Toggle login/register link
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLoginMode ? t.auth.noAccount : t.auth.haveAccount,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: _isAuthenticating
                    ? null
                    : () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          _errorMessage = null;
                        });
                      },
                child: Text(_isLoginMode ? t.auth.signUp : t.auth.signIn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, bool isLogin) {
    final isSelected = _isLoginMode == isLogin;
    return InkWell(
      onTap: _isAuthenticating
          ? null
          : () {
              setState(() {
                _isLoginMode = isLogin;
                _errorMessage = null;
              });
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// A card widget that handles focus for TV/keyboard navigation
class _FocusableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _FocusableCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<_FocusableCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: _isFocused
              ? Matrix4.diagonal3Values(1.02, 1.02, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
