import { Link } from 'react-router-dom'
import {
  Plus,
  Settings,
  FolderOpen,
  Loader,
  Search,
  Film,
  Clapperboard,
  HardDrive,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import type { Library } from '../types'

function SettingsTabNav({ active }: { active: 'general' | 'sources' | 'livetv-dvr' | 'advanced' | 'status' }) {
  const tabs = [
    { id: 'general' as const, label: 'General', path: '/ui/settings' },
    { id: 'sources' as const, label: 'Sources', path: '/ui/settings/sources' },
    { id: 'livetv-dvr' as const, label: 'Live TV & DVR', path: '/ui/settings/livetv-dvr' },
    { id: 'advanced' as const, label: 'Advanced', path: '/ui/settings/advanced' },
    { id: 'status' as const, label: 'Status', path: '/ui/settings/status' },
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

      <PersonalMediaSection />
    </div>
  )
}
