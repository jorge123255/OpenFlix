import { useState, useCallback } from 'react'
import { Image, Palette, Search, Loader, AlertCircle, X, Upload, Link, ArrowLeft } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'

const authFetch = async (url: string, options?: RequestInit) => {
  const token = localStorage.getItem('openflix_token') || ''
  const res = await fetch(url, {
    ...options,
    headers: { 'X-Plex-Token': token, 'Content-Type': 'application/json', ...options?.headers },
  })
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

interface MediaItem {
  id: number
  title: string
  year?: number
  type: string
  posterUrl?: string
  backdropUrl?: string
  tmdbId?: number
}

interface MediaSearchResponse {
  items: MediaItem[]
  total: number
  page: number
}

interface TMDBArtwork {
  url: string
  width: number
  height: number
  type: 'poster' | 'backdrop'
}

function useMediaSearch(search: string, page: number) {
  return useQuery({
    queryKey: ['mediaSearch', search, page],
    queryFn: () =>
      authFetch(`/admin/media?search=${encodeURIComponent(search)}&page=${page}`) as Promise<MediaSearchResponse>,
    enabled: search.length >= 2,
    placeholderData: (prev) => prev,
  })
}

function proxyImageUrl(url: string): string {
  if (!url) return ''
  const token = localStorage.getItem('openflix_token') || ''
  return `/api/images/proxy?url=${encodeURIComponent(url)}&X-Plex-Token=${token}`
}

function MediaGrid({
  items,
  onSelect,
}: {
  items: MediaItem[]
  onSelect: (item: MediaItem) => void
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
            {item.posterUrl ? (
              <img
                src={proxyImageUrl(item.posterUrl)}
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
              <Palette className="h-6 w-6 text-white opacity-0 group-hover:opacity-100 transition-opacity" />
            </div>
          </div>
          <div className="p-2">
            <p className="text-sm text-white truncate">{item.title}</p>
            <p className="text-xs text-gray-400">
              {item.year && `${item.year} - `}
              <span className="capitalize">{item.type}</span>
            </p>
          </div>
        </button>
      ))}
    </div>
  )
}

function ArtworkEditor({
  item,
  onClose,
}: {
  item: MediaItem
  onClose: () => void
}) {
  const [activeArtworkType, setActiveArtworkType] = useState<'poster' | 'backdrop'>('poster')
  const [customUrl, setCustomUrl] = useState('')
  const [selectedArtwork, setSelectedArtwork] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [saveResult, setSaveResult] = useState<{ success: boolean; message: string } | null>(null)

  const { data: tmdbResults, isLoading: loadingTmdb } = useQuery({
    queryKey: ['tmdbArtwork', item.id, item.tmdbId, activeArtworkType],
    queryFn: async () => {
      if (!item.tmdbId) return [] as TMDBArtwork[]
      const data = await authFetch(
        `/admin/media/${item.id}/artwork?type=${activeArtworkType}&tmdbId=${item.tmdbId}`
      )
      return (data.results || []) as TMDBArtwork[]
    },
    enabled: !!item.tmdbId,
  })

  const currentArtwork =
    activeArtworkType === 'poster' ? item.posterUrl : item.backdropUrl

  const previewArtwork = selectedArtwork || customUrl || null

  const handleSave = useCallback(async () => {
    const artworkUrl = selectedArtwork || customUrl
    if (!artworkUrl) return

    setSaving(true)
    setSaveResult(null)
    try {
      await authFetch(`/admin/media/${item.id}/artwork`, {
        method: 'PUT',
        body: JSON.stringify({
          type: activeArtworkType,
          url: artworkUrl,
        }),
      })
      setSaveResult({ success: true, message: 'Artwork updated successfully' })
    } catch (err) {
      setSaveResult({
        success: false,
        message: err instanceof Error ? err.message : 'Failed to update artwork',
      })
    } finally {
      setSaving(false)
    }
  }, [selectedArtwork, customUrl, activeArtworkType, item.id])

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
        <div>
          <h2 className="text-xl font-semibold text-white">{item.title}</h2>
          <p className="text-sm text-gray-400">
            {item.year && `${item.year} - `}
            <span className="capitalize">{item.type}</span>
            {item.tmdbId && ` - TMDB: ${item.tmdbId}`}
          </p>
        </div>
      </div>

      {/* Artwork Type Tabs */}
      <div className="flex gap-2">
        <button
          onClick={() => {
            setActiveArtworkType('poster')
            setSelectedArtwork(null)
            setCustomUrl('')
            setSaveResult(null)
          }}
          className={`px-4 py-2 rounded-lg font-medium ${
            activeArtworkType === 'poster'
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-700 text-gray-400 hover:text-white'
          }`}
        >
          Poster
        </button>
        <button
          onClick={() => {
            setActiveArtworkType('backdrop')
            setSelectedArtwork(null)
            setCustomUrl('')
            setSaveResult(null)
          }}
          className={`px-4 py-2 rounded-lg font-medium ${
            activeArtworkType === 'backdrop'
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-700 text-gray-400 hover:text-white'
          }`}
        >
          Backdrop
        </button>
      </div>

      {/* Side-by-side Preview */}
      <div className="bg-gray-800 rounded-xl p-6">
        <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-4">Preview</h3>
        <div className="grid grid-cols-2 gap-6">
          <div>
            <p className="text-sm text-gray-400 mb-2">Current</p>
            <div
              className={`bg-gray-700 rounded-lg overflow-hidden ${
                activeArtworkType === 'poster' ? 'aspect-[2/3]' : 'aspect-video'
              }`}
            >
              {currentArtwork ? (
                <img
                  src={proxyImageUrl(currentArtwork)}
                  alt="Current artwork"
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <Image className="h-12 w-12 text-gray-600" />
                  <span className="text-gray-500 ml-2">No artwork</span>
                </div>
              )}
            </div>
          </div>
          <div>
            <p className="text-sm text-gray-400 mb-2">New</p>
            <div
              className={`bg-gray-700 rounded-lg overflow-hidden border-2 ${
                previewArtwork ? 'border-indigo-500' : 'border-gray-600 border-dashed'
              } ${activeArtworkType === 'poster' ? 'aspect-[2/3]' : 'aspect-video'}`}
            >
              {previewArtwork ? (
                <img
                  src={proxyImageUrl(previewArtwork)}
                  alt="New artwork"
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <Palette className="h-12 w-12 text-gray-600" />
                  <span className="text-gray-500 ml-2">Select artwork below</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Save Button */}
        {previewArtwork && (
          <div className="mt-4 flex items-center gap-3">
            <button
              onClick={handleSave}
              disabled={saving}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg"
            >
              {saving ? <Loader className="h-4 w-4 animate-spin" /> : <Palette className="h-4 w-4" />}
              {saving ? 'Saving...' : 'Apply Artwork'}
            </button>
            <button
              onClick={() => {
                setSelectedArtwork(null)
                setCustomUrl('')
                setSaveResult(null)
              }}
              className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-gray-300 rounded-lg"
            >
              Cancel
            </button>
          </div>
        )}

        {saveResult && (
          <div
            className={`mt-3 flex items-center gap-2 p-3 rounded-lg ${
              saveResult.success
                ? 'bg-green-500/10 border border-green-500/30'
                : 'bg-red-500/10 border border-red-500/30'
            }`}
          >
            <span className={saveResult.success ? 'text-green-400 text-sm' : 'text-red-400 text-sm'}>
              {saveResult.message}
            </span>
          </div>
        )}
      </div>

      {/* Custom URL Input */}
      <div className="bg-gray-800 rounded-xl p-6">
        <div className="flex items-center gap-2 mb-3">
          <Link className="h-4 w-4 text-gray-400" />
          <h3 className="text-sm font-medium text-gray-300">Custom URL</h3>
        </div>
        <div className="flex gap-2">
          <input
            type="text"
            value={customUrl}
            onChange={(e) => {
              setCustomUrl(e.target.value)
              setSelectedArtwork(null)
            }}
            className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
            placeholder="https://example.com/artwork.jpg"
          />
          {customUrl && (
            <button
              onClick={() => setCustomUrl('')}
              className="p-2 text-gray-400 hover:text-white"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>
      </div>

      {/* Upload Custom Artwork */}
      <div className="bg-gray-800 rounded-xl p-6">
        <div className="flex items-center gap-2 mb-3">
          <Upload className="h-4 w-4 text-gray-400" />
          <h3 className="text-sm font-medium text-gray-300">Upload Custom Artwork</h3>
        </div>
        <label className="block border-2 border-dashed border-gray-600 hover:border-gray-500 rounded-lg p-6 text-center cursor-pointer transition-colors">
          <Upload className="h-8 w-8 mx-auto text-gray-500 mb-2" />
          <p className="text-gray-400 text-sm">Click to upload an image</p>
          <p className="text-gray-500 text-xs mt-1">PNG, JPG, or WebP</p>
          <input
            type="file"
            className="hidden"
            accept="image/png,image/jpeg,image/webp"
            onChange={async (e) => {
              const file = e.target.files?.[0]
              if (!file) return
              const token = localStorage.getItem('openflix_token') || ''
              const formData = new FormData()
              formData.append('file', file)
              formData.append('type', activeArtworkType)
              try {
                const res = await fetch(`/admin/media/${item.id}/artwork/upload`, {
                  method: 'POST',
                  headers: { 'X-Plex-Token': token },
                  body: formData,
                })
                if (!res.ok) throw new Error('Upload failed')
                const data = await res.json()
                if (data.url) {
                  setSelectedArtwork(data.url)
                  setCustomUrl('')
                }
              } catch {
                setSaveResult({ success: false, message: 'Failed to upload artwork' })
              }
            }}
          />
        </label>
      </div>

      {/* TMDB Results */}
      {item.tmdbId && (
        <div className="bg-gray-800 rounded-xl p-6">
          <h3 className="text-sm font-medium text-gray-300 mb-4">
            TMDB {activeArtworkType === 'poster' ? 'Posters' : 'Backdrops'}
          </h3>

          {loadingTmdb ? (
            <div className="flex items-center justify-center py-8">
              <Loader className="h-6 w-6 text-indigo-500 animate-spin" />
            </div>
          ) : tmdbResults && tmdbResults.length > 0 ? (
            <div
              className={`grid gap-3 ${
                activeArtworkType === 'poster'
                  ? 'grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6'
                  : 'grid-cols-2 sm:grid-cols-3 md:grid-cols-4'
              }`}
            >
              {tmdbResults.map((art, idx) => (
                <button
                  key={idx}
                  onClick={() => {
                    setSelectedArtwork(art.url)
                    setCustomUrl('')
                  }}
                  className={`rounded-lg overflow-hidden border-2 transition-all ${
                    selectedArtwork === art.url
                      ? 'border-indigo-500 ring-2 ring-indigo-500/50'
                      : 'border-transparent hover:border-gray-500'
                  }`}
                >
                  <div className={activeArtworkType === 'poster' ? 'aspect-[2/3]' : 'aspect-video'}>
                    <img
                      src={proxyImageUrl(art.url)}
                      alt={`TMDB artwork ${idx + 1}`}
                      className="w-full h-full object-cover"
                      loading="lazy"
                    />
                  </div>
                  <div className="p-1 bg-gray-700 text-center">
                    <span className="text-xs text-gray-400">
                      {art.width}x{art.height}
                    </span>
                  </div>
                </button>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <Image className="h-8 w-8 text-gray-600 mx-auto mb-2" />
              <p className="text-gray-500 text-sm">No TMDB artwork found</p>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export function ArtworkManagerPage() {
  const [searchQuery, setSearchQuery] = useState('')
  const [page, setPage] = useState(1)
  const [selectedItem, setSelectedItem] = useState<MediaItem | null>(null)

  const {
    data: searchResults,
    isLoading,
    error,
  } = useMediaSearch(searchQuery, page)

  if (selectedItem) {
    return (
      <div>
        <ArtworkEditor item={selectedItem} onClose={() => setSelectedItem(null)} />
      </div>
    )
  }

  return (
    <div>
      <div className="mb-8">
        <div className="flex items-center gap-3">
          <Palette className="h-6 w-6 text-indigo-400" />
          <h1 className="text-2xl font-bold text-white">Artwork Manager</h1>
        </div>
        <p className="text-gray-400 mt-1">Search and update artwork for movies, TV shows, and other media</p>
      </div>

      {/* Search */}
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value)
              setPage(1)
            }}
            className="w-full pl-10 pr-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
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
      </div>

      {/* Results */}
      {!searchQuery || searchQuery.length < 2 ? (
        <div className="bg-gray-800 rounded-xl p-12 text-center">
          <Image className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">Search for Media</h3>
          <p className="text-gray-400">Enter at least 2 characters to search your media library.</p>
        </div>
      ) : isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-gray-800 rounded-xl p-6 text-center">
          <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">Search Failed</h3>
          <p className="text-gray-400">Could not search media library. Please try again.</p>
        </div>
      ) : searchResults && searchResults.items.length > 0 ? (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-400">
              {searchResults.total} result{searchResults.total !== 1 ? 's' : ''} found
            </p>
          </div>

          <MediaGrid items={searchResults.items} onSelect={setSelectedItem} />

          {/* Pagination */}
          {searchResults.total > 24 && (
            <div className="flex justify-center gap-2 pt-4">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 disabled:text-gray-600 text-white rounded-lg"
              >
                Previous
              </button>
              <span className="px-4 py-2 text-gray-400">Page {page}</span>
              <button
                onClick={() => setPage((p) => p + 1)}
                disabled={searchResults.items.length < 24}
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
          <p className="text-gray-400">No media found matching "{searchQuery}"</p>
        </div>
      )}
    </div>
  )
}
