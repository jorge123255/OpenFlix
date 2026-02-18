import { useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Loader,
  Clock,
  CircleDot,
  AlertTriangle,
  Tv,
  Calendar,
  Timer,
  Trash2,
  ArrowUpDown,
  Video,
} from 'lucide-react'
import { api } from '../api/client'
import type { DVRScheduleItem } from '../api/client'

function formatTimeRange(start: string, end: string): string {
  const startDate = new Date(start)
  const endDate = new Date(end)
  const timeOptions: Intl.DateTimeFormatOptions = { hour: 'numeric', minute: '2-digit' }
  return `${startDate.toLocaleTimeString([], timeOptions)} - ${endDate.toLocaleTimeString([], timeOptions)}`
}

function formatDayHeader(dateStr: string): string {
  const date = new Date(dateStr + 'T00:00:00')
  const today = new Date()
  const tomorrow = new Date(today)
  tomorrow.setDate(tomorrow.getDate() + 1)

  if (date.toDateString() === today.toDateString()) {
    return 'Today'
  } else if (date.toDateString() === tomorrow.toDateString()) {
    return 'Tomorrow'
  } else {
    return date.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' })
  }
}

function formatDuration(start: string, end: string): string {
  const ms = new Date(end).getTime() - new Date(start).getTime()
  const minutes = Math.round(ms / 60000)
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`
  }
  return `${minutes}m`
}

const statusConfig = {
  scheduled: {
    icon: Clock,
    color: 'text-blue-400',
    bgColor: 'bg-blue-500/10',
    borderColor: 'border-blue-500/30',
    label: 'Scheduled',
  },
  recording: {
    icon: CircleDot,
    color: 'text-red-400 animate-pulse',
    bgColor: 'bg-red-500/10',
    borderColor: 'border-red-500/30',
    label: 'Recording',
  },
  conflict: {
    icon: AlertTriangle,
    color: 'text-amber-400',
    bgColor: 'bg-amber-500/10',
    borderColor: 'border-amber-500/30',
    label: 'Conflict',
  },
}

export function DVRSchedulePage() {
  const queryClient = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['dvrSchedule'],
    queryFn: () => api.getDVRSchedule(),
    refetchInterval: 30000,
  })

  const deleteRecording = useMutation({
    mutationFn: (id: number) => api.deleteRecording(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dvrSchedule'] })
      queryClient.invalidateQueries({ queryKey: ['recordings'] })
    },
  })

  // Group schedule items by day
  const groupedByDay = useMemo(() => {
    if (!data?.schedule) return new Map<string, DVRScheduleItem[]>()

    const groups = new Map<string, DVRScheduleItem[]>()
    for (const item of data.schedule) {
      const existing = groups.get(item.day) || []
      existing.push(item)
      groups.set(item.day, existing)
    }
    return groups
  }, [data])

  const handleCancel = (id: number, title: string) => {
    if (!confirm(`Cancel scheduled recording "${title}"?`)) return
    deleteRecording.mutate(id)
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">DVR Schedule</h1>
        <p className="text-gray-400 mt-1">
          Upcoming scheduled recordings
          {data?.totalCount ? ` (${data.totalCount})` : ''}
        </p>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      ) : data?.schedule && data.schedule.length > 0 ? (
        <div className="space-y-8">
          {Array.from(groupedByDay.entries()).map(([day, items]) => (
            <div key={day}>
              {/* Day Header */}
              <div className="flex items-center gap-3 mb-4">
                <Calendar className="w-5 h-5 text-indigo-400" />
                <h2 className="text-lg font-semibold text-white">
                  {formatDayHeader(day)}
                </h2>
                <span className="text-sm text-gray-500">
                  {items.length} recording{items.length !== 1 ? 's' : ''}
                </span>
              </div>

              {/* Schedule Items */}
              <div className="space-y-2">
                {items.map((item) => {
                  const config = statusConfig[item.status] || statusConfig.scheduled
                  const StatusIcon = config.icon

                  return (
                    <div
                      key={item.id}
                      className={`bg-gray-800 rounded-xl border ${config.borderColor} hover:border-gray-600 transition-colors`}
                    >
                      <div className="p-4 flex items-center gap-4">
                        {/* Thumbnail */}
                        <div className="flex-shrink-0 w-12 h-12 rounded-lg overflow-hidden bg-gray-700 flex items-center justify-center">
                          {item.thumb ? (
                            <img
                              src={item.thumb}
                              alt={item.title}
                              className="w-full h-full object-cover"
                            />
                          ) : item.channelLogo ? (
                            <img
                              src={item.channelLogo}
                              alt={item.channelName || ''}
                              className="w-full h-full object-contain p-1"
                            />
                          ) : (
                            <Video className="w-5 h-5 text-gray-500" />
                          )}
                        </div>

                        {/* Content */}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <h3 className="font-medium text-white truncate">
                              {item.title}
                            </h3>
                            {item.episodeNum && (
                              <span className="text-sm text-gray-400 flex-shrink-0">
                                {item.episodeNum}
                              </span>
                            )}
                          </div>
                          <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1 text-sm text-gray-400">
                            {item.channelName && (
                              <span className="flex items-center gap-1">
                                <Tv className="w-3.5 h-3.5" />
                                {item.channelName}
                              </span>
                            )}
                            <span className="flex items-center gap-1">
                              <Clock className="w-3.5 h-3.5" />
                              {formatTimeRange(item.startTime, item.endTime)}
                            </span>
                            <span className="flex items-center gap-1">
                              <Timer className="w-3.5 h-3.5" />
                              {formatDuration(item.startTime, item.endTime)}
                            </span>
                          </div>
                        </div>

                        {/* Status Badge */}
                        <div className="flex-shrink-0 flex items-center gap-3">
                          <span
                            className={`flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded-full ${config.bgColor} ${config.color}`}
                          >
                            <StatusIcon className="w-3.5 h-3.5" />
                            {config.label}
                          </span>

                          {/* Priority indicator */}
                          {item.priority > 0 && (
                            <span
                              className="flex items-center gap-1 text-xs text-gray-500"
                              title={`Priority: ${item.priority}`}
                            >
                              <ArrowUpDown className="w-3 h-3" />
                              {item.priority}
                            </span>
                          )}

                          {/* Cancel Button */}
                          {item.status === 'scheduled' && (
                            <button
                              onClick={() => handleCancel(item.id, item.title)}
                              disabled={deleteRecording.isPending}
                              className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg transition-colors"
                              title="Cancel recording"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <Calendar className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No upcoming recordings</h3>
          <p className="text-gray-400">
            Schedule recordings from On Later or the TV Guide
          </p>
        </div>
      )}
    </div>
  )
}
