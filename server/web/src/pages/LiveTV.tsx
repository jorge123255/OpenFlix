import React, { useState, useRef } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Tv, Plus, Trash2, RefreshCw, FileText, Radio, Search, Edit, X, Check, Settings, MapPin, Zap, AlertCircle, Film, Monitor, Download, Clock, Archive, Layers, ArrowUp, ArrowDown, ChevronDown, ChevronRight, Wand2, Upload } from 'lucide-react'
import { EPGSourceCard } from '../components/EPGSourceCard'
import {
  useM3USources,
  useCreateM3USource,
  useDeleteM3USource,
  useRefreshM3USource,
  useEPGSources,
  useCreateEPGSource,
  useDeleteEPGSource,
  useRefreshEPG,
} from '../hooks/useLiveTV'
import { api, type Provider, type ProviderGroup } from '../api/client'

interface Channel {
  id: number
  sourceId: number
  channelId: string
  number: number
  name: string
  logo?: string
  group?: string
  streamUrl: string
  enabled: boolean
  epgSourceId?: number
  archiveEnabled?: boolean
  archiveDays?: number
}

function AddSourceModal({
  type,
  onClose,
}: {
  type: 'm3u' | 'epg'
  onClose: () => void
}) {
  const createM3U = useCreateM3USource()
  const createEPG = useCreateEPGSource()
  const [name, setName] = useState('')
  const [url, setUrl] = useState('')
  const [providerType, setProviderType] = useState<'xmltv' | 'gracenote'>('xmltv')
  const [gracenoteAffiliate, setGracenoteAffiliate] = useState('')
  const [gracenotePostalCode, setGracenotePostalCode] = useState('')
  const [gracenoteHours, setGracenoteHours] = useState(6)
  const [preview, setPreview] = useState<any>(null)
  const [isPreviewing, setIsPreviewing] = useState(false)
  const [previewError, setPreviewError] = useState('')

  // Provider discovery state
  const [providerGroups, setProviderGroups] = useState<ProviderGroup[]>([])
  const [selectedProvider, setSelectedProvider] = useState<Provider | null>(null)
  const [isDiscoveringProviders, setIsDiscoveringProviders] = useState(false)

  const handleDiscoverProviders = async () => {
    if (!gracenotePostalCode || gracenotePostalCode.length < 5) {
      setPreviewError('Please enter a valid 5-digit ZIP code')
      return
    }

    setIsDiscoveringProviders(true)
    setPreviewError('')
    setProviderGroups([])
    setSelectedProvider(null)
    setPreview(null)

    try {
      const response = await api.discoverProviders(gracenotePostalCode)
      setProviderGroups(response.grouped)

      // Auto-select first cable provider if available
      const cableGroup = response.grouped.find(g => g.type === 'Cable')
      if (cableGroup && cableGroup.providers.length > 0) {
        const firstCable = cableGroup.providers[0]
        setSelectedProvider(firstCable)
        setGracenoteAffiliate(firstCable.headendId)
        setName(firstCable.name + ' - ' + firstCable.location)
      }
    } catch (error: any) {
      setPreviewError(error.response?.data?.error || error.message || 'Failed to discover providers')
    } finally {
      setIsDiscoveringProviders(false)
    }
  }

  const handleProviderSelect = (provider: Provider) => {
    setSelectedProvider(provider)
    setGracenoteAffiliate(provider.headendId)
    setName(provider.name + ' - ' + provider.location)
    setPreview(null) // Clear any previous preview
  }

  const handlePreview = async () => {
    if (!gracenoteAffiliate) {
      setPreviewError('Please select a provider first')
      return
    }

    setIsPreviewing(true)
    setPreviewError('')

    try {
      const response = await api.previewEPGSource({
        postalCode: gracenotePostalCode,
        affiliate: gracenoteAffiliate,
        hours: gracenoteHours,
      })
      setPreview(response)
    } catch (error: any) {
      setPreviewError(error.message || 'Failed to preview EPG data')
      setPreview(null)
    } finally {
      setIsPreviewing(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (type === 'm3u') {
      await createM3U.mutateAsync({ name, url })
    } else {
      // EPG source with provider type selection
      if (providerType === 'xmltv') {
        await createEPG.mutateAsync({ name, providerType: 'xmltv', url })
      } else {
        // Validate Gracenote requirements
        if (!gracenoteAffiliate) {
          setPreviewError('Please select a TV provider')
          return
        }

        await createEPG.mutateAsync({
          name,
          providerType: 'gracenote',
          gracenoteAffiliate,
          gracenotePostalCode,
          gracenoteHours,
        })
      }
    }
    onClose()
  }

  const isPending = createM3U.isPending || createEPG.isPending

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
        <h2 className="text-lg font-semibold text-white mb-4">
          Add {type === 'm3u' ? 'M3U Playlist' : 'EPG Source'}
        </h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder={type === 'm3u' ? 'My IPTV' : 'TV Guide'}
              required
            />
          </div>

          {type === 'epg' && (
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-300 mb-2">Provider</label>
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setProviderType('xmltv')}
                  className={`flex-1 py-2 px-4 rounded-lg border transition-colors ${
                    providerType === 'xmltv'
                      ? 'bg-indigo-600 border-indigo-600 text-white'
                      : 'bg-gray-700 border-gray-600 text-gray-300 hover:border-gray-500'
                  }`}
                >
                  XMLTV
                </button>
                <button
                  type="button"
                  onClick={() => setProviderType('gracenote')}
                  className={`flex-1 py-2 px-4 rounded-lg border transition-colors ${
                    providerType === 'gracenote'
                      ? 'bg-indigo-600 border-indigo-600 text-white'
                      : 'bg-gray-700 border-gray-600 text-gray-300 hover:border-gray-500'
                  }`}
                >
                  Gracenote
                </button>
              </div>
            </div>
          )}

          {type === 'm3u' && (
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-300 mb-2">URL</label>
              <input
                type="url"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="http://example.com/playlist.m3u"
                required
              />
            </div>
          )}

          {type === 'epg' && providerType === 'xmltv' && (
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-300 mb-2">XMLTV URL</label>
              <input
                type="url"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="http://example.com/guide.xml"
                required
              />
            </div>
          )}

          {type === 'epg' && providerType === 'gracenote' && (
            <>
              {/* Step 1: Postal Code - Enter ZIP to find providers */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  ZIP Code <span className="text-red-400">*</span>
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={gracenotePostalCode}
                    onChange={(e) => setGracenotePostalCode(e.target.value.replace(/\D/g, '').slice(0, 5))}
                    className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                    placeholder="10001"
                    maxLength={5}
                  />
                  <button
                    type="button"
                    onClick={handleDiscoverProviders}
                    disabled={isDiscoveringProviders || gracenotePostalCode.length < 5}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-lg flex items-center gap-2"
                  >
                    {isDiscoveringProviders ? (
                      <RefreshCw className="h-4 w-4 animate-spin" />
                    ) : (
                      <MapPin className="h-4 w-4" />
                    )}
                    Find
                  </button>
                </div>
                <p className="text-xs text-gray-500 mt-1">
                  Enter your ZIP code to find available TV providers
                </p>
              </div>

              {previewError && (
                <p className="text-sm text-red-400 mb-4">{previewError}</p>
              )}

              {/* Step 2: Provider Selection - Show discovered providers */}
              {providerGroups.length > 0 && (
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Select Your TV Provider
                  </label>
                  <div className="space-y-3">
                    {providerGroups.map((group) => (
                      <div key={group.type}>
                        <p className="text-xs text-gray-500 mb-2 uppercase tracking-wide">
                          {group.type === 'Cable' && '📺 Cable'}
                          {group.type === 'Satellite' && '📡 Satellite'}
                          {group.type === 'Antenna' && '📻 Over-the-Air'}
                        </p>
                        <div className="space-y-1">
                          {group.providers.map((provider) => (
                            <button
                              key={provider.headendId}
                              type="button"
                              onClick={() => handleProviderSelect(provider)}
                              className={`w-full text-left px-4 py-3 rounded-lg border transition-colors ${
                                selectedProvider?.headendId === provider.headendId
                                  ? 'bg-indigo-600/20 border-indigo-500 text-white'
                                  : 'bg-gray-700/50 border-gray-600 text-gray-300 hover:border-gray-500 hover:bg-gray-700'
                              }`}
                            >
                              <div className="flex items-center justify-between">
                                <div>
                                  <span className="font-medium">{provider.name}</span>
                                  {provider.location && (
                                    <span className="text-gray-400 ml-2 text-sm">• {provider.location}</span>
                                  )}
                                </div>
                                {selectedProvider?.headendId === provider.headendId && (
                                  <Check className="h-4 w-4 text-indigo-400" />
                                )}
                              </div>
                            </button>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Step 3: Preview Channels (optional) */}
              {selectedProvider && (
                <div className="mb-4">
                  <button
                    type="button"
                    onClick={handlePreview}
                    disabled={isPreviewing}
                    className="w-full py-2 px-4 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-lg flex items-center justify-center gap-2"
                  >
                    {isPreviewing ? (
                      <>
                        <RefreshCw className="h-4 w-4 animate-spin" />
                        Loading Preview...
                      </>
                    ) : (
                      <>
                        <Search className="h-4 w-4" />
                        Preview Channels (Optional)
                      </>
                    )}
                  </button>
                </div>
              )}

              {/* Preview Results */}
              {preview && (
                <div className="mb-4 p-4 bg-gray-700/50 rounded-lg border border-green-500/50">
                  <div className="flex items-center gap-2 mb-3">
                    <Check className="h-5 w-5 text-green-400" />
                    <h3 className="text-sm font-semibold text-white">
                      Found {preview.totalChannels} channels
                    </h3>
                  </div>
                  <div className="text-xs text-gray-400 mb-3">
                    <p>Programs: {preview.totalPrograms}</p>
                  </div>
                  <div className="max-h-32 overflow-y-auto space-y-1">
                    <p className="text-xs text-gray-500 mb-2">Sample channels:</p>
                    {preview.previewChannels?.slice(0, 5).map((ch: any, idx: number) => (
                      <div key={idx} className="flex items-center gap-2 text-xs text-gray-300 py-1">
                        <span className="font-medium text-white">{ch.callSign || ch.channelId}</span>
                        {ch.channelNo && <span className="text-gray-500">Ch {ch.channelNo}</span>}
                      </div>
                    ))}
                    {preview.totalChannels > 5 && (
                      <p className="text-xs text-gray-500 mt-2">
                        ... and {preview.totalChannels - 5} more channels
                      </p>
                    )}
                  </div>
                </div>
              )}

              {/* Advanced Settings */}
              {selectedProvider && (
                <div className="mb-4 pt-4 border-t border-gray-700">
                  <details className="group">
                    <summary className="text-sm font-medium text-gray-400 cursor-pointer hover:text-white flex items-center gap-2">
                      <Settings className="h-4 w-4" />
                      Advanced Settings
                    </summary>
                    <div className="mt-3 space-y-3">
                      <div>
                        <label className="block text-xs font-medium text-gray-400 mb-1">
                          Provider ID
                        </label>
                        <input
                          type="text"
                          value={gracenoteAffiliate}
                          onChange={(e) => setGracenoteAffiliate(e.target.value)}
                          className="w-full px-3 py-1.5 bg-gray-700 border border-gray-600 rounded text-white text-sm font-mono"
                          readOnly
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-gray-400 mb-1">
                          Hours of Guide Data
                        </label>
                        <input
                          type="number"
                          value={gracenoteHours}
                          onChange={(e) => setGracenoteHours(parseInt(e.target.value) || 6)}
                          min="1"
                          max="12"
                          className="w-full px-3 py-1.5 bg-gray-700 border border-gray-600 rounded text-white text-sm"
                        />
                        <p className="text-xs text-gray-500 mt-1">1-12 hours (default: 6). API limits longer requests.</p>
                      </div>
                    </div>
                  </details>
                </div>
              )}
            </>
          )}

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
              disabled={isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {isPending ? 'Adding...' : 'Add'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function EditChannelModal({
  channel,
  onClose,
  epgSources,
}: {
  channel: Channel
  onClose: () => void
  epgSources: any[]
}) {
  const queryClient = useQueryClient()
  const [name, setName] = useState(channel.name)
  const [number, setNumber] = useState(channel.number)
  const [logo, setLogo] = useState(channel.logo || '')
  const [group, setGroup] = useState(channel.group || '')
  const [epgSourceId, setEpgSourceId] = useState<number | null>(channel.epgSourceId || null)
  const [epgChannelId, setEpgChannelId] = useState(channel.channelId || '')

  // Fetch available EPG channels when EPG source is selected
  const { data: epgChannels } = useQuery({
    queryKey: ['epgChannels', epgSourceId],
    queryFn: () => api.getEPGChannels(epgSourceId || undefined),
    enabled: !!epgSourceId,
  })

  const updateChannel = useMutation({
    mutationFn: async (data: Partial<Channel>) => {
      const response = await fetch(`/livetv/channels/${channel.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || '',
        },
        body: JSON.stringify(data),
      })
      if (!response.ok) throw new Error('Failed to update channel')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channels'] })
      onClose()
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    updateChannel.mutate({
      name,
      number,
      logo,
      group,
      epgSourceId: epgSourceId ?? undefined,
      channelId: epgChannelId || undefined,
    })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">Edit Channel</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Number</label>
            <input
              type="number"
              value={number}
              onChange={(e) => setNumber(parseInt(e.target.value) || 0)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Logo URL</label>
            <input
              type="text"
              value={logo}
              onChange={(e) => setLogo(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="https://..."
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Group</label>
            <input
              type="text"
              value={group}
              onChange={(e) => setGroup(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="Sports, News, etc."
            />
          </div>

          {/* EPG Mapping Section */}
          <div className="mb-4 pt-4 border-t border-gray-700">
            <h3 className="text-sm font-semibold text-white mb-3">EPG Mapping</h3>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-300 mb-2">EPG Source</label>
              <select
                value={epgSourceId || ''}
                onChange={(e) => {
                  const value = e.target.value ? parseInt(e.target.value) : null
                  setEpgSourceId(value)
                  setEpgChannelId('')
                }}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              >
                <option value="">None</option>
                {epgSources.map((source) => (
                  <option key={source.id} value={source.id}>
                    {source.name}
                  </option>
                ))}
              </select>
              <p className="text-xs text-gray-500 mt-1">
                Select an EPG source to match program guide data
              </p>
            </div>

            {epgSourceId && (
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">EPG Channel</label>
                <select
                  value={epgChannelId}
                  onChange={(e) => setEpgChannelId(e.target.value)}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                >
                  <option value="">Select EPG Channel...</option>
                  {epgChannels?.map((ch) => (
                    <option key={ch.channelId} value={ch.channelId}>
                      {ch.channelId} - {ch.sampleTitle}
                    </option>
                  ))}
                </select>
                <p className="text-xs text-gray-500 mt-1">
                  Match this channel to an EPG channel ID
                </p>
              </div>
            )}
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
              disabled={updateChannel.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {updateChannel.isPending ? 'Saving...' : 'Save'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function MapChannelNumbersModal({
  onClose,
}: {
  onClose: () => void
}) {
  const queryClient = useQueryClient()
  const [m3uUrl, setM3uUrl] = useState('')
  const [m3uContent, setM3uContent] = useState('')
  const [inputMode, setInputMode] = useState<'url' | 'file' | 'paste'>('file')
  const [fileName, setFileName] = useState('')
  const [preview, setPreview] = useState<any>(null)
  const [isPreviewLoading, setIsPreviewLoading] = useState(false)
  const [isApplying, setIsApplying] = useState(false)
  const [error, setError] = useState('')
  const fileInputRef = useRef<HTMLInputElement>(null)
  // Manual mappings: { m3uName: channelId }
  const [manualMappings, setManualMappings] = useState<Record<string, number>>({})

  // Fetch existing channels for manual matching dropdown
  const { data: existingChannels } = useQuery({
    queryKey: ['channels'],
    queryFn: async () => {
      const response = await fetch('/livetv/channels', {
        headers: { 'X-Plex-Token': api.getToken() || '' },
      })
      const data = await response.json()
      return (data.channels || []) as Channel[]
    },
  })

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setFileName(file.name)
      const reader = new FileReader()
      reader.onload = (event) => {
        const content = event.target?.result as string
        setM3uContent(content)
      }
      reader.onerror = () => {
        setError('Failed to read file')
      }
      reader.readAsText(file)
    }
  }

  const handlePreview = async () => {
    setIsPreviewLoading(true)
    setError('')
    setPreview(null)

    try {
      const data = inputMode === 'url' ? { url: m3uUrl, preview: true } : { content: m3uContent, preview: true }
      const result = await api.mapChannelNumbers(data)
      setPreview(result)
    } catch (err: any) {
      setError(err.response?.data?.error || err.message || 'Failed to parse M3U')
    } finally {
      setIsPreviewLoading(false)
    }
  }

  const handleApply = async () => {
    setIsApplying(true)
    setError('')

    try {
      // Build manual mappings array from the unmatched results
      const manualMappingsArray = Object.entries(manualMappings).map(([m3uName, channelId]) => {
        const unmatched = unmatchedResults.find((r: any) => r.m3uName === m3uName)
        return {
          m3uName,
          m3uNumber: unmatched?.m3uNumber || 0,
          channelId,
        }
      })

      const data = inputMode === 'url'
        ? { url: m3uUrl, preview: false, manualMappings: manualMappingsArray }
        : { content: m3uContent, preview: false, manualMappings: manualMappingsArray }
      const result = await api.mapChannelNumbers(data)
      setPreview(result)
      setManualMappings({}) // Clear manual mappings after apply
      queryClient.invalidateQueries({ queryKey: ['channels'] })
    } catch (err: any) {
      setError(err.response?.data?.error || err.message || 'Failed to apply mappings')
    } finally {
      setIsApplying(false)
    }
  }

  const matchedResults = preview?.results?.filter((r: any) => r.matchType !== 'none') || []
  const unmatchedResults = preview?.results?.filter((r: any) => r.matchType === 'none') || []

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">Import Channel Numbers from M3U</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        <p className="text-gray-400 text-sm mb-4">
          Import channel numbers from an M3U file to apply to your existing channels.
          Only channel numbers will be updated - stream URLs will not be modified.
        </p>

        {/* Input Mode Tabs */}
        <div className="flex gap-2 mb-4">
          <button
            onClick={() => setInputMode('file')}
            className={`px-4 py-2 rounded-lg text-sm ${
              inputMode === 'file'
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
          >
            Upload File
          </button>
          <button
            onClick={() => setInputMode('url')}
            className={`px-4 py-2 rounded-lg text-sm ${
              inputMode === 'url'
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
          >
            URL
          </button>
          <button
            onClick={() => setInputMode('paste')}
            className={`px-4 py-2 rounded-lg text-sm ${
              inputMode === 'paste'
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
          >
            Paste Content
          </button>
        </div>

        {/* Input Field */}
        {inputMode === 'file' ? (
          <div className="mb-4">
            <input
              ref={fileInputRef}
              type="file"
              accept=".m3u,.m3u8,text/plain"
              onChange={handleFileSelect}
              className="hidden"
            />
            <div
              onClick={() => fileInputRef.current?.click()}
              className="w-full p-6 bg-gray-700 border-2 border-dashed border-gray-600 rounded-lg text-center cursor-pointer hover:border-indigo-500 hover:bg-gray-700/70 transition-colors"
            >
              {fileName ? (
                <div>
                  <FileText className="h-8 w-8 text-indigo-400 mx-auto mb-2" />
                  <p className="text-white font-medium">{fileName}</p>
                  <p className="text-gray-400 text-sm mt-1">Click to choose a different file</p>
                </div>
              ) : (
                <div>
                  <Upload className="h-8 w-8 text-gray-500 mx-auto mb-2" />
                  <p className="text-gray-300">Click to select an M3U file</p>
                  <p className="text-gray-500 text-sm mt-1">.m3u or .m3u8</p>
                </div>
              )}
            </div>
          </div>
        ) : inputMode === 'url' ? (
          <div className="mb-4">
            <input
              type="url"
              value={m3uUrl}
              onChange={(e) => setM3uUrl(e.target.value)}
              placeholder="https://example.com/channels.m3u"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            />
          </div>
        ) : (
          <div className="mb-4">
            <textarea
              value={m3uContent}
              onChange={(e) => setM3uContent(e.target.value)}
              placeholder="#EXTM3U&#10;#EXTINF:-1 tvg-chno=&quot;5&quot;,Channel Name&#10;http://..."
              className="w-full h-32 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white font-mono text-sm"
            />
          </div>
        )}

        {error && (
          <div className="mb-4 p-3 bg-red-900/50 border border-red-500 rounded-lg text-red-300 text-sm">
            {error}
          </div>
        )}

        {/* Preview Button */}
        {!preview && (
          <button
            onClick={handlePreview}
            disabled={isPreviewLoading || (!m3uUrl && !m3uContent)}
            className="w-full mb-4 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-lg flex items-center justify-center gap-2"
          >
            {isPreviewLoading ? (
              <>
                <RefreshCw className="h-4 w-4 animate-spin" />
                Parsing...
              </>
            ) : (
              <>
                <Search className="h-4 w-4" />
                Preview Matches
              </>
            )}
          </button>
        )}

        {/* Preview Results */}
        {preview && (
          <div className="flex-1 overflow-hidden flex flex-col">
            {/* Summary */}
            <div className="flex gap-4 mb-4">
              <div className="flex-1 p-3 bg-green-900/30 border border-green-500/50 rounded-lg">
                <div className="text-green-400 text-lg font-semibold">{preview.matched}</div>
                <div className="text-green-300 text-xs">Matched</div>
              </div>
              <div className="flex-1 p-3 bg-yellow-900/30 border border-yellow-500/50 rounded-lg">
                <div className="text-yellow-400 text-lg font-semibold">{preview.unmatched}</div>
                <div className="text-yellow-300 text-xs">Unmatched</div>
              </div>
            </div>

            {/* Results List */}
            <div className="flex-1 overflow-y-auto mb-4">
              {matchedResults.length > 0 && (
                <div className="mb-4">
                  <h3 className="text-sm font-medium text-white mb-2">Matched Channels</h3>
                  <div className="space-y-1">
                    {matchedResults.slice(0, 50).map((r: any, idx: number) => (
                      <div key={idx} className="flex items-center justify-between text-sm bg-gray-700/50 p-2 rounded">
                        <div className="flex items-center gap-2">
                          <span className="text-indigo-400 font-mono w-12">{r.m3uNumber}</span>
                          <span className="text-white">{r.m3uName}</span>
                        </div>
                        <div className="flex items-center gap-2 text-gray-400">
                          <span className="text-xs bg-gray-600 px-1.5 py-0.5 rounded">{r.matchType}</span>
                          <span>→ {r.matchedName}</span>
                          {r.applied && <Check className="h-3 w-3 text-green-400" />}
                        </div>
                      </div>
                    ))}
                    {matchedResults.length > 50 && (
                      <div className="text-xs text-gray-500 text-center py-2">
                        ... and {matchedResults.length - 50} more
                      </div>
                    )}
                  </div>
                </div>
              )}

              {unmatchedResults.length > 0 && (
                <div>
                  <h3 className="text-sm font-medium text-yellow-400 mb-2">
                    Unmatched ({unmatchedResults.length})
                    {Object.keys(manualMappings).length > 0 && (
                      <span className="text-green-400 ml-2">
                        - {Object.keys(manualMappings).length} manually matched
                      </span>
                    )}
                  </h3>
                  <div className="space-y-1">
                    {unmatchedResults.map((r: any, idx: number) => (
                      <div key={idx} className="flex items-center gap-2 text-sm p-2 bg-gray-700/30 rounded">
                        <span className="text-indigo-400 font-mono w-12 flex-shrink-0">{r.m3uNumber}</span>
                        <span className="text-white flex-shrink-0 min-w-[120px]">{r.m3uName}</span>
                        <span className="text-gray-500 mx-2">→</span>
                        <select
                          value={manualMappings[r.m3uName] || ''}
                          onChange={(e) => {
                            const value = e.target.value
                            setManualMappings(prev => {
                              if (value === '') {
                                const { [r.m3uName]: _, ...rest } = prev
                                return rest
                              }
                              return { ...prev, [r.m3uName]: parseInt(value) }
                            })
                          }}
                          className={`flex-1 px-2 py-1 bg-gray-700 border rounded text-sm ${
                            manualMappings[r.m3uName]
                              ? 'border-green-500 text-green-300'
                              : 'border-gray-600 text-gray-400'
                          }`}
                        >
                          <option value="">Select channel...</option>
                          {existingChannels?.map((ch: Channel) => (
                            <option key={ch.id} value={ch.id}>
                              {ch.number} - {ch.name}
                            </option>
                          ))}
                        </select>
                        {manualMappings[r.m3uName] && (
                          <Check className="h-4 w-4 text-green-400 flex-shrink-0" />
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3">
              <button
                onClick={() => setPreview(null)}
                className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
              >
                Back
              </button>
              <button
                onClick={handleApply}
                disabled={isApplying || (preview.matched === 0 && Object.keys(manualMappings).length === 0)}
                className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-lg flex items-center justify-center gap-2"
              >
                {isApplying ? (
                  <>
                    <RefreshCw className="h-4 w-4 animate-spin" />
                    Applying...
                  </>
                ) : (
                  <>
                    <Check className="h-4 w-4" />
                    Apply {preview.matched + Object.keys(manualMappings).length} Mappings
                  </>
                )}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

function EditM3USourceModal({
  source,
  onClose,
}: {
  source: { id: number; name: string; url: string }
  onClose: () => void
}) {
  const queryClient = useQueryClient()
  const [name, setName] = useState(source.name)
  const [url, setUrl] = useState(source.url)
  const [error, setError] = useState('')

  const updateSource = useMutation({
    mutationFn: async (data: { name: string; url: string }) => {
      return api.updateM3USource(source.id, data)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['m3uSources'] })
      queryClient.invalidateQueries({ queryKey: ['channels'] })
      onClose()
    },
    onError: (error: any) => {
      setError(error.response?.data?.error || error.message || 'Failed to update source')
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    updateSource.mutate({ name, url })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">Edit M3U Source</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">URL</label>
            <input
              type="url"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="http://example.com/playlist.m3u"
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              Update the URL if your provider's IP address changed
            </p>
          </div>
          {error && (
            <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg">
              <p className="text-sm text-red-300 flex items-center gap-2">
                <AlertCircle className="h-4 w-4" />
                {error}
              </p>
            </div>
          )}
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
              disabled={updateSource.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {updateSource.isPending ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function EditXtreamSourceModal({
  source,
  onClose,
}: {
  source: {
    id: number
    name: string
    serverUrl: string
    username: string
    importVod?: boolean
    importSeries?: boolean
    vodLibraryId?: number
    seriesLibraryId?: number
  }
  onClose: () => void
}) {
  const queryClient = useQueryClient()
  const [name, setName] = useState(source.name)
  const [serverUrl, setServerUrl] = useState(source.serverUrl)
  const [username, setUsername] = useState(source.username)
  const [password, setPassword] = useState('')
  const [importVod, setImportVod] = useState(source.importVod || false)
  const [importSeries, setImportSeries] = useState(source.importSeries || false)
  const [vodLibraryId, setVodLibraryId] = useState<number | null>(source.vodLibraryId || null)
  const [seriesLibraryId, setSeriesLibraryId] = useState<number | null>(source.seriesLibraryId || null)
  const [error, setError] = useState('')

  const { data: libraries } = useQuery({
    queryKey: ['libraries'],
    queryFn: () => api.getLibraries(),
  })

  const movieLibraries = libraries?.filter(l => l.type === 'movie') || []
  const showLibraries = libraries?.filter(l => l.type === 'show') || []

  const updateSource = useMutation({
    mutationFn: async (data: any) => {
      return api.updateXtreamSource(source.id, data)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['xtreamSources'] })
      queryClient.invalidateQueries({ queryKey: ['channels'] })
      onClose()
    },
    onError: (error: any) => {
      setError(error.response?.data?.error || error.message || 'Failed to update source')
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    const data: any = {
      name,
      serverUrl,
      username,
      importVod,
      importSeries,
      vodLibraryId: vodLibraryId ?? undefined,
      seriesLibraryId: seriesLibraryId ?? undefined,
    }
    // Only include password if it was changed
    if (password) {
      data.password = password
    }
    updateSource.mutate(data)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white flex items-center gap-2">
            <Zap className="h-5 w-5 text-yellow-400" />
            Edit Xtream Source
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Server URL</label>
            <input
              type="url"
              value={serverUrl}
              onChange={(e) => setServerUrl(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="http://server.com:8080"
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              Update the URL if your provider's IP address changed
            </p>
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Username</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Password <span className="text-gray-500">(leave blank to keep current)</span>
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="••••••••"
            />
          </div>

          {/* VOD/Series Import Settings */}
          <div className="mb-6 p-4 bg-gray-700/50 rounded-lg border border-gray-600">
            <h3 className="text-sm font-semibold text-white mb-3">Content Import</h3>
            <div className="mb-4">
              <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer">
                <input
                  type="checkbox"
                  checked={importVod}
                  onChange={(e) => setImportVod(e.target.checked)}
                  className="rounded bg-gray-600 border-gray-500"
                />
                Import VOD Movies
              </label>
              {importVod && (
                <div className="mt-2 ml-6">
                  <select
                    value={vodLibraryId || ''}
                    onChange={(e) => setVodLibraryId(e.target.value ? parseInt(e.target.value) : null)}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  >
                    <option value="">Select Movie Library...</option>
                    {movieLibraries.map(lib => (
                      <option key={lib.id} value={lib.id}>{lib.title}</option>
                    ))}
                  </select>
                </div>
              )}
            </div>
            <div>
              <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer">
                <input
                  type="checkbox"
                  checked={importSeries}
                  onChange={(e) => setImportSeries(e.target.checked)}
                  className="rounded bg-gray-600 border-gray-500"
                />
                Import TV Series
              </label>
              {importSeries && (
                <div className="mt-2 ml-6">
                  <select
                    value={seriesLibraryId || ''}
                    onChange={(e) => setSeriesLibraryId(e.target.value ? parseInt(e.target.value) : null)}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  >
                    <option value="">Select TV Library...</option>
                    {showLibraries.map(lib => (
                      <option key={lib.id} value={lib.id}>{lib.title}</option>
                    ))}
                  </select>
                </div>
              )}
            </div>
          </div>

          {error && (
            <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg">
              <p className="text-sm text-red-300 flex items-center gap-2">
                <AlertCircle className="h-4 w-4" />
                {error}
              </p>
            </div>
          )}

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
              disabled={updateSource.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {updateSource.isPending ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function EditEPGSourceModal({
  source,
  onClose,
}: {
  source: {
    id: number
    name: string
    providerType: string
    url?: string
    gracenoteAffiliate?: string
    gracenotePostalCode?: string
    gracenoteHours?: number
  }
  onClose: () => void
}) {
  const queryClient = useQueryClient()
  const [name, setName] = useState(source.name)
  const [url, setUrl] = useState(source.url || '')
  const [gracenoteAffiliate, setGracenoteAffiliate] = useState(source.gracenoteAffiliate || '')
  const [gracenotePostalCode, setGracenotePostalCode] = useState(source.gracenotePostalCode || '')
  const [gracenoteHours, setGracenoteHours] = useState(source.gracenoteHours || 6)
  const [error, setError] = useState('')

  const updateSource = useMutation({
    mutationFn: async (data: any) => {
      return api.updateEPGSource(source.id, data)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['epgSources'] })
      onClose()
    },
    onError: (error: any) => {
      setError(error.response?.data?.error || error.message || 'Failed to update source')
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    if (source.providerType === 'xmltv') {
      updateSource.mutate({ name, url })
    } else {
      updateSource.mutate({
        name,
        gracenoteAffiliate,
        gracenotePostalCode,
        gracenoteHours,
      })
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">Edit EPG Source</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>

          {source.providerType === 'xmltv' ? (
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-300 mb-2">XMLTV URL</label>
              <input
                type="url"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="http://example.com/guide.xml"
                required
              />
              <p className="text-xs text-gray-500 mt-1">
                Update the URL if your EPG provider's address changed
              </p>
            </div>
          ) : (
            <>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">ZIP Code</label>
                <input
                  type="text"
                  value={gracenotePostalCode}
                  onChange={(e) => setGracenotePostalCode(e.target.value.replace(/\D/g, '').slice(0, 5))}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                  placeholder="10001"
                  maxLength={5}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">Provider ID (Headend)</label>
                <input
                  type="text"
                  value={gracenoteAffiliate}
                  onChange={(e) => setGracenoteAffiliate(e.target.value)}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white font-mono"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Change if you switched TV providers
                </p>
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">Hours of Guide Data</label>
                <input
                  type="number"
                  value={gracenoteHours}
                  onChange={(e) => setGracenoteHours(parseInt(e.target.value) || 6)}
                  min="1"
                  max="12"
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                />
              </div>
            </>
          )}

          {error && (
            <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg">
              <p className="text-sm text-red-300 flex items-center gap-2">
                <AlertCircle className="h-4 w-4" />
                {error}
              </p>
            </div>
          )}

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
              disabled={updateSource.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {updateSource.isPending ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function AddXtreamSourceModal({ onClose }: { onClose: () => void }) {
  const queryClient = useQueryClient()
  const [name, setName] = useState('')
  const [serverUrl, setServerUrl] = useState('')
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [m3uUrl, setM3uUrl] = useState('')
  const [useM3uParse, setUseM3uParse] = useState(false)
  const [parseResult, setParseResult] = useState<any>(null)
  const [parseError, setParseError] = useState('')
  const [isParsing, setIsParsing] = useState(false)

  // VOD/Series import settings
  const [importVod, setImportVod] = useState(false)
  const [importSeries, setImportSeries] = useState(false)
  const [vodLibraryId, setVodLibraryId] = useState<number | null>(null)
  const [seriesLibraryId, setSeriesLibraryId] = useState<number | null>(null)

  // Fetch libraries for dropdown
  const { data: libraries } = useQuery({
    queryKey: ['libraries'],
    queryFn: () => api.getLibraries(),
  })

  const movieLibraries = libraries?.filter(l => l.type === 'movie') || []
  const showLibraries = libraries?.filter(l => l.type === 'show') || []

  const [submitError, setSubmitError] = useState('')

  const createXtream = useMutation({
    mutationFn: async (data: {
      name: string
      serverUrl: string
      username: string
      password: string
      importVod?: boolean
      importSeries?: boolean
      vodLibraryId?: number
      seriesLibraryId?: number
    }) => {
      return api.createXtreamSource(data)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['xtreamSources'] })
      onClose()
    },
    onError: (error: any) => {
      setSubmitError(error.response?.data?.error || error.message || 'Failed to add source')
    },
  })

  const handleParseM3U = async () => {
    if (!m3uUrl) return
    setIsParsing(true)
    setParseError('')
    setParseResult(null)

    try {
      const result = await api.parseXtreamFromM3U(m3uUrl)
      if (result.success) {
        setParseResult(result)
        setServerUrl(result.serverUrl || '')
        setUsername(result.username || '')
        setPassword(result.password || '')
        setName(result.name || '')
      } else {
        setParseError(result.error || 'Failed to parse URL')
        // Still try to use extracted info if available
        if (result.serverUrl) setServerUrl(result.serverUrl)
        if (result.username) setUsername(result.username)
      }
    } catch (error: any) {
      setParseError(error.message || 'Failed to parse URL')
    } finally {
      setIsParsing(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitError('')
    await createXtream.mutateAsync({
      name,
      serverUrl,
      username,
      password,
      importVod,
      importSeries,
      vodLibraryId: vodLibraryId ?? undefined,
      seriesLibraryId: seriesLibraryId ?? undefined,
    })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white flex items-center gap-2">
            <Zap className="h-5 w-5 text-yellow-400" />
            Add Xtream Source
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Auto-detect from M3U URL */}
        <div className="mb-6 p-4 bg-gray-700/50 rounded-lg border border-gray-600">
          <label className="flex items-center gap-2 text-sm font-medium text-gray-300 mb-2 cursor-pointer">
            <input
              type="checkbox"
              checked={useM3uParse}
              onChange={(e) => setUseM3uParse(e.target.checked)}
              className="rounded"
            />
            Auto-detect from M3U URL
          </label>
          {useM3uParse && (
            <div className="mt-3">
              <div className="flex gap-2">
                <input
                  type="url"
                  value={m3uUrl}
                  onChange={(e) => setM3uUrl(e.target.value)}
                  className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  placeholder="http://server:port/get.php?username=...&password=..."
                />
                <button
                  type="button"
                  onClick={handleParseM3U}
                  disabled={isParsing || !m3uUrl}
                  className="px-3 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-600 text-white rounded-lg text-sm"
                >
                  {isParsing ? <RefreshCw className="h-4 w-4 animate-spin" /> : 'Parse'}
                </button>
              </div>
              {parseError && (
                <p className="text-sm text-yellow-400 mt-2 flex items-center gap-1">
                  <AlertCircle className="h-4 w-4" />
                  {parseError}
                </p>
              )}
              {parseResult && parseResult.success && (
                <div className="mt-3 p-2 bg-green-500/20 border border-green-500/50 rounded text-sm text-green-300">
                  <Check className="inline h-4 w-4 mr-1" />
                  Credentials detected! Account status: {parseResult.userInfo?.status}
                </div>
              )}
            </div>
          )}
        </div>

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="My IPTV Provider"
              required
            />
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Server URL</label>
            <input
              type="url"
              value={serverUrl}
              onChange={(e) => setServerUrl(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="http://server.com:8080"
              required
            />
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Username</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>

          {/* VOD/Series Import Settings */}
          <div className="mb-6 p-4 bg-gray-700/50 rounded-lg border border-gray-600">
            <h3 className="text-sm font-semibold text-white mb-3">Content Import</h3>
            <p className="text-xs text-gray-400 mb-4">
              Import VOD movies and series from this source into your media libraries
            </p>

            {/* Import VOD */}
            <div className="mb-4">
              <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer">
                <input
                  type="checkbox"
                  checked={importVod}
                  onChange={(e) => setImportVod(e.target.checked)}
                  className="rounded bg-gray-600 border-gray-500"
                />
                Import VOD Movies
              </label>
              {importVod && (
                <div className="mt-2 ml-6">
                  <select
                    value={vodLibraryId || ''}
                    onChange={(e) => setVodLibraryId(e.target.value ? parseInt(e.target.value) : null)}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                    required={importVod}
                  >
                    <option value="">Select Movie Library...</option>
                    {movieLibraries.map(lib => (
                      <option key={lib.id} value={lib.id}>{lib.title}</option>
                    ))}
                  </select>
                  {movieLibraries.length === 0 && (
                    <p className="text-xs text-yellow-400 mt-1">No movie libraries found. Create one first.</p>
                  )}
                </div>
              )}
            </div>

            {/* Import Series */}
            <div>
              <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer">
                <input
                  type="checkbox"
                  checked={importSeries}
                  onChange={(e) => setImportSeries(e.target.checked)}
                  className="rounded bg-gray-600 border-gray-500"
                />
                Import TV Series
              </label>
              {importSeries && (
                <div className="mt-2 ml-6">
                  <select
                    value={seriesLibraryId || ''}
                    onChange={(e) => setSeriesLibraryId(e.target.value ? parseInt(e.target.value) : null)}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                    required={importSeries}
                  >
                    <option value="">Select TV Library...</option>
                    {showLibraries.map(lib => (
                      <option key={lib.id} value={lib.id}>{lib.title}</option>
                    ))}
                  </select>
                  {showLibraries.length === 0 && (
                    <p className="text-xs text-yellow-400 mt-1">No TV show libraries found. Create one first.</p>
                  )}
                </div>
              )}
            </div>
          </div>

          {submitError && (
            <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg">
              <p className="text-sm text-red-300 flex items-center gap-2">
                <AlertCircle className="h-4 w-4" />
                {submitError}
              </p>
            </div>
          )}

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
              disabled={createXtream.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {createXtream.isPending ? 'Adding...' : 'Add Source'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function EPGProgramsTab({ epgSources }: { epgSources: any[] }) {
  const [selectedSource, setSelectedSource] = useState<number | null>(null)
  const [page, setPage] = useState(1)
  const limit = 50

  const { data: programsData, isLoading } = useQuery({
    queryKey: ['epgPrograms', selectedSource, page],
    queryFn: () => api.getEPGPrograms({
      page,
      limit,
      epgSourceId: selectedSource || undefined,
    }),
    enabled: epgSources.length > 0,
  })

  const totalPrograms = epgSources.reduce((sum, s) => sum + (s.programCount || 0), 0)

  return (
    <div>
      <div className="bg-gray-800 rounded-xl p-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="text-lg font-semibold text-white mb-1">EPG Program Listings</h3>
            <p className="text-sm text-gray-400">
              Total: {totalPrograms.toLocaleString()} programs across {epgSources.length} source(s)
            </p>
          </div>
          {epgSources.length > 1 && (
            <select
              value={selectedSource || ''}
              onChange={(e) => {
                setSelectedSource(e.target.value ? parseInt(e.target.value) : null)
                setPage(1)
              }}
              className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
            >
              <option value="">All Sources</option>
              {epgSources.map((source) => (
                <option key={source.id} value={source.id}>
                  {source.name} ({source.programCount} programs)
                </option>
              ))}
            </select>
          )}
        </div>

        {/* Channel mapping info */}
        <div className="mb-4 p-3 bg-blue-500/10 border border-blue-500/30 rounded-lg">
          <p className="text-sm text-blue-300">
            <strong>Note:</strong> Channel names in gray are EPG channel IDs that haven't been mapped to your M3U channels yet.
            Go to the <strong>Channels</strong> tab to assign EPG sources to your channels for proper matching.
          </p>
        </div>

        {isLoading ? (
          <div className="text-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500 mx-auto"></div>
            <p className="text-gray-400 mt-4">Loading programs...</p>
          </div>
        ) : programsData && programsData.programs.length > 0 ? (
          <>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-700/50">
                  <tr>
                    <th className="text-left p-3 text-gray-300 text-sm font-medium">Channel</th>
                    <th className="text-left p-3 text-gray-300 text-sm font-medium">Program</th>
                    <th className="text-left p-3 text-gray-300 text-sm font-medium">Time</th>
                    <th className="text-left p-3 text-gray-300 text-sm font-medium">Category</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-700">
                  {programsData.programs.map((program) => {
                    const start = new Date(program.start)
                    const end = new Date(program.end)
                    const duration = Math.round((end.getTime() - start.getTime()) / 60000)

                    // Format channel display
                    const channelDisplay = program.channelName ||
                      (program.channelId?.replace(/^(fubo|gracenote)-/, '') || 'Unknown')
                    const isUnmapped = !program.channelName

                    return (
                      <tr key={program.id} className="hover:bg-gray-700/30">
                        <td className="p-3">
                          <div className={`font-medium ${isUnmapped ? 'text-gray-400' : 'text-white'}`}>
                            {channelDisplay}
                          </div>
                          {isUnmapped && (
                            <div className="text-xs text-gray-600 mt-1">EPG ID: {program.channelId}</div>
                          )}
                        </td>
                        <td className="p-3">
                          <div className="font-medium text-white">{program.title}</div>
                          {program.description && (
                            <div className="text-sm text-gray-400 mt-1 line-clamp-2">
                              {program.description}
                            </div>
                          )}
                          {program.episodeNum && (
                            <div className="text-xs text-gray-500 mt-1">{program.episodeNum}</div>
                          )}
                        </td>
                        <td className="p-3">
                          <div className="text-sm text-white">
                            {start.toLocaleDateString()} {start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </div>
                          <div className="text-xs text-gray-400">{duration} min</div>
                        </td>
                        <td className="p-3">
                          {program.category && (
                            <span className="inline-block px-2 py-1 bg-gray-700 text-gray-300 text-xs rounded">
                              {program.category}
                            </span>
                          )}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {programsData.pages > 1 && (
              <div className="flex items-center justify-between mt-6 pt-4 border-t border-gray-700">
                <div className="text-sm text-gray-400">
                  Showing {((page - 1) * limit) + 1} - {Math.min(page * limit, programsData.total)} of {programsData.total.toLocaleString()}
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => setPage(p => Math.max(1, p - 1))}
                    disabled={page === 1}
                    className="px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-sm rounded disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Previous
                  </button>
                  <div className="flex items-center gap-1">
                    {Array.from({ length: Math.min(5, programsData.pages) }, (_, i) => {
                      let pageNum
                      if (programsData.pages <= 5) {
                        pageNum = i + 1
                      } else if (page <= 3) {
                        pageNum = i + 1
                      } else if (page >= programsData.pages - 2) {
                        pageNum = programsData.pages - 4 + i
                      } else {
                        pageNum = page - 2 + i
                      }
                      return (
                        <button
                          key={pageNum}
                          onClick={() => setPage(pageNum)}
                          className={`px-3 py-1.5 text-sm rounded ${
                            page === pageNum
                              ? 'bg-indigo-600 text-white'
                              : 'bg-gray-700 hover:bg-gray-600 text-white'
                          }`}
                        >
                          {pageNum}
                        </button>
                      )
                    })}
                  </div>
                  <button
                    onClick={() => setPage(p => Math.min(programsData.pages, p + 1))}
                    disabled={page === programsData.pages}
                    className="px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-sm rounded disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Next
                  </button>
                </div>
              </div>
            )}
          </>
        ) : (
          <div className="text-center py-12">
            <FileText className="h-12 w-12 text-gray-600 mx-auto mb-4" />
            <p className="text-gray-400">
              {epgSources.length === 0
                ? 'No EPG sources configured. Add an EPG source to see program listings.'
                : 'No programs found. Try refreshing your EPG sources.'}
            </p>
          </div>
        )}
      </div>
    </div>
  )
}

// Channel Group Card Component
function ChannelGroupCard({
  group,
  channels,
  onEdit,
  onDelete,
  onAddMember,
  onUpdatePriority,
  onRemoveMember,
}: {
  group: any
  channels: Channel[]
  onEdit: () => void
  onDelete: () => void
  onAddMember: (channelId: number, priority: number) => void
  onUpdatePriority: (channelId: number, priority: number) => void
  onRemoveMember: (channelId: number) => void
}) {
  const [isExpanded, setIsExpanded] = useState(false)
  const [showAddChannel, setShowAddChannel] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')

  const memberChannelIds = new Set(group.members?.map((m: any) => m.channelId) || [])
  const availableChannels = channels.filter(
    (ch) => ch.enabled && !memberChannelIds.has(ch.id)
  )
  const filteredAvailable = availableChannels.filter((ch) =>
    ch.name.toLowerCase().includes(searchQuery.toLowerCase())
  )

  return (
    <div className="bg-gray-800 rounded-xl overflow-hidden">
      {/* Header */}
      <div
        className="p-4 flex items-center justify-between cursor-pointer hover:bg-gray-750"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <div className="flex items-center gap-4">
          <button className="text-gray-400">
            {isExpanded ? (
              <ChevronDown className="h-5 w-5" />
            ) : (
              <ChevronRight className="h-5 w-5" />
            )}
          </button>
          {group.logo ? (
            <img
              src={group.logo}
              alt={group.name}
              className="w-10 h-10 object-contain bg-gray-700 rounded"
            />
          ) : (
            <div className="w-10 h-10 bg-gray-700 rounded flex items-center justify-center">
              <Layers className="h-5 w-5 text-gray-500" />
            </div>
          )}
          <div>
            <div className="flex items-center gap-2">
              <span className="text-white font-medium">{group.name}</span>
              <span className="text-gray-500 text-sm">#{group.displayNumber}</span>
              {!group.enabled && (
                <span className="px-2 py-0.5 bg-gray-700 text-gray-400 text-xs rounded">
                  Disabled
                </span>
              )}
            </div>
            <div className="text-sm text-gray-400">
              {group.members?.length || 0} source{(group.members?.length || 0) !== 1 ? 's' : ''}
              {group.channelId && ` • EPG: ${group.channelId}`}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
          <button
            onClick={onEdit}
            className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded"
            title="Edit group"
          >
            <Edit className="h-4 w-4" />
          </button>
          <button
            onClick={onDelete}
            className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded"
            title="Delete group"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Expanded content */}
      {isExpanded && (
        <div className="border-t border-gray-700 p-4">
          {/* Members list */}
          {group.members?.length > 0 ? (
            <div className="space-y-2 mb-4">
              <div className="text-xs text-gray-500 uppercase tracking-wider mb-2">
                Priority Order (failover from top to bottom)
              </div>
              {group.members
                .sort((a: any, b: any) => a.priority - b.priority)
                .map((member: any, index: number) => (
                  <div
                    key={member.channelId}
                    className="flex items-center justify-between bg-gray-750 rounded-lg p-3"
                  >
                    <div className="flex items-center gap-3">
                      <span className="text-gray-500 text-sm font-mono w-6">
                        {index + 1}.
                      </span>
                      {member.channel?.logo ? (
                        <img
                          src={member.channel.logo}
                          alt={member.channel.name}
                          className="w-8 h-8 object-contain bg-gray-700 rounded"
                        />
                      ) : (
                        <div className="w-8 h-8 bg-gray-700 rounded flex items-center justify-center">
                          <Radio className="h-4 w-4 text-gray-500" />
                        </div>
                      )}
                      <div>
                        <div className="text-white text-sm">{member.channel?.name}</div>
                        <div className="text-gray-500 text-xs">
                          {member.channel?.sourceName || 'Unknown source'}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() =>
                          onUpdatePriority(member.channelId, Math.max(0, member.priority - 1))
                        }
                        disabled={index === 0}
                        className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded disabled:opacity-30"
                        title="Move up"
                      >
                        <ArrowUp className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() =>
                          onUpdatePriority(member.channelId, member.priority + 1)
                        }
                        disabled={index === (group.members?.length || 0) - 1}
                        className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded disabled:opacity-30"
                        title="Move down"
                      >
                        <ArrowDown className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => onRemoveMember(member.channelId)}
                        className="p-1.5 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded"
                        title="Remove from group"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                ))}
            </div>
          ) : (
            <div className="text-center py-4 text-gray-400 mb-4">
              No channels in this group. Add channels to enable failover.
            </div>
          )}

          {/* Add channel section */}
          {showAddChannel ? (
            <div className="bg-gray-750 rounded-lg p-3">
              <div className="flex items-center gap-2 mb-3">
                <Search className="h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search channels to add..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="flex-1 bg-transparent text-white placeholder-gray-500 outline-none text-sm"
                  autoFocus
                />
                <button
                  onClick={() => {
                    setShowAddChannel(false)
                    setSearchQuery('')
                  }}
                  className="p-1 text-gray-400 hover:text-white"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
              <div className="max-h-48 overflow-y-auto space-y-1">
                {filteredAvailable.length > 0 ? (
                  filteredAvailable.slice(0, 20).map((channel) => (
                    <button
                      key={channel.id}
                      onClick={() => {
                        onAddMember(channel.id, group.members?.length || 0)
                        setSearchQuery('')
                      }}
                      className="w-full flex items-center gap-3 p-2 hover:bg-gray-700 rounded text-left"
                    >
                      {channel.logo ? (
                        <img
                          src={channel.logo}
                          alt={channel.name}
                          className="w-6 h-6 object-contain bg-gray-700 rounded"
                        />
                      ) : (
                        <div className="w-6 h-6 bg-gray-700 rounded flex items-center justify-center">
                          <Radio className="h-3 w-3 text-gray-500" />
                        </div>
                      )}
                      <span className="text-sm text-white">{channel.name}</span>
                      <span className="text-xs text-gray-500">#{channel.number}</span>
                    </button>
                  ))
                ) : (
                  <div className="text-center py-2 text-gray-500 text-sm">
                    {searchQuery ? 'No matching channels' : 'No available channels'}
                  </div>
                )}
              </div>
            </div>
          ) : (
            <button
              onClick={() => setShowAddChannel(true)}
              className="w-full py-2 border border-dashed border-gray-600 rounded-lg text-gray-400 hover:text-white hover:border-gray-500 flex items-center justify-center gap-2"
            >
              <Plus className="h-4 w-4" />
              Add Channel Source
            </button>
          )}
        </div>
      )}
    </div>
  )
}

// Create/Edit Channel Group Modal
function ChannelGroupModal({
  group,
  onClose,
  onSave,
  isLoading,
}: {
  group?: any
  onClose: () => void
  onSave: (data: { name: string; displayNumber: number; logo?: string; channelId?: string; enabled?: boolean }) => void
  isLoading: boolean
}) {
  const [name, setName] = useState(group?.name || '')
  const [displayNumber, setDisplayNumber] = useState(group?.displayNumber?.toString() || '')
  const [logo, setLogo] = useState(group?.logo || '')
  const [channelId, setChannelId] = useState(group?.channelId || '')
  const [enabled, setEnabled] = useState(group?.enabled ?? true)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSave({
      name,
      displayNumber: parseInt(displayNumber) || 0,
      logo: logo || undefined,
      channelId: channelId || undefined,
      enabled,
    })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <h2 className="text-lg font-semibold text-white mb-4">
          {group ? 'Edit Channel Group' : 'Create Channel Group'}
        </h2>
        <form onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Group Name
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="ESPN"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Channel Number
              </label>
              <input
                type="number"
                value={displayNumber}
                onChange={(e) => setDisplayNumber(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="100"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Logo URL (optional)
              </label>
              <input
                type="url"
                value={logo}
                onChange={(e) => setLogo(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="https://example.com/logo.png"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                EPG Channel ID (optional)
              </label>
              <input
                type="text"
                value={channelId}
                onChange={(e) => setChannelId(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="ESPN.us"
              />
            </div>

            {group && (
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setEnabled(!enabled)}
                  className={`w-5 h-5 rounded border flex items-center justify-center ${
                    enabled
                      ? 'bg-indigo-600 border-indigo-600'
                      : 'border-gray-500 hover:border-gray-400'
                  }`}
                >
                  {enabled && <Check className="h-3 w-3 text-white" />}
                </button>
                <span className="text-sm text-gray-300">Enabled</span>
              </div>
            )}
          </div>

          <div className="mt-6 flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isLoading || !name || !displayNumber}
              className="flex-1 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-600 text-white rounded-lg"
            >
              {isLoading ? 'Saving...' : group ? 'Save Changes' : 'Create Group'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// Auto-Detect Duplicates Modal
function AutoDetectModal({
  results,
  onClose,
  onCreateGroup,
  isCreating,
}: {
  results: any[]
  onClose: () => void
  onCreateGroup: (group: any) => void
  isCreating: boolean
}) {
  const [createdNames, setCreatedNames] = useState<Set<string>>(new Set())

  if (!results || results.length === 0) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
        <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md text-center">
          <Layers className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h2 className="text-lg font-semibold text-white mb-2">No Duplicates Found</h2>
          <p className="text-gray-400 mb-4">
            No duplicate channels were detected across your sources.
          </p>
          <button
            onClick={onClose}
            className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
          >
            Close
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-2xl max-h-[80vh] flex flex-col">
        <h2 className="text-lg font-semibold text-white mb-2">Detected Duplicate Channels</h2>
        <p className="text-gray-400 text-sm mb-4">
          Found {results.length} channel{results.length !== 1 ? 's' : ''} with duplicates across sources.
          Create groups to enable automatic failover.
        </p>

        <div className="flex-1 overflow-y-auto space-y-3">
          {results.map((group, index) => (
            <div key={index} className="bg-gray-750 rounded-lg p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  {group.channels[0]?.logo ? (
                    <img
                      src={group.channels[0].logo}
                      alt={group.name}
                      className="w-8 h-8 object-contain bg-gray-700 rounded"
                    />
                  ) : (
                    <div className="w-8 h-8 bg-gray-700 rounded flex items-center justify-center">
                      <Radio className="h-4 w-4 text-gray-500" />
                    </div>
                  )}
                  <div>
                    <div className="text-white font-medium">{group.name}</div>
                    <div className="text-gray-500 text-xs">
                      {group.channels.length} sources found
                    </div>
                  </div>
                </div>
                {createdNames.has(group.name) ? (
                  <span className="px-3 py-1 bg-green-600/20 text-green-400 text-sm rounded-lg">
                    Created
                  </span>
                ) : (
                  <button
                    onClick={() => {
                      onCreateGroup(group)
                      setCreatedNames((prev) => new Set([...prev, group.name]))
                    }}
                    disabled={isCreating}
                    className="px-3 py-1 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-600 text-white text-sm rounded-lg"
                  >
                    Create Group
                  </button>
                )}
              </div>
              <div className="space-y-1 pl-11">
                {group.channels.map((ch: any, idx: number) => (
                  <div key={ch.id} className="text-sm text-gray-400 flex items-center gap-2">
                    <span className="text-gray-600">{idx + 1}.</span>
                    <span>{ch.name}</span>
                    <span className="text-gray-600">•</span>
                    <span className="text-gray-500">{ch.sourceName || 'Unknown'}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className="mt-4 pt-4 border-t border-gray-700 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  )
}

export function LiveTVPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { data: m3uSources, isLoading: loadingM3U } = useM3USources()
  const { data: epgSources, isLoading: loadingEPG } = useEPGSources()
  const deleteM3U = useDeleteM3USource()
  const refreshM3U = useRefreshM3USource()
  const deleteEPG = useDeleteEPGSource()
  const refreshEPG = useRefreshEPG()
  const [showAddModal, setShowAddModal] = useState<'m3u' | 'epg' | 'xtream' | null>(null)
  const [activeTab, setActiveTab] = useState<'sources' | 'channels' | 'programs' | 'groups'>('sources')
  const [channelSearch, setChannelSearch] = useState('')
  const [editingChannel, setEditingChannel] = useState<Channel | null>(null)
  const [showMapNumbersModal, setShowMapNumbersModal] = useState(false)
  const [editingM3USource, setEditingM3USource] = useState<any | null>(null)
  const [editingXtreamSource, setEditingXtreamSource] = useState<any | null>(null)
  const [editingEPGSource, setEditingEPGSource] = useState<any | null>(null)
  const [refreshingEPGId, setRefreshingEPGId] = useState<number | null>(null)
  const [refreshingXtreamId, setRefreshingXtreamId] = useState<number | null>(null)
  // Channel Groups state
  const [editingGroup, setEditingGroup] = useState<any | null>(null)
  const [showCreateGroupModal, setShowCreateGroupModal] = useState(false)
  const [showAutoDetectModal, setShowAutoDetectModal] = useState(false)

  // Xtream sources
  const { data: xtreamSources, isLoading: loadingXtream } = useQuery({
    queryKey: ['xtreamSources'],
    queryFn: () => api.getXtreamSources(),
  })

  const deleteXtream = useMutation({
    mutationFn: (id: number) => api.deleteXtreamSource(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['xtreamSources'] })
      queryClient.invalidateQueries({ queryKey: ['channels'] })
    },
  })

  const refreshXtream = useMutation({
    mutationFn: (id: number) => api.refreshXtreamSource(id),
    onMutate: (id) => setRefreshingXtreamId(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['xtreamSources'] })
      queryClient.invalidateQueries({ queryKey: ['channels'] })
    },
    onSettled: () => setRefreshingXtreamId(null),
  })

  const [importingVodId, setImportingVodId] = useState<number | null>(null)
  const [importingSeriesId, setImportingSeriesId] = useState<number | null>(null)

  const importVod = useMutation({
    mutationFn: (id: number) => api.importXtreamVOD(id),
    onMutate: (id) => setImportingVodId(id),
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ['xtreamSources'] })
      alert(`VOD Import: ${result.added} added, ${result.updated} updated`)
    },
    onSettled: () => setImportingVodId(null),
  })

  const importSeries = useMutation({
    mutationFn: (id: number) => api.importXtreamSeries(id),
    onMutate: (id) => setImportingSeriesId(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['xtreamSources'] })
      queryClient.invalidateQueries({ queryKey: ['libraryStats'] })
      alert('Series import started in background. Check library stats for progress.')
    },
    onSettled: () => setImportingSeriesId(null),
  })

  // Query for library stats to show actual counts
  const { data: libraryStatsMap } = useQuery({
    queryKey: ['libraryStats'],
    queryFn: async () => {
      const stats: Record<number, { movieCount: number; showCount: number; episodeCount: number }> = {}
      // Get stats for all libraries used by Xtream sources
      const libraryIds = new Set<number>()
      xtreamSources?.forEach(source => {
        if (source.vodLibraryId) libraryIds.add(source.vodLibraryId)
        if (source.seriesLibraryId) libraryIds.add(source.seriesLibraryId)
      })
      for (const id of libraryIds) {
        try {
          const libStats = await api.getLibraryStats(id)
          stats[id] = {
            movieCount: libStats.movieCount,
            showCount: libStats.showCount,
            episodeCount: libStats.episodeCount,
          }
        } catch {
          // Library might not exist
        }
      }
      return stats
    },
    enabled: !!xtreamSources?.length,
    refetchInterval: 10000, // Refresh every 10 seconds to show import progress
  })

  // Individual EPG source refresh
  const refreshIndividualEPG = useMutation({
    mutationFn: async (id: number) => {
      const response = await fetch(`/livetv/epg/sources/${id}/refresh`, {
        method: 'POST',
        headers: { 'X-Plex-Token': api.getToken() || '' },
      })
      if (!response.ok) throw new Error('Failed to refresh EPG source')
      return response.json()
    },
    onMutate: (id) => {
      setRefreshingEPGId(id)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['epgSources'] })
    },
    onSettled: () => {
      setRefreshingEPGId(null)
    },
  })

  // Fetch channels
  const { data: channelsData, isLoading: loadingChannels } = useQuery({
    queryKey: ['channels'],
    queryFn: async () => {
      const response = await fetch('/livetv/channels', {
        headers: { 'X-Plex-Token': api.getToken() || '' },
      })
      const data = await response.json()
      return data.channels as Channel[]
    },
    enabled: activeTab === 'channels',
  })

  const toggleChannel = useMutation({
    mutationFn: async ({ id, enabled }: { id: number; enabled: boolean }) => {
      const response = await fetch(`/livetv/channels/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || '',
        },
        body: JSON.stringify({ enabled }),
      })
      if (!response.ok) throw new Error('Failed to update channel')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channels'] })
    },
  })

  // Toggle archive/catch-up for a channel
  const toggleArchive = useMutation({
    mutationFn: async ({ id, enabled }: { id: number; enabled: boolean }) => {
      const endpoint = enabled
        ? `/livetv/channels/${id}/archive/enable`
        : `/livetv/channels/${id}/archive/disable`
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || '',
        },
        body: enabled ? JSON.stringify({ days: 7 }) : undefined,
      })
      if (!response.ok) throw new Error('Failed to update channel archive')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channels'] })
    },
  })

  // Channel Groups
  const { data: channelGroups, isLoading: loadingGroups } = useQuery({
    queryKey: ['channelGroups'],
    queryFn: () => api.getChannelGroups(),
    enabled: activeTab === 'groups',
  })

  const createGroup = useMutation({
    mutationFn: (data: { name: string; displayNumber: number; logo?: string; channelId?: string }) =>
      api.createChannelGroup(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channelGroups'] })
      setShowCreateGroupModal(false)
    },
  })

  const updateGroup = useMutation({
    mutationFn: ({ id, data }: { id: number; data: { name?: string; displayNumber?: number; logo?: string; channelId?: string; enabled?: boolean } }) =>
      api.updateChannelGroup(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channelGroups'] })
      setEditingGroup(null)
    },
  })

  const deleteGroup = useMutation({
    mutationFn: (id: number) => api.deleteChannelGroup(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channelGroups'] })
    },
  })

  const addMember = useMutation({
    mutationFn: ({ groupId, channelId, priority }: { groupId: number; channelId: number; priority: number }) =>
      api.addChannelToGroup(groupId, channelId, priority),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channelGroups'] })
    },
  })

  const updateMemberPriority = useMutation({
    mutationFn: ({ groupId, channelId, priority }: { groupId: number; channelId: number; priority: number }) =>
      api.updateGroupMemberPriority(groupId, channelId, priority),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channelGroups'] })
    },
  })

  const removeMember = useMutation({
    mutationFn: ({ groupId, channelId }: { groupId: number; channelId: number }) =>
      api.removeChannelFromGroup(groupId, channelId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channelGroups'] })
    },
  })

  const [autoDetectResults, setAutoDetectResults] = useState<any[] | null>(null)
  const [isAutoDetecting, setIsAutoDetecting] = useState(false)

  const handleAutoDetect = async () => {
    setIsAutoDetecting(true)
    try {
      const result = await api.autoDetectDuplicates()
      setAutoDetectResults(result.duplicates)
      setShowAutoDetectModal(true)
    } catch (error) {
      console.error('Failed to auto-detect duplicates:', error)
    } finally {
      setIsAutoDetecting(false)
    }
  }

  const filteredChannels = channelsData?.filter(
    (ch) =>
      ch.name.toLowerCase().includes(channelSearch.toLowerCase()) ||
      ch.channelId.toLowerCase().includes(channelSearch.toLowerCase()) ||
      (ch.group && ch.group.toLowerCase().includes(channelSearch.toLowerCase()))
  )

  const enabledCount = channelsData?.filter((ch) => ch.enabled).length || 0
  const totalCount = channelsData?.length || 0
  const archiveCount = channelsData?.filter((ch) => ch.archiveEnabled).length || 0

  return (
    <div>
      <div className="mb-8 flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Live TV</h1>
          <p className="text-gray-400 mt-1">Manage your IPTV sources, channels, and program guide</p>
        </div>
        <button
          onClick={() => navigate('/ui/livetv/epg-editor')}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg"
        >
          <Settings className="h-4 w-4" />
          EPG Editor
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-4 mb-6 border-b border-gray-700">
        <button
          onClick={() => setActiveTab('sources')}
          className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'sources'
              ? 'border-indigo-500 text-white'
              : 'border-transparent text-gray-400 hover:text-white'
          }`}
        >
          Sources
        </button>
        <button
          onClick={() => setActiveTab('channels')}
          className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'channels'
              ? 'border-indigo-500 text-white'
              : 'border-transparent text-gray-400 hover:text-white'
          }`}
        >
          Channels {totalCount > 0 && `(${enabledCount}/${totalCount})`}
          {archiveCount > 0 && (
            <span className="ml-2 px-1.5 py-0.5 bg-purple-600 text-white text-xs rounded">
              {archiveCount} recording
            </span>
          )}
        </button>
        <button
          onClick={() => setActiveTab('programs')}
          className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'programs'
              ? 'border-indigo-500 text-white'
              : 'border-transparent text-gray-400 hover:text-white'
          }`}
        >
          EPG Programs
        </button>
        <button
          onClick={() => setActiveTab('groups')}
          className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'groups'
              ? 'border-indigo-500 text-white'
              : 'border-transparent text-gray-400 hover:text-white'
          }`}
        >
          Channel Groups
        </button>
      </div>

      {activeTab === 'sources' && (
        <>
          {/* M3U Sources */}
          <div className="mb-8">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white flex items-center gap-2">
                <Tv className="h-5 w-5" />
                M3U Playlists
              </h2>
              <button
                onClick={() => setShowAddModal('m3u')}
                className="flex items-center gap-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg"
              >
                <Plus className="h-4 w-4" />
                Add Playlist
              </button>
            </div>

            {loadingM3U ? (
              <div className="text-gray-400">Loading...</div>
            ) : m3uSources?.length ? (
              <div className="bg-gray-800 rounded-xl divide-y divide-gray-700">
                {m3uSources.map((source) => (
                  <div key={source.id} className="p-4 flex items-center justify-between">
                    <div>
                      <h3 className="font-medium text-white">{source.name}</h3>
                      <p className="text-sm text-gray-400">
                        {source.channelCount} channels
                        {source.lastRefresh && (
                          <> • Last updated: {new Date(source.lastRefresh).toLocaleDateString()}</>
                        )}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => setEditingM3USource(source)}
                        className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg"
                        title="Edit"
                      >
                        <Edit className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => refreshM3U.mutate(source.id)}
                        disabled={refreshM3U.isPending}
                        className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg"
                        title="Refresh"
                      >
                        <RefreshCw className={`h-4 w-4 ${refreshM3U.isPending ? 'animate-spin' : ''}`} />
                      </button>
                      <button
                        onClick={() => deleteM3U.mutate(source.id)}
                        className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg"
                        title="Delete"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 bg-gray-800 rounded-xl">
                <Tv className="h-10 w-10 text-gray-600 mx-auto mb-3" />
                <p className="text-gray-400">No M3U playlists configured</p>
              </div>
            )}
          </div>

          {/* Xtream Sources */}
          <div className="mb-8">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white flex items-center gap-2">
                <Zap className="h-5 w-5 text-yellow-400" />
                Xtream Codes API
              </h2>
              <button
                onClick={() => setShowAddModal('xtream')}
                className="flex items-center gap-2 px-3 py-1.5 bg-yellow-600 hover:bg-yellow-700 text-white text-sm rounded-lg"
              >
                <Plus className="h-4 w-4" />
                Add Xtream
              </button>
            </div>

            {loadingXtream ? (
              <div className="text-gray-400">Loading...</div>
            ) : xtreamSources?.length ? (
              <div className="bg-gray-800 rounded-xl divide-y divide-gray-700">
                {xtreamSources.map((source) => (
                  <div key={source.id} className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <h3 className="font-medium text-white">{source.name}</h3>
                          {!source.enabled && (
                            <span className="px-2 py-0.5 bg-gray-700 text-gray-400 text-xs rounded">
                              Disabled
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-gray-400">
                          {source.channelCount} channels • {source.username}@{source.serverUrl.replace(/^https?:\/\//, '')}
                        </p>
                        {source.expirationDate && (
                          <p className="text-xs text-gray-500 mt-1">
                            Expires: {new Date(source.expirationDate).toLocaleDateString()}
                          </p>
                        )}
                        {source.lastError && (
                          <p className="text-xs text-red-400 mt-1 flex items-center gap-1">
                            <AlertCircle className="h-3 w-3" />
                            {source.lastError}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => setEditingXtreamSource(source)}
                          className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg"
                          title="Edit"
                        >
                          <Edit className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => refreshXtream.mutate(source.id)}
                          disabled={refreshingXtreamId === source.id}
                          className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg"
                          title="Refresh Channels"
                        >
                          <RefreshCw className={`h-4 w-4 ${refreshingXtreamId === source.id ? 'animate-spin' : ''}`} />
                        </button>
                        <button
                          onClick={() => deleteXtream.mutate(source.id)}
                          className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg"
                          title="Delete"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>

                    {/* VOD/Series Import Section */}
                    {(source.importVod || source.importSeries) && (
                      <div className="mt-3 pt-3 border-t border-gray-700 flex flex-wrap gap-3">
                        {source.importVod && source.vodLibraryId && (
                          <div className="flex items-center gap-2">
                            <div className="flex items-center gap-1 text-sm text-gray-400">
                              <Film className="h-4 w-4" />
                              <span>VOD: {libraryStatsMap?.[source.vodLibraryId]?.movieCount ?? source.vodCount ?? 0} movies</span>
                            </div>
                            <button
                              onClick={() => importVod.mutate(source.id)}
                              disabled={importingVodId === source.id}
                              className="px-2 py-1 text-xs bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 text-white rounded flex items-center gap-1"
                              title="Import VOD Movies"
                            >
                              {importingVodId === source.id ? (
                                <RefreshCw className="h-3 w-3 animate-spin" />
                              ) : (
                                <Download className="h-3 w-3" />
                              )}
                              Import
                            </button>
                          </div>
                        )}
                        {source.importSeries && source.seriesLibraryId && (
                          <div className="flex items-center gap-2">
                            <div className="flex items-center gap-1 text-sm text-gray-400">
                              <Monitor className="h-4 w-4" />
                              <span>Series: {libraryStatsMap?.[source.seriesLibraryId]?.showCount ?? source.seriesCount ?? 0} shows ({libraryStatsMap?.[source.seriesLibraryId]?.episodeCount ?? 0} episodes)</span>
                            </div>
                            <button
                              onClick={() => importSeries.mutate(source.id)}
                              disabled={importingSeriesId === source.id}
                              className="px-2 py-1 text-xs bg-purple-600 hover:bg-purple-700 disabled:bg-gray-600 text-white rounded flex items-center gap-1"
                              title="Import TV Series"
                            >
                              {importingSeriesId === source.id ? (
                                <RefreshCw className="h-3 w-3 animate-spin" />
                              ) : (
                                <Download className="h-3 w-3" />
                              )}
                              Import
                            </button>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 bg-gray-800 rounded-xl">
                <Zap className="h-10 w-10 text-gray-600 mx-auto mb-3" />
                <p className="text-gray-400">No Xtream Codes sources configured</p>
                <p className="text-sm text-gray-500 mt-1">
                  Add your Xtream provider to import channels via API
                </p>
              </div>
            )}
          </div>

          {/* EPG Sources */}
          <div>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white flex items-center gap-2">
                <FileText className="h-5 w-5" />
                EPG Sources
              </h2>
              <div className="flex gap-2">
                <button
                  onClick={() => refreshEPG.mutate()}
                  disabled={refreshEPG.isPending}
                  className="flex items-center gap-2 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-sm rounded-lg"
                >
                  <RefreshCw className={`h-4 w-4 ${refreshEPG.isPending ? 'animate-spin' : ''}`} />
                  Refresh All
                </button>
                <button
                  onClick={() => setShowAddModal('epg')}
                  className="flex items-center gap-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg"
                >
                  <Plus className="h-4 w-4" />
                  Add EPG
                </button>
              </div>
            </div>

            {loadingEPG ? (
              <div className="text-gray-400">Loading...</div>
            ) : epgSources?.length ? (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                {epgSources.map((source) => (
                  <EPGSourceCard
                    key={source.id}
                    source={source}
                    onRefresh={(id) => refreshIndividualEPG.mutate(id)}
                    onDelete={(id) => deleteEPG.mutate(id)}
                    onEdit={(source) => setEditingEPGSource(source)}
                    isRefreshing={refreshingEPGId === source.id}
                  />
                ))}
              </div>
            ) : (
              <div className="text-center py-8 bg-gray-800 rounded-xl">
                <FileText className="h-10 w-10 text-gray-600 mx-auto mb-3" />
                <p className="text-gray-400">No EPG sources configured</p>
              </div>
            )}
          </div>
        </>
      )}

      {activeTab === 'programs' && (
        <EPGProgramsTab epgSources={epgSources || []} />
      )}

      {activeTab === 'channels' && (
        <div>
          {/* Search and Actions */}
          <div className="mb-4 flex gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search channels..."
                value={channelSearch}
                onChange={(e) => setChannelSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400"
              />
            </div>
            <button
              onClick={() => setShowMapNumbersModal(true)}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg flex items-center gap-2 whitespace-nowrap"
            >
              <FileText className="h-4 w-4" />
              Import Numbers
            </button>
          </div>

          {loadingChannels ? (
            <div className="text-gray-400">Loading channels...</div>
          ) : filteredChannels?.length ? (
            <div className="bg-gray-800 rounded-xl overflow-hidden">
              <div className="max-h-[600px] overflow-y-auto">
                <table className="w-full">
                  <thead className="sticky top-0 bg-gray-800 border-b border-gray-700">
                    <tr>
                      <th className="text-left p-3 text-gray-400 text-sm font-medium">Enabled</th>
                      <th className="text-left p-3 text-gray-400 text-sm font-medium">#</th>
                      <th className="text-left p-3 text-gray-400 text-sm font-medium">Channel</th>
                      <th className="text-left p-3 text-gray-400 text-sm font-medium">Group</th>
                      <th className="text-left p-3 text-gray-400 text-sm font-medium">
                        <div className="flex items-center gap-1">
                          <Archive className="h-3 w-3" />
                          Catch-up
                        </div>
                      </th>
                      <th className="text-left p-3 text-gray-400 text-sm font-medium">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-700">
                    {filteredChannels.map((channel) => (
                      <tr key={channel.id} className={!channel.enabled ? 'opacity-50' : ''}>
                        <td className="p-3">
                          <button
                            onClick={() =>
                              toggleChannel.mutate({ id: channel.id, enabled: !channel.enabled })
                            }
                            className={`w-5 h-5 rounded border flex items-center justify-center ${
                              channel.enabled
                                ? 'bg-indigo-600 border-indigo-600'
                                : 'border-gray-500 hover:border-gray-400'
                            }`}
                          >
                            {channel.enabled && <Check className="h-3 w-3 text-white" />}
                          </button>
                        </td>
                        <td className="p-3 text-gray-400 text-sm">{channel.number}</td>
                        <td className="p-3">
                          <div className="flex items-center gap-3">
                            {channel.logo ? (
                              <img
                                src={channel.logo}
                                alt={channel.name}
                                className="w-8 h-8 object-contain bg-gray-700 rounded"
                              />
                            ) : (
                              <div className="w-8 h-8 bg-gray-700 rounded flex items-center justify-center">
                                <Radio className="h-4 w-4 text-gray-500" />
                              </div>
                            )}
                            <div>
                              <div className="text-white text-sm">{channel.name}</div>
                              <div className="text-gray-500 text-xs">{channel.channelId}</div>
                            </div>
                          </div>
                        </td>
                        <td className="p-3 text-gray-400 text-sm">{channel.group || '-'}</td>
                        <td className="p-3">
                          <button
                            onClick={() => toggleArchive.mutate({ id: channel.id, enabled: !channel.archiveEnabled })}
                            disabled={!channel.enabled}
                            className={`px-2 py-1 rounded text-xs font-medium flex items-center gap-1 ${
                              channel.archiveEnabled
                                ? 'bg-purple-600 text-white hover:bg-purple-700'
                                : 'bg-gray-700 text-gray-400 hover:bg-gray-600 hover:text-white'
                            } ${!channel.enabled ? 'opacity-50 cursor-not-allowed' : ''}`}
                            title={channel.archiveEnabled ? 'Disable catch-up recording' : 'Enable catch-up recording (7 days)'}
                          >
                            <Clock className="h-3 w-3" />
                            {channel.archiveEnabled ? `${channel.archiveDays || 7}d` : 'Off'}
                          </button>
                        </td>
                        <td className="p-3">
                          <button
                            onClick={() => setEditingChannel(channel)}
                            className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded"
                            title="Edit"
                          >
                            <Edit className="h-4 w-4" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 bg-gray-800 rounded-xl">
              <Radio className="h-10 w-10 text-gray-600 mx-auto mb-3" />
              <p className="text-gray-400">
                {channelSearch ? 'No channels match your search' : 'No channels loaded'}
              </p>
            </div>
          )}
        </div>
      )}

      {activeTab === 'groups' && (
        <div>
          {/* Header with actions */}
          <div className="mb-4 flex items-center justify-between">
            <div className="text-sm text-gray-400">
              {channelGroups?.length || 0} channel group{channelGroups?.length !== 1 ? 's' : ''}
            </div>
            <div className="flex gap-2">
              <button
                onClick={handleAutoDetect}
                disabled={isAutoDetecting}
                className="px-4 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-gray-600 text-white rounded-lg flex items-center gap-2"
              >
                {isAutoDetecting ? (
                  <RefreshCw className="h-4 w-4 animate-spin" />
                ) : (
                  <Wand2 className="h-4 w-4" />
                )}
                Auto-Detect Duplicates
              </button>
              <button
                onClick={() => setShowCreateGroupModal(true)}
                className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg flex items-center gap-2"
              >
                <Plus className="h-4 w-4" />
                Create Group
              </button>
            </div>
          </div>

          {loadingGroups ? (
            <div className="text-gray-400">Loading channel groups...</div>
          ) : channelGroups?.length ? (
            <div className="space-y-4">
              {channelGroups.map((group) => (
                <ChannelGroupCard
                  key={group.id}
                  group={group}
                  channels={channelsData || []}
                  onEdit={() => setEditingGroup(group)}
                  onDelete={() => {
                    if (confirm(`Delete group "${group.name}"?`)) {
                      deleteGroup.mutate(group.id)
                    }
                  }}
                  onAddMember={(channelId: number, priority: number) =>
                    addMember.mutate({ groupId: group.id, channelId, priority })
                  }
                  onUpdatePriority={(channelId: number, priority: number) =>
                    updateMemberPriority.mutate({ groupId: group.id, channelId, priority })
                  }
                  onRemoveMember={(channelId: number) =>
                    removeMember.mutate({ groupId: group.id, channelId })
                  }
                />
              ))}
            </div>
          ) : (
            <div className="text-center py-12 bg-gray-800 rounded-xl">
              <Layers className="h-12 w-12 text-gray-600 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-white mb-2">No Channel Groups</h3>
              <p className="text-gray-400 mb-4">
                Create groups to combine duplicate channels from different sources with automatic failover.
              </p>
              <button
                onClick={handleAutoDetect}
                disabled={isAutoDetecting}
                className="px-4 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-gray-600 text-white rounded-lg inline-flex items-center gap-2"
              >
                {isAutoDetecting ? (
                  <RefreshCw className="h-4 w-4 animate-spin" />
                ) : (
                  <Wand2 className="h-4 w-4" />
                )}
                Auto-Detect Duplicates
              </button>
            </div>
          )}
        </div>
      )}

      {showAddModal === 'm3u' && (
        <AddSourceModal type="m3u" onClose={() => setShowAddModal(null)} />
      )}

      {showAddModal === 'epg' && (
        <AddSourceModal type="epg" onClose={() => setShowAddModal(null)} />
      )}

      {showAddModal === 'xtream' && (
        <AddXtreamSourceModal onClose={() => setShowAddModal(null)} />
      )}

      {editingChannel && (
        <EditChannelModal
          channel={editingChannel}
          onClose={() => setEditingChannel(null)}
          epgSources={epgSources || []}
        />
      )}

      {showMapNumbersModal && (
        <MapChannelNumbersModal onClose={() => setShowMapNumbersModal(false)} />
      )}

      {editingM3USource && (
        <EditM3USourceModal
          source={editingM3USource}
          onClose={() => setEditingM3USource(null)}
        />
      )}

      {editingXtreamSource && (
        <EditXtreamSourceModal
          source={editingXtreamSource}
          onClose={() => setEditingXtreamSource(null)}
        />
      )}

      {editingEPGSource && (
        <EditEPGSourceModal
          source={editingEPGSource}
          onClose={() => setEditingEPGSource(null)}
        />
      )}

      {showCreateGroupModal && (
        <ChannelGroupModal
          onClose={() => setShowCreateGroupModal(false)}
          onSave={(data) => createGroup.mutate(data)}
          isLoading={createGroup.isPending}
        />
      )}

      {editingGroup && (
        <ChannelGroupModal
          group={editingGroup}
          onClose={() => setEditingGroup(null)}
          onSave={(data) => updateGroup.mutate({ id: editingGroup.id, data })}
          isLoading={updateGroup.isPending}
        />
      )}

      {showAutoDetectModal && autoDetectResults && (
        <AutoDetectModal
          results={autoDetectResults}
          onClose={() => {
            setShowAutoDetectModal(false)
            setAutoDetectResults(null)
          }}
          onCreateGroup={async (group) => {
            // Create the group first
            const newGroup = await api.createChannelGroup({
              name: group.name,
              displayNumber: group.channels[0]?.number || 0,
              logo: group.channels[0]?.logo,
            })
            // Then add all channels as members
            for (let i = 0; i < group.channels.length; i++) {
              await api.addChannelToGroup(newGroup.id, group.channels[i].id, i)
            }
            queryClient.invalidateQueries({ queryKey: ['channelGroups'] })
          }}
          isCreating={false}
        />
      )}
    </div>
  )
}
