import { Link } from 'react-router-dom'
import {
  Server,
  Cpu,
  HardDrive,
  Database,
  Package,
  Clock,
  Loader,
  AlertTriangle,
  RefreshCw,
  CheckCircle,
  XCircle,
  MemoryStick,
  Users,
  Tv,
  Video,
  FolderOpen,
  FileText,
  Clapperboard,
} from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'
import type { SystemStatusResponse, DiskUsageInfo } from '../api/client'

function SettingsTabNav({ active }: { active: 'general' | 'sources' | 'advanced' | 'status' }) {
  const tabs = [
    { id: 'general' as const, label: 'General', path: '/ui/settings' },
    { id: 'sources' as const, label: 'Sources', path: '/ui/settings/sources' },
    { id: 'advanced' as const, label: 'Advanced', path: '/ui/settings/advanced' },
    { id: 'status' as const, label: 'Status', path: '/ui/settings/status' },
  ]

  return (
    <div className="flex gap-1 mb-8 bg-gray-800 rounded-lg p-1 w-fit">
      {tabs.map((tab) => (
        <Link
          key={tab.id}
          to={tab.path}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            active === tab.id
              ? 'bg-indigo-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700'
          }`}
        >
          {tab.label}
        </Link>
      ))}
    </div>
  )
}

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  const val = bytes / Math.pow(1024, i)
  return `${val.toFixed(1)} ${units[i]}`
}

function ProgressBar({ value, max, label, sublabel, color = 'bg-indigo-600' }: {
  value: number
  max: number
  label: string
  sublabel?: string
  color?: string
}) {
  const percent = max > 0 ? Math.min(100, Math.round((value / max) * 100)) : 0
  return (
    <div>
      <div className="flex justify-between text-sm mb-1.5">
        <div>
          <span className="text-gray-300">{label}</span>
          {sublabel && <span className="text-gray-500 ml-2 text-xs">{sublabel}</span>}
        </div>
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

function DiskUsageBar({ disk }: { disk: DiskUsageInfo }) {
  const barColor = disk.percent > 90 ? 'bg-red-600' : disk.percent > 75 ? 'bg-yellow-600' : 'bg-indigo-600'
  return (
    <ProgressBar
      value={disk.used}
      max={disk.total}
      label={disk.label}
      sublabel={disk.path}
      color={barColor}
    />
  )
}

function InfoRow({ label, value, icon }: { label: string; value: string | number; icon?: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between py-2.5 border-b border-gray-700/50 last:border-0">
      <div className="flex items-center gap-2 text-sm text-gray-400">
        {icon}
        {label}
      </div>
      <span className="text-sm text-white font-medium">{value}</span>
    </div>
  )
}

function CountCard({ label, value, icon: Icon, color }: {
  label: string
  value: number
  icon: React.ElementType
  color: string
}) {
  return (
    <div className="bg-gray-900 rounded-lg p-4 flex items-center gap-3">
      <div className={`p-2 rounded-lg ${color}`}>
        <Icon className="h-4 w-4 text-white" />
      </div>
      <div>
        <p className="text-lg font-bold text-white">{value.toLocaleString()}</p>
        <p className="text-xs text-gray-400">{label}</p>
      </div>
    </div>
  )
}

function ComponentStatus({ name, value, available }: {
  name: string
  value: string
  available: boolean
}) {
  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-700/50 last:border-0">
      <div className="flex items-center gap-2">
        {available ? (
          <CheckCircle className="h-4 w-4 text-green-400" />
        ) : (
          <XCircle className="h-4 w-4 text-gray-500" />
        )}
        <span className="text-sm text-white font-medium">{name}</span>
      </div>
      <span className={`text-sm ${available ? 'text-gray-300' : 'text-gray-500'}`}>
        {value}
      </span>
    </div>
  )
}

function StatusContent({ status }: { status: SystemStatusResponse }) {
  return (
    <div className="space-y-6">
      {/* Server Info */}
      <div className="bg-gray-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          <Server className="h-5 w-5 text-indigo-400" />
          Server Info
        </h2>
        <div className="divide-y divide-gray-700/50">
          <InfoRow label="Version" value={`v${status.server.version}`} />
          <InfoRow label="Uptime" value={status.server.uptime} icon={<Clock className="h-3.5 w-3.5" />} />
          <InfoRow label="Started At" value={new Date(status.server.startedAt).toLocaleString()} />
          <InfoRow label="Operating System" value={status.server.os} />
          <InfoRow label="Architecture" value={status.server.arch} />
          <InfoRow label="Go Version" value={status.server.goVersion} />
          <InfoRow label="Hostname" value={status.server.hostname} />
        </div>
      </div>

      {/* Resource Usage */}
      <div className="bg-gray-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          <Cpu className="h-5 w-5 text-orange-400" />
          Resource Usage
        </h2>
        <div className="space-y-5">
          {/* CPU */}
          <div className="flex items-center justify-between py-2">
            <span className="text-sm text-gray-400">CPU Cores</span>
            <span className="text-sm text-white font-medium">{status.resources.cpuCores}</span>
          </div>

          {/* Memory */}
          <div>
            <ProgressBar
              value={status.resources.memUsedMB}
              max={status.resources.memTotalMB}
              label="Memory"
              sublabel={`${status.resources.memUsedMB} MB / ${status.resources.memTotalMB} MB`}
              color={
                status.resources.memPercent > 90 ? 'bg-red-600'
                : status.resources.memPercent > 75 ? 'bg-yellow-600'
                : 'bg-indigo-600'
              }
            />
          </div>

          {/* Goroutines */}
          <div className="flex items-center justify-between py-2">
            <span className="text-sm text-gray-400">Goroutines</span>
            <span className="text-sm text-white font-medium">{status.resources.goroutines}</span>
          </div>

          {/* Disk Usage */}
          {status.resources.diskUsage && status.resources.diskUsage.length > 0 && (
            <div className="pt-2">
              <h3 className="text-sm font-medium text-gray-300 mb-3 flex items-center gap-2">
                <HardDrive className="h-4 w-4" />
                Disk Usage
              </h3>
              <div className="space-y-4">
                {status.resources.diskUsage.map((disk, i) => (
                  <div key={i}>
                    <DiskUsageBar disk={disk} />
                    <div className="flex justify-between text-xs text-gray-500 mt-1">
                      <span>{formatBytes(disk.used)} used</span>
                      <span>{formatBytes(disk.free)} free of {formatBytes(disk.total)}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Database */}
      <div className="bg-gray-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          <Database className="h-5 w-5 text-green-400" />
          Database
        </h2>

        <div className="mb-4">
          <InfoRow label="Database Size" value={`${status.database.sizeMB.toFixed(1)} MB`} icon={<HardDrive className="h-3.5 w-3.5" />} />
        </div>

        <h3 className="text-sm font-medium text-gray-300 mb-3">Record Counts</h3>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <CountCard label="Libraries" value={status.database.libraries} icon={FolderOpen} color="bg-blue-600" />
          <CountCard label="Channels" value={status.database.channels} icon={Tv} color="bg-purple-600" />
          <CountCard label="Recordings" value={status.database.recordings} icon={Video} color="bg-red-600" />
          <CountCard label="Passes" value={status.database.passes} icon={FileText} color="bg-orange-600" />
          <CountCard label="Users" value={status.database.users} icon={Users} color="bg-green-600" />
          <CountCard label="Media Items" value={status.database.mediaItems} icon={Clapperboard} color="bg-indigo-600" />
          <CountCard label="Programs" value={status.database.programs} icon={MemoryStick} color="bg-yellow-600" />
        </div>
      </div>

      {/* Components */}
      <div className="bg-gray-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          <Package className="h-5 w-5 text-purple-400" />
          Components
        </h2>
        <div>
          <ComponentStatus
            name="FFmpeg"
            value={status.components.ffmpegVersion}
            available={status.components.ffmpegVersion !== 'not found'}
          />
          <ComponentStatus
            name="Chrome / Chromium"
            value={status.components.chromeVersion}
            available={status.components.chromeVersion !== 'not found'}
          />
          <ComponentStatus
            name="Comskip"
            value={status.components.comskipAvailable ? 'Installed' : 'Not found'}
            available={status.components.comskipAvailable}
          />
          <ComponentStatus
            name="Hardware Transcode"
            value={status.components.transcodeHW === 'none' ? 'Software (CPU)' : status.components.transcodeHW}
            available={status.components.transcodeHW !== 'none'}
          />
        </div>
      </div>
    </div>
  )
}

export function SettingsStatusPage() {
  const { data: status, isLoading, error, refetch } = useQuery({
    queryKey: ['systemStatus'],
    queryFn: () => api.getSystemStatus(),
    refetchInterval: 15000,
    retry: 1,
  })

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <div>
          <h1 className="text-2xl font-bold text-white">Settings</h1>
          <p className="text-gray-400 mt-1">Server status and system information</p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isLoading}
          className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 text-white rounded-lg text-sm"
        >
          {isLoading ? (
            <Loader className="h-4 w-4 animate-spin" />
          ) : (
            <RefreshCw className="h-4 w-4" />
          )}
          Refresh
        </button>
      </div>

      <SettingsTabNav active="status" />

      {isLoading && (
        <div className="flex items-center justify-center h-64">
          <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
        </div>
      )}

      {error && !isLoading && (
        <div className="flex flex-col items-center justify-center h-64 gap-4">
          <AlertTriangle className="h-12 w-12 text-red-400" />
          <h3 className="text-lg font-medium text-white">Failed to load system status</h3>
          <p className="text-gray-400 text-sm">{(error as Error).message}</p>
          <button
            onClick={() => refetch()}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
          >
            <RefreshCw className="h-4 w-4" />
            Retry
          </button>
        </div>
      )}

      {status && <StatusContent status={status} />}
    </div>
  )
}
