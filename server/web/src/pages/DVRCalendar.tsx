import { useState, useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  Loader,
  ChevronLeft,
  ChevronRight,
  Clock,
  CircleDot,
  CheckCircle,
  Calendar,
} from 'lucide-react'
import { api } from '../api/client'
import type { DVRCalendarItem } from '../api/client'

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

function getMonday(date: Date): Date {
  const d = new Date(date)
  // Get to Sunday of the week
  const day = d.getDay()
  d.setDate(d.getDate() - day)
  d.setHours(0, 0, 0, 0)
  return d
}

function formatWeekRange(startStr: string, endStr: string): string {
  const start = new Date(startStr + 'T00:00:00')
  const end = new Date(endStr + 'T00:00:00')
  end.setDate(end.getDate() - 1) // endStr is exclusive
  const opts: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric' }
  if (start.getFullYear() !== end.getFullYear()) {
    return `${start.toLocaleDateString([], { ...opts, year: 'numeric' })} - ${end.toLocaleDateString([], { ...opts, year: 'numeric' })}`
  }
  if (start.getMonth() === end.getMonth()) {
    return `${start.toLocaleDateString([], { month: 'short', day: 'numeric' })} - ${end.getDate()}, ${start.getFullYear()}`
  }
  return `${start.toLocaleDateString([], opts)} - ${end.toLocaleDateString([], opts)}, ${start.getFullYear()}`
}

function formatTime(dateStr: string): string {
  return new Date(dateStr).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
}

function isToday(dateStr: string): boolean {
  const date = new Date(dateStr + 'T00:00:00')
  const today = new Date()
  return date.toDateString() === today.toDateString()
}

const statusColors: Record<string, { bg: string; border: string; text: string; dot: string }> = {
  scheduled: {
    bg: 'bg-blue-500/10',
    border: 'border-blue-500/30',
    text: 'text-blue-300',
    dot: 'bg-blue-400',
  },
  recording: {
    bg: 'bg-red-500/10',
    border: 'border-red-500/30',
    text: 'text-red-300',
    dot: 'bg-red-400',
  },
  completed: {
    bg: 'bg-green-500/10',
    border: 'border-green-500/30',
    text: 'text-green-300',
    dot: 'bg-green-400',
  },
}

const StatusIcons: Record<string, typeof Clock> = {
  scheduled: Clock,
  recording: CircleDot,
  completed: CheckCircle,
}

export function DVRCalendarPage() {
  const [weekOffset, setWeekOffset] = useState(0)

  // Calculate the anchor date for the week
  const anchorDate = useMemo(() => {
    const today = new Date()
    const sunday = getMonday(today)
    sunday.setDate(sunday.getDate() + weekOffset * 7)
    return sunday.toISOString().split('T')[0]
  }, [weekOffset])

  const { data, isLoading } = useQuery({
    queryKey: ['dvrCalendar', anchorDate],
    queryFn: () => api.getDVRCalendar(anchorDate),
    refetchInterval: 60000,
  })

  // Build the 7 day columns
  const days = useMemo(() => {
    if (!data) return []
    const start = new Date(data.weekStart + 'T00:00:00')
    const result: { date: string; dayName: string; dateLabel: string }[] = []
    for (let i = 0; i < 7; i++) {
      const d = new Date(start)
      d.setDate(start.getDate() + i)
      const dateStr = d.toISOString().split('T')[0]
      result.push({
        date: dateStr,
        dayName: DAY_NAMES[d.getDay()],
        dateLabel: d.toLocaleDateString([], { month: 'short', day: 'numeric' }),
      })
    }
    return result
  }, [data])

  // Group items by day
  const itemsByDay = useMemo(() => {
    if (!data?.items) return new Map<string, DVRCalendarItem[]>()
    const map = new Map<string, DVRCalendarItem[]>()
    for (const item of data.items) {
      const existing = map.get(item.day) || []
      existing.push(item)
      map.set(item.day, existing)
    }
    return map
  }, [data])

  const goToPrevWeek = () => setWeekOffset((prev) => prev - 1)
  const goToNextWeek = () => setWeekOffset((prev) => prev + 1)
  const goToThisWeek = () => setWeekOffset(0)

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">DVR Calendar</h1>
        <p className="text-gray-400 mt-1">Week view of scheduled recordings</p>
      </div>

      {/* Week Navigation */}
      <div className="mb-6 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <button
            onClick={goToPrevWeek}
            className="p-2 bg-gray-800 hover:bg-gray-700 text-gray-300 rounded-lg transition-colors"
            title="Previous week"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            onClick={goToNextWeek}
            className="p-2 bg-gray-800 hover:bg-gray-700 text-gray-300 rounded-lg transition-colors"
            title="Next week"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
          {weekOffset !== 0 && (
            <button
              onClick={goToThisWeek}
              className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-lg transition-colors"
            >
              This Week
            </button>
          )}
        </div>

        {data && (
          <div className="text-lg font-semibold text-white">
            {formatWeekRange(data.weekStart, data.weekEnd)}
          </div>
        )}

        {/* Legend */}
        <div className="flex items-center gap-4 text-sm">
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-blue-400" />
            <span className="text-gray-400">Scheduled</span>
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-red-400" />
            <span className="text-gray-400">Recording</span>
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-green-400" />
            <span className="text-gray-400">Completed</span>
          </span>
        </div>
      </div>

      {/* Calendar Grid */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      ) : days.length > 0 ? (
        <div className="grid grid-cols-7 gap-2">
          {days.map((day) => {
            const dayItems = itemsByDay.get(day.date) || []
            const today = isToday(day.date)

            return (
              <div
                key={day.date}
                className={`bg-gray-800 rounded-xl min-h-[240px] flex flex-col ${
                  today ? 'ring-2 ring-indigo-500/60' : ''
                }`}
              >
                {/* Day Header */}
                <div
                  className={`text-center px-3 py-2.5 border-b border-gray-700 rounded-t-xl ${
                    today
                      ? 'bg-indigo-600/20'
                      : 'bg-gray-800'
                  }`}
                >
                  <div
                    className={`text-sm font-semibold ${
                      today ? 'text-indigo-400' : 'text-gray-300'
                    }`}
                  >
                    {today ? 'Today' : day.dayName}
                  </div>
                  <div className="text-xs text-gray-500">{day.dateLabel}</div>
                </div>

                {/* Day Content */}
                <div className="flex-1 p-2 space-y-1.5 overflow-y-auto">
                  {dayItems.length > 0 ? (
                    dayItems.map((item) => {
                      const colors = statusColors[item.status] || statusColors.scheduled
                      const StatusIcon = StatusIcons[item.status] || Clock

                      return (
                        <div
                          key={item.id}
                          className={`p-2 rounded-lg border ${colors.bg} ${colors.border} cursor-default`}
                          title={`${item.title}${item.channelName ? ' - ' + item.channelName : ''}\n${formatTime(item.startTime)} - ${formatTime(item.endTime)}`}
                        >
                          <div className={`text-xs font-medium truncate ${colors.text}`}>
                            {item.title}
                          </div>
                          <div className="flex items-center gap-1 mt-0.5 text-gray-400">
                            <StatusIcon className={`w-3 h-3 ${item.status === 'recording' ? 'animate-pulse text-red-400' : ''}`} />
                            <span className="text-[11px]">
                              {formatTime(item.startTime)}
                            </span>
                          </div>
                          {item.channelName && (
                            <div className="text-[11px] text-gray-500 truncate mt-0.5">
                              {item.channelName}
                            </div>
                          )}
                        </div>
                      )
                    })
                  ) : (
                    <div className="flex items-center justify-center h-full text-gray-600 text-xs py-8">
                      No recordings
                    </div>
                  )}
                </div>

                {/* Day count */}
                {dayItems.length > 0 && (
                  <div className="px-2 pb-2">
                    <div className="text-[11px] text-gray-500 text-center">
                      {dayItems.length} rec{dayItems.length !== 1 ? 's' : ''}
                    </div>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      ) : (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <Calendar className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No data</h3>
          <p className="text-gray-400">Calendar data is not available</p>
        </div>
      )}
    </div>
  )
}
