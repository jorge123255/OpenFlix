import { useState, useEffect } from 'react'
import { Save, CheckCircle, XCircle, Loader } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type ServerSettings, type DVRSettings } from '../api/client'

function useServerConfig() {
  return useQuery({
    queryKey: ['serverConfig'],
    queryFn: () => api.getServerConfig(),
    retry: false,
  })
}

function SettingSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <h2 className="text-lg font-semibold text-white mb-4">{title}</h2>
      <div className="space-y-4">{children}</div>
    </div>
  )
}

function SettingField({
  label,
  description,
  children,
}: {
  label: string
  description?: string
  children: React.ReactNode
}) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-300 mb-1">{label}</label>
      {description && <p className="text-xs text-gray-500 mb-2">{description}</p>}
      {children}
    </div>
  )
}

function DVRSettingsSection() {
  const queryClient = useQueryClient()
  const [saved, setSaved] = useState(false)

  const { data: dvrSettings, isLoading, error } = useQuery({
    queryKey: ['dvrSettings'],
    queryFn: () => api.getDVRSettings(),
    retry: 1,
  })

  const [maxConcurrent, setMaxConcurrent] = useState(0)

  useEffect(() => {
    if (dvrSettings) {
      setMaxConcurrent(dvrSettings.maxConcurrentRecordings)
    }
  }, [dvrSettings])

  const updateSettings = useMutation({
    mutationFn: (data: Partial<DVRSettings>) => api.updateDVRSettings(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dvrSettings'] })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    },
  })

  const handleSave = () => {
    updateSettings.mutate({ maxConcurrentRecordings: maxConcurrent })
  }

  if (isLoading) {
    return (
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <h2 className="text-lg font-semibold text-white mb-4">DVR Settings</h2>
        <div className="text-gray-400">Loading...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <h2 className="text-lg font-semibold text-white mb-4">DVR Settings</h2>
        <div className="text-red-400 text-sm">Failed to load DVR settings</div>
      </div>
    )
  }

  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-white">DVR Settings</h2>
        <button
          onClick={handleSave}
          disabled={updateSettings.isPending}
          className="flex items-center gap-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white text-sm rounded-lg"
        >
          <Save className="h-3.5 w-3.5" />
          {updateSettings.isPending ? 'Saving...' : saved ? 'Saved!' : 'Save'}
        </button>
      </div>
      <div className="space-y-4">
        <SettingField
          label="Max Concurrent Recordings"
          description="Maximum number of recordings that can run at the same time. Set to 0 for unlimited."
        >
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="0"
              value={maxConcurrent}
              onChange={(e) => setMaxConcurrent(Number(e.target.value))}
              className="w-32 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            />
            <span className="text-gray-400 text-sm">
              {maxConcurrent === 0 ? '(Unlimited)' : `(Max ${maxConcurrent} at once)`}
            </span>
          </div>
        </SettingField>
        <p className="text-xs text-gray-500">
          If you have limited tuners or bandwidth, you may want to set a limit.
          When conflicts occur, higher priority recordings will be preferred.
        </p>
      </div>
    </div>
  )
}

function VODSettingsSection({
  vodApiUrl,
  onUrlChange,
}: {
  vodApiUrl: string
  onUrlChange: (url: string) => void
}) {
  const [testResult, setTestResult] = useState<{ connected: boolean; error?: string } | null>(null)
  const [isTesting, setIsTesting] = useState(false)

  const testConnection = async () => {
    if (!vodApiUrl) {
      setTestResult({ connected: false, error: 'Please enter a VOD API URL' })
      return
    }
    setIsTesting(true)
    setTestResult(null)
    try {
      const result = await api.vod.testConnection(vodApiUrl)
      setTestResult(result)
    } catch (error: any) {
      setTestResult({
        connected: false,
        error: error.message || 'Connection failed',
      })
    } finally {
      setIsTesting(false)
    }
  }

  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <h2 className="text-lg font-semibold text-white mb-4">VOD Downloads</h2>
      <div className="space-y-4">
        <SettingField
          label="VOD API URL"
          description="URL of the external VOD download service (e.g., http://192.168.1.82:7070)"
        >
          <div className="flex gap-2">
            <input
              type="text"
              value={vodApiUrl}
              onChange={(e) => {
                onUrlChange(e.target.value)
                setTestResult(null)
              }}
              className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="http://192.168.1.82:7070"
            />
            <button
              onClick={testConnection}
              disabled={isTesting}
              className="px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 text-white rounded-lg whitespace-nowrap"
            >
              {isTesting ? (
                <Loader className="w-4 h-4 animate-spin" />
              ) : (
                'Test Connection'
              )}
            </button>
          </div>
        </SettingField>

        {testResult && (
          <div
            className={`flex items-center gap-2 p-3 rounded-lg ${
              testResult.connected
                ? 'bg-green-500/10 border border-green-500/30'
                : 'bg-red-500/10 border border-red-500/30'
            }`}
          >
            {testResult.connected ? (
              <>
                <CheckCircle className="w-4 h-4 text-green-400" />
                <span className="text-green-400 text-sm">Connection successful</span>
              </>
            ) : (
              <>
                <XCircle className="w-4 h-4 text-red-400" />
                <span className="text-red-400 text-sm">
                  {testResult.error || 'Connection failed'}
                </span>
              </>
            )}
          </div>
        )}

        <p className="text-xs text-gray-500">
          The VOD service provides access to Disney+ and other streaming content for download.
          Downloads will be saved to your configured movie and TV show library paths.
        </p>
      </div>
    </div>
  )
}

export function SettingsPage() {
  const { data: config, isLoading, error } = useServerConfig()
  const queryClient = useQueryClient()
  const [formData, setFormData] = useState<Partial<ServerSettings>>({})
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    if (config) {
      setFormData(config)
    }
  }, [config])

  const updateConfig = useMutation({
    mutationFn: (data: Partial<ServerSettings>) => api.updateServerConfig(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['serverConfig'] })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    },
  })

  const handleSave = () => {
    updateConfig.mutate(formData)
  }

  const updateField = (field: keyof ServerSettings, value: any) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }))
  }

  if (isLoading) {
    return <div className="text-gray-400">Loading settings...</div>
  }

  if (error) {
    return (
      <div>
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-white">Settings</h1>
          <p className="text-gray-400 mt-1">Server configuration</p>
        </div>
        <div className="bg-gray-800 rounded-xl p-6">
          <p className="text-yellow-400 mb-4">
            Settings API not available. Configure via config.yaml file.
          </p>
          <pre className="text-sm text-gray-300 bg-gray-900 p-4 rounded-lg overflow-x-auto">
{`# ~/.openflix/config.yaml or ./config.yaml

server:
  host: "0.0.0.0"
  port: 32400

auth:
  jwt_secret: "change-me-in-production"
  token_expiry: 720
  allow_signup: true

library:
  scan_interval: 60
  metadata_lang: "en"
  tmdb_api_key: ""

livetv:
  enabled: true
  epg_interval: 12

dvr:
  enabled: true
  recording_dir: "~/.openflix/recordings"
  pre_padding: 2
  post_padding: 5

transcode:
  enabled: true
  ffmpeg_path: "ffmpeg"
  hardware_accel: "auto"
  max_sessions: 3`}
          </pre>
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Settings</h1>
          <p className="text-gray-400 mt-1">Configure your OpenFlix server</p>
        </div>
        <button
          onClick={handleSave}
          disabled={updateConfig.isPending}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg"
        >
          <Save className="h-4 w-4" />
          {updateConfig.isPending ? 'Saving...' : saved ? 'Saved!' : 'Save Changes'}
        </button>
      </div>

      <SettingSection title="Metadata">
        <SettingField label="TMDB API Key" description="For movie and TV show metadata (get yours at themoviedb.org)">
          <input
            type="password"
            value={formData.tmdb_api_key || ''}
            onChange={(e) => updateField('tmdb_api_key', e.target.value)}
            className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            placeholder="Enter your TMDB API key"
          />
        </SettingField>
        <SettingField label="TVDB API Key" description="For additional TV show metadata (optional)">
          <input
            type="password"
            value={formData.tvdb_api_key || ''}
            onChange={(e) => updateField('tvdb_api_key', e.target.value)}
            className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            placeholder="Enter your TVDB API key"
          />
        </SettingField>
        <SettingField label="Metadata Language" description="Preferred language for metadata">
          <select
            value={formData.metadata_lang || 'en'}
            onChange={(e) => updateField('metadata_lang', e.target.value)}
            className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
          >
            <option value="en">English</option>
            <option value="es">Spanish</option>
            <option value="fr">French</option>
            <option value="de">German</option>
            <option value="it">Italian</option>
            <option value="pt">Portuguese</option>
            <option value="ja">Japanese</option>
            <option value="ko">Korean</option>
            <option value="zh">Chinese</option>
          </select>
        </SettingField>
        <SettingField label="Scan Interval" description="Minutes between automatic library scans">
          <input
            type="number"
            value={formData.scan_interval || 60}
            onChange={(e) => updateField('scan_interval', Number(e.target.value))}
            className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
          />
        </SettingField>
      </SettingSection>

      <DVRSettingsSection />

      <VODSettingsSection
        vodApiUrl={formData.vod_api_url || ''}
        onUrlChange={(url) => updateField('vod_api_url', url)}
      />

      <div className="bg-gray-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Other Settings</h2>
        <p className="text-gray-400 text-sm">
          Additional server settings (Live TV, Transcoding) can be configured via the <code className="bg-gray-700 px-2 py-1 rounded">config.yaml</code> file.
        </p>
        <p className="text-gray-500 text-sm mt-2">
          Location: <code className="bg-gray-700 px-2 py-1 rounded">~/.openflix/config.yaml</code>
        </p>
      </div>
    </div>
  )
}
