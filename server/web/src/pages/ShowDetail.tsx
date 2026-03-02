import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'
import {
  ArrowLeft,
  Play,
  Tv,
  Calendar,
  Star,
  CheckCircle2,
  Clock,
  Film,
  Loader2,
} from 'lucide-react'

// Types matching the Plex-compatible API response
interface MetadataItem {
  ratingKey: number
  key: string
  guid: string
  type: string
  title: string
  originalTitle?: string
  titleSort?: string
  summary?: string
  tagline?: string
  contentRating?: string
  studio?: string
  year?: number
  duration?: number
  rating?: number
  audienceRating?: number
  thumb?: string
  art?: string
  parentRatingKey?: number
  grandparentRatingKey?: number
  index?: number
  parentIndex?: number
  parentTitle?: string
  grandparentTitle?: string
  parentThumb?: string
  grandparentThumb?: string
  grandparentArt?: string
  childCount?: number
  leafCount?: number
  viewedLeafCount?: number
  addedAt?: number
  updatedAt?: number
  originallyAvailableAt?: string
  Genre?: Array<{ tag: string }>
  Role?: Array<{ tag: string; role: string; thumb?: string }>
  Director?: Array<{ tag: string; thumb?: string }>
  Writer?: Array<{ tag: string; thumb?: string }>
  Media?: Array<{
    id: number
    duration: number
    bitrate: number
    width: number
    height: number
    container: string
    videoCodec: string
    audioCodec: string
    Part?: Array<{
      id: number
      key: string
      duration: number
      file: string
      size: number
      container: string
    }>
  }>
}

interface MediaContainerResponse {
  MediaContainer: {
    size: number
    Metadata?: MetadataItem[]
  }
}

interface ChildrenResponse {
  MediaContainer: {
    size: number
    key?: string
    parentRatingKey?: number
    parentTitle?: string
    parentYear?: number
    Metadata?: MetadataItem[]
  }
}

function formatDuration(ms: number): string {
  const minutes = Math.round(ms / 60000)
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const remainMinutes = minutes % 60
  return remainMinutes > 0 ? `${hours}h ${remainMinutes}m` : `${hours}h`
}

function formatDate(dateStr?: string | number): string {
  if (!dateStr) return ''
  const date = typeof dateStr === 'number' ? new Date(dateStr * 1000) : new Date(dateStr)
  return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
}

function getImageUrl(url?: string): string | undefined {
  if (!url) return undefined
  // TMDB image URLs start with /  followed by a path or are full https URLs
  if (url.startsWith('http')) return url
  if (url.startsWith('/library/')) return url
  // Assume it's a TMDB path
  return `https://image.tmdb.org/t/p/original${url}`
}

function getPosterUrl(url?: string): string | undefined {
  if (!url) return undefined
  if (url.startsWith('http')) return url
  if (url.startsWith('/library/')) return url
  return `https://image.tmdb.org/t/p/w500${url}`
}

export function ShowDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [selectedSeasonIndex, setSelectedSeasonIndex] = useState<number | null>(null)

  // Fetch show metadata
  const { data: showData, isLoading: showLoading } = useQuery<MediaContainerResponse>({
    queryKey: ['show-detail', id],
    queryFn: async () => {
      const response = await api.client.get(`/library/metadata/${id}`)
      return response.data
    },
    enabled: !!id,
  })

  const show = showData?.MediaContainer?.Metadata?.[0]

  // Fetch seasons (children of show)
  const { data: seasonsData, isLoading: seasonsLoading } = useQuery<ChildrenResponse>({
    queryKey: ['show-seasons', id],
    queryFn: async () => {
      const response = await api.client.get(`/library/metadata/${id}/children`)
      return response.data
    },
    enabled: !!id,
  })

  const seasons = seasonsData?.MediaContainer?.Metadata ?? []

  // Auto-select first season when loaded
  const effectiveSeasonId =
    selectedSeasonIndex !== null
      ? seasons[selectedSeasonIndex]?.ratingKey
      : seasons.length > 0
        ? seasons[0]?.ratingKey
        : null

  const currentSeasonIdx = selectedSeasonIndex ?? (seasons.length > 0 ? 0 : null)

  // Fetch episodes for selected season
  const { data: episodesData, isLoading: episodesLoading } = useQuery<ChildrenResponse>({
    queryKey: ['season-episodes', effectiveSeasonId],
    queryFn: async () => {
      const response = await api.client.get(`/library/metadata/${effectiveSeasonId}/children`)
      return response.data
    },
    enabled: !!effectiveSeasonId,
  })

  const episodes = episodesData?.MediaContainer?.Metadata ?? []

  // Compute stats
  const totalEpisodes = show?.leafCount ?? 0
  const watchedEpisodes = show?.viewedLeafCount ?? 0
  const unwatchedEpisodes = totalEpisodes - watchedEpisodes

  if (showLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="h-8 w-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  if (!show) {
    return (
      <div className="flex flex-col items-center justify-center h-96 gap-4">
        <Tv className="h-12 w-12 text-gray-500" />
        <p className="text-gray-400 text-lg">Show not found</p>
        <Link
          to="/ui/media"
          className="text-indigo-400 hover:text-indigo-300 flex items-center gap-2"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Media
        </Link>
      </div>
    )
  }

  const backdropUrl = getImageUrl(show.art || show.grandparentArt)
  const posterUrl = getPosterUrl(show.thumb)
  const genres = show.Genre?.map((g) => g.tag) ?? []

  return (
    <div className="space-y-6 -mt-6 -mx-6">
      {/* Hero Banner */}
      <div className="relative h-[420px] overflow-hidden">
        {backdropUrl ? (
          <img
            src={backdropUrl}
            alt=""
            className="absolute inset-0 w-full h-full object-cover"
          />
        ) : (
          <div className="absolute inset-0 bg-gradient-to-br from-gray-800 to-gray-900" />
        )}
        {/* Gradient overlays */}
        <div className="absolute inset-0 bg-gradient-to-t from-gray-900 via-gray-900/60 to-transparent" />
        <div className="absolute inset-0 bg-gradient-to-r from-gray-900/80 via-transparent to-transparent" />

        {/* Content over hero */}
        <div className="absolute bottom-0 left-0 right-0 p-6 flex gap-6">
          {/* Poster */}
          <div className="flex-shrink-0 w-48 h-72 rounded-lg overflow-hidden shadow-2xl bg-gray-800 hidden sm:block">
            {posterUrl ? (
              <img
                src={posterUrl}
                alt={show.title}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center">
                <Tv className="h-16 w-16 text-gray-600" />
              </div>
            )}
          </div>

          {/* Info */}
          <div className="flex-1 min-w-0 flex flex-col justify-end">
            <h1 className="text-3xl md:text-4xl font-bold text-white mb-2 drop-shadow-lg">
              {show.title}
            </h1>
            <div className="flex flex-wrap items-center gap-3 text-sm text-gray-300 mb-3">
              {show.year && <span>{show.year}</span>}
              {show.contentRating && (
                <span className="px-2 py-0.5 border border-gray-500 rounded text-xs">
                  {show.contentRating}
                </span>
              )}
              {show.childCount !== undefined && show.childCount > 0 && (
                <span>{show.childCount} Season{show.childCount !== 1 ? 's' : ''}</span>
              )}
              {totalEpisodes > 0 && (
                <span>{totalEpisodes} Episode{totalEpisodes !== 1 ? 's' : ''}</span>
              )}
              {show.studio && <span className="text-gray-400">{show.studio}</span>}
              {show.rating && show.rating > 0 && (
                <span className="flex items-center gap-1">
                  <Star className="h-3.5 w-3.5 text-yellow-400 fill-yellow-400" />
                  {show.rating.toFixed(1)}
                </span>
              )}
            </div>
            {genres.length > 0 && (
              <div className="flex flex-wrap gap-2 mb-3">
                {genres.map((g) => (
                  <span
                    key={g}
                    className="px-2.5 py-1 bg-gray-700/70 text-gray-200 rounded-full text-xs"
                  >
                    {g}
                  </span>
                ))}
              </div>
            )}
            {show.summary && (
              <p className="text-gray-300 text-sm leading-relaxed line-clamp-3 max-w-3xl">
                {show.summary}
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Action Buttons & Stats */}
      <div className="px-6 flex flex-wrap items-center gap-4">
        <Link
          to="/ui/media"
          className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg flex items-center gap-2 text-sm transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back
        </Link>
        {episodes.length > 0 && (
          <button className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg flex items-center gap-2 text-sm font-medium transition-colors">
            <Play className="h-4 w-4" />
            Play Next Episode
          </button>
        )}

        {/* Stats */}
        <div className="ml-auto flex items-center gap-4 text-sm text-gray-400">
          {totalEpisodes > 0 && (
            <>
              <span className="flex items-center gap-1.5">
                <Film className="h-4 w-4" />
                {totalEpisodes} total
              </span>
              {unwatchedEpisodes > 0 && (
                <span className="flex items-center gap-1.5 text-indigo-400">
                  <Clock className="h-4 w-4" />
                  {unwatchedEpisodes} unwatched
                </span>
              )}
              {watchedEpisodes > 0 && (
                <span className="flex items-center gap-1.5 text-green-400">
                  <CheckCircle2 className="h-4 w-4" />
                  {watchedEpisodes} watched
                </span>
              )}
            </>
          )}
        </div>
      </div>

      {/* Season Tabs */}
      {seasons.length > 0 && (
        <div className="px-6">
          <div className="flex gap-2 overflow-x-auto pb-2">
            {seasons.map((season, idx) => (
              <button
                key={season.ratingKey}
                onClick={() => setSelectedSeasonIndex(idx)}
                className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
                  currentSeasonIdx === idx
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
                }`}
              >
                {season.title || `Season ${season.index ?? idx + 1}`}
                {season.leafCount !== undefined && season.leafCount > 0 && (
                  <span className="ml-1.5 text-xs opacity-70">({season.leafCount})</span>
                )}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Episode List */}
      <div className="px-6 pb-6">
        {(seasonsLoading || episodesLoading) ? (
          <div className="flex items-center justify-center h-32">
            <Loader2 className="h-6 w-6 text-indigo-500 animate-spin" />
          </div>
        ) : episodes.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            No episodes found for this season.
          </div>
        ) : (
          <div className="bg-gray-800 rounded-lg overflow-hidden divide-y divide-gray-700/50">
            {episodes.map((ep, idx) => {
              const epThumb = getPosterUrl(ep.thumb) || getPosterUrl(ep.parentThumb)
              const isWatched = false // Would come from watch history
              return (
                <div
                  key={ep.ratingKey}
                  className={`flex gap-4 p-4 hover:bg-gray-750 transition-colors ${
                    idx % 2 === 0 ? 'bg-gray-800' : 'bg-gray-800/70'
                  }`}
                >
                  {/* Episode Thumbnail */}
                  <div className="flex-shrink-0 w-40 h-24 rounded-md overflow-hidden bg-gray-700 relative hidden md:block">
                    {epThumb ? (
                      <img
                        src={epThumb}
                        alt={ep.title}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <Film className="h-8 w-8 text-gray-600" />
                      </div>
                    )}
                    {/* Play overlay */}
                    <div className="absolute inset-0 flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity bg-black/40">
                      <Play className="h-8 w-8 text-white" />
                    </div>
                  </div>

                  {/* Episode Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start gap-2">
                      <span className="text-indigo-400 font-mono text-sm mt-0.5 flex-shrink-0">
                        E{String(ep.index ?? idx + 1).padStart(2, '0')}
                      </span>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <h3 className="text-white font-medium truncate">{ep.title}</h3>
                          {isWatched && (
                            <CheckCircle2 className="h-4 w-4 text-green-500 flex-shrink-0" />
                          )}
                        </div>
                        <div className="flex items-center gap-3 text-xs text-gray-400 mt-1">
                          {ep.originallyAvailableAt && (
                            <span className="flex items-center gap-1">
                              <Calendar className="h-3 w-3" />
                              {formatDate(ep.originallyAvailableAt)}
                            </span>
                          )}
                          {ep.duration && ep.duration > 0 && (
                            <span className="flex items-center gap-1">
                              <Clock className="h-3 w-3" />
                              {formatDuration(ep.duration)}
                            </span>
                          )}
                        </div>
                        {ep.summary && (
                          <p className="text-gray-400 text-sm mt-2 line-clamp-2 leading-relaxed">
                            {ep.summary}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
