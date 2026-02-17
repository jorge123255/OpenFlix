import {
  Monitor,
  RefreshCw,
  AlertTriangle,
  Loader,
  Play,
  Pause,
  Tv,
  Globe,
  Clock,
  Zap,
  Wifi,
  User,
} from 'lucide-react'
import { useQuery } from '@tanstack/react-query'

interface Session {
  sessionKey: string
  userId: number
  username?: string
  mediaItemId: number
  mediaTitle?: string
  mediaType?: string
  mediaThumb?: string
  state: string
  viewOffset: number
  duration: number
  progress: number
  transcoding: boolean
  quality?: string
  player?: string
  platform?: string
  address?: string
  startedAt: string
}

interface SessionsResponse {
  sessions: Session[]
  total: number
}

const TOKEN_KEY = 'openflix_token'

function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

function formatDuration(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000)
  const h = Math.floor(totalSeconds / 3600)
  const m = Math.floor((totalSeconds % 3600) / 60)
  const s = totalSeconds % 60
  if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
  return `${m}:${String(s).padStart(2, '0')}`
}

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime()
  const minutes = Math.floor(diff / 60000)
  if (minutes < 1) return 'just now'
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return `${days}d ago`
}

async function fetchSessions(): Promise<SessionsResponse> {
  const res = await fetch('/status/sessions', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch sessions')
  return res.json()
}

function StateBadge({ state }: { state: string }) {
  if (state === 'playing') {
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-green-500/10 text-green-400 border border-green-500/30 rounded-full text-xs font-medium">
        <Play className="h-3 w-3" fill="currentColor" />
        Playing
      </span>
    )
  }
  if (state === 'paused') {
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-yellow-500/10 text-yellow-400 border border-yellow-500/30 rounded-full text-xs font-medium">
        <Pause className="h-3 w-3" />
        Paused
      </span>
    )
  }
  if (state === 'buffering') {
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-blue-500/10 text-blue-400 border border-blue-500/30 rounded-full text-xs font-medium">
        <Loader className="h-3 w-3 animate-spin" />
        Buffering
      </span>
    )
  }
  return (
    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-gray-500/10 text-gray-400 border border-gray-500/30 rounded-full text-xs font-medium">
      {state}
    </span>
  )
}

function ProgressBar({ progress, viewOffset, duration }: {
  progress: number
  viewOffset: number
  duration: number
}) {
  const percent = Math.min(100, Math.max(0, progress))
  return (
    <div>
      <div className="h-2 bg-gray-700 rounded-full overflow-hidden">
        <div
          className="h-full bg-indigo-600 rounded-full transition-all duration-1000"
          style={{ width: `${percent}%` }}
        />
      </div>
      <div className="flex justify-between mt-1 text-xs text-gray-500">
        <span>{formatDuration(viewOffset)}</span>
        <span>{formatDuration(duration)}</span>
      </div>
    </div>
  )
}

function SessionCard({ session }: { session: Session }) {
  return (
    <div className="bg-gray-800 rounded-xl p-5 hover:bg-gray-750 transition-colors">
      <div className="flex items-start gap-4">
        {/* Media Thumbnail */}
        {session.mediaThumb ? (
          <img
            src={session.mediaThumb}
            alt=""
            className="w-16 h-24 rounded-lg object-cover flex-shrink-0 bg-gray-700"
          />
        ) : (
          <div className="w-16 h-24 rounded-lg bg-gray-700 flex items-center justify-center flex-shrink-0">
            <Tv className="h-8 w-8 text-gray-600" />
          </div>
        )}

        {/* Session Details */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between gap-3 mb-2">
            <div className="flex items-center gap-2 min-w-0">
              <StateBadge state={session.state} />
              {session.transcoding && (
                <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-orange-500/10 text-orange-400 rounded text-xs">
                  <Zap className="h-3 w-3" />
                  Transcoding
                </span>
              )}
            </div>
            <span className="text-xs text-gray-500 flex items-center gap-1 flex-shrink-0">
              <Clock className="h-3 w-3" />
              {timeAgo(session.startedAt)}
            </span>
          </div>

          <h3 className="text-white font-medium truncate mb-1">
            {session.mediaTitle || `Media #${session.mediaItemId}`}
          </h3>

          {/* Progress */}
          <div className="mb-3">
            <ProgressBar
              progress={session.progress}
              viewOffset={session.viewOffset}
              duration={session.duration}
            />
          </div>

          {/* Client Info */}
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-400">
            <span className="flex items-center gap-1">
              <User className="h-3 w-3" />
              {session.username || `User #${session.userId}`}
            </span>
            {session.player && (
              <span className="flex items-center gap-1">
                <Monitor className="h-3 w-3" />
                {session.player}
              </span>
            )}
            {session.platform && (
              <span className="flex items-center gap-1">
                <Tv className="h-3 w-3" />
                {session.platform}
              </span>
            )}
            {session.quality && (
              <span className="flex items-center gap-1">
                <Wifi className="h-3 w-3" />
                {session.quality}
              </span>
            )}
            {session.address && (
              <span className="flex items-center gap-1">
                <Globe className="h-3 w-3" />
                {session.address}
              </span>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export function ClientConnectionsPage() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['sessions'],
    queryFn: fetchSessions,
    refetchInterval: 5000,
  })

  const sessions = data?.sessions || []
  const playingSessions = sessions.filter((s) => s.state === 'playing').length
  const pausedSessions = sessions.filter((s) => s.state === 'paused').length
  const transcodingSessions = sessions.filter((s) => s.transcoding).length

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <AlertTriangle className="h-12 w-12 text-red-400" />
        <h3 className="text-lg font-medium text-white">Failed to load sessions</h3>
        <p className="text-gray-400 text-sm">{(error as Error).message}</p>
        <button
          onClick={() => refetch()}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
        >
          <RefreshCw className="h-4 w-4" />
          Retry
        </button>
      </div>
    )
  }

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-3">
            <Monitor className="h-7 w-7 text-indigo-400" />
            Client Connections
          </h1>
          <p className="text-gray-400 mt-1">
            {sessions.length} active session{sessions.length !== 1 ? 's' : ''}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 text-xs text-gray-500">
            <RefreshCw className="h-3 w-3 animate-spin" />
            Auto-refresh: 5s
          </div>
          <button
            onClick={() => refetch()}
            className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      {sessions.length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-gray-800 rounded-xl p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-indigo-600/20">
                <Monitor className="h-5 w-5 text-indigo-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-white">{sessions.length}</p>
                <p className="text-xs text-gray-400">Total</p>
              </div>
            </div>
          </div>
          <div className="bg-gray-800 rounded-xl p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-green-500/20">
                <Play className="h-5 w-5 text-green-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-white">{playingSessions}</p>
                <p className="text-xs text-gray-400">Playing</p>
              </div>
            </div>
          </div>
          <div className="bg-gray-800 rounded-xl p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-yellow-500/20">
                <Pause className="h-5 w-5 text-yellow-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-white">{pausedSessions}</p>
                <p className="text-xs text-gray-400">Paused</p>
              </div>
            </div>
          </div>
          <div className="bg-gray-800 rounded-xl p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-orange-500/20">
                <Zap className="h-5 w-5 text-orange-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-white">{transcodingSessions}</p>
                <p className="text-xs text-gray-400">Transcoding</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Sessions List */}
      {sessions.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-64 bg-gray-800 rounded-xl">
          <Monitor className="h-16 w-16 text-gray-600 mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No active sessions</h3>
          <p className="text-gray-400 text-sm">
            Active playback sessions will appear here in real-time
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {sessions.map((session) => (
            <SessionCard key={session.sessionKey} session={session} />
          ))}
        </div>
      )}
    </div>
  )
}
