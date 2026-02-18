import { useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Radio,
  Plus,
  Settings,
  RefreshCw,
  Tv,
  Film,
  FolderOpen,
  Loader,
  CheckCircle,
  XCircle,
  Search,
  Satellite,
  MonitorPlay,
  ChevronRight,
  Clapperboard,
  HardDrive,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import type { M3USource, XtreamSource, Library } from '../types'

function SettingsTabNav({ active }: { active: 'general' | 'sources' | 'advanced' }) {
  const tabs = [
    { id: 'general' as const, label: 'General', path: '/ui/settings' },
    { id: 'sources' as const, label: 'Sources', path: '/ui/settings/sources' },
    { id: 'advanced' as const, label: 'Advanced', path: '/ui/settings/advanced' },
  ]

  return (
    <div className="flex gap-1 mb-8 bg-gray-800 rounded-lg p-1 w-fit">
      {tabs.map((tab) => (
        <Link
          key={tab.id}
          to={tab.path}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            active === tab.id
              ? 'bg-indigo-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700'
          }`}
        >
          {tab.label}
        </Link>
      ))}
    </div>
  )
}

function SourceTypeIcon({ type }: { type: string }) {
  switch (type) {
    case 'm3u':
      return <Radio className="h-5 w-5 text-blue-400" />
    case 'xtream':
      return <Satellite className="h-5 w-5 text-purple-400" />
    case 'hdhr':
      return <Tv className="h-5 w-5 text-green-400" />
    case 'pluto':
      return <MonitorPlay className="h-5 w-5 text-yellow-400" />
    default:
      return <Radio className="h-5 w-5 text-gray-400" />
  }
}

function LiveTVSourcesSection() {
  const queryClient = useQueryClient()
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [addType, setAddType] = useState<'m3u' | 'xtream' | null>(null)
  const [newSourceName, setNewSourceName] = useState('')
  const [newSourceUrl, setNewSourceUrl] = useState('')

  const { data: m3uSources, isLoading: m3uLoading } = useQuery({
    queryKey: ['m3uSources'],
    queryFn: () => api.getM3USources(),
  })

  const { data: xtreamSources, isLoading: xtreamLoading } = useQuery({
    queryKey: ['xtreamSources'],
    queryFn: () => api.getXtreamSources(),
  })

  const addM3USource = useMutation({
    mutationFn: (data: { name: string; url: string }) => api.createM3USource(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['m3uSources'] })
      setShowAddDialog(false)
      setAddType(null)
      setNewSourceName('')
      setNewSourceUrl('')
    },
  })

  const refreshM3U = useMutation({
    mutationFn: (id: number) => api.refreshM3USource(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['m3uSources'] })
    },
  })

  const deleteM3U = useMutation({
    mutationFn: (id: number) => api.deleteM3USource(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['m3uSources'] })
    },
  })

  const deleteXtream = useMutation({
    mutationFn: (id: number) => api.deleteXtreamSource(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['xtreamSources'] })
    },
  })

  const refreshXtream = useMutation({
    mutationFn: (id: number) => api.refreshXtreamSource(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['xtreamSources'] })
    },
  })

  const isLoading = m3uLoading || xtreamLoading
  const allSources: Array<{ type: 'm3u' | 'xtream'; source: M3USource | XtreamSource }> = [
    ...(m3uSources || []).map((s) => ({ type: 'm3u' as const, source: s })),
    ...(xtreamSources || []).map((s) => ({ type: 'xtream' as const, source: s })),
  ]

  const handleAddSource = () => {
    if (addType === 'm3u' && newSourceName && newSourceUrl) {
      addM3USource.mutate({ name: newSourceName, url: newSourceUrl })
    }
  }

  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-lg font-semibold text-white flex items-center gap-2">
            <Tv className="h-5 w-5 text-blue-400" />
            Live TV Sources
          </h2>
          <p className="text-sm text-gray-400 mt-1">
            Manage M3U playlists, Xtream Codes, HDHomeRun tuners, and other live TV sources
          </p>
        </div>
        <button
          onClick={() => setShowAddDialog(!showAddDialog)}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm"
        >
          <Plus className="h-4 w-4" />
          Add Source
        </button>
      </div>

      {/* Add Source Dialog */}
      {showAddDialog && (
        <div className="mb-6 p-4 bg-gray-900 rounded-lg border border-gray-700">
          <h3 className="text-sm font-medium text-white mb-3">Add a New Source</h3>
          {!addType ? (
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <button
                onClick={() => setAddType('m3u')}
                className="flex items-center gap-3 p-3 bg-gray-800 hover:bg-gray-700 rounded-lg border border-gray-600 text-left"
              >
                <Radio className="h-5 w-5 text-blue-400" />
                <div>
                  <div className="text-sm font-medium text-white">M3U URL</div>
                  <div className="text-xs text-gray-500">Add an M3U/M3U8 playlist URL</div>
                </div>
              </button>
              <button
                onClick={() => setAddType('xtream')}
                className="flex items-center gap-3 p-3 bg-gray-800 hover:bg-gray-700 rounded-lg border border-gray-600 text-left"
              >
                <Satellite className="h-5 w-5 text-purple-400" />
                <div>
                  <div className="text-sm font-medium text-white">Xtream Codes</div>
                  <div className="text-xs text-gray-500">Xtream-compatible provider</div>
                </div>
              </button>
              <Link
                to="/ui/tuners"
                className="flex items-center gap-3 p-3 bg-gray-800 hover:bg-gray-700 rounded-lg border border-gray-600 text-left"
              >
                <Tv className="h-5 w-5 text-green-400" />
                <div>
                  <div className="text-sm font-medium text-white">HDHomeRun</div>
                  <div className="text-xs text-gray-500">Manage tuner devices</div>
                </div>
              </Link>
            </div>
          ) : addType === 'm3u' ? (
            <div className="space-y-3">
              <div>
                <label className="block text-xs text-gray-400 mb-1">Source Name</label>
                <input
                  type="text"
                  value={newSourceName}
                  onChange={(e) => setNewSourceName(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  placeholder="My IPTV Provider"
                />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">M3U URL</label>
                <input
                  type="text"
                  value={newSourceUrl}
                  onChange={(e) => setNewSourceUrl(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  placeholder="http://example.com/playlist.m3u"
                />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={handleAddSource}
                  disabled={addM3USource.isPending || !newSourceName || !newSourceUrl}
                  className="flex items-center gap-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white text-sm rounded-lg"
                >
                  {addM3USource.isPending ? <Loader className="h-3.5 w-3.5 animate-spin" /> : <Plus className="h-3.5 w-3.5" />}
                  {addM3USource.isPending ? 'Adding...' : 'Add Source'}
                </button>
                <button
                  onClick={() => { setAddType(null); setNewSourceName(''); setNewSourceUrl('') }}
                  className="px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-sm rounded-lg"
                >
                  Cancel
                </button>
              </div>
            </div>
          ) : (
            <div className="space-y-3">
              <p className="text-sm text-gray-400">
                To add an Xtream Codes source, go to the dedicated Xtream management page in Live TV.
              </p>
              <div className="flex gap-2">
                <Link
                  to="/ui/livetv"
                  className="flex items-center gap-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg"
                >
                  Go to Live TV
                  <ChevronRight className="h-3.5 w-3.5" />
                </Link>
                <button
                  onClick={() => setAddType(null)}
                  className="px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-sm rounded-lg"
                >
                  Cancel
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Sources List */}
      {isLoading ? (
        <div className="flex items-center gap-2 text-gray-400 py-8 justify-center">
          <Loader className="h-5 w-5 animate-spin" />
          Loading sources...
        </div>
      ) : allSources.length === 0 ? (
        <div className="text-center py-8">
          <Radio className="h-8 w-8 text-gray-600 mx-auto mb-3" />
          <p className="text-gray-400">No live TV sources configured</p>
          <p className="text-sm text-gray-500 mt-1">Add an M3U URL or Xtream Codes provider to get started</p>
        </div>
      ) : (
        <div className="space-y-3">
          {allSources.map(({ type, source }) => (
            <div
              key={`${type}-${source.id}`}
              className="flex items-center justify-between p-4 bg-gray-900 rounded-lg border border-gray-700"
            >
              <div className="flex items-center gap-3">
                <SourceTypeIcon type={type} />
                <div>
                  <div className="text-sm font-medium text-white">{source.name}</div>
                  <div className="flex items-center gap-3 mt-1">
                    <span className="text-xs text-gray-500 uppercase">{type === 'm3u' ? 'M3U' : 'Xtream'}</span>
                    <span className="text-xs text-gray-400">
                      {source.channelCount} channel{source.channelCount !== 1 ? 's' : ''}
                    </span>
                    {type === 'm3u' && (source as M3USource).lastRefresh && (
                      <span className="text-xs text-gray-500">
                        Last refresh: {new Date((source as M3USource).lastRefresh!).toLocaleDateString()}
                      </span>
                    )}
                    {'enabled' in source && (
                      <span className={`flex items-center gap-1 text-xs ${source.enabled ? 'text-green-400' : 'text-gray-500'}`}>
                        {source.enabled ? (
                          <><CheckCircle className="h-3 w-3" /> Enabled</>
                        ) : (
                          <><XCircle className="h-3 w-3" /> Disabled</>
                        )}
                      </span>
                    )}
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => {
                    if (type === 'm3u') refreshM3U.mutate(source.id)
                    else refreshXtream.mutate(source.id)
                  }}
                  className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg"
                  title="Refresh"
                >
                  <RefreshCw className="h-4 w-4" />
                </button>
                <Link
                  to="/ui/livetv"
                  className="px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
                >
                  Manage
                </Link>
                <button
                  onClick={() => {
                    if (confirm('Are you sure you want to delete this source?')) {
                      if (type === 'm3u') deleteM3U.mutate(source.id)
                      else deleteXtream.mutate(source.id)
                    }
                  }}
                  className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg"
                  title="Delete"
                >
                  <XCircle className="h-4 w-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function PersonalMediaSection() {
  const queryClient = useQueryClient()

  const { data: libraries, isLoading } = useQuery({
    queryKey: ['libraries'],
    queryFn: () => api.getLibraries(),
  })

  const scanLibrary = useMutation({
    mutationFn: (id: number) => api.scanLibrary(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
    },
  })

  // Group libraries by type
  const movieLibraries = (libraries || []).filter((l: Library) => l.type === 'movie')
  const showLibraries = (libraries || []).filter((l: Library) => l.type === 'show')
  const otherLibraries = (libraries || []).filter((l: Library) => l.type !== 'movie' && l.type !== 'show')

  const libraryGroups = [
    { title: 'Movies', icon: <Film className="h-4 w-4 text-yellow-400" />, libraries: movieLibraries },
    { title: 'TV Shows', icon: <Clapperboard className="h-4 w-4 text-blue-400" />, libraries: showLibraries },
    { title: 'Other', icon: <HardDrive className="h-4 w-4 text-gray-400" />, libraries: otherLibraries },
  ].filter((g) => g.libraries.length > 0)

  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-lg font-semibold text-white flex items-center gap-2">
            <FolderOpen className="h-5 w-5 text-green-400" />
            Personal Media
          </h2>
          <p className="text-sm text-gray-400 mt-1">
            Library folders for movies, TV shows, and other personal media
          </p>
        </div>
        <Link
          to="/ui/libraries"
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm"
        >
          <Settings className="h-4 w-4" />
          Manage Libraries
        </Link>
      </div>

      {isLoading ? (
        <div className="flex items-center gap-2 text-gray-400 py-8 justify-center">
          <Loader className="h-5 w-5 animate-spin" />
          Loading libraries...
        </div>
      ) : (libraries || []).length === 0 ? (
        <div className="text-center py-8">
          <FolderOpen className="h-8 w-8 text-gray-600 mx-auto mb-3" />
          <p className="text-gray-400">No libraries configured</p>
          <p className="text-sm text-gray-500 mt-1">Add movie and TV show folders to get started</p>
          <Link
            to="/ui/libraries"
            className="inline-flex items-center gap-2 mt-4 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm"
          >
            <Plus className="h-4 w-4" />
            Add Library
          </Link>
        </div>
      ) : (
        <div className="space-y-6">
          {libraryGroups.map((group) => (
            <div key={group.title}>
              <h3 className="text-sm font-medium text-gray-300 flex items-center gap-2 mb-3">
                {group.icon}
                {group.title}
              </h3>
              <div className="space-y-2">
                {group.libraries.map((lib: Library) => (
                  <div
                    key={lib.id}
                    className="flex items-center justify-between p-3 bg-gray-900 rounded-lg border border-gray-700"
                  >
                    <div className="flex items-center gap-3">
                      <FolderOpen className="h-4 w-4 text-gray-500" />
                      <div>
                        <div className="text-sm font-medium text-white">{lib.title}</div>
                        <div className="text-xs text-gray-500 mt-0.5">
                          {lib.paths && lib.paths.length > 0 ? (
                            lib.paths.map((p) => p.path).join(', ')
                          ) : (
                            'No paths configured'
                          )}
                        </div>
                        {lib.scannedAt && (
                          <div className="text-xs text-gray-500 mt-0.5">
                            Last scanned: {new Date(lib.scannedAt).toLocaleDateString()}
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => scanLibrary.mutate(lib.id)}
                        disabled={scanLibrary.isPending}
                        className="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 text-white rounded-lg"
                        title="Scan library"
                      >
                        {scanLibrary.isPending ? (
                          <Loader className="h-3.5 w-3.5 animate-spin" />
                        ) : (
                          <Search className="h-3.5 w-3.5" />
                        )}
                        Scan
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export function SettingsSourcesPage() {
  return (
    <div>
      <div className="mb-2">
        <h1 className="text-2xl font-bold text-white">Settings</h1>
        <p className="text-gray-400 mt-1">Manage your content sources</p>
      </div>

      <SettingsTabNav active="sources" />

      <LiveTVSourcesSection />
      <PersonalMediaSection />
    </div>
  )
}
