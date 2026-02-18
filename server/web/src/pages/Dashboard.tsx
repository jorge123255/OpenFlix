import {
  FolderOpen,
  Tv,
  Video,
  HardDrive,
  Play,
  ChevronLeft,
  ChevronRight,
  Film,
  Clapperboard,
  Clock,
} from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'
import type {
  DashboardUpNextItem,
  DashboardRecentShow,
  DashboardRecentMovie,
  DashboardRecentRecording,
} from '../api/client'
import { useLibraries } from '../hooks/useLibraries'
import { useM3USources } from '../hooks/useLiveTV'
import { useRecordings } from '../hooks/useDVR'
import { useRef, useCallback } from 'react'
import { Link } from 'react-router-dom'

function useServerStatus() {
  return useQuery({
    queryKey: ['serverStatus'],
    queryFn: () => api.getServerStatus(),
    refetchInterval: 10000,
  })
}

function useDashboardData() {
  return useQuery({
    queryKey: ['dashboardData'],
    queryFn: () => api.getDashboardData(),
    refetchInterval: 60000,
  })
}

// ---------- Quick Stats Bar ----------

function QuickStatBadge({
  icon: Icon,
  label,
  value,
  color,
}: {
  icon: React.ElementType
  label: string
  value: string | number
  color: string
}) {
  return (
    <div className="flex items-center gap-3 bg-gray-800/60 rounded-lg px-4 py-3 min-w-[140px]">
      <div className={`p-2 rounded-md ${color}`}>
        <Icon className="h-4 w-4 text-white" />
      </div>
      <div>
        <p className="text-xs text-gray-400 leading-none">{label}</p>
        <p className="text-lg font-semibold text-white leading-tight">{value}</p>
      </div>
    </div>
  )
}

// ---------- Scroll Container ----------

function ScrollRow({
  title,
  icon: Icon,
  children,
  emptyMessage,
  isEmpty,
}: {
  title: string
  icon: React.ElementType
  children: React.ReactNode
  emptyMessage: string
  isEmpty: boolean
}) {
  const scrollRef = useRef<HTMLDivElement>(null)

  const scroll = useCallback((direction: 'left' | 'right') => {
    if (!scrollRef.current) return
    const scrollAmount = scrollRef.current.clientWidth * 0.75
    scrollRef.current.scrollBy({
      left: direction === 'left' ? -scrollAmount : scrollAmount,
      behavior: 'smooth',
    })
  }, [])

  return (
    <div className="mb-8">
      <div className="flex items-center justify-between mb-3 px-1">
        <h2 className="text-lg font-semibold text-white flex items-center gap-2">
          <Icon className="h-5 w-5 text-gray-400" />
          {title}
        </h2>
        {!isEmpty && (
          <div className="flex gap-1">
            <button
              onClick={() => scroll('left')}
              className="p-1.5 rounded-md bg-gray-700/50 hover:bg-gray-700 text-gray-400 hover:text-white transition-colors"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <button
              onClick={() => scroll('right')}
              className="p-1.5 rounded-md bg-gray-700/50 hover:bg-gray-700 text-gray-400 hover:text-white transition-colors"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        )}
      </div>
      {isEmpty ? (
        <div className="bg-gray-800/40 rounded-xl p-8 text-center">
          <p className="text-gray-500 text-sm">{emptyMessage}</p>
        </div>
      ) : (
        <div
          ref={scrollRef}
          className="flex gap-4 overflow-x-auto pb-2 scrollbar-hide"
          style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
        >
          {children}
        </div>
      )}
    </div>
  )
}

// ---------- Poster Card (shared base) ----------

function PosterImage({ src, alt }: { src?: string; alt: string }) {
  if (src) {
    return (
      <img
        src={src}
        alt={alt}
        className="w-full h-full object-cover"
        loading="lazy"
      />
    )
  }
  return (
    <div className="w-full h-full bg-gradient-to-br from-gray-700 to-gray-800 flex items-center justify-center">
      <Film className="h-8 w-8 text-gray-600" />
    </div>
  )
}

// ---------- Up Next Card ----------

function UpNextCard({ item }: { item: DashboardUpNextItem }) {
  const progress =
    item.duration && item.duration > 0
      ? Math.min(100, Math.round((item.viewOffset / item.duration) * 100))
      : 0

  const showTitle = item.grandparentTitle || item.title
  const episodeInfo =
    item.type === 'episode' && item.parentIndex && item.index
      ? `S${item.parentIndex} E${item.index}`
      : null

  const posterSrc = item.grandparentThumb || item.parentThumb || item.thumb

  return (
    <Link
      to="/ui/media"
      className="flex-shrink-0 w-[160px] group cursor-pointer"
    >
      <div className="relative aspect-[2/3] rounded-lg overflow-hidden bg-gray-800 mb-2">
        <PosterImage src={posterSrc} alt={showTitle} />
        {/* Hover play overlay */}
        <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
          <div className="bg-white/20 backdrop-blur-sm rounded-full p-3">
            <Play className="h-6 w-6 text-white fill-white" />
          </div>
        </div>
        {/* Progress bar */}
        {progress > 0 && (
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-gray-700">
            <div
              className="h-full bg-blue-500 transition-all"
              style={{ width: `${progress}%` }}
            />
          </div>
        )}
      </div>
      <div className="px-0.5">
        <p className="text-sm text-white font-medium truncate leading-tight">
          {showTitle}
        </p>
        {episodeInfo && (
          <p className="text-xs text-gray-400 truncate mt-0.5">
            {episodeInfo}
            {item.title !== showTitle ? ` \u2022 ${item.title}` : ''}
          </p>
        )}
        {!episodeInfo && item.year ? (
          <p className="text-xs text-gray-400 mt-0.5">{item.year}</p>
        ) : null}
      </div>
    </Link>
  )
}

// ---------- Recent Show Card ----------

function RecentShowCard({ show }: { show: DashboardRecentShow }) {
  return (
    <Link
      to="/ui/media"
      className="flex-shrink-0 w-[160px] group cursor-pointer"
    >
      <div className="relative aspect-[2/3] rounded-lg overflow-hidden bg-gray-800 mb-2">
        <PosterImage src={show.thumb} alt={show.title} />
        {/* Episode count badge */}
        {show.leafCount != null && show.leafCount > 0 && (
          <div className="absolute top-2 right-2 bg-blue-600 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-md shadow-lg">
            {show.leafCount} ep
          </div>
        )}
        {/* Hover overlay */}
        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity" />
      </div>
      <div className="px-0.5">
        <p className="text-sm text-white font-medium truncate leading-tight">
          {show.title}
        </p>
        {show.year ? (
          <p className="text-xs text-gray-400 mt-0.5">{show.year}</p>
        ) : null}
      </div>
    </Link>
  )
}

// ---------- Recent Movie Card ----------

function RecentMovieCard({ movie }: { movie: DashboardRecentMovie }) {
  return (
    <Link
      to="/ui/media"
      className="flex-shrink-0 w-[160px] group cursor-pointer"
    >
      <div className="relative aspect-[2/3] rounded-lg overflow-hidden bg-gray-800 mb-2">
        <PosterImage src={movie.thumb} alt={movie.title} />
        {/* Rating badge */}
        {movie.rating != null && movie.rating > 0 && (
          <div className="absolute top-2 left-2 bg-yellow-600/90 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-md shadow-lg">
            {movie.rating.toFixed(1)}
          </div>
        )}
        {/* Hover overlay */}
        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-end">
          <div className="p-3 w-full">
            <p className="text-xs text-gray-200 line-clamp-3 opacity-0 group-hover:opacity-100 transition-opacity">
              {movie.summary || ''}
            </p>
          </div>
        </div>
      </div>
      <div className="px-0.5">
        <p className="text-sm text-white font-medium truncate leading-tight">
          {movie.title}
        </p>
        <p className="text-xs text-gray-400 mt-0.5">
          {movie.year || ''}
          {movie.studio ? ` \u2022 ${movie.studio}` : ''}
        </p>
      </div>
    </Link>
  )
}

// ---------- Recent Recording Card ----------

function RecentRecordingCard({ recording }: { recording: DashboardRecentRecording }) {
  return (
    <Link
      to="/ui/dvr"
      className="flex-shrink-0 w-[160px] group cursor-pointer"
    >
      <div className="relative aspect-[2/3] rounded-lg overflow-hidden bg-gray-800 mb-2">
        <PosterImage src={recording.thumb} alt={recording.title} />
        {/* Channel badge */}
        {recording.channelName && (
          <div className="absolute top-2 right-2 bg-gray-900/80 text-gray-200 text-[10px] font-medium px-1.5 py-0.5 rounded-md shadow-lg max-w-[100px] truncate">
            {recording.channelName}
          </div>
        )}
        {/* Hover overlay */}
        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity" />
      </div>
      <div className="px-0.5">
        <p className="text-sm text-white font-medium truncate leading-tight">
          {recording.title}
        </p>
        <p className="text-xs text-gray-400 mt-0.5">
          {recording.year || ''}
          {recording.duration ? ` \u2022 ${recording.duration} min` : ''}
        </p>
      </div>
    </Link>
  )
}

// ---------- Main Dashboard ----------

export function DashboardPage() {
  const { data: status } = useServerStatus()
  const { data: dashboard, isLoading: dashLoading } = useDashboardData()
  const { data: libraries } = useLibraries()
  const { data: m3uSources } = useM3USources()
  const { data: recordings } = useRecordings()

  const totalChannels =
    m3uSources?.reduce((acc, s) => acc + (s.channelCount || 0), 0) || 0
  const scheduledRecordings =
    recordings?.filter((r) => r.status === 'scheduled').length || 0
  const activeStreams = status?.sessions.active || 0

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-white">Home</h1>
      </div>

      {/* Quick Stats Row */}
      <div className="flex gap-3 overflow-x-auto pb-2 mb-8" style={{ scrollbarWidth: 'none' }}>
        <QuickStatBadge
          icon={FolderOpen}
          label="Libraries"
          value={status?.libraries.count || libraries?.length || 0}
          color="bg-blue-600"
        />
        <QuickStatBadge
          icon={Tv}
          label="Channels"
          value={status?.livetv.channels || totalChannels}
          color="bg-green-600"
        />
        <QuickStatBadge
          icon={Video}
          label="Recordings"
          value={
            (status?.dvr.scheduled || scheduledRecordings) +
            (status?.dvr.completed || 0)
          }
          color="bg-orange-600"
        />
        <QuickStatBadge
          icon={HardDrive}
          label="Active Streams"
          value={activeStreams}
          color="bg-purple-600"
        />
      </div>

      {/* Loading state */}
      {dashLoading && (
        <div className="flex items-center justify-center py-16">
          <div className="animate-spin rounded-full h-8 w-8 border-2 border-gray-600 border-t-blue-500" />
        </div>
      )}

      {/* Content Rows */}
      {dashboard && (
        <>
          {/* Up Next */}
          <ScrollRow
            title="Up Next"
            icon={Play}
            isEmpty={dashboard.upNext.length === 0}
            emptyMessage="Nothing in progress. Start watching something to see it here."
          >
            {dashboard.upNext.map((item) => (
              <UpNextCard key={item.id} item={item} />
            ))}
          </ScrollRow>

          {/* Recently Updated Shows */}
          <ScrollRow
            title="Recently Updated Shows"
            icon={Clapperboard}
            isEmpty={dashboard.recentShows.length === 0}
            emptyMessage="No TV shows in your library yet."
          >
            {dashboard.recentShows.map((show) => (
              <RecentShowCard key={show.id} show={show} />
            ))}
          </ScrollRow>

          {/* Recently Added Movies */}
          <ScrollRow
            title="Recently Added Movies"
            icon={Film}
            isEmpty={dashboard.recentMovies.length === 0}
            emptyMessage="No movies in your library yet."
          >
            {dashboard.recentMovies.map((movie) => (
              <RecentMovieCard key={movie.id} movie={movie} />
            ))}
          </ScrollRow>

          {/* Recent Recordings */}
          <ScrollRow
            title="Recent Recordings"
            icon={Clock}
            isEmpty={dashboard.recentRecordings.length === 0}
            emptyMessage="No completed recordings yet."
          >
            {dashboard.recentRecordings.map((rec) => (
              <RecentRecordingCard key={rec.id} recording={rec} />
            ))}
          </ScrollRow>
        </>
      )}
    </div>
  )
}
