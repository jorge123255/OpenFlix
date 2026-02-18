import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import {
  Save,
  Cpu,
  MonitorPlay,
  Puzzle,
  FlaskConical,
  Loader,
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

function ToggleRow({
  label,
  description,
  checked,
  onChange,
}: {
  label: string
  description?: string
  checked: boolean
  onChange: (checked: boolean) => void
}) {
  return (
    <div className="flex items-center justify-between py-2">
      <div className="flex-1 mr-4">
        <div className="text-sm font-medium text-gray-300">{label}</div>
        {description && <p className="text-xs text-gray-500 mt-0.5">{description}</p>}
      </div>
      <ToggleSwitch checked={checked} onChange={onChange} label={label} />
    </div>
  )
}

const selectClass = 'w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white'
const numberInputClass = 'w-32 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white'

export function SettingsAdvancedPage() {
  const queryClient = useQueryClient()
  const [formData, setFormData] = useState<Partial<ServerSettings>>({})
  const [saved, setSaved] = useState(false)

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

  if (isLoading) {
    return (
      <div>
        <div className="mb-2">
          <h1 className="text-2xl font-bold text-white">Settings</h1>
          <p className="text-gray-400 mt-1">Advanced configuration</p>
        </div>
        <SettingsTabNav active="advanced" />
        <div className="flex items-center gap-2 text-gray-400 py-12 justify-center">
          <Loader className="h-5 w-5 animate-spin" />
          Loading settings...
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div>
        <div className="mb-2">
          <h1 className="text-2xl font-bold text-white">Settings</h1>
          <p className="text-gray-400 mt-1">Advanced configuration</p>
        </div>
        <SettingsTabNav active="advanced" />
        <div className="bg-gray-800 rounded-xl p-6">
          <p className="text-yellow-400">Settings API not available. Configure via config.yaml file.</p>
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <div>
          <h1 className="text-2xl font-bold text-white">Settings</h1>
          <p className="text-gray-400 mt-1">Advanced configuration</p>
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

      <SettingsTabNav active="advanced" />

      {/* Transcoder Section */}
      <SettingSection
        title="Transcoder"
        description="Configure how live TV and recordings are transcoded"
        icon={<Cpu className="h-5 w-5 text-orange-400" />}
      >
        <SettingField
          label="Transcoder Type"
          description="Hardware acceleration method for transcoding. Software is most compatible but slowest."
        >
          <select
            value={formData.transcoder_type || 'software'}
            onChange={(e) => updateField('transcoder_type', e.target.value)}
            className={selectClass}
          >
            <option value="software">Software (CPU)</option>
            <option value="nvenc">NVIDIA NVENC</option>
            <option value="qsv">Intel Quick Sync (QSV)</option>
            <option value="vaapi">VAAPI (Linux)</option>
            <option value="videotoolbox">VideoToolbox (macOS)</option>
          </select>
        </SettingField>

        <SettingField
          label="Deinterlacer Mode"
          description="Method used to deinterlace interlaced video content (common in live TV)"
        >
          <select
            value={formData.deinterlacer_mode || 'blend'}
            onChange={(e) => updateField('deinterlacer_mode', e.target.value)}
            className={selectClass}
          >
            <option value="blend">Blend (faster, good quality)</option>
            <option value="linear">Linear (slower, better quality)</option>
          </select>
        </SettingField>

        <SettingField
          label="Live TV Buffer Duration"
          description="Seconds of video to buffer before playback starts. Higher values reduce stuttering but increase startup time."
        >
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="2"
              max="30"
              value={formData.livetv_buffer_secs || 8}
              onChange={(e) => updateField('livetv_buffer_secs', Number(e.target.value))}
              className={numberInputClass}
            />
            <span className="text-gray-400 text-sm">seconds</span>
          </div>
        </SettingField>
      </SettingSection>

      {/* Web Player Section */}
      <SettingSection
        title="Web Player"
        description="Configure the built-in web player for browser-based playback"
        icon={<MonitorPlay className="h-5 w-5 text-blue-400" />}
      >
        <SettingField
          label="Playback Quality"
          description="Default streaming quality for the web player. Lower quality uses less bandwidth."
        >
          <select
            value={formData.playback_quality || 'original'}
            onChange={(e) => updateField('playback_quality', e.target.value)}
            className={selectClass}
          >
            <option value="original">Original Quality</option>
            <option value="1080p">1080p (8 Mbps)</option>
            <option value="720p">720p (4 Mbps)</option>
            <option value="480p">480p (2 Mbps)</option>
            <option value="360p">360p (1 Mbps)</option>
          </select>
        </SettingField>

        <SettingField
          label="Client Buffer Duration"
          description="Seconds of video the player will buffer ahead. Higher values prevent buffering on slow connections."
        >
          <div className="flex items-center gap-3">
            <input
              type="number"
              min="1"
              max="30"
              value={formData.client_buffer_secs || 5}
              onChange={(e) => updateField('client_buffer_secs', Number(e.target.value))}
              className={numberInputClass}
            />
            <span className="text-gray-400 text-sm">seconds</span>
          </div>
        </SettingField>
      </SettingSection>

      {/* Integrations Section */}
      <SettingSection
        title="Integrations"
        description="External tool integration and data export options"
        icon={<Puzzle className="h-5 w-5 text-green-400" />}
      >
        <ToggleRow
          label="EDL Export"
          description="Export Edit Decision List files alongside recordings for use in external editors (Kodi, etc.)"
          checked={formData.edl_export ?? false}
          onChange={(checked) => updateField('edl_export', checked)}
        />
        <div className="border-t border-gray-700" />
        <ToggleRow
          label="M3U Channel IDs"
          description="Include tvc-guide-stationid tags in exported M3U playlists for EPG mapping in other apps"
          checked={formData.m3u_channel_ids ?? false}
          onChange={(checked) => updateField('m3u_channel_ids', checked)}
        />
        <div className="border-t border-gray-700" />
        <ToggleRow
          label="VLC Links"
          description="Generate VLC-compatible stream links for direct playback in VLC media player"
          checked={formData.vlc_links ?? false}
          onChange={(checked) => updateField('vlc_links', checked)}
        />
        <div className="border-t border-gray-700" />
        <ToggleRow
          label="HTTP Logging"
          description="Log all HTTP requests and responses for debugging. May impact performance and generate large log files."
          checked={formData.http_logging ?? false}
          onChange={(checked) => updateField('http_logging', checked)}
        />
      </SettingSection>

      {/* Experimental Section */}
      <SettingSection
        title="Experimental"
        description="Features under development. These may be unstable or change without notice."
        icon={<FlaskConical className="h-5 w-5 text-purple-400" />}
      >
        <div className="p-3 bg-yellow-500/10 border border-yellow-500/20 rounded-lg mb-4">
          <p className="text-xs text-yellow-400">
            These features are experimental and may not work correctly. Enable at your own risk.
          </p>
        </div>

        <ToggleRow
          label="HDR Tone Mapping"
          description="Enable HDR to SDR tone mapping for clients that do not support HDR. Requires hardware transcoding support."
          checked={formData.experimental_hdr ?? false}
          onChange={(checked) => updateField('experimental_hdr', checked)}
        />
        <div className="border-t border-gray-700" />
        <ToggleRow
          label="Low Latency Mode"
          description="Reduce live TV latency by using smaller buffer segments. May cause more frequent buffering on slow connections."
          checked={formData.experimental_low_latency ?? false}
          onChange={(checked) => updateField('experimental_low_latency', checked)}
        />
        <div className="border-t border-gray-700" />
        <ToggleRow
          label="AI Metadata Enhancement"
          description="Use AI models to improve metadata quality, generate better descriptions, and auto-tag content categories."
          checked={formData.experimental_ai_metadata ?? false}
          onChange={(checked) => updateField('experimental_ai_metadata', checked)}
        />
      </SettingSection>
    </div>
  )
}
