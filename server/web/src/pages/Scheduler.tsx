import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Clock, Play, CheckCircle, XCircle, AlertTriangle, RefreshCw, Pause, Settings } from 'lucide-react'
import { api } from '../api/client'

interface ScheduledTask {
  id: string
  name: string
  description: string
  schedule: string
  enabled: boolean
  running: boolean
  lastRun?: string
  lastDuration?: number
  lastError?: string
  nextRun?: string
  runCount: number
  failCount: number
  timeout: number
}

interface TaskRun {
  taskId: string
  taskName: string
  startTime: string
  endTime: string
  duration: number
  success: boolean
  error?: string
}

export function SchedulerPage() {
  const queryClient = useQueryClient()
  const [editingTask, setEditingTask] = useState<string | null>(null)
  const [editSchedule, setEditSchedule] = useState('')
  const [activeTab, setActiveTab] = useState<'tasks' | 'history'>('tasks')

  const { data: tasks, isLoading } = useQuery({
    queryKey: ['schedulerTasks'],
    queryFn: async () => {
      const res = await api.client.get('/api/scheduler/tasks')
      return (res.data?.tasks || []) as ScheduledTask[]
    },
    refetchInterval: 5000,
  })

  const { data: history } = useQuery({
    queryKey: ['schedulerHistory'],
    queryFn: async () => {
      const res = await api.client.get('/api/scheduler/history', { params: { limit: 50 } })
      return (res.data?.history || []) as TaskRun[]
    },
    enabled: activeTab === 'history',
    refetchInterval: 10000,
  })

  const triggerTask = useMutation({
    mutationFn: async (id: string) => {
      await api.client.post(`/api/scheduler/tasks/${id}/run`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schedulerTasks'] })
    },
  })

  const updateTask = useMutation({
    mutationFn: async ({ id, ...data }: { id: string; schedule?: string; enabled?: boolean; timeout?: number }) => {
      await api.client.put(`/api/scheduler/tasks/${id}`, data)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schedulerTasks'] })
      setEditingTask(null)
    },
  })

  const formatDuration = (ms: number) => {
    if (ms < 1000) return `${ms}ms`
    if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`
    return `${(ms / 60000).toFixed(1)}m`
  }

  const formatNextRun = (next?: string) => {
    if (!next) return 'N/A'
    const d = new Date(next)
    const now = new Date()
    const diff = d.getTime() - now.getTime()
    if (diff < 0) return 'overdue'
    if (diff < 60000) return 'in < 1m'
    if (diff < 3600000) return `in ${Math.round(diff / 60000)}m`
    if (diff < 86400000) return `in ${Math.round(diff / 3600000)}h`
    return d.toLocaleDateString()
  }

  const getStatusBadge = (task: ScheduledTask) => {
    if (task.running) {
      return <span className="flex items-center gap-1 text-xs px-2 py-0.5 bg-blue-500/20 text-blue-400 rounded-full"><RefreshCw className="h-3 w-3 animate-spin" />Running</span>
    }
    if (!task.enabled) {
      return <span className="flex items-center gap-1 text-xs px-2 py-0.5 bg-gray-500/20 text-gray-400 rounded-full"><Pause className="h-3 w-3" />Disabled</span>
    }
    if (task.lastError) {
      return <span className="flex items-center gap-1 text-xs px-2 py-0.5 bg-red-500/20 text-red-400 rounded-full"><XCircle className="h-3 w-3" />Error</span>
    }
    return <span className="flex items-center gap-1 text-xs px-2 py-0.5 bg-green-500/20 text-green-400 rounded-full"><CheckCircle className="h-3 w-3" />OK</span>
  }

  if (isLoading) return <div className="text-gray-400">Loading...</div>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Scheduled Tasks</h1>
          <p className="text-gray-400 mt-1">Manage background tasks and view execution history</p>
        </div>
        <button
          onClick={() => queryClient.invalidateQueries({ queryKey: ['schedulerTasks'] })}
          className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
        >
          <RefreshCw className="h-4 w-4" /> Refresh
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-gray-800 rounded-lg p-1 w-fit">
        <button
          onClick={() => setActiveTab('tasks')}
          className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'tasks' ? 'bg-indigo-600 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          <Clock className="h-4 w-4" /> Tasks
        </button>
        <button
          onClick={() => setActiveTab('history')}
          className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'history' ? 'bg-indigo-600 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          <CheckCircle className="h-4 w-4" /> History
        </button>
      </div>

      {activeTab === 'tasks' ? (
        <div className="space-y-3">
          {!tasks || tasks.length === 0 ? (
            <div className="bg-gray-800 rounded-xl p-12 text-center">
              <Clock className="h-12 w-12 text-gray-600 mx-auto mb-3" />
              <p className="text-gray-500">No scheduled tasks configured</p>
            </div>
          ) : (
            tasks.map(task => (
              <div key={task.id} className="bg-gray-800 rounded-xl p-5">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-1">
                      <h3 className="text-white font-semibold">{task.name}</h3>
                      {getStatusBadge(task)}
                    </div>
                    <p className="text-gray-400 text-sm">{task.description}</p>
                    <div className="flex items-center gap-4 mt-3 text-xs text-gray-500">
                      <span className="font-mono bg-gray-700/50 px-2 py-0.5 rounded">{task.schedule}</span>
                      <span>Next: {formatNextRun(task.nextRun)}</span>
                      {task.lastRun && <span>Last: {new Date(task.lastRun).toLocaleString()}</span>}
                      {task.lastDuration !== undefined && task.lastDuration > 0 && <span>Duration: {formatDuration(task.lastDuration)}</span>}
                      <span>Runs: {task.runCount} ({task.failCount} failed)</span>
                    </div>
                    {task.lastError && (
                      <div className="mt-2 flex items-start gap-2 text-xs text-red-400 bg-red-500/10 rounded p-2">
                        <AlertTriangle className="h-3 w-3 flex-shrink-0 mt-0.5" />
                        <span>{task.lastError}</span>
                      </div>
                    )}

                    {/* Edit schedule inline */}
                    {editingTask === task.id && (
                      <div className="mt-3 flex items-center gap-3">
                        <input
                          type="text"
                          value={editSchedule}
                          onChange={e => setEditSchedule(e.target.value)}
                          placeholder="*/5 * * * * (cron)"
                          className="px-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500"
                        />
                        <button
                          onClick={() => updateTask.mutate({ id: task.id, schedule: editSchedule })}
                          className="px-3 py-1.5 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
                        >
                          Save
                        </button>
                        <button
                          onClick={() => setEditingTask(null)}
                          className="px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
                        >
                          Cancel
                        </button>
                      </div>
                    )}
                  </div>
                  <div className="flex items-center gap-2 ml-4">
                    <button
                      onClick={() => {
                        setEditSchedule(task.schedule)
                        setEditingTask(editingTask === task.id ? null : task.id)
                      }}
                      className="p-2 text-gray-400 hover:text-white transition-colors"
                      title="Edit schedule"
                    >
                      <Settings className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => updateTask.mutate({ id: task.id, enabled: !task.enabled })}
                      className={`p-2 transition-colors ${task.enabled ? 'text-green-400 hover:text-green-300' : 'text-gray-500 hover:text-gray-400'}`}
                      title={task.enabled ? 'Disable' : 'Enable'}
                    >
                      {task.enabled ? <CheckCircle className="h-4 w-4" /> : <Pause className="h-4 w-4" />}
                    </button>
                    <button
                      onClick={() => triggerTask.mutate(task.id)}
                      disabled={task.running}
                      className="flex items-center gap-1 px-3 py-1.5 text-sm bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-lg transition-colors"
                    >
                      <Play className="h-3 w-3" /> Run Now
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      ) : (
        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Execution History</h2>
          {!history || history.length === 0 ? (
            <p className="text-gray-500">No task executions yet</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="text-left text-xs text-gray-500 uppercase tracking-wider">
                    <th className="pb-3 pr-4">Status</th>
                    <th className="pb-3 pr-4">Task</th>
                    <th className="pb-3 pr-4">Started</th>
                    <th className="pb-3 pr-4">Duration</th>
                    <th className="pb-3">Error</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-700/50">
                  {history.map((run, i) => (
                    <tr key={i} className="text-sm">
                      <td className="py-3 pr-4">
                        {run.success ? (
                          <CheckCircle className="h-4 w-4 text-green-400" />
                        ) : (
                          <XCircle className="h-4 w-4 text-red-400" />
                        )}
                      </td>
                      <td className="py-3 pr-4 text-white font-medium">{run.taskName}</td>
                      <td className="py-3 pr-4 text-gray-400">{new Date(run.startTime).toLocaleString()}</td>
                      <td className="py-3 pr-4 text-gray-400">{formatDuration(run.duration)}</td>
                      <td className="py-3 text-red-400 text-xs max-w-xs truncate">{run.error || '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
