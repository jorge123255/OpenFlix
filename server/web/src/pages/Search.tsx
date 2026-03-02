import { useState, useCallback } from 'react'
import {
  Search as SearchIcon,
  RefreshCw,
  AlertTriangle,
  Loader,
  Film,
  Tv,
  Radio,
  FileText,
  Users,
  ChevronLeft,
  ChevronRight,
  Tag,
} from 'lucide-react'
import { useQuery } from '@tanstack/react-query'

interface SearchResult {
  id: number | string
  type: string
  title: string
  description?: string
  thumb?: string
  year?: number
  channelNumber?: string
  groupName?: string
}

interface SearchResponse {
  results: SearchResult[]
  total: number
  offset: number
  limit: number
}

const TOKEN_KEY = 'openflix_token'

function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

const SEARCH_TYPES = [
  { value: '', label: 'All', icon: SearchIcon },
  { value: 'media', label: 'Media', icon: Film },
  { value: 'channel', label: 'Channels', icon: Tv },
  { value: 'program', label: 'Programs', icon: Radio },
  { value: 'file', label: 'Files', icon: FileText },
  { value: 'group', label: 'Groups', icon: Users },
] as const

const TYPE_BADGES: Record<string, { color: string; bg: string; label: string }> = {
  media: { color: 'text-purple-400', bg: 'bg-purple-500/20', label: 'Media' },
  movie: { color: 'text-purple-400', bg: 'bg-purple-500/20', label: 'Movie' },
  show: { color: 'text-blue-400', bg: 'bg-blue-500/20', label: 'TV Show' },
  episode: { color: 'text-blue-300', bg: 'bg-blue-500/15', label: 'Episode' },
  channel: { color: 'text-green-400', bg: 'bg-green-500/20', label: 'Channel' },
  program: { color: 'text-orange-400', bg: 'bg-orange-500/20', label: 'Program' },
  file: { color: 'text-gray-400', bg: 'bg-gray-500/20', label: 'File' },
  group: { color: 'text-yellow-400', bg: 'bg-yellow-500/20', label: 'Group' },
}

const PAGE_SIZE = 25

async function searchApi(query: string, type: string, limit: number, offset: number): Promise<SearchResponse> {
  const params = new URLSearchParams()
  params.set('q', query)
  if (type) params.set('type', type)
  params.set('limit', String(limit))
  params.set('offset', String(offset))

  const res = await fetch(`/api/search?${params.toString()}`, {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Search failed')
  return res.json()
}

function TypeBadge({ type }: { type: string }) {
  const badge = TYPE_BADGES[type] || { color: 'text-gray-400', bg: 'bg-gray-500/20', label: type }
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 ${badge.bg} ${badge.color} rounded text-xs font-medium`}>
      <Tag className="h-3 w-3" />
      {badge.label}
    </span>
  )
}

export function SearchPage() {
  const [query, setQuery] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [type, setType] = useState('')
  const [offset, setOffset] = useState(0)

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['search', searchQuery, type, offset],
    queryFn: () => searchApi(searchQuery, type, PAGE_SIZE, offset),
    enabled: searchQuery.length > 0,
  })

  const handleSearch = useCallback(() => {
    if (query.trim()) {
      setSearchQuery(query.trim())
      setOffset(0)
    }
  }, [query])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSearch()
    }
  }

  const handleTypeChange = (newType: string) => {
    setType(newType)
    setOffset(0)
  }

  const results = data?.results || []
  const total = data?.total || 0
  const currentPage = Math.floor(offset / PAGE_SIZE) + 1
  const totalPages = Math.ceil(total / PAGE_SIZE)

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white flex items-center gap-3">
          <SearchIcon className="h-7 w-7 text-indigo-400" />
          Search
        </h1>
        <p className="text-gray-400 mt-1">Search across channels, media, programs, and more</p>
      </div>

      {/* Search Input */}
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <div className="flex gap-3">
          <div className="relative flex-1">
            <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Search for anything..."
              className="w-full pl-10 pr-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white text-base placeholder-gray-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
              autoFocus
            />
          </div>
          <button
            onClick={handleSearch}
            disabled={!query.trim() || isLoading}
            className="flex items-center gap-2 px-6 py-3 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 disabled:cursor-not-allowed text-white rounded-lg font-medium"
          >
            {isLoading ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <SearchIcon className="h-4 w-4" />
            )}
            Search
          </button>
        </div>

        {/* Type Filter Chips */}
        <div className="flex flex-wrap gap-2 mt-4">
          {SEARCH_TYPES.map(({ value, label, icon: Icon }) => (
            <button
              key={value}
              onClick={() => handleTypeChange(value)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm transition-colors ${
                type === value
                  ? 'bg-indigo-600 text-white'
                  : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
              }`}
            >
              <Icon className="h-3.5 w-3.5" />
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="mb-6 flex flex-col items-center justify-center h-48 gap-4">
          <AlertTriangle className="h-10 w-10 text-red-400" />
          <p className="text-red-400 text-sm">{(error as Error).message}</p>
          <button
            onClick={() => refetch()}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm"
          >
            <RefreshCw className="h-4 w-4" />
            Retry
          </button>
        </div>
      )}

      {/* No query yet */}
      {!searchQuery && !error && (
        <div className="flex flex-col items-center justify-center h-48 text-gray-500">
          <SearchIcon className="h-16 w-16 mb-4 text-gray-600" />
          <p className="text-lg">Enter a search term to get started</p>
        </div>
      )}

      {/* Loading */}
      {isLoading && (
        <div className="flex items-center justify-center h-48">
          <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
        </div>
      )}

      {/* Results */}
      {searchQuery && !isLoading && !error && (
        <>
          {/* Results count */}
          <div className="flex items-center justify-between mb-4">
            <p className="text-sm text-gray-400">
              {total === 0 ? (
                'No results found'
              ) : (
                <>
                  Showing {offset + 1}-{Math.min(offset + PAGE_SIZE, total)} of {total} result{total !== 1 ? 's' : ''}
                  {type && <span className="ml-1">in {SEARCH_TYPES.find(t => t.value === type)?.label || type}</span>}
                </>
              )}
            </p>
          </div>

          {/* Empty State */}
          {results.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-48 bg-gray-800 rounded-xl">
              <SearchIcon className="h-12 w-12 text-gray-600 mb-3" />
              <h3 className="text-lg font-medium text-white mb-1">No results found</h3>
              <p className="text-gray-400 text-sm">
                Try a different search term or filter
              </p>
            </div>
          ) : (
            /* Results List */
            <div className="space-y-2">
              {results.map((result, index) => (
                <div
                  key={`${result.type}-${result.id}-${index}`}
                  className="bg-gray-800 rounded-xl p-4 hover:bg-gray-750 transition-colors cursor-pointer flex items-center gap-4"
                >
                  {/* Thumbnail */}
                  {result.thumb ? (
                    <img
                      src={result.thumb}
                      alt=""
                      className="w-12 h-12 rounded-lg object-cover flex-shrink-0 bg-gray-700"
                    />
                  ) : (
                    <div className="w-12 h-12 rounded-lg bg-gray-700 flex items-center justify-center flex-shrink-0">
                      {result.type === 'channel' ? (
                        <Tv className="h-5 w-5 text-gray-500" />
                      ) : result.type === 'program' ? (
                        <Radio className="h-5 w-5 text-gray-500" />
                      ) : (
                        <Film className="h-5 w-5 text-gray-500" />
                      )}
                    </div>
                  )}

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <TypeBadge type={result.type} />
                      {result.channelNumber && (
                        <span className="text-xs text-gray-500">Ch. {result.channelNumber}</span>
                      )}
                      {result.year && (
                        <span className="text-xs text-gray-500">{result.year}</span>
                      )}
                    </div>
                    <p className="text-white font-medium truncate">{result.title}</p>
                    {result.description && (
                      <p className="text-gray-400 text-sm mt-0.5 line-clamp-1">{result.description}</p>
                    )}
                    {result.groupName && (
                      <p className="text-gray-500 text-xs mt-0.5">Group: {result.groupName}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-3 mt-6">
              <button
                onClick={() => setOffset(Math.max(0, offset - PAGE_SIZE))}
                disabled={offset === 0}
                className="flex items-center gap-1.5 px-3 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 disabled:text-gray-600 text-white rounded-lg text-sm"
              >
                <ChevronLeft className="h-4 w-4" />
                Previous
              </button>
              <span className="text-sm text-gray-400">
                Page {currentPage} of {totalPages}
              </span>
              <button
                onClick={() => setOffset(offset + PAGE_SIZE)}
                disabled={offset + PAGE_SIZE >= total}
                className="flex items-center gap-1.5 px-3 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 disabled:text-gray-600 text-white rounded-lg text-sm"
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
