/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 6
/// Strings: 4603 (767 per locale)
///
/// Built on 2026-01-04 at 20:19 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	en(languageCode: 'en', build: Translations.build),
	de(languageCode: 'de', build: _StringsDe.build),
	it(languageCode: 'it', build: _StringsIt.build),
	nl(languageCode: 'nl', build: _StringsNl.build),
	sv(languageCode: 'sv', build: _StringsSv.build),
	zh(languageCode: 'zh', build: _StringsZh.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final _StringsAppEn app = _StringsAppEn._(_root);
	late final _StringsAuthEn auth = _StringsAuthEn._(_root);
	late final _StringsCommonEn common = _StringsCommonEn._(_root);
	late final _StringsScreensEn screens = _StringsScreensEn._(_root);
	late final _StringsUpdateEn update = _StringsUpdateEn._(_root);
	late final _StringsSettingsEn settings = _StringsSettingsEn._(_root);
	late final _StringsSearchEn search = _StringsSearchEn._(_root);
	late final _StringsHotkeysEn hotkeys = _StringsHotkeysEn._(_root);
	late final _StringsPinEntryEn pinEntry = _StringsPinEntryEn._(_root);
	late final _StringsFileInfoEn fileInfo = _StringsFileInfoEn._(_root);
	late final _StringsMediaMenuEn mediaMenu = _StringsMediaMenuEn._(_root);
	late final _StringsAccessibilityEn accessibility = _StringsAccessibilityEn._(_root);
	late final _StringsTooltipsEn tooltips = _StringsTooltipsEn._(_root);
	late final _StringsVideoControlsEn videoControls = _StringsVideoControlsEn._(_root);
	late final _StringsUserStatusEn userStatus = _StringsUserStatusEn._(_root);
	late final _StringsMessagesEn messages = _StringsMessagesEn._(_root);
	late final _StringsProfileEn profile = _StringsProfileEn._(_root);
	late final _StringsSubtitlingStylingEn subtitlingStyling = _StringsSubtitlingStylingEn._(_root);
	late final _StringsDialogEn dialog = _StringsDialogEn._(_root);
	late final _StringsDiscoverEn discover = _StringsDiscoverEn._(_root);
	late final _StringsErrorsEn errors = _StringsErrorsEn._(_root);
	late final _StringsVoiceEn voice = _StringsVoiceEn._(_root);
	late final _StringsLibrariesEn libraries = _StringsLibrariesEn._(_root);
	late final _StringsAboutEn about = _StringsAboutEn._(_root);
	late final _StringsServerSelectionEn serverSelection = _StringsServerSelectionEn._(_root);
	late final _StringsHubDetailEn hubDetail = _StringsHubDetailEn._(_root);
	late final _StringsLogsEn logs = _StringsLogsEn._(_root);
	late final _StringsStatsEn stats = _StringsStatsEn._(_root);
	late final _StringsLicensesEn licenses = _StringsLicensesEn._(_root);
	late final _StringsNavigationEn navigation = _StringsNavigationEn._(_root);
	late final _StringsCollectionsEn collections = _StringsCollectionsEn._(_root);
	late final _StringsPlaylistsEn playlists = _StringsPlaylistsEn._(_root);
	late final _StringsWatchPartyEn watchParty = _StringsWatchPartyEn._(_root);
	late final _StringsCatchUpEn catchUp = _StringsCatchUpEn._(_root);
	late final _StringsWatchlistEn watchlist = _StringsWatchlistEn._(_root);
	late final _StringsLiveTVEn liveTV = _StringsLiveTVEn._(_root);
	late final _StringsDvrEn dvr = _StringsDvrEn._(_root);
	late final _StringsEpgEn epg = _StringsEpgEn._(_root);
	late final _StringsChannelSurfingEn channelSurfing = _StringsChannelSurfingEn._(_root);
	late final _StringsVirtualChannelsEn virtualChannels = _StringsVirtualChannelsEn._(_root);
	late final _StringsMultiviewEn multiview = _StringsMultiviewEn._(_root);
	late final _StringsPlayerEn player = _StringsPlayerEn._(_root);
	late final _StringsDownloadsEn downloads = _StringsDownloadsEn._(_root);
}

// Path: app
class _StringsAppEn {
	_StringsAppEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'OpenFlix';
	String get loading => 'Loading...';
}

// Path: auth
class _StringsAuthEn {
	_StringsAuthEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get signIn => 'Sign In';
	String get signUp => 'Sign Up';
	String get signInWithPlex => 'Sign in to OpenFlix';
	String get showQRCode => 'Show QR Code';
	String get cancel => 'Cancel';
	String get authenticate => 'Authenticate';
	String get retry => 'Retry';
	String get debugEnterToken => 'Debug: Enter Auth Token';
	String get plexTokenLabel => 'Auth Token';
	String get plexTokenHint => 'Enter your auth token';
	String get authenticationTimeout => 'Authentication timed out. Please try again.';
	String get scanQRCodeInstruction => 'Scan this QR code to authenticate.';
	String get waitingForAuth => 'Waiting for authentication...\nPlease complete sign-in in your browser.';
	String get serverUrl => 'Server URL';
	String get serverUrlHint => 'e.g., http://192.168.1.100:32400';
	String get username => 'Username';
	String get usernameHint => 'Enter your username';
	String get email => 'Email';
	String get emailHint => 'Enter your email';
	String get password => 'Password';
	String get passwordHint => 'Enter your password';
	String get confirmPassword => 'Confirm Password';
	String get confirmPasswordHint => 'Re-enter your password';
	String get displayName => 'Display Name';
	String get displayNameHint => 'Optional display name';
	String get noAccount => 'Don\'t have an account?';
	String get haveAccount => 'Already have an account?';
	String get connecting => 'Connecting to server...';
	String get loggingIn => 'Signing in...';
	String get registering => 'Creating account...';
	String get connectToServer => 'Connect to Server';
	String get changeServer => 'Change Server';
	String serverConnected({required Object serverName}) => 'Connected to ${serverName}';
	String get invalidServerUrl => 'Please enter a valid server URL';
	String get serverConnectionFailed => 'Could not connect to server';
	String get passwordMismatch => 'Passwords do not match';
	String get usernameRequired => 'Username is required';
	String get emailRequired => 'Email is required';
	String get passwordRequired => 'Password is required';
	String get passwordTooShort => 'Password must be at least 6 characters';
	String get invalidEmail => 'Please enter a valid email address';
	String get firstUserNote => 'First user will be the admin';
	String get howConnecting => 'How are you connecting?';
	String get atHome => 'At Home';
	String get atHomeDescription => 'Auto-detect server on your local network';
	String get awayFromHome => 'Away from Home';
	String get awayFromHomeDescription => 'Enter server address manually';
	String get findYourServer => 'Find Your Server';
	String get searching => 'Searching...';
	String get checkingNetwork => 'Checking network...';
	String get serversFound => 'Servers Found';
	String get scanAgain => 'Scan Again';
	String get enterManually => 'Enter Manually';
	String get noServersFound => 'No servers found on your network. Make sure your OpenFlix server is running.';
	String discoveryFailed({required Object error}) => 'Discovery failed: ${error}';
}

// Path: common
class _StringsCommonEn {
	_StringsCommonEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get cancel => 'Cancel';
	String get save => 'Save';
	String get close => 'Close';
	String get clear => 'Clear';
	String get reset => 'Reset';
	String get later => 'Later';
	String get submit => 'Submit';
	String get confirm => 'Confirm';
	String get retry => 'Retry';
	String get playNow => 'Play Now';
	String get logout => 'Logout';
	String get online => 'Online';
	String get offline => 'Offline';
	String get owned => 'Owned';
	String get shared => 'Shared';
	String get current => 'CURRENT';
	String get unknown => 'Unknown';
	String get refresh => 'Refresh';
	String get yes => 'Yes';
	String get no => 'No';
	String get server => 'Server';
	String get delete => 'Delete';
	String get shuffle => 'Shuffle';
	String get addTo => 'Add to...';
	String get remove => 'Remove';
	String get play => 'Play';
	String get details => 'Details';
	String get seeAll => 'See All';
	String get live => 'LIVE';
	String get newLabel => 'NEW';
}

// Path: screens
class _StringsScreensEn {
	_StringsScreensEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get licenses => 'Licenses';
	String get switchProfile => 'Switch Profile';
	String get subtitleStyling => 'Subtitle Styling';
	String get search => 'Search';
	String get logs => 'Logs';
}

// Path: update
class _StringsUpdateEn {
	_StringsUpdateEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get available => 'Update Available';
	String versionAvailable({required Object version}) => 'Version ${version} is available';
	String currentVersion({required Object version}) => 'Current: ${version}';
	String get skipVersion => 'Skip This Version';
	String get viewRelease => 'View Release';
	String get latestVersion => 'You are on the latest version';
	String get checkFailed => 'Failed to check for updates';
}

// Path: settings
class _StringsSettingsEn {
	_StringsSettingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Settings';
	String get profile => 'Profile';
	String get noProfileSelected => 'No profile selected';
	String get kidsMode => 'Kids Mode';
	String get switchProfile => 'Switch Profile';
	String get switchProfileDescription => 'Change to a different profile';
	String get manageProfiles => 'Manage Profiles';
	String get manageProfilesDescription => 'Add, edit, or delete profiles';
	String get language => 'Language';
	String get theme => 'Theme';
	String get appearance => 'Appearance';
	String get videoPlayback => 'Video Playback';
	String get shufflePlay => 'Shuffle Play';
	String get advanced => 'Advanced';
	String get useSeasonPostersDescription => 'Show season poster instead of series poster for episodes';
	String get showHeroSectionDescription => 'Display featured content carousel on home screen';
	String get secondsLabel => 'Seconds';
	String get minutesLabel => 'Minutes';
	String get secondsShort => 's';
	String get minutesShort => 'm';
	String durationHint({required Object min, required Object max}) => 'Enter duration (${min}-${max})';
	String get systemTheme => 'System';
	String get systemThemeDescription => 'Follow system settings';
	String get lightTheme => 'Light';
	String get darkTheme => 'Dark';
	String get libraryDensity => 'Library Density';
	String get compact => 'Compact';
	String get compactDescription => 'Smaller cards, more items visible';
	String get normal => 'Normal';
	String get normalDescription => 'Default size';
	String get comfortable => 'Comfortable';
	String get comfortableDescription => 'Larger cards, fewer items visible';
	String get viewMode => 'View Mode';
	String get gridView => 'Grid';
	String get gridViewDescription => 'Display items in a grid layout';
	String get listView => 'List';
	String get listViewDescription => 'Display items in a list layout';
	String get useSeasonPosters => 'Use Season Posters';
	String get showHeroSection => 'Show Hero Section';
	String get hardwareDecoding => 'Hardware Decoding';
	String get hardwareDecodingDescription => 'Use hardware acceleration when available';
	String get bufferSize => 'Buffer Size';
	String bufferSizeMB({required Object size}) => '${size}MB';
	String get subtitleStyling => 'Subtitle Styling';
	String get subtitleStylingDescription => 'Customize subtitle appearance';
	String get smallSkipDuration => 'Small Skip Duration';
	String get largeSkipDuration => 'Large Skip Duration';
	String secondsUnit({required Object seconds}) => '${seconds} seconds';
	String get defaultSleepTimer => 'Default Sleep Timer';
	String minutesUnit({required Object minutes}) => '${minutes} minutes';
	String get rememberTrackSelections => 'Remember track selections per show/movie';
	String get rememberTrackSelectionsDescription => 'Automatically save audio and subtitle language preferences when you change tracks during playback';
	String get unwatchedOnly => 'Unwatched Only';
	String get unwatchedOnlyDescription => 'Only include unwatched episodes in shuffle queue';
	String get shuffleOrderNavigation => 'Shuffle Order Navigation';
	String get shuffleOrderNavigationDescription => 'Next/previous buttons follow shuffled order';
	String get loopShuffleQueue => 'Loop Shuffle Queue';
	String get loopShuffleQueueDescription => 'Restart queue when reaching the end';
	String get videoPlayerControls => 'Video Player Controls';
	String get keyboardShortcuts => 'Keyboard Shortcuts';
	String get keyboardShortcutsDescription => 'Customize keyboard shortcuts';
	String get debugLogging => 'Debug Logging';
	String get debugLoggingDescription => 'Enable detailed logging for troubleshooting';
	String get viewLogs => 'View Logs';
	String get viewLogsDescription => 'View application logs';
	String get clearCache => 'Clear Cache';
	String get clearCacheDescription => 'This will clear all cached images and data. The app may take longer to load content after clearing the cache.';
	String get clearCacheSuccess => 'Cache cleared successfully';
	String get resetSettings => 'Reset Settings';
	String get resetSettingsDescription => 'This will reset all settings to their default values. This action cannot be undone.';
	String get resetSettingsSuccess => 'Settings reset successfully';
	String get shortcutsReset => 'Shortcuts reset to defaults';
	String get about => 'About';
	String get aboutDescription => 'App information and licenses';
	String get updates => 'Updates';
	String get updateAvailable => 'Update Available';
	String get checkForUpdates => 'Check for Updates';
	String get validationErrorEnterNumber => 'Please enter a valid number';
	String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Duration must be between ${min} and ${max} ${unit}';
	String shortcutAlreadyAssigned({required Object action}) => 'Shortcut already assigned to ${action}';
	String shortcutUpdated({required Object action}) => 'Shortcut updated for ${action}';
	String get autoSkip => 'Auto Skip';
	String get autoSkipIntro => 'Auto Skip Intro';
	String get autoSkipIntroDescription => 'Automatically skip intro markers after a few seconds';
	String get autoSkipCredits => 'Auto Skip Credits';
	String get autoSkipCreditsDescription => 'Automatically skip credits and play next episode';
	String get autoSkipDelay => 'Auto Skip Delay';
	String autoSkipDelayDescription({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping';
	String get metadataSection => 'Metadata';
	String get tmdbApiKey => 'TMDB API Key';
	String get tmdbApiKeyDescription => 'Configure TMDB for enhanced metadata';
	String get tmdbApiKeyConfigured => 'API key configured';
	String get tmdbApiKeyHint => 'Get your API key from themoviedb.org';
	String get tmdbApiKeyPlaceholder => 'Enter your TMDB API key';
	String get apiKey => 'API Key';
	String get tmdbApiKeySaved => 'TMDB API key saved';
	String get tmdbApiKeyCleared => 'TMDB API key cleared';
	String get parentalControls => 'Parental Controls';
	String get kidsModeDescription => 'Show only kid-friendly content (G, PG, TV-Y7)';
	String get enableParentalControls => 'Enable Parental Controls';
	String get enableParentalControlsDescription => 'Restrict content based on age ratings';
	String get setPin => 'Set PIN';
	String get setPinDescription => 'Enter a 4-digit PIN to protect parental settings';
	String get confirmPin => 'Confirm PIN';
	String get confirmPinDescription => 'Enter the PIN again to confirm';
	String get enterPin => 'Enter PIN';
	String get enterPinDescription => 'Enter your parental control PIN';
	String get changePin => 'Change PIN';
	String get changePinDescription => 'Change your parental control PIN';
	String get pinSet => 'Parental control PIN set successfully';
	String get pinMismatch => 'PINs do not match. Please try again.';
	String get incorrectPin => 'Incorrect PIN. Please try again.';
	String get maxMovieRating => 'Maximum Movie Rating';
	String get maxTvRating => 'Maximum TV Rating';
	String get remoteAccess => 'Remote Access';
	String get tailscaleStatus => 'Tailscale Status';
	String get remoteAccessCheckingStatus => 'Checking status...';
	String get refreshStatus => 'Refresh Status';
	String get remoteUrl => 'Remote URL';
	String get copyUrl => 'Copy URL';
	String get urlCopied => 'URL copied to clipboard';
	String get tailscaleIp => 'Tailscale IP';
	String get tailscaleNotInstalled => 'Tailscale is not installed on the server.';
	String get tailscaleDescription => 'Install Tailscale on your server to enable secure remote access from anywhere.';
	String get tailscaleNeedsLogin => 'Login Required';
	String get tailscaleNeedsLoginDescription => 'Tailscale requires authentication. Log in on the server.';
}

// Path: search
class _StringsSearchEn {
	_StringsSearchEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get hint => 'Search movies, shows, music...';
	String get tryDifferentTerm => 'Try a different search term';
	String get searchYourMedia => 'Search your media';
	String get enterTitleActorOrKeyword => 'Enter a title, actor, or keyword';
	String get recentSearches => 'Recent Searches';
	String get clear => 'Clear';
	String get voiceSearch => 'Voice Search';
	String get listening => 'Listening...';
	String get speakNow => 'Speak now';
	String get all => 'All';
	String get movies => 'Movies';
	String get tvShows => 'TV Shows';
	String get music => 'Music';
}

// Path: hotkeys
class _StringsHotkeysEn {
	_StringsHotkeysEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String setShortcutFor({required Object actionName}) => 'Set Shortcut for ${actionName}';
	String get clearShortcut => 'Clear shortcut';
}

// Path: pinEntry
class _StringsPinEntryEn {
	_StringsPinEntryEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get enterPin => 'Enter PIN';
	String get showPin => 'Show PIN';
	String get hidePin => 'Hide PIN';
}

// Path: fileInfo
class _StringsFileInfoEn {
	_StringsFileInfoEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'File Info';
	String get video => 'Video';
	String get audio => 'Audio';
	String get file => 'File';
	String get advanced => 'Advanced';
	String get codec => 'Codec';
	String get resolution => 'Resolution';
	String get bitrate => 'Bitrate';
	String get frameRate => 'Frame Rate';
	String get aspectRatio => 'Aspect Ratio';
	String get profile => 'Profile';
	String get bitDepth => 'Bit Depth';
	String get colorSpace => 'Color Space';
	String get colorRange => 'Color Range';
	String get colorPrimaries => 'Color Primaries';
	String get chromaSubsampling => 'Chroma Subsampling';
	String get channels => 'Channels';
	String get path => 'Path';
	String get size => 'Size';
	String get container => 'Container';
	String get duration => 'Duration';
	String get optimizedForStreaming => 'Optimized for Streaming';
	String get has64bitOffsets => '64-bit Offsets';
}

// Path: mediaMenu
class _StringsMediaMenuEn {
	_StringsMediaMenuEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get markAsWatched => 'Mark as Watched';
	String get markAsUnwatched => 'Mark as Unwatched';
	String get removeFromContinueWatching => 'Remove from Continue Watching';
	String get goToSeries => 'Go to series';
	String get goToSeason => 'Go to season';
	String get shufflePlay => 'Shuffle Play';
	String get fileInfo => 'File Info';
}

// Path: accessibility
class _StringsAccessibilityEn {
	_StringsAccessibilityEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String mediaCardMovie({required Object title}) => '${title}, movie';
	String mediaCardShow({required Object title}) => '${title}, TV show';
	String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	String get mediaCardWatched => 'watched';
	String mediaCardPartiallyWatched({required Object percent}) => '${percent} percent watched';
	String get mediaCardUnwatched => 'unwatched';
	String get tapToPlay => 'Tap to play';
}

// Path: tooltips
class _StringsTooltipsEn {
	_StringsTooltipsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get shufflePlay => 'Shuffle play';
	String get markAsWatched => 'Mark as watched';
	String get markAsUnwatched => 'Mark as unwatched';
}

// Path: videoControls
class _StringsVideoControlsEn {
	_StringsVideoControlsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get audioLabel => 'Audio';
	String get subtitlesLabel => 'Subtitles';
	String get resetToZero => 'Reset to 0ms';
	String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	String playsLater({required Object label}) => '${label} plays later';
	String playsEarlier({required Object label}) => '${label} plays earlier';
	String get noOffset => 'No offset';
	String get letterbox => 'Letterbox';
	String get fillScreen => 'Fill screen';
	String get stretch => 'Stretch';
	String get lockRotation => 'Lock rotation';
	String get unlockRotation => 'Unlock rotation';
	String get lockScreen => 'Lock screen';
	String get unlockScreen => 'Unlock screen';
	String get screenLockButton => 'Screen lock';
	String get screenLocked => 'Screen locked';
	String get tapToUnlock => 'Tap to unlock';
	String get sleepTimer => 'Sleep Timer';
	String get timerActive => 'Timer Active';
	String playbackWillPauseIn({required Object duration}) => 'Playback will pause in ${duration}';
	String get sleepTimerCompleted => 'Sleep timer completed - playback paused';
	String get playButton => 'Play';
	String get pauseButton => 'Pause';
	String seekBackwardButton({required Object seconds}) => 'Seek backward ${seconds} seconds';
	String seekForwardButton({required Object seconds}) => 'Seek forward ${seconds} seconds';
	String get previousButton => 'Previous episode';
	String get nextButton => 'Next episode';
	String get previousChapterButton => 'Previous chapter';
	String get nextChapterButton => 'Next chapter';
	String get volumeButton => 'Volume';
	String get muteButton => 'Mute';
	String get unmuteButton => 'Unmute';
	String get settingsButton => 'Video settings';
	String get audioTrackButton => 'Audio tracks';
	String get subtitlesButton => 'Subtitles';
	String get chaptersButton => 'Chapters';
	String get versionsButton => 'Video versions';
	String get aspectRatioButton => 'Aspect ratio';
	String get fullscreenButton => 'Enter fullscreen';
	String get exitFullscreenButton => 'Exit fullscreen';
	String get rotationLockButton => 'Rotation lock';
	String get timelineSlider => 'Video timeline';
	String get volumeSlider => 'Volume level';
	String get backButton => 'Back';
}

// Path: userStatus
class _StringsUserStatusEn {
	_StringsUserStatusEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get admin => 'Admin';
	String get restricted => 'Restricted';
	String get protected => 'Protected';
	String get current => 'CURRENT';
}

// Path: messages
class _StringsMessagesEn {
	_StringsMessagesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get markedAsWatched => 'Marked as watched';
	String get markedAsUnwatched => 'Marked as unwatched';
	String get removedFromContinueWatching => 'Removed from Continue Watching';
	String errorLoading({required Object error}) => 'Error: ${error}';
	String get fileInfoNotAvailable => 'File information not available';
	String errorLoadingFileInfo({required Object error}) => 'Error loading file info: ${error}';
	String get errorLoadingSeries => 'Error loading series';
	String get errorLoadingSeason => 'Error loading season';
	String get musicNotSupported => 'Music playback is not yet supported';
	String get logsCleared => 'Logs cleared';
	String get logsCopied => 'Logs copied to clipboard';
	String get noLogsAvailable => 'No logs available';
	String libraryScanning({required Object title}) => 'Scanning "${title}"...';
	String libraryScanStarted({required Object title}) => 'Library scan started for "${title}"';
	String libraryScanFailed({required Object error}) => 'Failed to scan library: ${error}';
	String metadataRefreshing({required Object title}) => 'Refreshing metadata for "${title}"...';
	String metadataRefreshStarted({required Object title}) => 'Metadata refresh started for "${title}"';
	String metadataRefreshFailed({required Object error}) => 'Failed to refresh metadata: ${error}';
	String get noTokenFound => 'No auth token found. Please login again.';
	String get logoutConfirm => 'Are you sure you want to logout?';
	String get noSeasonsFound => 'No seasons found';
	String get noEpisodesFound => 'No episodes found in first season';
	String get noEpisodesFoundGeneral => 'No episodes found';
	String get noResultsFound => 'No results found';
	String sleepTimerSet({required Object label}) => 'Sleep timer set for ${label}';
	String failedToSwitchProfile({required Object displayName}) => 'Failed to switch to ${displayName}';
	String get noItemsAvailable => 'No items available';
	String get failedToCreatePlayQueue => 'Failed to create play queue';
	String get failedToCreatePlayQueueNoItems => 'Failed to create play queue - no items';
	String failedPlayback({required Object action, required Object error}) => 'Failed to ${action}: ${error}';
}

// Path: profile
class _StringsProfileEn {
	_StringsProfileEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get noUsersAvailable => 'No users available';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get stylingOptions => 'Styling Options';
	String get fontSize => 'Font Size';
	String get textColor => 'Text Color';
	String get borderSize => 'Border Size';
	String get borderColor => 'Border Color';
	String get backgroundOpacity => 'Background Opacity';
	String get backgroundColor => 'Background Color';
}

// Path: dialog
class _StringsDialogEn {
	_StringsDialogEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get confirmAction => 'Confirm Action';
	String get areYouSure => 'Are you sure you want to perform this action?';
	String get cancel => 'Cancel';
	String get playNow => 'Play Now';
}

// Path: discover
class _StringsDiscoverEn {
	_StringsDiscoverEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Discover';
	String get switchProfile => 'Switch Profile';
	String get logout => 'Logout';
	String get noContentAvailable => 'No content available';
	String get addMediaToLibraries => 'Add some media to your libraries';
	String get continueWatching => 'Continue Watching';
	String get recentlyAdded => 'Recently Added';
	String get play => 'Play';
	String get resume => 'Resume';
	String playEpisode({required Object season, required Object episode}) => 'Play S${season}, E${episode}';
	String resumeEpisode({required Object season, required Object episode}) => 'Resume S${season}, E${episode}';
	String get pause => 'Pause';
	String get overview => 'Overview';
	String get cast => 'Cast';
	String get seasons => 'Seasons';
	String get studio => 'Studio';
	String get rating => 'Rating';
	String get watched => 'Watched';
	String episodeCount({required Object count}) => '${count} episodes';
	String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} watched';
	String get movie => 'Movie';
	String get tvShow => 'TV Show';
	String minutesLeft({required Object minutes}) => '${minutes} min left';
	String get whatsOnNow => 'What\'s On Now';
	String get channelGuide => 'Channel Guide';
	String get liveNow => 'Live Now';
	String get topTen => 'Top 10';
	String get newBadge => 'NEW';
	String get liveBadge => 'LIVE';
	String get goodMorning => 'Good morning';
	String get goodAfternoon => 'Good afternoon';
	String get goodEvening => 'Good evening';
	String get defaultUser => 'Guest';
	String get yourNextWatch => 'Your Next Watch';
	String pickedForYou({required Object name}) => 'Picked just for you, ${name}';
	String get surpriseMe => 'Surprise Me';
	String get randomPicker => 'Random Movie Picker';
	String get noMoviesFound => 'No movies found in your library';
	String get spinning => 'Picking something great...';
	String get spinAgain => 'Spin Again';
	String get loadingMovies => 'Loading your movies...';
	String get calendar => 'Calendar';
	String get today => 'Today';
	String get item => 'item';
	String get items => 'items';
	String get noContentOnDate => 'No content added on this date';
	String get noEpgData => 'No program info';
}

// Path: errors
class _StringsErrorsEn {
	_StringsErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String searchFailed({required Object error}) => 'Search failed: ${error}';
	String connectionTimeout({required Object context}) => 'Connection timeout while loading ${context}';
	String get connectionFailed => 'Unable to connect to Plex server';
	String failedToLoad({required Object context, required Object error}) => 'Failed to load ${context}: ${error}';
	String get noClientAvailable => 'No client available';
	String authenticationFailed({required Object error}) => 'Authentication failed: ${error}';
	String get couldNotLaunchUrl => 'Could not launch auth URL';
	String get pleaseEnterToken => 'Please enter a token';
	String get invalidToken => 'Invalid token';
	String failedToVerifyToken({required Object error}) => 'Failed to verify token: ${error}';
	String failedToSwitchProfile({required Object displayName}) => 'Failed to switch to ${displayName}';
	String get connectionFailedGeneric => 'Connection failed';
	String failedToRemove({required Object error}) => 'Failed to remove: ${error}';
}

// Path: voice
class _StringsVoiceEn {
	_StringsVoiceEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get notAvailable => 'Voice control is not available';
	String commandNotRecognized({required Object command}) => 'Command not recognized: "${command}"';
}

// Path: libraries
class _StringsLibrariesEn {
	_StringsLibrariesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Libraries';
	String get scanLibraryFiles => 'Scan Library Files';
	String get scanLibrary => 'Scan Library';
	String get analyze => 'Analyze';
	String get analyzeLibrary => 'Analyze Library';
	String get refreshMetadata => 'Refresh Metadata';
	String get emptyTrash => 'Empty Trash';
	String emptyingTrash({required Object title}) => 'Emptying trash for "${title}"...';
	String trashEmptied({required Object title}) => 'Trash emptied for "${title}"';
	String failedToEmptyTrash({required Object error}) => 'Failed to empty trash: ${error}';
	String analyzing({required Object title}) => 'Analyzing "${title}"...';
	String analysisStarted({required Object title}) => 'Analysis started for "${title}"';
	String failedToAnalyze({required Object error}) => 'Failed to analyze library: ${error}';
	String get noLibrariesFound => 'No libraries found';
	String get thisLibraryIsEmpty => 'This library is empty';
	String get all => 'All';
	String get clearAll => 'Clear All';
	String scanLibraryConfirm({required Object title}) => 'Are you sure you want to scan "${title}"?';
	String analyzeLibraryConfirm({required Object title}) => 'Are you sure you want to analyze "${title}"?';
	String refreshMetadataConfirm({required Object title}) => 'Are you sure you want to refresh metadata for "${title}"?';
	String emptyTrashConfirm({required Object title}) => 'Are you sure you want to empty trash for "${title}"?';
	String get manageLibraries => 'Manage Libraries';
	String get sort => 'Sort';
	String get sortBy => 'Sort By';
	String get filters => 'Filters';
	String loadingLibraryWithCount({required Object count}) => 'Loading library... (${count} items loaded)';
	String get confirmActionMessage => 'Are you sure you want to perform this action?';
	String get showLibrary => 'Show library';
	String get hideLibrary => 'Hide library';
	String get libraryOptions => 'Library options';
	String get content => 'library content';
	String get selectLibrary => 'Select library';
	String filtersWithCount({required Object count}) => 'Filters (${count})';
	String get noRecommendations => 'No recommendations available';
	String get noCollections => 'No collections in this library';
	String get noFoldersFound => 'No folders found';
	String get folders => 'folders';
	late final _StringsLibrariesTabsEn tabs = _StringsLibrariesTabsEn._(_root);
	late final _StringsLibrariesGroupingsEn groupings = _StringsLibrariesGroupingsEn._(_root);
}

// Path: about
class _StringsAboutEn {
	_StringsAboutEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'About';
	String get openSourceLicenses => 'Open Source Licenses';
	String versionLabel({required Object version}) => 'Version ${version}';
	String get appDescription => 'A beautiful Plex client for Flutter';
	String get viewLicensesDescription => 'View licenses of third-party libraries';
}

// Path: serverSelection
class _StringsServerSelectionEn {
	_StringsServerSelectionEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get connectingToServer => 'Connecting to server...';
	String get connectingToAllServers => 'Connecting to all servers...';
	String get connectToAllServers => 'Connect to All Servers';
	String get allServerConnectionsFailed => 'Failed to connect to any servers. Please check your network and try again.';
	String foundServers({required Object count}) => 'Found ${count} server(s)';
	String get orSelectIndividually => 'Or select a server individually:';
	String get serverDebugCopied => 'Server debug data copied to clipboard';
	String get copyDebugData => 'Copy Debug Data';
	String get noServersFound => 'No servers found';
	String malformedServerData({required Object count}) => 'Found ${count} server(s) with malformed data. No valid servers available.';
	String get incompleteServerInfo => 'Some servers have incomplete information and were skipped. Please check your Plex.tv account.';
	String get incompleteConnectionInfo => 'Server connection information is incomplete. Please try again.';
	String malformedServerInfo({required Object message}) => 'Server information is malformed: ${message}';
	String get networkConnectionFailed => 'Network connection failed. Please check your internet connection and try again.';
	String get authenticationFailed => 'Authentication failed. Please sign in again.';
	String get plexServiceUnavailable => 'Plex service unavailable. Please try again later.';
	String failedToLoadServers({required Object error}) => 'Failed to load servers: ${error}';
}

// Path: hubDetail
class _StringsHubDetailEn {
	_StringsHubDetailEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Title';
	String get releaseYear => 'Release Year';
	String get dateAdded => 'Date Added';
	String get rating => 'Rating';
	String get noItemsFound => 'No items found';
}

// Path: logs
class _StringsLogsEn {
	_StringsLogsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Logs';
	String get clearLogs => 'Clear Logs';
	String get copyLogs => 'Copy Logs';
	String get exportLogs => 'Export Logs';
	String get noLogsToShow => 'No logs to show';
	String get error => 'Error:';
	String get stackTrace => 'Stack Trace:';
}

// Path: stats
class _StringsStatsEn {
	_StringsStatsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Watch Statistics';
	String get totalWatchTime => 'Total Watch Time';
	String get moviesWatched => 'Movies Watched';
	String get episodesWatched => 'Episodes Watched';
	String get avgPerDay => 'Avg Per Day';
	String get topGenres => 'Top Genres';
	String get monthlyActivity => 'Monthly Activity';
	String get noData => 'No watch history yet';
	String get startWatching => 'Start watching to see your stats';
	String get days => 'days';
}

// Path: licenses
class _StringsLicensesEn {
	_StringsLicensesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get relatedPackages => 'Related Packages';
	String get license => 'License';
	String licenseNumber({required Object number}) => 'License ${number}';
	String licensesCount({required Object count}) => '${count} licenses';
}

// Path: navigation
class _StringsNavigationEn {
	_StringsNavigationEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get home => 'Home';
	String get movies => 'Movies';
	String get tvShows => 'TV Shows';
	String get search => 'Search';
	String get libraries => 'Libraries';
	String get livetv => 'Live TV';
	String get settings => 'Settings';
}

// Path: collections
class _StringsCollectionsEn {
	_StringsCollectionsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Collections';
	String get collection => 'Collection';
	String get empty => 'Collection is empty';
	String get noItems => 'No items in this collection';
	String get unknownLibrarySection => 'Cannot delete: Unknown library section';
	String get deleteCollection => 'Delete Collection';
	String deleteConfirm({required Object title}) => 'Are you sure you want to delete "${title}"? This action cannot be undone.';
	String get deleted => 'Collection deleted';
	String get deleteFailed => 'Failed to delete collection';
	String deleteFailedWithError({required Object error}) => 'Failed to delete collection: ${error}';
	String failedToLoadItems({required Object error}) => 'Failed to load collection items: ${error}';
	String get addTo => 'Add to collection';
	String get selectCollection => 'Select Collection';
	String get createNewCollection => 'Create New Collection';
	String get collectionName => 'Collection Name';
	String get enterCollectionName => 'Enter collection name';
	String get addedToCollection => 'Added to collection';
	String get errorAddingToCollection => 'Failed to add to collection';
	String get created => 'Collection created';
	String get removeFromCollection => 'Remove from collection';
	String removeFromCollectionConfirm({required Object title}) => 'Remove "${title}" from this collection?';
	String get removedFromCollection => 'Removed from collection';
	String get removeFromCollectionFailed => 'Failed to remove from collection';
	String removeFromCollectionError({required Object error}) => 'Error removing from collection: ${error}';
}

// Path: playlists
class _StringsPlaylistsEn {
	_StringsPlaylistsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Playlists';
	String get playlist => 'Playlist';
	String get noPlaylists => 'No playlists found';
	String get create => 'Create Playlist';
	String get newPlaylist => 'New Playlist';
	String get playlistName => 'Playlist Name';
	String get enterPlaylistName => 'Enter playlist name';
	String get edit => 'Edit Playlist';
	String get delete => 'Delete Playlist';
	String get addTo => 'Add to Playlist';
	String get addItems => 'Add Items';
	String get removeItem => 'Remove from Playlist';
	String get clearPlaylist => 'Clear Playlist';
	String get playAll => 'Play All';
	String get shuffle => 'Shuffle';
	String get smartPlaylist => 'Smart Playlist';
	String get regularPlaylist => 'Regular Playlist';
	String itemCount({required Object count}) => '${count} items';
	String get oneItem => '1 item';
	String get emptyPlaylist => 'This playlist is empty';
	String get deleteConfirm => 'Delete Playlist?';
	String deleteMessage({required Object name}) => 'Are you sure you want to delete "${name}"?';
	String get created => 'Playlist created';
	String get updated => 'Playlist updated';
	String get deleted => 'Playlist deleted';
	String get itemAdded => 'Added to playlist';
	String get itemRemoved => 'Removed from playlist';
	String get selectPlaylist => 'Select Playlist';
	String get createNewPlaylist => 'Create New Playlist';
	String get errorCreating => 'Failed to create playlist';
	String get errorDeleting => 'Failed to delete playlist';
	String get errorLoading => 'Failed to load playlists';
	String get errorAdding => 'Failed to add to playlist';
	String get errorReordering => 'Failed to reorder playlist item';
	String get errorRemoving => 'Failed to remove from playlist';
}

// Path: watchParty
class _StringsWatchPartyEn {
	_StringsWatchPartyEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Watch Party';
	String get startParty => 'Start Watch Party';
	String get joinParty => 'Join Party';
	String get enterCode => 'Enter party code';
	String get shareCode => 'Share this code';
	String get friendsCanJoin => 'Friends can join using this code';
	String get participants => 'Participants';
	String get host => 'Host';
	String get endParty => 'End Party';
	String get leaveParty => 'Leave Party';
	String get partyEnded => 'Watch Party ended';
	String get chat => 'Chat';
	String get typeMessage => 'Type a message...';
	String joined({required Object name}) => '${name} joined';
	String left({required Object name}) => '${name} left';
	String get syncedPlayback => 'Playback is synced with party';
	String get hostControls => 'Only the host can control playback';
	String get creating => 'Creating party...';
	String get joining => 'Joining party...';
	String get createFailed => 'Failed to create party';
	String get joinFailed => 'Failed to join party';
	String get invalidCode => 'Invalid party code';
	String get gotIt => 'Got it';
}

// Path: catchUp
class _StringsCatchUpEn {
	_StringsCatchUpEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Catch Up TV';
	String get startOver => 'Start Over';
	String get startOverDescription => 'Watch from the beginning';
	String get watchFromBeginning => 'Watch from the beginning?';
	String alreadyStarted({required Object title}) => '"${title}" has already started. You can start from the beginning.';
	String get watchLive => 'Watch Live';
	String get programsAvailable => 'Programs Available';
	String get noProgramsAvailable => 'No catch-up programs available';
	String get programsWillAppear => 'Programs will appear here as they air';
	String get unavailable => 'Unavailable';
	String get bufferNotReady => 'Buffer not ready yet';
	String get rewind => 'Rewind';
	String get timeshiftEnabled => 'Time-shift enabled';
	String goBackTo({required Object time}) => 'Go back to ${time}';
}

// Path: watchlist
class _StringsWatchlistEn {
	_StringsWatchlistEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'My Watchlist';
	String get all => 'All';
	String get movies => 'Movies';
	String get shows => 'TV Shows';
	String get episodes => 'Episodes';
	String get empty => 'Your watchlist is empty';
	String get emptyHint => 'Add movies and shows to your watchlist from their detail pages';
	String get noItemsFiltered => 'No items match this filter';
	String get removeTitle => 'Remove from Watchlist';
	String removeConfirm({required Object title}) => 'Remove "${title}" from your watchlist?';
	String get remove => 'Remove';
	String get clearAllTitle => 'Clear Watchlist';
	String clearAllConfirm({required Object count}) => 'Remove all ${count} items from your watchlist?';
	String get clearAll => 'Clear All';
	String get addedToday => 'Added today';
	String get addedYesterday => 'Added yesterday';
	String addedDaysAgo({required Object days}) => 'Added ${days} days ago';
	String addedOn({required Object date}) => 'Added on ${date}';
	String get addToWatchlist => 'Add to Watchlist';
	String get removeFromWatchlist => 'Remove from Watchlist';
	String get addedToWatchlist => 'Added to watchlist';
	String get removedFromWatchlist => 'Removed from watchlist';
}

// Path: liveTV
class _StringsLiveTVEn {
	_StringsLiveTVEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Live TV';
	String get guide => 'Guide';
	String get dvr => 'DVR';
	String get multiview => 'Multiview';
	String get allChannels => 'All Channels';
	String get favorites => 'Favorites';
	String get noChannels => 'No channels available';
	String get addM3USource => 'Add an M3U source in server settings';
	String get recording => 'Recording';
	String get recordingNow => 'Recording Now';
	String get upNext => 'Up Next';
	String get noProgram => 'No program info';
	String get filterByGroup => 'Filter by group';
	String get refresh => 'Refresh';
	String channelCount({required Object count}) => '${count} channels';
	String get nowPlaying => 'Now Playing';
	String get scheduleRecording => 'Schedule Recording';
	String get onNow => 'On Now';
	String endsAt({required Object time}) => 'Ends at ${time}';
	String startsAt({required Object time}) => 'Starts at ${time}';
	String playbackError({required Object error}) => 'Playback error: ${error}';
	String get noPreviousChannel => 'No previous channel';
	String switchedTo({required Object channel}) => 'Switched to: ${channel}';
	String get startingFromBeginning => 'Starting program from beginning...';
	String failedToStartOver({required Object error}) => 'Failed to start over: ${error}';
	String playingProgram({required Object title}) => 'Playing: ${title}';
	String failedToPlayProgram({required Object error}) => 'Failed to play program: ${error}';
	String get addedToFavorites => 'Added to favorites';
	String get removedFromFavorites => 'Removed from favorites';
	String failedToUpdateFavorite({required Object error}) => 'Failed to update favorite: ${error}';
	String get pipNotSupported => 'Picture-in-Picture not supported on this platform';
	String get enteredPipMode => 'Entered Picture-in-Picture mode';
	String get exitedPipMode => 'Exited Picture-in-Picture mode';
	String aspectRatioChanged({required Object mode}) => 'Aspect Ratio: ${mode}';
	String get tune => 'Tune';
	String get retry => 'Retry';
	String get noChannelsMatchFilter => 'No channels match filter';
	String get skipCommercial => 'Skip Commercial';
}

// Path: dvr
class _StringsDvrEn {
	_StringsDvrEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'DVR';
	String get recordings => 'Recordings';
	String get seriesRules => 'Series Rules';
	String get noRecordings => 'No recordings';
	String get noRules => 'No series rules';
	String get scheduleFromGuide => 'Schedule recordings from the Live TV guide';
	String get createRulesHint => 'Create rules to auto-record series';
	String get storage => 'Storage';
	String recordingsCount({required Object count}) => '${count} recordings';
	String get all => 'All';
	String get scheduled => 'Scheduled';
	String get completed => 'Completed';
	String get failed => 'Failed';
	String get deleteRecording => 'Delete Recording?';
	String get deleteRule => 'Delete Series Rule?';
	String get sortByDate => 'Date';
	String get sortByTitle => 'Title';
	String get sortBySize => 'Size';
	String get playRecording => 'Play recording';
	String keepPolicy({required Object count}) => 'Keep ${count} episodes';
	String get keepAll => 'Keep all';
	String get recordingScheduled => 'Recording scheduled';
	String get scheduleRecordingTitle => 'Schedule Recording';
	String get schedule => 'Schedule';
	String get cancel => 'Cancel';
}

// Path: epg
class _StringsEpgEn {
	_StringsEpgEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'TV Guide';
	String get now => 'Now';
	String get today => 'Today';
	String get tomorrow => 'Tomorrow';
	String get noPrograms => 'No program information available';
	String get loading => 'Loading guide...';
	String get record => 'Record';
	String get reminder => 'Set Reminder';
	String get moreInfo => 'More Info';
	String get toggleView => 'Toggle view';
	String get gridView => 'Grid view';
	String get nowNextView => 'Now/Next view';
}

// Path: channelSurfing
class _StringsChannelSurfingEn {
	_StringsChannelSurfingEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Channel Surfing';
	String get kidsMode => 'Kids Mode';
	String get loading => 'Loading channel surfing...';
	String get failedToLoad => 'Failed to load content';
	String get retry => 'Retry';
	String get noContent => 'No content available';
	String itemsAvailable({required Object count}) => '${count} items available';
	String get startSurfing => 'Start Surfing';
	String get pressBackToExit => 'Press back to exit';
	String get description => 'Watch random movies and shows continuously';
	String get noServers => 'No servers available';
}

// Path: virtualChannels
class _StringsVirtualChannelsEn {
	_StringsVirtualChannelsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Virtual Channels';
	String get createChannel => 'Create Channel';
	String get editChannel => 'Edit Channel';
	String get deleteChannel => 'Delete Channel';
	String get channelName => 'Channel Name';
	String get channelNameHint => 'Enter channel name';
	String get selectContent => 'Select Content';
	String get noChannels => 'No virtual channels yet';
	String get createFirst => 'Create your first virtual channel';
	String get description => 'Create custom 24/7 channels from your media library';
	String get shuffle => 'Shuffle Playback';
	String get loop => 'Loop Playlist';
	String get nowPlaying => 'Now Playing';
	String get upNext => 'Up Next';
	String get addMedia => 'Add Media';
	String get removeMedia => 'Remove';
	String get reorderMedia => 'Reorder';
	String get confirmDelete => 'Are you sure you want to delete this channel?';
	String get channelCreated => 'Channel created';
	String get channelUpdated => 'Channel updated';
	String get channelDeleted => 'Channel deleted';
}

// Path: multiview
class _StringsMultiviewEn {
	_StringsMultiviewEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Multi-View';
	String get changeLayout => 'Change Layout (L)';
	String get addChannel => 'Add Channel (A)';
	String get removeChannel => 'Remove Channel (R)';
	String get swapChannel => 'Change Channel';
	String get toggleMute => 'Toggle Mute (M)';
	String get selectChannel => 'Select Channel';
	String get searchChannels => 'Search channels...';
	String get cancel => 'Cancel';
	String channelNumber({required Object number}) => 'Ch. ${number}';
}

// Path: player
class _StringsPlayerEn {
	_StringsPlayerEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get playbackError => 'Playback Error';
	String get error => 'Error';
	String failedToStartPlayback({required Object error}) => 'Failed to start playback:\n${error}';
	String get ok => 'OK';
}

// Path: downloads
class _StringsDownloadsEn {
	_StringsDownloadsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Downloads';
	String get deleteAll => 'Delete All';
	String get deleteAllTitle => 'Delete All Downloads?';
	String deleteAllMessage({required Object count, required Object size}) => 'This will delete all ${count} downloads and free up ${size} of storage.';
	String storageUsed({required Object size}) => 'Storage Used: ${size}';
	String downloading({required Object count}) => 'Downloading (${count})';
	String downloaded({required Object count}) => 'Downloaded (${count})';
	String get noDownloads => 'No Downloads';
	String get noDownloadsHint => 'Download movies and shows to watch offline';
	String get deleteDownloadTitle => 'Delete Download?';
	String deleteDownloadMessage({required Object title}) => 'Delete "${title}"?';
	String get delete => 'Delete';
	String get cancel => 'Cancel';
	String get downloadFailed => 'Download failed';
	String get paused => 'Paused';
}

// Path: libraries.tabs
class _StringsLibrariesTabsEn {
	_StringsLibrariesTabsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get recommended => 'Recommended';
	String get browse => 'Browse';
	String get collections => 'Collections';
	String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get all => 'All';
	String get movies => 'Movies';
	String get shows => 'TV Shows';
	String get seasons => 'Seasons';
	String get episodes => 'Episodes';
	String get folders => 'Folders';
}

// Path: <root>
class _StringsDe extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsDe.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _StringsDe _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppDe app = _StringsAppDe._(_root);
	@override late final _StringsAuthDe auth = _StringsAuthDe._(_root);
	@override late final _StringsCommonDe common = _StringsCommonDe._(_root);
	@override late final _StringsScreensDe screens = _StringsScreensDe._(_root);
	@override late final _StringsUpdateDe update = _StringsUpdateDe._(_root);
	@override late final _StringsSettingsDe settings = _StringsSettingsDe._(_root);
	@override late final _StringsSearchDe search = _StringsSearchDe._(_root);
	@override late final _StringsHotkeysDe hotkeys = _StringsHotkeysDe._(_root);
	@override late final _StringsPinEntryDe pinEntry = _StringsPinEntryDe._(_root);
	@override late final _StringsFileInfoDe fileInfo = _StringsFileInfoDe._(_root);
	@override late final _StringsMediaMenuDe mediaMenu = _StringsMediaMenuDe._(_root);
	@override late final _StringsAccessibilityDe accessibility = _StringsAccessibilityDe._(_root);
	@override late final _StringsTooltipsDe tooltips = _StringsTooltipsDe._(_root);
	@override late final _StringsVideoControlsDe videoControls = _StringsVideoControlsDe._(_root);
	@override late final _StringsUserStatusDe userStatus = _StringsUserStatusDe._(_root);
	@override late final _StringsMessagesDe messages = _StringsMessagesDe._(_root);
	@override late final _StringsProfileDe profile = _StringsProfileDe._(_root);
	@override late final _StringsSubtitlingStylingDe subtitlingStyling = _StringsSubtitlingStylingDe._(_root);
	@override late final _StringsDialogDe dialog = _StringsDialogDe._(_root);
	@override late final _StringsDiscoverDe discover = _StringsDiscoverDe._(_root);
	@override late final _StringsErrorsDe errors = _StringsErrorsDe._(_root);
	@override late final _StringsVoiceDe voice = _StringsVoiceDe._(_root);
	@override late final _StringsLibrariesDe libraries = _StringsLibrariesDe._(_root);
	@override late final _StringsAboutDe about = _StringsAboutDe._(_root);
	@override late final _StringsServerSelectionDe serverSelection = _StringsServerSelectionDe._(_root);
	@override late final _StringsHubDetailDe hubDetail = _StringsHubDetailDe._(_root);
	@override late final _StringsLogsDe logs = _StringsLogsDe._(_root);
	@override late final _StringsStatsDe stats = _StringsStatsDe._(_root);
	@override late final _StringsLicensesDe licenses = _StringsLicensesDe._(_root);
	@override late final _StringsNavigationDe navigation = _StringsNavigationDe._(_root);
	@override late final _StringsPlaylistsDe playlists = _StringsPlaylistsDe._(_root);
	@override late final _StringsCollectionsDe collections = _StringsCollectionsDe._(_root);
	@override late final _StringsWatchPartyDe watchParty = _StringsWatchPartyDe._(_root);
	@override late final _StringsCatchUpDe catchUp = _StringsCatchUpDe._(_root);
	@override late final _StringsWatchlistDe watchlist = _StringsWatchlistDe._(_root);
	@override late final _StringsLiveTVDe liveTV = _StringsLiveTVDe._(_root);
	@override late final _StringsDvrDe dvr = _StringsDvrDe._(_root);
	@override late final _StringsEpgDe epg = _StringsEpgDe._(_root);
	@override late final _StringsChannelSurfingDe channelSurfing = _StringsChannelSurfingDe._(_root);
	@override late final _StringsMultiviewDe multiview = _StringsMultiviewDe._(_root);
	@override late final _StringsPlayerDe player = _StringsPlayerDe._(_root);
	@override late final _StringsDownloadsDe downloads = _StringsDownloadsDe._(_root);
}

// Path: app
class _StringsAppDe extends _StringsAppEn {
	_StringsAppDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'OpenFlix';
	@override String get loading => 'Lädt...';
}

// Path: auth
class _StringsAuthDe extends _StringsAuthEn {
	_StringsAuthDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get signIn => 'Anmelden';
	@override String get signUp => 'Registrieren';
	@override String get signInWithPlex => 'Bei OpenFlix anmelden';
	@override String get showQRCode => 'QR-Code anzeigen';
	@override String get cancel => 'Abbrechen';
	@override String get authenticate => 'Authentifizieren';
	@override String get retry => 'Erneut versuchen';
	@override String get debugEnterToken => 'Debug: Token eingeben';
	@override String get plexTokenLabel => 'Auth-Token';
	@override String get plexTokenHint => 'Token eingeben';
	@override String get authenticationTimeout => 'Authentifizierung abgelaufen. Bitte erneut versuchen.';
	@override String get scanQRCodeInstruction => 'Diesen QR-Code scannen, um zu authentifizieren.';
	@override String get waitingForAuth => 'Warte auf Authentifizierung...\nBitte Anmeldung im Browser abschließen.';
	@override String get serverUrl => 'Server-URL';
	@override String get serverUrlHint => 'z.B. http://192.168.1.100:32400';
	@override String get username => 'Benutzername';
	@override String get usernameHint => 'Benutzername eingeben';
	@override String get email => 'E-Mail';
	@override String get emailHint => 'E-Mail-Adresse eingeben';
	@override String get password => 'Passwort';
	@override String get passwordHint => 'Passwort eingeben';
	@override String get confirmPassword => 'Passwort bestätigen';
	@override String get confirmPasswordHint => 'Passwort erneut eingeben';
	@override String get displayName => 'Anzeigename';
	@override String get displayNameHint => 'Optionaler Anzeigename';
	@override String get noAccount => 'Noch kein Konto?';
	@override String get haveAccount => 'Bereits ein Konto?';
	@override String get connecting => 'Verbinde mit Server...';
	@override String get loggingIn => 'Anmeldung...';
	@override String get registering => 'Konto wird erstellt...';
	@override String get connectToServer => 'Mit Server verbinden';
	@override String get changeServer => 'Server ändern';
	@override String serverConnected({required Object serverName}) => 'Verbunden mit ${serverName}';
	@override String get invalidServerUrl => 'Bitte gültige Server-URL eingeben';
	@override String get serverConnectionFailed => 'Verbindung zum Server fehlgeschlagen';
	@override String get passwordMismatch => 'Passwörter stimmen nicht überein';
	@override String get usernameRequired => 'Benutzername erforderlich';
	@override String get emailRequired => 'E-Mail erforderlich';
	@override String get passwordRequired => 'Passwort erforderlich';
	@override String get passwordTooShort => 'Passwort muss mindestens 6 Zeichen haben';
	@override String get invalidEmail => 'Bitte gültige E-Mail-Adresse eingeben';
	@override String get firstUserNote => 'Erster Benutzer wird Administrator';
	@override String get howConnecting => 'Wie möchten Sie sich verbinden?';
	@override String get atHome => 'Zu Hause';
	@override String get atHomeDescription => 'Server im lokalen Netzwerk automatisch erkennen';
	@override String get awayFromHome => 'Unterwegs';
	@override String get awayFromHomeDescription => 'Serveradresse manuell eingeben';
	@override String get findYourServer => 'Server finden';
	@override String get searching => 'Suche...';
	@override String get checkingNetwork => 'Netzwerk wird überprüft...';
	@override String get serversFound => 'Server gefunden';
	@override String get scanAgain => 'Erneut suchen';
	@override String get enterManually => 'Manuell eingeben';
	@override String get noServersFound => 'Keine Server in Ihrem Netzwerk gefunden. Stellen Sie sicher, dass Ihr OpenFlix-Server läuft.';
	@override String discoveryFailed({required Object error}) => 'Suche fehlgeschlagen: ${error}';
}

// Path: common
class _StringsCommonDe extends _StringsCommonEn {
	_StringsCommonDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Abbrechen';
	@override String get save => 'Speichern';
	@override String get close => 'Schließen';
	@override String get clear => 'Leeren';
	@override String get reset => 'Zurücksetzen';
	@override String get later => 'Später';
	@override String get submit => 'Senden';
	@override String get confirm => 'Bestätigen';
	@override String get retry => 'Erneut versuchen';
	@override String get playNow => 'Jetzt abspielen';
	@override String get logout => 'Abmelden';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get owned => 'Besitzer';
	@override String get shared => 'Geteilt';
	@override String get current => 'AKTUELL';
	@override String get unknown => 'Unbekannt';
	@override String get refresh => 'Aktualisieren';
	@override String get yes => 'Ja';
	@override String get no => 'Nein';
	@override String get server => 'Server';
	@override String get delete => 'Löschen';
	@override String get shuffle => 'Zufall';
	@override String get addTo => 'Hinzufügen zu...';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get live => 'LIVE';
	@override String get newLabel => 'NEU';
}

// Path: screens
class _StringsScreensDe extends _StringsScreensEn {
	_StringsScreensDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lizenzen';
	@override String get selectServer => 'Server auswählen';
	@override String get switchProfile => 'Profil wechseln';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get search => 'Suche';
	@override String get logs => 'Protokolle';
}

// Path: update
class _StringsUpdateDe extends _StringsUpdateEn {
	_StringsUpdateDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update verfügbar';
	@override String versionAvailable({required Object version}) => 'Version ${version} ist verfügbar';
	@override String currentVersion({required Object version}) => 'Aktuell: ${version}';
	@override String get skipVersion => 'Diese Version überspringen';
	@override String get viewRelease => 'Release anzeigen';
	@override String get latestVersion => 'Aktuellste Version installiert';
	@override String get checkFailed => 'Fehler bei der Updateprüfung';
}

// Path: settings
class _StringsSettingsDe extends _StringsSettingsEn {
	_StringsSettingsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Einstellungen';
	@override String get profile => 'Profil';
	@override String get noProfileSelected => 'Kein Profil ausgewählt';
	@override String get kidsMode => 'Kindermodus';
	@override String get switchProfile => 'Profil wechseln';
	@override String get switchProfileDescription => 'Zu einem anderen Profil wechseln';
	@override String get manageProfiles => 'Profile verwalten';
	@override String get manageProfilesDescription => 'Profile hinzufügen, bearbeiten oder löschen';
	@override String get language => 'Sprache';
	@override String get theme => 'Design';
	@override String get appearance => 'Darstellung';
	@override String get videoPlayback => 'Videowiedergabe';
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get advanced => 'Erweitert';
	@override String get useSeasonPostersDescription => 'Staffelposter statt Serienposter für Episoden anzeigen';
	@override String get showHeroSectionDescription => 'Bereich mit empfohlenen Inhalten auf der Startseite anzeigen';
	@override String get secondsLabel => 'Sekunden';
	@override String get minutesLabel => 'Minuten';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get systemThemeDescription => 'Systemeinstellungen folgen';
	@override String get lightTheme => 'Hell';
	@override String get darkTheme => 'Dunkel';
	@override String get libraryDensity => 'Mediathekdichte';
	@override String get compact => 'Kompakt';
	@override String get compactDescription => 'Kleinere Karten, mehr Elemente sichtbar';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Standardgröße';
	@override String get comfortable => 'Großzügig';
	@override String get comfortableDescription => 'Größere Karten, weniger Elemente sichtbar';
	@override String get viewMode => 'Ansichtsmodus';
	@override String get gridView => 'Raster';
	@override String get gridViewDescription => 'Elemente im Raster anzeigen';
	@override String get listView => 'Liste';
	@override String get listViewDescription => 'Elemente in Listenansicht anzeigen';
	@override String get useSeasonPosters => 'Staffelposter verwenden';
	@override String get showHeroSection => 'Hero-Bereich anzeigen';
	@override String get hardwareDecoding => 'Hardware-Decodierung';
	@override String get hardwareDecodingDescription => 'Hardwarebeschleunigung verwenden, sofern verfügbar';
	@override String get bufferSize => 'Puffergröße';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get subtitleStylingDescription => 'Aussehen von Untertiteln anpassen';
	@override String get smallSkipDuration => 'Kleine Sprungdauer';
	@override String get largeSkipDuration => 'Große Sprungdauer';
	@override String secondsUnit({required Object seconds}) => '${seconds} Sekunden';
	@override String get defaultSleepTimer => 'Standard-Sleep-Timer';
	@override String minutesUnit({required Object minutes}) => '${minutes} Minuten';
	@override String get rememberTrackSelections => 'Spurauswahl pro Serie/Film merken';
	@override String get rememberTrackSelectionsDescription => 'Audio- und Untertitelsprache automatisch speichern, wenn während der Wiedergabe geändert';
	@override String get unwatchedOnly => 'Nur ungesehene';
	@override String get unwatchedOnlyDescription => 'Nur ungesehene Episoden in die Shuffle-Warteschlange aufnehmen';
	@override String get shuffleOrderNavigation => 'Navigation der Shuffle-Reihenfolge';
	@override String get shuffleOrderNavigationDescription => 'Weiter/Zurück folgt der zufälligen Reihenfolge';
	@override String get loopShuffleQueue => 'Shuffle-Warteschlange wiederholen';
	@override String get loopShuffleQueueDescription => 'Warteschlange neu starten, wenn das Ende erreicht ist';
	@override String get videoPlayerControls => 'Videoplayer-Steuerung';
	@override String get keyboardShortcuts => 'Tastenkürzel';
	@override String get keyboardShortcutsDescription => 'Tastenkürzel anpassen';
	@override String get debugLogging => 'Debug-Protokollierung';
	@override String get debugLoggingDescription => 'Detaillierte Protokolle zur Fehleranalyse aktivieren';
	@override String get viewLogs => 'Protokolle anzeigen';
	@override String get viewLogsDescription => 'App-Protokolle anzeigen';
	@override String get clearCache => 'Cache löschen';
	@override String get clearCacheDescription => 'Löscht alle zwischengespeicherten Bilder und Daten. Die App kann danach langsamer laden.';
	@override String get clearCacheSuccess => 'Cache erfolgreich gelöscht';
	@override String get resetSettings => 'Einstellungen zurücksetzen';
	@override String get resetSettingsDescription => 'Alle Einstellungen auf Standard zurücksetzen. Dies kann nicht rückgängig gemacht werden.';
	@override String get resetSettingsSuccess => 'Einstellungen erfolgreich zurückgesetzt';
	@override String get shortcutsReset => 'Tastenkürzel auf Standard zurückgesetzt';
	@override String get about => 'Über';
	@override String get aboutDescription => 'App-Informationen und Lizenzen';
	@override String get updates => 'Updates';
	@override String get updateAvailable => 'Update verfügbar';
	@override String get checkForUpdates => 'Nach Updates suchen';
	@override String get validationErrorEnterNumber => 'Bitte eine gültige Zahl eingeben';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Dauer muss zwischen ${min} und ${max} ${unit} liegen';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Tastenkürzel bereits zugewiesen an ${action}';
	@override String shortcutUpdated({required Object action}) => 'Tastenkürzel aktualisiert für ${action}';
	@override String get autoSkip => 'Automatisches Überspringen';
	@override String get autoSkipIntro => 'Intro automatisch überspringen';
	@override String get autoSkipIntroDescription => 'Intro-Marker nach wenigen Sekunden automatisch überspringen';
	@override String get autoSkipCredits => 'Abspann automatisch überspringen';
	@override String get autoSkipCreditsDescription => 'Abspann automatisch überspringen und nächste Episode abspielen';
	@override String get autoSkipDelay => 'Verzögerung für automatisches Überspringen';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten';
	@override String get metadataSection => 'Metadaten';
	@override String get tmdbApiKey => 'TMDB-API-Schlüssel';
	@override String get tmdbApiKeyDescription => 'TMDB für erweiterte Metadaten konfigurieren';
	@override String get tmdbApiKeyConfigured => 'API-Schlüssel konfiguriert';
	@override String get tmdbApiKeyHint => 'API-Schlüssel von themoviedb.org erhalten';
	@override String get tmdbApiKeyPlaceholder => 'TMDB-API-Schlüssel eingeben';
	@override String get apiKey => 'API-Schlüssel';
	@override String get tmdbApiKeySaved => 'TMDB-API-Schlüssel gespeichert';
	@override String get tmdbApiKeyCleared => 'TMDB-API-Schlüssel gelöscht';
	@override String get parentalControls => 'Kindersicherung';
	@override String get enableParentalControls => 'Kindersicherung aktivieren';
	@override String get enableParentalControlsDescription => 'Inhalte basierend auf Altersfreigaben einschränken';
	@override String get setPin => 'PIN festlegen';
	@override String get setPinDescription => 'Geben Sie eine 4-stellige PIN zum Schutz der Kindersicherung ein';
	@override String get confirmPin => 'PIN bestätigen';
	@override String get confirmPinDescription => 'Geben Sie die PIN zur Bestätigung erneut ein';
	@override String get enterPin => 'PIN eingeben';
	@override String get enterPinDescription => 'Geben Sie Ihre Kindersicherungs-PIN ein';
	@override String get changePin => 'PIN ändern';
	@override String get changePinDescription => 'Ändern Sie Ihre Kindersicherungs-PIN';
	@override String get pinSet => 'Kindersicherungs-PIN erfolgreich festgelegt';
	@override String get pinMismatch => 'PINs stimmen nicht überein. Bitte versuchen Sie es erneut.';
	@override String get incorrectPin => 'Falsche PIN. Bitte versuchen Sie es erneut.';
	@override String get maxMovieRating => 'Maximale Filmfreigabe';
	@override String get maxTvRating => 'Maximale TV-Freigabe';
}

// Path: search
class _StringsSearchDe extends _StringsSearchEn {
	_StringsSearchDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Filme, Serien, Musik suchen...';
	@override String get tryDifferentTerm => 'Anderen Suchbegriff versuchen';
	@override String get searchYourMedia => 'Medien durchsuchen';
	@override String get enterTitleActorOrKeyword => 'Titel, Schauspieler oder Stichwort eingeben';
	@override String get recentSearches => 'Letzte Suchen';
	@override String get clear => 'Löschen';
	@override String get voiceSearch => 'Sprachsuche';
	@override String get listening => 'Höre zu...';
	@override String get speakNow => 'Jetzt sprechen';
	@override String get all => 'Alle';
	@override String get movies => 'Filme';
	@override String get tvShows => 'Serien';
	@override String get music => 'Musik';
}

// Path: hotkeys
class _StringsHotkeysDe extends _StringsHotkeysEn {
	_StringsHotkeysDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Tastenkürzel festlegen für ${actionName}';
	@override String get clearShortcut => 'Kürzel löschen';
}

// Path: pinEntry
class _StringsPinEntryDe extends _StringsPinEntryEn {
	_StringsPinEntryDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'PIN eingeben';
	@override String get showPin => 'PIN anzeigen';
	@override String get hidePin => 'PIN verbergen';
}

// Path: fileInfo
class _StringsFileInfoDe extends _StringsFileInfoEn {
	_StringsFileInfoDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dateiinfo';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'Datei';
	@override String get advanced => 'Erweitert';
	@override String get codec => 'Codec';
	@override String get resolution => 'Auflösung';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Bildrate';
	@override String get aspectRatio => 'Seitenverhältnis';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Farbtiefe';
	@override String get colorSpace => 'Farbraum';
	@override String get colorRange => 'Farbbereich';
	@override String get colorPrimaries => 'Primärfarben';
	@override String get chromaSubsampling => 'Chroma-Subsampling';
	@override String get channels => 'Kanäle';
	@override String get path => 'Pfad';
	@override String get size => 'Größe';
	@override String get container => 'Container';
	@override String get duration => 'Dauer';
	@override String get optimizedForStreaming => 'Für Streaming optimiert';
	@override String get has64bitOffsets => '64-Bit-Offsets';
}

// Path: mediaMenu
class _StringsMediaMenuDe extends _StringsMediaMenuEn {
	_StringsMediaMenuDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Als gesehen markieren';
	@override String get markAsUnwatched => 'Als ungesehen markieren';
	@override String get removeFromContinueWatching => 'Aus ‚Weiterschauen‘ entfernen';
	@override String get goToSeries => 'Zur Serie';
	@override String get goToSeason => 'Zur Staffel';
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get fileInfo => 'Dateiinfo';
}

// Path: accessibility
class _StringsAccessibilityDe extends _StringsAccessibilityEn {
	_StringsAccessibilityDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, Film';
	@override String mediaCardShow({required Object title}) => '${title}, Serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'angesehen';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} Prozent angesehen';
	@override String get mediaCardUnwatched => 'ungeschaut';
	@override String get tapToPlay => 'Zum Abspielen tippen';
}

// Path: tooltips
class _StringsTooltipsDe extends _StringsTooltipsEn {
	_StringsTooltipsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get markAsWatched => 'Als gesehen markieren';
	@override String get markAsUnwatched => 'Als ungesehen markieren';
}

// Path: videoControls
class _StringsVideoControlsDe extends _StringsVideoControlsEn {
	_StringsVideoControlsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Untertitel';
	@override String get resetToZero => 'Auf 0 ms zurücksetzen';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} spielt später';
	@override String playsEarlier({required Object label}) => '${label} spielt früher';
	@override String get noOffset => 'Kein Offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Bild füllen';
	@override String get stretch => 'Strecken';
	@override String get lockRotation => 'Rotation sperren';
	@override String get unlockRotation => 'Rotation entsperren';
	@override String get lockScreen => 'Bildschirm sperren';
	@override String get unlockScreen => 'Bildschirm entsperren';
	@override String get screenLockButton => 'Bildschirmsperre';
	@override String get screenLocked => 'Bildschirm gesperrt';
	@override String get tapToUnlock => 'Zum Entsperren tippen';
	@override String get sleepTimer => 'Schlaftimer';
	@override String get timerActive => 'Schlaftimer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert';
	@override String get sleepTimerCompleted => 'Schlaftimer abgelaufen – Wiedergabe pausiert';
	@override String get playButton => 'Wiedergeben';
	@override String get pauseButton => 'Pause';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} Sekunden zurück';
	@override String seekForwardButton({required Object seconds}) => '${seconds} Sekunden vor';
	@override String get previousButton => 'Vorherige Episode';
	@override String get nextButton => 'Nächste Episode';
	@override String get previousChapterButton => 'Vorheriges Kapitel';
	@override String get nextChapterButton => 'Nächstes Kapitel';
	@override String get volumeButton => 'Lautstärke';
	@override String get muteButton => 'Stumm schalten';
	@override String get unmuteButton => 'Stummschaltung aufheben';
	@override String get settingsButton => 'Videoeinstellungen';
	@override String get audioTrackButton => 'Tonspuren';
	@override String get subtitlesButton => 'Untertitel';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionsButton => 'Videoversionen';
	@override String get aspectRatioButton => 'Seitenverhältnis';
	@override String get fullscreenButton => 'Vollbild aktivieren';
	@override String get exitFullscreenButton => 'Vollbild verlassen';
	@override String get rotationLockButton => 'Dreh­sperre';
	@override String get timelineSlider => 'Video-Zeitleiste';
	@override String get volumeSlider => 'Lautstärkepegel';
	@override String get backButton => 'Zurück';
}

// Path: userStatus
class _StringsUserStatusDe extends _StringsUserStatusEn {
	_StringsUserStatusDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Eigentümer';
	@override String get restricted => 'Eingeschränkt';
	@override String get protected => 'Geschützt';
	@override String get current => 'AKTUELL';
}

// Path: messages
class _StringsMessagesDe extends _StringsMessagesEn {
	_StringsMessagesDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Als gesehen markiert';
	@override String get markedAsUnwatched => 'Als ungesehen markiert';
	@override String get removedFromContinueWatching => 'Aus ‚Weiterschauen‘ entfernt';
	@override String errorLoading({required Object error}) => 'Fehler: ${error}';
	@override String get fileInfoNotAvailable => 'Dateiinfo nicht verfügbar';
	@override String errorLoadingFileInfo({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}';
	@override String get errorLoadingSeries => 'Fehler beim Laden der Serie';
	@override String get errorLoadingSeason => 'Fehler beim Laden der Staffel';
	@override String get musicNotSupported => 'Musikwiedergabe wird noch nicht unterstützt';
	@override String get logsCleared => 'Protokolle gelöscht';
	@override String get logsCopied => 'Protokolle in Zwischenablage kopiert';
	@override String get noLogsAvailable => 'Keine Protokolle verfügbar';
	@override String libraryScanning({required Object title}) => 'Scanne „${title}“...';
	@override String libraryScanStarted({required Object title}) => 'Mediathekscan gestartet für „${title}“';
	@override String libraryScanFailed({required Object error}) => 'Fehler beim Scannen der Mediathek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadaten werden aktualisiert für „${title}“...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“';
	@override String metadataRefreshFailed({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}';
	@override String get noTokenFound => 'Kein Token gefunden. Bitte erneut anmelden.';
	@override String get logoutConfirm => 'Abmeldung wirklich durchführen?';
	@override String get noSeasonsFound => 'Keine Staffeln gefunden';
	@override String get noEpisodesFound => 'Keine Episoden in der ersten Staffel gefunden';
	@override String get noEpisodesFoundGeneral => 'Keine Episoden gefunden';
	@override String get noResultsFound => 'Keine Ergebnisse gefunden';
	@override String sleepTimerSet({required Object label}) => 'Sleep-Timer gesetzt auf ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
	@override String get noItemsAvailable => 'Keine Elemente verfügbar';
	@override String get failedToCreatePlayQueue => 'Wiedergabewarteschlange konnte nicht erstellt werden';
	@override String get failedToCreatePlayQueueNoItems => 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente';
	@override String failedPlayback({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}';
}

// Path: profile
class _StringsProfileDe extends _StringsProfileEn {
	_StringsProfileDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => 'Keine Benutzer verfügbar';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingDe extends _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Stiloptionen';
	@override String get fontSize => 'Schriftgröße';
	@override String get textColor => 'Textfarbe';
	@override String get borderSize => 'Rahmengröße';
	@override String get borderColor => 'Rahmenfarbe';
	@override String get backgroundOpacity => 'Hintergrunddeckkraft';
	@override String get backgroundColor => 'Hintergrundfarbe';
}

// Path: dialog
class _StringsDialogDe extends _StringsDialogEn {
	_StringsDialogDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Aktion bestätigen';
	@override String get areYouSure => 'Aktion wirklich ausführen?';
	@override String get cancel => 'Abbrechen';
	@override String get playNow => 'Jetzt abspielen';
}

// Path: discover
class _StringsDiscoverDe extends _StringsDiscoverEn {
	_StringsDiscoverDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Entdecken';
	@override String get switchProfile => 'Profil wechseln';
	@override String get switchServer => 'Server wechseln';
	@override String get logout => 'Abmelden';
	@override String get noContentAvailable => 'Kein Inhalt verfügbar';
	@override String get addMediaToLibraries => 'Medien zur Mediathek hinzufügen';
	@override String get continueWatching => 'Weiterschauen';
	@override String get recentlyAdded => 'Kürzlich hinzugefügt';
	@override String get play => 'Abspielen';
	@override String get resume => 'Fortsetzen';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}, E${episode} - Abspielen';
	@override String resumeEpisode({required Object season, required Object episode}) => 'S${season}, E${episode} - Fortsetzen';
	@override String get pause => 'Pause';
	@override String get overview => 'Übersicht';
	@override String get cast => 'Besetzung';
	@override String get seasons => 'Staffeln';
	@override String get studio => 'Studio';
	@override String get rating => 'Altersfreigabe';
	@override String get watched => 'Gesehen';
	@override String episodeCount({required Object count}) => '${count} Episoden';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched} von ${total} gesehen';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} Min übrig';
	@override String get whatsOnNow => 'Jetzt läuft';
	@override String get channelGuide => 'Programmführer';
	@override String get liveNow => 'Jetzt Live';
	@override String get topTen => 'Top 10';
	@override String get newBadge => 'NEU';
	@override String get liveBadge => 'LIVE';
	@override String get goodMorning => 'Good morning';
	@override String get goodAfternoon => 'Good afternoon';
	@override String get goodEvening => 'Good evening';
	@override String get defaultUser => 'Guest';
	@override String get yourNextWatch => 'Your Next Watch';
	@override String pickedForYou({required Object name}) => 'Picked just for you, ${name}';
	@override String get surpriseMe => 'Surprise Me';
	@override String get randomPicker => 'Random Movie Picker';
	@override String get noMoviesFound => 'No movies found in your library';
	@override String get spinning => 'Picking something great...';
	@override String get spinAgain => 'Spin Again';
	@override String get calendar => 'Calendar';
	@override String get today => 'Today';
	@override String get item => 'item';
	@override String get items => 'items';
	@override String get loadingMovies => 'Lade deine Filme...';
	@override String get noContentOnDate => 'No content added on this date';
	@override String get noEpgData => 'Keine Programminformationen';
}

// Path: errors
class _StringsErrorsDe extends _StringsErrorsEn {
	_StringsErrorsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Suche fehlgeschlagen: ${error}';
	@override String connectionTimeout({required Object context}) => 'Zeitüberschreitung beim Laden von ${context}';
	@override String get connectionFailed => 'Verbindung zum Plex-Server fehlgeschlagen';
	@override String failedToLoad({required Object context, required Object error}) => 'Fehler beim Laden von ${context}: ${error}';
	@override String get noClientAvailable => 'Kein Client verfügbar';
	@override String authenticationFailed({required Object error}) => 'Authentifizierung fehlgeschlagen: ${error}';
	@override String get couldNotLaunchUrl => 'Auth-URL konnte nicht geöffnet werden';
	@override String get pleaseEnterToken => 'Bitte Token eingeben';
	@override String get invalidToken => 'Ungültiges Token';
	@override String failedToVerifyToken({required Object error}) => 'Token-Verifizierung fehlgeschlagen: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
	@override String get connectionFailedGeneric => 'Verbindung fehlgeschlagen';
	@override String failedToRemove({required Object error}) => 'Entfernen fehlgeschlagen: ${error}';
}

// Path: voice
class _StringsVoiceDe extends _StringsVoiceEn {
	_StringsVoiceDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get notAvailable => 'Sprachsteuerung ist nicht verfügbar';
	@override String commandNotRecognized({required Object command}) => 'Befehl nicht erkannt: "${command}"';
}

// Path: libraries
class _StringsLibrariesDe extends _StringsLibrariesEn {
	_StringsLibrariesDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mediatheken';
	@override String get scanLibraryFiles => 'Mediatheksdateien scannen';
	@override String get scanLibrary => 'Mediathek scannen';
	@override String get analyze => 'Analysieren';
	@override String get analyzeLibrary => 'Mediathek analysieren';
	@override String get refreshMetadata => 'Metadaten aktualisieren';
	@override String get emptyTrash => 'Papierkorb leeren';
	@override String emptyingTrash({required Object title}) => 'Papierkorb für „${title}“ wird geleert...';
	@override String trashEmptied({required Object title}) => 'Papierkorb für „${title}“ geleert';
	@override String failedToEmptyTrash({required Object error}) => 'Papierkorb konnte nicht geleert werden: ${error}';
	@override String analyzing({required Object title}) => 'Analysiere „${title}“...';
	@override String analysisStarted({required Object title}) => 'Analyse gestartet für „${title}“';
	@override String failedToAnalyze({required Object error}) => 'Analyse der Mediathek fehlgeschlagen: ${error}';
	@override String get noLibrariesFound => 'Keine Mediatheken gefunden';
	@override String get thisLibraryIsEmpty => 'Diese Mediathek ist leer';
	@override String get all => 'Alle';
	@override String get clearAll => 'Alle löschen';
	@override String scanLibraryConfirm({required Object title}) => '„${title}“ wirklich scannen?';
	@override String analyzeLibraryConfirm({required Object title}) => '„${title}“ wirklich analysieren?';
	@override String refreshMetadataConfirm({required Object title}) => 'Metadaten für „${title}“ wirklich aktualisieren?';
	@override String emptyTrashConfirm({required Object title}) => 'Papierkorb für „${title}“ wirklich leeren?';
	@override String get manageLibraries => 'Mediatheken verwalten';
	@override String get sort => 'Sortieren';
	@override String get sortBy => 'Sortieren nach';
	@override String get filters => 'Filter';
	@override String loadingLibraryWithCount({required Object count}) => 'Lade Mediathek... (${count} Elemente geladen)';
	@override String get confirmActionMessage => 'Aktion wirklich durchführen?';
	@override String get showLibrary => 'Mediathek anzeigen';
	@override String get hideLibrary => 'Mediathek ausblenden';
	@override String get libraryOptions => 'Mediatheksoptionen';
	@override String get content => 'Bibliotheksinhalt';
	@override String get selectLibrary => 'Bibliothek auswählen';
	@override String filtersWithCount({required Object count}) => 'Filter (${count})';
	@override String get noRecommendations => 'Keine Empfehlungen verfügbar';
	@override String get noCollections => 'Keine Sammlungen in dieser Mediathek';
	@override String get noFoldersFound => 'Keine Ordner gefunden';
	@override String get folders => 'Ordner';
	@override late final _StringsLibrariesTabsDe tabs = _StringsLibrariesTabsDe._(_root);
	@override late final _StringsLibrariesGroupingsDe groupings = _StringsLibrariesGroupingsDe._(_root);
}

// Path: about
class _StringsAboutDe extends _StringsAboutEn {
	_StringsAboutDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Über';
	@override String get openSourceLicenses => 'Open-Source-Lizenzen';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Ein schöner Plex-Client für Flutter';
	@override String get viewLicensesDescription => 'Lizenzen von Drittanbieter-Bibliotheken anzeigen';
}

// Path: serverSelection
class _StringsServerSelectionDe extends _StringsServerSelectionEn {
	_StringsServerSelectionDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get connectingToServer => 'Verbinde mit Server...';
	@override String get connectingToAllServers => 'Verbinde mit allen Servern...';
	@override String get connectToAllServers => 'Mit allen Servern verbinden';
	@override String get allServerConnectionsFailed => 'Verbindung zu allen Servern fehlgeschlagen. Bitte Netzwerk prüfen und erneut versuchen.';
	@override String foundServers({required Object count}) => '${count} Server gefunden';
	@override String get orSelectIndividually => 'Oder einzelnen Server auswählen:';
	@override String get serverDebugCopied => 'Server-Debugdaten kopiert';
	@override String get copyDebugData => 'Debugdaten kopieren';
	@override String get noServersFound => 'Keine Server gefunden';
	@override String malformedServerData({required Object count}) => '${count} Server mit fehlerhaften Daten gefunden. Keine gültigen Server verfügbar.';
	@override String get incompleteServerInfo => 'Einige Serverinformationen sind unvollständig und wurden übersprungen. Plex.tv-Konto prüfen.';
	@override String get incompleteConnectionInfo => 'Serververbindungsinformationen unvollständig. Bitte erneut versuchen.';
	@override String malformedServerInfo({required Object message}) => 'Serverinformationen fehlerhaft: ${message}';
	@override String get networkConnectionFailed => 'Netzwerkverbindung fehlgeschlagen. Internetverbindung prüfen und erneut versuchen.';
	@override String get authenticationFailed => 'Authentifizierung fehlgeschlagen. Bitte erneut anmelden.';
	@override String get plexServiceUnavailable => 'Plex-Dienst nicht verfügbar. Bitte später erneut versuchen.';
	@override String failedToLoadServers({required Object error}) => 'Server konnten nicht geladen werden: ${error}';
}

// Path: hubDetail
class _StringsHubDetailDe extends _StringsHubDetailEn {
	_StringsHubDetailDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Erscheinungsjahr';
	@override String get dateAdded => 'Hinzugefügt am';
	@override String get rating => 'Bewertung';
	@override String get noItemsFound => 'Keine Elemente gefunden';
}

// Path: logs
class _StringsLogsDe extends _StringsLogsEn {
	_StringsLogsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Protokolle';
	@override String get clearLogs => 'Protokolle löschen';
	@override String get copyLogs => 'Protokolle kopieren';
	@override String get exportLogs => 'Protokolle exportieren';
	@override String get noLogsToShow => 'Keine Protokolle zum Anzeigen';
	@override String get error => 'Fehler:';
	@override String get stackTrace => 'Stacktrace:';
}

// Path: stats
class _StringsStatsDe extends _StringsStatsEn {
	_StringsStatsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wiedergabestatistik';
	@override String get totalWatchTime => 'Gesamte Wiedergabezeit';
	@override String get moviesWatched => 'Filme gesehen';
	@override String get episodesWatched => 'Episoden gesehen';
	@override String get avgPerDay => 'Durchschnitt pro Tag';
	@override String get topGenres => 'Top-Genres';
	@override String get monthlyActivity => 'Monatliche Aktivität';
	@override String get noData => 'Noch kein Wiedergabeverlauf';
	@override String get startWatching => 'Schauen Sie etwas, um Ihre Statistiken zu sehen';
	@override String get days => 'Tage';
}

// Path: licenses
class _StringsLicensesDe extends _StringsLicensesEn {
	_StringsLicensesDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Verwandte Pakete';
	@override String get license => 'Lizenz';
	@override String licenseNumber({required Object number}) => 'Lizenz ${number}';
	@override String licensesCount({required Object count}) => '${count} Lizenzen';
}

// Path: navigation
class _StringsNavigationDe extends _StringsNavigationEn {
	_StringsNavigationDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get home => 'Start';
	@override String get search => 'Suche';
	@override String get libraries => 'Mediatheken';
	@override String get livetv => 'Live TV';
	@override String get settings => 'Einstellungen';
}

// Path: playlists
class _StringsPlaylistsDe extends _StringsPlaylistsEn {
	_StringsPlaylistsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wiedergabelisten';
	@override String get noPlaylists => 'Keine Wiedergabelisten gefunden';
	@override String get create => 'Wiedergabeliste erstellen';
	@override String get newPlaylist => 'Neue Wiedergabeliste';
	@override String get playlistName => 'Name der Wiedergabeliste';
	@override String get enterPlaylistName => 'Name der Wiedergabeliste eingeben';
	@override String get edit => 'Wiedergabeliste bearbeiten';
	@override String get delete => 'Wiedergabeliste löschen';
	@override String get addTo => 'Zur Wiedergabeliste hinzufügen';
	@override String get addItems => 'Elemente hinzufügen';
	@override String get removeItem => 'Aus Wiedergabeliste entfernen';
	@override String get clearPlaylist => 'Wiedergabeliste leeren';
	@override String get playAll => 'Alle abspielen';
	@override String get shuffle => 'Zufällig';
	@override String get smartPlaylist => 'Intelligente Wiedergabeliste';
	@override String get regularPlaylist => 'Normale Wiedergabeliste';
	@override String itemCount({required Object count}) => '${count} Elemente';
	@override String get oneItem => '1 Element';
	@override String get emptyPlaylist => 'Diese Wiedergabeliste ist leer';
	@override String get deleteConfirm => 'Wiedergabeliste löschen?';
	@override String deleteMessage({required Object name}) => 'Soll "${name}" wirklich gelöscht werden?';
	@override String get created => 'Wiedergabeliste erstellt';
	@override String get updated => 'Wiedergabeliste aktualisiert';
	@override String get deleted => 'Wiedergabeliste gelöscht';
	@override String get itemAdded => 'Zur Wiedergabeliste hinzugefügt';
	@override String get itemRemoved => 'Aus Wiedergabeliste entfernt';
	@override String get selectPlaylist => 'Wiedergabeliste auswählen';
	@override String get createNewPlaylist => 'Neue Wiedergabeliste erstellen';
	@override String get errorCreating => 'Wiedergabeliste konnte nicht erstellt werden';
	@override String get errorDeleting => 'Wiedergabeliste konnte nicht gelöscht werden';
	@override String get errorLoading => 'Wiedergabelisten konnten nicht geladen werden';
	@override String get errorAdding => 'Konnte nicht zur Wiedergabeliste hinzugefügt werden';
	@override String get errorReordering => 'Element der Wiedergabeliste konnte nicht neu geordnet werden';
	@override String get errorRemoving => 'Konnte nicht aus der Wiedergabeliste entfernt werden';
	@override String get playlist => 'Wiedergabeliste';
}

// Path: collections
class _StringsCollectionsDe extends _StringsCollectionsEn {
	_StringsCollectionsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sammlungen';
	@override String get collection => 'Sammlung';
	@override String get empty => 'Sammlung ist leer';
	@override String get noItems => 'Keine Elemente in dieser Sammlung';
	@override String get unknownLibrarySection => 'Löschen nicht möglich: Unbekannte Bibliothekssektion';
	@override String get deleteCollection => 'Sammlung löschen';
	@override String deleteConfirm({required Object title}) => 'Sind Sie sicher, dass Sie "${title}" löschen möchten? Dies kann nicht rückgängig gemacht werden.';
	@override String get deleted => 'Sammlung gelöscht';
	@override String get deleteFailed => 'Sammlung konnte nicht gelöscht werden';
	@override String deleteFailedWithError({required Object error}) => 'Sammlung konnte nicht gelöscht werden: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Sammlungselemente konnten nicht geladen werden: ${error}';
	@override String get addTo => 'Zur Sammlung hinzufügen';
	@override String get selectCollection => 'Sammlung auswählen';
	@override String get createNewCollection => 'Neue Sammlung erstellen';
	@override String get collectionName => 'Sammlungsname';
	@override String get enterCollectionName => 'Sammlungsnamen eingeben';
	@override String get addedToCollection => 'Zur Sammlung hinzugefügt';
	@override String get errorAddingToCollection => 'Fehler beim Hinzufügen zur Sammlung';
	@override String get created => 'Sammlung erstellt';
	@override String get removeFromCollection => 'Aus Sammlung entfernen';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" aus dieser Sammlung entfernen?';
	@override String get removedFromCollection => 'Aus Sammlung entfernt';
	@override String get removeFromCollectionFailed => 'Entfernen aus Sammlung fehlgeschlagen';
	@override String removeFromCollectionError({required Object error}) => 'Fehler beim Entfernen aus der Sammlung: ${error}';
}

// Path: watchParty
class _StringsWatchPartyDe extends _StringsWatchPartyEn {
	_StringsWatchPartyDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Watch Party';
	@override String get startParty => 'Watch Party starten';
	@override String get joinParty => 'Party beitreten';
	@override String get enterCode => 'Party-Code eingeben';
	@override String get shareCode => 'Diesen Code teilen';
	@override String get friendsCanJoin => 'Freunde können mit diesem Code beitreten';
	@override String get participants => 'Teilnehmer';
	@override String get host => 'Host';
	@override String get endParty => 'Party beenden';
	@override String get leaveParty => 'Party verlassen';
	@override String get partyEnded => 'Watch Party beendet';
	@override String get chat => 'Chat';
	@override String get typeMessage => 'Nachricht eingeben...';
	@override String joined({required Object name}) => '${name} ist beigetreten';
	@override String left({required Object name}) => '${name} hat verlassen';
	@override String get syncedPlayback => 'Wiedergabe ist mit der Party synchronisiert';
	@override String get hostControls => 'Nur der Host kann die Wiedergabe steuern';
	@override String get creating => 'Party wird erstellt...';
	@override String get joining => 'Beitritt zur Party...';
	@override String get createFailed => 'Party konnte nicht erstellt werden';
	@override String get joinFailed => 'Beitritt zur Party fehlgeschlagen';
	@override String get invalidCode => 'Ungültiger Party-Code';
	@override String get gotIt => 'Verstanden';
}

// Path: catchUp
class _StringsCatchUpDe extends _StringsCatchUpEn {
	_StringsCatchUpDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Catch Up TV';
	@override String get startOver => 'Von Anfang an';
	@override String get startOverDescription => 'Von Anfang an schauen';
	@override String get watchFromBeginning => 'Von Anfang an schauen?';
	@override String alreadyStarted({required Object title}) => '"${title}" hat bereits begonnen. Sie können von Anfang an schauen.';
	@override String get watchLive => 'Live schauen';
	@override String get programsAvailable => 'Verfügbare Sendungen';
	@override String get noProgramsAvailable => 'Keine Catch-up Sendungen verfügbar';
	@override String get programsWillAppear => 'Sendungen erscheinen hier, wenn sie ausgestrahlt werden';
	@override String get unavailable => 'Nicht verfügbar';
	@override String get bufferNotReady => 'Puffer noch nicht bereit';
	@override String get rewind => 'Zurückspulen';
	@override String get timeshiftEnabled => 'Timeshift aktiviert';
	@override String goBackTo({required Object time}) => 'Zurück zu ${time}';
}

// Path: watchlist
class _StringsWatchlistDe extends _StringsWatchlistEn {
	_StringsWatchlistDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Meine Merkliste';
	@override String get all => 'Alle';
	@override String get movies => 'Filme';
	@override String get shows => 'Serien';
	@override String get episodes => 'Episoden';
	@override String get empty => 'Ihre Merkliste ist leer';
	@override String get emptyHint => 'Fügen Sie Filme und Serien zu Ihrer Merkliste hinzu';
	@override String get noItemsFiltered => 'Keine Elemente entsprechen diesem Filter';
	@override String get removeTitle => 'Von Merkliste entfernen';
	@override String removeConfirm({required Object title}) => '"${title}" von Ihrer Merkliste entfernen?';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get clearAllTitle => 'Merkliste leeren';
	@override String clearAllConfirm({required Object count}) => 'Alle ${count} Elemente von Ihrer Merkliste entfernen?';
	@override String get clearAll => 'Alle löschen';
	@override String get addedToday => 'Heute hinzugefügt';
	@override String get addedYesterday => 'Gestern hinzugefügt';
	@override String addedDaysAgo({required Object days}) => 'Vor ${days} Tagen hinzugefügt';
	@override String addedOn({required Object date}) => 'Hinzugefügt am ${date}';
	@override String get addToWatchlist => 'Zur Merkliste hinzufügen';
	@override String get removeFromWatchlist => 'Von Merkliste entfernen';
	@override String get addedToWatchlist => 'Zur Merkliste hinzugefügt';
	@override String get removedFromWatchlist => 'Von Merkliste entfernt';
}

// Path: liveTV
class _StringsLiveTVDe extends _StringsLiveTVEn {
	_StringsLiveTVDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live TV';
	@override String get guide => 'Guide';
	@override String get dvr => 'DVR';
	@override String get multiview => 'Multiview';
	@override String get allChannels => 'Alle Kanäle';
	@override String get favorites => 'Favoriten';
	@override String get noChannels => 'Keine Kanäle verfügbar';
	@override String get addM3USource => 'M3U-Quelle in Server-Einstellungen hinzufügen';
	@override String get recording => 'Aufnahme';
	@override String get recordingNow => 'Jetzt aufnehmen';
	@override String get upNext => 'Als nächstes';
	@override String get noProgram => 'Keine Programminfo';
	@override String get filterByGroup => 'Nach Gruppe filtern';
	@override String get refresh => 'Aktualisieren';
	@override String channelCount({required Object count}) => '${count} Kanäle';
	@override String get nowPlaying => 'Läuft gerade';
	@override String get scheduleRecording => 'Aufnahme planen';
	@override String get onNow => 'Jetzt';
	@override String endsAt({required Object time}) => 'Endet um ${time}';
	@override String startsAt({required Object time}) => 'Beginnt um ${time}';
	@override String playbackError({required Object error}) => 'Wiedergabefehler: ${error}';
	@override String get noPreviousChannel => 'Kein vorheriger Sender';
	@override String switchedTo({required Object channel}) => 'Gewechselt zu: ${channel}';
	@override String get startingFromBeginning => 'Starte Sendung von Anfang...';
	@override String failedToStartOver({required Object error}) => 'Neustart fehlgeschlagen: ${error}';
	@override String playingProgram({required Object title}) => 'Wiedergabe: ${title}';
	@override String failedToPlayProgram({required Object error}) => 'Sendung abspielen fehlgeschlagen: ${error}';
	@override String get addedToFavorites => 'Zu Favoriten hinzugefügt';
	@override String get removedFromFavorites => 'Aus Favoriten entfernt';
	@override String failedToUpdateFavorite({required Object error}) => 'Favorit aktualisieren fehlgeschlagen: ${error}';
	@override String get pipNotSupported => 'Bild-in-Bild wird auf dieser Plattform nicht unterstützt';
	@override String get enteredPipMode => 'Bild-in-Bild-Modus aktiviert';
	@override String get exitedPipMode => 'Bild-in-Bild-Modus beendet';
	@override String aspectRatioChanged({required Object mode}) => 'Seitenverhältnis: ${mode}';
	@override String get tune => 'Einschalten';
	@override String get retry => 'Wiederholen';
	@override String get noChannelsMatchFilter => 'Keine Sender entsprechen dem Filter';
	@override String get skipCommercial => 'Werbung überspringen';
}

// Path: dvr
class _StringsDvrDe extends _StringsDvrEn {
	_StringsDvrDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'DVR';
	@override String get recordings => 'Aufnahmen';
	@override String get seriesRules => 'Serienregeln';
	@override String get noRecordings => 'Keine Aufnahmen';
	@override String get noRules => 'Keine Serienregeln';
	@override String get scheduleFromGuide => 'Aufnahmen vom TV-Guide planen';
	@override String get createRulesHint => 'Regeln für Auto-Aufnahme erstellen';
	@override String get storage => 'Speicher';
	@override String recordingsCount({required Object count}) => '${count} Aufnahmen';
	@override String get all => 'Alle';
	@override String get scheduled => 'Geplant';
	@override String get completed => 'Fertig';
	@override String get failed => 'Fehlgeschlagen';
	@override String get deleteRecording => 'Aufnahme löschen?';
	@override String get deleteRule => 'Serienregel löschen?';
	@override String get sortByDate => 'Datum';
	@override String get sortByTitle => 'Titel';
	@override String get sortBySize => 'Größe';
	@override String get playRecording => 'Aufnahme abspielen';
	@override String keepPolicy({required Object count}) => '${count} Folgen behalten';
	@override String get keepAll => 'Alle behalten';
	@override String get recordingScheduled => 'Aufnahme geplant';
	@override String get scheduleRecordingTitle => 'Aufnahme planen';
	@override String get schedule => 'Planen';
	@override String get cancel => 'Abbrechen';
}

// Path: epg
class _StringsEpgDe extends _StringsEpgEn {
	_StringsEpgDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV Guide';
	@override String get now => 'Jetzt';
	@override String get today => 'Heute';
	@override String get tomorrow => 'Morgen';
	@override String get noPrograms => 'Keine Programminfos verfügbar';
	@override String get loading => 'Guide wird geladen...';
	@override String get record => 'Aufnehmen';
	@override String get reminder => 'Erinnerung setzen';
	@override String get moreInfo => 'Mehr Info';
	@override String get toggleView => 'Ansicht wechseln';
	@override String get gridView => 'Rasteransicht';
	@override String get nowNextView => 'Jetzt/Gleich Ansicht';
}

// Path: channelSurfing
class _StringsChannelSurfingDe extends _StringsChannelSurfingEn {
	_StringsChannelSurfingDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Zufallswiedergabe';
	@override String get kidsMode => 'Kindermodus';
	@override String get loading => 'Zufallswiedergabe wird geladen...';
	@override String get failedToLoad => 'Inhalt konnte nicht geladen werden';
	@override String get retry => 'Erneut versuchen';
	@override String get noContent => 'Kein Inhalt verfügbar';
	@override String itemsAvailable({required Object count}) => '${count} Elemente verfügbar';
	@override String get startSurfing => 'Starten';
	@override String get pressBackToExit => 'Zurück zum Beenden';
	@override String get description => 'Zufällige Filme und Serien durchgehend abspielen';
	@override String get noServers => 'Keine Server verfügbar';
}

// Path: multiview
class _StringsMultiviewDe extends _StringsMultiviewEn {
	_StringsMultiviewDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Multi-Ansicht';
	@override String get changeLayout => 'Layout ändern (L)';
	@override String get addChannel => 'Kanal hinzufügen (A)';
	@override String get removeChannel => 'Kanal entfernen (R)';
	@override String get swapChannel => 'Kanal wechseln';
	@override String get toggleMute => 'Stumm schalten (M)';
	@override String get selectChannel => 'Kanal auswählen';
	@override String get searchChannels => 'Kanäle suchen...';
	@override String get cancel => 'Abbrechen';
	@override String channelNumber({required Object number}) => 'K. ${number}';
}

// Path: player
class _StringsPlayerDe extends _StringsPlayerEn {
	_StringsPlayerDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get playbackError => 'Wiedergabefehler';
	@override String get error => 'Fehler';
	@override String failedToStartPlayback({required Object error}) => 'Wiedergabe konnte nicht gestartet werden:\n${error}';
	@override String get ok => 'OK';
}

// Path: downloads
class _StringsDownloadsDe extends _StringsDownloadsEn {
	_StringsDownloadsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get deleteAll => 'Alle löschen';
	@override String get deleteAllTitle => 'Alle Downloads löschen?';
	@override String deleteAllMessage({required Object count, required Object size}) => 'Dies löscht alle ${count} Downloads und gibt ${size} Speicherplatz frei.';
	@override String storageUsed({required Object size}) => 'Speicher belegt: ${size}';
	@override String downloading({required Object count}) => 'Wird heruntergeladen (${count})';
	@override String downloaded({required Object count}) => 'Heruntergeladen (${count})';
	@override String get noDownloads => 'Keine Downloads';
	@override String get noDownloadsHint => 'Laden Sie Filme und Serien herunter, um sie offline anzusehen';
	@override String get deleteDownloadTitle => 'Download löschen?';
	@override String deleteDownloadMessage({required Object title}) => '"${title}" löschen?';
	@override String get delete => 'Löschen';
	@override String get cancel => 'Abbrechen';
	@override String get downloadFailed => 'Download fehlgeschlagen';
	@override String get paused => 'Pausiert';
}

// Path: libraries.tabs
class _StringsLibrariesTabsDe extends _StringsLibrariesTabsEn {
	_StringsLibrariesTabsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Empfohlen';
	@override String get browse => 'Durchsuchen';
	@override String get collections => 'Sammlungen';
	@override String get playlists => 'Wiedergabelisten';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsDe extends _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsDe._(_StringsDe root) : this._root = root, super._(root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get all => 'Alle';
	@override String get movies => 'Filme';
	@override String get shows => 'Serien';
	@override String get seasons => 'Staffeln';
	@override String get episodes => 'Episoden';
	@override String get folders => 'Ordner';
}

// Path: <root>
class _StringsIt extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsIt.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <it>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _StringsIt _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppIt app = _StringsAppIt._(_root);
	@override late final _StringsAuthIt auth = _StringsAuthIt._(_root);
	@override late final _StringsCommonIt common = _StringsCommonIt._(_root);
	@override late final _StringsScreensIt screens = _StringsScreensIt._(_root);
	@override late final _StringsUpdateIt update = _StringsUpdateIt._(_root);
	@override late final _StringsSettingsIt settings = _StringsSettingsIt._(_root);
	@override late final _StringsSearchIt search = _StringsSearchIt._(_root);
	@override late final _StringsHotkeysIt hotkeys = _StringsHotkeysIt._(_root);
	@override late final _StringsPinEntryIt pinEntry = _StringsPinEntryIt._(_root);
	@override late final _StringsFileInfoIt fileInfo = _StringsFileInfoIt._(_root);
	@override late final _StringsMediaMenuIt mediaMenu = _StringsMediaMenuIt._(_root);
	@override late final _StringsAccessibilityIt accessibility = _StringsAccessibilityIt._(_root);
	@override late final _StringsTooltipsIt tooltips = _StringsTooltipsIt._(_root);
	@override late final _StringsVideoControlsIt videoControls = _StringsVideoControlsIt._(_root);
	@override late final _StringsUserStatusIt userStatus = _StringsUserStatusIt._(_root);
	@override late final _StringsMessagesIt messages = _StringsMessagesIt._(_root);
	@override late final _StringsProfileIt profile = _StringsProfileIt._(_root);
	@override late final _StringsSubtitlingStylingIt subtitlingStyling = _StringsSubtitlingStylingIt._(_root);
	@override late final _StringsDialogIt dialog = _StringsDialogIt._(_root);
	@override late final _StringsDiscoverIt discover = _StringsDiscoverIt._(_root);
	@override late final _StringsErrorsIt errors = _StringsErrorsIt._(_root);
	@override late final _StringsVoiceIt voice = _StringsVoiceIt._(_root);
	@override late final _StringsLibrariesIt libraries = _StringsLibrariesIt._(_root);
	@override late final _StringsAboutIt about = _StringsAboutIt._(_root);
	@override late final _StringsServerSelectionIt serverSelection = _StringsServerSelectionIt._(_root);
	@override late final _StringsHubDetailIt hubDetail = _StringsHubDetailIt._(_root);
	@override late final _StringsLogsIt logs = _StringsLogsIt._(_root);
	@override late final _StringsStatsIt stats = _StringsStatsIt._(_root);
	@override late final _StringsLicensesIt licenses = _StringsLicensesIt._(_root);
	@override late final _StringsNavigationIt navigation = _StringsNavigationIt._(_root);
	@override late final _StringsPlaylistsIt playlists = _StringsPlaylistsIt._(_root);
	@override late final _StringsCollectionsIt collections = _StringsCollectionsIt._(_root);
	@override late final _StringsWatchPartyIt watchParty = _StringsWatchPartyIt._(_root);
	@override late final _StringsCatchUpIt catchUp = _StringsCatchUpIt._(_root);
	@override late final _StringsWatchlistIt watchlist = _StringsWatchlistIt._(_root);
	@override late final _StringsLiveTVIt liveTV = _StringsLiveTVIt._(_root);
	@override late final _StringsDvrIt dvr = _StringsDvrIt._(_root);
	@override late final _StringsEpgIt epg = _StringsEpgIt._(_root);
	@override late final _StringsChannelSurfingIt channelSurfing = _StringsChannelSurfingIt._(_root);
	@override late final _StringsMultiviewIt multiview = _StringsMultiviewIt._(_root);
	@override late final _StringsPlayerIt player = _StringsPlayerIt._(_root);
	@override late final _StringsDownloadsIt downloads = _StringsDownloadsIt._(_root);
}

// Path: app
class _StringsAppIt extends _StringsAppEn {
	_StringsAppIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'OpenFlix';
	@override String get loading => 'Caricamento...';
}

// Path: auth
class _StringsAuthIt extends _StringsAuthEn {
	_StringsAuthIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get signIn => 'Accedi';
	@override String get signUp => 'Registrati';
	@override String get signInWithPlex => 'Accedi a OpenFlix';
	@override String get showQRCode => 'Mostra QR Code';
	@override String get cancel => 'Cancella';
	@override String get authenticate => 'Autenticazione';
	@override String get retry => 'Riprova';
	@override String get debugEnterToken => 'Debug: Inserisci Token';
	@override String get plexTokenLabel => 'Token Auth';
	@override String get plexTokenHint => 'Inserisci il token';
	@override String get authenticationTimeout => 'Autenticazione scaduta. Riprova.';
	@override String get scanQRCodeInstruction => 'Scansiona questo QR code per autenticarti.';
	@override String get waitingForAuth => 'In attesa di autenticazione...\nCompleta l\'accesso dal tuo browser.';
	@override String get serverUrl => 'URL Server';
	@override String get serverUrlHint => 'es. http://192.168.1.100:32400';
	@override String get username => 'Nome utente';
	@override String get usernameHint => 'Inserisci il nome utente';
	@override String get email => 'Email';
	@override String get emailHint => 'Inserisci la tua email';
	@override String get password => 'Password';
	@override String get passwordHint => 'Inserisci la password';
	@override String get confirmPassword => 'Conferma Password';
	@override String get confirmPasswordHint => 'Reinserisci la password';
	@override String get displayName => 'Nome visualizzato';
	@override String get displayNameHint => 'Nome visualizzato opzionale';
	@override String get noAccount => 'Non hai un account?';
	@override String get haveAccount => 'Hai già un account?';
	@override String get connecting => 'Connessione al server...';
	@override String get loggingIn => 'Accesso in corso...';
	@override String get registering => 'Creazione account...';
	@override String get connectToServer => 'Connetti al Server';
	@override String get changeServer => 'Cambia Server';
	@override String serverConnected({required Object serverName}) => 'Connesso a ${serverName}';
	@override String get invalidServerUrl => 'Inserisci un URL server valido';
	@override String get serverConnectionFailed => 'Connessione al server fallita';
	@override String get passwordMismatch => 'Le password non corrispondono';
	@override String get usernameRequired => 'Nome utente richiesto';
	@override String get emailRequired => 'Email richiesta';
	@override String get passwordRequired => 'Password richiesta';
	@override String get passwordTooShort => 'La password deve avere almeno 6 caratteri';
	@override String get invalidEmail => 'Inserisci un indirizzo email valido';
	@override String get firstUserNote => 'Il primo utente sarà l\'amministratore';
	@override String get howConnecting => 'Come ti stai connettendo?';
	@override String get atHome => 'A casa';
	@override String get atHomeDescription => 'Rileva automaticamente il server sulla rete locale';
	@override String get awayFromHome => 'Fuori casa';
	@override String get awayFromHomeDescription => 'Inserisci l\'indirizzo del server manualmente';
	@override String get findYourServer => 'Trova il tuo server';
	@override String get searching => 'Ricerca...';
	@override String get checkingNetwork => 'Controllo rete...';
	@override String get serversFound => 'Server trovati';
	@override String get scanAgain => 'Cerca di nuovo';
	@override String get enterManually => 'Inserisci manualmente';
	@override String get noServersFound => 'Nessun server trovato nella tua rete. Assicurati che il server OpenFlix sia in esecuzione.';
	@override String discoveryFailed({required Object error}) => 'Ricerca fallita: ${error}';
}

// Path: common
class _StringsCommonIt extends _StringsCommonEn {
	_StringsCommonIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancella';
	@override String get save => 'Salva';
	@override String get close => 'Chiudi';
	@override String get clear => 'Pulisci';
	@override String get reset => 'Ripristina';
	@override String get later => 'Più tardi';
	@override String get submit => 'Invia';
	@override String get confirm => 'Conferma';
	@override String get retry => 'Riprova';
	@override String get playNow => 'Riproduci ora';
	@override String get logout => 'Disconnetti';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get owned => 'Di proprietà';
	@override String get shared => 'Condiviso';
	@override String get current => 'CORRENTE';
	@override String get unknown => 'Sconosciuto';
	@override String get refresh => 'Aggiorna';
	@override String get yes => 'Sì';
	@override String get no => 'No';
	@override String get server => 'Server';
	@override String get delete => 'Elimina';
	@override String get shuffle => 'Casuale';
	@override String get addTo => 'Aggiungi a...';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get live => 'LIVE';
	@override String get newLabel => 'NUOVO';
}

// Path: screens
class _StringsScreensIt extends _StringsScreensEn {
	_StringsScreensIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenze';
	@override String get selectServer => 'Seleziona server';
	@override String get switchProfile => 'Cambia profilo';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get search => 'Cerca';
	@override String get logs => 'Registro';
}

// Path: update
class _StringsUpdateIt extends _StringsUpdateEn {
	_StringsUpdateIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Aggiornamento disponibile';
	@override String versionAvailable({required Object version}) => 'Versione ${version} disponibile';
	@override String currentVersion({required Object version}) => 'Corrente: ${version}';
	@override String get skipVersion => 'Salta questa versione';
	@override String get viewRelease => 'Visualizza dettagli release';
	@override String get latestVersion => 'La versione installata è l\'ultima disponibile';
	@override String get checkFailed => 'Impossibile controllare gli aggiornamenti';
}

// Path: settings
class _StringsSettingsIt extends _StringsSettingsEn {
	_StringsSettingsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Impostazioni';
	@override String get profile => 'Profilo';
	@override String get noProfileSelected => 'Nessun profilo selezionato';
	@override String get kidsMode => 'Modalità bambini';
	@override String get switchProfile => 'Cambia profilo';
	@override String get switchProfileDescription => 'Passa a un altro profilo';
	@override String get manageProfiles => 'Gestisci profili';
	@override String get manageProfilesDescription => 'Aggiungi, modifica o elimina profili';
	@override String get language => 'Lingua';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aspetto';
	@override String get videoPlayback => 'Riproduzione video';
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get advanced => 'Avanzate';
	@override String get useSeasonPostersDescription => 'Mostra il poster della stagione invece del poster della serie per gli episodi';
	@override String get showHeroSectionDescription => 'Visualizza il carosello dei contenuti in primo piano sulla schermata iniziale';
	@override String get secondsLabel => 'Secondi';
	@override String get minutesLabel => 'Minuti';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Inserisci durata (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get systemThemeDescription => 'Segui le impostazioni di sistema';
	@override String get lightTheme => 'Chiaro';
	@override String get darkTheme => 'Scuro';
	@override String get libraryDensity => 'Densità libreria';
	@override String get compact => 'Compatta';
	@override String get compactDescription => 'Schede più piccole, più elementi visibili';
	@override String get normal => 'Normale';
	@override String get normalDescription => 'Dimensione predefinita';
	@override String get comfortable => 'Comoda';
	@override String get comfortableDescription => 'Schede più grandi, meno elementi visibili';
	@override String get viewMode => 'Modalità di visualizzazione';
	@override String get gridView => 'Griglia';
	@override String get gridViewDescription => 'Visualizza gli elementi in un layout a griglia';
	@override String get listView => 'Elenco';
	@override String get listViewDescription => 'Visualizza gli elementi in un layout a elenco';
	@override String get useSeasonPosters => 'Usa poster delle stagioni';
	@override String get showHeroSection => 'Mostra sezione principale';
	@override String get hardwareDecoding => 'Decodifica Hardware';
	@override String get hardwareDecodingDescription => 'Utilizza l\'accelerazione hardware quando disponibile';
	@override String get bufferSize => 'Dimensione buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Stile sottotitoli';
	@override String get subtitleStylingDescription => 'Personalizza l\'aspetto dei sottotitoli';
	@override String get smallSkipDuration => 'Durata skip breve';
	@override String get largeSkipDuration => 'Durata skip lungo';
	@override String secondsUnit({required Object seconds}) => '${seconds} secondi';
	@override String get defaultSleepTimer => 'Timer spegnimento predefinito';
	@override String minutesUnit({required Object minutes}) => '${minutes} minuti';
	@override String get rememberTrackSelections => 'Ricorda selezioni tracce per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Salva automaticamente le preferenze delle lingue audio e sottotitoli quando cambi tracce durante la riproduzione';
	@override String get unwatchedOnly => 'Solo non guardati';
	@override String get unwatchedOnlyDescription => 'Includi solo gli episodi non guardati nella coda di riproduzione casuale';
	@override String get shuffleOrderNavigation => 'Navigazione in ordine casuale';
	@override String get shuffleOrderNavigationDescription => 'I pulsanti Avanti/Indietro seguono l\'ordine casuale';
	@override String get loopShuffleQueue => 'Coda di riproduzione casuale in loop';
	@override String get loopShuffleQueueDescription => 'Riavvia la coda quando raggiungi la fine';
	@override String get videoPlayerControls => 'Controlli del lettore video';
	@override String get keyboardShortcuts => 'Scorciatoie da tastiera';
	@override String get keyboardShortcutsDescription => 'Personalizza le scorciatoie da tastiera';
	@override String get debugLogging => 'Log di debug';
	@override String get debugLoggingDescription => 'Abilita il logging dettagliato per la risoluzione dei problemi';
	@override String get viewLogs => 'Visualizza log';
	@override String get viewLogsDescription => 'Visualizza i log dell\'applicazione';
	@override String get clearCache => 'Svuota cache';
	@override String get clearCacheDescription => 'Questa opzione cancellerà tutte le immagini e i dati memorizzati nella cache. Dopo aver cancellato la cache, l\'app potrebbe impiegare più tempo per caricare i contenuti.';
	@override String get clearCacheSuccess => 'Cache cancellata correttamente';
	@override String get resetSettings => 'Ripristina impostazioni';
	@override String get resetSettingsDescription => 'Questa opzione ripristinerà tutte le impostazioni ai valori predefiniti. Non può essere annullata.';
	@override String get resetSettingsSuccess => 'Impostazioni ripristinate correttamente';
	@override String get shortcutsReset => 'Scorciatoie ripristinate alle impostazioni predefinite';
	@override String get about => 'Informazioni';
	@override String get aboutDescription => 'Informazioni sull\'app e le licenze';
	@override String get updates => 'Aggiornamenti';
	@override String get updateAvailable => 'Aggiornamento disponibile';
	@override String get checkForUpdates => 'Controlla aggiornamenti';
	@override String get validationErrorEnterNumber => 'Inserisci un numero valido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'la durata deve essere compresa tra ${min} e ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Scorciatoia già assegnata a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Scorciatoia aggiornata per ${action}';
	@override String get autoSkip => 'Salto Automatico';
	@override String get autoSkipIntro => 'Salta Intro Automaticamente';
	@override String get autoSkipIntroDescription => 'Salta automaticamente i marcatori dell\'intro dopo alcuni secondi';
	@override String get autoSkipCredits => 'Salta Crediti Automaticamente';
	@override String get autoSkipCreditsDescription => 'Salta automaticamente i crediti e riproduci l\'episodio successivo';
	@override String get autoSkipDelay => 'Ritardo Salto Automatico';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Aspetta ${seconds} secondi prima del salto automatico';
	@override String get metadataSection => 'Metadati';
	@override String get tmdbApiKey => 'Chiave API TMDB';
	@override String get tmdbApiKeyDescription => 'Configura TMDB per metadati avanzati';
	@override String get tmdbApiKeyConfigured => 'Chiave API configurata';
	@override String get tmdbApiKeyHint => 'Ottieni la tua chiave API da themoviedb.org';
	@override String get tmdbApiKeyPlaceholder => 'Inserisci la chiave API TMDB';
	@override String get apiKey => 'Chiave API';
	@override String get tmdbApiKeySaved => 'Chiave API TMDB salvata';
	@override String get tmdbApiKeyCleared => 'Chiave API TMDB eliminata';
	@override String get parentalControls => 'Controllo Genitori';
	@override String get enableParentalControls => 'Abilita Controllo Genitori';
	@override String get enableParentalControlsDescription => 'Limita i contenuti in base alle classificazioni per età';
	@override String get setPin => 'Imposta PIN';
	@override String get setPinDescription => 'Inserisci un PIN a 4 cifre per proteggere le impostazioni';
	@override String get confirmPin => 'Conferma PIN';
	@override String get confirmPinDescription => 'Inserisci nuovamente il PIN per confermare';
	@override String get enterPin => 'Inserisci PIN';
	@override String get enterPinDescription => 'Inserisci il tuo PIN di controllo genitori';
	@override String get changePin => 'Cambia PIN';
	@override String get changePinDescription => 'Cambia il tuo PIN di controllo genitori';
	@override String get pinSet => 'PIN di controllo genitori impostato con successo';
	@override String get pinMismatch => 'I PIN non corrispondono. Riprova.';
	@override String get incorrectPin => 'PIN errato. Riprova.';
	@override String get maxMovieRating => 'Classificazione Film Massima';
	@override String get maxTvRating => 'Classificazione TV Massima';
}

// Path: search
class _StringsSearchIt extends _StringsSearchEn {
	_StringsSearchIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Cerca film, serie, musica...';
	@override String get tryDifferentTerm => 'Prova altri termini di ricerca';
	@override String get searchYourMedia => 'Cerca nei tuoi media';
	@override String get enterTitleActorOrKeyword => 'Inserisci un titolo, attore o parola chiave';
	@override String get recentSearches => 'Ricerche recenti';
	@override String get clear => 'Cancella';
	@override String get voiceSearch => 'Ricerca vocale';
	@override String get listening => 'In ascolto...';
	@override String get speakNow => 'Parla ora';
	@override String get all => 'Tutto';
	@override String get movies => 'Film';
	@override String get tvShows => 'Serie TV';
	@override String get music => 'Musica';
}

// Path: hotkeys
class _StringsHotkeysIt extends _StringsHotkeysEn {
	_StringsHotkeysIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Imposta scorciatoia per ${actionName}';
	@override String get clearShortcut => 'Elimina scorciatoia';
}

// Path: pinEntry
class _StringsPinEntryIt extends _StringsPinEntryEn {
	_StringsPinEntryIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Inserisci PIN';
	@override String get showPin => 'Mostra PIN';
	@override String get hidePin => 'Nascondi PIN';
}

// Path: fileInfo
class _StringsFileInfoIt extends _StringsFileInfoEn {
	_StringsFileInfoIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Info sul file';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'File';
	@override String get advanced => 'Avanzate';
	@override String get codec => 'Codec';
	@override String get resolution => 'Risoluzione';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Frame Rate';
	@override String get aspectRatio => 'Aspect Ratio';
	@override String get profile => 'Profilo';
	@override String get bitDepth => 'Profondità colore';
	@override String get colorSpace => 'Spazio colore';
	@override String get colorRange => 'Gamma colori';
	@override String get colorPrimaries => 'Colori primari';
	@override String get chromaSubsampling => 'Sottocampionamento cromatico';
	@override String get channels => 'Canali';
	@override String get path => 'Percorso';
	@override String get size => 'Dimensione';
	@override String get container => 'Contenitore';
	@override String get duration => 'Durata';
	@override String get optimizedForStreaming => 'Ottimizzato per lo streaming';
	@override String get has64bitOffsets => 'Offset a 64-bit';
}

// Path: mediaMenu
class _StringsMediaMenuIt extends _StringsMediaMenuEn {
	_StringsMediaMenuIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Segna come visto';
	@override String get markAsUnwatched => 'Segna come non visto';
	@override String get removeFromContinueWatching => 'Rimuovi da Continua a guardare';
	@override String get goToSeries => 'Vai alle serie';
	@override String get goToSeason => 'Vai alla stagione';
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get fileInfo => 'Info sul file';
}

// Path: accessibility
class _StringsAccessibilityIt extends _StringsAccessibilityEn {
	_StringsAccessibilityIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, serie TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visto';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} percento visto';
	@override String get mediaCardUnwatched => 'non visto';
	@override String get tapToPlay => 'Tocca per riprodurre';
}

// Path: tooltips
class _StringsTooltipsIt extends _StringsTooltipsEn {
	_StringsTooltipsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Riproduzione casuale';
	@override String get markAsWatched => 'Segna come visto';
	@override String get markAsUnwatched => 'Segna come non visto';
}

// Path: videoControls
class _StringsVideoControlsIt extends _StringsVideoControlsEn {
	_StringsVideoControlsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Sottotitoli';
	@override String get resetToZero => 'Riporta a 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} riprodotto dopo';
	@override String playsEarlier({required Object label}) => '${label} riprodotto prima';
	@override String get noOffset => 'Nessun offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Riempi schermo';
	@override String get stretch => 'Allunga';
	@override String get lockRotation => 'Blocca rotazione';
	@override String get unlockRotation => 'Sblocca rotazione';
	@override String get lockScreen => 'Blocca schermo';
	@override String get unlockScreen => 'Sblocca schermo';
	@override String get screenLockButton => 'Blocco schermo';
	@override String get screenLocked => 'Schermo bloccato';
	@override String get tapToUnlock => 'Tocca per sbloccare';
	@override String get sleepTimer => 'Timer di spegnimento';
	@override String get timerActive => 'Timer attivo';
	@override String playbackWillPauseIn({required Object duration}) => 'La riproduzione si interromperà tra ${duration}';
	@override String get sleepTimerCompleted => 'Timer di spegnimento completato - riproduzione in pausa';
	@override String get playButton => 'Riproduci';
	@override String get pauseButton => 'Pausa';
	@override String seekBackwardButton({required Object seconds}) => 'Riavvolgi di ${seconds} secondi';
	@override String seekForwardButton({required Object seconds}) => 'Avanza di ${seconds} secondi';
	@override String get previousButton => 'Episodio precedente';
	@override String get nextButton => 'Episodio successivo';
	@override String get previousChapterButton => 'Capitolo precedente';
	@override String get nextChapterButton => 'Capitolo successivo';
	@override String get volumeButton => 'Volume';
	@override String get muteButton => 'Silenzia';
	@override String get unmuteButton => 'Riattiva audio';
	@override String get settingsButton => 'Impostazioni video';
	@override String get audioTrackButton => 'Tracce audio';
	@override String get subtitlesButton => 'Sottotitoli';
	@override String get chaptersButton => 'Capitoli';
	@override String get versionsButton => 'Versioni video';
	@override String get aspectRatioButton => 'Proporzioni';
	@override String get fullscreenButton => 'Attiva schermo intero';
	@override String get exitFullscreenButton => 'Esci da schermo intero';
	@override String get rotationLockButton => 'Blocco rotazione';
	@override String get timelineSlider => 'Timeline video';
	@override String get volumeSlider => 'Livello volume';
	@override String get backButton => 'Indietro';
}

// Path: userStatus
class _StringsUserStatusIt extends _StringsUserStatusEn {
	_StringsUserStatusIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Limitato';
	@override String get protected => 'Protetto';
	@override String get current => 'ATTUALE';
}

// Path: messages
class _StringsMessagesIt extends _StringsMessagesEn {
	_StringsMessagesIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Segna come visto';
	@override String get markedAsUnwatched => 'Segna come non visto';
	@override String get removedFromContinueWatching => 'Rimosso da Continua a guardare';
	@override String errorLoading({required Object error}) => 'Errore: ${error}';
	@override String get fileInfoNotAvailable => 'Informazioni sul file non disponibili';
	@override String errorLoadingFileInfo({required Object error}) => 'Errore caricamento informazioni sul file: ${error}';
	@override String get errorLoadingSeries => 'Errore caricamento serie';
	@override String get errorLoadingSeason => 'Errore caricamento stagione';
	@override String get musicNotSupported => 'La riproduzione musicale non è ancora supportata';
	@override String get logsCleared => 'Log eliminati';
	@override String get logsCopied => 'Log copiati negli appunti';
	@override String get noLogsAvailable => 'Nessun log disponibile';
	@override String libraryScanning({required Object title}) => 'Scansione "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Scansione libreria iniziata per "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Impossibile eseguire scansione della libreria: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Aggiornamento metadati per "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Aggiornamento metadati per "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Errore aggiornamento metadati: ${error}';
	@override String get noTokenFound => 'Nessun token trovato. Riesegui l\'accesso.';
	@override String get logoutConfirm => 'Sei sicuro di volerti disconnettere?';
	@override String get noSeasonsFound => 'Nessuna stagione trovata';
	@override String get noEpisodesFound => 'Nessun episodio trovato nella prima stagione';
	@override String get noEpisodesFoundGeneral => 'Nessun episodio trovato';
	@override String get noResultsFound => 'Nessun risultato';
	@override String sleepTimerSet({required Object label}) => 'Imposta timer spegnimento per ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossibile passare a ${displayName}';
	@override String get noItemsAvailable => 'Nessun elemento disponibile';
	@override String get failedToCreatePlayQueue => 'Impossibile creare la coda di riproduzione';
	@override String get failedToCreatePlayQueueNoItems => 'Impossibile creare la coda di riproduzione - nessun elemento';
	@override String failedPlayback({required Object action, required Object error}) => 'Impossibile ${action}: ${error}';
}

// Path: profile
class _StringsProfileIt extends _StringsProfileEn {
	_StringsProfileIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => 'Nessun utente disponibile';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingIt extends _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opzioni stile';
	@override String get fontSize => 'Dimensione';
	@override String get textColor => 'Colore testo';
	@override String get borderSize => 'Dimensione bordo';
	@override String get borderColor => 'Colore bordo';
	@override String get backgroundOpacity => 'Opacità sfondo';
	@override String get backgroundColor => 'Colore sfondo';
}

// Path: dialog
class _StringsDialogIt extends _StringsDialogEn {
	_StringsDialogIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Conferma azione';
	@override String get areYouSure => 'Sei sicuro di voler eseguire questa azione?';
	@override String get cancel => 'Cancella';
	@override String get playNow => 'Riproduci ora';
}

// Path: discover
class _StringsDiscoverIt extends _StringsDiscoverEn {
	_StringsDiscoverIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Esplora';
	@override String get switchProfile => 'Cambia profilo';
	@override String get switchServer => 'Cambia server';
	@override String get logout => 'Disconnetti';
	@override String get noContentAvailable => 'Nessun contenuto disponibile';
	@override String get addMediaToLibraries => 'Aggiungi alcuni file multimediali alle tue librerie';
	@override String get continueWatching => 'Continua a guardare';
	@override String get recentlyAdded => 'Aggiunti di recente';
	@override String get play => 'Riproduci';
	@override String get resume => 'Riprendi';
	@override String playEpisode({required Object season, required Object episode}) => 'Riproduci S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => 'Riprendi S${season}, E${episode}';
	@override String get pause => 'Pausa';
	@override String get overview => 'Panoramica';
	@override String get cast => 'Attori';
	@override String get seasons => 'Stagioni';
	@override String get studio => 'Studio';
	@override String get rating => 'Classificazione';
	@override String get watched => 'Guardato';
	@override String episodeCount({required Object count}) => '${count} episodi';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} guardati';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} minuti rimanenti';
	@override String get whatsOnNow => 'In onda ora';
	@override String get channelGuide => 'Guida TV';
	@override String get liveNow => 'In diretta';
	@override String get topTen => 'Top 10';
	@override String get newBadge => 'NUOVO';
	@override String get liveBadge => 'LIVE';
	@override String get goodMorning => 'Good morning';
	@override String get goodAfternoon => 'Good afternoon';
	@override String get goodEvening => 'Good evening';
	@override String get defaultUser => 'Guest';
	@override String get yourNextWatch => 'Your Next Watch';
	@override String pickedForYou({required Object name}) => 'Picked just for you, ${name}';
	@override String get surpriseMe => 'Surprise Me';
	@override String get randomPicker => 'Random Movie Picker';
	@override String get noMoviesFound => 'No movies found in your library';
	@override String get spinning => 'Picking something great...';
	@override String get spinAgain => 'Spin Again';
	@override String get calendar => 'Calendar';
	@override String get today => 'Today';
	@override String get item => 'item';
	@override String get items => 'items';
	@override String get loadingMovies => 'Caricamento dei tuoi film...';
	@override String get noContentOnDate => 'No content added on this date';
	@override String get noEpgData => 'Nessuna informazione programma';
}

// Path: errors
class _StringsErrorsIt extends _StringsErrorsEn {
	_StringsErrorsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Ricerca fallita: ${error}';
	@override String connectionTimeout({required Object context}) => 'Timeout connessione durante caricamento di ${context}';
	@override String get connectionFailed => 'Impossibile connettersi al server Plex.';
	@override String failedToLoad({required Object context, required Object error}) => 'Impossibile caricare ${context}: ${error}';
	@override String get noClientAvailable => 'Nessun client disponibile';
	@override String authenticationFailed({required Object error}) => 'Autenticazione fallita: ${error}';
	@override String get couldNotLaunchUrl => 'Impossibile avviare URL di autenticazione';
	@override String get pleaseEnterToken => 'Inserisci token';
	@override String get invalidToken => 'Token non valido';
	@override String failedToVerifyToken({required Object error}) => 'Verifica token fallita: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossibile passare a ${displayName}';
	@override String get connectionFailedGeneric => 'Connessione fallita';
	@override String failedToRemove({required Object error}) => 'Rimozione fallita: ${error}';
}

// Path: voice
class _StringsVoiceIt extends _StringsVoiceEn {
	_StringsVoiceIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get notAvailable => 'Il controllo vocale non è disponibile';
	@override String commandNotRecognized({required Object command}) => 'Comando non riconosciuto: "${command}"';
}

// Path: libraries
class _StringsLibrariesIt extends _StringsLibrariesEn {
	_StringsLibrariesIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Librerie';
	@override String get scanLibraryFiles => 'Scansiona file libreria';
	@override String get scanLibrary => 'Scansiona libreria';
	@override String get analyze => 'Analizza';
	@override String get analyzeLibrary => 'Analizza libreria';
	@override String get refreshMetadata => 'Aggiorna metadati';
	@override String get emptyTrash => 'Svuota cestino';
	@override String emptyingTrash({required Object title}) => 'Svuotamento cestino per "${title}"...';
	@override String trashEmptied({required Object title}) => 'Cestino svuotato per "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Impossibile svuotare cestino: ${error}';
	@override String analyzing({required Object title}) => 'Analisi "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analisi iniziata per "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Impossibile analizzare libreria: ${error}';
	@override String get noLibrariesFound => 'Nessuna libreria trovata';
	@override String get thisLibraryIsEmpty => 'Questa libreria è vuota';
	@override String get all => 'Tutto';
	@override String get clearAll => 'Cancella tutto';
	@override String scanLibraryConfirm({required Object title}) => 'Sei sicuro di voler scansionare "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Sei sicuro di voler analizzare "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Sei sicuro di voler aggiornare i metadati per "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Sei sicuro di voler svuotare il cestino per "${title}"?';
	@override String get manageLibraries => 'Gestisci librerie';
	@override String get sort => 'Ordina';
	@override String get sortBy => 'Ordina per';
	@override String get filters => 'Filtri';
	@override String loadingLibraryWithCount({required Object count}) => 'Caricamento librerie... (${count} oggetti caricati)';
	@override String get confirmActionMessage => 'Sei sicuro di voler eseguire questa azione?';
	@override String get showLibrary => 'Mostra libreria';
	@override String get hideLibrary => 'Nascondi libreria';
	@override String get libraryOptions => 'Opzioni libreria';
	@override String get content => 'contenuto della libreria';
	@override String get selectLibrary => 'Seleziona libreria';
	@override String filtersWithCount({required Object count}) => 'Filtri (${count})';
	@override String get noRecommendations => 'Nessun consiglio disponibile';
	@override String get noCollections => 'Nessuna raccolta in questa libreria';
	@override String get noFoldersFound => 'Nessuna cartella trovata';
	@override String get folders => 'cartelle';
	@override late final _StringsLibrariesTabsIt tabs = _StringsLibrariesTabsIt._(_root);
	@override late final _StringsLibrariesGroupingsIt groupings = _StringsLibrariesGroupingsIt._(_root);
}

// Path: about
class _StringsAboutIt extends _StringsAboutEn {
	_StringsAboutIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informazioni';
	@override String get openSourceLicenses => 'Licenze Open Source';
	@override String versionLabel({required Object version}) => 'Versione ${version}';
	@override String get appDescription => 'Un bellissimo client Plex per Flutter';
	@override String get viewLicensesDescription => 'Visualizza le licenze delle librerie di terze parti';
}

// Path: serverSelection
class _StringsServerSelectionIt extends _StringsServerSelectionEn {
	_StringsServerSelectionIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get connectingToServer => 'Connessione al server...';
	@override String get connectingToAllServers => 'Connessione a tutti i server...';
	@override String get connectToAllServers => 'Connetti a tutti i server';
	@override String get allServerConnectionsFailed => 'Impossibile connettersi a nessun server. Controlla la tua rete e riprova.';
	@override String foundServers({required Object count}) => 'Trovati ${count} server';
	@override String get orSelectIndividually => 'Oppure seleziona un server singolarmente:';
	@override String get serverDebugCopied => 'Dati di debug del server copiati negli appunti';
	@override String get copyDebugData => 'Copia dati di debug';
	@override String get noServersFound => 'Nessun server trovato';
	@override String malformedServerData({required Object count}) => 'Trovato ${count} server con dati difettosi. Nessun server valido disponibile.';
	@override String get incompleteServerInfo => 'Alcuni server presentano informazioni incomplete e sono stati ignorati. Controlla il tuo account Plex.tv.';
	@override String get incompleteConnectionInfo => 'Le informazioni di connessione al server sono incomplete. Riprova.';
	@override String malformedServerInfo({required Object message}) => 'Le informazioni sul server sono errate: ${message}';
	@override String get networkConnectionFailed => 'Connessione di rete non riuscita. Controlla la tua connessione Internet e riprova.';
	@override String get authenticationFailed => 'Autenticazione fallita. Effettua nuovamente l\'accesso.';
	@override String get plexServiceUnavailable => 'Servizio Plex non disponibile. Riprova più tardi.';
	@override String failedToLoadServers({required Object error}) => 'Impossibile caricare i server: ${error}';
}

// Path: hubDetail
class _StringsHubDetailIt extends _StringsHubDetailEn {
	_StringsHubDetailIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titolo';
	@override String get releaseYear => 'Anno rilascio';
	@override String get dateAdded => 'Data aggiunta';
	@override String get rating => 'Valutazione';
	@override String get noItemsFound => 'Nessun elemento trovato';
}

// Path: logs
class _StringsLogsIt extends _StringsLogsEn {
	_StringsLogsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Registro';
	@override String get clearLogs => 'Cancella log';
	@override String get copyLogs => 'Copia log';
	@override String get exportLogs => 'Esporta log';
	@override String get noLogsToShow => 'Nessun log da mostrare';
	@override String get error => 'Errore:';
	@override String get stackTrace => 'Traccia dello stack:';
}

// Path: stats
class _StringsStatsIt extends _StringsStatsEn {
	_StringsStatsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Statistiche di Visione';
	@override String get totalWatchTime => 'Tempo di Visione Totale';
	@override String get moviesWatched => 'Film Visti';
	@override String get episodesWatched => 'Episodi Visti';
	@override String get avgPerDay => 'Media al Giorno';
	@override String get topGenres => 'Generi Preferiti';
	@override String get monthlyActivity => 'Attività Mensile';
	@override String get noData => 'Nessuna cronologia di visione';
	@override String get startWatching => 'Inizia a guardare per vedere le tue statistiche';
	@override String get days => 'giorni';
}

// Path: licenses
class _StringsLicensesIt extends _StringsLicensesEn {
	_StringsLicensesIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacchetti correlati';
	@override String get license => 'Licenza';
	@override String licenseNumber({required Object number}) => 'Licenza ${number}';
	@override String licensesCount({required Object count}) => '${count} licenze';
}

// Path: navigation
class _StringsNavigationIt extends _StringsNavigationEn {
	_StringsNavigationIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get search => 'Cerca';
	@override String get libraries => 'Librerie';
	@override String get livetv => 'Live TV';
	@override String get settings => 'Impostazioni';
}

// Path: playlists
class _StringsPlaylistsIt extends _StringsPlaylistsEn {
	_StringsPlaylistsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlist';
	@override String get noPlaylists => 'Nessuna playlist trovata';
	@override String get create => 'Crea playlist';
	@override String get newPlaylist => 'Nuova playlist';
	@override String get playlistName => 'Nome playlist';
	@override String get enterPlaylistName => 'Inserisci nome playlist';
	@override String get edit => 'Modifica playlist';
	@override String get delete => 'Elimina playlist';
	@override String get addTo => 'Aggiungi a playlist';
	@override String get addItems => 'Aggiungi elementi';
	@override String get removeItem => 'Rimuovi da playlist';
	@override String get clearPlaylist => 'Svuota playlist';
	@override String get playAll => 'Riproduci tutto';
	@override String get shuffle => 'Casuale';
	@override String get smartPlaylist => 'Playlist intelligente';
	@override String get regularPlaylist => 'Playlist normale';
	@override String itemCount({required Object count}) => '${count} elementi';
	@override String get oneItem => '1 elemento';
	@override String get emptyPlaylist => 'Questa playlist è vuota';
	@override String get deleteConfirm => 'Eliminare playlist?';
	@override String deleteMessage({required Object name}) => 'Sei sicuro di voler eliminare "${name}"?';
	@override String get created => 'Playlist creata';
	@override String get updated => 'Playlist aggiornata';
	@override String get deleted => 'Playlist eliminata';
	@override String get itemAdded => 'Aggiunto alla playlist';
	@override String get itemRemoved => 'Rimosso dalla playlist';
	@override String get selectPlaylist => 'Seleziona playlist';
	@override String get createNewPlaylist => 'Crea nuova playlist';
	@override String get errorCreating => 'Errore durante la creazione della playlist';
	@override String get errorDeleting => 'Errore durante l\'eliminazione della playlist';
	@override String get errorLoading => 'Errore durante il caricamento delle playlist';
	@override String get errorAdding => 'Errore durante l\'aggiunta alla playlist';
	@override String get errorReordering => 'Errore durante il riordino dell\'elemento della playlist';
	@override String get errorRemoving => 'Errore durante la rimozione dalla playlist';
	@override String get playlist => 'Playlist';
}

// Path: collections
class _StringsCollectionsIt extends _StringsCollectionsEn {
	_StringsCollectionsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Raccolte';
	@override String get collection => 'Raccolta';
	@override String get empty => 'La raccolta è vuota';
	@override String get noItems => 'Nessun elemento in questa raccolta';
	@override String get unknownLibrarySection => 'Impossibile eliminare: sezione libreria sconosciuta';
	@override String get deleteCollection => 'Elimina raccolta';
	@override String deleteConfirm({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Questa azione non può essere annullata.';
	@override String get deleted => 'Raccolta eliminata';
	@override String get deleteFailed => 'Impossibile eliminare la raccolta';
	@override String deleteFailedWithError({required Object error}) => 'Impossibile eliminare la raccolta: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Impossibile caricare gli elementi della raccolta: ${error}';
	@override String get addTo => 'Aggiungi alla raccolta';
	@override String get selectCollection => 'Seleziona raccolta';
	@override String get createNewCollection => 'Crea nuova raccolta';
	@override String get collectionName => 'Nome raccolta';
	@override String get enterCollectionName => 'Inserisci nome raccolta';
	@override String get addedToCollection => 'Aggiunto alla raccolta';
	@override String get errorAddingToCollection => 'Errore nell\'aggiunta alla raccolta';
	@override String get created => 'Raccolta creata';
	@override String get removeFromCollection => 'Rimuovi dalla raccolta';
	@override String removeFromCollectionConfirm({required Object title}) => 'Rimuovere "${title}" da questa raccolta?';
	@override String get removedFromCollection => 'Rimosso dalla raccolta';
	@override String get removeFromCollectionFailed => 'Impossibile rimuovere dalla raccolta';
	@override String removeFromCollectionError({required Object error}) => 'Errore durante la rimozione dalla raccolta: ${error}';
}

// Path: watchParty
class _StringsWatchPartyIt extends _StringsWatchPartyEn {
	_StringsWatchPartyIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Watch Party';
	@override String get startParty => 'Avvia Watch Party';
	@override String get joinParty => 'Unisciti alla Party';
	@override String get enterCode => 'Inserisci codice party';
	@override String get shareCode => 'Condividi questo codice';
	@override String get friendsCanJoin => 'Gli amici possono unirsi usando questo codice';
	@override String get participants => 'Partecipanti';
	@override String get host => 'Host';
	@override String get endParty => 'Termina Party';
	@override String get leaveParty => 'Lascia Party';
	@override String get partyEnded => 'Watch Party terminata';
	@override String get chat => 'Chat';
	@override String get typeMessage => 'Scrivi un messaggio...';
	@override String joined({required Object name}) => '${name} si è unito';
	@override String left({required Object name}) => '${name} ha lasciato';
	@override String get syncedPlayback => 'Riproduzione sincronizzata con la party';
	@override String get hostControls => 'Solo l\'host può controllare la riproduzione';
	@override String get creating => 'Creazione party...';
	@override String get joining => 'Accesso alla party...';
	@override String get createFailed => 'Creazione party fallita';
	@override String get joinFailed => 'Accesso alla party fallito';
	@override String get invalidCode => 'Codice party non valido';
	@override String get gotIt => 'Capito';
}

// Path: catchUp
class _StringsCatchUpIt extends _StringsCatchUpEn {
	_StringsCatchUpIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Catch Up TV';
	@override String get startOver => 'Ricomincia';
	@override String get startOverDescription => 'Guarda dall\'inizio';
	@override String get watchFromBeginning => 'Guardare dall\'inizio?';
	@override String alreadyStarted({required Object title}) => '"${title}" è già iniziato. Puoi guardare dall\'inizio.';
	@override String get watchLive => 'Guarda in diretta';
	@override String get programsAvailable => 'Programmi disponibili';
	@override String get noProgramsAvailable => 'Nessun programma catch-up disponibile';
	@override String get programsWillAppear => 'I programmi appariranno qui man mano che vengono trasmessi';
	@override String get unavailable => 'Non disponibile';
	@override String get bufferNotReady => 'Buffer non ancora pronto';
	@override String get rewind => 'Riavvolgi';
	@override String get timeshiftEnabled => 'Time-shift abilitato';
	@override String goBackTo({required Object time}) => 'Torna a ${time}';
}

// Path: watchlist
class _StringsWatchlistIt extends _StringsWatchlistEn {
	_StringsWatchlistIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'La mia lista';
	@override String get all => 'Tutti';
	@override String get movies => 'Film';
	@override String get shows => 'Serie TV';
	@override String get episodes => 'Episodi';
	@override String get empty => 'La tua lista è vuota';
	@override String get emptyHint => 'Aggiungi film e serie alla tua lista dalle loro pagine';
	@override String get noItemsFiltered => 'Nessun elemento corrisponde a questo filtro';
	@override String get removeTitle => 'Rimuovi dalla lista';
	@override String removeConfirm({required Object title}) => 'Rimuovere "${title}" dalla tua lista?';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get clearAllTitle => 'Svuota lista';
	@override String clearAllConfirm({required Object count}) => 'Rimuovere tutti i ${count} elementi dalla tua lista?';
	@override String get clearAll => 'Svuota tutto';
	@override String get addedToday => 'Aggiunto oggi';
	@override String get addedYesterday => 'Aggiunto ieri';
	@override String addedDaysAgo({required Object days}) => 'Aggiunto ${days} giorni fa';
	@override String addedOn({required Object date}) => 'Aggiunto il ${date}';
	@override String get addToWatchlist => 'Aggiungi alla lista';
	@override String get removeFromWatchlist => 'Rimuovi dalla lista';
	@override String get addedToWatchlist => 'Aggiunto alla lista';
	@override String get removedFromWatchlist => 'Rimosso dalla lista';
}

// Path: liveTV
class _StringsLiveTVIt extends _StringsLiveTVEn {
	_StringsLiveTVIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV in diretta';
	@override String get guide => 'Guida';
	@override String get dvr => 'DVR';
	@override String get multiview => 'Multiview';
	@override String get allChannels => 'Tutti i canali';
	@override String get favorites => 'Preferiti';
	@override String get noChannels => 'Nessun canale disponibile';
	@override String get addM3USource => 'Aggiungi una sorgente M3U nelle impostazioni del server';
	@override String get recording => 'Registrazione';
	@override String get recordingNow => 'In registrazione ora';
	@override String get upNext => 'Prossimamente';
	@override String get noProgram => 'Nessuna info programma';
	@override String get filterByGroup => 'Filtra per gruppo';
	@override String get refresh => 'Aggiorna';
	@override String channelCount({required Object count}) => '${count} canali';
	@override String get nowPlaying => 'In onda ora';
	@override String get scheduleRecording => 'Programma registrazione';
	@override String get onNow => 'In onda adesso';
	@override String endsAt({required Object time}) => 'Finisce alle ${time}';
	@override String startsAt({required Object time}) => 'Inizia alle ${time}';
	@override String playbackError({required Object error}) => 'Errore di riproduzione: ${error}';
	@override String get noPreviousChannel => 'Nessun canale precedente';
	@override String switchedTo({required Object channel}) => 'Passato a: ${channel}';
	@override String get startingFromBeginning => 'Avvio del programma dall\'inizio...';
	@override String failedToStartOver({required Object error}) => 'Impossibile riavviare: ${error}';
	@override String playingProgram({required Object title}) => 'In riproduzione: ${title}';
	@override String failedToPlayProgram({required Object error}) => 'Impossibile riprodurre il programma: ${error}';
	@override String get addedToFavorites => 'Aggiunto ai preferiti';
	@override String get removedFromFavorites => 'Rimosso dai preferiti';
	@override String failedToUpdateFavorite({required Object error}) => 'Impossibile aggiornare preferito: ${error}';
	@override String get pipNotSupported => 'Picture-in-Picture non supportato su questa piattaforma';
	@override String get enteredPipMode => 'Modalità Picture-in-Picture attivata';
	@override String get exitedPipMode => 'Modalità Picture-in-Picture disattivata';
	@override String aspectRatioChanged({required Object mode}) => 'Rapporto aspetto: ${mode}';
	@override String get tune => 'Sintonizza';
	@override String get retry => 'Riprova';
	@override String get noChannelsMatchFilter => 'Nessun canale corrisponde al filtro';
	@override String get skipCommercial => 'Salta pubblicità';
}

// Path: dvr
class _StringsDvrIt extends _StringsDvrEn {
	_StringsDvrIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'DVR';
	@override String get recordings => 'Registrazioni';
	@override String get seriesRules => 'Regole serie';
	@override String get noRecordings => 'Nessuna registrazione';
	@override String get noRules => 'Nessuna regola serie';
	@override String get scheduleFromGuide => 'Programma registrazioni dalla guida TV';
	@override String get createRulesHint => 'Crea regole per registrare serie automaticamente';
	@override String get storage => 'Spazio di archiviazione';
	@override String recordingsCount({required Object count}) => '${count} registrazioni';
	@override String get all => 'Tutte';
	@override String get scheduled => 'Programmate';
	@override String get completed => 'Completate';
	@override String get failed => 'Non riuscite';
	@override String get deleteRecording => 'Eliminare registrazione?';
	@override String get deleteRule => 'Eliminare regola serie?';
	@override String get sortByDate => 'Data';
	@override String get sortByTitle => 'Titolo';
	@override String get sortBySize => 'Dimensione';
	@override String get playRecording => 'Riproduci registrazione';
	@override String keepPolicy({required Object count}) => 'Mantieni ${count} episodi';
	@override String get keepAll => 'Mantieni tutti';
	@override String get recordingScheduled => 'Registrazione programmata';
	@override String get scheduleRecordingTitle => 'Programma registrazione';
	@override String get schedule => 'Programma';
	@override String get cancel => 'Annulla';
}

// Path: epg
class _StringsEpgIt extends _StringsEpgEn {
	_StringsEpgIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guida TV';
	@override String get now => 'Adesso';
	@override String get today => 'Oggi';
	@override String get tomorrow => 'Domani';
	@override String get noPrograms => 'Nessun programma disponibile';
	@override String get loading => 'Caricamento guida...';
	@override String get record => 'Registra';
	@override String get reminder => 'Imposta promemoria';
	@override String get moreInfo => 'Altre info';
	@override String get toggleView => 'Cambia vista';
	@override String get gridView => 'Vista a griglia';
	@override String get nowNextView => 'Vista ora/prossimo';
}

// Path: channelSurfing
class _StringsChannelSurfingIt extends _StringsChannelSurfingEn {
	_StringsChannelSurfingIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Zapping casuale';
	@override String get kidsMode => 'Modalità bambini';
	@override String get loading => 'Caricamento zapping casuale...';
	@override String get failedToLoad => 'Impossibile caricare il contenuto';
	@override String get retry => 'Riprova';
	@override String get noContent => 'Nessun contenuto disponibile';
	@override String itemsAvailable({required Object count}) => '${count} elementi disponibili';
	@override String get startSurfing => 'Inizia';
	@override String get pressBackToExit => 'Premi indietro per uscire';
	@override String get description => 'Guarda film e serie casuali in modo continuo';
	@override String get noServers => 'Nessun server disponibile';
}

// Path: multiview
class _StringsMultiviewIt extends _StringsMultiviewEn {
	_StringsMultiviewIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Multi-Vista';
	@override String get changeLayout => 'Cambia layout (L)';
	@override String get addChannel => 'Aggiungi canale (A)';
	@override String get removeChannel => 'Rimuovi canale (R)';
	@override String get swapChannel => 'Cambia canale';
	@override String get toggleMute => 'Attiva/Disattiva audio (M)';
	@override String get selectChannel => 'Seleziona canale';
	@override String get searchChannels => 'Cerca canali...';
	@override String get cancel => 'Annulla';
	@override String channelNumber({required Object number}) => 'Can. ${number}';
}

// Path: player
class _StringsPlayerIt extends _StringsPlayerEn {
	_StringsPlayerIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get playbackError => 'Errore di riproduzione';
	@override String get error => 'Errore';
	@override String failedToStartPlayback({required Object error}) => 'Impossibile avviare la riproduzione:\n${error}';
	@override String get ok => 'OK';
}

// Path: downloads
class _StringsDownloadsIt extends _StringsDownloadsEn {
	_StringsDownloadsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Download';
	@override String get deleteAll => 'Elimina tutto';
	@override String get deleteAllTitle => 'Eliminare tutti i download?';
	@override String deleteAllMessage({required Object count, required Object size}) => 'Questo eliminerà tutti i ${count} download e libererà ${size} di spazio.';
	@override String storageUsed({required Object size}) => 'Spazio utilizzato: ${size}';
	@override String downloading({required Object count}) => 'In download (${count})';
	@override String downloaded({required Object count}) => 'Scaricati (${count})';
	@override String get noDownloads => 'Nessun download';
	@override String get noDownloadsHint => 'Scarica film e serie per guardarli offline';
	@override String get deleteDownloadTitle => 'Eliminare il download?';
	@override String deleteDownloadMessage({required Object title}) => 'Eliminare "${title}"?';
	@override String get delete => 'Elimina';
	@override String get cancel => 'Annulla';
	@override String get downloadFailed => 'Download fallito';
	@override String get paused => 'In pausa';
}

// Path: libraries.tabs
class _StringsLibrariesTabsIt extends _StringsLibrariesTabsEn {
	_StringsLibrariesTabsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Consigliati';
	@override String get browse => 'Esplora';
	@override String get collections => 'Raccolte';
	@override String get playlists => 'Playlist';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsIt extends _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsIt._(_StringsIt root) : this._root = root, super._(root);

	@override final _StringsIt _root; // ignore: unused_field

	// Translations
	@override String get all => 'Tutti';
	@override String get movies => 'Film';
	@override String get shows => 'Serie TV';
	@override String get seasons => 'Stagioni';
	@override String get episodes => 'Episodi';
	@override String get folders => 'Cartelle';
}

// Path: <root>
class _StringsNl extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsNl.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.nl,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <nl>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _StringsNl _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppNl app = _StringsAppNl._(_root);
	@override late final _StringsAuthNl auth = _StringsAuthNl._(_root);
	@override late final _StringsCommonNl common = _StringsCommonNl._(_root);
	@override late final _StringsScreensNl screens = _StringsScreensNl._(_root);
	@override late final _StringsUpdateNl update = _StringsUpdateNl._(_root);
	@override late final _StringsSettingsNl settings = _StringsSettingsNl._(_root);
	@override late final _StringsSearchNl search = _StringsSearchNl._(_root);
	@override late final _StringsHotkeysNl hotkeys = _StringsHotkeysNl._(_root);
	@override late final _StringsPinEntryNl pinEntry = _StringsPinEntryNl._(_root);
	@override late final _StringsFileInfoNl fileInfo = _StringsFileInfoNl._(_root);
	@override late final _StringsMediaMenuNl mediaMenu = _StringsMediaMenuNl._(_root);
	@override late final _StringsAccessibilityNl accessibility = _StringsAccessibilityNl._(_root);
	@override late final _StringsTooltipsNl tooltips = _StringsTooltipsNl._(_root);
	@override late final _StringsVideoControlsNl videoControls = _StringsVideoControlsNl._(_root);
	@override late final _StringsUserStatusNl userStatus = _StringsUserStatusNl._(_root);
	@override late final _StringsMessagesNl messages = _StringsMessagesNl._(_root);
	@override late final _StringsProfileNl profile = _StringsProfileNl._(_root);
	@override late final _StringsSubtitlingStylingNl subtitlingStyling = _StringsSubtitlingStylingNl._(_root);
	@override late final _StringsDialogNl dialog = _StringsDialogNl._(_root);
	@override late final _StringsDiscoverNl discover = _StringsDiscoverNl._(_root);
	@override late final _StringsErrorsNl errors = _StringsErrorsNl._(_root);
	@override late final _StringsVoiceNl voice = _StringsVoiceNl._(_root);
	@override late final _StringsLibrariesNl libraries = _StringsLibrariesNl._(_root);
	@override late final _StringsAboutNl about = _StringsAboutNl._(_root);
	@override late final _StringsServerSelectionNl serverSelection = _StringsServerSelectionNl._(_root);
	@override late final _StringsHubDetailNl hubDetail = _StringsHubDetailNl._(_root);
	@override late final _StringsLogsNl logs = _StringsLogsNl._(_root);
	@override late final _StringsStatsNl stats = _StringsStatsNl._(_root);
	@override late final _StringsLicensesNl licenses = _StringsLicensesNl._(_root);
	@override late final _StringsNavigationNl navigation = _StringsNavigationNl._(_root);
	@override late final _StringsPlaylistsNl playlists = _StringsPlaylistsNl._(_root);
	@override late final _StringsCollectionsNl collections = _StringsCollectionsNl._(_root);
	@override late final _StringsWatchPartyNl watchParty = _StringsWatchPartyNl._(_root);
	@override late final _StringsCatchUpNl catchUp = _StringsCatchUpNl._(_root);
	@override late final _StringsWatchlistNl watchlist = _StringsWatchlistNl._(_root);
	@override late final _StringsLiveTVNl liveTV = _StringsLiveTVNl._(_root);
	@override late final _StringsDvrNl dvr = _StringsDvrNl._(_root);
	@override late final _StringsEpgNl epg = _StringsEpgNl._(_root);
	@override late final _StringsChannelSurfingNl channelSurfing = _StringsChannelSurfingNl._(_root);
	@override late final _StringsMultiviewNl multiview = _StringsMultiviewNl._(_root);
	@override late final _StringsPlayerNl player = _StringsPlayerNl._(_root);
	@override late final _StringsDownloadsNl downloads = _StringsDownloadsNl._(_root);
}

// Path: app
class _StringsAppNl extends _StringsAppEn {
	_StringsAppNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'OpenFlix';
	@override String get loading => 'Laden...';
}

// Path: auth
class _StringsAuthNl extends _StringsAuthEn {
	_StringsAuthNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get signIn => 'Inloggen';
	@override String get signUp => 'Registreren';
	@override String get signInWithPlex => 'Inloggen bij OpenFlix';
	@override String get showQRCode => 'Toon QR-code';
	@override String get cancel => 'Annuleren';
	@override String get authenticate => 'Authenticeren';
	@override String get retry => 'Opnieuw proberen';
	@override String get debugEnterToken => 'Debug: Voer Token in';
	@override String get plexTokenLabel => 'Authenticatietoken';
	@override String get plexTokenHint => 'Voer token in';
	@override String get authenticationTimeout => 'Authenticatie verlopen. Probeer opnieuw.';
	@override String get scanQRCodeInstruction => 'Scan deze QR-code om te authenticeren.';
	@override String get waitingForAuth => 'Wachten op authenticatie...\nVoltooi het inloggen in je browser.';
	@override String get serverUrl => 'Server URL';
	@override String get serverUrlHint => 'bijv. http://192.168.1.100:32400';
	@override String get username => 'Gebruikersnaam';
	@override String get usernameHint => 'Voer gebruikersnaam in';
	@override String get email => 'E-mail';
	@override String get emailHint => 'Voer e-mailadres in';
	@override String get password => 'Wachtwoord';
	@override String get passwordHint => 'Voer wachtwoord in';
	@override String get confirmPassword => 'Bevestig Wachtwoord';
	@override String get confirmPasswordHint => 'Voer wachtwoord opnieuw in';
	@override String get displayName => 'Weergavenaam';
	@override String get displayNameHint => 'Optionele weergavenaam';
	@override String get noAccount => 'Nog geen account?';
	@override String get haveAccount => 'Al een account?';
	@override String get connecting => 'Verbinden met server...';
	@override String get loggingIn => 'Inloggen...';
	@override String get registering => 'Account aanmaken...';
	@override String get connectToServer => 'Verbind met Server';
	@override String get changeServer => 'Wijzig Server';
	@override String serverConnected({required Object serverName}) => 'Verbonden met ${serverName}';
	@override String get invalidServerUrl => 'Voer een geldige server URL in';
	@override String get serverConnectionFailed => 'Verbinding met server mislukt';
	@override String get passwordMismatch => 'Wachtwoorden komen niet overeen';
	@override String get usernameRequired => 'Gebruikersnaam vereist';
	@override String get emailRequired => 'E-mail vereist';
	@override String get passwordRequired => 'Wachtwoord vereist';
	@override String get passwordTooShort => 'Wachtwoord moet minimaal 6 tekens zijn';
	@override String get invalidEmail => 'Voer een geldig e-mailadres in';
	@override String get firstUserNote => 'Eerste gebruiker wordt beheerder';
	@override String get howConnecting => 'Hoe maak je verbinding?';
	@override String get atHome => 'Thuis';
	@override String get atHomeDescription => 'Detecteer server automatisch op je lokale netwerk';
	@override String get awayFromHome => 'Onderweg';
	@override String get awayFromHomeDescription => 'Voer serveradres handmatig in';
	@override String get findYourServer => 'Vind je server';
	@override String get searching => 'Zoeken...';
	@override String get checkingNetwork => 'Netwerk controleren...';
	@override String get serversFound => 'Servers gevonden';
	@override String get scanAgain => 'Opnieuw zoeken';
	@override String get enterManually => 'Handmatig invoeren';
	@override String get noServersFound => 'Geen servers gevonden op je netwerk. Zorg ervoor dat je OpenFlix-server draait.';
	@override String discoveryFailed({required Object error}) => 'Zoeken mislukt: ${error}';
}

// Path: common
class _StringsCommonNl extends _StringsCommonEn {
	_StringsCommonNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuleren';
	@override String get save => 'Opslaan';
	@override String get close => 'Sluiten';
	@override String get clear => 'Wissen';
	@override String get reset => 'Resetten';
	@override String get later => 'Later';
	@override String get submit => 'Verzenden';
	@override String get confirm => 'Bevestigen';
	@override String get retry => 'Opnieuw proberen';
	@override String get playNow => 'Nu afspelen';
	@override String get logout => 'Uitloggen';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get owned => 'Eigendom';
	@override String get shared => 'Gedeeld';
	@override String get current => 'HUIDIG';
	@override String get unknown => 'Onbekend';
	@override String get refresh => 'Vernieuwen';
	@override String get yes => 'Ja';
	@override String get no => 'Nee';
	@override String get server => 'Server';
	@override String get delete => 'Verwijderen';
	@override String get shuffle => 'Willekeurig';
	@override String get addTo => 'Toevoegen aan...';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get live => 'LIVE';
	@override String get newLabel => 'NIEUW';
}

// Path: screens
class _StringsScreensNl extends _StringsScreensEn {
	_StringsScreensNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenties';
	@override String get selectServer => 'Selecteer server';
	@override String get switchProfile => 'Wissel van profiel';
	@override String get subtitleStyling => 'Ondertitel opmaak';
	@override String get search => 'Zoeken';
	@override String get logs => 'Logbestanden';
}

// Path: update
class _StringsUpdateNl extends _StringsUpdateEn {
	_StringsUpdateNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update beschikbaar';
	@override String versionAvailable({required Object version}) => 'Versie ${version} is beschikbaar';
	@override String currentVersion({required Object version}) => 'Huidig: ${version}';
	@override String get skipVersion => 'Deze versie overslaan';
	@override String get viewRelease => 'Bekijk release';
	@override String get latestVersion => 'Je hebt de nieuwste versie';
	@override String get checkFailed => 'Kon niet controleren op updates';
}

// Path: settings
class _StringsSettingsNl extends _StringsSettingsEn {
	_StringsSettingsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Instellingen';
	@override String get profile => 'Profiel';
	@override String get noProfileSelected => 'Geen profiel geselecteerd';
	@override String get kidsMode => 'Kindermodus';
	@override String get switchProfile => 'Profiel wisselen';
	@override String get switchProfileDescription => 'Wissel naar een ander profiel';
	@override String get manageProfiles => 'Profielen beheren';
	@override String get manageProfilesDescription => 'Profielen toevoegen, bewerken of verwijderen';
	@override String get language => 'Taal';
	@override String get theme => 'Thema';
	@override String get appearance => 'Uiterlijk';
	@override String get videoPlayback => 'Video afspelen';
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get advanced => 'Geavanceerd';
	@override String get useSeasonPostersDescription => 'Toon seizoenposter in plaats van serieposter voor afleveringen';
	@override String get showHeroSectionDescription => 'Toon uitgelichte inhoud carrousel op startscherm';
	@override String get secondsLabel => 'Seconden';
	@override String get minutesLabel => 'Minuten';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Voer duur in (${min}-${max})';
	@override String get systemTheme => 'Systeem';
	@override String get systemThemeDescription => 'Volg systeeminstellingen';
	@override String get lightTheme => 'Licht';
	@override String get darkTheme => 'Donker';
	@override String get libraryDensity => 'Bibliotheek dichtheid';
	@override String get compact => 'Compact';
	@override String get compactDescription => 'Kleinere kaarten, meer items zichtbaar';
	@override String get normal => 'Normaal';
	@override String get normalDescription => 'Standaard grootte';
	@override String get comfortable => 'Comfortabel';
	@override String get comfortableDescription => 'Grotere kaarten, minder items zichtbaar';
	@override String get viewMode => 'Weergavemodus';
	@override String get gridView => 'Raster';
	@override String get gridViewDescription => 'Items weergeven in een rasterindeling';
	@override String get listView => 'Lijst';
	@override String get listViewDescription => 'Items weergeven in een lijstindeling';
	@override String get useSeasonPosters => 'Gebruik seizoenposters';
	@override String get showHeroSection => 'Toon hoofdsectie';
	@override String get hardwareDecoding => 'Hardware decodering';
	@override String get hardwareDecodingDescription => 'Gebruik hardware versnelling indien beschikbaar';
	@override String get bufferSize => 'Buffer grootte';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Ondertitel opmaak';
	@override String get subtitleStylingDescription => 'Pas ondertitel uiterlijk aan';
	@override String get smallSkipDuration => 'Korte skip duur';
	@override String get largeSkipDuration => 'Lange skip duur';
	@override String secondsUnit({required Object seconds}) => '${seconds} seconden';
	@override String get defaultSleepTimer => 'Standaard slaap timer';
	@override String minutesUnit({required Object minutes}) => 'bij ${minutes} minuten';
	@override String get rememberTrackSelections => 'Onthoud track selecties per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Bewaar automatisch audio- en ondertiteltaalvoorkeuren wanneer je tracks wijzigt tijdens afspelen';
	@override String get unwatchedOnly => 'Alleen ongekeken';
	@override String get unwatchedOnlyDescription => 'Alleen ongekeken afleveringen opnemen in willekeurige wachtrij';
	@override String get shuffleOrderNavigation => 'Willekeurige volgorde navigatie';
	@override String get shuffleOrderNavigationDescription => 'Volgende/vorige knoppen volgen willekeurige volgorde';
	@override String get loopShuffleQueue => 'Herhaal willekeurige wachtrij';
	@override String get loopShuffleQueueDescription => 'Start wachtrij opnieuw bij het einde';
	@override String get videoPlayerControls => 'Videospeler bediening';
	@override String get keyboardShortcuts => 'Toetsenbord sneltoetsen';
	@override String get keyboardShortcutsDescription => 'Pas toetsenbord sneltoetsen aan';
	@override String get debugLogging => 'Debug logging';
	@override String get debugLoggingDescription => 'Schakel gedetailleerde logging in voor probleemoplossing';
	@override String get viewLogs => 'Bekijk logs';
	@override String get viewLogsDescription => 'Bekijk applicatie logs';
	@override String get clearCache => 'Cache wissen';
	@override String get clearCacheDescription => 'Dit wist alle gecachte afbeeldingen en gegevens. De app kan langer duren om inhoud te laden na het wissen van de cache.';
	@override String get clearCacheSuccess => 'Cache succesvol gewist';
	@override String get resetSettings => 'Instellingen resetten';
	@override String get resetSettingsDescription => 'Dit reset alle instellingen naar hun standaard waarden. Deze actie kan niet ongedaan gemaakt worden.';
	@override String get resetSettingsSuccess => 'Instellingen succesvol gereset';
	@override String get shortcutsReset => 'Sneltoetsen gereset naar standaard';
	@override String get about => 'Over';
	@override String get aboutDescription => 'App informatie en licenties';
	@override String get updates => 'Updates';
	@override String get updateAvailable => 'Update beschikbaar';
	@override String get checkForUpdates => 'Controleer op updates';
	@override String get validationErrorEnterNumber => 'Voer een geldig nummer in';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Duur moet tussen ${min} en ${max} ${unit} zijn';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Sneltoets al toegewezen aan ${action}';
	@override String shortcutUpdated({required Object action}) => 'Sneltoets bijgewerkt voor ${action}';
	@override String get autoSkip => 'Automatisch Overslaan';
	@override String get autoSkipIntro => 'Intro Automatisch Overslaan';
	@override String get autoSkipIntroDescription => 'Intro-markeringen na enkele seconden automatisch overslaan';
	@override String get autoSkipCredits => 'Credits Automatisch Overslaan';
	@override String get autoSkipCreditsDescription => 'Credits automatisch overslaan en volgende aflevering afspelen';
	@override String get autoSkipDelay => 'Vertraging Automatisch Overslaan';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} seconden wachten voor automatisch overslaan';
	@override String get metadataSection => 'Metadata';
	@override String get tmdbApiKey => 'TMDB API-sleutel';
	@override String get tmdbApiKeyDescription => 'Configureer TMDB voor uitgebreide metadata';
	@override String get tmdbApiKeyConfigured => 'API-sleutel geconfigureerd';
	@override String get tmdbApiKeyHint => 'Haal je API-sleutel op bij themoviedb.org';
	@override String get tmdbApiKeyPlaceholder => 'Voer je TMDB API-sleutel in';
	@override String get apiKey => 'API-sleutel';
	@override String get tmdbApiKeySaved => 'TMDB API-sleutel opgeslagen';
	@override String get tmdbApiKeyCleared => 'TMDB API-sleutel verwijderd';
	@override String get parentalControls => 'Ouderlijk Toezicht';
	@override String get enableParentalControls => 'Ouderlijk Toezicht Inschakelen';
	@override String get enableParentalControlsDescription => 'Beperk content op basis van leeftijdsclassificaties';
	@override String get setPin => 'PIN Instellen';
	@override String get setPinDescription => 'Voer een 4-cijferige PIN in om de instellingen te beschermen';
	@override String get confirmPin => 'PIN Bevestigen';
	@override String get confirmPinDescription => 'Voer de PIN nogmaals in ter bevestiging';
	@override String get enterPin => 'PIN Invoeren';
	@override String get enterPinDescription => 'Voer je ouderlijk toezicht PIN in';
	@override String get changePin => 'PIN Wijzigen';
	@override String get changePinDescription => 'Wijzig je ouderlijk toezicht PIN';
	@override String get pinSet => 'Ouderlijk toezicht PIN succesvol ingesteld';
	@override String get pinMismatch => 'PIN-codes komen niet overeen. Probeer opnieuw.';
	@override String get incorrectPin => 'Onjuiste PIN. Probeer opnieuw.';
	@override String get maxMovieRating => 'Maximale Filmclassificatie';
	@override String get maxTvRating => 'Maximale TV-classificatie';
}

// Path: search
class _StringsSearchNl extends _StringsSearchEn {
	_StringsSearchNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Zoek films, series, muziek...';
	@override String get tryDifferentTerm => 'Probeer een andere zoekterm';
	@override String get searchYourMedia => 'Zoek in je media';
	@override String get enterTitleActorOrKeyword => 'Voer een titel, acteur of trefwoord in';
	@override String get recentSearches => 'Recente zoekopdrachten';
	@override String get clear => 'Wissen';
	@override String get voiceSearch => 'Spraakzoeken';
	@override String get listening => 'Luisteren...';
	@override String get speakNow => 'Spreek nu';
	@override String get all => 'Alle';
	@override String get movies => 'Films';
	@override String get tvShows => 'Series';
	@override String get music => 'Muziek';
}

// Path: hotkeys
class _StringsHotkeysNl extends _StringsHotkeysEn {
	_StringsHotkeysNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Stel sneltoets in voor ${actionName}';
	@override String get clearShortcut => 'Wis sneltoets';
}

// Path: pinEntry
class _StringsPinEntryNl extends _StringsPinEntryEn {
	_StringsPinEntryNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Voer PIN in';
	@override String get showPin => 'Toon PIN';
	@override String get hidePin => 'Verberg PIN';
}

// Path: fileInfo
class _StringsFileInfoNl extends _StringsFileInfoEn {
	_StringsFileInfoNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bestand info';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'Bestand';
	@override String get advanced => 'Geavanceerd';
	@override String get codec => 'Codec';
	@override String get resolution => 'Resolutie';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Frame rate';
	@override String get aspectRatio => 'Beeldverhouding';
	@override String get profile => 'Profiel';
	@override String get bitDepth => 'Bit diepte';
	@override String get colorSpace => 'Kleurruimte';
	@override String get colorRange => 'Kleurbereik';
	@override String get colorPrimaries => 'Kleurprimaires';
	@override String get chromaSubsampling => 'Chroma subsampling';
	@override String get channels => 'Kanalen';
	@override String get path => 'Pad';
	@override String get size => 'Grootte';
	@override String get container => 'Container';
	@override String get duration => 'Duur';
	@override String get optimizedForStreaming => 'Geoptimaliseerd voor streaming';
	@override String get has64bitOffsets => '64-bit Offsets';
}

// Path: mediaMenu
class _StringsMediaMenuNl extends _StringsMediaMenuEn {
	_StringsMediaMenuNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Markeer als gekeken';
	@override String get markAsUnwatched => 'Markeer als ongekeken';
	@override String get removeFromContinueWatching => 'Verwijder uit Doorgaan met kijken';
	@override String get goToSeries => 'Ga naar serie';
	@override String get goToSeason => 'Ga naar seizoen';
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get fileInfo => 'Bestand info';
}

// Path: accessibility
class _StringsAccessibilityNl extends _StringsAccessibilityEn {
	_StringsAccessibilityNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV-serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'bekeken';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} procent bekeken';
	@override String get mediaCardUnwatched => 'niet bekeken';
	@override String get tapToPlay => 'Tik om af te spelen';
}

// Path: tooltips
class _StringsTooltipsNl extends _StringsTooltipsEn {
	_StringsTooltipsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Willekeurig afspelen';
	@override String get markAsWatched => 'Markeer als gekeken';
	@override String get markAsUnwatched => 'Markeer als ongekeken';
}

// Path: videoControls
class _StringsVideoControlsNl extends _StringsVideoControlsEn {
	_StringsVideoControlsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Ondertitels';
	@override String get resetToZero => 'Reset naar 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} speelt later af';
	@override String playsEarlier({required Object label}) => '${label} speelt eerder af';
	@override String get noOffset => 'Geen offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Vul scherm';
	@override String get stretch => 'Uitrekken';
	@override String get lockRotation => 'Vergrendel rotatie';
	@override String get unlockRotation => 'Ontgrendel rotatie';
	@override String get lockScreen => 'Vergrendel scherm';
	@override String get unlockScreen => 'Ontgrendel scherm';
	@override String get screenLockButton => 'Schermvergrendeling';
	@override String get screenLocked => 'Scherm vergrendeld';
	@override String get tapToUnlock => 'Tik om te ontgrendelen';
	@override String get sleepTimer => 'Slaaptimer';
	@override String get timerActive => 'Timer actief';
	@override String playbackWillPauseIn({required Object duration}) => 'Afspelen wordt gepauzeerd over ${duration}';
	@override String get sleepTimerCompleted => 'Slaaptimer voltooid - afspelen gepauzeerd';
	@override String get playButton => 'Afspelen';
	@override String get pauseButton => 'Pauzeren';
	@override String seekBackwardButton({required Object seconds}) => 'Terugspoelen ${seconds} seconden';
	@override String seekForwardButton({required Object seconds}) => 'Vooruitspoelen ${seconds} seconden';
	@override String get previousButton => 'Vorige aflevering';
	@override String get nextButton => 'Volgende aflevering';
	@override String get previousChapterButton => 'Vorig hoofdstuk';
	@override String get nextChapterButton => 'Volgend hoofdstuk';
	@override String get volumeButton => 'Volume';
	@override String get muteButton => 'Dempen';
	@override String get unmuteButton => 'Dempen opheffen';
	@override String get settingsButton => 'Video-instellingen';
	@override String get audioTrackButton => 'Audiosporen';
	@override String get subtitlesButton => 'Ondertitels';
	@override String get chaptersButton => 'Hoofdstukken';
	@override String get versionsButton => 'Videoversies';
	@override String get aspectRatioButton => 'Beeldverhouding';
	@override String get fullscreenButton => 'Volledig scherm activeren';
	@override String get exitFullscreenButton => 'Volledig scherm verlaten';
	@override String get rotationLockButton => 'Rotatievergrendeling';
	@override String get timelineSlider => 'Videotijdlijn';
	@override String get volumeSlider => 'Volumeniveau';
	@override String get backButton => 'Terug';
}

// Path: userStatus
class _StringsUserStatusNl extends _StringsUserStatusEn {
	_StringsUserStatusNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Beheerder';
	@override String get restricted => 'Beperkt';
	@override String get protected => 'Beschermd';
	@override String get current => 'HUIDIG';
}

// Path: messages
class _StringsMessagesNl extends _StringsMessagesEn {
	_StringsMessagesNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Gemarkeerd als gekeken';
	@override String get markedAsUnwatched => 'Gemarkeerd als ongekeken';
	@override String get removedFromContinueWatching => 'Verwijderd uit Doorgaan met kijken';
	@override String errorLoading({required Object error}) => 'Fout: ${error}';
	@override String get fileInfoNotAvailable => 'Bestand informatie niet beschikbaar';
	@override String errorLoadingFileInfo({required Object error}) => 'Fout bij laden bestand info: ${error}';
	@override String get errorLoadingSeries => 'Fout bij laden serie';
	@override String get errorLoadingSeason => 'Fout bij laden seizoen';
	@override String get musicNotSupported => 'Muziek afspelen wordt nog niet ondersteund';
	@override String get logsCleared => 'Logs gewist';
	@override String get logsCopied => 'Logs gekopieerd naar klembord';
	@override String get noLogsAvailable => 'Geen logs beschikbaar';
	@override String libraryScanning({required Object title}) => 'Scannen "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Bibliotheek scan gestart voor "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Kon bibliotheek niet scannen: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadata vernieuwen voor "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadata vernieuwen gestart voor "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Kon metadata niet vernieuwen: ${error}';
	@override String get noTokenFound => 'Geen token gevonden. Log opnieuw in.';
	@override String get logoutConfirm => 'Weet je zeker dat je wilt uitloggen?';
	@override String get noSeasonsFound => 'Geen seizoenen gevonden';
	@override String get noEpisodesFound => 'Geen afleveringen gevonden in eerste seizoen';
	@override String get noEpisodesFoundGeneral => 'Geen afleveringen gevonden';
	@override String get noResultsFound => 'Geen resultaten gevonden';
	@override String sleepTimerSet({required Object label}) => 'Slaap timer ingesteld voor ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
	@override String get noItemsAvailable => 'Geen items beschikbaar';
	@override String get failedToCreatePlayQueue => 'Kan afspeelwachtrij niet maken';
	@override String get failedToCreatePlayQueueNoItems => 'Kan afspeelwachtrij niet maken - geen items';
	@override String failedPlayback({required Object action, required Object error}) => 'Afspelen van ${action} mislukt: ${error}';
}

// Path: profile
class _StringsProfileNl extends _StringsProfileEn {
	_StringsProfileNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => 'Geen gebruikers beschikbaar';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingNl extends _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opmaak opties';
	@override String get fontSize => 'Lettergrootte';
	@override String get textColor => 'Tekstkleur';
	@override String get borderSize => 'Rand grootte';
	@override String get borderColor => 'Randkleur';
	@override String get backgroundOpacity => 'Achtergrond transparantie';
	@override String get backgroundColor => 'Achtergrondkleur';
}

// Path: dialog
class _StringsDialogNl extends _StringsDialogEn {
	_StringsDialogNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bevestig actie';
	@override String get areYouSure => 'Weet je zeker dat je deze actie wilt uitvoeren?';
	@override String get cancel => 'Annuleren';
	@override String get playNow => 'Nu afspelen';
}

// Path: discover
class _StringsDiscoverNl extends _StringsDiscoverEn {
	_StringsDiscoverNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ontdekken';
	@override String get switchProfile => 'Wissel van profiel';
	@override String get switchServer => 'Wissel van server';
	@override String get logout => 'Uitloggen';
	@override String get noContentAvailable => 'Geen inhoud beschikbaar';
	@override String get addMediaToLibraries => 'Voeg wat media toe aan je bibliotheken';
	@override String get continueWatching => 'Verder kijken';
	@override String get recentlyAdded => 'Recent toegevoegd';
	@override String get play => 'Afspelen';
	@override String get resume => 'Hervatten';
	@override String playEpisode({required Object season, required Object episode}) => 'Speel S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => 'Hervat S${season}, E${episode}';
	@override String get pause => 'Pauzeren';
	@override String get overview => 'Overzicht';
	@override String get cast => 'Acteurs';
	@override String get seasons => 'Seizoenen';
	@override String get studio => 'Studio';
	@override String get rating => 'Leeftijd';
	@override String get watched => 'Bekeken';
	@override String episodeCount({required Object count}) => '${count} afleveringen';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} gekeken';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV Serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min over';
	@override String get whatsOnNow => 'Nu op TV';
	@override String get channelGuide => 'TV Gids';
	@override String get liveNow => 'Nu Live';
	@override String get topTen => 'Top 10';
	@override String get newBadge => 'NIEUW';
	@override String get liveBadge => 'LIVE';
	@override String get goodMorning => 'Good morning';
	@override String get goodAfternoon => 'Good afternoon';
	@override String get goodEvening => 'Good evening';
	@override String get defaultUser => 'Guest';
	@override String get yourNextWatch => 'Your Next Watch';
	@override String pickedForYou({required Object name}) => 'Picked just for you, ${name}';
	@override String get surpriseMe => 'Surprise Me';
	@override String get randomPicker => 'Random Movie Picker';
	@override String get noMoviesFound => 'No movies found in your library';
	@override String get spinning => 'Picking something great...';
	@override String get spinAgain => 'Spin Again';
	@override String get calendar => 'Calendar';
	@override String get today => 'Today';
	@override String get item => 'item';
	@override String get items => 'items';
	@override String get loadingMovies => 'Je films laden...';
	@override String get noContentOnDate => 'No content added on this date';
	@override String get noEpgData => 'Geen programma-informatie';
}

// Path: errors
class _StringsErrorsNl extends _StringsErrorsEn {
	_StringsErrorsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Zoeken mislukt: ${error}';
	@override String connectionTimeout({required Object context}) => 'Verbinding time-out tijdens laden ${context}';
	@override String get connectionFailed => 'Kan geen verbinding maken met Plex server';
	@override String failedToLoad({required Object context, required Object error}) => 'Kon ${context} niet laden: ${error}';
	@override String get noClientAvailable => 'Geen client beschikbaar';
	@override String authenticationFailed({required Object error}) => 'Authenticatie mislukt: ${error}';
	@override String get couldNotLaunchUrl => 'Kon auth URL niet openen';
	@override String get pleaseEnterToken => 'Voer een token in';
	@override String get invalidToken => 'Ongeldig token';
	@override String failedToVerifyToken({required Object error}) => 'Kon token niet verifiëren: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
	@override String get connectionFailedGeneric => 'Verbinding mislukt';
	@override String failedToRemove({required Object error}) => 'Verwijderen mislukt: ${error}';
}

// Path: voice
class _StringsVoiceNl extends _StringsVoiceEn {
	_StringsVoiceNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get notAvailable => 'Spraakbesturing is niet beschikbaar';
	@override String commandNotRecognized({required Object command}) => 'Commando niet herkend: "${command}"';
}

// Path: libraries
class _StringsLibrariesNl extends _StringsLibrariesEn {
	_StringsLibrariesNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotheken';
	@override String get scanLibraryFiles => 'Scan bibliotheek bestanden';
	@override String get scanLibrary => 'Scan bibliotheek';
	@override String get analyze => 'Analyseren';
	@override String get analyzeLibrary => 'Analyseer bibliotheek';
	@override String get refreshMetadata => 'Vernieuw metadata';
	@override String get emptyTrash => 'Prullenbak legen';
	@override String emptyingTrash({required Object title}) => 'Prullenbak legen voor "${title}"...';
	@override String trashEmptied({required Object title}) => 'Prullenbak geleegd voor "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Kon prullenbak niet legen: ${error}';
	@override String analyzing({required Object title}) => 'Analyseren "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analyse gestart voor "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Kon bibliotheek niet analyseren: ${error}';
	@override String get noLibrariesFound => 'Geen bibliotheken gevonden';
	@override String get thisLibraryIsEmpty => 'Deze bibliotheek is leeg';
	@override String get all => 'Alles';
	@override String get clearAll => 'Alles wissen';
	@override String scanLibraryConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt scannen?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt analyseren?';
	@override String refreshMetadataConfirm({required Object title}) => 'Weet je zeker dat je metadata wilt vernieuwen voor "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Weet je zeker dat je de prullenbak wilt legen voor "${title}"?';
	@override String get manageLibraries => 'Beheer bibliotheken';
	@override String get sort => 'Sorteren';
	@override String get sortBy => 'Sorteer op';
	@override String get filters => 'Filters';
	@override String loadingLibraryWithCount({required Object count}) => 'Bibliotheek laden... (${count} items geladen)';
	@override String get confirmActionMessage => 'Weet je zeker dat je deze actie wilt uitvoeren?';
	@override String get showLibrary => 'Toon bibliotheek';
	@override String get hideLibrary => 'Verberg bibliotheek';
	@override String get libraryOptions => 'Bibliotheek opties';
	@override String get content => 'bibliotheekinhoud';
	@override String get selectLibrary => 'Bibliotheek kiezen';
	@override String filtersWithCount({required Object count}) => 'Filters (${count})';
	@override String get noRecommendations => 'Geen aanbevelingen beschikbaar';
	@override String get noCollections => 'Geen collecties in deze bibliotheek';
	@override String get noFoldersFound => 'Geen mappen gevonden';
	@override String get folders => 'mappen';
	@override late final _StringsLibrariesTabsNl tabs = _StringsLibrariesTabsNl._(_root);
	@override late final _StringsLibrariesGroupingsNl groupings = _StringsLibrariesGroupingsNl._(_root);
}

// Path: about
class _StringsAboutNl extends _StringsAboutEn {
	_StringsAboutNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Over';
	@override String get openSourceLicenses => 'Open Source licenties';
	@override String versionLabel({required Object version}) => 'Versie ${version}';
	@override String get appDescription => 'Een mooie Plex client voor Flutter';
	@override String get viewLicensesDescription => 'Bekijk licenties van third-party bibliotheken';
}

// Path: serverSelection
class _StringsServerSelectionNl extends _StringsServerSelectionEn {
	_StringsServerSelectionNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get connectingToServer => 'Verbinden met server...';
	@override String get connectingToAllServers => 'Verbinden met alle servers...';
	@override String get connectToAllServers => 'Verbind met alle servers';
	@override String get allServerConnectionsFailed => 'Kon niet verbinden met servers. Controleer je netwerk en probeer opnieuw.';
	@override String foundServers({required Object count}) => '${count} server(s) gevonden';
	@override String get orSelectIndividually => 'Of selecteer een server individueel:';
	@override String get serverDebugCopied => 'Server debug gegevens gekopieerd naar klembord';
	@override String get copyDebugData => 'Kopieer debug gegevens';
	@override String get noServersFound => 'Geen servers gevonden';
	@override String malformedServerData({required Object count}) => '${count} server(s) gevonden met verkeerde data. Geen geldige servers beschikbaar.';
	@override String get incompleteServerInfo => 'Sommige servers hebben incomplete informatie en zijn overgeslagen. Controleer je Plex.tv account.';
	@override String get incompleteConnectionInfo => 'Server verbinding informatie is incompleet. Probeer opnieuw.';
	@override String malformedServerInfo({required Object message}) => 'Server informatie is verkeerd geformatteerd: ${message}';
	@override String get networkConnectionFailed => 'Netwerkverbinding mislukt. Controleer je internetverbinding en probeer opnieuw.';
	@override String get authenticationFailed => 'Authenticatie mislukt. Log opnieuw in.';
	@override String get plexServiceUnavailable => 'Plex service niet beschikbaar. Probeer later opnieuw.';
	@override String failedToLoadServers({required Object error}) => 'Kon servers niet laden: ${error}';
}

// Path: hubDetail
class _StringsHubDetailNl extends _StringsHubDetailEn {
	_StringsHubDetailNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Uitgavejaar';
	@override String get dateAdded => 'Datum toegevoegd';
	@override String get rating => 'Beoordeling';
	@override String get noItemsFound => 'Geen items gevonden';
}

// Path: logs
class _StringsLogsNl extends _StringsLogsEn {
	_StringsLogsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Logbestanden';
	@override String get clearLogs => 'Wis logs';
	@override String get copyLogs => 'Kopieer logs';
	@override String get exportLogs => 'Exporteer logs';
	@override String get noLogsToShow => 'Geen logs om te tonen';
	@override String get error => 'Fout:';
	@override String get stackTrace => 'Stacktracering:';
}

// Path: stats
class _StringsStatsNl extends _StringsStatsEn {
	_StringsStatsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kijkstatistieken';
	@override String get totalWatchTime => 'Totale Kijktijd';
	@override String get moviesWatched => 'Films Bekeken';
	@override String get episodesWatched => 'Afleveringen Bekeken';
	@override String get avgPerDay => 'Gemiddeld per Dag';
	@override String get topGenres => 'Favoriete Genres';
	@override String get monthlyActivity => 'Maandelijkse Activiteit';
	@override String get noData => 'Nog geen kijkgeschiedenis';
	@override String get startWatching => 'Begin met kijken om je statistieken te zien';
	@override String get days => 'dagen';
}

// Path: licenses
class _StringsLicensesNl extends _StringsLicensesEn {
	_StringsLicensesNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Gerelateerde pakketten';
	@override String get license => 'Licentie';
	@override String licenseNumber({required Object number}) => 'Licentie ${number}';
	@override String licensesCount({required Object count}) => '${count} licenties';
}

// Path: navigation
class _StringsNavigationNl extends _StringsNavigationEn {
	_StringsNavigationNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get home => 'Thuis';
	@override String get search => 'Zoeken';
	@override String get libraries => 'Bibliotheken';
	@override String get livetv => 'Live TV';
	@override String get settings => 'Instellingen';
}

// Path: playlists
class _StringsPlaylistsNl extends _StringsPlaylistsEn {
	_StringsPlaylistsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Afspeellijsten';
	@override String get noPlaylists => 'Geen afspeellijsten gevonden';
	@override String get create => 'Afspeellijst maken';
	@override String get newPlaylist => 'Nieuwe afspeellijst';
	@override String get playlistName => 'Naam afspeellijst';
	@override String get enterPlaylistName => 'Voer naam afspeellijst in';
	@override String get edit => 'Afspeellijst bewerken';
	@override String get delete => 'Afspeellijst verwijderen';
	@override String get addTo => 'Toevoegen aan afspeellijst';
	@override String get addItems => 'Items toevoegen';
	@override String get removeItem => 'Verwijderen uit afspeellijst';
	@override String get clearPlaylist => 'Afspeellijst wissen';
	@override String get playAll => 'Alles afspelen';
	@override String get shuffle => 'Willekeurig';
	@override String get smartPlaylist => 'Slimme afspeellijst';
	@override String get regularPlaylist => 'Normale afspeellijst';
	@override String itemCount({required Object count}) => '${count} items';
	@override String get oneItem => '1 item';
	@override String get emptyPlaylist => 'Deze afspeellijst is leeg';
	@override String get deleteConfirm => 'Afspeellijst verwijderen?';
	@override String deleteMessage({required Object name}) => 'Weet je zeker dat je "${name}" wilt verwijderen?';
	@override String get created => 'Afspeellijst gemaakt';
	@override String get updated => 'Afspeellijst bijgewerkt';
	@override String get deleted => 'Afspeellijst verwijderd';
	@override String get itemAdded => 'Toegevoegd aan afspeellijst';
	@override String get itemRemoved => 'Verwijderd uit afspeellijst';
	@override String get selectPlaylist => 'Selecteer afspeellijst';
	@override String get createNewPlaylist => 'Nieuwe afspeellijst maken';
	@override String get errorCreating => 'Fout bij maken afspeellijst';
	@override String get errorDeleting => 'Fout bij verwijderen afspeellijst';
	@override String get errorLoading => 'Fout bij laden afspeellijsten';
	@override String get errorAdding => 'Fout bij toevoegen aan afspeellijst';
	@override String get errorReordering => 'Fout bij herschikken van afspeellijstitem';
	@override String get errorRemoving => 'Fout bij verwijderen uit afspeellijst';
	@override String get playlist => 'Afspeellijst';
}

// Path: collections
class _StringsCollectionsNl extends _StringsCollectionsEn {
	_StringsCollectionsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Collecties';
	@override String get collection => 'Collectie';
	@override String get empty => 'Collectie is leeg';
	@override String get noItems => 'Geen items in deze collectie';
	@override String get unknownLibrarySection => 'Kan niet verwijderen: onbekende bibliotheeksectie';
	@override String get deleteCollection => 'Collectie verwijderen';
	@override String deleteConfirm({required Object title}) => 'Weet je zeker dat je "${title}" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.';
	@override String get deleted => 'Collectie verwijderd';
	@override String get deleteFailed => 'Collectie verwijderen mislukt';
	@override String deleteFailedWithError({required Object error}) => 'Collectie verwijderen mislukt: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Collectie-items laden mislukt: ${error}';
	@override String get addTo => 'Toevoegen aan collectie';
	@override String get selectCollection => 'Selecteer collectie';
	@override String get createNewCollection => 'Nieuwe collectie maken';
	@override String get collectionName => 'Collectienaam';
	@override String get enterCollectionName => 'Voer collectienaam in';
	@override String get addedToCollection => 'Toegevoegd aan collectie';
	@override String get errorAddingToCollection => 'Fout bij toevoegen aan collectie';
	@override String get created => 'Collectie gemaakt';
	@override String get removeFromCollection => 'Verwijderen uit collectie';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" uit deze collectie verwijderen?';
	@override String get removedFromCollection => 'Uit collectie verwijderd';
	@override String get removeFromCollectionFailed => 'Verwijderen uit collectie mislukt';
	@override String removeFromCollectionError({required Object error}) => 'Fout bij verwijderen uit collectie: ${error}';
}

// Path: watchParty
class _StringsWatchPartyNl extends _StringsWatchPartyEn {
	_StringsWatchPartyNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Watch Party';
	@override String get startParty => 'Watch Party starten';
	@override String get joinParty => 'Deelnemen aan Party';
	@override String get enterCode => 'Voer party code in';
	@override String get shareCode => 'Deel deze code';
	@override String get friendsCanJoin => 'Vrienden kunnen deelnemen met deze code';
	@override String get participants => 'Deelnemers';
	@override String get host => 'Host';
	@override String get endParty => 'Party beëindigen';
	@override String get leaveParty => 'Party verlaten';
	@override String get partyEnded => 'Watch Party beëindigd';
	@override String get chat => 'Chat';
	@override String get typeMessage => 'Typ een bericht...';
	@override String joined({required Object name}) => '${name} is toegetreden';
	@override String left({required Object name}) => '${name} is vertrokken';
	@override String get syncedPlayback => 'Afspelen is gesynchroniseerd met party';
	@override String get hostControls => 'Alleen de host kan het afspelen bedienen';
	@override String get creating => 'Party wordt aangemaakt...';
	@override String get joining => 'Deelnemen aan party...';
	@override String get createFailed => 'Party aanmaken mislukt';
	@override String get joinFailed => 'Deelnemen aan party mislukt';
	@override String get invalidCode => 'Ongeldige party code';
	@override String get gotIt => 'Begrepen';
}

// Path: catchUp
class _StringsCatchUpNl extends _StringsCatchUpEn {
	_StringsCatchUpNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Catch Up TV';
	@override String get startOver => 'Opnieuw beginnen';
	@override String get startOverDescription => 'Vanaf het begin kijken';
	@override String get watchFromBeginning => 'Vanaf het begin kijken?';
	@override String alreadyStarted({required Object title}) => '"${title}" is al begonnen. Je kunt vanaf het begin kijken.';
	@override String get watchLive => 'Live kijken';
	@override String get programsAvailable => 'Beschikbare programma\'s';
	@override String get noProgramsAvailable => 'Geen catch-up programma\'s beschikbaar';
	@override String get programsWillAppear => 'Programma\'s verschijnen hier naarmate ze worden uitgezonden';
	@override String get unavailable => 'Niet beschikbaar';
	@override String get bufferNotReady => 'Buffer nog niet klaar';
	@override String get rewind => 'Terugspoelen';
	@override String get timeshiftEnabled => 'Time-shift ingeschakeld';
	@override String goBackTo({required Object time}) => 'Ga terug naar ${time}';
}

// Path: watchlist
class _StringsWatchlistNl extends _StringsWatchlistEn {
	_StringsWatchlistNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mijn kijklijst';
	@override String get all => 'Alle';
	@override String get movies => 'Films';
	@override String get shows => 'Series';
	@override String get episodes => 'Afleveringen';
	@override String get empty => 'Je kijklijst is leeg';
	@override String get emptyHint => 'Voeg films en series toe aan je kijklijst';
	@override String get noItemsFiltered => 'Geen items komen overeen met dit filter';
	@override String get removeTitle => 'Verwijder van kijklijst';
	@override String removeConfirm({required Object title}) => '"${title}" van je kijklijst verwijderen?';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get clearAllTitle => 'Kijklijst wissen';
	@override String clearAllConfirm({required Object count}) => 'Alle ${count} items van je kijklijst verwijderen?';
	@override String get clearAll => 'Alles wissen';
	@override String get addedToday => 'Vandaag toegevoegd';
	@override String get addedYesterday => 'Gisteren toegevoegd';
	@override String addedDaysAgo({required Object days}) => '${days} dagen geleden toegevoegd';
	@override String addedOn({required Object date}) => 'Toegevoegd op ${date}';
	@override String get addToWatchlist => 'Toevoegen aan kijklijst';
	@override String get removeFromWatchlist => 'Verwijderen van kijklijst';
	@override String get addedToWatchlist => 'Toegevoegd aan kijklijst';
	@override String get removedFromWatchlist => 'Verwijderd van kijklijst';
}

// Path: liveTV
class _StringsLiveTVNl extends _StringsLiveTVEn {
	_StringsLiveTVNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live TV';
	@override String get guide => 'Gids';
	@override String get dvr => 'DVR';
	@override String get multiview => 'Multiview';
	@override String get allChannels => 'Alle zenders';
	@override String get favorites => 'Favorieten';
	@override String get noChannels => 'Geen zenders beschikbaar';
	@override String get addM3USource => 'Voeg een M3U-bron toe in serverinstellingen';
	@override String get recording => 'Opnemen';
	@override String get recordingNow => 'Nu opnemen';
	@override String get upNext => 'Hierna';
	@override String get noProgram => 'Geen programma-info';
	@override String get filterByGroup => 'Filter op groep';
	@override String get refresh => 'Vernieuwen';
	@override String channelCount({required Object count}) => '${count} zenders';
	@override String get nowPlaying => 'Nu op TV';
	@override String get scheduleRecording => 'Opname plannen';
	@override String get onNow => 'Nu te zien';
	@override String endsAt({required Object time}) => 'Eindigt om ${time}';
	@override String startsAt({required Object time}) => 'Start om ${time}';
	@override String playbackError({required Object error}) => 'Afspeelfout: ${error}';
	@override String get noPreviousChannel => 'Geen vorig kanaal';
	@override String switchedTo({required Object channel}) => 'Gewisseld naar: ${channel}';
	@override String get startingFromBeginning => 'Programma vanaf begin starten...';
	@override String failedToStartOver({required Object error}) => 'Opnieuw starten mislukt: ${error}';
	@override String playingProgram({required Object title}) => 'Afspelen: ${title}';
	@override String failedToPlayProgram({required Object error}) => 'Programma afspelen mislukt: ${error}';
	@override String get addedToFavorites => 'Toegevoegd aan favorieten';
	@override String get removedFromFavorites => 'Verwijderd uit favorieten';
	@override String failedToUpdateFavorite({required Object error}) => 'Favoriet bijwerken mislukt: ${error}';
	@override String get pipNotSupported => 'Picture-in-Picture niet ondersteund op dit platform';
	@override String get enteredPipMode => 'Picture-in-Picture modus geactiveerd';
	@override String get exitedPipMode => 'Picture-in-Picture modus beëindigd';
	@override String aspectRatioChanged({required Object mode}) => 'Beeldverhouding: ${mode}';
	@override String get tune => 'Afstemmen';
	@override String get retry => 'Opnieuw proberen';
	@override String get noChannelsMatchFilter => 'Geen kanalen komen overeen met filter';
	@override String get skipCommercial => 'Reclame overslaan';
}

// Path: dvr
class _StringsDvrNl extends _StringsDvrEn {
	_StringsDvrNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'DVR';
	@override String get recordings => 'Opnames';
	@override String get seriesRules => 'Serie regels';
	@override String get noRecordings => 'Geen opnames';
	@override String get noRules => 'Geen serie regels';
	@override String get scheduleFromGuide => 'Plan opnames vanuit de Live TV gids';
	@override String get createRulesHint => 'Maak regels om series automatisch op te nemen';
	@override String get storage => 'Opslag';
	@override String recordingsCount({required Object count}) => '${count} opnames';
	@override String get all => 'Alle';
	@override String get scheduled => 'Gepland';
	@override String get completed => 'Voltooid';
	@override String get failed => 'Mislukt';
	@override String get deleteRecording => 'Opname verwijderen?';
	@override String get deleteRule => 'Serie regel verwijderen?';
	@override String get sortByDate => 'Datum';
	@override String get sortByTitle => 'Titel';
	@override String get sortBySize => 'Grootte';
	@override String get playRecording => 'Opname afspelen';
	@override String keepPolicy({required Object count}) => 'Bewaar ${count} afleveringen';
	@override String get keepAll => 'Alles bewaren';
	@override String get recordingScheduled => 'Opname gepland';
	@override String get scheduleRecordingTitle => 'Opname plannen';
	@override String get schedule => 'Plannen';
	@override String get cancel => 'Annuleren';
}

// Path: epg
class _StringsEpgNl extends _StringsEpgEn {
	_StringsEpgNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV Gids';
	@override String get now => 'Nu';
	@override String get today => 'Vandaag';
	@override String get tomorrow => 'Morgen';
	@override String get noPrograms => 'Geen programma-informatie beschikbaar';
	@override String get loading => 'Gids laden...';
	@override String get record => 'Opnemen';
	@override String get reminder => 'Herinnering instellen';
	@override String get moreInfo => 'Meer info';
	@override String get toggleView => 'Wissel weergave';
	@override String get gridView => 'Rasterweergave';
	@override String get nowNextView => 'Nu/Straks weergave';
}

// Path: channelSurfing
class _StringsChannelSurfingNl extends _StringsChannelSurfingEn {
	_StringsChannelSurfingNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Willekeurig kijken';
	@override String get kidsMode => 'Kindermodus';
	@override String get loading => 'Willekeurig kijken laden...';
	@override String get failedToLoad => 'Inhoud kon niet worden geladen';
	@override String get retry => 'Opnieuw proberen';
	@override String get noContent => 'Geen inhoud beschikbaar';
	@override String itemsAvailable({required Object count}) => '${count} items beschikbaar';
	@override String get startSurfing => 'Starten';
	@override String get pressBackToExit => 'Druk terug om af te sluiten';
	@override String get description => 'Kijk willekeurige films en series doorlopend';
	@override String get noServers => 'Geen servers beschikbaar';
}

// Path: multiview
class _StringsMultiviewNl extends _StringsMultiviewEn {
	_StringsMultiviewNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Multi-View';
	@override String get changeLayout => 'Layout wijzigen (L)';
	@override String get addChannel => 'Zender toevoegen (A)';
	@override String get removeChannel => 'Zender verwijderen (R)';
	@override String get swapChannel => 'Zender wijzigen';
	@override String get toggleMute => 'Geluid aan/uit (M)';
	@override String get selectChannel => 'Zender selecteren';
	@override String get searchChannels => 'Zenders zoeken...';
	@override String get cancel => 'Annuleren';
	@override String channelNumber({required Object number}) => 'Z. ${number}';
}

// Path: player
class _StringsPlayerNl extends _StringsPlayerEn {
	_StringsPlayerNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get playbackError => 'Afspeelfout';
	@override String get error => 'Fout';
	@override String failedToStartPlayback({required Object error}) => 'Kan afspelen niet starten:\n${error}';
	@override String get ok => 'OK';
}

// Path: downloads
class _StringsDownloadsNl extends _StringsDownloadsEn {
	_StringsDownloadsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get deleteAll => 'Alles verwijderen';
	@override String get deleteAllTitle => 'Alle downloads verwijderen?';
	@override String deleteAllMessage({required Object count, required Object size}) => 'Dit verwijdert alle ${count} downloads en maakt ${size} opslagruimte vrij.';
	@override String storageUsed({required Object size}) => 'Opslag gebruikt: ${size}';
	@override String downloading({required Object count}) => 'Downloaden (${count})';
	@override String downloaded({required Object count}) => 'Gedownload (${count})';
	@override String get noDownloads => 'Geen downloads';
	@override String get noDownloadsHint => 'Download films en series om offline te bekijken';
	@override String get deleteDownloadTitle => 'Download verwijderen?';
	@override String deleteDownloadMessage({required Object title}) => '"${title}" verwijderen?';
	@override String get delete => 'Verwijderen';
	@override String get cancel => 'Annuleren';
	@override String get downloadFailed => 'Download mislukt';
	@override String get paused => 'Gepauzeerd';
}

// Path: libraries.tabs
class _StringsLibrariesTabsNl extends _StringsLibrariesTabsEn {
	_StringsLibrariesTabsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Aanbevolen';
	@override String get browse => 'Bladeren';
	@override String get collections => 'Collecties';
	@override String get playlists => 'Afspeellijsten';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsNl extends _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsNl._(_StringsNl root) : this._root = root, super._(root);

	@override final _StringsNl _root; // ignore: unused_field

	// Translations
	@override String get all => 'Alles';
	@override String get movies => 'Films';
	@override String get shows => 'Series';
	@override String get seasons => 'Seizoenen';
	@override String get episodes => 'Afleveringen';
	@override String get folders => 'Mappen';
}

// Path: <root>
class _StringsSv extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsSv.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.sv,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <sv>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _StringsSv _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppSv app = _StringsAppSv._(_root);
	@override late final _StringsAuthSv auth = _StringsAuthSv._(_root);
	@override late final _StringsCommonSv common = _StringsCommonSv._(_root);
	@override late final _StringsScreensSv screens = _StringsScreensSv._(_root);
	@override late final _StringsUpdateSv update = _StringsUpdateSv._(_root);
	@override late final _StringsSettingsSv settings = _StringsSettingsSv._(_root);
	@override late final _StringsSearchSv search = _StringsSearchSv._(_root);
	@override late final _StringsHotkeysSv hotkeys = _StringsHotkeysSv._(_root);
	@override late final _StringsPinEntrySv pinEntry = _StringsPinEntrySv._(_root);
	@override late final _StringsFileInfoSv fileInfo = _StringsFileInfoSv._(_root);
	@override late final _StringsMediaMenuSv mediaMenu = _StringsMediaMenuSv._(_root);
	@override late final _StringsAccessibilitySv accessibility = _StringsAccessibilitySv._(_root);
	@override late final _StringsTooltipsSv tooltips = _StringsTooltipsSv._(_root);
	@override late final _StringsVideoControlsSv videoControls = _StringsVideoControlsSv._(_root);
	@override late final _StringsUserStatusSv userStatus = _StringsUserStatusSv._(_root);
	@override late final _StringsMessagesSv messages = _StringsMessagesSv._(_root);
	@override late final _StringsProfileSv profile = _StringsProfileSv._(_root);
	@override late final _StringsSubtitlingStylingSv subtitlingStyling = _StringsSubtitlingStylingSv._(_root);
	@override late final _StringsDialogSv dialog = _StringsDialogSv._(_root);
	@override late final _StringsDiscoverSv discover = _StringsDiscoverSv._(_root);
	@override late final _StringsErrorsSv errors = _StringsErrorsSv._(_root);
	@override late final _StringsVoiceSv voice = _StringsVoiceSv._(_root);
	@override late final _StringsLibrariesSv libraries = _StringsLibrariesSv._(_root);
	@override late final _StringsAboutSv about = _StringsAboutSv._(_root);
	@override late final _StringsServerSelectionSv serverSelection = _StringsServerSelectionSv._(_root);
	@override late final _StringsHubDetailSv hubDetail = _StringsHubDetailSv._(_root);
	@override late final _StringsLogsSv logs = _StringsLogsSv._(_root);
	@override late final _StringsStatsSv stats = _StringsStatsSv._(_root);
	@override late final _StringsLicensesSv licenses = _StringsLicensesSv._(_root);
	@override late final _StringsNavigationSv navigation = _StringsNavigationSv._(_root);
	@override late final _StringsPlaylistsSv playlists = _StringsPlaylistsSv._(_root);
	@override late final _StringsCollectionsSv collections = _StringsCollectionsSv._(_root);
	@override late final _StringsWatchPartySv watchParty = _StringsWatchPartySv._(_root);
	@override late final _StringsCatchUpSv catchUp = _StringsCatchUpSv._(_root);
	@override late final _StringsWatchlistSv watchlist = _StringsWatchlistSv._(_root);
	@override late final _StringsLiveTVSv liveTV = _StringsLiveTVSv._(_root);
	@override late final _StringsDvrSv dvr = _StringsDvrSv._(_root);
	@override late final _StringsEpgSv epg = _StringsEpgSv._(_root);
	@override late final _StringsChannelSurfingSv channelSurfing = _StringsChannelSurfingSv._(_root);
	@override late final _StringsMultiviewSv multiview = _StringsMultiviewSv._(_root);
	@override late final _StringsPlayerSv player = _StringsPlayerSv._(_root);
	@override late final _StringsDownloadsSv downloads = _StringsDownloadsSv._(_root);
}

// Path: app
class _StringsAppSv extends _StringsAppEn {
	_StringsAppSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'OpenFlix';
	@override String get loading => 'Laddar...';
}

// Path: auth
class _StringsAuthSv extends _StringsAuthEn {
	_StringsAuthSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get signIn => 'Logga in';
	@override String get signUp => 'Registrera';
	@override String get signInWithPlex => 'Logga in på OpenFlix';
	@override String get showQRCode => 'Visa QR-kod';
	@override String get cancel => 'Avbryt';
	@override String get authenticate => 'Autentisera';
	@override String get retry => 'Försök igen';
	@override String get debugEnterToken => 'Debug: Ange Token';
	@override String get plexTokenLabel => 'Autentiseringstoken';
	@override String get plexTokenHint => 'Ange token';
	@override String get authenticationTimeout => 'Autentisering tog för lång tid. Försök igen.';
	@override String get scanQRCodeInstruction => 'Skanna denna QR-kod för att autentisera.';
	@override String get waitingForAuth => 'Väntar på autentisering...\nVänligen slutför inloggning i din webbläsare.';
	@override String get serverUrl => 'Server-URL';
	@override String get serverUrlHint => 't.ex. http://192.168.1.100:32400';
	@override String get username => 'Användarnamn';
	@override String get usernameHint => 'Ange användarnamn';
	@override String get email => 'E-post';
	@override String get emailHint => 'Ange e-postadress';
	@override String get password => 'Lösenord';
	@override String get passwordHint => 'Ange lösenord';
	@override String get confirmPassword => 'Bekräfta lösenord';
	@override String get confirmPasswordHint => 'Ange lösenord igen';
	@override String get displayName => 'Visningsnamn';
	@override String get displayNameHint => 'Valfritt visningsnamn';
	@override String get noAccount => 'Inget konto?';
	@override String get haveAccount => 'Har du redan ett konto?';
	@override String get connecting => 'Ansluter till server...';
	@override String get loggingIn => 'Loggar in...';
	@override String get registering => 'Skapar konto...';
	@override String get connectToServer => 'Anslut till Server';
	@override String get changeServer => 'Byt Server';
	@override String serverConnected({required Object serverName}) => 'Ansluten till ${serverName}';
	@override String get invalidServerUrl => 'Ange en giltig server-URL';
	@override String get serverConnectionFailed => 'Kunde inte ansluta till servern';
	@override String get passwordMismatch => 'Lösenorden matchar inte';
	@override String get usernameRequired => 'Användarnamn krävs';
	@override String get emailRequired => 'E-post krävs';
	@override String get passwordRequired => 'Lösenord krävs';
	@override String get passwordTooShort => 'Lösenordet måste vara minst 6 tecken';
	@override String get invalidEmail => 'Ange en giltig e-postadress';
	@override String get firstUserNote => 'Första användaren blir administratör';
	@override String get howConnecting => 'Hur ansluter du?';
	@override String get atHome => 'Hemma';
	@override String get atHomeDescription => 'Upptäck server automatiskt på ditt lokala nätverk';
	@override String get awayFromHome => 'Utanför hemmet';
	@override String get awayFromHomeDescription => 'Ange serveradress manuellt';
	@override String get findYourServer => 'Hitta din server';
	@override String get searching => 'Söker...';
	@override String get checkingNetwork => 'Kontrollerar nätverk...';
	@override String get serversFound => 'Servrar hittade';
	@override String get scanAgain => 'Sök igen';
	@override String get enterManually => 'Ange manuellt';
	@override String get noServersFound => 'Inga servrar hittades på ditt nätverk. Se till att din OpenFlix-server körs.';
	@override String discoveryFailed({required Object error}) => 'Sökning misslyckades: ${error}';
}

// Path: common
class _StringsCommonSv extends _StringsCommonEn {
	_StringsCommonSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Avbryt';
	@override String get save => 'Spara';
	@override String get close => 'Stäng';
	@override String get clear => 'Rensa';
	@override String get reset => 'Återställ';
	@override String get later => 'Senare';
	@override String get submit => 'Skicka';
	@override String get confirm => 'Bekräfta';
	@override String get retry => 'Försök igen';
	@override String get playNow => 'Spela nu';
	@override String get logout => 'Logga ut';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get owned => 'Egen';
	@override String get shared => 'Delad';
	@override String get current => 'NUVARANDE';
	@override String get unknown => 'Okänd';
	@override String get refresh => 'Uppdatera';
	@override String get yes => 'Ja';
	@override String get no => 'Nej';
	@override String get server => 'Server';
	@override String get delete => 'Ta bort';
	@override String get shuffle => 'Blanda';
	@override String get addTo => 'Lägg till i...';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get live => 'LIVE';
	@override String get newLabel => 'NY';
}

// Path: screens
class _StringsScreensSv extends _StringsScreensEn {
	_StringsScreensSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenser';
	@override String get selectServer => 'Välj server';
	@override String get switchProfile => 'Byt profil';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get search => 'Sök';
	@override String get logs => 'Loggar';
}

// Path: update
class _StringsUpdateSv extends _StringsUpdateEn {
	_StringsUpdateSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get available => 'Uppdatering tillgänglig';
	@override String versionAvailable({required Object version}) => 'Version ${version} är tillgänglig';
	@override String currentVersion({required Object version}) => 'Nuvarande: ${version}';
	@override String get skipVersion => 'Hoppa över denna version';
	@override String get viewRelease => 'Visa release';
	@override String get latestVersion => 'Du har den senaste versionen';
	@override String get checkFailed => 'Misslyckades att kontrollera uppdateringar';
}

// Path: settings
class _StringsSettingsSv extends _StringsSettingsEn {
	_StringsSettingsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Inställningar';
	@override String get profile => 'Profil';
	@override String get noProfileSelected => 'Ingen profil vald';
	@override String get kidsMode => 'Barnläge';
	@override String get switchProfile => 'Byt profil';
	@override String get switchProfileDescription => 'Byt till en annan profil';
	@override String get manageProfiles => 'Hantera profiler';
	@override String get manageProfilesDescription => 'Lägg till, redigera eller ta bort profiler';
	@override String get language => 'Språk';
	@override String get theme => 'Tema';
	@override String get appearance => 'Utseende';
	@override String get videoPlayback => 'Videouppspelning';
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get advanced => 'Avancerat';
	@override String get useSeasonPostersDescription => 'Visa säsongsaffisch istället för serieaffisch för avsnitt';
	@override String get showHeroSectionDescription => 'Visa utvalda innehållskarusell på startsidan';
	@override String get secondsLabel => 'Sekunder';
	@override String get minutesLabel => 'Minuter';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Ange tid (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get systemThemeDescription => 'Följ systeminställningar';
	@override String get lightTheme => 'Ljust';
	@override String get darkTheme => 'Mörkt';
	@override String get libraryDensity => 'Biblioteksdensitet';
	@override String get compact => 'Kompakt';
	@override String get compactDescription => 'Mindre kort, fler objekt synliga';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Standardstorlek';
	@override String get comfortable => 'Bekväm';
	@override String get comfortableDescription => 'Större kort, färre objekt synliga';
	@override String get viewMode => 'Visningsläge';
	@override String get gridView => 'Rutnät';
	@override String get gridViewDescription => 'Visa objekt i rutnätslayout';
	@override String get listView => 'Lista';
	@override String get listViewDescription => 'Visa objekt i listlayout';
	@override String get useSeasonPosters => 'Använd säsongsaffischer';
	@override String get showHeroSection => 'Visa hjältesektion';
	@override String get hardwareDecoding => 'Hårdvaruavkodning';
	@override String get hardwareDecodingDescription => 'Använd hårdvaruacceleration när tillgängligt';
	@override String get bufferSize => 'Bufferstorlek';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get subtitleStylingDescription => 'Anpassa undertextutseende';
	@override String get smallSkipDuration => 'Kort hoppvaraktighet';
	@override String get largeSkipDuration => 'Lång hoppvaraktighet';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekunder';
	@override String get defaultSleepTimer => 'Standard sovtimer';
	@override String minutesUnit({required Object minutes}) => '${minutes} minuter';
	@override String get rememberTrackSelections => 'Kom ihåg spårval per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Spara automatiskt ljud- och undertextspråkpreferenser när du ändrar spår under uppspelning';
	@override String get unwatchedOnly => 'Endast osedda';
	@override String get unwatchedOnlyDescription => 'Inkludera endast osedda avsnitt i blandningskön';
	@override String get shuffleOrderNavigation => 'Blandningsordning-navigation';
	@override String get shuffleOrderNavigationDescription => 'Nästa/föregående knappar följer blandad ordning';
	@override String get loopShuffleQueue => 'Loopa blandningskö';
	@override String get loopShuffleQueueDescription => 'Starta om kö när slutet nås';
	@override String get videoPlayerControls => 'Videospelar-kontroller';
	@override String get keyboardShortcuts => 'Tangentbordsgenvägar';
	@override String get keyboardShortcutsDescription => 'Anpassa tangentbordsgenvägar';
	@override String get debugLogging => 'Felsökningsloggning';
	@override String get debugLoggingDescription => 'Aktivera detaljerad loggning för felsökning';
	@override String get viewLogs => 'Visa loggar';
	@override String get viewLogsDescription => 'Visa applikationsloggar';
	@override String get clearCache => 'Rensa cache';
	@override String get clearCacheDescription => 'Detta rensar alla cachade bilder och data. Appen kan ta längre tid att ladda innehåll efter cache-rensning.';
	@override String get clearCacheSuccess => 'Cache rensad framgångsrikt';
	@override String get resetSettings => 'Återställ inställningar';
	@override String get resetSettingsDescription => 'Detta återställer alla inställningar till standardvärden. Denna åtgärd kan inte ångras.';
	@override String get resetSettingsSuccess => 'Inställningar återställda framgångsrikt';
	@override String get shortcutsReset => 'Genvägar återställda till standard';
	@override String get about => 'Om';
	@override String get aboutDescription => 'Appinformation och licenser';
	@override String get updates => 'Uppdateringar';
	@override String get updateAvailable => 'Uppdatering tillgänglig';
	@override String get checkForUpdates => 'Kontrollera uppdateringar';
	@override String get validationErrorEnterNumber => 'Vänligen ange ett giltigt nummer';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Tiden måste vara mellan ${min} och ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Genväg redan tilldelad ${action}';
	@override String shortcutUpdated({required Object action}) => 'Genväg uppdaterad för ${action}';
	@override String get autoSkip => 'Auto Hoppa Över';
	@override String get autoSkipIntro => 'Hoppa Över Intro Automatiskt';
	@override String get autoSkipIntroDescription => 'Hoppa automatiskt över intro-markörer efter några sekunder';
	@override String get autoSkipCredits => 'Hoppa Över Credits Automatiskt';
	@override String get autoSkipCreditsDescription => 'Hoppa automatiskt över credits och spela nästa avsnitt';
	@override String get autoSkipDelay => 'Fördröjning Auto Hoppa Över';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Vänta ${seconds} sekunder innan automatisk överhoppning';
	@override String get metadataSection => 'Metadata';
	@override String get tmdbApiKey => 'TMDB API-nyckel';
	@override String get tmdbApiKeyDescription => 'Konfigurera TMDB för förbättrad metadata';
	@override String get tmdbApiKeyConfigured => 'API-nyckel konfigurerad';
	@override String get tmdbApiKeyHint => 'Hämta din API-nyckel från themoviedb.org';
	@override String get tmdbApiKeyPlaceholder => 'Ange din TMDB API-nyckel';
	@override String get apiKey => 'API-nyckel';
	@override String get tmdbApiKeySaved => 'TMDB API-nyckel sparad';
	@override String get tmdbApiKeyCleared => 'TMDB API-nyckel raderad';
	@override String get parentalControls => 'Föräldrakontroll';
	@override String get enableParentalControls => 'Aktivera Föräldrakontroll';
	@override String get enableParentalControlsDescription => 'Begränsa innehåll baserat på åldersgränser';
	@override String get setPin => 'Ställ in PIN';
	@override String get setPinDescription => 'Ange en 4-siffrig PIN för att skydda inställningarna';
	@override String get confirmPin => 'Bekräfta PIN';
	@override String get confirmPinDescription => 'Ange PIN igen för att bekräfta';
	@override String get enterPin => 'Ange PIN';
	@override String get enterPinDescription => 'Ange din föräldrakontroll-PIN';
	@override String get changePin => 'Ändra PIN';
	@override String get changePinDescription => 'Ändra din föräldrakontroll-PIN';
	@override String get pinSet => 'Föräldrakontroll-PIN har ställts in';
	@override String get pinMismatch => 'PIN-koderna matchar inte. Försök igen.';
	@override String get incorrectPin => 'Felaktig PIN. Försök igen.';
	@override String get maxMovieRating => 'Maximal Filmklassificering';
	@override String get maxTvRating => 'Maximal TV-klassificering';
}

// Path: search
class _StringsSearchSv extends _StringsSearchEn {
	_StringsSearchSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Sök filmer, serier, musik...';
	@override String get tryDifferentTerm => 'Prova en annan sökterm';
	@override String get searchYourMedia => 'Sök i dina media';
	@override String get enterTitleActorOrKeyword => 'Ange en titel, skådespelare eller nyckelord';
	@override String get recentSearches => 'Senaste sökningar';
	@override String get clear => 'Rensa';
	@override String get voiceSearch => 'Röstsökning';
	@override String get listening => 'Lyssnar...';
	@override String get speakNow => 'Tala nu';
	@override String get all => 'Alla';
	@override String get movies => 'Filmer';
	@override String get tvShows => 'TV-serier';
	@override String get music => 'Musik';
}

// Path: hotkeys
class _StringsHotkeysSv extends _StringsHotkeysEn {
	_StringsHotkeysSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Sätt genväg för ${actionName}';
	@override String get clearShortcut => 'Rensa genväg';
}

// Path: pinEntry
class _StringsPinEntrySv extends _StringsPinEntryEn {
	_StringsPinEntrySv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Ange PIN';
	@override String get showPin => 'Visa PIN';
	@override String get hidePin => 'Dölj PIN';
}

// Path: fileInfo
class _StringsFileInfoSv extends _StringsFileInfoEn {
	_StringsFileInfoSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filinformation';
	@override String get video => 'Video';
	@override String get audio => 'Ljud';
	@override String get file => 'Fil';
	@override String get advanced => 'Avancerat';
	@override String get codec => 'Kodek';
	@override String get resolution => 'Upplösning';
	@override String get bitrate => 'Bithastighet';
	@override String get frameRate => 'Bildfrekvens';
	@override String get aspectRatio => 'Bildförhållande';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Bitdjup';
	@override String get colorSpace => 'Färgrymd';
	@override String get colorRange => 'Färgområde';
	@override String get colorPrimaries => 'Färggrunder';
	@override String get chromaSubsampling => 'Kroma-undersampling';
	@override String get channels => 'Kanaler';
	@override String get path => 'Sökväg';
	@override String get size => 'Storlek';
	@override String get container => 'Container';
	@override String get duration => 'Varaktighet';
	@override String get optimizedForStreaming => 'Optimerad för streaming';
	@override String get has64bitOffsets => '64-bit offset';
}

// Path: mediaMenu
class _StringsMediaMenuSv extends _StringsMediaMenuEn {
	_StringsMediaMenuSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Markera som sedd';
	@override String get markAsUnwatched => 'Markera som osedd';
	@override String get removeFromContinueWatching => 'Ta bort från Fortsätt titta';
	@override String get goToSeries => 'Gå till serie';
	@override String get goToSeason => 'Gå till säsong';
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get fileInfo => 'Filinformation';
}

// Path: accessibility
class _StringsAccessibilitySv extends _StringsAccessibilityEn {
	_StringsAccessibilitySv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV-serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'sedd';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} procent sedd';
	@override String get mediaCardUnwatched => 'osedd';
	@override String get tapToPlay => 'Tryck för att spela';
}

// Path: tooltips
class _StringsTooltipsSv extends _StringsTooltipsEn {
	_StringsTooltipsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get markAsWatched => 'Markera som sedd';
	@override String get markAsUnwatched => 'Markera som osedd';
}

// Path: videoControls
class _StringsVideoControlsSv extends _StringsVideoControlsEn {
	_StringsVideoControlsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Ljud';
	@override String get subtitlesLabel => 'Undertexter';
	@override String get resetToZero => 'Återställ till 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} spelas senare';
	@override String playsEarlier({required Object label}) => '${label} spelas tidigare';
	@override String get noOffset => 'Ingen offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Fyll skärm';
	@override String get stretch => 'Sträck';
	@override String get lockRotation => 'Lås rotation';
	@override String get unlockRotation => 'Lås upp rotation';
	@override String get lockScreen => 'Lås skärm';
	@override String get unlockScreen => 'Lås upp skärm';
	@override String get screenLockButton => 'Skärmlås';
	@override String get screenLocked => 'Skärmen låst';
	@override String get tapToUnlock => 'Tryck för att låsa upp';
	@override String get sleepTimer => 'Sovtimer';
	@override String get timerActive => 'Timer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Uppspelningen pausas om ${duration}';
	@override String get sleepTimerCompleted => 'Sovtimer slutförd - uppspelning pausad';
	@override String get playButton => 'Spela';
	@override String get pauseButton => 'Pausa';
	@override String seekBackwardButton({required Object seconds}) => 'Spola bakåt ${seconds} sekunder';
	@override String seekForwardButton({required Object seconds}) => 'Spola framåt ${seconds} sekunder';
	@override String get previousButton => 'Föregående avsnitt';
	@override String get nextButton => 'Nästa avsnitt';
	@override String get previousChapterButton => 'Föregående kapitel';
	@override String get nextChapterButton => 'Nästa kapitel';
	@override String get volumeButton => 'Volym';
	@override String get muteButton => 'Tysta';
	@override String get unmuteButton => 'Slå på ljud';
	@override String get settingsButton => 'Videoinställningar';
	@override String get audioTrackButton => 'Ljudspår';
	@override String get subtitlesButton => 'Undertexter';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionsButton => 'Videoversioner';
	@override String get aspectRatioButton => 'Bildförhållande';
	@override String get fullscreenButton => 'Aktivera helskärm';
	@override String get exitFullscreenButton => 'Avsluta helskärm';
	@override String get rotationLockButton => 'Rotationslås';
	@override String get timelineSlider => 'Videotidslinje';
	@override String get volumeSlider => 'Volymnivå';
	@override String get backButton => 'Tillbaka';
}

// Path: userStatus
class _StringsUserStatusSv extends _StringsUserStatusEn {
	_StringsUserStatusSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Begränsad';
	@override String get protected => 'Skyddad';
	@override String get current => 'NUVARANDE';
}

// Path: messages
class _StringsMessagesSv extends _StringsMessagesEn {
	_StringsMessagesSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Markerad som sedd';
	@override String get markedAsUnwatched => 'Markerad som osedd';
	@override String get removedFromContinueWatching => 'Borttagen från Fortsätt titta';
	@override String errorLoading({required Object error}) => 'Fel: ${error}';
	@override String get fileInfoNotAvailable => 'Filinformation inte tillgänglig';
	@override String errorLoadingFileInfo({required Object error}) => 'Fel vid laddning av filinformation: ${error}';
	@override String get errorLoadingSeries => 'Fel vid laddning av serie';
	@override String get errorLoadingSeason => 'Fel vid laddning av säsong';
	@override String get musicNotSupported => 'Musikuppspelning stöds inte ännu';
	@override String get logsCleared => 'Loggar rensade';
	@override String get logsCopied => 'Loggar kopierade till urklipp';
	@override String get noLogsAvailable => 'Inga loggar tillgängliga';
	@override String libraryScanning({required Object title}) => 'Skannar "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Biblioteksskanning startad för "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Misslyckades att skanna bibliotek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Uppdaterar metadata för "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadata-uppdatering startad för "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Misslyckades att uppdatera metadata: ${error}';
	@override String get noTokenFound => 'Ingen token hittad. Vänligen logga in igen.';
	@override String get logoutConfirm => 'Är du säker på att du vill logga ut?';
	@override String get noSeasonsFound => 'Inga säsonger hittades';
	@override String get noEpisodesFound => 'Inga avsnitt hittades i första säsongen';
	@override String get noEpisodesFoundGeneral => 'Inga avsnitt hittades';
	@override String get noResultsFound => 'Inga resultat hittades';
	@override String sleepTimerSet({required Object label}) => 'Sovtimer inställd för ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
	@override String get noItemsAvailable => 'Inga objekt tillgängliga';
	@override String get failedToCreatePlayQueue => 'Det gick inte att skapa uppspelningskö';
	@override String get failedToCreatePlayQueueNoItems => 'Det gick inte att skapa uppspelningskö – inga objekt';
	@override String failedPlayback({required Object action, required Object error}) => 'Kunde inte ${action}: ${error}';
}

// Path: profile
class _StringsProfileSv extends _StringsProfileEn {
	_StringsProfileSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => 'Inga användare tillgängliga';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingSv extends _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Stilalternativ';
	@override String get fontSize => 'Teckenstorlek';
	@override String get textColor => 'Textfärg';
	@override String get borderSize => 'Kantstorlek';
	@override String get borderColor => 'Kantfärg';
	@override String get backgroundOpacity => 'Bakgrundsopacitet';
	@override String get backgroundColor => 'Bakgrundsfärg';
}

// Path: dialog
class _StringsDialogSv extends _StringsDialogEn {
	_StringsDialogSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekräfta åtgärd';
	@override String get areYouSure => 'Är du säker på att du vill utföra denna åtgärd?';
	@override String get cancel => 'Avbryt';
	@override String get playNow => 'Spela nu';
}

// Path: discover
class _StringsDiscoverSv extends _StringsDiscoverEn {
	_StringsDiscoverSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Upptäck';
	@override String get switchProfile => 'Byt profil';
	@override String get switchServer => 'Byt server';
	@override String get logout => 'Logga ut';
	@override String get noContentAvailable => 'Inget innehåll tillgängligt';
	@override String get addMediaToLibraries => 'Lägg till media till dina bibliotek';
	@override String get continueWatching => 'Fortsätt titta';
	@override String get recentlyAdded => 'Nyligen tillagda';
	@override String get play => 'Spela';
	@override String get resume => 'Återuppta';
	@override String playEpisode({required Object season, required Object episode}) => 'Spela S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => 'Återuppta S${season}, E${episode}';
	@override String get pause => 'Pausa';
	@override String get overview => 'Översikt';
	@override String get cast => 'Rollbesättning';
	@override String get seasons => 'Säsonger';
	@override String get studio => 'Studio';
	@override String get rating => 'Åldersgräns';
	@override String get watched => 'Tittad';
	@override String episodeCount({required Object count}) => '${count} avsnitt';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} sedda';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min kvar';
	@override String get whatsOnNow => 'Sänds nu';
	@override String get channelGuide => 'TV-guide';
	@override String get liveNow => 'Live nu';
	@override String get topTen => 'Topp 10';
	@override String get newBadge => 'NY';
	@override String get liveBadge => 'LIVE';
	@override String get goodMorning => 'Good morning';
	@override String get goodAfternoon => 'Good afternoon';
	@override String get goodEvening => 'Good evening';
	@override String get defaultUser => 'Guest';
	@override String get yourNextWatch => 'Your Next Watch';
	@override String pickedForYou({required Object name}) => 'Picked just for you, ${name}';
	@override String get surpriseMe => 'Surprise Me';
	@override String get randomPicker => 'Random Movie Picker';
	@override String get noMoviesFound => 'No movies found in your library';
	@override String get spinning => 'Picking something great...';
	@override String get spinAgain => 'Spin Again';
	@override String get calendar => 'Calendar';
	@override String get today => 'Today';
	@override String get item => 'item';
	@override String get items => 'items';
	@override String get loadingMovies => 'Laddar dina filmer...';
	@override String get noContentOnDate => 'No content added on this date';
	@override String get noEpgData => 'Ingen programinformation';
}

// Path: errors
class _StringsErrorsSv extends _StringsErrorsEn {
	_StringsErrorsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Sökning misslyckades: ${error}';
	@override String connectionTimeout({required Object context}) => 'Anslutnings-timeout vid laddning ${context}';
	@override String get connectionFailed => 'Kan inte ansluta till Plex-server';
	@override String failedToLoad({required Object context, required Object error}) => 'Misslyckades att ladda ${context}: ${error}';
	@override String get noClientAvailable => 'Ingen klient tillgänglig';
	@override String authenticationFailed({required Object error}) => 'Autentisering misslyckades: ${error}';
	@override String get couldNotLaunchUrl => 'Kunde inte öppna autentiserings-URL';
	@override String get pleaseEnterToken => 'Vänligen ange en token';
	@override String get invalidToken => 'Ogiltig token';
	@override String failedToVerifyToken({required Object error}) => 'Misslyckades att verifiera token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
	@override String get connectionFailedGeneric => 'Anslutning misslyckades';
	@override String failedToRemove({required Object error}) => 'Misslyckades att ta bort: ${error}';
}

// Path: voice
class _StringsVoiceSv extends _StringsVoiceEn {
	_StringsVoiceSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get notAvailable => 'Röststyrning är inte tillgänglig';
	@override String commandNotRecognized({required Object command}) => 'Kommando inte igenkänt: "${command}"';
}

// Path: libraries
class _StringsLibrariesSv extends _StringsLibrariesEn {
	_StringsLibrariesSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotek';
	@override String get scanLibraryFiles => 'Skanna biblioteksfiler';
	@override String get scanLibrary => 'Skanna bibliotek';
	@override String get analyze => 'Analysera';
	@override String get analyzeLibrary => 'Analysera bibliotek';
	@override String get refreshMetadata => 'Uppdatera metadata';
	@override String get emptyTrash => 'Töm papperskorg';
	@override String emptyingTrash({required Object title}) => 'Tömmer papperskorg för "${title}"...';
	@override String trashEmptied({required Object title}) => 'Papperskorg tömd för "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Misslyckades att tömma papperskorg: ${error}';
	@override String analyzing({required Object title}) => 'Analyserar "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analys startad för "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Misslyckades att analysera bibliotek: ${error}';
	@override String get noLibrariesFound => 'Inga bibliotek hittades';
	@override String get thisLibraryIsEmpty => 'Detta bibliotek är tomt';
	@override String get all => 'Alla';
	@override String get clearAll => 'Rensa alla';
	@override String scanLibraryConfirm({required Object title}) => 'Är du säker på att du vill skanna "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Är du säker på att du vill analysera "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Är du säker på att du vill uppdatera metadata för "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Är du säker på att du vill tömma papperskorgen för "${title}"?';
	@override String get manageLibraries => 'Hantera bibliotek';
	@override String get sort => 'Sortera';
	@override String get sortBy => 'Sortera efter';
	@override String get filters => 'Filter';
	@override String loadingLibraryWithCount({required Object count}) => 'Laddar bibliotek... (${count} objekt laddade)';
	@override String get confirmActionMessage => 'Är du säker på att du vill utföra denna åtgärd?';
	@override String get showLibrary => 'Visa bibliotek';
	@override String get hideLibrary => 'Dölj bibliotek';
	@override String get libraryOptions => 'Biblioteksalternativ';
	@override String get content => 'bibliotekets innehåll';
	@override String get selectLibrary => 'Välj bibliotek';
	@override String filtersWithCount({required Object count}) => 'Filter (${count})';
	@override String get noRecommendations => 'Inga rekommendationer tillgängliga';
	@override String get noCollections => 'Inga samlingar i det här biblioteket';
	@override String get noFoldersFound => 'Inga mappar hittades';
	@override String get folders => 'mappar';
	@override late final _StringsLibrariesTabsSv tabs = _StringsLibrariesTabsSv._(_root);
	@override late final _StringsLibrariesGroupingsSv groupings = _StringsLibrariesGroupingsSv._(_root);
}

// Path: about
class _StringsAboutSv extends _StringsAboutEn {
	_StringsAboutSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Öppen källkod-licenser';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'En vacker Plex-klient för Flutter';
	@override String get viewLicensesDescription => 'Visa licenser för tredjepartsbibliotek';
}

// Path: serverSelection
class _StringsServerSelectionSv extends _StringsServerSelectionEn {
	_StringsServerSelectionSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get connectingToServer => 'Ansluter till server...';
	@override String get connectingToAllServers => 'Ansluter till alla servrar...';
	@override String get connectToAllServers => 'Anslut till alla servrar';
	@override String get allServerConnectionsFailed => 'Misslyckades att ansluta till servrar. Kontrollera ditt nätverk och försök igen.';
	@override String foundServers({required Object count}) => 'Hittade ${count} server(ar)';
	@override String get orSelectIndividually => 'Eller välj en server individuellt:';
	@override String get serverDebugCopied => 'Server-felsökningsdata kopierad till urklipp';
	@override String get copyDebugData => 'Kopiera felsökningsdata';
	@override String get noServersFound => 'Inga servrar hittades';
	@override String malformedServerData({required Object count}) => 'Hittade ${count} server(ar) med felformaterad data. Inga giltiga servrar tillgängliga.';
	@override String get incompleteServerInfo => 'Vissa servrar har ofullständig information och hoppades över. Vänligen kontrollera ditt Plex.tv-konto.';
	@override String get incompleteConnectionInfo => 'Server-anslutningsinformation är ofullständig. Försök igen.';
	@override String malformedServerInfo({required Object message}) => 'Serverinformation är felformaterad: ${message}';
	@override String get networkConnectionFailed => 'Nätverksanslutning misslyckades. Kontrollera din internetanslutning och försök igen.';
	@override String get authenticationFailed => 'Autentisering misslyckades. Logga in igen.';
	@override String get plexServiceUnavailable => 'Plex-tjänst otillgänglig. Försök igen senare.';
	@override String failedToLoadServers({required Object error}) => 'Misslyckades att ladda servrar: ${error}';
}

// Path: hubDetail
class _StringsHubDetailSv extends _StringsHubDetailEn {
	_StringsHubDetailSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Utgivningsår';
	@override String get dateAdded => 'Datum tillagd';
	@override String get rating => 'Betyg';
	@override String get noItemsFound => 'Inga objekt hittades';
}

// Path: logs
class _StringsLogsSv extends _StringsLogsEn {
	_StringsLogsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Loggar';
	@override String get clearLogs => 'Rensa loggar';
	@override String get copyLogs => 'Kopiera loggar';
	@override String get exportLogs => 'Exportera loggar';
	@override String get noLogsToShow => 'Inga loggar att visa';
	@override String get error => 'Fel:';
	@override String get stackTrace => 'Stack trace:';
}

// Path: stats
class _StringsStatsSv extends _StringsStatsEn {
	_StringsStatsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tittarstatistik';
	@override String get totalWatchTime => 'Total Tittartid';
	@override String get moviesWatched => 'Filmer Sedda';
	@override String get episodesWatched => 'Avsnitt Sedda';
	@override String get avgPerDay => 'Genomsnitt per Dag';
	@override String get topGenres => 'Favoritgenrer';
	@override String get monthlyActivity => 'Månadsaktivitet';
	@override String get noData => 'Ingen tittarhistorik ännu';
	@override String get startWatching => 'Börja titta för att se din statistik';
	@override String get days => 'dagar';
}

// Path: licenses
class _StringsLicensesSv extends _StringsLicensesEn {
	_StringsLicensesSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Relaterade paket';
	@override String get license => 'Licens';
	@override String licenseNumber({required Object number}) => 'Licens ${number}';
	@override String licensesCount({required Object count}) => '${count} licenser';
}

// Path: navigation
class _StringsNavigationSv extends _StringsNavigationEn {
	_StringsNavigationSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get home => 'Hem';
	@override String get search => 'Sök';
	@override String get libraries => 'Bibliotek';
	@override String get livetv => 'Live TV';
	@override String get settings => 'Inställningar';
}

// Path: playlists
class _StringsPlaylistsSv extends _StringsPlaylistsEn {
	_StringsPlaylistsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Spellistor';
	@override String get noPlaylists => 'Inga spellistor hittades';
	@override String get create => 'Skapa spellista';
	@override String get newPlaylist => 'Ny spellista';
	@override String get playlistName => 'Spellistans namn';
	@override String get enterPlaylistName => 'Ange spellistans namn';
	@override String get edit => 'Redigera spellista';
	@override String get delete => 'Ta bort spellista';
	@override String get addTo => 'Lägg till i spellista';
	@override String get addItems => 'Lägg till objekt';
	@override String get removeItem => 'Ta bort från spellista';
	@override String get clearPlaylist => 'Rensa spellista';
	@override String get playAll => 'Spela alla';
	@override String get shuffle => 'Blanda';
	@override String get smartPlaylist => 'Smart spellista';
	@override String get regularPlaylist => 'Vanlig spellista';
	@override String itemCount({required Object count}) => '${count} objekt';
	@override String get oneItem => '1 objekt';
	@override String get emptyPlaylist => 'Denna spellista är tom';
	@override String get deleteConfirm => 'Ta bort spellista?';
	@override String deleteMessage({required Object name}) => 'Är du säker på att du vill ta bort "${name}"?';
	@override String get created => 'Spellista skapad';
	@override String get updated => 'Spellista uppdaterad';
	@override String get deleted => 'Spellista borttagen';
	@override String get itemAdded => 'Tillagd i spellista';
	@override String get itemRemoved => 'Borttagen från spellista';
	@override String get selectPlaylist => 'Välj spellista';
	@override String get createNewPlaylist => 'Skapa ny spellista';
	@override String get errorCreating => 'Det gick inte att skapa spellista';
	@override String get errorDeleting => 'Det gick inte att ta bort spellista';
	@override String get errorLoading => 'Det gick inte att ladda spellistor';
	@override String get errorAdding => 'Det gick inte att lägga till i spellista';
	@override String get errorReordering => 'Det gick inte att omordna spellisteobjekt';
	@override String get errorRemoving => 'Det gick inte att ta bort från spellista';
	@override String get playlist => 'Spellista';
}

// Path: collections
class _StringsCollectionsSv extends _StringsCollectionsEn {
	_StringsCollectionsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Samlingar';
	@override String get collection => 'Samling';
	@override String get empty => 'Samlingen är tom';
	@override String get noItems => 'Inga objekt i den här samlingen';
	@override String get unknownLibrarySection => 'Kan inte ta bort: okänd bibliotekssektion';
	@override String get deleteCollection => 'Ta bort samling';
	@override String deleteConfirm({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Detta går inte att ångra.';
	@override String get deleted => 'Samling borttagen';
	@override String get deleteFailed => 'Det gick inte att ta bort samlingen';
	@override String deleteFailedWithError({required Object error}) => 'Det gick inte att ta bort samlingen: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Det gick inte att läsa in samlingsobjekt: ${error}';
	@override String get addTo => 'Lägg till i samling';
	@override String get selectCollection => 'Välj samling';
	@override String get createNewCollection => 'Skapa ny samling';
	@override String get collectionName => 'Samlingsnamn';
	@override String get enterCollectionName => 'Ange samlingsnamn';
	@override String get addedToCollection => 'Tillagd i samling';
	@override String get errorAddingToCollection => 'Fel vid tillägg i samling';
	@override String get created => 'Samling skapad';
	@override String get removeFromCollection => 'Ta bort från samling';
	@override String removeFromCollectionConfirm({required Object title}) => 'Ta bort "${title}" från denna samling?';
	@override String get removedFromCollection => 'Borttagen från samling';
	@override String get removeFromCollectionFailed => 'Misslyckades med att ta bort från samling';
	@override String removeFromCollectionError({required Object error}) => 'Fel vid borttagning från samling: ${error}';
}

// Path: watchParty
class _StringsWatchPartySv extends _StringsWatchPartyEn {
	_StringsWatchPartySv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Watch Party';
	@override String get startParty => 'Starta Watch Party';
	@override String get joinParty => 'Gå med i Party';
	@override String get enterCode => 'Ange party-kod';
	@override String get shareCode => 'Dela denna kod';
	@override String get friendsCanJoin => 'Vänner kan gå med med denna kod';
	@override String get participants => 'Deltagare';
	@override String get host => 'Värd';
	@override String get endParty => 'Avsluta Party';
	@override String get leaveParty => 'Lämna Party';
	@override String get partyEnded => 'Watch Party avslutad';
	@override String get chat => 'Chatt';
	@override String get typeMessage => 'Skriv ett meddelande...';
	@override String joined({required Object name}) => '${name} gick med';
	@override String left({required Object name}) => '${name} lämnade';
	@override String get syncedPlayback => 'Uppspelning är synkroniserad med party';
	@override String get hostControls => 'Endast värden kan styra uppspelningen';
	@override String get creating => 'Skapar party...';
	@override String get joining => 'Går med i party...';
	@override String get createFailed => 'Misslyckades att skapa party';
	@override String get joinFailed => 'Misslyckades att gå med i party';
	@override String get invalidCode => 'Ogiltig party-kod';
	@override String get gotIt => 'Uppfattat';
}

// Path: catchUp
class _StringsCatchUpSv extends _StringsCatchUpEn {
	_StringsCatchUpSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Catch Up TV';
	@override String get startOver => 'Börja om';
	@override String get startOverDescription => 'Se från början';
	@override String get watchFromBeginning => 'Se från början?';
	@override String alreadyStarted({required Object title}) => '"${title}" har redan börjat. Du kan se från början.';
	@override String get watchLive => 'Se Live';
	@override String get programsAvailable => 'Tillgängliga program';
	@override String get noProgramsAvailable => 'Inga catch-up program tillgängliga';
	@override String get programsWillAppear => 'Program visas här efterhand som de sänds';
	@override String get unavailable => 'Inte tillgänglig';
	@override String get bufferNotReady => 'Buffer inte redo än';
	@override String get rewind => 'Spola tillbaka';
	@override String get timeshiftEnabled => 'Time-shift aktiverad';
	@override String goBackTo({required Object time}) => 'Gå tillbaka till ${time}';
}

// Path: watchlist
class _StringsWatchlistSv extends _StringsWatchlistEn {
	_StringsWatchlistSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Min bevakningslista';
	@override String get all => 'Alla';
	@override String get movies => 'Filmer';
	@override String get shows => 'TV-serier';
	@override String get episodes => 'Avsnitt';
	@override String get empty => 'Din bevakningslista är tom';
	@override String get emptyHint => 'Lägg till filmer och serier till din bevakningslista';
	@override String get noItemsFiltered => 'Inga objekt matchar detta filter';
	@override String get removeTitle => 'Ta bort från bevakningslista';
	@override String removeConfirm({required Object title}) => 'Ta bort "${title}" från din bevakningslista?';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get clearAllTitle => 'Rensa bevakningslista';
	@override String clearAllConfirm({required Object count}) => 'Ta bort alla ${count} objekt från din bevakningslista?';
	@override String get clearAll => 'Rensa allt';
	@override String get addedToday => 'Tillagd idag';
	@override String get addedYesterday => 'Tillagd igår';
	@override String addedDaysAgo({required Object days}) => 'Tillagd för ${days} dagar sedan';
	@override String addedOn({required Object date}) => 'Tillagd den ${date}';
	@override String get addToWatchlist => 'Lägg till i bevakningslista';
	@override String get removeFromWatchlist => 'Ta bort från bevakningslista';
	@override String get addedToWatchlist => 'Tillagd i bevakningslista';
	@override String get removedFromWatchlist => 'Borttagen från bevakningslista';
}

// Path: liveTV
class _StringsLiveTVSv extends _StringsLiveTVEn {
	_StringsLiveTVSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live TV';
	@override String get guide => 'Guide';
	@override String get dvr => 'DVR';
	@override String get multiview => 'Multivy';
	@override String get allChannels => 'Alla kanaler';
	@override String get favorites => 'Favoriter';
	@override String get noChannels => 'Inga kanaler tillgängliga';
	@override String get addM3USource => 'Lägg till en M3U-källa i serverinställningarna';
	@override String get recording => 'Spelar in';
	@override String get recordingNow => 'Spelar in nu';
	@override String get upNext => 'Nästa';
	@override String get noProgram => 'Ingen programinfo';
	@override String get filterByGroup => 'Filtrera efter grupp';
	@override String get refresh => 'Uppdatera';
	@override String channelCount({required Object count}) => '${count} kanaler';
	@override String get nowPlaying => 'Sänds nu';
	@override String get scheduleRecording => 'Schemalägg inspelning';
	@override String get onNow => 'Sänds nu';
	@override String endsAt({required Object time}) => 'Slutar ${time}';
	@override String startsAt({required Object time}) => 'Börjar ${time}';
	@override String playbackError({required Object error}) => 'Uppspelningsfel: ${error}';
	@override String get noPreviousChannel => 'Ingen föregående kanal';
	@override String switchedTo({required Object channel}) => 'Bytte till: ${channel}';
	@override String get startingFromBeginning => 'Startar program från början...';
	@override String failedToStartOver({required Object error}) => 'Kunde inte starta om: ${error}';
	@override String playingProgram({required Object title}) => 'Spelar: ${title}';
	@override String failedToPlayProgram({required Object error}) => 'Kunde inte spela program: ${error}';
	@override String get addedToFavorites => 'Tillagd i favoriter';
	@override String get removedFromFavorites => 'Borttagen från favoriter';
	@override String failedToUpdateFavorite({required Object error}) => 'Kunde inte uppdatera favorit: ${error}';
	@override String get pipNotSupported => 'Bild-i-bild stöds inte på denna plattform';
	@override String get enteredPipMode => 'Bild-i-bild-läge aktiverat';
	@override String get exitedPipMode => 'Bild-i-bild-läge avslutat';
	@override String aspectRatioChanged({required Object mode}) => 'Bildförhållande: ${mode}';
	@override String get tune => 'Ställ in';
	@override String get retry => 'Försök igen';
	@override String get noChannelsMatchFilter => 'Inga kanaler matchar filtret';
	@override String get skipCommercial => 'Hoppa över reklam';
}

// Path: dvr
class _StringsDvrSv extends _StringsDvrEn {
	_StringsDvrSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'DVR';
	@override String get recordings => 'Inspelningar';
	@override String get seriesRules => 'Serieregler';
	@override String get noRecordings => 'Inga inspelningar';
	@override String get noRules => 'Inga serieregler';
	@override String get scheduleFromGuide => 'Schemalägg inspelningar från Live TV-guiden';
	@override String get createRulesHint => 'Skapa regler för att spela in serier automatiskt';
	@override String get storage => 'Lagring';
	@override String recordingsCount({required Object count}) => '${count} inspelningar';
	@override String get all => 'Alla';
	@override String get scheduled => 'Schemalagda';
	@override String get completed => 'Slutförda';
	@override String get failed => 'Misslyckade';
	@override String get deleteRecording => 'Ta bort inspelning?';
	@override String get deleteRule => 'Ta bort serieregel?';
	@override String get sortByDate => 'Datum';
	@override String get sortByTitle => 'Titel';
	@override String get sortBySize => 'Storlek';
	@override String get playRecording => 'Spela inspelning';
	@override String keepPolicy({required Object count}) => 'Behåll ${count} avsnitt';
	@override String get keepAll => 'Behåll alla';
	@override String get recordingScheduled => 'Inspelning schemalagd';
	@override String get scheduleRecordingTitle => 'Schemalägg inspelning';
	@override String get schedule => 'Schemalägg';
	@override String get cancel => 'Avbryt';
}

// Path: epg
class _StringsEpgSv extends _StringsEpgEn {
	_StringsEpgSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV-guide';
	@override String get now => 'Nu';
	@override String get today => 'Idag';
	@override String get tomorrow => 'Imorgon';
	@override String get noPrograms => 'Ingen programinformation tillgänglig';
	@override String get loading => 'Laddar guide...';
	@override String get record => 'Spela in';
	@override String get reminder => 'Ställ in påminnelse';
	@override String get moreInfo => 'Mer info';
	@override String get toggleView => 'Byt vy';
	@override String get gridView => 'Rutnätsvy';
	@override String get nowNextView => 'Nu/Nästa vy';
}

// Path: channelSurfing
class _StringsChannelSurfingSv extends _StringsChannelSurfingEn {
	_StringsChannelSurfingSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Slumpmässig visning';
	@override String get kidsMode => 'Barnläge';
	@override String get loading => 'Laddar slumpmässig visning...';
	@override String get failedToLoad => 'Kunde inte ladda innehåll';
	@override String get retry => 'Försök igen';
	@override String get noContent => 'Inget innehåll tillgängligt';
	@override String itemsAvailable({required Object count}) => '${count} objekt tillgängliga';
	@override String get startSurfing => 'Starta';
	@override String get pressBackToExit => 'Tryck bakåt för att avsluta';
	@override String get description => 'Se slumpmässiga filmer och serier kontinuerligt';
	@override String get noServers => 'Inga servrar tillgängliga';
}

// Path: multiview
class _StringsMultiviewSv extends _StringsMultiviewEn {
	_StringsMultiviewSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Multi-Vy';
	@override String get changeLayout => 'Ändra layout (L)';
	@override String get addChannel => 'Lägg till kanal (A)';
	@override String get removeChannel => 'Ta bort kanal (R)';
	@override String get swapChannel => 'Byt kanal';
	@override String get toggleMute => 'Ljud av/på (M)';
	@override String get selectChannel => 'Välj kanal';
	@override String get searchChannels => 'Sök kanaler...';
	@override String get cancel => 'Avbryt';
	@override String channelNumber({required Object number}) => 'K. ${number}';
}

// Path: player
class _StringsPlayerSv extends _StringsPlayerEn {
	_StringsPlayerSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get playbackError => 'Uppspelningsfel';
	@override String get error => 'Fel';
	@override String failedToStartPlayback({required Object error}) => 'Kunde inte starta uppspelning:\n${error}';
	@override String get ok => 'OK';
}

// Path: downloads
class _StringsDownloadsSv extends _StringsDownloadsEn {
	_StringsDownloadsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nedladdningar';
	@override String get deleteAll => 'Ta bort alla';
	@override String get deleteAllTitle => 'Ta bort alla nedladdningar?';
	@override String deleteAllMessage({required Object count, required Object size}) => 'Detta tar bort alla ${count} nedladdningar och frigör ${size} lagringsutrymme.';
	@override String storageUsed({required Object size}) => 'Lagring använd: ${size}';
	@override String downloading({required Object count}) => 'Laddar ner (${count})';
	@override String downloaded({required Object count}) => 'Nedladdat (${count})';
	@override String get noDownloads => 'Inga nedladdningar';
	@override String get noDownloadsHint => 'Ladda ner filmer och serier för att se offline';
	@override String get deleteDownloadTitle => 'Ta bort nedladdning?';
	@override String deleteDownloadMessage({required Object title}) => 'Ta bort "${title}"?';
	@override String get delete => 'Ta bort';
	@override String get cancel => 'Avbryt';
	@override String get downloadFailed => 'Nedladdning misslyckades';
	@override String get paused => 'Pausad';
}

// Path: libraries.tabs
class _StringsLibrariesTabsSv extends _StringsLibrariesTabsEn {
	_StringsLibrariesTabsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Rekommenderat';
	@override String get browse => 'Bläddra';
	@override String get collections => 'Samlingar';
	@override String get playlists => 'Spellistor';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsSv extends _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsSv._(_StringsSv root) : this._root = root, super._(root);

	@override final _StringsSv _root; // ignore: unused_field

	// Translations
	@override String get all => 'Alla';
	@override String get movies => 'Filmer';
	@override String get shows => 'Serier';
	@override String get seasons => 'Säsonger';
	@override String get episodes => 'Avsnitt';
	@override String get folders => 'Mappar';
}

// Path: <root>
class _StringsZh extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsZh.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _StringsZh _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppZh app = _StringsAppZh._(_root);
	@override late final _StringsAuthZh auth = _StringsAuthZh._(_root);
	@override late final _StringsCommonZh common = _StringsCommonZh._(_root);
	@override late final _StringsScreensZh screens = _StringsScreensZh._(_root);
	@override late final _StringsUpdateZh update = _StringsUpdateZh._(_root);
	@override late final _StringsSettingsZh settings = _StringsSettingsZh._(_root);
	@override late final _StringsSearchZh search = _StringsSearchZh._(_root);
	@override late final _StringsHotkeysZh hotkeys = _StringsHotkeysZh._(_root);
	@override late final _StringsPinEntryZh pinEntry = _StringsPinEntryZh._(_root);
	@override late final _StringsFileInfoZh fileInfo = _StringsFileInfoZh._(_root);
	@override late final _StringsMediaMenuZh mediaMenu = _StringsMediaMenuZh._(_root);
	@override late final _StringsAccessibilityZh accessibility = _StringsAccessibilityZh._(_root);
	@override late final _StringsTooltipsZh tooltips = _StringsTooltipsZh._(_root);
	@override late final _StringsVideoControlsZh videoControls = _StringsVideoControlsZh._(_root);
	@override late final _StringsUserStatusZh userStatus = _StringsUserStatusZh._(_root);
	@override late final _StringsMessagesZh messages = _StringsMessagesZh._(_root);
	@override late final _StringsProfileZh profile = _StringsProfileZh._(_root);
	@override late final _StringsSubtitlingStylingZh subtitlingStyling = _StringsSubtitlingStylingZh._(_root);
	@override late final _StringsDialogZh dialog = _StringsDialogZh._(_root);
	@override late final _StringsDiscoverZh discover = _StringsDiscoverZh._(_root);
	@override late final _StringsErrorsZh errors = _StringsErrorsZh._(_root);
	@override late final _StringsVoiceZh voice = _StringsVoiceZh._(_root);
	@override late final _StringsLibrariesZh libraries = _StringsLibrariesZh._(_root);
	@override late final _StringsAboutZh about = _StringsAboutZh._(_root);
	@override late final _StringsServerSelectionZh serverSelection = _StringsServerSelectionZh._(_root);
	@override late final _StringsHubDetailZh hubDetail = _StringsHubDetailZh._(_root);
	@override late final _StringsLogsZh logs = _StringsLogsZh._(_root);
	@override late final _StringsStatsZh stats = _StringsStatsZh._(_root);
	@override late final _StringsLicensesZh licenses = _StringsLicensesZh._(_root);
	@override late final _StringsNavigationZh navigation = _StringsNavigationZh._(_root);
	@override late final _StringsPlaylistsZh playlists = _StringsPlaylistsZh._(_root);
	@override late final _StringsCollectionsZh collections = _StringsCollectionsZh._(_root);
	@override late final _StringsWatchPartyZh watchParty = _StringsWatchPartyZh._(_root);
	@override late final _StringsCatchUpZh catchUp = _StringsCatchUpZh._(_root);
	@override late final _StringsWatchlistZh watchlist = _StringsWatchlistZh._(_root);
	@override late final _StringsLiveTVZh liveTV = _StringsLiveTVZh._(_root);
	@override late final _StringsDvrZh dvr = _StringsDvrZh._(_root);
	@override late final _StringsEpgZh epg = _StringsEpgZh._(_root);
	@override late final _StringsChannelSurfingZh channelSurfing = _StringsChannelSurfingZh._(_root);
	@override late final _StringsMultiviewZh multiview = _StringsMultiviewZh._(_root);
	@override late final _StringsPlayerZh player = _StringsPlayerZh._(_root);
	@override late final _StringsDownloadsZh downloads = _StringsDownloadsZh._(_root);
}

// Path: app
class _StringsAppZh extends _StringsAppEn {
	_StringsAppZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'OpenFlix';
	@override String get loading => '加载中...';
}

// Path: auth
class _StringsAuthZh extends _StringsAuthEn {
	_StringsAuthZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get signIn => '登录';
	@override String get signUp => '注册';
	@override String get signInWithPlex => '登录 OpenFlix';
	@override String get showQRCode => '显示二维码';
	@override String get cancel => '取消';
	@override String get authenticate => '验证';
	@override String get retry => '重试';
	@override String get debugEnterToken => '调试：输入令牌';
	@override String get plexTokenLabel => '授权令牌';
	@override String get plexTokenHint => '输入令牌';
	@override String get authenticationTimeout => '验证超时。请重试。';
	@override String get scanQRCodeInstruction => '扫描此二维码进行验证。';
	@override String get waitingForAuth => '等待验证中...\n请在你的浏览器中完成登录。';
	@override String get serverUrl => '服务器地址';
	@override String get serverUrlHint => '例如 http://192.168.1.100:32400';
	@override String get username => '用户名';
	@override String get usernameHint => '输入用户名';
	@override String get email => '电子邮件';
	@override String get emailHint => '输入电子邮件地址';
	@override String get password => '密码';
	@override String get passwordHint => '输入密码';
	@override String get confirmPassword => '确认密码';
	@override String get confirmPasswordHint => '再次输入密码';
	@override String get displayName => '显示名称';
	@override String get displayNameHint => '可选的显示名称';
	@override String get noAccount => '没有账号？';
	@override String get haveAccount => '已有账号？';
	@override String get connecting => '正在连接服务器...';
	@override String get loggingIn => '正在登录...';
	@override String get registering => '正在创建账号...';
	@override String get connectToServer => '连接服务器';
	@override String get changeServer => '更换服务器';
	@override String serverConnected({required Object serverName}) => '已连接到 ${serverName}';
	@override String get invalidServerUrl => '请输入有效的服务器地址';
	@override String get serverConnectionFailed => '无法连接到服务器';
	@override String get passwordMismatch => '密码不匹配';
	@override String get usernameRequired => '需要用户名';
	@override String get emailRequired => '需要电子邮件';
	@override String get passwordRequired => '需要密码';
	@override String get passwordTooShort => '密码至少需要6个字符';
	@override String get invalidEmail => '请输入有效的电子邮件地址';
	@override String get firstUserNote => '第一个用户将成为管理员';
	@override String get howConnecting => '您要如何连接？';
	@override String get atHome => '在家中';
	@override String get atHomeDescription => '在本地网络中自动检测服务器';
	@override String get awayFromHome => '在外出时';
	@override String get awayFromHomeDescription => '手动输入服务器地址';
	@override String get findYourServer => '查找您的服务器';
	@override String get searching => '搜索中...';
	@override String get checkingNetwork => '正在检查网络...';
	@override String get serversFound => '找到的服务器';
	@override String get scanAgain => '重新扫描';
	@override String get enterManually => '手动输入';
	@override String get noServersFound => '在您的网络中未找到服务器。请确保您的 OpenFlix 服务器正在运行。';
	@override String discoveryFailed({required Object error}) => '搜索失败：${error}';
}

// Path: common
class _StringsCommonZh extends _StringsCommonEn {
	_StringsCommonZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get save => '保存';
	@override String get close => '关闭';
	@override String get clear => '清除';
	@override String get reset => '重置';
	@override String get later => '稍后';
	@override String get submit => '提交';
	@override String get confirm => '确认';
	@override String get retry => '重试';
	@override String get playNow => '立即播放';
	@override String get logout => '登出';
	@override String get online => '在线';
	@override String get offline => '离线';
	@override String get owned => '拥有';
	@override String get shared => '共享';
	@override String get current => '当前';
	@override String get unknown => '未知';
	@override String get refresh => '刷新';
	@override String get yes => '是';
	@override String get no => '否';
	@override String get server => '服务器';
	@override String get delete => '删除';
	@override String get shuffle => '随机播放';
	@override String get addTo => '添加到...';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get live => '直播';
	@override String get newLabel => '新';
}

// Path: screens
class _StringsScreensZh extends _StringsScreensEn {
	_StringsScreensZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get licenses => '许可证';
	@override String get selectServer => '选择服务器';
	@override String get switchProfile => '切换配置文件';
	@override String get subtitleStyling => '字幕样式';
	@override String get search => '搜索';
	@override String get logs => '日志';
}

// Path: update
class _StringsUpdateZh extends _StringsUpdateEn {
	_StringsUpdateZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get available => '有可用更新';
	@override String versionAvailable({required Object version}) => '版本 ${version} 已发布';
	@override String currentVersion({required Object version}) => '当前版本: ${version}';
	@override String get skipVersion => '跳过此版本';
	@override String get viewRelease => '查看发布详情';
	@override String get latestVersion => '已安装的版本是可用的最新版本';
	@override String get checkFailed => '无法检查更新';
}

// Path: settings
class _StringsSettingsZh extends _StringsSettingsEn {
	_StringsSettingsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get profile => '个人资料';
	@override String get noProfileSelected => '未选择个人资料';
	@override String get kidsMode => '儿童模式';
	@override String get switchProfile => '切换个人资料';
	@override String get switchProfileDescription => '切换到其他个人资料';
	@override String get manageProfiles => '管理个人资料';
	@override String get manageProfilesDescription => '添加、编辑或删除个人资料';
	@override String get language => '语言';
	@override String get theme => '主题';
	@override String get appearance => '外观';
	@override String get videoPlayback => '视频播放';
	@override String get shufflePlay => '随机播放';
	@override String get advanced => '高级';
	@override String get useSeasonPostersDescription => '为剧集显示季海报而非剧集海报';
	@override String get showHeroSectionDescription => '在主屏幕上显示精选内容轮播区';
	@override String get secondsLabel => '秒';
	@override String get minutesLabel => '分钟';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => '输入时长 (${min}-${max})';
	@override String get systemTheme => '系统';
	@override String get systemThemeDescription => '跟随系统设置';
	@override String get lightTheme => '浅色';
	@override String get darkTheme => '深色';
	@override String get libraryDensity => '媒体库密度';
	@override String get compact => '紧凑';
	@override String get compactDescription => '卡片更小，显示更多项目';
	@override String get normal => '标准';
	@override String get normalDescription => '默认尺寸';
	@override String get comfortable => '舒适';
	@override String get comfortableDescription => '卡片更大，显示更少项目';
	@override String get viewMode => '视图模式';
	@override String get gridView => '网格视图';
	@override String get gridViewDescription => '以网格布局显示项目';
	@override String get listView => '列表视图';
	@override String get listViewDescription => '以列表布局显示项目';
	@override String get useSeasonPosters => '使用季海报';
	@override String get showHeroSection => '显示主要精选区';
	@override String get hardwareDecoding => '硬件解码';
	@override String get hardwareDecodingDescription => '如果可用，使用硬件加速';
	@override String get bufferSize => '缓冲区大小';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => '字幕样式';
	@override String get subtitleStylingDescription => '调整字幕外观';
	@override String get smallSkipDuration => '短跳过时长';
	@override String get largeSkipDuration => '长跳过时长';
	@override String secondsUnit({required Object seconds}) => '${seconds} 秒';
	@override String get defaultSleepTimer => '默认睡眠定时器';
	@override String minutesUnit({required Object minutes}) => '${minutes} 分钟';
	@override String get rememberTrackSelections => '记住每个剧集/电影的音轨选择';
	@override String get rememberTrackSelectionsDescription => '在播放过程中更改音轨时自动保存音频和字幕语言偏好';
	@override String get unwatchedOnly => '仅未观看';
	@override String get unwatchedOnlyDescription => '随机队列中仅包含未观看的剧集';
	@override String get shuffleOrderNavigation => '随机顺序导航';
	@override String get shuffleOrderNavigationDescription => '下一集/上一集按钮遵循随机播放顺序';
	@override String get loopShuffleQueue => '循环随机队列';
	@override String get loopShuffleQueueDescription => '在队列结束时重新开始';
	@override String get videoPlayerControls => '视频播放器控制';
	@override String get keyboardShortcuts => '键盘快捷键';
	@override String get keyboardShortcutsDescription => '自定义键盘快捷键';
	@override String get debugLogging => '调试日志';
	@override String get debugLoggingDescription => '启用详细日志记录以便故障排除';
	@override String get viewLogs => '查看日志';
	@override String get viewLogsDescription => '查看应用程序日志';
	@override String get clearCache => '清除缓存';
	@override String get clearCacheDescription => '这将清除所有缓存的图片和数据。清除缓存后，应用程序加载内容可能会变慢。';
	@override String get clearCacheSuccess => '缓存清除成功';
	@override String get resetSettings => '重置设置';
	@override String get resetSettingsDescription => '这会将所有设置重置为其默认值。此操作无法撤销。';
	@override String get resetSettingsSuccess => '设置重置成功';
	@override String get shortcutsReset => '快捷键已重置为默认值';
	@override String get about => '关于';
	@override String get aboutDescription => '应用程序信息和许可证';
	@override String get updates => '更新';
	@override String get updateAvailable => '有可用更新';
	@override String get checkForUpdates => '检查更新';
	@override String get validationErrorEnterNumber => '请输入一个有效的数字';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间';
	@override String shortcutAlreadyAssigned({required Object action}) => '快捷键已被分配给 ${action}';
	@override String shortcutUpdated({required Object action}) => '快捷键已为 ${action} 更新';
	@override String get autoSkip => '自动跳过';
	@override String get autoSkipIntro => '自动跳过片头';
	@override String get autoSkipIntroDescription => '几秒钟后自动跳过片头标记';
	@override String get autoSkipCredits => '自动跳过片尾';
	@override String get autoSkipCreditsDescription => '自动跳过片尾并播放下一集';
	@override String get autoSkipDelay => '自动跳过延迟';
	@override String autoSkipDelayDescription({required Object seconds}) => '自动跳过前等待 ${seconds} 秒';
	@override String get metadataSection => '元数据';
	@override String get tmdbApiKey => 'TMDB API 密钥';
	@override String get tmdbApiKeyDescription => '配置 TMDB 以获取增强元数据';
	@override String get tmdbApiKeyConfigured => 'API 密钥已配置';
	@override String get tmdbApiKeyHint => '从 themoviedb.org 获取你的 API 密钥';
	@override String get tmdbApiKeyPlaceholder => '输入你的 TMDB API 密钥';
	@override String get apiKey => 'API 密钥';
	@override String get tmdbApiKeySaved => 'TMDB API 密钥已保存';
	@override String get tmdbApiKeyCleared => 'TMDB API 密钥已清除';
	@override String get parentalControls => '家长控制';
	@override String get enableParentalControls => '启用家长控制';
	@override String get enableParentalControlsDescription => '根据年龄分级限制内容';
	@override String get setPin => '设置 PIN';
	@override String get setPinDescription => '输入 4 位 PIN 码以保护设置';
	@override String get confirmPin => '确认 PIN';
	@override String get confirmPinDescription => '再次输入 PIN 码进行确认';
	@override String get enterPin => '输入 PIN';
	@override String get enterPinDescription => '输入您的家长控制 PIN 码';
	@override String get changePin => '更改 PIN';
	@override String get changePinDescription => '更改您的家长控制 PIN 码';
	@override String get pinSet => '家长控制 PIN 码设置成功';
	@override String get pinMismatch => 'PIN 码不匹配。请重试。';
	@override String get incorrectPin => 'PIN 码错误。请重试。';
	@override String get maxMovieRating => '最大电影分级';
	@override String get maxTvRating => '最大电视分级';
}

// Path: search
class _StringsSearchZh extends _StringsSearchEn {
	_StringsSearchZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get hint => '搜索电影、剧集、音乐...';
	@override String get tryDifferentTerm => '尝试不同的搜索词';
	@override String get searchYourMedia => '搜索媒体';
	@override String get enterTitleActorOrKeyword => '输入标题、演员或关键词';
	@override String get recentSearches => '最近搜索';
	@override String get clear => '清除';
	@override String get voiceSearch => '语音搜索';
	@override String get listening => '正在听取...';
	@override String get speakNow => '请说话';
	@override String get all => '全部';
	@override String get movies => '电影';
	@override String get tvShows => '电视剧';
	@override String get music => '音乐';
}

// Path: hotkeys
class _StringsHotkeysZh extends _StringsHotkeysEn {
	_StringsHotkeysZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => '为 ${actionName} 设置快捷键';
	@override String get clearShortcut => '清除快捷键';
}

// Path: pinEntry
class _StringsPinEntryZh extends _StringsPinEntryEn {
	_StringsPinEntryZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get enterPin => '输入 PIN';
	@override String get showPin => '显示 PIN';
	@override String get hidePin => '隐藏 PIN';
}

// Path: fileInfo
class _StringsFileInfoZh extends _StringsFileInfoEn {
	_StringsFileInfoZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '文件信息';
	@override String get video => '视频';
	@override String get audio => '音频';
	@override String get file => '文件';
	@override String get advanced => '高级';
	@override String get codec => '编解码器';
	@override String get resolution => '分辨率';
	@override String get bitrate => '比特率';
	@override String get frameRate => '帧率';
	@override String get aspectRatio => '宽高比';
	@override String get profile => '配置文件';
	@override String get bitDepth => '位深度';
	@override String get colorSpace => '色彩空间';
	@override String get colorRange => '色彩范围';
	@override String get colorPrimaries => '颜色原色';
	@override String get chromaSubsampling => '色度子采样';
	@override String get channels => '声道';
	@override String get path => '路径';
	@override String get size => '大小';
	@override String get container => '容器';
	@override String get duration => '时长';
	@override String get optimizedForStreaming => '已优化用于流媒体';
	@override String get has64bitOffsets => '64位偏移量';
}

// Path: mediaMenu
class _StringsMediaMenuZh extends _StringsMediaMenuEn {
	_StringsMediaMenuZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
	@override String get removeFromContinueWatching => '从继续观看中移除';
	@override String get goToSeries => '转到系列';
	@override String get goToSeason => '转到季';
	@override String get shufflePlay => '随机播放';
	@override String get fileInfo => '文件信息';
}

// Path: accessibility
class _StringsAccessibilityZh extends _StringsAccessibilityEn {
	_StringsAccessibilityZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, 电影';
	@override String mediaCardShow({required Object title}) => '${title}, 电视剧';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => '已观看';
	@override String mediaCardPartiallyWatched({required Object percent}) => '已观看 ${percent} 百分比';
	@override String get mediaCardUnwatched => '未观看';
	@override String get tapToPlay => '点击播放';
}

// Path: tooltips
class _StringsTooltipsZh extends _StringsTooltipsEn {
	_StringsTooltipsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => '随机播放';
	@override String get markAsWatched => '标记为已观看';
	@override String get markAsUnwatched => '标记为未观看';
}

// Path: videoControls
class _StringsVideoControlsZh extends _StringsVideoControlsEn {
	_StringsVideoControlsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => '音频';
	@override String get subtitlesLabel => '字幕';
	@override String get resetToZero => '重置为 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} 播放较晚';
	@override String playsEarlier({required Object label}) => '${label} 播放较早';
	@override String get noOffset => '无偏移';
	@override String get letterbox => '信箱模式（Letterbox）';
	@override String get fillScreen => '填充屏幕';
	@override String get stretch => '拉伸';
	@override String get lockRotation => '锁定旋转';
	@override String get unlockRotation => '解锁旋转';
	@override String get lockScreen => '锁定屏幕';
	@override String get unlockScreen => '解锁屏幕';
	@override String get screenLockButton => '屏幕锁定';
	@override String get screenLocked => '屏幕已锁定';
	@override String get tapToUnlock => '点击解锁';
	@override String get sleepTimer => '睡眠定时器';
	@override String get timerActive => '定时器已激活';
	@override String playbackWillPauseIn({required Object duration}) => '播放将在 ${duration} 后暂停';
	@override String get sleepTimerCompleted => '睡眠定时器已完成 - 播放已暂停';
	@override String get playButton => '播放';
	@override String get pauseButton => '暂停';
	@override String seekBackwardButton({required Object seconds}) => '后退 ${seconds} 秒';
	@override String seekForwardButton({required Object seconds}) => '前进 ${seconds} 秒';
	@override String get previousButton => '上一集';
	@override String get nextButton => '下一集';
	@override String get previousChapterButton => '上一章节';
	@override String get nextChapterButton => '下一章节';
	@override String get volumeButton => '音量';
	@override String get muteButton => '静音';
	@override String get unmuteButton => '取消静音';
	@override String get settingsButton => '视频设置';
	@override String get audioTrackButton => '音轨';
	@override String get subtitlesButton => '字幕';
	@override String get chaptersButton => '章节';
	@override String get versionsButton => '视频版本';
	@override String get aspectRatioButton => '宽高比';
	@override String get fullscreenButton => '进入全屏';
	@override String get exitFullscreenButton => '退出全屏';
	@override String get rotationLockButton => '旋转锁定';
	@override String get timelineSlider => '视频时间轴';
	@override String get volumeSlider => '音量调节';
	@override String get backButton => '返回';
}

// Path: userStatus
class _StringsUserStatusZh extends _StringsUserStatusEn {
	_StringsUserStatusZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get admin => '管理员';
	@override String get restricted => '受限';
	@override String get protected => '受保护';
	@override String get current => '当前';
}

// Path: messages
class _StringsMessagesZh extends _StringsMessagesEn {
	_StringsMessagesZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => '已标记为已观看';
	@override String get markedAsUnwatched => '已标记为未观看';
	@override String get removedFromContinueWatching => '已从继续观看中移除';
	@override String errorLoading({required Object error}) => '错误: ${error}';
	@override String get fileInfoNotAvailable => '文件信息不可用';
	@override String errorLoadingFileInfo({required Object error}) => '加载文件信息时出错: ${error}';
	@override String get errorLoadingSeries => '加载系列时出错';
	@override String get errorLoadingSeason => '加载季时出错';
	@override String get musicNotSupported => '尚不支持播放音乐';
	@override String get logsCleared => '日志已清除';
	@override String get logsCopied => '日志已复制到剪贴板';
	@override String get noLogsAvailable => '没有可用日志';
	@override String libraryScanning({required Object title}) => '正在扫描 “${title}”...';
	@override String libraryScanStarted({required Object title}) => '已开始扫描 “${title}” 媒体库';
	@override String libraryScanFailed({required Object error}) => '无法扫描媒体库: ${error}';
	@override String metadataRefreshing({required Object title}) => '正在刷新 “${title}” 的元数据...';
	@override String metadataRefreshStarted({required Object title}) => '已开始刷新 “${title}” 的元数据';
	@override String metadataRefreshFailed({required Object error}) => '无法刷新元数据: ${error}';
	@override String get noTokenFound => '未找到令牌。请重新登录。';
	@override String get logoutConfirm => '你确定要登出吗？';
	@override String get noSeasonsFound => '未找到季';
	@override String get noEpisodesFound => '在第一季中未找到剧集';
	@override String get noEpisodesFoundGeneral => '未找到剧集';
	@override String get noResultsFound => '未找到结果';
	@override String sleepTimerSet({required Object label}) => '睡眠定时器已设置为 ${label}';
	@override String failedToSwitchProfile({required Object displayName}) => '无法切换到 ${displayName}';
	@override String get noItemsAvailable => '没有可用的项目';
	@override String get failedToCreatePlayQueue => '创建播放队列失败';
	@override String get failedToCreatePlayQueueNoItems => '创建播放队列失败 - 没有项目';
	@override String failedPlayback({required Object action, required Object error}) => '无法${action}: ${error}';
}

// Path: profile
class _StringsProfileZh extends _StringsProfileEn {
	_StringsProfileZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get noUsersAvailable => '没有可用用户';
}

// Path: subtitlingStyling
class _StringsSubtitlingStylingZh extends _StringsSubtitlingStylingEn {
	_StringsSubtitlingStylingZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => '样式选项';
	@override String get fontSize => '字号';
	@override String get textColor => '文本颜色';
	@override String get borderSize => '边框大小';
	@override String get borderColor => '边框颜色';
	@override String get backgroundOpacity => '背景不透明度';
	@override String get backgroundColor => '背景颜色';
}

// Path: dialog
class _StringsDialogZh extends _StringsDialogEn {
	_StringsDialogZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => '确认操作';
	@override String get areYouSure => '确定要执行此操作吗？';
	@override String get cancel => '取消';
	@override String get playNow => '立即播放';
}

// Path: discover
class _StringsDiscoverZh extends _StringsDiscoverEn {
	_StringsDiscoverZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '发现';
	@override String get switchProfile => '切换配置文件';
	@override String get switchServer => '切换服务器';
	@override String get logout => '登出';
	@override String get noContentAvailable => '没有可用内容';
	@override String get addMediaToLibraries => '请向你的媒体库添加一些媒体';
	@override String get continueWatching => '继续观看';
	@override String get recentlyAdded => '最近添加';
	@override String get play => '播放';
	@override String get resume => '继续';
	@override String playEpisode({required Object season, required Object episode}) => '播放 S${season}, E${episode}';
	@override String resumeEpisode({required Object season, required Object episode}) => '继续 S${season}, E${episode}';
	@override String get pause => '暂停';
	@override String get overview => '概述';
	@override String get cast => '演员表';
	@override String get seasons => '季数';
	@override String get studio => '制作公司';
	@override String get rating => '年龄分级';
	@override String get watched => '已观看';
	@override String episodeCount({required Object count}) => '${count} 集';
	@override String watchedProgress({required Object watched, required Object total}) => '已观看 ${watched}/${total} 集';
	@override String get movie => '电影';
	@override String get tvShow => '电视剧';
	@override String minutesLeft({required Object minutes}) => '剩余 ${minutes} 分钟';
	@override String get whatsOnNow => '正在播出';
	@override String get channelGuide => '节目指南';
	@override String get liveNow => '正在直播';
	@override String get topTen => '前10名';
	@override String get newBadge => '新';
	@override String get liveBadge => '直播';
	@override String get goodMorning => '早上好';
	@override String get goodAfternoon => '下午好';
	@override String get goodEvening => '晚上好';
	@override String get defaultUser => 'Guest';
	@override String get yourNextWatch => 'Your Next Watch';
	@override String pickedForYou({required Object name}) => 'Picked just for you, ${name}';
	@override String get surpriseMe => 'Surprise Me';
	@override String get randomPicker => 'Random Movie Picker';
	@override String get noMoviesFound => 'No movies found in your library';
	@override String get spinning => 'Picking something great...';
	@override String get spinAgain => 'Spin Again';
	@override String get calendar => 'Calendar';
	@override String get today => 'Today';
	@override String get item => 'item';
	@override String get items => 'items';
	@override String get loadingMovies => '正在加载你的电影...';
	@override String get noContentOnDate => 'No content added on this date';
	@override String get noEpgData => '暂无节目信息';
}

// Path: errors
class _StringsErrorsZh extends _StringsErrorsEn {
	_StringsErrorsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => '搜索失败: ${error}';
	@override String connectionTimeout({required Object context}) => '加载 ${context} 时连接超时';
	@override String get connectionFailed => '无法连接到 Plex 服务器';
	@override String failedToLoad({required Object context, required Object error}) => '无法加载 ${context}: ${error}';
	@override String get noClientAvailable => '没有可用客户端';
	@override String authenticationFailed({required Object error}) => '验证失败: ${error}';
	@override String get couldNotLaunchUrl => '无法打开授权 URL';
	@override String get pleaseEnterToken => '请输入一个令牌';
	@override String get invalidToken => '令牌无效';
	@override String failedToVerifyToken({required Object error}) => '无法验证令牌: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => '无法切换到 ${displayName}';
	@override String get connectionFailedGeneric => '连接失败';
	@override String failedToRemove({required Object error}) => '移除失败：${error}';
}

// Path: voice
class _StringsVoiceZh extends _StringsVoiceEn {
	_StringsVoiceZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get notAvailable => '语音控制不可用';
	@override String commandNotRecognized({required Object command}) => '无法识别的命令："${command}"';
}

// Path: libraries
class _StringsLibrariesZh extends _StringsLibrariesEn {
	_StringsLibrariesZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '媒体库';
	@override String get scanLibraryFiles => '扫描媒体库文件';
	@override String get scanLibrary => '扫描媒体库';
	@override String get analyze => '分析';
	@override String get analyzeLibrary => '分析媒体库';
	@override String get refreshMetadata => '刷新元数据';
	@override String get emptyTrash => '清空回收站';
	@override String emptyingTrash({required Object title}) => '正在清空 “${title}” 的回收站...';
	@override String trashEmptied({required Object title}) => '已清空 “${title}” 的回收站';
	@override String failedToEmptyTrash({required Object error}) => '无法清空回收站: ${error}';
	@override String analyzing({required Object title}) => '正在分析 “${title}”...';
	@override String analysisStarted({required Object title}) => '已开始分析 “${title}”';
	@override String failedToAnalyze({required Object error}) => '无法分析媒体库: ${error}';
	@override String get noLibrariesFound => '未找到媒体库';
	@override String get thisLibraryIsEmpty => '此媒体库为空';
	@override String get all => '全部';
	@override String get clearAll => '全部清除';
	@override String scanLibraryConfirm({required Object title}) => '确定要扫描 “${title}” 吗？';
	@override String analyzeLibraryConfirm({required Object title}) => '确定要分析 “${title}” 吗？';
	@override String refreshMetadataConfirm({required Object title}) => '确定要刷新 “${title}” 的元数据吗？';
	@override String emptyTrashConfirm({required Object title}) => '确定要清空 “${title}” 的回收站吗？';
	@override String get manageLibraries => '管理媒体库';
	@override String get sort => '排序';
	@override String get sortBy => '排序依据';
	@override String get filters => '筛选器';
	@override String loadingLibraryWithCount({required Object count}) => '正在加载媒体库... (已加载 ${count} 个项目)';
	@override String get confirmActionMessage => '确定要执行此操作吗？';
	@override String get showLibrary => '显示媒体库';
	@override String get hideLibrary => '隐藏媒体库';
	@override String get libraryOptions => '媒体库选项';
	@override String get content => '媒体库内容';
	@override String get selectLibrary => '选择媒体库';
	@override String filtersWithCount({required Object count}) => '筛选器（${count}）';
	@override String get noRecommendations => '暂无推荐';
	@override String get noCollections => '此媒体库中没有合集';
	@override String get noFoldersFound => '未找到文件夹';
	@override String get folders => '文件夹';
	@override late final _StringsLibrariesTabsZh tabs = _StringsLibrariesTabsZh._(_root);
	@override late final _StringsLibrariesGroupingsZh groupings = _StringsLibrariesGroupingsZh._(_root);
}

// Path: about
class _StringsAboutZh extends _StringsAboutEn {
	_StringsAboutZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '关于';
	@override String get openSourceLicenses => '开源许可证';
	@override String versionLabel({required Object version}) => '版本 ${version}';
	@override String get appDescription => '一款精美的 Flutter Plex 客户端';
	@override String get viewLicensesDescription => '查看第三方库的许可证';
}

// Path: serverSelection
class _StringsServerSelectionZh extends _StringsServerSelectionEn {
	_StringsServerSelectionZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get connectingToServer => '正在连接服务器...';
	@override String get connectingToAllServers => '正在连接所有服务器...';
	@override String get connectToAllServers => '连接所有服务器';
	@override String get allServerConnectionsFailed => '无法连接到任何服务器。请检查你的网络并重试。';
	@override String foundServers({required Object count}) => '找到 ${count} 个服务器';
	@override String get orSelectIndividually => '或单独选择一个服务器：';
	@override String get serverDebugCopied => '服务器调试数据已复制到剪贴板';
	@override String get copyDebugData => '复制调试数据';
	@override String get noServersFound => '未找到服务器';
	@override String malformedServerData({required Object count}) => '找到 ${count} 个数据格式错误的服务器。没有可用的有效服务器。';
	@override String get incompleteServerInfo => '某些服务器信息不完整，已被跳过。请检查你的 Plex.tv 账户。';
	@override String get incompleteConnectionInfo => '服务器连接信息不完整。请重试。';
	@override String malformedServerInfo({required Object message}) => '服务器信息格式错误: ${message}';
	@override String get networkConnectionFailed => '网络连接失败。请检查你的网络连接并重试。';
	@override String get authenticationFailed => '验证失败。请重新登录。';
	@override String get plexServiceUnavailable => 'Plex 服务不可用。请稍后重试。';
	@override String failedToLoadServers({required Object error}) => '无法加载服务器: ${error}';
}

// Path: hubDetail
class _StringsHubDetailZh extends _StringsHubDetailEn {
	_StringsHubDetailZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '标题';
	@override String get releaseYear => '发行年份';
	@override String get dateAdded => '添加日期';
	@override String get rating => '评分';
	@override String get noItemsFound => '未找到项目';
}

// Path: logs
class _StringsLogsZh extends _StringsLogsEn {
	_StringsLogsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '日志';
	@override String get clearLogs => '清除日志';
	@override String get copyLogs => '复制日志';
	@override String get exportLogs => '导出日志';
	@override String get noLogsToShow => '没有可显示的日志';
	@override String get error => '错误:';
	@override String get stackTrace => '堆栈跟踪 (Stack Trace):';
}

// Path: stats
class _StringsStatsZh extends _StringsStatsEn {
	_StringsStatsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '观看统计';
	@override String get totalWatchTime => '总观看时长';
	@override String get moviesWatched => '已观看电影';
	@override String get episodesWatched => '已观看剧集';
	@override String get avgPerDay => '每日平均';
	@override String get topGenres => '常看类型';
	@override String get monthlyActivity => '月度活动';
	@override String get noData => '暂无观看记录';
	@override String get startWatching => '开始观看以查看统计数据';
	@override String get days => '天';
}

// Path: licenses
class _StringsLicensesZh extends _StringsLicensesEn {
	_StringsLicensesZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => '相关软件包';
	@override String get license => '许可证';
	@override String licenseNumber({required Object number}) => '许可证 ${number}';
	@override String licensesCount({required Object count}) => '${count} 个许可证';
}

// Path: navigation
class _StringsNavigationZh extends _StringsNavigationEn {
	_StringsNavigationZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get home => '主页';
	@override String get search => '搜索';
	@override String get libraries => '媒体库';
	@override String get livetv => '电视直播';
	@override String get settings => '设置';
}

// Path: playlists
class _StringsPlaylistsZh extends _StringsPlaylistsEn {
	_StringsPlaylistsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '播放列表';
	@override String get noPlaylists => '未找到播放列表';
	@override String get create => '创建播放列表';
	@override String get newPlaylist => '新播放列表';
	@override String get playlistName => '播放列表名称';
	@override String get enterPlaylistName => '输入播放列表名称';
	@override String get edit => '编辑播放列表';
	@override String get delete => '删除播放列表';
	@override String get addTo => '添加到播放列表';
	@override String get addItems => '添加项目';
	@override String get removeItem => '从播放列表中移除';
	@override String get clearPlaylist => '清空播放列表';
	@override String get playAll => '全部播放';
	@override String get shuffle => '随机播放';
	@override String get smartPlaylist => '智能播放列表';
	@override String get regularPlaylist => '普通播放列表';
	@override String itemCount({required Object count}) => '${count} 个项目';
	@override String get oneItem => '1 个项目';
	@override String get emptyPlaylist => '此播放列表为空';
	@override String get deleteConfirm => '删除播放列表？';
	@override String deleteMessage({required Object name}) => '确定要删除 "${name}" 吗？';
	@override String get created => '播放列表已创建';
	@override String get updated => '播放列表已更新';
	@override String get deleted => '播放列表已删除';
	@override String get itemAdded => '已添加到播放列表';
	@override String get itemRemoved => '已从播放列表中移除';
	@override String get selectPlaylist => '选择播放列表';
	@override String get createNewPlaylist => '创建新播放列表';
	@override String get errorCreating => '创建播放列表失败';
	@override String get errorDeleting => '删除播放列表失败';
	@override String get errorLoading => '加载播放列表失败';
	@override String get errorAdding => '添加到播放列表失败';
	@override String get errorReordering => '重新排序播放列表项目失败';
	@override String get errorRemoving => '从播放列表中移除失败';
	@override String get playlist => '播放列表';
}

// Path: collections
class _StringsCollectionsZh extends _StringsCollectionsEn {
	_StringsCollectionsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '合集';
	@override String get collection => '合集';
	@override String get empty => '合集为空';
	@override String get noItems => '此合集没有项目';
	@override String get unknownLibrarySection => '无法删除：未知的媒体库分区';
	@override String get deleteCollection => '删除合集';
	@override String deleteConfirm({required Object title}) => '确定要删除"${title}"吗？此操作无法撤销。';
	@override String get deleted => '已删除合集';
	@override String get deleteFailed => '删除合集失败';
	@override String deleteFailedWithError({required Object error}) => '删除合集失败：${error}';
	@override String failedToLoadItems({required Object error}) => '加载合集项目失败：${error}';
	@override String get addTo => '添加到合集';
	@override String get selectCollection => '选择合集';
	@override String get createNewCollection => '创建新合集';
	@override String get collectionName => '合集名称';
	@override String get enterCollectionName => '输入合集名称';
	@override String get addedToCollection => '已添加到合集';
	@override String get errorAddingToCollection => '添加到合集失败';
	@override String get created => '已创建合集';
	@override String get removeFromCollection => '从合集移除';
	@override String removeFromCollectionConfirm({required Object title}) => '将“${title}”从此合集移除？';
	@override String get removedFromCollection => '已从合集移除';
	@override String get removeFromCollectionFailed => '从合集移除失败';
	@override String removeFromCollectionError({required Object error}) => '从合集移除时出错：${error}';
}

// Path: watchParty
class _StringsWatchPartyZh extends _StringsWatchPartyEn {
	_StringsWatchPartyZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Watch Party';
	@override String get startParty => '开始 Watch Party';
	@override String get joinParty => '加入 Party';
	@override String get enterCode => '输入 Party 代码';
	@override String get shareCode => '分享此代码';
	@override String get friendsCanJoin => '朋友可以使用此代码加入';
	@override String get participants => '参与者';
	@override String get host => '主持人';
	@override String get endParty => '结束 Party';
	@override String get leaveParty => '离开 Party';
	@override String get partyEnded => 'Watch Party 已结束';
	@override String get chat => '聊天';
	@override String get typeMessage => '输入消息...';
	@override String joined({required Object name}) => '${name} 已加入';
	@override String left({required Object name}) => '${name} 已离开';
	@override String get syncedPlayback => '播放已与 Party 同步';
	@override String get hostControls => '只有主持人可以控制播放';
	@override String get creating => '正在创建 Party...';
	@override String get joining => '正在加入 Party...';
	@override String get createFailed => '创建 Party 失败';
	@override String get joinFailed => '加入 Party 失败';
	@override String get invalidCode => '无效的 Party 代码';
	@override String get gotIt => '知道了';
}

// Path: catchUp
class _StringsCatchUpZh extends _StringsCatchUpEn {
	_StringsCatchUpZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '回看电视';
	@override String get startOver => '重新开始';
	@override String get startOverDescription => '从头观看';
	@override String get watchFromBeginning => '从头开始观看？';
	@override String alreadyStarted({required Object title}) => '"${title}" 已经开始。您可以从头开始观看。';
	@override String get watchLive => '观看直播';
	@override String get programsAvailable => '可用节目';
	@override String get noProgramsAvailable => '没有可用的回看节目';
	@override String get programsWillAppear => '节目将在播出后出现在这里';
	@override String get unavailable => '不可用';
	@override String get bufferNotReady => '缓冲区尚未就绪';
	@override String get rewind => '倒带';
	@override String get timeshiftEnabled => '时移已启用';
	@override String goBackTo({required Object time}) => '返回到 ${time}';
}

// Path: watchlist
class _StringsWatchlistZh extends _StringsWatchlistEn {
	_StringsWatchlistZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '我的观看列表';
	@override String get all => '全部';
	@override String get movies => '电影';
	@override String get shows => '电视剧';
	@override String get episodes => '剧集';
	@override String get empty => '您的观看列表为空';
	@override String get emptyHint => '从详情页添加电影和剧集到您的观看列表';
	@override String get noItemsFiltered => '没有符合此筛选条件的项目';
	@override String get removeTitle => '从观看列表移除';
	@override String removeConfirm({required Object title}) => '确定要将「${title}」从观看列表移除吗？';
	@override String get remove => 'Remove';
	@override String get play => 'Play';
	@override String get details => 'Details';
	@override String get seeAll => 'See All';
	@override String get clearAllTitle => '清空观看列表';
	@override String clearAllConfirm({required Object count}) => '确定要移除观看列表中的 ${count} 个项目吗？';
	@override String get clearAll => '全部清除';
	@override String get addedToday => '今天添加';
	@override String get addedYesterday => '昨天添加';
	@override String addedDaysAgo({required Object days}) => '${days} 天前添加';
	@override String addedOn({required Object date}) => '添加于 ${date}';
	@override String get addToWatchlist => '添加到观看列表';
	@override String get removeFromWatchlist => '从观看列表移除';
	@override String get addedToWatchlist => '已添加到观看列表';
	@override String get removedFromWatchlist => '已从观看列表移除';
}

// Path: liveTV
class _StringsLiveTVZh extends _StringsLiveTVEn {
	_StringsLiveTVZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '电视直播';
	@override String get guide => '节目指南';
	@override String get dvr => 'DVR';
	@override String get multiview => '多画面';
	@override String get allChannels => '所有频道';
	@override String get favorites => '收藏';
	@override String get noChannels => '没有可用频道';
	@override String get addM3USource => '在服务器设置中添加M3U源';
	@override String get recording => '录制中';
	@override String get recordingNow => '正在录制';
	@override String get upNext => '即将播出';
	@override String get noProgram => '没有节目信息';
	@override String get filterByGroup => '按组筛选';
	@override String get refresh => '刷新';
	@override String channelCount({required Object count}) => '${count} 个频道';
	@override String get nowPlaying => '正在播出';
	@override String get scheduleRecording => '预约录制';
	@override String get onNow => '正在播出';
	@override String endsAt({required Object time}) => '结束于 ${time}';
	@override String startsAt({required Object time}) => '开始于 ${time}';
	@override String playbackError({required Object error}) => '播放错误：${error}';
	@override String get noPreviousChannel => '没有上一个频道';
	@override String switchedTo({required Object channel}) => '已切换到：${channel}';
	@override String get startingFromBeginning => '正在从头开始播放节目...';
	@override String failedToStartOver({required Object error}) => '重新开始失败：${error}';
	@override String playingProgram({required Object title}) => '正在播放：${title}';
	@override String failedToPlayProgram({required Object error}) => '播放节目失败：${error}';
	@override String get addedToFavorites => '已添加到收藏';
	@override String get removedFromFavorites => '已从收藏中移除';
	@override String failedToUpdateFavorite({required Object error}) => '更新收藏失败：${error}';
	@override String get pipNotSupported => '此平台不支持画中画';
	@override String get enteredPipMode => '已进入画中画模式';
	@override String get exitedPipMode => '已退出画中画模式';
	@override String aspectRatioChanged({required Object mode}) => '画面比例：${mode}';
	@override String get tune => '调谐';
	@override String get retry => '重试';
	@override String get noChannelsMatchFilter => '没有匹配筛选条件的频道';
	@override String get skipCommercial => '跳过广告';
}

// Path: dvr
class _StringsDvrZh extends _StringsDvrEn {
	_StringsDvrZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'DVR';
	@override String get recordings => '录制内容';
	@override String get seriesRules => '系列规则';
	@override String get noRecordings => '没有录制内容';
	@override String get noRules => '没有系列规则';
	@override String get scheduleFromGuide => '从电视指南预约录制';
	@override String get createRulesHint => '创建规则自动录制系列节目';
	@override String get storage => '存储空间';
	@override String recordingsCount({required Object count}) => '${count} 个录制';
	@override String get all => '全部';
	@override String get scheduled => '已预约';
	@override String get completed => '已完成';
	@override String get failed => '失败';
	@override String get deleteRecording => '删除录制？';
	@override String get deleteRule => '删除系列规则？';
	@override String get sortByDate => '日期';
	@override String get sortByTitle => '标题';
	@override String get sortBySize => '大小';
	@override String get playRecording => '播放录制';
	@override String keepPolicy({required Object count}) => '保留 ${count} 集';
	@override String get keepAll => '全部保留';
	@override String get recordingScheduled => '录制已预约';
	@override String get scheduleRecordingTitle => '预约录制';
	@override String get schedule => '预约';
	@override String get cancel => '取消';
}

// Path: epg
class _StringsEpgZh extends _StringsEpgEn {
	_StringsEpgZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '电视节目指南';
	@override String get now => '现在';
	@override String get today => '今天';
	@override String get tomorrow => '明天';
	@override String get noPrograms => '没有可用的节目信息';
	@override String get loading => '正在加载节目指南...';
	@override String get record => '录制';
	@override String get reminder => '设置提醒';
	@override String get moreInfo => '更多信息';
	@override String get toggleView => '切换视图';
	@override String get gridView => '网格视图';
	@override String get nowNextView => '正在播出/即将播出视图';
}

// Path: channelSurfing
class _StringsChannelSurfingZh extends _StringsChannelSurfingEn {
	_StringsChannelSurfingZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '随机播放';
	@override String get kidsMode => '儿童模式';
	@override String get loading => '正在加载随机播放...';
	@override String get failedToLoad => '无法加载内容';
	@override String get retry => '重试';
	@override String get noContent => '没有可用内容';
	@override String itemsAvailable({required Object count}) => '${count} 个项目可用';
	@override String get startSurfing => '开始播放';
	@override String get pressBackToExit => '按返回键退出';
	@override String get description => '连续观看随机电影和剧集';
	@override String get noServers => '没有可用服务器';
}

// Path: multiview
class _StringsMultiviewZh extends _StringsMultiviewEn {
	_StringsMultiviewZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '多画面';
	@override String get changeLayout => '更改布局 (L)';
	@override String get addChannel => '添加频道 (A)';
	@override String get removeChannel => '移除频道 (R)';
	@override String get swapChannel => '切换频道';
	@override String get toggleMute => '静音切换 (M)';
	@override String get selectChannel => '选择频道';
	@override String get searchChannels => '搜索频道...';
	@override String get cancel => '取消';
	@override String channelNumber({required Object number}) => '频道 ${number}';
}

// Path: player
class _StringsPlayerZh extends _StringsPlayerEn {
	_StringsPlayerZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get playbackError => '播放错误';
	@override String get error => '错误';
	@override String failedToStartPlayback({required Object error}) => '无法开始播放：\n${error}';
	@override String get ok => '确定';
}

// Path: downloads
class _StringsDownloadsZh extends _StringsDownloadsEn {
	_StringsDownloadsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '下载';
	@override String get deleteAll => '删除全部';
	@override String get deleteAllTitle => '删除所有下载？';
	@override String deleteAllMessage({required Object count, required Object size}) => '这将删除所有 ${count} 个下载并释放 ${size} 存储空间。';
	@override String storageUsed({required Object size}) => '已用存储空间：${size}';
	@override String downloading({required Object count}) => '下载中 (${count})';
	@override String downloaded({required Object count}) => '已下载 (${count})';
	@override String get noDownloads => '没有下载';
	@override String get noDownloadsHint => '下载电影和剧集以便离线观看';
	@override String get deleteDownloadTitle => '删除下载？';
	@override String deleteDownloadMessage({required Object title}) => '删除「${title}」？';
	@override String get delete => '删除';
	@override String get cancel => '取消';
	@override String get downloadFailed => '下载失败';
	@override String get paused => '已暂停';
}

// Path: libraries.tabs
class _StringsLibrariesTabsZh extends _StringsLibrariesTabsEn {
	_StringsLibrariesTabsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get recommended => '推荐';
	@override String get browse => '浏览';
	@override String get collections => '合集';
	@override String get playlists => '播放列表';
}

// Path: libraries.groupings
class _StringsLibrariesGroupingsZh extends _StringsLibrariesGroupingsEn {
	_StringsLibrariesGroupingsZh._(_StringsZh root) : this._root = root, super._(root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get all => '全部';
	@override String get movies => '电影';
	@override String get shows => '剧集';
	@override String get seasons => '季';
	@override String get episodes => '集';
	@override String get folders => '文件夹';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'OpenFlix';
			case 'app.loading': return 'Loading...';
			case 'auth.signIn': return 'Sign In';
			case 'auth.signUp': return 'Sign Up';
			case 'auth.signInWithPlex': return 'Sign in to OpenFlix';
			case 'auth.showQRCode': return 'Show QR Code';
			case 'auth.cancel': return 'Cancel';
			case 'auth.authenticate': return 'Authenticate';
			case 'auth.retry': return 'Retry';
			case 'auth.debugEnterToken': return 'Debug: Enter Auth Token';
			case 'auth.plexTokenLabel': return 'Auth Token';
			case 'auth.plexTokenHint': return 'Enter your auth token';
			case 'auth.authenticationTimeout': return 'Authentication timed out. Please try again.';
			case 'auth.scanQRCodeInstruction': return 'Scan this QR code to authenticate.';
			case 'auth.waitingForAuth': return 'Waiting for authentication...\nPlease complete sign-in in your browser.';
			case 'auth.serverUrl': return 'Server URL';
			case 'auth.serverUrlHint': return 'e.g., http://192.168.1.100:32400';
			case 'auth.username': return 'Username';
			case 'auth.usernameHint': return 'Enter your username';
			case 'auth.email': return 'Email';
			case 'auth.emailHint': return 'Enter your email';
			case 'auth.password': return 'Password';
			case 'auth.passwordHint': return 'Enter your password';
			case 'auth.confirmPassword': return 'Confirm Password';
			case 'auth.confirmPasswordHint': return 'Re-enter your password';
			case 'auth.displayName': return 'Display Name';
			case 'auth.displayNameHint': return 'Optional display name';
			case 'auth.noAccount': return 'Don\'t have an account?';
			case 'auth.haveAccount': return 'Already have an account?';
			case 'auth.connecting': return 'Connecting to server...';
			case 'auth.loggingIn': return 'Signing in...';
			case 'auth.registering': return 'Creating account...';
			case 'auth.connectToServer': return 'Connect to Server';
			case 'auth.changeServer': return 'Change Server';
			case 'auth.serverConnected': return ({required Object serverName}) => 'Connected to ${serverName}';
			case 'auth.invalidServerUrl': return 'Please enter a valid server URL';
			case 'auth.serverConnectionFailed': return 'Could not connect to server';
			case 'auth.passwordMismatch': return 'Passwords do not match';
			case 'auth.usernameRequired': return 'Username is required';
			case 'auth.emailRequired': return 'Email is required';
			case 'auth.passwordRequired': return 'Password is required';
			case 'auth.passwordTooShort': return 'Password must be at least 6 characters';
			case 'auth.invalidEmail': return 'Please enter a valid email address';
			case 'auth.firstUserNote': return 'First user will be the admin';
			case 'auth.howConnecting': return 'How are you connecting?';
			case 'auth.atHome': return 'At Home';
			case 'auth.atHomeDescription': return 'Auto-detect server on your local network';
			case 'auth.awayFromHome': return 'Away from Home';
			case 'auth.awayFromHomeDescription': return 'Enter server address manually';
			case 'auth.findYourServer': return 'Find Your Server';
			case 'auth.searching': return 'Searching...';
			case 'auth.checkingNetwork': return 'Checking network...';
			case 'auth.serversFound': return 'Servers Found';
			case 'auth.scanAgain': return 'Scan Again';
			case 'auth.enterManually': return 'Enter Manually';
			case 'auth.noServersFound': return 'No servers found on your network. Make sure your OpenFlix server is running.';
			case 'auth.discoveryFailed': return ({required Object error}) => 'Discovery failed: ${error}';
			case 'common.cancel': return 'Cancel';
			case 'common.save': return 'Save';
			case 'common.close': return 'Close';
			case 'common.clear': return 'Clear';
			case 'common.reset': return 'Reset';
			case 'common.later': return 'Later';
			case 'common.submit': return 'Submit';
			case 'common.confirm': return 'Confirm';
			case 'common.retry': return 'Retry';
			case 'common.playNow': return 'Play Now';
			case 'common.logout': return 'Logout';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Owned';
			case 'common.shared': return 'Shared';
			case 'common.current': return 'CURRENT';
			case 'common.unknown': return 'Unknown';
			case 'common.refresh': return 'Refresh';
			case 'common.yes': return 'Yes';
			case 'common.no': return 'No';
			case 'common.server': return 'Server';
			case 'common.delete': return 'Delete';
			case 'common.shuffle': return 'Shuffle';
			case 'common.addTo': return 'Add to...';
			case 'common.remove': return 'Remove';
			case 'common.play': return 'Play';
			case 'common.details': return 'Details';
			case 'common.seeAll': return 'See All';
			case 'common.live': return 'LIVE';
			case 'common.newLabel': return 'NEW';
			case 'screens.licenses': return 'Licenses';
			case 'screens.switchProfile': return 'Switch Profile';
			case 'screens.subtitleStyling': return 'Subtitle Styling';
			case 'screens.search': return 'Search';
			case 'screens.logs': return 'Logs';
			case 'update.available': return 'Update Available';
			case 'update.versionAvailable': return ({required Object version}) => 'Version ${version} is available';
			case 'update.currentVersion': return ({required Object version}) => 'Current: ${version}';
			case 'update.skipVersion': return 'Skip This Version';
			case 'update.viewRelease': return 'View Release';
			case 'update.latestVersion': return 'You are on the latest version';
			case 'update.checkFailed': return 'Failed to check for updates';
			case 'settings.title': return 'Settings';
			case 'settings.profile': return 'Profile';
			case 'settings.noProfileSelected': return 'No profile selected';
			case 'settings.kidsMode': return 'Kids Mode';
			case 'settings.switchProfile': return 'Switch Profile';
			case 'settings.switchProfileDescription': return 'Change to a different profile';
			case 'settings.manageProfiles': return 'Manage Profiles';
			case 'settings.manageProfilesDescription': return 'Add, edit, or delete profiles';
			case 'settings.language': return 'Language';
			case 'settings.theme': return 'Theme';
			case 'settings.appearance': return 'Appearance';
			case 'settings.videoPlayback': return 'Video Playback';
			case 'settings.shufflePlay': return 'Shuffle Play';
			case 'settings.advanced': return 'Advanced';
			case 'settings.useSeasonPostersDescription': return 'Show season poster instead of series poster for episodes';
			case 'settings.showHeroSectionDescription': return 'Display featured content carousel on home screen';
			case 'settings.secondsLabel': return 'Seconds';
			case 'settings.minutesLabel': return 'Minutes';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Enter duration (${min}-${max})';
			case 'settings.systemTheme': return 'System';
			case 'settings.systemThemeDescription': return 'Follow system settings';
			case 'settings.lightTheme': return 'Light';
			case 'settings.darkTheme': return 'Dark';
			case 'settings.libraryDensity': return 'Library Density';
			case 'settings.compact': return 'Compact';
			case 'settings.compactDescription': return 'Smaller cards, more items visible';
			case 'settings.normal': return 'Normal';
			case 'settings.normalDescription': return 'Default size';
			case 'settings.comfortable': return 'Comfortable';
			case 'settings.comfortableDescription': return 'Larger cards, fewer items visible';
			case 'settings.viewMode': return 'View Mode';
			case 'settings.gridView': return 'Grid';
			case 'settings.gridViewDescription': return 'Display items in a grid layout';
			case 'settings.listView': return 'List';
			case 'settings.listViewDescription': return 'Display items in a list layout';
			case 'settings.useSeasonPosters': return 'Use Season Posters';
			case 'settings.showHeroSection': return 'Show Hero Section';
			case 'settings.hardwareDecoding': return 'Hardware Decoding';
			case 'settings.hardwareDecodingDescription': return 'Use hardware acceleration when available';
			case 'settings.bufferSize': return 'Buffer Size';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Subtitle Styling';
			case 'settings.subtitleStylingDescription': return 'Customize subtitle appearance';
			case 'settings.smallSkipDuration': return 'Small Skip Duration';
			case 'settings.largeSkipDuration': return 'Large Skip Duration';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} seconds';
			case 'settings.defaultSleepTimer': return 'Default Sleep Timer';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} minutes';
			case 'settings.rememberTrackSelections': return 'Remember track selections per show/movie';
			case 'settings.rememberTrackSelectionsDescription': return 'Automatically save audio and subtitle language preferences when you change tracks during playback';
			case 'settings.unwatchedOnly': return 'Unwatched Only';
			case 'settings.unwatchedOnlyDescription': return 'Only include unwatched episodes in shuffle queue';
			case 'settings.shuffleOrderNavigation': return 'Shuffle Order Navigation';
			case 'settings.shuffleOrderNavigationDescription': return 'Next/previous buttons follow shuffled order';
			case 'settings.loopShuffleQueue': return 'Loop Shuffle Queue';
			case 'settings.loopShuffleQueueDescription': return 'Restart queue when reaching the end';
			case 'settings.videoPlayerControls': return 'Video Player Controls';
			case 'settings.keyboardShortcuts': return 'Keyboard Shortcuts';
			case 'settings.keyboardShortcutsDescription': return 'Customize keyboard shortcuts';
			case 'settings.debugLogging': return 'Debug Logging';
			case 'settings.debugLoggingDescription': return 'Enable detailed logging for troubleshooting';
			case 'settings.viewLogs': return 'View Logs';
			case 'settings.viewLogsDescription': return 'View application logs';
			case 'settings.clearCache': return 'Clear Cache';
			case 'settings.clearCacheDescription': return 'This will clear all cached images and data. The app may take longer to load content after clearing the cache.';
			case 'settings.clearCacheSuccess': return 'Cache cleared successfully';
			case 'settings.resetSettings': return 'Reset Settings';
			case 'settings.resetSettingsDescription': return 'This will reset all settings to their default values. This action cannot be undone.';
			case 'settings.resetSettingsSuccess': return 'Settings reset successfully';
			case 'settings.shortcutsReset': return 'Shortcuts reset to defaults';
			case 'settings.about': return 'About';
			case 'settings.aboutDescription': return 'App information and licenses';
			case 'settings.updates': return 'Updates';
			case 'settings.updateAvailable': return 'Update Available';
			case 'settings.checkForUpdates': return 'Check for Updates';
			case 'settings.validationErrorEnterNumber': return 'Please enter a valid number';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'Duration must be between ${min} and ${max} ${unit}';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Shortcut already assigned to ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Shortcut updated for ${action}';
			case 'settings.autoSkip': return 'Auto Skip';
			case 'settings.autoSkipIntro': return 'Auto Skip Intro';
			case 'settings.autoSkipIntroDescription': return 'Automatically skip intro markers after a few seconds';
			case 'settings.autoSkipCredits': return 'Auto Skip Credits';
			case 'settings.autoSkipCreditsDescription': return 'Automatically skip credits and play next episode';
			case 'settings.autoSkipDelay': return 'Auto Skip Delay';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => 'Wait ${seconds} seconds before auto-skipping';
			case 'settings.metadataSection': return 'Metadata';
			case 'settings.tmdbApiKey': return 'TMDB API Key';
			case 'settings.tmdbApiKeyDescription': return 'Configure TMDB for enhanced metadata';
			case 'settings.tmdbApiKeyConfigured': return 'API key configured';
			case 'settings.tmdbApiKeyHint': return 'Get your API key from themoviedb.org';
			case 'settings.tmdbApiKeyPlaceholder': return 'Enter your TMDB API key';
			case 'settings.apiKey': return 'API Key';
			case 'settings.tmdbApiKeySaved': return 'TMDB API key saved';
			case 'settings.tmdbApiKeyCleared': return 'TMDB API key cleared';
			case 'settings.parentalControls': return 'Parental Controls';
			case 'settings.kidsModeDescription': return 'Show only kid-friendly content (G, PG, TV-Y7)';
			case 'settings.enableParentalControls': return 'Enable Parental Controls';
			case 'settings.enableParentalControlsDescription': return 'Restrict content based on age ratings';
			case 'settings.setPin': return 'Set PIN';
			case 'settings.setPinDescription': return 'Enter a 4-digit PIN to protect parental settings';
			case 'settings.confirmPin': return 'Confirm PIN';
			case 'settings.confirmPinDescription': return 'Enter the PIN again to confirm';
			case 'settings.enterPin': return 'Enter PIN';
			case 'settings.enterPinDescription': return 'Enter your parental control PIN';
			case 'settings.changePin': return 'Change PIN';
			case 'settings.changePinDescription': return 'Change your parental control PIN';
			case 'settings.pinSet': return 'Parental control PIN set successfully';
			case 'settings.pinMismatch': return 'PINs do not match. Please try again.';
			case 'settings.incorrectPin': return 'Incorrect PIN. Please try again.';
			case 'settings.maxMovieRating': return 'Maximum Movie Rating';
			case 'settings.maxTvRating': return 'Maximum TV Rating';
			case 'settings.remoteAccess': return 'Remote Access';
			case 'settings.tailscaleStatus': return 'Tailscale Status';
			case 'settings.remoteAccessCheckingStatus': return 'Checking status...';
			case 'settings.refreshStatus': return 'Refresh Status';
			case 'settings.remoteUrl': return 'Remote URL';
			case 'settings.copyUrl': return 'Copy URL';
			case 'settings.urlCopied': return 'URL copied to clipboard';
			case 'settings.tailscaleIp': return 'Tailscale IP';
			case 'settings.tailscaleNotInstalled': return 'Tailscale is not installed on the server.';
			case 'settings.tailscaleDescription': return 'Install Tailscale on your server to enable secure remote access from anywhere.';
			case 'settings.tailscaleNeedsLogin': return 'Login Required';
			case 'settings.tailscaleNeedsLoginDescription': return 'Tailscale requires authentication. Log in on the server.';
			case 'search.hint': return 'Search movies, shows, music...';
			case 'search.tryDifferentTerm': return 'Try a different search term';
			case 'search.searchYourMedia': return 'Search your media';
			case 'search.enterTitleActorOrKeyword': return 'Enter a title, actor, or keyword';
			case 'search.recentSearches': return 'Recent Searches';
			case 'search.clear': return 'Clear';
			case 'search.voiceSearch': return 'Voice Search';
			case 'search.listening': return 'Listening...';
			case 'search.speakNow': return 'Speak now';
			case 'search.all': return 'All';
			case 'search.movies': return 'Movies';
			case 'search.tvShows': return 'TV Shows';
			case 'search.music': return 'Music';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Set Shortcut for ${actionName}';
			case 'hotkeys.clearShortcut': return 'Clear shortcut';
			case 'pinEntry.enterPin': return 'Enter PIN';
			case 'pinEntry.showPin': return 'Show PIN';
			case 'pinEntry.hidePin': return 'Hide PIN';
			case 'fileInfo.title': return 'File Info';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Audio';
			case 'fileInfo.file': return 'File';
			case 'fileInfo.advanced': return 'Advanced';
			case 'fileInfo.codec': return 'Codec';
			case 'fileInfo.resolution': return 'Resolution';
			case 'fileInfo.bitrate': return 'Bitrate';
			case 'fileInfo.frameRate': return 'Frame Rate';
			case 'fileInfo.aspectRatio': return 'Aspect Ratio';
			case 'fileInfo.profile': return 'Profile';
			case 'fileInfo.bitDepth': return 'Bit Depth';
			case 'fileInfo.colorSpace': return 'Color Space';
			case 'fileInfo.colorRange': return 'Color Range';
			case 'fileInfo.colorPrimaries': return 'Color Primaries';
			case 'fileInfo.chromaSubsampling': return 'Chroma Subsampling';
			case 'fileInfo.channels': return 'Channels';
			case 'fileInfo.path': return 'Path';
			case 'fileInfo.size': return 'Size';
			case 'fileInfo.container': return 'Container';
			case 'fileInfo.duration': return 'Duration';
			case 'fileInfo.optimizedForStreaming': return 'Optimized for Streaming';
			case 'fileInfo.has64bitOffsets': return '64-bit Offsets';
			case 'mediaMenu.markAsWatched': return 'Mark as Watched';
			case 'mediaMenu.markAsUnwatched': return 'Mark as Unwatched';
			case 'mediaMenu.removeFromContinueWatching': return 'Remove from Continue Watching';
			case 'mediaMenu.goToSeries': return 'Go to series';
			case 'mediaMenu.goToSeason': return 'Go to season';
			case 'mediaMenu.shufflePlay': return 'Shuffle Play';
			case 'mediaMenu.fileInfo': return 'File Info';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, movie';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, TV show';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'watched';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} percent watched';
			case 'accessibility.mediaCardUnwatched': return 'unwatched';
			case 'accessibility.tapToPlay': return 'Tap to play';
			case 'tooltips.shufflePlay': return 'Shuffle play';
			case 'tooltips.markAsWatched': return 'Mark as watched';
			case 'tooltips.markAsUnwatched': return 'Mark as unwatched';
			case 'videoControls.audioLabel': return 'Audio';
			case 'videoControls.subtitlesLabel': return 'Subtitles';
			case 'videoControls.resetToZero': return 'Reset to 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} plays later';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} plays earlier';
			case 'videoControls.noOffset': return 'No offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Fill screen';
			case 'videoControls.stretch': return 'Stretch';
			case 'videoControls.lockRotation': return 'Lock rotation';
			case 'videoControls.unlockRotation': return 'Unlock rotation';
			case 'videoControls.lockScreen': return 'Lock screen';
			case 'videoControls.unlockScreen': return 'Unlock screen';
			case 'videoControls.screenLockButton': return 'Screen lock';
			case 'videoControls.screenLocked': return 'Screen locked';
			case 'videoControls.tapToUnlock': return 'Tap to unlock';
			case 'videoControls.sleepTimer': return 'Sleep Timer';
			case 'videoControls.timerActive': return 'Timer Active';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'Playback will pause in ${duration}';
			case 'videoControls.sleepTimerCompleted': return 'Sleep timer completed - playback paused';
			case 'videoControls.playButton': return 'Play';
			case 'videoControls.pauseButton': return 'Pause';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => 'Seek backward ${seconds} seconds';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => 'Seek forward ${seconds} seconds';
			case 'videoControls.previousButton': return 'Previous episode';
			case 'videoControls.nextButton': return 'Next episode';
			case 'videoControls.previousChapterButton': return 'Previous chapter';
			case 'videoControls.nextChapterButton': return 'Next chapter';
			case 'videoControls.volumeButton': return 'Volume';
			case 'videoControls.muteButton': return 'Mute';
			case 'videoControls.unmuteButton': return 'Unmute';
			case 'videoControls.settingsButton': return 'Video settings';
			case 'videoControls.audioTrackButton': return 'Audio tracks';
			case 'videoControls.subtitlesButton': return 'Subtitles';
			case 'videoControls.chaptersButton': return 'Chapters';
			case 'videoControls.versionsButton': return 'Video versions';
			case 'videoControls.aspectRatioButton': return 'Aspect ratio';
			case 'videoControls.fullscreenButton': return 'Enter fullscreen';
			case 'videoControls.exitFullscreenButton': return 'Exit fullscreen';
			case 'videoControls.rotationLockButton': return 'Rotation lock';
			case 'videoControls.timelineSlider': return 'Video timeline';
			case 'videoControls.volumeSlider': return 'Volume level';
			case 'videoControls.backButton': return 'Back';
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Restricted';
			case 'userStatus.protected': return 'Protected';
			case 'userStatus.current': return 'CURRENT';
			case 'messages.markedAsWatched': return 'Marked as watched';
			case 'messages.markedAsUnwatched': return 'Marked as unwatched';
			case 'messages.removedFromContinueWatching': return 'Removed from Continue Watching';
			case 'messages.errorLoading': return ({required Object error}) => 'Error: ${error}';
			case 'messages.fileInfoNotAvailable': return 'File information not available';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Error loading file info: ${error}';
			case 'messages.errorLoadingSeries': return 'Error loading series';
			case 'messages.errorLoadingSeason': return 'Error loading season';
			case 'messages.musicNotSupported': return 'Music playback is not yet supported';
			case 'messages.logsCleared': return 'Logs cleared';
			case 'messages.logsCopied': return 'Logs copied to clipboard';
			case 'messages.noLogsAvailable': return 'No logs available';
			case 'messages.libraryScanning': return ({required Object title}) => 'Scanning "${title}"...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Library scan started for "${title}"';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Failed to scan library: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Refreshing metadata for "${title}"...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadata refresh started for "${title}"';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Failed to refresh metadata: ${error}';
			case 'messages.noTokenFound': return 'No auth token found. Please login again.';
			case 'messages.logoutConfirm': return 'Are you sure you want to logout?';
			case 'messages.noSeasonsFound': return 'No seasons found';
			case 'messages.noEpisodesFound': return 'No episodes found in first season';
			case 'messages.noEpisodesFoundGeneral': return 'No episodes found';
			case 'messages.noResultsFound': return 'No results found';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sleep timer set for ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Failed to switch to ${displayName}';
			case 'messages.noItemsAvailable': return 'No items available';
			case 'messages.failedToCreatePlayQueue': return 'Failed to create play queue';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Failed to create play queue - no items';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Failed to ${action}: ${error}';
			case 'profile.noUsersAvailable': return 'No users available';
			case 'subtitlingStyling.stylingOptions': return 'Styling Options';
			case 'subtitlingStyling.fontSize': return 'Font Size';
			case 'subtitlingStyling.textColor': return 'Text Color';
			case 'subtitlingStyling.borderSize': return 'Border Size';
			case 'subtitlingStyling.borderColor': return 'Border Color';
			case 'subtitlingStyling.backgroundOpacity': return 'Background Opacity';
			case 'subtitlingStyling.backgroundColor': return 'Background Color';
			case 'dialog.confirmAction': return 'Confirm Action';
			case 'dialog.areYouSure': return 'Are you sure you want to perform this action?';
			case 'dialog.cancel': return 'Cancel';
			case 'dialog.playNow': return 'Play Now';
			case 'discover.title': return 'Discover';
			case 'discover.switchProfile': return 'Switch Profile';
			case 'discover.logout': return 'Logout';
			case 'discover.noContentAvailable': return 'No content available';
			case 'discover.addMediaToLibraries': return 'Add some media to your libraries';
			case 'discover.continueWatching': return 'Continue Watching';
			case 'discover.recentlyAdded': return 'Recently Added';
			case 'discover.play': return 'Play';
			case 'discover.resume': return 'Resume';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Play S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Resume S${season}, E${episode}';
			case 'discover.pause': return 'Pause';
			case 'discover.overview': return 'Overview';
			case 'discover.cast': return 'Cast';
			case 'discover.seasons': return 'Seasons';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Rating';
			case 'discover.watched': return 'Watched';
			case 'discover.episodeCount': return ({required Object count}) => '${count} episodes';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} watched';
			case 'discover.movie': return 'Movie';
			case 'discover.tvShow': return 'TV Show';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} min left';
			case 'discover.whatsOnNow': return 'What\'s On Now';
			case 'discover.channelGuide': return 'Channel Guide';
			case 'discover.liveNow': return 'Live Now';
			case 'discover.topTen': return 'Top 10';
			case 'discover.newBadge': return 'NEW';
			case 'discover.liveBadge': return 'LIVE';
			case 'discover.goodMorning': return 'Good morning';
			case 'discover.goodAfternoon': return 'Good afternoon';
			case 'discover.goodEvening': return 'Good evening';
			case 'discover.defaultUser': return 'Guest';
			case 'discover.yourNextWatch': return 'Your Next Watch';
			case 'discover.pickedForYou': return ({required Object name}) => 'Picked just for you, ${name}';
			case 'discover.surpriseMe': return 'Surprise Me';
			case 'discover.randomPicker': return 'Random Movie Picker';
			case 'discover.noMoviesFound': return 'No movies found in your library';
			case 'discover.spinning': return 'Picking something great...';
			case 'discover.spinAgain': return 'Spin Again';
			case 'discover.loadingMovies': return 'Loading your movies...';
			case 'discover.calendar': return 'Calendar';
			case 'discover.today': return 'Today';
			case 'discover.item': return 'item';
			case 'discover.items': return 'items';
			case 'discover.noContentOnDate': return 'No content added on this date';
			case 'discover.noEpgData': return 'No program info';
			case 'errors.searchFailed': return ({required Object error}) => 'Search failed: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Connection timeout while loading ${context}';
			case 'errors.connectionFailed': return 'Unable to connect to Plex server';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Failed to load ${context}: ${error}';
			case 'errors.noClientAvailable': return 'No client available';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Authentication failed: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Could not launch auth URL';
			case 'errors.pleaseEnterToken': return 'Please enter a token';
			case 'errors.invalidToken': return 'Invalid token';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Failed to verify token: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Failed to switch to ${displayName}';
			case 'errors.connectionFailedGeneric': return 'Connection failed';
			case 'errors.failedToRemove': return ({required Object error}) => 'Failed to remove: ${error}';
			case 'voice.notAvailable': return 'Voice control is not available';
			case 'voice.commandNotRecognized': return ({required Object command}) => 'Command not recognized: "${command}"';
			case 'libraries.title': return 'Libraries';
			case 'libraries.scanLibraryFiles': return 'Scan Library Files';
			case 'libraries.scanLibrary': return 'Scan Library';
			case 'libraries.analyze': return 'Analyze';
			case 'libraries.analyzeLibrary': return 'Analyze Library';
			case 'libraries.refreshMetadata': return 'Refresh Metadata';
			case 'libraries.emptyTrash': return 'Empty Trash';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Emptying trash for "${title}"...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Trash emptied for "${title}"';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Failed to empty trash: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analyzing "${title}"...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analysis started for "${title}"';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Failed to analyze library: ${error}';
			case 'libraries.noLibrariesFound': return 'No libraries found';
			case 'libraries.thisLibraryIsEmpty': return 'This library is empty';
			case 'libraries.all': return 'All';
			case 'libraries.clearAll': return 'Clear All';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => 'Are you sure you want to scan "${title}"?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => 'Are you sure you want to analyze "${title}"?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Are you sure you want to refresh metadata for "${title}"?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Are you sure you want to empty trash for "${title}"?';
			case 'libraries.manageLibraries': return 'Manage Libraries';
			case 'libraries.sort': return 'Sort';
			case 'libraries.sortBy': return 'Sort By';
			case 'libraries.filters': return 'Filters';
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Loading library... (${count} items loaded)';
			case 'libraries.confirmActionMessage': return 'Are you sure you want to perform this action?';
			case 'libraries.showLibrary': return 'Show library';
			case 'libraries.hideLibrary': return 'Hide library';
			case 'libraries.libraryOptions': return 'Library options';
			case 'libraries.content': return 'library content';
			case 'libraries.selectLibrary': return 'Select library';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filters (${count})';
			case 'libraries.noRecommendations': return 'No recommendations available';
			case 'libraries.noCollections': return 'No collections in this library';
			case 'libraries.noFoldersFound': return 'No folders found';
			case 'libraries.folders': return 'folders';
			case 'libraries.tabs.recommended': return 'Recommended';
			case 'libraries.tabs.browse': return 'Browse';
			case 'libraries.tabs.collections': return 'Collections';
			case 'libraries.tabs.playlists': return 'Playlists';
			case 'libraries.groupings.all': return 'All';
			case 'libraries.groupings.movies': return 'Movies';
			case 'libraries.groupings.shows': return 'TV Shows';
			case 'libraries.groupings.seasons': return 'Seasons';
			case 'libraries.groupings.episodes': return 'Episodes';
			case 'libraries.groupings.folders': return 'Folders';
			case 'about.title': return 'About';
			case 'about.openSourceLicenses': return 'Open Source Licenses';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'A beautiful Plex client for Flutter';
			case 'about.viewLicensesDescription': return 'View licenses of third-party libraries';
			case 'serverSelection.connectingToServer': return 'Connecting to server...';
			case 'serverSelection.connectingToAllServers': return 'Connecting to all servers...';
			case 'serverSelection.connectToAllServers': return 'Connect to All Servers';
			case 'serverSelection.allServerConnectionsFailed': return 'Failed to connect to any servers. Please check your network and try again.';
			case 'serverSelection.foundServers': return ({required Object count}) => 'Found ${count} server(s)';
			case 'serverSelection.orSelectIndividually': return 'Or select a server individually:';
			case 'serverSelection.serverDebugCopied': return 'Server debug data copied to clipboard';
			case 'serverSelection.copyDebugData': return 'Copy Debug Data';
			case 'serverSelection.noServersFound': return 'No servers found';
			case 'serverSelection.malformedServerData': return ({required Object count}) => 'Found ${count} server(s) with malformed data. No valid servers available.';
			case 'serverSelection.incompleteServerInfo': return 'Some servers have incomplete information and were skipped. Please check your Plex.tv account.';
			case 'serverSelection.incompleteConnectionInfo': return 'Server connection information is incomplete. Please try again.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Server information is malformed: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Network connection failed. Please check your internet connection and try again.';
			case 'serverSelection.authenticationFailed': return 'Authentication failed. Please sign in again.';
			case 'serverSelection.plexServiceUnavailable': return 'Plex service unavailable. Please try again later.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Failed to load servers: ${error}';
			case 'hubDetail.title': return 'Title';
			case 'hubDetail.releaseYear': return 'Release Year';
			case 'hubDetail.dateAdded': return 'Date Added';
			case 'hubDetail.rating': return 'Rating';
			case 'hubDetail.noItemsFound': return 'No items found';
			case 'logs.title': return 'Logs';
			case 'logs.clearLogs': return 'Clear Logs';
			case 'logs.copyLogs': return 'Copy Logs';
			case 'logs.exportLogs': return 'Export Logs';
			case 'logs.noLogsToShow': return 'No logs to show';
			case 'logs.error': return 'Error:';
			case 'logs.stackTrace': return 'Stack Trace:';
			case 'stats.title': return 'Watch Statistics';
			case 'stats.totalWatchTime': return 'Total Watch Time';
			case 'stats.moviesWatched': return 'Movies Watched';
			case 'stats.episodesWatched': return 'Episodes Watched';
			case 'stats.avgPerDay': return 'Avg Per Day';
			case 'stats.topGenres': return 'Top Genres';
			case 'stats.monthlyActivity': return 'Monthly Activity';
			case 'stats.noData': return 'No watch history yet';
			case 'stats.startWatching': return 'Start watching to see your stats';
			case 'stats.days': return 'days';
			case 'licenses.relatedPackages': return 'Related Packages';
			case 'licenses.license': return 'License';
			case 'licenses.licenseNumber': return ({required Object number}) => 'License ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenses';
			case 'navigation.home': return 'Home';
			case 'navigation.movies': return 'Movies';
			case 'navigation.tvShows': return 'TV Shows';
			case 'navigation.search': return 'Search';
			case 'navigation.libraries': return 'Libraries';
			case 'navigation.livetv': return 'Live TV';
			case 'navigation.settings': return 'Settings';
			case 'collections.title': return 'Collections';
			case 'collections.collection': return 'Collection';
			case 'collections.empty': return 'Collection is empty';
			case 'collections.noItems': return 'No items in this collection';
			case 'collections.unknownLibrarySection': return 'Cannot delete: Unknown library section';
			case 'collections.deleteCollection': return 'Delete Collection';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Are you sure you want to delete "${title}"? This action cannot be undone.';
			case 'collections.deleted': return 'Collection deleted';
			case 'collections.deleteFailed': return 'Failed to delete collection';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Failed to delete collection: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Failed to load collection items: ${error}';
			case 'collections.addTo': return 'Add to collection';
			case 'collections.selectCollection': return 'Select Collection';
			case 'collections.createNewCollection': return 'Create New Collection';
			case 'collections.collectionName': return 'Collection Name';
			case 'collections.enterCollectionName': return 'Enter collection name';
			case 'collections.addedToCollection': return 'Added to collection';
			case 'collections.errorAddingToCollection': return 'Failed to add to collection';
			case 'collections.created': return 'Collection created';
			case 'collections.removeFromCollection': return 'Remove from collection';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => 'Remove "${title}" from this collection?';
			case 'collections.removedFromCollection': return 'Removed from collection';
			case 'collections.removeFromCollectionFailed': return 'Failed to remove from collection';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Error removing from collection: ${error}';
			case 'playlists.title': return 'Playlists';
			case 'playlists.playlist': return 'Playlist';
			case 'playlists.noPlaylists': return 'No playlists found';
			case 'playlists.create': return 'Create Playlist';
			case 'playlists.newPlaylist': return 'New Playlist';
			case 'playlists.playlistName': return 'Playlist Name';
			case 'playlists.enterPlaylistName': return 'Enter playlist name';
			case 'playlists.edit': return 'Edit Playlist';
			case 'playlists.delete': return 'Delete Playlist';
			case 'playlists.addTo': return 'Add to Playlist';
			case 'playlists.addItems': return 'Add Items';
			case 'playlists.removeItem': return 'Remove from Playlist';
			case 'playlists.clearPlaylist': return 'Clear Playlist';
			case 'playlists.playAll': return 'Play All';
			case 'playlists.shuffle': return 'Shuffle';
			case 'playlists.smartPlaylist': return 'Smart Playlist';
			case 'playlists.regularPlaylist': return 'Regular Playlist';
			case 'playlists.itemCount': return ({required Object count}) => '${count} items';
			case 'playlists.oneItem': return '1 item';
			case 'playlists.emptyPlaylist': return 'This playlist is empty';
			case 'playlists.deleteConfirm': return 'Delete Playlist?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Are you sure you want to delete "${name}"?';
			case 'playlists.created': return 'Playlist created';
			case 'playlists.updated': return 'Playlist updated';
			case 'playlists.deleted': return 'Playlist deleted';
			case 'playlists.itemAdded': return 'Added to playlist';
			case 'playlists.itemRemoved': return 'Removed from playlist';
			case 'playlists.selectPlaylist': return 'Select Playlist';
			case 'playlists.createNewPlaylist': return 'Create New Playlist';
			case 'playlists.errorCreating': return 'Failed to create playlist';
			case 'playlists.errorDeleting': return 'Failed to delete playlist';
			case 'playlists.errorLoading': return 'Failed to load playlists';
			case 'playlists.errorAdding': return 'Failed to add to playlist';
			case 'playlists.errorReordering': return 'Failed to reorder playlist item';
			case 'playlists.errorRemoving': return 'Failed to remove from playlist';
			case 'watchParty.title': return 'Watch Party';
			case 'watchParty.startParty': return 'Start Watch Party';
			case 'watchParty.joinParty': return 'Join Party';
			case 'watchParty.enterCode': return 'Enter party code';
			case 'watchParty.shareCode': return 'Share this code';
			case 'watchParty.friendsCanJoin': return 'Friends can join using this code';
			case 'watchParty.participants': return 'Participants';
			case 'watchParty.host': return 'Host';
			case 'watchParty.endParty': return 'End Party';
			case 'watchParty.leaveParty': return 'Leave Party';
			case 'watchParty.partyEnded': return 'Watch Party ended';
			case 'watchParty.chat': return 'Chat';
			case 'watchParty.typeMessage': return 'Type a message...';
			case 'watchParty.joined': return ({required Object name}) => '${name} joined';
			case 'watchParty.left': return ({required Object name}) => '${name} left';
			case 'watchParty.syncedPlayback': return 'Playback is synced with party';
			case 'watchParty.hostControls': return 'Only the host can control playback';
			case 'watchParty.creating': return 'Creating party...';
			case 'watchParty.joining': return 'Joining party...';
			case 'watchParty.createFailed': return 'Failed to create party';
			case 'watchParty.joinFailed': return 'Failed to join party';
			case 'watchParty.invalidCode': return 'Invalid party code';
			case 'watchParty.gotIt': return 'Got it';
			case 'catchUp.title': return 'Catch Up TV';
			case 'catchUp.startOver': return 'Start Over';
			case 'catchUp.startOverDescription': return 'Watch from the beginning';
			case 'catchUp.watchFromBeginning': return 'Watch from the beginning?';
			case 'catchUp.alreadyStarted': return ({required Object title}) => '"${title}" has already started. You can start from the beginning.';
			case 'catchUp.watchLive': return 'Watch Live';
			case 'catchUp.programsAvailable': return 'Programs Available';
			case 'catchUp.noProgramsAvailable': return 'No catch-up programs available';
			case 'catchUp.programsWillAppear': return 'Programs will appear here as they air';
			case 'catchUp.unavailable': return 'Unavailable';
			case 'catchUp.bufferNotReady': return 'Buffer not ready yet';
			case 'catchUp.rewind': return 'Rewind';
			case 'catchUp.timeshiftEnabled': return 'Time-shift enabled';
			case 'catchUp.goBackTo': return ({required Object time}) => 'Go back to ${time}';
			case 'watchlist.title': return 'My Watchlist';
			case 'watchlist.all': return 'All';
			case 'watchlist.movies': return 'Movies';
			case 'watchlist.shows': return 'TV Shows';
			case 'watchlist.episodes': return 'Episodes';
			case 'watchlist.empty': return 'Your watchlist is empty';
			case 'watchlist.emptyHint': return 'Add movies and shows to your watchlist from their detail pages';
			case 'watchlist.noItemsFiltered': return 'No items match this filter';
			case 'watchlist.removeTitle': return 'Remove from Watchlist';
			case 'watchlist.removeConfirm': return ({required Object title}) => 'Remove "${title}" from your watchlist?';
			case 'watchlist.remove': return 'Remove';
			case 'watchlist.clearAllTitle': return 'Clear Watchlist';
			case 'watchlist.clearAllConfirm': return ({required Object count}) => 'Remove all ${count} items from your watchlist?';
			case 'watchlist.clearAll': return 'Clear All';
			case 'watchlist.addedToday': return 'Added today';
			case 'watchlist.addedYesterday': return 'Added yesterday';
			case 'watchlist.addedDaysAgo': return ({required Object days}) => 'Added ${days} days ago';
			case 'watchlist.addedOn': return ({required Object date}) => 'Added on ${date}';
			case 'watchlist.addToWatchlist': return 'Add to Watchlist';
			case 'watchlist.removeFromWatchlist': return 'Remove from Watchlist';
			case 'watchlist.addedToWatchlist': return 'Added to watchlist';
			case 'watchlist.removedFromWatchlist': return 'Removed from watchlist';
			case 'liveTV.title': return 'Live TV';
			case 'liveTV.guide': return 'Guide';
			case 'liveTV.dvr': return 'DVR';
			case 'liveTV.multiview': return 'Multiview';
			case 'liveTV.allChannels': return 'All Channels';
			case 'liveTV.favorites': return 'Favorites';
			case 'liveTV.noChannels': return 'No channels available';
			case 'liveTV.addM3USource': return 'Add an M3U source in server settings';
			case 'liveTV.recording': return 'Recording';
			case 'liveTV.recordingNow': return 'Recording Now';
			case 'liveTV.upNext': return 'Up Next';
			case 'liveTV.noProgram': return 'No program info';
			case 'liveTV.filterByGroup': return 'Filter by group';
			case 'liveTV.refresh': return 'Refresh';
			case 'liveTV.channelCount': return ({required Object count}) => '${count} channels';
			case 'liveTV.nowPlaying': return 'Now Playing';
			case 'liveTV.scheduleRecording': return 'Schedule Recording';
			case 'liveTV.onNow': return 'On Now';
			case 'liveTV.endsAt': return ({required Object time}) => 'Ends at ${time}';
			case 'liveTV.startsAt': return ({required Object time}) => 'Starts at ${time}';
			case 'liveTV.playbackError': return ({required Object error}) => 'Playback error: ${error}';
			case 'liveTV.noPreviousChannel': return 'No previous channel';
			case 'liveTV.switchedTo': return ({required Object channel}) => 'Switched to: ${channel}';
			case 'liveTV.startingFromBeginning': return 'Starting program from beginning...';
			case 'liveTV.failedToStartOver': return ({required Object error}) => 'Failed to start over: ${error}';
			case 'liveTV.playingProgram': return ({required Object title}) => 'Playing: ${title}';
			case 'liveTV.failedToPlayProgram': return ({required Object error}) => 'Failed to play program: ${error}';
			case 'liveTV.addedToFavorites': return 'Added to favorites';
			case 'liveTV.removedFromFavorites': return 'Removed from favorites';
			case 'liveTV.failedToUpdateFavorite': return ({required Object error}) => 'Failed to update favorite: ${error}';
			case 'liveTV.pipNotSupported': return 'Picture-in-Picture not supported on this platform';
			case 'liveTV.enteredPipMode': return 'Entered Picture-in-Picture mode';
			case 'liveTV.exitedPipMode': return 'Exited Picture-in-Picture mode';
			case 'liveTV.aspectRatioChanged': return ({required Object mode}) => 'Aspect Ratio: ${mode}';
			case 'liveTV.tune': return 'Tune';
			case 'liveTV.retry': return 'Retry';
			case 'liveTV.noChannelsMatchFilter': return 'No channels match filter';
			case 'liveTV.skipCommercial': return 'Skip Commercial';
			case 'dvr.title': return 'DVR';
			case 'dvr.recordings': return 'Recordings';
			case 'dvr.seriesRules': return 'Series Rules';
			case 'dvr.noRecordings': return 'No recordings';
			case 'dvr.noRules': return 'No series rules';
			case 'dvr.scheduleFromGuide': return 'Schedule recordings from the Live TV guide';
			case 'dvr.createRulesHint': return 'Create rules to auto-record series';
			case 'dvr.storage': return 'Storage';
			case 'dvr.recordingsCount': return ({required Object count}) => '${count} recordings';
			case 'dvr.all': return 'All';
			case 'dvr.scheduled': return 'Scheduled';
			case 'dvr.completed': return 'Completed';
			case 'dvr.failed': return 'Failed';
			case 'dvr.deleteRecording': return 'Delete Recording?';
			case 'dvr.deleteRule': return 'Delete Series Rule?';
			case 'dvr.sortByDate': return 'Date';
			case 'dvr.sortByTitle': return 'Title';
			case 'dvr.sortBySize': return 'Size';
			case 'dvr.playRecording': return 'Play recording';
			case 'dvr.keepPolicy': return ({required Object count}) => 'Keep ${count} episodes';
			case 'dvr.keepAll': return 'Keep all';
			case 'dvr.recordingScheduled': return 'Recording scheduled';
			case 'dvr.scheduleRecordingTitle': return 'Schedule Recording';
			case 'dvr.schedule': return 'Schedule';
			case 'dvr.cancel': return 'Cancel';
			case 'epg.title': return 'TV Guide';
			case 'epg.now': return 'Now';
			case 'epg.today': return 'Today';
			case 'epg.tomorrow': return 'Tomorrow';
			case 'epg.noPrograms': return 'No program information available';
			case 'epg.loading': return 'Loading guide...';
			case 'epg.record': return 'Record';
			case 'epg.reminder': return 'Set Reminder';
			case 'epg.moreInfo': return 'More Info';
			case 'epg.toggleView': return 'Toggle view';
			case 'epg.gridView': return 'Grid view';
			case 'epg.nowNextView': return 'Now/Next view';
			case 'channelSurfing.title': return 'Channel Surfing';
			case 'channelSurfing.kidsMode': return 'Kids Mode';
			case 'channelSurfing.loading': return 'Loading channel surfing...';
			case 'channelSurfing.failedToLoad': return 'Failed to load content';
			case 'channelSurfing.retry': return 'Retry';
			case 'channelSurfing.noContent': return 'No content available';
			case 'channelSurfing.itemsAvailable': return ({required Object count}) => '${count} items available';
			case 'channelSurfing.startSurfing': return 'Start Surfing';
			case 'channelSurfing.pressBackToExit': return 'Press back to exit';
			case 'channelSurfing.description': return 'Watch random movies and shows continuously';
			case 'channelSurfing.noServers': return 'No servers available';
			case 'virtualChannels.title': return 'Virtual Channels';
			case 'virtualChannels.createChannel': return 'Create Channel';
			case 'virtualChannels.editChannel': return 'Edit Channel';
			case 'virtualChannels.deleteChannel': return 'Delete Channel';
			case 'virtualChannels.channelName': return 'Channel Name';
			case 'virtualChannels.channelNameHint': return 'Enter channel name';
			case 'virtualChannels.selectContent': return 'Select Content';
			case 'virtualChannels.noChannels': return 'No virtual channels yet';
			case 'virtualChannels.createFirst': return 'Create your first virtual channel';
			case 'virtualChannels.description': return 'Create custom 24/7 channels from your media library';
			case 'virtualChannels.shuffle': return 'Shuffle Playback';
			case 'virtualChannels.loop': return 'Loop Playlist';
			case 'virtualChannels.nowPlaying': return 'Now Playing';
			case 'virtualChannels.upNext': return 'Up Next';
			case 'virtualChannels.addMedia': return 'Add Media';
			case 'virtualChannels.removeMedia': return 'Remove';
			case 'virtualChannels.reorderMedia': return 'Reorder';
			case 'virtualChannels.confirmDelete': return 'Are you sure you want to delete this channel?';
			case 'virtualChannels.channelCreated': return 'Channel created';
			case 'virtualChannels.channelUpdated': return 'Channel updated';
			case 'virtualChannels.channelDeleted': return 'Channel deleted';
			case 'multiview.title': return 'Multi-View';
			case 'multiview.changeLayout': return 'Change Layout (L)';
			case 'multiview.addChannel': return 'Add Channel (A)';
			case 'multiview.removeChannel': return 'Remove Channel (R)';
			case 'multiview.swapChannel': return 'Change Channel';
			case 'multiview.toggleMute': return 'Toggle Mute (M)';
			case 'multiview.selectChannel': return 'Select Channel';
			case 'multiview.searchChannels': return 'Search channels...';
			case 'multiview.cancel': return 'Cancel';
			case 'multiview.channelNumber': return ({required Object number}) => 'Ch. ${number}';
			case 'player.playbackError': return 'Playback Error';
			case 'player.error': return 'Error';
			case 'player.failedToStartPlayback': return ({required Object error}) => 'Failed to start playback:\n${error}';
			case 'player.ok': return 'OK';
			case 'downloads.title': return 'Downloads';
			case 'downloads.deleteAll': return 'Delete All';
			case 'downloads.deleteAllTitle': return 'Delete All Downloads?';
			case 'downloads.deleteAllMessage': return ({required Object count, required Object size}) => 'This will delete all ${count} downloads and free up ${size} of storage.';
			case 'downloads.storageUsed': return ({required Object size}) => 'Storage Used: ${size}';
			case 'downloads.downloading': return ({required Object count}) => 'Downloading (${count})';
			case 'downloads.downloaded': return ({required Object count}) => 'Downloaded (${count})';
			case 'downloads.noDownloads': return 'No Downloads';
			case 'downloads.noDownloadsHint': return 'Download movies and shows to watch offline';
			case 'downloads.deleteDownloadTitle': return 'Delete Download?';
			case 'downloads.deleteDownloadMessage': return ({required Object title}) => 'Delete "${title}"?';
			case 'downloads.delete': return 'Delete';
			case 'downloads.cancel': return 'Cancel';
			case 'downloads.downloadFailed': return 'Download failed';
			case 'downloads.paused': return 'Paused';
			default: return null;
		}
	}
}

extension on _StringsDe {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'OpenFlix';
			case 'app.loading': return 'Lädt...';
			case 'auth.signIn': return 'Anmelden';
			case 'auth.signUp': return 'Registrieren';
			case 'auth.signInWithPlex': return 'Bei OpenFlix anmelden';
			case 'auth.showQRCode': return 'QR-Code anzeigen';
			case 'auth.cancel': return 'Abbrechen';
			case 'auth.authenticate': return 'Authentifizieren';
			case 'auth.retry': return 'Erneut versuchen';
			case 'auth.debugEnterToken': return 'Debug: Token eingeben';
			case 'auth.plexTokenLabel': return 'Auth-Token';
			case 'auth.plexTokenHint': return 'Token eingeben';
			case 'auth.authenticationTimeout': return 'Authentifizierung abgelaufen. Bitte erneut versuchen.';
			case 'auth.scanQRCodeInstruction': return 'Diesen QR-Code scannen, um zu authentifizieren.';
			case 'auth.waitingForAuth': return 'Warte auf Authentifizierung...\nBitte Anmeldung im Browser abschließen.';
			case 'auth.serverUrl': return 'Server-URL';
			case 'auth.serverUrlHint': return 'z.B. http://192.168.1.100:32400';
			case 'auth.username': return 'Benutzername';
			case 'auth.usernameHint': return 'Benutzername eingeben';
			case 'auth.email': return 'E-Mail';
			case 'auth.emailHint': return 'E-Mail-Adresse eingeben';
			case 'auth.password': return 'Passwort';
			case 'auth.passwordHint': return 'Passwort eingeben';
			case 'auth.confirmPassword': return 'Passwort bestätigen';
			case 'auth.confirmPasswordHint': return 'Passwort erneut eingeben';
			case 'auth.displayName': return 'Anzeigename';
			case 'auth.displayNameHint': return 'Optionaler Anzeigename';
			case 'auth.noAccount': return 'Noch kein Konto?';
			case 'auth.haveAccount': return 'Bereits ein Konto?';
			case 'auth.connecting': return 'Verbinde mit Server...';
			case 'auth.loggingIn': return 'Anmeldung...';
			case 'auth.registering': return 'Konto wird erstellt...';
			case 'auth.connectToServer': return 'Mit Server verbinden';
			case 'auth.changeServer': return 'Server ändern';
			case 'auth.serverConnected': return ({required Object serverName}) => 'Verbunden mit ${serverName}';
			case 'auth.invalidServerUrl': return 'Bitte gültige Server-URL eingeben';
			case 'auth.serverConnectionFailed': return 'Verbindung zum Server fehlgeschlagen';
			case 'auth.passwordMismatch': return 'Passwörter stimmen nicht überein';
			case 'auth.usernameRequired': return 'Benutzername erforderlich';
			case 'auth.emailRequired': return 'E-Mail erforderlich';
			case 'auth.passwordRequired': return 'Passwort erforderlich';
			case 'auth.passwordTooShort': return 'Passwort muss mindestens 6 Zeichen haben';
			case 'auth.invalidEmail': return 'Bitte gültige E-Mail-Adresse eingeben';
			case 'auth.firstUserNote': return 'Erster Benutzer wird Administrator';
			case 'auth.howConnecting': return 'Wie möchten Sie sich verbinden?';
			case 'auth.atHome': return 'Zu Hause';
			case 'auth.atHomeDescription': return 'Server im lokalen Netzwerk automatisch erkennen';
			case 'auth.awayFromHome': return 'Unterwegs';
			case 'auth.awayFromHomeDescription': return 'Serveradresse manuell eingeben';
			case 'auth.findYourServer': return 'Server finden';
			case 'auth.searching': return 'Suche...';
			case 'auth.checkingNetwork': return 'Netzwerk wird überprüft...';
			case 'auth.serversFound': return 'Server gefunden';
			case 'auth.scanAgain': return 'Erneut suchen';
			case 'auth.enterManually': return 'Manuell eingeben';
			case 'auth.noServersFound': return 'Keine Server in Ihrem Netzwerk gefunden. Stellen Sie sicher, dass Ihr OpenFlix-Server läuft.';
			case 'auth.discoveryFailed': return ({required Object error}) => 'Suche fehlgeschlagen: ${error}';
			case 'common.cancel': return 'Abbrechen';
			case 'common.save': return 'Speichern';
			case 'common.close': return 'Schließen';
			case 'common.clear': return 'Leeren';
			case 'common.reset': return 'Zurücksetzen';
			case 'common.later': return 'Später';
			case 'common.submit': return 'Senden';
			case 'common.confirm': return 'Bestätigen';
			case 'common.retry': return 'Erneut versuchen';
			case 'common.playNow': return 'Jetzt abspielen';
			case 'common.logout': return 'Abmelden';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Besitzer';
			case 'common.shared': return 'Geteilt';
			case 'common.current': return 'AKTUELL';
			case 'common.unknown': return 'Unbekannt';
			case 'common.refresh': return 'Aktualisieren';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nein';
			case 'common.server': return 'Server';
			case 'common.delete': return 'Löschen';
			case 'common.shuffle': return 'Zufall';
			case 'common.addTo': return 'Hinzufügen zu...';
			case 'common.remove': return 'Remove';
			case 'common.play': return 'Play';
			case 'common.details': return 'Details';
			case 'common.seeAll': return 'See All';
			case 'common.live': return 'LIVE';
			case 'common.newLabel': return 'NEU';
			case 'screens.licenses': return 'Lizenzen';
			case 'screens.selectServer': return 'Server auswählen';
			case 'screens.switchProfile': return 'Profil wechseln';
			case 'screens.subtitleStyling': return 'Untertitel-Stil';
			case 'screens.search': return 'Suche';
			case 'screens.logs': return 'Protokolle';
			case 'update.available': return 'Update verfügbar';
			case 'update.versionAvailable': return ({required Object version}) => 'Version ${version} ist verfügbar';
			case 'update.currentVersion': return ({required Object version}) => 'Aktuell: ${version}';
			case 'update.skipVersion': return 'Diese Version überspringen';
			case 'update.viewRelease': return 'Release anzeigen';
			case 'update.latestVersion': return 'Aktuellste Version installiert';
			case 'update.checkFailed': return 'Fehler bei der Updateprüfung';
			case 'settings.title': return 'Einstellungen';
			case 'settings.profile': return 'Profil';
			case 'settings.noProfileSelected': return 'Kein Profil ausgewählt';
			case 'settings.kidsMode': return 'Kindermodus';
			case 'settings.switchProfile': return 'Profil wechseln';
			case 'settings.switchProfileDescription': return 'Zu einem anderen Profil wechseln';
			case 'settings.manageProfiles': return 'Profile verwalten';
			case 'settings.manageProfilesDescription': return 'Profile hinzufügen, bearbeiten oder löschen';
			case 'settings.language': return 'Sprache';
			case 'settings.theme': return 'Design';
			case 'settings.appearance': return 'Darstellung';
			case 'settings.videoPlayback': return 'Videowiedergabe';
			case 'settings.shufflePlay': return 'Zufallswiedergabe';
			case 'settings.advanced': return 'Erweitert';
			case 'settings.useSeasonPostersDescription': return 'Staffelposter statt Serienposter für Episoden anzeigen';
			case 'settings.showHeroSectionDescription': return 'Bereich mit empfohlenen Inhalten auf der Startseite anzeigen';
			case 'settings.secondsLabel': return 'Sekunden';
			case 'settings.minutesLabel': return 'Minuten';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})';
			case 'settings.systemTheme': return 'System';
			case 'settings.systemThemeDescription': return 'Systemeinstellungen folgen';
			case 'settings.lightTheme': return 'Hell';
			case 'settings.darkTheme': return 'Dunkel';
			case 'settings.libraryDensity': return 'Mediathekdichte';
			case 'settings.compact': return 'Kompakt';
			case 'settings.compactDescription': return 'Kleinere Karten, mehr Elemente sichtbar';
			case 'settings.normal': return 'Normal';
			case 'settings.normalDescription': return 'Standardgröße';
			case 'settings.comfortable': return 'Großzügig';
			case 'settings.comfortableDescription': return 'Größere Karten, weniger Elemente sichtbar';
			case 'settings.viewMode': return 'Ansichtsmodus';
			case 'settings.gridView': return 'Raster';
			case 'settings.gridViewDescription': return 'Elemente im Raster anzeigen';
			case 'settings.listView': return 'Liste';
			case 'settings.listViewDescription': return 'Elemente in Listenansicht anzeigen';
			case 'settings.useSeasonPosters': return 'Staffelposter verwenden';
			case 'settings.showHeroSection': return 'Hero-Bereich anzeigen';
			case 'settings.hardwareDecoding': return 'Hardware-Decodierung';
			case 'settings.hardwareDecodingDescription': return 'Hardwarebeschleunigung verwenden, sofern verfügbar';
			case 'settings.bufferSize': return 'Puffergröße';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Untertitel-Stil';
			case 'settings.subtitleStylingDescription': return 'Aussehen von Untertiteln anpassen';
			case 'settings.smallSkipDuration': return 'Kleine Sprungdauer';
			case 'settings.largeSkipDuration': return 'Große Sprungdauer';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} Sekunden';
			case 'settings.defaultSleepTimer': return 'Standard-Sleep-Timer';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} Minuten';
			case 'settings.rememberTrackSelections': return 'Spurauswahl pro Serie/Film merken';
			case 'settings.rememberTrackSelectionsDescription': return 'Audio- und Untertitelsprache automatisch speichern, wenn während der Wiedergabe geändert';
			case 'settings.unwatchedOnly': return 'Nur ungesehene';
			case 'settings.unwatchedOnlyDescription': return 'Nur ungesehene Episoden in die Shuffle-Warteschlange aufnehmen';
			case 'settings.shuffleOrderNavigation': return 'Navigation der Shuffle-Reihenfolge';
			case 'settings.shuffleOrderNavigationDescription': return 'Weiter/Zurück folgt der zufälligen Reihenfolge';
			case 'settings.loopShuffleQueue': return 'Shuffle-Warteschlange wiederholen';
			case 'settings.loopShuffleQueueDescription': return 'Warteschlange neu starten, wenn das Ende erreicht ist';
			case 'settings.videoPlayerControls': return 'Videoplayer-Steuerung';
			case 'settings.keyboardShortcuts': return 'Tastenkürzel';
			case 'settings.keyboardShortcutsDescription': return 'Tastenkürzel anpassen';
			case 'settings.debugLogging': return 'Debug-Protokollierung';
			case 'settings.debugLoggingDescription': return 'Detaillierte Protokolle zur Fehleranalyse aktivieren';
			case 'settings.viewLogs': return 'Protokolle anzeigen';
			case 'settings.viewLogsDescription': return 'App-Protokolle anzeigen';
			case 'settings.clearCache': return 'Cache löschen';
			case 'settings.clearCacheDescription': return 'Löscht alle zwischengespeicherten Bilder und Daten. Die App kann danach langsamer laden.';
			case 'settings.clearCacheSuccess': return 'Cache erfolgreich gelöscht';
			case 'settings.resetSettings': return 'Einstellungen zurücksetzen';
			case 'settings.resetSettingsDescription': return 'Alle Einstellungen auf Standard zurücksetzen. Dies kann nicht rückgängig gemacht werden.';
			case 'settings.resetSettingsSuccess': return 'Einstellungen erfolgreich zurückgesetzt';
			case 'settings.shortcutsReset': return 'Tastenkürzel auf Standard zurückgesetzt';
			case 'settings.about': return 'Über';
			case 'settings.aboutDescription': return 'App-Informationen und Lizenzen';
			case 'settings.updates': return 'Updates';
			case 'settings.updateAvailable': return 'Update verfügbar';
			case 'settings.checkForUpdates': return 'Nach Updates suchen';
			case 'settings.validationErrorEnterNumber': return 'Bitte eine gültige Zahl eingeben';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'Dauer muss zwischen ${min} und ${max} ${unit} liegen';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Tastenkürzel bereits zugewiesen an ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Tastenkürzel aktualisiert für ${action}';
			case 'settings.autoSkip': return 'Automatisches Überspringen';
			case 'settings.autoSkipIntro': return 'Intro automatisch überspringen';
			case 'settings.autoSkipIntroDescription': return 'Intro-Marker nach wenigen Sekunden automatisch überspringen';
			case 'settings.autoSkipCredits': return 'Abspann automatisch überspringen';
			case 'settings.autoSkipCreditsDescription': return 'Abspann automatisch überspringen und nächste Episode abspielen';
			case 'settings.autoSkipDelay': return 'Verzögerung für automatisches Überspringen';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten';
			case 'settings.metadataSection': return 'Metadaten';
			case 'settings.tmdbApiKey': return 'TMDB-API-Schlüssel';
			case 'settings.tmdbApiKeyDescription': return 'TMDB für erweiterte Metadaten konfigurieren';
			case 'settings.tmdbApiKeyConfigured': return 'API-Schlüssel konfiguriert';
			case 'settings.tmdbApiKeyHint': return 'API-Schlüssel von themoviedb.org erhalten';
			case 'settings.tmdbApiKeyPlaceholder': return 'TMDB-API-Schlüssel eingeben';
			case 'settings.apiKey': return 'API-Schlüssel';
			case 'settings.tmdbApiKeySaved': return 'TMDB-API-Schlüssel gespeichert';
			case 'settings.tmdbApiKeyCleared': return 'TMDB-API-Schlüssel gelöscht';
			case 'settings.parentalControls': return 'Kindersicherung';
			case 'settings.enableParentalControls': return 'Kindersicherung aktivieren';
			case 'settings.enableParentalControlsDescription': return 'Inhalte basierend auf Altersfreigaben einschränken';
			case 'settings.setPin': return 'PIN festlegen';
			case 'settings.setPinDescription': return 'Geben Sie eine 4-stellige PIN zum Schutz der Kindersicherung ein';
			case 'settings.confirmPin': return 'PIN bestätigen';
			case 'settings.confirmPinDescription': return 'Geben Sie die PIN zur Bestätigung erneut ein';
			case 'settings.enterPin': return 'PIN eingeben';
			case 'settings.enterPinDescription': return 'Geben Sie Ihre Kindersicherungs-PIN ein';
			case 'settings.changePin': return 'PIN ändern';
			case 'settings.changePinDescription': return 'Ändern Sie Ihre Kindersicherungs-PIN';
			case 'settings.pinSet': return 'Kindersicherungs-PIN erfolgreich festgelegt';
			case 'settings.pinMismatch': return 'PINs stimmen nicht überein. Bitte versuchen Sie es erneut.';
			case 'settings.incorrectPin': return 'Falsche PIN. Bitte versuchen Sie es erneut.';
			case 'settings.maxMovieRating': return 'Maximale Filmfreigabe';
			case 'settings.maxTvRating': return 'Maximale TV-Freigabe';
			case 'search.hint': return 'Filme, Serien, Musik suchen...';
			case 'search.tryDifferentTerm': return 'Anderen Suchbegriff versuchen';
			case 'search.searchYourMedia': return 'Medien durchsuchen';
			case 'search.enterTitleActorOrKeyword': return 'Titel, Schauspieler oder Stichwort eingeben';
			case 'search.recentSearches': return 'Letzte Suchen';
			case 'search.clear': return 'Löschen';
			case 'search.voiceSearch': return 'Sprachsuche';
			case 'search.listening': return 'Höre zu...';
			case 'search.speakNow': return 'Jetzt sprechen';
			case 'search.all': return 'Alle';
			case 'search.movies': return 'Filme';
			case 'search.tvShows': return 'Serien';
			case 'search.music': return 'Musik';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Tastenkürzel festlegen für ${actionName}';
			case 'hotkeys.clearShortcut': return 'Kürzel löschen';
			case 'pinEntry.enterPin': return 'PIN eingeben';
			case 'pinEntry.showPin': return 'PIN anzeigen';
			case 'pinEntry.hidePin': return 'PIN verbergen';
			case 'fileInfo.title': return 'Dateiinfo';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Audio';
			case 'fileInfo.file': return 'Datei';
			case 'fileInfo.advanced': return 'Erweitert';
			case 'fileInfo.codec': return 'Codec';
			case 'fileInfo.resolution': return 'Auflösung';
			case 'fileInfo.bitrate': return 'Bitrate';
			case 'fileInfo.frameRate': return 'Bildrate';
			case 'fileInfo.aspectRatio': return 'Seitenverhältnis';
			case 'fileInfo.profile': return 'Profil';
			case 'fileInfo.bitDepth': return 'Farbtiefe';
			case 'fileInfo.colorSpace': return 'Farbraum';
			case 'fileInfo.colorRange': return 'Farbbereich';
			case 'fileInfo.colorPrimaries': return 'Primärfarben';
			case 'fileInfo.chromaSubsampling': return 'Chroma-Subsampling';
			case 'fileInfo.channels': return 'Kanäle';
			case 'fileInfo.path': return 'Pfad';
			case 'fileInfo.size': return 'Größe';
			case 'fileInfo.container': return 'Container';
			case 'fileInfo.duration': return 'Dauer';
			case 'fileInfo.optimizedForStreaming': return 'Für Streaming optimiert';
			case 'fileInfo.has64bitOffsets': return '64-Bit-Offsets';
			case 'mediaMenu.markAsWatched': return 'Als gesehen markieren';
			case 'mediaMenu.markAsUnwatched': return 'Als ungesehen markieren';
			case 'mediaMenu.removeFromContinueWatching': return 'Aus ‚Weiterschauen‘ entfernen';
			case 'mediaMenu.goToSeries': return 'Zur Serie';
			case 'mediaMenu.goToSeason': return 'Zur Staffel';
			case 'mediaMenu.shufflePlay': return 'Zufallswiedergabe';
			case 'mediaMenu.fileInfo': return 'Dateiinfo';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, Film';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, Serie';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'angesehen';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} Prozent angesehen';
			case 'accessibility.mediaCardUnwatched': return 'ungeschaut';
			case 'accessibility.tapToPlay': return 'Zum Abspielen tippen';
			case 'tooltips.shufflePlay': return 'Zufallswiedergabe';
			case 'tooltips.markAsWatched': return 'Als gesehen markieren';
			case 'tooltips.markAsUnwatched': return 'Als ungesehen markieren';
			case 'videoControls.audioLabel': return 'Audio';
			case 'videoControls.subtitlesLabel': return 'Untertitel';
			case 'videoControls.resetToZero': return 'Auf 0 ms zurücksetzen';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} spielt später';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} spielt früher';
			case 'videoControls.noOffset': return 'Kein Offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Bild füllen';
			case 'videoControls.stretch': return 'Strecken';
			case 'videoControls.lockRotation': return 'Rotation sperren';
			case 'videoControls.unlockRotation': return 'Rotation entsperren';
			case 'videoControls.lockScreen': return 'Bildschirm sperren';
			case 'videoControls.unlockScreen': return 'Bildschirm entsperren';
			case 'videoControls.screenLockButton': return 'Bildschirmsperre';
			case 'videoControls.screenLocked': return 'Bildschirm gesperrt';
			case 'videoControls.tapToUnlock': return 'Zum Entsperren tippen';
			case 'videoControls.sleepTimer': return 'Schlaftimer';
			case 'videoControls.timerActive': return 'Schlaftimer aktiv';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert';
			case 'videoControls.sleepTimerCompleted': return 'Schlaftimer abgelaufen – Wiedergabe pausiert';
			case 'videoControls.playButton': return 'Wiedergeben';
			case 'videoControls.pauseButton': return 'Pause';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => '${seconds} Sekunden zurück';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => '${seconds} Sekunden vor';
			case 'videoControls.previousButton': return 'Vorherige Episode';
			case 'videoControls.nextButton': return 'Nächste Episode';
			case 'videoControls.previousChapterButton': return 'Vorheriges Kapitel';
			case 'videoControls.nextChapterButton': return 'Nächstes Kapitel';
			case 'videoControls.volumeButton': return 'Lautstärke';
			case 'videoControls.muteButton': return 'Stumm schalten';
			case 'videoControls.unmuteButton': return 'Stummschaltung aufheben';
			case 'videoControls.settingsButton': return 'Videoeinstellungen';
			case 'videoControls.audioTrackButton': return 'Tonspuren';
			case 'videoControls.subtitlesButton': return 'Untertitel';
			case 'videoControls.chaptersButton': return 'Kapitel';
			case 'videoControls.versionsButton': return 'Videoversionen';
			case 'videoControls.aspectRatioButton': return 'Seitenverhältnis';
			case 'videoControls.fullscreenButton': return 'Vollbild aktivieren';
			case 'videoControls.exitFullscreenButton': return 'Vollbild verlassen';
			case 'videoControls.rotationLockButton': return 'Dreh­sperre';
			case 'videoControls.timelineSlider': return 'Video-Zeitleiste';
			case 'videoControls.volumeSlider': return 'Lautstärkepegel';
			case 'videoControls.backButton': return 'Zurück';
			case 'userStatus.admin': return 'Eigentümer';
			case 'userStatus.restricted': return 'Eingeschränkt';
			case 'userStatus.protected': return 'Geschützt';
			case 'userStatus.current': return 'AKTUELL';
			case 'messages.markedAsWatched': return 'Als gesehen markiert';
			case 'messages.markedAsUnwatched': return 'Als ungesehen markiert';
			case 'messages.removedFromContinueWatching': return 'Aus ‚Weiterschauen‘ entfernt';
			case 'messages.errorLoading': return ({required Object error}) => 'Fehler: ${error}';
			case 'messages.fileInfoNotAvailable': return 'Dateiinfo nicht verfügbar';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}';
			case 'messages.errorLoadingSeries': return 'Fehler beim Laden der Serie';
			case 'messages.errorLoadingSeason': return 'Fehler beim Laden der Staffel';
			case 'messages.musicNotSupported': return 'Musikwiedergabe wird noch nicht unterstützt';
			case 'messages.logsCleared': return 'Protokolle gelöscht';
			case 'messages.logsCopied': return 'Protokolle in Zwischenablage kopiert';
			case 'messages.noLogsAvailable': return 'Keine Protokolle verfügbar';
			case 'messages.libraryScanning': return ({required Object title}) => 'Scanne „${title}“...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Mediathekscan gestartet für „${title}“';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Fehler beim Scannen der Mediathek: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Metadaten werden aktualisiert für „${title}“...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}';
			case 'messages.noTokenFound': return 'Kein Token gefunden. Bitte erneut anmelden.';
			case 'messages.logoutConfirm': return 'Abmeldung wirklich durchführen?';
			case 'messages.noSeasonsFound': return 'Keine Staffeln gefunden';
			case 'messages.noEpisodesFound': return 'Keine Episoden in der ersten Staffel gefunden';
			case 'messages.noEpisodesFoundGeneral': return 'Keine Episoden gefunden';
			case 'messages.noResultsFound': return 'Keine Ergebnisse gefunden';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sleep-Timer gesetzt auf ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
			case 'messages.noItemsAvailable': return 'Keine Elemente verfügbar';
			case 'messages.failedToCreatePlayQueue': return 'Wiedergabewarteschlange konnte nicht erstellt werden';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}';
			case 'profile.noUsersAvailable': return 'Keine Benutzer verfügbar';
			case 'subtitlingStyling.stylingOptions': return 'Stiloptionen';
			case 'subtitlingStyling.fontSize': return 'Schriftgröße';
			case 'subtitlingStyling.textColor': return 'Textfarbe';
			case 'subtitlingStyling.borderSize': return 'Rahmengröße';
			case 'subtitlingStyling.borderColor': return 'Rahmenfarbe';
			case 'subtitlingStyling.backgroundOpacity': return 'Hintergrunddeckkraft';
			case 'subtitlingStyling.backgroundColor': return 'Hintergrundfarbe';
			case 'dialog.confirmAction': return 'Aktion bestätigen';
			case 'dialog.areYouSure': return 'Aktion wirklich ausführen?';
			case 'dialog.cancel': return 'Abbrechen';
			case 'dialog.playNow': return 'Jetzt abspielen';
			case 'discover.title': return 'Entdecken';
			case 'discover.switchProfile': return 'Profil wechseln';
			case 'discover.switchServer': return 'Server wechseln';
			case 'discover.logout': return 'Abmelden';
			case 'discover.noContentAvailable': return 'Kein Inhalt verfügbar';
			case 'discover.addMediaToLibraries': return 'Medien zur Mediathek hinzufügen';
			case 'discover.continueWatching': return 'Weiterschauen';
			case 'discover.recentlyAdded': return 'Kürzlich hinzugefügt';
			case 'discover.play': return 'Abspielen';
			case 'discover.resume': return 'Fortsetzen';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'S${season}, E${episode} - Abspielen';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'S${season}, E${episode} - Fortsetzen';
			case 'discover.pause': return 'Pause';
			case 'discover.overview': return 'Übersicht';
			case 'discover.cast': return 'Besetzung';
			case 'discover.seasons': return 'Staffeln';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Altersfreigabe';
			case 'discover.watched': return 'Gesehen';
			case 'discover.episodeCount': return ({required Object count}) => '${count} Episoden';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched} von ${total} gesehen';
			case 'discover.movie': return 'Film';
			case 'discover.tvShow': return 'Serie';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} Min übrig';
			case 'discover.whatsOnNow': return 'Jetzt läuft';
			case 'discover.channelGuide': return 'Programmführer';
			case 'discover.liveNow': return 'Jetzt Live';
			case 'discover.topTen': return 'Top 10';
			case 'discover.newBadge': return 'NEU';
			case 'discover.liveBadge': return 'LIVE';
			case 'discover.goodMorning': return 'Good morning';
			case 'discover.goodAfternoon': return 'Good afternoon';
			case 'discover.goodEvening': return 'Good evening';
			case 'discover.defaultUser': return 'Guest';
			case 'discover.yourNextWatch': return 'Your Next Watch';
			case 'discover.pickedForYou': return ({required Object name}) => 'Picked just for you, ${name}';
			case 'discover.surpriseMe': return 'Surprise Me';
			case 'discover.randomPicker': return 'Random Movie Picker';
			case 'discover.noMoviesFound': return 'No movies found in your library';
			case 'discover.spinning': return 'Picking something great...';
			case 'discover.spinAgain': return 'Spin Again';
			case 'discover.calendar': return 'Calendar';
			case 'discover.today': return 'Today';
			case 'discover.item': return 'item';
			case 'discover.items': return 'items';
			case 'discover.loadingMovies': return 'Lade deine Filme...';
			case 'discover.noContentOnDate': return 'No content added on this date';
			case 'discover.noEpgData': return 'Keine Programminformationen';
			case 'errors.searchFailed': return ({required Object error}) => 'Suche fehlgeschlagen: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Zeitüberschreitung beim Laden von ${context}';
			case 'errors.connectionFailed': return 'Verbindung zum Plex-Server fehlgeschlagen';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Fehler beim Laden von ${context}: ${error}';
			case 'errors.noClientAvailable': return 'Kein Client verfügbar';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Authentifizierung fehlgeschlagen: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Auth-URL konnte nicht geöffnet werden';
			case 'errors.pleaseEnterToken': return 'Bitte Token eingeben';
			case 'errors.invalidToken': return 'Ungültiges Token';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Token-Verifizierung fehlgeschlagen: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
			case 'errors.connectionFailedGeneric': return 'Verbindung fehlgeschlagen';
			case 'errors.failedToRemove': return ({required Object error}) => 'Entfernen fehlgeschlagen: ${error}';
			case 'voice.notAvailable': return 'Sprachsteuerung ist nicht verfügbar';
			case 'voice.commandNotRecognized': return ({required Object command}) => 'Befehl nicht erkannt: "${command}"';
			case 'libraries.title': return 'Mediatheken';
			case 'libraries.scanLibraryFiles': return 'Mediatheksdateien scannen';
			case 'libraries.scanLibrary': return 'Mediathek scannen';
			case 'libraries.analyze': return 'Analysieren';
			case 'libraries.analyzeLibrary': return 'Mediathek analysieren';
			case 'libraries.refreshMetadata': return 'Metadaten aktualisieren';
			case 'libraries.emptyTrash': return 'Papierkorb leeren';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Papierkorb für „${title}“ wird geleert...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Papierkorb für „${title}“ geleert';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Papierkorb konnte nicht geleert werden: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analysiere „${title}“...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analyse gestartet für „${title}“';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Analyse der Mediathek fehlgeschlagen: ${error}';
			case 'libraries.noLibrariesFound': return 'Keine Mediatheken gefunden';
			case 'libraries.thisLibraryIsEmpty': return 'Diese Mediathek ist leer';
			case 'libraries.all': return 'Alle';
			case 'libraries.clearAll': return 'Alle löschen';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => '„${title}“ wirklich scannen?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => '„${title}“ wirklich analysieren?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Metadaten für „${title}“ wirklich aktualisieren?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Papierkorb für „${title}“ wirklich leeren?';
			case 'libraries.manageLibraries': return 'Mediatheken verwalten';
			case 'libraries.sort': return 'Sortieren';
			case 'libraries.sortBy': return 'Sortieren nach';
			case 'libraries.filters': return 'Filter';
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Lade Mediathek... (${count} Elemente geladen)';
			case 'libraries.confirmActionMessage': return 'Aktion wirklich durchführen?';
			case 'libraries.showLibrary': return 'Mediathek anzeigen';
			case 'libraries.hideLibrary': return 'Mediathek ausblenden';
			case 'libraries.libraryOptions': return 'Mediatheksoptionen';
			case 'libraries.content': return 'Bibliotheksinhalt';
			case 'libraries.selectLibrary': return 'Bibliothek auswählen';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filter (${count})';
			case 'libraries.noRecommendations': return 'Keine Empfehlungen verfügbar';
			case 'libraries.noCollections': return 'Keine Sammlungen in dieser Mediathek';
			case 'libraries.noFoldersFound': return 'Keine Ordner gefunden';
			case 'libraries.folders': return 'Ordner';
			case 'libraries.tabs.recommended': return 'Empfohlen';
			case 'libraries.tabs.browse': return 'Durchsuchen';
			case 'libraries.tabs.collections': return 'Sammlungen';
			case 'libraries.tabs.playlists': return 'Wiedergabelisten';
			case 'libraries.groupings.all': return 'Alle';
			case 'libraries.groupings.movies': return 'Filme';
			case 'libraries.groupings.shows': return 'Serien';
			case 'libraries.groupings.seasons': return 'Staffeln';
			case 'libraries.groupings.episodes': return 'Episoden';
			case 'libraries.groupings.folders': return 'Ordner';
			case 'about.title': return 'Über';
			case 'about.openSourceLicenses': return 'Open-Source-Lizenzen';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'Ein schöner Plex-Client für Flutter';
			case 'about.viewLicensesDescription': return 'Lizenzen von Drittanbieter-Bibliotheken anzeigen';
			case 'serverSelection.connectingToServer': return 'Verbinde mit Server...';
			case 'serverSelection.connectingToAllServers': return 'Verbinde mit allen Servern...';
			case 'serverSelection.connectToAllServers': return 'Mit allen Servern verbinden';
			case 'serverSelection.allServerConnectionsFailed': return 'Verbindung zu allen Servern fehlgeschlagen. Bitte Netzwerk prüfen und erneut versuchen.';
			case 'serverSelection.foundServers': return ({required Object count}) => '${count} Server gefunden';
			case 'serverSelection.orSelectIndividually': return 'Oder einzelnen Server auswählen:';
			case 'serverSelection.serverDebugCopied': return 'Server-Debugdaten kopiert';
			case 'serverSelection.copyDebugData': return 'Debugdaten kopieren';
			case 'serverSelection.noServersFound': return 'Keine Server gefunden';
			case 'serverSelection.malformedServerData': return ({required Object count}) => '${count} Server mit fehlerhaften Daten gefunden. Keine gültigen Server verfügbar.';
			case 'serverSelection.incompleteServerInfo': return 'Einige Serverinformationen sind unvollständig und wurden übersprungen. Plex.tv-Konto prüfen.';
			case 'serverSelection.incompleteConnectionInfo': return 'Serververbindungsinformationen unvollständig. Bitte erneut versuchen.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Serverinformationen fehlerhaft: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Netzwerkverbindung fehlgeschlagen. Internetverbindung prüfen und erneut versuchen.';
			case 'serverSelection.authenticationFailed': return 'Authentifizierung fehlgeschlagen. Bitte erneut anmelden.';
			case 'serverSelection.plexServiceUnavailable': return 'Plex-Dienst nicht verfügbar. Bitte später erneut versuchen.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Server konnten nicht geladen werden: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Erscheinungsjahr';
			case 'hubDetail.dateAdded': return 'Hinzugefügt am';
			case 'hubDetail.rating': return 'Bewertung';
			case 'hubDetail.noItemsFound': return 'Keine Elemente gefunden';
			case 'logs.title': return 'Protokolle';
			case 'logs.clearLogs': return 'Protokolle löschen';
			case 'logs.copyLogs': return 'Protokolle kopieren';
			case 'logs.exportLogs': return 'Protokolle exportieren';
			case 'logs.noLogsToShow': return 'Keine Protokolle zum Anzeigen';
			case 'logs.error': return 'Fehler:';
			case 'logs.stackTrace': return 'Stacktrace:';
			case 'stats.title': return 'Wiedergabestatistik';
			case 'stats.totalWatchTime': return 'Gesamte Wiedergabezeit';
			case 'stats.moviesWatched': return 'Filme gesehen';
			case 'stats.episodesWatched': return 'Episoden gesehen';
			case 'stats.avgPerDay': return 'Durchschnitt pro Tag';
			case 'stats.topGenres': return 'Top-Genres';
			case 'stats.monthlyActivity': return 'Monatliche Aktivität';
			case 'stats.noData': return 'Noch kein Wiedergabeverlauf';
			case 'stats.startWatching': return 'Schauen Sie etwas, um Ihre Statistiken zu sehen';
			case 'stats.days': return 'Tage';
			case 'licenses.relatedPackages': return 'Verwandte Pakete';
			case 'licenses.license': return 'Lizenz';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Lizenz ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} Lizenzen';
			case 'navigation.home': return 'Start';
			case 'navigation.search': return 'Suche';
			case 'navigation.libraries': return 'Mediatheken';
			case 'navigation.livetv': return 'Live TV';
			case 'navigation.settings': return 'Einstellungen';
			case 'playlists.title': return 'Wiedergabelisten';
			case 'playlists.noPlaylists': return 'Keine Wiedergabelisten gefunden';
			case 'playlists.create': return 'Wiedergabeliste erstellen';
			case 'playlists.newPlaylist': return 'Neue Wiedergabeliste';
			case 'playlists.playlistName': return 'Name der Wiedergabeliste';
			case 'playlists.enterPlaylistName': return 'Name der Wiedergabeliste eingeben';
			case 'playlists.edit': return 'Wiedergabeliste bearbeiten';
			case 'playlists.delete': return 'Wiedergabeliste löschen';
			case 'playlists.addTo': return 'Zur Wiedergabeliste hinzufügen';
			case 'playlists.addItems': return 'Elemente hinzufügen';
			case 'playlists.removeItem': return 'Aus Wiedergabeliste entfernen';
			case 'playlists.clearPlaylist': return 'Wiedergabeliste leeren';
			case 'playlists.playAll': return 'Alle abspielen';
			case 'playlists.shuffle': return 'Zufällig';
			case 'playlists.smartPlaylist': return 'Intelligente Wiedergabeliste';
			case 'playlists.regularPlaylist': return 'Normale Wiedergabeliste';
			case 'playlists.itemCount': return ({required Object count}) => '${count} Elemente';
			case 'playlists.oneItem': return '1 Element';
			case 'playlists.emptyPlaylist': return 'Diese Wiedergabeliste ist leer';
			case 'playlists.deleteConfirm': return 'Wiedergabeliste löschen?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Soll "${name}" wirklich gelöscht werden?';
			case 'playlists.created': return 'Wiedergabeliste erstellt';
			case 'playlists.updated': return 'Wiedergabeliste aktualisiert';
			case 'playlists.deleted': return 'Wiedergabeliste gelöscht';
			case 'playlists.itemAdded': return 'Zur Wiedergabeliste hinzugefügt';
			case 'playlists.itemRemoved': return 'Aus Wiedergabeliste entfernt';
			case 'playlists.selectPlaylist': return 'Wiedergabeliste auswählen';
			case 'playlists.createNewPlaylist': return 'Neue Wiedergabeliste erstellen';
			case 'playlists.errorCreating': return 'Wiedergabeliste konnte nicht erstellt werden';
			case 'playlists.errorDeleting': return 'Wiedergabeliste konnte nicht gelöscht werden';
			case 'playlists.errorLoading': return 'Wiedergabelisten konnten nicht geladen werden';
			case 'playlists.errorAdding': return 'Konnte nicht zur Wiedergabeliste hinzugefügt werden';
			case 'playlists.errorReordering': return 'Element der Wiedergabeliste konnte nicht neu geordnet werden';
			case 'playlists.errorRemoving': return 'Konnte nicht aus der Wiedergabeliste entfernt werden';
			case 'playlists.playlist': return 'Wiedergabeliste';
			case 'collections.title': return 'Sammlungen';
			case 'collections.collection': return 'Sammlung';
			case 'collections.empty': return 'Sammlung ist leer';
			case 'collections.noItems': return 'Keine Elemente in dieser Sammlung';
			case 'collections.unknownLibrarySection': return 'Löschen nicht möglich: Unbekannte Bibliothekssektion';
			case 'collections.deleteCollection': return 'Sammlung löschen';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Sind Sie sicher, dass Sie "${title}" löschen möchten? Dies kann nicht rückgängig gemacht werden.';
			case 'collections.deleted': return 'Sammlung gelöscht';
			case 'collections.deleteFailed': return 'Sammlung konnte nicht gelöscht werden';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Sammlung konnte nicht gelöscht werden: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Sammlungselemente konnten nicht geladen werden: ${error}';
			case 'collections.addTo': return 'Zur Sammlung hinzufügen';
			case 'collections.selectCollection': return 'Sammlung auswählen';
			case 'collections.createNewCollection': return 'Neue Sammlung erstellen';
			case 'collections.collectionName': return 'Sammlungsname';
			case 'collections.enterCollectionName': return 'Sammlungsnamen eingeben';
			case 'collections.addedToCollection': return 'Zur Sammlung hinzugefügt';
			case 'collections.errorAddingToCollection': return 'Fehler beim Hinzufügen zur Sammlung';
			case 'collections.created': return 'Sammlung erstellt';
			case 'collections.removeFromCollection': return 'Aus Sammlung entfernen';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => '"${title}" aus dieser Sammlung entfernen?';
			case 'collections.removedFromCollection': return 'Aus Sammlung entfernt';
			case 'collections.removeFromCollectionFailed': return 'Entfernen aus Sammlung fehlgeschlagen';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Fehler beim Entfernen aus der Sammlung: ${error}';
			case 'watchParty.title': return 'Watch Party';
			case 'watchParty.startParty': return 'Watch Party starten';
			case 'watchParty.joinParty': return 'Party beitreten';
			case 'watchParty.enterCode': return 'Party-Code eingeben';
			case 'watchParty.shareCode': return 'Diesen Code teilen';
			case 'watchParty.friendsCanJoin': return 'Freunde können mit diesem Code beitreten';
			case 'watchParty.participants': return 'Teilnehmer';
			case 'watchParty.host': return 'Host';
			case 'watchParty.endParty': return 'Party beenden';
			case 'watchParty.leaveParty': return 'Party verlassen';
			case 'watchParty.partyEnded': return 'Watch Party beendet';
			case 'watchParty.chat': return 'Chat';
			case 'watchParty.typeMessage': return 'Nachricht eingeben...';
			case 'watchParty.joined': return ({required Object name}) => '${name} ist beigetreten';
			case 'watchParty.left': return ({required Object name}) => '${name} hat verlassen';
			case 'watchParty.syncedPlayback': return 'Wiedergabe ist mit der Party synchronisiert';
			case 'watchParty.hostControls': return 'Nur der Host kann die Wiedergabe steuern';
			case 'watchParty.creating': return 'Party wird erstellt...';
			case 'watchParty.joining': return 'Beitritt zur Party...';
			case 'watchParty.createFailed': return 'Party konnte nicht erstellt werden';
			case 'watchParty.joinFailed': return 'Beitritt zur Party fehlgeschlagen';
			case 'watchParty.invalidCode': return 'Ungültiger Party-Code';
			case 'watchParty.gotIt': return 'Verstanden';
			case 'catchUp.title': return 'Catch Up TV';
			case 'catchUp.startOver': return 'Von Anfang an';
			case 'catchUp.startOverDescription': return 'Von Anfang an schauen';
			case 'catchUp.watchFromBeginning': return 'Von Anfang an schauen?';
			case 'catchUp.alreadyStarted': return ({required Object title}) => '"${title}" hat bereits begonnen. Sie können von Anfang an schauen.';
			case 'catchUp.watchLive': return 'Live schauen';
			case 'catchUp.programsAvailable': return 'Verfügbare Sendungen';
			case 'catchUp.noProgramsAvailable': return 'Keine Catch-up Sendungen verfügbar';
			case 'catchUp.programsWillAppear': return 'Sendungen erscheinen hier, wenn sie ausgestrahlt werden';
			case 'catchUp.unavailable': return 'Nicht verfügbar';
			case 'catchUp.bufferNotReady': return 'Puffer noch nicht bereit';
			case 'catchUp.rewind': return 'Zurückspulen';
			case 'catchUp.timeshiftEnabled': return 'Timeshift aktiviert';
			case 'catchUp.goBackTo': return ({required Object time}) => 'Zurück zu ${time}';
			case 'watchlist.title': return 'Meine Merkliste';
			case 'watchlist.all': return 'Alle';
			case 'watchlist.movies': return 'Filme';
			case 'watchlist.shows': return 'Serien';
			case 'watchlist.episodes': return 'Episoden';
			case 'watchlist.empty': return 'Ihre Merkliste ist leer';
			case 'watchlist.emptyHint': return 'Fügen Sie Filme und Serien zu Ihrer Merkliste hinzu';
			case 'watchlist.noItemsFiltered': return 'Keine Elemente entsprechen diesem Filter';
			case 'watchlist.removeTitle': return 'Von Merkliste entfernen';
			case 'watchlist.removeConfirm': return ({required Object title}) => '"${title}" von Ihrer Merkliste entfernen?';
			case 'watchlist.remove': return 'Remove';
			case 'watchlist.play': return 'Play';
			case 'watchlist.details': return 'Details';
			case 'watchlist.seeAll': return 'See All';
			case 'watchlist.clearAllTitle': return 'Merkliste leeren';
			case 'watchlist.clearAllConfirm': return ({required Object count}) => 'Alle ${count} Elemente von Ihrer Merkliste entfernen?';
			case 'watchlist.clearAll': return 'Alle löschen';
			case 'watchlist.addedToday': return 'Heute hinzugefügt';
			case 'watchlist.addedYesterday': return 'Gestern hinzugefügt';
			case 'watchlist.addedDaysAgo': return ({required Object days}) => 'Vor ${days} Tagen hinzugefügt';
			case 'watchlist.addedOn': return ({required Object date}) => 'Hinzugefügt am ${date}';
			case 'watchlist.addToWatchlist': return 'Zur Merkliste hinzufügen';
			case 'watchlist.removeFromWatchlist': return 'Von Merkliste entfernen';
			case 'watchlist.addedToWatchlist': return 'Zur Merkliste hinzugefügt';
			case 'watchlist.removedFromWatchlist': return 'Von Merkliste entfernt';
			case 'liveTV.title': return 'Live TV';
			case 'liveTV.guide': return 'Guide';
			case 'liveTV.dvr': return 'DVR';
			case 'liveTV.multiview': return 'Multiview';
			case 'liveTV.allChannels': return 'Alle Kanäle';
			case 'liveTV.favorites': return 'Favoriten';
			case 'liveTV.noChannels': return 'Keine Kanäle verfügbar';
			case 'liveTV.addM3USource': return 'M3U-Quelle in Server-Einstellungen hinzufügen';
			case 'liveTV.recording': return 'Aufnahme';
			case 'liveTV.recordingNow': return 'Jetzt aufnehmen';
			case 'liveTV.upNext': return 'Als nächstes';
			case 'liveTV.noProgram': return 'Keine Programminfo';
			case 'liveTV.filterByGroup': return 'Nach Gruppe filtern';
			case 'liveTV.refresh': return 'Aktualisieren';
			case 'liveTV.channelCount': return ({required Object count}) => '${count} Kanäle';
			case 'liveTV.nowPlaying': return 'Läuft gerade';
			case 'liveTV.scheduleRecording': return 'Aufnahme planen';
			case 'liveTV.onNow': return 'Jetzt';
			case 'liveTV.endsAt': return ({required Object time}) => 'Endet um ${time}';
			case 'liveTV.startsAt': return ({required Object time}) => 'Beginnt um ${time}';
			case 'liveTV.playbackError': return ({required Object error}) => 'Wiedergabefehler: ${error}';
			case 'liveTV.noPreviousChannel': return 'Kein vorheriger Sender';
			case 'liveTV.switchedTo': return ({required Object channel}) => 'Gewechselt zu: ${channel}';
			case 'liveTV.startingFromBeginning': return 'Starte Sendung von Anfang...';
			case 'liveTV.failedToStartOver': return ({required Object error}) => 'Neustart fehlgeschlagen: ${error}';
			case 'liveTV.playingProgram': return ({required Object title}) => 'Wiedergabe: ${title}';
			case 'liveTV.failedToPlayProgram': return ({required Object error}) => 'Sendung abspielen fehlgeschlagen: ${error}';
			case 'liveTV.addedToFavorites': return 'Zu Favoriten hinzugefügt';
			case 'liveTV.removedFromFavorites': return 'Aus Favoriten entfernt';
			case 'liveTV.failedToUpdateFavorite': return ({required Object error}) => 'Favorit aktualisieren fehlgeschlagen: ${error}';
			case 'liveTV.pipNotSupported': return 'Bild-in-Bild wird auf dieser Plattform nicht unterstützt';
			case 'liveTV.enteredPipMode': return 'Bild-in-Bild-Modus aktiviert';
			case 'liveTV.exitedPipMode': return 'Bild-in-Bild-Modus beendet';
			case 'liveTV.aspectRatioChanged': return ({required Object mode}) => 'Seitenverhältnis: ${mode}';
			case 'liveTV.tune': return 'Einschalten';
			case 'liveTV.retry': return 'Wiederholen';
			case 'liveTV.noChannelsMatchFilter': return 'Keine Sender entsprechen dem Filter';
			case 'liveTV.skipCommercial': return 'Werbung überspringen';
			case 'dvr.title': return 'DVR';
			case 'dvr.recordings': return 'Aufnahmen';
			case 'dvr.seriesRules': return 'Serienregeln';
			case 'dvr.noRecordings': return 'Keine Aufnahmen';
			case 'dvr.noRules': return 'Keine Serienregeln';
			case 'dvr.scheduleFromGuide': return 'Aufnahmen vom TV-Guide planen';
			case 'dvr.createRulesHint': return 'Regeln für Auto-Aufnahme erstellen';
			case 'dvr.storage': return 'Speicher';
			case 'dvr.recordingsCount': return ({required Object count}) => '${count} Aufnahmen';
			case 'dvr.all': return 'Alle';
			case 'dvr.scheduled': return 'Geplant';
			case 'dvr.completed': return 'Fertig';
			case 'dvr.failed': return 'Fehlgeschlagen';
			case 'dvr.deleteRecording': return 'Aufnahme löschen?';
			case 'dvr.deleteRule': return 'Serienregel löschen?';
			case 'dvr.sortByDate': return 'Datum';
			case 'dvr.sortByTitle': return 'Titel';
			case 'dvr.sortBySize': return 'Größe';
			case 'dvr.playRecording': return 'Aufnahme abspielen';
			case 'dvr.keepPolicy': return ({required Object count}) => '${count} Folgen behalten';
			case 'dvr.keepAll': return 'Alle behalten';
			case 'dvr.recordingScheduled': return 'Aufnahme geplant';
			case 'dvr.scheduleRecordingTitle': return 'Aufnahme planen';
			case 'dvr.schedule': return 'Planen';
			case 'dvr.cancel': return 'Abbrechen';
			case 'epg.title': return 'TV Guide';
			case 'epg.now': return 'Jetzt';
			case 'epg.today': return 'Heute';
			case 'epg.tomorrow': return 'Morgen';
			case 'epg.noPrograms': return 'Keine Programminfos verfügbar';
			case 'epg.loading': return 'Guide wird geladen...';
			case 'epg.record': return 'Aufnehmen';
			case 'epg.reminder': return 'Erinnerung setzen';
			case 'epg.moreInfo': return 'Mehr Info';
			case 'epg.toggleView': return 'Ansicht wechseln';
			case 'epg.gridView': return 'Rasteransicht';
			case 'epg.nowNextView': return 'Jetzt/Gleich Ansicht';
			case 'channelSurfing.title': return 'Zufallswiedergabe';
			case 'channelSurfing.kidsMode': return 'Kindermodus';
			case 'channelSurfing.loading': return 'Zufallswiedergabe wird geladen...';
			case 'channelSurfing.failedToLoad': return 'Inhalt konnte nicht geladen werden';
			case 'channelSurfing.retry': return 'Erneut versuchen';
			case 'channelSurfing.noContent': return 'Kein Inhalt verfügbar';
			case 'channelSurfing.itemsAvailable': return ({required Object count}) => '${count} Elemente verfügbar';
			case 'channelSurfing.startSurfing': return 'Starten';
			case 'channelSurfing.pressBackToExit': return 'Zurück zum Beenden';
			case 'channelSurfing.description': return 'Zufällige Filme und Serien durchgehend abspielen';
			case 'channelSurfing.noServers': return 'Keine Server verfügbar';
			case 'multiview.title': return 'Multi-Ansicht';
			case 'multiview.changeLayout': return 'Layout ändern (L)';
			case 'multiview.addChannel': return 'Kanal hinzufügen (A)';
			case 'multiview.removeChannel': return 'Kanal entfernen (R)';
			case 'multiview.swapChannel': return 'Kanal wechseln';
			case 'multiview.toggleMute': return 'Stumm schalten (M)';
			case 'multiview.selectChannel': return 'Kanal auswählen';
			case 'multiview.searchChannels': return 'Kanäle suchen...';
			case 'multiview.cancel': return 'Abbrechen';
			case 'multiview.channelNumber': return ({required Object number}) => 'K. ${number}';
			case 'player.playbackError': return 'Wiedergabefehler';
			case 'player.error': return 'Fehler';
			case 'player.failedToStartPlayback': return ({required Object error}) => 'Wiedergabe konnte nicht gestartet werden:\n${error}';
			case 'player.ok': return 'OK';
			case 'downloads.title': return 'Downloads';
			case 'downloads.deleteAll': return 'Alle löschen';
			case 'downloads.deleteAllTitle': return 'Alle Downloads löschen?';
			case 'downloads.deleteAllMessage': return ({required Object count, required Object size}) => 'Dies löscht alle ${count} Downloads und gibt ${size} Speicherplatz frei.';
			case 'downloads.storageUsed': return ({required Object size}) => 'Speicher belegt: ${size}';
			case 'downloads.downloading': return ({required Object count}) => 'Wird heruntergeladen (${count})';
			case 'downloads.downloaded': return ({required Object count}) => 'Heruntergeladen (${count})';
			case 'downloads.noDownloads': return 'Keine Downloads';
			case 'downloads.noDownloadsHint': return 'Laden Sie Filme und Serien herunter, um sie offline anzusehen';
			case 'downloads.deleteDownloadTitle': return 'Download löschen?';
			case 'downloads.deleteDownloadMessage': return ({required Object title}) => '"${title}" löschen?';
			case 'downloads.delete': return 'Löschen';
			case 'downloads.cancel': return 'Abbrechen';
			case 'downloads.downloadFailed': return 'Download fehlgeschlagen';
			case 'downloads.paused': return 'Pausiert';
			default: return null;
		}
	}
}

extension on _StringsIt {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'OpenFlix';
			case 'app.loading': return 'Caricamento...';
			case 'auth.signIn': return 'Accedi';
			case 'auth.signUp': return 'Registrati';
			case 'auth.signInWithPlex': return 'Accedi a OpenFlix';
			case 'auth.showQRCode': return 'Mostra QR Code';
			case 'auth.cancel': return 'Cancella';
			case 'auth.authenticate': return 'Autenticazione';
			case 'auth.retry': return 'Riprova';
			case 'auth.debugEnterToken': return 'Debug: Inserisci Token';
			case 'auth.plexTokenLabel': return 'Token Auth';
			case 'auth.plexTokenHint': return 'Inserisci il token';
			case 'auth.authenticationTimeout': return 'Autenticazione scaduta. Riprova.';
			case 'auth.scanQRCodeInstruction': return 'Scansiona questo QR code per autenticarti.';
			case 'auth.waitingForAuth': return 'In attesa di autenticazione...\nCompleta l\'accesso dal tuo browser.';
			case 'auth.serverUrl': return 'URL Server';
			case 'auth.serverUrlHint': return 'es. http://192.168.1.100:32400';
			case 'auth.username': return 'Nome utente';
			case 'auth.usernameHint': return 'Inserisci il nome utente';
			case 'auth.email': return 'Email';
			case 'auth.emailHint': return 'Inserisci la tua email';
			case 'auth.password': return 'Password';
			case 'auth.passwordHint': return 'Inserisci la password';
			case 'auth.confirmPassword': return 'Conferma Password';
			case 'auth.confirmPasswordHint': return 'Reinserisci la password';
			case 'auth.displayName': return 'Nome visualizzato';
			case 'auth.displayNameHint': return 'Nome visualizzato opzionale';
			case 'auth.noAccount': return 'Non hai un account?';
			case 'auth.haveAccount': return 'Hai già un account?';
			case 'auth.connecting': return 'Connessione al server...';
			case 'auth.loggingIn': return 'Accesso in corso...';
			case 'auth.registering': return 'Creazione account...';
			case 'auth.connectToServer': return 'Connetti al Server';
			case 'auth.changeServer': return 'Cambia Server';
			case 'auth.serverConnected': return ({required Object serverName}) => 'Connesso a ${serverName}';
			case 'auth.invalidServerUrl': return 'Inserisci un URL server valido';
			case 'auth.serverConnectionFailed': return 'Connessione al server fallita';
			case 'auth.passwordMismatch': return 'Le password non corrispondono';
			case 'auth.usernameRequired': return 'Nome utente richiesto';
			case 'auth.emailRequired': return 'Email richiesta';
			case 'auth.passwordRequired': return 'Password richiesta';
			case 'auth.passwordTooShort': return 'La password deve avere almeno 6 caratteri';
			case 'auth.invalidEmail': return 'Inserisci un indirizzo email valido';
			case 'auth.firstUserNote': return 'Il primo utente sarà l\'amministratore';
			case 'auth.howConnecting': return 'Come ti stai connettendo?';
			case 'auth.atHome': return 'A casa';
			case 'auth.atHomeDescription': return 'Rileva automaticamente il server sulla rete locale';
			case 'auth.awayFromHome': return 'Fuori casa';
			case 'auth.awayFromHomeDescription': return 'Inserisci l\'indirizzo del server manualmente';
			case 'auth.findYourServer': return 'Trova il tuo server';
			case 'auth.searching': return 'Ricerca...';
			case 'auth.checkingNetwork': return 'Controllo rete...';
			case 'auth.serversFound': return 'Server trovati';
			case 'auth.scanAgain': return 'Cerca di nuovo';
			case 'auth.enterManually': return 'Inserisci manualmente';
			case 'auth.noServersFound': return 'Nessun server trovato nella tua rete. Assicurati che il server OpenFlix sia in esecuzione.';
			case 'auth.discoveryFailed': return ({required Object error}) => 'Ricerca fallita: ${error}';
			case 'common.cancel': return 'Cancella';
			case 'common.save': return 'Salva';
			case 'common.close': return 'Chiudi';
			case 'common.clear': return 'Pulisci';
			case 'common.reset': return 'Ripristina';
			case 'common.later': return 'Più tardi';
			case 'common.submit': return 'Invia';
			case 'common.confirm': return 'Conferma';
			case 'common.retry': return 'Riprova';
			case 'common.playNow': return 'Riproduci ora';
			case 'common.logout': return 'Disconnetti';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Di proprietà';
			case 'common.shared': return 'Condiviso';
			case 'common.current': return 'CORRENTE';
			case 'common.unknown': return 'Sconosciuto';
			case 'common.refresh': return 'Aggiorna';
			case 'common.yes': return 'Sì';
			case 'common.no': return 'No';
			case 'common.server': return 'Server';
			case 'common.delete': return 'Elimina';
			case 'common.shuffle': return 'Casuale';
			case 'common.addTo': return 'Aggiungi a...';
			case 'common.remove': return 'Remove';
			case 'common.play': return 'Play';
			case 'common.details': return 'Details';
			case 'common.seeAll': return 'See All';
			case 'common.live': return 'LIVE';
			case 'common.newLabel': return 'NUOVO';
			case 'screens.licenses': return 'Licenze';
			case 'screens.selectServer': return 'Seleziona server';
			case 'screens.switchProfile': return 'Cambia profilo';
			case 'screens.subtitleStyling': return 'Stile sottotitoli';
			case 'screens.search': return 'Cerca';
			case 'screens.logs': return 'Registro';
			case 'update.available': return 'Aggiornamento disponibile';
			case 'update.versionAvailable': return ({required Object version}) => 'Versione ${version} disponibile';
			case 'update.currentVersion': return ({required Object version}) => 'Corrente: ${version}';
			case 'update.skipVersion': return 'Salta questa versione';
			case 'update.viewRelease': return 'Visualizza dettagli release';
			case 'update.latestVersion': return 'La versione installata è l\'ultima disponibile';
			case 'update.checkFailed': return 'Impossibile controllare gli aggiornamenti';
			case 'settings.title': return 'Impostazioni';
			case 'settings.profile': return 'Profilo';
			case 'settings.noProfileSelected': return 'Nessun profilo selezionato';
			case 'settings.kidsMode': return 'Modalità bambini';
			case 'settings.switchProfile': return 'Cambia profilo';
			case 'settings.switchProfileDescription': return 'Passa a un altro profilo';
			case 'settings.manageProfiles': return 'Gestisci profili';
			case 'settings.manageProfilesDescription': return 'Aggiungi, modifica o elimina profili';
			case 'settings.language': return 'Lingua';
			case 'settings.theme': return 'Tema';
			case 'settings.appearance': return 'Aspetto';
			case 'settings.videoPlayback': return 'Riproduzione video';
			case 'settings.shufflePlay': return 'Riproduzione casuale';
			case 'settings.advanced': return 'Avanzate';
			case 'settings.useSeasonPostersDescription': return 'Mostra il poster della stagione invece del poster della serie per gli episodi';
			case 'settings.showHeroSectionDescription': return 'Visualizza il carosello dei contenuti in primo piano sulla schermata iniziale';
			case 'settings.secondsLabel': return 'Secondi';
			case 'settings.minutesLabel': return 'Minuti';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Inserisci durata (${min}-${max})';
			case 'settings.systemTheme': return 'Sistema';
			case 'settings.systemThemeDescription': return 'Segui le impostazioni di sistema';
			case 'settings.lightTheme': return 'Chiaro';
			case 'settings.darkTheme': return 'Scuro';
			case 'settings.libraryDensity': return 'Densità libreria';
			case 'settings.compact': return 'Compatta';
			case 'settings.compactDescription': return 'Schede più piccole, più elementi visibili';
			case 'settings.normal': return 'Normale';
			case 'settings.normalDescription': return 'Dimensione predefinita';
			case 'settings.comfortable': return 'Comoda';
			case 'settings.comfortableDescription': return 'Schede più grandi, meno elementi visibili';
			case 'settings.viewMode': return 'Modalità di visualizzazione';
			case 'settings.gridView': return 'Griglia';
			case 'settings.gridViewDescription': return 'Visualizza gli elementi in un layout a griglia';
			case 'settings.listView': return 'Elenco';
			case 'settings.listViewDescription': return 'Visualizza gli elementi in un layout a elenco';
			case 'settings.useSeasonPosters': return 'Usa poster delle stagioni';
			case 'settings.showHeroSection': return 'Mostra sezione principale';
			case 'settings.hardwareDecoding': return 'Decodifica Hardware';
			case 'settings.hardwareDecodingDescription': return 'Utilizza l\'accelerazione hardware quando disponibile';
			case 'settings.bufferSize': return 'Dimensione buffer';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Stile sottotitoli';
			case 'settings.subtitleStylingDescription': return 'Personalizza l\'aspetto dei sottotitoli';
			case 'settings.smallSkipDuration': return 'Durata skip breve';
			case 'settings.largeSkipDuration': return 'Durata skip lungo';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} secondi';
			case 'settings.defaultSleepTimer': return 'Timer spegnimento predefinito';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} minuti';
			case 'settings.rememberTrackSelections': return 'Ricorda selezioni tracce per serie/film';
			case 'settings.rememberTrackSelectionsDescription': return 'Salva automaticamente le preferenze delle lingue audio e sottotitoli quando cambi tracce durante la riproduzione';
			case 'settings.unwatchedOnly': return 'Solo non guardati';
			case 'settings.unwatchedOnlyDescription': return 'Includi solo gli episodi non guardati nella coda di riproduzione casuale';
			case 'settings.shuffleOrderNavigation': return 'Navigazione in ordine casuale';
			case 'settings.shuffleOrderNavigationDescription': return 'I pulsanti Avanti/Indietro seguono l\'ordine casuale';
			case 'settings.loopShuffleQueue': return 'Coda di riproduzione casuale in loop';
			case 'settings.loopShuffleQueueDescription': return 'Riavvia la coda quando raggiungi la fine';
			case 'settings.videoPlayerControls': return 'Controlli del lettore video';
			case 'settings.keyboardShortcuts': return 'Scorciatoie da tastiera';
			case 'settings.keyboardShortcutsDescription': return 'Personalizza le scorciatoie da tastiera';
			case 'settings.debugLogging': return 'Log di debug';
			case 'settings.debugLoggingDescription': return 'Abilita il logging dettagliato per la risoluzione dei problemi';
			case 'settings.viewLogs': return 'Visualizza log';
			case 'settings.viewLogsDescription': return 'Visualizza i log dell\'applicazione';
			case 'settings.clearCache': return 'Svuota cache';
			case 'settings.clearCacheDescription': return 'Questa opzione cancellerà tutte le immagini e i dati memorizzati nella cache. Dopo aver cancellato la cache, l\'app potrebbe impiegare più tempo per caricare i contenuti.';
			case 'settings.clearCacheSuccess': return 'Cache cancellata correttamente';
			case 'settings.resetSettings': return 'Ripristina impostazioni';
			case 'settings.resetSettingsDescription': return 'Questa opzione ripristinerà tutte le impostazioni ai valori predefiniti. Non può essere annullata.';
			case 'settings.resetSettingsSuccess': return 'Impostazioni ripristinate correttamente';
			case 'settings.shortcutsReset': return 'Scorciatoie ripristinate alle impostazioni predefinite';
			case 'settings.about': return 'Informazioni';
			case 'settings.aboutDescription': return 'Informazioni sull\'app e le licenze';
			case 'settings.updates': return 'Aggiornamenti';
			case 'settings.updateAvailable': return 'Aggiornamento disponibile';
			case 'settings.checkForUpdates': return 'Controlla aggiornamenti';
			case 'settings.validationErrorEnterNumber': return 'Inserisci un numero valido';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'la durata deve essere compresa tra ${min} e ${max} ${unit}';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Scorciatoia già assegnata a ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Scorciatoia aggiornata per ${action}';
			case 'settings.autoSkip': return 'Salto Automatico';
			case 'settings.autoSkipIntro': return 'Salta Intro Automaticamente';
			case 'settings.autoSkipIntroDescription': return 'Salta automaticamente i marcatori dell\'intro dopo alcuni secondi';
			case 'settings.autoSkipCredits': return 'Salta Crediti Automaticamente';
			case 'settings.autoSkipCreditsDescription': return 'Salta automaticamente i crediti e riproduci l\'episodio successivo';
			case 'settings.autoSkipDelay': return 'Ritardo Salto Automatico';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => 'Aspetta ${seconds} secondi prima del salto automatico';
			case 'settings.metadataSection': return 'Metadati';
			case 'settings.tmdbApiKey': return 'Chiave API TMDB';
			case 'settings.tmdbApiKeyDescription': return 'Configura TMDB per metadati avanzati';
			case 'settings.tmdbApiKeyConfigured': return 'Chiave API configurata';
			case 'settings.tmdbApiKeyHint': return 'Ottieni la tua chiave API da themoviedb.org';
			case 'settings.tmdbApiKeyPlaceholder': return 'Inserisci la chiave API TMDB';
			case 'settings.apiKey': return 'Chiave API';
			case 'settings.tmdbApiKeySaved': return 'Chiave API TMDB salvata';
			case 'settings.tmdbApiKeyCleared': return 'Chiave API TMDB eliminata';
			case 'settings.parentalControls': return 'Controllo Genitori';
			case 'settings.enableParentalControls': return 'Abilita Controllo Genitori';
			case 'settings.enableParentalControlsDescription': return 'Limita i contenuti in base alle classificazioni per età';
			case 'settings.setPin': return 'Imposta PIN';
			case 'settings.setPinDescription': return 'Inserisci un PIN a 4 cifre per proteggere le impostazioni';
			case 'settings.confirmPin': return 'Conferma PIN';
			case 'settings.confirmPinDescription': return 'Inserisci nuovamente il PIN per confermare';
			case 'settings.enterPin': return 'Inserisci PIN';
			case 'settings.enterPinDescription': return 'Inserisci il tuo PIN di controllo genitori';
			case 'settings.changePin': return 'Cambia PIN';
			case 'settings.changePinDescription': return 'Cambia il tuo PIN di controllo genitori';
			case 'settings.pinSet': return 'PIN di controllo genitori impostato con successo';
			case 'settings.pinMismatch': return 'I PIN non corrispondono. Riprova.';
			case 'settings.incorrectPin': return 'PIN errato. Riprova.';
			case 'settings.maxMovieRating': return 'Classificazione Film Massima';
			case 'settings.maxTvRating': return 'Classificazione TV Massima';
			case 'search.hint': return 'Cerca film, serie, musica...';
			case 'search.tryDifferentTerm': return 'Prova altri termini di ricerca';
			case 'search.searchYourMedia': return 'Cerca nei tuoi media';
			case 'search.enterTitleActorOrKeyword': return 'Inserisci un titolo, attore o parola chiave';
			case 'search.recentSearches': return 'Ricerche recenti';
			case 'search.clear': return 'Cancella';
			case 'search.voiceSearch': return 'Ricerca vocale';
			case 'search.listening': return 'In ascolto...';
			case 'search.speakNow': return 'Parla ora';
			case 'search.all': return 'Tutto';
			case 'search.movies': return 'Film';
			case 'search.tvShows': return 'Serie TV';
			case 'search.music': return 'Musica';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Imposta scorciatoia per ${actionName}';
			case 'hotkeys.clearShortcut': return 'Elimina scorciatoia';
			case 'pinEntry.enterPin': return 'Inserisci PIN';
			case 'pinEntry.showPin': return 'Mostra PIN';
			case 'pinEntry.hidePin': return 'Nascondi PIN';
			case 'fileInfo.title': return 'Info sul file';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Audio';
			case 'fileInfo.file': return 'File';
			case 'fileInfo.advanced': return 'Avanzate';
			case 'fileInfo.codec': return 'Codec';
			case 'fileInfo.resolution': return 'Risoluzione';
			case 'fileInfo.bitrate': return 'Bitrate';
			case 'fileInfo.frameRate': return 'Frame Rate';
			case 'fileInfo.aspectRatio': return 'Aspect Ratio';
			case 'fileInfo.profile': return 'Profilo';
			case 'fileInfo.bitDepth': return 'Profondità colore';
			case 'fileInfo.colorSpace': return 'Spazio colore';
			case 'fileInfo.colorRange': return 'Gamma colori';
			case 'fileInfo.colorPrimaries': return 'Colori primari';
			case 'fileInfo.chromaSubsampling': return 'Sottocampionamento cromatico';
			case 'fileInfo.channels': return 'Canali';
			case 'fileInfo.path': return 'Percorso';
			case 'fileInfo.size': return 'Dimensione';
			case 'fileInfo.container': return 'Contenitore';
			case 'fileInfo.duration': return 'Durata';
			case 'fileInfo.optimizedForStreaming': return 'Ottimizzato per lo streaming';
			case 'fileInfo.has64bitOffsets': return 'Offset a 64-bit';
			case 'mediaMenu.markAsWatched': return 'Segna come visto';
			case 'mediaMenu.markAsUnwatched': return 'Segna come non visto';
			case 'mediaMenu.removeFromContinueWatching': return 'Rimuovi da Continua a guardare';
			case 'mediaMenu.goToSeries': return 'Vai alle serie';
			case 'mediaMenu.goToSeason': return 'Vai alla stagione';
			case 'mediaMenu.shufflePlay': return 'Riproduzione casuale';
			case 'mediaMenu.fileInfo': return 'Info sul file';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, film';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, serie TV';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'visto';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} percento visto';
			case 'accessibility.mediaCardUnwatched': return 'non visto';
			case 'accessibility.tapToPlay': return 'Tocca per riprodurre';
			case 'tooltips.shufflePlay': return 'Riproduzione casuale';
			case 'tooltips.markAsWatched': return 'Segna come visto';
			case 'tooltips.markAsUnwatched': return 'Segna come non visto';
			case 'videoControls.audioLabel': return 'Audio';
			case 'videoControls.subtitlesLabel': return 'Sottotitoli';
			case 'videoControls.resetToZero': return 'Riporta a 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} riprodotto dopo';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} riprodotto prima';
			case 'videoControls.noOffset': return 'Nessun offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Riempi schermo';
			case 'videoControls.stretch': return 'Allunga';
			case 'videoControls.lockRotation': return 'Blocca rotazione';
			case 'videoControls.unlockRotation': return 'Sblocca rotazione';
			case 'videoControls.lockScreen': return 'Blocca schermo';
			case 'videoControls.unlockScreen': return 'Sblocca schermo';
			case 'videoControls.screenLockButton': return 'Blocco schermo';
			case 'videoControls.screenLocked': return 'Schermo bloccato';
			case 'videoControls.tapToUnlock': return 'Tocca per sbloccare';
			case 'videoControls.sleepTimer': return 'Timer di spegnimento';
			case 'videoControls.timerActive': return 'Timer attivo';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'La riproduzione si interromperà tra ${duration}';
			case 'videoControls.sleepTimerCompleted': return 'Timer di spegnimento completato - riproduzione in pausa';
			case 'videoControls.playButton': return 'Riproduci';
			case 'videoControls.pauseButton': return 'Pausa';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => 'Riavvolgi di ${seconds} secondi';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => 'Avanza di ${seconds} secondi';
			case 'videoControls.previousButton': return 'Episodio precedente';
			case 'videoControls.nextButton': return 'Episodio successivo';
			case 'videoControls.previousChapterButton': return 'Capitolo precedente';
			case 'videoControls.nextChapterButton': return 'Capitolo successivo';
			case 'videoControls.volumeButton': return 'Volume';
			case 'videoControls.muteButton': return 'Silenzia';
			case 'videoControls.unmuteButton': return 'Riattiva audio';
			case 'videoControls.settingsButton': return 'Impostazioni video';
			case 'videoControls.audioTrackButton': return 'Tracce audio';
			case 'videoControls.subtitlesButton': return 'Sottotitoli';
			case 'videoControls.chaptersButton': return 'Capitoli';
			case 'videoControls.versionsButton': return 'Versioni video';
			case 'videoControls.aspectRatioButton': return 'Proporzioni';
			case 'videoControls.fullscreenButton': return 'Attiva schermo intero';
			case 'videoControls.exitFullscreenButton': return 'Esci da schermo intero';
			case 'videoControls.rotationLockButton': return 'Blocco rotazione';
			case 'videoControls.timelineSlider': return 'Timeline video';
			case 'videoControls.volumeSlider': return 'Livello volume';
			case 'videoControls.backButton': return 'Indietro';
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Limitato';
			case 'userStatus.protected': return 'Protetto';
			case 'userStatus.current': return 'ATTUALE';
			case 'messages.markedAsWatched': return 'Segna come visto';
			case 'messages.markedAsUnwatched': return 'Segna come non visto';
			case 'messages.removedFromContinueWatching': return 'Rimosso da Continua a guardare';
			case 'messages.errorLoading': return ({required Object error}) => 'Errore: ${error}';
			case 'messages.fileInfoNotAvailable': return 'Informazioni sul file non disponibili';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Errore caricamento informazioni sul file: ${error}';
			case 'messages.errorLoadingSeries': return 'Errore caricamento serie';
			case 'messages.errorLoadingSeason': return 'Errore caricamento stagione';
			case 'messages.musicNotSupported': return 'La riproduzione musicale non è ancora supportata';
			case 'messages.logsCleared': return 'Log eliminati';
			case 'messages.logsCopied': return 'Log copiati negli appunti';
			case 'messages.noLogsAvailable': return 'Nessun log disponibile';
			case 'messages.libraryScanning': return ({required Object title}) => 'Scansione "${title}"...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Scansione libreria iniziata per "${title}"';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Impossibile eseguire scansione della libreria: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Aggiornamento metadati per "${title}"...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Aggiornamento metadati per "${title}"';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Errore aggiornamento metadati: ${error}';
			case 'messages.noTokenFound': return 'Nessun token trovato. Riesegui l\'accesso.';
			case 'messages.logoutConfirm': return 'Sei sicuro di volerti disconnettere?';
			case 'messages.noSeasonsFound': return 'Nessuna stagione trovata';
			case 'messages.noEpisodesFound': return 'Nessun episodio trovato nella prima stagione';
			case 'messages.noEpisodesFoundGeneral': return 'Nessun episodio trovato';
			case 'messages.noResultsFound': return 'Nessun risultato';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Imposta timer spegnimento per ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Impossibile passare a ${displayName}';
			case 'messages.noItemsAvailable': return 'Nessun elemento disponibile';
			case 'messages.failedToCreatePlayQueue': return 'Impossibile creare la coda di riproduzione';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Impossibile creare la coda di riproduzione - nessun elemento';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Impossibile ${action}: ${error}';
			case 'profile.noUsersAvailable': return 'Nessun utente disponibile';
			case 'subtitlingStyling.stylingOptions': return 'Opzioni stile';
			case 'subtitlingStyling.fontSize': return 'Dimensione';
			case 'subtitlingStyling.textColor': return 'Colore testo';
			case 'subtitlingStyling.borderSize': return 'Dimensione bordo';
			case 'subtitlingStyling.borderColor': return 'Colore bordo';
			case 'subtitlingStyling.backgroundOpacity': return 'Opacità sfondo';
			case 'subtitlingStyling.backgroundColor': return 'Colore sfondo';
			case 'dialog.confirmAction': return 'Conferma azione';
			case 'dialog.areYouSure': return 'Sei sicuro di voler eseguire questa azione?';
			case 'dialog.cancel': return 'Cancella';
			case 'dialog.playNow': return 'Riproduci ora';
			case 'discover.title': return 'Esplora';
			case 'discover.switchProfile': return 'Cambia profilo';
			case 'discover.switchServer': return 'Cambia server';
			case 'discover.logout': return 'Disconnetti';
			case 'discover.noContentAvailable': return 'Nessun contenuto disponibile';
			case 'discover.addMediaToLibraries': return 'Aggiungi alcuni file multimediali alle tue librerie';
			case 'discover.continueWatching': return 'Continua a guardare';
			case 'discover.recentlyAdded': return 'Aggiunti di recente';
			case 'discover.play': return 'Riproduci';
			case 'discover.resume': return 'Riprendi';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Riproduci S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Riprendi S${season}, E${episode}';
			case 'discover.pause': return 'Pausa';
			case 'discover.overview': return 'Panoramica';
			case 'discover.cast': return 'Attori';
			case 'discover.seasons': return 'Stagioni';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Classificazione';
			case 'discover.watched': return 'Guardato';
			case 'discover.episodeCount': return ({required Object count}) => '${count} episodi';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} guardati';
			case 'discover.movie': return 'Film';
			case 'discover.tvShow': return 'Serie TV';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} minuti rimanenti';
			case 'discover.whatsOnNow': return 'In onda ora';
			case 'discover.channelGuide': return 'Guida TV';
			case 'discover.liveNow': return 'In diretta';
			case 'discover.topTen': return 'Top 10';
			case 'discover.newBadge': return 'NUOVO';
			case 'discover.liveBadge': return 'LIVE';
			case 'discover.goodMorning': return 'Good morning';
			case 'discover.goodAfternoon': return 'Good afternoon';
			case 'discover.goodEvening': return 'Good evening';
			case 'discover.defaultUser': return 'Guest';
			case 'discover.yourNextWatch': return 'Your Next Watch';
			case 'discover.pickedForYou': return ({required Object name}) => 'Picked just for you, ${name}';
			case 'discover.surpriseMe': return 'Surprise Me';
			case 'discover.randomPicker': return 'Random Movie Picker';
			case 'discover.noMoviesFound': return 'No movies found in your library';
			case 'discover.spinning': return 'Picking something great...';
			case 'discover.spinAgain': return 'Spin Again';
			case 'discover.calendar': return 'Calendar';
			case 'discover.today': return 'Today';
			case 'discover.item': return 'item';
			case 'discover.items': return 'items';
			case 'discover.loadingMovies': return 'Caricamento dei tuoi film...';
			case 'discover.noContentOnDate': return 'No content added on this date';
			case 'discover.noEpgData': return 'Nessuna informazione programma';
			case 'errors.searchFailed': return ({required Object error}) => 'Ricerca fallita: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Timeout connessione durante caricamento di ${context}';
			case 'errors.connectionFailed': return 'Impossibile connettersi al server Plex.';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Impossibile caricare ${context}: ${error}';
			case 'errors.noClientAvailable': return 'Nessun client disponibile';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Autenticazione fallita: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Impossibile avviare URL di autenticazione';
			case 'errors.pleaseEnterToken': return 'Inserisci token';
			case 'errors.invalidToken': return 'Token non valido';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Verifica token fallita: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Impossibile passare a ${displayName}';
			case 'errors.connectionFailedGeneric': return 'Connessione fallita';
			case 'errors.failedToRemove': return ({required Object error}) => 'Rimozione fallita: ${error}';
			case 'voice.notAvailable': return 'Il controllo vocale non è disponibile';
			case 'voice.commandNotRecognized': return ({required Object command}) => 'Comando non riconosciuto: "${command}"';
			case 'libraries.title': return 'Librerie';
			case 'libraries.scanLibraryFiles': return 'Scansiona file libreria';
			case 'libraries.scanLibrary': return 'Scansiona libreria';
			case 'libraries.analyze': return 'Analizza';
			case 'libraries.analyzeLibrary': return 'Analizza libreria';
			case 'libraries.refreshMetadata': return 'Aggiorna metadati';
			case 'libraries.emptyTrash': return 'Svuota cestino';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Svuotamento cestino per "${title}"...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Cestino svuotato per "${title}"';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Impossibile svuotare cestino: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analisi "${title}"...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analisi iniziata per "${title}"';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Impossibile analizzare libreria: ${error}';
			case 'libraries.noLibrariesFound': return 'Nessuna libreria trovata';
			case 'libraries.thisLibraryIsEmpty': return 'Questa libreria è vuota';
			case 'libraries.all': return 'Tutto';
			case 'libraries.clearAll': return 'Cancella tutto';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => 'Sei sicuro di voler scansionare "${title}"?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => 'Sei sicuro di voler analizzare "${title}"?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Sei sicuro di voler aggiornare i metadati per "${title}"?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Sei sicuro di voler svuotare il cestino per "${title}"?';
			case 'libraries.manageLibraries': return 'Gestisci librerie';
			case 'libraries.sort': return 'Ordina';
			case 'libraries.sortBy': return 'Ordina per';
			case 'libraries.filters': return 'Filtri';
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Caricamento librerie... (${count} oggetti caricati)';
			case 'libraries.confirmActionMessage': return 'Sei sicuro di voler eseguire questa azione?';
			case 'libraries.showLibrary': return 'Mostra libreria';
			case 'libraries.hideLibrary': return 'Nascondi libreria';
			case 'libraries.libraryOptions': return 'Opzioni libreria';
			case 'libraries.content': return 'contenuto della libreria';
			case 'libraries.selectLibrary': return 'Seleziona libreria';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filtri (${count})';
			case 'libraries.noRecommendations': return 'Nessun consiglio disponibile';
			case 'libraries.noCollections': return 'Nessuna raccolta in questa libreria';
			case 'libraries.noFoldersFound': return 'Nessuna cartella trovata';
			case 'libraries.folders': return 'cartelle';
			case 'libraries.tabs.recommended': return 'Consigliati';
			case 'libraries.tabs.browse': return 'Esplora';
			case 'libraries.tabs.collections': return 'Raccolte';
			case 'libraries.tabs.playlists': return 'Playlist';
			case 'libraries.groupings.all': return 'Tutti';
			case 'libraries.groupings.movies': return 'Film';
			case 'libraries.groupings.shows': return 'Serie TV';
			case 'libraries.groupings.seasons': return 'Stagioni';
			case 'libraries.groupings.episodes': return 'Episodi';
			case 'libraries.groupings.folders': return 'Cartelle';
			case 'about.title': return 'Informazioni';
			case 'about.openSourceLicenses': return 'Licenze Open Source';
			case 'about.versionLabel': return ({required Object version}) => 'Versione ${version}';
			case 'about.appDescription': return 'Un bellissimo client Plex per Flutter';
			case 'about.viewLicensesDescription': return 'Visualizza le licenze delle librerie di terze parti';
			case 'serverSelection.connectingToServer': return 'Connessione al server...';
			case 'serverSelection.connectingToAllServers': return 'Connessione a tutti i server...';
			case 'serverSelection.connectToAllServers': return 'Connetti a tutti i server';
			case 'serverSelection.allServerConnectionsFailed': return 'Impossibile connettersi a nessun server. Controlla la tua rete e riprova.';
			case 'serverSelection.foundServers': return ({required Object count}) => 'Trovati ${count} server';
			case 'serverSelection.orSelectIndividually': return 'Oppure seleziona un server singolarmente:';
			case 'serverSelection.serverDebugCopied': return 'Dati di debug del server copiati negli appunti';
			case 'serverSelection.copyDebugData': return 'Copia dati di debug';
			case 'serverSelection.noServersFound': return 'Nessun server trovato';
			case 'serverSelection.malformedServerData': return ({required Object count}) => 'Trovato ${count} server con dati difettosi. Nessun server valido disponibile.';
			case 'serverSelection.incompleteServerInfo': return 'Alcuni server presentano informazioni incomplete e sono stati ignorati. Controlla il tuo account Plex.tv.';
			case 'serverSelection.incompleteConnectionInfo': return 'Le informazioni di connessione al server sono incomplete. Riprova.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Le informazioni sul server sono errate: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Connessione di rete non riuscita. Controlla la tua connessione Internet e riprova.';
			case 'serverSelection.authenticationFailed': return 'Autenticazione fallita. Effettua nuovamente l\'accesso.';
			case 'serverSelection.plexServiceUnavailable': return 'Servizio Plex non disponibile. Riprova più tardi.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Impossibile caricare i server: ${error}';
			case 'hubDetail.title': return 'Titolo';
			case 'hubDetail.releaseYear': return 'Anno rilascio';
			case 'hubDetail.dateAdded': return 'Data aggiunta';
			case 'hubDetail.rating': return 'Valutazione';
			case 'hubDetail.noItemsFound': return 'Nessun elemento trovato';
			case 'logs.title': return 'Registro';
			case 'logs.clearLogs': return 'Cancella log';
			case 'logs.copyLogs': return 'Copia log';
			case 'logs.exportLogs': return 'Esporta log';
			case 'logs.noLogsToShow': return 'Nessun log da mostrare';
			case 'logs.error': return 'Errore:';
			case 'logs.stackTrace': return 'Traccia dello stack:';
			case 'stats.title': return 'Statistiche di Visione';
			case 'stats.totalWatchTime': return 'Tempo di Visione Totale';
			case 'stats.moviesWatched': return 'Film Visti';
			case 'stats.episodesWatched': return 'Episodi Visti';
			case 'stats.avgPerDay': return 'Media al Giorno';
			case 'stats.topGenres': return 'Generi Preferiti';
			case 'stats.monthlyActivity': return 'Attività Mensile';
			case 'stats.noData': return 'Nessuna cronologia di visione';
			case 'stats.startWatching': return 'Inizia a guardare per vedere le tue statistiche';
			case 'stats.days': return 'giorni';
			case 'licenses.relatedPackages': return 'Pacchetti correlati';
			case 'licenses.license': return 'Licenza';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Licenza ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenze';
			case 'navigation.home': return 'Home';
			case 'navigation.search': return 'Cerca';
			case 'navigation.libraries': return 'Librerie';
			case 'navigation.livetv': return 'Live TV';
			case 'navigation.settings': return 'Impostazioni';
			case 'playlists.title': return 'Playlist';
			case 'playlists.noPlaylists': return 'Nessuna playlist trovata';
			case 'playlists.create': return 'Crea playlist';
			case 'playlists.newPlaylist': return 'Nuova playlist';
			case 'playlists.playlistName': return 'Nome playlist';
			case 'playlists.enterPlaylistName': return 'Inserisci nome playlist';
			case 'playlists.edit': return 'Modifica playlist';
			case 'playlists.delete': return 'Elimina playlist';
			case 'playlists.addTo': return 'Aggiungi a playlist';
			case 'playlists.addItems': return 'Aggiungi elementi';
			case 'playlists.removeItem': return 'Rimuovi da playlist';
			case 'playlists.clearPlaylist': return 'Svuota playlist';
			case 'playlists.playAll': return 'Riproduci tutto';
			case 'playlists.shuffle': return 'Casuale';
			case 'playlists.smartPlaylist': return 'Playlist intelligente';
			case 'playlists.regularPlaylist': return 'Playlist normale';
			case 'playlists.itemCount': return ({required Object count}) => '${count} elementi';
			case 'playlists.oneItem': return '1 elemento';
			case 'playlists.emptyPlaylist': return 'Questa playlist è vuota';
			case 'playlists.deleteConfirm': return 'Eliminare playlist?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Sei sicuro di voler eliminare "${name}"?';
			case 'playlists.created': return 'Playlist creata';
			case 'playlists.updated': return 'Playlist aggiornata';
			case 'playlists.deleted': return 'Playlist eliminata';
			case 'playlists.itemAdded': return 'Aggiunto alla playlist';
			case 'playlists.itemRemoved': return 'Rimosso dalla playlist';
			case 'playlists.selectPlaylist': return 'Seleziona playlist';
			case 'playlists.createNewPlaylist': return 'Crea nuova playlist';
			case 'playlists.errorCreating': return 'Errore durante la creazione della playlist';
			case 'playlists.errorDeleting': return 'Errore durante l\'eliminazione della playlist';
			case 'playlists.errorLoading': return 'Errore durante il caricamento delle playlist';
			case 'playlists.errorAdding': return 'Errore durante l\'aggiunta alla playlist';
			case 'playlists.errorReordering': return 'Errore durante il riordino dell\'elemento della playlist';
			case 'playlists.errorRemoving': return 'Errore durante la rimozione dalla playlist';
			case 'playlists.playlist': return 'Playlist';
			case 'collections.title': return 'Raccolte';
			case 'collections.collection': return 'Raccolta';
			case 'collections.empty': return 'La raccolta è vuota';
			case 'collections.noItems': return 'Nessun elemento in questa raccolta';
			case 'collections.unknownLibrarySection': return 'Impossibile eliminare: sezione libreria sconosciuta';
			case 'collections.deleteCollection': return 'Elimina raccolta';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Sei sicuro di voler eliminare "${title}"? Questa azione non può essere annullata.';
			case 'collections.deleted': return 'Raccolta eliminata';
			case 'collections.deleteFailed': return 'Impossibile eliminare la raccolta';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Impossibile eliminare la raccolta: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Impossibile caricare gli elementi della raccolta: ${error}';
			case 'collections.addTo': return 'Aggiungi alla raccolta';
			case 'collections.selectCollection': return 'Seleziona raccolta';
			case 'collections.createNewCollection': return 'Crea nuova raccolta';
			case 'collections.collectionName': return 'Nome raccolta';
			case 'collections.enterCollectionName': return 'Inserisci nome raccolta';
			case 'collections.addedToCollection': return 'Aggiunto alla raccolta';
			case 'collections.errorAddingToCollection': return 'Errore nell\'aggiunta alla raccolta';
			case 'collections.created': return 'Raccolta creata';
			case 'collections.removeFromCollection': return 'Rimuovi dalla raccolta';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => 'Rimuovere "${title}" da questa raccolta?';
			case 'collections.removedFromCollection': return 'Rimosso dalla raccolta';
			case 'collections.removeFromCollectionFailed': return 'Impossibile rimuovere dalla raccolta';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Errore durante la rimozione dalla raccolta: ${error}';
			case 'watchParty.title': return 'Watch Party';
			case 'watchParty.startParty': return 'Avvia Watch Party';
			case 'watchParty.joinParty': return 'Unisciti alla Party';
			case 'watchParty.enterCode': return 'Inserisci codice party';
			case 'watchParty.shareCode': return 'Condividi questo codice';
			case 'watchParty.friendsCanJoin': return 'Gli amici possono unirsi usando questo codice';
			case 'watchParty.participants': return 'Partecipanti';
			case 'watchParty.host': return 'Host';
			case 'watchParty.endParty': return 'Termina Party';
			case 'watchParty.leaveParty': return 'Lascia Party';
			case 'watchParty.partyEnded': return 'Watch Party terminata';
			case 'watchParty.chat': return 'Chat';
			case 'watchParty.typeMessage': return 'Scrivi un messaggio...';
			case 'watchParty.joined': return ({required Object name}) => '${name} si è unito';
			case 'watchParty.left': return ({required Object name}) => '${name} ha lasciato';
			case 'watchParty.syncedPlayback': return 'Riproduzione sincronizzata con la party';
			case 'watchParty.hostControls': return 'Solo l\'host può controllare la riproduzione';
			case 'watchParty.creating': return 'Creazione party...';
			case 'watchParty.joining': return 'Accesso alla party...';
			case 'watchParty.createFailed': return 'Creazione party fallita';
			case 'watchParty.joinFailed': return 'Accesso alla party fallito';
			case 'watchParty.invalidCode': return 'Codice party non valido';
			case 'watchParty.gotIt': return 'Capito';
			case 'catchUp.title': return 'Catch Up TV';
			case 'catchUp.startOver': return 'Ricomincia';
			case 'catchUp.startOverDescription': return 'Guarda dall\'inizio';
			case 'catchUp.watchFromBeginning': return 'Guardare dall\'inizio?';
			case 'catchUp.alreadyStarted': return ({required Object title}) => '"${title}" è già iniziato. Puoi guardare dall\'inizio.';
			case 'catchUp.watchLive': return 'Guarda in diretta';
			case 'catchUp.programsAvailable': return 'Programmi disponibili';
			case 'catchUp.noProgramsAvailable': return 'Nessun programma catch-up disponibile';
			case 'catchUp.programsWillAppear': return 'I programmi appariranno qui man mano che vengono trasmessi';
			case 'catchUp.unavailable': return 'Non disponibile';
			case 'catchUp.bufferNotReady': return 'Buffer non ancora pronto';
			case 'catchUp.rewind': return 'Riavvolgi';
			case 'catchUp.timeshiftEnabled': return 'Time-shift abilitato';
			case 'catchUp.goBackTo': return ({required Object time}) => 'Torna a ${time}';
			case 'watchlist.title': return 'La mia lista';
			case 'watchlist.all': return 'Tutti';
			case 'watchlist.movies': return 'Film';
			case 'watchlist.shows': return 'Serie TV';
			case 'watchlist.episodes': return 'Episodi';
			case 'watchlist.empty': return 'La tua lista è vuota';
			case 'watchlist.emptyHint': return 'Aggiungi film e serie alla tua lista dalle loro pagine';
			case 'watchlist.noItemsFiltered': return 'Nessun elemento corrisponde a questo filtro';
			case 'watchlist.removeTitle': return 'Rimuovi dalla lista';
			case 'watchlist.removeConfirm': return ({required Object title}) => 'Rimuovere "${title}" dalla tua lista?';
			case 'watchlist.remove': return 'Remove';
			case 'watchlist.play': return 'Play';
			case 'watchlist.details': return 'Details';
			case 'watchlist.seeAll': return 'See All';
			case 'watchlist.clearAllTitle': return 'Svuota lista';
			case 'watchlist.clearAllConfirm': return ({required Object count}) => 'Rimuovere tutti i ${count} elementi dalla tua lista?';
			case 'watchlist.clearAll': return 'Svuota tutto';
			case 'watchlist.addedToday': return 'Aggiunto oggi';
			case 'watchlist.addedYesterday': return 'Aggiunto ieri';
			case 'watchlist.addedDaysAgo': return ({required Object days}) => 'Aggiunto ${days} giorni fa';
			case 'watchlist.addedOn': return ({required Object date}) => 'Aggiunto il ${date}';
			case 'watchlist.addToWatchlist': return 'Aggiungi alla lista';
			case 'watchlist.removeFromWatchlist': return 'Rimuovi dalla lista';
			case 'watchlist.addedToWatchlist': return 'Aggiunto alla lista';
			case 'watchlist.removedFromWatchlist': return 'Rimosso dalla lista';
			case 'liveTV.title': return 'TV in diretta';
			case 'liveTV.guide': return 'Guida';
			case 'liveTV.dvr': return 'DVR';
			case 'liveTV.multiview': return 'Multiview';
			case 'liveTV.allChannels': return 'Tutti i canali';
			case 'liveTV.favorites': return 'Preferiti';
			case 'liveTV.noChannels': return 'Nessun canale disponibile';
			case 'liveTV.addM3USource': return 'Aggiungi una sorgente M3U nelle impostazioni del server';
			case 'liveTV.recording': return 'Registrazione';
			case 'liveTV.recordingNow': return 'In registrazione ora';
			case 'liveTV.upNext': return 'Prossimamente';
			case 'liveTV.noProgram': return 'Nessuna info programma';
			case 'liveTV.filterByGroup': return 'Filtra per gruppo';
			case 'liveTV.refresh': return 'Aggiorna';
			case 'liveTV.channelCount': return ({required Object count}) => '${count} canali';
			case 'liveTV.nowPlaying': return 'In onda ora';
			case 'liveTV.scheduleRecording': return 'Programma registrazione';
			case 'liveTV.onNow': return 'In onda adesso';
			case 'liveTV.endsAt': return ({required Object time}) => 'Finisce alle ${time}';
			case 'liveTV.startsAt': return ({required Object time}) => 'Inizia alle ${time}';
			case 'liveTV.playbackError': return ({required Object error}) => 'Errore di riproduzione: ${error}';
			case 'liveTV.noPreviousChannel': return 'Nessun canale precedente';
			case 'liveTV.switchedTo': return ({required Object channel}) => 'Passato a: ${channel}';
			case 'liveTV.startingFromBeginning': return 'Avvio del programma dall\'inizio...';
			case 'liveTV.failedToStartOver': return ({required Object error}) => 'Impossibile riavviare: ${error}';
			case 'liveTV.playingProgram': return ({required Object title}) => 'In riproduzione: ${title}';
			case 'liveTV.failedToPlayProgram': return ({required Object error}) => 'Impossibile riprodurre il programma: ${error}';
			case 'liveTV.addedToFavorites': return 'Aggiunto ai preferiti';
			case 'liveTV.removedFromFavorites': return 'Rimosso dai preferiti';
			case 'liveTV.failedToUpdateFavorite': return ({required Object error}) => 'Impossibile aggiornare preferito: ${error}';
			case 'liveTV.pipNotSupported': return 'Picture-in-Picture non supportato su questa piattaforma';
			case 'liveTV.enteredPipMode': return 'Modalità Picture-in-Picture attivata';
			case 'liveTV.exitedPipMode': return 'Modalità Picture-in-Picture disattivata';
			case 'liveTV.aspectRatioChanged': return ({required Object mode}) => 'Rapporto aspetto: ${mode}';
			case 'liveTV.tune': return 'Sintonizza';
			case 'liveTV.retry': return 'Riprova';
			case 'liveTV.noChannelsMatchFilter': return 'Nessun canale corrisponde al filtro';
			case 'liveTV.skipCommercial': return 'Salta pubblicità';
			case 'dvr.title': return 'DVR';
			case 'dvr.recordings': return 'Registrazioni';
			case 'dvr.seriesRules': return 'Regole serie';
			case 'dvr.noRecordings': return 'Nessuna registrazione';
			case 'dvr.noRules': return 'Nessuna regola serie';
			case 'dvr.scheduleFromGuide': return 'Programma registrazioni dalla guida TV';
			case 'dvr.createRulesHint': return 'Crea regole per registrare serie automaticamente';
			case 'dvr.storage': return 'Spazio di archiviazione';
			case 'dvr.recordingsCount': return ({required Object count}) => '${count} registrazioni';
			case 'dvr.all': return 'Tutte';
			case 'dvr.scheduled': return 'Programmate';
			case 'dvr.completed': return 'Completate';
			case 'dvr.failed': return 'Non riuscite';
			case 'dvr.deleteRecording': return 'Eliminare registrazione?';
			case 'dvr.deleteRule': return 'Eliminare regola serie?';
			case 'dvr.sortByDate': return 'Data';
			case 'dvr.sortByTitle': return 'Titolo';
			case 'dvr.sortBySize': return 'Dimensione';
			case 'dvr.playRecording': return 'Riproduci registrazione';
			case 'dvr.keepPolicy': return ({required Object count}) => 'Mantieni ${count} episodi';
			case 'dvr.keepAll': return 'Mantieni tutti';
			case 'dvr.recordingScheduled': return 'Registrazione programmata';
			case 'dvr.scheduleRecordingTitle': return 'Programma registrazione';
			case 'dvr.schedule': return 'Programma';
			case 'dvr.cancel': return 'Annulla';
			case 'epg.title': return 'Guida TV';
			case 'epg.now': return 'Adesso';
			case 'epg.today': return 'Oggi';
			case 'epg.tomorrow': return 'Domani';
			case 'epg.noPrograms': return 'Nessun programma disponibile';
			case 'epg.loading': return 'Caricamento guida...';
			case 'epg.record': return 'Registra';
			case 'epg.reminder': return 'Imposta promemoria';
			case 'epg.moreInfo': return 'Altre info';
			case 'epg.toggleView': return 'Cambia vista';
			case 'epg.gridView': return 'Vista a griglia';
			case 'epg.nowNextView': return 'Vista ora/prossimo';
			case 'channelSurfing.title': return 'Zapping casuale';
			case 'channelSurfing.kidsMode': return 'Modalità bambini';
			case 'channelSurfing.loading': return 'Caricamento zapping casuale...';
			case 'channelSurfing.failedToLoad': return 'Impossibile caricare il contenuto';
			case 'channelSurfing.retry': return 'Riprova';
			case 'channelSurfing.noContent': return 'Nessun contenuto disponibile';
			case 'channelSurfing.itemsAvailable': return ({required Object count}) => '${count} elementi disponibili';
			case 'channelSurfing.startSurfing': return 'Inizia';
			case 'channelSurfing.pressBackToExit': return 'Premi indietro per uscire';
			case 'channelSurfing.description': return 'Guarda film e serie casuali in modo continuo';
			case 'channelSurfing.noServers': return 'Nessun server disponibile';
			case 'multiview.title': return 'Multi-Vista';
			case 'multiview.changeLayout': return 'Cambia layout (L)';
			case 'multiview.addChannel': return 'Aggiungi canale (A)';
			case 'multiview.removeChannel': return 'Rimuovi canale (R)';
			case 'multiview.swapChannel': return 'Cambia canale';
			case 'multiview.toggleMute': return 'Attiva/Disattiva audio (M)';
			case 'multiview.selectChannel': return 'Seleziona canale';
			case 'multiview.searchChannels': return 'Cerca canali...';
			case 'multiview.cancel': return 'Annulla';
			case 'multiview.channelNumber': return ({required Object number}) => 'Can. ${number}';
			case 'player.playbackError': return 'Errore di riproduzione';
			case 'player.error': return 'Errore';
			case 'player.failedToStartPlayback': return ({required Object error}) => 'Impossibile avviare la riproduzione:\n${error}';
			case 'player.ok': return 'OK';
			case 'downloads.title': return 'Download';
			case 'downloads.deleteAll': return 'Elimina tutto';
			case 'downloads.deleteAllTitle': return 'Eliminare tutti i download?';
			case 'downloads.deleteAllMessage': return ({required Object count, required Object size}) => 'Questo eliminerà tutti i ${count} download e libererà ${size} di spazio.';
			case 'downloads.storageUsed': return ({required Object size}) => 'Spazio utilizzato: ${size}';
			case 'downloads.downloading': return ({required Object count}) => 'In download (${count})';
			case 'downloads.downloaded': return ({required Object count}) => 'Scaricati (${count})';
			case 'downloads.noDownloads': return 'Nessun download';
			case 'downloads.noDownloadsHint': return 'Scarica film e serie per guardarli offline';
			case 'downloads.deleteDownloadTitle': return 'Eliminare il download?';
			case 'downloads.deleteDownloadMessage': return ({required Object title}) => 'Eliminare "${title}"?';
			case 'downloads.delete': return 'Elimina';
			case 'downloads.cancel': return 'Annulla';
			case 'downloads.downloadFailed': return 'Download fallito';
			case 'downloads.paused': return 'In pausa';
			default: return null;
		}
	}
}

extension on _StringsNl {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'OpenFlix';
			case 'app.loading': return 'Laden...';
			case 'auth.signIn': return 'Inloggen';
			case 'auth.signUp': return 'Registreren';
			case 'auth.signInWithPlex': return 'Inloggen bij OpenFlix';
			case 'auth.showQRCode': return 'Toon QR-code';
			case 'auth.cancel': return 'Annuleren';
			case 'auth.authenticate': return 'Authenticeren';
			case 'auth.retry': return 'Opnieuw proberen';
			case 'auth.debugEnterToken': return 'Debug: Voer Token in';
			case 'auth.plexTokenLabel': return 'Authenticatietoken';
			case 'auth.plexTokenHint': return 'Voer token in';
			case 'auth.authenticationTimeout': return 'Authenticatie verlopen. Probeer opnieuw.';
			case 'auth.scanQRCodeInstruction': return 'Scan deze QR-code om te authenticeren.';
			case 'auth.waitingForAuth': return 'Wachten op authenticatie...\nVoltooi het inloggen in je browser.';
			case 'auth.serverUrl': return 'Server URL';
			case 'auth.serverUrlHint': return 'bijv. http://192.168.1.100:32400';
			case 'auth.username': return 'Gebruikersnaam';
			case 'auth.usernameHint': return 'Voer gebruikersnaam in';
			case 'auth.email': return 'E-mail';
			case 'auth.emailHint': return 'Voer e-mailadres in';
			case 'auth.password': return 'Wachtwoord';
			case 'auth.passwordHint': return 'Voer wachtwoord in';
			case 'auth.confirmPassword': return 'Bevestig Wachtwoord';
			case 'auth.confirmPasswordHint': return 'Voer wachtwoord opnieuw in';
			case 'auth.displayName': return 'Weergavenaam';
			case 'auth.displayNameHint': return 'Optionele weergavenaam';
			case 'auth.noAccount': return 'Nog geen account?';
			case 'auth.haveAccount': return 'Al een account?';
			case 'auth.connecting': return 'Verbinden met server...';
			case 'auth.loggingIn': return 'Inloggen...';
			case 'auth.registering': return 'Account aanmaken...';
			case 'auth.connectToServer': return 'Verbind met Server';
			case 'auth.changeServer': return 'Wijzig Server';
			case 'auth.serverConnected': return ({required Object serverName}) => 'Verbonden met ${serverName}';
			case 'auth.invalidServerUrl': return 'Voer een geldige server URL in';
			case 'auth.serverConnectionFailed': return 'Verbinding met server mislukt';
			case 'auth.passwordMismatch': return 'Wachtwoorden komen niet overeen';
			case 'auth.usernameRequired': return 'Gebruikersnaam vereist';
			case 'auth.emailRequired': return 'E-mail vereist';
			case 'auth.passwordRequired': return 'Wachtwoord vereist';
			case 'auth.passwordTooShort': return 'Wachtwoord moet minimaal 6 tekens zijn';
			case 'auth.invalidEmail': return 'Voer een geldig e-mailadres in';
			case 'auth.firstUserNote': return 'Eerste gebruiker wordt beheerder';
			case 'auth.howConnecting': return 'Hoe maak je verbinding?';
			case 'auth.atHome': return 'Thuis';
			case 'auth.atHomeDescription': return 'Detecteer server automatisch op je lokale netwerk';
			case 'auth.awayFromHome': return 'Onderweg';
			case 'auth.awayFromHomeDescription': return 'Voer serveradres handmatig in';
			case 'auth.findYourServer': return 'Vind je server';
			case 'auth.searching': return 'Zoeken...';
			case 'auth.checkingNetwork': return 'Netwerk controleren...';
			case 'auth.serversFound': return 'Servers gevonden';
			case 'auth.scanAgain': return 'Opnieuw zoeken';
			case 'auth.enterManually': return 'Handmatig invoeren';
			case 'auth.noServersFound': return 'Geen servers gevonden op je netwerk. Zorg ervoor dat je OpenFlix-server draait.';
			case 'auth.discoveryFailed': return ({required Object error}) => 'Zoeken mislukt: ${error}';
			case 'common.cancel': return 'Annuleren';
			case 'common.save': return 'Opslaan';
			case 'common.close': return 'Sluiten';
			case 'common.clear': return 'Wissen';
			case 'common.reset': return 'Resetten';
			case 'common.later': return 'Later';
			case 'common.submit': return 'Verzenden';
			case 'common.confirm': return 'Bevestigen';
			case 'common.retry': return 'Opnieuw proberen';
			case 'common.playNow': return 'Nu afspelen';
			case 'common.logout': return 'Uitloggen';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Eigendom';
			case 'common.shared': return 'Gedeeld';
			case 'common.current': return 'HUIDIG';
			case 'common.unknown': return 'Onbekend';
			case 'common.refresh': return 'Vernieuwen';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nee';
			case 'common.server': return 'Server';
			case 'common.delete': return 'Verwijderen';
			case 'common.shuffle': return 'Willekeurig';
			case 'common.addTo': return 'Toevoegen aan...';
			case 'common.remove': return 'Remove';
			case 'common.play': return 'Play';
			case 'common.details': return 'Details';
			case 'common.seeAll': return 'See All';
			case 'common.live': return 'LIVE';
			case 'common.newLabel': return 'NIEUW';
			case 'screens.licenses': return 'Licenties';
			case 'screens.selectServer': return 'Selecteer server';
			case 'screens.switchProfile': return 'Wissel van profiel';
			case 'screens.subtitleStyling': return 'Ondertitel opmaak';
			case 'screens.search': return 'Zoeken';
			case 'screens.logs': return 'Logbestanden';
			case 'update.available': return 'Update beschikbaar';
			case 'update.versionAvailable': return ({required Object version}) => 'Versie ${version} is beschikbaar';
			case 'update.currentVersion': return ({required Object version}) => 'Huidig: ${version}';
			case 'update.skipVersion': return 'Deze versie overslaan';
			case 'update.viewRelease': return 'Bekijk release';
			case 'update.latestVersion': return 'Je hebt de nieuwste versie';
			case 'update.checkFailed': return 'Kon niet controleren op updates';
			case 'settings.title': return 'Instellingen';
			case 'settings.profile': return 'Profiel';
			case 'settings.noProfileSelected': return 'Geen profiel geselecteerd';
			case 'settings.kidsMode': return 'Kindermodus';
			case 'settings.switchProfile': return 'Profiel wisselen';
			case 'settings.switchProfileDescription': return 'Wissel naar een ander profiel';
			case 'settings.manageProfiles': return 'Profielen beheren';
			case 'settings.manageProfilesDescription': return 'Profielen toevoegen, bewerken of verwijderen';
			case 'settings.language': return 'Taal';
			case 'settings.theme': return 'Thema';
			case 'settings.appearance': return 'Uiterlijk';
			case 'settings.videoPlayback': return 'Video afspelen';
			case 'settings.shufflePlay': return 'Willekeurig afspelen';
			case 'settings.advanced': return 'Geavanceerd';
			case 'settings.useSeasonPostersDescription': return 'Toon seizoenposter in plaats van serieposter voor afleveringen';
			case 'settings.showHeroSectionDescription': return 'Toon uitgelichte inhoud carrousel op startscherm';
			case 'settings.secondsLabel': return 'Seconden';
			case 'settings.minutesLabel': return 'Minuten';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Voer duur in (${min}-${max})';
			case 'settings.systemTheme': return 'Systeem';
			case 'settings.systemThemeDescription': return 'Volg systeeminstellingen';
			case 'settings.lightTheme': return 'Licht';
			case 'settings.darkTheme': return 'Donker';
			case 'settings.libraryDensity': return 'Bibliotheek dichtheid';
			case 'settings.compact': return 'Compact';
			case 'settings.compactDescription': return 'Kleinere kaarten, meer items zichtbaar';
			case 'settings.normal': return 'Normaal';
			case 'settings.normalDescription': return 'Standaard grootte';
			case 'settings.comfortable': return 'Comfortabel';
			case 'settings.comfortableDescription': return 'Grotere kaarten, minder items zichtbaar';
			case 'settings.viewMode': return 'Weergavemodus';
			case 'settings.gridView': return 'Raster';
			case 'settings.gridViewDescription': return 'Items weergeven in een rasterindeling';
			case 'settings.listView': return 'Lijst';
			case 'settings.listViewDescription': return 'Items weergeven in een lijstindeling';
			case 'settings.useSeasonPosters': return 'Gebruik seizoenposters';
			case 'settings.showHeroSection': return 'Toon hoofdsectie';
			case 'settings.hardwareDecoding': return 'Hardware decodering';
			case 'settings.hardwareDecodingDescription': return 'Gebruik hardware versnelling indien beschikbaar';
			case 'settings.bufferSize': return 'Buffer grootte';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Ondertitel opmaak';
			case 'settings.subtitleStylingDescription': return 'Pas ondertitel uiterlijk aan';
			case 'settings.smallSkipDuration': return 'Korte skip duur';
			case 'settings.largeSkipDuration': return 'Lange skip duur';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} seconden';
			case 'settings.defaultSleepTimer': return 'Standaard slaap timer';
			case 'settings.minutesUnit': return ({required Object minutes}) => 'bij ${minutes} minuten';
			case 'settings.rememberTrackSelections': return 'Onthoud track selecties per serie/film';
			case 'settings.rememberTrackSelectionsDescription': return 'Bewaar automatisch audio- en ondertiteltaalvoorkeuren wanneer je tracks wijzigt tijdens afspelen';
			case 'settings.unwatchedOnly': return 'Alleen ongekeken';
			case 'settings.unwatchedOnlyDescription': return 'Alleen ongekeken afleveringen opnemen in willekeurige wachtrij';
			case 'settings.shuffleOrderNavigation': return 'Willekeurige volgorde navigatie';
			case 'settings.shuffleOrderNavigationDescription': return 'Volgende/vorige knoppen volgen willekeurige volgorde';
			case 'settings.loopShuffleQueue': return 'Herhaal willekeurige wachtrij';
			case 'settings.loopShuffleQueueDescription': return 'Start wachtrij opnieuw bij het einde';
			case 'settings.videoPlayerControls': return 'Videospeler bediening';
			case 'settings.keyboardShortcuts': return 'Toetsenbord sneltoetsen';
			case 'settings.keyboardShortcutsDescription': return 'Pas toetsenbord sneltoetsen aan';
			case 'settings.debugLogging': return 'Debug logging';
			case 'settings.debugLoggingDescription': return 'Schakel gedetailleerde logging in voor probleemoplossing';
			case 'settings.viewLogs': return 'Bekijk logs';
			case 'settings.viewLogsDescription': return 'Bekijk applicatie logs';
			case 'settings.clearCache': return 'Cache wissen';
			case 'settings.clearCacheDescription': return 'Dit wist alle gecachte afbeeldingen en gegevens. De app kan langer duren om inhoud te laden na het wissen van de cache.';
			case 'settings.clearCacheSuccess': return 'Cache succesvol gewist';
			case 'settings.resetSettings': return 'Instellingen resetten';
			case 'settings.resetSettingsDescription': return 'Dit reset alle instellingen naar hun standaard waarden. Deze actie kan niet ongedaan gemaakt worden.';
			case 'settings.resetSettingsSuccess': return 'Instellingen succesvol gereset';
			case 'settings.shortcutsReset': return 'Sneltoetsen gereset naar standaard';
			case 'settings.about': return 'Over';
			case 'settings.aboutDescription': return 'App informatie en licenties';
			case 'settings.updates': return 'Updates';
			case 'settings.updateAvailable': return 'Update beschikbaar';
			case 'settings.checkForUpdates': return 'Controleer op updates';
			case 'settings.validationErrorEnterNumber': return 'Voer een geldig nummer in';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'Duur moet tussen ${min} en ${max} ${unit} zijn';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Sneltoets al toegewezen aan ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Sneltoets bijgewerkt voor ${action}';
			case 'settings.autoSkip': return 'Automatisch Overslaan';
			case 'settings.autoSkipIntro': return 'Intro Automatisch Overslaan';
			case 'settings.autoSkipIntroDescription': return 'Intro-markeringen na enkele seconden automatisch overslaan';
			case 'settings.autoSkipCredits': return 'Credits Automatisch Overslaan';
			case 'settings.autoSkipCreditsDescription': return 'Credits automatisch overslaan en volgende aflevering afspelen';
			case 'settings.autoSkipDelay': return 'Vertraging Automatisch Overslaan';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => '${seconds} seconden wachten voor automatisch overslaan';
			case 'settings.metadataSection': return 'Metadata';
			case 'settings.tmdbApiKey': return 'TMDB API-sleutel';
			case 'settings.tmdbApiKeyDescription': return 'Configureer TMDB voor uitgebreide metadata';
			case 'settings.tmdbApiKeyConfigured': return 'API-sleutel geconfigureerd';
			case 'settings.tmdbApiKeyHint': return 'Haal je API-sleutel op bij themoviedb.org';
			case 'settings.tmdbApiKeyPlaceholder': return 'Voer je TMDB API-sleutel in';
			case 'settings.apiKey': return 'API-sleutel';
			case 'settings.tmdbApiKeySaved': return 'TMDB API-sleutel opgeslagen';
			case 'settings.tmdbApiKeyCleared': return 'TMDB API-sleutel verwijderd';
			case 'settings.parentalControls': return 'Ouderlijk Toezicht';
			case 'settings.enableParentalControls': return 'Ouderlijk Toezicht Inschakelen';
			case 'settings.enableParentalControlsDescription': return 'Beperk content op basis van leeftijdsclassificaties';
			case 'settings.setPin': return 'PIN Instellen';
			case 'settings.setPinDescription': return 'Voer een 4-cijferige PIN in om de instellingen te beschermen';
			case 'settings.confirmPin': return 'PIN Bevestigen';
			case 'settings.confirmPinDescription': return 'Voer de PIN nogmaals in ter bevestiging';
			case 'settings.enterPin': return 'PIN Invoeren';
			case 'settings.enterPinDescription': return 'Voer je ouderlijk toezicht PIN in';
			case 'settings.changePin': return 'PIN Wijzigen';
			case 'settings.changePinDescription': return 'Wijzig je ouderlijk toezicht PIN';
			case 'settings.pinSet': return 'Ouderlijk toezicht PIN succesvol ingesteld';
			case 'settings.pinMismatch': return 'PIN-codes komen niet overeen. Probeer opnieuw.';
			case 'settings.incorrectPin': return 'Onjuiste PIN. Probeer opnieuw.';
			case 'settings.maxMovieRating': return 'Maximale Filmclassificatie';
			case 'settings.maxTvRating': return 'Maximale TV-classificatie';
			case 'search.hint': return 'Zoek films, series, muziek...';
			case 'search.tryDifferentTerm': return 'Probeer een andere zoekterm';
			case 'search.searchYourMedia': return 'Zoek in je media';
			case 'search.enterTitleActorOrKeyword': return 'Voer een titel, acteur of trefwoord in';
			case 'search.recentSearches': return 'Recente zoekopdrachten';
			case 'search.clear': return 'Wissen';
			case 'search.voiceSearch': return 'Spraakzoeken';
			case 'search.listening': return 'Luisteren...';
			case 'search.speakNow': return 'Spreek nu';
			case 'search.all': return 'Alle';
			case 'search.movies': return 'Films';
			case 'search.tvShows': return 'Series';
			case 'search.music': return 'Muziek';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Stel sneltoets in voor ${actionName}';
			case 'hotkeys.clearShortcut': return 'Wis sneltoets';
			case 'pinEntry.enterPin': return 'Voer PIN in';
			case 'pinEntry.showPin': return 'Toon PIN';
			case 'pinEntry.hidePin': return 'Verberg PIN';
			case 'fileInfo.title': return 'Bestand info';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Audio';
			case 'fileInfo.file': return 'Bestand';
			case 'fileInfo.advanced': return 'Geavanceerd';
			case 'fileInfo.codec': return 'Codec';
			case 'fileInfo.resolution': return 'Resolutie';
			case 'fileInfo.bitrate': return 'Bitrate';
			case 'fileInfo.frameRate': return 'Frame rate';
			case 'fileInfo.aspectRatio': return 'Beeldverhouding';
			case 'fileInfo.profile': return 'Profiel';
			case 'fileInfo.bitDepth': return 'Bit diepte';
			case 'fileInfo.colorSpace': return 'Kleurruimte';
			case 'fileInfo.colorRange': return 'Kleurbereik';
			case 'fileInfo.colorPrimaries': return 'Kleurprimaires';
			case 'fileInfo.chromaSubsampling': return 'Chroma subsampling';
			case 'fileInfo.channels': return 'Kanalen';
			case 'fileInfo.path': return 'Pad';
			case 'fileInfo.size': return 'Grootte';
			case 'fileInfo.container': return 'Container';
			case 'fileInfo.duration': return 'Duur';
			case 'fileInfo.optimizedForStreaming': return 'Geoptimaliseerd voor streaming';
			case 'fileInfo.has64bitOffsets': return '64-bit Offsets';
			case 'mediaMenu.markAsWatched': return 'Markeer als gekeken';
			case 'mediaMenu.markAsUnwatched': return 'Markeer als ongekeken';
			case 'mediaMenu.removeFromContinueWatching': return 'Verwijder uit Doorgaan met kijken';
			case 'mediaMenu.goToSeries': return 'Ga naar serie';
			case 'mediaMenu.goToSeason': return 'Ga naar seizoen';
			case 'mediaMenu.shufflePlay': return 'Willekeurig afspelen';
			case 'mediaMenu.fileInfo': return 'Bestand info';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, film';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, TV-serie';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'bekeken';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} procent bekeken';
			case 'accessibility.mediaCardUnwatched': return 'niet bekeken';
			case 'accessibility.tapToPlay': return 'Tik om af te spelen';
			case 'tooltips.shufflePlay': return 'Willekeurig afspelen';
			case 'tooltips.markAsWatched': return 'Markeer als gekeken';
			case 'tooltips.markAsUnwatched': return 'Markeer als ongekeken';
			case 'videoControls.audioLabel': return 'Audio';
			case 'videoControls.subtitlesLabel': return 'Ondertitels';
			case 'videoControls.resetToZero': return 'Reset naar 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} speelt later af';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} speelt eerder af';
			case 'videoControls.noOffset': return 'Geen offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Vul scherm';
			case 'videoControls.stretch': return 'Uitrekken';
			case 'videoControls.lockRotation': return 'Vergrendel rotatie';
			case 'videoControls.unlockRotation': return 'Ontgrendel rotatie';
			case 'videoControls.lockScreen': return 'Vergrendel scherm';
			case 'videoControls.unlockScreen': return 'Ontgrendel scherm';
			case 'videoControls.screenLockButton': return 'Schermvergrendeling';
			case 'videoControls.screenLocked': return 'Scherm vergrendeld';
			case 'videoControls.tapToUnlock': return 'Tik om te ontgrendelen';
			case 'videoControls.sleepTimer': return 'Slaaptimer';
			case 'videoControls.timerActive': return 'Timer actief';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'Afspelen wordt gepauzeerd over ${duration}';
			case 'videoControls.sleepTimerCompleted': return 'Slaaptimer voltooid - afspelen gepauzeerd';
			case 'videoControls.playButton': return 'Afspelen';
			case 'videoControls.pauseButton': return 'Pauzeren';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => 'Terugspoelen ${seconds} seconden';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => 'Vooruitspoelen ${seconds} seconden';
			case 'videoControls.previousButton': return 'Vorige aflevering';
			case 'videoControls.nextButton': return 'Volgende aflevering';
			case 'videoControls.previousChapterButton': return 'Vorig hoofdstuk';
			case 'videoControls.nextChapterButton': return 'Volgend hoofdstuk';
			case 'videoControls.volumeButton': return 'Volume';
			case 'videoControls.muteButton': return 'Dempen';
			case 'videoControls.unmuteButton': return 'Dempen opheffen';
			case 'videoControls.settingsButton': return 'Video-instellingen';
			case 'videoControls.audioTrackButton': return 'Audiosporen';
			case 'videoControls.subtitlesButton': return 'Ondertitels';
			case 'videoControls.chaptersButton': return 'Hoofdstukken';
			case 'videoControls.versionsButton': return 'Videoversies';
			case 'videoControls.aspectRatioButton': return 'Beeldverhouding';
			case 'videoControls.fullscreenButton': return 'Volledig scherm activeren';
			case 'videoControls.exitFullscreenButton': return 'Volledig scherm verlaten';
			case 'videoControls.rotationLockButton': return 'Rotatievergrendeling';
			case 'videoControls.timelineSlider': return 'Videotijdlijn';
			case 'videoControls.volumeSlider': return 'Volumeniveau';
			case 'videoControls.backButton': return 'Terug';
			case 'userStatus.admin': return 'Beheerder';
			case 'userStatus.restricted': return 'Beperkt';
			case 'userStatus.protected': return 'Beschermd';
			case 'userStatus.current': return 'HUIDIG';
			case 'messages.markedAsWatched': return 'Gemarkeerd als gekeken';
			case 'messages.markedAsUnwatched': return 'Gemarkeerd als ongekeken';
			case 'messages.removedFromContinueWatching': return 'Verwijderd uit Doorgaan met kijken';
			case 'messages.errorLoading': return ({required Object error}) => 'Fout: ${error}';
			case 'messages.fileInfoNotAvailable': return 'Bestand informatie niet beschikbaar';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Fout bij laden bestand info: ${error}';
			case 'messages.errorLoadingSeries': return 'Fout bij laden serie';
			case 'messages.errorLoadingSeason': return 'Fout bij laden seizoen';
			case 'messages.musicNotSupported': return 'Muziek afspelen wordt nog niet ondersteund';
			case 'messages.logsCleared': return 'Logs gewist';
			case 'messages.logsCopied': return 'Logs gekopieerd naar klembord';
			case 'messages.noLogsAvailable': return 'Geen logs beschikbaar';
			case 'messages.libraryScanning': return ({required Object title}) => 'Scannen "${title}"...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Bibliotheek scan gestart voor "${title}"';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Kon bibliotheek niet scannen: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Metadata vernieuwen voor "${title}"...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadata vernieuwen gestart voor "${title}"';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Kon metadata niet vernieuwen: ${error}';
			case 'messages.noTokenFound': return 'Geen token gevonden. Log opnieuw in.';
			case 'messages.logoutConfirm': return 'Weet je zeker dat je wilt uitloggen?';
			case 'messages.noSeasonsFound': return 'Geen seizoenen gevonden';
			case 'messages.noEpisodesFound': return 'Geen afleveringen gevonden in eerste seizoen';
			case 'messages.noEpisodesFoundGeneral': return 'Geen afleveringen gevonden';
			case 'messages.noResultsFound': return 'Geen resultaten gevonden';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Slaap timer ingesteld voor ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
			case 'messages.noItemsAvailable': return 'Geen items beschikbaar';
			case 'messages.failedToCreatePlayQueue': return 'Kan afspeelwachtrij niet maken';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Kan afspeelwachtrij niet maken - geen items';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Afspelen van ${action} mislukt: ${error}';
			case 'profile.noUsersAvailable': return 'Geen gebruikers beschikbaar';
			case 'subtitlingStyling.stylingOptions': return 'Opmaak opties';
			case 'subtitlingStyling.fontSize': return 'Lettergrootte';
			case 'subtitlingStyling.textColor': return 'Tekstkleur';
			case 'subtitlingStyling.borderSize': return 'Rand grootte';
			case 'subtitlingStyling.borderColor': return 'Randkleur';
			case 'subtitlingStyling.backgroundOpacity': return 'Achtergrond transparantie';
			case 'subtitlingStyling.backgroundColor': return 'Achtergrondkleur';
			case 'dialog.confirmAction': return 'Bevestig actie';
			case 'dialog.areYouSure': return 'Weet je zeker dat je deze actie wilt uitvoeren?';
			case 'dialog.cancel': return 'Annuleren';
			case 'dialog.playNow': return 'Nu afspelen';
			case 'discover.title': return 'Ontdekken';
			case 'discover.switchProfile': return 'Wissel van profiel';
			case 'discover.switchServer': return 'Wissel van server';
			case 'discover.logout': return 'Uitloggen';
			case 'discover.noContentAvailable': return 'Geen inhoud beschikbaar';
			case 'discover.addMediaToLibraries': return 'Voeg wat media toe aan je bibliotheken';
			case 'discover.continueWatching': return 'Verder kijken';
			case 'discover.recentlyAdded': return 'Recent toegevoegd';
			case 'discover.play': return 'Afspelen';
			case 'discover.resume': return 'Hervatten';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Speel S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Hervat S${season}, E${episode}';
			case 'discover.pause': return 'Pauzeren';
			case 'discover.overview': return 'Overzicht';
			case 'discover.cast': return 'Acteurs';
			case 'discover.seasons': return 'Seizoenen';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Leeftijd';
			case 'discover.watched': return 'Bekeken';
			case 'discover.episodeCount': return ({required Object count}) => '${count} afleveringen';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} gekeken';
			case 'discover.movie': return 'Film';
			case 'discover.tvShow': return 'TV Serie';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} min over';
			case 'discover.whatsOnNow': return 'Nu op TV';
			case 'discover.channelGuide': return 'TV Gids';
			case 'discover.liveNow': return 'Nu Live';
			case 'discover.topTen': return 'Top 10';
			case 'discover.newBadge': return 'NIEUW';
			case 'discover.liveBadge': return 'LIVE';
			case 'discover.goodMorning': return 'Good morning';
			case 'discover.goodAfternoon': return 'Good afternoon';
			case 'discover.goodEvening': return 'Good evening';
			case 'discover.defaultUser': return 'Guest';
			case 'discover.yourNextWatch': return 'Your Next Watch';
			case 'discover.pickedForYou': return ({required Object name}) => 'Picked just for you, ${name}';
			case 'discover.surpriseMe': return 'Surprise Me';
			case 'discover.randomPicker': return 'Random Movie Picker';
			case 'discover.noMoviesFound': return 'No movies found in your library';
			case 'discover.spinning': return 'Picking something great...';
			case 'discover.spinAgain': return 'Spin Again';
			case 'discover.calendar': return 'Calendar';
			case 'discover.today': return 'Today';
			case 'discover.item': return 'item';
			case 'discover.items': return 'items';
			case 'discover.loadingMovies': return 'Je films laden...';
			case 'discover.noContentOnDate': return 'No content added on this date';
			case 'discover.noEpgData': return 'Geen programma-informatie';
			case 'errors.searchFailed': return ({required Object error}) => 'Zoeken mislukt: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Verbinding time-out tijdens laden ${context}';
			case 'errors.connectionFailed': return 'Kan geen verbinding maken met Plex server';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Kon ${context} niet laden: ${error}';
			case 'errors.noClientAvailable': return 'Geen client beschikbaar';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Authenticatie mislukt: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Kon auth URL niet openen';
			case 'errors.pleaseEnterToken': return 'Voer een token in';
			case 'errors.invalidToken': return 'Ongeldig token';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Kon token niet verifiëren: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Kon niet wisselen naar ${displayName}';
			case 'errors.connectionFailedGeneric': return 'Verbinding mislukt';
			case 'errors.failedToRemove': return ({required Object error}) => 'Verwijderen mislukt: ${error}';
			case 'voice.notAvailable': return 'Spraakbesturing is niet beschikbaar';
			case 'voice.commandNotRecognized': return ({required Object command}) => 'Commando niet herkend: "${command}"';
			case 'libraries.title': return 'Bibliotheken';
			case 'libraries.scanLibraryFiles': return 'Scan bibliotheek bestanden';
			case 'libraries.scanLibrary': return 'Scan bibliotheek';
			case 'libraries.analyze': return 'Analyseren';
			case 'libraries.analyzeLibrary': return 'Analyseer bibliotheek';
			case 'libraries.refreshMetadata': return 'Vernieuw metadata';
			case 'libraries.emptyTrash': return 'Prullenbak legen';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Prullenbak legen voor "${title}"...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Prullenbak geleegd voor "${title}"';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Kon prullenbak niet legen: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analyseren "${title}"...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analyse gestart voor "${title}"';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Kon bibliotheek niet analyseren: ${error}';
			case 'libraries.noLibrariesFound': return 'Geen bibliotheken gevonden';
			case 'libraries.thisLibraryIsEmpty': return 'Deze bibliotheek is leeg';
			case 'libraries.all': return 'Alles';
			case 'libraries.clearAll': return 'Alles wissen';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => 'Weet je zeker dat je "${title}" wilt scannen?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => 'Weet je zeker dat je "${title}" wilt analyseren?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Weet je zeker dat je metadata wilt vernieuwen voor "${title}"?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Weet je zeker dat je de prullenbak wilt legen voor "${title}"?';
			case 'libraries.manageLibraries': return 'Beheer bibliotheken';
			case 'libraries.sort': return 'Sorteren';
			case 'libraries.sortBy': return 'Sorteer op';
			case 'libraries.filters': return 'Filters';
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Bibliotheek laden... (${count} items geladen)';
			case 'libraries.confirmActionMessage': return 'Weet je zeker dat je deze actie wilt uitvoeren?';
			case 'libraries.showLibrary': return 'Toon bibliotheek';
			case 'libraries.hideLibrary': return 'Verberg bibliotheek';
			case 'libraries.libraryOptions': return 'Bibliotheek opties';
			case 'libraries.content': return 'bibliotheekinhoud';
			case 'libraries.selectLibrary': return 'Bibliotheek kiezen';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filters (${count})';
			case 'libraries.noRecommendations': return 'Geen aanbevelingen beschikbaar';
			case 'libraries.noCollections': return 'Geen collecties in deze bibliotheek';
			case 'libraries.noFoldersFound': return 'Geen mappen gevonden';
			case 'libraries.folders': return 'mappen';
			case 'libraries.tabs.recommended': return 'Aanbevolen';
			case 'libraries.tabs.browse': return 'Bladeren';
			case 'libraries.tabs.collections': return 'Collecties';
			case 'libraries.tabs.playlists': return 'Afspeellijsten';
			case 'libraries.groupings.all': return 'Alles';
			case 'libraries.groupings.movies': return 'Films';
			case 'libraries.groupings.shows': return 'Series';
			case 'libraries.groupings.seasons': return 'Seizoenen';
			case 'libraries.groupings.episodes': return 'Afleveringen';
			case 'libraries.groupings.folders': return 'Mappen';
			case 'about.title': return 'Over';
			case 'about.openSourceLicenses': return 'Open Source licenties';
			case 'about.versionLabel': return ({required Object version}) => 'Versie ${version}';
			case 'about.appDescription': return 'Een mooie Plex client voor Flutter';
			case 'about.viewLicensesDescription': return 'Bekijk licenties van third-party bibliotheken';
			case 'serverSelection.connectingToServer': return 'Verbinden met server...';
			case 'serverSelection.connectingToAllServers': return 'Verbinden met alle servers...';
			case 'serverSelection.connectToAllServers': return 'Verbind met alle servers';
			case 'serverSelection.allServerConnectionsFailed': return 'Kon niet verbinden met servers. Controleer je netwerk en probeer opnieuw.';
			case 'serverSelection.foundServers': return ({required Object count}) => '${count} server(s) gevonden';
			case 'serverSelection.orSelectIndividually': return 'Of selecteer een server individueel:';
			case 'serverSelection.serverDebugCopied': return 'Server debug gegevens gekopieerd naar klembord';
			case 'serverSelection.copyDebugData': return 'Kopieer debug gegevens';
			case 'serverSelection.noServersFound': return 'Geen servers gevonden';
			case 'serverSelection.malformedServerData': return ({required Object count}) => '${count} server(s) gevonden met verkeerde data. Geen geldige servers beschikbaar.';
			case 'serverSelection.incompleteServerInfo': return 'Sommige servers hebben incomplete informatie en zijn overgeslagen. Controleer je Plex.tv account.';
			case 'serverSelection.incompleteConnectionInfo': return 'Server verbinding informatie is incompleet. Probeer opnieuw.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Server informatie is verkeerd geformatteerd: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Netwerkverbinding mislukt. Controleer je internetverbinding en probeer opnieuw.';
			case 'serverSelection.authenticationFailed': return 'Authenticatie mislukt. Log opnieuw in.';
			case 'serverSelection.plexServiceUnavailable': return 'Plex service niet beschikbaar. Probeer later opnieuw.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Kon servers niet laden: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Uitgavejaar';
			case 'hubDetail.dateAdded': return 'Datum toegevoegd';
			case 'hubDetail.rating': return 'Beoordeling';
			case 'hubDetail.noItemsFound': return 'Geen items gevonden';
			case 'logs.title': return 'Logbestanden';
			case 'logs.clearLogs': return 'Wis logs';
			case 'logs.copyLogs': return 'Kopieer logs';
			case 'logs.exportLogs': return 'Exporteer logs';
			case 'logs.noLogsToShow': return 'Geen logs om te tonen';
			case 'logs.error': return 'Fout:';
			case 'logs.stackTrace': return 'Stacktracering:';
			case 'stats.title': return 'Kijkstatistieken';
			case 'stats.totalWatchTime': return 'Totale Kijktijd';
			case 'stats.moviesWatched': return 'Films Bekeken';
			case 'stats.episodesWatched': return 'Afleveringen Bekeken';
			case 'stats.avgPerDay': return 'Gemiddeld per Dag';
			case 'stats.topGenres': return 'Favoriete Genres';
			case 'stats.monthlyActivity': return 'Maandelijkse Activiteit';
			case 'stats.noData': return 'Nog geen kijkgeschiedenis';
			case 'stats.startWatching': return 'Begin met kijken om je statistieken te zien';
			case 'stats.days': return 'dagen';
			case 'licenses.relatedPackages': return 'Gerelateerde pakketten';
			case 'licenses.license': return 'Licentie';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Licentie ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenties';
			case 'navigation.home': return 'Thuis';
			case 'navigation.search': return 'Zoeken';
			case 'navigation.libraries': return 'Bibliotheken';
			case 'navigation.livetv': return 'Live TV';
			case 'navigation.settings': return 'Instellingen';
			case 'playlists.title': return 'Afspeellijsten';
			case 'playlists.noPlaylists': return 'Geen afspeellijsten gevonden';
			case 'playlists.create': return 'Afspeellijst maken';
			case 'playlists.newPlaylist': return 'Nieuwe afspeellijst';
			case 'playlists.playlistName': return 'Naam afspeellijst';
			case 'playlists.enterPlaylistName': return 'Voer naam afspeellijst in';
			case 'playlists.edit': return 'Afspeellijst bewerken';
			case 'playlists.delete': return 'Afspeellijst verwijderen';
			case 'playlists.addTo': return 'Toevoegen aan afspeellijst';
			case 'playlists.addItems': return 'Items toevoegen';
			case 'playlists.removeItem': return 'Verwijderen uit afspeellijst';
			case 'playlists.clearPlaylist': return 'Afspeellijst wissen';
			case 'playlists.playAll': return 'Alles afspelen';
			case 'playlists.shuffle': return 'Willekeurig';
			case 'playlists.smartPlaylist': return 'Slimme afspeellijst';
			case 'playlists.regularPlaylist': return 'Normale afspeellijst';
			case 'playlists.itemCount': return ({required Object count}) => '${count} items';
			case 'playlists.oneItem': return '1 item';
			case 'playlists.emptyPlaylist': return 'Deze afspeellijst is leeg';
			case 'playlists.deleteConfirm': return 'Afspeellijst verwijderen?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Weet je zeker dat je "${name}" wilt verwijderen?';
			case 'playlists.created': return 'Afspeellijst gemaakt';
			case 'playlists.updated': return 'Afspeellijst bijgewerkt';
			case 'playlists.deleted': return 'Afspeellijst verwijderd';
			case 'playlists.itemAdded': return 'Toegevoegd aan afspeellijst';
			case 'playlists.itemRemoved': return 'Verwijderd uit afspeellijst';
			case 'playlists.selectPlaylist': return 'Selecteer afspeellijst';
			case 'playlists.createNewPlaylist': return 'Nieuwe afspeellijst maken';
			case 'playlists.errorCreating': return 'Fout bij maken afspeellijst';
			case 'playlists.errorDeleting': return 'Fout bij verwijderen afspeellijst';
			case 'playlists.errorLoading': return 'Fout bij laden afspeellijsten';
			case 'playlists.errorAdding': return 'Fout bij toevoegen aan afspeellijst';
			case 'playlists.errorReordering': return 'Fout bij herschikken van afspeellijstitem';
			case 'playlists.errorRemoving': return 'Fout bij verwijderen uit afspeellijst';
			case 'playlists.playlist': return 'Afspeellijst';
			case 'collections.title': return 'Collecties';
			case 'collections.collection': return 'Collectie';
			case 'collections.empty': return 'Collectie is leeg';
			case 'collections.noItems': return 'Geen items in deze collectie';
			case 'collections.unknownLibrarySection': return 'Kan niet verwijderen: onbekende bibliotheeksectie';
			case 'collections.deleteCollection': return 'Collectie verwijderen';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Weet je zeker dat je "${title}" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.';
			case 'collections.deleted': return 'Collectie verwijderd';
			case 'collections.deleteFailed': return 'Collectie verwijderen mislukt';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Collectie verwijderen mislukt: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Collectie-items laden mislukt: ${error}';
			case 'collections.addTo': return 'Toevoegen aan collectie';
			case 'collections.selectCollection': return 'Selecteer collectie';
			case 'collections.createNewCollection': return 'Nieuwe collectie maken';
			case 'collections.collectionName': return 'Collectienaam';
			case 'collections.enterCollectionName': return 'Voer collectienaam in';
			case 'collections.addedToCollection': return 'Toegevoegd aan collectie';
			case 'collections.errorAddingToCollection': return 'Fout bij toevoegen aan collectie';
			case 'collections.created': return 'Collectie gemaakt';
			case 'collections.removeFromCollection': return 'Verwijderen uit collectie';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => '"${title}" uit deze collectie verwijderen?';
			case 'collections.removedFromCollection': return 'Uit collectie verwijderd';
			case 'collections.removeFromCollectionFailed': return 'Verwijderen uit collectie mislukt';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Fout bij verwijderen uit collectie: ${error}';
			case 'watchParty.title': return 'Watch Party';
			case 'watchParty.startParty': return 'Watch Party starten';
			case 'watchParty.joinParty': return 'Deelnemen aan Party';
			case 'watchParty.enterCode': return 'Voer party code in';
			case 'watchParty.shareCode': return 'Deel deze code';
			case 'watchParty.friendsCanJoin': return 'Vrienden kunnen deelnemen met deze code';
			case 'watchParty.participants': return 'Deelnemers';
			case 'watchParty.host': return 'Host';
			case 'watchParty.endParty': return 'Party beëindigen';
			case 'watchParty.leaveParty': return 'Party verlaten';
			case 'watchParty.partyEnded': return 'Watch Party beëindigd';
			case 'watchParty.chat': return 'Chat';
			case 'watchParty.typeMessage': return 'Typ een bericht...';
			case 'watchParty.joined': return ({required Object name}) => '${name} is toegetreden';
			case 'watchParty.left': return ({required Object name}) => '${name} is vertrokken';
			case 'watchParty.syncedPlayback': return 'Afspelen is gesynchroniseerd met party';
			case 'watchParty.hostControls': return 'Alleen de host kan het afspelen bedienen';
			case 'watchParty.creating': return 'Party wordt aangemaakt...';
			case 'watchParty.joining': return 'Deelnemen aan party...';
			case 'watchParty.createFailed': return 'Party aanmaken mislukt';
			case 'watchParty.joinFailed': return 'Deelnemen aan party mislukt';
			case 'watchParty.invalidCode': return 'Ongeldige party code';
			case 'watchParty.gotIt': return 'Begrepen';
			case 'catchUp.title': return 'Catch Up TV';
			case 'catchUp.startOver': return 'Opnieuw beginnen';
			case 'catchUp.startOverDescription': return 'Vanaf het begin kijken';
			case 'catchUp.watchFromBeginning': return 'Vanaf het begin kijken?';
			case 'catchUp.alreadyStarted': return ({required Object title}) => '"${title}" is al begonnen. Je kunt vanaf het begin kijken.';
			case 'catchUp.watchLive': return 'Live kijken';
			case 'catchUp.programsAvailable': return 'Beschikbare programma\'s';
			case 'catchUp.noProgramsAvailable': return 'Geen catch-up programma\'s beschikbaar';
			case 'catchUp.programsWillAppear': return 'Programma\'s verschijnen hier naarmate ze worden uitgezonden';
			case 'catchUp.unavailable': return 'Niet beschikbaar';
			case 'catchUp.bufferNotReady': return 'Buffer nog niet klaar';
			case 'catchUp.rewind': return 'Terugspoelen';
			case 'catchUp.timeshiftEnabled': return 'Time-shift ingeschakeld';
			case 'catchUp.goBackTo': return ({required Object time}) => 'Ga terug naar ${time}';
			case 'watchlist.title': return 'Mijn kijklijst';
			case 'watchlist.all': return 'Alle';
			case 'watchlist.movies': return 'Films';
			case 'watchlist.shows': return 'Series';
			case 'watchlist.episodes': return 'Afleveringen';
			case 'watchlist.empty': return 'Je kijklijst is leeg';
			case 'watchlist.emptyHint': return 'Voeg films en series toe aan je kijklijst';
			case 'watchlist.noItemsFiltered': return 'Geen items komen overeen met dit filter';
			case 'watchlist.removeTitle': return 'Verwijder van kijklijst';
			case 'watchlist.removeConfirm': return ({required Object title}) => '"${title}" van je kijklijst verwijderen?';
			case 'watchlist.remove': return 'Remove';
			case 'watchlist.play': return 'Play';
			case 'watchlist.details': return 'Details';
			case 'watchlist.seeAll': return 'See All';
			case 'watchlist.clearAllTitle': return 'Kijklijst wissen';
			case 'watchlist.clearAllConfirm': return ({required Object count}) => 'Alle ${count} items van je kijklijst verwijderen?';
			case 'watchlist.clearAll': return 'Alles wissen';
			case 'watchlist.addedToday': return 'Vandaag toegevoegd';
			case 'watchlist.addedYesterday': return 'Gisteren toegevoegd';
			case 'watchlist.addedDaysAgo': return ({required Object days}) => '${days} dagen geleden toegevoegd';
			case 'watchlist.addedOn': return ({required Object date}) => 'Toegevoegd op ${date}';
			case 'watchlist.addToWatchlist': return 'Toevoegen aan kijklijst';
			case 'watchlist.removeFromWatchlist': return 'Verwijderen van kijklijst';
			case 'watchlist.addedToWatchlist': return 'Toegevoegd aan kijklijst';
			case 'watchlist.removedFromWatchlist': return 'Verwijderd van kijklijst';
			case 'liveTV.title': return 'Live TV';
			case 'liveTV.guide': return 'Gids';
			case 'liveTV.dvr': return 'DVR';
			case 'liveTV.multiview': return 'Multiview';
			case 'liveTV.allChannels': return 'Alle zenders';
			case 'liveTV.favorites': return 'Favorieten';
			case 'liveTV.noChannels': return 'Geen zenders beschikbaar';
			case 'liveTV.addM3USource': return 'Voeg een M3U-bron toe in serverinstellingen';
			case 'liveTV.recording': return 'Opnemen';
			case 'liveTV.recordingNow': return 'Nu opnemen';
			case 'liveTV.upNext': return 'Hierna';
			case 'liveTV.noProgram': return 'Geen programma-info';
			case 'liveTV.filterByGroup': return 'Filter op groep';
			case 'liveTV.refresh': return 'Vernieuwen';
			case 'liveTV.channelCount': return ({required Object count}) => '${count} zenders';
			case 'liveTV.nowPlaying': return 'Nu op TV';
			case 'liveTV.scheduleRecording': return 'Opname plannen';
			case 'liveTV.onNow': return 'Nu te zien';
			case 'liveTV.endsAt': return ({required Object time}) => 'Eindigt om ${time}';
			case 'liveTV.startsAt': return ({required Object time}) => 'Start om ${time}';
			case 'liveTV.playbackError': return ({required Object error}) => 'Afspeelfout: ${error}';
			case 'liveTV.noPreviousChannel': return 'Geen vorig kanaal';
			case 'liveTV.switchedTo': return ({required Object channel}) => 'Gewisseld naar: ${channel}';
			case 'liveTV.startingFromBeginning': return 'Programma vanaf begin starten...';
			case 'liveTV.failedToStartOver': return ({required Object error}) => 'Opnieuw starten mislukt: ${error}';
			case 'liveTV.playingProgram': return ({required Object title}) => 'Afspelen: ${title}';
			case 'liveTV.failedToPlayProgram': return ({required Object error}) => 'Programma afspelen mislukt: ${error}';
			case 'liveTV.addedToFavorites': return 'Toegevoegd aan favorieten';
			case 'liveTV.removedFromFavorites': return 'Verwijderd uit favorieten';
			case 'liveTV.failedToUpdateFavorite': return ({required Object error}) => 'Favoriet bijwerken mislukt: ${error}';
			case 'liveTV.pipNotSupported': return 'Picture-in-Picture niet ondersteund op dit platform';
			case 'liveTV.enteredPipMode': return 'Picture-in-Picture modus geactiveerd';
			case 'liveTV.exitedPipMode': return 'Picture-in-Picture modus beëindigd';
			case 'liveTV.aspectRatioChanged': return ({required Object mode}) => 'Beeldverhouding: ${mode}';
			case 'liveTV.tune': return 'Afstemmen';
			case 'liveTV.retry': return 'Opnieuw proberen';
			case 'liveTV.noChannelsMatchFilter': return 'Geen kanalen komen overeen met filter';
			case 'liveTV.skipCommercial': return 'Reclame overslaan';
			case 'dvr.title': return 'DVR';
			case 'dvr.recordings': return 'Opnames';
			case 'dvr.seriesRules': return 'Serie regels';
			case 'dvr.noRecordings': return 'Geen opnames';
			case 'dvr.noRules': return 'Geen serie regels';
			case 'dvr.scheduleFromGuide': return 'Plan opnames vanuit de Live TV gids';
			case 'dvr.createRulesHint': return 'Maak regels om series automatisch op te nemen';
			case 'dvr.storage': return 'Opslag';
			case 'dvr.recordingsCount': return ({required Object count}) => '${count} opnames';
			case 'dvr.all': return 'Alle';
			case 'dvr.scheduled': return 'Gepland';
			case 'dvr.completed': return 'Voltooid';
			case 'dvr.failed': return 'Mislukt';
			case 'dvr.deleteRecording': return 'Opname verwijderen?';
			case 'dvr.deleteRule': return 'Serie regel verwijderen?';
			case 'dvr.sortByDate': return 'Datum';
			case 'dvr.sortByTitle': return 'Titel';
			case 'dvr.sortBySize': return 'Grootte';
			case 'dvr.playRecording': return 'Opname afspelen';
			case 'dvr.keepPolicy': return ({required Object count}) => 'Bewaar ${count} afleveringen';
			case 'dvr.keepAll': return 'Alles bewaren';
			case 'dvr.recordingScheduled': return 'Opname gepland';
			case 'dvr.scheduleRecordingTitle': return 'Opname plannen';
			case 'dvr.schedule': return 'Plannen';
			case 'dvr.cancel': return 'Annuleren';
			case 'epg.title': return 'TV Gids';
			case 'epg.now': return 'Nu';
			case 'epg.today': return 'Vandaag';
			case 'epg.tomorrow': return 'Morgen';
			case 'epg.noPrograms': return 'Geen programma-informatie beschikbaar';
			case 'epg.loading': return 'Gids laden...';
			case 'epg.record': return 'Opnemen';
			case 'epg.reminder': return 'Herinnering instellen';
			case 'epg.moreInfo': return 'Meer info';
			case 'epg.toggleView': return 'Wissel weergave';
			case 'epg.gridView': return 'Rasterweergave';
			case 'epg.nowNextView': return 'Nu/Straks weergave';
			case 'channelSurfing.title': return 'Willekeurig kijken';
			case 'channelSurfing.kidsMode': return 'Kindermodus';
			case 'channelSurfing.loading': return 'Willekeurig kijken laden...';
			case 'channelSurfing.failedToLoad': return 'Inhoud kon niet worden geladen';
			case 'channelSurfing.retry': return 'Opnieuw proberen';
			case 'channelSurfing.noContent': return 'Geen inhoud beschikbaar';
			case 'channelSurfing.itemsAvailable': return ({required Object count}) => '${count} items beschikbaar';
			case 'channelSurfing.startSurfing': return 'Starten';
			case 'channelSurfing.pressBackToExit': return 'Druk terug om af te sluiten';
			case 'channelSurfing.description': return 'Kijk willekeurige films en series doorlopend';
			case 'channelSurfing.noServers': return 'Geen servers beschikbaar';
			case 'multiview.title': return 'Multi-View';
			case 'multiview.changeLayout': return 'Layout wijzigen (L)';
			case 'multiview.addChannel': return 'Zender toevoegen (A)';
			case 'multiview.removeChannel': return 'Zender verwijderen (R)';
			case 'multiview.swapChannel': return 'Zender wijzigen';
			case 'multiview.toggleMute': return 'Geluid aan/uit (M)';
			case 'multiview.selectChannel': return 'Zender selecteren';
			case 'multiview.searchChannels': return 'Zenders zoeken...';
			case 'multiview.cancel': return 'Annuleren';
			case 'multiview.channelNumber': return ({required Object number}) => 'Z. ${number}';
			case 'player.playbackError': return 'Afspeelfout';
			case 'player.error': return 'Fout';
			case 'player.failedToStartPlayback': return ({required Object error}) => 'Kan afspelen niet starten:\n${error}';
			case 'player.ok': return 'OK';
			case 'downloads.title': return 'Downloads';
			case 'downloads.deleteAll': return 'Alles verwijderen';
			case 'downloads.deleteAllTitle': return 'Alle downloads verwijderen?';
			case 'downloads.deleteAllMessage': return ({required Object count, required Object size}) => 'Dit verwijdert alle ${count} downloads en maakt ${size} opslagruimte vrij.';
			case 'downloads.storageUsed': return ({required Object size}) => 'Opslag gebruikt: ${size}';
			case 'downloads.downloading': return ({required Object count}) => 'Downloaden (${count})';
			case 'downloads.downloaded': return ({required Object count}) => 'Gedownload (${count})';
			case 'downloads.noDownloads': return 'Geen downloads';
			case 'downloads.noDownloadsHint': return 'Download films en series om offline te bekijken';
			case 'downloads.deleteDownloadTitle': return 'Download verwijderen?';
			case 'downloads.deleteDownloadMessage': return ({required Object title}) => '"${title}" verwijderen?';
			case 'downloads.delete': return 'Verwijderen';
			case 'downloads.cancel': return 'Annuleren';
			case 'downloads.downloadFailed': return 'Download mislukt';
			case 'downloads.paused': return 'Gepauzeerd';
			default: return null;
		}
	}
}

extension on _StringsSv {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'OpenFlix';
			case 'app.loading': return 'Laddar...';
			case 'auth.signIn': return 'Logga in';
			case 'auth.signUp': return 'Registrera';
			case 'auth.signInWithPlex': return 'Logga in på OpenFlix';
			case 'auth.showQRCode': return 'Visa QR-kod';
			case 'auth.cancel': return 'Avbryt';
			case 'auth.authenticate': return 'Autentisera';
			case 'auth.retry': return 'Försök igen';
			case 'auth.debugEnterToken': return 'Debug: Ange Token';
			case 'auth.plexTokenLabel': return 'Autentiseringstoken';
			case 'auth.plexTokenHint': return 'Ange token';
			case 'auth.authenticationTimeout': return 'Autentisering tog för lång tid. Försök igen.';
			case 'auth.scanQRCodeInstruction': return 'Skanna denna QR-kod för att autentisera.';
			case 'auth.waitingForAuth': return 'Väntar på autentisering...\nVänligen slutför inloggning i din webbläsare.';
			case 'auth.serverUrl': return 'Server-URL';
			case 'auth.serverUrlHint': return 't.ex. http://192.168.1.100:32400';
			case 'auth.username': return 'Användarnamn';
			case 'auth.usernameHint': return 'Ange användarnamn';
			case 'auth.email': return 'E-post';
			case 'auth.emailHint': return 'Ange e-postadress';
			case 'auth.password': return 'Lösenord';
			case 'auth.passwordHint': return 'Ange lösenord';
			case 'auth.confirmPassword': return 'Bekräfta lösenord';
			case 'auth.confirmPasswordHint': return 'Ange lösenord igen';
			case 'auth.displayName': return 'Visningsnamn';
			case 'auth.displayNameHint': return 'Valfritt visningsnamn';
			case 'auth.noAccount': return 'Inget konto?';
			case 'auth.haveAccount': return 'Har du redan ett konto?';
			case 'auth.connecting': return 'Ansluter till server...';
			case 'auth.loggingIn': return 'Loggar in...';
			case 'auth.registering': return 'Skapar konto...';
			case 'auth.connectToServer': return 'Anslut till Server';
			case 'auth.changeServer': return 'Byt Server';
			case 'auth.serverConnected': return ({required Object serverName}) => 'Ansluten till ${serverName}';
			case 'auth.invalidServerUrl': return 'Ange en giltig server-URL';
			case 'auth.serverConnectionFailed': return 'Kunde inte ansluta till servern';
			case 'auth.passwordMismatch': return 'Lösenorden matchar inte';
			case 'auth.usernameRequired': return 'Användarnamn krävs';
			case 'auth.emailRequired': return 'E-post krävs';
			case 'auth.passwordRequired': return 'Lösenord krävs';
			case 'auth.passwordTooShort': return 'Lösenordet måste vara minst 6 tecken';
			case 'auth.invalidEmail': return 'Ange en giltig e-postadress';
			case 'auth.firstUserNote': return 'Första användaren blir administratör';
			case 'auth.howConnecting': return 'Hur ansluter du?';
			case 'auth.atHome': return 'Hemma';
			case 'auth.atHomeDescription': return 'Upptäck server automatiskt på ditt lokala nätverk';
			case 'auth.awayFromHome': return 'Utanför hemmet';
			case 'auth.awayFromHomeDescription': return 'Ange serveradress manuellt';
			case 'auth.findYourServer': return 'Hitta din server';
			case 'auth.searching': return 'Söker...';
			case 'auth.checkingNetwork': return 'Kontrollerar nätverk...';
			case 'auth.serversFound': return 'Servrar hittade';
			case 'auth.scanAgain': return 'Sök igen';
			case 'auth.enterManually': return 'Ange manuellt';
			case 'auth.noServersFound': return 'Inga servrar hittades på ditt nätverk. Se till att din OpenFlix-server körs.';
			case 'auth.discoveryFailed': return ({required Object error}) => 'Sökning misslyckades: ${error}';
			case 'common.cancel': return 'Avbryt';
			case 'common.save': return 'Spara';
			case 'common.close': return 'Stäng';
			case 'common.clear': return 'Rensa';
			case 'common.reset': return 'Återställ';
			case 'common.later': return 'Senare';
			case 'common.submit': return 'Skicka';
			case 'common.confirm': return 'Bekräfta';
			case 'common.retry': return 'Försök igen';
			case 'common.playNow': return 'Spela nu';
			case 'common.logout': return 'Logga ut';
			case 'common.online': return 'Online';
			case 'common.offline': return 'Offline';
			case 'common.owned': return 'Egen';
			case 'common.shared': return 'Delad';
			case 'common.current': return 'NUVARANDE';
			case 'common.unknown': return 'Okänd';
			case 'common.refresh': return 'Uppdatera';
			case 'common.yes': return 'Ja';
			case 'common.no': return 'Nej';
			case 'common.server': return 'Server';
			case 'common.delete': return 'Ta bort';
			case 'common.shuffle': return 'Blanda';
			case 'common.addTo': return 'Lägg till i...';
			case 'common.remove': return 'Remove';
			case 'common.play': return 'Play';
			case 'common.details': return 'Details';
			case 'common.seeAll': return 'See All';
			case 'common.live': return 'LIVE';
			case 'common.newLabel': return 'NY';
			case 'screens.licenses': return 'Licenser';
			case 'screens.selectServer': return 'Välj server';
			case 'screens.switchProfile': return 'Byt profil';
			case 'screens.subtitleStyling': return 'Undertext-styling';
			case 'screens.search': return 'Sök';
			case 'screens.logs': return 'Loggar';
			case 'update.available': return 'Uppdatering tillgänglig';
			case 'update.versionAvailable': return ({required Object version}) => 'Version ${version} är tillgänglig';
			case 'update.currentVersion': return ({required Object version}) => 'Nuvarande: ${version}';
			case 'update.skipVersion': return 'Hoppa över denna version';
			case 'update.viewRelease': return 'Visa release';
			case 'update.latestVersion': return 'Du har den senaste versionen';
			case 'update.checkFailed': return 'Misslyckades att kontrollera uppdateringar';
			case 'settings.title': return 'Inställningar';
			case 'settings.profile': return 'Profil';
			case 'settings.noProfileSelected': return 'Ingen profil vald';
			case 'settings.kidsMode': return 'Barnläge';
			case 'settings.switchProfile': return 'Byt profil';
			case 'settings.switchProfileDescription': return 'Byt till en annan profil';
			case 'settings.manageProfiles': return 'Hantera profiler';
			case 'settings.manageProfilesDescription': return 'Lägg till, redigera eller ta bort profiler';
			case 'settings.language': return 'Språk';
			case 'settings.theme': return 'Tema';
			case 'settings.appearance': return 'Utseende';
			case 'settings.videoPlayback': return 'Videouppspelning';
			case 'settings.shufflePlay': return 'Blanda uppspelning';
			case 'settings.advanced': return 'Avancerat';
			case 'settings.useSeasonPostersDescription': return 'Visa säsongsaffisch istället för serieaffisch för avsnitt';
			case 'settings.showHeroSectionDescription': return 'Visa utvalda innehållskarusell på startsidan';
			case 'settings.secondsLabel': return 'Sekunder';
			case 'settings.minutesLabel': return 'Minuter';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => 'Ange tid (${min}-${max})';
			case 'settings.systemTheme': return 'System';
			case 'settings.systemThemeDescription': return 'Följ systeminställningar';
			case 'settings.lightTheme': return 'Ljust';
			case 'settings.darkTheme': return 'Mörkt';
			case 'settings.libraryDensity': return 'Biblioteksdensitet';
			case 'settings.compact': return 'Kompakt';
			case 'settings.compactDescription': return 'Mindre kort, fler objekt synliga';
			case 'settings.normal': return 'Normal';
			case 'settings.normalDescription': return 'Standardstorlek';
			case 'settings.comfortable': return 'Bekväm';
			case 'settings.comfortableDescription': return 'Större kort, färre objekt synliga';
			case 'settings.viewMode': return 'Visningsläge';
			case 'settings.gridView': return 'Rutnät';
			case 'settings.gridViewDescription': return 'Visa objekt i rutnätslayout';
			case 'settings.listView': return 'Lista';
			case 'settings.listViewDescription': return 'Visa objekt i listlayout';
			case 'settings.useSeasonPosters': return 'Använd säsongsaffischer';
			case 'settings.showHeroSection': return 'Visa hjältesektion';
			case 'settings.hardwareDecoding': return 'Hårdvaruavkodning';
			case 'settings.hardwareDecodingDescription': return 'Använd hårdvaruacceleration när tillgängligt';
			case 'settings.bufferSize': return 'Bufferstorlek';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return 'Undertext-styling';
			case 'settings.subtitleStylingDescription': return 'Anpassa undertextutseende';
			case 'settings.smallSkipDuration': return 'Kort hoppvaraktighet';
			case 'settings.largeSkipDuration': return 'Lång hoppvaraktighet';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} sekunder';
			case 'settings.defaultSleepTimer': return 'Standard sovtimer';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} minuter';
			case 'settings.rememberTrackSelections': return 'Kom ihåg spårval per serie/film';
			case 'settings.rememberTrackSelectionsDescription': return 'Spara automatiskt ljud- och undertextspråkpreferenser när du ändrar spår under uppspelning';
			case 'settings.unwatchedOnly': return 'Endast osedda';
			case 'settings.unwatchedOnlyDescription': return 'Inkludera endast osedda avsnitt i blandningskön';
			case 'settings.shuffleOrderNavigation': return 'Blandningsordning-navigation';
			case 'settings.shuffleOrderNavigationDescription': return 'Nästa/föregående knappar följer blandad ordning';
			case 'settings.loopShuffleQueue': return 'Loopa blandningskö';
			case 'settings.loopShuffleQueueDescription': return 'Starta om kö när slutet nås';
			case 'settings.videoPlayerControls': return 'Videospelar-kontroller';
			case 'settings.keyboardShortcuts': return 'Tangentbordsgenvägar';
			case 'settings.keyboardShortcutsDescription': return 'Anpassa tangentbordsgenvägar';
			case 'settings.debugLogging': return 'Felsökningsloggning';
			case 'settings.debugLoggingDescription': return 'Aktivera detaljerad loggning för felsökning';
			case 'settings.viewLogs': return 'Visa loggar';
			case 'settings.viewLogsDescription': return 'Visa applikationsloggar';
			case 'settings.clearCache': return 'Rensa cache';
			case 'settings.clearCacheDescription': return 'Detta rensar alla cachade bilder och data. Appen kan ta längre tid att ladda innehåll efter cache-rensning.';
			case 'settings.clearCacheSuccess': return 'Cache rensad framgångsrikt';
			case 'settings.resetSettings': return 'Återställ inställningar';
			case 'settings.resetSettingsDescription': return 'Detta återställer alla inställningar till standardvärden. Denna åtgärd kan inte ångras.';
			case 'settings.resetSettingsSuccess': return 'Inställningar återställda framgångsrikt';
			case 'settings.shortcutsReset': return 'Genvägar återställda till standard';
			case 'settings.about': return 'Om';
			case 'settings.aboutDescription': return 'Appinformation och licenser';
			case 'settings.updates': return 'Uppdateringar';
			case 'settings.updateAvailable': return 'Uppdatering tillgänglig';
			case 'settings.checkForUpdates': return 'Kontrollera uppdateringar';
			case 'settings.validationErrorEnterNumber': return 'Vänligen ange ett giltigt nummer';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => 'Tiden måste vara mellan ${min} och ${max} ${unit}';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => 'Genväg redan tilldelad ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => 'Genväg uppdaterad för ${action}';
			case 'settings.autoSkip': return 'Auto Hoppa Över';
			case 'settings.autoSkipIntro': return 'Hoppa Över Intro Automatiskt';
			case 'settings.autoSkipIntroDescription': return 'Hoppa automatiskt över intro-markörer efter några sekunder';
			case 'settings.autoSkipCredits': return 'Hoppa Över Credits Automatiskt';
			case 'settings.autoSkipCreditsDescription': return 'Hoppa automatiskt över credits och spela nästa avsnitt';
			case 'settings.autoSkipDelay': return 'Fördröjning Auto Hoppa Över';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => 'Vänta ${seconds} sekunder innan automatisk överhoppning';
			case 'settings.metadataSection': return 'Metadata';
			case 'settings.tmdbApiKey': return 'TMDB API-nyckel';
			case 'settings.tmdbApiKeyDescription': return 'Konfigurera TMDB för förbättrad metadata';
			case 'settings.tmdbApiKeyConfigured': return 'API-nyckel konfigurerad';
			case 'settings.tmdbApiKeyHint': return 'Hämta din API-nyckel från themoviedb.org';
			case 'settings.tmdbApiKeyPlaceholder': return 'Ange din TMDB API-nyckel';
			case 'settings.apiKey': return 'API-nyckel';
			case 'settings.tmdbApiKeySaved': return 'TMDB API-nyckel sparad';
			case 'settings.tmdbApiKeyCleared': return 'TMDB API-nyckel raderad';
			case 'settings.parentalControls': return 'Föräldrakontroll';
			case 'settings.enableParentalControls': return 'Aktivera Föräldrakontroll';
			case 'settings.enableParentalControlsDescription': return 'Begränsa innehåll baserat på åldersgränser';
			case 'settings.setPin': return 'Ställ in PIN';
			case 'settings.setPinDescription': return 'Ange en 4-siffrig PIN för att skydda inställningarna';
			case 'settings.confirmPin': return 'Bekräfta PIN';
			case 'settings.confirmPinDescription': return 'Ange PIN igen för att bekräfta';
			case 'settings.enterPin': return 'Ange PIN';
			case 'settings.enterPinDescription': return 'Ange din föräldrakontroll-PIN';
			case 'settings.changePin': return 'Ändra PIN';
			case 'settings.changePinDescription': return 'Ändra din föräldrakontroll-PIN';
			case 'settings.pinSet': return 'Föräldrakontroll-PIN har ställts in';
			case 'settings.pinMismatch': return 'PIN-koderna matchar inte. Försök igen.';
			case 'settings.incorrectPin': return 'Felaktig PIN. Försök igen.';
			case 'settings.maxMovieRating': return 'Maximal Filmklassificering';
			case 'settings.maxTvRating': return 'Maximal TV-klassificering';
			case 'search.hint': return 'Sök filmer, serier, musik...';
			case 'search.tryDifferentTerm': return 'Prova en annan sökterm';
			case 'search.searchYourMedia': return 'Sök i dina media';
			case 'search.enterTitleActorOrKeyword': return 'Ange en titel, skådespelare eller nyckelord';
			case 'search.recentSearches': return 'Senaste sökningar';
			case 'search.clear': return 'Rensa';
			case 'search.voiceSearch': return 'Röstsökning';
			case 'search.listening': return 'Lyssnar...';
			case 'search.speakNow': return 'Tala nu';
			case 'search.all': return 'Alla';
			case 'search.movies': return 'Filmer';
			case 'search.tvShows': return 'TV-serier';
			case 'search.music': return 'Musik';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => 'Sätt genväg för ${actionName}';
			case 'hotkeys.clearShortcut': return 'Rensa genväg';
			case 'pinEntry.enterPin': return 'Ange PIN';
			case 'pinEntry.showPin': return 'Visa PIN';
			case 'pinEntry.hidePin': return 'Dölj PIN';
			case 'fileInfo.title': return 'Filinformation';
			case 'fileInfo.video': return 'Video';
			case 'fileInfo.audio': return 'Ljud';
			case 'fileInfo.file': return 'Fil';
			case 'fileInfo.advanced': return 'Avancerat';
			case 'fileInfo.codec': return 'Kodek';
			case 'fileInfo.resolution': return 'Upplösning';
			case 'fileInfo.bitrate': return 'Bithastighet';
			case 'fileInfo.frameRate': return 'Bildfrekvens';
			case 'fileInfo.aspectRatio': return 'Bildförhållande';
			case 'fileInfo.profile': return 'Profil';
			case 'fileInfo.bitDepth': return 'Bitdjup';
			case 'fileInfo.colorSpace': return 'Färgrymd';
			case 'fileInfo.colorRange': return 'Färgområde';
			case 'fileInfo.colorPrimaries': return 'Färggrunder';
			case 'fileInfo.chromaSubsampling': return 'Kroma-undersampling';
			case 'fileInfo.channels': return 'Kanaler';
			case 'fileInfo.path': return 'Sökväg';
			case 'fileInfo.size': return 'Storlek';
			case 'fileInfo.container': return 'Container';
			case 'fileInfo.duration': return 'Varaktighet';
			case 'fileInfo.optimizedForStreaming': return 'Optimerad för streaming';
			case 'fileInfo.has64bitOffsets': return '64-bit offset';
			case 'mediaMenu.markAsWatched': return 'Markera som sedd';
			case 'mediaMenu.markAsUnwatched': return 'Markera som osedd';
			case 'mediaMenu.removeFromContinueWatching': return 'Ta bort från Fortsätt titta';
			case 'mediaMenu.goToSeries': return 'Gå till serie';
			case 'mediaMenu.goToSeason': return 'Gå till säsong';
			case 'mediaMenu.shufflePlay': return 'Blanda uppspelning';
			case 'mediaMenu.fileInfo': return 'Filinformation';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, film';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, TV-serie';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return 'sedd';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '${percent} procent sedd';
			case 'accessibility.mediaCardUnwatched': return 'osedd';
			case 'accessibility.tapToPlay': return 'Tryck för att spela';
			case 'tooltips.shufflePlay': return 'Blanda uppspelning';
			case 'tooltips.markAsWatched': return 'Markera som sedd';
			case 'tooltips.markAsUnwatched': return 'Markera som osedd';
			case 'videoControls.audioLabel': return 'Ljud';
			case 'videoControls.subtitlesLabel': return 'Undertexter';
			case 'videoControls.resetToZero': return 'Återställ till 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} spelas senare';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} spelas tidigare';
			case 'videoControls.noOffset': return 'Ingen offset';
			case 'videoControls.letterbox': return 'Letterbox';
			case 'videoControls.fillScreen': return 'Fyll skärm';
			case 'videoControls.stretch': return 'Sträck';
			case 'videoControls.lockRotation': return 'Lås rotation';
			case 'videoControls.unlockRotation': return 'Lås upp rotation';
			case 'videoControls.lockScreen': return 'Lås skärm';
			case 'videoControls.unlockScreen': return 'Lås upp skärm';
			case 'videoControls.screenLockButton': return 'Skärmlås';
			case 'videoControls.screenLocked': return 'Skärmen låst';
			case 'videoControls.tapToUnlock': return 'Tryck för att låsa upp';
			case 'videoControls.sleepTimer': return 'Sovtimer';
			case 'videoControls.timerActive': return 'Timer aktiv';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => 'Uppspelningen pausas om ${duration}';
			case 'videoControls.sleepTimerCompleted': return 'Sovtimer slutförd - uppspelning pausad';
			case 'videoControls.playButton': return 'Spela';
			case 'videoControls.pauseButton': return 'Pausa';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => 'Spola bakåt ${seconds} sekunder';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => 'Spola framåt ${seconds} sekunder';
			case 'videoControls.previousButton': return 'Föregående avsnitt';
			case 'videoControls.nextButton': return 'Nästa avsnitt';
			case 'videoControls.previousChapterButton': return 'Föregående kapitel';
			case 'videoControls.nextChapterButton': return 'Nästa kapitel';
			case 'videoControls.volumeButton': return 'Volym';
			case 'videoControls.muteButton': return 'Tysta';
			case 'videoControls.unmuteButton': return 'Slå på ljud';
			case 'videoControls.settingsButton': return 'Videoinställningar';
			case 'videoControls.audioTrackButton': return 'Ljudspår';
			case 'videoControls.subtitlesButton': return 'Undertexter';
			case 'videoControls.chaptersButton': return 'Kapitel';
			case 'videoControls.versionsButton': return 'Videoversioner';
			case 'videoControls.aspectRatioButton': return 'Bildförhållande';
			case 'videoControls.fullscreenButton': return 'Aktivera helskärm';
			case 'videoControls.exitFullscreenButton': return 'Avsluta helskärm';
			case 'videoControls.rotationLockButton': return 'Rotationslås';
			case 'videoControls.timelineSlider': return 'Videotidslinje';
			case 'videoControls.volumeSlider': return 'Volymnivå';
			case 'videoControls.backButton': return 'Tillbaka';
			case 'userStatus.admin': return 'Admin';
			case 'userStatus.restricted': return 'Begränsad';
			case 'userStatus.protected': return 'Skyddad';
			case 'userStatus.current': return 'NUVARANDE';
			case 'messages.markedAsWatched': return 'Markerad som sedd';
			case 'messages.markedAsUnwatched': return 'Markerad som osedd';
			case 'messages.removedFromContinueWatching': return 'Borttagen från Fortsätt titta';
			case 'messages.errorLoading': return ({required Object error}) => 'Fel: ${error}';
			case 'messages.fileInfoNotAvailable': return 'Filinformation inte tillgänglig';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => 'Fel vid laddning av filinformation: ${error}';
			case 'messages.errorLoadingSeries': return 'Fel vid laddning av serie';
			case 'messages.errorLoadingSeason': return 'Fel vid laddning av säsong';
			case 'messages.musicNotSupported': return 'Musikuppspelning stöds inte ännu';
			case 'messages.logsCleared': return 'Loggar rensade';
			case 'messages.logsCopied': return 'Loggar kopierade till urklipp';
			case 'messages.noLogsAvailable': return 'Inga loggar tillgängliga';
			case 'messages.libraryScanning': return ({required Object title}) => 'Skannar "${title}"...';
			case 'messages.libraryScanStarted': return ({required Object title}) => 'Biblioteksskanning startad för "${title}"';
			case 'messages.libraryScanFailed': return ({required Object error}) => 'Misslyckades att skanna bibliotek: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => 'Uppdaterar metadata för "${title}"...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => 'Metadata-uppdatering startad för "${title}"';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => 'Misslyckades att uppdatera metadata: ${error}';
			case 'messages.noTokenFound': return 'Ingen token hittad. Vänligen logga in igen.';
			case 'messages.logoutConfirm': return 'Är du säker på att du vill logga ut?';
			case 'messages.noSeasonsFound': return 'Inga säsonger hittades';
			case 'messages.noEpisodesFound': return 'Inga avsnitt hittades i första säsongen';
			case 'messages.noEpisodesFoundGeneral': return 'Inga avsnitt hittades';
			case 'messages.noResultsFound': return 'Inga resultat hittades';
			case 'messages.sleepTimerSet': return ({required Object label}) => 'Sovtimer inställd för ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
			case 'messages.noItemsAvailable': return 'Inga objekt tillgängliga';
			case 'messages.failedToCreatePlayQueue': return 'Det gick inte att skapa uppspelningskö';
			case 'messages.failedToCreatePlayQueueNoItems': return 'Det gick inte att skapa uppspelningskö – inga objekt';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => 'Kunde inte ${action}: ${error}';
			case 'profile.noUsersAvailable': return 'Inga användare tillgängliga';
			case 'subtitlingStyling.stylingOptions': return 'Stilalternativ';
			case 'subtitlingStyling.fontSize': return 'Teckenstorlek';
			case 'subtitlingStyling.textColor': return 'Textfärg';
			case 'subtitlingStyling.borderSize': return 'Kantstorlek';
			case 'subtitlingStyling.borderColor': return 'Kantfärg';
			case 'subtitlingStyling.backgroundOpacity': return 'Bakgrundsopacitet';
			case 'subtitlingStyling.backgroundColor': return 'Bakgrundsfärg';
			case 'dialog.confirmAction': return 'Bekräfta åtgärd';
			case 'dialog.areYouSure': return 'Är du säker på att du vill utföra denna åtgärd?';
			case 'dialog.cancel': return 'Avbryt';
			case 'dialog.playNow': return 'Spela nu';
			case 'discover.title': return 'Upptäck';
			case 'discover.switchProfile': return 'Byt profil';
			case 'discover.switchServer': return 'Byt server';
			case 'discover.logout': return 'Logga ut';
			case 'discover.noContentAvailable': return 'Inget innehåll tillgängligt';
			case 'discover.addMediaToLibraries': return 'Lägg till media till dina bibliotek';
			case 'discover.continueWatching': return 'Fortsätt titta';
			case 'discover.recentlyAdded': return 'Nyligen tillagda';
			case 'discover.play': return 'Spela';
			case 'discover.resume': return 'Återuppta';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => 'Spela S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => 'Återuppta S${season}, E${episode}';
			case 'discover.pause': return 'Pausa';
			case 'discover.overview': return 'Översikt';
			case 'discover.cast': return 'Rollbesättning';
			case 'discover.seasons': return 'Säsonger';
			case 'discover.studio': return 'Studio';
			case 'discover.rating': return 'Åldersgräns';
			case 'discover.watched': return 'Tittad';
			case 'discover.episodeCount': return ({required Object count}) => '${count} avsnitt';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '${watched}/${total} sedda';
			case 'discover.movie': return 'Film';
			case 'discover.tvShow': return 'TV-serie';
			case 'discover.minutesLeft': return ({required Object minutes}) => '${minutes} min kvar';
			case 'discover.whatsOnNow': return 'Sänds nu';
			case 'discover.channelGuide': return 'TV-guide';
			case 'discover.liveNow': return 'Live nu';
			case 'discover.topTen': return 'Topp 10';
			case 'discover.newBadge': return 'NY';
			case 'discover.liveBadge': return 'LIVE';
			case 'discover.goodMorning': return 'Good morning';
			case 'discover.goodAfternoon': return 'Good afternoon';
			case 'discover.goodEvening': return 'Good evening';
			case 'discover.defaultUser': return 'Guest';
			case 'discover.yourNextWatch': return 'Your Next Watch';
			case 'discover.pickedForYou': return ({required Object name}) => 'Picked just for you, ${name}';
			case 'discover.surpriseMe': return 'Surprise Me';
			case 'discover.randomPicker': return 'Random Movie Picker';
			case 'discover.noMoviesFound': return 'No movies found in your library';
			case 'discover.spinning': return 'Picking something great...';
			case 'discover.spinAgain': return 'Spin Again';
			case 'discover.calendar': return 'Calendar';
			case 'discover.today': return 'Today';
			case 'discover.item': return 'item';
			case 'discover.items': return 'items';
			case 'discover.loadingMovies': return 'Laddar dina filmer...';
			case 'discover.noContentOnDate': return 'No content added on this date';
			case 'discover.noEpgData': return 'Ingen programinformation';
			case 'errors.searchFailed': return ({required Object error}) => 'Sökning misslyckades: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => 'Anslutnings-timeout vid laddning ${context}';
			case 'errors.connectionFailed': return 'Kan inte ansluta till Plex-server';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => 'Misslyckades att ladda ${context}: ${error}';
			case 'errors.noClientAvailable': return 'Ingen klient tillgänglig';
			case 'errors.authenticationFailed': return ({required Object error}) => 'Autentisering misslyckades: ${error}';
			case 'errors.couldNotLaunchUrl': return 'Kunde inte öppna autentiserings-URL';
			case 'errors.pleaseEnterToken': return 'Vänligen ange en token';
			case 'errors.invalidToken': return 'Ogiltig token';
			case 'errors.failedToVerifyToken': return ({required Object error}) => 'Misslyckades att verifiera token: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
			case 'errors.connectionFailedGeneric': return 'Anslutning misslyckades';
			case 'errors.failedToRemove': return ({required Object error}) => 'Misslyckades att ta bort: ${error}';
			case 'voice.notAvailable': return 'Röststyrning är inte tillgänglig';
			case 'voice.commandNotRecognized': return ({required Object command}) => 'Kommando inte igenkänt: "${command}"';
			case 'libraries.title': return 'Bibliotek';
			case 'libraries.scanLibraryFiles': return 'Skanna biblioteksfiler';
			case 'libraries.scanLibrary': return 'Skanna bibliotek';
			case 'libraries.analyze': return 'Analysera';
			case 'libraries.analyzeLibrary': return 'Analysera bibliotek';
			case 'libraries.refreshMetadata': return 'Uppdatera metadata';
			case 'libraries.emptyTrash': return 'Töm papperskorg';
			case 'libraries.emptyingTrash': return ({required Object title}) => 'Tömmer papperskorg för "${title}"...';
			case 'libraries.trashEmptied': return ({required Object title}) => 'Papperskorg tömd för "${title}"';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => 'Misslyckades att tömma papperskorg: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => 'Analyserar "${title}"...';
			case 'libraries.analysisStarted': return ({required Object title}) => 'Analys startad för "${title}"';
			case 'libraries.failedToAnalyze': return ({required Object error}) => 'Misslyckades att analysera bibliotek: ${error}';
			case 'libraries.noLibrariesFound': return 'Inga bibliotek hittades';
			case 'libraries.thisLibraryIsEmpty': return 'Detta bibliotek är tomt';
			case 'libraries.all': return 'Alla';
			case 'libraries.clearAll': return 'Rensa alla';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => 'Är du säker på att du vill skanna "${title}"?';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => 'Är du säker på att du vill analysera "${title}"?';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => 'Är du säker på att du vill uppdatera metadata för "${title}"?';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => 'Är du säker på att du vill tömma papperskorgen för "${title}"?';
			case 'libraries.manageLibraries': return 'Hantera bibliotek';
			case 'libraries.sort': return 'Sortera';
			case 'libraries.sortBy': return 'Sortera efter';
			case 'libraries.filters': return 'Filter';
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => 'Laddar bibliotek... (${count} objekt laddade)';
			case 'libraries.confirmActionMessage': return 'Är du säker på att du vill utföra denna åtgärd?';
			case 'libraries.showLibrary': return 'Visa bibliotek';
			case 'libraries.hideLibrary': return 'Dölj bibliotek';
			case 'libraries.libraryOptions': return 'Biblioteksalternativ';
			case 'libraries.content': return 'bibliotekets innehåll';
			case 'libraries.selectLibrary': return 'Välj bibliotek';
			case 'libraries.filtersWithCount': return ({required Object count}) => 'Filter (${count})';
			case 'libraries.noRecommendations': return 'Inga rekommendationer tillgängliga';
			case 'libraries.noCollections': return 'Inga samlingar i det här biblioteket';
			case 'libraries.noFoldersFound': return 'Inga mappar hittades';
			case 'libraries.folders': return 'mappar';
			case 'libraries.tabs.recommended': return 'Rekommenderat';
			case 'libraries.tabs.browse': return 'Bläddra';
			case 'libraries.tabs.collections': return 'Samlingar';
			case 'libraries.tabs.playlists': return 'Spellistor';
			case 'libraries.groupings.all': return 'Alla';
			case 'libraries.groupings.movies': return 'Filmer';
			case 'libraries.groupings.shows': return 'Serier';
			case 'libraries.groupings.seasons': return 'Säsonger';
			case 'libraries.groupings.episodes': return 'Avsnitt';
			case 'libraries.groupings.folders': return 'Mappar';
			case 'about.title': return 'Om';
			case 'about.openSourceLicenses': return 'Öppen källkod-licenser';
			case 'about.versionLabel': return ({required Object version}) => 'Version ${version}';
			case 'about.appDescription': return 'En vacker Plex-klient för Flutter';
			case 'about.viewLicensesDescription': return 'Visa licenser för tredjepartsbibliotek';
			case 'serverSelection.connectingToServer': return 'Ansluter till server...';
			case 'serverSelection.connectingToAllServers': return 'Ansluter till alla servrar...';
			case 'serverSelection.connectToAllServers': return 'Anslut till alla servrar';
			case 'serverSelection.allServerConnectionsFailed': return 'Misslyckades att ansluta till servrar. Kontrollera ditt nätverk och försök igen.';
			case 'serverSelection.foundServers': return ({required Object count}) => 'Hittade ${count} server(ar)';
			case 'serverSelection.orSelectIndividually': return 'Eller välj en server individuellt:';
			case 'serverSelection.serverDebugCopied': return 'Server-felsökningsdata kopierad till urklipp';
			case 'serverSelection.copyDebugData': return 'Kopiera felsökningsdata';
			case 'serverSelection.noServersFound': return 'Inga servrar hittades';
			case 'serverSelection.malformedServerData': return ({required Object count}) => 'Hittade ${count} server(ar) med felformaterad data. Inga giltiga servrar tillgängliga.';
			case 'serverSelection.incompleteServerInfo': return 'Vissa servrar har ofullständig information och hoppades över. Vänligen kontrollera ditt Plex.tv-konto.';
			case 'serverSelection.incompleteConnectionInfo': return 'Server-anslutningsinformation är ofullständig. Försök igen.';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => 'Serverinformation är felformaterad: ${message}';
			case 'serverSelection.networkConnectionFailed': return 'Nätverksanslutning misslyckades. Kontrollera din internetanslutning och försök igen.';
			case 'serverSelection.authenticationFailed': return 'Autentisering misslyckades. Logga in igen.';
			case 'serverSelection.plexServiceUnavailable': return 'Plex-tjänst otillgänglig. Försök igen senare.';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => 'Misslyckades att ladda servrar: ${error}';
			case 'hubDetail.title': return 'Titel';
			case 'hubDetail.releaseYear': return 'Utgivningsår';
			case 'hubDetail.dateAdded': return 'Datum tillagd';
			case 'hubDetail.rating': return 'Betyg';
			case 'hubDetail.noItemsFound': return 'Inga objekt hittades';
			case 'logs.title': return 'Loggar';
			case 'logs.clearLogs': return 'Rensa loggar';
			case 'logs.copyLogs': return 'Kopiera loggar';
			case 'logs.exportLogs': return 'Exportera loggar';
			case 'logs.noLogsToShow': return 'Inga loggar att visa';
			case 'logs.error': return 'Fel:';
			case 'logs.stackTrace': return 'Stack trace:';
			case 'stats.title': return 'Tittarstatistik';
			case 'stats.totalWatchTime': return 'Total Tittartid';
			case 'stats.moviesWatched': return 'Filmer Sedda';
			case 'stats.episodesWatched': return 'Avsnitt Sedda';
			case 'stats.avgPerDay': return 'Genomsnitt per Dag';
			case 'stats.topGenres': return 'Favoritgenrer';
			case 'stats.monthlyActivity': return 'Månadsaktivitet';
			case 'stats.noData': return 'Ingen tittarhistorik ännu';
			case 'stats.startWatching': return 'Börja titta för att se din statistik';
			case 'stats.days': return 'dagar';
			case 'licenses.relatedPackages': return 'Relaterade paket';
			case 'licenses.license': return 'Licens';
			case 'licenses.licenseNumber': return ({required Object number}) => 'Licens ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} licenser';
			case 'navigation.home': return 'Hem';
			case 'navigation.search': return 'Sök';
			case 'navigation.libraries': return 'Bibliotek';
			case 'navigation.livetv': return 'Live TV';
			case 'navigation.settings': return 'Inställningar';
			case 'playlists.title': return 'Spellistor';
			case 'playlists.noPlaylists': return 'Inga spellistor hittades';
			case 'playlists.create': return 'Skapa spellista';
			case 'playlists.newPlaylist': return 'Ny spellista';
			case 'playlists.playlistName': return 'Spellistans namn';
			case 'playlists.enterPlaylistName': return 'Ange spellistans namn';
			case 'playlists.edit': return 'Redigera spellista';
			case 'playlists.delete': return 'Ta bort spellista';
			case 'playlists.addTo': return 'Lägg till i spellista';
			case 'playlists.addItems': return 'Lägg till objekt';
			case 'playlists.removeItem': return 'Ta bort från spellista';
			case 'playlists.clearPlaylist': return 'Rensa spellista';
			case 'playlists.playAll': return 'Spela alla';
			case 'playlists.shuffle': return 'Blanda';
			case 'playlists.smartPlaylist': return 'Smart spellista';
			case 'playlists.regularPlaylist': return 'Vanlig spellista';
			case 'playlists.itemCount': return ({required Object count}) => '${count} objekt';
			case 'playlists.oneItem': return '1 objekt';
			case 'playlists.emptyPlaylist': return 'Denna spellista är tom';
			case 'playlists.deleteConfirm': return 'Ta bort spellista?';
			case 'playlists.deleteMessage': return ({required Object name}) => 'Är du säker på att du vill ta bort "${name}"?';
			case 'playlists.created': return 'Spellista skapad';
			case 'playlists.updated': return 'Spellista uppdaterad';
			case 'playlists.deleted': return 'Spellista borttagen';
			case 'playlists.itemAdded': return 'Tillagd i spellista';
			case 'playlists.itemRemoved': return 'Borttagen från spellista';
			case 'playlists.selectPlaylist': return 'Välj spellista';
			case 'playlists.createNewPlaylist': return 'Skapa ny spellista';
			case 'playlists.errorCreating': return 'Det gick inte att skapa spellista';
			case 'playlists.errorDeleting': return 'Det gick inte att ta bort spellista';
			case 'playlists.errorLoading': return 'Det gick inte att ladda spellistor';
			case 'playlists.errorAdding': return 'Det gick inte att lägga till i spellista';
			case 'playlists.errorReordering': return 'Det gick inte att omordna spellisteobjekt';
			case 'playlists.errorRemoving': return 'Det gick inte att ta bort från spellista';
			case 'playlists.playlist': return 'Spellista';
			case 'collections.title': return 'Samlingar';
			case 'collections.collection': return 'Samling';
			case 'collections.empty': return 'Samlingen är tom';
			case 'collections.noItems': return 'Inga objekt i den här samlingen';
			case 'collections.unknownLibrarySection': return 'Kan inte ta bort: okänd bibliotekssektion';
			case 'collections.deleteCollection': return 'Ta bort samling';
			case 'collections.deleteConfirm': return ({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Detta går inte att ångra.';
			case 'collections.deleted': return 'Samling borttagen';
			case 'collections.deleteFailed': return 'Det gick inte att ta bort samlingen';
			case 'collections.deleteFailedWithError': return ({required Object error}) => 'Det gick inte att ta bort samlingen: ${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => 'Det gick inte att läsa in samlingsobjekt: ${error}';
			case 'collections.addTo': return 'Lägg till i samling';
			case 'collections.selectCollection': return 'Välj samling';
			case 'collections.createNewCollection': return 'Skapa ny samling';
			case 'collections.collectionName': return 'Samlingsnamn';
			case 'collections.enterCollectionName': return 'Ange samlingsnamn';
			case 'collections.addedToCollection': return 'Tillagd i samling';
			case 'collections.errorAddingToCollection': return 'Fel vid tillägg i samling';
			case 'collections.created': return 'Samling skapad';
			case 'collections.removeFromCollection': return 'Ta bort från samling';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => 'Ta bort "${title}" från denna samling?';
			case 'collections.removedFromCollection': return 'Borttagen från samling';
			case 'collections.removeFromCollectionFailed': return 'Misslyckades med att ta bort från samling';
			case 'collections.removeFromCollectionError': return ({required Object error}) => 'Fel vid borttagning från samling: ${error}';
			case 'watchParty.title': return 'Watch Party';
			case 'watchParty.startParty': return 'Starta Watch Party';
			case 'watchParty.joinParty': return 'Gå med i Party';
			case 'watchParty.enterCode': return 'Ange party-kod';
			case 'watchParty.shareCode': return 'Dela denna kod';
			case 'watchParty.friendsCanJoin': return 'Vänner kan gå med med denna kod';
			case 'watchParty.participants': return 'Deltagare';
			case 'watchParty.host': return 'Värd';
			case 'watchParty.endParty': return 'Avsluta Party';
			case 'watchParty.leaveParty': return 'Lämna Party';
			case 'watchParty.partyEnded': return 'Watch Party avslutad';
			case 'watchParty.chat': return 'Chatt';
			case 'watchParty.typeMessage': return 'Skriv ett meddelande...';
			case 'watchParty.joined': return ({required Object name}) => '${name} gick med';
			case 'watchParty.left': return ({required Object name}) => '${name} lämnade';
			case 'watchParty.syncedPlayback': return 'Uppspelning är synkroniserad med party';
			case 'watchParty.hostControls': return 'Endast värden kan styra uppspelningen';
			case 'watchParty.creating': return 'Skapar party...';
			case 'watchParty.joining': return 'Går med i party...';
			case 'watchParty.createFailed': return 'Misslyckades att skapa party';
			case 'watchParty.joinFailed': return 'Misslyckades att gå med i party';
			case 'watchParty.invalidCode': return 'Ogiltig party-kod';
			case 'watchParty.gotIt': return 'Uppfattat';
			case 'catchUp.title': return 'Catch Up TV';
			case 'catchUp.startOver': return 'Börja om';
			case 'catchUp.startOverDescription': return 'Se från början';
			case 'catchUp.watchFromBeginning': return 'Se från början?';
			case 'catchUp.alreadyStarted': return ({required Object title}) => '"${title}" har redan börjat. Du kan se från början.';
			case 'catchUp.watchLive': return 'Se Live';
			case 'catchUp.programsAvailable': return 'Tillgängliga program';
			case 'catchUp.noProgramsAvailable': return 'Inga catch-up program tillgängliga';
			case 'catchUp.programsWillAppear': return 'Program visas här efterhand som de sänds';
			case 'catchUp.unavailable': return 'Inte tillgänglig';
			case 'catchUp.bufferNotReady': return 'Buffer inte redo än';
			case 'catchUp.rewind': return 'Spola tillbaka';
			case 'catchUp.timeshiftEnabled': return 'Time-shift aktiverad';
			case 'catchUp.goBackTo': return ({required Object time}) => 'Gå tillbaka till ${time}';
			case 'watchlist.title': return 'Min bevakningslista';
			case 'watchlist.all': return 'Alla';
			case 'watchlist.movies': return 'Filmer';
			case 'watchlist.shows': return 'TV-serier';
			case 'watchlist.episodes': return 'Avsnitt';
			case 'watchlist.empty': return 'Din bevakningslista är tom';
			case 'watchlist.emptyHint': return 'Lägg till filmer och serier till din bevakningslista';
			case 'watchlist.noItemsFiltered': return 'Inga objekt matchar detta filter';
			case 'watchlist.removeTitle': return 'Ta bort från bevakningslista';
			case 'watchlist.removeConfirm': return ({required Object title}) => 'Ta bort "${title}" från din bevakningslista?';
			case 'watchlist.remove': return 'Remove';
			case 'watchlist.play': return 'Play';
			case 'watchlist.details': return 'Details';
			case 'watchlist.seeAll': return 'See All';
			case 'watchlist.clearAllTitle': return 'Rensa bevakningslista';
			case 'watchlist.clearAllConfirm': return ({required Object count}) => 'Ta bort alla ${count} objekt från din bevakningslista?';
			case 'watchlist.clearAll': return 'Rensa allt';
			case 'watchlist.addedToday': return 'Tillagd idag';
			case 'watchlist.addedYesterday': return 'Tillagd igår';
			case 'watchlist.addedDaysAgo': return ({required Object days}) => 'Tillagd för ${days} dagar sedan';
			case 'watchlist.addedOn': return ({required Object date}) => 'Tillagd den ${date}';
			case 'watchlist.addToWatchlist': return 'Lägg till i bevakningslista';
			case 'watchlist.removeFromWatchlist': return 'Ta bort från bevakningslista';
			case 'watchlist.addedToWatchlist': return 'Tillagd i bevakningslista';
			case 'watchlist.removedFromWatchlist': return 'Borttagen från bevakningslista';
			case 'liveTV.title': return 'Live TV';
			case 'liveTV.guide': return 'Guide';
			case 'liveTV.dvr': return 'DVR';
			case 'liveTV.multiview': return 'Multivy';
			case 'liveTV.allChannels': return 'Alla kanaler';
			case 'liveTV.favorites': return 'Favoriter';
			case 'liveTV.noChannels': return 'Inga kanaler tillgängliga';
			case 'liveTV.addM3USource': return 'Lägg till en M3U-källa i serverinställningarna';
			case 'liveTV.recording': return 'Spelar in';
			case 'liveTV.recordingNow': return 'Spelar in nu';
			case 'liveTV.upNext': return 'Nästa';
			case 'liveTV.noProgram': return 'Ingen programinfo';
			case 'liveTV.filterByGroup': return 'Filtrera efter grupp';
			case 'liveTV.refresh': return 'Uppdatera';
			case 'liveTV.channelCount': return ({required Object count}) => '${count} kanaler';
			case 'liveTV.nowPlaying': return 'Sänds nu';
			case 'liveTV.scheduleRecording': return 'Schemalägg inspelning';
			case 'liveTV.onNow': return 'Sänds nu';
			case 'liveTV.endsAt': return ({required Object time}) => 'Slutar ${time}';
			case 'liveTV.startsAt': return ({required Object time}) => 'Börjar ${time}';
			case 'liveTV.playbackError': return ({required Object error}) => 'Uppspelningsfel: ${error}';
			case 'liveTV.noPreviousChannel': return 'Ingen föregående kanal';
			case 'liveTV.switchedTo': return ({required Object channel}) => 'Bytte till: ${channel}';
			case 'liveTV.startingFromBeginning': return 'Startar program från början...';
			case 'liveTV.failedToStartOver': return ({required Object error}) => 'Kunde inte starta om: ${error}';
			case 'liveTV.playingProgram': return ({required Object title}) => 'Spelar: ${title}';
			case 'liveTV.failedToPlayProgram': return ({required Object error}) => 'Kunde inte spela program: ${error}';
			case 'liveTV.addedToFavorites': return 'Tillagd i favoriter';
			case 'liveTV.removedFromFavorites': return 'Borttagen från favoriter';
			case 'liveTV.failedToUpdateFavorite': return ({required Object error}) => 'Kunde inte uppdatera favorit: ${error}';
			case 'liveTV.pipNotSupported': return 'Bild-i-bild stöds inte på denna plattform';
			case 'liveTV.enteredPipMode': return 'Bild-i-bild-läge aktiverat';
			case 'liveTV.exitedPipMode': return 'Bild-i-bild-läge avslutat';
			case 'liveTV.aspectRatioChanged': return ({required Object mode}) => 'Bildförhållande: ${mode}';
			case 'liveTV.tune': return 'Ställ in';
			case 'liveTV.retry': return 'Försök igen';
			case 'liveTV.noChannelsMatchFilter': return 'Inga kanaler matchar filtret';
			case 'liveTV.skipCommercial': return 'Hoppa över reklam';
			case 'dvr.title': return 'DVR';
			case 'dvr.recordings': return 'Inspelningar';
			case 'dvr.seriesRules': return 'Serieregler';
			case 'dvr.noRecordings': return 'Inga inspelningar';
			case 'dvr.noRules': return 'Inga serieregler';
			case 'dvr.scheduleFromGuide': return 'Schemalägg inspelningar från Live TV-guiden';
			case 'dvr.createRulesHint': return 'Skapa regler för att spela in serier automatiskt';
			case 'dvr.storage': return 'Lagring';
			case 'dvr.recordingsCount': return ({required Object count}) => '${count} inspelningar';
			case 'dvr.all': return 'Alla';
			case 'dvr.scheduled': return 'Schemalagda';
			case 'dvr.completed': return 'Slutförda';
			case 'dvr.failed': return 'Misslyckade';
			case 'dvr.deleteRecording': return 'Ta bort inspelning?';
			case 'dvr.deleteRule': return 'Ta bort serieregel?';
			case 'dvr.sortByDate': return 'Datum';
			case 'dvr.sortByTitle': return 'Titel';
			case 'dvr.sortBySize': return 'Storlek';
			case 'dvr.playRecording': return 'Spela inspelning';
			case 'dvr.keepPolicy': return ({required Object count}) => 'Behåll ${count} avsnitt';
			case 'dvr.keepAll': return 'Behåll alla';
			case 'dvr.recordingScheduled': return 'Inspelning schemalagd';
			case 'dvr.scheduleRecordingTitle': return 'Schemalägg inspelning';
			case 'dvr.schedule': return 'Schemalägg';
			case 'dvr.cancel': return 'Avbryt';
			case 'epg.title': return 'TV-guide';
			case 'epg.now': return 'Nu';
			case 'epg.today': return 'Idag';
			case 'epg.tomorrow': return 'Imorgon';
			case 'epg.noPrograms': return 'Ingen programinformation tillgänglig';
			case 'epg.loading': return 'Laddar guide...';
			case 'epg.record': return 'Spela in';
			case 'epg.reminder': return 'Ställ in påminnelse';
			case 'epg.moreInfo': return 'Mer info';
			case 'epg.toggleView': return 'Byt vy';
			case 'epg.gridView': return 'Rutnätsvy';
			case 'epg.nowNextView': return 'Nu/Nästa vy';
			case 'channelSurfing.title': return 'Slumpmässig visning';
			case 'channelSurfing.kidsMode': return 'Barnläge';
			case 'channelSurfing.loading': return 'Laddar slumpmässig visning...';
			case 'channelSurfing.failedToLoad': return 'Kunde inte ladda innehåll';
			case 'channelSurfing.retry': return 'Försök igen';
			case 'channelSurfing.noContent': return 'Inget innehåll tillgängligt';
			case 'channelSurfing.itemsAvailable': return ({required Object count}) => '${count} objekt tillgängliga';
			case 'channelSurfing.startSurfing': return 'Starta';
			case 'channelSurfing.pressBackToExit': return 'Tryck bakåt för att avsluta';
			case 'channelSurfing.description': return 'Se slumpmässiga filmer och serier kontinuerligt';
			case 'channelSurfing.noServers': return 'Inga servrar tillgängliga';
			case 'multiview.title': return 'Multi-Vy';
			case 'multiview.changeLayout': return 'Ändra layout (L)';
			case 'multiview.addChannel': return 'Lägg till kanal (A)';
			case 'multiview.removeChannel': return 'Ta bort kanal (R)';
			case 'multiview.swapChannel': return 'Byt kanal';
			case 'multiview.toggleMute': return 'Ljud av/på (M)';
			case 'multiview.selectChannel': return 'Välj kanal';
			case 'multiview.searchChannels': return 'Sök kanaler...';
			case 'multiview.cancel': return 'Avbryt';
			case 'multiview.channelNumber': return ({required Object number}) => 'K. ${number}';
			case 'player.playbackError': return 'Uppspelningsfel';
			case 'player.error': return 'Fel';
			case 'player.failedToStartPlayback': return ({required Object error}) => 'Kunde inte starta uppspelning:\n${error}';
			case 'player.ok': return 'OK';
			case 'downloads.title': return 'Nedladdningar';
			case 'downloads.deleteAll': return 'Ta bort alla';
			case 'downloads.deleteAllTitle': return 'Ta bort alla nedladdningar?';
			case 'downloads.deleteAllMessage': return ({required Object count, required Object size}) => 'Detta tar bort alla ${count} nedladdningar och frigör ${size} lagringsutrymme.';
			case 'downloads.storageUsed': return ({required Object size}) => 'Lagring använd: ${size}';
			case 'downloads.downloading': return ({required Object count}) => 'Laddar ner (${count})';
			case 'downloads.downloaded': return ({required Object count}) => 'Nedladdat (${count})';
			case 'downloads.noDownloads': return 'Inga nedladdningar';
			case 'downloads.noDownloadsHint': return 'Ladda ner filmer och serier för att se offline';
			case 'downloads.deleteDownloadTitle': return 'Ta bort nedladdning?';
			case 'downloads.deleteDownloadMessage': return ({required Object title}) => 'Ta bort "${title}"?';
			case 'downloads.delete': return 'Ta bort';
			case 'downloads.cancel': return 'Avbryt';
			case 'downloads.downloadFailed': return 'Nedladdning misslyckades';
			case 'downloads.paused': return 'Pausad';
			default: return null;
		}
	}
}

extension on _StringsZh {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'app.title': return 'OpenFlix';
			case 'app.loading': return '加载中...';
			case 'auth.signIn': return '登录';
			case 'auth.signUp': return '注册';
			case 'auth.signInWithPlex': return '登录 OpenFlix';
			case 'auth.showQRCode': return '显示二维码';
			case 'auth.cancel': return '取消';
			case 'auth.authenticate': return '验证';
			case 'auth.retry': return '重试';
			case 'auth.debugEnterToken': return '调试：输入令牌';
			case 'auth.plexTokenLabel': return '授权令牌';
			case 'auth.plexTokenHint': return '输入令牌';
			case 'auth.authenticationTimeout': return '验证超时。请重试。';
			case 'auth.scanQRCodeInstruction': return '扫描此二维码进行验证。';
			case 'auth.waitingForAuth': return '等待验证中...\n请在你的浏览器中完成登录。';
			case 'auth.serverUrl': return '服务器地址';
			case 'auth.serverUrlHint': return '例如 http://192.168.1.100:32400';
			case 'auth.username': return '用户名';
			case 'auth.usernameHint': return '输入用户名';
			case 'auth.email': return '电子邮件';
			case 'auth.emailHint': return '输入电子邮件地址';
			case 'auth.password': return '密码';
			case 'auth.passwordHint': return '输入密码';
			case 'auth.confirmPassword': return '确认密码';
			case 'auth.confirmPasswordHint': return '再次输入密码';
			case 'auth.displayName': return '显示名称';
			case 'auth.displayNameHint': return '可选的显示名称';
			case 'auth.noAccount': return '没有账号？';
			case 'auth.haveAccount': return '已有账号？';
			case 'auth.connecting': return '正在连接服务器...';
			case 'auth.loggingIn': return '正在登录...';
			case 'auth.registering': return '正在创建账号...';
			case 'auth.connectToServer': return '连接服务器';
			case 'auth.changeServer': return '更换服务器';
			case 'auth.serverConnected': return ({required Object serverName}) => '已连接到 ${serverName}';
			case 'auth.invalidServerUrl': return '请输入有效的服务器地址';
			case 'auth.serverConnectionFailed': return '无法连接到服务器';
			case 'auth.passwordMismatch': return '密码不匹配';
			case 'auth.usernameRequired': return '需要用户名';
			case 'auth.emailRequired': return '需要电子邮件';
			case 'auth.passwordRequired': return '需要密码';
			case 'auth.passwordTooShort': return '密码至少需要6个字符';
			case 'auth.invalidEmail': return '请输入有效的电子邮件地址';
			case 'auth.firstUserNote': return '第一个用户将成为管理员';
			case 'auth.howConnecting': return '您要如何连接？';
			case 'auth.atHome': return '在家中';
			case 'auth.atHomeDescription': return '在本地网络中自动检测服务器';
			case 'auth.awayFromHome': return '在外出时';
			case 'auth.awayFromHomeDescription': return '手动输入服务器地址';
			case 'auth.findYourServer': return '查找您的服务器';
			case 'auth.searching': return '搜索中...';
			case 'auth.checkingNetwork': return '正在检查网络...';
			case 'auth.serversFound': return '找到的服务器';
			case 'auth.scanAgain': return '重新扫描';
			case 'auth.enterManually': return '手动输入';
			case 'auth.noServersFound': return '在您的网络中未找到服务器。请确保您的 OpenFlix 服务器正在运行。';
			case 'auth.discoveryFailed': return ({required Object error}) => '搜索失败：${error}';
			case 'common.cancel': return '取消';
			case 'common.save': return '保存';
			case 'common.close': return '关闭';
			case 'common.clear': return '清除';
			case 'common.reset': return '重置';
			case 'common.later': return '稍后';
			case 'common.submit': return '提交';
			case 'common.confirm': return '确认';
			case 'common.retry': return '重试';
			case 'common.playNow': return '立即播放';
			case 'common.logout': return '登出';
			case 'common.online': return '在线';
			case 'common.offline': return '离线';
			case 'common.owned': return '拥有';
			case 'common.shared': return '共享';
			case 'common.current': return '当前';
			case 'common.unknown': return '未知';
			case 'common.refresh': return '刷新';
			case 'common.yes': return '是';
			case 'common.no': return '否';
			case 'common.server': return '服务器';
			case 'common.delete': return '删除';
			case 'common.shuffle': return '随机播放';
			case 'common.addTo': return '添加到...';
			case 'common.remove': return 'Remove';
			case 'common.play': return 'Play';
			case 'common.details': return 'Details';
			case 'common.seeAll': return 'See All';
			case 'common.live': return '直播';
			case 'common.newLabel': return '新';
			case 'screens.licenses': return '许可证';
			case 'screens.selectServer': return '选择服务器';
			case 'screens.switchProfile': return '切换配置文件';
			case 'screens.subtitleStyling': return '字幕样式';
			case 'screens.search': return '搜索';
			case 'screens.logs': return '日志';
			case 'update.available': return '有可用更新';
			case 'update.versionAvailable': return ({required Object version}) => '版本 ${version} 已发布';
			case 'update.currentVersion': return ({required Object version}) => '当前版本: ${version}';
			case 'update.skipVersion': return '跳过此版本';
			case 'update.viewRelease': return '查看发布详情';
			case 'update.latestVersion': return '已安装的版本是可用的最新版本';
			case 'update.checkFailed': return '无法检查更新';
			case 'settings.title': return '设置';
			case 'settings.profile': return '个人资料';
			case 'settings.noProfileSelected': return '未选择个人资料';
			case 'settings.kidsMode': return '儿童模式';
			case 'settings.switchProfile': return '切换个人资料';
			case 'settings.switchProfileDescription': return '切换到其他个人资料';
			case 'settings.manageProfiles': return '管理个人资料';
			case 'settings.manageProfilesDescription': return '添加、编辑或删除个人资料';
			case 'settings.language': return '语言';
			case 'settings.theme': return '主题';
			case 'settings.appearance': return '外观';
			case 'settings.videoPlayback': return '视频播放';
			case 'settings.shufflePlay': return '随机播放';
			case 'settings.advanced': return '高级';
			case 'settings.useSeasonPostersDescription': return '为剧集显示季海报而非剧集海报';
			case 'settings.showHeroSectionDescription': return '在主屏幕上显示精选内容轮播区';
			case 'settings.secondsLabel': return '秒';
			case 'settings.minutesLabel': return '分钟';
			case 'settings.secondsShort': return 's';
			case 'settings.minutesShort': return 'm';
			case 'settings.durationHint': return ({required Object min, required Object max}) => '输入时长 (${min}-${max})';
			case 'settings.systemTheme': return '系统';
			case 'settings.systemThemeDescription': return '跟随系统设置';
			case 'settings.lightTheme': return '浅色';
			case 'settings.darkTheme': return '深色';
			case 'settings.libraryDensity': return '媒体库密度';
			case 'settings.compact': return '紧凑';
			case 'settings.compactDescription': return '卡片更小，显示更多项目';
			case 'settings.normal': return '标准';
			case 'settings.normalDescription': return '默认尺寸';
			case 'settings.comfortable': return '舒适';
			case 'settings.comfortableDescription': return '卡片更大，显示更少项目';
			case 'settings.viewMode': return '视图模式';
			case 'settings.gridView': return '网格视图';
			case 'settings.gridViewDescription': return '以网格布局显示项目';
			case 'settings.listView': return '列表视图';
			case 'settings.listViewDescription': return '以列表布局显示项目';
			case 'settings.useSeasonPosters': return '使用季海报';
			case 'settings.showHeroSection': return '显示主要精选区';
			case 'settings.hardwareDecoding': return '硬件解码';
			case 'settings.hardwareDecodingDescription': return '如果可用，使用硬件加速';
			case 'settings.bufferSize': return '缓冲区大小';
			case 'settings.bufferSizeMB': return ({required Object size}) => '${size}MB';
			case 'settings.subtitleStyling': return '字幕样式';
			case 'settings.subtitleStylingDescription': return '调整字幕外观';
			case 'settings.smallSkipDuration': return '短跳过时长';
			case 'settings.largeSkipDuration': return '长跳过时长';
			case 'settings.secondsUnit': return ({required Object seconds}) => '${seconds} 秒';
			case 'settings.defaultSleepTimer': return '默认睡眠定时器';
			case 'settings.minutesUnit': return ({required Object minutes}) => '${minutes} 分钟';
			case 'settings.rememberTrackSelections': return '记住每个剧集/电影的音轨选择';
			case 'settings.rememberTrackSelectionsDescription': return '在播放过程中更改音轨时自动保存音频和字幕语言偏好';
			case 'settings.unwatchedOnly': return '仅未观看';
			case 'settings.unwatchedOnlyDescription': return '随机队列中仅包含未观看的剧集';
			case 'settings.shuffleOrderNavigation': return '随机顺序导航';
			case 'settings.shuffleOrderNavigationDescription': return '下一集/上一集按钮遵循随机播放顺序';
			case 'settings.loopShuffleQueue': return '循环随机队列';
			case 'settings.loopShuffleQueueDescription': return '在队列结束时重新开始';
			case 'settings.videoPlayerControls': return '视频播放器控制';
			case 'settings.keyboardShortcuts': return '键盘快捷键';
			case 'settings.keyboardShortcutsDescription': return '自定义键盘快捷键';
			case 'settings.debugLogging': return '调试日志';
			case 'settings.debugLoggingDescription': return '启用详细日志记录以便故障排除';
			case 'settings.viewLogs': return '查看日志';
			case 'settings.viewLogsDescription': return '查看应用程序日志';
			case 'settings.clearCache': return '清除缓存';
			case 'settings.clearCacheDescription': return '这将清除所有缓存的图片和数据。清除缓存后，应用程序加载内容可能会变慢。';
			case 'settings.clearCacheSuccess': return '缓存清除成功';
			case 'settings.resetSettings': return '重置设置';
			case 'settings.resetSettingsDescription': return '这会将所有设置重置为其默认值。此操作无法撤销。';
			case 'settings.resetSettingsSuccess': return '设置重置成功';
			case 'settings.shortcutsReset': return '快捷键已重置为默认值';
			case 'settings.about': return '关于';
			case 'settings.aboutDescription': return '应用程序信息和许可证';
			case 'settings.updates': return '更新';
			case 'settings.updateAvailable': return '有可用更新';
			case 'settings.checkForUpdates': return '检查更新';
			case 'settings.validationErrorEnterNumber': return '请输入一个有效的数字';
			case 'settings.validationErrorDuration': return ({required Object min, required Object max, required Object unit}) => '时长必须介于 ${min} 和 ${max} ${unit} 之间';
			case 'settings.shortcutAlreadyAssigned': return ({required Object action}) => '快捷键已被分配给 ${action}';
			case 'settings.shortcutUpdated': return ({required Object action}) => '快捷键已为 ${action} 更新';
			case 'settings.autoSkip': return '自动跳过';
			case 'settings.autoSkipIntro': return '自动跳过片头';
			case 'settings.autoSkipIntroDescription': return '几秒钟后自动跳过片头标记';
			case 'settings.autoSkipCredits': return '自动跳过片尾';
			case 'settings.autoSkipCreditsDescription': return '自动跳过片尾并播放下一集';
			case 'settings.autoSkipDelay': return '自动跳过延迟';
			case 'settings.autoSkipDelayDescription': return ({required Object seconds}) => '自动跳过前等待 ${seconds} 秒';
			case 'settings.metadataSection': return '元数据';
			case 'settings.tmdbApiKey': return 'TMDB API 密钥';
			case 'settings.tmdbApiKeyDescription': return '配置 TMDB 以获取增强元数据';
			case 'settings.tmdbApiKeyConfigured': return 'API 密钥已配置';
			case 'settings.tmdbApiKeyHint': return '从 themoviedb.org 获取你的 API 密钥';
			case 'settings.tmdbApiKeyPlaceholder': return '输入你的 TMDB API 密钥';
			case 'settings.apiKey': return 'API 密钥';
			case 'settings.tmdbApiKeySaved': return 'TMDB API 密钥已保存';
			case 'settings.tmdbApiKeyCleared': return 'TMDB API 密钥已清除';
			case 'settings.parentalControls': return '家长控制';
			case 'settings.enableParentalControls': return '启用家长控制';
			case 'settings.enableParentalControlsDescription': return '根据年龄分级限制内容';
			case 'settings.setPin': return '设置 PIN';
			case 'settings.setPinDescription': return '输入 4 位 PIN 码以保护设置';
			case 'settings.confirmPin': return '确认 PIN';
			case 'settings.confirmPinDescription': return '再次输入 PIN 码进行确认';
			case 'settings.enterPin': return '输入 PIN';
			case 'settings.enterPinDescription': return '输入您的家长控制 PIN 码';
			case 'settings.changePin': return '更改 PIN';
			case 'settings.changePinDescription': return '更改您的家长控制 PIN 码';
			case 'settings.pinSet': return '家长控制 PIN 码设置成功';
			case 'settings.pinMismatch': return 'PIN 码不匹配。请重试。';
			case 'settings.incorrectPin': return 'PIN 码错误。请重试。';
			case 'settings.maxMovieRating': return '最大电影分级';
			case 'settings.maxTvRating': return '最大电视分级';
			case 'search.hint': return '搜索电影、剧集、音乐...';
			case 'search.tryDifferentTerm': return '尝试不同的搜索词';
			case 'search.searchYourMedia': return '搜索媒体';
			case 'search.enterTitleActorOrKeyword': return '输入标题、演员或关键词';
			case 'search.recentSearches': return '最近搜索';
			case 'search.clear': return '清除';
			case 'search.voiceSearch': return '语音搜索';
			case 'search.listening': return '正在听取...';
			case 'search.speakNow': return '请说话';
			case 'search.all': return '全部';
			case 'search.movies': return '电影';
			case 'search.tvShows': return '电视剧';
			case 'search.music': return '音乐';
			case 'hotkeys.setShortcutFor': return ({required Object actionName}) => '为 ${actionName} 设置快捷键';
			case 'hotkeys.clearShortcut': return '清除快捷键';
			case 'pinEntry.enterPin': return '输入 PIN';
			case 'pinEntry.showPin': return '显示 PIN';
			case 'pinEntry.hidePin': return '隐藏 PIN';
			case 'fileInfo.title': return '文件信息';
			case 'fileInfo.video': return '视频';
			case 'fileInfo.audio': return '音频';
			case 'fileInfo.file': return '文件';
			case 'fileInfo.advanced': return '高级';
			case 'fileInfo.codec': return '编解码器';
			case 'fileInfo.resolution': return '分辨率';
			case 'fileInfo.bitrate': return '比特率';
			case 'fileInfo.frameRate': return '帧率';
			case 'fileInfo.aspectRatio': return '宽高比';
			case 'fileInfo.profile': return '配置文件';
			case 'fileInfo.bitDepth': return '位深度';
			case 'fileInfo.colorSpace': return '色彩空间';
			case 'fileInfo.colorRange': return '色彩范围';
			case 'fileInfo.colorPrimaries': return '颜色原色';
			case 'fileInfo.chromaSubsampling': return '色度子采样';
			case 'fileInfo.channels': return '声道';
			case 'fileInfo.path': return '路径';
			case 'fileInfo.size': return '大小';
			case 'fileInfo.container': return '容器';
			case 'fileInfo.duration': return '时长';
			case 'fileInfo.optimizedForStreaming': return '已优化用于流媒体';
			case 'fileInfo.has64bitOffsets': return '64位偏移量';
			case 'mediaMenu.markAsWatched': return '标记为已观看';
			case 'mediaMenu.markAsUnwatched': return '标记为未观看';
			case 'mediaMenu.removeFromContinueWatching': return '从继续观看中移除';
			case 'mediaMenu.goToSeries': return '转到系列';
			case 'mediaMenu.goToSeason': return '转到季';
			case 'mediaMenu.shufflePlay': return '随机播放';
			case 'mediaMenu.fileInfo': return '文件信息';
			case 'accessibility.mediaCardMovie': return ({required Object title}) => '${title}, 电影';
			case 'accessibility.mediaCardShow': return ({required Object title}) => '${title}, 电视剧';
			case 'accessibility.mediaCardEpisode': return ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
			case 'accessibility.mediaCardSeason': return ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
			case 'accessibility.mediaCardWatched': return '已观看';
			case 'accessibility.mediaCardPartiallyWatched': return ({required Object percent}) => '已观看 ${percent} 百分比';
			case 'accessibility.mediaCardUnwatched': return '未观看';
			case 'accessibility.tapToPlay': return '点击播放';
			case 'tooltips.shufflePlay': return '随机播放';
			case 'tooltips.markAsWatched': return '标记为已观看';
			case 'tooltips.markAsUnwatched': return '标记为未观看';
			case 'videoControls.audioLabel': return '音频';
			case 'videoControls.subtitlesLabel': return '字幕';
			case 'videoControls.resetToZero': return '重置为 0ms';
			case 'videoControls.addTime': return ({required Object amount, required Object unit}) => '+${amount}${unit}';
			case 'videoControls.minusTime': return ({required Object amount, required Object unit}) => '-${amount}${unit}';
			case 'videoControls.playsLater': return ({required Object label}) => '${label} 播放较晚';
			case 'videoControls.playsEarlier': return ({required Object label}) => '${label} 播放较早';
			case 'videoControls.noOffset': return '无偏移';
			case 'videoControls.letterbox': return '信箱模式（Letterbox）';
			case 'videoControls.fillScreen': return '填充屏幕';
			case 'videoControls.stretch': return '拉伸';
			case 'videoControls.lockRotation': return '锁定旋转';
			case 'videoControls.unlockRotation': return '解锁旋转';
			case 'videoControls.lockScreen': return '锁定屏幕';
			case 'videoControls.unlockScreen': return '解锁屏幕';
			case 'videoControls.screenLockButton': return '屏幕锁定';
			case 'videoControls.screenLocked': return '屏幕已锁定';
			case 'videoControls.tapToUnlock': return '点击解锁';
			case 'videoControls.sleepTimer': return '睡眠定时器';
			case 'videoControls.timerActive': return '定时器已激活';
			case 'videoControls.playbackWillPauseIn': return ({required Object duration}) => '播放将在 ${duration} 后暂停';
			case 'videoControls.sleepTimerCompleted': return '睡眠定时器已完成 - 播放已暂停';
			case 'videoControls.playButton': return '播放';
			case 'videoControls.pauseButton': return '暂停';
			case 'videoControls.seekBackwardButton': return ({required Object seconds}) => '后退 ${seconds} 秒';
			case 'videoControls.seekForwardButton': return ({required Object seconds}) => '前进 ${seconds} 秒';
			case 'videoControls.previousButton': return '上一集';
			case 'videoControls.nextButton': return '下一集';
			case 'videoControls.previousChapterButton': return '上一章节';
			case 'videoControls.nextChapterButton': return '下一章节';
			case 'videoControls.volumeButton': return '音量';
			case 'videoControls.muteButton': return '静音';
			case 'videoControls.unmuteButton': return '取消静音';
			case 'videoControls.settingsButton': return '视频设置';
			case 'videoControls.audioTrackButton': return '音轨';
			case 'videoControls.subtitlesButton': return '字幕';
			case 'videoControls.chaptersButton': return '章节';
			case 'videoControls.versionsButton': return '视频版本';
			case 'videoControls.aspectRatioButton': return '宽高比';
			case 'videoControls.fullscreenButton': return '进入全屏';
			case 'videoControls.exitFullscreenButton': return '退出全屏';
			case 'videoControls.rotationLockButton': return '旋转锁定';
			case 'videoControls.timelineSlider': return '视频时间轴';
			case 'videoControls.volumeSlider': return '音量调节';
			case 'videoControls.backButton': return '返回';
			case 'userStatus.admin': return '管理员';
			case 'userStatus.restricted': return '受限';
			case 'userStatus.protected': return '受保护';
			case 'userStatus.current': return '当前';
			case 'messages.markedAsWatched': return '已标记为已观看';
			case 'messages.markedAsUnwatched': return '已标记为未观看';
			case 'messages.removedFromContinueWatching': return '已从继续观看中移除';
			case 'messages.errorLoading': return ({required Object error}) => '错误: ${error}';
			case 'messages.fileInfoNotAvailable': return '文件信息不可用';
			case 'messages.errorLoadingFileInfo': return ({required Object error}) => '加载文件信息时出错: ${error}';
			case 'messages.errorLoadingSeries': return '加载系列时出错';
			case 'messages.errorLoadingSeason': return '加载季时出错';
			case 'messages.musicNotSupported': return '尚不支持播放音乐';
			case 'messages.logsCleared': return '日志已清除';
			case 'messages.logsCopied': return '日志已复制到剪贴板';
			case 'messages.noLogsAvailable': return '没有可用日志';
			case 'messages.libraryScanning': return ({required Object title}) => '正在扫描 “${title}”...';
			case 'messages.libraryScanStarted': return ({required Object title}) => '已开始扫描 “${title}” 媒体库';
			case 'messages.libraryScanFailed': return ({required Object error}) => '无法扫描媒体库: ${error}';
			case 'messages.metadataRefreshing': return ({required Object title}) => '正在刷新 “${title}” 的元数据...';
			case 'messages.metadataRefreshStarted': return ({required Object title}) => '已开始刷新 “${title}” 的元数据';
			case 'messages.metadataRefreshFailed': return ({required Object error}) => '无法刷新元数据: ${error}';
			case 'messages.noTokenFound': return '未找到令牌。请重新登录。';
			case 'messages.logoutConfirm': return '你确定要登出吗？';
			case 'messages.noSeasonsFound': return '未找到季';
			case 'messages.noEpisodesFound': return '在第一季中未找到剧集';
			case 'messages.noEpisodesFoundGeneral': return '未找到剧集';
			case 'messages.noResultsFound': return '未找到结果';
			case 'messages.sleepTimerSet': return ({required Object label}) => '睡眠定时器已设置为 ${label}';
			case 'messages.failedToSwitchProfile': return ({required Object displayName}) => '无法切换到 ${displayName}';
			case 'messages.noItemsAvailable': return '没有可用的项目';
			case 'messages.failedToCreatePlayQueue': return '创建播放队列失败';
			case 'messages.failedToCreatePlayQueueNoItems': return '创建播放队列失败 - 没有项目';
			case 'messages.failedPlayback': return ({required Object action, required Object error}) => '无法${action}: ${error}';
			case 'profile.noUsersAvailable': return '没有可用用户';
			case 'subtitlingStyling.stylingOptions': return '样式选项';
			case 'subtitlingStyling.fontSize': return '字号';
			case 'subtitlingStyling.textColor': return '文本颜色';
			case 'subtitlingStyling.borderSize': return '边框大小';
			case 'subtitlingStyling.borderColor': return '边框颜色';
			case 'subtitlingStyling.backgroundOpacity': return '背景不透明度';
			case 'subtitlingStyling.backgroundColor': return '背景颜色';
			case 'dialog.confirmAction': return '确认操作';
			case 'dialog.areYouSure': return '确定要执行此操作吗？';
			case 'dialog.cancel': return '取消';
			case 'dialog.playNow': return '立即播放';
			case 'discover.title': return '发现';
			case 'discover.switchProfile': return '切换配置文件';
			case 'discover.switchServer': return '切换服务器';
			case 'discover.logout': return '登出';
			case 'discover.noContentAvailable': return '没有可用内容';
			case 'discover.addMediaToLibraries': return '请向你的媒体库添加一些媒体';
			case 'discover.continueWatching': return '继续观看';
			case 'discover.recentlyAdded': return '最近添加';
			case 'discover.play': return '播放';
			case 'discover.resume': return '继续';
			case 'discover.playEpisode': return ({required Object season, required Object episode}) => '播放 S${season}, E${episode}';
			case 'discover.resumeEpisode': return ({required Object season, required Object episode}) => '继续 S${season}, E${episode}';
			case 'discover.pause': return '暂停';
			case 'discover.overview': return '概述';
			case 'discover.cast': return '演员表';
			case 'discover.seasons': return '季数';
			case 'discover.studio': return '制作公司';
			case 'discover.rating': return '年龄分级';
			case 'discover.watched': return '已观看';
			case 'discover.episodeCount': return ({required Object count}) => '${count} 集';
			case 'discover.watchedProgress': return ({required Object watched, required Object total}) => '已观看 ${watched}/${total} 集';
			case 'discover.movie': return '电影';
			case 'discover.tvShow': return '电视剧';
			case 'discover.minutesLeft': return ({required Object minutes}) => '剩余 ${minutes} 分钟';
			case 'discover.whatsOnNow': return '正在播出';
			case 'discover.channelGuide': return '节目指南';
			case 'discover.liveNow': return '正在直播';
			case 'discover.topTen': return '前10名';
			case 'discover.newBadge': return '新';
			case 'discover.liveBadge': return '直播';
			case 'discover.goodMorning': return '早上好';
			case 'discover.goodAfternoon': return '下午好';
			case 'discover.goodEvening': return '晚上好';
			case 'discover.defaultUser': return 'Guest';
			case 'discover.yourNextWatch': return 'Your Next Watch';
			case 'discover.pickedForYou': return ({required Object name}) => 'Picked just for you, ${name}';
			case 'discover.surpriseMe': return 'Surprise Me';
			case 'discover.randomPicker': return 'Random Movie Picker';
			case 'discover.noMoviesFound': return 'No movies found in your library';
			case 'discover.spinning': return 'Picking something great...';
			case 'discover.spinAgain': return 'Spin Again';
			case 'discover.calendar': return 'Calendar';
			case 'discover.today': return 'Today';
			case 'discover.item': return 'item';
			case 'discover.items': return 'items';
			case 'discover.loadingMovies': return '正在加载你的电影...';
			case 'discover.noContentOnDate': return 'No content added on this date';
			case 'discover.noEpgData': return '暂无节目信息';
			case 'errors.searchFailed': return ({required Object error}) => '搜索失败: ${error}';
			case 'errors.connectionTimeout': return ({required Object context}) => '加载 ${context} 时连接超时';
			case 'errors.connectionFailed': return '无法连接到 Plex 服务器';
			case 'errors.failedToLoad': return ({required Object context, required Object error}) => '无法加载 ${context}: ${error}';
			case 'errors.noClientAvailable': return '没有可用客户端';
			case 'errors.authenticationFailed': return ({required Object error}) => '验证失败: ${error}';
			case 'errors.couldNotLaunchUrl': return '无法打开授权 URL';
			case 'errors.pleaseEnterToken': return '请输入一个令牌';
			case 'errors.invalidToken': return '令牌无效';
			case 'errors.failedToVerifyToken': return ({required Object error}) => '无法验证令牌: ${error}';
			case 'errors.failedToSwitchProfile': return ({required Object displayName}) => '无法切换到 ${displayName}';
			case 'errors.connectionFailedGeneric': return '连接失败';
			case 'errors.failedToRemove': return ({required Object error}) => '移除失败：${error}';
			case 'voice.notAvailable': return '语音控制不可用';
			case 'voice.commandNotRecognized': return ({required Object command}) => '无法识别的命令："${command}"';
			case 'libraries.title': return '媒体库';
			case 'libraries.scanLibraryFiles': return '扫描媒体库文件';
			case 'libraries.scanLibrary': return '扫描媒体库';
			case 'libraries.analyze': return '分析';
			case 'libraries.analyzeLibrary': return '分析媒体库';
			case 'libraries.refreshMetadata': return '刷新元数据';
			case 'libraries.emptyTrash': return '清空回收站';
			case 'libraries.emptyingTrash': return ({required Object title}) => '正在清空 “${title}” 的回收站...';
			case 'libraries.trashEmptied': return ({required Object title}) => '已清空 “${title}” 的回收站';
			case 'libraries.failedToEmptyTrash': return ({required Object error}) => '无法清空回收站: ${error}';
			case 'libraries.analyzing': return ({required Object title}) => '正在分析 “${title}”...';
			case 'libraries.analysisStarted': return ({required Object title}) => '已开始分析 “${title}”';
			case 'libraries.failedToAnalyze': return ({required Object error}) => '无法分析媒体库: ${error}';
			case 'libraries.noLibrariesFound': return '未找到媒体库';
			case 'libraries.thisLibraryIsEmpty': return '此媒体库为空';
			case 'libraries.all': return '全部';
			case 'libraries.clearAll': return '全部清除';
			case 'libraries.scanLibraryConfirm': return ({required Object title}) => '确定要扫描 “${title}” 吗？';
			case 'libraries.analyzeLibraryConfirm': return ({required Object title}) => '确定要分析 “${title}” 吗？';
			case 'libraries.refreshMetadataConfirm': return ({required Object title}) => '确定要刷新 “${title}” 的元数据吗？';
			case 'libraries.emptyTrashConfirm': return ({required Object title}) => '确定要清空 “${title}” 的回收站吗？';
			case 'libraries.manageLibraries': return '管理媒体库';
			case 'libraries.sort': return '排序';
			case 'libraries.sortBy': return '排序依据';
			case 'libraries.filters': return '筛选器';
			case 'libraries.loadingLibraryWithCount': return ({required Object count}) => '正在加载媒体库... (已加载 ${count} 个项目)';
			case 'libraries.confirmActionMessage': return '确定要执行此操作吗？';
			case 'libraries.showLibrary': return '显示媒体库';
			case 'libraries.hideLibrary': return '隐藏媒体库';
			case 'libraries.libraryOptions': return '媒体库选项';
			case 'libraries.content': return '媒体库内容';
			case 'libraries.selectLibrary': return '选择媒体库';
			case 'libraries.filtersWithCount': return ({required Object count}) => '筛选器（${count}）';
			case 'libraries.noRecommendations': return '暂无推荐';
			case 'libraries.noCollections': return '此媒体库中没有合集';
			case 'libraries.noFoldersFound': return '未找到文件夹';
			case 'libraries.folders': return '文件夹';
			case 'libraries.tabs.recommended': return '推荐';
			case 'libraries.tabs.browse': return '浏览';
			case 'libraries.tabs.collections': return '合集';
			case 'libraries.tabs.playlists': return '播放列表';
			case 'libraries.groupings.all': return '全部';
			case 'libraries.groupings.movies': return '电影';
			case 'libraries.groupings.shows': return '剧集';
			case 'libraries.groupings.seasons': return '季';
			case 'libraries.groupings.episodes': return '集';
			case 'libraries.groupings.folders': return '文件夹';
			case 'about.title': return '关于';
			case 'about.openSourceLicenses': return '开源许可证';
			case 'about.versionLabel': return ({required Object version}) => '版本 ${version}';
			case 'about.appDescription': return '一款精美的 Flutter Plex 客户端';
			case 'about.viewLicensesDescription': return '查看第三方库的许可证';
			case 'serverSelection.connectingToServer': return '正在连接服务器...';
			case 'serverSelection.connectingToAllServers': return '正在连接所有服务器...';
			case 'serverSelection.connectToAllServers': return '连接所有服务器';
			case 'serverSelection.allServerConnectionsFailed': return '无法连接到任何服务器。请检查你的网络并重试。';
			case 'serverSelection.foundServers': return ({required Object count}) => '找到 ${count} 个服务器';
			case 'serverSelection.orSelectIndividually': return '或单独选择一个服务器：';
			case 'serverSelection.serverDebugCopied': return '服务器调试数据已复制到剪贴板';
			case 'serverSelection.copyDebugData': return '复制调试数据';
			case 'serverSelection.noServersFound': return '未找到服务器';
			case 'serverSelection.malformedServerData': return ({required Object count}) => '找到 ${count} 个数据格式错误的服务器。没有可用的有效服务器。';
			case 'serverSelection.incompleteServerInfo': return '某些服务器信息不完整，已被跳过。请检查你的 Plex.tv 账户。';
			case 'serverSelection.incompleteConnectionInfo': return '服务器连接信息不完整。请重试。';
			case 'serverSelection.malformedServerInfo': return ({required Object message}) => '服务器信息格式错误: ${message}';
			case 'serverSelection.networkConnectionFailed': return '网络连接失败。请检查你的网络连接并重试。';
			case 'serverSelection.authenticationFailed': return '验证失败。请重新登录。';
			case 'serverSelection.plexServiceUnavailable': return 'Plex 服务不可用。请稍后重试。';
			case 'serverSelection.failedToLoadServers': return ({required Object error}) => '无法加载服务器: ${error}';
			case 'hubDetail.title': return '标题';
			case 'hubDetail.releaseYear': return '发行年份';
			case 'hubDetail.dateAdded': return '添加日期';
			case 'hubDetail.rating': return '评分';
			case 'hubDetail.noItemsFound': return '未找到项目';
			case 'logs.title': return '日志';
			case 'logs.clearLogs': return '清除日志';
			case 'logs.copyLogs': return '复制日志';
			case 'logs.exportLogs': return '导出日志';
			case 'logs.noLogsToShow': return '没有可显示的日志';
			case 'logs.error': return '错误:';
			case 'logs.stackTrace': return '堆栈跟踪 (Stack Trace):';
			case 'stats.title': return '观看统计';
			case 'stats.totalWatchTime': return '总观看时长';
			case 'stats.moviesWatched': return '已观看电影';
			case 'stats.episodesWatched': return '已观看剧集';
			case 'stats.avgPerDay': return '每日平均';
			case 'stats.topGenres': return '常看类型';
			case 'stats.monthlyActivity': return '月度活动';
			case 'stats.noData': return '暂无观看记录';
			case 'stats.startWatching': return '开始观看以查看统计数据';
			case 'stats.days': return '天';
			case 'licenses.relatedPackages': return '相关软件包';
			case 'licenses.license': return '许可证';
			case 'licenses.licenseNumber': return ({required Object number}) => '许可证 ${number}';
			case 'licenses.licensesCount': return ({required Object count}) => '${count} 个许可证';
			case 'navigation.home': return '主页';
			case 'navigation.search': return '搜索';
			case 'navigation.libraries': return '媒体库';
			case 'navigation.livetv': return '电视直播';
			case 'navigation.settings': return '设置';
			case 'playlists.title': return '播放列表';
			case 'playlists.noPlaylists': return '未找到播放列表';
			case 'playlists.create': return '创建播放列表';
			case 'playlists.newPlaylist': return '新播放列表';
			case 'playlists.playlistName': return '播放列表名称';
			case 'playlists.enterPlaylistName': return '输入播放列表名称';
			case 'playlists.edit': return '编辑播放列表';
			case 'playlists.delete': return '删除播放列表';
			case 'playlists.addTo': return '添加到播放列表';
			case 'playlists.addItems': return '添加项目';
			case 'playlists.removeItem': return '从播放列表中移除';
			case 'playlists.clearPlaylist': return '清空播放列表';
			case 'playlists.playAll': return '全部播放';
			case 'playlists.shuffle': return '随机播放';
			case 'playlists.smartPlaylist': return '智能播放列表';
			case 'playlists.regularPlaylist': return '普通播放列表';
			case 'playlists.itemCount': return ({required Object count}) => '${count} 个项目';
			case 'playlists.oneItem': return '1 个项目';
			case 'playlists.emptyPlaylist': return '此播放列表为空';
			case 'playlists.deleteConfirm': return '删除播放列表？';
			case 'playlists.deleteMessage': return ({required Object name}) => '确定要删除 "${name}" 吗？';
			case 'playlists.created': return '播放列表已创建';
			case 'playlists.updated': return '播放列表已更新';
			case 'playlists.deleted': return '播放列表已删除';
			case 'playlists.itemAdded': return '已添加到播放列表';
			case 'playlists.itemRemoved': return '已从播放列表中移除';
			case 'playlists.selectPlaylist': return '选择播放列表';
			case 'playlists.createNewPlaylist': return '创建新播放列表';
			case 'playlists.errorCreating': return '创建播放列表失败';
			case 'playlists.errorDeleting': return '删除播放列表失败';
			case 'playlists.errorLoading': return '加载播放列表失败';
			case 'playlists.errorAdding': return '添加到播放列表失败';
			case 'playlists.errorReordering': return '重新排序播放列表项目失败';
			case 'playlists.errorRemoving': return '从播放列表中移除失败';
			case 'playlists.playlist': return '播放列表';
			case 'collections.title': return '合集';
			case 'collections.collection': return '合集';
			case 'collections.empty': return '合集为空';
			case 'collections.noItems': return '此合集没有项目';
			case 'collections.unknownLibrarySection': return '无法删除：未知的媒体库分区';
			case 'collections.deleteCollection': return '删除合集';
			case 'collections.deleteConfirm': return ({required Object title}) => '确定要删除"${title}"吗？此操作无法撤销。';
			case 'collections.deleted': return '已删除合集';
			case 'collections.deleteFailed': return '删除合集失败';
			case 'collections.deleteFailedWithError': return ({required Object error}) => '删除合集失败：${error}';
			case 'collections.failedToLoadItems': return ({required Object error}) => '加载合集项目失败：${error}';
			case 'collections.addTo': return '添加到合集';
			case 'collections.selectCollection': return '选择合集';
			case 'collections.createNewCollection': return '创建新合集';
			case 'collections.collectionName': return '合集名称';
			case 'collections.enterCollectionName': return '输入合集名称';
			case 'collections.addedToCollection': return '已添加到合集';
			case 'collections.errorAddingToCollection': return '添加到合集失败';
			case 'collections.created': return '已创建合集';
			case 'collections.removeFromCollection': return '从合集移除';
			case 'collections.removeFromCollectionConfirm': return ({required Object title}) => '将“${title}”从此合集移除？';
			case 'collections.removedFromCollection': return '已从合集移除';
			case 'collections.removeFromCollectionFailed': return '从合集移除失败';
			case 'collections.removeFromCollectionError': return ({required Object error}) => '从合集移除时出错：${error}';
			case 'watchParty.title': return 'Watch Party';
			case 'watchParty.startParty': return '开始 Watch Party';
			case 'watchParty.joinParty': return '加入 Party';
			case 'watchParty.enterCode': return '输入 Party 代码';
			case 'watchParty.shareCode': return '分享此代码';
			case 'watchParty.friendsCanJoin': return '朋友可以使用此代码加入';
			case 'watchParty.participants': return '参与者';
			case 'watchParty.host': return '主持人';
			case 'watchParty.endParty': return '结束 Party';
			case 'watchParty.leaveParty': return '离开 Party';
			case 'watchParty.partyEnded': return 'Watch Party 已结束';
			case 'watchParty.chat': return '聊天';
			case 'watchParty.typeMessage': return '输入消息...';
			case 'watchParty.joined': return ({required Object name}) => '${name} 已加入';
			case 'watchParty.left': return ({required Object name}) => '${name} 已离开';
			case 'watchParty.syncedPlayback': return '播放已与 Party 同步';
			case 'watchParty.hostControls': return '只有主持人可以控制播放';
			case 'watchParty.creating': return '正在创建 Party...';
			case 'watchParty.joining': return '正在加入 Party...';
			case 'watchParty.createFailed': return '创建 Party 失败';
			case 'watchParty.joinFailed': return '加入 Party 失败';
			case 'watchParty.invalidCode': return '无效的 Party 代码';
			case 'watchParty.gotIt': return '知道了';
			case 'catchUp.title': return '回看电视';
			case 'catchUp.startOver': return '重新开始';
			case 'catchUp.startOverDescription': return '从头观看';
			case 'catchUp.watchFromBeginning': return '从头开始观看？';
			case 'catchUp.alreadyStarted': return ({required Object title}) => '"${title}" 已经开始。您可以从头开始观看。';
			case 'catchUp.watchLive': return '观看直播';
			case 'catchUp.programsAvailable': return '可用节目';
			case 'catchUp.noProgramsAvailable': return '没有可用的回看节目';
			case 'catchUp.programsWillAppear': return '节目将在播出后出现在这里';
			case 'catchUp.unavailable': return '不可用';
			case 'catchUp.bufferNotReady': return '缓冲区尚未就绪';
			case 'catchUp.rewind': return '倒带';
			case 'catchUp.timeshiftEnabled': return '时移已启用';
			case 'catchUp.goBackTo': return ({required Object time}) => '返回到 ${time}';
			case 'watchlist.title': return '我的观看列表';
			case 'watchlist.all': return '全部';
			case 'watchlist.movies': return '电影';
			case 'watchlist.shows': return '电视剧';
			case 'watchlist.episodes': return '剧集';
			case 'watchlist.empty': return '您的观看列表为空';
			case 'watchlist.emptyHint': return '从详情页添加电影和剧集到您的观看列表';
			case 'watchlist.noItemsFiltered': return '没有符合此筛选条件的项目';
			case 'watchlist.removeTitle': return '从观看列表移除';
			case 'watchlist.removeConfirm': return ({required Object title}) => '确定要将「${title}」从观看列表移除吗？';
			case 'watchlist.remove': return 'Remove';
			case 'watchlist.play': return 'Play';
			case 'watchlist.details': return 'Details';
			case 'watchlist.seeAll': return 'See All';
			case 'watchlist.clearAllTitle': return '清空观看列表';
			case 'watchlist.clearAllConfirm': return ({required Object count}) => '确定要移除观看列表中的 ${count} 个项目吗？';
			case 'watchlist.clearAll': return '全部清除';
			case 'watchlist.addedToday': return '今天添加';
			case 'watchlist.addedYesterday': return '昨天添加';
			case 'watchlist.addedDaysAgo': return ({required Object days}) => '${days} 天前添加';
			case 'watchlist.addedOn': return ({required Object date}) => '添加于 ${date}';
			case 'watchlist.addToWatchlist': return '添加到观看列表';
			case 'watchlist.removeFromWatchlist': return '从观看列表移除';
			case 'watchlist.addedToWatchlist': return '已添加到观看列表';
			case 'watchlist.removedFromWatchlist': return '已从观看列表移除';
			case 'liveTV.title': return '电视直播';
			case 'liveTV.guide': return '节目指南';
			case 'liveTV.dvr': return 'DVR';
			case 'liveTV.multiview': return '多画面';
			case 'liveTV.allChannels': return '所有频道';
			case 'liveTV.favorites': return '收藏';
			case 'liveTV.noChannels': return '没有可用频道';
			case 'liveTV.addM3USource': return '在服务器设置中添加M3U源';
			case 'liveTV.recording': return '录制中';
			case 'liveTV.recordingNow': return '正在录制';
			case 'liveTV.upNext': return '即将播出';
			case 'liveTV.noProgram': return '没有节目信息';
			case 'liveTV.filterByGroup': return '按组筛选';
			case 'liveTV.refresh': return '刷新';
			case 'liveTV.channelCount': return ({required Object count}) => '${count} 个频道';
			case 'liveTV.nowPlaying': return '正在播出';
			case 'liveTV.scheduleRecording': return '预约录制';
			case 'liveTV.onNow': return '正在播出';
			case 'liveTV.endsAt': return ({required Object time}) => '结束于 ${time}';
			case 'liveTV.startsAt': return ({required Object time}) => '开始于 ${time}';
			case 'liveTV.playbackError': return ({required Object error}) => '播放错误：${error}';
			case 'liveTV.noPreviousChannel': return '没有上一个频道';
			case 'liveTV.switchedTo': return ({required Object channel}) => '已切换到：${channel}';
			case 'liveTV.startingFromBeginning': return '正在从头开始播放节目...';
			case 'liveTV.failedToStartOver': return ({required Object error}) => '重新开始失败：${error}';
			case 'liveTV.playingProgram': return ({required Object title}) => '正在播放：${title}';
			case 'liveTV.failedToPlayProgram': return ({required Object error}) => '播放节目失败：${error}';
			case 'liveTV.addedToFavorites': return '已添加到收藏';
			case 'liveTV.removedFromFavorites': return '已从收藏中移除';
			case 'liveTV.failedToUpdateFavorite': return ({required Object error}) => '更新收藏失败：${error}';
			case 'liveTV.pipNotSupported': return '此平台不支持画中画';
			case 'liveTV.enteredPipMode': return '已进入画中画模式';
			case 'liveTV.exitedPipMode': return '已退出画中画模式';
			case 'liveTV.aspectRatioChanged': return ({required Object mode}) => '画面比例：${mode}';
			case 'liveTV.tune': return '调谐';
			case 'liveTV.retry': return '重试';
			case 'liveTV.noChannelsMatchFilter': return '没有匹配筛选条件的频道';
			case 'liveTV.skipCommercial': return '跳过广告';
			case 'dvr.title': return 'DVR';
			case 'dvr.recordings': return '录制内容';
			case 'dvr.seriesRules': return '系列规则';
			case 'dvr.noRecordings': return '没有录制内容';
			case 'dvr.noRules': return '没有系列规则';
			case 'dvr.scheduleFromGuide': return '从电视指南预约录制';
			case 'dvr.createRulesHint': return '创建规则自动录制系列节目';
			case 'dvr.storage': return '存储空间';
			case 'dvr.recordingsCount': return ({required Object count}) => '${count} 个录制';
			case 'dvr.all': return '全部';
			case 'dvr.scheduled': return '已预约';
			case 'dvr.completed': return '已完成';
			case 'dvr.failed': return '失败';
			case 'dvr.deleteRecording': return '删除录制？';
			case 'dvr.deleteRule': return '删除系列规则？';
			case 'dvr.sortByDate': return '日期';
			case 'dvr.sortByTitle': return '标题';
			case 'dvr.sortBySize': return '大小';
			case 'dvr.playRecording': return '播放录制';
			case 'dvr.keepPolicy': return ({required Object count}) => '保留 ${count} 集';
			case 'dvr.keepAll': return '全部保留';
			case 'dvr.recordingScheduled': return '录制已预约';
			case 'dvr.scheduleRecordingTitle': return '预约录制';
			case 'dvr.schedule': return '预约';
			case 'dvr.cancel': return '取消';
			case 'epg.title': return '电视节目指南';
			case 'epg.now': return '现在';
			case 'epg.today': return '今天';
			case 'epg.tomorrow': return '明天';
			case 'epg.noPrograms': return '没有可用的节目信息';
			case 'epg.loading': return '正在加载节目指南...';
			case 'epg.record': return '录制';
			case 'epg.reminder': return '设置提醒';
			case 'epg.moreInfo': return '更多信息';
			case 'epg.toggleView': return '切换视图';
			case 'epg.gridView': return '网格视图';
			case 'epg.nowNextView': return '正在播出/即将播出视图';
			case 'channelSurfing.title': return '随机播放';
			case 'channelSurfing.kidsMode': return '儿童模式';
			case 'channelSurfing.loading': return '正在加载随机播放...';
			case 'channelSurfing.failedToLoad': return '无法加载内容';
			case 'channelSurfing.retry': return '重试';
			case 'channelSurfing.noContent': return '没有可用内容';
			case 'channelSurfing.itemsAvailable': return ({required Object count}) => '${count} 个项目可用';
			case 'channelSurfing.startSurfing': return '开始播放';
			case 'channelSurfing.pressBackToExit': return '按返回键退出';
			case 'channelSurfing.description': return '连续观看随机电影和剧集';
			case 'channelSurfing.noServers': return '没有可用服务器';
			case 'multiview.title': return '多画面';
			case 'multiview.changeLayout': return '更改布局 (L)';
			case 'multiview.addChannel': return '添加频道 (A)';
			case 'multiview.removeChannel': return '移除频道 (R)';
			case 'multiview.swapChannel': return '切换频道';
			case 'multiview.toggleMute': return '静音切换 (M)';
			case 'multiview.selectChannel': return '选择频道';
			case 'multiview.searchChannels': return '搜索频道...';
			case 'multiview.cancel': return '取消';
			case 'multiview.channelNumber': return ({required Object number}) => '频道 ${number}';
			case 'player.playbackError': return '播放错误';
			case 'player.error': return '错误';
			case 'player.failedToStartPlayback': return ({required Object error}) => '无法开始播放：\n${error}';
			case 'player.ok': return '确定';
			case 'downloads.title': return '下载';
			case 'downloads.deleteAll': return '删除全部';
			case 'downloads.deleteAllTitle': return '删除所有下载？';
			case 'downloads.deleteAllMessage': return ({required Object count, required Object size}) => '这将删除所有 ${count} 个下载并释放 ${size} 存储空间。';
			case 'downloads.storageUsed': return ({required Object size}) => '已用存储空间：${size}';
			case 'downloads.downloading': return ({required Object count}) => '下载中 (${count})';
			case 'downloads.downloaded': return ({required Object count}) => '已下载 (${count})';
			case 'downloads.noDownloads': return '没有下载';
			case 'downloads.noDownloadsHint': return '下载电影和剧集以便离线观看';
			case 'downloads.deleteDownloadTitle': return '删除下载？';
			case 'downloads.deleteDownloadMessage': return ({required Object title}) => '删除「${title}」？';
			case 'downloads.delete': return '删除';
			case 'downloads.cancel': return '取消';
			case 'downloads.downloadFailed': return '下载失败';
			case 'downloads.paused': return '已暂停';
			default: return null;
		}
	}
}
