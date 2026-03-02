import { useState, useRef, useEffect, useCallback, useMemo } from 'react'
import Hls from 'hls.js'
import {
  Video,
  Trash2,
  CheckCircle,
  Loader,
  Play,
  Pause,
  Tv,
  CircleDot,
  X,
  SkipForward,
  ToggleLeft,
  ToggleRight,
  Volume2,
  VolumeX,
  Maximize,
  Radio,
  Rewind,
  Search,
  Square,
  CheckSquare,
  ChevronDown,
  Eye,
  EyeOff,
  Star,
  Lock,
  ArrowUp,
  ArrowDown,
  Film,
  Image,
  FileQuestion,
  MoreHorizontal,
  Download,
  Check,
  StopCircle,
} from 'lucide-react'
// DVR hooks available at '../hooks/useDVR' if needed
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type TMDBSearchResult } from '../api/client'
import type { Recording, CommercialSegment } from '../types'

// ============ Utility Functions ============

function _formatFileSize(bytes?: number): string {
  if (!bytes) return ''
  const gb = bytes / (1024 * 1024 * 1024)
  if (gb >= 1) return `${gb.toFixed(1)} GB`
  const mb = bytes / (1024 * 1024)
  return `${mb.toFixed(0)} MB`
}
void _formatFileSize

function formatDuration(minutes?: number): string {
  if (!minutes) return ''
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0) {
    return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`
  }
  return `${mins}m`
}

function _formatTimeRange(start: string, end: string): string {
  const startDate = new Date(start)
  const endDate = new Date(end)
  const timeOptions: Intl.DateTimeFormatOptions = { hour: 'numeric', minute: '2-digit' }
  return `${startDate.toLocaleTimeString([], timeOptions)} - ${endDate.toLocaleTimeString([], timeOptions)}`
}
void _formatTimeRange

function formatDateFull(dateStr: string): string {
  const date = new Date(dateStr)
  return date.toLocaleDateString([], {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

function getResolutionBadge(resolution?: string): string | null {
  if (!resolution) return null
  const r = resolution.toLowerCase()
  if (r.includes('2160') || r.includes('4k') || r.includes('uhd')) return '4K'
  if (r.includes('1080')) return 'HD'
  if (r.includes('720')) return 'HD'
  if (r.includes('480')) return 'SD'
  return null
}

function getAudioBadge(codec?: string): string | null {
  if (!codec) return null
  const c = codec.toLowerCase()
  if (c.includes('eac3') || c.includes('e-ac-3')) return 'Dolby Digital+'
  if (c.includes('ac3') || c.includes('ac-3')) return 'Dolby Digital'
  if (c.includes('atmos')) return 'Atmos'
  if (c.includes('dts')) return 'DTS'
  if (c.includes('aac')) return 'AAC'
  return null
}

// ============ Player Modals (preserved from original) ============

function WatchOptionsModal({
  recording,
  onClose,
  onSelect,
}: {
  recording: Recording
  onClose: () => void
  onSelect: (mode: 'start' | 'live') => void
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <CircleDot className="w-5 h-5 text-red-400 animate-pulse" />
            <h2 className="text-lg font-semibold text-white">Now Recording</h2>
          </div>
          <button onClick={onClose} className="p-1 text-gray-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        <p className="text-gray-300 mb-2">{recording.title}</p>
        <p className="text-gray-500 text-sm mb-6">
          This recording is currently in progress. How would you like to watch it?
        </p>

        <div className="space-y-3">
          <button
            onClick={() => onSelect('start')}
            className="w-full p-4 rounded-lg border border-gray-600 bg-gray-700 hover:border-indigo-500 hover:bg-gray-600 transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-500/20 rounded-lg">
                <Rewind className="w-5 h-5 text-indigo-400" />
              </div>
              <div>
                <h4 className="font-medium text-white">Watch from Start</h4>
                <p className="text-sm text-gray-400">Begin playback from the beginning</p>
              </div>
            </div>
          </button>

          <button
            onClick={() => onSelect('live')}
            className="w-full p-4 rounded-lg border border-gray-600 bg-gray-700 hover:border-red-500 hover:bg-gray-600 transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-500/20 rounded-lg">
                <Radio className="w-5 h-5 text-red-400" />
              </div>
              <div>
                <h4 className="font-medium text-white">Watch Live</h4>
                <p className="text-sm text-gray-400">Jump to the current live position</p>
              </div>
            </div>
          </button>
        </div>

        <button
          onClick={onClose}
          className="w-full mt-4 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-gray-300 rounded-lg"
        >
          Cancel
        </button>
      </div>
    </div>
  )
}

function ResumeModal({
  recording,
  onResume,
  onStartOver,
}: {
  recording: Recording
  onResume: () => void
  onStartOver: () => void
}) {
  const formatResumeTime = (ms: number): string => {
    const totalSeconds = Math.floor(ms / 1000)
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60
    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
    }
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/70">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <div className="flex items-center gap-3 mb-4">
          <Play className="w-6 h-6 text-indigo-400" />
          <h2 className="text-lg font-semibold text-white">Resume Playback?</h2>
        </div>

        <p className="text-gray-300 mb-2">{recording.title}</p>
        <p className="text-gray-500 text-sm mb-6">
          You were watching at {formatResumeTime(recording.viewOffset || 0)}. Would you like to continue?
        </p>

        <div className="space-y-3">
          <button
            onClick={onResume}
            className="w-full p-4 rounded-lg border border-indigo-500 bg-indigo-500/20 hover:bg-indigo-500/30 transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-500/30 rounded-lg">
                <Play className="w-5 h-5 text-indigo-400" />
              </div>
              <div>
                <h4 className="font-medium text-white">Resume</h4>
                <p className="text-sm text-gray-400">Continue from {formatResumeTime(recording.viewOffset || 0)}</p>
              </div>
            </div>
          </button>

          <button
            onClick={onStartOver}
            className="w-full p-4 rounded-lg border border-gray-600 bg-gray-700 hover:border-gray-500 hover:bg-gray-600 transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-gray-600 rounded-lg">
                <Rewind className="w-5 h-5 text-gray-400" />
              </div>
              <div>
                <h4 className="font-medium text-white">Start Over</h4>
                <p className="text-sm text-gray-400">Watch from the beginning</p>
              </div>
            </div>
          </button>
        </div>
      </div>
    </div>
  )
}

function DVRPlayerModal({
  recording,
  onClose,
  startLive = false,
}: {
  recording: Recording
  onClose: () => void
  startLive?: boolean
}) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const hlsRef = useRef<Hls | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const [isMuted, setIsMuted] = useState(false)
  const [autoSkipEnabled, setAutoSkipEnabled] = useState(true)
  const [currentCommercial, setCurrentCommercial] = useState<CommercialSegment | null>(null)
  const [skippedCommercials, setSkippedCommercials] = useState<Set<number>>(new Set())
  const [showControls, setShowControls] = useState(true)
  const controlsTimeoutRef = useRef<number | null>(null)
  const [showResumeModal, setShowResumeModal] = useState(false)
  const [pendingSeekTime, setPendingSeekTime] = useState<number | null>(null)
  const progressSaveIntervalRef = useRef<number | null>(null)
  const lastSavedTimeRef = useRef<number>(0)

  const { data: streamUrl, isLoading: loadingStream } = useQuery({
    queryKey: ['recording-stream', recording.id],
    queryFn: () => api.getRecordingStreamUrl(recording.id),
  })

  const { data: commercialsData } = useQuery({
    queryKey: ['recording-commercials', recording.id],
    queryFn: () => api.getRecordingCommercials(recording.id),
  })

  const commercials = commercialsData?.segments || []

  useEffect(() => {
    if (recording.viewOffset && recording.viewOffset > 10000 && !startLive && recording.status === 'completed') {
      setShowResumeModal(true)
    }
  }, [recording.viewOffset, startLive, recording.status])

  useEffect(() => {
    const saveProgress = () => {
      const video = videoRef.current
      if (!video || recording.status !== 'completed') return
      const currentTimeMs = Math.floor(video.currentTime * 1000)
      if (Math.abs(currentTimeMs - lastSavedTimeRef.current) > 5000) {
        lastSavedTimeRef.current = currentTimeMs
        api.updateRecordingProgress(recording.id, currentTimeMs).catch(() => {})
      }
    }
    progressSaveIntervalRef.current = window.setInterval(saveProgress, 15000)
    return () => {
      const video = videoRef.current
      if (video && recording.status === 'completed') {
        const currentTimeMs = Math.floor(video.currentTime * 1000)
        api.updateRecordingProgress(recording.id, currentTimeMs).catch(() => {})
      }
      if (progressSaveIntervalRef.current) clearInterval(progressSaveIntervalRef.current)
    }
  }, [recording.id, recording.status])

  useEffect(() => {
    const video = videoRef.current
    if (video && pendingSeekTime !== null && duration > 0) {
      video.currentTime = pendingSeekTime
      setPendingSeekTime(null)
    }
  }, [pendingSeekTime, duration])

  useEffect(() => {
    const video = videoRef.current
    if (!video || !streamUrl) return
    const token = localStorage.getItem('token')
    if (streamUrl.includes('.m3u8')) {
      if (Hls.isSupported()) {
        const hls = new Hls({
          enableWorker: true,
          lowLatencyMode: false,
          xhrSetup: (xhr) => {
            if (token) xhr.setRequestHeader('Authorization', `Bearer ${token}`)
          },
        })
        hlsRef.current = hls
        hls.loadSource(streamUrl)
        hls.attachMedia(video)
        hls.on(Hls.Events.MANIFEST_PARSED, () => { video.play().catch(() => {}) })
        hls.on(Hls.Events.ERROR, (_, data) => {
          if (data.fatal) {
            if (data.type === Hls.ErrorTypes.NETWORK_ERROR) hls.startLoad()
            else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) hls.recoverMediaError()
          }
        })
      } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = streamUrl
        video.play().catch(() => {})
      }
    } else {
      video.src = streamUrl
      video.play().catch(() => {})
    }
    return () => {
      if (hlsRef.current) { hlsRef.current.destroy(); hlsRef.current = null }
    }
  }, [streamUrl])

  const getCurrentCommercial = useCallback((time: number): CommercialSegment | null => {
    return commercials.find(c => time >= c.startTime && time < c.endTime) || null
  }, [commercials])

  useEffect(() => {
    const video = videoRef.current
    if (!video) return
    const handleTimeUpdate = () => {
      const time = video.currentTime
      setCurrentTime(time)
      const commercial = getCurrentCommercial(time)
      setCurrentCommercial(commercial)
      if (commercial && autoSkipEnabled && !skippedCommercials.has(commercial.id)) {
        setSkippedCommercials(prev => new Set(prev).add(commercial.id))
        video.currentTime = commercial.endTime
      }
    }
    const handleDurationChange = () => setDuration(video.duration)
    const handlePlay = () => setIsPlaying(true)
    const handlePause = () => setIsPlaying(false)
    video.addEventListener('timeupdate', handleTimeUpdate)
    video.addEventListener('durationchange', handleDurationChange)
    video.addEventListener('play', handlePlay)
    video.addEventListener('pause', handlePause)
    return () => {
      video.removeEventListener('timeupdate', handleTimeUpdate)
      video.removeEventListener('durationchange', handleDurationChange)
      video.removeEventListener('play', handlePlay)
      video.removeEventListener('pause', handlePause)
    }
  }, [autoSkipEnabled, skippedCommercials, getCurrentCommercial])

  useEffect(() => {
    if (showControls && isPlaying) {
      if (controlsTimeoutRef.current) clearTimeout(controlsTimeoutRef.current)
      controlsTimeoutRef.current = window.setTimeout(() => setShowControls(false), 3000)
    }
    return () => { if (controlsTimeoutRef.current) clearTimeout(controlsTimeoutRef.current) }
  }, [showControls, isPlaying])

  useEffect(() => {
    if (startLive && duration > 0 && videoRef.current) {
      videoRef.current.currentTime = Math.max(0, duration - 10)
    }
  }, [startLive, duration])

  const isLiveRecording = recording.status === 'recording'
  const jumpToLive = () => { if (videoRef.current && duration > 0) videoRef.current.currentTime = Math.max(0, duration - 5) }
  const handleMouseMove = () => setShowControls(true)
  const togglePlayPause = () => {
    const video = videoRef.current
    if (!video) return
    if (isPlaying) video.pause()
    else video.play()
  }
  const skipCommercial = () => {
    if (currentCommercial && videoRef.current) {
      setSkippedCommercials(prev => new Set(prev).add(currentCommercial.id))
      videoRef.current.currentTime = currentCommercial.endTime
    }
  }
  const seek = (time: number) => {
    if (videoRef.current) { videoRef.current.currentTime = time; setSkippedCommercials(new Set()) }
  }
  const formatTime = (seconds: number): string => {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = Math.floor(seconds % 60)
    if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
    return `${m}:${s.toString().padStart(2, '0')}`
  }
  const toggleFullscreen = () => {
    const container = document.getElementById('dvr-player-container')
    if (container) {
      if (document.fullscreenElement) document.exitFullscreen()
      else container.requestFullscreen()
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-black">
      <div id="dvr-player-container" className="relative w-full h-full" onMouseMove={handleMouseMove} onClick={handleMouseMove}>
        {loadingStream ? (
          <div className="flex items-center justify-center h-full"><Loader className="w-12 h-12 text-white animate-spin" /></div>
        ) : streamUrl ? (
          <video ref={videoRef} className="w-full h-full object-contain" muted={isMuted} />
        ) : (
          <div className="flex items-center justify-center h-full"><p className="text-red-400">Failed to load video</p></div>
        )}
        {currentCommercial && !autoSkipEnabled && (
          <button onClick={skipCommercial} className="absolute bottom-32 right-8 px-6 py-3 bg-yellow-500 hover:bg-yellow-400 text-black font-semibold rounded-lg flex items-center gap-2 transition-colors">
            <SkipForward className="w-5 h-5" />
            <div><div>Skip Ad</div><div className="text-xs opacity-75">{Math.ceil(currentCommercial.endTime - currentTime)}s remaining</div></div>
          </button>
        )}
        {currentCommercial && autoSkipEnabled && (
          <div className="absolute bottom-32 right-8 px-4 py-2 bg-indigo-600 text-white rounded-lg">Skipping commercial...</div>
        )}
        <div className={`absolute inset-0 transition-opacity duration-300 ${showControls ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
          <div className="absolute top-0 left-0 right-0 p-4 bg-gradient-to-b from-black/80 to-transparent">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <button onClick={onClose} className="p-2 text-white hover:bg-white/20 rounded-lg transition-colors"><X className="w-6 h-6" /></button>
                <div>
                  <div className="flex items-center gap-3">
                    <h2 className="text-xl font-semibold text-white">{recording.title}</h2>
                    {isLiveRecording && <span className="flex items-center gap-1 px-2 py-0.5 bg-red-500 text-white text-xs font-bold rounded animate-pulse"><CircleDot className="w-3 h-3" />LIVE</span>}
                  </div>
                  {recording.episodeNum && <p className="text-sm text-gray-300">{recording.episodeNum}</p>}
                </div>
              </div>
              {commercials.length > 0 && (
                <div className="flex items-center gap-4">
                  <span className="text-sm text-yellow-400">{commercials.length} commercial break{commercials.length > 1 ? 's' : ''} detected</span>
                  <button onClick={() => setAutoSkipEnabled(!autoSkipEnabled)} className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${autoSkipEnabled ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30' : 'bg-gray-500/20 text-gray-400 hover:bg-gray-500/30'}`}>
                    {autoSkipEnabled ? <ToggleRight className="w-4 h-4" /> : <ToggleLeft className="w-4 h-4" />}Auto-Skip {autoSkipEnabled ? 'ON' : 'OFF'}
                  </button>
                </div>
              )}
            </div>
          </div>
          <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/80 to-transparent">
            <div className="relative mb-4">
              <div className="relative h-2 bg-white/30 rounded-full cursor-pointer group" onClick={(e) => { const rect = e.currentTarget.getBoundingClientRect(); seek((e.clientX - rect.left) / rect.width * duration) }}>
                {commercials.map((commercial) => {
                  const startPercent = (commercial.startTime / duration) * 100
                  const widthPercent = ((commercial.endTime - commercial.startTime) / duration) * 100
                  return <div key={commercial.id} className="absolute top-0 h-full bg-yellow-500/80" style={{ left: `${startPercent}%`, width: `${Math.max(widthPercent, 0.5)}%` }} />
                })}
                <div className="absolute top-0 left-0 h-full bg-indigo-500 rounded-full" style={{ width: `${(currentTime / duration) * 100}%` }} />
                <div className="absolute top-1/2 -translate-y-1/2 w-4 h-4 bg-white rounded-full shadow-lg opacity-0 group-hover:opacity-100 transition-opacity" style={{ left: `calc(${(currentTime / duration) * 100}% - 8px)` }} />
              </div>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <button onClick={togglePlayPause} className="p-3 bg-white/20 hover:bg-white/30 rounded-full transition-colors">
                  {isPlaying ? <Pause className="w-6 h-6 text-white" /> : <Play className="w-6 h-6 text-white" />}
                </button>
                <button onClick={() => setIsMuted(!isMuted)} className="p-2 text-white hover:bg-white/20 rounded-lg transition-colors">
                  {isMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
                </button>
                <span className="text-sm text-white">{formatTime(currentTime)} / {formatTime(duration)}</span>
                {isLiveRecording && (
                  <button onClick={jumpToLive} className="flex items-center gap-1.5 px-3 py-1.5 bg-red-500/20 hover:bg-red-500/30 text-red-400 rounded-lg text-sm font-medium transition-colors"><Radio className="w-4 h-4" />LIVE</button>
                )}
              </div>
              <button onClick={toggleFullscreen} className="p-2 text-white hover:bg-white/20 rounded-lg transition-colors"><Maximize className="w-5 h-5" /></button>
            </div>
          </div>
        </div>
      </div>
      {showResumeModal && (
        <ResumeModal
          recording={recording}
          onResume={() => { setShowResumeModal(false); if (recording.viewOffset) setPendingSeekTime(recording.viewOffset / 1000) }}
          onStartOver={() => { setShowResumeModal(false); api.updateRecordingProgress(recording.id, 0).catch(() => {}) }}
        />
      )}
    </div>
  )
}

// ============ Sidebar Category Item ============

type ContentCategory = 'show' | 'movie' | 'video' | 'image' | 'unmatched'

const categoryConfig: Record<ContentCategory, { label: string; icon: typeof Tv }> = {
  show: { label: 'Shows', icon: Tv },
  movie: { label: 'Movies', icon: Film },
  video: { label: 'Videos', icon: Video },
  image: { label: 'Images', icon: Image },
  unmatched: { label: 'Unmatched', icon: FileQuestion },
}

// ============ Recording Card for Manager ============

function RecordingManagerCard({
  recording,
  isSelected,
  onToggleSelect,
  onPlay,
  onToggleWatched,
  onToggleFavorite,
  onToggleKeep,
  onTrash,
  onStop,
  onFixMatch,
}: {
  recording: Recording
  isSelected: boolean
  onToggleSelect: () => void
  onPlay: () => void
  onToggleWatched: () => void
  onToggleFavorite: () => void
  onToggleKeep: () => void
  onTrash: () => void
  onStop?: () => void
  onFixMatch?: () => void
}) {
  const [showOptions, setShowOptions] = useState(false)
  const isWatched = recording.isWatched

  const posterImage = recording.thumb || recording.art || recording.channelLogo
  const resBadge = getResolutionBadge(recording.videoResolution)
  const audioBadge = getAudioBadge(recording.audioCodec)

  // Calculate watch progress percentage
  const watchPercent = useMemo(() => {
    if (!recording.viewOffset || !recording.duration) return 0
    const durationMs = recording.duration * 60000
    return Math.min(100, (recording.viewOffset / durationMs) * 100)
  }, [recording.viewOffset, recording.duration])

  return (
    <div
      className={`relative group border rounded-lg transition-all duration-200 ${
        isSelected
          ? 'border-indigo-500 bg-indigo-500/5'
          : isWatched
            ? 'border-gray-700/50 bg-gray-800/50'
            : 'border-gray-700 bg-gray-800'
      } ${isWatched ? 'opacity-60 hover:opacity-100' : ''}`}
    >
      <div className="flex gap-0">
        {/* Thumbnail */}
        <div className="relative flex-shrink-0 w-44 h-28 sm:w-52 sm:h-32 bg-gray-900 rounded-l-lg overflow-hidden cursor-pointer" onClick={onPlay}>
          {posterImage ? (
            <img
              src={posterImage}
              alt={recording.title}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center">
              <Video className="w-10 h-10 text-gray-700" />
            </div>
          )}
          {/* Play button overlay */}
          <div className="absolute inset-0 flex items-center justify-center bg-black/0 group-hover:bg-black/40 transition-colors">
            <div className="w-10 h-10 flex items-center justify-center rounded-full bg-white/90 opacity-0 group-hover:opacity-100 transition-opacity shadow-lg">
              <Play className="w-5 h-5 text-gray-900 ml-0.5" />
            </div>
          </div>
          {/* Watch progress bar */}
          {watchPercent > 0 && watchPercent < 90 && (
            <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/60">
              <div className="h-full bg-indigo-500" style={{ width: `${watchPercent}%` }} />
            </div>
          )}
          {/* Selection checkbox */}
          <button
            onClick={(e) => { e.stopPropagation(); onToggleSelect() }}
            className="absolute top-2 left-2 opacity-0 group-hover:opacity-100 transition-opacity"
          >
            {isSelected ? (
              <CheckSquare className="w-5 h-5 text-indigo-400 drop-shadow-lg" />
            ) : (
              <Square className="w-5 h-5 text-white/80 drop-shadow-lg hover:text-white" />
            )}
          </button>
          {/* Keep forever badge */}
          {recording.keepForever && (
            <div className="absolute top-2 right-2">
              <Lock className="w-4 h-4 text-yellow-400 drop-shadow-lg" />
            </div>
          )}
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0 p-3 flex flex-col justify-between">
          <div>
            {/* Title row */}
            <div className="flex items-start justify-between gap-2">
              <div className="min-w-0">
                <h4 className={`font-semibold truncate ${isWatched ? 'text-gray-400' : 'text-white'}`}>
                  {recording.title}
                </h4>
                {recording.subtitle && (
                  <p className="text-sm text-gray-400 truncate">{recording.subtitle}</p>
                )}
              </div>
              {/* Date and duration on right */}
              <div className="flex-shrink-0 text-right text-xs text-gray-500 hidden sm:block">
                <div>{formatDateFull(recording.createdAt)}</div>
                {recording.duration && <div>{formatDuration(recording.duration)}</div>}
                {recording.channelName && (
                  <div className="text-gray-600">Ch {recording.channelName}</div>
                )}
              </div>
            </div>

            {/* Episode info */}
            {recording.episodeNum && (
              <p className="text-xs text-gray-500 mt-0.5">{recording.episodeNum}</p>
            )}

            {/* Badges row */}
            <div className="flex flex-wrap items-center gap-1.5 mt-1.5">
              {recording.status === 'recording' && (
                <span className="px-1.5 py-0.5 text-[10px] font-bold bg-red-600 text-white rounded animate-pulse flex items-center gap-1">
                  <Radio className="w-3 h-3" /> RECORDING
                </span>
              )}
              {recording.status === 'scheduled' && (
                <span className="px-1.5 py-0.5 text-[10px] font-bold bg-blue-600 text-white rounded">
                  SCHEDULED
                </span>
              )}
              {recording.status === 'failed' && (
                <span className="px-1.5 py-0.5 text-[10px] font-bold bg-orange-600 text-white rounded">
                  FAILED
                </span>
              )}
              {resBadge && (
                <span className="px-1.5 py-0.5 text-[10px] font-bold bg-gray-700 text-gray-300 rounded">
                  {resBadge}
                </span>
              )}
              {audioBadge && (
                <span className="px-1.5 py-0.5 text-[10px] font-medium bg-gray-700 text-gray-300 rounded">
                  {audioBadge}
                </span>
              )}
              {recording.hasCC && (
                <span className="px-1.5 py-0.5 text-[10px] font-medium bg-gray-700 text-gray-300 rounded">
                  CC
                </span>
              )}
              {recording.hasDVS && (
                <span className="px-1.5 py-0.5 text-[10px] font-medium bg-gray-700 text-gray-300 rounded">
                  DVS
                </span>
              )}
              {recording.contentRating && (
                <span className="px-1.5 py-0.5 text-[10px] font-medium border border-gray-600 text-gray-400 rounded">
                  {recording.contentRating}
                </span>
              )}
              {recording.isFavorite && (
                <Star className="w-3.5 h-3.5 text-yellow-400 fill-yellow-400" />
              )}
              {recording.isWatched && (
                <span className="px-1.5 py-0.5 text-[10px] font-medium bg-green-500/20 text-green-400 rounded flex items-center gap-0.5">
                  <CheckCircle className="w-3 h-3" /> Watched
                </span>
              )}
            </div>

            {/* Description */}
            {(recording.summary || recording.description) && (
              <p className="text-xs text-gray-500 line-clamp-2 mt-1.5 leading-relaxed hidden md:block">
                {recording.summary || recording.description}
              </p>
            )}
          </div>

          {/* Action buttons row */}
          <div className="flex items-center gap-1 mt-2 -mb-1">
            {onFixMatch && (
              <button
                onClick={onFixMatch}
                className="flex items-center gap-1 px-2 py-1 text-xs font-medium bg-yellow-500/10 text-yellow-400 hover:bg-yellow-500/20 rounded-md transition-colors"
                title="Fix metadata match"
              >
                <Search className="w-3.5 h-3.5" />
                Fix Match
              </button>
            )}
            <button
              onClick={onToggleWatched}
              className={`p-1.5 rounded-md transition-colors ${
                recording.isWatched
                  ? 'text-green-400 hover:bg-green-500/10'
                  : 'text-gray-500 hover:text-gray-300 hover:bg-gray-700'
              }`}
              title={recording.isWatched ? 'Mark as Unwatched' : 'Mark as Watched'}
            >
              {recording.isWatched ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
            </button>
            <button
              onClick={onToggleFavorite}
              className={`p-1.5 rounded-md transition-colors ${
                recording.isFavorite
                  ? 'text-yellow-400 hover:bg-yellow-500/10'
                  : 'text-gray-500 hover:text-gray-300 hover:bg-gray-700'
              }`}
              title={recording.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'}
            >
              <Star className={`w-4 h-4 ${recording.isFavorite ? 'fill-yellow-400' : ''}`} />
            </button>
            <button
              onClick={onToggleKeep}
              className={`p-1.5 rounded-md transition-colors ${
                recording.keepForever
                  ? 'text-blue-400 hover:bg-blue-500/10'
                  : 'text-gray-500 hover:text-gray-300 hover:bg-gray-700'
              }`}
              title={recording.keepForever ? 'Remove Keep Forever' : 'Keep Forever'}
            >
              <Lock className="w-4 h-4" />
            </button>
            {recording.status === 'recording' && onStop && (
              <button
                onClick={onStop}
                className="p-1.5 text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-md transition-colors"
                title="Stop Recording"
              >
                <StopCircle className="w-4 h-4" />
              </button>
            )}
            <button
              onClick={onTrash}
              className="p-1.5 text-gray-500 hover:text-red-400 hover:bg-red-500/10 rounded-md transition-colors"
              title="Move to Trash"
            >
              <Trash2 className="w-4 h-4" />
            </button>
            {/* Options dropdown */}
            <div className="relative ml-auto">
              <button
                onClick={() => setShowOptions(!showOptions)}
                className="p-1.5 text-gray-500 hover:text-gray-300 hover:bg-gray-700 rounded-md transition-colors"
              >
                <MoreHorizontal className="w-4 h-4" />
              </button>
              {showOptions && (
                <>
                  <div className="fixed inset-0 z-10" onClick={() => setShowOptions(false)} />
                  <div className="absolute right-0 bottom-full mb-1 w-48 bg-gray-700 rounded-lg shadow-xl border border-gray-600 py-1 z-20">
                    <button
                      onClick={() => { onPlay(); setShowOptions(false) }}
                      className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                    >
                      <Play className="w-4 h-4" /> Play
                    </button>
                    <button
                      onClick={() => { onToggleWatched(); setShowOptions(false) }}
                      className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                    >
                      {recording.isWatched ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      {recording.isWatched ? 'Mark Unwatched' : 'Mark Watched'}
                    </button>
                    <button
                      onClick={() => { onToggleFavorite(); setShowOptions(false) }}
                      className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                    >
                      <Star className="w-4 h-4" />
                      {recording.isFavorite ? 'Remove Favorite' : 'Add Favorite'}
                    </button>
                    <button
                      onClick={() => { onToggleKeep(); setShowOptions(false) }}
                      className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                    >
                      <Lock className="w-4 h-4" />
                      {recording.keepForever ? 'Remove Keep Forever' : 'Keep Forever'}
                    </button>
                    <div className="border-t border-gray-600 my-1" />
                    <button
                      onClick={() => {
                        const url = api.getRecordingEDLUrl(recording.id)
                        window.open(url, '_blank')
                        setShowOptions(false)
                      }}
                      className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                      title="Download EDL file for use with Kodi, MPC-HC, and other players"
                    >
                      <Download className="w-4 h-4" /> Export EDL
                    </button>
                    <button
                      onClick={() => {
                        const url = api.getRecordingEDLUrl(recording.id, 'mplayer')
                        window.open(url, '_blank')
                        setShowOptions(false)
                      }}
                      className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                      title="Download MPlayer-format EDL file"
                    >
                      <Download className="w-4 h-4" /> Export EDL (MPlayer)
                    </button>
                    <div className="border-t border-gray-600 my-1" />
                    <button
                      onClick={() => { onTrash(); setShowOptions(false) }}
                      className="w-full px-3 py-2 text-left text-sm text-red-400 hover:bg-gray-600 flex items-center gap-2"
                    >
                      <Trash2 className="w-4 h-4" /> Move to Trash
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// ============ Dropdown Component ============

function Dropdown({
  value,
  options,
  onChange,
}: {
  label?: string
  value: string
  options: { value: string; label: string }[]
  onChange: (v: string) => void
}) {
  return (
    <div className="relative">
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="appearance-none bg-gray-700 border border-gray-600 text-gray-200 text-sm rounded-lg pl-3 pr-8 py-2 cursor-pointer hover:border-gray-500 focus:outline-none focus:border-indigo-500"
      >
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
      <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
    </div>
  )
}

// ============ Main DVR Page ============

export function DVRPage() {
  const queryClient = useQueryClient()

  // State
  const [activeCategory, setActiveCategory] = useState<ContentCategory>('show')
  const [searchQuery, setSearchQuery] = useState('')
  const [sortBy, setSortBy] = useState('date_added')
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('desc')
  const [filterShow, setFilterShow] = useState('')
  const [filterRating, setFilterRating] = useState('')
  const [filterWatched, setFilterWatched] = useState('')
  const [selectedRecordings, setSelectedRecordings] = useState<Set<number>>(new Set())
  const [playbackRecording, setPlaybackRecording] = useState<Recording | null>(null)
  const [playbackStartLive, setPlaybackStartLive] = useState(false)
  const [watchOptionsRecording, setWatchOptionsRecording] = useState<Recording | null>(null)
  const [showActionsDropdown, setShowActionsDropdown] = useState(false)
  const [fixMatchRecording, setFixMatchRecording] = useState<Recording | null>(null)
  const [fixMatchSearch, setFixMatchSearch] = useState('')

  // Query
  const { data: managerData, isLoading } = useQuery({
    queryKey: ['recordings-manager', activeCategory, sortBy, sortDir, searchQuery, filterShow, filterRating, filterWatched],
    queryFn: () =>
      api.getRecordingsManager({
        contentType: activeCategory,
        sortBy,
        sortDir,
        search: searchQuery || undefined,
        showTitle: filterShow || undefined,
        contentRating: filterRating || undefined,
        watched: filterWatched || undefined,
      }),
    staleTime: 15000,
  })

  const recordings = managerData?.recordings || []
  const showTitles = managerData?.showTitles || []
  const contentRatings = managerData?.contentRatings || []

  // Mutations
  const toggleWatched = useMutation({
    mutationFn: (id: number) => api.toggleRecordingWatched(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['recordings-manager'] }),
  })

  const toggleFavorite = useMutation({
    mutationFn: (id: number) => api.toggleRecordingFavorite(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['recordings-manager'] }),
  })

  const toggleKeep = useMutation({
    mutationFn: (id: number) => api.toggleRecordingKeep(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['recordings-manager'] }),
  })

  const trashRecording = useMutation({
    mutationFn: (id: number) => api.trashRecording(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recordings-manager'] })
      queryClient.invalidateQueries({ queryKey: ['recordings'] })
    },
  })

  const stopRecording = useMutation({
    mutationFn: (id: number) => api.stopRecording(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recordings-manager'] })
      queryClient.invalidateQueries({ queryKey: ['recordings'] })
    },
  })

  const bulkAction = useMutation({
    mutationFn: ({ ids, action }: { ids: number[]; action: string }) =>
      api.bulkRecordingAction(ids, action),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recordings-manager'] })
      queryClient.invalidateQueries({ queryKey: ['recordings'] })
      setSelectedRecordings(new Set())
    },
  })

  // TMDB search for Fix Match modal
  const { data: fixMatchResults, isLoading: isSearchingFixMatch } = useQuery({
    queryKey: ['tmdb-fix-match', fixMatchRecording?.id, fixMatchSearch],
    queryFn: () => api.searchTMDB(fixMatchSearch, fixMatchRecording?.isMovie ? 'movie' : 'tv'),
    enabled: !!fixMatchRecording && fixMatchSearch.length > 2,
  })

  // Apply recording match mutation
  const applyRecordingMatchMutation = useMutation({
    mutationFn: (params: { id: number; result: TMDBSearchResult }) =>
      api.applyRecordingMatch(
        params.id,
        params.result.id,
        params.result.media_type,
        params.result.title,
        params.result.poster_path,
        params.result.backdrop_path,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recordings-manager'] })
      setFixMatchRecording(null)
      setFixMatchSearch('')
    },
  })

  // Selection helpers
  const allSelected = recordings.length > 0 && selectedRecordings.size === recordings.length
  const someSelected = selectedRecordings.size > 0

  const toggleSelectAll = () => {
    if (allSelected) {
      setSelectedRecordings(new Set())
    } else {
      setSelectedRecordings(new Set(recordings.map((r) => r.id)))
    }
  }

  const toggleRecordingSelection = (id: number) => {
    setSelectedRecordings((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const handleBulkAction = (action: string) => {
    const ids = Array.from(selectedRecordings)
    if (ids.length === 0) return
    if (action === 'delete') {
      if (!confirm(`Move ${ids.length} recording${ids.length > 1 ? 's' : ''} to trash?`)) return
    }
    bulkAction.mutate({ ids, action })
    setShowActionsDropdown(false)
  }

  const handlePlay = (rec: Recording) => {
    if (rec.status === 'recording') {
      setWatchOptionsRecording(rec)
    } else {
      setPlaybackStartLive(false)
      setPlaybackRecording(rec)
    }
  }

  // Count recordings per category (simple counts from current data)
  const { data: showCount } = useQuery({
    queryKey: ['rec-count-show'],
    queryFn: () => api.getRecordingsManager({ contentType: 'show' }),
    select: (d) => d.totalCount,
    staleTime: 30000,
  })
  const { data: movieCount } = useQuery({
    queryKey: ['rec-count-movie'],
    queryFn: () => api.getRecordingsManager({ contentType: 'movie' }),
    select: (d) => d.totalCount,
    staleTime: 30000,
  })
  const { data: videoCount } = useQuery({
    queryKey: ['rec-count-video'],
    queryFn: () => api.getRecordingsManager({ contentType: 'video' }),
    select: (d) => d.totalCount,
    staleTime: 30000,
  })
  const { data: imageCount } = useQuery({
    queryKey: ['rec-count-image'],
    queryFn: () => api.getRecordingsManager({ contentType: 'image' }),
    select: (d) => d.totalCount,
    staleTime: 30000,
  })
  const { data: unmatchedCount } = useQuery({
    queryKey: ['rec-count-unmatched'],
    queryFn: () => api.getRecordingsManager({ contentType: 'unmatched' }),
    select: (d) => d.totalCount,
    staleTime: 30000,
  })

  const categoryCounts: Record<ContentCategory, number | undefined> = {
    show: showCount,
    movie: movieCount,
    video: videoCount,
    image: imageCount,
    unmatched: unmatchedCount,
  }

  return (
    <div className="flex gap-0 -m-6 min-h-[calc(100vh-4rem)]">
      {/* ============ Left Sidebar ============ */}
      <div className="w-56 flex-shrink-0 bg-gray-900/50 border-r border-gray-700/50 p-4">
        <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 px-2">
          Manage
        </h2>
        <nav className="space-y-0.5">
          {(Object.keys(categoryConfig) as ContentCategory[]).map((cat) => {
            const cfg = categoryConfig[cat]
            const Icon = cfg.icon
            const isActive = activeCategory === cat
            const count = categoryCounts[cat]
            return (
              <button
                key={cat}
                onClick={() => {
                  setActiveCategory(cat)
                  setSelectedRecordings(new Set())
                  setFilterShow('')
                  setFilterRating('')
                }}
                className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm transition-colors ${
                  isActive
                    ? 'bg-indigo-600 text-white'
                    : 'text-gray-400 hover:text-white hover:bg-gray-800'
                }`}
              >
                <div className="flex items-center gap-2.5">
                  <Icon className="w-4 h-4" />
                  <span>{cfg.label}</span>
                </div>
                {count !== undefined && count > 0 && (
                  <span className={`text-xs ${isActive ? 'text-indigo-200' : 'text-gray-600'}`}>
                    {count}
                  </span>
                )}
              </button>
            )
          })}
        </nav>
      </div>

      {/* ============ Main Content ============ */}
      <div className="flex-1 min-w-0">
        {/* Top Toolbar */}
        <div className="sticky top-0 z-10 bg-gray-900/95 backdrop-blur-sm border-b border-gray-700/50 px-4 py-3">
          <div className="flex flex-wrap items-center gap-3">
            {/* Select All */}
            <button
              onClick={toggleSelectAll}
              className="flex items-center gap-2 text-sm text-gray-400 hover:text-white transition-colors"
              title="Select All"
            >
              {allSelected ? (
                <CheckSquare className="w-4 h-4 text-indigo-400" />
              ) : someSelected ? (
                <div className="w-4 h-4 border-2 border-indigo-400 rounded bg-indigo-400/30" />
              ) : (
                <Square className="w-4 h-4" />
              )}
            </button>

            {/* Actions dropdown (only when items selected) */}
            {someSelected && (
              <div className="relative">
                <button
                  onClick={() => setShowActionsDropdown(!showActionsDropdown)}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-gray-200 text-sm rounded-lg transition-colors"
                >
                  Actions ({selectedRecordings.size})
                  <ChevronDown className="w-3.5 h-3.5" />
                </button>
                {showActionsDropdown && (
                  <>
                    <div className="fixed inset-0 z-10" onClick={() => setShowActionsDropdown(false)} />
                    <div className="absolute left-0 top-full mt-1 w-48 bg-gray-700 rounded-lg shadow-xl border border-gray-600 py-1 z-20">
                      <button
                        onClick={() => handleBulkAction('watched')}
                        className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                      >
                        <Eye className="w-4 h-4" /> Mark Watched
                      </button>
                      <button
                        onClick={() => handleBulkAction('unwatched')}
                        className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                      >
                        <EyeOff className="w-4 h-4" /> Mark Unwatched
                      </button>
                      <button
                        onClick={() => handleBulkAction('keep_forever')}
                        className="w-full px-3 py-2 text-left text-sm text-gray-200 hover:bg-gray-600 flex items-center gap-2"
                      >
                        <Lock className="w-4 h-4" /> Keep Forever
                      </button>
                      <div className="border-t border-gray-600 my-1" />
                      <button
                        onClick={() => handleBulkAction('delete')}
                        className="w-full px-3 py-2 text-left text-sm text-red-400 hover:bg-gray-600 flex items-center gap-2"
                      >
                        <Trash2 className="w-4 h-4" /> Delete
                      </button>
                    </div>
                  </>
                )}
              </div>
            )}

            {/* Separator */}
            {someSelected && <div className="w-px h-6 bg-gray-700" />}

            {/* Filter dropdowns */}
            {activeCategory === 'show' && showTitles.length > 0 && (
              <Dropdown
                label="Shows"
                value={filterShow}
                options={[
                  { value: '', label: 'All Shows' },
                  ...showTitles.map((t) => ({ value: t, label: t })),
                ]}
                onChange={setFilterShow}
              />
            )}

            {contentRatings.length > 0 && (
              <Dropdown
                label="Content Rating"
                value={filterRating}
                options={[
                  { value: '', label: 'All Ratings' },
                  ...contentRatings.map((r) => ({ value: r, label: r })),
                ]}
                onChange={setFilterRating}
              />
            )}

            <Dropdown
              label="Filter"
              value={filterWatched}
              options={[
                { value: '', label: 'All' },
                { value: 'false', label: 'Unwatched' },
                { value: 'true', label: 'Watched' },
              ]}
              onChange={setFilterWatched}
            />

            {/* Spacer */}
            <div className="flex-1" />

            {/* Search */}
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
              <input
                type="text"
                placeholder="Search..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-48 pl-8 pr-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-sm text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
            </div>

            {/* Sort */}
            <Dropdown
              label="Sort"
              value={sortBy}
              options={[
                { value: 'date_added', label: 'Date Added' },
                { value: 'name', label: 'Name' },
                { value: 'duration', label: 'Duration' },
                { value: 'size', label: 'Size' },
              ]}
              onChange={setSortBy}
            />

            <button
              onClick={() => setSortDir(sortDir === 'asc' ? 'desc' : 'asc')}
              className="p-2 bg-gray-700 border border-gray-600 rounded-lg text-gray-400 hover:text-white hover:border-gray-500 transition-colors"
              title={sortDir === 'asc' ? 'Ascending' : 'Descending'}
            >
              {sortDir === 'asc' ? (
                <ArrowUp className="w-4 h-4" />
              ) : (
                <ArrowDown className="w-4 h-4" />
              )}
            </button>
          </div>
        </div>

        {/* Recording count header */}
        <div className="px-4 py-2 flex items-center justify-between text-sm border-b border-gray-800">
          <span className="text-gray-500">
            {isLoading
              ? 'Loading...'
              : `${recordings.length} recording${recordings.length !== 1 ? 's' : ''}`}
          </span>
          {someSelected && !allSelected && (
            <button
              onClick={() => setSelectedRecordings(new Set())}
              className="text-xs text-indigo-400 hover:text-indigo-300"
            >
              Clear selection
            </button>
          )}
        </div>

        {/* Recordings List */}
        <div className="p-4">
          {isLoading ? (
            <div className="flex items-center justify-center py-24">
              <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
            </div>
          ) : recordings.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-24 text-center">
              {(() => {
                const cfg = categoryConfig[activeCategory]
                const Icon = cfg.icon
                return (
                  <>
                    <Icon className="w-16 h-16 text-gray-700 mb-4" />
                    <h3 className="text-lg font-medium text-gray-300 mb-2">
                      No {cfg.label.toLowerCase()} found
                    </h3>
                    <p className="text-gray-500 max-w-md">
                      {searchQuery
                        ? `No recordings match "${searchQuery}"`
                        : `Completed recordings will appear here once you schedule and record ${cfg.label.toLowerCase()}.`}
                    </p>
                    {searchQuery && (
                      <button
                        onClick={() => setSearchQuery('')}
                        className="mt-4 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
                      >
                        Clear search
                      </button>
                    )}
                  </>
                )
              })()}
            </div>
          ) : (
            <div className="space-y-2">
              {recordings.map((rec) => (
                <RecordingManagerCard
                  key={rec.id}
                  recording={rec}
                  isSelected={selectedRecordings.has(rec.id)}
                  onToggleSelect={() => toggleRecordingSelection(rec.id)}
                  onPlay={() => handlePlay(rec)}
                  onToggleWatched={() => toggleWatched.mutate(rec.id)}
                  onToggleFavorite={() => toggleFavorite.mutate(rec.id)}
                  onToggleKeep={() => toggleKeep.mutate(rec.id)}
                  onTrash={() => {
                    if (confirm(`Move "${rec.title}" to trash?`)) {
                      trashRecording.mutate(rec.id)
                    }
                  }}
                  onStop={rec.status === 'recording' ? () => {
                    if (confirm(`Stop recording "${rec.title}"?`)) {
                      stopRecording.mutate(rec.id)
                    }
                  } : undefined}
                  onFixMatch={activeCategory === 'unmatched' ? () => {
                    setFixMatchRecording(rec)
                    setFixMatchSearch(rec.title)
                  } : undefined}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ============ Player Modals ============ */}
      {watchOptionsRecording && (
        <WatchOptionsModal
          recording={watchOptionsRecording}
          onClose={() => setWatchOptionsRecording(null)}
          onSelect={(mode) => {
            setPlaybackStartLive(mode === 'live')
            setPlaybackRecording(watchOptionsRecording)
            setWatchOptionsRecording(null)
          }}
        />
      )}

      {playbackRecording && (
        <DVRPlayerModal
          recording={playbackRecording}
          onClose={() => {
            setPlaybackRecording(null)
            setPlaybackStartLive(false)
          }}
          startLive={playbackStartLive}
        />
      )}

      {/* ============ Fix Match Modal ============ */}
      {fixMatchRecording && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-gray-800 rounded-lg p-6 w-full max-w-2xl max-h-[80vh] overflow-hidden flex flex-col">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-white">Fix Match: {fixMatchRecording.title}</h2>
              <button
                onClick={() => {
                  setFixMatchRecording(null)
                  setFixMatchSearch('')
                }}
                className="text-gray-400 hover:text-white"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mb-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search TMDB..."
                  value={fixMatchSearch}
                  onChange={(e) => setFixMatchSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                />
              </div>
            </div>

            <div className="flex-1 overflow-y-auto">
              {isSearchingFixMatch ? (
                <div className="p-8 text-center text-gray-400">Searching...</div>
              ) : !fixMatchResults?.length ? (
                <div className="p-8 text-center text-gray-400">
                  {fixMatchSearch.length > 2 ? 'No results found' : 'Type to search'}
                </div>
              ) : (
                <div className="space-y-2">
                  {fixMatchResults.map((result: TMDBSearchResult) => (
                    <div
                      key={result.id}
                      className="flex items-center gap-4 p-3 bg-gray-700 rounded hover:bg-gray-600 cursor-pointer"
                      onClick={() => applyRecordingMatchMutation.mutate({
                        id: fixMatchRecording.id,
                        result,
                      })}
                    >
                      <div className="w-12 h-18 bg-gray-600 rounded overflow-hidden flex-shrink-0">
                        {result.poster_path ? (
                          <img
                            src={`https://image.tmdb.org/t/p/w92${result.poster_path}`}
                            alt={result.title}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center">
                            <Film className="h-4 w-4 text-gray-400" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <h4 className="text-white font-medium truncate">{result.title}</h4>
                          <span className="text-gray-400 text-sm">
                            ({(result.release_date || result.first_air_date || '').substring(0, 4)})
                          </span>
                        </div>
                        <p className="text-sm text-gray-400 line-clamp-2">{result.overview}</p>
                        <p className="text-xs text-gray-500 mt-1">
                          TMDB ID: {result.id} &bull; {result.media_type === 'movie' ? 'Movie' : 'TV Show'}
                          {result.vote_average ? ` \u2022 Rating: ${result.vote_average.toFixed(1)}` : ''}
                        </p>
                      </div>
                      <Check className="h-5 w-5 text-green-500 flex-shrink-0" />
                    </div>
                  ))}
                </div>
              )}
            </div>

            {applyRecordingMatchMutation.isPending && (
              <div className="mt-4 text-center text-gray-400 flex items-center justify-center gap-2">
                <Loader className="h-4 w-4 animate-spin" />
                Applying match...
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
