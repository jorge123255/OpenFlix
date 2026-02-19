import { useState, useCallback, useEffect } from 'react'
import {
  Search,
  Loader,
  AlertCircle,
  X,
  ArrowLeft,
  Save,
  RefreshCw,
  Film,
  Tv,
  FileEdit,
  ExternalLink,
  CheckCircle2,
  Clapperboard,
  Scissors,
  Image,
} from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { api, type AdminMediaItem, type TMDBSearchResult } from '../api/client'

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function proxyImageUrl(url: string): string {
  if (!url) return ''
  const token = localStorage.getItem('openflix_token') || ''
  if (url.startsWith('http')) {
    return `/api/images/proxy?url=${encodeURIComponent(url)}&X-Plex-Token=${token}`
  }
  return `${url}${url.includes('?') ? '&' : '?'}X-Plex-Token=${token}`
}

function tmdbPosterUrl(path: string | undefined | null): string {
  if (!path) return ''
  return `https://image.tmdb.org/t/p/w342${path}`
}

const CONTENT_RATINGS = [
  'TV-Y',
  'TV-G',
  'TV-PG',
  'TV-14',
  'TV-MA',
  'G',
  'PG',
  'PG-13',
  'R',
  'NR',
]

// ---------------------------------------------------------------------------
// Media search hook (reuses pattern from ArtworkManager)
// ---------------------------------------------------------------------------

function useMediaSearch(search: string, page: number, mediaType: string) {
  return useQuery({
    queryKey: ['metadataSearch', search, page, mediaType],
    queryFn: () =>
      api.getAdminMedia({
        search,
        page,
        type: mediaType || undefined,
      }),
    enabled: search.length >= 2,
    placeholderData: (prev) => prev,
  })
}

// ---------------------------------------------------------------------------
// Media Grid
// ---------------------------------------------------------------------------

function MediaGrid({
  items,
  onSelect,
}: {
  items: AdminMediaItem[]
  onSelect: (item: AdminMediaItem) => void
}) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
      {items.map((item) => (
        <button
          key={item.id}
          onClick={() => onSelect(item)}
          className="group bg-gray-700/50 rounded-lg overflow-hidden text-left hover:ring-2 hover:ring-indigo-500 transition-all"
        >
          <div className="aspect-[2/3] bg-gray-700 relative">
            {item.thumb ? (
              <img
                src={proxyImageUrl(item.thumb)}
                alt={item.title}
                className="w-full h-full object-cover"
                loading="lazy"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center">
                <Image className="h-8 w-8 text-gray-600" />
              </div>
            )}
            <div className="absolute inset-0 bg-black/0 group-hover:bg-black/30 transition-colors flex items-center justify-center">
              <FileEdit className="h-6 w-6 text-white opacity-0 group-hover:opacity-100 transition-opacity" />
            </div>
          </div>
          <div className="p-2">
            <p className="text-sm text-white truncate">{item.title}</p>
            <p className="text-xs text-gray-400">
              {item.year ? `${item.year} \u2022 ` : ''}
              <span className="capitalize">{item.type}</span>
            </p>
          </div>
        </button>
      ))}
    </div>
  )
}

// ---------------------------------------------------------------------------
// TMDB Search Modal
// ---------------------------------------------------------------------------

function TMDBSearchModal({
  item,
  onClose,
  onApply,
}: {
  item: AdminMediaItem
  onClose: () => void
  onApply: (result: TMDBSearchResult) => void
}) {
  const [query, setQuery] = useState(item.title)
  const [searchType, setSearchType] = useState<string>(
    item.type === 'show' ? 'tv' : 'movie'
  )
  const [results, setResults] = useState<TMDBSearchResult[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [applying, setApplying] = useState<number | null>(null)

  const doSearch = useCallback(async () => {
    if (!query.trim()) return
    setLoading(true)
    setError(null)
    try {
      const data = await api.searchTMDB(query, searchType)
      setResults(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Search failed')
    } finally {
      setLoading(false)
    }
  }, [query, searchType])

  // Auto-search on mount
  useEffect(() => {
    doSearch()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleApply = async (result: TMDBSearchResult) => {
    setApplying(result.id)
    try {
      await api.applyMediaMatch(item.id, result.id, result.media_type)
      onApply(result)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to apply match')
    } finally {
      setApplying(null)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl w-full max-w-3xl max-h-[85vh] flex flex-col shadow-2xl border border-gray-700">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-700">
          <h3 className="text-lg font-semibold text-white">Search TMDB</h3>
          <button
            onClick={onClose}
            className="p-1 text-gray-400 hover:text-white"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Search bar */}
        <div className="px-6 py-4 border-b border-gray-700 space-y-3">
          <div className="flex gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && doSearch()}
                className="w-full pl-9 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
                placeholder="Search TMDB..."
              />
            </div>
            <select
              value={searchType}
              onChange={(e) => setSearchType(e.target.value)}
              className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
            >
              <option value="movie">Movie</option>
              <option value="tv">TV Show</option>
            </select>
            <button
              onClick={doSearch}
              disabled={loading}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white text-sm rounded-lg font-medium"
            >
              {loading ? (
                <Loader className="h-4 w-4 animate-spin" />
              ) : (
                'Search'
              )}
            </button>
          </div>
        </div>

        {/* Results */}
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-3">
          {error && (
            <div className="flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
              <AlertCircle className="h-4 w-4 text-red-400 shrink-0" />
              <span className="text-red-400 text-sm">{error}</span>
            </div>
          )}

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader className="h-6 w-6 text-indigo-500 animate-spin" />
            </div>
          ) : results.length === 0 ? (
            <div className="text-center py-12">
              <Search className="h-8 w-8 text-gray-600 mx-auto mb-2" />
              <p className="text-gray-500 text-sm">No results found</p>
            </div>
          ) : (
            results.map((r) => {
              const year =
                r.release_date?.slice(0, 4) || r.first_air_date?.slice(0, 4)
              return (
                <button
                  key={r.id}
                  onClick={() => handleApply(r)}
                  disabled={applying !== null}
                  className="w-full flex gap-4 p-3 bg-gray-700/50 hover:bg-gray-700 rounded-lg text-left transition-colors disabled:opacity-50"
                >
                  <div className="w-16 h-24 shrink-0 bg-gray-700 rounded overflow-hidden">
                    {r.poster_path ? (
                      <img
                        src={tmdbPosterUrl(r.poster_path)}
                        alt={r.title}
                        className="w-full h-full object-cover"
                        loading="lazy"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <Film className="h-6 w-6 text-gray-600" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="text-white font-medium truncate">
                        {r.title}
                      </p>
                      {year && (
                        <span className="text-gray-400 text-sm shrink-0">
                          ({year})
                        </span>
                      )}
                    </div>
                    {r.original_title && r.original_title !== r.title && (
                      <p className="text-gray-500 text-xs mt-0.5">
                        {r.original_title}
                      </p>
                    )}
                    <p className="text-gray-400 text-sm mt-1 line-clamp-2">
                      {r.overview || 'No overview available'}
                    </p>
                    <div className="flex items-center gap-3 mt-1.5">
                      <span className="text-xs text-gray-500 uppercase">
                        {r.media_type === 'tv' ? 'TV Show' : 'Movie'}
                      </span>
                      {r.vote_average != null && r.vote_average > 0 && (
                        <span className="text-xs text-yellow-500">
                          {r.vote_average.toFixed(1)} / 10
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="shrink-0 self-center">
                    {applying === r.id ? (
                      <Loader className="h-5 w-5 text-indigo-400 animate-spin" />
                    ) : (
                      <ExternalLink className="h-5 w-5 text-gray-500" />
                    )}
                  </div>
                </button>
              )
            })
          )}
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Metadata Edit Panel
// ---------------------------------------------------------------------------

function MetadataEditPanel({
  item,
  onClose,
}: {
  item: AdminMediaItem
  onClose: () => void
}) {
  // Form state
  const [title, setTitle] = useState(item.title)
  const [sortTitle, setSortTitle] = useState(item.sort_title || '')
  const [year, setYear] = useState<number | ''>(item.year || '')
  const [contentRating, setContentRating] = useState(item.content_rating || '')
  const [studio, setStudio] = useState(item.studio || '')
  const [summary, setSummary] = useState(item.summary || '')

  // UI state
  const [saving, setSaving] = useState(false)
  const [saveResult, setSaveResult] = useState<{
    success: boolean
    message: string
  } | null>(null)
  const [refreshing, setRefreshing] = useState(false)
  const [showTMDBModal, setShowTMDBModal] = useState(false)

  // Reset form when item changes
  useEffect(() => {
    setTitle(item.title)
    setSortTitle(item.sort_title || '')
    setYear(item.year || '')
    setContentRating(item.content_rating || '')
    setStudio(item.studio || '')
    setSummary(item.summary || '')
    setSaveResult(null)
  }, [item])

  const handleSave = useCallback(async () => {
    setSaving(true)
    setSaveResult(null)
    try {
      await api.updateMediaMetadata(item.id, {
        title,
        sort_title: sortTitle,
        year: year === '' ? 0 : year,
        content_rating: contentRating,
        studio,
        summary,
      } as Partial<AdminMediaItem>)
      setSaveResult({ success: true, message: 'Metadata saved successfully' })
    } catch (err) {
      setSaveResult({
        success: false,
        message:
          err instanceof Error ? err.message : 'Failed to save metadata',
      })
    } finally {
      setSaving(false)
    }
  }, [item.id, title, sortTitle, year, contentRating, studio, summary])

  const handleRefreshMetadata = useCallback(async () => {
    setRefreshing(true)
    setSaveResult(null)
    try {
      await api.refreshMediaMetadata(item.id)
      setSaveResult({
        success: true,
        message: 'Metadata refresh started. Changes may take a moment to appear.',
      })
    } catch (err) {
      setSaveResult({
        success: false,
        message:
          err instanceof Error ? err.message : 'Failed to refresh metadata',
      })
    } finally {
      setRefreshing(false)
    }
  }, [item.id])

  const handleReprocess = useCallback(async () => {
    setSaveResult(null)
    try {
      const token = localStorage.getItem('openflix_token') || ''
      const res = await fetch(`/dvr/recordings/${item.id}/reprocess`, {
        method: 'POST',
        headers: { 'X-Plex-Token': token, 'Content-Type': 'application/json' },
      })
      if (!res.ok) {
        const data = await res.json().catch(() => ({}))
        throw new Error(data.error || `HTTP ${res.status}`)
      }
      setSaveResult({ success: true, message: 'Reprocessing started' })
    } catch (err) {
      setSaveResult({
        success: false,
        message:
          err instanceof Error ? err.message : 'Failed to start reprocessing',
      })
    }
  }, [item.id])

  const handleRedetectCommercials = useCallback(async () => {
    setSaveResult(null)
    try {
      await api.runCommercialDetection(item.id)
      setSaveResult({
        success: true,
        message: 'Commercial detection started',
      })
    } catch (err) {
      setSaveResult({
        success: false,
        message:
          err instanceof Error
            ? err.message
            : 'Failed to start commercial detection',
      })
    }
  }, [item.id])

  const handleTMDBMatch = (_result: TMDBSearchResult) => {
    setShowTMDBModal(false)
    setSaveResult({
      success: true,
      message:
        'TMDB match applied. Metadata will refresh automatically.',
    })
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={onClose}
          className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg transition-colors"
        >
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div className="flex items-center gap-4 flex-1 min-w-0">
          {item.thumb && (
            <img
              src={proxyImageUrl(item.thumb)}
              alt={item.title}
              className="w-12 h-18 rounded object-cover shrink-0"
            />
          )}
          <div className="min-w-0">
            <h2 className="text-xl font-semibold text-white truncate">
              {item.title}
            </h2>
            <p className="text-sm text-gray-400">
              {item.year ? `${item.year} \u2022 ` : ''}
              <span className="capitalize">{item.type}</span>
              {item.library_name && ` \u2022 ${item.library_name}`}
              {item.tmdb_id && ` \u2022 ID: ${item.tmdb_id}`}
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: Edit Form (takes 2 columns) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Edit Metadata Section */}
          <div className="bg-gray-800 rounded-xl p-6">
            <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-4">
              Edit Metadata
            </h3>

            <div className="space-y-4">
              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Title
                </label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                />
              </div>

              {/* Sort Title */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Sort Title
                </label>
                <input
                  type="text"
                  value={sortTitle}
                  onChange={(e) => setSortTitle(e.target.value)}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                  placeholder="Leave blank to sort by title"
                />
              </div>

              {/* Year + Content Rating row */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1">
                    Year
                  </label>
                  <input
                    type="number"
                    value={year}
                    onChange={(e) =>
                      setYear(
                        e.target.value === '' ? '' : parseInt(e.target.value, 10)
                      )
                    }
                    className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                    placeholder="e.g. 2024"
                    min={1900}
                    max={2100}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1">
                    Content Rating
                  </label>
                  <select
                    value={contentRating}
                    onChange={(e) => setContentRating(e.target.value)}
                    className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                  >
                    <option value="">-- None --</option>
                    {CONTENT_RATINGS.map((cr) => (
                      <option key={cr} value={cr}>
                        {cr}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Studio */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Studio
                </label>
                <input
                  type="text"
                  value={studio}
                  onChange={(e) => setStudio(e.target.value)}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                  placeholder="e.g. Warner Bros."
                />
              </div>

              {/* Summary */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Summary / Description
                </label>
                <textarea
                  value={summary}
                  onChange={(e) => setSummary(e.target.value)}
                  rows={5}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500 resize-vertical"
                  placeholder="Enter a description..."
                />
              </div>

              {/* Save Button */}
              <div className="flex items-center gap-3 pt-2">
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="flex items-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg font-medium transition-colors"
                >
                  {saving ? (
                    <Loader className="h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  {saving ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Right: Actions sidebar */}
        <div className="space-y-6">
          {/* Fix Incorrect Match */}
          <div className="bg-gray-800 rounded-xl p-6">
            <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-4">
              Fix Incorrect Match
            </h3>
            <p className="text-sm text-gray-400 mb-4">
              If this item matched the wrong TMDB entry, search for the correct
              one and apply it.
            </p>
            <button
              onClick={() => setShowTMDBModal(true)}
              className="w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium transition-colors"
            >
              <Search className="h-4 w-4" />
              Search TMDB
            </button>
          </div>

          {/* Actions */}
          <div className="bg-gray-800 rounded-xl p-6">
            <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-4">
              Actions
            </h3>
            <div className="space-y-2">
              <button
                onClick={handleRefreshMetadata}
                disabled={refreshing}
                className="w-full flex items-center gap-2 px-4 py-2.5 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-750 text-white rounded-lg text-sm font-medium transition-colors"
              >
                {refreshing ? (
                  <Loader className="h-4 w-4 animate-spin" />
                ) : (
                  <RefreshCw className="h-4 w-4" />
                )}
                Refresh Metadata
              </button>

              <button
                onClick={handleReprocess}
                className="w-full flex items-center gap-2 px-4 py-2.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm font-medium transition-colors"
              >
                <Clapperboard className="h-4 w-4" />
                Reprocess Video
              </button>

              <button
                onClick={handleRedetectCommercials}
                className="w-full flex items-center gap-2 px-4 py-2.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm font-medium transition-colors"
              >
                <Scissors className="h-4 w-4" />
                Redetect Commercials
              </button>
            </div>
          </div>

          {/* Item Info */}
          <div className="bg-gray-800 rounded-xl p-6">
            <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-4">
              Item Info
            </h3>
            <dl className="space-y-2 text-sm">
              <div className="flex justify-between">
                <dt className="text-gray-500">ID</dt>
                <dd className="text-gray-300">{item.id}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-gray-500">Type</dt>
                <dd className="text-gray-300 capitalize">{item.type}</dd>
              </div>
              {item.library_name && (
                <div className="flex justify-between">
                  <dt className="text-gray-500">Library</dt>
                  <dd className="text-gray-300">{item.library_name}</dd>
                </div>
              )}
              {item.duration != null && item.duration > 0 && (
                <div className="flex justify-between">
                  <dt className="text-gray-500">Duration</dt>
                  <dd className="text-gray-300">
                    {Math.round(item.duration / 60000)}m
                  </dd>
                </div>
              )}
              {item.child_count != null && item.child_count > 0 && (
                <div className="flex justify-between">
                  <dt className="text-gray-500">
                    {item.type === 'show' ? 'Seasons' : 'Children'}
                  </dt>
                  <dd className="text-gray-300">{item.child_count}</dd>
                </div>
              )}
              <div className="flex justify-between">
                <dt className="text-gray-500">Added</dt>
                <dd className="text-gray-300">
                  {new Date(item.added_at).toLocaleDateString()}
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-gray-500">Updated</dt>
                <dd className="text-gray-300">
                  {new Date(item.updated_at).toLocaleDateString()}
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>

      {/* Status message */}
      {saveResult && (
        <div
          className={`flex items-center gap-2 p-4 rounded-lg ${
            saveResult.success
              ? 'bg-green-500/10 border border-green-500/30'
              : 'bg-red-500/10 border border-red-500/30'
          }`}
        >
          {saveResult.success ? (
            <CheckCircle2 className="h-5 w-5 text-green-400 shrink-0" />
          ) : (
            <AlertCircle className="h-5 w-5 text-red-400 shrink-0" />
          )}
          <span
            className={
              saveResult.success ? 'text-green-400 text-sm' : 'text-red-400 text-sm'
            }
          >
            {saveResult.message}
          </span>
        </div>
      )}

      {/* TMDB Modal */}
      {showTMDBModal && (
        <TMDBSearchModal
          item={item}
          onClose={() => setShowTMDBModal(false)}
          onApply={handleTMDBMatch}
        />
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Main Page
// ---------------------------------------------------------------------------

export function MetadataEditorPage() {
  const [searchQuery, setSearchQuery] = useState('')
  const [page, setPage] = useState(1)
  const [typeFilter, setTypeFilter] = useState('')
  const [selectedItem, setSelectedItem] = useState<AdminMediaItem | null>(null)

  const {
    data: searchResults,
    isLoading,
    error,
  } = useMediaSearch(searchQuery, page, typeFilter)

  if (selectedItem) {
    return (
      <div>
        <MetadataEditPanel
          item={selectedItem}
          onClose={() => setSelectedItem(null)}
        />
      </div>
    )
  }

  return (
    <div>
      <div className="mb-8">
        <div className="flex items-center gap-3">
          <FileEdit className="h-6 w-6 text-indigo-400" />
          <h1 className="text-2xl font-bold text-white">Metadata Editor</h1>
        </div>
        <p className="text-gray-400 mt-1">
          Search and edit metadata for movies and TV shows. Fix incorrect
          matches, update titles, and refresh from TMDB.
        </p>
      </div>

      {/* Search */}
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <div className="flex gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value)
                setPage(1)
              }}
              className="w-full pl-10 pr-10 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
              placeholder="Search for a movie or TV show..."
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-gray-400 hover:text-white"
              >
                <X className="h-4 w-4" />
              </button>
            )}
          </div>
          <div className="flex gap-1 bg-gray-700 rounded-lg p-1">
            <button
              onClick={() => {
                setTypeFilter('')
                setPage(1)
              }}
              className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                typeFilter === ''
                  ? 'bg-indigo-600 text-white'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              All
            </button>
            <button
              onClick={() => {
                setTypeFilter('movie')
                setPage(1)
              }}
              className={`flex items-center gap-1.5 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                typeFilter === 'movie'
                  ? 'bg-indigo-600 text-white'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              <Film className="h-3.5 w-3.5" />
              Movies
            </button>
            <button
              onClick={() => {
                setTypeFilter('show')
                setPage(1)
              }}
              className={`flex items-center gap-1.5 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                typeFilter === 'show'
                  ? 'bg-indigo-600 text-white'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              <Tv className="h-3.5 w-3.5" />
              Shows
            </button>
          </div>
        </div>
      </div>

      {/* Results */}
      {!searchQuery || searchQuery.length < 2 ? (
        <div className="bg-gray-800 rounded-xl p-12 text-center">
          <FileEdit className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">
            Search for Media
          </h3>
          <p className="text-gray-400">
            Enter at least 2 characters to search your media library.
          </p>
        </div>
      ) : isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-gray-800 rounded-xl p-6 text-center">
          <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">
            Search Failed
          </h3>
          <p className="text-gray-400">
            Could not search media library. Please try again.
          </p>
        </div>
      ) : searchResults && searchResults.items.length > 0 ? (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-400">
              {searchResults.total} result
              {searchResults.total !== 1 ? 's' : ''} found
            </p>
          </div>

          <MediaGrid items={searchResults.items} onSelect={setSelectedItem} />

          {/* Pagination */}
          {searchResults.total > searchResults.page_size && (
            <div className="flex justify-center gap-2 pt-4">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 disabled:text-gray-600 text-white rounded-lg"
              >
                Previous
              </button>
              <span className="px-4 py-2 text-gray-400">
                Page {page} of{' '}
                {Math.ceil(searchResults.total / searchResults.page_size)}
              </span>
              <button
                onClick={() => setPage((p) => p + 1)}
                disabled={
                  page >=
                  Math.ceil(searchResults.total / searchResults.page_size)
                }
                className="px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 disabled:text-gray-600 text-white rounded-lg"
              >
                Next
              </button>
            </div>
          )}
        </div>
      ) : (
        <div className="bg-gray-800 rounded-xl p-12 text-center">
          <Search className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No Results</h3>
          <p className="text-gray-400">
            No media found matching &ldquo;{searchQuery}&rdquo;
          </p>
        </div>
      )}
    </div>
  )
}
