import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Tv, Plus, Trash2, RefreshCw, FileText, Radio, Search, Edit, X, Check } from 'lucide-react'
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (type === 'm3u') {
      await createM3U.mutateAsync({ name, url })
    } else {
      await createEPG.mutateAsync({ name, url })
    }
    onClose()
  }

  const isPending = createM3U.isPending || createEPG.isPending

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
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
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-300 mb-2">URL</label>
            <input
              type="url"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder={type === 'm3u' ? 'http://example.com/playlist.m3u' : 'http://example.com/guide.xml'}
              required
            />
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
}: {
  channel: Channel
  onClose: () => void
}) {
  const queryClient = useQueryClient()
  const [name, setName] = useState(channel.name)
  const [number, setNumber] = useState(channel.number)
  const [logo, setLogo] = useState(channel.logo || '')
  const [group, setGroup] = useState(channel.group || '')

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
    updateChannel.mutate({ name, number, logo, group })
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
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-300 mb-2">Group</label>
            <input
              type="text"
              value={group}
              onChange={(e) => setGroup(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="Sports, News, etc."
            />
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

export function LiveTVPage() {
  const queryClient = useQueryClient()
  const { data: m3uSources, isLoading: loadingM3U } = useM3USources()
  const { data: epgSources, isLoading: loadingEPG } = useEPGSources()
  const deleteM3U = useDeleteM3USource()
  const refreshM3U = useRefreshM3USource()
  const deleteEPG = useDeleteEPGSource()
  const refreshEPG = useRefreshEPG()
  const [showAddModal, setShowAddModal] = useState<'m3u' | 'epg' | null>(null)
  const [activeTab, setActiveTab] = useState<'sources' | 'channels'>('sources')
  const [channelSearch, setChannelSearch] = useState('')
  const [editingChannel, setEditingChannel] = useState<Channel | null>(null)

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
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">Live TV</h1>
        <p className="text-gray-400 mt-1">Manage your IPTV sources, channels, and program guide</p>
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
              <div className="bg-gray-800 rounded-xl divide-y divide-gray-700">
                {epgSources.map((source) => (
                  <div key={source.id} className="p-4 flex items-center justify-between">
                    <div>
                      <h3 className="font-medium text-white">{source.name}</h3>
                      <p className="text-sm text-gray-400 truncate max-w-md">{source.url}</p>
                    </div>
                    <button
                      onClick={() => deleteEPG.mutate(source.id)}
                      className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg"
                      title="Delete"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
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
        <EditChannelModal channel={editingChannel} onClose={() => setEditingChannel(null)} />
      )}
    </div>
  )
}
