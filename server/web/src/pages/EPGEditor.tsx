import { useState, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ChevronDown, ChevronRight, Save, Trash2, Search, X } from 'lucide-react'
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

interface EPGChannel {
  channelId: string
  callSign?: string
  channelNo?: string
  affiliateName?: string
  sampleTitle?: string
}

export function EPGEditorPage() {
  const queryClient = useQueryClient()
  const [selectedChannel, setSelectedChannel] = useState<Channel | null>(null)
  const [epgSourceId, setEpgSourceId] = useState<number | null>(null)
  const [epgChannelId, setEpgChannelId] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [epgSearchQuery, setEpgSearchQuery] = useState('')
  const [showEpgDropdown, setShowEpgDropdown] = useState(false)
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set(['all']))

  // Fetch channels
  const { data: channelsData } = useQuery({
    queryKey: ['channels'],
    queryFn: async () => {
      const response = await fetch('/livetv/channels', {
        headers: { 'X-Plex-Token': api.getToken() || '' },
      })
      const data = await response.json()
      return data.channels as Channel[]
    },
  })

  // Fetch EPG sources
  const { data: epgSources } = useQuery({
    queryKey: ['epgSources'],
    queryFn: async () => {
      const response = await api.getEPGSources()
      return response
    },
  })

  // Fetch available EPG channels for selected source
  const { data: epgChannels } = useQuery({
    queryKey: ['epgChannels', epgSourceId],
    queryFn: () => api.getEPGChannels(epgSourceId || undefined),
    enabled: !!epgSourceId,
  })

  // Filter and group EPG channels
  const filteredEpgChannels = useMemo(() => {
    if (!epgChannels) return []

    let filtered = epgChannels as EPGChannel[]

    // Apply search filter
    if (epgSearchQuery) {
      const query = epgSearchQuery.toLowerCase()
      filtered = filtered.filter(ch =>
        ch.channelId?.toLowerCase().includes(query) ||
        ch.callSign?.toLowerCase().includes(query) ||
        ch.affiliateName?.toLowerCase().includes(query) ||
        ch.sampleTitle?.toLowerCase().includes(query) ||
        ch.channelNo?.toLowerCase().includes(query)
      )
    }

    return filtered
  }, [epgChannels, epgSearchQuery])

  // Group EPG channels by affiliate/network
  const groupedEpgChannels = useMemo(() => {
    const groups: Record<string, EPGChannel[]> = {}

    filteredEpgChannels.forEach(ch => {
      const group = ch.affiliateName || ch.callSign || 'Other'
      if (!groups[group]) groups[group] = []
      groups[group].push(ch)
    })

    // Sort groups alphabetically
    return Object.entries(groups).sort(([a], [b]) => a.localeCompare(b))
  }, [filteredEpgChannels])

  // Fetch EPG programs for preview
  const { data: programsData } = useQuery({
    queryKey: ['epgPrograms', epgChannelId],
    queryFn: () => api.getEPGPrograms({
      channelId: epgChannelId,
      limit: 10,
    }),
    enabled: !!epgChannelId,
  })

  // Update channel mutation
  const updateChannel = useMutation({
    mutationFn: async (data: { id: number; epgSourceId: number | null; channelId: string }) => {
      const response = await fetch(`/livetv/channels/${data.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || '',
        },
        body: JSON.stringify({
          epgSourceId: data.epgSourceId ?? undefined,
          channelId: data.channelId || undefined,
        }),
      })
      if (!response.ok) throw new Error('Failed to update channel')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channels'] })
    },
  })

  // Group channels
  const groupedChannels = channelsData?.reduce((acc, channel) => {
    const group = channel.group || 'Ungrouped'
    if (!acc[group]) acc[group] = []
    acc[group].push(channel)
    return acc
  }, {} as Record<string, Channel[]>) || {}

  const handleChannelSelect = (channel: Channel) => {
    setSelectedChannel(channel)
    setEpgSourceId(channel.epgSourceId || null)
    setEpgChannelId(channel.channelId || '')
  }

  const handleSave = () => {
    if (!selectedChannel) return
    updateChannel.mutate({
      id: selectedChannel.id,
      epgSourceId,
      channelId: epgChannelId,
    })
  }

  const toggleGroup = (group: string) => {
    const newExpanded = new Set(expandedGroups)
    if (newExpanded.has(group)) {
      newExpanded.delete(group)
    } else {
      newExpanded.add(group)
    }
    setExpandedGroups(newExpanded)
  }

  return (
    <div className="flex h-screen bg-gray-900">
      {/* Left Panel - Channel List */}
      <div className="w-1/3 border-r border-gray-700 flex flex-col">
        <div className="p-4 border-b border-gray-700">
          <h1 className="text-xl font-bold text-white mb-3">EPG Editor</h1>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search channels..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-600 rounded-lg text-white placeholder-gray-400"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {Object.entries(groupedChannels).map(([group, channels]) => {
            const isExpanded = expandedGroups.has(group)
            const visibleChannels = searchQuery
              ? channels.filter(ch =>
                  ch.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                  ch.channelId.toLowerCase().includes(searchQuery.toLowerCase())
                )
              : channels

            if (visibleChannels.length === 0 && searchQuery) return null

            return (
              <div key={group}>
                <button
                  onClick={() => toggleGroup(group)}
                  className="w-full flex items-center gap-2 px-4 py-2 bg-gray-800 hover:bg-gray-750 text-white border-b border-gray-700"
                >
                  {isExpanded ? (
                    <ChevronDown className="h-4 w-4" />
                  ) : (
                    <ChevronRight className="h-4 w-4" />
                  )}
                  <span className="font-medium">{group}</span>
                  <span className="text-sm text-gray-400">({visibleChannels.length})</span>
                </button>

                {isExpanded && visibleChannels.map((channel) => (
                  <button
                    key={channel.id}
                    onClick={() => handleChannelSelect(channel)}
                    className={`w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-700 border-b border-gray-700 ${
                      selectedChannel?.id === channel.id ? 'bg-blue-600 hover:bg-blue-700' : ''
                    }`}
                  >
                    {channel.logo ? (
                      <img
                        src={channel.logo}
                        alt={channel.name}
                        className="w-10 h-10 object-contain bg-gray-800 rounded"
                      />
                    ) : (
                      <div className="w-10 h-10 bg-gray-800 rounded flex items-center justify-center text-gray-500 text-xs">
                        {channel.name.substring(0, 2)}
                      </div>
                    )}
                    <div className="flex-1 text-left">
                      <div className="text-white text-sm font-medium">{channel.name}</div>
                      <div className="text-gray-400 text-xs">
                        {channel.channelId || `Channel ${channel.number}`}
                      </div>
                    </div>
                    {channel.epgSourceId && (
                      <div className="w-2 h-2 bg-green-500 rounded-full" title="EPG mapped" />
                    )}
                  </button>
                ))}
              </div>
            )
          })}
        </div>
      </div>

      {/* Right Panel - EPG Editor */}
      <div className="flex-1 flex flex-col">
        {selectedChannel ? (
          <>
            {/* Channel Header */}
            <div className="p-6 border-b border-gray-700">
              <div className="flex items-center gap-4">
                {selectedChannel.logo ? (
                  <img
                    src={selectedChannel.logo}
                    alt={selectedChannel.name}
                    className="w-16 h-16 object-contain bg-gray-800 rounded"
                  />
                ) : (
                  <div className="w-16 h-16 bg-gray-800 rounded flex items-center justify-center text-gray-500">
                    {selectedChannel.name.substring(0, 2)}
                  </div>
                )}
                <div>
                  <h2 className="text-2xl font-bold text-white">{selectedChannel.name}</h2>
                  <p className="text-gray-400">Channel {selectedChannel.number}</p>
                </div>
              </div>
            </div>

            {/* EPG Mapping Form */}
            <div className="flex-1 overflow-y-auto p-6">
              <div className="max-w-2xl">
                {/* EPG Source Selection */}
                <div className="mb-6">
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    EPG Source
                  </label>
                  <select
                    value={epgSourceId || ''}
                    onChange={(e) => {
                      const value = e.target.value ? parseInt(e.target.value) : null
                      setEpgSourceId(value)
                      setEpgChannelId('')
                    }}
                    className="w-full px-4 py-2 bg-gray-800 border border-gray-600 rounded-lg text-white"
                  >
                    <option value="">No source selected</option>
                    {epgSources?.map((source) => (
                      <option key={source.id} value={source.id}>
                        {source.name} ({source.channelCount} channels)
                      </option>
                    ))}
                  </select>
                </div>

                {/* EPG Channel ID */}
                {epgSourceId && (
                  <>
                    <div className="mb-6">
                      <label className="block text-sm font-medium text-gray-300 mb-2">
                        EPG Channel ({filteredEpgChannels.length} channels)
                      </label>

                      {/* Search + Selected Display */}
                      <div className="flex gap-2 mb-2">
                        <div className="flex-1 relative">
                          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                          <input
                            type="text"
                            placeholder="Search EPG channels..."
                            value={epgSearchQuery}
                            onChange={(e) => {
                              setEpgSearchQuery(e.target.value)
                              setShowEpgDropdown(true)
                            }}
                            onFocus={() => setShowEpgDropdown(true)}
                            className="w-full pl-10 pr-10 py-2 bg-gray-800 border border-gray-600 rounded-lg text-white placeholder-gray-400"
                          />
                          {epgSearchQuery && (
                            <button
                              onClick={() => setEpgSearchQuery('')}
                              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
                            >
                              <X className="h-4 w-4" />
                            </button>
                          )}
                        </div>
                        <button
                          onClick={handleSave}
                          disabled={updateChannel.isPending}
                          className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg flex items-center gap-2 disabled:opacity-50"
                        >
                          <Save className="h-4 w-4" />
                          Save
                        </button>
                      </div>

                      {/* Selected Channel Display */}
                      {epgChannelId && (
                        <div className="mb-2 px-3 py-2 bg-blue-600/20 border border-blue-500/50 rounded-lg flex items-center justify-between">
                          <span className="text-blue-300 text-sm">
                            Selected: <span className="font-medium text-white">{epgChannelId}</span>
                          </span>
                          <button
                            onClick={() => setEpgChannelId('')}
                            className="text-blue-400 hover:text-blue-300"
                          >
                            <X className="h-4 w-4" />
                          </button>
                        </div>
                      )}

                      {/* EPG Channel List with Groups */}
                      {showEpgDropdown && (
                        <div className="relative">
                          <div className="absolute top-0 left-0 right-0 z-10 max-h-80 overflow-y-auto bg-gray-800 border border-gray-600 rounded-lg shadow-xl">
                            {groupedEpgChannels.length === 0 ? (
                              <div className="p-4 text-center text-gray-400">
                                {epgSearchQuery ? 'No channels match your search' : 'No EPG channels available'}
                              </div>
                            ) : (
                              groupedEpgChannels.map(([group, channels]) => (
                                <div key={group}>
                                  <div className="sticky top-0 px-3 py-2 bg-gray-700 text-xs font-semibold text-gray-300 uppercase tracking-wider">
                                    {group} ({channels.length})
                                  </div>
                                  {channels.map((ch) => (
                                    <button
                                      key={ch.channelId}
                                      onClick={() => {
                                        setEpgChannelId(ch.channelId)
                                        setShowEpgDropdown(false)
                                        setEpgSearchQuery('')
                                      }}
                                      className={`w-full px-3 py-2 text-left hover:bg-gray-700 flex items-center gap-2 ${
                                        epgChannelId === ch.channelId ? 'bg-blue-600/30' : ''
                                      }`}
                                    >
                                      <div className="flex-1 min-w-0">
                                        <div className="text-white text-sm font-medium truncate">
                                          {ch.callSign || ch.channelId}
                                          {ch.channelNo && <span className="text-gray-400 ml-1">(#{ch.channelNo})</span>}
                                        </div>
                                        {ch.sampleTitle && (
                                          <div className="text-gray-400 text-xs truncate">
                                            {ch.sampleTitle}
                                          </div>
                                        )}
                                      </div>
                                    </button>
                                  ))}
                                </div>
                              ))
                            )}
                          </div>
                          {/* Click outside to close */}
                          <div
                            className="fixed inset-0 z-0"
                            onClick={() => setShowEpgDropdown(false)}
                          />
                        </div>
                      )}

                      <p className="text-xs text-gray-500 mt-1">
                        Search and select the EPG channel that matches this stream
                      </p>
                    </div>

                    {/* EPG Program Preview */}
                    {epgChannelId && programsData && programsData.programs.length > 0 && (
                      <div className="mb-6">
                        <h3 className="text-sm font-medium text-gray-300 mb-3">
                          EPG Program Preview
                        </h3>
                        <div className="bg-gray-800 rounded-lg border border-gray-700 divide-y divide-gray-700">
                          {programsData.programs.slice(0, 5).map((program) => {
                            const start = new Date(program.start)
                            const end = new Date(program.end)
                            const now = new Date()
                            const isLive = start <= now && end > now

                            return (
                              <div key={program.id} className="p-4">
                                <div className="flex items-start justify-between mb-1">
                                  <div className="flex items-center gap-2">
                                    <h4 className="font-medium text-white">{program.title}</h4>
                                    {isLive && (
                                      <span className="px-2 py-0.5 bg-red-600 text-white text-xs rounded">
                                        LIVE
                                      </span>
                                    )}
                                  </div>
                                  <span className="text-sm text-gray-400">
                                    {start.toLocaleTimeString([], {
                                      hour: '2-digit',
                                      minute: '2-digit',
                                    })}{' '}
                                    -{' '}
                                    {end.toLocaleTimeString([], {
                                      hour: '2-digit',
                                      minute: '2-digit',
                                    })}
                                  </span>
                                </div>
                                {program.description && (
                                  <p className="text-sm text-gray-400 line-clamp-2">
                                    {program.description}
                                  </p>
                                )}
                                {program.category && (
                                  <span className="inline-block mt-2 px-2 py-1 bg-gray-700 text-gray-300 text-xs rounded">
                                    {program.category}
                                  </span>
                                )}
                              </div>
                            )
                          })}
                        </div>
                      </div>
                    )}
                  </>
                )}

                {/* Clear Mapping */}
                {selectedChannel.epgSourceId && (
                  <button
                    onClick={() => {
                      if (confirm('Remove EPG mapping for this channel?')) {
                        updateChannel.mutate({
                          id: selectedChannel.id,
                          epgSourceId: null,
                          channelId: '',
                        })
                      }
                    }}
                    className="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg"
                  >
                    <Trash2 className="h-4 w-4" />
                    Remove EPG Mapping
                  </button>
                )}
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            <div className="text-center">
              <Search className="h-16 w-16 mx-auto mb-4 text-gray-600" />
              <p className="text-lg">Select a channel to edit EPG mapping</p>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
