import { useState, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  ListMusic,
  Plus,
  Trash2,
  Edit,
  Loader,
  X,
  Search,
  GripVertical,
  Film,
  Tv,
  Clock,
} from 'lucide-react'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface Playlist {
  ID: number
  ratingKey: number
  guid: string
  title: string
  summary: string
  playlistType: string
  smart: boolean
  leafCount: number
  duration: number
  addedAt: string
  updatedAt: string
}

interface PlaylistItem {
  id: number
  playlistId: number
  mediaId: number
  position: number
  title: string
  type: string
  year?: number
  thumb?: string
  duration?: number
  summary?: string
}

interface PlaylistDetail {
  playlist: Playlist
  items: PlaylistItem[]
}

// ---------------------------------------------------------------------------
// API helpers
// ---------------------------------------------------------------------------

const getAuthHeaders = (): Record<string, string> => ({
  'X-Plex-Token': localStorage.getItem('openflix_token') || '',
  'Content-Type': 'application/json',
})

async function fetchPlaylists(): Promise<Playlist[]> {
  const res = await fetch('/api/playlists', { headers: getAuthHeaders() })
  if (!res.ok) throw new Error('Failed to fetch playlists')
  const data = await res.json()
  return data.playlists || []
}

async function fetchPlaylist(id: number): Promise<PlaylistDetail> {
  const res = await fetch(`/api/playlists/${id}`, { headers: getAuthHeaders() })
  if (!res.ok) throw new Error('Failed to fetch playlist')
  return res.json()
}

async function createPlaylist(body: { name: string; description: string }): Promise<Playlist> {
  const res = await fetch('/api/playlists', {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to create playlist')
  return res.json()
}

async function updatePlaylist(id: number, body: { name?: string; description?: string }): Promise<Playlist> {
  const res = await fetch(`/api/playlists/${id}`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to update playlist')
  return res.json()
}

async function deletePlaylist(id: number): Promise<void> {
  const res = await fetch(`/api/playlists/${id}`, {
    method: 'DELETE',
    headers: getAuthHeaders(),
  })
  if (!res.ok) throw new Error('Failed to delete playlist')
}

async function removePlaylistItem(playlistId: number, itemId: number): Promise<void> {
  const res = await fetch(`/api/playlists/${playlistId}/items/${itemId}`, {
    method: 'DELETE',
    headers: getAuthHeaders(),
  })
  if (!res.ok) throw new Error('Failed to remove item')
}

async function reorderPlaylistItems(playlistId: number, itemIds: number[]): Promise<void> {
  const res = await fetch(`/api/playlists/${playlistId}/items/reorder`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify({ itemIds }),
  })
  if (!res.ok) throw new Error('Failed to reorder items')
}

async function addItemsToPlaylist(playlistId: number, mediaIds: number[]): Promise<void> {
  const res = await fetch(`/api/playlists/${playlistId}/items`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ mediaIds }),
  })
  if (!res.ok) throw new Error('Failed to add items')
}

async function searchMedia(query: string): Promise<PlaylistItem[]> {
  const res = await fetch(`/api/search?query=${encodeURIComponent(query)}&limit=20`, {
    headers: getAuthHeaders(),
  })
  if (!res.ok) return []
  const data = await res.json()
  // The search API returns results in various formats; normalize them
  const results = data.results || data.items || []
  return results.map((r: Record<string, unknown>) => ({
    id: 0,
    playlistId: 0,
    mediaId: (r.ratingKey || r.id || r.mediaId) as number,
    position: 0,
    title: (r.title || '') as string,
    type: (r.type || '') as string,
    year: (r.year || 0) as number,
    thumb: (r.thumb || '') as string,
    duration: (r.duration || 0) as number,
  }))
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function formatDuration(ms: number): string {
  if (!ms) return ''
  const minutes = Math.floor(ms / 60000)
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0) return `${hours}h ${mins}m`
  return `${mins}m`
}

function getTypeIcon(type: string) {
  switch (type) {
    case 'movie':
      return <Film className="h-4 w-4 text-blue-400" />
    case 'show':
    case 'episode':
      return <Tv className="h-4 w-4 text-green-400" />
    default:
      return <Film className="h-4 w-4 text-gray-400" />
  }
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function PlaylistsPage() {
  const queryClient = useQueryClient()
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [showCreateDialog, setShowCreateDialog] = useState(false)
  const [editingPlaylist, setEditingPlaylist] = useState<Playlist | null>(null)
  const [showAddItems, setShowAddItems] = useState(false)
  const [addSearchQuery, setAddSearchQuery] = useState('')
  const [dragIndex, setDragIndex] = useState<number | null>(null)

  // Queries
  const { data: playlists = [], isLoading } = useQuery({
    queryKey: ['admin-playlists'],
    queryFn: fetchPlaylists,
  })

  const { data: playlistDetail, isLoading: isLoadingDetail } = useQuery({
    queryKey: ['admin-playlist', selectedId],
    queryFn: () => fetchPlaylist(selectedId!),
    enabled: !!selectedId,
  })

  const { data: searchResults = [] } = useQuery({
    queryKey: ['media-search', addSearchQuery],
    queryFn: () => searchMedia(addSearchQuery),
    enabled: showAddItems && addSearchQuery.length >= 2,
  })

  // Mutations
  const createMutation = useMutation({
    mutationFn: createPlaylist,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-playlists'] })
      setShowCreateDialog(false)
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: { name?: string; description?: string } }) =>
      updatePlaylist(id, body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-playlists'] })
      queryClient.invalidateQueries({ queryKey: ['admin-playlist', selectedId] })
      setEditingPlaylist(null)
    },
  })

  const deleteMutation = useMutation({
    mutationFn: deletePlaylist,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-playlists'] })
      setSelectedId(null)
    },
  })

  const removeItemMutation = useMutation({
    mutationFn: ({ playlistId, itemId }: { playlistId: number; itemId: number }) =>
      removePlaylistItem(playlistId, itemId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-playlist', selectedId] })
      queryClient.invalidateQueries({ queryKey: ['admin-playlists'] })
    },
  })

  const reorderMutation = useMutation({
    mutationFn: ({ playlistId, itemIds }: { playlistId: number; itemIds: number[] }) =>
      reorderPlaylistItems(playlistId, itemIds),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-playlist', selectedId] })
    },
  })

  const addItemsMutation = useMutation({
    mutationFn: ({ playlistId, mediaIds }: { playlistId: number; mediaIds: number[] }) =>
      addItemsToPlaylist(playlistId, mediaIds),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-playlist', selectedId] })
      queryClient.invalidateQueries({ queryKey: ['admin-playlists'] })
      setShowAddItems(false)
      setAddSearchQuery('')
    },
  })

  // Drag and drop
  const handleDragStart = useCallback((index: number) => {
    setDragIndex(index)
  }, [])

  const handleDragOver = useCallback((e: React.DragEvent, index: number) => {
    e.preventDefault()
    if (dragIndex === null || dragIndex === index) return
    // Visual feedback handled by CSS
  }, [dragIndex])

  const handleDrop = useCallback(
    (index: number) => {
      if (dragIndex === null || !playlistDetail?.items) return
      const items = [...playlistDetail.items]
      const [moved] = items.splice(dragIndex, 1)
      items.splice(index, 0, moved)
      const itemIds = items.map((it) => it.id)
      reorderMutation.mutate({ playlistId: selectedId!, itemIds })
      setDragIndex(null)
    },
    [dragIndex, playlistDetail, selectedId, reorderMutation]
  )

  const filteredPlaylists = playlists.filter((p) =>
    p.title.toLowerCase().includes(searchQuery.toLowerCase())
  )

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader className="h-8 w-8 animate-spin text-indigo-500" />
      </div>
    )
  }

  // Empty state
  if (playlists.length === 0 && !showCreateDialog) {
    return (
      <div className="flex flex-col items-center justify-center h-96 text-center">
        <ListMusic className="h-16 w-16 text-gray-600 mb-4" />
        <h2 className="text-2xl font-bold text-white mb-2">Create a Playlist</h2>
        <p className="text-gray-400 max-w-md mb-6">
          Playlists let you create a list of movies, episodes, and videos from your library.
        </p>
        <button
          onClick={() => setShowCreateDialog(true)}
          className="px-6 py-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
        >
          Create Playlist
        </button>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Playlists</h1>
          <p className="text-sm text-gray-400 mt-1">
            Create and manage playlists of movies, episodes, and videos from your library.
          </p>
        </div>
      </div>

      <div className="flex gap-6 h-[calc(100vh-200px)]">
        {/* Left panel - Playlist list */}
        <div className="w-80 flex-shrink-0 bg-gray-800 rounded-lg border border-gray-700 flex flex-col">
          {/* Search and create */}
          <div className="p-3 border-b border-gray-700 space-y-2">
            <div className="flex gap-2">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search playlists..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <button
                onClick={() => setShowCreateDialog(true)}
                className="p-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors"
                title="Create playlist"
              >
                <Plus className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* Playlist list */}
          <div className="flex-1 overflow-y-auto">
            {filteredPlaylists.map((playlist) => (
              <button
                key={playlist.ID}
                onClick={() => setSelectedId(playlist.ID)}
                className={`w-full text-left px-4 py-3 border-b border-gray-700/50 transition-colors ${
                  selectedId === playlist.ID
                    ? 'bg-indigo-600/20 border-l-2 border-l-indigo-500'
                    : 'hover:bg-gray-700/50'
                }`}
              >
                <div className="font-medium text-white text-sm truncate">{playlist.title}</div>
                <div className="text-xs text-gray-400 mt-1">
                  {playlist.leafCount} {playlist.leafCount === 1 ? 'item' : 'items'}
                </div>
              </button>
            ))}
            {filteredPlaylists.length === 0 && (
              <div className="p-4 text-center text-gray-500 text-sm">
                {searchQuery ? 'No playlists match your search' : 'No playlists yet'}
              </div>
            )}
          </div>
        </div>

        {/* Right panel - Playlist detail */}
        <div className="flex-1 bg-gray-800 rounded-lg border border-gray-700 flex flex-col overflow-hidden">
          {!selectedId ? (
            <div className="flex-1 flex items-center justify-center text-gray-500">
              <div className="text-center">
                <ListMusic className="h-12 w-12 mx-auto mb-3 text-gray-600" />
                <p className="text-sm">Select a playlist to view its contents</p>
              </div>
            </div>
          ) : isLoadingDetail ? (
            <div className="flex-1 flex items-center justify-center">
              <Loader className="h-6 w-6 animate-spin text-indigo-500" />
            </div>
          ) : playlistDetail ? (
            <>
              {/* Playlist header */}
              <div className="p-4 border-b border-gray-700 flex items-start justify-between">
                <div className="flex-1 min-w-0">
                  <h2 className="text-lg font-semibold text-white truncate">
                    {playlistDetail.playlist.title}
                  </h2>
                  {playlistDetail.playlist.summary && (
                    <p className="text-sm text-gray-400 mt-1">{playlistDetail.playlist.summary}</p>
                  )}
                  <p className="text-xs text-gray-500 mt-1">
                    {playlistDetail.items.length} {playlistDetail.items.length === 1 ? 'item' : 'items'}
                  </p>
                </div>
                <div className="flex gap-2 ml-4">
                  <button
                    onClick={() => setShowAddItems(true)}
                    className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors flex items-center gap-1"
                  >
                    <Plus className="h-3.5 w-3.5" />
                    Add Items
                  </button>
                  <button
                    onClick={() => setEditingPlaylist(playlistDetail.playlist)}
                    className="p-1.5 text-gray-400 hover:text-white transition-colors"
                    title="Edit playlist"
                  >
                    <Edit className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => {
                      if (confirm('Delete this playlist?')) {
                        deleteMutation.mutate(selectedId)
                      }
                    }}
                    className="p-1.5 text-gray-400 hover:text-red-400 transition-colors"
                    title="Delete playlist"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Items list */}
              <div className="flex-1 overflow-y-auto">
                {playlistDetail.items.length === 0 ? (
                  <div className="p-8 text-center text-gray-500">
                    <p className="text-sm">This playlist is empty.</p>
                    <button
                      onClick={() => setShowAddItems(true)}
                      className="mt-3 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors"
                    >
                      Add Items
                    </button>
                  </div>
                ) : (
                  <div>
                    {playlistDetail.items.map((item, index) => (
                      <div
                        key={item.id}
                        draggable
                        onDragStart={() => handleDragStart(index)}
                        onDragOver={(e) => handleDragOver(e, index)}
                        onDrop={() => handleDrop(index)}
                        className="flex items-center gap-3 px-4 py-3 border-b border-gray-700/30 hover:bg-gray-700/30 transition-colors group cursor-grab active:cursor-grabbing"
                      >
                        <GripVertical className="h-4 w-4 text-gray-600 group-hover:text-gray-400 flex-shrink-0" />
                        <span className="text-xs text-gray-500 w-6 text-right flex-shrink-0">
                          {index + 1}
                        </span>
                        {item.thumb ? (
                          <img
                            src={item.thumb}
                            alt=""
                            className="h-10 w-16 object-cover rounded flex-shrink-0 bg-gray-700"
                          />
                        ) : (
                          <div className="h-10 w-16 bg-gray-700 rounded flex items-center justify-center flex-shrink-0">
                            {getTypeIcon(item.type)}
                          </div>
                        )}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            {getTypeIcon(item.type)}
                            <span className="text-sm text-white truncate">{item.title}</span>
                          </div>
                          <div className="flex items-center gap-2 text-xs text-gray-500 mt-0.5">
                            {item.year && <span>{item.year}</span>}
                            {item.duration && (
                              <>
                                <Clock className="h-3 w-3" />
                                <span>{formatDuration(item.duration)}</span>
                              </>
                            )}
                          </div>
                        </div>
                        <button
                          onClick={() =>
                            removeItemMutation.mutate({ playlistId: selectedId, itemId: item.id })
                          }
                          className="p-1 text-gray-600 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-all"
                          title="Remove from playlist"
                        >
                          <X className="h-4 w-4" />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </>
          ) : null}
        </div>
      </div>

      {/* Create Playlist Dialog */}
      {showCreateDialog && (
        <CreateEditDialog
          title="Create Playlist"
          initialName=""
          initialDescription=""
          onSave={(name, description) => createMutation.mutate({ name, description })}
          onClose={() => setShowCreateDialog(false)}
          saving={createMutation.isPending}
        />
      )}

      {/* Edit Playlist Dialog */}
      {editingPlaylist && (
        <CreateEditDialog
          title="Edit Playlist"
          initialName={editingPlaylist.title}
          initialDescription={editingPlaylist.summary || ''}
          onSave={(name, description) =>
            updateMutation.mutate({ id: editingPlaylist.ID, body: { name, description } })
          }
          onClose={() => setEditingPlaylist(null)}
          saving={updateMutation.isPending}
        />
      )}

      {/* Add Items Dialog */}
      {showAddItems && selectedId && (
        <AddItemsDialog
          playlistId={selectedId}
          searchQuery={addSearchQuery}
          onSearchChange={setAddSearchQuery}
          searchResults={searchResults}
          onAdd={(mediaIds) =>
            addItemsMutation.mutate({ playlistId: selectedId, mediaIds })
          }
          onClose={() => {
            setShowAddItems(false)
            setAddSearchQuery('')
          }}
          adding={addItemsMutation.isPending}
        />
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Create/Edit Dialog
// ---------------------------------------------------------------------------

function CreateEditDialog({
  title,
  initialName,
  initialDescription,
  onSave,
  onClose,
  saving,
}: {
  title: string
  initialName: string
  initialDescription: string
  onSave: (name: string, description: string) => void
  onClose: () => void
  saving: boolean
}) {
  const [name, setName] = useState(initialName)
  const [description, setDescription] = useState(initialDescription)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl border border-gray-700 w-full max-w-md p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-white">{title}</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="My Playlist"
              className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
              autoFocus
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">Description</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Optional description..."
              rows={3}
              className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none resize-none"
            />
          </div>
        </div>
        <div className="flex justify-end gap-3 mt-6">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={() => onSave(name, description)}
            disabled={!name.trim() || saving}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {saving && <Loader className="h-4 w-4 animate-spin" />}
            Save
          </button>
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Add Items Dialog
// ---------------------------------------------------------------------------

function AddItemsDialog({
  playlistId: _playlistId,
  searchQuery,
  onSearchChange,
  searchResults,
  onAdd,
  onClose,
  adding,
}: {
  playlistId: number
  searchQuery: string
  onSearchChange: (q: string) => void
  searchResults: PlaylistItem[]
  onAdd: (mediaIds: number[]) => void
  onClose: () => void
  adding: boolean
}) {
  const [selected, setSelected] = useState<Set<number>>(new Set())

  const toggleItem = (mediaId: number) => {
    const next = new Set(selected)
    if (next.has(mediaId)) {
      next.delete(mediaId)
    } else {
      next.add(mediaId)
    }
    setSelected(next)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl border border-gray-700 w-full max-w-lg p-6 max-h-[80vh] flex flex-col">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-white">Add Items to Playlist</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Search your library..."
            className="w-full pl-9 pr-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
            autoFocus
          />
        </div>

        <div className="flex-1 overflow-y-auto min-h-0 border border-gray-700 rounded-lg">
          {searchQuery.length < 2 ? (
            <div className="p-8 text-center text-gray-500 text-sm">
              Type at least 2 characters to search
            </div>
          ) : searchResults.length === 0 ? (
            <div className="p-8 text-center text-gray-500 text-sm">No results found</div>
          ) : (
            searchResults.map((item) => (
              <button
                key={item.mediaId}
                onClick={() => toggleItem(item.mediaId)}
                className={`w-full flex items-center gap-3 px-4 py-3 border-b border-gray-700/30 transition-colors text-left ${
                  selected.has(item.mediaId) ? 'bg-indigo-600/20' : 'hover:bg-gray-700/50'
                }`}
              >
                <div
                  className={`h-5 w-5 rounded border flex items-center justify-center flex-shrink-0 ${
                    selected.has(item.mediaId)
                      ? 'bg-indigo-600 border-indigo-600'
                      : 'border-gray-500'
                  }`}
                >
                  {selected.has(item.mediaId) && (
                    <svg className="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                    </svg>
                  )}
                </div>
                {item.thumb ? (
                  <img src={item.thumb} alt="" className="h-8 w-12 object-cover rounded bg-gray-700 flex-shrink-0" />
                ) : (
                  <div className="h-8 w-12 bg-gray-700 rounded flex items-center justify-center flex-shrink-0">
                    {getTypeIcon(item.type)}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="text-sm text-white truncate">{item.title}</div>
                  <div className="text-xs text-gray-500">
                    {item.type} {item.year ? `(${item.year})` : ''}
                  </div>
                </div>
              </button>
            ))
          )}
        </div>

        <div className="flex items-center justify-between mt-4">
          <span className="text-sm text-gray-400">
            {selected.size} {selected.size === 1 ? 'item' : 'items'} selected
          </span>
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={() => onAdd(Array.from(selected))}
              disabled={selected.size === 0 || adding}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {adding && <Loader className="h-4 w-4 animate-spin" />}
              Add Selected
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
