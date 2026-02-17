import Foundation
import SwiftUI

extension UserDefaults {
    private enum Keys {
        static let serverURL = "server_url"
        static let lastUsername = "last_username"
        static let currentProfileUUID = "current_profile_uuid"
        static let rememberMe = "remember_me"
        static let autoPlayNext = "auto_play_next"
        static let skipIntros = "skip_intros"
        static let skipCredits = "skip_credits"
        static let defaultSubtitleLanguage = "default_subtitle_language"
        static let defaultAudioLanguage = "default_audio_language"
        static let showSubtitles = "show_subtitles"
        static let favoriteChannelIds = "favorite_channel_ids"
        static let lastChannelId = "last_channel_id"
        static let channelSurfingEnabled = "channel_surfing_enabled"
        static let epgDaysToLoad = "epg_days_to_load"
        static let commercialSkipEnabled = "commercial_skip_enabled"
        static let screensaverEnabled = "screensaver_enabled"
        static let screensaverDelay = "screensaver_delay"
    }

    var serverURL: URL? {
        get {
            guard let urlString = string(forKey: Keys.serverURL) else { return nil }
            return URL(string: urlString)
        }
        set {
            set(newValue?.absoluteString, forKey: Keys.serverURL)
        }
    }

    var lastUsername: String? {
        get { string(forKey: Keys.lastUsername) }
        set { set(newValue, forKey: Keys.lastUsername) }
    }

    var currentProfileUUID: String? {
        get { string(forKey: Keys.currentProfileUUID) }
        set { set(newValue, forKey: Keys.currentProfileUUID) }
    }

    var rememberMe: Bool {
        get { bool(forKey: Keys.rememberMe) }
        set { set(newValue, forKey: Keys.rememberMe) }
    }

    var autoPlayNext: Bool {
        get { object(forKey: Keys.autoPlayNext) == nil ? true : bool(forKey: Keys.autoPlayNext) }
        set { set(newValue, forKey: Keys.autoPlayNext) }
    }

    var skipIntros: Bool {
        get { bool(forKey: Keys.skipIntros) }
        set { set(newValue, forKey: Keys.skipIntros) }
    }

    var skipCredits: Bool {
        get { bool(forKey: Keys.skipCredits) }
        set { set(newValue, forKey: Keys.skipCredits) }
    }

    var defaultSubtitleLanguage: String? {
        get { string(forKey: Keys.defaultSubtitleLanguage) }
        set { set(newValue, forKey: Keys.defaultSubtitleLanguage) }
    }

    var defaultAudioLanguage: String? {
        get { string(forKey: Keys.defaultAudioLanguage) }
        set { set(newValue, forKey: Keys.defaultAudioLanguage) }
    }

    var showSubtitles: Bool {
        get { bool(forKey: Keys.showSubtitles) }
        set { set(newValue, forKey: Keys.showSubtitles) }
    }

    var favoriteChannelIds: [String] {
        get { stringArray(forKey: Keys.favoriteChannelIds) ?? [] }
        set { set(newValue, forKey: Keys.favoriteChannelIds) }
    }

    var lastChannelId: String? {
        get { string(forKey: Keys.lastChannelId) }
        set { set(newValue, forKey: Keys.lastChannelId) }
    }

    var channelSurfingEnabled: Bool {
        get { object(forKey: Keys.channelSurfingEnabled) == nil ? true : bool(forKey: Keys.channelSurfingEnabled) }
        set { set(newValue, forKey: Keys.channelSurfingEnabled) }
    }

    var epgDaysToLoad: Int {
        get {
            let value = integer(forKey: Keys.epgDaysToLoad)
            return value > 0 ? value : 3
        }
        set { set(newValue, forKey: Keys.epgDaysToLoad) }
    }

    var commercialSkipEnabled: Bool {
        get { object(forKey: Keys.commercialSkipEnabled) == nil ? true : bool(forKey: Keys.commercialSkipEnabled) }
        set { set(newValue, forKey: Keys.commercialSkipEnabled) }
    }

    var screensaverEnabled: Bool {
        get { object(forKey: Keys.screensaverEnabled) == nil ? true : bool(forKey: Keys.screensaverEnabled) }
        set { set(newValue, forKey: Keys.screensaverEnabled) }
    }

    var screensaverDelay: Int {
        get {
            let value = integer(forKey: Keys.screensaverDelay)
            return value > 0 ? value : 300 // 5 minutes default
        }
        set { set(newValue, forKey: Keys.screensaverDelay) }
    }
}

// MARK: - AppStorage Property Wrapper Keys
extension String {
    static let serverURLKey = "server_url"
    static let autoPlayNextKey = "auto_play_next"
    static let skipIntrosKey = "skip_intros"
    static let skipCreditsKey = "skip_credits"
    static let showSubtitlesKey = "show_subtitles"
    static let commercialSkipKey = "commercial_skip_enabled"
}
