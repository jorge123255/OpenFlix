import { useState, useRef, useEffect, useMemo, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Clock, Calendar, Video, Circle, X, ChevronLeft, ChevronRight, Link2, Search, Wand2, RefreshCw, Volume2, VolumeX, Maximize, Loader, Play, Pause, SkipBack, SkipForward } from 'lucide-react'
import { api } from '../api/client'
import Hls from 'hls.js'
import mpegts from 'mpegts.js'

interface Channel {
  id: number
  channelId: string
  tvgId?: string  // TVG ID used for EPG matching
  number: number
  name: string
  logo?: string
  group?: string
  sourceName?: string
  enabled?: boolean
  epgSourceId?: number
  streamUrl?: string
}

interface Program {
  id: number
  channelId: string
  callSign?: string
  channelNo?: string
  affiliateName?: string
  title: string
  description?: string
  start: string
  end: string
  category?: string
  episodeNum?: string
  // Episode status flags
  isNew?: boolean
  isPremiere?: boolean
  isLive?: boolean
  isFinale?: boolean
  // Content type flags
  isMovie?: boolean
  isSports?: boolean
  isKids?: boolean
  isNews?: boolean
}

interface EPGSource {
  id: number
  name: string
  providerType: string
  programCount: number
  channelCount: number
}

interface EPGChannel {
  channelId: string
  callSign: string
  channelNo: string
  affiliateName?: string
  sampleTitle: string
}

interface AutoDetectResult {
  channelId: number
  channelName: string
  currentMapping?: string
  bestMatch?: {
    epgChannelId: string
    epgCallSign: string
    epgName: string
    confidence: number
    matchReason: string
    matchStrategy: string
  }
  autoMapped: boolean
}

interface AutoDetectResponse {
  summary: {
    totalChannels: number
    alreadyMapped: number
    newMappings: number
    noMatchFound: number
    lowConfidence: number
    highConfidence: number
  }
  results: AutoDetectResult[]
}

// Constants for grid layout
const CHANNEL_WIDTH = 220
const ROW_HEIGHT = 70
const TIME_HEADER_HEIGHT = 50
const PIXELS_PER_MINUTE = 3 // 3px per minute = 180px per hour

// Category colors
const categoryColors: { [key: string]: string } = {
  Movies: 'bg-purple-600',
  TVShow: 'bg-blue-600',
  Sports: 'bg-green-600',
  News: 'bg-red-600',
  Kids: 'bg-orange-500',
  Documentary: 'bg-teal-600',
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
}

function ProgramBlock({
  program,
  startOffset,
  width,
  onClick,
  isNow,
  isScheduled,
  isRecording,
}: {
  program: Program
  startOffset: number
  width: number
  onClick: () => void
  isNow: boolean
  isScheduled?: boolean
  isRecording?: boolean
}) {
  const categoryColor = categoryColors[program.category || ''] || 'bg-gray-600'
  const minWidth = 60

  if (width < 20) return null

  return (
    <div
      onClick={onClick}
      className={`absolute top-1 bottom-1 rounded-md cursor-pointer overflow-hidden transition-all hover:z-20 hover:ring-2 hover:ring-white/80 hover:brightness-110 ${categoryColor} ${isNow ? 'ring-1 ring-yellow-400/70 shadow-[0_0_4px_rgba(250,204,21,0.3)]' : ''}`}
      style={{
        left: `${startOffset}px`,
        width: `${Math.max(width - 4, minWidth)}px`,
      }}
      title={`${program.title}\n${formatTime(new Date(program.start))} - ${formatTime(new Date(program.end))}${isScheduled ? '\n🔴 Scheduled to record' : ''}`}
    >
      {/* Recording indicator */}
      {(isScheduled || isRecording) && (
        <div className="absolute top-1 right-1 z-10">
          <div className={`w-3 h-3 rounded-full flex items-center justify-center ${isRecording ? 'bg-red-600 animate-pulse' : 'bg-red-500'}`}>
            <Circle className="w-2 h-2 text-white fill-current" />
          </div>
        </div>
      )}
      {/* NEW/PREMIERE/FINALE/LIVE badges */}
      {(() => {
        // For sports, only show NEW if it's also marked as LIVE (actual live broadcast, not replay)
        const isSportsReplay = program.isSports && !program.isLive
        const showNew = program.isNew && !isSportsReplay
        const showPremiere = program.isPremiere && !isSportsReplay
        const showLive = program.isLive
        const showFinale = program.isFinale
        
        if (!showNew && !showPremiere && !showFinale && !showLive) return null
        
        return (
          <div className="absolute top-1 left-1 z-10 flex gap-1">
            {showLive && (
              <span className="px-1 py-0.5 bg-red-500 text-white text-[9px] font-bold rounded uppercase animate-pulse">Live</span>
            )}
            {showPremiere && (
              <span className="px-1 py-0.5 bg-yellow-500 text-black text-[9px] font-bold rounded uppercase">Premiere</span>
            )}
            {showNew && !showPremiere && (
              <span className="px-1 py-0.5 bg-green-500 text-white text-[9px] font-bold rounded uppercase">New</span>
            )}
            {showFinale && (
              <span className="px-1 py-0.5 bg-purple-500 text-white text-[9px] font-bold rounded uppercase">Finale</span>
            )}
          </div>
        )
      })()}
      <div className="p-2 h-full flex flex-col justify-center">
        <div className="font-semibold text-white text-sm leading-tight truncate">{program.title}</div>
        {width > 120 && (
          <div className="text-xs text-white/80 mt-1 truncate">
            {formatTime(new Date(program.start))} - {formatTime(new Date(program.end))}
          </div>
        )}
        {width > 200 && program.description && (
          <div className="text-xs text-white/60 mt-1 line-clamp-1">
            {program.description}
          </div>
        )}
      </div>
    </div>
  )
}

function ProgramModal({
  program,
  channel,
  onClose,
  onRecord,
  onWatchNow,
  isRecording,
  scheduledStatus,
  onCancelRecording,
}: {
  program: Program
  channel?: Channel
  onClose: () => void
  onRecord: (seriesRecord: boolean) => void
  onWatchNow: () => void
  isRecording: boolean
  scheduledStatus?: 'scheduled' | 'recording' | null
  onCancelRecording?: () => void
}) {
  const start = new Date(program.start)
  const end = new Date(program.end)
  const duration = Math.round((end.getTime() - start.getTime()) / 60000)
  const isNow = new Date() >= start && new Date() < end
  const isFuture = new Date() < start
  const categoryColor = categoryColors[program.category || ''] || 'bg-gray-600'
  const isScheduledToRecord = scheduledStatus === 'scheduled' || scheduledStatus === 'recording'

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4" onClick={onClose}>
      <div className="bg-gray-800 rounded-xl w-full max-w-lg overflow-hidden shadow-2xl" onClick={e => e.stopPropagation()}>
        <div className={`relative h-28 ${categoryColor} flex items-end p-4`}>
          <button
            onClick={onClose}
            className="absolute top-3 right-3 p-1.5 bg-black/30 hover:bg-black/50 rounded-full transition-colors"
          >
            <X className="h-5 w-5 text-white" />
          </button>
          {scheduledStatus === 'recording' ? (
            <span className="absolute top-3 left-3 flex items-center gap-1.5 px-2.5 py-1 bg-red-600 text-white text-xs font-bold rounded-full">
              <Circle className="h-2 w-2 fill-current animate-pulse" />
              RECORDING
            </span>
          ) : scheduledStatus === 'scheduled' ? (
            <span className="absolute top-3 left-3 flex items-center gap-1.5 px-2.5 py-1 bg-red-500 text-white text-xs font-bold rounded-full">
              <Circle className="h-2 w-2 fill-current" />
              SCHEDULED
            </span>
          ) : isNow && (
            <span className="absolute top-3 left-3 flex items-center gap-1.5 px-2.5 py-1 bg-red-600 text-white text-xs font-bold rounded-full">
              <Circle className="h-2 w-2 fill-current animate-pulse" />
              LIVE NOW
            </span>
          )}
          <div>
            <h2 className="text-xl font-bold text-white drop-shadow-lg">{program.title}</h2>
            {channel && (
              <p className="text-white/90 text-sm mt-1">
                Ch {channel.number} • {channel.name}
              </p>
            )}
          </div>
        </div>

        <div className="p-5">
          <div className="flex flex-wrap items-center gap-3 text-sm text-gray-400 mb-4">
            <div className="flex items-center gap-1.5 bg-gray-700/50 px-2.5 py-1 rounded">
              <Calendar className="h-4 w-4" />
              {start.toLocaleDateString()}
            </div>
            <div className="flex items-center gap-1.5 bg-gray-700/50 px-2.5 py-1 rounded">
              <Clock className="h-4 w-4" />
              {formatTime(start)} - {formatTime(end)} ({duration} min)
            </div>
            {program.category && (
              <span className={`px-2.5 py-1 rounded text-xs font-semibold text-white ${categoryColor}`}>
                {program.category}
              </span>
            )}
            {/* NEW/PREMIERE/FINALE badges - for sports, only show NEW if also LIVE (not a replay) */}
            {(() => {
              const isSportsReplay = program.isSports && !program.isLive
              return (
                <>
                  {program.isPremiere && !isSportsReplay && (
                    <span className="px-2.5 py-1 bg-yellow-500 text-black text-xs font-bold rounded uppercase">
                      Premiere
                    </span>
                  )}
                  {program.isNew && !program.isPremiere && !isSportsReplay && (
                    <span className="px-2.5 py-1 bg-green-500 text-white text-xs font-bold rounded uppercase">
                      New Episode
                    </span>
                  )}
                  {program.isFinale && (
                    <span className="px-2.5 py-1 bg-purple-500 text-white text-xs font-bold rounded uppercase">
                      Finale
                    </span>
                  )}
                  {program.isLive && (
                    <span className="px-2.5 py-1 bg-red-500 text-white text-xs font-bold rounded uppercase animate-pulse">
                      Live
                    </span>
                  )}
                </>
              )
            })()}
          </div>

          {program.description && (
            <p className="text-gray-300 text-sm leading-relaxed mb-4">{program.description}</p>
          )}

          {program.episodeNum && (
            <p className="text-gray-500 text-xs mb-4">{program.episodeNum}</p>
          )}

          <div className="flex gap-3 mt-6 pt-4 border-t border-gray-700">
            {isNow && channel?.streamUrl && (
              <button
                onClick={onWatchNow}
                className="flex-1 flex items-center justify-center gap-2 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors"
              >
                <Video className="h-5 w-5" />
                Watch Now
              </button>
            )}
            {(isNow || isFuture) && !isScheduledToRecord && (
              <>
                <button
                  onClick={() => onRecord(false)}
                  disabled={isRecording}
                  className="flex-1 py-3 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-lg font-semibold transition-colors"
                >
                  {isRecording ? 'Recording...' : 'Record'}
                </button>
                <button
                  onClick={() => onRecord(true)}
                  disabled={isRecording}
                  className="flex-1 py-3 bg-gray-700 hover:bg-gray-600 disabled:opacity-50 text-white rounded-lg font-semibold transition-colors"
                >
                  Record Series
                </button>
              </>
            )}
            {isScheduledToRecord && onCancelRecording && (
              <button
                onClick={onCancelRecording}
                className="flex-1 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors"
              >
                {scheduledStatus === 'recording' ? 'Stop Recording' : 'Cancel Recording'}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

// Live TV Video Player Modal
function LiveTVPlayer({
  channel,
  program,
  onClose,
}: {
  channel: Channel
  program?: Program
  onClose: () => void
}) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const hlsRef = useRef<Hls | null>(null)
  const mpegtsRef = useRef<mpegts.Player | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isMuted, setIsMuted] = useState(false)
  const [isPlaying, setIsPlaying] = useState(true)
  const [showControls, setShowControls] = useState(true)
  const [retryCount, setRetryCount] = useState(0)
  const controlsTimeoutRef = useRef<number | null>(null)
  const loadingTimeoutRef = useRef<number | null>(null)

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

  useEffect(() => {
    const video = videoRef.current
    if (!video) return

    // Check if channel has a stream URL
    if (!channel.streamUrl) {
      setError('No stream URL available for this channel')
      setIsLoading(false)
      return
    }

    setIsLoading(true)
    setError(null)

    // Use absolute proxy URL for web worker compatibility
    const proxyUrl = `${window.location.origin}/livetv/channels/${channel.id}/stream`
    console.log('[LiveTVPlayer] Loading stream:', proxyUrl, 'Original URL:', channel.streamUrl)

    // Try mpegts.js first since most live TV streams are MPEG-TS
    // Fall back to HLS.js if mpegts fails
    if (mpegts.isSupported()) {
      console.log('[LiveTVPlayer] Trying mpegts.js first (most live TV is MPEG-TS)')
      let mpegtsWorked = false

      const player = mpegts.createPlayer({
        type: 'mpegts',
        isLive: true,
        url: proxyUrl,
      }, {
        enableWorker: false,
        lazyLoad: false,
        autoCleanupSourceBuffer: true,
        autoCleanupMaxBackwardDuration: 60,
        autoCleanupMinBackwardDuration: 30,
        stashInitialSize: 512 * 1024, // Larger buffer to reduce stuttering
        enableStashBuffer: true,
        liveBufferLatencyChasing: false, // Disable latency chasing to reduce stuttering
        liveBufferLatencyMaxLatency: 10,
        liveBufferLatencyMinRemain: 3,
      })
      mpegtsRef.current = player
      player.attachMediaElement(video)
      player.load()

      player.on(mpegts.Events.MEDIA_INFO, () => {
        console.log('[LiveTVPlayer] mpegts media info received - stream is MPEG-TS')
        mpegtsWorked = true
        // Clear timeout since loading succeeded
        if (loadingTimeoutRef.current) {
          clearTimeout(loadingTimeoutRef.current)
          loadingTimeoutRef.current = null
        }
        setIsLoading(false)
        video.play().catch((err) => console.error('[LiveTVPlayer] Play error:', err))
      })

      player.on(mpegts.Events.ERROR, (errorType: string, errorDetail: string) => {
        console.error('[LiveTVPlayer] mpegts error:', errorType, errorDetail)
        if (!mpegtsWorked) {
          // mpegts failed, try HLS
          console.log('[LiveTVPlayer] mpegts failed, trying HLS.js...')
          player.destroy()
          mpegtsRef.current = null

          if (Hls.isSupported()) {
            const hls = new Hls({
              enableWorker: true,
              lowLatencyMode: true,
            })
            hlsRef.current = hls

            hls.on(Hls.Events.MANIFEST_PARSED, () => {
              console.log('[LiveTVPlayer] HLS manifest parsed successfully')
              if (loadingTimeoutRef.current) {
                clearTimeout(loadingTimeoutRef.current)
                loadingTimeoutRef.current = null
              }
              setIsLoading(false)
              video.play().catch((err) => console.error('[LiveTVPlayer] Play error:', err))
            })

            hls.on(Hls.Events.ERROR, (_, data) => {
              console.error('[LiveTVPlayer] HLS error:', data.type, data.details)
              if (data.fatal) {
                setError(`Stream error: ${data.details}`)
                setIsLoading(false)
              }
            })

            hls.loadSource(proxyUrl)
            hls.attachMedia(video)
          } else {
            setError(`Stream error: ${errorType} - ${errorDetail}`)
            setIsLoading(false)
          }
        } else {
          // Stream was working but errored - show error
          setError(`Stream error: ${errorType} - ${errorDetail}`)
          setIsLoading(false)
        }
      })
    } else if (Hls.isSupported()) {
      // Fallback to HLS if mpegts not supported
      console.log('[LiveTVPlayer] Using HLS.js (mpegts not supported)')
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: true,
      })
      hlsRef.current = hls

      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        console.log('[LiveTVPlayer] HLS manifest parsed successfully')
        if (loadingTimeoutRef.current) {
          clearTimeout(loadingTimeoutRef.current)
          loadingTimeoutRef.current = null
        }
        setIsLoading(false)
        video.play().catch((err) => console.error('[LiveTVPlayer] Play error:', err))
      })

      hls.on(Hls.Events.ERROR, (_, data) => {
        console.error('[LiveTVPlayer] HLS error:', data.type, data.details)
        if (data.fatal) {
          setError(`Stream error: ${data.details}`)
          setIsLoading(false)
        }
      })

      hls.loadSource(proxyUrl)
      hls.attachMedia(video)
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Safari native HLS support
      console.log('[LiveTVPlayer] Using native HLS (Safari)')
      video.src = proxyUrl
      video.addEventListener('loadedmetadata', () => {
        console.log('[LiveTVPlayer] Native HLS loaded')
        if (loadingTimeoutRef.current) {
          clearTimeout(loadingTimeoutRef.current)
          loadingTimeoutRef.current = null
        }
        setIsLoading(false)
        video.play().catch((err) => console.error('[LiveTVPlayer] Play error:', err))
      })
      video.addEventListener('error', () => {
        console.error('[LiveTVPlayer] Native HLS error:', video.error)
        setError(`Video error: ${video.error?.message || 'Unknown error'}`)
        setIsLoading(false)
      })
    } else {
      setError('Your browser does not support video playback')
      setIsLoading(false)
    }

    // Add a loading timeout in case neither HLS nor mpegts can load
    // Using 30 seconds since some streams take time to start
    loadingTimeoutRef.current = window.setTimeout(() => {
      console.error('[LiveTVPlayer] Loading timeout - stream failed to load within 30 seconds')
      setError('Stream failed to load. Please check if the channel is available.')
      setIsLoading(false)
      loadingTimeoutRef.current = null
    }, 30000)

    return () => {
      if (loadingTimeoutRef.current) {
        clearTimeout(loadingTimeoutRef.current)
        loadingTimeoutRef.current = null
      }
      if (hlsRef.current) {
        hlsRef.current.destroy()
        hlsRef.current = null
      }
      if (mpegtsRef.current) {
        mpegtsRef.current.destroy()
        mpegtsRef.current = null
      }
    }
  }, [channel.id, channel.streamUrl, retryCount])

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
    const container = document.getElementById('livetv-player-container')
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
        id="livetv-player-container"
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
            <div className="text-center max-w-md px-4">
              <p className="text-red-400 text-lg mb-4">{error}</p>
              <div className="flex gap-3 justify-center">
                <button
                  onClick={() => {
                    setError(null)
                    setIsLoading(true)
                    setRetryCount(c => c + 1)
                  }}
                  className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg flex items-center gap-2"
                >
                  <RefreshCw className="w-4 h-4" />
                  Retry
                </button>
                <button
                  onClick={onClose}
                  className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
                >
                  Close
                </button>
              </div>
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
                  <div className="flex items-center gap-3">
                    <h2 className="text-xl font-semibold text-white">
                      Ch {channel.number} - {channel.name}
                    </h2>
                    <span className="flex items-center gap-1.5 px-2.5 py-1 bg-red-600 text-white text-xs font-bold rounded-full">
                      <Circle className="h-2 w-2 fill-current animate-pulse" />
                      LIVE
                    </span>
                  </div>
                  {program && (
                    <p className="text-gray-300 mt-1">{program.title}</p>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Bottom bar */}
          <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/80 to-transparent">
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

export function TVGuidePage() {
  const queryClient = useQueryClient()
  const gridScrollRef = useRef<HTMLDivElement>(null)
  const channelScrollRef = useRef<HTMLDivElement>(null)
  const [selectedProgram, setSelectedProgram] = useState<{ program: Program; channel?: Channel } | null>(null)
  const [watchingChannel, setWatchingChannel] = useState<{ channel: Channel; program?: Program } | null>(null)
  const [timeOffset, setTimeOffset] = useState(0) // hours offset from now
  const [selectedGroup, setSelectedGroup] = useState<string>('all') // provider/group filter
  const [showOnlyUnmapped, setShowOnlyUnmapped] = useState(false) // filter to show only channels without EPG

  // EPG Mapping modal state
  const [mappingChannel, setMappingChannel] = useState<Channel | null>(null)
  const [mappingEpgSourceId, setMappingEpgSourceId] = useState<number | null>(null)
  const [mappingSearchQuery, setMappingSearchQuery] = useState('')

  // Calculate time range based on offset
  const { startTime, endTime } = useMemo(() => {
    const now = new Date()
    const start = new Date(now)
    start.setMinutes(0, 0, 0)
    start.setHours(start.getHours() + timeOffset - 1) // 1 hour before current view

    const end = new Date(start)
    end.setHours(end.getHours() + 6) // 6 hour window

    return { startTime: start, endTime: end }
  }, [timeOffset])

  const now = new Date()

  // Generate time slots (every 30 minutes)
  const timeSlots = useMemo(() => {
    const slots: Date[] = []
    const current = new Date(startTime)
    while (current < endTime) {
      slots.push(new Date(current))
      current.setMinutes(current.getMinutes() + 30)
    }
    return slots
  }, [startTime, endTime])

  // Fetch channels
  const { data: channelsData, isLoading: loadingChannels } = useQuery({
    queryKey: ['channels'],
    queryFn: async () => {
      const response = await fetch('/livetv/channels', {
        headers: { 'X-Plex-Token': api.getToken() || '' },
      })
      const data = await response.json()
      return (data.channels as Channel[])
        .filter(ch => ch.enabled !== false)
        .sort((a, b) => a.number - b.number)
    },
  })

  // Fetch guide data (channels + programs for current time window)
  const { data: guideData, isLoading: loadingPrograms } = useQuery({
    queryKey: ['guide'],
    queryFn: () => api.getGuide(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })

  // Fetch scheduled recordings to show badges on EPG
  const { data: scheduledRecordings } = useQuery({
    queryKey: ['scheduled-recordings'],
    queryFn: () => api.getRecordings(),
    staleTime: 30 * 1000, // 30 seconds
  })

  // Create a map of scheduled recordings by channel+time for quick lookup
  const scheduledProgramsMap = useMemo(() => {
    const map = new Map<string, { status: 'scheduled' | 'recording'; recordingId: number }>()
    if (!scheduledRecordings) return map

    scheduledRecordings
      .filter(r => r.status === 'scheduled' || r.status === 'recording')
      .forEach(rec => {
        // Key by channelId + startTime
        const key = `${rec.channelId}-${rec.startTime}`
        map.set(key, { status: rec.status as 'scheduled' | 'recording', recordingId: rec.id })
      })
    return map
  }, [scheduledRecordings])

  // Helper to check if a program is scheduled
  const getProgramRecordingStatus = useCallback((channelId: number, startTime: string): 'scheduled' | 'recording' | null => {
    const key = `${channelId}-${startTime}`
    return scheduledProgramsMap.get(key)?.status || null
  }, [scheduledProgramsMap])

  // Helper to get recording ID for a program
  const getProgramRecordingId = useCallback((channelId: number, startTime: string): number | null => {
    const key = `${channelId}-${startTime}`
    return scheduledProgramsMap.get(key)?.recordingId || null
  }, [scheduledProgramsMap])

  // Programs are already grouped by channelId in the guide response
  const programsByChannel = useMemo(() => {
    if (!guideData?.programs) return {}
    return guideData.programs
  }, [guideData])

  // Get unique groups/providers from channels
  const channelGroups = useMemo(() => {
    if (!channelsData) return []
    const groups = new Set<string>()
    channelsData.forEach(ch => {
      if (ch.group) groups.add(ch.group)
    })
    return Array.from(groups).sort()
  }, [channelsData])

  // Check if a channel has EPG programs - use channelId for matching (matches program.channelId from Gracenote)
  const channelHasEPG = useCallback((channel: Channel): boolean => {
    const programs = programsByChannel[channel.channelId] || []
    return programs.length > 0
  }, [programsByChannel])

  // Get current program for a channel
  const getCurrentProgram = useCallback((channel: Channel): Program | undefined => {
    const programs = programsByChannel[channel.channelId] || []
    const now = new Date()
    return programs.find(p => new Date(p.start) <= now && new Date(p.end) > now)
  }, [programsByChannel])

  // Filter channels by group and EPG status
  const filteredChannels = useMemo(() => {
    if (!channelsData) return []
    return channelsData.filter(ch => {
      // Filter by group
      if (selectedGroup !== 'all' && ch.group !== selectedGroup) {
        return false
      }
      // Filter by EPG status
      if (showOnlyUnmapped && channelHasEPG(ch)) {
        return false
      }
      return true
    })
  }, [channelsData, selectedGroup, showOnlyUnmapped, channelHasEPG])

  // Count channels without EPG per group
  const unmappedCountByGroup = useMemo(() => {
    if (!channelsData) return {}
    const counts: Record<string, number> = { all: 0 }
    channelsData.forEach(ch => {
      const hasEPG = channelHasEPG(ch)
      if (!hasEPG) {
        counts.all++
        if (ch.group) {
          counts[ch.group] = (counts[ch.group] || 0) + 1
        }
      }
    })
    return counts
  }, [channelsData, channelHasEPG])

  // Record mutation
  const recordProgram = useMutation({
    mutationFn: async ({ channelId, programId, seriesRecord }: { channelId: number; programId: number; seriesRecord: boolean }) => {
      const response = await fetch('/dvr/recordings/from-program', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || '',
        },
        body: JSON.stringify({ channelId, programId, seriesRecord }),
      })
      if (!response.ok) throw new Error('Failed to create recording')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recordings'] })
      queryClient.invalidateQueries({ queryKey: ['scheduled-recordings'] })
      setSelectedProgram(null)
    },
  })

  // Cancel recording mutation
  const cancelRecording = useMutation({
    mutationFn: async (recordingId: number) => {
      await api.deleteRecording(recordingId)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recordings'] })
      queryClient.invalidateQueries({ queryKey: ['scheduled-recordings'] })
      setSelectedProgram(null)
    },
  })

  // Fetch EPG sources for mapping modal
  const { data: epgSources } = useQuery({
    queryKey: ['epgSources'],
    queryFn: async () => {
      return await api.getEPGSources() as EPGSource[]
    },
  })

  // Fetch EPG channels for the selected source in mapping modal
  const { data: epgChannelsForMapping } = useQuery({
    queryKey: ['epgChannels', mappingEpgSourceId],
    queryFn: async () => {
      const response = await fetch(`/livetv/epg/channels?epgSourceId=${mappingEpgSourceId}`, {
        headers: { 'X-Plex-Token': api.getToken() || '' },
      })
      const data = await response.json()
      return data.channels as EPGChannel[]
    },
    enabled: !!mappingEpgSourceId && !!mappingChannel,
  })

  // Filter EPG channels by search query
  const filteredEpgChannels = useMemo(() => {
    if (!epgChannelsForMapping) return []
    if (!mappingSearchQuery.trim()) return epgChannelsForMapping
    const query = mappingSearchQuery.toLowerCase()
    return epgChannelsForMapping.filter(ch =>
      ch.callSign?.toLowerCase().includes(query) ||
      ch.channelNo?.toLowerCase().includes(query) ||
      ch.channelId.toLowerCase().includes(query) ||
      ch.sampleTitle?.toLowerCase().includes(query)
    )
  }, [epgChannelsForMapping, mappingSearchQuery])

  // Map channel mutation
  const mapChannel = useMutation({
    mutationFn: async ({ channelId, epgSourceId, epgChannelId }: { channelId: number; epgSourceId: number; epgChannelId: string }) => {
      const response = await fetch(`/livetv/channels/${channelId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || '',
        },
        body: JSON.stringify({
          epgSourceId,
          channelId: epgChannelId,
        }),
      })
      if (!response.ok) throw new Error('Failed to map channel')
      return response.json()
    },
    onSuccess: async () => {
      // Force immediate refetch of both channels and programs data
      await queryClient.refetchQueries({ queryKey: ['channels'] })
      await queryClient.refetchQueries({ queryKey: ['guide'] })
      setMappingChannel(null)
      setMappingSearchQuery('')
    },
  })

  // Unmap channel mutation
  const unmapChannel = useMutation({
    mutationFn: async (channelId: number) => {
      const response = await fetch(`/livetv/channels/${channelId}/epg-mapping`, {
        method: 'DELETE',
        headers: {
          'X-Plex-Token': api.getToken() || '',
        },
      })
      if (!response.ok) throw new Error('Failed to unmap channel')
      return response.json()
    },
    onSuccess: async () => {
      // Force immediate refetch
      await queryClient.refetchQueries({ queryKey: ['channels'] })
      await queryClient.refetchQueries({ queryKey: ['guide'] })
      setMappingChannel(null)
    },
  })

  // Auto-detect state
  const [autoDetectResult, setAutoDetectResult] = useState<AutoDetectResponse | null>(null)

  // Auto-detect EPG mutation
  const autoDetectEPG = useMutation({
    mutationFn: async () => {
      const response = await fetch('/livetv/channels/auto-detect?apply=true&unmappedOnly=true', {
        method: 'POST',
        headers: {
          'X-Plex-Token': api.getToken() || '',
        },
      })
      if (!response.ok) throw new Error('Failed to auto-detect EPG mappings')
      return response.json() as Promise<AutoDetectResponse>
    },
    onSuccess: async (data) => {
      // Force immediate refetch after auto-detect
      await queryClient.refetchQueries({ queryKey: ['channels'] })
      await queryClient.refetchQueries({ queryKey: ['guide'] })
      setAutoDetectResult(data)
    },
  })

  // Auto-select first EPG source when opening mapping modal
  useEffect(() => {
    if (mappingChannel && epgSources && epgSources.length > 0 && !mappingEpgSourceId) {
      setMappingEpgSourceId(epgSources[0].id)
    }
  }, [mappingChannel, epgSources, mappingEpgSourceId])

  // Sync scroll between channel list and grid
  const handleGridScroll = useCallback(() => {
    if (gridScrollRef.current && channelScrollRef.current) {
      channelScrollRef.current.scrollTop = gridScrollRef.current.scrollTop
    }
  }, [])

  // Scroll to current time on mount
  useEffect(() => {
    if (gridScrollRef.current && timeOffset === 0) {
      const minutesFromStart = (now.getTime() - startTime.getTime()) / 60000
      const scrollPosition = minutesFromStart * PIXELS_PER_MINUTE - 100
      gridScrollRef.current.scrollLeft = Math.max(0, scrollPosition)
    }
  }, [startTime, timeOffset])

  // Calculate grid dimensions
  const gridWidth = ((endTime.getTime() - startTime.getTime()) / 60000) * PIXELS_PER_MINUTE
  const currentTimeOffset = ((now.getTime() - startTime.getTime()) / 60000) * PIXELS_PER_MINUTE

  const channels = filteredChannels
  const isLoading = loadingChannels || loadingPrograms
  const totalChannels = channelsData?.length || 0

  const handleRecord = (seriesRecord: boolean) => {
    if (selectedProgram) {
      recordProgram.mutate({
        channelId: selectedProgram.channel?.id || 0,
        programId: selectedProgram.program.id,
        seriesRecord,
      })
    }
  }

  const goToPrevious = () => setTimeOffset(prev => prev - 3)
  const goToNext = () => setTimeOffset(prev => prev + 3)
  const goToNow = () => setTimeOffset(0)

  return (
    <div className="h-full flex flex-col">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">TV Guide</h1>
          <p className="text-gray-400 mt-1">Browse the program schedule and record shows</p>
        </div>

        {/* Time navigation */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => {
              queryClient.refetchQueries({ queryKey: ['channels'] })
              queryClient.refetchQueries({ queryKey: ['guide'] })
            }}
            className="p-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
            title="Refresh EPG data"
          >
            <RefreshCw className={`h-5 w-5 ${loadingChannels || loadingPrograms ? 'animate-spin' : ''}`} />
          </button>
          <div className="h-6 w-px bg-gray-600" />
          <button
            onClick={goToPrevious}
            className="p-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <button
            onClick={goToNow}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
          >
            Now
          </button>
          <button
            onClick={goToNext}
            className="p-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>
      </div>

      {/* Filters and Legend */}
      <div className="flex flex-wrap items-center gap-4 mb-4">
        {/* Provider/Group filter */}
        <div className="flex items-center gap-2">
          <label className="text-sm text-gray-400">Provider:</label>
          <select
            value={selectedGroup}
            onChange={(e) => setSelectedGroup(e.target.value)}
            className="px-3 py-1.5 bg-gray-700 border border-gray-600 rounded text-white text-sm min-w-[180px]"
          >
            <option value="all">
              All Groups ({totalChannels} channels)
            </option>
            {channelGroups.map(group => (
              <option key={group} value={group}>
                {group} ({channelsData?.filter(ch => ch.group === group).length || 0})
                {unmappedCountByGroup[group] > 0 && ` - ${unmappedCountByGroup[group]} need EPG`}
              </option>
            ))}
          </select>
        </div>

        {/* Show only unmapped toggle */}
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={showOnlyUnmapped}
            onChange={(e) => setShowOnlyUnmapped(e.target.checked)}
            className="w-4 h-4 rounded border-gray-500 bg-gray-600 text-red-600 focus:ring-red-500"
          />
          <span className="text-sm text-gray-400">
            Show only channels without EPG
            {unmappedCountByGroup.all > 0 && (
              <span className="ml-1 text-red-400">({unmappedCountByGroup.all})</span>
            )}
          </span>
        </label>

        {/* Auto-Detect EPG button */}
        {unmappedCountByGroup.all > 0 && (
          <button
            onClick={() => autoDetectEPG.mutate()}
            disabled={autoDetectEPG.isPending}
            className="flex items-center gap-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white text-sm font-medium rounded-lg transition-colors"
          >
            <Wand2 className={`h-4 w-4 ${autoDetectEPG.isPending ? 'animate-spin' : ''}`} />
            {autoDetectEPG.isPending ? 'Detecting...' : 'Auto-Detect EPG'}
          </button>
        )}

        {/* Separator */}
        <div className="h-6 w-px bg-gray-700" />

        {/* Legend */}
        {Object.entries(categoryColors).map(([category, color]) => (
          <div key={category} className="flex items-center gap-2">
            <div className={`w-4 h-4 rounded ${color}`} />
            <span className="text-sm text-gray-400">{category}</span>
          </div>
        ))}
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center bg-gray-800 rounded-xl">
          <div className="text-center">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-500 mx-auto mb-4" />
            <p className="text-gray-400">Loading TV Guide...</p>
          </div>
        </div>
      ) : (
        <div className="flex-1 bg-gray-800 rounded-xl overflow-hidden flex flex-col min-h-0">
          {/* Header row */}
          <div className="flex flex-shrink-0 border-b border-gray-700">
            {/* Corner spacer */}
            <div
              className="flex-shrink-0 bg-gray-900 border-r border-gray-700 flex items-center justify-center flex-col"
              style={{ width: CHANNEL_WIDTH, height: TIME_HEADER_HEIGHT }}
            >
              <span className="text-sm font-semibold text-gray-400">
                {channels.length} Channels
              </span>
              {channels.length !== totalChannels && (
                <span className="text-xs text-gray-500">of {totalChannels}</span>
              )}
            </div>

            {/* Time header (scrolls with grid) */}
            <div className="flex-1 overflow-hidden">
              <div
                className="relative bg-gray-900"
                style={{ width: gridWidth, height: TIME_HEADER_HEIGHT }}
              >
                {timeSlots.map((time, idx) => (
                  <div
                    key={idx}
                    className="absolute top-0 bottom-0 border-l border-gray-700 flex items-center px-3"
                    style={{ left: ((time.getTime() - startTime.getTime()) / 60000) * PIXELS_PER_MINUTE }}
                  >
                    <span className="text-sm font-medium text-gray-300">{formatTime(time)}</span>
                  </div>
                ))}

                {/* Current time indicator in header */}
                {currentTimeOffset > 0 && currentTimeOffset < gridWidth && (
                  <div
                    className="absolute top-0 bottom-0 w-0.5 bg-red-500 z-20"
                    style={{ left: currentTimeOffset }}
                  >
                    <div className="absolute -top-0 left-1/2 -translate-x-1/2 w-3 h-3 bg-red-500 rounded-full" />
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Main content area */}
          <div className="flex flex-1 min-h-0">
            {/* Channel column (synced scroll) */}
            <div
              ref={channelScrollRef}
              className="flex-shrink-0 overflow-hidden border-r border-gray-700"
              style={{ width: CHANNEL_WIDTH }}
            >
              <div>
                {channels.map((channel) => {
                  const hasEPG = channelHasEPG(channel)
                  return (
                    <div
                      key={channel.id}
                      className={`flex items-center gap-2 px-3 border-b border-gray-700/50 hover:bg-gray-750 cursor-pointer group ${
                        hasEPG ? 'bg-gray-800' : 'bg-red-900/20'
                      }`}
                      style={{ height: ROW_HEIGHT }}
                      onClick={() => {
                        if (channel.streamUrl) {
                          setWatchingChannel({ channel, program: getCurrentProgram(channel) })
                        }
                      }}
                    >
                      {/* Play button */}
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          if (channel.streamUrl) {
                            setWatchingChannel({ channel, program: getCurrentProgram(channel) })
                          }
                        }}
                        className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 transition-all ${
                          channel.streamUrl
                            ? 'bg-green-600 hover:bg-green-500 text-white opacity-70 group-hover:opacity-100'
                            : 'bg-gray-700 text-gray-500 cursor-not-allowed'
                        }`}
                        title={channel.streamUrl ? 'Watch Now' : 'No stream available'}
                        disabled={!channel.streamUrl}
                      >
                        <Play className="h-4 w-4 ml-0.5" />
                      </button>
                      {channel.logo ? (
                        <img
                          src={channel.logo}
                          alt={channel.name}
                          className="w-10 h-7 object-contain bg-gray-700 rounded flex-shrink-0"
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = 'none'
                          }}
                        />
                      ) : (
                        <div className="w-10 h-7 bg-gray-700 rounded flex items-center justify-center text-xs text-gray-400 flex-shrink-0">
                          {channel.number}
                        </div>
                      )}
                      <div className="min-w-0 flex-1">
                        <div className="text-sm font-medium text-white truncate">{channel.name}</div>
                        <div className="text-xs text-gray-500 flex items-center gap-1 flex-wrap">
                          Ch {channel.number}
                          {channel.sourceName && (
                            <span className="text-indigo-400">• {channel.sourceName}</span>
                          )}
                          {!hasEPG ? (
                            <>
                              <span className="text-red-400 font-medium">• No EPG</span>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation()
                                  setMappingChannel(channel)
                                }}
                                className="ml-1 px-1.5 py-0.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs rounded transition-colors flex items-center gap-0.5"
                                title="Map to EPG channel"
                              >
                                <Link2 className="h-3 w-3" />
                                Map
                              </button>
                            </>
                          ) : (
                            <button
                              onClick={(e) => {
                                e.stopPropagation()
                                setMappingChannel(channel)
                              }}
                              className="ml-1 px-1.5 py-0.5 bg-gray-600 hover:bg-gray-500 text-white text-xs rounded transition-colors flex items-center gap-0.5 opacity-60 hover:opacity-100"
                              title="Change EPG mapping"
                            >
                              <Link2 className="h-3 w-3" />
                              Re-map
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>

            {/* Program grid (scrollable) */}
            <div
              ref={gridScrollRef}
              className="flex-1 overflow-auto"
              onScroll={handleGridScroll}
            >
              <div className="relative" style={{ width: gridWidth, minWidth: '100%' }}>
                {/* Current time line */}
                {currentTimeOffset > 0 && currentTimeOffset < gridWidth && (
                  <div
                    className="absolute w-0.5 bg-red-500 z-10 pointer-events-none"
                    style={{
                      left: currentTimeOffset,
                      top: 0,
                      height: channels.length * ROW_HEIGHT
                    }}
                  />
                )}

                {/* Channel rows */}
                {channels.map((channel) => {
                  // Use channelId for EPG matching (matches program.channelId from Gracenote)
                  const channelPrograms: Program[] = programsByChannel[channel.channelId] || []

                  return (
                    <div
                      key={channel.id}
                      className="relative border-b border-gray-700/50"
                      style={{ height: ROW_HEIGHT }}
                    >
                      {/* Time slot grid lines */}
                      {timeSlots.map((time, idx) => (
                        <div
                          key={idx}
                          className="absolute top-0 bottom-0 border-l border-gray-700/30"
                          style={{ left: ((time.getTime() - startTime.getTime()) / 60000) * PIXELS_PER_MINUTE }}
                        />
                      ))}

                      {/* Programs */}
                      {channelPrograms.map((program) => {
                        const programStart = new Date(program.start)
                        const programEnd = new Date(program.end)

                        // Skip if completely outside visible range
                        if (programEnd <= startTime || programStart >= endTime) return null

                        // Calculate visible portion
                        const visibleStart = programStart < startTime ? startTime : programStart
                        const visibleEnd = programEnd > endTime ? endTime : programEnd
                        const startOffset = ((visibleStart.getTime() - startTime.getTime()) / 60000) * PIXELS_PER_MINUTE
                        const width = ((visibleEnd.getTime() - visibleStart.getTime()) / 60000) * PIXELS_PER_MINUTE

                        const isNow = now >= programStart && now < programEnd
                        const recordingStatus = getProgramRecordingStatus(channel.id, program.start)

                        return (
                          <ProgramBlock
                            key={program.id}
                            program={program}
                            startOffset={startOffset}
                            width={width}
                            isNow={isNow}
                            isScheduled={recordingStatus === 'scheduled'}
                            isRecording={recordingStatus === 'recording'}
                            onClick={() => setSelectedProgram({ program, channel })}
                          />
                        )
                      })}

                      {/* Empty state for channels with no programs */}
                      {channelPrograms.filter((p: Program) => {
                        const ps = new Date(p.start)
                        const pe = new Date(p.end)
                        return !(pe <= startTime || ps >= endTime)
                      }).length === 0 && (
                        <div className="absolute inset-1 flex items-center justify-center">
                          <span className="text-xs text-gray-600">No program info</span>
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Program details modal */}
      {selectedProgram && (
        <ProgramModal
          program={selectedProgram.program}
          channel={selectedProgram.channel}
          onClose={() => setSelectedProgram(null)}
          onRecord={handleRecord}
          onWatchNow={() => {
            if (selectedProgram.channel?.streamUrl) {
              setWatchingChannel({
                channel: selectedProgram.channel,
                program: selectedProgram.program,
              })
            }
            setSelectedProgram(null)
          }}
          isRecording={recordProgram.isPending}
          scheduledStatus={selectedProgram.channel ? getProgramRecordingStatus(selectedProgram.channel.id, selectedProgram.program.start) : null}
          onCancelRecording={() => {
            if (selectedProgram.channel) {
              const recordingId = getProgramRecordingId(selectedProgram.channel.id, selectedProgram.program.start)
              if (recordingId) {
                cancelRecording.mutate(recordingId)
              }
            }
          }}
        />
      )}

      {/* Live TV Player modal */}
      {watchingChannel && (
        <LiveTVPlayer
          channel={watchingChannel.channel}
          program={watchingChannel.program}
          onClose={() => setWatchingChannel(null)}
        />
      )}

      {/* EPG Mapping modal */}
      {mappingChannel && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4" onClick={() => setMappingChannel(null)}>
          <div className="bg-gray-800 rounded-xl w-full max-w-2xl max-h-[80vh] overflow-hidden shadow-2xl flex flex-col" onClick={e => e.stopPropagation()}>
            {/* Header */}
            <div className="p-4 border-b border-gray-700 flex-shrink-0">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-white flex items-center gap-2">
                    <Link2 className="h-5 w-5" />
                    Map EPG Channel
                  </h2>
                  <p className="text-sm text-gray-400 mt-1">
                    Map <span className="text-indigo-400 font-medium">Ch {mappingChannel.number} - {mappingChannel.name}</span> to an EPG channel
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  {/* Remove Mapping button - only show if channel has EPG */}
                  {channelHasEPG(mappingChannel) && (
                    <button
                      onClick={() => unmapChannel.mutate(mappingChannel.id)}
                      disabled={unmapChannel.isPending}
                      className="px-3 py-1.5 bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white text-sm rounded-lg transition-colors flex items-center gap-1.5"
                    >
                      <X className="h-4 w-4" />
                      {unmapChannel.isPending ? 'Removing...' : 'Remove Mapping'}
                    </button>
                  )}
                  <button
                    onClick={() => setMappingChannel(null)}
                    className="p-1.5 bg-gray-700 hover:bg-gray-600 rounded-full transition-colors"
                  >
                    <X className="h-5 w-5 text-white" />
                  </button>
                </div>
              </div>

              {/* EPG Source selector */}
              {epgSources && epgSources.length > 0 && (
                <div className="mt-3">
                  <label className="text-sm text-gray-400 mb-1 block">EPG Source:</label>
                  <select
                    value={mappingEpgSourceId || ''}
                    onChange={(e) => {
                      setMappingEpgSourceId(parseInt(e.target.value))
                      setMappingSearchQuery('')
                    }}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white text-sm"
                  >
                    {epgSources.map(source => (
                      <option key={source.id} value={source.id}>
                        {source.name} ({source.channelCount} channels)
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {/* Search input */}
              <div className="relative mt-3">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search by call sign, channel number, or title..."
                  value={mappingSearchQuery}
                  onChange={(e) => setMappingSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded text-white placeholder-gray-400 text-sm"
                  autoFocus
                />
              </div>

              <div className="text-xs text-gray-500 mt-2">
                {filteredEpgChannels.length} channel{filteredEpgChannels.length !== 1 ? 's' : ''} found
                {mappingSearchQuery && ` for "${mappingSearchQuery}"`}
              </div>
            </div>

            {/* Channel list */}
            <div className="flex-1 overflow-y-auto p-4">
              {!epgChannelsForMapping ? (
                <div className="text-center py-8 text-gray-400">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500 mx-auto mb-3" />
                  <p>Loading EPG channels...</p>
                </div>
              ) : filteredEpgChannels.length === 0 ? (
                <div className="text-center py-8 text-gray-400">
                  <p>No channels match your search</p>
                </div>
              ) : (
                <div className="space-y-2">
                  {filteredEpgChannels.slice(0, 100).map((epgChannel) => (
                    <button
                      key={epgChannel.channelId}
                      onClick={() => {
                        if (mappingEpgSourceId) {
                          mapChannel.mutate({
                            channelId: mappingChannel.id,
                            epgSourceId: mappingEpgSourceId,
                            epgChannelId: epgChannel.channelId,
                          })
                        }
                      }}
                      disabled={mapChannel.isPending}
                      className="w-full p-3 bg-gray-700 hover:bg-gray-600 rounded-lg text-left transition-colors disabled:opacity-50"
                    >
                      <div className="flex items-center justify-between">
                        <div className="min-w-0 flex-1">
                          <div className="text-white font-medium">
                            {epgChannel.callSign || epgChannel.channelId}
                            {epgChannel.channelNo && (
                              <span className="text-gray-400 font-normal ml-2">Ch {epgChannel.channelNo}</span>
                            )}
                          </div>
                          <div className="text-sm text-gray-400 truncate">
                            {epgChannel.sampleTitle}
                          </div>
                        </div>
                        <Link2 className="h-4 w-4 text-gray-500 flex-shrink-0 ml-2" />
                      </div>
                    </button>
                  ))}
                  {filteredEpgChannels.length > 100 && (
                    <p className="text-center text-sm text-gray-500 py-2">
                      Showing first 100 results. Use search to narrow down.
                    </p>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Auto-Detect Results modal */}
      {autoDetectResult && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4" onClick={() => setAutoDetectResult(null)}>
          <div className="bg-gray-800 rounded-xl w-full max-w-2xl max-h-[80vh] overflow-hidden shadow-2xl flex flex-col" onClick={e => e.stopPropagation()}>
            {/* Header */}
            <div className="p-4 border-b border-gray-700 flex-shrink-0">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-white flex items-center gap-2">
                    <Wand2 className="h-5 w-5 text-indigo-400" />
                    Auto-Detect Results
                  </h2>
                  <p className="text-sm text-gray-400 mt-1">
                    EPG channel mapping completed
                  </p>
                </div>
                <button
                  onClick={() => setAutoDetectResult(null)}
                  className="p-1.5 bg-gray-700 hover:bg-gray-600 rounded-full transition-colors"
                >
                  <X className="h-5 w-5 text-white" />
                </button>
              </div>

              {/* Summary stats */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-4">
                <div className="bg-gray-700/50 rounded-lg p-3 text-center">
                  <div className="text-2xl font-bold text-white">{autoDetectResult.summary.totalChannels}</div>
                  <div className="text-xs text-gray-400">Scanned</div>
                </div>
                <div className="bg-green-600/20 rounded-lg p-3 text-center">
                  <div className="text-2xl font-bold text-green-400">{autoDetectResult.summary.newMappings}</div>
                  <div className="text-xs text-gray-400">New Mappings</div>
                </div>
                <div className="bg-blue-600/20 rounded-lg p-3 text-center">
                  <div className="text-2xl font-bold text-blue-400">{autoDetectResult.summary.alreadyMapped}</div>
                  <div className="text-xs text-gray-400">Already Mapped</div>
                </div>
                <div className="bg-yellow-600/20 rounded-lg p-3 text-center">
                  <div className="text-2xl font-bold text-yellow-400">{autoDetectResult.summary.noMatchFound}</div>
                  <div className="text-xs text-gray-400">No Match</div>
                </div>
              </div>
            </div>

            {/* Results list */}
            <div className="flex-1 overflow-y-auto p-4">
              {autoDetectResult.results.filter(r => r.autoMapped).length > 0 && (
                <>
                  <h3 className="text-sm font-semibold text-green-400 mb-2">Successfully Mapped</h3>
                  <div className="space-y-2 mb-4">
                    {autoDetectResult.results.filter(r => r.autoMapped).map((result) => (
                      <div key={result.channelId} className="p-3 bg-green-600/10 border border-green-600/30 rounded-lg">
                        <div className="flex items-center justify-between">
                          <div>
                            <span className="text-white font-medium">{result.channelName}</span>
                            {result.bestMatch && (
                              <span className="text-green-400 ml-2">
                                → {result.bestMatch.epgCallSign || result.bestMatch.epgName}
                              </span>
                            )}
                          </div>
                          {result.bestMatch && (
                            <span className="text-xs bg-green-600/30 text-green-300 px-2 py-1 rounded">
                              {Math.round(result.bestMatch.confidence * 100)}% • {result.bestMatch.matchStrategy}
                            </span>
                          )}
                        </div>
                        {result.bestMatch?.matchReason && (
                          <div className="text-xs text-gray-400 mt-1">{result.bestMatch.matchReason}</div>
                        )}
                      </div>
                    ))}
                  </div>
                </>
              )}

              {autoDetectResult.results.filter(r => !r.autoMapped && !r.currentMapping).length > 0 && (
                <>
                  <h3 className="text-sm font-semibold text-yellow-400 mb-2">No Match Found</h3>
                  <div className="space-y-2">
                    {autoDetectResult.results.filter(r => !r.autoMapped && !r.currentMapping).map((result) => (
                      <div key={result.channelId} className="p-3 bg-yellow-600/10 border border-yellow-600/30 rounded-lg">
                        <div className="flex items-center justify-between">
                          <span className="text-white">{result.channelName}</span>
                          <button
                            onClick={() => {
                              const channel = channelsData?.find(c => c.id === result.channelId)
                              if (channel) {
                                setAutoDetectResult(null)
                                setMappingChannel(channel)
                              }
                            }}
                            className="text-xs bg-gray-600 hover:bg-gray-500 text-white px-2 py-1 rounded transition-colors"
                          >
                            Map Manually
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-gray-700 flex-shrink-0">
              <button
                onClick={() => setAutoDetectResult(null)}
                className="w-full py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-lg transition-colors"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
