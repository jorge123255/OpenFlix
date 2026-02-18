import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import {
  Save,
  Tv,
  Film,
  RefreshCw,
  Database,
  Loader,
  CheckCircle,
  Radio,
  SkipForward,
  Calendar,
  Trash2,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type ServerSettings } from '../api/client'

function SettingsTabNav({ active }: { active: 'general' | 'sources' | 'livetv-dvr' | 'advanced' | 'status' }) {
  const tabs = [
    { id: 'general' as const, label: 'General', path: '/ui/settings' },
    { id: 'sources' as const, label: 'Sources', path: '/ui/settings/sources' },
    { id: 'livetv-dvr' as const, label: 'Live TV & DVR', path: '/ui/settings/livetv-dvr' },
    { id: 'advanced' as const, label: 'Advanced', path: '/ui/settings/advanced' },
    { id: 'status' as const, label: 'Status', path: '/ui/settings/status' },
  ]

  return (
    <div className="flex gap-1 mb-8 bg-gray-800 rounded-lg p-1 w-fit">
      {tabs.map((tab) => (
        <Link
          key={tab.id}
          to={tab.path}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            active === tab.id
              ? 'bg-indigo-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700'
          }`}
        >
          {tab.label}
        </Link>
      ))}
    </div>
  )
}

function SettingSection({
  title,
  description,
  icon,
  children,
}: {
  title: string
  description?: string
  icon?: React.ReactNode
  children: React.ReactNode
}) {
  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <div className="mb-4">
        <h2 className="text-lg font-semibold text-white flex items-center gap-2">
          {icon}
          {title}
        </h2>
        {description && <p className="text-sm text-gray-400 mt-1">{description}</p>}
      </div>
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

const selectClass = 'w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white'
const numberInputClass = 'w-32 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white'

const PRE_PADDING_OPTIONS = [0, 1, 2, 3, 5, 10, 15]
const POST_PADDING_OPTIONS = [0, 1, 2, 3, 5, 10, 15, 30]
const QUALITY_OPTIONS = [
  { value: 'original', label: 'Original (Pass-through)' },
  { value: 'high', label: 'High Quality (1080p)' },
  { value: 'medium', label: 'Medium Quality (720p)' },
  { value: 'low', label: 'Low Quality (480p)' },
]
const KEEP_RULE_OPTIONS = [
  { value: 'all', label: 'Keep All' },
  { value: '3', label: 'Keep 3' },
  { value: '5', label: 'Keep 5' },
  { value: '10', label: 'Keep 10' },
  { value: 'latest', label: 'Keep Latest Only' },
]
const COMSKIP_MODE_OPTIONS = [
  { value: 'off', label: 'Off' },
  { value: 'comskip', label: 'Comskip' },
  { value: 'chapters', label: 'Chapter Markers' },
]
const GUIDE_REFRESH_OPTIONS = [
  { value: 6, label: 'Every 6 hours' },
  { value: 12, label: 'Every 12 hours' },
  { value: 24, label: 'Every 24 hours' },
]
const DEINTERLACE_OPTIONS = [
  { value: 'off', label: 'Off' },
  { value: 'blend', label: 'Blend' },
  { value: 'linear', label: 'Linear' },
]
const BUFFER_SIZE_OPTIONS = [
  { value: '30s', label: '30 seconds' },
  { value: '1min', label: '1 minute' },
  { value: '5min', label: '5 minutes' },
  { value: '15min', label: '15 minutes' },
  { value: '30min', label: '30 minutes' },
  { value: '1hr', label: '1 hour' },
]

export function SettingsLiveTVDVRPage() {
  const queryClient = useQueryClient()
  const [formData, setFormData] = useState<Partial<ServerSettings>>({})
  const [saved, setSaved] = useState(false)
  const [refreshing, setRefreshing] = useState(false)
  const [rebuilding, setRebuilding] = useState(false)

  const { data: config, isLoading, error } = useQuery({
    queryKey: ['serverConfig'],
    queryFn: () => api.getServerConfig(),
    retry: false,
  })

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

  const updateField = (field: keyof ServerSettings, value: unknown) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }))
  }

  const handleRefreshGuide = async () => {
    setRefreshing(true)
    try {
      await api.refreshGuideData()
      setTimeout(() => setRefreshing(false), 3000)
    } catch {
      setRefreshing(false)
    }
  }

  const handleRebuildGuide = async () => {
    setRebuilding(true)
    try {
      await api.rebuildGuideData()
      setTimeout(() => setRebuilding(false), 5000)
    } catch {
      setRebuilding(false)
    }
  }

  if (isLoading) {
    return <div className="text-gray-400">Loading settings...</div>
  }

  if (error) {
    return (
      <div>
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-white">Settings</h1>
          <p className="text-gray-400 mt-1">Live TV & DVR configuration</p>
        </div>
        <SettingsTabNav active="livetv-dvr" />
        <div className="bg-gray-800 rounded-xl p-6">
          <p className="text-yellow-400">Settings API not available.</p>
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <div>
          <h1 className="text-2xl font-bold text-white">Settings</h1>
          <p className="text-gray-400 mt-1">Live TV & DVR configuration</p>
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

      <SettingsTabNav active="livetv-dvr" />

      {/* Recording Defaults */}
      <SettingSection
        title="Recording Defaults"
        description="Default settings applied to new DVR recordings"
        icon={<Film className="h-5 w-5 text-red-400" />}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <SettingField
            label="Pre-Padding"
            description="Minutes to start recording before the scheduled start time"
          >
            <select
              value={formData.recording_pre_padding ?? 2}
              onChange={(e) => updateField('recording_pre_padding', Number(e.target.value))}
              className={selectClass}
            >
              {PRE_PADDING_OPTIONS.map((m) => (
                <option key={m} value={m}>
                  {m === 0 ? 'None' : `${m} minute${m !== 1 ? 's' : ''}`}
                </option>
              ))}
            </select>
          </SettingField>

          <SettingField
            label="Post-Padding"
            description="Minutes to continue recording after the scheduled end time"
          >
            <select
              value={formData.recording_post_padding ?? 5}
              onChange={(e) => updateField('recording_post_padding', Number(e.target.value))}
              className={selectClass}
            >
              {POST_PADDING_OPTIONS.map((m) => (
                <option key={m} value={m}>
                  {m === 0 ? 'None' : `${m} minute${m !== 1 ? 's' : ''}`}
                </option>
              ))}
            </select>
          </SettingField>
        </div>

        <SettingField
          label="Default Quality Preset"
          description="Recording quality when no specific quality is set per-pass"
        >
          <select
            value={formData.recording_quality || 'original'}
            onChange={(e) => updateField('recording_quality', e.target.value)}
            className={selectClass}
          >
            {QUALITY_OPTIONS.map((q) => (
              <option key={q.value} value={q.value}>{q.label}</option>
            ))}
          </select>
        </SettingField>
      </SettingSection>

      {/* Keep Rules */}
      <SettingSection
        title="Keep Rules"
        description="How recordings are managed over time"
        icon={<Calendar className="h-5 w-5 text-blue-400" />}
      >
        <SettingField
          label="Default Keep Rule"
          description="How many episodes to keep by default for series recordings"
        >
          <select
            value={formData.keep_rule || 'all'}
            onChange={(e) => updateField('keep_rule', e.target.value)}
            className={selectClass}
          >
            {KEEP_RULE_OPTIONS.map((k) => (
              <option key={k.value} value={k.value}>{k.label}</option>
            ))}
          </select>
        </SettingField>

        <div className="flex items-center justify-between py-2">
          <div>
            <p className="text-sm font-medium text-gray-300">Auto-Delete Watched Recordings</p>
            <p className="text-xs text-gray-500">Automatically remove recordings after they have been watched</p>
          </div>
          <ToggleSwitch
            checked={formData.auto_delete_watched ?? false}
            onChange={(v) => updateField('auto_delete_watched', v)}
            label="Auto-delete watched recordings"
          />
        </div>

        <SettingField
          label="Auto-Delete After (days)"
          description="Automatically delete recordings after this many days. Set to 0 to disable."
        >
          <input
            type="number"
            min="0"
            max="365"
            value={formData.auto_delete_days ?? 0}
            onChange={(e) => updateField('auto_delete_days', Number(e.target.value))}
            className={numberInputClass}
          />
          <span className="text-xs text-gray-500 ml-2">
            {(formData.auto_delete_days ?? 0) === 0 ? '(Disabled)' : `(${formData.auto_delete_days} days)`}
          </span>
        </SettingField>
      </SettingSection>

      {/* Commercial Detection */}
      <SettingSection
        title="Commercial Detection"
        description="Detect and manage commercial breaks in recordings"
        icon={<SkipForward className="h-5 w-5 text-yellow-400" />}
      >
        <div className="flex items-center justify-between py-2">
          <div>
            <p className="text-sm font-medium text-gray-300">Enable Commercial Detection</p>
            <p className="text-xs text-gray-500">
              Process recordings with Comskip to detect commercial break markers
            </p>
          </div>
          <ToggleSwitch
            checked={formData.commercial_detection_enabled ?? false}
            onChange={(v) => updateField('commercial_detection_enabled', v)}
            label="Enable commercial detection"
          />
        </div>

        <SettingField
          label="Comskip Mode"
          description="How commercial markers are stored"
        >
          <select
            value={formData.commercial_detection_mode || 'comskip'}
            onChange={(e) => updateField('commercial_detection_mode', e.target.value)}
            className={selectClass}
            disabled={!(formData.commercial_detection_enabled ?? false)}
          >
            {COMSKIP_MODE_OPTIONS.map((m) => (
              <option key={m.value} value={m.value}>{m.label}</option>
            ))}
          </select>
        </SettingField>

        <div className="flex items-center justify-between py-2">
          <div>
            <p className="text-sm font-medium text-gray-300">Auto-Skip Commercials on Playback</p>
            <p className="text-xs text-gray-500">
              Automatically skip detected commercial segments during playback on all clients
            </p>
          </div>
          <ToggleSwitch
            checked={formData.auto_skip_commercials ?? false}
            onChange={(v) => updateField('auto_skip_commercials', v)}
            label="Auto-skip commercials"
          />
        </div>
      </SettingSection>

      {/* Guide Data */}
      <SettingSection
        title="Guide Data"
        description="EPG / program guide data management"
        icon={<Database className="h-5 w-5 text-green-400" />}
      >
        <SettingField
          label="Guide Data Refresh Interval"
          description="How often to automatically refresh EPG data from all configured sources"
        >
          <select
            value={formData.guide_refresh_interval ?? 12}
            onChange={(e) => updateField('guide_refresh_interval', Number(e.target.value))}
            className={selectClass}
          >
            {GUIDE_REFRESH_OPTIONS.map((g) => (
              <option key={g.value} value={g.value}>{g.label}</option>
            ))}
          </select>
        </SettingField>

        <div className="py-2">
          <p className="text-sm font-medium text-gray-300 mb-1">Guide Data Source</p>
          <div className="flex items-center gap-2 p-3 bg-gray-900 rounded-lg">
            <Radio className="h-4 w-4 text-green-400" />
            <span className="text-sm text-gray-300">
              {formData.guide_data_source === 'gracenote' ? 'Gracenote (OTA)' : 'XMLTV'}
            </span>
            <span className="text-xs text-gray-500 ml-auto">
              Configured via Sources tab
            </span>
          </div>
        </div>

        <div className="flex gap-3 pt-2">
          <button
            onClick={handleRefreshGuide}
            disabled={refreshing}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 disabled:bg-green-800 disabled:cursor-not-allowed text-white text-sm rounded-lg transition-colors"
          >
            {refreshing ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            {refreshing ? 'Refreshing...' : 'Refresh Guide Data Now'}
          </button>

          <button
            onClick={handleRebuildGuide}
            disabled={rebuilding}
            className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 disabled:cursor-not-allowed text-white text-sm rounded-lg transition-colors"
          >
            {rebuilding ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <Trash2 className="h-4 w-4" />
            )}
            {rebuilding ? 'Rebuilding...' : 'Rebuild Guide Data'}
          </button>
        </div>

        {refreshing && (
          <div className="flex items-center gap-2 p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
            <CheckCircle className="h-4 w-4 text-green-400" />
            <span className="text-sm text-green-400">Guide data refresh triggered successfully. This may take a few minutes.</span>
          </div>
        )}

        {rebuilding && (
          <div className="flex items-center gap-2 p-3 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
            <Loader className="h-4 w-4 text-yellow-400 animate-spin" />
            <span className="text-sm text-yellow-400">Rebuilding guide data from scratch. All cached data has been cleared.</span>
          </div>
        )}
      </SettingSection>

      {/* Live TV Streaming */}
      <SettingSection
        title="Live TV Streaming"
        description="Settings for live TV stream processing"
        icon={<Tv className="h-5 w-5 text-purple-400" />}
      >
        <div className="flex items-center justify-between py-2">
          <div>
            <p className="text-sm font-medium text-gray-300">Tuner Sharing</p>
            <p className="text-xs text-gray-500">
              Allow multiple clients to share a single tuner when watching the same channel
            </p>
          </div>
          <ToggleSwitch
            checked={formData.tuner_sharing ?? true}
            onChange={(v) => updateField('tuner_sharing', v)}
            label="Tuner sharing"
          />
        </div>

        <SettingField
          label="Deinterlacing"
          description="Deinterlacing method for interlaced content (e.g., 1080i broadcasts)"
        >
          <select
            value={formData.deinterlacing_mode || 'blend'}
            onChange={(e) => updateField('deinterlacing_mode', e.target.value)}
            className={selectClass}
          >
            {DEINTERLACE_OPTIONS.map((d) => (
              <option key={d.value} value={d.value}>{d.label}</option>
            ))}
          </select>
        </SettingField>

        <SettingField
          label="Live TV Buffer Size"
          description="Amount of live TV content to buffer for pause/rewind. Larger values use more memory."
        >
          <select
            value={formData.livetv_buffer_size || '1min'}
            onChange={(e) => updateField('livetv_buffer_size', e.target.value)}
            className={selectClass}
          >
            {BUFFER_SIZE_OPTIONS.map((b) => (
              <option key={b.value} value={b.value}>{b.label}</option>
            ))}
          </select>
        </SettingField>
      </SettingSection>
    </div>
  )
}
