import { useState, useRef, useEffect, useCallback, useMemo } from 'react'
import Hls from 'hls.js'
import {
  Video,
  Plus,
  Trash2,
  Clock,
  CheckCircle,
  AlertCircle,
  Loader,
  Play,
  Pause,
  Calendar,
  Tv,
  HardDrive,
  CircleDot,
  Timer,
  AlertTriangle,
  X,
  Activity,
  Zap,
  Heart,
  HeartOff,
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
} from 'lucide-react'
import {
  useRecordings,
  useDeleteRecording,
  useSeriesRules,
  useCreateSeriesRule,
  useDeleteSeriesRule,
  useRecordingConflicts,
  useResolveConflict,
  useRecordingStats,
} from '../hooks/useDVR'
import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'
import type { Recording, ConflictGroup, RecordingStats, CommercialSegment } from '../types'

const statusConfig = {
  scheduled: {
    icon: Clock,
    color: 'text-blue-400',
    bgColor: 'bg-blue-500/10',
    borderColor: 'border-blue-500/30',
    label: 'Scheduled'
  },
  recording: {
    icon: CircleDot,
    color: 'text-red-400 animate-pulse',
    bgColor: 'bg-red-500/10',
    borderColor: 'border-red-500/30',
    label: 'Recording'
  },
  completed: {
    icon: CheckCircle,
    color: 'text-green-400',
    bgColor: 'bg-green-500/10',
    borderColor: 'border-green-500/30',
    label: 'Completed'
  },
  failed: {
    icon: AlertCircle,
    color: 'text-red-400',
    bgColor: 'bg-red-500/10',
    borderColor: 'border-red-500/30',
    label: 'Failed'
  },
}

function formatFileSize(bytes?: number): string {
  if (!bytes) return ''
  const gb = bytes / (1024 * 1024 * 1024)
  if (gb >= 1) return `${gb.toFixed(1)} GB`
  const mb = bytes / (1024 * 1024)
  return `${mb.toFixed(0)} MB`
}

function formatDuration(minutes?: number): string {
  if (!minutes) return ''
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0) {
    return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`
  }
  return `${mins}m`
}

function formatTimeRange(start: string, end: string): string {
  const startDate = new Date(start)
  const endDate = new Date(end)
  const timeOptions: Intl.DateTimeFormatOptions = { hour: 'numeric', minute: '2-digit' }
  return `${startDate.toLocaleTimeString([], timeOptions)} - ${endDate.toLocaleTimeString([], timeOptions)}`
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

function CreateRuleModal({ onClose }: { onClose: () => void }) {
  const createRule = useCreateSeriesRule()
  const [title, setTitle] = useState('')
  const [anyChannel, setAnyChannel] = useState(true)
  const [keepCount, setKeepCount] = useState(5)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    await createRule.mutateAsync({
      title,
      anyChannel,
      anyTime: true,
      keepCount,
      priority: 0,
      prePadding: 2,
      postPadding: 5,
      enabled: true,
    })
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <h2 className="text-lg font-semibold text-white mb-4">Create Series Rule</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Series Title (keyword match)
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="Game of Thrones"
              required
            />
          </div>
          <div className="mb-4">
            <label className="flex items-center gap-2 text-sm text-gray-300">
              <input
                type="checkbox"
                checked={anyChannel}
                onChange={(e) => setAnyChannel(e.target.checked)}
                className="rounded bg-gray-700 border-gray-600"
              />
              Record from any channel
            </label>
          </div>
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Keep last
            </label>
            <select
              value={keepCount}
              onChange={(e) => setKeepCount(Number(e.target.value))}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            >
              <option value={0}>All recordings</option>
              <option value={3}>3 recordings</option>
              <option value={5}>5 recordings</option>
              <option value={10}>10 recordings</option>
              <option value={20}>20 recordings</option>
            </select>
          </div>
          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={createRule.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {createRule.isPending ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function ConflictResolutionModal({
  conflict,
  onClose,
  onResolve,
  isResolving,
}: {
  conflict: ConflictGroup
  onClose: () => void
  onResolve: (keepId: number, cancelId: number) => void
  isResolving: boolean
}) {
  const [selectedKeep, setSelectedKeep] = useState<number | null>(null)

  const handleResolve = () => {
    if (selectedKeep === null) return
    const cancelIds = conflict.recordings
      .filter((r) => r.id !== selectedKeep)
      .map((r) => r.id)
    // Cancel all conflicting recordings (for simplicity, cancel the first one)
    if (cancelIds.length > 0) {
      onResolve(selectedKeep, cancelIds[0])
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-lg">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-amber-400" />
            <h2 className="text-lg font-semibold text-white">Recording Conflict</h2>
          </div>
          <button onClick={onClose} className="p-1 text-gray-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        <p className="text-gray-400 mb-4">
          These recordings overlap in time. Select which one to keep:
        </p>

        <div className="space-y-3 mb-6">
          {conflict.recordings.map((rec) => (
            <button
              key={rec.id}
              onClick={() => setSelectedKeep(rec.id)}
              className={`w-full p-4 rounded-lg border text-left transition-colors ${
                selectedKeep === rec.id
                  ? 'border-indigo-500 bg-indigo-500/10'
                  : 'border-gray-600 bg-gray-700 hover:border-gray-500'
              }`}
            >
              <div className="flex items-start justify-between">
                <div>
                  <h4 className="font-medium text-white">{rec.title}</h4>
                  {rec.channelName && (
                    <p className="text-sm text-gray-400">{rec.channelName}</p>
                  )}
                  <p className="text-sm text-gray-500 mt-1">
                    {formatDate(rec.startTime)} {formatTimeRange(rec.startTime, rec.endTime)}
                  </p>
                </div>
                {selectedKeep === rec.id && (
                  <CheckCircle className="w-5 h-5 text-indigo-400 flex-shrink-0" />
                )}
              </div>
            </button>
          ))}
        </div>

        <div className="flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
          >
            Cancel
          </button>
          <button
            onClick={handleResolve}
            disabled={selectedKeep === null || isResolving}
            className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-lg"
          >
            {isResolving ? 'Resolving...' : 'Keep Selected'}
          </button>
        </div>
      </div>
    </div>
  )
}

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

  // Fetch stream URL
  const { data: streamUrl, isLoading: loadingStream } = useQuery({
    queryKey: ['recording-stream', recording.id],
    queryFn: () => api.getRecordingStreamUrl(recording.id),
  })

  // Fetch commercials
  const { data: commercialsData } = useQuery({
    queryKey: ['recording-commercials', recording.id],
    queryFn: () => api.getRecordingCommercials(recording.id),
  })

  const commercials = commercialsData?.segments || []

  // Show resume modal if there's a saved position (for completed recordings, not live)
  useEffect(() => {
    if (recording.viewOffset && recording.viewOffset > 10000 && !startLive && recording.status === 'completed') {
      // Only show resume modal if we have a meaningful position (more than 10 seconds)
      setShowResumeModal(true)
    }
  }, [recording.viewOffset, startLive, recording.status])

  // Save playback progress periodically (every 15 seconds)
  useEffect(() => {
    const saveProgress = () => {
      const video = videoRef.current
      if (!video || recording.status !== 'completed') return

      const currentTimeMs = Math.floor(video.currentTime * 1000)
      // Only save if position changed significantly (more than 5 seconds difference)
      if (Math.abs(currentTimeMs - lastSavedTimeRef.current) > 5000) {
        lastSavedTimeRef.current = currentTimeMs
        api.updateRecordingProgress(recording.id, currentTimeMs).catch(() => {
          // Silently ignore save errors
        })
      }
    }

    progressSaveIntervalRef.current = window.setInterval(saveProgress, 15000)

    return () => {
      // Save final position on unmount
      const video = videoRef.current
      if (video && recording.status === 'completed') {
        const currentTimeMs = Math.floor(video.currentTime * 1000)
        api.updateRecordingProgress(recording.id, currentTimeMs).catch(() => {})
      }
      if (progressSaveIntervalRef.current) {
        clearInterval(progressSaveIntervalRef.current)
      }
    }
  }, [recording.id, recording.status])

  // Handle pending seek after video is ready
  useEffect(() => {
    const video = videoRef.current
    if (video && pendingSeekTime !== null && duration > 0) {
      video.currentTime = pendingSeekTime
      setPendingSeekTime(null)
    }
  }, [pendingSeekTime, duration])

  // Initialize HLS.js for HLS streams
  useEffect(() => {
    const video = videoRef.current
    if (!video || !streamUrl) return

    // Get auth token from localStorage
    const token = localStorage.getItem('token')

    // Check if this is an HLS stream
    if (streamUrl.includes('.m3u8')) {
      if (Hls.isSupported()) {
        // Use HLS.js for browsers that don't support HLS natively
        const hls = new Hls({
          enableWorker: true,
          lowLatencyMode: false,
          xhrSetup: (xhr) => {
            // Include auth token in all HLS requests
            if (token) {
              xhr.setRequestHeader('Authorization', `Bearer ${token}`)
            }
          },
        })
        hlsRef.current = hls
        hls.loadSource(streamUrl)
        hls.attachMedia(video)
        hls.on(Hls.Events.MANIFEST_PARSED, () => {
          video.play().catch(() => {})
        })
        hls.on(Hls.Events.ERROR, (_, data) => {
          if (data.fatal) {
            console.error('HLS fatal error:', data.type, data.details)
            if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
              hls.startLoad()
            } else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
              hls.recoverMediaError()
            }
          }
        })
      } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        // Safari supports HLS natively - but won't work with auth headers
        // For Safari, we'd need to use cookies instead
        video.src = streamUrl
        video.play().catch(() => {})
      }
    } else {
      // Direct stream (non-HLS)
      video.src = streamUrl
      video.play().catch(() => {})
    }

    return () => {
      if (hlsRef.current) {
        hlsRef.current.destroy()
        hlsRef.current = null
      }
    }
  }, [streamUrl])

  // Check if current time is in a commercial
  const getCurrentCommercial = useCallback((time: number): CommercialSegment | null => {
    return commercials.find(c => time >= c.startTime && time < c.endTime) || null
  }, [commercials])

  // Handle time updates
  useEffect(() => {
    const video = videoRef.current
    if (!video) return

    const handleTimeUpdate = () => {
      const time = video.currentTime
      setCurrentTime(time)

      const commercial = getCurrentCommercial(time)
      setCurrentCommercial(commercial)

      // Auto-skip if enabled
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

  // Auto-hide controls
  useEffect(() => {
    if (showControls && isPlaying) {
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
  }, [showControls, isPlaying])

  // Seek to live (end) when startLive is true
  useEffect(() => {
    if (startLive && duration > 0 && videoRef.current) {
      // Seek to near the end (10 seconds before to allow some buffer)
      const livePosition = Math.max(0, duration - 10)
      videoRef.current.currentTime = livePosition
    }
  }, [startLive, duration])

  const isLiveRecording = recording.status === 'recording'

  const jumpToLive = () => {
    if (videoRef.current && duration > 0) {
      videoRef.current.currentTime = Math.max(0, duration - 5)
    }
  }

  const handleMouseMove = () => {
    setShowControls(true)
  }

  const togglePlayPause = () => {
    const video = videoRef.current
    if (!video) return
    if (isPlaying) {
      video.pause()
    } else {
      video.play()
    }
  }

  const skipCommercial = () => {
    if (currentCommercial && videoRef.current) {
      setSkippedCommercials(prev => new Set(prev).add(currentCommercial.id))
      videoRef.current.currentTime = currentCommercial.endTime
    }
  }

  const seek = (time: number) => {
    if (videoRef.current) {
      videoRef.current.currentTime = time
      setSkippedCommercials(new Set()) // Reset skipped commercials when seeking
    }
  }

  const formatTime = (seconds: number): string => {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = Math.floor(seconds % 60)
    if (h > 0) {
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
    }
    return `${m}:${s.toString().padStart(2, '0')}`
  }

  const toggleFullscreen = () => {
    const container = document.getElementById('dvr-player-container')
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
        id="dvr-player-container"
        className="relative w-full h-full"
        onMouseMove={handleMouseMove}
        onClick={handleMouseMove}
      >
        {/* Video */}
        {loadingStream ? (
          <div className="flex items-center justify-center h-full">
            <Loader className="w-12 h-12 text-white animate-spin" />
          </div>
        ) : streamUrl ? (
          <video
            ref={videoRef}
            className="w-full h-full object-contain"
            muted={isMuted}
          />
        ) : (
          <div className="flex items-center justify-center h-full">
            <p className="text-red-400">Failed to load video</p>
          </div>
        )}

        {/* Skip Commercial Button (when in commercial and auto-skip is off) */}
        {currentCommercial && !autoSkipEnabled && (
          <button
            onClick={skipCommercial}
            className="absolute bottom-32 right-8 px-6 py-3 bg-yellow-500 hover:bg-yellow-400 text-black font-semibold rounded-lg flex items-center gap-2 transition-colors"
          >
            <SkipForward className="w-5 h-5" />
            <div>
              <div>Skip Ad</div>
              <div className="text-xs opacity-75">
                {Math.ceil(currentCommercial.endTime - currentTime)}s remaining
              </div>
            </div>
          </button>
        )}

        {/* Auto-skip indicator */}
        {currentCommercial && autoSkipEnabled && (
          <div className="absolute bottom-32 right-8 px-4 py-2 bg-indigo-600 text-white rounded-lg">
            Skipping commercial...
          </div>
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
                    <h2 className="text-xl font-semibold text-white">{recording.title}</h2>
                    {isLiveRecording && (
                      <span className="flex items-center gap-1 px-2 py-0.5 bg-red-500 text-white text-xs font-bold rounded animate-pulse">
                        <CircleDot className="w-3 h-3" />
                        LIVE
                      </span>
                    )}
                  </div>
                  {recording.episodeNum && (
                    <p className="text-sm text-gray-300">{recording.episodeNum}</p>
                  )}
                </div>
              </div>

              {/* Commercial info */}
              {commercials.length > 0 && (
                <div className="flex items-center gap-4">
                  <span className="text-sm text-yellow-400">
                    {commercials.length} commercial break{commercials.length > 1 ? 's' : ''} detected
                  </span>
                  <button
                    onClick={() => setAutoSkipEnabled(!autoSkipEnabled)}
                    className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                      autoSkipEnabled
                        ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30'
                        : 'bg-gray-500/20 text-gray-400 hover:bg-gray-500/30'
                    }`}
                  >
                    {autoSkipEnabled ? <ToggleRight className="w-4 h-4" /> : <ToggleLeft className="w-4 h-4" />}
                    Auto-Skip {autoSkipEnabled ? 'ON' : 'OFF'}
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Bottom bar */}
          <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/80 to-transparent">
            {/* Progress bar */}
            <div className="relative mb-4">
              <div
                className="relative h-2 bg-white/30 rounded-full cursor-pointer group"
                onClick={(e) => {
                  const rect = e.currentTarget.getBoundingClientRect()
                  const percent = (e.clientX - rect.left) / rect.width
                  seek(percent * duration)
                }}
              >
                {/* Commercial markers */}
                {commercials.map((commercial) => {
                  const startPercent = (commercial.startTime / duration) * 100
                  const widthPercent = ((commercial.endTime - commercial.startTime) / duration) * 100
                  return (
                    <div
                      key={commercial.id}
                      className="absolute top-0 h-full bg-yellow-500/80"
                      style={{
                        left: `${startPercent}%`,
                        width: `${Math.max(widthPercent, 0.5)}%`,
                      }}
                    />
                  )
                })}

                {/* Progress */}
                <div
                  className="absolute top-0 left-0 h-full bg-indigo-500 rounded-full"
                  style={{ width: `${(currentTime / duration) * 100}%` }}
                />

                {/* Scrubber */}
                <div
                  className="absolute top-1/2 -translate-y-1/2 w-4 h-4 bg-white rounded-full shadow-lg opacity-0 group-hover:opacity-100 transition-opacity"
                  style={{ left: `calc(${(currentTime / duration) * 100}% - 8px)` }}
                />
              </div>
            </div>

            {/* Controls row */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <button
                  onClick={togglePlayPause}
                  className="p-3 bg-white/20 hover:bg-white/30 rounded-full transition-colors"
                >
                  {isPlaying ? <Pause className="w-6 h-6 text-white" /> : <Play className="w-6 h-6 text-white" />}
                </button>

                <button
                  onClick={() => setIsMuted(!isMuted)}
                  className="p-2 text-white hover:bg-white/20 rounded-lg transition-colors"
                >
                  {isMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
                </button>

                <span className="text-sm text-white">
                  {formatTime(currentTime)} / {formatTime(duration)}
                </span>

                {/* Jump to Live button for live recordings */}
                {isLiveRecording && (
                  <button
                    onClick={jumpToLive}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-red-500/20 hover:bg-red-500/30 text-red-400 rounded-lg text-sm font-medium transition-colors"
                  >
                    <Radio className="w-4 h-4" />
                    LIVE
                  </button>
                )}
              </div>

              <button
                onClick={toggleFullscreen}
                className="p-2 text-white hover:bg-white/20 rounded-lg transition-colors"
              >
                <Maximize className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Resume Modal */}
      {showResumeModal && (
        <ResumeModal
          recording={recording}
          onResume={() => {
            setShowResumeModal(false)
            // Convert milliseconds to seconds and set pending seek
            if (recording.viewOffset) {
              setPendingSeekTime(recording.viewOffset / 1000)
            }
          }}
          onStartOver={() => {
            setShowResumeModal(false)
            // Reset viewOffset on server
            api.updateRecordingProgress(recording.id, 0).catch(() => {})
          }}
        />
      )}
    </div>
  )
}

function RecordingCard({
  recording,
  onDelete,
  onPlay,
  liveStats,
  isSelected,
  onToggleSelect,
  selectionMode,
}: {
  recording: Recording
  onDelete: () => void
  onPlay?: () => void
  liveStats?: RecordingStats
  isSelected?: boolean
  onToggleSelect?: () => void
  selectionMode?: boolean
}) {
  const config = statusConfig[recording.status]
  const StatusIcon = config.icon
  const isRecording = recording.status === 'recording'

  // Determine best image to use - prefer poster for movies, backdrop for TV
  const posterImage = recording.thumb || recording.art || recording.channelLogo
  const backdropImage = recording.art || recording.thumb

  return (
    <div className={`bg-gray-800 rounded-xl overflow-hidden border ${config.borderColor} hover:border-gray-600 transition-colors`}>
      {/* Live progress bar for active recordings */}
      {isRecording && liveStats && (
        <div className="h-1 bg-gray-700">
          <div
            className={`h-full transition-all duration-1000 ${
              liveStats.isFailed ? 'bg-red-600' : 'bg-green-500'
            }`}
            style={{ width: `${liveStats.isFailed ? 100 : liveStats.progressPercent}%` }}
          />
        </div>
      )}

      <div className="p-4">
        <div className="flex items-start gap-4">
          {/* Selection Checkbox */}
          {selectionMode && onToggleSelect && (
            <button
              onClick={(e) => {
                e.stopPropagation()
                onToggleSelect()
              }}
              className="flex-shrink-0 p-1 -ml-1 mt-1"
            >
              {isSelected ? (
                <CheckSquare className="w-5 h-5 text-indigo-400" />
              ) : (
                <Square className="w-5 h-5 text-gray-500 hover:text-gray-300" />
              )}
            </button>
          )}

          {/* Poster/Thumbnail Image */}
          <div className={`flex-shrink-0 relative ${recording.isMovie ? 'w-24 h-36' : 'w-40 h-24'} rounded-lg overflow-hidden bg-gray-700`}>
            {posterImage ? (
              <img
                src={recording.isMovie ? posterImage : (backdropImage || posterImage)}
                alt={recording.title}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center">
                <Video className="w-8 h-8 text-gray-600" />
              </div>
            )}
            {/* Channel logo overlay for TV shows */}
            {recording.channelLogo && !recording.isMovie && (
              <div className="absolute bottom-1 right-1 w-8 h-8 bg-black/70 rounded p-1">
                <img
                  src={recording.channelLogo}
                  alt={recording.channelName || ''}
                  className="w-full h-full object-contain"
                />
              </div>
            )}
            {/* Status overlay */}
            <div className={`absolute top-1 left-1 p-1.5 rounded ${config.bgColor}`}>
              <StatusIcon className={`w-3.5 h-3.5 ${config.color}`} />
            </div>
            {/* Watch progress bar for completed recordings */}
            {recording.status === 'completed' && recording.viewOffset && recording.duration && (
              <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/60">
                <div
                  className="h-full bg-indigo-500"
                  style={{ width: `${Math.min(100, (recording.viewOffset / (recording.duration * 60000)) * 100)}%` }}
                />
              </div>
            )}
          </div>

          {/* Content */}
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <div className="min-w-0">
                <h4 className="font-medium text-white truncate">{recording.title}</h4>
                {recording.episodeNum && (
                  <p className="text-sm text-gray-400">{recording.episodeNum}</p>
                )}
              </div>

              {/* Status badge with health indicator */}
              <div className="flex items-center gap-2">
                {isRecording && liveStats && (
                  <span title={liveStats.isHealthy ? 'Recording healthy' : 'Recording may have issues'}>
                    {liveStats.isHealthy ? (
                      <Heart className="w-4 h-4 text-green-400" />
                    ) : (
                      <HeartOff className="w-4 h-4 text-red-400" />
                    )}
                  </span>
                )}
                <span className={`flex-shrink-0 px-2 py-0.5 text-xs font-medium rounded ${config.bgColor} ${config.color}`}>
                  {config.label}
                </span>
              </div>
            </div>

            {/* Metadata badges row (year, content rating, TMDB rating) */}
            <div className="mt-1 flex flex-wrap items-center gap-2 text-sm">
              {recording.year && (
                <span className="text-gray-400">{recording.year}</span>
              )}
              {recording.contentRating && (
                <span className="px-1.5 py-0.5 text-xs border border-gray-600 text-gray-400 rounded">
                  {recording.contentRating}
                </span>
              )}
              {recording.rating && recording.rating > 0 && (
                <span className="flex items-center gap-1 text-gray-400">
                  <span className="text-yellow-400">★</span>
                  {recording.rating.toFixed(1)}
                </span>
              )}
              {recording.isMovie && (
                <span className="px-1.5 py-0.5 text-xs bg-indigo-500/20 text-indigo-400 rounded">
                  MOVIE
                </span>
              )}
              {recording.isLive && (
                <span className="px-1.5 py-0.5 text-xs bg-red-500 text-white font-bold rounded animate-pulse">
                  LIVE
                </span>
              )}
            </div>

            {/* Live recording stats panel */}
            {isRecording && liveStats && (
              <div className={`mt-3 p-3 rounded-lg border ${
                liveStats.isFailed
                  ? 'bg-red-900/30 border-red-500/40'
                  : 'bg-gray-900/50 border-red-500/20'
              }`}>
                {liveStats.isFailed ? (
                  <div className="flex items-center gap-3">
                    <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
                    <div>
                      <p className="text-red-400 font-medium">Recording Failed</p>
                      <p className="text-sm text-gray-400">{liveStats.failureReason}</p>
                    </div>
                  </div>
                ) : (
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                    <div className="flex items-center gap-2">
                      <HardDrive className="w-4 h-4 text-red-400" />
                      <div>
                        <p className="text-white font-medium">{liveStats.fileSizeFormatted}</p>
                        <p className="text-xs text-gray-500">File Size</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Timer className="w-4 h-4 text-red-400" />
                      <div>
                        <p className="text-white font-medium">{liveStats.elapsedFormatted}</p>
                        <p className="text-xs text-gray-500">Elapsed</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Activity className="w-4 h-4 text-red-400" />
                      <div>
                        <p className="text-white font-medium">{Math.round(liveStats.progressPercent)}%</p>
                        <p className="text-xs text-gray-500">Progress</p>
                      </div>
                    </div>
                    {liveStats.bitrate && (
                      <div className="flex items-center gap-2">
                        <Zap className="w-4 h-4 text-red-400" />
                        <div>
                          <p className="text-white font-medium">{liveStats.bitrate}</p>
                          <p className="text-xs text-gray-500">Bitrate</p>
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}

            {/* Details row */}
            <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-gray-400">
              {recording.channelName && !recording.channelLogo && (
                <span className="flex items-center gap-1">
                  <Tv className="w-3.5 h-3.5" />
                  {recording.channelName}
                </span>
              )}
              <span className="flex items-center gap-1">
                <Calendar className="w-3.5 h-3.5" />
                {formatDate(recording.startTime)}
              </span>
              <span className="flex items-center gap-1">
                <Clock className="w-3.5 h-3.5" />
                {formatTimeRange(recording.startTime, recording.endTime)}
              </span>
              {recording.duration && (
                <span className="flex items-center gap-1">
                  <Timer className="w-3.5 h-3.5" />
                  {formatDuration(recording.duration)}
                </span>
              )}
              {/* Show file size only for non-recording status */}
              {!isRecording && recording.fileSize && (
                <span className="flex items-center gap-1">
                  <HardDrive className="w-3.5 h-3.5" />
                  {formatFileSize(recording.fileSize)}
                </span>
              )}
            </div>

            {/* Genres */}
            {recording.genres && (
              <p className="mt-1 text-xs text-gray-500 truncate">{recording.genres}</p>
            )}

            {/* Description/Summary */}
            {(recording.summary || recording.description) && (
              <p className="mt-2 text-sm text-gray-500 line-clamp-2">
                {recording.summary || recording.description}
              </p>
            )}

            {/* Category/Series/Watch status tags */}
            <div className="mt-2 flex flex-wrap gap-2">
              {/* Watched status for completed recordings */}
              {recording.status === 'completed' && recording.duration && (
                (() => {
                  const durationMs = recording.duration * 60000 // Convert minutes to ms
                  const watchPercent = recording.viewOffset ? (recording.viewOffset / durationMs) * 100 : 0
                  if (watchPercent >= 90) {
                    return (
                      <span className="px-2 py-0.5 text-xs bg-green-500/20 text-green-400 rounded flex items-center gap-1">
                        <CheckCircle className="w-3 h-3" />
                        Watched
                      </span>
                    )
                  } else if (watchPercent > 5) {
                    return (
                      <span className="px-2 py-0.5 text-xs bg-blue-500/20 text-blue-400 rounded">
                        {Math.round(watchPercent)}% watched
                      </span>
                    )
                  } else {
                    return (
                      <span className="px-2 py-0.5 text-xs bg-gray-600/50 text-gray-400 rounded">
                        Unwatched
                      </span>
                    )
                  }
                })()
              )}
              {recording.category && !recording.isMovie && (
                <span className="px-2 py-0.5 text-xs bg-gray-700 text-gray-300 rounded">
                  {recording.category}
                </span>
              )}
              {recording.seriesRecord && (
                <span className="px-2 py-0.5 text-xs bg-indigo-500/20 text-indigo-400 rounded">
                  Series Recording
                </span>
              )}
            </div>
          </div>

          {/* Actions */}
          <div className="flex-shrink-0 flex items-center gap-1">
            {(recording.status === 'completed' || recording.status === 'recording') && onPlay && (
              <button
                onClick={onPlay}
                className={`p-2 hover:bg-gray-700 rounded-lg transition-colors ${
                  recording.status === 'recording'
                    ? 'text-red-400 hover:text-red-300'
                    : 'text-gray-400 hover:text-green-400'
                }`}
                title={recording.status === 'recording' ? 'Watch' : 'Play'}
              >
                <Play className="w-4 h-4" />
              </button>
            )}
            <button
              onClick={onDelete}
              className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg transition-colors"
              title="Delete"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

function CalendarView({ recordings }: { recordings: Recording[] }) {
  // Get upcoming scheduled recordings (next 7 days)
  const upcomingRecordings = useMemo(() => {
    const now = new Date()
    const weekFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)

    return recordings
      .filter(r => r.status === 'scheduled' || r.status === 'recording')
      .filter(r => {
        const startTime = new Date(r.startTime)
        const endTime = r.endTime ? new Date(r.endTime) : new Date(startTime.getTime() + 60 * 60 * 1000)
        // Include if recording hasn't ended yet and starts within the week
        return endTime >= now && startTime <= weekFromNow
      })
      .sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())
  }, [recordings])

  // Group by date
  const recordingsByDate = useMemo(() => {
    const groups = new Map<string, Recording[]>()

    upcomingRecordings.forEach(rec => {
      const date = new Date(rec.startTime).toDateString()
      const existing = groups.get(date) || []
      existing.push(rec)
      groups.set(date, existing)
    })

    return groups
  }, [upcomingRecordings])

  // Generate next 7 days
  const days = useMemo(() => {
    const result: Date[] = []
    const today = new Date()
    for (let i = 0; i < 7; i++) {
      const day = new Date(today)
      day.setDate(today.getDate() + i)
      day.setHours(0, 0, 0, 0)
      result.push(day)
    }
    return result
  }, [])

  const formatDayName = (date: Date): string => {
    const today = new Date()
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)

    if (date.toDateString() === today.toDateString()) return 'Today'
    if (date.toDateString() === tomorrow.toDateString()) return 'Tomorrow'
    return date.toLocaleDateString([], { weekday: 'short' })
  }

  const formatDayDate = (date: Date): string => {
    return date.toLocaleDateString([], { month: 'short', day: 'numeric' })
  }

  const formatTime = (dateStr: string): string => {
    return new Date(dateStr).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
  }

  return (
    <div>
      <div className="flex items-center gap-2 mb-4">
        <Calendar className="w-5 h-5 text-indigo-400" />
        <h3 className="font-semibold text-white">Upcoming Recordings (Next 7 Days)</h3>
      </div>

      {upcomingRecordings.length === 0 ? (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <Calendar className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No upcoming recordings</h3>
          <p className="text-gray-400">Schedule recordings from the TV Guide</p>
        </div>
      ) : (
        <div className="grid grid-cols-7 gap-2">
          {days.map((day) => {
            const dateKey = day.toDateString()
            const dayRecordings = recordingsByDate.get(dateKey) || []
            const isToday = day.toDateString() === new Date().toDateString()

            return (
              <div
                key={dateKey}
                className={`bg-gray-800 rounded-xl p-3 min-h-[200px] ${
                  isToday ? 'border border-indigo-500/50' : ''
                }`}
              >
                <div className={`text-center mb-3 pb-2 border-b border-gray-700 ${
                  isToday ? 'text-indigo-400' : 'text-gray-400'
                }`}>
                  <div className="font-medium">{formatDayName(day)}</div>
                  <div className="text-sm">{formatDayDate(day)}</div>
                </div>

                <div className="space-y-2">
                  {dayRecordings.map((rec) => (
                    <div
                      key={rec.id}
                      className={`p-2 rounded-lg text-xs ${
                        rec.status === 'recording'
                          ? 'bg-red-500/20 border border-red-500/40'
                          : 'bg-blue-500/10 border border-blue-500/30'
                      }`}
                    >
                      <div className={`font-medium truncate ${
                        rec.status === 'recording' ? 'text-red-300' : 'text-white'
                      }`}>
                        {rec.title}
                      </div>
                      <div className="text-gray-400 mt-0.5 flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {formatTime(rec.startTime)}
                      </div>
                      {rec.channelName && (
                        <div className="text-gray-500 truncate">{rec.channelName}</div>
                      )}
                      {rec.status === 'recording' && (
                        <div className="flex items-center gap-1 text-red-400 mt-1">
                          <CircleDot className="w-3 h-3 animate-pulse" />
                          Recording
                        </div>
                      )}
                    </div>
                  ))}

                  {dayRecordings.length === 0 && (
                    <div className="text-center text-gray-600 text-xs py-4">
                      No recordings
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

function StorageStatsWidget({ recordings }: { recordings: Recording[] }) {
  const stats = useMemo(() => {
    const completedRecordings = recordings.filter(r => r.status === 'completed')
    const totalSize = completedRecordings.reduce((sum, r) => sum + (r.fileSize || 0), 0)
    const watchedCount = completedRecordings.filter(r => {
      if (!r.viewOffset || !r.duration) return false
      const durationMs = r.duration * 60000
      return (r.viewOffset / durationMs) >= 0.9
    }).length
    const unwatchedCount = completedRecordings.length - watchedCount

    // Group by series/title (for TV shows)
    const byTitle = new Map<string, { count: number; size: number }>()
    completedRecordings.forEach(r => {
      const title = r.title
      const existing = byTitle.get(title) || { count: 0, size: 0 }
      existing.count++
      existing.size += r.fileSize || 0
      byTitle.set(title, existing)
    })

    // Sort by size (largest first)
    const topTitles = Array.from(byTitle.entries())
      .sort((a, b) => b[1].size - a[1].size)
      .slice(0, 5)

    return {
      totalSize,
      totalCount: completedRecordings.length,
      watchedCount,
      unwatchedCount,
      topTitles,
    }
  }, [recordings])

  const formatSize = (bytes: number): string => {
    if (bytes === 0) return '0 B'
    const gb = bytes / (1024 * 1024 * 1024)
    if (gb >= 1) return `${gb.toFixed(1)} GB`
    const mb = bytes / (1024 * 1024)
    if (mb >= 1) return `${mb.toFixed(0)} MB`
    const kb = bytes / 1024
    return `${kb.toFixed(0)} KB`
  }

  return (
    <div className="bg-gray-800 rounded-xl p-5 mb-6">
      <div className="flex items-center gap-2 mb-4">
        <HardDrive className="w-5 h-5 text-indigo-400" />
        <h3 className="font-semibold text-white">Storage</h3>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
        <div className="bg-gray-700/50 rounded-lg p-3">
          <p className="text-2xl font-bold text-white">{formatSize(stats.totalSize)}</p>
          <p className="text-sm text-gray-400">Total Used</p>
        </div>
        <div className="bg-gray-700/50 rounded-lg p-3">
          <p className="text-2xl font-bold text-white">{stats.totalCount}</p>
          <p className="text-sm text-gray-400">Recordings</p>
        </div>
        <div className="bg-gray-700/50 rounded-lg p-3">
          <p className="text-2xl font-bold text-green-400">{stats.watchedCount}</p>
          <p className="text-sm text-gray-400">Watched</p>
        </div>
        <div className="bg-gray-700/50 rounded-lg p-3">
          <p className="text-2xl font-bold text-blue-400">{stats.unwatchedCount}</p>
          <p className="text-sm text-gray-400">Unwatched</p>
        </div>
      </div>

      {stats.topTitles.length > 0 && (
        <div>
          <p className="text-sm text-gray-400 mb-2">Storage by Series</p>
          <div className="space-y-2">
            {stats.topTitles.map(([title, data]) => {
              const percent = stats.totalSize > 0 ? (data.size / stats.totalSize) * 100 : 0
              return (
                <div key={title} className="flex items-center gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-sm text-white truncate">{title}</span>
                      <span className="text-xs text-gray-400 ml-2">{data.count} rec • {formatSize(data.size)}</span>
                    </div>
                    <div className="h-1.5 bg-gray-700 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-indigo-500 rounded-full"
                        style={{ width: `${percent}%` }}
                      />
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}

export function DVRPage() {
  const { data: recordings, isLoading: loadingRec } = useRecordings()
  const { data: rules, isLoading: loadingRules } = useSeriesRules()
  const { data: conflictsData } = useRecordingConflicts()
  const { data: statsData } = useRecordingStats()
  const { data: dvrSettings } = useQuery({
    queryKey: ['dvrSettings'],
    queryFn: () => api.getDVRSettings(),
  })
  const deleteRecording = useDeleteRecording()
  const deleteRule = useDeleteSeriesRule()
  const resolveConflict = useResolveConflict()
  const [showCreateRule, setShowCreateRule] = useState(false)
  const [activeTab, setActiveTab] = useState<'recordings' | 'rules' | 'calendar'>('recordings')
  const [selectedConflict, setSelectedConflict] = useState<ConflictGroup | null>(null)

  // Only show conflict warnings when max concurrent is limited (not 0/unlimited)
  const showConflictWarnings = dvrSettings?.maxConcurrentRecordings !== undefined &&
    dvrSettings.maxConcurrentRecordings > 0
  const [playbackRecording, setPlaybackRecording] = useState<Recording | null>(null)
  const [playbackStartLive, setPlaybackStartLive] = useState(false)
  const [watchOptionsRecording, setWatchOptionsRecording] = useState<Recording | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedRecordings, setSelectedRecordings] = useState<Set<number>>(new Set())
  const [isDeleting, setIsDeleting] = useState(false)

  // Filter recordings based on search query
  const filteredRecordings = useMemo(() => {
    if (!recordings || !searchQuery.trim()) return recordings
    const query = searchQuery.toLowerCase()
    return recordings.filter(rec =>
      rec.title?.toLowerCase().includes(query) ||
      rec.description?.toLowerCase().includes(query) ||
      rec.summary?.toLowerCase().includes(query) ||
      rec.channelName?.toLowerCase().includes(query) ||
      rec.genres?.toLowerCase().includes(query) ||
      rec.episodeNum?.toLowerCase().includes(query)
    )
  }, [recordings, searchQuery])

  // Selection helpers
  const selectionMode = selectedRecordings.size > 0

  const toggleRecordingSelection = (id: number) => {
    setSelectedRecordings(prev => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
  }

  const selectAllInStatus = (status: string) => {
    const statusRecordings = filteredRecordings?.filter(r => r.status === status) || []
    setSelectedRecordings(prev => {
      const next = new Set(prev)
      statusRecordings.forEach(r => next.add(r.id))
      return next
    })
  }

  const clearSelection = () => {
    setSelectedRecordings(new Set())
  }

  const handleBulkDelete = async () => {
    if (selectedRecordings.size === 0) return

    const confirmMsg = `Are you sure you want to delete ${selectedRecordings.size} recording${selectedRecordings.size > 1 ? 's' : ''}?`
    if (!confirm(confirmMsg)) return

    setIsDeleting(true)
    const ids = Array.from(selectedRecordings)

    for (const id of ids) {
      try {
        await deleteRecording.mutateAsync(id)
      } catch {
        // Continue deleting others even if one fails
      }
    }

    setSelectedRecordings(new Set())
    setIsDeleting(false)
  }

  // Create a lookup map for live stats by recording ID
  const statsMap = new Map<number, RecordingStats>()
  statsData?.stats?.forEach((stat) => {
    statsMap.set(stat.id, stat)
  })

  const groupedRecordings = filteredRecordings?.reduce(
    (acc, rec) => {
      acc[rec.status] = acc[rec.status] || []
      acc[rec.status].push(rec)
      return acc
    },
    {} as Record<string, Recording[]>
  )

  const handleResolveConflict = (keepId: number, cancelId: number) => {
    resolveConflict.mutate(
      { keepId, cancelId },
      {
        onSuccess: () => {
          setSelectedConflict(null)
        },
      }
    )
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">DVR</h1>
        <p className="text-gray-400 mt-1">Manage recordings and series rules</p>
      </div>

      {/* Conflict Alert Banner - only show when max concurrent is limited */}
      {showConflictWarnings && conflictsData?.hasConflicts && (
        <div className="mb-6 p-4 bg-amber-500/10 border border-amber-500/30 rounded-xl">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-amber-400 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <h3 className="font-medium text-amber-400">
                {conflictsData.totalCount} Recording Conflict{conflictsData.totalCount > 1 ? 's' : ''} Detected
              </h3>
              <p className="text-sm text-gray-400 mt-1">
                Some of your scheduled recordings overlap in time. Only {dvrSettings?.maxConcurrentRecordings} can be recorded at a time.
              </p>
              <div className="mt-3 flex flex-wrap gap-2">
                {conflictsData.conflicts.map((conflict, idx) => (
                  <button
                    key={idx}
                    onClick={() => setSelectedConflict(conflict)}
                    className="px-3 py-1.5 text-sm bg-amber-500/20 hover:bg-amber-500/30 text-amber-300 rounded-lg transition-colors"
                  >
                    {conflict.recordings.map((r) => r.title).join(' vs ')}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-2 mb-6">
        <button
          onClick={() => setActiveTab('recordings')}
          className={`px-4 py-2 rounded-lg font-medium ${
            activeTab === 'recordings'
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-800 text-gray-400 hover:text-white'
          }`}
        >
          Recordings
        </button>
        <button
          onClick={() => setActiveTab('rules')}
          className={`px-4 py-2 rounded-lg font-medium ${
            activeTab === 'rules'
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-800 text-gray-400 hover:text-white'
          }`}
        >
          Series Rules
        </button>
        <button
          onClick={() => setActiveTab('calendar')}
          className={`px-4 py-2 rounded-lg font-medium flex items-center gap-2 ${
            activeTab === 'calendar'
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-800 text-gray-400 hover:text-white'
          }`}
        >
          <Calendar className="w-4 h-4" />
          Calendar
        </button>
      </div>

      {activeTab === 'recordings' && (
        <div>
          {/* Search and Actions Bar */}
          <div className="mb-6 flex flex-col sm:flex-row gap-4">
            {/* Search Input */}
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search recordings by title, channel, description..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-gray-400 hover:text-white"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>

          {/* Selection Toolbar */}
          {selectionMode && (
            <div className="mb-4 p-3 bg-indigo-600/20 border border-indigo-500/30 rounded-lg flex items-center justify-between">
              <div className="flex items-center gap-4">
                <span className="text-indigo-300 font-medium">
                  {selectedRecordings.size} selected
                </span>
                <button
                  onClick={clearSelection}
                  className="text-sm text-gray-400 hover:text-white"
                >
                  Clear selection
                </button>
              </div>
              <button
                onClick={handleBulkDelete}
                disabled={isDeleting}
                className="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white rounded-lg font-medium"
              >
                {isDeleting ? (
                  <Loader className="w-4 h-4 animate-spin" />
                ) : (
                  <Trash2 className="w-4 h-4" />
                )}
                Delete Selected
              </button>
            </div>
          )}

          {loadingRec ? (
            <div className="flex items-center justify-center py-12">
              <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
            </div>
          ) : recordings?.length ? (
            <div className="space-y-8">
              {/* Summary stats */}
              <div className="grid grid-cols-4 gap-4">
                {(['scheduled', 'recording', 'completed', 'failed'] as const).map((status) => {
                  const count = groupedRecordings?.[status]?.length || 0
                  const config = statusConfig[status]
                  const StatusIcon = config.icon
                  return (
                    <div key={status} className={`p-4 rounded-xl border ${config.borderColor} ${config.bgColor}`}>
                      <div className="flex items-center gap-3">
                        <StatusIcon className={`w-5 h-5 ${config.color}`} />
                        <div>
                          <p className="text-2xl font-bold text-white">{count}</p>
                          <p className="text-sm text-gray-400">{config.label}</p>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>

              {/* Storage Stats Widget */}
              <StorageStatsWidget recordings={recordings} />

              {/* Recordings by status */}
              {(['recording', 'scheduled', 'completed', 'failed'] as const).map((status) => {
                const items = groupedRecordings?.[status]
                if (!items?.length) return null

                const config = statusConfig[status]
                const StatusIcon = config.icon
                return (
                  <div key={status}>
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wider flex items-center gap-2">
                        <StatusIcon className={`h-4 w-4 ${config.color}`} />
                        {config.label} ({items.length})
                      </h3>
                      {items.length > 0 && (
                        <button
                          onClick={() => selectAllInStatus(status)}
                          className="text-xs text-indigo-400 hover:text-indigo-300"
                        >
                          Select all {config.label.toLowerCase()}
                        </button>
                      )}
                    </div>
                    <div className="space-y-3">
                      {items.map((rec) => (
                        <RecordingCard
                          key={rec.id}
                          recording={rec}
                          onDelete={() => deleteRecording.mutate(rec.id)}
                          onPlay={(rec.status === 'completed' || rec.status === 'recording') ? () => {
                            if (rec.status === 'recording') {
                              // Show watch options modal for active recordings
                              setWatchOptionsRecording(rec)
                            } else {
                              // Play completed recordings directly
                              setPlaybackStartLive(false)
                              setPlaybackRecording(rec)
                            }
                          } : undefined}
                          liveStats={statsMap.get(rec.id)}
                          isSelected={selectedRecordings.has(rec.id)}
                          onToggleSelect={() => toggleRecordingSelection(rec.id)}
                          selectionMode={true}
                        />
                      ))}
                    </div>
                  </div>
                )
              })}
            </div>
          ) : searchQuery && recordings?.length ? (
            <div className="text-center py-12 bg-gray-800 rounded-xl">
              <Search className="h-12 w-12 text-gray-600 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-white mb-2">No matches found</h3>
              <p className="text-gray-400">No recordings match "{searchQuery}"</p>
              <button
                onClick={() => setSearchQuery('')}
                className="mt-4 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
              >
                Clear search
              </button>
            </div>
          ) : (
            <div className="text-center py-12 bg-gray-800 rounded-xl">
              <Video className="h-12 w-12 text-gray-600 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-white mb-2">No recordings</h3>
              <p className="text-gray-400">Schedule recordings from On Later or the EPG Guide</p>
            </div>
          )}
        </div>
      )}

      {activeTab === 'rules' && (
        <div>
          <div className="flex justify-end mb-4">
            <button
              onClick={() => setShowCreateRule(true)}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              <Plus className="h-4 w-4" />
              Add Series Rule
            </button>
          </div>

          {loadingRules ? (
            <div className="text-gray-400">Loading...</div>
          ) : rules?.length ? (
            <div className="bg-gray-800 rounded-xl divide-y divide-gray-700">
              {rules.map((rule) => (
                <div key={rule.id} className="p-4 flex items-center justify-between">
                  <div>
                    <h4 className="font-medium text-white">{rule.title}</h4>
                    <p className="text-sm text-gray-400">
                      {rule.anyChannel ? 'Any channel' : 'Specific channel'}
                      {' • Keep '}
                      {rule.keepCount === 0 ? 'all' : `last ${rule.keepCount}`}
                      {' • '}
                      {rule.enabled ? (
                        <span className="text-green-400">Enabled</span>
                      ) : (
                        <span className="text-gray-500">Disabled</span>
                      )}
                    </p>
                  </div>
                  <button
                    onClick={() => deleteRule.mutate(rule.id)}
                    className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg"
                    title="Delete"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12 bg-gray-800 rounded-xl">
              <Video className="h-12 w-12 text-gray-600 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-white mb-2">No series rules</h3>
              <p className="text-gray-400 mb-4">Create rules to automatically record shows</p>
              <button
                onClick={() => setShowCreateRule(true)}
                className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
              >
                <Plus className="h-4 w-4" />
                Add Series Rule
              </button>
            </div>
          )}
        </div>
      )}

      {activeTab === 'calendar' && recordings && (
        <CalendarView recordings={recordings} />
      )}

      {showCreateRule && <CreateRuleModal onClose={() => setShowCreateRule(false)} />}

      {selectedConflict && (
        <ConflictResolutionModal
          conflict={selectedConflict}
          onClose={() => setSelectedConflict(null)}
          onResolve={handleResolveConflict}
          isResolving={resolveConflict.isPending}
        />
      )}

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
    </div>
  )
}
