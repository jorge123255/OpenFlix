import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import {
  Search,
  Film,
  Tv,
  RefreshCw,
  Edit,
  ChevronDown,
  ChevronUp,
  X,
  Check,
  AlertCircle,
} from 'lucide-react'

interface MediaItem {
  id: number
  uuid: string
  type: string
  title: string
  sort_title: string
  original_title?: string
  year?: number
  thumb?: string
  art?: string
  summary?: string
  rating?: number
  content_rating?: string
  studio?: string
  duration?: number
  added_at: string
  updated_at: string
  library_id: number
  library_name?: string
  tmdb_id?: string
  child_count?: number
}

export function MediaPage() {
  const queryClient = useQueryClient()
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState<string>('')
  const [libraryFilter, setLibraryFilter] = useState<number | ''>('')
  const [page, setPage] = useState(1)
  const [expandedItem, setExpandedItem] = useState<number | null>(null)
  const [editingItem, setEditingItem] = useState<MediaItem | null>(null)
  const [matchingItem, setMatchingItem] = useState<MediaItem | null>(null)
  const [matchSearch, setMatchSearch] = useState('')

  // Fetch libraries for filter dropdown
  const { data: libraries } = useQuery({
    queryKey: ['admin-libraries'],
    queryFn: () => api.getLibraries(),
  })

  // Fetch media items
  const { data: mediaData, isLoading } = useQuery({
    queryKey: ['admin-media', search, typeFilter, libraryFilter, page],
    queryFn: () => api.getAdminMedia({ search, type: typeFilter, libraryId: libraryFilter || undefined, page }),
  })

  // Search TMDB for matches
  const { data: matchResults, isLoading: isSearchingMatches } = useQuery({
    queryKey: ['tmdb-search', matchingItem?.id, matchSearch],
    queryFn: () => api.searchTMDB(matchSearch, matchingItem?.type === 'show' ? 'tv' : 'movie'),
    enabled: !!matchingItem && matchSearch.length > 2,
  })

  // Refresh metadata mutation
  const refreshMutation = useMutation({
    mutationFn: (id: number) => api.refreshMediaMetadata(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-media'] })
    },
  })

  // Update metadata mutation
  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<MediaItem> }) =>
      api.updateMediaMetadata(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-media'] })
      setEditingItem(null)
    },
  })

  // Apply match mutation
  const applyMatchMutation = useMutation({
    mutationFn: ({ id, tmdbId, mediaType }: { id: number; tmdbId: number; mediaType: string }) =>
      api.applyMediaMatch(id, tmdbId, mediaType),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-media'] })
      setMatchingItem(null)
      setMatchSearch('')
    },
  })

  const handleSaveEdit = () => {
    if (!editingItem) return
    updateMutation.mutate({
      id: editingItem.id,
      data: {
        title: editingItem.title,
        sort_title: editingItem.sort_title,
        year: editingItem.year,
        summary: editingItem.summary,
        studio: editingItem.studio,
        content_rating: editingItem.content_rating,
      },
    })
  }

  const getTypeIcon = (type: string) => {
    switch (type.toLowerCase()) {
      case 'movie':
        return <Film className="h-4 w-4" />
      case 'show':
        return <Tv className="h-4 w-4" />
      default:
        return <Film className="h-4 w-4" />
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Media</h1>
          <p className="text-gray-400">Manage your media library metadata</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-4">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search media..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <select
          value={typeFilter}
          onChange={(e) => {
            setTypeFilter(e.target.value)
            setPage(1)
          }}
          className="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="">All Types</option>
          <option value="movie">Movies</option>
          <option value="show">TV Shows</option>
        </select>

        <select
          value={libraryFilter}
          onChange={(e) => {
            setLibraryFilter(e.target.value ? Number(e.target.value) : '')
            setPage(1)
          }}
          className="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="">All Libraries</option>
          {libraries?.map((lib) => (
            <option key={lib.id} value={lib.id}>
              {lib.title}
            </option>
          ))}
        </select>
      </div>

      {/* Media List */}
      <div className="bg-gray-800 rounded-lg overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-gray-400">Loading...</div>
        ) : !mediaData?.items?.length ? (
          <div className="p-8 text-center text-gray-400">No media found</div>
        ) : (
          <div className="divide-y divide-gray-700">
            {mediaData.items.map((item) => (
              <div key={item.id} className="p-4">
                <div
                  className="flex items-center gap-4 cursor-pointer"
                  onClick={() => setExpandedItem(expandedItem === item.id ? null : item.id)}
                >
                  {/* Poster */}
                  <div className="w-16 h-24 bg-gray-700 rounded overflow-hidden flex-shrink-0">
                    {item.thumb ? (
                      <img
                        src={item.thumb}
                        alt={item.title}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        {getTypeIcon(item.type)}
                      </div>
                    )}
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      {getTypeIcon(item.type)}
                      <h3 className="text-white font-medium truncate">{item.title}</h3>
                      {item.year && (
                        <span className="text-gray-400">({item.year})</span>
                      )}
                    </div>
                    <p className="text-sm text-gray-400 truncate">
                      {item.library_name} • Added {new Date(item.added_at).toLocaleDateString()}
                    </p>
                    {!item.thumb && (
                      <p className="text-sm text-yellow-500 flex items-center gap-1 mt-1">
                        <AlertCircle className="h-3 w-3" />
                        Missing metadata
                      </p>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2">
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        setMatchingItem(item)
                        setMatchSearch(item.title)
                      }}
                      className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded"
                      title="Fix Match"
                    >
                      <Search className="h-4 w-4" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        setEditingItem({ ...item })
                      }}
                      className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded"
                      title="Edit"
                    >
                      <Edit className="h-4 w-4" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        refreshMutation.mutate(item.id)
                      }}
                      disabled={refreshMutation.isPending}
                      className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded disabled:opacity-50"
                      title="Refresh Metadata"
                    >
                      <RefreshCw className={`h-4 w-4 ${refreshMutation.isPending ? 'animate-spin' : ''}`} />
                    </button>
                    {expandedItem === item.id ? (
                      <ChevronUp className="h-5 w-5 text-gray-400" />
                    ) : (
                      <ChevronDown className="h-5 w-5 text-gray-400" />
                    )}
                  </div>
                </div>

                {/* Expanded Details */}
                {expandedItem === item.id && (
                  <div className="mt-4 pl-20 grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span className="text-gray-400">Original Title:</span>
                      <span className="ml-2 text-white">{item.original_title || '-'}</span>
                    </div>
                    <div>
                      <span className="text-gray-400">Sort Title:</span>
                      <span className="ml-2 text-white">{item.sort_title}</span>
                    </div>
                    <div>
                      <span className="text-gray-400">Studio:</span>
                      <span className="ml-2 text-white">{item.studio || '-'}</span>
                    </div>
                    <div>
                      <span className="text-gray-400">Rating:</span>
                      <span className="ml-2 text-white">{item.content_rating || '-'}</span>
                    </div>
                    <div>
                      <span className="text-gray-400">TMDB ID:</span>
                      <span className="ml-2 text-white">{item.tmdb_id || 'Not matched'}</span>
                    </div>
                    <div>
                      <span className="text-gray-400">Score:</span>
                      <span className="ml-2 text-white">{item.rating?.toFixed(1) || '-'}</span>
                    </div>
                    {item.summary && (
                      <div className="col-span-2">
                        <span className="text-gray-400">Summary:</span>
                        <p className="mt-1 text-white text-sm">{item.summary}</p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Pagination */}
        {mediaData && mediaData.total > mediaData.page_size && (
          <div className="flex items-center justify-between p-4 border-t border-gray-700">
            <p className="text-sm text-gray-400">
              Showing {(page - 1) * mediaData.page_size + 1} to{' '}
              {Math.min(page * mediaData.page_size, mediaData.total)} of {mediaData.total}
            </p>
            <div className="flex gap-2">
              <button
                onClick={() => setPage(page - 1)}
                disabled={page === 1}
                className="px-3 py-1 bg-gray-700 text-white rounded disabled:opacity-50"
              >
                Previous
              </button>
              <button
                onClick={() => setPage(page + 1)}
                disabled={page * mediaData.page_size >= mediaData.total}
                className="px-3 py-1 bg-gray-700 text-white rounded disabled:opacity-50"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Edit Modal */}
      {editingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-gray-800 rounded-lg p-6 w-full max-w-lg">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-white">Edit Metadata</h2>
              <button
                onClick={() => setEditingItem(null)}
                className="text-gray-400 hover:text-white"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm text-gray-400 mb-1">Title</label>
                <input
                  type="text"
                  value={editingItem.title}
                  onChange={(e) => setEditingItem({ ...editingItem, title: e.target.value })}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Sort Title</label>
                <input
                  type="text"
                  value={editingItem.sort_title}
                  onChange={(e) => setEditingItem({ ...editingItem, sort_title: e.target.value })}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-gray-400 mb-1">Year</label>
                  <input
                    type="number"
                    value={editingItem.year || ''}
                    onChange={(e) => setEditingItem({ ...editingItem, year: Number(e.target.value) || undefined })}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                  />
                </div>
                <div>
                  <label className="block text-sm text-gray-400 mb-1">Studio</label>
                  <input
                    type="text"
                    value={editingItem.studio || ''}
                    onChange={(e) => setEditingItem({ ...editingItem, studio: e.target.value })}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Content Rating</label>
                <input
                  type="text"
                  value={editingItem.content_rating || ''}
                  onChange={(e) => setEditingItem({ ...editingItem, content_rating: e.target.value })}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Summary</label>
                <textarea
                  value={editingItem.summary || ''}
                  onChange={(e) => setEditingItem({ ...editingItem, summary: e.target.value })}
                  rows={4}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                />
              </div>
            </div>

            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setEditingItem(null)}
                className="px-4 py-2 text-gray-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveEdit}
                disabled={updateMutation.isPending}
                className="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 disabled:opacity-50"
              >
                {updateMutation.isPending ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Fix Match Modal */}
      {matchingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-gray-800 rounded-lg p-6 w-full max-w-2xl max-h-[80vh] overflow-hidden flex flex-col">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-white">Fix Match: {matchingItem.title}</h2>
              <button
                onClick={() => {
                  setMatchingItem(null)
                  setMatchSearch('')
                }}
                className="text-gray-400 hover:text-white"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mb-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search TMDB..."
                  value={matchSearch}
                  onChange={(e) => setMatchSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                />
              </div>
            </div>

            <div className="flex-1 overflow-y-auto">
              {isSearchingMatches ? (
                <div className="p-8 text-center text-gray-400">Searching...</div>
              ) : !matchResults?.length ? (
                <div className="p-8 text-center text-gray-400">
                  {matchSearch.length > 2 ? 'No results found' : 'Type to search'}
                </div>
              ) : (
                <div className="space-y-2">
                  {matchResults.map((result) => (
                    <div
                      key={result.id}
                      className="flex items-center gap-4 p-3 bg-gray-700 rounded hover:bg-gray-600 cursor-pointer"
                      onClick={() => applyMatchMutation.mutate({
                        id: matchingItem.id,
                        tmdbId: result.id,
                        mediaType: result.media_type,
                      })}
                    >
                      <div className="w-12 h-18 bg-gray-600 rounded overflow-hidden flex-shrink-0">
                        {result.poster_path ? (
                          <img
                            src={`https://image.tmdb.org/t/p/w92${result.poster_path}`}
                            alt={result.title}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center">
                            <Film className="h-4 w-4 text-gray-400" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <h4 className="text-white font-medium truncate">{result.title}</h4>
                          <span className="text-gray-400 text-sm">
                            ({(result.release_date || result.first_air_date || '').substring(0, 4)})
                          </span>
                        </div>
                        <p className="text-sm text-gray-400 line-clamp-2">{result.overview}</p>
                        <p className="text-xs text-gray-500 mt-1">
                          TMDB ID: {result.id} • Rating: {result.vote_average?.toFixed(1)}
                        </p>
                      </div>
                      <Check className="h-5 w-5 text-green-500 flex-shrink-0" />
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
