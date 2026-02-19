import { useState, useEffect } from 'react'
import { Settings, Scissors, Loader, AlertCircle, CheckCircle, Save, ToggleLeft, ToggleRight } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

const authFetch = async (url: string, options?: RequestInit) => {
  const token = localStorage.getItem('openflix_token') || ''
  const res = await fetch(url, {
    ...options,
    headers: { 'X-Plex-Token': token, 'Content-Type': 'application/json', ...options?.headers },
  })
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

interface ComskipStatus {
  enabled: boolean
}

interface ComskipSettings {
  settings: {
    detection_method: string
    comskip_path: string
    sensitivity: number
    auto_skip_behavior: string
    skip_prompt_duration: number
    detection_workers: number
    generate_thumbnails: boolean
    share_edits: boolean
  }
}

interface DetectionResult {
  file: string
  segmentsFound: number
  processingTime: number
  status: string
  timestamp: string
}

function useComskipStatus() {
  return useQuery({
    queryKey: ['comskipStatus'],
    queryFn: () => authFetch('/dvr/commercials/status') as Promise<ComskipStatus>,
  })
}

function useComskipSettings() {
  return useQuery({
    queryKey: ['comskipSettings'],
    queryFn: () => authFetch('/dvr/settings') as Promise<ComskipSettings>,
  })
}

export function ComskipSettingsPage() {
  const queryClient = useQueryClient()
  const { data: status, isLoading: loadingStatus, error: statusError } = useComskipStatus()
  const { data: settingsData, isLoading: loadingSettings } = useComskipSettings()
  const [saved, setSaved] = useState(false)

  const [detectionMethod, setDetectionMethod] = useState('comskip')
  const [comskipPath, setComskipPath] = useState('/usr/bin/comskip')
  const [sensitivity, setSensitivity] = useState(50)
  const [autoSkipBehavior, setAutoSkipBehavior] = useState('show_prompt')
  const [skipPromptDuration, setSkipPromptDuration] = useState(5)
  const [enabled, setEnabled] = useState(false)
  const [detectionWorkers, setDetectionWorkers] = useState(2)
  const [generateThumbnails, setGenerateThumbnails] = useState(false)
  const [shareEdits, setShareEdits] = useState(false)

  useEffect(() => {
    if (settingsData?.settings) {
      const s = settingsData.settings
      setDetectionMethod(s.detection_method || 'comskip')
      setComskipPath(s.comskip_path || '/usr/bin/comskip')
      setSensitivity(s.sensitivity ?? 50)
      setAutoSkipBehavior(s.auto_skip_behavior || 'show_prompt')
      setSkipPromptDuration(s.skip_prompt_duration ?? 5)
      setDetectionWorkers(s.detection_workers ?? 2)
      setGenerateThumbnails(s.generate_thumbnails ?? false)
      setShareEdits(s.share_edits ?? false)
    }
  }, [settingsData])

  useEffect(() => {
    if (status) {
      setEnabled(status.enabled)
    }
  }, [status])

  const updateSettings = useMutation({
    mutationFn: (data: Record<string, unknown>) =>
      authFetch('/dvr/settings', {
        method: 'PUT',
        body: JSON.stringify(data),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['comskipSettings'] })
      queryClient.invalidateQueries({ queryKey: ['comskipStatus'] })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    },
  })

  const handleSave = () => {
    updateSettings.mutate({
      enabled,
      detection_method: detectionMethod,
      comskip_path: comskipPath,
      sensitivity,
      auto_skip_behavior: autoSkipBehavior,
      skip_prompt_duration: skipPromptDuration,
      detection_workers: detectionWorkers,
      generate_thumbnails: generateThumbnails,
      share_edits: shareEdits,
    })
  }

  const { data: resultsData } = useQuery({
    queryKey: ['comskipResults'],
    queryFn: () => authFetch('/api/commercial/get') as Promise<{ results?: DetectionResult[] }>,
  })
  const recentResults: DetectionResult[] = resultsData?.results || []

  if (loadingStatus || loadingSettings) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  if (statusError) {
    return (
      <div className="text-center py-12">
        <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-white">Failed to load commercial detection settings</h3>
        <p className="text-gray-400 mt-2">Check that the DVR service is running.</p>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <div className="flex items-center gap-3">
            <Settings className="h-6 w-6 text-indigo-400" />
            <h1 className="text-2xl font-bold text-white">Commercial Skip Settings</h1>
          </div>
          <p className="text-gray-400 mt-1">Configure automatic commercial detection and skipping</p>
        </div>
        <button
          onClick={handleSave}
          disabled={updateSettings.isPending}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg"
        >
          <Save className="h-4 w-4" />
          {updateSettings.isPending ? 'Saving...' : saved ? 'Saved!' : 'Save Changes'}
        </button>
      </div>

      {/* Enable/Disable Toggle */}
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-white">Commercial Detection</h2>
            <p className="text-sm text-gray-400 mt-1">
              Automatically detect commercial breaks in DVR recordings
            </p>
          </div>
          <button
            onClick={() => setEnabled(!enabled)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
              enabled
                ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30'
                : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
            }`}
          >
            {enabled ? (
              <>
                <ToggleRight className="h-5 w-5" />
                Enabled
              </>
            ) : (
              <>
                <ToggleLeft className="h-5 w-5" />
                Disabled
              </>
            )}
          </button>
        </div>
      </div>

      {/* Detection Settings */}
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
          <Scissors className="h-5 w-5 text-indigo-400" />
          <h2 className="text-lg font-semibold text-white">Detection Configuration</h2>
        </div>

        <div className="space-y-6">
          {/* Detection Method */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Detection Method</label>
            <select
              value={detectionMethod}
              onChange={(e) => setDetectionMethod(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            >
              <option value="comskip">Comskip (External)</option>
              <option value="black_frames">Black Frame Detection</option>
              <option value="hybrid">Hybrid (Comskip + Black Frames)</option>
            </select>
            <p className="text-xs text-gray-500 mt-1">
              {detectionMethod === 'comskip' && 'Uses the external Comskip binary for accurate commercial detection.'}
              {detectionMethod === 'black_frames' && 'Detects black frames as commercial boundaries. Less accurate but no external dependency.'}
              {detectionMethod === 'hybrid' && 'Combines Comskip output with black frame detection for best results.'}
            </p>
          </div>

          {/* Comskip Path */}
          {(detectionMethod === 'comskip' || detectionMethod === 'hybrid') && (
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Comskip Path</label>
              <input
                type="text"
                value={comskipPath}
                onChange={(e) => setComskipPath(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white font-mono text-sm"
                placeholder="/usr/bin/comskip"
              />
              <p className="text-xs text-gray-500 mt-1">
                Full path to the Comskip binary on the server.
              </p>
            </div>
          )}

          {/* Sensitivity */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Detection Sensitivity: {sensitivity}%
            </label>
            <input
              type="range"
              min="0"
              max="100"
              value={sensitivity}
              onChange={(e) => setSensitivity(Number(e.target.value))}
              className="w-full h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer accent-indigo-600"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>Less Aggressive (fewer cuts)</span>
              <span>More Aggressive (more cuts)</span>
            </div>
          </div>

          {/* Auto-Skip Behavior */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Auto-Skip Behavior</label>
            <div className="space-y-2">
              {[
                { value: 'disabled', label: 'Disabled', desc: 'Show commercial markers but do not skip automatically' },
                { value: 'show_prompt', label: 'Show Skip Prompt', desc: 'Display a "Skip" button when a commercial is detected' },
                { value: 'skip_immediately', label: 'Skip Immediately', desc: 'Automatically skip past detected commercials' },
              ].map((option) => (
                <label
                  key={option.value}
                  className={`flex items-start gap-3 p-4 rounded-lg border cursor-pointer transition-colors ${
                    autoSkipBehavior === option.value
                      ? 'border-indigo-500 bg-indigo-500/10'
                      : 'border-gray-700 bg-gray-700/50 hover:border-gray-600'
                  }`}
                >
                  <input
                    type="radio"
                    name="autoSkipBehavior"
                    value={option.value}
                    checked={autoSkipBehavior === option.value}
                    onChange={(e) => setAutoSkipBehavior(e.target.value)}
                    className="mt-1 accent-indigo-600"
                  />
                  <div>
                    <div className="font-medium text-white">{option.label}</div>
                    <div className="text-sm text-gray-400">{option.desc}</div>
                  </div>
                </label>
              ))}
            </div>
          </div>

          {/* Skip Prompt Duration */}
          {autoSkipBehavior === 'show_prompt' && (
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Skip Prompt Duration (seconds)</label>
              <input
                type="number"
                min="1"
                max="30"
                value={skipPromptDuration}
                onChange={(e) => setSkipPromptDuration(Number(e.target.value))}
                className="w-32 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              />
              <p className="text-xs text-gray-500 mt-1">
                How long the skip button is displayed before auto-dismissing.
              </p>
            </div>
          )}

          {/* Detection Workers */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Detection Workers</label>
            <input
              type="number"
              min="1"
              max="8"
              value={detectionWorkers}
              onChange={(e) => setDetectionWorkers(Math.min(8, Math.max(1, Number(e.target.value))))}
              className="w-32 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            />
            <p className="text-xs text-gray-500 mt-1">
              Number of parallel commercial detection jobs (1-8). Higher values process recordings faster but use more CPU.
            </p>
          </div>

          {/* Generate Thumbnails */}
          <div className="flex items-center justify-between">
            <div>
              <label className="block text-sm font-medium text-gray-300">Generate Thumbnails</label>
              <p className="text-xs text-gray-500 mt-1">
                Generate preview thumbnails at chapter points during commercial detection.
              </p>
            </div>
            <button
              onClick={() => setGenerateThumbnails(!generateThumbnails)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
                generateThumbnails
                  ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30'
                  : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
              }`}
            >
              {generateThumbnails ? (
                <>
                  <ToggleRight className="h-5 w-5" />
                  On
                </>
              ) : (
                <>
                  <ToggleLeft className="h-5 w-5" />
                  Off
                </>
              )}
            </button>
          </div>

          {/* Share Commercial Edits */}
          <div className="flex items-center justify-between">
            <div>
              <label className="block text-sm font-medium text-gray-300">Share Commercial Edits</label>
              <p className="text-xs text-gray-500 mt-1">
                Share your commercial detection results to help improve accuracy for everyone.
              </p>
            </div>
            <button
              onClick={() => setShareEdits(!shareEdits)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
                shareEdits
                  ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30'
                  : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
              }`}
            >
              {shareEdits ? (
                <>
                  <ToggleRight className="h-5 w-5" />
                  On
                </>
              ) : (
                <>
                  <ToggleLeft className="h-5 w-5" />
                  Off
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Recent Detection Results */}
      <div className="bg-gray-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Recent Detection Results</h2>
        {recentResults.length === 0 ? (
          <div className="text-center py-8">
            <Scissors className="h-12 w-12 text-gray-600 mx-auto mb-3" />
            <p className="text-gray-400">No recent detection results</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-700">
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">File</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">Segments Found</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">Processing Time</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">Status</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">Timestamp</th>
                </tr>
              </thead>
              <tbody>
                {recentResults.map((result, idx) => (
                  <tr key={idx} className="border-b border-gray-700/50 hover:bg-gray-700/30">
                    <td className="py-3 px-4 text-sm text-white font-mono">{result.file}</td>
                    <td className="py-3 px-4 text-sm text-gray-300">
                      <span className={`px-2 py-0.5 rounded ${
                        result.segmentsFound > 0 ? 'bg-indigo-500/20 text-indigo-400' : 'bg-gray-700 text-gray-400'
                      }`}>
                        {result.segmentsFound}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-sm text-gray-300">{result.processingTime.toFixed(1)}s</td>
                    <td className="py-3 px-4 text-sm">
                      <span className="flex items-center gap-1 text-green-400">
                        <CheckCircle className="h-3.5 w-3.5" />
                        {result.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-sm text-gray-400">
                      {new Date(result.timestamp).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
