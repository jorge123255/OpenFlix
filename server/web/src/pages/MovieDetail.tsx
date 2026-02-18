import { useParams, Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'
import {
  ArrowLeft,
  Play,
  Film,
  Star,
  Clock,
  Calendar,
  HardDrive,
  Monitor,
  Loader2,
  Bookmark,
} from 'lucide-react'

// Types matching the Plex-compatible API response
interface MetadataItem {
  ratingKey: number
  key: string
  guid: string
  type: string
  title: string
  librarySectionID?: number
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

function formatDuration(ms: number): string {
  const minutes = Math.round(ms / 60000)
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const remainMinutes = minutes % 60
  return remainMinutes > 0 ? `${hours}h ${remainMinutes}m` : `${hours}h`
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${units[i]}`
}

function formatBitrate(bitrate: number): string {
  if (bitrate >= 1000) {
    return `${(bitrate / 1000).toFixed(1)} Mbps`
  }
  return `${bitrate} kbps`
}

function getResolutionLabel(width: number, height: number): string {
  if (height >= 2160) return '4K UHD'
  if (height >= 1440) return '1440p QHD'
  if (height >= 1080) return '1080p FHD'
  if (height >= 720) return '720p HD'
  if (height >= 480) return '480p SD'
  return `${width}x${height}`
}

function formatDate(dateStr?: string | number): string {
  if (!dateStr) return ''
  const date = typeof dateStr === 'number' ? new Date(dateStr * 1000) : new Date(dateStr)
  return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
}

function getImageUrl(url?: string): string | undefined {
  if (!url) return undefined
  if (url.startsWith('http')) return url
  if (url.startsWith('/library/')) return url
  return `https://image.tmdb.org/t/p/original${url}`
}

function getPosterUrl(url?: string): string | undefined {
  if (!url) return undefined
  if (url.startsWith('http')) return url
  if (url.startsWith('/library/')) return url
  return `https://image.tmdb.org/t/p/w500${url}`
}

function getProfileUrl(url?: string): string | undefined {
  if (!url) return undefined
  if (url.startsWith('http')) return url
  return `https://image.tmdb.org/t/p/w185${url}`
}

export function MovieDetailPage() {
  const { id } = useParams<{ id: string }>()

  // Fetch movie metadata
  const { data: movieData, isLoading } = useQuery<MediaContainerResponse>({
    queryKey: ['movie-detail', id],
    queryFn: async () => {
      const response = await api.client.get(`/library/metadata/${id}`)
      return response.data
    },
    enabled: !!id,
  })

  const movie = movieData?.MediaContainer?.Metadata?.[0]

  // Fetch related movies from same library
  const { data: relatedData } = useQuery<MediaContainerResponse>({
    queryKey: ['related-movies', movie?.ratingKey],
    queryFn: async () => {
      const response = await api.client.get(`/library/sections/${movie!.librarySectionID}/all`, {
        params: {
          type: 1,
          'X-Plex-Container-Start': 0,
          'X-Plex-Container-Size': 12,
          sort: 'addedAt:desc',
        },
      })
      return response.data
    },
    enabled: !!movie && !!movie.librarySectionID,
  })

  // Filter out current movie from related
  const relatedMovies = (relatedData?.MediaContainer?.Metadata ?? []).filter(
    (m) => m.ratingKey !== movie?.ratingKey
  ).slice(0, 8)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="h-8 w-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  if (!movie) {
    return (
      <div className="flex flex-col items-center justify-center h-96 gap-4">
        <Film className="h-12 w-12 text-gray-500" />
        <p className="text-gray-400 text-lg">Movie not found</p>
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

  const backdropUrl = getImageUrl(movie.art)
  const posterUrl = getPosterUrl(movie.thumb)
  const genres = movie.Genre?.map((g) => g.tag) ?? []
  const cast = movie.Role ?? []
  const directors = movie.Director ?? []
  const writers = movie.Writer ?? []
  const mediaFile = movie.Media?.[0]
  const filePart = mediaFile?.Part?.[0]

  return (
    <div className="space-y-6 -mt-6 -mx-6">
      {/* Hero Banner */}
      <div className="relative h-[460px] overflow-hidden">
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
          <div className="flex-shrink-0 w-52 h-78 rounded-lg overflow-hidden shadow-2xl bg-gray-800 hidden sm:block">
            {posterUrl ? (
              <img
                src={posterUrl}
                alt={movie.title}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center" style={{ height: '312px' }}>
                <Film className="h-16 w-16 text-gray-600" />
              </div>
            )}
          </div>

          {/* Info */}
          <div className="flex-1 min-w-0 flex flex-col justify-end">
            <h1 className="text-3xl md:text-4xl font-bold text-white mb-2 drop-shadow-lg">
              {movie.title}
            </h1>
            {movie.tagline && (
              <p className="text-gray-300 italic text-sm mb-3">{movie.tagline}</p>
            )}
            <div className="flex flex-wrap items-center gap-3 text-sm text-gray-300 mb-3">
              {movie.year && <span>{movie.year}</span>}
              {movie.contentRating && (
                <span className="px-2 py-0.5 border border-gray-500 rounded text-xs">
                  {movie.contentRating}
                </span>
              )}
              {movie.duration && movie.duration > 0 && (
                <span className="flex items-center gap-1">
                  <Clock className="h-3.5 w-3.5" />
                  {formatDuration(movie.duration)}
                </span>
              )}
              {movie.rating && movie.rating > 0 && (
                <span className="flex items-center gap-1">
                  <Star className="h-3.5 w-3.5 text-yellow-400 fill-yellow-400" />
                  {movie.rating.toFixed(1)}
                </span>
              )}
              {movie.audienceRating && movie.audienceRating > 0 && (
                <span className="flex items-center gap-1 text-gray-400">
                  Audience: {movie.audienceRating.toFixed(1)}
                </span>
              )}
              {movie.studio && <span className="text-gray-400">{movie.studio}</span>}
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
            {movie.summary && (
              <p className="text-gray-300 text-sm leading-relaxed line-clamp-4 max-w-3xl">
                {movie.summary}
              </p>
            )}

            {/* Directors & Writers */}
            {(directors.length > 0 || writers.length > 0) && (
              <div className="flex flex-wrap gap-x-6 gap-y-1 mt-3 text-sm">
                {directors.length > 0 && (
                  <p className="text-gray-400">
                    <span className="text-gray-500">Directed by </span>
                    {directors.map((d) => d.tag).join(', ')}
                  </p>
                )}
                {writers.length > 0 && (
                  <p className="text-gray-400">
                    <span className="text-gray-500">Written by </span>
                    {writers.map((w) => w.tag).join(', ')}
                  </p>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="px-6 flex flex-wrap items-center gap-3">
        <Link
          to="/ui/media"
          className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg flex items-center gap-2 text-sm transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back
        </Link>
        {mediaFile && (
          <button className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg flex items-center gap-2 text-sm font-medium transition-colors">
            <Play className="h-4 w-4" />
            Play
          </button>
        )}
        <button className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg flex items-center gap-2 text-sm transition-colors">
          <Bookmark className="h-4 w-4" />
          Watchlist
        </button>
        {movie.addedAt && (
          <span className="ml-auto text-xs text-gray-500 flex items-center gap-1">
            <Calendar className="h-3 w-3" />
            Added {formatDate(movie.addedAt)}
          </span>
        )}
      </div>

      {/* Cast Section */}
      {cast.length > 0 && (
        <div className="px-6">
          <h2 className="text-lg font-semibold text-white mb-3">Cast</h2>
          <div className="flex gap-4 overflow-x-auto pb-3">
            {cast.slice(0, 20).map((person, idx) => {
              const profileImg = getProfileUrl(person.thumb)
              return (
                <div
                  key={`${person.tag}-${idx}`}
                  className="flex-shrink-0 w-28 text-center"
                >
                  <div className="w-20 h-20 mx-auto rounded-full overflow-hidden bg-gray-700 mb-2">
                    {profileImg ? (
                      <img
                        src={profileImg}
                        alt={person.tag}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-500 text-xl font-bold">
                        {person.tag.charAt(0)}
                      </div>
                    )}
                  </div>
                  <p className="text-white text-xs font-medium truncate">{person.tag}</p>
                  {person.role && (
                    <p className="text-gray-500 text-xs truncate">{person.role}</p>
                  )}
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* Technical Info */}
      {mediaFile && (
        <div className="px-6">
          <h2 className="text-lg font-semibold text-white mb-3">Technical Details</h2>
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {mediaFile.width > 0 && mediaFile.height > 0 && (
                <div className="flex items-start gap-3">
                  <Monitor className="h-5 w-5 text-gray-400 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-xs text-gray-500">Resolution</p>
                    <p className="text-sm text-white">
                      {getResolutionLabel(mediaFile.width, mediaFile.height)}
                    </p>
                    <p className="text-xs text-gray-500">
                      {mediaFile.width}x{mediaFile.height}
                    </p>
                  </div>
                </div>
              )}
              {mediaFile.videoCodec && (
                <div className="flex items-start gap-3">
                  <Film className="h-5 w-5 text-gray-400 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-xs text-gray-500">Video</p>
                    <p className="text-sm text-white uppercase">{mediaFile.videoCodec}</p>
                    {mediaFile.container && (
                      <p className="text-xs text-gray-500 uppercase">{mediaFile.container}</p>
                    )}
                  </div>
                </div>
              )}
              {mediaFile.audioCodec && (
                <div className="flex items-start gap-3">
                  <Film className="h-5 w-5 text-gray-400 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-xs text-gray-500">Audio</p>
                    <p className="text-sm text-white uppercase">{mediaFile.audioCodec}</p>
                  </div>
                </div>
              )}
              {filePart && filePart.size > 0 && (
                <div className="flex items-start gap-3">
                  <HardDrive className="h-5 w-5 text-gray-400 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-xs text-gray-500">File Size</p>
                    <p className="text-sm text-white">{formatFileSize(filePart.size)}</p>
                    {mediaFile.bitrate > 0 && (
                      <p className="text-xs text-gray-500">{formatBitrate(mediaFile.bitrate)}</p>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Related Movies */}
      {relatedMovies.length > 0 && (
        <div className="px-6 pb-6">
          <h2 className="text-lg font-semibold text-white mb-3">More in Library</h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-4">
            {relatedMovies.map((related) => {
              const relatedPoster = getPosterUrl(related.thumb)
              return (
                <Link
                  key={related.ratingKey}
                  to={
                    related.type === 'show'
                      ? `/ui/shows/${related.ratingKey}`
                      : `/ui/movies/${related.ratingKey}`
                  }
                  className="group"
                >
                  <div className="aspect-[2/3] rounded-lg overflow-hidden bg-gray-800 mb-2 relative">
                    {relatedPoster ? (
                      <img
                        src={relatedPoster}
                        alt={related.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <Film className="h-8 w-8 text-gray-600" />
                      </div>
                    )}
                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/30 transition-colors flex items-center justify-center">
                      <Play className="h-8 w-8 text-white opacity-0 group-hover:opacity-100 transition-opacity" />
                    </div>
                  </div>
                  <p className="text-white text-xs font-medium truncate">{related.title}</p>
                  {related.year && (
                    <p className="text-gray-500 text-xs">{related.year}</p>
                  )}
                </Link>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}
