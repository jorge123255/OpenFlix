import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.g.dart';
import 'main_screen.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/keyboard_shortcuts_service.dart';
import '../services/openflix_auth_service.dart';
import '../services/remote_access_service.dart';
import '../services/settings_service.dart' as settings;
import '../services/storage_service.dart';
import '../services/update_service.dart';
import '../utils/app_logger.dart';
import '../utils/keyboard_utils.dart';
import '../utils/content_rating_filter.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/hotkey_recorder_widget.dart';
import '../widgets/pin_entry_dialog.dart';
import 'about_screen.dart';
import 'logs_screen.dart';
import 'subtitle_styling_screen.dart';
import 'profile_selection_screen.dart';
import 'avatar_selection_screen.dart';
import '../services/profile_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late settings.SettingsService _settingsService;
  late KeyboardShortcutsService _keyboardService;
  bool _isLoading = true;

  bool _enableDebugLogging = false;
  bool _enableHardwareDecoding = true;
  int _bufferSize = 128;
  int _seekTimeSmall = 10;
  int _seekTimeLarge = 30;
  int _sleepTimerDuration = 30;
  bool _rememberTrackSelections = true;
  bool _autoSkipIntro = true;
  bool _autoSkipCredits = true;
  int _autoSkipDelay = 5;
  String? _tmdbApiKey;
  bool _parentalControlsEnabled = false;
  bool _kidsModeEnabled = false;
  String _maxMovieRating = 'NC-17';
  String _maxTvRating = 'TV-MA';

  // Home screen settings
  String _startupBehavior = settings.SettingsService.startupBehaviorHome;
  bool _dockedPlayerEnabled = true;
  bool _dockedPlayerAutoMute = true;

  // Update checking state
  bool _isCheckingForUpdate = false;
  Map<String, dynamic>? _updateInfo;

  // Remote access state
  RemoteAccessStatus? _remoteAccessStatus;
  bool _isLoadingRemoteAccess = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await settings.SettingsService.getInstance();
    _keyboardService = await KeyboardShortcutsService.getInstance();

    setState(() {
      _enableDebugLogging = _settingsService.getEnableDebugLogging();
      _enableHardwareDecoding = _settingsService.getEnableHardwareDecoding();
      _bufferSize = _settingsService.getBufferSize();
      _seekTimeSmall = _settingsService.getSeekTimeSmall();
      _seekTimeLarge = _settingsService.getSeekTimeLarge();
      _sleepTimerDuration = _settingsService.getSleepTimerDuration();
      _rememberTrackSelections = _settingsService.getRememberTrackSelections();
      _autoSkipIntro = _settingsService.getAutoSkipIntro();
      _autoSkipCredits = _settingsService.getAutoSkipCredits();
      _autoSkipDelay = _settingsService.getAutoSkipDelay();
      _tmdbApiKey = _settingsService.getTmdbApiKey();
      _parentalControlsEnabled = _settingsService.getParentalControlsEnabled();
      _kidsModeEnabled = _settingsService.getKidsModeEnabled();
      _maxMovieRating = _settingsService.getMaxMovieRating();
      _maxTvRating = _settingsService.getMaxTvRating();
      _startupBehavior = _settingsService.getStartupBehavior();
      _dockedPlayerEnabled = _settingsService.getDockedPlayerEnabled();
      _dockedPlayerAutoMute = _settingsService.getDockedPlayerAutoMute();
      _isLoading = false;
    });

    // Load remote access status in background
    _loadRemoteAccessStatus();
  }

  Future<void> _loadRemoteAccessStatus() async {
    try {
      final storageService = await StorageService.getInstance();
      final serverUrl = storageService.getServerUrl();
      final token = storageService.getToken();

      if (serverUrl == null || token == null) return;

      setState(() {
        _isLoadingRemoteAccess = true;
      });

      final remoteAccessService = RemoteAccessService(
        baseUrl: serverUrl,
        token: token,
      );

      final status = await remoteAccessService.getStatus();

      if (mounted) {
        setState(() {
          _remoteAccessStatus = status;
          _isLoadingRemoteAccess = false;
        });
      }
    } catch (e) {
      appLogger.d('Remote access status not available: $e');
      if (mounted) {
        setState(() {
          _isLoadingRemoteAccess = false;
        });
      }
    }
  }

  /// Handle back key press - focus bottom navigation
  KeyEventResult _handleBackKey(FocusNode node, KeyEvent event) {
    if (isBackKeyEvent(event)) {
      BackNavigationScope.of(context)?.focusBottomNav();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Focus(
        onKeyEvent: _handleBackKey,
        child: CustomScrollView(
          slivers: [
            CustomAppBar(title: Text(t.settings.title), pinned: true),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileSection(),
                  const SizedBox(height: 24),
                  _buildHomeScreenSection(),
                  const SizedBox(height: 24),
                  _buildAppearanceSection(),
                  const SizedBox(height: 24),
                  _buildVideoPlaybackSection(),
                  const SizedBox(height: 24),
                  _buildKeyboardShortcutsSection(),
                  const SizedBox(height: 24),
                  _buildParentalControlsSection(),
                  const SizedBox(height: 24),
                  _buildAdvancedSection(),
                  const SizedBox(height: 24),
                  _buildRemoteAccessSection(),
                  const SizedBox(height: 24),
                  if (UpdateService.isUpdateCheckEnabled) ...[
                    _buildUpdateSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return FutureBuilder<ProfileStorageService>(
      future: ProfileStorageService.getInstance(),
      builder: (context, snapshot) {
        final activeProfile = snapshot.data?.getActiveProfile();
        final avatarData = activeProfile != null
            ? AvatarData.getAvatarById(activeProfile.avatarId)
            : null;

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t.settings.profile,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Current profile display
              ListTile(
                leading: activeProfile != null && avatarData != null
                    ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              avatarData.primaryColor,
                              avatarData.secondaryColor,
                            ],
                          ),
                        ),
                        child: Icon(
                          avatarData.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(activeProfile?.name ?? t.settings.noProfileSelected),
                subtitle: activeProfile?.isKidsProfile == true
                    ? Text(t.settings.kidsMode)
                    : null,
              ),
              const Divider(height: 1),
              // Switch Profile option
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text(t.settings.switchProfile),
                subtitle: Text(t.settings.switchProfileDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _switchProfile(),
              ),
              // Manage Profiles option
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: Text(t.settings.manageProfiles),
                subtitle: Text(t.settings.manageProfilesDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _manageProfiles(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchProfile() async {
    final storage = await StorageService.getInstance();
    final serverUrl = storage.getServerUrl();

    if (serverUrl != null && mounted) {
      // Clear the navigation stack and go to profile selection
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ProfileSelectionScreen(
            serverUrl: serverUrl,
            serverName: Uri.tryParse(serverUrl)?.host,
          ),
        ),
        (route) => false, // Remove all routes
      );
    }
  }

  Future<void> _manageProfiles() async {
    final storage = await StorageService.getInstance();
    final serverUrl = storage.getServerUrl();

    if (serverUrl != null && mounted) {
      // Navigate to profile selection in manage mode
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ProfileSelectionScreen(
            serverUrl: serverUrl,
            serverName: Uri.tryParse(serverUrl)?.host,
            manageMode: true,
          ),
        ),
        (route) => false, // Remove all routes
      );
    }
  }

  Widget _buildHomeScreenSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Home Screen',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Startup Behavior'),
            subtitle: Text(
              _startupBehavior == settings.SettingsService.startupBehaviorLastChannel
                  ? 'Start on last watched channel'
                  : 'Start on home screen',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStartupBehaviorDialog(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.picture_in_picture),
            title: const Text('Docked Player'),
            subtitle: const Text('Show mini player on home screen with last watched channel'),
            value: _dockedPlayerEnabled,
            onChanged: (value) async {
              setState(() {
                _dockedPlayerEnabled = value;
              });
              await _settingsService.setDockedPlayerEnabled(value);
            },
          ),
          if (_dockedPlayerEnabled)
            SwitchListTile(
              secondary: const Icon(Icons.volume_off),
              title: const Text('Auto-mute Docked Player'),
              subtitle: const Text('Start docked player muted (tap to unmute)'),
              value: _dockedPlayerAutoMute,
              onChanged: (value) async {
                setState(() {
                  _dockedPlayerAutoMute = value;
                });
                await _settingsService.setDockedPlayerAutoMute(value);
              },
            ),
        ],
      ),
    );
  }

  void _showStartupBehaviorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Startup Behavior'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Home Screen'),
                subtitle: const Text('Start on the home menu screen'),
                value: settings.SettingsService.startupBehaviorHome,
                groupValue: _startupBehavior,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _startupBehavior = value;
                    });
                    await _settingsService.setStartupBehavior(value);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Last Watched Channel'),
                subtitle: const Text('Start on the last channel you were watching'),
                value: settings.SettingsService.startupBehaviorLastChannel,
                groupValue: _startupBehavior,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _startupBehavior = value;
                    });
                    await _settingsService.setStartupBehavior(value);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.appearance,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: Icon(themeProvider.themeModeIcon),
                title: Text(t.settings.theme),
                subtitle: Text(themeProvider.themeModeDisplayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(themeProvider),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t.settings.language),
            subtitle: Text(
              _getLanguageDisplayName(LocaleSettings.currentLocale),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
                leading: const Icon(Icons.grid_view),
                title: Text(t.settings.libraryDensity),
                subtitle: Text(settingsProvider.libraryDensityDisplayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLibraryDensityDialog(),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
                leading: const Icon(Icons.view_list),
                title: Text(t.settings.viewMode),
                subtitle: Text(
                  settingsProvider.viewMode == settings.ViewMode.grid
                      ? t.settings.gridView
                      : t.settings.listView,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showViewModeDialog(),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.image),
                title: Text(t.settings.useSeasonPosters),
                subtitle: Text(t.settings.useSeasonPostersDescription),
                value: settingsProvider.useSeasonPoster,
                onChanged: (value) async {
                  await settingsProvider.setUseSeasonPoster(value);
                },
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.featured_play_list),
                title: Text(t.settings.showHeroSection),
                subtitle: Text(t.settings.showHeroSectionDescription),
                value: settingsProvider.showHeroSection,
                onChanged: (value) async {
                  await settingsProvider.setShowHeroSection(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaybackSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.videoPlayback,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.hardware),
            title: Text(t.settings.hardwareDecoding),
            subtitle: Text(t.settings.hardwareDecodingDescription),
            value: _enableHardwareDecoding,
            onChanged: (value) async {
              setState(() {
                _enableHardwareDecoding = value;
              });
              await _settingsService.setEnableHardwareDecoding(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: Text(t.settings.bufferSize),
            subtitle: Text(
              t.settings.bufferSizeMB(size: _bufferSize.toString()),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBufferSizeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.subtitles),
            title: Text(t.settings.subtitleStyling),
            subtitle: Text(t.settings.subtitleStylingDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubtitleStylingScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.replay_10),
            title: Text(t.settings.smallSkipDuration),
            subtitle: Text(
              t.settings.secondsUnit(seconds: _seekTimeSmall.toString()),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSeekTimeSmallDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.replay_30),
            title: Text(t.settings.largeSkipDuration),
            subtitle: Text(
              t.settings.secondsUnit(seconds: _seekTimeLarge.toString()),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSeekTimeLargeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.bedtime),
            title: Text(t.settings.defaultSleepTimer),
            subtitle: Text(
              t.settings.minutesUnit(minutes: _sleepTimerDuration.toString()),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSleepTimerDurationDialog(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bookmark),
            title: Text(t.settings.rememberTrackSelections),
            subtitle: Text(t.settings.rememberTrackSelectionsDescription),
            value: _rememberTrackSelections,
            onChanged: (value) async {
              setState(() {
                _rememberTrackSelections = value;
              });
              await _settingsService.setRememberTrackSelections(value);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              t.settings.autoSkip,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fast_forward),
            title: Text(t.settings.autoSkipIntro),
            subtitle: Text(t.settings.autoSkipIntroDescription),
            value: _autoSkipIntro,
            onChanged: (value) async {
              setState(() {
                _autoSkipIntro = value;
              });
              await _settingsService.setAutoSkipIntro(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.skip_next),
            title: Text(t.settings.autoSkipCredits),
            subtitle: Text(t.settings.autoSkipCreditsDescription),
            value: _autoSkipCredits,
            onChanged: (value) async {
              setState(() {
                _autoSkipCredits = value;
              });
              await _settingsService.setAutoSkipCredits(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text(t.settings.autoSkipDelay),
            subtitle: Text(
              t.settings.autoSkipDelayDescription(
                seconds: _autoSkipDelay.toString(),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAutoSkipDelayDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardShortcutsSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.keyboardShortcuts,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.keyboard),
            title: Text(t.settings.videoPlayerControls),
            subtitle: Text(t.settings.keyboardShortcutsDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showKeyboardShortcutsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildParentalControlsSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.parentalControls,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: Icon(
              Icons.child_care,
              color: _kidsModeEnabled ? Colors.pink : null,
            ),
            title: Text(t.settings.kidsMode),
            subtitle: Text(t.settings.kidsModeDescription),
            value: _kidsModeEnabled,
            onChanged: (value) async {
              setState(() {
                _kidsModeEnabled = value;
                if (value) {
                  // Kids mode auto-sets ratings and enables parental controls
                  _parentalControlsEnabled = true;
                  _maxMovieRating = 'PG';
                  _maxTvRating = 'TV-Y7';
                }
              });
              await _settingsService.setKidsModeEnabled(value);
              if (value) {
                await _settingsService.setParentalControlsEnabled(true);
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.lock),
            title: Text(t.settings.enableParentalControls),
            subtitle: Text(t.settings.enableParentalControlsDescription),
            value: _parentalControlsEnabled,
            onChanged: (value) async {
              if (value) {
                // Enabling - require PIN setup
                _showSetPinDialog();
              } else {
                // Disabling - require current PIN
                final pin = _settingsService.getParentalControlsPin();
                if (pin != null) {
                  _showVerifyPinDialog(() async {
                    setState(() {
                      _parentalControlsEnabled = false;
                    });
                    await _settingsService.setParentalControlsEnabled(false);
                    await _settingsService.setParentalControlsPin(null);
                  });
                } else {
                  setState(() {
                    _parentalControlsEnabled = false;
                  });
                  await _settingsService.setParentalControlsEnabled(false);
                }
              }
            },
          ),
          if (_parentalControlsEnabled) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.pin),
              title: Text(t.settings.changePin),
              subtitle: Text(t.settings.changePinDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePinDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.movie),
              title: Text(t.settings.maxMovieRating),
              subtitle: Text(getMovieRatingDisplayName(_maxMovieRating)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showMovieRatingDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.tv),
              title: Text(t.settings.maxTvRating),
              subtitle: Text(getTvRatingDisplayName(_maxTvRating)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTvRatingDialog(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.advanced,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bug_report),
            title: Text(t.settings.debugLogging),
            subtitle: Text(t.settings.debugLoggingDescription),
            value: _enableDebugLogging,
            onChanged: (value) async {
              setState(() {
                _enableDebugLogging = value;
              });
              await _settingsService.setEnableDebugLogging(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: Text(t.settings.viewLogs),
            subtitle: Text(t.settings.viewLogsDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Send Logs to Server'),
            subtitle: const Text('Upload logs for remote troubleshooting'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _sendLogsToServer(),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: Text(t.settings.clearCache),
            subtitle: Text(t.settings.clearCacheDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearCacheDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(t.settings.resetSettings),
            subtitle: Text(t.settings.resetSettingsDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showResetSettingsDialog(),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              t.settings.metadataSection,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.movie),
            title: Text(t.settings.tmdbApiKey),
            subtitle: Text(
              _tmdbApiKey != null && _tmdbApiKey!.isNotEmpty
                  ? t.settings.tmdbApiKeyConfigured
                  : t.settings.tmdbApiKeyDescription,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTmdbApiKeyDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteAccessSection() {
    final status = _remoteAccessStatus;
    final isConnected = status?.isConnected ?? false;
    final isInstalled = status?.isInstalled ?? false;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  t.settings.remoteAccess,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoadingRemoteAccess)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              isConnected
                  ? Icons.cloud_done
                  : isInstalled
                      ? Icons.cloud_off
                      : Icons.cloud_queue,
              color: isConnected ? Colors.green : null,
            ),
            title: Text(t.settings.tailscaleStatus),
            subtitle: Text(
              status?.statusText ?? t.settings.remoteAccessCheckingStatus,
            ),
            trailing: _isLoadingRemoteAccess
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadRemoteAccessStatus,
                    tooltip: t.settings.refreshStatus,
                  ),
          ),
          if (isConnected && status?.tailscaleUrl != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(t.settings.remoteUrl),
              subtitle: Text(
                status!.tailscaleUrl!,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyRemoteUrl(status.tailscaleUrl!),
                tooltip: t.settings.copyUrl,
              ),
            ),
          ],
          if (isConnected && status?.tailscaleIp != null) ...[
            ListTile(
              leading: const Icon(Icons.computer),
              title: Text(t.settings.tailscaleIp),
              subtitle: Text(status!.tailscaleIp!),
            ),
          ],
          if (!isInstalled) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.settings.tailscaleNotInstalled,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.settings.tailscaleDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
          if (status?.needsLogin == true) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.login, color: Colors.orange),
              title: Text(t.settings.tailscaleNeedsLogin),
              subtitle: Text(t.settings.tailscaleNeedsLoginDescription),
            ),
          ],
        ],
      ),
    );
  }

  void _copyRemoteUrl(String url) {
    // Copy to clipboard functionality would be added here
    // For now just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.settings.urlCopied)),
    );
  }

  Widget _buildUpdateSection() {
    final hasUpdate = _updateInfo != null && _updateInfo!['hasUpdate'] == true;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.updates,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(
              hasUpdate ? Icons.system_update : Icons.check_circle,
              color: hasUpdate ? Colors.orange : null,
            ),
            title: Text(
              hasUpdate
                  ? t.settings.updateAvailable
                  : t.settings.checkForUpdates,
            ),
            subtitle: hasUpdate
                ? Text(
                    t.update.versionAvailable(
                      version: _updateInfo!['latestVersion'],
                    ),
                  )
                : Text(t.update.checkFailed),
            trailing: _isCheckingForUpdate
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isCheckingForUpdate
                ? null
                : () {
                    if (hasUpdate) {
                      _showUpdateDialog();
                    } else {
                      _checkForUpdates();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info),
        title: Text(t.settings.about),
        subtitle: Text(t.settings.aboutDescription),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        },
      ),
    );
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.theme),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  themeProvider.themeMode == settings.ThemeMode.system
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(t.settings.systemTheme),
                subtitle: Text(t.settings.systemThemeDescription),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  themeProvider.themeMode == settings.ThemeMode.light
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(t.settings.lightTheme),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  themeProvider.themeMode == settings.ThemeMode.dark
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(t.settings.darkTheme),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showBufferSizeDialog() {
    final options = [64, 128, 256, 512, 1024];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.bufferSize),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((size) {
              return ListTile(
                leading: Icon(
                  _bufferSize == size
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text('${size}MB'),
                onTap: () {
                  setState(() {
                    _bufferSize = size;
                    _settingsService.setBufferSize(size);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showSeekTimeSmallDialog() {
    final controller = TextEditingController(text: _seekTimeSmall.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.settings.smallSkipDuration),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.settings.secondsLabel,
                  hintText: t.settings.durationHint(min: 1, max: 120),
                  errorText: errorText,
                  suffixText: t.settings.secondsShort,
                ),
                autofocus: true,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setDialogState(() {
                    if (parsed == null) {
                      errorText = t.settings.validationErrorEnterNumber;
                    } else if (parsed < 1 || parsed > 120) {
                      errorText = t.settings.validationErrorDuration(
                        min: 1,
                        max: 120,
                        unit: t.settings.secondsLabel.toLowerCase(),
                      );
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t.common.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed >= 1 && parsed <= 120) {
                      setState(() {
                        _seekTimeSmall = parsed;
                        _settingsService.setSeekTimeSmall(parsed);
                      });
                      // Reload keyboard shortcuts service to use new settings
                      await _keyboardService.refreshFromStorage();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSeekTimeLargeDialog() {
    final controller = TextEditingController(text: _seekTimeLarge.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.settings.largeSkipDuration),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.settings.secondsLabel,
                  hintText: t.settings.durationHint(min: 1, max: 120),
                  errorText: errorText,
                  suffixText: t.settings.secondsShort,
                ),
                autofocus: true,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setDialogState(() {
                    if (parsed == null) {
                      errorText = t.settings.validationErrorEnterNumber;
                    } else if (parsed < 1 || parsed > 120) {
                      errorText = t.settings.validationErrorDuration(
                        min: 1,
                        max: 120,
                        unit: t.settings.secondsLabel.toLowerCase(),
                      );
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t.common.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed >= 1 && parsed <= 120) {
                      setState(() {
                        _seekTimeLarge = parsed;
                        _settingsService.setSeekTimeLarge(parsed);
                      });
                      // Reload keyboard shortcuts service to use new settings
                      await _keyboardService.refreshFromStorage();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSleepTimerDurationDialog() {
    final controller = TextEditingController(
      text: _sleepTimerDuration.toString(),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.settings.defaultSleepTimer),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.settings.minutesLabel,
                  hintText: t.settings.durationHint(min: 5, max: 240),
                  errorText: errorText,
                  suffixText: t.settings.minutesShort,
                ),
                autofocus: true,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setDialogState(() {
                    if (parsed == null) {
                      errorText = t.settings.validationErrorEnterNumber;
                    } else if (parsed < 5 || parsed > 240) {
                      errorText = t.settings.validationErrorDuration(
                        min: 5,
                        max: 240,
                        unit: t.settings.minutesLabel.toLowerCase(),
                      );
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t.common.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed >= 5 && parsed <= 240) {
                      setState(() {
                        _sleepTimerDuration = parsed;
                      });
                      await _settingsService.setSleepTimerDuration(parsed);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAutoSkipDelayDialog() {
    final controller = TextEditingController(text: _autoSkipDelay.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.settings.autoSkipDelay),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.settings.secondsLabel,
                  hintText: t.settings.durationHint(min: 1, max: 30),
                  errorText: errorText,
                  suffixText: t.settings.secondsShort,
                ),
                autofocus: true,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setDialogState(() {
                    if (parsed == null) {
                      errorText = t.settings.validationErrorEnterNumber;
                    } else if (parsed < 1 || parsed > 30) {
                      errorText = t.settings.validationErrorDuration(
                        min: 1,
                        max: 30,
                        unit: t.settings.secondsLabel.toLowerCase(),
                      );
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t.common.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed >= 1 && parsed <= 30) {
                      setState(() {
                        _autoSkipDelay = parsed;
                      });
                      await _settingsService.setAutoSkipDelay(parsed);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showKeyboardShortcutsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _KeyboardShortcutsScreen(keyboardService: _keyboardService),
      ),
    );
  }

  Future<void> _sendLogsToServer() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending logs to server...'),
          ],
        ),
      ),
    );

    try {
      // Get server URL and auth token from storage
      final storage = await StorageService.getInstance();
      final serverUrl = storage.getServerUrl();
      final token = storage.getToken();

      if (serverUrl == null || token == null) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not connected to a server')),
          );
        }
        return;
      }

      final success = await sendLogsToServer(
        serverUrl: serverUrl,
        authToken: token,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Logs sent successfully'
                : 'Failed to send logs'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.clearCache),
          content: Text(t.settings.clearCacheDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await _settingsService.clearCache();
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.settings.clearCacheSuccess)),
                  );
                }
              },
              child: Text(t.common.clear),
            ),
          ],
        );
      },
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.resetSettings),
          content: Text(t.settings.resetSettingsDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await _settingsService.resetAllSettings();
                await _keyboardService.resetToDefaults();
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.settings.resetSettingsSuccess)),
                  );
                  // Reload settings
                  _loadSettings();
                }
              },
              child: Text(t.common.reset),
            ),
          ],
        );
      },
    );
  }

  void _showTmdbApiKeyDialog() {
    final controller = TextEditingController(text: _tmdbApiKey ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(t.settings.tmdbApiKey),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.settings.tmdbApiKeyHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: t.settings.apiKey,
                  hintText: t.settings.tmdbApiKeyPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            if (_tmdbApiKey != null && _tmdbApiKey!.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  await _settingsService.setTmdbApiKey(null);
                  await _updateServerTmdbApiKey('');
                  setState(() {
                    _tmdbApiKey = null;
                  });
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.settings.tmdbApiKeyCleared)),
                  );
                },
                child: Text(t.common.clear),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(dialogContext);
                final apiKey = controller.text.trim();
                await _settingsService.setTmdbApiKey(
                  apiKey.isEmpty ? null : apiKey,
                );
                if (apiKey.isNotEmpty) {
                  await _updateServerTmdbApiKey(apiKey);
                }
                setState(() {
                  _tmdbApiKey = apiKey.isEmpty ? null : apiKey;
                });
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(t.settings.tmdbApiKeySaved)),
                );
              },
              child: Text(t.common.save),
            ),
          ],
        );
      },
    );
  }

  /// Sends the TMDB API key to the server for metadata fetching
  Future<void> _updateServerTmdbApiKey(String apiKey) async {
    try {
      final storageService = await StorageService.getInstance();
      final serverUrl = storageService.getServerUrl();
      final token = storageService.getToken();

      if (serverUrl == null || token == null) {
        appLogger.w('Cannot update server TMDB key: no server connection');
        return;
      }

      final adminService = OpenFlixAdminService.create(serverUrl, token);
      await adminService.updateSettings(
        ServerSettings(tmdbApiKey: apiKey.isEmpty ? '' : apiKey),
      );
      appLogger.i('TMDB API key updated on server');
    } catch (e) {
      appLogger.w('Failed to update TMDB API key on server', error: e);
      // Don't throw - the local save still succeeded
    }
  }

  String _getLanguageDisplayName(AppLocale locale) {
    switch (locale) {
      case AppLocale.en:
        return 'English';
      case AppLocale.sv:
        return 'Svenska';
      case AppLocale.it:
        return 'Italiano';
      case AppLocale.nl:
        return 'Nederlands';
      case AppLocale.de:
        return 'Deutsch';
      case AppLocale.zh:
        return '中文';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLocale.values.map((locale) {
              final isSelected = LocaleSettings.currentLocale == locale;
              return ListTile(
                title: Text(_getLanguageDisplayName(locale)),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tileColor: isSelected
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
                onTap: () async {
                  // Save the locale to settings
                  await _settingsService.setAppLocale(locale);

                  // Set the locale immediately
                  LocaleSettings.setLocale(locale);

                  // Close dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  // Trigger app-wide rebuild by restarting the app
                  if (context.mounted) {
                    _restartApp();
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            ),
          ],
        );
      },
    );
  }

  void _restartApp() {
    // Navigate to the root and remove all previous routes
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _showSetPinDialog() async {
    final pin = await showPinEntryDialog(
      context,
      t.settings.setPin,
    );
    if (pin != null && mounted) {
      _showConfirmPinDialog(pin);
    }
  }

  Future<void> _showConfirmPinDialog(String originalPin) async {
    final confirmPin = await showPinEntryDialog(
      context,
      t.settings.confirmPin,
    );
    if (!mounted) return;

    if (confirmPin == originalPin) {
      await _settingsService.setParentalControlsPin(originalPin);
      await _settingsService.setParentalControlsEnabled(true);
      setState(() {
        _parentalControlsEnabled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.settings.pinSet)),
      );
    } else if (confirmPin != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.settings.pinMismatch)),
      );
    }
  }

  Future<void> _showVerifyPinDialog(VoidCallback onSuccess) async {
    final pin = await showPinEntryDialog(
      context,
      t.settings.enterPin,
    );
    if (!mounted) return;

    if (pin != null && _settingsService.verifyParentalPin(pin)) {
      onSuccess();
    } else if (pin != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.settings.incorrectPin)),
      );
    }
  }

  void _showChangePinDialog() {
    _showVerifyPinDialog(() {
      _showSetPinDialog();
    });
  }

  void _showMovieRatingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(t.settings.maxMovieRating),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: movieRatings.map((rating) {
              return ListTile(
                leading: Icon(
                  _maxMovieRating == rating
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(getMovieRatingDisplayName(rating)),
                onTap: () async {
                  setState(() {
                    _maxMovieRating = rating;
                  });
                  await _settingsService.setMaxMovieRating(rating);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.common.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showTvRatingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(t.settings.maxTvRating),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: tvRatings.map((rating) {
              return ListTile(
                leading: Icon(
                  _maxTvRating == rating
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(getTvRatingDisplayName(rating)),
                onTap: () async {
                  setState(() {
                    _maxTvRating = rating;
                  });
                  await _settingsService.setMaxTvRating(rating);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.common.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdate = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdates();

      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _isCheckingForUpdate = false;
        });

        if (updateInfo == null || updateInfo['hasUpdate'] != true) {
          // Show "no updates" message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.update.latestVersion),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingForUpdate = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.update.checkFailed),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showUpdateDialog() {
    if (_updateInfo == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.updateAvailable),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.update.versionAvailable(
                  version: _updateInfo!['latestVersion'],
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                t.update.currentVersion(
                  version: _updateInfo!['currentVersion'],
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.close),
            ),
            FilledButton(
              onPressed: () async {
                final url = Uri.parse(_updateInfo!['releaseUrl']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(t.update.viewRelease),
            ),
          ],
        );
      },
    );
  }

  void _showLibraryDensityDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: Text(t.settings.libraryDensity),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      provider.libraryDensity == settings.LibraryDensity.compact
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(t.settings.compact),
                    subtitle: Text(t.settings.compactDescription),
                    onTap: () async {
                      await settingsProvider.setLibraryDensity(
                        settings.LibraryDensity.compact,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      provider.libraryDensity == settings.LibraryDensity.normal
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(t.settings.normal),
                    subtitle: Text(t.settings.normalDescription),
                    onTap: () async {
                      await settingsProvider.setLibraryDensity(
                        settings.LibraryDensity.normal,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      provider.libraryDensity ==
                              settings.LibraryDensity.comfortable
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(t.settings.comfortable),
                    subtitle: Text(t.settings.comfortableDescription),
                    onTap: () async {
                      await settingsProvider.setLibraryDensity(
                        settings.LibraryDensity.comfortable,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.common.cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showViewModeDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: Text(t.settings.viewMode),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      provider.viewMode == settings.ViewMode.grid
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(t.settings.gridView),
                    subtitle: Text(t.settings.gridViewDescription),
                    onTap: () async {
                      await settingsProvider.setViewMode(
                        settings.ViewMode.grid,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      provider.viewMode == settings.ViewMode.list
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(t.settings.listView),
                    subtitle: Text(t.settings.listViewDescription),
                    onTap: () async {
                      await settingsProvider.setViewMode(
                        settings.ViewMode.list,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.common.cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _KeyboardShortcutsScreen extends StatefulWidget {
  final KeyboardShortcutsService keyboardService;

  const _KeyboardShortcutsScreen({required this.keyboardService});

  @override
  State<_KeyboardShortcutsScreen> createState() =>
      _KeyboardShortcutsScreenState();
}

class _KeyboardShortcutsScreenState extends State<_KeyboardShortcutsScreen> {
  Map<String, HotKey> _hotkeys = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotkeys();
  }

  Future<void> _loadHotkeys() async {
    await widget.keyboardService.refreshFromStorage();
    setState(() {
      _hotkeys = widget.keyboardService.hotkeys;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Text(t.settings.keyboardShortcuts),
            pinned: true,
            actions: [
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await widget.keyboardService.resetToDefaults();
                  await _loadHotkeys();
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(t.settings.shortcutsReset)),
                    );
                  }
                },
                child: Text(t.common.reset),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final actions = _hotkeys.keys.toList();
                final action = actions[index];
                final hotkey = _hotkeys[action]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      widget.keyboardService.getActionDisplayName(action),
                    ),
                    subtitle: Text(action),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.keyboardService.formatHotkey(hotkey),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    onTap: () => _editHotkey(action, hotkey),
                  ),
                );
              }, childCount: _hotkeys.length),
            ),
          ),
        ],
      ),
    );
  }

  void _editHotkey(String action, HotKey currentHotkey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HotKeyRecorderWidget(
          actionName: widget.keyboardService.getActionDisplayName(action),
          currentHotKey: currentHotkey,
          onHotKeyRecorded: (newHotkey) async {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);

            // Check for conflicts
            final existingAction = widget.keyboardService.getActionForHotkey(
              newHotkey,
            );
            if (existingAction != null && existingAction != action) {
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    t.settings.shortcutAlreadyAssigned(
                      action: widget.keyboardService.getActionDisplayName(
                        existingAction,
                      ),
                    ),
                  ),
                ),
              );
              return;
            }

            // Save the new hotkey
            await widget.keyboardService.setHotkey(action, newHotkey);

            if (mounted) {
              // Update UI directly instead of reloading from storage
              setState(() {
                _hotkeys[action] = newHotkey;
              });

              navigator.pop();

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    t.settings.shortcutUpdated(
                      action: widget.keyboardService.getActionDisplayName(
                        action,
                      ),
                    ),
                  ),
                ),
              );
            }
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}
