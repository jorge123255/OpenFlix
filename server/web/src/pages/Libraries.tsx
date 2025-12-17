import { useState } from 'react'
import {
  FolderOpen,
  Plus,
  Trash2,
  RefreshCw,
  Film,
  Tv,
  Music,
  Image,
  Edit2,
  ChevronDown,
  ChevronUp,
  HardDrive,
  Clock,
  FileVideo,
  X,
  FolderPlus,
  AlertCircle,
} from 'lucide-react'
import {
  useLibraries,
  useCreateLibrary,
  useDeleteLibrary,
  useScanLibrary,
  useUpdateLibrary,
  useAddLibraryPath,
  useRemoveLibraryPath,
  useLibraryStats,
} from '../hooks/useLibraries'
import { FileBrowser } from '../components/FileBrowser'
import type { Library } from '../types'

const libraryTypeIcons = {
  movie: Film,
  show: Tv,
  music: Music,
  photo: Image,
}

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`
}

function formatDuration(ms: number): string {
  const hours = Math.floor(ms / 3600000)
  const minutes = Math.floor((ms % 3600000) / 60000)
  if (hours > 0) {
    return `${hours}h ${minutes}m`
  }
  return `${minutes}m`
}

function LibraryStatsDisplay({ libraryId, type }: { libraryId: number; type: Library['type'] }) {
  const { data: stats, isLoading } = useLibraryStats(libraryId)

  if (isLoading || !stats) {
    return (
      <div className="mt-4 pt-4 border-t border-gray-700">
        <div className="text-sm text-gray-500">Loading stats...</div>
      </div>
    )
  }

  const itemCount =
    type === 'movie'
      ? stats.movieCount
      : type === 'show'
      ? stats.showCount
      : stats.movieCount + stats.showCount

  const hasNoFiles = stats.fileCount === 0
  const hasItemsButNoFiles = itemCount > 0 && hasNoFiles

  return (
    <div className="mt-4 pt-4 border-t border-gray-700">
      {hasItemsButNoFiles && (
        <div className="mb-4 flex items-start gap-2 px-4 py-3 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
          <AlertCircle className="h-5 w-5 text-yellow-500 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-medium text-yellow-500">Library needs scanning</p>
            <p className="text-xs text-yellow-500/80 mt-1">
              Media items exist but no files are indexed. Click "Scan" to index media files.
            </p>
          </div>
        </div>
      )}
      {hasNoFiles && itemCount === 0 && (
        <div className="mb-4 flex items-start gap-2 px-4 py-3 bg-blue-500/10 border border-blue-500/30 rounded-lg">
          <AlertCircle className="h-5 w-5 text-blue-500 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-medium text-blue-500">Library is empty</p>
            <p className="text-xs text-blue-500/80 mt-1">
              Add media files to your library paths and click "Scan" to index them.
            </p>
          </div>
        </div>
      )}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="flex items-center gap-2">
          <FileVideo className="h-4 w-4 text-gray-500" />
          <div>
            <div className="text-sm font-medium text-white">
              {type === 'movie' ? stats.movieCount : type === 'show' ? stats.showCount : itemCount}
            </div>
            <div className="text-xs text-gray-500">
              {type === 'movie' ? 'Movies' : type === 'show' ? 'Shows' : 'Items'}
            </div>
          </div>
        </div>
        {type === 'show' && stats.episodeCount > 0 && (
          <div className="flex items-center gap-2">
            <Film className="h-4 w-4 text-gray-500" />
            <div>
              <div className="text-sm font-medium text-white">{stats.episodeCount}</div>
              <div className="text-xs text-gray-500">Episodes</div>
            </div>
          </div>
        )}
        <div className="flex items-center gap-2">
          <HardDrive className="h-4 w-4 text-gray-500" />
          <div>
            <div className="text-sm font-medium text-white">{formatBytes(stats.totalSize)}</div>
            <div className="text-xs text-gray-500">Total Size</div>
          </div>
        </div>
        {stats.totalDuration > 0 && (
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-gray-500" />
            <div>
              <div className="text-sm font-medium text-white">
                {formatDuration(stats.totalDuration)}
              </div>
              <div className="text-xs text-gray-500">Duration</div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

function CreateLibraryModal({ onClose }: { onClose: () => void }) {
  const createLibrary = useCreateLibrary()
  const [title, setTitle] = useState('')
  const [type, setType] = useState<Library['type']>('movie')
  const [paths, setPaths] = useState<string[]>([])
  const [showBrowser, setShowBrowser] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (paths.length === 0) return
    await createLibrary.mutateAsync({
      title,
      type,
      paths,
    })
    onClose()
  }

  const handleAddPath = (path: string) => {
    if (!paths.includes(path)) {
      setPaths([...paths, path])
    }
    setShowBrowser(false)
  }

  const handleRemovePath = (path: string) => {
    setPaths(paths.filter((p) => p !== path))
  }

  if (showBrowser) {
    return <FileBrowser onSelect={handleAddPath} onCancel={() => setShowBrowser(false)} />
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <h2 className="text-lg font-semibold text-white mb-4">Create Library</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="My Movies"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Type</label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value as Library['type'])}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            >
              <option value="movie">Movies</option>
              <option value="show">TV Shows</option>
              <option value="music">Music</option>
              <option value="photo">Photos</option>
            </select>
          </div>
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-300 mb-2">Paths</label>
            <div className="space-y-2 mb-2">
              {paths.map((path) => (
                <div
                  key={path}
                  className="flex items-center gap-2 px-3 py-2 bg-gray-700/50 rounded-lg"
                >
                  <FolderOpen className="h-4 w-4 text-yellow-400 flex-shrink-0" />
                  <code className="flex-1 text-sm text-gray-300 truncate">{path}</code>
                  <button
                    type="button"
                    onClick={() => handleRemovePath(path)}
                    className="p-1 text-gray-400 hover:text-red-400"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
            <button
              type="button"
              onClick={() => setShowBrowser(true)}
              className="w-full flex items-center justify-center gap-2 px-4 py-2 border-2 border-dashed border-gray-600 hover:border-gray-500 rounded-lg text-gray-400 hover:text-gray-300"
            >
              <FolderPlus className="h-4 w-4" />
              Browse for folder
            </button>
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
              disabled={createLibrary.isPending || paths.length === 0}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-lg"
            >
              {createLibrary.isPending ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function EditLibraryModal({
  library,
  onClose,
}: {
  library: Library
  onClose: () => void
}) {
  const updateLibrary = useUpdateLibrary()
  const addPath = useAddLibraryPath()
  const removePath = useRemoveLibraryPath()
  const [title, setTitle] = useState(library.title)
  const [showBrowser, setShowBrowser] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (title !== library.title) {
      await updateLibrary.mutateAsync({ id: library.id, data: { title } })
    }
    onClose()
  }

  const handleAddPath = async (path: string) => {
    await addPath.mutateAsync({ libraryId: library.id, path })
    setShowBrowser(false)
  }

  const handleRemovePath = async (pathId: number) => {
    if (library.paths.length <= 1) {
      alert('Library must have at least one path')
      return
    }
    await removePath.mutateAsync({ libraryId: library.id, pathId })
  }

  if (showBrowser) {
    return <FileBrowser onSelect={handleAddPath} onCancel={() => setShowBrowser(false)} />
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <h2 className="text-lg font-semibold text-white mb-4">Edit Library</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Type</label>
            <div className="px-4 py-2 bg-gray-700/50 border border-gray-600 rounded-lg text-gray-400 capitalize">
              {library.type}
              <span className="text-xs ml-2">(cannot be changed)</span>
            </div>
          </div>
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-300 mb-2">Paths</label>
            <div className="space-y-2 mb-2">
              {library.paths.map((p) => (
                <div
                  key={p.id}
                  className="flex items-center gap-2 px-3 py-2 bg-gray-700/50 rounded-lg"
                >
                  <FolderOpen className="h-4 w-4 text-yellow-400 flex-shrink-0" />
                  <code className="flex-1 text-sm text-gray-300 truncate">{p.path}</code>
                  <button
                    type="button"
                    onClick={() => handleRemovePath(p.id)}
                    disabled={removePath.isPending || library.paths.length <= 1}
                    className="p-1 text-gray-400 hover:text-red-400 disabled:opacity-50"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
            <button
              type="button"
              onClick={() => setShowBrowser(true)}
              className="w-full flex items-center justify-center gap-2 px-4 py-2 border-2 border-dashed border-gray-600 hover:border-gray-500 rounded-lg text-gray-400 hover:text-gray-300"
            >
              <FolderPlus className="h-4 w-4" />
              Add another folder
            </button>
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
              disabled={updateLibrary.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {updateLibrary.isPending ? 'Saving...' : 'Save'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function LibraryCard({ library }: { library: Library }) {
  const deleteLibrary = useDeleteLibrary()
  const scanLibrary = useScanLibrary()
  const [expanded, setExpanded] = useState(false)
  const [showEdit, setShowEdit] = useState(false)

  const Icon = libraryTypeIcons[library.type] || FolderOpen

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this library? This will remove all associated metadata.')) {
      await deleteLibrary.mutateAsync(library.id)
    }
  }

  const handleScan = async () => {
    await scanLibrary.mutateAsync(library.id)
  }

  return (
    <>
      <div className="bg-gray-800 rounded-xl p-6">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-gray-700 rounded-lg">
              <Icon className="h-6 w-6 text-indigo-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-white">{library.title}</h3>
              <p className="text-sm text-gray-400 capitalize">{library.type}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowEdit(true)}
              className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg"
              title="Edit Library"
            >
              <Edit2 className="h-4 w-4" />
            </button>
            <button
              onClick={handleScan}
              disabled={scanLibrary.isPending}
              className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg"
              title="Scan Library"
            >
              <RefreshCw
                className={`h-4 w-4 ${scanLibrary.isPending ? 'animate-spin' : ''}`}
              />
            </button>
            <button
              onClick={handleDelete}
              disabled={deleteLibrary.isPending}
              className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg"
              title="Delete Library"
            >
              <Trash2 className="h-4 w-4" />
            </button>
            <button
              onClick={() => setExpanded(!expanded)}
              className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg"
              title={expanded ? 'Collapse' : 'Expand'}
            >
              {expanded ? (
                <ChevronUp className="h-4 w-4" />
              ) : (
                <ChevronDown className="h-4 w-4" />
              )}
            </button>
          </div>
        </div>

        {/* Quick stats preview */}
        <LibraryStatsDisplay libraryId={library.id} type={library.type} />

        {/* Expanded content */}
        {expanded && (
          <>
            {library.paths?.length > 0 && (
              <div className="mt-4 pt-4 border-t border-gray-700">
                <p className="text-sm text-gray-400 mb-2">Paths:</p>
                <div className="space-y-1">
                  {library.paths.map((p) => (
                    <code
                      key={p.id}
                      className="block text-sm text-gray-300 bg-gray-700/50 px-3 py-1 rounded"
                    >
                      {p.path}
                    </code>
                  ))}
                </div>
              </div>
            )}

            {library.scannedAt && (
              <p className="mt-4 text-xs text-gray-500">
                Last scanned: {new Date(library.scannedAt).toLocaleString()}
              </p>
            )}
          </>
        )}
      </div>

      {showEdit && <EditLibraryModal library={library} onClose={() => setShowEdit(false)} />}
    </>
  )
}

export function LibrariesPage() {
  const { data: libraries, isLoading } = useLibraries()
  const [showCreate, setShowCreate] = useState(false)

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Libraries</h1>
          <p className="text-gray-400 mt-1">Manage your media libraries</p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
        >
          <Plus className="h-4 w-4" />
          Add Library
        </button>
      </div>

      {isLoading ? (
        <div className="text-gray-400">Loading...</div>
      ) : libraries?.length ? (
        <div className="grid gap-4">
          {libraries.map((library) => (
            <LibraryCard key={library.id} library={library} />
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <FolderOpen className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No libraries</h3>
          <p className="text-gray-400 mb-4">Get started by adding a media library</p>
          <button
            onClick={() => setShowCreate(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
          >
            <Plus className="h-4 w-4" />
            Add Library
          </button>
        </div>
      )}

      {showCreate && <CreateLibraryModal onClose={() => setShowCreate(false)} />}
    </div>
  )
}
