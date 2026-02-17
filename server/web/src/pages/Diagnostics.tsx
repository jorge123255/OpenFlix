import {
  Activity,
  Cpu,
  HardDrive,
  Server,
  Clock,
  RefreshCw,
  AlertTriangle,
  Loader,
  CheckCircle,
  XCircle,
  Tv,
  Video,
  FolderOpen,
  Zap,
  MemoryStick,
  Layers,
} from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'

interface HealthResponse {
  status: string
}

const TOKEN_KEY = 'openflix_token'

function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

async function fetchHealth(): Promise<HealthResponse> {
  const res = await fetch('/health', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Health check failed')
  return res.json()
}

function StatCard({ title, value, icon: Icon, color, subtitle }: {
  title: string
  value: string | number
  icon: React.ElementType
  color: string
  subtitle?: string
}) {
  return (
    <div className="bg-gray-800 rounded-xl p-5">
      <div className="flex items-center gap-3">
        <div className={`p-2.5 rounded-lg ${color}`}>
          <Icon className="h-5 w-5 text-white" />
        </div>
        <div className="min-w-0">
          <p className="text-xs text-gray-400">{title}</p>
          <p className="text-xl font-bold text-white truncate">{value}</p>
          {subtitle && <p className="text-xs text-gray-500 truncate">{subtitle}</p>}
        </div>
      </div>
    </div>
  )
}

function ProgressBar({ value, max, label, color = 'bg-indigo-600' }: {
  value: number
  max: number
  label: string
  color?: string
}) {
  const percent = max > 0 ? Math.min(100, Math.round((value / max) * 100)) : 0
  return (
    <div>
      <div className="flex justify-between text-sm mb-1.5">
        <span className="text-gray-300">{label}</span>
        <span className="text-gray-400">{percent}%</span>
      </div>
      <div className="h-3 bg-gray-700 rounded-full overflow-hidden">
        <div
          className={`h-full ${color} rounded-full transition-all duration-500`}
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  )
}

function HealthIndicator({ health }: { health?: HealthResponse; isLoading: boolean; error?: Error | null }) {
  if (!health) {
    return (
      <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-700 rounded-lg">
        <Loader className="h-4 w-4 text-gray-400 animate-spin" />
        <span className="text-sm text-gray-400">Checking...</span>
      </div>
    )
  }

  const isOk = health.status === 'ok'
  return (
    <div className={`flex items-center gap-2 px-3 py-1.5 rounded-lg ${
      isOk ? 'bg-green-500/10 border border-green-500/30' : 'bg-red-500/10 border border-red-500/30'
    }`}>
      {isOk ? (
        <CheckCircle className="h-4 w-4 text-green-400" />
      ) : (
        <XCircle className="h-4 w-4 text-red-400" />
      )}
      <span className={`text-sm ${isOk ? 'text-green-400' : 'text-red-400'}`}>
        {isOk ? 'Healthy' : 'Unhealthy'}
      </span>
    </div>
  )
}

export function DiagnosticsPage() {
  const { data: status, isLoading: statusLoading, error: statusError, refetch: refetchStatus } = useQuery({
    queryKey: ['serverStatus'],
    queryFn: () => api.getServerStatus(),
    refetchInterval: 10000,
  })

  const { data: health, isLoading: healthLoading, error: healthError } = useQuery({
    queryKey: ['healthCheck'],
    queryFn: fetchHealth,
    refetchInterval: 10000,
  })

  if (statusLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  if (statusError) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <AlertTriangle className="h-12 w-12 text-red-400" />
        <h3 className="text-lg font-medium text-white">Failed to load diagnostics</h3>
        <p className="text-gray-400 text-sm">{(statusError as Error).message}</p>
        <button
          onClick={() => refetchStatus()}
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
            <Activity className="h-7 w-7 text-indigo-400" />
            Diagnostics
          </h1>
          <p className="text-gray-400 mt-1">System health and performance overview</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 text-xs text-gray-500">
            <RefreshCw className="h-3 w-3 animate-spin" />
            Auto-refresh: 10s
          </div>
          <HealthIndicator health={health} isLoading={healthLoading} error={healthError as Error | null} />
          <button
            onClick={() => refetchStatus()}
            className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>
      </div>

      {/* Server Info Banner */}
      {status && (
        <div className="bg-gray-800 rounded-xl p-5 mb-6">
          <div className="flex flex-wrap items-center gap-6 text-sm">
            <div className="flex items-center gap-2">
              <Server className="h-4 w-4 text-indigo-400" />
              <span className="text-white font-medium">{status.server.name}</span>
              <span className="text-gray-500">v{status.server.version}</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-gray-400">{status.server.platform}/{status.server.arch}</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-gray-400">Go {status.server.goVersion}</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-gray-400">{status.server.hostname}</span>
            </div>
            <div className="flex items-center gap-2 text-gray-500 font-mono text-xs">
              {status.server.machineIdentifier}
            </div>
          </div>
        </div>
      )}

      {status && (
        <>
          {/* System Stats Grid */}
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <Cpu className="h-5 w-5" />
            System Resources
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <StatCard
              title="CPUs"
              value={status.system.numCPU}
              icon={Cpu}
              color="bg-blue-600"
            />
            <StatCard
              title="Memory Used"
              value={`${status.system.memAllocMB} MB`}
              icon={MemoryStick}
              color="bg-purple-600"
              subtitle={`${status.system.memTotalMB} MB total allocated`}
            />
            <StatCard
              title="Goroutines"
              value={status.system.goroutines}
              icon={Layers}
              color="bg-orange-600"
            />
            <StatCard
              title="Uptime"
              value={status.server.uptime}
              icon={Clock}
              color="bg-green-600"
            />
          </div>

          {/* Memory Usage */}
          <div className="bg-gray-800 rounded-xl p-6 mb-8">
            <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <HardDrive className="h-5 w-5" />
              Memory Usage
            </h2>
            <div className="space-y-4">
              <ProgressBar
                value={status.system.memAllocMB}
                max={status.system.memTotalMB}
                label="Heap Allocation"
                color={
                  status.system.memAllocMB / status.system.memTotalMB > 0.9
                    ? 'bg-red-600'
                    : status.system.memAllocMB / status.system.memTotalMB > 0.7
                    ? 'bg-yellow-600'
                    : 'bg-indigo-600'
                }
              />
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div className="bg-gray-900 rounded-lg p-3">
                  <p className="text-gray-400 text-xs">Allocated</p>
                  <p className="text-white font-medium">{status.system.memAllocMB} MB</p>
                </div>
                <div className="bg-gray-900 rounded-lg p-3">
                  <p className="text-gray-400 text-xs">Total System</p>
                  <p className="text-white font-medium">{status.system.memTotalMB} MB</p>
                </div>
              </div>
            </div>
          </div>

          {/* Library Stats */}
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <FolderOpen className="h-5 w-5" />
            Library Statistics
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <StatCard
              title="Libraries"
              value={status.libraries.count}
              icon={FolderOpen}
              color="bg-blue-600"
            />
            <StatCard
              title="Movies"
              value={status.libraries.movies}
              icon={Video}
              color="bg-purple-600"
            />
            <StatCard
              title="TV Shows"
              value={status.libraries.shows}
              icon={Tv}
              color="bg-green-600"
            />
            <StatCard
              title="Episodes"
              value={status.libraries.episodes}
              icon={Layers}
              color="bg-orange-600"
            />
          </div>

          {/* DVR Stats */}
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <Video className="h-5 w-5" />
            DVR Statistics
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <StatCard
              title="Scheduled"
              value={status.dvr.scheduled}
              icon={Clock}
              color="bg-blue-600"
            />
            <StatCard
              title="Recording Now"
              value={status.dvr.recording}
              icon={Zap}
              color="bg-red-600"
              subtitle={status.dvr.recording > 0 ? 'Active recording' : undefined}
            />
            <StatCard
              title="Completed"
              value={status.dvr.completed}
              icon={CheckCircle}
              color="bg-green-600"
            />
            <StatCard
              title="Commercial Detect"
              value={status.dvr.commercialDetect ? 'Enabled' : 'Disabled'}
              icon={Zap}
              color={status.dvr.commercialDetect ? 'bg-green-600' : 'bg-gray-600'}
            />
          </div>

          {/* Live TV Stats */}
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <Tv className="h-5 w-5" />
            Live TV Statistics
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <StatCard
              title="Total Channels"
              value={status.livetv.channels}
              icon={Tv}
              color="bg-blue-600"
            />
            <StatCard
              title="Timeshift Channels"
              value={status.livetv.timeshiftChannels}
              icon={Clock}
              color="bg-purple-600"
            />
            <StatCard
              title="Timeshift"
              value={status.livetv.timeshiftEnabled ? 'Enabled' : 'Disabled'}
              icon={Zap}
              color={status.livetv.timeshiftEnabled ? 'bg-green-600' : 'bg-gray-600'}
            />
            <StatCard
              title="Active Sessions"
              value={status.sessions.active}
              icon={Activity}
              color="bg-orange-600"
            />
          </div>

          {/* Logging Info */}
          <div className="bg-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <Activity className="h-5 w-5" />
              Logging
            </h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div className="bg-gray-900 rounded-lg p-3">
                <p className="text-gray-400 text-xs">Log Level</p>
                <p className="text-white font-medium capitalize">{status.logging.level}</p>
              </div>
              <div className="bg-gray-900 rounded-lg p-3">
                <p className="text-gray-400 text-xs">JSON Format</p>
                <p className="text-white font-medium">{status.logging.json ? 'Yes' : 'No'}</p>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
