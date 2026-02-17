import { useState } from 'react'
import { Radio, Loader, AlertCircle, Plus, Trash2, RefreshCw, Download, Wifi, X, CheckCircle, Signal } from 'lucide-react'
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

interface Tuner {
  id: string
  name: string
  model: string
  ip: string
  firmware: string
  tunerCount: number
  url: string
  discovered?: boolean
}

interface TunerStatus {
  id: string
  tunerId: string
  channel?: string
  signalStrength: number
  signalQuality: number
  symbolQuality: number
  active: boolean
}

interface TunerChannel {
  number: string
  name: string
  enabled: boolean
  hd: boolean
  favorite: boolean
}

interface TunerStatusResponse {
  tuners: TunerStatus[]
}

interface TunerLineupResponse {
  channels: TunerChannel[]
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
    if (url.trim()) {
      onAdd(url.trim())
    }
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
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Tuner URL
            </label>
            <input
              type="text"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="http://192.168.1.100:5004"
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              Enter the base URL of your HDHomeRun device.
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
  onImportChannels,
  isImporting,
}: {
  tuner: Tuner
  onRemove: () => void
  onImportChannels: () => void
  isImporting: boolean
}) {
  const [showLineup, setShowLineup] = useState(false)

  const { data: statusData, isLoading: loadingStatus } = useQuery({
    queryKey: ['tunerStatus', tuner.id],
    queryFn: () => authFetch(`/api/tuners/${tuner.id}/status`) as Promise<TunerStatusResponse>,
    refetchInterval: 5000,
  })

  const { data: lineupData, isLoading: loadingLineup } = useQuery({
    queryKey: ['tunerLineup', tuner.id],
    queryFn: () => authFetch(`/api/tuners/${tuner.id}/lineup`) as Promise<TunerLineupResponse>,
    enabled: showLineup,
  })

  const tunerStatuses = statusData?.tuners || []
  const activeTuners = tunerStatuses.filter((t) => t.active).length

  return (
    <div className="bg-gray-800 rounded-xl overflow-hidden">
      <div className="p-6">
        <div className="flex items-start justify-between">
          <div className="flex items-start gap-4">
            <div className="p-3 bg-gray-700 rounded-lg">
              <Radio className="h-6 w-6 text-indigo-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-white">{tuner.name || tuner.model}</h3>
              <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-1 text-sm text-gray-400">
                <span className="flex items-center gap-1">
                  <Wifi className="h-3.5 w-3.5" />
                  {tuner.ip}
                </span>
                {tuner.model && <span>Model: {tuner.model}</span>}
                {tuner.firmware && <span>Firmware: {tuner.firmware}</span>}
                <span>
                  {tuner.tunerCount} tuner{tuner.tunerCount !== 1 ? 's' : ''}
                </span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2 flex-shrink-0">
            <button
              onClick={onImportChannels}
              disabled={isImporting}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white text-sm rounded-lg transition-colors"
            >
              {isImporting ? (
                <Loader className="h-3.5 w-3.5 animate-spin" />
              ) : (
                <Download className="h-3.5 w-3.5" />
              )}
              Import Channels
            </button>
            <button
              onClick={onRemove}
              className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg transition-colors"
              title="Remove tuner"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </div>

        {/* Tuner Status Indicators */}
        <div className="mt-4 pt-4 border-t border-gray-700">
          <div className="flex items-center justify-between mb-3">
            <h4 className="text-sm font-medium text-gray-400">
              Tuner Status
              {activeTuners > 0 && (
                <span className="ml-2 text-green-400">
                  ({activeTuners} active)
                </span>
              )}
            </h4>
            {loadingStatus && <Loader className="h-4 w-4 text-gray-500 animate-spin" />}
          </div>

          {tunerStatuses.length > 0 ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              {tunerStatuses.map((status, idx) => (
                <div
                  key={status.id || idx}
                  className={`p-3 rounded-lg ${
                    status.active
                      ? 'bg-green-500/10 border border-green-500/30'
                      : 'bg-gray-700/50 border border-gray-700'
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-medium text-gray-400">
                      Tuner {idx + 1}
                    </span>
                    <SignalBars strength={status.signalStrength} />
                  </div>
                  {status.active ? (
                    <div>
                      <p className="text-sm text-white font-medium">
                        {status.channel || 'Active'}
                      </p>
                      <div className="flex gap-2 mt-1 text-xs text-gray-400">
                        <span>Sig: {status.signalStrength}%</span>
                        <span>Qual: {status.signalQuality}%</span>
                      </div>
                    </div>
                  ) : (
                    <p className="text-sm text-gray-500">Idle</p>
                  )}
                </div>
              ))}
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

        {/* Channel Lineup Toggle */}
        <div className="mt-4 pt-4 border-t border-gray-700">
          <button
            onClick={() => setShowLineup(!showLineup)}
            className="text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
          >
            {showLineup ? 'Hide Channel Lineup' : 'Show Channel Lineup'}
          </button>

          {showLineup && (
            <div className="mt-3">
              {loadingLineup ? (
                <div className="flex items-center justify-center py-6">
                  <Loader className="h-6 w-6 text-indigo-500 animate-spin" />
                </div>
              ) : lineupData && lineupData.channels.length > 0 ? (
                <div className="overflow-x-auto max-h-96 overflow-y-auto">
                  <table className="w-full">
                    <thead className="sticky top-0 bg-gray-800">
                      <tr className="border-b border-gray-700">
                        <th className="text-left py-2 px-3 text-xs font-medium text-gray-400">Ch</th>
                        <th className="text-left py-2 px-3 text-xs font-medium text-gray-400">Name</th>
                        <th className="text-left py-2 px-3 text-xs font-medium text-gray-400">HD</th>
                        <th className="text-left py-2 px-3 text-xs font-medium text-gray-400">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {lineupData.channels.map((ch) => (
                        <tr
                          key={ch.number}
                          className="border-b border-gray-700/50 hover:bg-gray-700/30"
                        >
                          <td className="py-2 px-3 text-sm text-white font-mono">{ch.number}</td>
                          <td className="py-2 px-3 text-sm text-gray-300">{ch.name}</td>
                          <td className="py-2 px-3">
                            {ch.hd && (
                              <span className="px-1.5 py-0.5 text-xs bg-indigo-500/20 text-indigo-400 rounded">
                                HD
                              </span>
                            )}
                          </td>
                          <td className="py-2 px-3">
                            {ch.enabled ? (
                              <span className="flex items-center gap-1 text-xs text-green-400">
                                <CheckCircle className="h-3 w-3" />
                                Enabled
                              </span>
                            ) : (
                              <span className="text-xs text-gray-500">Disabled</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center py-6">
                  <p className="text-gray-500 text-sm">No channels in lineup</p>
                </div>
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
  const [importingTunerId, setImportingTunerId] = useState<string | null>(null)

  const {
    data: tuners,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['tuners'],
    queryFn: () => authFetch('/api/tuners') as Promise<{ tuners: Tuner[] }>,
  })

  const discoverTuners = useMutation({
    mutationFn: () => authFetch('/api/tuners/discover', { method: 'POST' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tuners'] })
    },
  })

  const addTuner = useMutation({
    mutationFn: (url: string) =>
      authFetch('/api/tuners', {
        method: 'POST',
        body: JSON.stringify({ url }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tuners'] })
      setShowAddModal(false)
    },
  })

  const removeTuner = useMutation({
    mutationFn: (id: string) =>
      authFetch(`/api/tuners/${id}`, { method: 'DELETE' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tuners'] })
    },
  })

  const importChannels = async (tunerId: string) => {
    setImportingTunerId(tunerId)
    try {
      await authFetch(`/api/tuners/${tunerId}/import`, { method: 'POST' })
      queryClient.invalidateQueries({ queryKey: ['tunerLineup', tunerId] })
    } catch (err) {
      console.error('Channel import failed:', err)
    } finally {
      setImportingTunerId(null)
    }
  }

  const tunerList = tuners?.tuners || []

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

      {/* Discovery success message */}
      {discoverTuners.isSuccess && (
        <div className="mb-6 flex items-center gap-2 p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
          <CheckCircle className="h-4 w-4 text-green-400" />
          <span className="text-green-400 text-sm">
            Network discovery complete. Found tuners have been added.
          </span>
        </div>
      )}
      {discoverTuners.isError && (
        <div className="mb-6 flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
          <AlertCircle className="h-4 w-4 text-red-400" />
          <span className="text-red-400 text-sm">
            Discovery failed. Check that your network allows broadcast traffic.
          </span>
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
            Connect an HDHomeRun device to your network and click "Discover Tuners" to find it.
          </p>
          <div className="flex justify-center gap-3">
            <button
              onClick={() => discoverTuners.mutate()}
              disabled={discoverTuners.isPending}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
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
      ) : (
        <div className="space-y-6">
          {/* Summary */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="bg-gray-800 rounded-xl p-4">
              <p className="text-2xl font-bold text-white">{tunerList.length}</p>
              <p className="text-sm text-gray-400">
                Tuner Device{tunerList.length !== 1 ? 's' : ''}
              </p>
            </div>
            <div className="bg-gray-800 rounded-xl p-4">
              <p className="text-2xl font-bold text-white">
                {tunerList.reduce((sum, t) => sum + (t.tunerCount || 0), 0)}
              </p>
              <p className="text-sm text-gray-400">Total Tuners</p>
            </div>
            <div className="bg-gray-800 rounded-xl p-4">
              <p className="text-2xl font-bold text-green-400">
                {tunerList.filter((t) => t.firmware).length}
              </p>
              <p className="text-sm text-gray-400">Online</p>
            </div>
            <div className="bg-gray-800 rounded-xl p-4">
              <p className="text-2xl font-bold text-gray-400">
                {tunerList.filter((t) => !t.firmware).length}
              </p>
              <p className="text-sm text-gray-400">Offline</p>
            </div>
          </div>

          {/* Tuner Cards */}
          <div className="space-y-4">
            {tunerList.map((tuner) => (
              <TunerCard
                key={tuner.id}
                tuner={tuner}
                onRemove={() => {
                  if (confirm(`Remove tuner ${tuner.name || tuner.model}?`)) {
                    removeTuner.mutate(tuner.id)
                  }
                }}
                onImportChannels={() => importChannels(tuner.id)}
                isImporting={importingTunerId === tuner.id}
              />
            ))}
          </div>
        </div>
      )}

      {/* Add Tuner Modal */}
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
