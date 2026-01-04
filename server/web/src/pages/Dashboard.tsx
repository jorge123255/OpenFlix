import { FolderOpen, Tv, Video, Activity, HardDrive, Server, Users, Clock, Cpu, FileText } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'
import { useLibraries } from '../hooks/useLibraries'
import { useM3USources } from '../hooks/useLiveTV'
import { useRecordings } from '../hooks/useDVR'

function useServerStatus() {
  return useQuery({
    queryKey: ['serverStatus'],
    queryFn: () => api.getServerStatus(),
    refetchInterval: 10000, // Refresh every 10 seconds
  })
}

function StatCard({ title, value, icon: Icon, color, subtitle }: {
  title: string
  value: string | number
  icon: React.ElementType
  color: string
  subtitle?: string
}) {
  return (
    <div className="bg-gray-800 rounded-xl p-6">
      <div className="flex items-center gap-4">
        <div className={`p-3 rounded-lg ${color}`}>
          <Icon className="h-6 w-6 text-white" />
        </div>
        <div>
          <p className="text-sm text-gray-400">{title}</p>
          <p className="text-2xl font-bold text-white">{value}</p>
          {subtitle && <p className="text-xs text-gray-500">{subtitle}</p>}
        </div>
      </div>
    </div>
  )
}

export function DashboardPage() {
  const { data: status } = useServerStatus()
  const { data: libraries } = useLibraries()
  const { data: m3uSources } = useM3USources()
  const { data: recordings } = useRecordings()

  const totalChannels = m3uSources?.reduce((acc, s) => acc + (s.channelCount || 0), 0) || 0
  const scheduledRecordings = recordings?.filter(r => r.status === 'scheduled').length || 0
  const completedRecordings = recordings?.filter(r => r.status === 'completed').length || 0

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">Dashboard</h1>
        <p className="text-gray-400 mt-1">Overview of your OpenFlix server</p>
      </div>

      {/* Server Status Bar */}
      {status && (
        <div className="bg-gray-800 rounded-xl p-4 mb-6 flex flex-wrap items-center gap-6 text-sm">
          <div className="flex items-center gap-2">
            <Server className="h-4 w-4 text-green-400" />
            <span className="text-gray-300">{status.server.name} v{status.server.version}</span>
          </div>
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-blue-400" />
            <span className="text-gray-300">Uptime: {status.server.uptime}</span>
          </div>
          <div className="flex items-center gap-2">
            <Users className="h-4 w-4 text-purple-400" />
            <span className="text-gray-300">{status.sessions.active} active session{status.sessions.active !== 1 ? 's' : ''}</span>
          </div>
          <div className="flex items-center gap-2">
            <Cpu className="h-4 w-4 text-orange-400" />
            <span className="text-gray-300">{status.system.memAllocMB} MB</span>
          </div>
          <div className="flex items-center gap-2">
            <FileText className="h-4 w-4 text-yellow-400" />
            <span className="text-gray-300">Log: {status.logging.level}</span>
          </div>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          title="Libraries"
          value={status?.libraries.count || libraries?.length || 0}
          icon={FolderOpen}
          color="bg-blue-600"
          subtitle={status ? `${status.libraries.movies} movies, ${status.libraries.shows} shows` : undefined}
        />
        <StatCard
          title="Live TV Channels"
          value={status?.livetv.channels || totalChannels}
          icon={Tv}
          color="bg-green-600"
          subtitle={status?.livetv.timeshiftEnabled ? `${status.livetv.timeshiftChannels} buffering` : undefined}
        />
        <StatCard
          title="Scheduled Recordings"
          value={status?.dvr.scheduled || scheduledRecordings}
          icon={Video}
          color="bg-orange-600"
          subtitle={status?.dvr.recording ? `${status.dvr.recording} recording now` : undefined}
        />
        <StatCard
          title="Completed Recordings"
          value={status?.dvr.completed || completedRecordings}
          icon={HardDrive}
          color="bg-purple-600"
          subtitle={status?.dvr.commercialDetect ? 'Commercial detect enabled' : undefined}
        />
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Libraries */}
        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <FolderOpen className="h-5 w-5" />
            Libraries
          </h2>
          {libraries?.length ? (
            <div className="space-y-3">
              {libraries.map((lib) => (
                <div
                  key={lib.id}
                  className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg"
                >
                  <div>
                    <p className="font-medium text-white">{lib.title}</p>
                    <p className="text-sm text-gray-400 capitalize">{lib.type}</p>
                  </div>
                  <span className="text-xs text-gray-500">
                    {lib.paths?.length || 0} paths
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-400 text-sm">No libraries configured</p>
          )}
        </div>

        {/* Live TV Sources */}
        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <Tv className="h-5 w-5" />
            Live TV Sources
          </h2>
          {m3uSources?.length ? (
            <div className="space-y-3">
              {m3uSources.map((source) => (
                <div
                  key={source.id}
                  className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg"
                >
                  <div>
                    <p className="font-medium text-white">{source.name}</p>
                    <p className="text-sm text-gray-400">{source.channelCount} channels</p>
                  </div>
                  <span className="text-xs text-gray-500">
                    {source.lastRefresh ? new Date(source.lastRefresh).toLocaleDateString() : 'Never refreshed'}
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-400 text-sm">No M3U sources configured</p>
          )}
        </div>

        {/* Upcoming Recordings */}
        <div className="bg-gray-800 rounded-xl p-6 lg:col-span-2">
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Upcoming Recordings
          </h2>
          {recordings?.filter(r => r.status === 'scheduled').length ? (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="text-left text-sm text-gray-400 border-b border-gray-700">
                    <th className="pb-3 font-medium">Title</th>
                    <th className="pb-3 font-medium">Channel</th>
                    <th className="pb-3 font-medium">Start Time</th>
                    <th className="pb-3 font-medium">Duration</th>
                  </tr>
                </thead>
                <tbody className="text-sm">
                  {recordings
                    .filter(r => r.status === 'scheduled')
                    .slice(0, 5)
                    .map((rec) => (
                      <tr key={rec.id} className="border-b border-gray-700/50">
                        <td className="py-3 text-white">{rec.title}</td>
                        <td className="py-3 text-gray-300">{rec.channelName}</td>
                        <td className="py-3 text-gray-300">
                          {new Date(rec.startTime).toLocaleString()}
                        </td>
                        <td className="py-3 text-gray-300">{rec.duration} min</td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          ) : (
            <p className="text-gray-400 text-sm">No upcoming recordings</p>
          )}
        </div>
      </div>
    </div>
  )
}
