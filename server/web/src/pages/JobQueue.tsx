import { useState } from 'react'
import {
  ListTodo,
  RefreshCw,
  AlertTriangle,
  Loader,
  Clock,
  Play,
  CheckCircle,
  XCircle,
  Pause,
  Filter,
} from 'lucide-react'
import { useQuery } from '@tanstack/react-query'

interface Job {
  id: string
  type: string
  status: string
  priority: number
  payload: string
  result?: string
  error?: string
  createdAt: string
  startedAt?: string
  completedAt?: string
}

interface JobsResponse {
  jobs: Job[]
  total: number
}

const TOKEN_KEY = 'openflix_token'

function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString()
}

function formatDuration(start?: string, end?: string): string {
  if (!start) return '--'
  const startTime = new Date(start).getTime()
  const endTime = end ? new Date(end).getTime() : Date.now()
  const diff = endTime - startTime
  const seconds = Math.floor(diff / 1000)
  if (seconds < 60) return `${seconds}s`
  const minutes = Math.floor(seconds / 60)
  const remainingSec = seconds % 60
  if (minutes < 60) return `${minutes}m ${remainingSec}s`
  const hours = Math.floor(minutes / 60)
  const remainingMin = minutes % 60
  return `${hours}h ${remainingMin}m`
}

const STATUS_CONFIG: Record<string, {
  icon: React.ElementType
  color: string
  bgColor: string
  borderColor: string
  label: string
}> = {
  pending: {
    icon: Clock,
    color: 'text-yellow-400',
    bgColor: 'bg-yellow-500/10',
    borderColor: 'border-yellow-500/30',
    label: 'Pending',
  },
  running: {
    icon: Play,
    color: 'text-blue-400',
    bgColor: 'bg-blue-500/10',
    borderColor: 'border-blue-500/30',
    label: 'Running',
  },
  completed: {
    icon: CheckCircle,
    color: 'text-green-400',
    bgColor: 'bg-green-500/10',
    borderColor: 'border-green-500/30',
    label: 'Completed',
  },
  failed: {
    icon: XCircle,
    color: 'text-red-400',
    bgColor: 'bg-red-500/10',
    borderColor: 'border-red-500/30',
    label: 'Failed',
  },
  paused: {
    icon: Pause,
    color: 'text-gray-400',
    bgColor: 'bg-gray-500/10',
    borderColor: 'border-gray-500/30',
    label: 'Paused',
  },
}

function StatusBadge({ status }: { status: string }) {
  const config = STATUS_CONFIG[status] || STATUS_CONFIG.pending
  const Icon = config.icon
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 ${config.bgColor} ${config.color} border ${config.borderColor} rounded-full text-xs font-medium`}>
      <Icon className="h-3 w-3" />
      {config.label}
    </span>
  )
}

function PriorityBadge({ priority }: { priority: number }) {
  let color = 'text-gray-400 bg-gray-500/10'
  let label = 'Normal'
  if (priority >= 8) {
    color = 'text-red-400 bg-red-500/10'
    label = 'Critical'
  } else if (priority >= 5) {
    color = 'text-orange-400 bg-orange-500/10'
    label = 'High'
  } else if (priority >= 3) {
    color = 'text-yellow-400 bg-yellow-500/10'
    label = 'Medium'
  } else if (priority <= 1) {
    color = 'text-gray-500 bg-gray-500/10'
    label = 'Low'
  }
  return (
    <span className={`px-2 py-0.5 ${color} rounded text-xs`}>
      {label}
    </span>
  )
}

async function fetchJobs(): Promise<JobsResponse> {
  const res = await fetch('/dvr/v2/jobs', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch jobs')
  return res.json()
}

const STATUS_FILTERS = ['all', 'pending', 'running', 'completed', 'failed'] as const
type StatusFilter = typeof STATUS_FILTERS[number]

export function JobQueuePage() {
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [expandedJob, setExpandedJob] = useState<string | null>(null)

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['jobs'],
    queryFn: fetchJobs,
    refetchInterval: 5000,
  })

  const jobs = data?.jobs || []
  const filteredJobs = statusFilter === 'all'
    ? jobs
    : jobs.filter((job) => job.status === statusFilter)

  const statusCounts = jobs.reduce<Record<string, number>>((acc, job) => {
    acc[job.status] = (acc[job.status] || 0) + 1
    return acc
  }, {})

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
        <h3 className="text-lg font-medium text-white">Failed to load jobs</h3>
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
            <ListTodo className="h-7 w-7 text-indigo-400" />
            Job Queue
          </h1>
          <p className="text-gray-400 mt-1">
            {jobs.length} job{jobs.length !== 1 ? 's' : ''} total
            {statusCounts.running ? ` / ${statusCounts.running} running` : ''}
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

      {/* Status Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        {(['pending', 'running', 'completed', 'failed'] as const).map((status) => {
          const config = STATUS_CONFIG[status]
          const Icon = config.icon
          return (
            <button
              key={status}
              onClick={() => setStatusFilter(statusFilter === status ? 'all' : status)}
              className={`bg-gray-800 rounded-xl p-4 text-left transition-colors ${
                statusFilter === status ? 'ring-2 ring-indigo-500' : 'hover:bg-gray-750'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className={`p-2 rounded-lg ${config.bgColor}`}>
                  <Icon className={`h-5 w-5 ${config.color}`} />
                </div>
                <div>
                  <p className="text-2xl font-bold text-white">{statusCounts[status] || 0}</p>
                  <p className="text-xs text-gray-400">{config.label}</p>
                </div>
              </div>
            </button>
          )
        })}
      </div>

      {/* Filter Bar */}
      <div className="flex items-center gap-2 mb-4">
        <Filter className="h-4 w-4 text-gray-500" />
        <div className="flex gap-1">
          {STATUS_FILTERS.map((filter) => (
            <button
              key={filter}
              onClick={() => setStatusFilter(filter)}
              className={`px-3 py-1.5 rounded-lg text-xs capitalize transition-colors ${
                statusFilter === filter
                  ? 'bg-indigo-600 text-white'
                  : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
              }`}
            >
              {filter} {filter !== 'all' && statusCounts[filter] ? `(${statusCounts[filter]})` : ''}
            </button>
          ))}
        </div>
      </div>

      {/* Jobs Table */}
      {filteredJobs.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-48 bg-gray-800 rounded-xl">
          <ListTodo className="h-12 w-12 text-gray-600 mb-3" />
          <h3 className="text-lg font-medium text-white mb-1">No jobs</h3>
          <p className="text-gray-400 text-sm">
            {statusFilter !== 'all'
              ? `No ${statusFilter} jobs found`
              : 'The job queue is empty'}
          </p>
        </div>
      ) : (
        <div className="bg-gray-800 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="text-left text-sm text-gray-400 border-b border-gray-700">
                  <th className="px-6 py-4 font-medium">Job ID</th>
                  <th className="px-6 py-4 font-medium">Type</th>
                  <th className="px-6 py-4 font-medium">Status</th>
                  <th className="px-6 py-4 font-medium">Priority</th>
                  <th className="px-6 py-4 font-medium">Created</th>
                  <th className="px-6 py-4 font-medium">Duration</th>
                </tr>
              </thead>
              <tbody className="text-sm">
                {filteredJobs.map((job) => (
                  <>
                    <tr
                      key={job.id}
                      onClick={() => setExpandedJob(expandedJob === job.id ? null : job.id)}
                      className="border-b border-gray-700/50 hover:bg-gray-700/30 transition-colors cursor-pointer"
                    >
                      <td className="px-6 py-4">
                        <span className="text-gray-300 font-mono text-xs">{job.id}</span>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-white font-medium">
                          {job.type.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <StatusBadge status={job.status} />
                      </td>
                      <td className="px-6 py-4">
                        <PriorityBadge priority={job.priority} />
                      </td>
                      <td className="px-6 py-4 text-gray-400 text-xs">
                        {formatDate(job.createdAt)}
                      </td>
                      <td className="px-6 py-4 text-gray-400 text-xs">
                        {formatDuration(job.startedAt, job.completedAt)}
                      </td>
                    </tr>
                    {/* Expanded Details */}
                    {expandedJob === job.id && (
                      <tr key={`${job.id}-details`}>
                        <td colSpan={6} className="px-6 py-4 bg-gray-900/50">
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                            <div>
                              <p className="text-gray-500 mb-1">Payload</p>
                              <pre className="text-gray-300 bg-gray-900 p-3 rounded-lg overflow-x-auto font-mono">
                                {(() => {
                                  try {
                                    return JSON.stringify(JSON.parse(job.payload), null, 2)
                                  } catch {
                                    return job.payload
                                  }
                                })()}
                              </pre>
                            </div>
                            {job.result && (
                              <div>
                                <p className="text-gray-500 mb-1">Result</p>
                                <pre className="text-green-400 bg-gray-900 p-3 rounded-lg overflow-x-auto font-mono">
                                  {(() => {
                                    try {
                                      return JSON.stringify(JSON.parse(job.result), null, 2)
                                    } catch {
                                      return job.result
                                    }
                                  })()}
                                </pre>
                              </div>
                            )}
                            {job.error && (
                              <div>
                                <p className="text-gray-500 mb-1">Error</p>
                                <pre className="text-red-400 bg-gray-900 p-3 rounded-lg overflow-x-auto font-mono">
                                  {job.error}
                                </pre>
                              </div>
                            )}
                            <div className="md:col-span-2">
                              <div className="flex gap-6 text-gray-400">
                                {job.startedAt && (
                                  <span>Started: {formatDate(job.startedAt)}</span>
                                )}
                                {job.completedAt && (
                                  <span>Completed: {formatDate(job.completedAt)}</span>
                                )}
                              </div>
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
