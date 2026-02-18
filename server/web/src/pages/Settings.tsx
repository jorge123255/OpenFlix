import { useState, useEffect, useRef } from 'react'
import { Save, CheckCircle, XCircle, Loader, Download, Upload, AlertCircle, Server, Cpu, Tv, HardDrive, Globe, Play } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type ServerSettings, type DVRSettings, type ImportResult, type ConfigStats } from '../api/client'

function useServerConfig() {
  return useQuery({
    queryKey: ['serverConfig'],
    queryFn: () => api.getServerConfig(),
    retry: false,
  })
}

function SettingSection({ title, icon, children }: { title: string; icon?: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        {icon}
        {title}
      </h2>
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

function ToggleSwitch({
  checked,
  onChange,
  label,
}: {
  checked: boolean
  onChange: (checked: boolean) => void
  label?: string
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
        checked ? 'bg-indigo-600' : 'bg-gray-600'
      }`}
    >
      <span
        className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
          checked ? 'translate-x-6' : 'translate-x-1'
        }`}
      />
      {label && <span className="sr-only">{label}</span>}
    </button>
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

  const { data: commercialStatus } = useQuery({
    queryKey: ['commercialDetectionStatus'],
    queryFn: () => api.getCommercialDetectionStatus(),
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

        {/* Commercial Detection Status */}
        <div className="pt-4 border-t border-gray-700">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-medium text-gray-300">Commercial Detection</h3>
              <p className="text-xs text-gray-500 mt-1">
                Automatically detect and skip commercials in recordings using Comskip
              </p>
            </div>
            <div className="flex items-center gap-2">
              {commercialStatus?.enabled ? (
                <>
                  <CheckCircle className="h-4 w-4 text-green-400" />
                  <span className="text-sm text-green-400">Enabled</span>
                </>
              ) : (
                <>
                  <XCircle className="h-4 w-4 text-gray-500" />
                  <span className="text-sm text-gray-500">Not Available</span>
                </>
              )}
            </div>
          </div>
          {!commercialStatus?.enabled && (
            <p className="text-xs text-gray-500 mt-2">
              Comskip is not installed. Commercial detection will be enabled automatically when Comskip is available.
            </p>
          )}
        </div>
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

function ConfigBackupSection() {
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [isExporting, setIsExporting] = useState(false)
  const [isImporting, setIsImporting] = useState(false)
  const [importResult, setImportResult] = useState<ImportResult | null>(null)
  const [pendingImport, setPendingImport] = useState<unknown | null>(null)
  const [error, setError] = useState<string | null>(null)

  const { data: stats, isLoading: statsLoading } = useQuery<ConfigStats>({
    queryKey: ['configStats'],
    queryFn: () => api.getConfigStats(),
    retry: 1,
  })

  const handleExport = async () => {
    setIsExporting(true)
    setError(null)
    try {
      const blob = await api.exportConfig()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `openflix-config-${new Date().toISOString().split('T')[0]}.json`
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
    } catch (err: any) {
      setError(err.message || 'Failed to export configuration')
    } finally {
      setIsExporting(false)
    }
  }

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    setError(null)
    setImportResult(null)
    setIsImporting(true)

    try {
      const text = await file.text()
      const data = JSON.parse(text)

      // Preview first
      const preview = await api.importConfig(data, true)
      setImportResult(preview)
      setPendingImport(data)
    } catch (err: any) {
      setError(err.message || 'Failed to parse configuration file')
    } finally {
      setIsImporting(false)
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
    }
  }

  const confirmImport = async () => {
    if (!pendingImport) return

    setIsImporting(true)
    setError(null)

    try {
      const result = await api.importConfig(pendingImport, false)
      setImportResult(result)
      setPendingImport(null)
    } catch (err: any) {
      setError(err.message || 'Failed to import configuration')
    } finally {
      setIsImporting(false)
    }
  }

  const cancelImport = () => {
    setPendingImport(null)
    setImportResult(null)
  }

  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <h2 className="text-lg font-semibold text-white mb-4">Configuration Backup</h2>
      <div className="space-y-4">
        <p className="text-sm text-gray-400">
          Export your entire OpenFlix configuration including channels, sources, EPG, libraries, users, playlists, and more.
        </p>

        {/* Current Stats */}
        {!statsLoading && stats && (
          <div className="grid grid-cols-3 sm:grid-cols-5 gap-3 p-4 bg-gray-900 rounded-lg">
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.channels}</div>
              <div className="text-xs text-gray-500">Channels</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.m3uSources + stats.xtreamSources}</div>
              <div className="text-xs text-gray-500">Sources</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.epgSources}</div>
              <div className="text-xs text-gray-500">EPG</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.libraries}</div>
              <div className="text-xs text-gray-500">Libraries</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.recordings}</div>
              <div className="text-xs text-gray-500">Recordings</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.users}</div>
              <div className="text-xs text-gray-500">Users</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.playlists}</div>
              <div className="text-xs text-gray-500">Playlists</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.seriesRules + stats.teamPasses}</div>
              <div className="text-xs text-gray-500">DVR Rules</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.watchHistory}</div>
              <div className="text-xs text-gray-500">Watch History</div>
            </div>
            <div className="text-center">
              <div className="text-xl font-semibold text-white">{stats.settings}</div>
              <div className="text-xs text-gray-500">Settings</div>
            </div>
          </div>
        )}

        {/* Export/Import Buttons */}
        <div className="flex gap-3">
          <button
            onClick={handleExport}
            disabled={isExporting}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg"
          >
            {isExporting ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <Download className="h-4 w-4" />
            )}
            {isExporting ? 'Exporting...' : 'Export Configuration'}
          </button>

          <input
            ref={fileInputRef}
            type="file"
            accept=".json"
            onChange={handleFileSelect}
            className="hidden"
          />
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={isImporting}
            className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 text-white rounded-lg"
          >
            {isImporting ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <Upload className="h-4 w-4" />
            )}
            {isImporting ? 'Processing...' : 'Import Configuration'}
          </button>
        </div>

        {/* Error Display */}
        {error && (
          <div className="flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
            <XCircle className="h-4 w-4 text-red-400 flex-shrink-0" />
            <span className="text-red-400 text-sm">{error}</span>
          </div>
        )}

        {/* Import Preview */}
        {importResult && pendingImport !== null && (
          <div className="p-4 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
            <div className="flex items-start gap-2 mb-3">
              <AlertCircle className="h-5 w-5 text-yellow-400 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-medium text-yellow-400">Import Preview</h3>
                <p className="text-sm text-gray-400 mt-1">
                  This will import the following items. Existing items with the same ID will be updated.
                </p>
              </div>
            </div>

            {importResult.version && (
              <p className="text-xs text-gray-500 mb-2">
                Export version: {importResult.version} | Exported: {importResult.exportedAt ? new Date(importResult.exportedAt).toLocaleString() : 'Unknown'}
              </p>
            )}

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mb-4">
              {importResult.counts && (Object.entries(importResult.counts) as [string, number][]).map(([key, value]) =>
                value > 0 ? (
                  <div key={key} className="text-center p-2 bg-gray-800 rounded">
                    <div className="text-lg font-semibold text-white">{value}</div>
                    <div className="text-xs text-gray-500 capitalize">{key.replace(/([A-Z])/g, ' $1').trim()}</div>
                  </div>
                ) : null
              )}
            </div>

            <div className="flex gap-2">
              <button
                onClick={confirmImport}
                disabled={isImporting}
                className="flex items-center gap-2 px-4 py-2 bg-yellow-600 hover:bg-yellow-700 disabled:bg-yellow-800 text-white rounded-lg"
              >
                {isImporting ? <Loader className="h-4 w-4 animate-spin" /> : <CheckCircle className="h-4 w-4" />}
                {isImporting ? 'Importing...' : 'Confirm Import'}
              </button>
              <button
                onClick={cancelImport}
                disabled={isImporting}
                className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Import Success */}
        {importResult && importResult.success && pendingImport === null && (
          <div className="flex items-center gap-2 p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
            <CheckCircle className="h-4 w-4 text-green-400 flex-shrink-0" />
            <span className="text-green-400 text-sm">
              Configuration imported successfully!
              {importResult.imported && (
                <span className="text-gray-400 ml-2">
                  ({Object.entries(importResult.imported).filter(([, v]) => v > 0).map(([k, v]) => `${v} ${k}`).join(', ')})
                </span>
              )}
            </span>
          </div>
        )}

        <p className="text-xs text-gray-500">
          Note: Passwords and sensitive credentials are not included in exports for security.
        </p>
      </div>
    </div>
  )
}

const inputClass = "w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
const selectClass = "w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
const numberInputClass = "w-32 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
const readOnlyClass = "w-full px-4 py-2 bg-gray-900 border border-gray-700 rounded-lg text-gray-400 cursor-not-allowed"

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

      {/* 1. Server Settings */}
      <SettingSection title="Server Settings" icon={<Server className="h-5 w-5 text-indigo-400" />}>
        <SettingField label="Server Name" description="Friendly name shown to clients on your network">
          <input
            type="text"
            value={formData.server_name || ''}
            onChange={(e) => updateField('server_name', e.target.value)}
            className={inputClass}
            placeholder="OpenFlix Server"
          />
        </SettingField>
        <SettingField label="Server Port" description="Port the server listens on. Requires restart to take effect.">
          <input
            type="number"
            min="1"
            max="65535"
            value={formData.server_port || 32400}
            onChange={(e) => updateField('server_port', Number(e.target.value))}
            className={numberInputClass}
          />
        </SettingField>
        <SettingField label="Log Level" description="Controls the verbosity of server logs">
          <select
            value={formData.log_level || 'info'}
            onChange={(e) => updateField('log_level', e.target.value)}
            className={selectClass}
          >
            <option value="debug">Debug</option>
            <option value="info">Info</option>
            <option value="warn">Warning</option>
            <option value="error">Error</option>
          </select>
        </SettingField>
        <SettingField label="Data Directory" description="Where OpenFlix stores its database, cache, and media files">
          <input
            type="text"
            value={formData.data_dir || ''}
            readOnly
            className={readOnlyClass}
          />
        </SettingField>
      </SettingSection>

      {/* Metadata (existing) */}
      <SettingSection title="Metadata">
        <SettingField label="TMDB API Key" description="For movie and TV show metadata (get yours at themoviedb.org)">
          <input
            type="password"
            value={formData.tmdb_api_key || ''}
            onChange={(e) => updateField('tmdb_api_key', e.target.value)}
            className={inputClass}
            placeholder="Enter your TMDB API key"
          />
        </SettingField>
        <SettingField label="TVDB API Key" description="For additional TV show metadata (optional)">
          <input
            type="password"
            value={formData.tvdb_api_key || ''}
            onChange={(e) => updateField('tvdb_api_key', e.target.value)}
            className={inputClass}
            placeholder="Enter your TVDB API key"
          />
        </SettingField>
        <SettingField label="Metadata Language" description="Preferred language for metadata">
          <select
            value={formData.metadata_lang || 'en'}
            onChange={(e) => updateField('metadata_lang', e.target.value)}
            className={selectClass}
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
            className={numberInputClass}
          />
        </SettingField>
      </SettingSection>

      {/* 2. Transcoding */}
      <SettingSection title="Transcoding" icon={<Cpu className="h-5 w-5 text-orange-400" />}>
        <SettingField label="Hardware Acceleration" description="GPU-accelerated encoding/decoding. 'auto' will detect the best option.">
          <select
            value={formData.hardware_accel || 'auto'}
            onChange={(e) => updateField('hardware_accel', e.target.value)}
            className={selectClass}
          >
            <option value="auto">Auto-detect</option>
            <option value="nvidia">NVIDIA (NVENC)</option>
            <option value="amd">AMD (AMF)</option>
            <option value="intel_qsv">Intel Quick Sync (QSV)</option>
            <option value="videotoolbox">Apple VideoToolbox</option>
            <option value="software">Software (CPU only)</option>
          </select>
        </SettingField>
        <SettingField label="Max Concurrent Transcode Sessions" description="Limit simultaneous transcodes to prevent CPU/GPU overload">
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="1"
              max="20"
              value={formData.max_transcode_sessions || 3}
              onChange={(e) => updateField('max_transcode_sessions', Number(e.target.value))}
              className={numberInputClass}
            />
            <span className="text-gray-400 text-sm">sessions</span>
          </div>
        </SettingField>
        <SettingField label="Transcode Temp Directory" description="Temporary directory for transcode output files">
          <input
            type="text"
            value={formData.transcode_temp_dir || ''}
            onChange={(e) => updateField('transcode_temp_dir', e.target.value)}
            className={inputClass}
            placeholder="~/.openflix/transcode"
          />
        </SettingField>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <SettingField label="Default Video Codec" description="Preferred output video codec for transcoding">
            <select
              value={formData.default_video_codec || 'h264'}
              onChange={(e) => updateField('default_video_codec', e.target.value)}
              className={selectClass}
            >
              <option value="h264">H.264 (AVC)</option>
              <option value="hevc">H.265 (HEVC)</option>
              <option value="copy">Copy (no re-encode)</option>
            </select>
          </SettingField>
          <SettingField label="Default Audio Codec" description="Preferred output audio codec for transcoding">
            <select
              value={formData.default_audio_codec || 'aac'}
              onChange={(e) => updateField('default_audio_codec', e.target.value)}
              className={selectClass}
            >
              <option value="aac">AAC</option>
              <option value="ac3">AC3 (Dolby Digital)</option>
              <option value="copy">Copy (no re-encode)</option>
            </select>
          </SettingField>
        </div>
      </SettingSection>

      {/* 3. Live TV */}
      <SettingSection title="Live TV" icon={<Tv className="h-5 w-5 text-blue-400" />}>
        <SettingField label="Max Concurrent Streams" description="Maximum number of simultaneous live TV streams. 0 = unlimited.">
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="0"
              value={formData.livetv_max_streams ?? 0}
              onChange={(e) => updateField('livetv_max_streams', Number(e.target.value))}
              className={numberInputClass}
            />
            <span className="text-gray-400 text-sm">
              {(formData.livetv_max_streams ?? 0) === 0 ? '(Unlimited)' : `streams`}
            </span>
          </div>
        </SettingField>
        <SettingField label="Timeshift Buffer Duration" description="Hours of live TV kept for pause/rewind. Higher values use more disk space.">
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="1"
              max="72"
              value={formData.timeshift_buffer_hrs || 4}
              onChange={(e) => updateField('timeshift_buffer_hrs', Number(e.target.value))}
              className={numberInputClass}
            />
            <span className="text-gray-400 text-sm">hours</span>
          </div>
        </SettingField>
        <SettingField label="EPG Refresh Interval" description="How often to fetch updated program guide data">
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="1"
              max="48"
              value={formData.epg_refresh_interval || 4}
              onChange={(e) => updateField('epg_refresh_interval', Number(e.target.value))}
              className={numberInputClass}
            />
            <span className="text-gray-400 text-sm">hours</span>
          </div>
        </SettingField>
        <SettingField label="Channel Switch Buffer Size" description="Seconds of buffer to maintain for faster channel switching">
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="1"
              max="30"
              value={formData.channel_switch_buffer || 3}
              onChange={(e) => updateField('channel_switch_buffer', Number(e.target.value))}
              className={numberInputClass}
            />
            <span className="text-gray-400 text-sm">seconds</span>
          </div>
        </SettingField>
        <div className="flex items-center justify-between pt-2">
          <SettingField label="Tuner Sharing" description="Allow multiple clients to share the same tuner when watching the same channel">
            <span />
          </SettingField>
          <ToggleSwitch
            checked={formData.tuner_sharing ?? true}
            onChange={(checked) => updateField('tuner_sharing', checked)}
            label="Tuner Sharing"
          />
        </div>
      </SettingSection>

      {/* 4. DVR Settings (expanded) */}
      <SettingSection title="DVR" icon={<HardDrive className="h-5 w-5 text-red-400" />}>
        <SettingField label="Recording Directory" description="Where DVR recordings are saved">
          <input
            type="text"
            value={formData.recording_dir || ''}
            onChange={(e) => updateField('recording_dir', e.target.value)}
            className={inputClass}
            placeholder="~/.openflix/recordings"
          />
        </SettingField>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <SettingField label="Pre-Padding Default" description="Minutes to start recording before scheduled time">
            <div className="flex items-center gap-3">
              <input
                type="number"
                min="0"
                max="60"
                value={formData.pre_padding ?? 2}
                onChange={(e) => updateField('pre_padding', Number(e.target.value))}
                className={numberInputClass}
              />
              <span className="text-gray-400 text-sm">minutes</span>
            </div>
          </SettingField>
          <SettingField label="Post-Padding Default" description="Minutes to continue recording after scheduled end">
            <div className="flex items-center gap-3">
              <input
                type="number"
                min="0"
                max="120"
                value={formData.post_padding ?? 5}
                onChange={(e) => updateField('post_padding', Number(e.target.value))}
                className={numberInputClass}
              />
              <span className="text-gray-400 text-sm">minutes</span>
            </div>
          </SettingField>
        </div>
        <div className="flex items-center justify-between pt-2">
          <SettingField label="Auto Commercial Detection" description="Run commercial detection on completed recordings using Comskip">
            <span />
          </SettingField>
          <ToggleSwitch
            checked={formData.commercial_detect ?? true}
            onChange={(checked) => updateField('commercial_detect', checked)}
            label="Auto Commercial Detection"
          />
        </div>
        <SettingField label="Auto-Delete After" description="Automatically delete recordings after this many days. 0 = never auto-delete.">
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="0"
              value={formData.auto_delete_days ?? 0}
              onChange={(e) => updateField('auto_delete_days', Number(e.target.value))}
              className={numberInputClass}
            />
            <span className="text-gray-400 text-sm">
              {(formData.auto_delete_days ?? 0) === 0 ? 'days (never)' : 'days'}
            </span>
          </div>
        </SettingField>
        <SettingField label="Max Recording Quality" description="Maximum quality for new recordings">
          <select
            value={formData.max_record_quality || 'original'}
            onChange={(e) => updateField('max_record_quality', e.target.value)}
            className={selectClass}
          >
            <option value="original">Original (no re-encode)</option>
            <option value="high">High (1080p)</option>
            <option value="medium">Medium (720p)</option>
            <option value="low">Low (480p)</option>
          </select>
        </SettingField>
      </SettingSection>

      {/* Existing DVR concurrent recordings section */}
      <DVRSettingsSection />

      {/* 5. Remote Access */}
      <SettingSection title="Remote Access" icon={<Globe className="h-5 w-5 text-green-400" />}>
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-sm font-medium text-gray-300">Tailscale Status</h3>
            <p className="text-xs text-gray-500 mt-1">
              Tailscale provides secure remote access to your server via WireGuard VPN
            </p>
          </div>
          <div className="flex items-center gap-2">
            {formData.tailscale_status === 'connected' ? (
              <>
                <CheckCircle className="h-4 w-4 text-green-400" />
                <span className="text-sm text-green-400">Connected</span>
              </>
            ) : (
              <>
                <XCircle className="h-4 w-4 text-gray-500" />
                <span className="text-sm text-gray-500 capitalize">{formData.tailscale_status || 'Disconnected'}</span>
              </>
            )}
          </div>
        </div>
        <div className="flex items-center justify-between pt-2">
          <SettingField label="Remote Access" description="Enable access to your server from outside your local network">
            <span />
          </SettingField>
          <ToggleSwitch
            checked={formData.remote_access_enabled ?? false}
            onChange={(checked) => updateField('remote_access_enabled', checked)}
            label="Remote Access"
          />
        </div>
        <SettingField label="External URL" description="The external URL clients use to reach your server (optional, auto-detected via Tailscale)">
          <input
            type="text"
            value={formData.external_url || ''}
            onChange={(e) => updateField('external_url', e.target.value)}
            className={inputClass}
            placeholder="https://openflix.your-tailnet.ts.net"
          />
        </SettingField>
      </SettingSection>

      {/* 6. Playback Defaults */}
      <SettingSection title="Playback Defaults" icon={<Play className="h-5 w-5 text-purple-400" />}>
        <SettingField label="Default Playback Speed" description="Default speed for video playback">
          <select
            value={formData.default_playback_speed || '1.0'}
            onChange={(e) => updateField('default_playback_speed', e.target.value)}
            className={selectClass}
          >
            <option value="0.5">0.5x</option>
            <option value="0.75">0.75x</option>
            <option value="1.0">1.0x (Normal)</option>
            <option value="1.25">1.25x</option>
            <option value="1.5">1.5x</option>
            <option value="1.75">1.75x</option>
            <option value="2.0">2.0x</option>
          </select>
        </SettingField>
        <SettingField label="Frame Rate Matching" description="Match display refresh rate to content frame rate">
          <select
            value={formData.frame_rate_match_mode || 'auto'}
            onChange={(e) => updateField('frame_rate_match_mode', e.target.value)}
            className={selectClass}
          >
            <option value="auto">Auto</option>
            <option value="always">Always</option>
            <option value="never">Never</option>
          </select>
        </SettingField>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <SettingField label="Default Subtitle Language" description="Preferred language for subtitles">
            <select
              value={formData.default_subtitle_language || ''}
              onChange={(e) => updateField('default_subtitle_language', e.target.value)}
              className={selectClass}
            >
              <option value="">None (Off)</option>
              <option value="en">English</option>
              <option value="es">Spanish</option>
              <option value="fr">French</option>
              <option value="de">German</option>
              <option value="it">Italian</option>
              <option value="pt">Portuguese</option>
              <option value="ja">Japanese</option>
              <option value="ko">Korean</option>
              <option value="zh">Chinese</option>
              <option value="ar">Arabic</option>
              <option value="ru">Russian</option>
              <option value="hi">Hindi</option>
            </select>
          </SettingField>
          <SettingField label="Default Audio Language" description="Preferred language for audio tracks">
            <select
              value={formData.default_audio_language || 'en'}
              onChange={(e) => updateField('default_audio_language', e.target.value)}
              className={selectClass}
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
              <option value="ar">Arabic</option>
              <option value="ru">Russian</option>
              <option value="hi">Hindi</option>
            </select>
          </SettingField>
        </div>
      </SettingSection>

      {/* VOD (existing) */}
      <VODSettingsSection
        vodApiUrl={formData.vod_api_url || ''}
        onUrlChange={(url) => updateField('vod_api_url', url)}
      />

      {/* Config Backup (existing) */}
      <ConfigBackupSection />
    </div>
  )
}
