import { useState, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Film,
  Trophy,
  Baby,
  Newspaper,
  Star,
  Clock,
  Search,
  Loader2,
  Tv,
  Circle,
  Sparkles,
  CircleDot,
  Check,
  X,
  Repeat,
  Sun,
  Moon,
  CalendarDays,
  LayoutGrid,
  ChevronRight,
} from 'lucide-react'
import { api } from '../api/client'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface Program {
  id: number
  channelId: string
  title: string
  subtitle?: string
  description?: string
  start: string
  end: string
  icon?: string
  art?: string
  category?: string
  isMovie: boolean
  isSports: boolean
  isKids: boolean
  isNews: boolean
  isPremiere: boolean
  isNew: boolean
  isLive: boolean
  teams?: string
  league?: string
  rating?: string
}

interface Channel {
  id: number
  name: string
  logo?: string
  number: number
}

interface OnLaterItem {
  program: Program
  channel?: Channel
  hasRecording: boolean
  recordingId?: number
}

interface OnLaterResponse {
  items: OnLaterItem[]
  totalCount: number
  startTime: string
  endTime: string
}

interface OnLaterStats {
  all: number
  tvshows: number
  movies: number
  sports: number
  kids: number
  news: number
  premieres: number
}

// ---------------------------------------------------------------------------
// Category config
// ---------------------------------------------------------------------------

type Category = 'all' | 'tvshows' | 'movies' | 'sports' | 'kids' | 'news'

const categories: { id: Category; name: string; icon: React.ElementType; color: string; activeText: string }[] = [
  { id: 'all',      name: 'All',       icon: LayoutGrid, color: 'bg-indigo-600',  activeText: 'text-white' },
  { id: 'tvshows',  name: 'TV Shows',  icon: Tv,         color: 'bg-blue-600',    activeText: 'text-white' },
  { id: 'movies',   name: 'Movies',    icon: Film,       color: 'bg-purple-600',  activeText: 'text-white' },
  { id: 'sports',   name: 'Sports',    icon: Trophy,     color: 'bg-green-600',   activeText: 'text-white' },
  { id: 'kids',     name: 'Kids',      icon: Baby,       color: 'bg-orange-500',  activeText: 'text-white' },
  { id: 'news',     name: 'News',      icon: Newspaper,  color: 'bg-red-600',     activeText: 'text-white' },
]

// ---------------------------------------------------------------------------
// Time-slot grouping
// ---------------------------------------------------------------------------

type TimeSlot = 'coming_up' | 'prime_time' | 'tonight' | 'tomorrow' | 'this_week'

interface TimeGroup {
  slot: TimeSlot
  label: string
  icon: React.ElementType
  items: OnLaterItem[]
}

function classifyTimeSlot(startStr: string): TimeSlot {
  const start = new Date(startStr)
  const now = new Date()

  const diffMin = (start.getTime() - now.getTime()) / 60000

  // Coming Up Next: within 30 minutes
  if (diffMin >= 0 && diffMin <= 30) {
    return 'coming_up'
  }

  const today = new Date(now)
  today.setHours(0, 0, 0, 0)

  const startDay = new Date(start)
  startDay.setHours(0, 0, 0, 0)

  const isToday = today.getTime() === startDay.getTime()

  // Prime Time: 8pm-11pm tonight
  if (isToday) {
    const hour = start.getHours()
    if (hour >= 20 && hour < 23) {
      return 'prime_time'
    }
    return 'tonight'
  }

  // Tomorrow
  const tomorrow = new Date(today)
  tomorrow.setDate(tomorrow.getDate() + 1)
  if (startDay.getTime() === tomorrow.getTime()) {
    return 'tomorrow'
  }

  return 'this_week'
}

function groupByTimeSlot(items: OnLaterItem[]): TimeGroup[] {
  const buckets: Record<TimeSlot, OnLaterItem[]> = {
    coming_up: [],
    prime_time: [],
    tonight: [],
    tomorrow: [],
    this_week: [],
  }

  for (const item of items) {
    const slot = classifyTimeSlot(item.program.start)
    buckets[slot].push(item)
  }

  const config: { slot: TimeSlot; label: string; icon: React.ElementType }[] = [
    { slot: 'coming_up',  label: 'Coming Up Next',  icon: Clock },
    { slot: 'prime_time', label: 'Prime Time',       icon: Star },
    { slot: 'tonight',    label: 'Tonight',           icon: Moon },
    { slot: 'tomorrow',   label: 'Tomorrow',          icon: Sun },
    { slot: 'this_week',  label: 'This Week',         icon: CalendarDays },
  ]

  return config
    .filter(c => buckets[c.slot].length > 0)
    .map(c => ({
      ...c,
      items: buckets[c.slot],
    }))
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

function formatTime(dateStr: string): string {
  const date = new Date(dateStr)
  return date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  const today = new Date()
  const tomorrow = new Date(today)
  tomorrow.setDate(tomorrow.getDate() + 1)

  if (date.toDateString() === today.toDateString()) {
    return 'Today'
  } else if (date.toDateString() === tomorrow.toDateString()) {
    return 'Tomorrow'
  }
  return date.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })
}

function getDuration(start: string, end: string): string {
  const startDate = new Date(start)
  const endDate = new Date(end)
  const minutes = Math.round((endDate.getTime() - startDate.getTime()) / 60000)
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0) {
    return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`
  }
  return `${mins}m`
}

function getCategoryBadge(program: Program): { label: string; className: string } | null {
  if (program.isSports) return { label: program.league || 'Sports', className: 'bg-green-600/80 text-green-100' }
  if (program.isMovie) return { label: 'Movie', className: 'bg-purple-600/80 text-purple-100' }
  if (program.isKids) return { label: 'Kids', className: 'bg-orange-500/80 text-orange-100' }
  if (program.isNews) return { label: 'News', className: 'bg-red-600/80 text-red-100' }
  if (program.category) return { label: program.category, className: 'bg-gray-600/80 text-gray-200' }
  return null
}

// ---------------------------------------------------------------------------
// Program Card component
// ---------------------------------------------------------------------------

function ProgramCard({
  item,
  onRecord,
  isRecording
}: {
  item: OnLaterItem
  onRecord: () => void
  isRecording: boolean
}) {
  const { program, channel, hasRecording } = item

  const handleRecordClick = (e: React.MouseEvent) => {
    e.stopPropagation()
    if (!hasRecording && channel) {
      onRecord()
    }
  }

  const badge = getCategoryBadge(program)

  return (
    <div className="group bg-gray-800/70 rounded-xl overflow-hidden border border-gray-700/50 hover:border-indigo-500/60 hover:bg-gray-800 transition-all duration-200">
      {/* Image / placeholder */}
      <div className="relative aspect-video bg-gray-900/60">
        {program.icon || program.art ? (
          <img
            src={program.icon || program.art}
            alt={program.title}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-gray-800 to-gray-900">
            <Tv className="w-10 h-10 text-gray-700" />
          </div>
        )}

        {/* Top-left badges */}
        <div className="absolute top-2 left-2 flex gap-1.5">
          {program.isLive && (
            <span className="px-2 py-0.5 bg-red-600 text-white text-xs font-semibold rounded-md flex items-center gap-1 shadow">
              <Circle className="w-2 h-2 fill-current" />
              LIVE
            </span>
          )}
          {program.isNew && (
            <span className="px-2 py-0.5 bg-emerald-600 text-white text-xs font-semibold rounded-md shadow">
              NEW
            </span>
          )}
          {program.isPremiere && (
            <span className="px-2 py-0.5 bg-yellow-500 text-gray-900 text-xs font-semibold rounded-md shadow">
              PREMIERE
            </span>
          )}
        </div>

        {/* Recording indicator */}
        {hasRecording && (
          <div className="absolute top-2 right-2">
            <span className="px-2 py-0.5 bg-red-600 text-white text-xs font-semibold rounded-md flex items-center gap-1 shadow">
              <CircleDot className="w-3 h-3" />
              REC
            </span>
          </div>
        )}

        {/* Duration overlay */}
        <div className="absolute bottom-2 right-2">
          <span className="px-2 py-0.5 bg-black/70 backdrop-blur-sm text-white text-xs rounded-md font-medium">
            {getDuration(program.start, program.end)}
          </span>
        </div>

        {/* Category badge */}
        {badge && (
          <div className="absolute bottom-2 left-2">
            <span className={`px-2 py-0.5 backdrop-blur-sm text-xs rounded-md font-medium ${badge.className}`}>
              {badge.label}
            </span>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-3 space-y-2">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0 flex-1">
            <h3 className="font-semibold text-white text-sm leading-tight truncate">{program.title}</h3>
            {program.subtitle && (
              <p className="text-xs text-gray-400 truncate mt-0.5">{program.subtitle}</p>
            )}
          </div>
          {/* Record button */}
          {channel && (
            <button
              onClick={handleRecordClick}
              disabled={hasRecording || isRecording}
              className={`flex-shrink-0 p-1.5 rounded-full transition-colors ${
                hasRecording
                  ? 'bg-red-600/20 text-red-400 cursor-default'
                  : isRecording
                  ? 'bg-gray-700 text-gray-500'
                  : 'bg-gray-700/60 text-gray-400 hover:bg-red-600 hover:text-white'
              }`}
              title={hasRecording ? 'Recording scheduled' : 'Record this program'}
            >
              {isRecording ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : hasRecording ? (
                <Check className="w-3.5 h-3.5" />
              ) : (
                <CircleDot className="w-3.5 h-3.5" />
              )}
            </button>
          )}
        </div>

        {/* Time + channel row */}
        <div className="flex items-center gap-2 text-xs">
          <span className="font-medium text-indigo-400 whitespace-nowrap">
            {formatDate(program.start)} {formatTime(program.start)}
          </span>
          {channel && (
            <>
              <span className="text-gray-600">|</span>
              <div className="flex items-center gap-1.5 min-w-0">
                {channel.logo && (
                  <img
                    src={channel.logo}
                    alt={channel.name}
                    className="w-4 h-4 rounded-sm object-contain bg-white/10 flex-shrink-0"
                  />
                )}
                <span className="text-gray-400 truncate">{channel.name}</span>
              </div>
            </>
          )}
        </div>

        {/* Tags row */}
        <div className="flex flex-wrap gap-1">
          {program.league && (
            <span className="px-1.5 py-0.5 bg-green-900/50 text-green-400 text-[10px] rounded font-medium">
              {program.league}
            </span>
          )}
          {program.rating && (
            <span className="px-1.5 py-0.5 bg-gray-700/60 text-gray-400 text-[10px] rounded font-medium">
              {program.rating}
            </span>
          )}
          {program.teams && (
            <span className="px-1.5 py-0.5 bg-gray-700/60 text-gray-400 text-[10px] rounded font-medium truncate max-w-[160px]">
              {program.teams}
            </span>
          )}
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Time group section component
// ---------------------------------------------------------------------------

function TimeGroupSection({
  group,
  onRecordClick,
  recordingProgramId,
}: {
  group: TimeGroup
  onRecordClick: (item: OnLaterItem) => void
  recordingProgramId: number | null
}) {
  const [collapsed, setCollapsed] = useState(false)
  const Icon = group.icon

  return (
    <section className="mb-8">
      <button
        onClick={() => setCollapsed(!collapsed)}
        className="flex items-center gap-3 mb-4 group/header cursor-pointer w-full text-left"
      >
        <div className="flex items-center gap-2 min-w-0">
          <Icon className="w-5 h-5 text-indigo-400 flex-shrink-0" />
          <h2 className="text-lg font-bold text-white">{group.label}</h2>
          <span className="text-sm text-gray-500 font-medium">({group.items.length})</span>
        </div>
        <div className="flex-1 h-px bg-gray-700/50" />
        <ChevronRight className={`w-4 h-4 text-gray-500 transition-transform ${collapsed ? '' : 'rotate-90'}`} />
      </button>

      {!collapsed && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
          {group.items.map((item) => (
            <ProgramCard
              key={`${item.program.id}-${item.program.start}`}
              item={item}
              onRecord={() => onRecordClick(item)}
              isRecording={recordingProgramId === item.program.id}
            />
          ))}
        </div>
      )}
    </section>
  )
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

export default function OnLater() {
  const queryClient = useQueryClient()
  const [selectedCategory, setSelectedCategory] = useState<Category>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [leagueFilter, setLeagueFilter] = useState('')
  const [recordingProgramId, setRecordingProgramId] = useState<number | null>(null)
  const [recordingModalItem, setRecordingModalItem] = useState<OnLaterItem | null>(null)

  // ---- Enrich mutation ----
  const enrichMutation = useMutation({
    mutationFn: async () => {
      const response = await fetch('/api/onlater/enrich?limit=200', {
        method: 'POST',
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    onSuccess: () => {
      setTimeout(() => {
        queryClient.invalidateQueries({ queryKey: ['onlater'] })
      }, 5000)
    }
  })

  // ---- Record mutation ----
  const recordMutation = useMutation({
    mutationFn: async ({ programId, channelId, seriesRecord }: { programId: number; channelId: number; seriesRecord?: boolean }) => {
      setRecordingProgramId(programId)
      const response = await fetch('/api/dvr/recordings/from-program', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || ''
        },
        body: JSON.stringify({ programId, channelId, seriesRecord: seriesRecord || false })
      })
      if (!response.ok) throw new Error('Failed to schedule recording')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['onlater'] })
      queryClient.invalidateQueries({ queryKey: ['onlater-search'] })
      setRecordingProgramId(null)
      setRecordingModalItem(null)
    },
    onError: () => {
      setRecordingProgramId(null)
    }
  })

  const handleRecord = (programId: number, channelId: number, seriesRecord?: boolean) => {
    recordMutation.mutate({ programId, channelId, seriesRecord })
  }

  const handleRecordClick = (item: OnLaterItem) => {
    setRecordingModalItem(item)
  }

  // ---- Stats query ----
  const { data: stats } = useQuery<OnLaterStats>({
    queryKey: ['onlater-stats'],
    queryFn: async () => {
      const response = await fetch('/api/onlater/stats', {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
  })

  // ---- Content query ----
  // For the new categories we use the new endpoints; legacy ones still work
  const categoryEndpoint = selectedCategory === 'all' ? 'all' :
                           selectedCategory === 'tvshows' ? 'tvshows' :
                           selectedCategory

  const { data, isLoading } = useQuery<OnLaterResponse>({
    queryKey: ['onlater', selectedCategory, leagueFilter],
    queryFn: async () => {
      let endpoint = `/api/onlater/${categoryEndpoint}`
      const params = new URLSearchParams()

      // Use a 7-day window so we have enough data for time grouping
      params.set('hours', '168')

      if (selectedCategory === 'sports' && leagueFilter) {
        params.set('league', leagueFilter)
      }

      const url = `${endpoint}?${params}`
      const response = await fetch(url, {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
  })

  // ---- Search query ----
  const { data: searchResults, isLoading: isSearching } = useQuery<OnLaterResponse>({
    queryKey: ['onlater-search', searchQuery],
    queryFn: async () => {
      const response = await fetch(`/api/onlater/search?q=${encodeURIComponent(searchQuery)}&hours=168`, {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    enabled: searchQuery.length > 2,
  })

  // ---- League filter ----
  const { data: leaguesData } = useQuery<{ leagues: string[] }>({
    queryKey: ['onlater-leagues'],
    queryFn: async () => {
      const response = await fetch('/api/onlater/leagues', {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
  })

  // ---- Derived data ----
  const displayItems = searchQuery.length > 2 ? searchResults?.items : data?.items

  const timeGroups = useMemo(() => {
    if (!displayItems || displayItems.length === 0) return []
    return groupByTimeSlot(displayItems)
  }, [displayItems])

  // Stat count for a given category
  const getStatCount = (cat: Category): number | undefined => {
    if (!stats) return undefined
    return stats[cat]
  }

  return (
    <div className="max-w-[1600px] mx-auto">
      {/* ---- Header ---- */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">On Later</h1>
          <p className="text-gray-400 text-sm mt-0.5">
            Browse upcoming programs across your channels
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* Enrich button */}
          <button
            onClick={() => enrichMutation.mutate()}
            disabled={enrichMutation.isPending}
            className="flex items-center gap-2 px-3.5 py-2 bg-purple-600/90 text-white text-sm rounded-lg hover:bg-purple-500 transition-colors disabled:opacity-50"
            title="Fetch artwork from TMDB for programs missing images"
          >
            {enrichMutation.isPending ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Sparkles className="w-4 h-4" />
            )}
            <span className="hidden sm:inline">Enrich Artwork</span>
          </button>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
            <input
              type="text"
              placeholder="Search upcoming..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 pr-4 py-2 bg-gray-800/80 border border-gray-700/60 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/60 focus:border-indigo-500/60 w-56"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* ---- Category tabs ---- */}
      <div className="flex gap-1.5 mb-6 overflow-x-auto pb-1 -mx-1 px-1 scrollbar-thin scrollbar-track-transparent scrollbar-thumb-gray-700">
        {categories.map((cat) => {
          const count = getStatCount(cat.id)
          const isActive = selectedCategory === cat.id
          return (
            <button
              key={cat.id}
              onClick={() => {
                setSelectedCategory(cat.id)
                setSearchQuery('')
                setLeagueFilter('')
              }}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-lg font-medium transition-all whitespace-nowrap text-sm ${
                isActive
                  ? `${cat.color} ${cat.activeText} shadow-lg shadow-${cat.color}/20`
                  : 'bg-gray-800/60 text-gray-400 hover:bg-gray-700/80 hover:text-gray-200'
              }`}
            >
              <cat.icon className="w-4 h-4" />
              {cat.name}
              {count !== undefined && count > 0 && (
                <span className={`text-xs font-normal px-1.5 py-0.5 rounded-full ${
                  isActive ? 'bg-white/20' : 'bg-gray-700/60 text-gray-500'
                }`}>
                  {count > 999 ? `${Math.floor(count/1000)}k+` : count}
                </span>
              )}
            </button>
          )
        })}
      </div>

      {/* ---- League filter for sports ---- */}
      {selectedCategory === 'sports' && leaguesData?.leagues && leaguesData.leagues.length > 0 && (
        <div className="flex gap-2 mb-6 overflow-x-auto pb-1">
          <button
            onClick={() => setLeagueFilter('')}
            className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
              !leagueFilter
                ? 'bg-green-600 text-white'
                : 'bg-gray-800/60 text-gray-400 hover:bg-gray-700'
            }`}
          >
            All Leagues
          </button>
          {leaguesData.leagues.map((league) => (
            <button
              key={league}
              onClick={() => setLeagueFilter(league)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
                leagueFilter === league
                  ? 'bg-green-600 text-white'
                  : 'bg-gray-800/60 text-gray-400 hover:bg-gray-700'
              }`}
            >
              {league}
            </button>
          ))}
        </div>
      )}

      {/* ---- Content ---- */}
      {isLoading || isSearching ? (
        <div className="flex flex-col items-center justify-center py-24 gap-3">
          <Loader2 className="w-8 h-8 text-indigo-500 animate-spin" />
          <p className="text-sm text-gray-500">Loading programs...</p>
        </div>
      ) : timeGroups.length > 0 ? (
        <>
          {timeGroups.map((group) => (
            <TimeGroupSection
              key={group.slot}
              group={group}
              onRecordClick={handleRecordClick}
              recordingProgramId={recordingProgramId}
            />
          ))}
          <div className="mt-4 pb-4 text-center text-xs text-gray-600">
            Showing {displayItems?.length ?? 0} programs across {timeGroups.length} time slots
          </div>
        </>
      ) : (
        <div className="flex flex-col items-center justify-center py-24 gap-3">
          <Tv className="w-14 h-14 text-gray-700" />
          <h3 className="text-lg font-semibold text-gray-300">No upcoming content</h3>
          <p className="text-sm text-gray-500 max-w-xs text-center">
            {searchQuery
              ? `No results found for "${searchQuery}"`
              : 'Check back later or try a different category'}
          </p>
        </div>
      )}

      {/* ---- Recording options modal ---- */}
      {recordingModalItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm" onClick={() => setRecordingModalItem(null)}>
          <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md mx-4 shadow-2xl border border-gray-700/50" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-start justify-between mb-4">
              <div className="min-w-0 flex-1">
                <h2 className="text-lg font-semibold text-white">Record Program</h2>
                <p className="text-gray-400 text-sm mt-1 truncate">{recordingModalItem.program.title}</p>
                {recordingModalItem.program.subtitle && (
                  <p className="text-gray-500 text-xs mt-0.5 truncate">{recordingModalItem.program.subtitle}</p>
                )}
              </div>
              <button
                onClick={() => setRecordingModalItem(null)}
                className="p-1 text-gray-400 hover:text-white hover:bg-gray-700 rounded ml-2"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              {/* Record single */}
              <button
                onClick={() => {
                  if (recordingModalItem.channel) {
                    handleRecord(recordingModalItem.program.id, recordingModalItem.channel.id, false)
                  }
                }}
                disabled={recordMutation.isPending}
                className="w-full flex items-center gap-4 p-4 bg-gray-700/60 hover:bg-gray-700 rounded-lg transition-colors text-left border border-gray-600/30"
              >
                <div className="flex-shrink-0 p-2 bg-indigo-600 rounded-lg">
                  <CircleDot className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-white text-sm">Record This Episode</p>
                  <p className="text-xs text-gray-400 mt-0.5">Record only this airing</p>
                </div>
                {recordMutation.isPending && (
                  <Loader2 className="w-5 h-5 text-indigo-400 animate-spin flex-shrink-0" />
                )}
              </button>

              {/* Record series */}
              <button
                onClick={() => {
                  if (recordingModalItem.channel) {
                    handleRecord(recordingModalItem.program.id, recordingModalItem.channel.id, true)
                  }
                }}
                disabled={recordMutation.isPending}
                className="w-full flex items-center gap-4 p-4 bg-gray-700/60 hover:bg-gray-700 rounded-lg transition-colors text-left border border-gray-600/30"
              >
                <div className="flex-shrink-0 p-2 bg-purple-600 rounded-lg">
                  <Repeat className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-white text-sm">Record Series</p>
                  <p className="text-xs text-gray-400 mt-0.5">Record all future episodes with this title</p>
                </div>
                {recordMutation.isPending && (
                  <Loader2 className="w-5 h-5 text-purple-400 animate-spin flex-shrink-0" />
                )}
              </button>
            </div>

            <button
              onClick={() => setRecordingModalItem(null)}
              className="w-full mt-4 py-2 text-sm text-gray-400 hover:text-white transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
