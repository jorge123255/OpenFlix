import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Tv, Plus, Trash2, RefreshCw, FileText, Radio, Search, Edit, X, Check, Settings } from 'lucide-react'
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
import { api } from '../api/client'

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

  const handlePreview = async () => {
    if (!gracenotePostalCode && !gracenoteAffiliate) {
      setPreviewError('Please enter a postal code')
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
      // Auto-fill affiliate if it was detected
      if (response.affiliate && !gracenoteAffiliate) {
        setGracenoteAffiliate(response.affiliate)
      }
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
          setPreviewError('Please click "Preview Channels" to auto-detect affiliate ID')
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
              {/* Step 1: Postal Code - Primary input for auto-detection */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Postal Code <span className="text-red-400">*</span>
                </label>
                <input
                  type="text"
                  value={gracenotePostalCode}
                  onChange={(e) => setGracenotePostalCode(e.target.value)}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                  placeholder="10001"
                  required
                />
                <p className="text-xs text-gray-500 mt-1">
                  Enter your ZIP code to auto-detect channels for your area
                </p>
              </div>

              {/* Step 2: Preview Button - Click to discover channels */}
              <div className="mb-4">
                <button
                  type="button"
                  onClick={handlePreview}
                  disabled={isPreviewing || (!gracenotePostalCode && !gracenoteAffiliate)}
                  className="w-full py-2 px-4 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-lg flex items-center justify-center gap-2"
                >
                  {isPreviewing ? (
                    <>
                      <RefreshCw className="h-4 w-4 animate-spin" />
                      Loading Preview...
                    </>
                  ) : (
                    <>
                      <Search className="h-4 w-4" />
                      Preview Channels
                    </>
                  )}
                </button>
                {previewError && (
                  <p className="text-sm text-red-400 mt-2">{previewError}</p>
                )}
              </div>

              {/* Preview Results */}
              {preview && (
                <div className="mb-4 p-4 bg-gray-700/50 rounded-lg border border-gray-600">
                  <div className="flex items-center gap-2 mb-3">
                    <Check className="h-5 w-5 text-green-400" />
                    <h3 className="text-sm font-semibold text-white">
                      Found {preview.totalChannels} channels
                    </h3>
                  </div>
                  <div className="text-xs text-gray-400 mb-3">
                    <p>Affiliate: <span className="text-white font-mono">{preview.affiliate}</span></p>
                    <p>Programs: {preview.totalPrograms}</p>
                  </div>
                  <div className="max-h-48 overflow-y-auto space-y-1">
                    <p className="text-xs text-gray-500 mb-2">Sample channels:</p>
                    {preview.previewChannels?.map((ch: any, idx: number) => (
                      <div key={idx} className="flex items-center gap-2 text-xs text-gray-300 py-1">
                        <span className="font-medium text-white">{ch.callSign || ch.channelId}</span>
                        {ch.channelNo && <span className="text-gray-500">Ch {ch.channelNo}</span>}
                        {ch.affiliateName && <span className="text-gray-400">• {ch.affiliateName}</span>}
                      </div>
                    ))}
                    {preview.totalChannels > preview.previewChannels?.length && (
                      <p className="text-xs text-gray-500 mt-2">
                        ... and {preview.totalChannels - preview.previewChannels.length} more channels
                      </p>
                    )}
                  </div>
                </div>
              )}

              {/* Step 3: Advanced Settings (shown after preview or optional) */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Affiliate ID {preview && <span className="text-xs text-gray-500">(auto-detected)</span>}
                </label>
                <input
                  type="text"
                  value={gracenoteAffiliate}
                  onChange={(e) => setGracenoteAffiliate(e.target.value)}
                  className={`w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white ${
                    preview ? 'border-green-500' : ''
                  }`}
                  placeholder="Will be auto-detected from postal code"
                  readOnly={!!preview && !!preview.affiliate}
                />
                <p className="text-xs text-gray-500 mt-1">
                  {preview
                    ? 'Auto-detected from your postal code'
                    : 'Click "Preview Channels" to auto-detect'
                  }
                </p>
              </div>

              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Hours of Guide Data
                </label>
                <input
                  type="number"
                  value={gracenoteHours}
                  onChange={(e) => setGracenoteHours(parseInt(e.target.value) || 6)}
                  min="1"
                  max="24"
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                />
                <p className="text-xs text-gray-500 mt-1">1-24 hours (default: 6)</p>
              </div>
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

export function LiveTVPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { data: m3uSources, isLoading: loadingM3U } = useM3USources()
  const { data: epgSources, isLoading: loadingEPG } = useEPGSources()
  const deleteM3U = useDeleteM3USource()
  const refreshM3U = useRefreshM3USource()
  const deleteEPG = useDeleteEPGSource()
  const refreshEPG = useRefreshEPG()
  const [showAddModal, setShowAddModal] = useState<'m3u' | 'epg' | null>(null)
  const [activeTab, setActiveTab] = useState<'sources' | 'channels' | 'programs'>('sources')
  const [channelSearch, setChannelSearch] = useState('')
  const [editingChannel, setEditingChannel] = useState<Channel | null>(null)
  const [refreshingEPGId, setRefreshingEPGId] = useState<number | null>(null)

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

  const filteredChannels = channelsData?.filter(
    (ch) =>
      ch.name.toLowerCase().includes(channelSearch.toLowerCase()) ||
      ch.channelId.toLowerCase().includes(channelSearch.toLowerCase()) ||
      (ch.group && ch.group.toLowerCase().includes(channelSearch.toLowerCase()))
  )

  const enabledCount = channelsData?.filter((ch) => ch.enabled).length || 0
  const totalCount = channelsData?.length || 0

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
          {/* Search */}
          <div className="mb-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search channels..."
                value={channelSearch}
                onChange={(e) => setChannelSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400"
              />
            </div>
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

      {showAddModal && (
        <AddSourceModal type={showAddModal} onClose={() => setShowAddModal(null)} />
      )}

      {editingChannel && (
        <EditChannelModal
          channel={editingChannel}
          onClose={() => setEditingChannel(null)}
          epgSources={epgSources || []}
        />
      )}
    </div>
  )
}
