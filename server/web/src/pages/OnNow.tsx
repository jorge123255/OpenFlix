import { useState, useMemo, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  MonitorPlay,
  Search,
  Star,
  Newspaper,
  Trophy,
  Film,
  Baby,
  Tv,
  Loader2,
  AlertCircle,
  Radio,
  Sparkles,
  Circle,
} from 'lucide-react'
import { api, type OnNowChannel } from '../api/client'

type FilterCategory = 'all' | 'favorites' | 'news' | 'sports' | 'movies' | 'entertainment' | 'kids'

const filterCategories: { id: FilterCategory; name: string; icon: React.ElementType }[] = [
  { id: 'all', name: 'All', icon: Tv },
  { id: 'favorites', name: 'Favorites', icon: Star },
  { id: 'news', name: 'News', icon: Newspaper },
  { id: 'sports', name: 'Sports', icon: Trophy },
  { id: 'movies', name: 'Movies', icon: Film },
  { id: 'entertainment', name: 'Entertainment', icon: MonitorPlay },
  { id: 'kids', name: 'Kids', icon: Baby },
]

function getProgramProgress(start: string, end: string): number {
  const now = Date.now()
  const startMs = new Date(start).getTime()
  const endMs = new Date(end).getTime()
  if (endMs <= startMs) return 0
  const elapsed = now - startMs
  const total = endMs - startMs
  return Math.max(0, Math.min(100, (elapsed / total) * 100))
}

function formatTime(dateStr: string): string {
  return new Date(dateStr).toLocaleTimeString([], {
    hour: 'numeric',
    minute: '2-digit',
  })
}

function getTimeRemaining(end: string): string {
  const now = Date.now()
  const endMs = new Date(end).getTime()
  const remainingMin = Math.max(0, Math.round((endMs - now) / 60000))
  if (remainingMin < 1) return 'Ending'
  if (remainingMin === 1) return '1 min left'
  if (remainingMin >= 60) {
    const hrs = Math.floor(remainingMin / 60)
    const mins = remainingMin % 60
    if (mins === 0) return `${hrs}h left`
    return `${hrs}h ${mins}m left`
  }
  return `${remainingMin} min left`
}

function matchesCategory(channel: OnNowChannel, category: FilterCategory): boolean {
  if (category === 'all') return true
  if (category === 'favorites') return channel.isFavorite
  const program = channel.nowPlaying
  if (!program) return false
  const group = (channel.group || '').toLowerCase()
  switch (category) {
    case 'news':
      return !!program.isNews || group.includes('news')
    case 'sports':
      return !!program.isSports || group.includes('sport')
    case 'movies':
      return !!program.isMovie || group.includes('movie') || group.includes('film')
    case 'entertainment':
      return (
        !program.isNews &&
        !program.isSports &&
        !program.isMovie &&
        !program.isKids &&
        !!program.title
      )
    case 'kids':
      return !!program.isKids || group.includes('kid') || group.includes('child')
    default:
      return true
  }
}

function ChannelCard({ channel }: { channel: OnNowChannel }) {
  const program = channel.nowPlaying
  const progress = program ? getProgramProgress(program.start, program.end) : 0

  return (
    <a
      href={channel.streamUrl || '#'}
      target="_blank"
      rel="noopener noreferrer"
      className="block bg-gray-800 rounded-xl border border-gray-700 hover:border-indigo-500 hover:bg-gray-750 transition-all duration-200 overflow-hidden group"
    >
      <div className="p-4">
        {/* Channel header */}
        <div className="flex items-center gap-3 mb-3">
          {channel.logo ? (
            <img
              src={channel.logo}
              alt={channel.name}
              className="h-10 w-10 rounded-lg object-contain bg-gray-900 p-1 flex-shrink-0"
              onError={(e) => {
                const target = e.target as HTMLImageElement
                target.style.display = 'none'
                const next = target.nextElementSibling as HTMLElement | null
                if (next) next.style.display = 'flex'
              }}
            />
          ) : null}
          <div
            className={`h-10 w-10 rounded-lg bg-gray-700 flex items-center justify-center flex-shrink-0 ${channel.logo ? 'hidden' : ''}`}
          >
            <Tv className="h-5 w-5 text-gray-400" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <span className="text-xs font-mono text-gray-400">{channel.number}</span>
              {channel.isFavorite && <Star className="h-3 w-3 text-yellow-400 fill-yellow-400" />}
            </div>
            <p className="text-sm font-medium text-white truncate">{channel.name}</p>
          </div>
        </div>

        {/* Program info */}
        {program ? (
          <div>
            <div className="flex items-center gap-1.5 mb-1">
              {program.isLive && (
                <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-bold uppercase bg-red-600 text-white">
                  <Circle className="h-1.5 w-1.5 fill-current" />
                  Live
                </span>
              )}
              {program.isNew && (
                <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-bold uppercase bg-emerald-600 text-white">
                  <Sparkles className="h-2.5 w-2.5" />
                  New
                </span>
              )}
              {program.isPremiere && (
                <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold uppercase bg-amber-600 text-white">
                  Premiere
                </span>
              )}
              {program.isMovie && (
                <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold uppercase bg-purple-600/60 text-purple-200">
                  Movie
                </span>
              )}
              {program.isSports && (
                <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold uppercase bg-green-600/60 text-green-200">
                  Sports
                </span>
              )}
            </div>
            <p className="text-sm font-semibold text-white truncate leading-tight">
              {program.title}
            </p>
            {program.episodeNum && (
              <p className="text-xs text-gray-400 truncate mt-0.5">{program.episodeNum}</p>
            )}
            <div className="flex items-center justify-between mt-2 text-xs text-gray-400">
              <span>
                {formatTime(program.start)} - {formatTime(program.end)}
              </span>
              <span>{getTimeRemaining(program.end)}</span>
            </div>

            {/* Progress bar */}
            <div className="mt-2 h-1 bg-gray-700 rounded-full overflow-hidden">
              <div
                className="h-full bg-indigo-600 rounded-full transition-all duration-1000"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        ) : (
          <div className="py-2">
            <p className="text-sm text-gray-500 italic">No program info</p>
          </div>
        )}
      </div>
    </a>
  )
}

export function OnNowPage() {
  const [filter, setFilter] = useState<FilterCategory>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [, setTick] = useState(0)

  // Re-render every 30s to update progress bars and time remaining
  useEffect(() => {
    const interval = setInterval(() => setTick((t) => t + 1), 30000)
    return () => clearInterval(interval)
  }, [])

  const { data: channels, isLoading, error } = useQuery({
    queryKey: ['onNow'],
    queryFn: () => api.getOnNow(),
    refetchInterval: 60000, // Refresh every 60s
  })

  const filteredChannels = useMemo(() => {
    if (!channels) return []
    let result = channels

    // Apply category filter
    result = result.filter((ch) => matchesCategory(ch, filter))

    // Apply search filter
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase()
      result = result.filter((ch) => {
        const nameMatch = ch.name.toLowerCase().includes(q)
        const numMatch = String(ch.number).includes(q)
        const programMatch = ch.nowPlaying?.title?.toLowerCase().includes(q) ?? false
        const groupMatch = ch.group?.toLowerCase().includes(q) ?? false
        return nameMatch || numMatch || programMatch || groupMatch
      })
    }

    return result
  }, [channels, filter, searchQuery])

  const categoryCounts = useMemo(() => {
    if (!channels) return {} as Record<FilterCategory, number>
    const counts: Record<FilterCategory, number> = {
      all: channels.length,
      favorites: 0,
      news: 0,
      sports: 0,
      movies: 0,
      entertainment: 0,
      kids: 0,
    }
    for (const ch of channels) {
      if (ch.isFavorite) counts.favorites++
      if (matchesCategory(ch, 'news')) counts.news++
      if (matchesCategory(ch, 'sports')) counts.sports++
      if (matchesCategory(ch, 'movies')) counts.movies++
      if (matchesCategory(ch, 'kids')) counts.kids++
      if (matchesCategory(ch, 'entertainment')) counts.entertainment++
    }
    return counts
  }, [channels])

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-indigo-500" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 text-red-400 gap-3">
        <AlertCircle className="h-10 w-10" />
        <p>Failed to load channel data</p>
      </div>
    )
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <Radio className="h-6 w-6 text-indigo-400" />
          <h1 className="text-2xl font-bold text-white">On Now</h1>
        </div>
        <p className="text-gray-400 text-sm">
          See what&apos;s currently airing across all your channels
        </p>
      </div>

      {/* Filter bar */}
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="flex gap-2 flex-wrap flex-1">
          {filterCategories.map((cat) => {
            const isActive = filter === cat.id
            const count = categoryCounts[cat.id] ?? 0
            return (
              <button
                key={cat.id}
                onClick={() => setFilter(cat.id)}
                className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-800 text-gray-300 hover:bg-gray-700 hover:text-white'
                }`}
              >
                <cat.icon className="h-4 w-4" />
                {cat.name}
                <span
                  className={`ml-1 text-xs ${isActive ? 'text-indigo-200' : 'text-gray-500'}`}
                >
                  {count}
                </span>
              </button>
            )
          })}
        </div>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search channels or programs..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full sm:w-72 pl-9 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>
      </div>

      {/* Channel count */}
      <p className="text-sm text-gray-500 mb-4">
        {filteredChannels.length} channel{filteredChannels.length !== 1 ? 's' : ''}
        {searchQuery && ` matching "${searchQuery}"`}
      </p>

      {/* Channel grid */}
      {filteredChannels.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-48 text-gray-500 gap-2">
          <Tv className="h-8 w-8" />
          <p>No channels match your filters</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-4">
          {filteredChannels.map((channel) => (
            <ChannelCard key={channel.id} channel={channel} />
          ))}
        </div>
      )}
    </div>
  )
}

export default OnNowPage
