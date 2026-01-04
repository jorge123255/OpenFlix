import { Cpu, MonitorPlay, Zap, HardDrive, AlertCircle, CheckCircle2, RefreshCw, PlayCircle, Settings2 } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'

interface TranscodeInfo {
  config: {
    enabled: boolean
    ffmpegPath: string
    hwAccel: string
    tempDir: string
    maxSessions: number
  }
  hardware: {
    available: boolean
    type: string
    name: string
    gpuInfo: string
    encoders: string[]
    decoders: string[]
    supportsHevc: boolean
    supportsAv1: boolean
    maxResolution: string
    recommendedMode: string
    detectedGpus?: string[]
    missingSupport?: string
  }
  sessions: {
    active: number
    max: number
    details: Array<{
      id: string
      fileId: number
      quality: string
      startTime: string
      lastAccess: string
    }>
  }
  playbackModes: Array<{
    id: string
    name: string
    description: string
  }>
}

function useTranscodeInfo() {
  return useQuery({
    queryKey: ['transcodeInfo'],
    queryFn: async (): Promise<TranscodeInfo> => {
      const response = await fetch('/api/transcode', {
        headers: {
          'X-Plex-Token': localStorage.getItem('openflix_token') || '',
        },
      })
      if (!response.ok) throw new Error('Failed to fetch transcode info')
      return response.json()
    },
    refetchInterval: 10000, // Refresh every 10 seconds
  })
}

function HardwareCard({ hardware }: { hardware: TranscodeInfo['hardware'] }) {
  const hasDetectedGpus = hardware.detectedGpus && hardware.detectedGpus.length > 0

  const getIcon = () => {
    if (!hardware.available && hasDetectedGpus) return <AlertCircle className="h-8 w-8 text-yellow-400" />
    if (!hardware.available) return <Cpu className="h-8 w-8 text-gray-400" />
    switch (hardware.type) {
      case 'nvenc':
        return <Zap className="h-8 w-8 text-green-400" />
      case 'qsv':
        return <Cpu className="h-8 w-8 text-blue-400" />
      case 'videotoolbox':
        return <MonitorPlay className="h-8 w-8 text-purple-400" />
      case 'vaapi':
        return <HardDrive className="h-8 w-8 text-orange-400" />
      default:
        return <Cpu className="h-8 w-8 text-gray-400" />
    }
  }

  return (
    <div className="bg-gray-800 rounded-xl p-6">
      <div className="flex items-start gap-4">
        <div className="p-3 bg-gray-700 rounded-lg">
          {getIcon()}
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-lg font-semibold text-white">{hardware.name}</h3>
            {hardware.available ? (
              <span className="flex items-center gap-1 text-xs bg-green-500/20 text-green-400 px-2 py-0.5 rounded-full">
                <CheckCircle2 className="h-3 w-3" /> Available
              </span>
            ) : hasDetectedGpus ? (
              <span className="flex items-center gap-1 text-xs bg-yellow-500/20 text-yellow-400 px-2 py-0.5 rounded-full">
                <AlertCircle className="h-3 w-3" /> GPU Detected - Not Usable
              </span>
            ) : (
              <span className="flex items-center gap-1 text-xs bg-gray-500/20 text-gray-400 px-2 py-0.5 rounded-full">
                <AlertCircle className="h-3 w-3" /> Software Only
              </span>
            )}
          </div>
          {hardware.gpuInfo && (
            <p className="text-sm text-gray-400 mb-3">{hardware.gpuInfo}</p>
          )}

          {/* Show detected GPUs when hardware acceleration isn't available */}
          {!hardware.available && hasDetectedGpus && (
            <div className="mb-3">
              <h4 className="text-xs font-medium text-gray-500 uppercase mb-1">Detected GPUs</h4>
              <div className="space-y-1">
                {hardware.detectedGpus!.map((gpu, i) => (
                  <p key={i} className="text-sm text-yellow-400">{gpu}</p>
                ))}
              </div>
            </div>
          )}

          {/* Show missing support message */}
          {hardware.missingSupport && (
            <div className="mb-3 p-3 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
              <p className="text-sm text-yellow-300">{hardware.missingSupport}</p>
            </div>
          )}

          <div className="grid grid-cols-2 gap-4 mt-4">
            <div>
              <h4 className="text-xs font-medium text-gray-500 uppercase mb-2">Encoders</h4>
              <div className="flex flex-wrap gap-1">
                {hardware.encoders.map((enc) => (
                  <span key={enc} className="text-xs bg-gray-700 text-gray-300 px-2 py-1 rounded">
                    {enc}
                  </span>
                ))}
              </div>
            </div>
            <div>
              <h4 className="text-xs font-medium text-gray-500 uppercase mb-2">Decoders</h4>
              <div className="flex flex-wrap gap-1">
                {hardware.decoders.map((dec) => (
                  <span key={dec} className="text-xs bg-gray-700 text-gray-300 px-2 py-1 rounded">
                    {dec}
                  </span>
                ))}
              </div>
            </div>
          </div>

          <div className="flex gap-4 mt-4 pt-4 border-t border-gray-700">
            <div className="flex items-center gap-2">
              <span className="text-xs text-gray-500">HEVC</span>
              {hardware.supportsHevc ? (
                <CheckCircle2 className="h-4 w-4 text-green-400" />
              ) : (
                <AlertCircle className="h-4 w-4 text-gray-500" />
              )}
            </div>
            <div className="flex items-center gap-2">
              <span className="text-xs text-gray-500">AV1</span>
              {hardware.supportsAv1 ? (
                <CheckCircle2 className="h-4 w-4 text-green-400" />
              ) : (
                <AlertCircle className="h-4 w-4 text-gray-500" />
              )}
            </div>
            {hardware.maxResolution && (
              <div className="flex items-center gap-2">
                <span className="text-xs text-gray-500">Max Resolution</span>
                <span className="text-xs text-white font-medium">{hardware.maxResolution}</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function PlaybackModesCard({ modes, recommended }: { modes: TranscodeInfo['playbackModes']; recommended: string }) {
  return (
    <div className="bg-gray-800 rounded-xl p-6">
      <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        <PlayCircle className="h-5 w-5" />
        Playback Modes
      </h3>
      <div className="space-y-3">
        {modes.map((mode) => (
          <div
            key={mode.id}
            className={`p-4 rounded-lg border ${
              mode.id === recommended
                ? 'border-indigo-500 bg-indigo-500/10'
                : 'border-gray-700 bg-gray-700/50'
            }`}
          >
            <div className="flex items-center gap-2 mb-1">
              <span className="font-medium text-white">{mode.name}</span>
              {mode.id === recommended && (
                <span className="text-xs bg-indigo-500 text-white px-2 py-0.5 rounded">
                  Recommended
                </span>
              )}
            </div>
            <p className="text-sm text-gray-400">{mode.description}</p>
          </div>
        ))}
      </div>
    </div>
  )
}

function ConfigCard({ config }: { config: TranscodeInfo['config'] }) {
  return (
    <div className="bg-gray-800 rounded-xl p-6">
      <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        <Settings2 className="h-5 w-5" />
        Configuration
      </h3>
      <div className="space-y-3">
        <div className="flex justify-between items-center py-2 border-b border-gray-700">
          <span className="text-gray-400">Transcoding Enabled</span>
          <span className={config.enabled ? 'text-green-400' : 'text-red-400'}>
            {config.enabled ? 'Yes' : 'No'}
          </span>
        </div>
        <div className="flex justify-between items-center py-2 border-b border-gray-700">
          <span className="text-gray-400">FFmpeg Path</span>
          <span className="text-white font-mono text-sm">{config.ffmpegPath}</span>
        </div>
        <div className="flex justify-between items-center py-2 border-b border-gray-700">
          <span className="text-gray-400">Hardware Acceleration</span>
          <span className="text-white capitalize">{config.hwAccel}</span>
        </div>
        <div className="flex justify-between items-center py-2 border-b border-gray-700">
          <span className="text-gray-400">Temp Directory</span>
          <span className="text-white font-mono text-sm truncate max-w-xs">{config.tempDir}</span>
        </div>
        <div className="flex justify-between items-center py-2">
          <span className="text-gray-400">Max Sessions</span>
          <span className="text-white">{config.maxSessions}</span>
        </div>
      </div>
    </div>
  )
}

function SessionsCard({ sessions }: { sessions: TranscodeInfo['sessions'] }) {
  return (
    <div className="bg-gray-800 rounded-xl p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-white flex items-center gap-2">
          <MonitorPlay className="h-5 w-5" />
          Active Sessions
        </h3>
        <span className="text-sm text-gray-400">
          {sessions.active} / {sessions.max}
        </span>
      </div>

      {/* Progress bar */}
      <div className="h-2 bg-gray-700 rounded-full mb-4">
        <div
          className={`h-full rounded-full transition-all ${
            sessions.active >= sessions.max ? 'bg-red-500' : 'bg-indigo-500'
          }`}
          style={{ width: `${Math.min((sessions.active / sessions.max) * 100, 100)}%` }}
        />
      </div>

      {sessions.details.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <MonitorPlay className="h-12 w-12 mx-auto mb-2 opacity-50" />
          <p>No active transcoding sessions</p>
        </div>
      ) : (
        <div className="space-y-2">
          {sessions.details.map((session) => (
            <div key={session.id} className="p-3 bg-gray-700 rounded-lg">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-white font-mono text-sm truncate">{session.id.slice(0, 8)}...</p>
                  <p className="text-xs text-gray-400">Quality: {session.quality}</p>
                </div>
                <span className="text-xs bg-green-500/20 text-green-400 px-2 py-1 rounded">
                  Active
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export function TranscodePage() {
  const { data: info, isLoading, refetch } = useTranscodeInfo()

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="h-8 w-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  if (!info) {
    return (
      <div className="text-center py-12">
        <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-white">Failed to load transcoding info</h3>
        <button
          onClick={() => refetch()}
          className="mt-4 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
        >
          Retry
        </button>
      </div>
    )
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-white">Transcoding</h1>
        <p className="text-gray-400 mt-1">
          Hardware acceleration and transcoding settings
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Hardware Detection */}
        <HardwareCard hardware={info.hardware} />

        {/* Configuration */}
        <ConfigCard config={info.config} />

        {/* Playback Modes */}
        <PlaybackModesCard
          modes={info.playbackModes}
          recommended={info.hardware.recommendedMode}
        />

        {/* Active Sessions */}
        <SessionsCard sessions={info.sessions} />
      </div>

      {/* Client-side vs Server-side explanation */}
      <div className="mt-6 bg-gray-800 rounded-xl p-6">
        <h3 className="text-lg font-semibold text-white mb-4">Playback Strategy</h3>
        <div className="prose prose-invert prose-sm max-w-none">
          <p className="text-gray-300">
            OpenFlix supports multiple playback strategies to optimize quality and performance:
          </p>
          <ul className="text-gray-300 mt-3 space-y-2">
            <li>
              <strong className="text-white">Direct Play:</strong> The client device decodes the original file directly.
              This provides the best quality and requires no server resources. Most modern devices (Android, iOS, Smart TVs)
              support hardware decoding for H.264 and often HEVC.
            </li>
            <li>
              <strong className="text-white">Direct Stream:</strong> The server remuxes the file (changes container format)
              without re-encoding. Useful when the client supports the codec but not the container format.
            </li>
            <li>
              <strong className="text-white">Server Transcode:</strong> The server re-encodes the video to a compatible format.
              Uses server CPU or GPU resources. Enable hardware acceleration (NVENC, QSV, VideoToolbox) for better performance.
            </li>
          </ul>
          <p className="text-gray-400 mt-4 text-sm">
            {info.hardware.available
              ? `Your server has hardware acceleration available (${info.hardware.name}). Server transcoding will use the GPU for efficient encoding.`
              : 'Your server will use software (CPU) transcoding. Consider using Direct Play when possible to reduce server load.'}
          </p>
        </div>
      </div>

      {/* Smart Playback Selection */}
      <div className="mt-6 bg-gradient-to-br from-indigo-900/50 to-purple-900/50 rounded-xl p-6 border border-indigo-500/30">
        <div className="flex items-start gap-4">
          <div className="p-3 bg-indigo-500/20 rounded-lg">
            <Zap className="h-6 w-6 text-indigo-400" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-white mb-2">Smart Playback Selection</h3>
            <p className="text-gray-300 text-sm mb-3">
              OpenFlix automatically analyzes each media file and your device's capabilities to choose the optimal playback mode:
            </p>
            <ul className="text-gray-400 text-sm space-y-1">
              <li className="flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-green-400" />
                <span>Analyzes video codec, audio codec, container format, and resolution</span>
              </li>
              <li className="flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-green-400" />
                <span>Detects HDR, Dolby Vision, and Atmos compatibility</span>
              </li>
              <li className="flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-green-400" />
                <span>Considers network bandwidth and client device capabilities</span>
              </li>
              <li className="flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-green-400" />
                <span>Prioritizes Direct Play for best quality, falls back to transcoding when needed</span>
              </li>
            </ul>
            <p className="text-indigo-300 text-xs mt-3">
              API: GET /api/playback/decide/:fileId — Returns recommended playback mode for any media file
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
