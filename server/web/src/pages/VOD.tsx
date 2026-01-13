import { useState, useEffect, useRef } from 'react'
import {
  Film,
  Tv2,
  Download,
  Loader,
  Search,
  X,
  Play,
  Pause,
  ChevronDown,
  ChevronRight,
  CheckCircle,
  AlertCircle,
  Clock,
  Trash2,
  RefreshCw,
  Wifi,
  WifiOff,
  Volume2,
  VolumeX,
  Maximize,
  SkipBack,
  SkipForward,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  api,
  type VODMovie,
  type VODDownloadItem,
} from '../api/client'
import Hls from 'hls.js'

// VOD Video Player Component
function VODPlayer({
  title,
  streamUrl,
  onClose,
}: {
  title: string
  streamUrl: string
  onClose: () => void
}) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const hlsRef = useRef<Hls | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isMuted, setIsMuted] = useState(false)
  const [isPlaying, setIsPlaying] = useState(true)
  const [showControls, setShowControls] = useState(true)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const controlsTimeoutRef = useRef<number | null>(null)

  // Playback control handlers
  const togglePlayPause = () => {
    const video = videoRef.current
    if (!video) return
    if (video.paused) {
      video.play().catch(() => {})
      setIsPlaying(true)
    } else {
      video.pause()
      setIsPlaying(false)
    }
  }

  const seekBackward = () => {
    const video = videoRef.current
    if (!video) return
    video.currentTime = Math.max(0, video.currentTime - 10)
  }

  const seekForward = () => {
    const video = videoRef.current
    if (!video) return
    video.currentTime = video.currentTime + 10
  }

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const video = videoRef.current
    if (!video) return
    video.currentTime = parseFloat(e.target.value)
  }

  const formatDuration = (seconds: number) => {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = Math.floor(seconds % 60)
    if (h > 0) {
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
    }
    return `${m}:${s.toString().padStart(2, '0')}`
  }

  useEffect(() => {
    const video = videoRef.current
    if (!video || !streamUrl) return

    setIsLoading(true)
    setError(null)

    // Handle time updates
    const handleTimeUpdate = () => {
      setCurrentTime(video.currentTime)
    }

    const handleLoadedMetadata = () => {
      setDuration(video.duration)
    }

    const handleEnded = () => {
      setIsPlaying(false)
    }

    video.addEventListener('timeupdate', handleTimeUpdate)
    video.addEventListener('loadedmetadata', handleLoadedMetadata)
    video.addEventListener('ended', handleEnded)

    // Try HLS first
    if (Hls.isSupported()) {
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false,
      })
      hlsRef.current = hls

      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        setIsLoading(false)
        video.play().catch(() => {})
      })

      hls.on(Hls.Events.ERROR, (_, data) => {
        if (data.fatal) {
          console.error('HLS error:', data)
          // Try direct playback as fallback
          hls.destroy()
          hlsRef.current = null
          video.src = streamUrl
          video.play().catch((err) => {
            setError(`Playback error: ${err.message}`)
            setIsLoading(false)
          })
        }
      })

      hls.loadSource(streamUrl)
      hls.attachMedia(video)
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Native HLS support (Safari)
      video.src = streamUrl
      video.addEventListener('loadedmetadata', () => {
        setIsLoading(false)
        video.play().catch(() => {})
      })
    } else {
      // Direct playback
      video.src = streamUrl
      video.addEventListener('canplay', () => {
        setIsLoading(false)
        video.play().catch(() => {})
      })
      video.addEventListener('error', () => {
        setError('Unable to play this video format')
        setIsLoading(false)
      })
    }

    return () => {
      video.removeEventListener('timeupdate', handleTimeUpdate)
      video.removeEventListener('loadedmetadata', handleLoadedMetadata)
      video.removeEventListener('ended', handleEnded)
      if (hlsRef.current) {
        hlsRef.current.destroy()
        hlsRef.current = null
      }
    }
  }, [streamUrl])

  // Auto-hide controls
  useEffect(() => {
    if (showControls) {
      if (controlsTimeoutRef.current) {
        clearTimeout(controlsTimeoutRef.current)
      }
      controlsTimeoutRef.current = window.setTimeout(() => {
        setShowControls(false)
      }, 3000)
    }
    return () => {
      if (controlsTimeoutRef.current) {
        clearTimeout(controlsTimeoutRef.current)
      }
    }
  }, [showControls])

  const handleMouseMove = () => setShowControls(true)

  const toggleFullscreen = () => {
    const container = document.getElementById('vod-player-container')
    if (container) {
      if (document.fullscreenElement) {
        document.exitFullscreen()
      } else {
        container.requestFullscreen()
      }
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-black">
      <div
        id="vod-player-container"
        className="relative w-full h-full"
        onMouseMove={handleMouseMove}
        onClick={handleMouseMove}
      >
        {/* Video */}
        {isLoading && (
          <div className="absolute inset-0 flex items-center justify-center">
            <Loader className="w-12 h-12 text-white animate-spin" />
          </div>
        )}
        {error ? (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-center">
              <p className="text-red-400 text-lg mb-4">{error}</p>
              <button
                onClick={onClose}
                className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
              >
                Close
              </button>
            </div>
          </div>
        ) : (
          <video
            ref={videoRef}
            className="w-full h-full object-contain"
            muted={isMuted}
            playsInline
          />
        )}

        {/* Controls Overlay */}
        <div
          className={`absolute inset-0 transition-opacity duration-300 ${showControls ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
        >
          {/* Top bar */}
          <div className="absolute top-0 left-0 right-0 p-4 bg-gradient-to-b from-black/80 to-transparent">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <button
                  onClick={onClose}
                  className="p-2 text-white hover:bg-white/20 rounded-lg transition-colors"
                >
                  <X className="w-6 h-6" />
                </button>
                <div>
                  <h2 className="text-xl font-semibold text-white">{title}</h2>
                </div>
              </div>
            </div>
          </div>

          {/* Bottom bar */}
          <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/80 to-transparent">
            {/* Progress bar */}
            {duration > 0 && (
              <div className="flex items-center gap-3 mb-4">
                <span className="text-white text-sm">{formatDuration(currentTime)}</span>
                <input
                  type="range"
                  min="0"
                  max={duration}
                  value={currentTime}
                  onChange={handleSeek}
                  className="flex-1 h-1 bg-gray-600 rounded-lg appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-white"
                />
                <span className="text-white text-sm">{formatDuration(duration)}</span>
              </div>
            )}

            <div className="flex items-center justify-between">
              {/* Left controls - Volume */}
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setIsMuted(!isMuted)}
                  className="p-2 text-white hover:bg-white/20 rounded-lg transition-colors"
                  title={isMuted ? "Unmute" : "Mute"}
                >
                  {isMuted ? <VolumeX className="w-6 h-6" /> : <Volume2 className="w-6 h-6" />}
                </button>
              </div>

              {/* Center controls - Playback */}
              <div className="flex items-center gap-2">
                <button
                  onClick={seekBackward}
                  className="p-3 text-white hover:bg-white/20 rounded-full transition-colors"
                  title="Rewind 10s"
                >
                  <SkipBack className="w-6 h-6" />
                </button>
                <button
                  onClick={togglePlayPause}
                  className="p-4 text-white bg-white/20 hover:bg-white/30 rounded-full transition-colors"
                  title={isPlaying ? "Pause" : "Play"}
                >
                  {isPlaying ? <Pause className="w-8 h-8" /> : <Play className="w-8 h-8" />}
                </button>
                <button
                  onClick={seekForward}
                  className="p-3 text-white hover:bg-white/20 rounded-full transition-colors"
                  title="Forward 10s"
                >
                  <SkipForward className="w-6 h-6" />
                </button>
              </div>

              {/* Right controls - Fullscreen */}
              <button
                onClick={toggleFullscreen}
                className="p-2 text-white hover:bg-white/20 rounded-lg transition-colors"
                title="Fullscreen"
              >
                <Maximize className="w-6 h-6" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// Movie Detail Modal
function MovieDetailModal({
  movie,
  onClose,
  onDownload,
  onPlay,
  isDownloading,
}: {
  movie: VODMovie
  onClose: () => void
  onDownload: () => void
  onPlay: () => void
  isDownloading: boolean
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
      <div className="bg-gray-800 rounded-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="relative">
          {movie.poster && (
            <div className="h-48 bg-gradient-to-b from-gray-700 to-gray-800 overflow-hidden">
              <img
                src={movie.poster}
                alt={movie.title}
                className="w-full h-full object-cover opacity-30"
              />
            </div>
          )}
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-2 bg-black/50 hover:bg-black/70 rounded-full text-white"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6">
          <div className="flex gap-6">
            {movie.poster && (
              <div className="flex-shrink-0 w-32">
                <img
                  src={movie.poster}
                  alt={movie.title}
                  className="w-full rounded-lg shadow-lg"
                />
              </div>
            )}
            <div className="flex-1">
              <h2 className="text-2xl font-bold text-white">{movie.title}</h2>
              <div className="flex flex-wrap items-center gap-3 mt-2 text-sm text-gray-400">
                {movie.year && <span>{movie.year}</span>}
                {movie.runtime && <span>{movie.runtime}</span>}
                {movie.rating && (
                  <span className="px-2 py-0.5 border border-gray-600 rounded">
                    {movie.rating}
                  </span>
                )}
              </div>
              {movie.genres && movie.genres.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-3">
                  {movie.genres.map((genre) => (
                    <span
                      key={genre}
                      className="px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded"
                    >
                      {genre}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </div>

          {movie.description && (
            <p className="mt-4 text-gray-300 text-sm leading-relaxed">
              {movie.description}
            </p>
          )}

          <div className="mt-6 flex gap-3">
            {movie.downloadUrl && (
              <button
                onClick={onPlay}
                className="flex items-center gap-2 px-6 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium"
              >
                <Play className="w-5 h-5" />
                Play
              </button>
            )}
            <button
              onClick={onDownload}
              disabled={isDownloading}
              className="flex items-center gap-2 px-6 py-3 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-lg font-medium"
            >
              {isDownloading ? (
                <Loader className="w-5 h-5 animate-spin" />
              ) : (
                <Download className="w-5 h-5" />
              )}
              {isDownloading ? 'Starting Download...' : 'Download'}
            </button>
            <button
              onClick={onClose}
              className="px-6 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

// Show Detail Modal
function ShowDetailModal({
  showId,
  provider,
  onClose,
  onDownload,
  onPlay,
  isDownloading,
}: {
  showId: string
  provider: string
  onClose: () => void
  onDownload: (episodeId: string) => void
  onPlay: (episode: { id: string; title?: string; downloadUrl?: string }) => void
  isDownloading: string | null
}) {
  const [expandedSeasons, setExpandedSeasons] = useState<number[]>([1])

  const { data: show, isLoading } = useQuery({
    queryKey: ['vod-show', provider, showId],
    queryFn: () => api.vod.getShow(provider, showId),
  })

  const toggleSeason = (seasonNumber: number) => {
    setExpandedSeasons((prev) =>
      prev.includes(seasonNumber)
        ? prev.filter((s) => s !== seasonNumber)
        : [...prev, seasonNumber]
    )
  }

  if (isLoading) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70">
        <Loader className="w-12 h-12 text-white animate-spin" />
      </div>
    )
  }

  if (!show) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
      <div className="bg-gray-800 rounded-xl w-full max-w-3xl max-h-[90vh] overflow-y-auto">
        <div className="relative">
          {show.poster && (
            <div className="h-48 bg-gradient-to-b from-gray-700 to-gray-800 overflow-hidden">
              <img
                src={show.poster}
                alt={show.title}
                className="w-full h-full object-cover opacity-30"
              />
            </div>
          )}
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-2 bg-black/50 hover:bg-black/70 rounded-full text-white"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6">
          <div className="flex gap-6">
            {show.poster && (
              <div className="flex-shrink-0 w-32">
                <img
                  src={show.poster}
                  alt={show.title}
                  className="w-full rounded-lg shadow-lg"
                />
              </div>
            )}
            <div className="flex-1">
              <h2 className="text-2xl font-bold text-white">{show.title}</h2>
              <div className="flex flex-wrap items-center gap-3 mt-2 text-sm text-gray-400">
                {show.year && <span>{show.year}</span>}
                {show.seasonCount && (
                  <span>{show.seasonCount} Season{show.seasonCount > 1 ? 's' : ''}</span>
                )}
                {show.rating && (
                  <span className="px-2 py-0.5 border border-gray-600 rounded">
                    {show.rating}
                  </span>
                )}
              </div>
              {show.genres && show.genres.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-3">
                  {show.genres.map((genre) => (
                    <span
                      key={genre}
                      className="px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded"
                    >
                      {genre}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </div>

          {show.description && (
            <p className="mt-4 text-gray-300 text-sm leading-relaxed">
              {show.description}
            </p>
          )}

          {/* Seasons */}
          {show.seasons && show.seasons.length > 0 && (
            <div className="mt-6 space-y-2">
              <h3 className="text-lg font-semibold text-white mb-3">Episodes</h3>
              {show.seasons.map((season) => (
                <div key={season.seasonNumber} className="border border-gray-700 rounded-lg overflow-hidden">
                  <button
                    onClick={() => toggleSeason(season.seasonNumber)}
                    className="w-full flex items-center justify-between p-4 bg-gray-700/50 hover:bg-gray-700 text-white"
                  >
                    <span className="font-medium">Season {season.seasonNumber}</span>
                    {expandedSeasons.includes(season.seasonNumber) ? (
                      <ChevronDown className="w-5 h-5" />
                    ) : (
                      <ChevronRight className="w-5 h-5" />
                    )}
                  </button>
                  {expandedSeasons.includes(season.seasonNumber) && season.episodes && (
                    <div className="divide-y divide-gray-700">
                      {season.episodes.map((episode) => (
                        <div
                          key={episode.id}
                          className="flex items-center justify-between p-4 hover:bg-gray-700/30"
                        >
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-gray-500 text-sm">
                                E{episode.episodeNumber}
                              </span>
                              <span className="text-white font-medium truncate">
                                {episode.title}
                              </span>
                            </div>
                            {episode.runtime && (
                              <span className="text-xs text-gray-500">
                                {episode.runtime} min
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-1">
                            {episode.downloadUrl && (
                              <button
                                onClick={() => onPlay({ id: episode.id, title: episode.title, downloadUrl: episode.downloadUrl })}
                                className="flex-shrink-0 p-2 text-gray-400 hover:text-green-400 hover:bg-gray-700 rounded-lg"
                                title="Play"
                              >
                                <Play className="w-4 h-4" />
                              </button>
                            )}
                            <button
                              onClick={() => onDownload(episode.id)}
                              disabled={isDownloading === episode.id}
                              className="flex-shrink-0 p-2 text-gray-400 hover:text-indigo-400 hover:bg-gray-700 rounded-lg disabled:opacity-50"
                              title="Download"
                            >
                              {isDownloading === episode.id ? (
                                <Loader className="w-4 h-4 animate-spin" />
                              ) : (
                                <Download className="w-4 h-4" />
                              )}
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}

          <div className="mt-6 flex justify-end">
            <button
              onClick={onClose}
              className="px-6 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

// Content Card
function ContentCard({
  title,
  year,
  poster,
  rating,
  onClick,
}: {
  title: string
  year?: number
  poster?: string
  rating?: string
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      className="group relative bg-gray-800 rounded-lg overflow-hidden hover:ring-2 hover:ring-indigo-500 transition-all"
    >
      <div className="aspect-[2/3] bg-gray-700">
        {poster ? (
          <img
            src={poster}
            alt={title}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <Film className="w-12 h-12 text-gray-600" />
          </div>
        )}
      </div>
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
      <div className="absolute bottom-0 left-0 right-0 p-3">
        <h4 className="font-medium text-white text-sm truncate">{title}</h4>
        <div className="flex items-center gap-2 mt-1 text-xs text-gray-400">
          {year && <span>{year}</span>}
          {rating && <span className="px-1 border border-gray-600 rounded">{rating}</span>}
        </div>
      </div>
      <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
        <div className="p-3 bg-indigo-600 rounded-full">
          <Play className="w-6 h-6 text-white" />
        </div>
      </div>
    </button>
  )
}

// Download Queue Panel
function DownloadQueuePanel({
  queue,
  onCancel,
  onRefresh,
  isRefreshing,
}: {
  queue: VODDownloadItem[]
  onCancel: (id: string) => void
  onRefresh: () => void
  isRefreshing: boolean
}) {
  if (!queue.length) {
    return (
      <div className="text-center py-8 text-gray-500">
        <Download className="w-8 h-8 mx-auto mb-2 opacity-50" />
        <p>No active downloads</p>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between mb-2">
        <span className="text-sm text-gray-400">{queue.length} download{queue.length > 1 ? 's' : ''}</span>
        <button
          onClick={onRefresh}
          disabled={isRefreshing}
          className="p-1 text-gray-400 hover:text-white"
        >
          <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
        </button>
      </div>
      {queue.map((item) => (
        <div
          key={item.id}
          className="bg-gray-700 rounded-lg p-3"
        >
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1 min-w-0">
              <h4 className="font-medium text-white text-sm truncate">{item.title}</h4>
              <div className="flex items-center gap-2 mt-1">
                {item.status === 'queued' && (
                  <span className="flex items-center gap-1 text-xs text-blue-400">
                    <Clock className="w-3 h-3" />
                    Queued
                  </span>
                )}
                {item.status === 'downloading' && (
                  <span className="flex items-center gap-1 text-xs text-indigo-400">
                    <Loader className="w-3 h-3 animate-spin" />
                    {item.progress.toFixed(0)}%
                  </span>
                )}
                {item.status === 'completed' && (
                  <span className="flex items-center gap-1 text-xs text-green-400">
                    <CheckCircle className="w-3 h-3" />
                    Completed
                  </span>
                )}
                {item.status === 'failed' && (
                  <span className="flex items-center gap-1 text-xs text-red-400">
                    <AlertCircle className="w-3 h-3" />
                    Failed
                  </span>
                )}
              </div>
            </div>
            {(item.status === 'queued' || item.status === 'downloading') && (
              <button
                onClick={() => onCancel(item.id)}
                className="p-1 text-gray-400 hover:text-red-400"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            )}
          </div>
          {item.status === 'downloading' && (
            <div className="mt-2 h-1.5 bg-gray-600 rounded-full overflow-hidden">
              <div
                className="h-full bg-indigo-500 transition-all duration-300"
                style={{ width: `${item.progress}%` }}
              />
            </div>
          )}
          {item.error && (
            <p className="mt-2 text-xs text-red-400">{item.error}</p>
          )}
        </div>
      ))}
    </div>
  )
}

export function VODPage() {
  const queryClient = useQueryClient()
  const [selectedProvider, setSelectedProvider] = useState<string | null>(null)
  const [viewType, setViewType] = useState<'movies' | 'shows'>('movies')
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedGenre, setSelectedGenre] = useState<string | null>(null)
  const [selectedMovie, setSelectedMovie] = useState<VODMovie | null>(null)
  const [selectedShowId, setSelectedShowId] = useState<string | null>(null)
  const [downloadingEpisode, setDownloadingEpisode] = useState<string | null>(null)
  const [showQueue, setShowQueue] = useState(false)
  const [playingContent, setPlayingContent] = useState<{ title: string; streamUrl: string } | null>(null)

  // Fetch server settings to get VOD API URL
  const { data: serverConfig } = useQuery({
    queryKey: ['serverConfig'],
    queryFn: () => api.getServerConfig(),
    retry: false,
  })

  const vodApiUrl = serverConfig?.vod_api_url || ''

  // Test connection
  const { data: connectionStatus } = useQuery({
    queryKey: ['vod-connection'],
    queryFn: () => api.vod.testConnection(),
    refetchInterval: 30000,
  })

  // Providers
  const { data: providers, isLoading: loadingProviders } = useQuery({
    queryKey: ['vod-providers'],
    queryFn: () => api.vod.getProviders(),
    enabled: connectionStatus?.connected === true,
  })

  // Auto-select first provider
  useEffect(() => {
    if (providers?.length && !selectedProvider) {
      setSelectedProvider(providers[0].id)
    }
  }, [providers, selectedProvider])

  // Movies
  const { data: movies, isLoading: loadingMovies } = useQuery({
    queryKey: ['vod-movies', selectedProvider],
    queryFn: () => api.vod.getMovies(selectedProvider!),
    enabled: !!selectedProvider && viewType === 'movies',
  })

  // Shows
  const { data: shows, isLoading: loadingShows } = useQuery({
    queryKey: ['vod-shows', selectedProvider],
    queryFn: () => api.vod.getShows(selectedProvider!),
    enabled: !!selectedProvider && viewType === 'shows',
  })

  // Genres
  const { data: genres } = useQuery({
    queryKey: ['vod-genres', selectedProvider],
    queryFn: () => api.vod.getGenres(selectedProvider!),
    enabled: !!selectedProvider,
  })

  // Download Queue
  const { data: queueData, refetch: refetchQueue, isRefetching: isRefreshingQueue } = useQuery({
    queryKey: ['vod-queue'],
    queryFn: () => api.vod.getQueue(),
    refetchInterval: 5000,
    enabled: connectionStatus?.connected === true,
  })

  // Start download mutation
  const startDownload = useMutation({
    mutationFn: ({ contentId, type }: { contentId: string; type: 'movie' | 'episode' }) =>
      api.vod.startDownload(selectedProvider!, contentId, type),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vod-queue'] })
    },
  })

  // Cancel download mutation
  const cancelDownload = useMutation({
    mutationFn: (id: string) => api.vod.cancelDownload(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vod-queue'] })
    },
  })

  const handleDownloadMovie = () => {
    if (selectedMovie && selectedProvider) {
      startDownload.mutate(
        { contentId: selectedMovie.id, type: 'movie' },
        {
          onSuccess: () => {
            setSelectedMovie(null)
          },
        }
      )
    }
  }

  const handleDownloadEpisode = (episodeId: string) => {
    if (selectedProvider) {
      setDownloadingEpisode(episodeId)
      startDownload.mutate(
        { contentId: episodeId, type: 'episode' },
        {
          onSettled: () => {
            setDownloadingEpisode(null)
          },
        }
      )
    }
  }

  const handlePlayMovie = () => {
    if (selectedMovie?.downloadUrl && vodApiUrl) {
      // Construct the stream URL using the VOD API URL and the download path
      const streamUrl = `${vodApiUrl}${selectedMovie.downloadUrl}`
      setPlayingContent({ title: selectedMovie.title, streamUrl })
      setSelectedMovie(null)
    }
  }

  const handlePlayEpisode = (episode: { id: string; title?: string; downloadUrl?: string }) => {
    if (episode.downloadUrl && vodApiUrl) {
      const streamUrl = `${vodApiUrl}${episode.downloadUrl}`
      setPlayingContent({ title: episode.title || 'Episode', streamUrl })
      setSelectedShowId(null)
    }
  }

  // Filter content
  const filteredMovies = movies?.filter((movie) => {
    const matchesSearch = !searchQuery ||
      movie.title.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesGenre = !selectedGenre ||
      movie.genres?.includes(selectedGenre)
    return matchesSearch && matchesGenre
  })

  const filteredShows = shows?.filter((show) => {
    const matchesSearch = !searchQuery ||
      show.title.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesGenre = !selectedGenre ||
      show.genres?.includes(selectedGenre)
    return matchesSearch && matchesGenre
  })

  const isLoading = loadingProviders || (viewType === 'movies' ? loadingMovies : loadingShows)
  const queue = queueData?.items || []
  const activeDownloads = queue.filter(
    (item) => item.status === 'queued' || item.status === 'downloading'
  ).length

  // Not connected state
  if (connectionStatus?.connected === false) {
    return (
      <div>
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-white">VOD Downloads</h1>
          <p className="text-gray-400 mt-1">Browse and download Disney+ content</p>
        </div>

        <div className="bg-gray-800 rounded-xl p-8 text-center">
          <WifiOff className="w-16 h-16 text-red-400 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-white mb-2">VOD Service Not Available</h3>
          <p className="text-gray-400 mb-4">
            {connectionStatus?.error || 'Could not connect to VOD API'}
          </p>
          <p className="text-sm text-gray-500">
            Configure the VOD API URL in <a href="/ui/settings" className="text-indigo-400 hover:underline">Settings</a>
          </p>
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">VOD Downloads</h1>
          <p className="text-gray-400 mt-1">Browse and download Disney+ content</p>
        </div>
        <div className="flex items-center gap-3">
          {connectionStatus?.connected && (
            <span className="flex items-center gap-1.5 text-sm text-green-400">
              <Wifi className="w-4 h-4" />
              Connected
            </span>
          )}
          <button
            onClick={() => setShowQueue(!showQueue)}
            className={`relative flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
              showQueue
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
            }`}
          >
            <Download className="w-4 h-4" />
            Queue
            {activeDownloads > 0 && (
              <span className="absolute -top-1 -right-1 w-5 h-5 flex items-center justify-center text-xs bg-red-500 text-white rounded-full">
                {activeDownloads}
              </span>
            )}
          </button>
        </div>
      </div>

      <div className="flex gap-6">
        {/* Main Content */}
        <div className="flex-1">
          {/* Provider Dropdown */}
          {providers && providers.length > 0 && (
            <div className="flex items-center gap-3 mb-6">
              <label className="text-sm text-gray-400">Provider:</label>
              <select
                value={selectedProvider || ''}
                onChange={(e) => setSelectedProvider(e.target.value)}
                className="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-indigo-500 min-w-[200px]"
              >
                {providers.map((provider) => (
                  <option key={provider.id} value={provider.id}>
                    {provider.name}
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* View Toggle */}
          <div className="flex items-center gap-4 mb-6">
            <div className="flex bg-gray-800 rounded-lg p-1">
              <button
                onClick={() => setViewType('movies')}
                className={`flex items-center gap-2 px-4 py-2 rounded-md font-medium transition-colors ${
                  viewType === 'movies'
                    ? 'bg-gray-700 text-white'
                    : 'text-gray-400 hover:text-white'
                }`}
              >
                <Film className="w-4 h-4" />
                Movies
              </button>
              <button
                onClick={() => setViewType('shows')}
                className={`flex items-center gap-2 px-4 py-2 rounded-md font-medium transition-colors ${
                  viewType === 'shows'
                    ? 'bg-gray-700 text-white'
                    : 'text-gray-400 hover:text-white'
                }`}
              >
                <Tv2 className="w-4 h-4" />
                TV Shows
              </button>
            </div>

            {/* Search */}
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search..."
                className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
              />
            </div>

            {/* Genre Filter */}
            {genres && genres.length > 0 && (
              <select
                value={selectedGenre || ''}
                onChange={(e) => setSelectedGenre(e.target.value || null)}
                className="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-indigo-500"
              >
                <option value="">All Genres</option>
                {genres.map((genre) => (
                  <option key={genre} value={genre}>
                    {genre}
                  </option>
                ))}
              </select>
            )}
          </div>

          {/* Content Grid */}
          {isLoading ? (
            <div className="flex items-center justify-center py-12">
              <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
            </div>
          ) : viewType === 'movies' ? (
            filteredMovies?.length ? (
              <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
                {filteredMovies.map((movie) => (
                  <ContentCard
                    key={movie.id}
                    title={movie.title}
                    year={movie.year}
                    poster={movie.poster}
                    rating={movie.rating}
                    onClick={() => setSelectedMovie(movie)}
                  />
                ))}
              </div>
            ) : (
              <div className="text-center py-12 bg-gray-800 rounded-xl">
                <Film className="w-12 h-12 text-gray-600 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-white mb-2">No movies found</h3>
                <p className="text-gray-400">Try adjusting your search or filters</p>
              </div>
            )
          ) : filteredShows?.length ? (
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
              {filteredShows.map((show) => (
                <ContentCard
                  key={show.id}
                  title={show.title}
                  year={show.year}
                  poster={show.poster}
                  rating={show.rating}
                  onClick={() => setSelectedShowId(show.id)}
                />
              ))}
            </div>
          ) : (
            <div className="text-center py-12 bg-gray-800 rounded-xl">
              <Tv2 className="w-12 h-12 text-gray-600 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-white mb-2">No TV shows found</h3>
              <p className="text-gray-400">Try adjusting your search or filters</p>
            </div>
          )}
        </div>

        {/* Download Queue Sidebar */}
        {showQueue && (
          <div className="w-80 flex-shrink-0">
            <div className="sticky top-6 bg-gray-800 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-4">Download Queue</h3>
              <DownloadQueuePanel
                queue={queue}
                onCancel={(id) => cancelDownload.mutate(id)}
                onRefresh={() => refetchQueue()}
                isRefreshing={isRefreshingQueue}
              />
            </div>
          </div>
        )}
      </div>

      {/* Movie Detail Modal */}
      {selectedMovie && selectedProvider && (
        <MovieDetailModal
          movie={selectedMovie}
          onClose={() => setSelectedMovie(null)}
          onDownload={handleDownloadMovie}
          onPlay={handlePlayMovie}
          isDownloading={startDownload.isPending}
        />
      )}

      {/* Show Detail Modal */}
      {selectedShowId && selectedProvider && (
        <ShowDetailModal
          showId={selectedShowId}
          provider={selectedProvider}
          onClose={() => setSelectedShowId(null)}
          onDownload={handleDownloadEpisode}
          onPlay={handlePlayEpisode}
          isDownloading={downloadingEpisode}
        />
      )}

      {/* Video Player */}
      {playingContent && (
        <VODPlayer
          title={playingContent.title}
          streamUrl={playingContent.streamUrl}
          onClose={() => setPlayingContent(null)}
        />
      )}
    </div>
  )
}
