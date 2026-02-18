import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Bell, Save, Send, History, Plus, Trash2, CheckCircle, XCircle } from 'lucide-react'
import { api } from '../api/client'

interface NotificationConfig {
  enabled: boolean
  discord?: { enabled: boolean; webhookUrl: string }
  slack?: { enabled: boolean; webhookUrl: string }
  email?: { enabled: boolean; smtpHost: string; smtpPort: number; username: string; password: string; from: string; to: string; useTLS: boolean }
  webhooks?: { url: string; method: string; headers?: Record<string, string> }[]
  events: string[]
}

interface NotificationHistoryItem {
  id: string
  type: string
  event: string
  message: string
  status: string
  timestamp: string
  error?: string
}

const ALL_EVENTS = [
  { id: 'recording_started', label: 'Recording Started', description: 'When a DVR recording begins' },
  { id: 'recording_completed', label: 'Recording Completed', description: 'When a DVR recording finishes successfully' },
  { id: 'recording_failed', label: 'Recording Failed', description: 'When a recording fails or is cancelled' },
  { id: 'library_scan_complete', label: 'Library Scan Complete', description: 'When a library scan finishes' },
  { id: 'update_available', label: 'Update Available', description: 'When a new server version is available' },
  { id: 'stream_health_alert', label: 'Stream Health Alert', description: 'When a stream quality drops below threshold' },
]

export function NotificationsPage() {
  const queryClient = useQueryClient()
  const [saved, setSaved] = useState(false)
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null)
  const [activeTab, setActiveTab] = useState<'config' | 'history'>('config')

  const [config, setConfig] = useState<NotificationConfig>({
    enabled: false,
    discord: { enabled: false, webhookUrl: '' },
    slack: { enabled: false, webhookUrl: '' },
    email: { enabled: false, smtpHost: '', smtpPort: 587, username: '', password: '', from: '', to: '', useTLS: true },
    webhooks: [],
    events: ['recording_completed', 'recording_failed'],
  })

  const { data, isLoading } = useQuery({
    queryKey: ['notificationConfig'],
    queryFn: async () => {
      const res = await api.client.get('/api/notifications/config')
      return res.data
    },
  })

  const { data: history } = useQuery({
    queryKey: ['notificationHistory'],
    queryFn: async () => {
      const res = await api.client.get('/api/notifications/history')
      return res.data?.history || []
    },
    enabled: activeTab === 'history',
  })

  useEffect(() => {
    if (data?.config) {
      setConfig(prev => ({ ...prev, ...data.config }))
    }
  }, [data])

  const saveConfig = useMutation({
    mutationFn: async (cfg: NotificationConfig) => {
      const res = await api.client.put('/api/notifications/config', cfg)
      return res.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notificationConfig'] })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    },
  })

  const testNotification = useMutation({
    mutationFn: async (type: string) => {
      const res = await api.client.post('/api/notifications/test', { type })
      return res.data
    },
    onSuccess: () => setTestResult({ success: true, message: 'Test notification sent!' }),
    onError: (err: any) => setTestResult({ success: false, message: err.response?.data?.error || 'Failed to send' }),
  })

  const toggleEvent = (eventId: string) => {
    setConfig(prev => ({
      ...prev,
      events: prev.events.includes(eventId)
        ? prev.events.filter(e => e !== eventId)
        : [...prev.events, eventId],
    }))
  }

  const addWebhook = () => {
    setConfig(prev => ({
      ...prev,
      webhooks: [...(prev.webhooks || []), { url: '', method: 'POST' }],
    }))
  }

  const removeWebhook = (index: number) => {
    setConfig(prev => ({
      ...prev,
      webhooks: (prev.webhooks || []).filter((_, i) => i !== index),
    }))
  }

  if (isLoading) return <div className="text-gray-400">Loading...</div>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Notifications</h1>
          <p className="text-gray-400 mt-1">Configure webhook notifications for server events</p>
        </div>
        <div className="flex items-center gap-3">
          {testResult && (
            <span className={`text-sm ${testResult.success ? 'text-green-400' : 'text-red-400'}`}>
              {testResult.message}
            </span>
          )}
          <button
            onClick={() => saveConfig.mutate(config)}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors"
          >
            <Save className="h-4 w-4" />
            {saveConfig.isPending ? 'Saving...' : saved ? 'Saved!' : 'Save Changes'}
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-gray-800 rounded-lg p-1 w-fit">
        <button
          onClick={() => setActiveTab('config')}
          className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'config' ? 'bg-indigo-600 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          <Bell className="h-4 w-4" /> Configuration
        </button>
        <button
          onClick={() => setActiveTab('history')}
          className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'history' ? 'bg-indigo-600 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          <History className="h-4 w-4" /> History
        </button>
      </div>

      {activeTab === 'config' ? (
        <div className="space-y-6">
          {/* Master Toggle */}
          <div className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-semibold text-white">Enable Notifications</h2>
                <p className="text-sm text-gray-400 mt-1">Send notifications when server events occur</p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  checked={config.enabled}
                  onChange={e => setConfig(prev => ({ ...prev, enabled: e.target.checked }))}
                  className="sr-only peer"
                />
                <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600" />
              </label>
            </div>
          </div>

          {/* Discord */}
          <div className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-[#5865F2] rounded-lg flex items-center justify-center text-white text-sm font-bold">D</div>
                <h2 className="text-lg font-semibold text-white">Discord</h2>
              </div>
              <div className="flex items-center gap-3">
                <button
                  onClick={() => testNotification.mutate('discord')}
                  disabled={!config.discord?.enabled || !config.discord?.webhookUrl}
                  className="flex items-center gap-1 px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 disabled:opacity-50 text-white rounded-lg transition-colors"
                >
                  <Send className="h-3 w-3" /> Test
                </button>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.discord?.enabled || false}
                    onChange={e => setConfig(prev => ({ ...prev, discord: { ...prev.discord!, enabled: e.target.checked } }))}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-600 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600" />
                </label>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">Webhook URL</label>
              <input
                type="url"
                placeholder="https://discord.com/api/webhooks/..."
                value={config.discord?.webhookUrl || ''}
                onChange={e => setConfig(prev => ({ ...prev, discord: { ...prev.discord!, webhookUrl: e.target.value } }))}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          {/* Slack */}
          <div className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-[#4A154B] rounded-lg flex items-center justify-center text-white text-sm font-bold">S</div>
                <h2 className="text-lg font-semibold text-white">Slack</h2>
              </div>
              <div className="flex items-center gap-3">
                <button
                  onClick={() => testNotification.mutate('slack')}
                  disabled={!config.slack?.enabled || !config.slack?.webhookUrl}
                  className="flex items-center gap-1 px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 disabled:opacity-50 text-white rounded-lg transition-colors"
                >
                  <Send className="h-3 w-3" /> Test
                </button>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.slack?.enabled || false}
                    onChange={e => setConfig(prev => ({ ...prev, slack: { ...prev.slack!, enabled: e.target.checked } }))}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-600 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600" />
                </label>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">Webhook URL</label>
              <input
                type="url"
                placeholder="https://hooks.slack.com/services/..."
                value={config.slack?.webhookUrl || ''}
                onChange={e => setConfig(prev => ({ ...prev, slack: { ...prev.slack!, webhookUrl: e.target.value } }))}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          {/* Email */}
          <div className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-emerald-600 rounded-lg flex items-center justify-center text-white text-sm font-bold">@</div>
                <h2 className="text-lg font-semibold text-white">Email (SMTP)</h2>
              </div>
              <div className="flex items-center gap-3">
                <button
                  onClick={() => testNotification.mutate('email')}
                  disabled={!config.email?.enabled || !config.email?.smtpHost}
                  className="flex items-center gap-1 px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 disabled:opacity-50 text-white rounded-lg transition-colors"
                >
                  <Send className="h-3 w-3" /> Test
                </button>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.email?.enabled || false}
                    onChange={e => setConfig(prev => ({ ...prev, email: { ...prev.email!, enabled: e.target.checked } }))}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-600 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600" />
                </label>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">SMTP Host</label>
                <input
                  type="text"
                  placeholder="smtp.gmail.com"
                  value={config.email?.smtpHost || ''}
                  onChange={e => setConfig(prev => ({ ...prev, email: { ...prev.email!, smtpHost: e.target.value } }))}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">SMTP Port</label>
                <input
                  type="number"
                  value={config.email?.smtpPort || 587}
                  onChange={e => setConfig(prev => ({ ...prev, email: { ...prev.email!, smtpPort: parseInt(e.target.value) || 587 } }))}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">Username</label>
                <input
                  type="text"
                  value={config.email?.username || ''}
                  onChange={e => setConfig(prev => ({ ...prev, email: { ...prev.email!, username: e.target.value } }))}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">Password</label>
                <input
                  type="password"
                  value={config.email?.password || ''}
                  onChange={e => setConfig(prev => ({ ...prev, email: { ...prev.email!, password: e.target.value } }))}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">From Address</label>
                <input
                  type="email"
                  placeholder="openflix@example.com"
                  value={config.email?.from || ''}
                  onChange={e => setConfig(prev => ({ ...prev, email: { ...prev.email!, from: e.target.value } }))}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">To Address</label>
                <input
                  type="email"
                  placeholder="you@example.com"
                  value={config.email?.to || ''}
                  onChange={e => setConfig(prev => ({ ...prev, email: { ...prev.email!, to: e.target.value } }))}
                  className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>
          </div>

          {/* Custom Webhooks */}
          <div className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white">Custom Webhooks</h2>
              <button onClick={addWebhook} className="flex items-center gap-1 px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors">
                <Plus className="h-3 w-3" /> Add Webhook
              </button>
            </div>
            {(config.webhooks || []).length === 0 ? (
              <p className="text-gray-500 text-sm">No custom webhooks configured</p>
            ) : (
              <div className="space-y-3">
                {(config.webhooks || []).map((wh, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <select
                      value={wh.method}
                      onChange={e => {
                        const webhooks = [...(config.webhooks || [])]
                        webhooks[i] = { ...webhooks[i], method: e.target.value }
                        setConfig(prev => ({ ...prev, webhooks }))
                      }}
                      className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                    >
                      <option value="POST">POST</option>
                      <option value="GET">GET</option>
                      <option value="PUT">PUT</option>
                    </select>
                    <input
                      type="url"
                      placeholder="https://example.com/webhook"
                      value={wh.url}
                      onChange={e => {
                        const webhooks = [...(config.webhooks || [])]
                        webhooks[i] = { ...webhooks[i], url: e.target.value }
                        setConfig(prev => ({ ...prev, webhooks }))
                      }}
                      className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    />
                    <button onClick={() => removeWebhook(i)} className="p-2 text-red-400 hover:text-red-300">
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Event Selection */}
          <div className="bg-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4">Events to Monitor</h2>
            <div className="space-y-3">
              {ALL_EVENTS.map(event => (
                <label key={event.id} className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg cursor-pointer hover:bg-gray-700 transition-colors">
                  <div>
                    <span className="text-white font-medium">{event.label}</span>
                    <p className="text-sm text-gray-400">{event.description}</p>
                  </div>
                  <input
                    type="checkbox"
                    checked={config.events.includes(event.id)}
                    onChange={() => toggleEvent(event.id)}
                    className="h-5 w-5 rounded border-gray-500 text-indigo-600 focus:ring-indigo-500 bg-gray-600"
                  />
                </label>
              ))}
            </div>
          </div>
        </div>
      ) : (
        /* History Tab */
        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Notification History</h2>
          {!history || (history as NotificationHistoryItem[]).length === 0 ? (
            <p className="text-gray-500">No notifications sent yet</p>
          ) : (
            <div className="space-y-2">
              {(history as NotificationHistoryItem[]).map((item, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg">
                  <div className="flex items-center gap-3">
                    {item.status === 'sent' ? (
                      <CheckCircle className="h-5 w-5 text-green-400 flex-shrink-0" />
                    ) : (
                      <XCircle className="h-5 w-5 text-red-400 flex-shrink-0" />
                    )}
                    <div>
                      <span className="text-white text-sm font-medium">{item.event}</span>
                      <span className="text-gray-400 text-sm ml-2">via {item.type}</span>
                      {item.error && <p className="text-red-400 text-xs mt-0.5">{item.error}</p>}
                    </div>
                  </div>
                  <span className="text-gray-500 text-xs">{new Date(item.timestamp).toLocaleString()}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
