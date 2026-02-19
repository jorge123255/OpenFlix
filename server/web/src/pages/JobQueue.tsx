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
  Tv,
  Film,
  Trophy,
  Radio,
  Trash2,
  StopCircle,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

const isAbsoluteUrl = (url?: string) => url ? /^https?:\/\//i.test(url) : false

interface DVRJob {
  id: number
  userId: number
  ruleId?: number
  channelId: number
  programId: number
  title: string
  subtitle?: string
  description: string
  startTime: string
  endTime: string
  status: string
  priority: number
  qualityPreset: string
  paddingStart: number
  paddingEnd: number
  retryCount: number
  maxRetries: number
  lastError?: string
  cancelled: boolean
  channelName: string
  channelLogo?: string
  category: string
  episodeNum?: string
  isMovie: boolean
  isSports: boolean
  seriesRecord: boolean
  isDuplicate: boolean
  acceptedDuplicate: boolean
  fileId?: number
  createdAt: string
  updatedAt: string
}

interface JobsResponse {
  jobs: DVRJob[]
  totalCount: number
}

const TOKEN_KEY = 'openflix_token'

function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString()
}

function formatTimeRange(start: string, end: string): string {
  const s = new Date(start)
  const e = new Date(end)
  const dateStr = s.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
  const startTime = s.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })
  const endTime = e.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })
  return `${dateStr}, ${startTime} - ${endTime}`
}

function formatDuration(start: string, end: string): string {
  const diff = new Date(end).getTime() - new Date(start).getTime()
  const minutes = Math.round(diff / 60000)
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const remainingMin = minutes % 60
  return remainingMin > 0 ? `${hours}h ${remainingMin}m` : `${hours}h`
}

const STATUS_CONFIG: Record<string, {
  icon: React.ElementType
  color: string
  bgColor: string
  borderColor: string
  label: string
}> = {
  scheduled: {
    icon: Clock,
    color: 'text-yellow-400',
    bgColor: 'bg-yellow-500/10',
    borderColor: 'border-yellow-500/30',
    label: 'Scheduled',
  },
  pending: {
    icon: Clock,
    color: 'text-yellow-400',
    bgColor: 'bg-yellow-500/10',
    borderColor: 'border-yellow-500/30',
    label: 'Pending',
  },
  recording: {
    icon: Play,
    color: 'text-red-400',
    bgColor: 'bg-red-500/10',
    borderColor: 'border-red-500/30',
    label: 'Recording',
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
  cancelled: {
    icon: Pause,
    color: 'text-gray-400',
    bgColor: 'bg-gray-500/10',
    borderColor: 'border-gray-500/30',
    label: 'Cancelled',
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

function CategoryIcon({ job }: { job: DVRJob }) {
  if (job.isSports) return <Trophy className="h-4 w-4 text-orange-400" />
  if (job.isMovie) return <Film className="h-4 w-4 text-purple-400" />
  if (job.category === 'TVShow') return <Tv className="h-4 w-4 text-blue-400" />
  return <Radio className="h-4 w-4 text-gray-400" />
}

async function fetchJobs(): Promise<JobsResponse> {
  const res = await fetch('/dvr/v2/jobs', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch jobs')
  return res.json()
}

const STATUS_FILTERS = ['all', 'scheduled', 'recording', 'completed', 'failed', 'cancelled'] as const
type StatusFilter = typeof STATUS_FILTERS[number]

export function JobQueuePage() {
  const queryClient = useQueryClient()
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [expandedJob, setExpandedJob] = useState<number | null>(null)

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['jobs'],
    queryFn: fetchJobs,
    refetchInterval: 5000,
  })

  const cancelJob = useMutation({
    mutationFn: async (jobId: number) => {
      const res = await fetch(`/dvr/v2/jobs/${jobId}/cancel`, {
        method: 'POST',
        headers: { 'X-Plex-Token': getToken() },
      })
      if (!res.ok) throw new Error('Failed to cancel job')
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['jobs'] }),
  })

  const deleteJob = useMutation({
    mutationFn: async (jobId: number) => {
      const res = await fetch(`/dvr/v2/jobs/${jobId}`, {
        method: 'DELETE',
        headers: { 'X-Plex-Token': getToken() },
      })
      if (!res.ok) throw new Error('Failed to delete job')
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['jobs'] }),
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
            DVR Jobs
          </h1>
          <p className="text-gray-400 mt-1">
            {jobs.length} job{jobs.length !== 1 ? 's' : ''} total
            {statusCounts.recording ? ` / ${statusCounts.recording} recording` : ''}
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
        {(['scheduled', 'recording', 'completed', 'failed'] as const).map((status) => {
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

      {/* Jobs List */}
      {filteredJobs.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-48 bg-gray-800 rounded-xl">
          <ListTodo className="h-12 w-12 text-gray-600 mb-3" />
          <h3 className="text-lg font-medium text-white mb-1">No jobs</h3>
          <p className="text-gray-400 text-sm">
            {statusFilter !== 'all'
              ? `No ${statusFilter} jobs found`
              : 'The DVR job queue is empty'}
          </p>
        </div>
      ) : (
        <div className="space-y-2">
          {filteredJobs.map((job) => (
            <div key={job.id} className="bg-gray-800 rounded-xl overflow-hidden">
              {/* Job Row */}
              <div
                onClick={() => setExpandedJob(expandedJob === job.id ? null : job.id)}
                className="flex items-center gap-4 p-4 hover:bg-gray-700/30 transition-colors cursor-pointer"
              >
                {/* Channel Logo */}
                <div className="w-10 h-10 rounded-lg bg-gray-700 flex items-center justify-center flex-shrink-0 overflow-hidden">
                  {isAbsoluteUrl(job.channelLogo) ? (
                    <img src={job.channelLogo} alt="" className="w-full h-full object-contain" />
                  ) : (
                    <CategoryIcon job={job} />
                  )}
                </div>

                {/* Title & Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-white font-medium truncate">{job.title}</span>
                    {job.subtitle && (
                      <span className="text-gray-400 text-sm truncate">- {job.subtitle}</span>
                    )}
                  </div>
                  <div className="flex items-center gap-3 text-xs text-gray-500 mt-0.5">
                    <span>{job.channelName}</span>
                    <span>{formatTimeRange(job.startTime, job.endTime)}</span>
                    <span>{formatDuration(job.startTime, job.endTime)}</span>
                  </div>
                </div>

                {/* Status */}
                <StatusBadge status={job.status} />

                {/* Actions */}
                <div className="flex items-center gap-1">
                  {(job.status === 'scheduled' || job.status === 'recording') && (
                    <button
                      onClick={(e) => { e.stopPropagation(); cancelJob.mutate(job.id) }}
                      className="p-1.5 text-gray-400 hover:text-red-400 rounded-lg hover:bg-gray-700 transition-colors"
                      title="Cancel"
                    >
                      <StopCircle className="h-4 w-4" />
                    </button>
                  )}
                  {(job.status === 'completed' || job.status === 'failed' || job.status === 'cancelled') && (
                    <button
                      onClick={(e) => { e.stopPropagation(); deleteJob.mutate(job.id) }}
                      className="p-1.5 text-gray-400 hover:text-red-400 rounded-lg hover:bg-gray-700 transition-colors"
                      title="Delete"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  )}
                </div>
              </div>

              {/* Expanded Details */}
              {expandedJob === job.id && (
                <div className="px-4 pb-4 border-t border-gray-700/50">
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-3 text-xs">
                    <div>
                      <p className="text-gray-500 mb-0.5">Category</p>
                      <p className="text-gray-300 flex items-center gap-1.5">
                        <CategoryIcon job={job} />
                        {job.isMovie ? 'Movie' : job.isSports ? 'Sports' : job.category || 'TV Show'}
                      </p>
                    </div>
                    <div>
                      <p className="text-gray-500 mb-0.5">Quality</p>
                      <p className="text-gray-300">{job.qualityPreset || 'Original'}</p>
                    </div>
                    <div>
                      <p className="text-gray-500 mb-0.5">Priority</p>
                      <p className="text-gray-300">{job.priority}</p>
                    </div>
                    <div>
                      <p className="text-gray-500 mb-0.5">Padding</p>
                      <p className="text-gray-300">
                        {job.paddingStart > 0 ? `${job.paddingStart}m before` : 'None'}
                        {job.paddingEnd > 0 ? ` / ${job.paddingEnd}m after` : ''}
                      </p>
                    </div>
                    {job.episodeNum && (
                      <div>
                        <p className="text-gray-500 mb-0.5">Episode</p>
                        <p className="text-gray-300">{job.episodeNum}</p>
                      </div>
                    )}
                    {job.retryCount > 0 && (
                      <div>
                        <p className="text-gray-500 mb-0.5">Retries</p>
                        <p className="text-gray-300">{job.retryCount} / {job.maxRetries}</p>
                      </div>
                    )}
                    {job.fileId && (
                      <div>
                        <p className="text-gray-500 mb-0.5">File ID</p>
                        <p className="text-gray-300">#{job.fileId}</p>
                      </div>
                    )}
                    <div>
                      <p className="text-gray-500 mb-0.5">Created</p>
                      <p className="text-gray-300">{formatDate(job.createdAt)}</p>
                    </div>
                  </div>
                  {job.description && (
                    <div className="mt-3">
                      <p className="text-gray-500 text-xs mb-0.5">Description</p>
                      <p className="text-gray-400 text-xs">{job.description}</p>
                    </div>
                  )}
                  {job.lastError && (
                    <div className="mt-3 p-2 bg-red-900/30 border border-red-500/30 rounded-lg">
                      <p className="text-red-400 text-xs">{job.lastError}</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
