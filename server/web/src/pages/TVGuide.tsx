import { useState, useRef, useEffect, useMemo, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Clock, Calendar, Video, Circle, X, ChevronLeft, ChevronRight, Link2, Search, Wand2, RefreshCw, Volume2, VolumeX, Maximize, Loader, Play, Pause, SkipBack, SkipForward, Filter, List, LayoutGrid, ChevronDown } from 'lucide-react'
import { api } from '../api/client'
import Hls from 'hls.js'
import mpegts from 'mpegts.js'

const isAbsoluteUrl = (url?: string) => url ? /^https?:\/\//i.test(url) : false

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
const CHANNEL_WIDTH = 200
const ROW_HEIGHT = 64
const TIME_HEADER_HEIGHT = 44
const PIXELS_PER_MINUTE = 4 // 4px per minute = 240px per hour = 120px per 30min

// Category colors - more distinct palette
const categoryColors: { [key: string]: string } = {
  Movies: 'bg-purple-700/90',
  TVShow: 'bg-blue-700/90',
  Sports: 'bg-green-700/90',
  News: 'bg-red-700/90',
  Kids: 'bg-orange-600/90',
  Documentary: 'bg-teal-700/90',
}

// Category border colors for left accent
const categoryBorderColors: { [key: string]: string } = {
  Movies: 'border-l-purple-400',
  TVShow: 'border-l-blue-400',
  Sports: 'border-l-green-400',
  News: 'border-l-red-400',
  Kids: 'border-l-orange-400',
  Documentary: 'border-l-teal-400',
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
}

function formatDateLabel(date: Date): string {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const target = new Date(date)
  target.setHours(0, 0, 0, 0)
  const diffDays = Math.round((target.getTime() - today.getTime()) / (24 * 60 * 60 * 1000))

  if (diffDays === 0) return 'Today'
  if (diffDays === 1) return 'Tomorrow'
  if (diffDays === -1) return 'Yesterday'
  return date.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })
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
  const categoryColor = categoryColors[program.category || ''] || 'bg-gray-700/90'
  const borderColor = categoryBorderColors[program.category || ''] || 'border-l-gray-500'
  const minWidth = 50

  if (width < 16) return null

  return (
    <div
      onClick={onClick}
      className={`absolute top-[3px] bottom-[3px] rounded cursor-pointer overflow-hidden transition-all hover:z-20 hover:ring-2 hover:ring-white/60 hover:brightness-110 border-l-[3px] ${borderColor} ${categoryColor} ${isNow ? 'ring-1 ring-yellow-400/50' : ''}`}
      style={{
        left: `${startOffset}px`,
        width: `${Math.max(width - 2, minWidth)}px`,
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
        const isSportsReplay = program.isSports && !program.isLive
        const showNew = program.isNew && !isSportsReplay
        const showPremiere = program.isPremiere && !isSportsReplay
        const showLive = program.isLive
        const showFinale = program.isFinale

        if (!showNew && !showPremiere && !showFinale && !showLive) return null

        return (
          <div className="absolute top-1 left-1 z-10 flex gap-0.5">
            {showLive && (
              <span className="px-1 py-0.5 bg-red-500 text-white text-[8px] font-bold rounded uppercase animate-pulse leading-none">Live</span>
            )}
            {showPremiere && (
              <span className="px-1 py-0.5 bg-yellow-500 text-black text-[8px] font-bold rounded uppercase leading-none">Premiere</span>
            )}
            {showNew && !showPremiere && (
              <span className="px-1 py-0.5 bg-green-500 text-white text-[8px] font-bold rounded uppercase leading-none">New</span>
            )}
            {showFinale && (
              <span className="px-1 py-0.5 bg-purple-500 text-white text-[8px] font-bold rounded uppercase leading-none">Finale</span>
            )}
          </div>
        )
      })()}
      <div className="px-2 py-1 h-full flex flex-col justify-center">
        <div className="font-semibold text-white text-xs leading-tight truncate">{program.title}</div>
        {width > 100 && (
          <div className="text-[10px] text-white/70 mt-0.5 truncate">
            {formatTime(new Date(program.start))} - {formatTime(new Date(program.end))}
          </div>
        )}
        {width > 200 && program.description && (
          <div className="text-[10px] text-white/50 mt-0.5 line-clamp-1">
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
                Ch {channel.number} - {channel.name}
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
            {/* NEW/PREMIERE/FINALE badges */}
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
        stashInitialSize: 512 * 1024,
        enableStashBuffer: true,
        liveBufferLatencyChasing: false,
        liveBufferLatencyMaxLatency: 10,
        liveBufferLatencyMinRemain: 3,
      })
      mpegtsRef.current = player
      player.attachMediaElement(video)
      player.load()

      player.on(mpegts.Events.MEDIA_INFO, () => {
        console.log('[LiveTVPlayer] mpegts media info received - stream is MPEG-TS')
        mpegtsWorked = true
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
          setError(`Stream error: ${errorType} - ${errorDetail}`)
          setIsLoading(false)
        }
      })
    } else if (Hls.isSupported()) {
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

// ============================================================
// Date picker dropdown component
// ============================================================
function DatePickerDropdown({
  selectedDate,
  onSelectDate,
}: {
  selectedDate: Date
  onSelectDate: (date: Date) => void
}) {
  const [isOpen, setIsOpen] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  // Generate dates: yesterday through +6 days
  const dates = useMemo(() => {
    const result: Date[] = []
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    for (let i = -1; i <= 6; i++) {
      const d = new Date(today)
      d.setDate(d.getDate() + i)
      result.push(d)
    }
    return result
  }, [])

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white text-sm rounded-lg transition-colors border border-gray-600"
      >
        <Calendar className="h-4 w-4 text-gray-400" />
        <span>{formatDateLabel(selectedDate)}</span>
        <ChevronDown className={`h-4 w-4 text-gray-400 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>
      {isOpen && (
        <div className="absolute top-full mt-1 left-0 bg-gray-800 border border-gray-600 rounded-lg shadow-xl z-30 py-1 min-w-[180px]">
          {dates.map((date, idx) => {
            const isSelected = date.toDateString() === selectedDate.toDateString()
            return (
              <button
                key={idx}
                onClick={() => {
                  onSelectDate(date)
                  setIsOpen(false)
                }}
                className={`w-full text-left px-4 py-2 text-sm transition-colors ${
                  isSelected
                    ? 'bg-indigo-600 text-white'
                    : 'text-gray-300 hover:bg-gray-700'
                }`}
              >
                <span className="font-medium">{formatDateLabel(date)}</span>
                <span className="text-gray-400 ml-2 text-xs">
                  {date.toLocaleDateString([], { month: 'short', day: 'numeric' })}
                </span>
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}


// ============================================================
// Main TV Guide Page
// ============================================================
export function TVGuidePage() {
  const queryClient = useQueryClient()
  const gridContainerRef = useRef<HTMLDivElement>(null)
  const timeHeaderRef = useRef<HTMLDivElement>(null)
  const channelColumnRef = useRef<HTMLDivElement>(null)
  const [selectedProgram, setSelectedProgram] = useState<{ program: Program; channel?: Channel } | null>(null)
  const [watchingChannel, setWatchingChannel] = useState<{ channel: Channel; program?: Program } | null>(null)
  const [selectedGroup, setSelectedGroup] = useState<string>('all')
  const [selectedSource, setSelectedSource] = useState<string>('all')
  const [showOnlyUnmapped, setShowOnlyUnmapped] = useState(false)
  const [channelSearch, setChannelSearch] = useState('')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')

  // Date-based navigation - use current time rounded down to nearest hour as start
  const [selectedDate, setSelectedDate] = useState<Date>(() => {
    const d = new Date()
    d.setMinutes(0, 0, 0) // round to current hour
    return d
  })
  const [hoursWindow] = useState(4) // 4 hours visible at a time (like Channels DVR)

  // EPG Mapping modal state
  const [mappingChannel, setMappingChannel] = useState<Channel | null>(null)
  const [mappingEpgSourceId, setMappingEpgSourceId] = useState<number | null>(null)
  const [mappingSearchQuery, setMappingSearchQuery] = useState('')

  // Calculate time range based on selected date
  const { startTime, endTime } = useMemo(() => {
    const start = new Date(selectedDate)
    const end = new Date(start)
    end.setHours(end.getHours() + hoursWindow)
    return { startTime: start, endTime: end }
  }, [selectedDate, hoursWindow])

  const now = useMemo(() => new Date(), [])

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

  // Fetch channels (lightweight - no program data)
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

  // Fetch guide data - 4 hour window, server-side capped at 8h max
  const { data: guideData, isLoading: loadingPrograms } = useQuery({
    queryKey: ['guide', startTime.toISOString(), endTime.toISOString()],
    queryFn: async () => {
      const params = new URLSearchParams({
        start: startTime.toISOString(),
        end: endTime.toISOString(),
      })
      const response = await fetch(`/livetv/guide?${params}`, {
        headers: { 'X-Plex-Token': api.getToken() || '' },
      })
      return response.json()
    },
    staleTime: 5 * 60 * 1000,
  })

  // Fetch scheduled recordings to show badges on EPG
  const { data: scheduledRecordings } = useQuery({
    queryKey: ['scheduled-recordings'],
    queryFn: () => api.getRecordings(),
    staleTime: 30 * 1000,
  })

  // Create a map of scheduled recordings by channel+time for quick lookup
  const scheduledProgramsMap = useMemo(() => {
    const map = new Map<string, { status: 'scheduled' | 'recording'; recordingId: number }>()
    if (!scheduledRecordings) return map

    scheduledRecordings
      .filter(r => r.status === 'scheduled' || r.status === 'recording')
      .forEach(rec => {
        const key = `${rec.channelId}-${rec.startTime}`
        map.set(key, { status: rec.status as 'scheduled' | 'recording', recordingId: rec.id })
      })
    return map
  }, [scheduledRecordings])

  const getProgramRecordingStatus = useCallback((channelId: number, startTime: string): 'scheduled' | 'recording' | null => {
    const key = `${channelId}-${startTime}`
    return scheduledProgramsMap.get(key)?.status || null
  }, [scheduledProgramsMap])

  const getProgramRecordingId = useCallback((channelId: number, startTime: string): number | null => {
    const key = `${channelId}-${startTime}`
    return scheduledProgramsMap.get(key)?.recordingId || null
  }, [scheduledProgramsMap])

  // Programs grouped by channelId
  const programsByChannel = useMemo(() => {
    if (!guideData?.programs) return {}
    return guideData.programs
  }, [guideData])

  // Get unique groups from channels
  const channelGroups = useMemo(() => {
    if (!channelsData) return []
    const groups = new Set<string>()
    channelsData.forEach(ch => {
      if (ch.group) groups.add(ch.group)
    })
    return Array.from(groups).sort()
  }, [channelsData])

  // Get unique sources from channels
  const channelSources = useMemo(() => {
    if (!channelsData) return []
    const sources = new Map<string, number>()
    channelsData.forEach(ch => {
      if (ch.sourceName) {
        sources.set(ch.sourceName, (sources.get(ch.sourceName) || 0) + 1)
      }
    })
    return Array.from(sources.entries()).sort((a, b) => a[0].localeCompare(b[0]))
  }, [channelsData])

  const channelHasEPG = useCallback((channel: Channel): boolean => {
    const programs = programsByChannel[channel.channelId] || []
    return programs.length > 0
  }, [programsByChannel])

  const getCurrentProgram = useCallback((channel: Channel): Program | undefined => {
    const programs = programsByChannel[channel.channelId] || []
    const now = new Date()
    return programs.find((p: Program) => new Date(p.start) <= now && new Date(p.end) > now)
  }, [programsByChannel])

  // Filter channels
  const filteredChannels = useMemo(() => {
    if (!channelsData) return []
    return channelsData.filter(ch => {
      if (selectedGroup !== 'all' && ch.group !== selectedGroup) return false
      if (selectedSource !== 'all' && ch.sourceName !== selectedSource) return false
      if (showOnlyUnmapped && channelHasEPG(ch)) return false
      if (channelSearch.trim()) {
        const q = channelSearch.toLowerCase()
        const matchesName = ch.name.toLowerCase().includes(q)
        const matchesNumber = String(ch.number).includes(q)
        const matchesGroup = ch.group?.toLowerCase().includes(q)
        if (!matchesName && !matchesNumber && !matchesGroup) return false
      }
      return true
    })
  }, [channelsData, selectedGroup, selectedSource, showOnlyUnmapped, channelHasEPG, channelSearch])

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
      await queryClient.refetchQueries({ queryKey: ['channels'] })
      await queryClient.refetchQueries({ queryKey: ['guide'] })
      setMappingChannel(null)
    },
  })

  // Auto-detect state
  const [autoDetectResult, setAutoDetectResult] = useState<AutoDetectResponse | null>(null)

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

  // ============================================================
  // Scroll synchronization: time header + channel column + grid
  // ============================================================
  // Scroll to current time on mount / date change
  const scrollToNow = useCallback(() => {
    const grid = gridContainerRef.current
    if (!grid) return
    const nowMs = Date.now()
    const minutesFromStart = (nowMs - startTime.getTime()) / 60000
    if (minutesFromStart >= 0 && minutesFromStart <= (hoursWindow * 60)) {
      const scrollPosition = minutesFromStart * PIXELS_PER_MINUTE - grid.clientWidth / 3
      grid.scrollLeft = Math.max(0, scrollPosition)
      // Also sync header
      if (timeHeaderRef.current) {
        timeHeaderRef.current.scrollLeft = grid.scrollLeft
      }
    } else {
      // If "now" is not in the window, scroll to the start
      grid.scrollLeft = 0
      if (timeHeaderRef.current) {
        timeHeaderRef.current.scrollLeft = 0
      }
    }
  }, [startTime, hoursWindow])

  useEffect(() => {
    // Small delay to ensure DOM is rendered
    const timer = setTimeout(scrollToNow, 100)
    return () => clearTimeout(timer)
  }, [scrollToNow, guideData])

  // Calculate grid dimensions
  const gridWidth = ((endTime.getTime() - startTime.getTime()) / 60000) * PIXELS_PER_MINUTE
  const currentTimeOffset = ((now.getTime() - startTime.getTime()) / 60000) * PIXELS_PER_MINUTE
  const isCurrentTimeVisible = currentTimeOffset > 0 && currentTimeOffset < gridWidth

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

  // Navigate by time window (shift by hoursWindow)
  const goToPreviousWindow = () => {
    const d = new Date(selectedDate)
    d.setHours(d.getHours() - hoursWindow)
    setSelectedDate(d)
  }
  const goToNextWindow = () => {
    const d = new Date(selectedDate)
    d.setHours(d.getHours() + hoursWindow)
    setSelectedDate(d)
  }
  const goToNow = () => {
    const d = new Date()
    d.setMinutes(0, 0, 0)
    setSelectedDate(d)
  }

  // ============================================================
  // List view: shows what's on now per channel
  // ============================================================
  const renderListView = () => {
    return (
      <div className="flex-1 bg-gray-800 rounded-xl overflow-auto">
        <table className="w-full">
          <thead className="sticky top-0 bg-gray-900 z-10">
            <tr>
              <th className="text-left text-xs text-gray-400 font-medium px-4 py-3 w-12">#</th>
              <th className="text-left text-xs text-gray-400 font-medium px-4 py-3 w-16">Logo</th>
              <th className="text-left text-xs text-gray-400 font-medium px-4 py-3">Channel</th>
              <th className="text-left text-xs text-gray-400 font-medium px-4 py-3">Now Playing</th>
              <th className="text-left text-xs text-gray-400 font-medium px-4 py-3 w-32">Time</th>
              <th className="text-left text-xs text-gray-400 font-medium px-4 py-3 w-24">Category</th>
              <th className="text-left text-xs text-gray-400 font-medium px-4 py-3 w-20">EPG</th>
              <th className="text-left text-xs text-gray-400 font-medium px-4 py-3 w-20"></th>
            </tr>
          </thead>
          <tbody>
            {channels.map((channel) => {
              const currentProg = getCurrentProgram(channel)
              const hasEPG = channelHasEPG(channel)
              const categoryColor = currentProg ? (categoryColors[currentProg.category || ''] || 'bg-gray-600') : ''
              return (
                <tr
                  key={channel.id}
                  className={`border-b border-gray-700/30 hover:bg-gray-700/30 transition-colors ${!hasEPG ? 'bg-red-900/10' : ''}`}
                >
                  <td className="px-4 py-3 text-gray-500 text-sm">{channel.number}</td>
                  <td className="px-4 py-3">
                    {isAbsoluteUrl(channel.logo) ? (
                      <img
                        src={channel.logo}
                        alt={channel.name}
                        className="w-10 h-7 object-contain bg-gray-700 rounded"
                        onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                      />
                    ) : (
                      <div className="w-10 h-7 bg-gray-700 rounded flex items-center justify-center text-xs text-gray-400">
                        TV
                      </div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <div className="text-sm font-medium text-white">{channel.name}</div>
                    {channel.sourceName && (
                      <div className="text-xs text-gray-500">{channel.sourceName}</div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {currentProg ? (
                      <button
                        onClick={() => setSelectedProgram({ program: currentProg, channel })}
                        className="text-left hover:text-indigo-400 transition-colors"
                      >
                        <div className="text-sm font-medium text-white">{currentProg.title}</div>
                        {currentProg.description && (
                          <div className="text-xs text-gray-500 line-clamp-1 max-w-md">{currentProg.description}</div>
                        )}
                      </button>
                    ) : (
                      <span className="text-xs text-gray-600">No program info</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-400">
                    {currentProg && (
                      <>
                        {formatTime(new Date(currentProg.start))} - {formatTime(new Date(currentProg.end))}
                      </>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {currentProg?.category && (
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold text-white ${categoryColor}`}>
                        {currentProg.category}
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {hasEPG ? (
                      <button
                        onClick={() => setMappingChannel(channel)}
                        className="text-green-400 text-xs hover:text-green-300 hover:underline cursor-pointer transition-colors"
                      >
                        Mapped
                      </button>
                    ) : (
                      <button
                        onClick={() => setMappingChannel(channel)}
                        className="flex items-center gap-1 px-2 py-1 bg-indigo-600 hover:bg-indigo-700 text-white text-xs rounded transition-colors"
                      >
                        <Link2 className="h-3 w-3" />
                        Map
                      </button>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {channel.streamUrl && (
                      <button
                        onClick={() => setWatchingChannel({ channel, program: currentProg })}
                        className="p-1.5 bg-green-600 hover:bg-green-500 text-white rounded-full transition-colors"
                        title="Watch"
                      >
                        <Play className="h-3 w-3" />
                      </button>
                    )}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    )
  }

  // ============================================================
  // Grid view with virtualization
  // ============================================================

  // Virtualization state - track which rows are visible
  const [visibleRange, setVisibleRange] = useState({ start: 0, end: 50 })
  const OVERSCAN = 10 // Extra rows above/below viewport

  // Update visible range on scroll
  const updateVisibleRange = useCallback(() => {
    const grid = gridContainerRef.current
    if (!grid) return
    const scrollTop = grid.scrollTop
    const viewportHeight = grid.clientHeight
    const startRow = Math.floor(scrollTop / ROW_HEIGHT)
    const endRow = Math.ceil((scrollTop + viewportHeight) / ROW_HEIGHT)
    setVisibleRange({
      start: Math.max(0, startRow - OVERSCAN),
      end: Math.min(channels.length, endRow + OVERSCAN),
    })
  }, [channels.length])

  // Enhanced scroll handler with virtualization
  const handleGridScrollVirtualized = useCallback(() => {
    const grid = gridContainerRef.current
    if (!grid) return
    if (timeHeaderRef.current) {
      timeHeaderRef.current.scrollLeft = grid.scrollLeft
    }
    if (channelColumnRef.current) {
      channelColumnRef.current.scrollTop = grid.scrollTop
    }
    updateVisibleRange()
  }, [updateVisibleRange])

  // Initialize visible range after channels load
  useEffect(() => {
    updateVisibleRange()
  }, [channels.length, updateVisibleRange])

  // CSS background for grid lines (replaces per-row divs)
  const hourWidth = 60 * PIXELS_PER_MINUTE // px per hour
  const halfHourWidth = 30 * PIXELS_PER_MINUTE // px per 30min
  const gridBgStyle = useMemo(() => ({
    backgroundImage: `
      repeating-linear-gradient(to right, rgba(75,85,99,0.4) 0px, rgba(75,85,99,0.4) 1px, transparent 1px, transparent ${hourWidth}px),
      repeating-linear-gradient(to right, rgba(55,65,81,0.25) 0px, rgba(55,65,81,0.25) 1px, transparent 1px, transparent ${halfHourWidth}px)
    `,
    backgroundSize: `${hourWidth}px 100%, ${halfHourWidth}px 100%`,
  }), [hourWidth, halfHourWidth])

  const renderGridView = () => {
    const totalHeight = channels.length * ROW_HEIGHT
    const visibleChannels = channels.slice(visibleRange.start, visibleRange.end)

    return (
      <div className="flex-1 bg-gray-900 rounded-xl overflow-hidden flex flex-col min-h-0">
        {/* Top row: corner spacer + time header */}
        <div className="flex flex-shrink-0 border-b border-gray-700/50">
          {/* Corner spacer - fixed */}
          <div
            className="flex-shrink-0 bg-gray-900 border-r border-gray-700/50 flex items-center justify-center"
            style={{ width: CHANNEL_WIDTH, height: TIME_HEADER_HEIGHT }}
          >
            <span className="text-xs font-medium text-gray-500">
              {channels.length} / {totalChannels}
            </span>
          </div>

          {/* Time header - synced horizontal scroll with grid */}
          <div
            ref={timeHeaderRef}
            className="flex-1 overflow-hidden"
            style={{ scrollbarWidth: 'none' }}
          >
            <div
              className="relative bg-gray-900"
              style={{ width: gridWidth, height: TIME_HEADER_HEIGHT }}
            >
              {timeSlots.map((time, idx) => {
                const isHour = time.getMinutes() === 0
                const left = ((time.getTime() - startTime.getTime()) / 60000) * PIXELS_PER_MINUTE
                return (
                  <div
                    key={idx}
                    className={`absolute top-0 bottom-0 flex items-center px-2 ${isHour ? 'border-l border-gray-600' : 'border-l border-gray-700/40'}`}
                    style={{ left }}
                  >
                    <span className={`text-xs whitespace-nowrap ${isHour ? 'font-semibold text-gray-200' : 'font-normal text-gray-500'}`}>
                      {formatTime(time)}
                    </span>
                  </div>
                )
              })}

              {/* Current time marker in header */}
              {isCurrentTimeVisible && (
                <div
                  className="absolute top-0 bottom-0 w-0.5 bg-red-500 z-20"
                  style={{ left: currentTimeOffset }}
                >
                  <div className="absolute -bottom-0.5 left-1/2 -translate-x-1/2 w-0 h-0 border-l-[5px] border-r-[5px] border-t-[6px] border-l-transparent border-r-transparent border-t-red-500" />
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Main content area: channel column + program grid */}
        <div className="flex flex-1 min-h-0">
          {/* Channel column - synced vertical scroll with grid */}
          <div
            ref={channelColumnRef}
            className="flex-shrink-0 overflow-hidden border-r border-gray-700/50 bg-gray-900/80"
            style={{ width: CHANNEL_WIDTH, scrollbarWidth: 'none' }}
          >
            <div style={{ height: totalHeight, position: 'relative' }}>
              {visibleChannels.map((channel, idx) => {
                const hasEPG = channelHasEPG(channel)
                const rowIndex = visibleRange.start + idx
                return (
                  <div
                    key={channel.id}
                    className={`absolute left-0 right-0 flex items-center gap-2 px-2 border-b border-gray-800/80 hover:bg-gray-800 cursor-pointer group ${
                      hasEPG ? '' : 'bg-red-950/20'
                    }`}
                    style={{ height: ROW_HEIGHT, top: rowIndex * ROW_HEIGHT }}
                    onClick={() => {
                      if (channel.streamUrl) {
                        setWatchingChannel({ channel, program: getCurrentProgram(channel) })
                      }
                    }}
                  >
                    {/* Channel logo */}
                    {isAbsoluteUrl(channel.logo) ? (
                      <img
                        src={channel.logo}
                        alt={channel.name}
                        className="w-9 h-6 object-contain bg-gray-800 rounded flex-shrink-0"
                        onError={(e) => {
                          (e.target as HTMLImageElement).style.display = 'none'
                        }}
                      />
                    ) : (
                      <div className="w-9 h-6 bg-gray-800 rounded flex items-center justify-center text-[10px] text-gray-500 flex-shrink-0">
                        {channel.number}
                      </div>
                    )}
                    <div className="min-w-0 flex-1">
                      <div className="text-xs font-medium text-gray-200 truncate leading-tight">{channel.name}</div>
                      <div className="text-[10px] text-gray-500 flex items-center gap-1 flex-wrap leading-tight">
                        <span>{channel.number}</span>
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            setMappingChannel(channel)
                          }}
                          className={`ml-0.5 px-1 py-0 text-[9px] rounded transition-colors flex items-center gap-0.5 ${
                            hasEPG
                              ? 'text-green-400 hover:text-green-300 hover:bg-gray-700'
                              : 'bg-indigo-600 hover:bg-indigo-700 text-white'
                          }`}
                          title={hasEPG ? "Remap EPG channel" : "Map to EPG channel"}
                        >
                          <Link2 className="h-2.5 w-2.5" />
                          {hasEPG ? 'Remap' : 'Map'}
                        </button>
                      </div>
                    </div>
                    {/* Play indicator on hover */}
                    {channel.streamUrl && (
                      <div className="opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0">
                        <Play className="h-3.5 w-3.5 text-green-400" />
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          </div>

          {/* Program grid - main scrollable area */}
          <div
            ref={gridContainerRef}
            className="flex-1 overflow-auto"
            onScroll={handleGridScrollVirtualized}
          >
            <div className="relative" style={{ width: gridWidth, height: totalHeight, minWidth: '100%', ...gridBgStyle }}>
              {/* Current time line spanning all rows */}
              {isCurrentTimeVisible && (
                <div
                  className="absolute w-0.5 bg-red-500/80 z-10 pointer-events-none"
                  style={{
                    left: currentTimeOffset,
                    top: 0,
                    height: totalHeight,
                  }}
                />
              )}

              {/* Only render visible channel rows */}
              {visibleChannels.map((channel, idx) => {
                const channelPrograms: Program[] = programsByChannel[channel.channelId] || []
                const rowIndex = visibleRange.start + idx
                const rowTop = rowIndex * ROW_HEIGHT

                return (
                  <div
                    key={channel.id}
                    className="absolute left-0 right-0 border-b border-gray-800/60"
                    style={{ height: ROW_HEIGHT, top: rowTop }}
                  >
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
                        <span className="text-[10px] text-gray-700">No program data</span>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="h-full flex flex-col">
      {/* Header bar */}
      <div className="mb-3 flex items-center justify-between flex-wrap gap-2">
        <div className="flex items-center gap-4">
          <h1 className="text-2xl font-bold text-white">TV Guide</h1>
          {/* View mode toggle */}
          <div className="flex items-center bg-gray-800 rounded-lg p-0.5">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-1.5 rounded transition-colors ${viewMode === 'grid' ? 'bg-indigo-600 text-white' : 'text-gray-400 hover:text-white'}`}
              title="Grid View"
            >
              <LayoutGrid className="h-4 w-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-1.5 rounded transition-colors ${viewMode === 'list' ? 'bg-indigo-600 text-white' : 'text-gray-400 hover:text-white'}`}
              title="List View"
            >
              <List className="h-4 w-4" />
            </button>
          </div>
        </div>

        {/* Time / date navigation */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => {
              queryClient.refetchQueries({ queryKey: ['channels'] })
              queryClient.refetchQueries({ queryKey: ['guide'] })
            }}
            className="p-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
            title="Refresh EPG data"
          >
            <RefreshCw className={`h-4 w-4 ${loadingChannels || loadingPrograms ? 'animate-spin' : ''}`} />
          </button>
          <div className="h-5 w-px bg-gray-600" />
          <button
            onClick={goToPreviousWindow}
            className="p-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
            title={`Previous ${hoursWindow} hours`}
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
          <DatePickerDropdown
            selectedDate={selectedDate}
            onSelectDate={(d) => {
              d.setMinutes(0, 0, 0)
              setSelectedDate(d)
            }}
          />
          <button
            onClick={goToNextWindow}
            className="p-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
            title={`Next ${hoursWindow} hours`}
          >
            <ChevronRight className="h-4 w-4" />
          </button>
          <button
            onClick={() => {
              goToNow()
              setTimeout(scrollToNow, 200)
            }}
            className="px-3 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm font-medium transition-colors"
          >
            Now
          </button>
        </div>
      </div>

      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-3 mb-3">
        {/* Source filter */}
        {channelSources.length > 1 && (
          <div className="flex items-center gap-1.5">
            <Filter className="h-3.5 w-3.5 text-gray-500" />
            <select
              value={selectedSource}
              onChange={(e) => setSelectedSource(e.target.value)}
              className="px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm min-w-[140px]"
            >
              <option value="all">All Sources</option>
              {channelSources.map(([name, count]) => (
                <option key={name} value={name}>
                  {name} ({count})
                </option>
              ))}
            </select>
          </div>
        )}

        {/* Group filter */}
        {channelGroups.length > 0 && (
          <select
            value={selectedGroup}
            onChange={(e) => setSelectedGroup(e.target.value)}
            className="px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm min-w-[140px]"
          >
            <option value="all">All Groups ({totalChannels})</option>
            {channelGroups.map(group => (
              <option key={group} value={group}>
                {group} ({channelsData?.filter(ch => ch.group === group).length || 0})
              </option>
            ))}
          </select>
        )}

        {/* Channel search */}
        <div className="relative">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-500" />
          <input
            type="text"
            placeholder="Search channels..."
            value={channelSearch}
            onChange={(e) => setChannelSearch(e.target.value)}
            className="pl-8 pr-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 text-sm w-48"
          />
          {channelSearch && (
            <button
              onClick={() => setChannelSearch('')}
              className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300"
            >
              <X className="h-3.5 w-3.5" />
            </button>
          )}
        </div>

        {/* Show unmapped toggle */}
        <label className="flex items-center gap-1.5 cursor-pointer">
          <input
            type="checkbox"
            checked={showOnlyUnmapped}
            onChange={(e) => setShowOnlyUnmapped(e.target.checked)}
            className="w-3.5 h-3.5 rounded border-gray-500 bg-gray-600 text-red-600 focus:ring-red-500"
          />
          <span className="text-xs text-gray-400">
            No EPG only
            {unmappedCountByGroup.all > 0 && (
              <span className="ml-1 text-red-400">({unmappedCountByGroup.all})</span>
            )}
          </span>
        </label>

        {/* Auto-Detect EPG */}
        {unmappedCountByGroup.all > 0 && (
          <button
            onClick={() => autoDetectEPG.mutate()}
            disabled={autoDetectEPG.isPending}
            className="flex items-center gap-1.5 px-2.5 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white text-xs font-medium rounded-lg transition-colors"
          >
            <Wand2 className={`h-3.5 w-3.5 ${autoDetectEPG.isPending ? 'animate-spin' : ''}`} />
            {autoDetectEPG.isPending ? 'Detecting...' : 'Auto-Detect'}
          </button>
        )}

        <div className="flex-1" />

        {/* Legend - compact */}
        <div className="flex items-center gap-2">
          {Object.entries(categoryColors).map(([category, color]) => (
            <div key={category} className="flex items-center gap-1">
              <div className={`w-2.5 h-2.5 rounded-sm ${color}`} />
              <span className="text-[10px] text-gray-500">{category}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Main content */}
      {isLoading ? (
        <div className="flex-1 flex items-center justify-center bg-gray-800 rounded-xl">
          <div className="text-center">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-500 mx-auto mb-4" />
            <p className="text-gray-400">Loading TV Guide...</p>
          </div>
        </div>
      ) : viewMode === 'grid' ? (
        renderGridView()
      ) : (
        renderListView()
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
                                {result.bestMatch.epgCallSign || result.bestMatch.epgName}
                              </span>
                            )}
                          </div>
                          {result.bestMatch && (
                            <span className="text-xs bg-green-600/30 text-green-300 px-2 py-1 rounded">
                              {Math.round(result.bestMatch.confidence * 100)}%
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
