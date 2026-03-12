import { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, X } from 'lucide-react'

interface SettingsEntry {
  label: string
  section: string
  route: string
  keywords?: string[]
  anchor?: string
}

const INDEX: SettingsEntry[] = [
  // ── Nav pages ─────────────────────────────────────────────────────────────
  { label: 'Dashboard', section: 'Home', route: '/ui', keywords: ['home', 'overview', 'summary'] },
  { label: 'Libraries', section: 'Media', route: '/ui/libraries', keywords: ['movies', 'tv shows', 'folders', 'scan', 'library'] },
  { label: 'Media Browser', section: 'Media', route: '/ui/media', keywords: ['movies', 'shows', 'browse', 'media'] },
  { label: 'Collections', section: 'Media', route: '/ui/collections', keywords: ['groups', 'sets', 'collections'] },
  { label: 'Artwork', section: 'Media', route: '/ui/artwork', keywords: ['posters', 'images', 'thumbnails', 'artwork'] },
  { label: 'Metadata', section: 'Media', route: '/ui/metadata', keywords: ['info', 'details', 'tmdb', 'tvdb', 'titles'] },
  { label: 'Live TV', section: 'Live TV', route: '/ui/livetv', keywords: ['channels', 'stream', 'live', 'iptv', 'hdhr'] },
  { label: 'TV Guide', section: 'Live TV', route: '/ui/tvguide', keywords: ['epg', 'guide', 'schedule', 'program', 'what is on'] },
  { label: 'On Now', section: 'Live TV', route: '/ui/onnow', keywords: ['currently airing', 'now', 'live now'] },
  { label: 'EPG Editor', section: 'Live TV', route: '/ui/livetv/epg-editor', keywords: ['epg', 'edit guide', 'program guide', 'channel mapping'] },
  { label: 'Tuners', section: 'Live TV', route: '/ui/tuners', keywords: ['hdhr', 'hdhomerun', 'tuner', 'antenna', 'hardware', 'add tuner'] },
  { label: 'Channel Collections', section: 'Live TV', route: '/ui/channel-collections', keywords: ['channels', 'groups', 'favorites', 'lineup'] },
  { label: 'Virtual Channels', section: 'Live TV', route: '/ui/virtual-channels', keywords: ['pluto', '24/7', 'loop', 'playlist channel'] },
  { label: 'DVR', section: 'DVR & Recording', route: '/ui/dvr', keywords: ['recordings', 'record', 'shows', 'dvr'] },
  { label: 'Passes', section: 'DVR & Recording', route: '/ui/dvr/passes', keywords: ['series pass', 'rules', 'record series', 'auto record', 'subscription'] },
  { label: 'DVR Schedule', section: 'DVR & Recording', route: '/ui/dvr/schedule', keywords: ['upcoming recordings', 'scheduled', 'queue'] },
  { label: 'DVR Calendar', section: 'DVR & Recording', route: '/ui/dvr/calendar', keywords: ['calendar', 'month view', 'schedule'] },
  { label: 'On Later', section: 'DVR & Recording', route: '/ui/onlater', keywords: ['upcoming', 'future airings', 'search guide', 'what is on later'] },
  { label: 'Team Pass', section: 'DVR & Recording', route: '/ui/teampass', keywords: ['sports', 'team', 'game', 'nfl', 'nba', 'mlb'] },
  { label: 'Comskip Settings', section: 'DVR & Recording', route: '/ui/comskip', keywords: ['commercial skip', 'ads', 'comskip', 'detection'] },
  { label: 'Segments', section: 'DVR & Recording', route: '/ui/segments', keywords: ['cut', 'clip', 'trim', 'chapters', 'commercial segments'] },
  { label: 'Labels', section: 'DVR & Recording', route: '/ui/labels', keywords: ['tags', 'categories', 'labels', 'organize'] },
  { label: 'Playlists', section: 'Content', route: '/ui/playlists', keywords: ['playlist', 'queue', 'watchlist'] },
  { label: 'Sections', section: 'Content', route: '/ui/sections', keywords: ['home sections', 'rows', 'featured', 'layout'] },
  { label: 'VOD', section: 'Content', route: '/ui/vod', keywords: ['download', 'streaming', 'on demand', 'video on demand'] },
  { label: 'Downloads', section: 'Content', route: '/ui/downloads', keywords: ['download', 'offline', 'queue'] },
  { label: 'Offline Content', section: 'Content', route: '/ui/offline', keywords: ['offline', 'downloaded', 'mobile'] },
  { label: 'Upload', section: 'Content', route: '/ui/upload', keywords: ['upload', 'import', 'add media'] },
  { label: 'Users', section: 'System', route: '/ui/users', keywords: ['accounts', 'users', 'admin', 'permissions', 'profiles', 'family'] },
  { label: 'Remote Access', section: 'System', route: '/ui/remote-access', keywords: ['away from home', 'cloud', 'vpn', 'external', 'pair', 'claim code', 'invite', 'license', 'outside'] },
  { label: 'Sources', section: 'System', route: '/ui/settings/sources', keywords: ['m3u', 'iptv', 'epg', 'xmltv', 'library folders', 'xtream', 'channels'] },

  // ── Settings pages ─────────────────────────────────────────────────────────
  { label: 'Server Name', section: 'Server Settings', route: '/ui/settings' , anchor: 'server-settings' },
  { label: 'Server Port', section: 'Server Settings', route: '/ui/settings' , anchor: 'server-settings' },
  { label: 'Log Level', section: 'Server Settings', route: '/ui/settings', anchor: 'server-settings', keywords: ['debug', 'verbose', 'logging'] },
  { label: 'TMDB API Key', section: 'Metadata', route: '/ui/settings', anchor: 'metadata', keywords: ['tmdb', 'movie', 'artwork', 'poster', 'metadata'] },
  { label: 'TVDB API Key', section: 'Metadata', route: '/ui/settings', anchor: 'metadata', keywords: ['tvdb', 'tv show', 'metadata'] },
  { label: 'Metadata Language', section: 'Metadata', route: '/ui/settings', anchor: 'metadata', keywords: ['language', 'locale'] },
  { label: 'Library Scan Interval', section: 'Metadata', route: '/ui/settings', anchor: 'metadata', keywords: ['scan', 'library', 'refresh'] },
  { label: 'Default Playback Speed', section: 'Playback Defaults', route: '/ui/settings' , anchor: 'playback-defaults' },
  { label: 'Default Subtitle Language', section: 'Playback Defaults', route: '/ui/settings', anchor: 'playback-defaults', keywords: ['subtitles', 'captions'] },
  { label: 'Default Audio Language', section: 'Playback Defaults', route: '/ui/settings', anchor: 'playback-defaults', keywords: ['audio', 'language'] },
  { label: 'VOD API URL', section: 'VOD Downloads', route: '/ui/settings', anchor: 'vod-downloads', keywords: ['streaming', 'download', 'vod'] },
  { label: 'Export Configuration', section: 'Backup', route: '/ui/settings', anchor: 'backup', keywords: ['backup', 'export', 'restore'] },
  { label: 'Import Configuration', section: 'Backup', route: '/ui/settings', anchor: 'backup', keywords: ['backup', 'import', 'restore'] },
  { label: 'Remote Access', section: 'Remote Access', route: '/ui/settings', anchor: 'remote-access', keywords: ['cloud', 'external', 'vpn', 'discovery'] },
  // Live TV & DVR
  { label: 'Recording Directory', section: 'Recording Defaults', route: '/ui/settings/livetv-dvr', anchor: 'recording-defaults', keywords: ['dvr', 'save', 'path', 'folder'] },
  { label: 'Pre-Padding', section: 'Recording Defaults', route: '/ui/settings/livetv-dvr', anchor: 'recording-defaults', keywords: ['recording', 'start early', 'padding'] },
  { label: 'Post-Padding', section: 'Recording Defaults', route: '/ui/settings/livetv-dvr', anchor: 'recording-defaults', keywords: ['recording', 'end late', 'padding'] },
  { label: 'Default Recording Quality', section: 'Recording Defaults', route: '/ui/settings/livetv-dvr', anchor: 'recording-defaults', keywords: ['quality', '1080p', 'original', 'dvr'] },
  { label: 'Default Keep Rule', section: 'Keep Rules', route: '/ui/settings/livetv-dvr', anchor: 'keep-rules', keywords: ['storage', 'cleanup', 'keep', 'delete'] },
  { label: 'Auto-Delete Watched Recordings', section: 'Keep Rules', route: '/ui/settings/livetv-dvr', anchor: 'keep-rules', keywords: ['watched', 'delete', 'auto'] },
  { label: 'Auto-Delete After Days', section: 'Keep Rules', route: '/ui/settings/livetv-dvr', anchor: 'keep-rules', keywords: ['delete', 'expire', 'cleanup'] },
  { label: 'Commercial Detection', section: 'Commercial Detection', route: '/ui/settings/livetv-dvr', anchor: 'commercial-detection', keywords: ['comskip', 'ads', 'skip commercials'] },
  { label: 'Auto-Skip Commercials on Playback', section: 'Commercial Detection', route: '/ui/settings/livetv-dvr', anchor: 'commercial-detection', keywords: ['ads', 'skip', 'automatic'] },
  { label: 'Guide Data Source', section: 'Guide Data', route: '/ui/settings/livetv-dvr', anchor: 'guide-data', keywords: ['epg', 'tvguide', 'zip', 'provider', 'guide'] },
  { label: 'Guide Refresh Interval', section: 'Guide Data', route: '/ui/settings/livetv-dvr', anchor: 'guide-data', keywords: ['epg', 'update', 'refresh'] },
  { label: 'Refresh Guide Data Now', section: 'Guide Data', route: '/ui/settings/livetv-dvr', anchor: 'guide-data', keywords: ['epg', 'update now'] },
  { label: 'Rebuild Guide Data', section: 'Guide Data', route: '/ui/settings/livetv-dvr', anchor: 'guide-data', keywords: ['epg', 'clear', 'reset'] },
  { label: 'Tuner Sharing', section: 'Live TV Streaming', route: '/ui/settings/livetv-dvr', anchor: 'live-tv-streaming', keywords: ['hdhr', 'tuner', 'multi-stream'] },
  { label: 'Live TV Buffer Size', section: 'Live TV Streaming', route: '/ui/settings/livetv-dvr', anchor: 'live-tv-streaming', keywords: ['buffer', 'pause', 'rewind', 'live tv'] },
  { label: 'Deinterlacing', section: 'Live TV Streaming', route: '/ui/settings/livetv-dvr', anchor: 'live-tv-streaming', keywords: ['1080i', 'interlaced', 'video'] },
  { label: 'Max Concurrent Recordings', section: 'Concurrency', route: '/ui/settings/livetv-dvr', anchor: 'concurrency', keywords: ['simultaneous', 'conflict', 'tuner'] },
  // Sources
  { label: 'Manage Libraries', section: 'Sources', route: '/ui/settings/sources', anchor: 'sources', keywords: ['libraries', 'folders', 'movies', 'tv shows', 'add library'] },
  { label: 'M3U Sources', section: 'Sources', route: '/ui/settings/sources', anchor: 'sources', keywords: ['m3u', 'playlist', 'iptv', 'import'] },
  { label: 'Xtream Sources', section: 'Sources', route: '/ui/settings/sources', anchor: 'sources', keywords: ['xtream', 'xtream codes', 'provider', 'vod'] },
  { label: 'EPG Sources', section: 'Sources', route: '/ui/settings/sources', anchor: 'sources', keywords: ['epg', 'guide', 'xmltv', 'program guide', 'tv guide'] },
  { label: 'Channel Mapping', section: 'Sources', route: '/ui/settings/sources', anchor: 'sources', keywords: ['channel', 'mapping', 'lineup', 'assign'] },
  // Advanced
  { label: 'Transcoder Type', section: 'Transcoder', route: '/ui/settings/advanced', anchor: 'transcoder', keywords: ['hardware', 'nvenc', 'quicksync', 'vaapi', 'software', 'gpu'] },
  { label: 'Max Concurrent Transcode Sessions', section: 'Transcoder', route: '/ui/settings/advanced', anchor: 'transcoder', keywords: ['concurrent', 'streams', 'transcode'] },
  { label: 'Transcode Temp Directory', section: 'Transcoder', route: '/ui/settings/advanced', anchor: 'transcoder', keywords: ['temp', 'cache', 'disk', 'transcode'] },
  { label: 'Default Video Codec', section: 'Transcoder', route: '/ui/settings/advanced', anchor: 'transcoder', keywords: ['h264', 'h265', 'hevc', 'av1', 'codec'] },
  { label: 'Default Audio Codec', section: 'Transcoder', route: '/ui/settings/advanced', anchor: 'transcoder', keywords: ['aac', 'ac3', 'dolby', 'codec', 'audio'] },
  { label: 'Playback Quality', section: 'Web Player', route: '/ui/settings/advanced', anchor: 'web-player', keywords: ['quality', 'streaming', 'bitrate'] },
  { label: 'Client Buffer Duration', section: 'Web Player', route: '/ui/settings/advanced', anchor: 'web-player', keywords: ['buffer', 'prebuffer', 'connection'] },
  { label: 'EDL Export', section: 'Integrations', route: '/ui/settings/advanced', anchor: 'integrations', keywords: ['kodi', 'chapters', 'cut list', 'edl'] },
  { label: 'M3U Channel IDs', section: 'Integrations', route: '/ui/settings/advanced', anchor: 'integrations', keywords: ['epg', 'mapping', 'm3u', 'playlist', 'channel id'] },
  { label: 'HTTP Logging', section: 'Integrations', route: '/ui/settings/advanced', anchor: 'integrations', keywords: ['debug', 'verbose', 'log'] },
  { label: 'HDR Tone Mapping', section: 'Experimental', route: '/ui/settings/advanced', anchor: 'experimental', keywords: ['hdr', 'sdr', 'tone map', 'dolby vision'] },
  { label: 'Low Latency Mode', section: 'Experimental', route: '/ui/settings/advanced', anchor: 'experimental', keywords: ['live tv', 'delay', 'latency', 'lag'] },
  { label: 'AI Metadata Enhancement', section: 'Experimental', route: '/ui/settings/advanced', anchor: 'experimental', keywords: ['ai', 'descriptions', 'categories', 'auto'] },
]

function pageLabel(route: string) {
  if (route === '/ui/settings') return 'General'
  if (route.includes('livetv-dvr')) return 'Live TV & DVR'
  if (route.includes('sources')) return 'Sources'
  if (route.includes('advanced')) return 'Advanced'
  return 'Settings'
}

export function SettingsSearch() {
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)
  const containerRef = useRef<HTMLDivElement>(null)

  const results = query.trim().length < 2
    ? []
    : INDEX.filter((e) => {
        const q = query.toLowerCase()
        return (
          e.label.toLowerCase().includes(q) ||
          e.section.toLowerCase().includes(q) ||
          (e.keywords ?? []).some((k) => k.toLowerCase().includes(q))
        )
      }).slice(0, 8)

  useEffect(() => {
    if (open) setTimeout(() => inputRef.current?.focus(), 50)
  }, [open])

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { setOpen(false); setQuery('') }
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [])

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        setOpen(true)
        setTimeout(() => inputRef.current?.focus(), 0)
      }
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [])

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false)
        setQuery('')
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const handleSelect = (entry: SettingsEntry) => {
    setOpen(false)
    setQuery('')

    // Navigate with hash — the page's useEffect([location.hash]) will handle scrolling
    const hash = entry.anchor ? `#${entry.anchor}` : ''
    // Use replace:true + a unique key to force React Router to re-trigger even on same route
    navigate(entry.route + hash, { replace: true, state: { scrollTo: Date.now() } })

    // Also try direct scroll as backup (for same-page navigation)
    if (entry.anchor) {
      setTimeout(() => {
        const el = document.getElementById(entry.anchor!)
        if (el) {
          el.scrollIntoView({ behavior: 'smooth', block: 'start' })
          el.style.outline = '2px solid rgba(139, 92, 246, 0.6)'
          el.style.outlineOffset = '4px'
          el.style.borderRadius = '12px'
          setTimeout(() => { el.style.outline = ''; el.style.outlineOffset = '' }, 2000)
        }
      }, 300)
    }
  }

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        className="flex items-center gap-1.5 p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg transition-colors"
        title="Search settings (type to find any setting)"
      >
        <Search className="h-5 w-5" />
        <kbd className="ml-1 text-xs text-gray-500 bg-gray-700 px-1 rounded">⌘K</kbd>
      </button>
    )
  }

  return (
    <div ref={containerRef} className="relative">
      <div className="flex items-center gap-2 bg-gray-700 border border-gray-600 rounded-lg px-3 py-1.5 w-72">
        <Search className="h-4 w-4 text-gray-400 shrink-0" />
        <input
          ref={inputRef}
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search settings..."
          className="flex-1 bg-transparent text-white text-sm placeholder-gray-500 focus:outline-none"
        />
        <button
          onClick={() => { setOpen(false); setQuery('') }}
          className="text-gray-500 hover:text-white transition-colors"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      {results.length > 0 && (
        <div className="absolute right-0 top-full mt-1 w-80 bg-gray-800 border border-gray-700 rounded-xl shadow-2xl z-50 overflow-hidden">
          {results.map((entry, i) => (
            <button
              key={i}
              onClick={() => handleSelect(entry)}
              className="w-full text-left px-4 py-3 hover:bg-gray-700 transition-colors border-b border-gray-700/60 last:border-0"
            >
              <div className="text-sm text-white font-medium">{entry.label}</div>
              <div className="text-xs text-gray-500 mt-0.5">
                {pageLabel(entry.route)} › {entry.section}
              </div>
            </button>
          ))}
        </div>
      )}

      {query.trim().length >= 2 && results.length === 0 && (
        <div className="absolute right-0 top-full mt-1 w-72 bg-gray-800 border border-gray-700 rounded-xl shadow-2xl z-50 p-4 text-center">
          <p className="text-sm text-gray-500">No settings found for "{query}"</p>
        </div>
      )}
    </div>
  )
}
