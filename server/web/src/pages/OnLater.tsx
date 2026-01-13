import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Film,
  Trophy,
  Baby,
  Newspaper,
  Star,
  Clock,
  Calendar,
  Search,
  Loader2,
  Tv,
  Circle,
  Sparkles,
  CircleDot,
  Check,
  X,
  Repeat
} from 'lucide-react'
import { api } from '../api/client'

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
  movies: number
  sports: number
  kids: number
  news: number
  premieres: number
}

type Category = 'movies' | 'sports' | 'kids' | 'news' | 'premieres' | 'tonight' | 'week'

const categories: { id: Category; name: string; icon: React.ElementType; color: string }[] = [
  { id: 'tonight', name: 'Tonight', icon: Clock, color: 'bg-indigo-600' },
  { id: 'movies', name: 'Movies', icon: Film, color: 'bg-purple-600' },
  { id: 'sports', name: 'Sports', icon: Trophy, color: 'bg-green-600' },
  { id: 'kids', name: 'Kids', icon: Baby, color: 'bg-orange-500' },
  { id: 'news', name: 'News', icon: Newspaper, color: 'bg-red-600' },
  { id: 'premieres', name: 'Premieres', icon: Star, color: 'bg-yellow-500' },
  { id: 'week', name: 'This Week', icon: Calendar, color: 'bg-blue-600' },
]

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
  } else {
    return date.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })
  }
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

  return (
    <div className="bg-gray-800 rounded-lg overflow-hidden hover:ring-2 hover:ring-indigo-500 transition-all cursor-pointer">
      {/* Image/Placeholder */}
      <div className="relative aspect-video bg-gray-700">
        {program.icon || program.art ? (
          <img
            src={program.icon || program.art}
            alt={program.title}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <Tv className="w-12 h-12 text-gray-600" />
          </div>
        )}

        {/* Badges */}
        <div className="absolute top-2 left-2 flex gap-1">
          {program.isLive && (
            <span className="px-2 py-0.5 bg-red-600 text-white text-xs font-medium rounded flex items-center gap-1">
              <Circle className="w-2 h-2 fill-current" />
              LIVE
            </span>
          )}
          {program.isNew && (
            <span className="px-2 py-0.5 bg-green-600 text-white text-xs font-medium rounded">
              NEW
            </span>
          )}
          {program.isPremiere && (
            <span className="px-2 py-0.5 bg-yellow-500 text-black text-xs font-medium rounded">
              PREMIERE
            </span>
          )}
        </div>

        {/* Recording indicator */}
        {hasRecording && (
          <div className="absolute top-2 right-2">
            <span className="px-2 py-0.5 bg-red-600 text-white text-xs font-medium rounded flex items-center gap-1">
              <CircleDot className="w-3 h-3" />
              REC
            </span>
          </div>
        )}

        {/* Duration */}
        <div className="absolute bottom-2 right-2">
          <span className="px-2 py-0.5 bg-black/70 text-white text-xs rounded">
            {getDuration(program.start, program.end)}
          </span>
        </div>
      </div>

      {/* Content */}
      <div className="p-3">
        <div className="flex items-start justify-between gap-2">
          <h3 className="font-medium text-white truncate flex-1">{program.title}</h3>
          {/* Record button */}
          {channel && (
            <button
              onClick={handleRecordClick}
              disabled={hasRecording || isRecording}
              className={`flex-shrink-0 p-1.5 rounded-full transition-colors ${
                hasRecording
                  ? 'bg-red-600 text-white cursor-default'
                  : isRecording
                  ? 'bg-gray-600 text-gray-400'
                  : 'bg-gray-700 text-gray-300 hover:bg-red-600 hover:text-white'
              }`}
              title={hasRecording ? 'Recording scheduled' : 'Record this program'}
            >
              {isRecording ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : hasRecording ? (
                <Check className="w-4 h-4" />
              ) : (
                <CircleDot className="w-4 h-4" />
              )}
            </button>
          )}
        </div>
        {program.subtitle && (
          <p className="text-sm text-gray-400 truncate">{program.subtitle}</p>
        )}

        <div className="mt-2 flex items-center gap-2 text-xs text-gray-400">
          <span className="font-medium text-indigo-400">
            {formatDate(program.start)} {formatTime(program.start)}
          </span>
          {channel && (
            <>
              <span>•</span>
              <span className="truncate">{channel.name}</span>
            </>
          )}
        </div>

        {/* Tags */}
        <div className="mt-2 flex flex-wrap gap-1">
          {program.category && (
            <span className="px-2 py-0.5 bg-gray-700 text-gray-300 text-xs rounded">
              {program.category}
            </span>
          )}
          {program.league && (
            <span className="px-2 py-0.5 bg-green-900 text-green-300 text-xs rounded">
              {program.league}
            </span>
          )}
          {program.rating && (
            <span className="px-2 py-0.5 bg-gray-700 text-gray-300 text-xs rounded">
              {program.rating}
            </span>
          )}
        </div>

        {program.teams && (
          <p className="mt-1 text-xs text-gray-500 truncate">
            {program.teams}
          </p>
        )}
      </div>
    </div>
  )
}

export default function OnLater() {
  const queryClient = useQueryClient()
  const [selectedCategory, setSelectedCategory] = useState<Category>('tonight')
  const [searchQuery, setSearchQuery] = useState('')
  const [leagueFilter, setLeagueFilter] = useState('')

  // Track which program is being recorded
  const [recordingProgramId, setRecordingProgramId] = useState<number | null>(null)

  // Enrich EPG mutation
  const enrichMutation = useMutation({
    mutationFn: async () => {
      const response = await fetch('/api/onlater/enrich?limit=200', {
        method: 'POST',
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    onSuccess: () => {
      // Refetch data after a delay to show new artwork
      setTimeout(() => {
        queryClient.invalidateQueries({ queryKey: ['onlater'] })
      }, 5000)
    }
  })

  // State for recording options modal
  const [recordingModalItem, setRecordingModalItem] = useState<OnLaterItem | null>(null)

  // Record program mutation
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
      if (!response.ok) {
        throw new Error('Failed to schedule recording')
      }
      return response.json()
    },
    onSuccess: () => {
      // Refresh the data to show updated recording status
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
    // Show modal to choose single or series recording
    setRecordingModalItem(item)
  }

  // Fetch stats
  const { data: stats } = useQuery<OnLaterStats>({
    queryKey: ['onlater-stats'],
    queryFn: async () => {
      const response = await fetch('/api/onlater/stats', {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
  })

  // Fetch content based on selected category
  const { data, isLoading } = useQuery<OnLaterResponse>({
    queryKey: ['onlater', selectedCategory, leagueFilter],
    queryFn: async () => {
      let endpoint = `/api/onlater/${selectedCategory}`
      const params = new URLSearchParams()

      if (selectedCategory === 'sports' && leagueFilter) {
        params.set('league', leagueFilter)
      }

      const url = params.toString() ? `${endpoint}?${params}` : endpoint
      const response = await fetch(url, {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
  })

  // Search
  const { data: searchResults, isLoading: isSearching } = useQuery<OnLaterResponse>({
    queryKey: ['onlater-search', searchQuery],
    queryFn: async () => {
      const response = await fetch(`/api/onlater/search?q=${encodeURIComponent(searchQuery)}`, {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    enabled: searchQuery.length > 2,
  })

  // Fetch leagues for filter
  const { data: leaguesData } = useQuery<{ leagues: string[] }>({
    queryKey: ['onlater-leagues'],
    queryFn: async () => {
      const response = await fetch('/api/onlater/leagues', {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
  })

  const displayItems = searchQuery.length > 2 ? searchResults?.items : data?.items

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">On Later</h1>
          <p className="text-gray-400">Browse upcoming content from your EPG</p>
        </div>

        <div className="flex items-center gap-3">
          {/* Enrich Button */}
          <button
            onClick={() => enrichMutation.mutate()}
            disabled={enrichMutation.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-500 transition-colors disabled:opacity-50"
            title="Fetch artwork from TMDB for programs missing images"
          >
            {enrichMutation.isPending ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Sparkles className="w-4 h-4" />
            )}
            Enrich Artwork
          </button>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search upcoming..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 w-64"
            />
          </div>
        </div>
      </div>

      {/* Stats Bar */}
      {stats && (
        <div className="grid grid-cols-5 gap-4 mb-6">
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-purple-400">
              <Film className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.movies}</span>
            </div>
            <p className="text-sm text-gray-400">Movies</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-green-400">
              <Trophy className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.sports}</span>
            </div>
            <p className="text-sm text-gray-400">Sports</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-orange-400">
              <Baby className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.kids}</span>
            </div>
            <p className="text-sm text-gray-400">Kids</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-red-400">
              <Newspaper className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.news}</span>
            </div>
            <p className="text-sm text-gray-400">News</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-yellow-400">
              <Star className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.premieres}</span>
            </div>
            <p className="text-sm text-gray-400">Premieres</p>
          </div>
        </div>
      )}

      {/* Category Tabs */}
      <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
        {categories.map((cat) => (
          <button
            key={cat.id}
            onClick={() => {
              setSelectedCategory(cat.id)
              setSearchQuery('')
            }}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors whitespace-nowrap ${
              selectedCategory === cat.id
                ? `${cat.color} text-white`
                : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
            }`}
          >
            <cat.icon className="w-4 h-4" />
            {cat.name}
          </button>
        ))}
      </div>

      {/* League Filter for Sports */}
      {selectedCategory === 'sports' && leaguesData?.leagues && (
        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setLeagueFilter('')}
            className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
              !leagueFilter
                ? 'bg-green-600 text-white'
                : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
            }`}
          >
            All Leagues
          </button>
          {leaguesData.leagues.map((league) => (
            <button
              key={league}
              onClick={() => setLeagueFilter(league)}
              className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                leagueFilter === league
                  ? 'bg-green-600 text-white'
                  : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
              }`}
            >
              {league}
            </button>
          ))}
        </div>
      )}

      {/* Content Grid */}
      {isLoading || isSearching ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      ) : displayItems && displayItems.length > 0 ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
          {displayItems.map((item) => (
            <ProgramCard
              key={item.program.id}
              item={item}
              onRecord={() => handleRecordClick(item)}
              isRecording={recordingProgramId === item.program.id}
            />
          ))}
        </div>
      ) : (
        <div className="text-center py-12">
          <Tv className="w-16 h-16 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No upcoming content</h3>
          <p className="text-gray-400">
            {searchQuery
              ? `No results found for "${searchQuery}"`
              : 'Check back later or try a different category'}
          </p>
        </div>
      )}

      {/* Results count */}
      {displayItems && displayItems.length > 0 && (
        <div className="mt-6 text-center text-sm text-gray-400">
          Showing {displayItems.length} programs
        </div>
      )}

      {/* Recording Options Modal */}
      {recordingModalItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md mx-4 shadow-2xl">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="text-lg font-semibold text-white">Record Program</h2>
                <p className="text-gray-400 text-sm mt-1">{recordingModalItem.program.title}</p>
              </div>
              <button
                onClick={() => setRecordingModalItem(null)}
                className="p-1 text-gray-400 hover:text-white hover:bg-gray-700 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              {/* Record Single Episode */}
              <button
                onClick={() => {
                  if (recordingModalItem.channel) {
                    handleRecord(recordingModalItem.program.id, recordingModalItem.channel.id, false)
                  }
                }}
                disabled={recordMutation.isPending}
                className="w-full flex items-center gap-4 p-4 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors text-left"
              >
                <div className="flex-shrink-0 p-2 bg-indigo-600 rounded-lg">
                  <CircleDot className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1">
                  <p className="font-medium text-white">Record This Episode</p>
                  <p className="text-sm text-gray-400">Record only this airing</p>
                </div>
                {recordMutation.isPending && (
                  <Loader2 className="w-5 h-5 text-indigo-400 animate-spin" />
                )}
              </button>

              {/* Record Series */}
              <button
                onClick={() => {
                  if (recordingModalItem.channel) {
                    handleRecord(recordingModalItem.program.id, recordingModalItem.channel.id, true)
                  }
                }}
                disabled={recordMutation.isPending}
                className="w-full flex items-center gap-4 p-4 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors text-left"
              >
                <div className="flex-shrink-0 p-2 bg-purple-600 rounded-lg">
                  <Repeat className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1">
                  <p className="font-medium text-white">Record Series</p>
                  <p className="text-sm text-gray-400">Record all future episodes with this title</p>
                </div>
                {recordMutation.isPending && (
                  <Loader2 className="w-5 h-5 text-purple-400 animate-spin" />
                )}
              </button>
            </div>

            <button
              onClick={() => setRecordingModalItem(null)}
              className="w-full mt-4 py-2 text-gray-400 hover:text-white transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
