import { useState } from 'react'
import { Video, Plus, Trash2, Clock, CheckCircle, AlertCircle, Loader } from 'lucide-react'
import {
  useRecordings,
  useDeleteRecording,
  useSeriesRules,
  useCreateSeriesRule,
  useDeleteSeriesRule,
} from '../hooks/useDVR'
import type { Recording } from '../types'

const statusIcons = {
  scheduled: Clock,
  recording: Loader,
  completed: CheckCircle,
  failed: AlertCircle,
}

const statusColors = {
  scheduled: 'text-blue-400',
  recording: 'text-orange-400 animate-pulse',
  completed: 'text-green-400',
  failed: 'text-red-400',
}

function CreateRuleModal({ onClose }: { onClose: () => void }) {
  const createRule = useCreateSeriesRule()
  const [title, setTitle] = useState('')
  const [anyChannel, setAnyChannel] = useState(true)
  const [keepCount, setKeepCount] = useState(5)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    await createRule.mutateAsync({
      title,
      anyChannel,
      anyTime: true,
      keepCount,
      priority: 0,
      prePadding: 2,
      postPadding: 5,
      enabled: true,
    })
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <h2 className="text-lg font-semibold text-white mb-4">Create Series Rule</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Series Title (keyword match)
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="Game of Thrones"
              required
            />
          </div>
          <div className="mb-4">
            <label className="flex items-center gap-2 text-sm text-gray-300">
              <input
                type="checkbox"
                checked={anyChannel}
                onChange={(e) => setAnyChannel(e.target.checked)}
                className="rounded bg-gray-700 border-gray-600"
              />
              Record from any channel
            </label>
          </div>
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Keep last
            </label>
            <select
              value={keepCount}
              onChange={(e) => setKeepCount(Number(e.target.value))}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            >
              <option value={0}>All recordings</option>
              <option value={3}>3 recordings</option>
              <option value={5}>5 recordings</option>
              <option value={10}>10 recordings</option>
              <option value={20}>20 recordings</option>
            </select>
          </div>
          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={createRule.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {createRule.isPending ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export function DVRPage() {
  const { data: recordings, isLoading: loadingRec } = useRecordings()
  const { data: rules, isLoading: loadingRules } = useSeriesRules()
  const deleteRecording = useDeleteRecording()
  const deleteRule = useDeleteSeriesRule()
  const [showCreateRule, setShowCreateRule] = useState(false)
  const [activeTab, setActiveTab] = useState<'recordings' | 'rules'>('recordings')

  const groupedRecordings = recordings?.reduce(
    (acc, rec) => {
      acc[rec.status] = acc[rec.status] || []
      acc[rec.status].push(rec)
      return acc
    },
    {} as Record<string, Recording[]>
  )

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">DVR</h1>
        <p className="text-gray-400 mt-1">Manage recordings and series rules</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-6">
        <button
          onClick={() => setActiveTab('recordings')}
          className={`px-4 py-2 rounded-lg font-medium ${
            activeTab === 'recordings'
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-800 text-gray-400 hover:text-white'
          }`}
        >
          Recordings
        </button>
        <button
          onClick={() => setActiveTab('rules')}
          className={`px-4 py-2 rounded-lg font-medium ${
            activeTab === 'rules'
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-800 text-gray-400 hover:text-white'
          }`}
        >
          Series Rules
        </button>
      </div>

      {activeTab === 'recordings' && (
        <div>
          {loadingRec ? (
            <div className="text-gray-400">Loading...</div>
          ) : recordings?.length ? (
            <div className="space-y-6">
              {(['scheduled', 'recording', 'completed', 'failed'] as const).map((status) => {
                const items = groupedRecordings?.[status]
                if (!items?.length) return null

                const StatusIcon = statusIcons[status]
                return (
                  <div key={status}>
                    <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-3 flex items-center gap-2">
                      <StatusIcon className={`h-4 w-4 ${statusColors[status]}`} />
                      {status} ({items.length})
                    </h3>
                    <div className="bg-gray-800 rounded-xl divide-y divide-gray-700">
                      {items.map((rec) => (
                        <div key={rec.id} className="p-4 flex items-center justify-between">
                          <div>
                            <h4 className="font-medium text-white">{rec.title}</h4>
                            <p className="text-sm text-gray-400">
                              {rec.channelName} • {new Date(rec.startTime).toLocaleString()}
                              {rec.duration && ` • ${rec.duration} min`}
                            </p>
                          </div>
                          <button
                            onClick={() => deleteRecording.mutate(rec.id)}
                            className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg"
                            title="Delete"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="text-center py-12 bg-gray-800 rounded-xl">
              <Video className="h-12 w-12 text-gray-600 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-white mb-2">No recordings</h3>
              <p className="text-gray-400">Recordings will appear here once scheduled</p>
            </div>
          )}
        </div>
      )}

      {activeTab === 'rules' && (
        <div>
          <div className="flex justify-end mb-4">
            <button
              onClick={() => setShowCreateRule(true)}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              <Plus className="h-4 w-4" />
              Add Series Rule
            </button>
          </div>

          {loadingRules ? (
            <div className="text-gray-400">Loading...</div>
          ) : rules?.length ? (
            <div className="bg-gray-800 rounded-xl divide-y divide-gray-700">
              {rules.map((rule) => (
                <div key={rule.id} className="p-4 flex items-center justify-between">
                  <div>
                    <h4 className="font-medium text-white">{rule.title}</h4>
                    <p className="text-sm text-gray-400">
                      {rule.anyChannel ? 'Any channel' : 'Specific channel'}
                      {' • Keep '}
                      {rule.keepCount === 0 ? 'all' : `last ${rule.keepCount}`}
                      {' • '}
                      {rule.enabled ? (
                        <span className="text-green-400">Enabled</span>
                      ) : (
                        <span className="text-gray-500">Disabled</span>
                      )}
                    </p>
                  </div>
                  <button
                    onClick={() => deleteRule.mutate(rule.id)}
                    className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg"
                    title="Delete"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12 bg-gray-800 rounded-xl">
              <Video className="h-12 w-12 text-gray-600 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-white mb-2">No series rules</h3>
              <p className="text-gray-400 mb-4">Create rules to automatically record shows</p>
              <button
                onClick={() => setShowCreateRule(true)}
                className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
              >
                <Plus className="h-4 w-4" />
                Add Series Rule
              </button>
            </div>
          )}
        </div>
      )}

      {showCreateRule && <CreateRuleModal onClose={() => setShowCreateRule(false)} />}
    </div>
  )
}
