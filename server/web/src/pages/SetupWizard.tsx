import { useState, useEffect } from 'react'
import { FileBrowser } from '../components/FileBrowser'
import {
  Server,
  FolderOpen,
  Tv,
  Video,
  CheckCircle,
  ArrowRight,
  ArrowLeft,
  Loader,
  Plus,
  Trash2,
  Rocket,
  AlertCircle,
  Radio,
  Search,
  CalendarDays,
} from 'lucide-react'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface WizardLibrary {
  title: string
  type: 'movie' | 'show'
  paths: string[]
}

interface WizardM3USource {
  name: string
  url: string
}

interface WizardTuner {
  deviceId: string
  modelNumber: string
  baseUrl: string
  imported?: number
}

interface WizardGuideProvider {
  id: number
  name: string
  type: string
  city?: string
  state?: string
}

interface WizardState {
  step: number
  serverName: string
  adminUsername: string
  adminEmail: string
  adminPassword: string
  libraries: WizardLibrary[]
  tuners: WizardTuner[]
  zipCode: string
  guideProvider: WizardGuideProvider | null
  m3uSource?: WizardM3USource
  dvrEnabled: boolean
  recordingDir: string
  tmdbApiKey: string
}

interface StatusResponse {
  server: { name: string }
  libraries: { count: number }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const authHeaders: Record<string, string> = {
  'X-Plex-Token': localStorage.getItem('openflix_token') || '',
  'Content-Type': 'application/json',
}

const TOTAL_STEPS = 8

const STEP_META: { label: string; icon: React.ElementType }[] = [
  { label: 'Welcome', icon: Server },
  { label: 'Libraries', icon: FolderOpen },
  { label: 'Tuners', icon: Radio },
  { label: 'Guide', icon: CalendarDays },
  { label: 'Metadata', icon: Search },
  { label: 'Live TV', icon: Tv },
  { label: 'DVR', icon: Video },
  { label: 'Done', icon: Rocket },
]

// ---------------------------------------------------------------------------
// StepIndicator
// ---------------------------------------------------------------------------

function StepIndicator({ current, total }: { current: number; total: number }) {
  return (
    <div className="flex items-center justify-center gap-2 mb-8">
      {Array.from({ length: total }).map((_, i) => {
        const stepNum = i + 1
        const completed = stepNum < current
        const active = stepNum === current
        const Icon = STEP_META[i].icon
        return (
          <div key={i} className="flex items-center gap-2">
            {i > 0 && (
              <div
                className={`h-0.5 w-8 ${
                  completed ? 'bg-green-500' : 'bg-gray-600'
                }`}
              />
            )}
            <div className="flex flex-col items-center gap-1">
              <div
                className={`flex items-center justify-center w-10 h-10 rounded-full border-2 text-sm font-bold transition-colors ${
                  completed
                    ? 'bg-green-500 border-green-500 text-white'
                    : active
                      ? 'bg-indigo-600 border-indigo-600 text-white'
                      : 'bg-gray-800 border-gray-600 text-gray-400'
                }`}
              >
                {completed ? (
                  <CheckCircle className="w-5 h-5" />
                ) : (
                  <Icon className="w-5 h-5" />
                )}
              </div>
              <span
                className={`text-xs ${
                  active ? 'text-indigo-400 font-medium' : 'text-gray-500'
                }`}
              >
                {STEP_META[i].label}
              </span>
            </div>
          </div>
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 1 - Welcome
// ---------------------------------------------------------------------------

function StepWelcome({
  state,
  onChange,
  needsAdmin,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
  needsAdmin: boolean
}) {
  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">Welcome to OpenFlix</h2>
        <p className="text-gray-400 mt-2">
          Let's configure your new media server in a few quick steps.
        </p>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-300 mb-2">
          Server Name
        </label>
        <input
          type="text"
          value={state.serverName}
          onChange={(e) => onChange({ serverName: e.target.value })}
          placeholder="My OpenFlix Server"
          className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
        />
      </div>

      {needsAdmin && (
        <>
          <div className="border-t border-gray-700 pt-4">
            <h3 className="text-lg font-semibold text-white mb-3">
              Create Admin Account
            </h3>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Username
            </label>
            <input
              type="text"
              value={state.adminUsername}
              onChange={(e) => onChange({ adminUsername: e.target.value })}
              placeholder="admin"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Email
            </label>
            <input
              type="email"
              value={state.adminEmail}
              onChange={(e) => onChange({ adminEmail: e.target.value })}
              placeholder="admin@example.com"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Password
            </label>
            <input
              type="password"
              value={state.adminPassword}
              onChange={(e) => onChange({ adminPassword: e.target.value })}
              placeholder="Choose a strong password"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
        </>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 2 - Libraries
// ---------------------------------------------------------------------------

function StepLibraries({
  state,
  onChange,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
}) {
  const [newTitle, setNewTitle] = useState('')
  const [newType, setNewType] = useState<'movie' | 'show'>('movie')
  const [newPath, setNewPath] = useState('')

  const addLibrary = () => {
    if (!newTitle.trim() || !newPath.trim()) return
    onChange({
      libraries: [
        ...state.libraries,
        { title: newTitle.trim(), type: newType, paths: [newPath.trim()] },
      ],
    })
    setNewTitle('')
    setNewPath('')
  }

  const removeLibrary = (idx: number) => {
    onChange({ libraries: state.libraries.filter((_, i) => i !== idx) })
  }

  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">Media Libraries</h2>
        <p className="text-gray-400 mt-2">
          Add folders containing your movies and TV shows.
        </p>
      </div>

      {/* Existing libraries */}
      {state.libraries.length > 0 && (
        <div className="space-y-3">
          {state.libraries.map((lib, idx) => (
            <div
              key={idx}
              className="flex items-center justify-between bg-gray-700/50 rounded-lg p-4"
            >
              <div className="flex items-center gap-3">
                <FolderOpen className="w-5 h-5 text-indigo-400" />
                <div>
                  <p className="text-white font-medium">{lib.title}</p>
                  <p className="text-sm text-gray-400">
                    {lib.type === 'movie' ? 'Movies' : 'TV Shows'} &mdash;{' '}
                    {lib.paths.join(', ')}
                  </p>
                </div>
              </div>
              <button
                onClick={() => removeLibrary(idx)}
                className="p-2 text-gray-400 hover:text-red-400 rounded-lg hover:bg-gray-700 transition-colors"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Add new library */}
      <div className="bg-gray-700/30 rounded-xl p-4 space-y-4 border border-gray-700">
        <h3 className="text-sm font-medium text-gray-300">Add Library</h3>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-xs text-gray-400 mb-1">Title</label>
            <input
              type="text"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder="e.g. Movies"
              className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-400 mb-1">Type</label>
            <select
              value={newType}
              onChange={(e) =>
                setNewType(e.target.value as 'movie' | 'show')
              }
              className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
            >
              <option value="movie">Movies</option>
              <option value="show">TV Shows</option>
            </select>
          </div>
        </div>
        <div>
          <label className="block text-xs text-gray-400 mb-1">
            Folder Path
          </label>
          <input
            type="text"
            value={newPath}
            onChange={(e) => setNewPath(e.target.value)}
            placeholder="/media/movies"
            className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
        </div>
        <button
          onClick={addLibrary}
          disabled={!newTitle.trim() || !newPath.trim()}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-lg text-sm font-medium transition-colors"
        >
          <Plus className="w-4 h-4" />
          Add Library
        </button>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 3 - Tuners
// ---------------------------------------------------------------------------

function StepTuners({
  state,
  onChange,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
}) {
  const [discovering, setDiscovering] = useState(false)
  const [discovered, setDiscovered] = useState<WizardTuner[]>([])
  const [discoverError, setDiscoverError] = useState<string | null>(null)
  const [manualUrl, setManualUrl] = useState('')
  const [adding, setAdding] = useState(false)
  const [addError, setAddError] = useState<string | null>(null)

  const handleDiscover = async () => {
    setDiscovering(true)
    setDiscoverError(null)
    try {
      const res = await fetch('/api/tuners/discover', { method: 'POST', headers: authHeaders })
      if (!res.ok) throw new Error('Discovery failed')
      const data = await res.json() as { devices: Array<{ deviceId: string; modelNumber: string; baseUrl: string }> }
      // Add discovered devices that aren't already added
      const existingIds = new Set(state.tuners.map((t) => t.deviceId))
      const newDevices = (data.devices || []).filter((d) => !existingIds.has(d.deviceId))
      setDiscovered(newDevices)
      if (newDevices.length === 0 && (data.devices || []).length === 0) {
        setDiscoverError('No HDHomeRun devices found on your network. Try adding manually.')
      }
    } catch {
      setDiscoverError('Discovery failed. Make sure the server can reach your local network.')
    } finally {
      setDiscovering(false)
    }
  }

  const addDevice = async (url: string) => {
    setAdding(true)
    setAddError(null)
    try {
      const res = await fetch('/api/tuners', {
        method: 'POST',
        headers: authHeaders,
        body: JSON.stringify({ url }),
      })
      if (!res.ok) {
        const err = await res.json().catch(() => ({})) as { message?: string }
        throw new Error(err.message || 'Failed to add tuner')
      }
      const data = await res.json() as { device: { deviceId: string; modelNumber: string; baseUrl: string }; imported: number }
      const newTuner: WizardTuner = {
        deviceId: data.device.deviceId,
        modelNumber: data.device.modelNumber,
        baseUrl: data.device.baseUrl,
        imported: data.imported ?? 0,
      }
      onChange({ tuners: [...state.tuners, newTuner] })
      setDiscovered((prev) => prev.filter((d) => d.deviceId !== data.device.deviceId))
      setManualUrl('')
    } catch (err) {
      setAddError(err instanceof Error ? err.message : 'Failed to add tuner')
    } finally {
      setAdding(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">HDHomeRun Tuners</h2>
        <p className="text-gray-400 mt-2">
          Connect your HDHomeRun device to get Live TV channels. You can skip this and add tuners later.
        </p>
      </div>

      {/* Already added */}
      {state.tuners.length > 0 && (
        <div className="space-y-2">
          <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">Added</p>
          {state.tuners.map((t) => (
            <div key={t.deviceId} className="flex items-center gap-3 bg-green-500/10 border border-green-500/30 rounded-lg p-3">
              <CheckCircle className="w-5 h-5 text-green-400 shrink-0" />
              <div>
                <p className="text-white font-medium">{t.modelNumber || t.deviceId}</p>
                <p className="text-xs text-gray-400">{t.baseUrl} · {t.imported} channels imported</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Discover */}
      <div className="space-y-3">
        <button
          onClick={handleDiscover}
          disabled={discovering}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-lg text-sm font-medium"
        >
          {discovering ? <Loader className="w-4 h-4 animate-spin" /> : <Search className="w-4 h-4" />}
          {discovering ? 'Scanning network…' : 'Discover Tuners'}
        </button>
        {discoverError && <p className="text-sm text-yellow-400">{discoverError}</p>}
        {discovered.length > 0 && (
          <div className="space-y-2">
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">Found on network</p>
            {discovered.map((d) => (
              <div key={d.deviceId} className="flex items-center justify-between bg-gray-700/50 border border-gray-600 rounded-lg p-3">
                <div>
                  <p className="text-white font-medium">{d.modelNumber || d.deviceId}</p>
                  <p className="text-xs text-gray-400">{d.baseUrl}</p>
                </div>
                <button
                  onClick={() => addDevice(d.baseUrl)}
                  disabled={adding}
                  className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white text-sm rounded-lg"
                >
                  Add
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Manual add */}
      <div>
        <p className="text-xs font-semibold uppercase tracking-wider text-gray-500 mb-2">Add manually</p>
        <div className="flex gap-2">
          <input
            type="text"
            value={manualUrl}
            onChange={(e) => setManualUrl(e.target.value)}
            placeholder="192.168.1.100"
            className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
          <button
            onClick={() => addDevice(manualUrl.trim())}
            disabled={adding || !manualUrl.trim()}
            className="flex items-center gap-1.5 px-4 py-2 bg-gray-600 hover:bg-gray-500 disabled:opacity-40 text-white text-sm rounded-lg"
          >
            {adding ? <Loader className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
            Add
          </button>
        </div>
        {addError && <p className="text-sm text-red-400 mt-1">{addError}</p>}
        <p className="text-xs text-gray-500 mt-1">Enter the IP address. Do not use port 5004 (that is the stream port).</p>
      </div>

      <p className="text-xs text-gray-500 text-center">
        This step is optional — you can add tuners from the Tuners page later.
      </p>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 4 - Guide Data
// ---------------------------------------------------------------------------

function StepGuideData({
  state,
  onChange,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
}) {
  const [searching, setSearching] = useState(false)
  const [providers, setProviders] = useState<WizardGuideProvider[]>([])
  const [searchError, setSearchError] = useState<string | null>(null)
  const [zipInput, setZipInput] = useState(state.zipCode)

  const handleSearch = async () => {
    if (!zipInput.trim()) return
    setSearching(true)
    setSearchError(null)
    setProviders([])
    onChange({ guideProvider: null, zipCode: zipInput.trim() })
    try {
      const res = await fetch(`/livetv/epg/tvguide/providers?zip=${encodeURIComponent(zipInput.trim())}`, { headers: authHeaders })
      if (!res.ok) throw new Error('Could not find providers for that ZIP code')
      const data = await res.json() as { providers: WizardGuideProvider[] }
      setProviders(data.providers || [])
      if (!data.providers?.length) setSearchError('No providers found for that ZIP code. Try a nearby ZIP.')
    } catch (err) {
      setSearchError(err instanceof Error ? err.message : 'Search failed')
    } finally {
      setSearching(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">TV Guide Data</h2>
        <p className="text-gray-400 mt-2">
          Enter your ZIP code to find available TV guide providers for program listings. You can skip this and configure it later.
        </p>
      </div>

      {state.guideProvider && (
        <div className="flex items-center gap-3 bg-green-500/10 border border-green-500/30 rounded-lg p-3">
          <CheckCircle className="w-5 h-5 text-green-400 shrink-0" />
          <div className="flex-1">
            <p className="text-white font-medium">{state.guideProvider.name}</p>
            <p className="text-xs text-gray-400">{state.guideProvider.type}{state.guideProvider.city ? ` · ${state.guideProvider.city}, ${state.guideProvider.state}` : ''}</p>
          </div>
          <button
            onClick={() => { onChange({ guideProvider: null }); setProviders([]) }}
            className="text-xs text-gray-400 hover:text-white"
          >
            Change
          </button>
        </div>
      )}

      {!state.guideProvider && (
        <>
          <div className="flex gap-2">
            <input
              type="text"
              value={zipInput}
              onChange={(e) => setZipInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
              placeholder="ZIP code (e.g. 90210)"
              maxLength={10}
              className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
            <button
              onClick={handleSearch}
              disabled={searching || !zipInput.trim()}
              className="flex items-center gap-1.5 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 text-white text-sm rounded-lg"
            >
              {searching ? <Loader className="w-4 h-4 animate-spin" /> : <Search className="w-4 h-4" />}
              Find Providers
            </button>
          </div>
          {searchError && <p className="text-sm text-yellow-400">{searchError}</p>}
          {providers.length > 0 && (
            <div className="space-y-2 max-h-64 overflow-y-auto">
              <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">{providers.length} providers found — pick one</p>
              {providers.map((p) => (
                <button
                  key={p.id}
                  onClick={() => onChange({ guideProvider: p })}
                  className="w-full text-left flex items-center justify-between bg-gray-700/50 hover:bg-gray-700 border border-gray-600 rounded-lg p-3 transition-colors"
                >
                  <div>
                    <p className="text-white text-sm font-medium">{p.name}</p>
                    <p className="text-xs text-gray-400">{p.type}{p.city ? ` · ${p.city}, ${p.state}` : ''}</p>
                  </div>
                  <ArrowRight className="w-4 h-4 text-gray-400" />
                </button>
              ))}
            </div>
          )}
        </>
      )}

      <p className="text-xs text-gray-500 text-center">
        This step is optional — you can configure guide data from Settings → Live TV later.
      </p>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 5 - Live TV (M3U)
// ---------------------------------------------------------------------------

function StepLiveTV({
  state,
  onChange,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
}) {
  const [name, setName] = useState(state.m3uSource?.name || '')
  const [url, setUrl] = useState(state.m3uSource?.url || '')

  const handleSet = () => {
    if (name.trim() && url.trim()) {
      onChange({ m3uSource: { name: name.trim(), url: url.trim() } })
    }
  }

  const handleClear = () => {
    onChange({ m3uSource: undefined })
    setName('')
    setUrl('')
  }

  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">Live TV</h2>
        <p className="text-gray-400 mt-2">
          Optionally add an M3U source for live TV channels. You can skip this
          and add sources later.
        </p>
      </div>

      {state.m3uSource ? (
        <div className="bg-green-500/10 border border-green-500/30 rounded-lg p-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <CheckCircle className="w-5 h-5 text-green-400" />
            <div>
              <p className="text-white font-medium">{state.m3uSource.name}</p>
              <p className="text-sm text-gray-400 truncate max-w-md">
                {state.m3uSource.url}
              </p>
            </div>
          </div>
          <button
            onClick={handleClear}
            className="p-2 text-gray-400 hover:text-red-400 rounded-lg hover:bg-gray-700 transition-colors"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Source Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="My IPTV"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              M3U URL
            </label>
            <input
              type="url"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="http://example.com/playlist.m3u"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <button
            onClick={handleSet}
            disabled={!name.trim() || !url.trim()}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-lg text-sm font-medium transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add M3U Source
          </button>
        </div>
      )}

      <p className="text-xs text-gray-500 text-center">
        This step is optional. You can always add or edit Live TV sources from
        Settings later.
      </p>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 4 - DVR
// ---------------------------------------------------------------------------

function StepDVR({
  state,
  onChange,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
}) {
  const [showRecordingDirBrowser, setShowRecordingDirBrowser] = useState(false)

  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">DVR Settings</h2>
        <p className="text-gray-400 mt-2">
          Configure recording options for your Live TV channels.
        </p>
      </div>

      <label className="flex items-center gap-3 cursor-pointer">
        <div
          className={`relative w-11 h-6 rounded-full transition-colors ${
            state.dvrEnabled ? 'bg-indigo-600' : 'bg-gray-600'
          }`}
          onClick={() => onChange({ dvrEnabled: !state.dvrEnabled })}
        >
          <div
            className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${
              state.dvrEnabled ? 'translate-x-5' : ''
            }`}
          />
        </div>
        <span className="text-white font-medium">Enable DVR Recording</span>
      </label>

      {state.dvrEnabled && (
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Recording Directory
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              value={state.recordingDir}
              onChange={(e) => onChange({ recordingDir: e.target.value })}
              placeholder="/recordings"
              className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
            <button
              type="button"
              onClick={() => setShowRecordingDirBrowser(true)}
              className="px-3 py-2 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white rounded-lg text-sm whitespace-nowrap"
            >
              Browse
            </button>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Path where recorded programmes will be saved on disk.
          </p>
          {showRecordingDirBrowser && (
            <FileBrowser
              initialPath={state.recordingDir || ''}
              onSelect={(path) => {
                onChange({ recordingDir: path })
                setShowRecordingDirBrowser(false)
              }}
              onCancel={() => setShowRecordingDirBrowser(false)}
            />
          )}
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 5 - Metadata (TMDB)
// ---------------------------------------------------------------------------

function StepTMDB({ state, onChange }: { state: WizardState; onChange: (c: Partial<WizardState>) => void }) {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-white">Metadata (Optional)</h2>
        <p className="text-gray-400 mt-2">
          A TMDB API key enables rich artwork, posters, and metadata enrichment for your media libraries.
        </p>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium text-gray-300">TMDB API Key</label>
        <input
          type="password"
          value={state.tmdbApiKey}
          onChange={(e) => onChange({ tmdbApiKey: e.target.value })}
          placeholder="Paste your TMDB API key here"
          className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
        />
        <p className="text-xs text-gray-500">
          Free account required.{' '}
          <a
            href="https://www.themoviedb.org/settings/api"
            target="_blank"
            rel="noreferrer"
            className="text-indigo-400 hover:text-indigo-300"
          >
            Get your key at themoviedb.org →
          </a>
        </p>
      </div>

      {state.tmdbApiKey && (
        <div className="flex items-center gap-2 text-green-400 text-sm">
          <CheckCircle className="w-4 h-4" />
          API key will be saved when you continue
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 8 - Done
// ---------------------------------------------------------------------------

function StepDone({ state }: { state: WizardState }) {
  return (
    <div className="space-y-6 text-center">
      <div className="flex justify-center">
        <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center">
          <Rocket className="w-8 h-8 text-green-400" />
        </div>
      </div>

      <div>
        <h2 className="text-2xl font-bold text-white">All Set!</h2>
        <p className="text-gray-400 mt-2">
          Your OpenFlix server is ready. Here is a summary of what was
          configured:
        </p>
      </div>

      <div className="bg-gray-700/30 rounded-xl p-5 text-left space-y-3 max-w-md mx-auto">
        <div className="flex items-center justify-between">
          <span className="text-gray-400">Server Name</span>
          <span className="text-white font-medium">
            {state.serverName || 'OpenFlix'}
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-gray-400">Libraries</span>
          <span className="text-white font-medium">
            {state.libraries.length} added
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-gray-400">Tuners</span>
          <span className="text-white font-medium">
            {state.tuners.length > 0 ? `${state.tuners.length} added` : 'Skipped'}
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-gray-400">Guide Data</span>
          <span className="text-white font-medium">
            {state.guideProvider ? state.guideProvider.name : 'Skipped'}
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-gray-400">TMDB</span>
          <span className="text-white font-medium">
            {state.tmdbApiKey ? 'Configured' : 'Skipped'}
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-gray-400">Live TV Source</span>
          <span className="text-white font-medium">
            {state.m3uSource ? state.m3uSource.name : 'Skipped'}
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-gray-400">DVR</span>
          <span className="text-white font-medium">
            {state.dvrEnabled ? 'Enabled' : 'Disabled'}
          </span>
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// SetupWizard (exported)
// ---------------------------------------------------------------------------

export function SetupWizardPage() {
  const [state, setState] = useState<WizardState>({
    step: 1,
    serverName: '',
    adminUsername: '',
    adminEmail: '',
    adminPassword: '',
    libraries: [],
    tuners: [],
    zipCode: '',
    guideProvider: null,
    m3uSource: undefined,
    dvrEnabled: false,
    recordingDir: '/recordings',
    tmdbApiKey: '',
  })

  const [needsAdmin, setNeedsAdmin] = useState(false)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Check initial status
  useEffect(() => {
    const check = async () => {
      try {
        const res = await fetch('/api/status', { headers: authHeaders })
        if (!res.ok) throw new Error('Failed to fetch status')
        const data: StatusResponse = await res.json()
        setState((s) => ({
          ...s,
          serverName: data.server?.name || '',
        }))
        // If no libraries and effectively a fresh install, we need admin
        if (data.libraries?.count === 0) {
          setNeedsAdmin(true)
        }
      } catch {
        // Still allow wizard to proceed even if status check fails
        setNeedsAdmin(true)
      } finally {
        setLoading(false)
      }
    }
    check()
  }, [])

  const patch = (changes: Partial<WizardState>) => {
    setState((prev) => ({ ...prev, ...changes }))
  }

  const canAdvance = (): boolean => {
    switch (state.step) {
      case 1:
        if (needsAdmin) {
          return (
            !!state.serverName.trim() &&
            !!state.adminUsername.trim() &&
            !!state.adminEmail.trim() &&
            !!state.adminPassword.trim()
          )
        }
        return !!state.serverName.trim()
      case 2: return true  // libraries optional
      case 3: return true  // tuners optional
      case 4: return true  // guide optional
      case 5: return true  // TMDB optional
      case 6: return true  // M3U optional
      case 7: return !state.dvrEnabled || !!state.recordingDir.trim()
      case 8: return true
      default: return false
    }
  }

  const submitStep = async (stepNum: number) => {
    setError(null)
    setSubmitting(true)
    try {
      switch (stepNum) {
        case 1: {
          // Register admin if needed
          if (needsAdmin) {
            const regRes = await fetch('/auth/register', {
              method: 'POST',
              headers: authHeaders,
              body: JSON.stringify({
                username: state.adminUsername,
                email: state.adminEmail,
                password: state.adminPassword,
              }),
            })
            if (!regRes.ok) {
              const errData = await regRes.json().catch(() => ({}))
              throw new Error(
                (errData as { error?: string }).error || 'Failed to create admin account'
              )
            }
            // Login to get token
            const loginRes = await fetch('/auth/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                username: state.adminUsername,
                password: state.adminPassword,
              }),
            })
            if (loginRes.ok) {
              const loginData = await loginRes.json()
              if (loginData.authToken) {
                localStorage.setItem('openflix_token', loginData.authToken)
                authHeaders['X-Plex-Token'] = loginData.authToken
              }
            }
          }
          // Update server name
          await fetch('/admin/settings', {
            method: 'PUT',
            headers: authHeaders,
            body: JSON.stringify({ server_name: state.serverName }),
          })
          break
        }
        case 2: {
          // Create libraries
          for (const lib of state.libraries) {
            await fetch('/admin/libraries', {
              method: 'POST',
              headers: authHeaders,
              body: JSON.stringify({ title: lib.title, type: lib.type, paths: lib.paths }),
            })
          }
          break
        }
        case 3: {
          // Tuners are added live in StepTuners — nothing to submit here
          break
        }
        case 4: {
          // Create EPG source from selected guide provider
          if (state.guideProvider && state.zipCode) {
            await fetch('/livetv/epg/sources', {
              method: 'POST',
              headers: authHeaders,
              body: JSON.stringify({
                name: state.guideProvider.name,
                providerType: 'tvguide',
                tvguideProviderId: String(state.guideProvider.id),
                tvguideZipCode: state.zipCode,
                tvguideDays: 7,
              }),
            })
          }
          break
        }
        case 5: {
          // Save TMDB API key
          if (state.tmdbApiKey.trim()) {
            await fetch('/admin/settings', {
              method: 'PUT',
              headers: authHeaders,
              body: JSON.stringify({ tmdb_api_key: state.tmdbApiKey.trim() }),
            })
          }
          break
        }
        case 6: {
          // Add M3U source
          if (state.m3uSource) {
            await fetch('/livetv/sources', {
              method: 'POST',
              headers: authHeaders,
              body: JSON.stringify({ name: state.m3uSource.name, url: state.m3uSource.url }),
            })
          }
          break
        }
        case 7: {
          // Update DVR settings
          if (state.dvrEnabled) {
            await fetch('/admin/settings', {
              method: 'PUT',
              headers: authHeaders,
              body: JSON.stringify({ dvr_enabled: true, recording_dir: state.recordingDir }),
            })
          }
          break
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
      setSubmitting(false)
      return false
    }
    setSubmitting(false)
    return true
  }

  const handleNext = async () => {
    if (state.step < TOTAL_STEPS) {
      const ok = await submitStep(state.step)
      if (ok) {
        patch({ step: state.step + 1 })
      }
    }
  }

  const handleBack = () => {
    if (state.step > 1) {
      patch({ step: state.step - 1 })
      setError(null)
    }
  }

  const handleFinish = () => {
    window.location.href = '/ui'
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-900 flex items-center justify-center p-6">
      <div className="w-full max-w-2xl">
        <StepIndicator current={state.step} total={TOTAL_STEPS} />

        <div className="bg-gray-800 rounded-xl p-8 shadow-2xl">
          {state.step === 1 && (
            <StepWelcome
              state={state}
              onChange={patch}
              needsAdmin={needsAdmin}
            />
          )}
          {state.step === 2 && (
            <StepLibraries state={state} onChange={patch} />
          )}
          {state.step === 3 && <StepTuners state={state} onChange={patch} />}
          {state.step === 4 && <StepGuideData state={state} onChange={patch} />}
          {state.step === 5 && <StepTMDB state={state} onChange={patch} />}
          {state.step === 6 && <StepLiveTV state={state} onChange={patch} />}
          {state.step === 7 && <StepDVR state={state} onChange={patch} />}
          {state.step === 8 && <StepDone state={state} />}

          {error && (
            <div className="mt-4 flex items-center gap-2 text-red-400 bg-red-500/10 border border-red-500/30 rounded-lg p-3 text-sm">
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
              {error}
            </div>
          )}

          {/* Navigation Buttons */}
          <div className="flex items-center justify-between mt-8 pt-6 border-t border-gray-700">
            {state.step > 1 && state.step < TOTAL_STEPS ? (
              <button
                onClick={handleBack}
                className="flex items-center gap-2 px-5 py-2.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium transition-colors"
              >
                <ArrowLeft className="w-4 h-4" />
                Back
              </button>
            ) : (
              <div />
            )}

            {state.step < TOTAL_STEPS ? (
              <button
                onClick={handleNext}
                disabled={!canAdvance() || submitting}
                className="flex items-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
              >
                {submitting ? (
                  <Loader className="w-4 h-4 animate-spin" />
                ) : (
                  <>
                    {state.step === 2 && state.libraries.length === 0
                      ? 'Skip'
                      : state.step === 3 && state.tuners.length === 0
                        ? 'Skip'
                        : state.step === 4 && !state.guideProvider
                          ? 'Skip'
                          : state.step === 5 && !state.tmdbApiKey
                            ? 'Skip'
                            : state.step === 6 && !state.m3uSource
                              ? 'Skip'
                              : 'Next'}
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
            ) : (
              <button
                onClick={handleFinish}
                className="flex items-center gap-2 px-6 py-2.5 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium transition-colors"
              >
                Go to Dashboard
                <ArrowRight className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
