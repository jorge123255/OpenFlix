import { useState } from 'react'
import { Radio, Loader, AlertCircle, Plus, Minus, Trash2, RefreshCw, Wifi, X, CheckCircle, Signal, Search, Tv, Star } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

const authFetch = async (url: string, options?: RequestInit) => {
  const token = localStorage.getItem('openflix_token') || ''
  const res = await fetch(url, {
    ...options,
    headers: { 'X-Plex-Token': token, 'Content-Type': 'application/json', ...options?.headers },
  })
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

// Matches HDHomeRunDevice from server
interface Tuner {
  deviceId: string
  localIp: string
  baseUrl: string
  modelNumber: string
  firmwareName: string
  firmwareVersion: string
  tunerCount: number
  lineupUrl: string
  deviceAuth?: string
  priority?: number
}

// Matches HDHomeRunStatus from server
interface TunerStatus {
  Resource: string
  VctNumber: string
  VctName: string
  Frequency: number
  SignalStrengthPercent: number
  SymbolQualityPercent: number
  StreamingRate: number
  TargetIP?: string
}

// Matches HDHomeRunChannel from server
interface TunerChannel {
  GuideNumber: string
  GuideName: string
  VideoCodec?: string
  AudioCodec?: string
  HD?: number
  URL: string
  Favorite?: number
  DRM?: number
}

interface TunerStatusResponse {
  tuners: TunerStatus[]
  count: number
}

interface TunerLineupResponse {
  channels: TunerChannel[]
  count: number
}

function SignalBars({ strength }: { strength: number }) {
  const bars = 5
  const activeBars = Math.round((strength / 100) * bars)
  const getColor = (bar: number) => {
    if (bar > activeBars) return 'bg-gray-600'
    if (strength >= 80) return 'bg-green-500'
    if (strength >= 50) return 'bg-yellow-500'
    return 'bg-red-500'
  }
  return (
    <div className="flex items-end gap-0.5 h-4" title={`${strength}%`}>
      {Array.from({ length: bars }).map((_, i) => (
        <div
          key={i}
          className={`w-1.5 rounded-sm transition-all ${getColor(i + 1)}`}
          style={{ height: `${((i + 1) / bars) * 100}%` }}
        />
      ))}
    </div>
  )
}

function AddTunerModal({
  onClose,
  onAdd,
  isAdding,
}: {
  onClose: () => void
  onAdd: (url: string) => void
  isAdding: boolean
}) {
  const [url, setUrl] = useState('')
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (url.trim()) onAdd(url.trim())
  }
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">Add Tuner Manually</h2>
          <button onClick={onClose} className="p-1 text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">IP Address or URL</label>
            <input
              type="text"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="192.168.1.100"
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              Enter the IP address of your HDHomeRun device (e.g. 192.168.1.100). Do not use port 5004 — that is the stream port, not the API port. Common ports are tried automatically.
            </p>
          </div>
          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isAdding || !url.trim()}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg"
            >
              {isAdding ? 'Adding...' : 'Add Tuner'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function TunerCard({
  tuner,
  onRemove,
}: {
  tuner: Tuner
  onRemove: () => void
}) {
  const queryClient = useQueryClient()
  const [showLineup, setShowLineup] = useState(false)
  const [channelFilter, setChannelFilter] = useState('')

  const { data: statusData, isLoading: loadingStatus, isFetching: fetchingStatus, isError: statusError } = useQuery({
    queryKey: ['tunerStatus', tuner.deviceId],
    queryFn: () => authFetch(`/api/tuners/${tuner.deviceId}/status`) as Promise<TunerStatusResponse>,
    // Only poll if the endpoint is working — stop if it errors out
    refetchInterval: (query) => (query.state.status === 'error' ? false : 8000),
    retry: 1,
    refetchOnWindowFocus: false,
  })

  const { data: lineupData, isLoading: loadingLineup } = useQuery({
    queryKey: ['tunerLineup', tuner.deviceId],
    queryFn: () => authFetch(`/api/tuners/${tuner.deviceId}/lineup`) as Promise<TunerLineupResponse>,
    enabled: showLineup,
  })

  const scanChannels = useMutation({
    mutationFn: () => authFetch(`/api/tuners/${tuner.deviceId}/scan`, { method: 'POST' }),
    onSuccess: () => {
      setTimeout(() => queryClient.invalidateQueries({ queryKey: ['tunerLineup', tuner.deviceId] }), 3000)
    },
  })

  const updatePriority = useMutation({
    mutationFn: (priority: number) =>
      authFetch(`/api/tuners/${tuner.deviceId}`, { method: 'PUT', body: JSON.stringify({ priority }) }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tuners'] })
    },
  })

  const tunerStatuses = statusData?.tuners || []
  const activeTuners = tunerStatuses.filter((t) => t.TargetIP && t.TargetIP !== '').length

  const rawPriority = typeof tuner.priority === 'number' ? tuner.priority : 0
  const clampedPriority = Math.min(10, Math.max(0, rawPriority))
  const adjustPriority = (delta: number) => {
    const next = Math.min(10, Math.max(0, clampedPriority + delta))
    if (next !== clampedPriority) updatePriority.mutate(next)
  }

  const channels = lineupData?.channels || []
  const filteredChannels = channels.filter(
    (ch) =>
      !channelFilter ||
      ch.GuideName.toLowerCase().includes(channelFilter.toLowerCase()) ||
      ch.GuideNumber.includes(channelFilter)
  )

  return (
    <div className="bg-gray-800 rounded-xl overflow-hidden">
      <div className="p-6">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-start gap-4">
            <div className="p-3 bg-gray-700 rounded-lg">
              <Radio className="h-6 w-6 text-indigo-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-white">{tuner.modelNumber || tuner.deviceId}</h3>
              <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-1 text-sm text-gray-400">
                <span className="flex items-center gap-1">
                  <Wifi className="h-3.5 w-3.5" />
                  {tuner.localIp}
                </span>
                <span className="font-mono text-xs text-gray-500">ID: {tuner.deviceId}</span>
                {tuner.firmwareVersion && <span>FW: {tuner.firmwareVersion}</span>}
                <span>{tuner.tunerCount} tuner{tuner.tunerCount !== 1 ? 's' : ''}</span>
              </div>
              <div className="mt-3 flex flex-wrap items-center gap-3">
                <div className="text-sm text-gray-300">
                  Priority: <span className="font-semibold text-white">{clampedPriority}</span>
                </div>
                <span className="text-xs text-gray-500">(lower = higher priority)</span>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => adjustPriority(-1)}
                    disabled={updatePriority.isPending || clampedPriority <= 0}
                    className="h-7 w-7 flex items-center justify-center rounded-full bg-gray-700 text-indigo-300 hover:bg-gray-600 disabled:bg-gray-800 disabled:text-gray-500 transition-colors"
                    aria-label="Decrease priority"
                  >
                    <Minus className="h-3.5 w-3.5" />
                  </button>
                  <div className="min-w-8 h-7 px-2 flex items-center justify-center rounded-full bg-gray-900 border border-gray-700 text-white text-xs font-semibold">
                    {clampedPriority}
                  </div>
                  <button
                    onClick={() => adjustPriority(1)}
                    disabled={updatePriority.isPending || clampedPriority >= 10}
                    className="h-7 w-7 flex items-center justify-center rounded-full bg-gray-700 text-indigo-300 hover:bg-gray-600 disabled:bg-gray-800 disabled:text-gray-500 transition-colors"
                    aria-label="Increase priority"
                  >
                    <Plus className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2 flex-shrink-0">
            <button
              onClick={onRemove}
              className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg transition-colors"
              title="Remove tuner"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </div>

        {/* Tuner Status */}
        <div className="mt-4 pt-4 border-t border-gray-700">
          <div className="flex items-center justify-between mb-3">
            <h4 className="text-sm font-medium text-gray-400">
              Tuner Status
              {activeTuners > 0 && (
                <span className="ml-2 text-green-400">({activeTuners} streaming)</span>
              )}
            </h4>
            {/* Only show spinner on initial load, not every 8s background poll */}
            {loadingStatus && !statusData && <Loader className="h-4 w-4 text-gray-500 animate-spin" />}
            {!loadingStatus && fetchingStatus && <div className="h-1.5 w-1.5 rounded-full bg-gray-600 animate-pulse" />}
          </div>

          {statusError ? (
            <p className="text-xs text-gray-500 italic">Status unavailable for this device.</p>
          ) : tunerStatuses.length > 0 ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              {tunerStatuses.map((status, idx) => {
                const isActive = !!(status.TargetIP && status.TargetIP !== '')
                return (
                  <div
                    key={status.Resource || idx}
                    className={`p-3 rounded-lg ${
                      isActive
                        ? 'bg-green-500/10 border border-green-500/30'
                        : 'bg-gray-700/50 border border-gray-700'
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-medium text-gray-400 capitalize">
                        {status.Resource || `Tuner ${idx + 1}`}
                      </span>
                      {isActive ? (
                        <SignalBars strength={status.SignalStrengthPercent} />
                      ) : (
                        <Signal className="h-4 w-4 text-gray-600" />
                      )}
                    </div>
                    {isActive ? (
                      <div>
                        <p className="text-sm text-white font-medium truncate" title={status.VctName}>
                          {status.VctName || status.VctNumber || 'Active'}
                        </p>
                        <div className="flex gap-2 mt-1 text-xs text-gray-400">
                          <span>Sig: {status.SignalStrengthPercent}%</span>
                          <span>Sym: {status.SymbolQualityPercent}%</span>
                        </div>
                        {status.StreamingRate > 0 && (
                          <p className="text-xs text-gray-500 mt-0.5">
                            {(status.StreamingRate / 1_000_000).toFixed(1)} Mbps
                          </p>
                        )}
                      </div>
                    ) : (
                      <p className="text-sm text-gray-500">Idle</p>
                    )}
                  </div>
                )
              })}
            </div>
          ) : !loadingStatus ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              {Array.from({ length: tuner.tunerCount || 2 }).map((_, i) => (
                <div key={i} className="p-3 rounded-lg bg-gray-700/50 border border-gray-700">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-medium text-gray-400">Tuner {i + 1}</span>
                    <Signal className="h-4 w-4 text-gray-600" />
                  </div>
                  <p className="text-sm text-gray-500">Idle</p>
                </div>
              ))}
            </div>
          ) : null}
        </div>

        {/* Channel Lineup */}
        <div className="mt-4 pt-4 border-t border-gray-700">
          <div className="flex items-center justify-between mb-3">
            <button
              onClick={() => setShowLineup(!showLineup)}
              className="flex items-center gap-2 text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
            >
              <Tv className="h-4 w-4" />
              {showLineup ? 'Hide' : 'Show'} Channel Lineup
              {channels.length > 0 && (
                <span className="px-1.5 py-0.5 text-xs bg-gray-700 text-gray-300 rounded-full">
                  {channels.length}
                </span>
              )}
            </button>
            {showLineup && (
              <button
                onClick={() => scanChannels.mutate()}
                disabled={scanChannels.isPending}
                className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-xs rounded-lg transition-colors"
              >
                {scanChannels.isPending ? (
                  <Loader className="h-3 w-3 animate-spin" />
                ) : (
                  <RefreshCw className="h-3 w-3" />
                )}
                Scan Channels
              </button>
            )}
          </div>

          {showLineup && (
            <div className="mt-2">
              {loadingLineup ? (
                <div className="flex items-center justify-center py-8">
                  <Loader className="h-6 w-6 text-indigo-500 animate-spin" />
                </div>
              ) : channels.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  <Tv className="h-8 w-8 mx-auto mb-2 text-gray-600" />
                  <p className="text-sm">No channels found.</p>
                  <p className="text-xs mt-1">Run a channel scan or import channels from an M3U source.</p>
                </div>
              ) : (
                <>
                  <div className="relative mb-3">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-500" />
                    <input
                      type="text"
                      value={channelFilter}
                      onChange={(e) => setChannelFilter(e.target.value)}
                      placeholder="Filter channels…"
                      className="w-full pl-9 pr-4 py-2 text-sm bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500"
                    />
                  </div>
                  <div className="overflow-x-auto max-h-80 overflow-y-auto rounded-lg border border-gray-700">
                    <table className="w-full text-sm">
                      <thead className="sticky top-0 bg-gray-750 bg-gray-900">
                        <tr className="border-b border-gray-700">
                          <th className="text-left py-2 px-3 text-xs font-medium text-gray-400 w-16">Ch</th>
                          <th className="text-left py-2 px-3 text-xs font-medium text-gray-400">Name</th>
                          <th className="text-left py-2 px-3 text-xs font-medium text-gray-400 hidden sm:table-cell">Video</th>
                          <th className="text-left py-2 px-3 text-xs font-medium text-gray-400 hidden sm:table-cell">Audio</th>
                          <th className="text-left py-2 px-3 text-xs font-medium text-gray-400">Tags</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredChannels.map((ch) => (
                          <tr
                            key={ch.GuideNumber}
                            className="border-b border-gray-700/50 hover:bg-gray-700/30"
                          >
                            <td className="py-2 px-3 font-mono text-white">{ch.GuideNumber}</td>
                            <td className="py-2 px-3 text-gray-200">{ch.GuideName}</td>
                            <td className="py-2 px-3 text-gray-400 hidden sm:table-cell">
                              {ch.VideoCodec || '—'}
                            </td>
                            <td className="py-2 px-3 text-gray-400 hidden sm:table-cell">
                              {ch.AudioCodec || '—'}
                            </td>
                            <td className="py-2 px-3">
                              <div className="flex gap-1 flex-wrap">
                                {ch.HD === 1 && (
                                  <span className="px-1.5 py-0.5 text-xs bg-indigo-500/20 text-indigo-400 rounded">HD</span>
                                )}
                                {ch.Favorite === 1 && (
                                  <span className="px-1.5 py-0.5 text-xs bg-yellow-500/20 text-yellow-400 rounded">Fav</span>
                                )}
                                {ch.DRM === 1 && (
                                  <span className="px-1.5 py-0.5 text-xs bg-red-500/20 text-red-400 rounded">DRM</span>
                                )}
                              </div>
                            </td>
                          </tr>
                        ))}
                        {filteredChannels.length === 0 && (
                          <tr>
                            <td colSpan={5} className="py-6 text-center text-gray-500 text-sm">
                              No channels match "{channelFilter}"
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                  <p className="text-xs text-gray-500 mt-2">
                    {filteredChannels.length} of {channels.length} channels
                    {channels.filter((c) => c.DRM === 1).length > 0 && (
                      <span className="ml-2 text-red-400/70">
                        ({channels.filter((c) => c.DRM === 1).length} DRM-protected)
                      </span>
                    )}
                  </p>
                </>
              )}
            </div>
          )}
        </div>
      </div>

    </div>
  )
}

export function TunersPage() {
  const queryClient = useQueryClient()
  const [showAddModal, setShowAddModal] = useState(false)
  const [addedDevice, setAddedDevice] = useState<string | null>(null)

  const {
    data: tunersData,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['tuners'],
    queryFn: () => authFetch('/api/tuners') as Promise<{ devices: Tuner[]; count: number }>,
    refetchInterval: 30000,
  })

  const discoverTuners = useMutation({
    mutationFn: () => authFetch('/api/tuners/discover', { method: 'POST' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tuners'] })
    },
  })

  const addTuner = useMutation({
    mutationFn: (url: string) =>
      authFetch('/api/tuners', { method: 'POST', body: JSON.stringify({ url }) }),
    onSuccess: (data: { device?: { modelNumber?: string; deviceId?: string }; imported?: number }) => {
      queryClient.invalidateQueries({ queryKey: ['tuners'] })
      setShowAddModal(false)
      const name = data?.device?.modelNumber || data?.device?.deviceId || 'Tuner'
      setAddedDevice(`${name} added — ${data?.imported ?? 0} channels imported`)
      setTimeout(() => setAddedDevice(null), 6000)
    },
  })

  const removeTuner = useMutation({
    mutationFn: (deviceId: string) =>
      authFetch(`/api/tuners/${deviceId}`, { method: 'DELETE' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tuners'] })
    },
  })

  const tunerList = (tunersData?.devices || []).slice().sort((a, b) => {
    const aPriority = typeof a.priority === 'number' ? a.priority : 0
    const bPriority = typeof b.priority === 'number' ? b.priority : 0
    if (aPriority !== bPriority) return aPriority - bPriority
    return String(a.deviceId).localeCompare(String(b.deviceId))
  })
  const totalTuners = tunerList.reduce((sum, t) => sum + (t.tunerCount || 0), 0)
  const primaryTuner =
    tunerList.length > 0
      ? tunerList.reduce<Tuner | null>((best, t) => {
          if (!best) return t
          const bestPriority = typeof best.priority === 'number' ? best.priority : 0
          const currentPriority = typeof t.priority === 'number' ? t.priority : 0
          return currentPriority < bestPriority ? t : best
        }, null)
      : null
  const primaryLabel = primaryTuner?.modelNumber || primaryTuner?.deviceId

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <div className="flex items-center gap-3">
            <Radio className="h-6 w-6 text-indigo-400" />
            <h1 className="text-2xl font-bold text-white">Tuners</h1>
          </div>
          <p className="text-gray-400 mt-1">Manage HDHomeRun and network tuner devices</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => discoverTuners.mutate()}
            disabled={discoverTuners.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg"
          >
            {discoverTuners.isPending ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            Discover Tuners
          </button>
          <button
            onClick={() => setShowAddModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
          >
            <Plus className="h-4 w-4" />
            Add Manually
          </button>
        </div>
      </div>

      {/* Status banners */}
      {discoverTuners.isSuccess && (
        <div className="mb-6 flex items-center gap-2 p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
          <CheckCircle className="h-4 w-4 text-green-400 flex-shrink-0" />
          <span className="text-green-400 text-sm">
            Network discovery complete.{' '}
            {tunerList.length > 0
              ? `Found ${tunerList.length} tuner device${tunerList.length !== 1 ? 's' : ''}.`
              : 'No new devices found.'}
          </span>
        </div>
      )}
      {addedDevice && (
        <div className="mb-6 flex items-center gap-2 p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
          <CheckCircle className="h-4 w-4 text-green-400 flex-shrink-0" />
          <span className="text-green-400 text-sm">{addedDevice}</span>
        </div>
      )}
      {addTuner.isError && (
        <div className="mb-6 flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
          <AlertCircle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">
            Failed to add tuner. Check the IP address and make sure the device is reachable from the server.
          </span>
        </div>
      )}
      {discoverTuners.isError && (
        <div className="mb-6 flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
          <AlertCircle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">Discovery failed. Check that your network allows broadcast traffic.</span>
        </div>
      )}

      {/* Content */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-gray-800 rounded-xl p-6 text-center">
          <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">Failed to Load Tuners</h3>
          <p className="text-gray-400">Could not retrieve tuner information from the server.</p>
        </div>
      ) : tunerList.length === 0 ? (
        <div className="bg-gray-800 rounded-xl p-12 text-center">
          <Radio className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No Tuners Found</h3>
          <p className="text-gray-400 mb-6">
            Connect an HDHomeRun-compatible device to your network and click "Discover Tuners".
          </p>
          <div className="flex justify-center gap-3">
            <button
              onClick={() => discoverTuners.mutate()}
              disabled={discoverTuners.isPending}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {discoverTuners.isPending ? <Loader className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
              Discover Tuners
            </button>
            <button
              onClick={() => setShowAddModal(true)}
              className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              <Plus className="h-4 w-4" />
              Add Manually
            </button>
          </div>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Summary */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="bg-gray-800 rounded-xl p-4">
              <p className="text-2xl font-bold text-white">{tunerList.length}</p>
              <p className="text-sm text-gray-400">Device{tunerList.length !== 1 ? 's' : ''}</p>
              {tunerList.length > 1 && primaryLabel && (
                <div className="mt-2 inline-flex items-center gap-1.5 px-2 py-1 rounded-full bg-indigo-500/10 text-indigo-300 text-xs">
                  <Star className="h-3 w-3" />
                  <span className="font-medium">Primary:</span>
                  <span className="text-gray-200">{primaryLabel}</span>
                </div>
              )}
            </div>
            <div className="bg-gray-800 rounded-xl p-4">
              <p className="text-2xl font-bold text-white">{totalTuners}</p>
              <p className="text-sm text-gray-400">Total Tuners</p>
            </div>
            <div className="bg-gray-800 rounded-xl p-4">
              <p className="text-2xl font-bold text-green-400">
                {tunerList.filter((t) => t.firmwareVersion).length}
              </p>
              <p className="text-sm text-gray-400">Online</p>
            </div>
            <div className="bg-gray-800 rounded-xl p-4">
              <p className="text-2xl font-bold text-gray-400">
                {tunerList.filter((t) => !t.firmwareVersion).length}
              </p>
              <p className="text-sm text-gray-400">Offline</p>
            </div>
          </div>

          {/* Tuner Cards */}
          <div className="space-y-4">
            {tunerList.map((tuner) => (
              <TunerCard
                key={tuner.deviceId}
                tuner={tuner}
                onRemove={() => {
                  if (confirm(`Remove tuner ${tuner.modelNumber || tuner.deviceId}?`)) {
                    removeTuner.mutate(tuner.deviceId)
                  }
                }}
                />
            ))}
          </div>
        </div>
      )}

      {showAddModal && (
        <AddTunerModal
          onClose={() => setShowAddModal(false)}
          onAdd={(url) => addTuner.mutate(url)}
          isAdding={addTuner.isPending}
        />
      )}
    </div>
  )
}
