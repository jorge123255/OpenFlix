import { useState, useEffect } from 'react'
import {
  Server,
  Tv,
  CheckCircle,
  ArrowRight,
  ArrowLeft,
  Loader,
  Plus,
  Rocket,
  AlertCircle,
  Radio,
  Search,
  Settings,
} from 'lucide-react'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface WizardTuner {
  deviceId: string
  modelNumber: string
  baseUrl: string
  imported?: number
}

interface WizardM3USource {
  name: string
  url: string
}

interface WizardState {
  step: number
  serverName: string
  adminUsername: string
  adminEmail: string
  adminPassword: string
  tuners: WizardTuner[]
  m3uSource?: WizardM3USource
}

interface StatusResponse {
  server: { name: string }
  libraries: { count: number }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const authHeaders: Record<string, string> = {
  'X-Plex-Token': localStorage.getItem('openflix_token') || '',
  'Content-Type': 'application/json',
}

const TOTAL_STEPS = 4

const STEP_META: { label: string; icon: React.ElementType }[] = [
  { label: 'Welcome', icon: Server },
  { label: 'Tuners', icon: Radio },
  { label: 'Live TV', icon: Tv },
  { label: 'Done', icon: Rocket },
]

// ---------------------------------------------------------------------------
// StepIndicator
// ---------------------------------------------------------------------------

function StepIndicator({ current, total }: { current: number; total: number }) {
  return (
    <div className="flex items-center justify-center gap-4 mb-8">
      {Array.from({ length: total }).map((_, i) => {
        const stepNum = i + 1
        const completed = stepNum < current
        const active = stepNum === current
        const Icon = STEP_META[i].icon
        return (
          <div key={i} className="flex items-center gap-4">
            {i > 0 && (
              <div
                className={`h-0.5 w-12 ${
                  completed ? 'bg-green-500' : 'bg-gray-600'
                }`}
              />
            )}
            <div className="flex flex-col items-center gap-1">
              <div
                className={`flex items-center justify-center w-12 h-12 rounded-full border-2 text-sm font-bold transition-colors ${
                  completed
                    ? 'bg-green-500 border-green-500 text-white'
                    : active
                      ? 'bg-indigo-600 border-indigo-600 text-white'
                      : 'bg-gray-800 border-gray-600 text-gray-400'
                }`}
              >
                {completed ? (
                  <CheckCircle className="w-5 h-5" />
                ) : (
                  <Icon className="w-5 h-5" />
                )}
              </div>
              <span
                className={`text-xs ${
                  active ? 'text-indigo-400 font-medium' : 'text-gray-500'
                }`}
              >
                {STEP_META[i].label}
              </span>
            </div>
          </div>
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 1 - Welcome
// ---------------------------------------------------------------------------

function StepWelcome({
  state,
  onChange,
  needsAdmin,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
  needsAdmin: boolean
}) {
  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">Welcome to OpenFlix</h2>
        <p className="text-gray-400 mt-2">
          Let's get your media server running in just a few steps.
        </p>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-300 mb-2">
          Server Name
        </label>
        <input
          type="text"
          value={state.serverName}
          onChange={(e) => onChange({ serverName: e.target.value })}
          placeholder="My OpenFlix Server"
          className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
        />
      </div>

      {needsAdmin && (
        <>
          <div className="border-t border-gray-700 pt-4">
            <h3 className="text-lg font-semibold text-white mb-3">
              Create Admin Account
            </h3>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Username
            </label>
            <input
              type="text"
              value={state.adminUsername}
              onChange={(e) => onChange({ adminUsername: e.target.value })}
              placeholder="admin"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Email
            </label>
            <input
              type="email"
              value={state.adminEmail}
              onChange={(e) => onChange({ adminEmail: e.target.value })}
              placeholder="admin@example.com"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Password
            </label>
            <input
              type="password"
              value={state.adminPassword}
              onChange={(e) => onChange({ adminPassword: e.target.value })}
              placeholder="Choose a strong password"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
        </>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 2 - Tuners (Auto-discovery on mount)
// ---------------------------------------------------------------------------

function StepTuners({
  state,
  onChange,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
}) {
  const [discovering, setDiscovering] = useState(false)
  const [discovered, setDiscovered] = useState<WizardTuner[]>([])
  const [discoverError, setDiscoverError] = useState<string | null>(null)
  const [manualUrl, setManualUrl] = useState('')
  const [adding, setAdding] = useState(false)
  const [addError, setAddError] = useState<string | null>(null)
  const [hasScanned, setHasScanned] = useState(false)

  // Auto-discover on mount
  useEffect(() => {
    if (!hasScanned) {
      handleDiscover()
      setHasScanned(true)
    }
  }, [hasScanned])

  const handleDiscover = async () => {
    setDiscovering(true)
    setDiscoverError(null)
    try {
      const res = await fetch('/api/setup/tuners/discover', { method: 'POST', headers: authHeaders })
      if (!res.ok) throw new Error('Discovery failed')
      const data = await res.json() as { devices: Array<{ deviceId: string; modelNumber: string; baseUrl: string }> }
      const existingIds = new Set(state.tuners.map((t) => t.deviceId))
      const newDevices = (data.devices || []).filter((d) => !existingIds.has(d.deviceId))
      setDiscovered(newDevices)
      if (newDevices.length === 0 && (data.devices || []).length === 0) {
        setDiscoverError('No HDHomeRun devices found. You can add one manually or skip this step.')
      }
    } catch {
      setDiscoverError('Could not scan network. You can add a tuner manually or skip.')
    } finally {
      setDiscovering(false)
    }
  }

  const addDevice = async (url: string) => {
    setAdding(true)
    setAddError(null)
    try {
      const res = await fetch('/api/setup/tuners', {
        method: 'POST',
        headers: authHeaders,
        body: JSON.stringify({ url }),
      })
      if (!res.ok) {
        const err = await res.json().catch(() => ({})) as { message?: string }
        throw new Error(err.message || 'Failed to add tuner')
      }
      const data = await res.json() as { device: { deviceId: string; modelNumber: string; baseUrl: string }; imported: number }
      const newTuner: WizardTuner = {
        deviceId: data.device.deviceId,
        modelNumber: data.device.modelNumber,
        baseUrl: data.device.baseUrl,
        imported: data.imported ?? 0,
      }
      onChange({ tuners: [...state.tuners, newTuner] })
      setDiscovered((prev) => prev.filter((d) => d.deviceId !== data.device.deviceId))
      setManualUrl('')
    } catch (err) {
      setAddError(err instanceof Error ? err.message : 'Failed to add tuner')
    } finally {
      setAdding(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">Connect Your TV Tuner</h2>
        <p className="text-gray-400 mt-2">
          {discovering
            ? 'Scanning your network for HDHomeRun devices...'
            : 'Add your HDHomeRun to get live TV channels. Skip if you don\'t have one.'}
        </p>
      </div>

      {/* Discovering spinner */}
      {discovering && (
        <div className="flex items-center justify-center py-8">
          <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      )}

      {/* Already added */}
      {state.tuners.length > 0 && (
        <div className="space-y-2">
          <p className="text-xs font-semibold uppercase tracking-wider text-green-400">✓ Added</p>
          {state.tuners.map((t) => (
            <div key={t.deviceId} className="flex items-center gap-3 bg-green-500/10 border border-green-500/30 rounded-lg p-4">
              <CheckCircle className="w-6 h-6 text-green-400 shrink-0" />
              <div>
                <p className="text-white font-medium">{t.modelNumber || t.deviceId}</p>
                <p className="text-sm text-gray-400">{t.baseUrl} · {t.imported} channels</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Discovered devices */}
      {!discovering && discovered.length > 0 && (
        <div className="space-y-2">
          <p className="text-xs font-semibold uppercase tracking-wider text-indigo-400">Found on your network</p>
          {discovered.map((d) => (
            <div key={d.deviceId} className="flex items-center justify-between bg-indigo-500/10 border border-indigo-500/30 rounded-lg p-4">
              <div className="flex items-center gap-3">
                <Radio className="w-5 h-5 text-indigo-400" />
                <div>
                  <p className="text-white font-medium">{d.modelNumber || d.deviceId}</p>
                  <p className="text-sm text-gray-400">{d.baseUrl}</p>
                </div>
              </div>
              <button
                onClick={() => addDevice(d.baseUrl)}
                disabled={adding}
                className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white text-sm font-medium rounded-lg"
              >
                {adding ? <Loader className="w-4 h-4 animate-spin" /> : 'Add'}
              </button>
            </div>
          ))}
        </div>
      )}

      {/* No devices found message */}
      {!discovering && discovered.length === 0 && state.tuners.length === 0 && (
        <div className="text-center py-4">
          {discoverError ? (
            <p className="text-gray-400">{discoverError}</p>
          ) : (
            <p className="text-gray-400">No tuners found automatically.</p>
          )}
        </div>
      )}

      {/* Manual add (collapsed by default) */}
      {!discovering && (
        <details className="group">
          <summary className="cursor-pointer text-sm text-gray-400 hover:text-white">
            Add tuner manually...
          </summary>
          <div className="mt-3 flex gap-2">
            <input
              type="text"
              value={manualUrl}
              onChange={(e) => setManualUrl(e.target.value)}
              placeholder="IP address (e.g. 192.168.1.100)"
              className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
            <button
              onClick={() => addDevice(manualUrl.trim())}
              disabled={adding || !manualUrl.trim()}
              className="flex items-center gap-1.5 px-4 py-2 bg-gray-600 hover:bg-gray-500 disabled:opacity-40 text-white text-sm rounded-lg"
            >
              <Plus className="w-4 h-4" />
              Add
            </button>
          </div>
          {addError && <p className="text-sm text-red-400 mt-2">{addError}</p>}
        </details>
      )}

      {/* Re-scan button */}
      {!discovering && (
        <button
          onClick={handleDiscover}
          className="text-sm text-indigo-400 hover:text-indigo-300"
        >
          <Search className="w-4 h-4 inline mr-1" />
          Scan again
        </button>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 3 - Live TV (M3U) - Optional
// ---------------------------------------------------------------------------

function StepLiveTV({
  state,
  onChange,
}: {
  state: WizardState
  onChange: (patch: Partial<WizardState>) => void
}) {
  const [name, setName] = useState(state.m3uSource?.name || '')
  const [url, setUrl] = useState(state.m3uSource?.url || '')
  const [showForm, setShowForm] = useState(false)

  const handleSet = () => {
    if (name.trim() && url.trim()) {
      onChange({ m3uSource: { name: name.trim(), url: url.trim() } })
      setShowForm(false)
    }
  }

  const handleClear = () => {
    onChange({ m3uSource: undefined })
    setName('')
    setUrl('')
  }

  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold text-white">Extra Live TV Channels</h2>
        <p className="text-gray-400 mt-2">
          Have an M3U playlist or IPTV subscription? Add it here. Otherwise, skip to finish.
        </p>
      </div>

      {state.m3uSource ? (
        <div className="bg-green-500/10 border border-green-500/30 rounded-lg p-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <CheckCircle className="w-6 h-6 text-green-400" />
            <div>
              <p className="text-white font-medium">{state.m3uSource.name}</p>
              <p className="text-sm text-gray-400 truncate max-w-sm">
                {state.m3uSource.url}
              </p>
            </div>
          </div>
          <button
            onClick={handleClear}
            className="px-3 py-1.5 text-sm text-gray-400 hover:text-red-400"
          >
            Remove
          </button>
        </div>
      ) : showForm ? (
        <div className="space-y-4 bg-gray-700/30 rounded-xl p-4 border border-gray-700">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="My IPTV"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              M3U URL
            </label>
            <input
              type="url"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="http://example.com/playlist.m3u"
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <div className="flex gap-2">
            <button
              onClick={handleSet}
              disabled={!name.trim() || !url.trim()}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 text-white rounded-lg text-sm font-medium"
            >
              <Plus className="w-4 h-4" />
              Add
            </button>
            <button
              onClick={() => setShowForm(false)}
              className="px-4 py-2 text-gray-400 hover:text-white text-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <div className="text-center py-6">
          <button
            onClick={() => setShowForm(true)}
            className="px-6 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium transition-colors"
          >
            <Tv className="w-5 h-5 inline mr-2" />
            Add M3U Source
          </button>
          <p className="text-xs text-gray-500 mt-3">
            Don't have one? No problem — just click Next to finish.
          </p>
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Step 4 - Done
// ---------------------------------------------------------------------------

function StepDone({ state }: { state: WizardState }) {
  return (
    <div className="space-y-6 text-center">
      <div className="flex justify-center">
        <div className="w-20 h-20 bg-green-500/20 rounded-full flex items-center justify-center">
          <Rocket className="w-10 h-10 text-green-400" />
        </div>
      </div>

      <div>
        <h2 className="text-2xl font-bold text-white">You're All Set!</h2>
        <p className="text-gray-400 mt-2">
          Your OpenFlix server is ready to go.
        </p>
      </div>

      <div className="bg-gray-700/30 rounded-xl p-5 text-left space-y-3 max-w-sm mx-auto">
        <div className="flex items-center justify-between">
          <span className="text-gray-400">Server</span>
          <span className="text-white font-medium">
            {state.serverName || 'OpenFlix'}
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-gray-400">Tuners</span>
          <span className="text-white font-medium">
            {state.tuners.length > 0
              ? `${state.tuners.length} connected`
              : 'None (add later)'}
          </span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-gray-400">Live TV</span>
          <span className="text-white font-medium">
            {state.m3uSource ? state.m3uSource.name : 'HDHomeRun only'}
          </span>
        </div>
      </div>

      <div className="pt-4 border-t border-gray-700">
        <p className="text-sm text-gray-400 mb-2">
          Want to add media libraries, guide data, or configure DVR?
        </p>
        <a
          href="/ui/settings"
          className="inline-flex items-center gap-2 text-indigo-400 hover:text-indigo-300 text-sm"
        >
          <Settings className="w-4 h-4" />
          Go to Settings
        </a>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// SetupWizard (exported)
// ---------------------------------------------------------------------------

export function SetupWizardPage() {
  const [state, setState] = useState<WizardState>({
    step: 1,
    serverName: '',
    adminUsername: '',
    adminEmail: '',
    adminPassword: '',
    tuners: [],
    m3uSource: undefined,
  })

  const [needsAdmin, setNeedsAdmin] = useState(false)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Check initial status
  useEffect(() => {
    const check = async () => {
      try {
        const res = await fetch('/api/status', { headers: authHeaders })
        if (!res.ok) throw new Error('Failed to fetch status')
        const data: StatusResponse = await res.json()
        setState((s) => ({
          ...s,
          serverName: data.server?.name || '',
        }))
        if (data.libraries?.count === 0) {
          setNeedsAdmin(true)
        }
      } catch {
        setNeedsAdmin(true)
      } finally {
        setLoading(false)
      }
    }
    check()
  }, [])

  const patch = (changes: Partial<WizardState>) => {
    setState((prev) => ({ ...prev, ...changes }))
  }

  const canAdvance = (): boolean => {
    switch (state.step) {
      case 1:
        if (needsAdmin) {
          return (
            !!state.serverName.trim() &&
            !!state.adminUsername.trim() &&
            !!state.adminEmail.trim() &&
            !!state.adminPassword.trim()
          )
        }
        return !!state.serverName.trim()
      case 2: return true // tuners optional
      case 3: return true // M3U optional
      case 4: return true
      default: return false
    }
  }

  const submitStep = async (stepNum: number) => {
    setError(null)
    setSubmitting(true)
    try {
      switch (stepNum) {
        case 1: {
          // Register admin if needed
          if (needsAdmin) {
            const regRes = await fetch('/auth/register', {
              method: 'POST',
              headers: authHeaders,
              body: JSON.stringify({
                username: state.adminUsername,
                email: state.adminEmail,
                password: state.adminPassword,
              }),
            })
            if (!regRes.ok) {
              const errData = await regRes.json().catch(() => ({}))
              throw new Error(
                (errData as { error?: string }).error || 'Failed to create admin account'
              )
            }
            // Login to get token
            const loginRes = await fetch('/auth/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                username: state.adminUsername,
                password: state.adminPassword,
              }),
            })
            if (loginRes.ok) {
              const loginData = await loginRes.json()
              if (loginData.authToken) {
                localStorage.setItem('openflix_token', loginData.authToken)
                authHeaders['X-Plex-Token'] = loginData.authToken
              }
            }
          }
          // Update server name + enable DVR by default
          await fetch('/admin/settings', {
            method: 'PUT',
            headers: authHeaders,
            body: JSON.stringify({
              server_name: state.serverName,
              dvr_enabled: true,
              recording_dir: '/recordings',
            }),
          })
          break
        }
        case 2: {
          // Tuners already added in-step via API calls
          break
        }
        case 3: {
          // Add M3U source if provided
          if (state.m3uSource) {
            await fetch('/livetv/sources', {
              method: 'POST',
              headers: authHeaders,
              body: JSON.stringify({
                name: state.m3uSource.name,
                url: state.m3uSource.url,
              }),
            })
          }
          break
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
      setSubmitting(false)
      return false
    }
    setSubmitting(false)
    return true
  }

  const handleNext = async () => {
    if (state.step < TOTAL_STEPS) {
      const ok = await submitStep(state.step)
      if (ok) {
        patch({ step: state.step + 1 })
      }
    }
  }

  const handleBack = () => {
    if (state.step > 1) {
      patch({ step: state.step - 1 })
      setError(null)
    }
  }

  const handleFinish = () => {
    window.location.href = '/ui'
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-900 flex items-center justify-center p-6">
      <div className="w-full max-w-xl">
        <StepIndicator current={state.step} total={TOTAL_STEPS} />

        <div className="bg-gray-800 rounded-xl p-8 shadow-2xl">
          {state.step === 1 && (
            <StepWelcome state={state} onChange={patch} needsAdmin={needsAdmin} />
          )}
          {state.step === 2 && <StepTuners state={state} onChange={patch} />}
          {state.step === 3 && <StepLiveTV state={state} onChange={patch} />}
          {state.step === 4 && <StepDone state={state} />}

          {error && (
            <div className="mt-4 flex items-center gap-2 text-red-400 bg-red-500/10 border border-red-500/30 rounded-lg p-3 text-sm">
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
              {error}
            </div>
          )}

          {/* Navigation Buttons */}
          <div className="flex items-center justify-between mt-8 pt-6 border-t border-gray-700">
            {state.step > 1 && state.step < TOTAL_STEPS ? (
              <button
                onClick={handleBack}
                className="flex items-center gap-2 px-5 py-2.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium transition-colors"
              >
                <ArrowLeft className="w-4 h-4" />
                Back
              </button>
            ) : (
              <div />
            )}

            {state.step < TOTAL_STEPS ? (
              <button
                onClick={handleNext}
                disabled={!canAdvance() || submitting}
                className="flex items-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
              >
                {submitting ? (
                  <Loader className="w-4 h-4 animate-spin" />
                ) : (
                  <>
                    {state.step === 2 && state.tuners.length === 0
                      ? 'Skip'
                      : state.step === 3 && !state.m3uSource
                        ? 'Skip'
                        : 'Next'}
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
            ) : (
              <button
                onClick={handleFinish}
                className="flex items-center gap-2 px-6 py-2.5 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium transition-colors"
              >
                Start Watching
                <ArrowRight className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
