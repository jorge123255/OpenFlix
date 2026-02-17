import { useState, useCallback } from 'react'
import { Gauge, Zap, Loader, Trash2, Clock, ArrowDown, ArrowUp, Wifi } from 'lucide-react'

const authFetch = async (url: string, options?: RequestInit) => {
  const token = localStorage.getItem('openflix_token') || ''
  const res = await fetch(url, {
    ...options,
    headers: { 'X-Plex-Token': token, 'Content-Type': 'application/json', ...options?.headers },
  })
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res
}

interface SpeedTestResult {
  id: string
  timestamp: string
  latency: number
  download: number
  upload: number
}

type TestPhase = 'idle' | 'latency' | 'download' | 'upload' | 'complete'

const HISTORY_KEY = 'openflix_speedtest_history'

function loadHistory(): SpeedTestResult[] {
  try {
    const raw = localStorage.getItem(HISTORY_KEY)
    return raw ? JSON.parse(raw) : []
  } catch {
    return []
  }
}

function saveHistory(results: SpeedTestResult[]) {
  localStorage.setItem(HISTORY_KEY, JSON.stringify(results.slice(0, 20)))
}

function SpeedGauge({ speed, max = 1000 }: { speed: number; max?: number }) {
  const percentage = Math.min((speed / max) * 100, 100)
  const arcLength = 283 // approx circumference * 270/360
  const offset = arcLength - (percentage / 100) * arcLength
  const bgOffset = 377 - arcLength // offset to show only 270 degrees

  return (
    <div className="relative w-64 h-64 mx-auto">
      <svg className="w-full h-full" viewBox="0 0 200 200">
        {/* Background arc */}
        <circle
          cx="100"
          cy="100"
          r="80"
          fill="none"
          stroke="#374151"
          strokeWidth="12"
          strokeDasharray="377"
          strokeDashoffset={bgOffset}
          strokeLinecap="round"
          transform="rotate(135 100 100)"
        />
        {/* Foreground arc */}
        <circle
          cx="100"
          cy="100"
          r="80"
          fill="none"
          stroke="#6366f1"
          strokeWidth="12"
          strokeDasharray={`${arcLength} 377`}
          strokeDashoffset={offset}
          strokeLinecap="round"
          transform="rotate(135 100 100)"
          className="transition-all duration-500"
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-4xl font-bold text-white">{speed.toFixed(1)}</span>
        <span className="text-gray-400 text-sm">Mbps</span>
      </div>
    </div>
  )
}

function PhaseIndicator({ phase, currentPhase }: { phase: TestPhase; currentPhase: TestPhase }) {
  const phases: TestPhase[] = ['latency', 'download', 'upload']
  const currentIdx = phases.indexOf(currentPhase)
  const thisIdx = phases.indexOf(phase)

  const isActive = currentPhase === phase
  const isComplete = currentPhase === 'complete' || currentIdx > thisIdx

  const labels: Record<string, string> = {
    latency: 'Latency',
    download: 'Download',
    upload: 'Upload',
  }

  const icons: Record<string, React.ReactNode> = {
    latency: <Clock className="h-4 w-4" />,
    download: <ArrowDown className="h-4 w-4" />,
    upload: <ArrowUp className="h-4 w-4" />,
  }

  return (
    <div
      className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
        isActive
          ? 'bg-indigo-600 text-white'
          : isComplete
            ? 'bg-green-500/20 text-green-400'
            : 'bg-gray-700 text-gray-500'
      }`}
    >
      {isActive && <Loader className="h-4 w-4 animate-spin" />}
      {!isActive && icons[phase]}
      {labels[phase]}
    </div>
  )
}

export function SpeedTestPage() {
  const [phase, setPhase] = useState<TestPhase>('idle')
  const [currentSpeed, setCurrentSpeed] = useState(0)
  const [latency, setLatency] = useState(0)
  const [downloadSpeed, setDownloadSpeed] = useState(0)
  const [uploadSpeed, setUploadSpeed] = useState(0)
  const [history, setHistory] = useState<SpeedTestResult[]>(loadHistory)
  const [error, setError] = useState<string | null>(null)

  const testLatency = useCallback(async (): Promise<number> => {
    const times: number[] = []
    for (let i = 0; i < 5; i++) {
      const start = performance.now()
      await authFetch('/api/speedtest/ping')
      const end = performance.now()
      times.push(end - start)
    }
    // Remove highest and lowest, average the rest
    times.sort((a, b) => a - b)
    const trimmed = times.slice(1, -1)
    return trimmed.reduce((sum, t) => sum + t, 0) / trimmed.length
  }, [])

  const testDownload = useCallback(async (): Promise<number> => {
    const size = 100_000_000 // 100 MB for accurate LAN measurement
    const token = localStorage.getItem('openflix_token') || ''
    const start = performance.now()
    const res = await fetch(`/api/speedtest/download?size=${size}`, {
      headers: { 'X-Plex-Token': token },
    })
    if (!res.ok) throw new Error('Download test failed')

    const reader = res.body?.getReader()
    let received = 0
    if (reader) {
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        received += value.length
        // Update speed display during download
        const elapsed = (performance.now() - start) / 1000
        if (elapsed > 0) {
          const mbps = (received * 8) / (elapsed * 1_000_000)
          setCurrentSpeed(mbps)
        }
      }
    }
    const elapsed = (performance.now() - start) / 1000
    return (received * 8) / (elapsed * 1_000_000) // Mbps
  }, [])

  const testUpload = useCallback(async (): Promise<number> => {
    const size = 50_000_000 // 50 MB for accurate LAN measurement
    const data = new Uint8Array(size)
    // Fill with random-ish data (crypto.getRandomValues has 64KB limit, use PRNG)
    for (let i = 0; i < size; i++) {
      data[i] = (i * 7 + 13) & 0xff
    }
    const token = localStorage.getItem('openflix_token') || ''
    const start = performance.now()
    const res = await fetch('/api/speedtest/upload', {
      method: 'POST',
      headers: { 'X-Plex-Token': token },
      body: data,
    })
    if (!res.ok) throw new Error('Upload test failed')
    const elapsed = (performance.now() - start) / 1000
    return (size * 8) / (elapsed * 1_000_000) // Mbps
  }, [])

  const runTest = useCallback(async () => {
    setError(null)
    setCurrentSpeed(0)
    setLatency(0)
    setDownloadSpeed(0)
    setUploadSpeed(0)

    try {
      // Latency
      setPhase('latency')
      const lat = await testLatency()
      setLatency(lat)

      // Download
      setPhase('download')
      setCurrentSpeed(0)
      const dl = await testDownload()
      setDownloadSpeed(dl)
      setCurrentSpeed(dl)

      // Upload
      setPhase('upload')
      setCurrentSpeed(0)
      const ul = await testUpload()
      setUploadSpeed(ul)
      setCurrentSpeed(ul)

      // Complete
      setPhase('complete')
      setCurrentSpeed(Math.max(dl, ul))

      // Save to history
      const result: SpeedTestResult = {
        id: Date.now().toString(),
        timestamp: new Date().toISOString(),
        latency: Math.round(lat * 10) / 10,
        download: Math.round(dl * 10) / 10,
        upload: Math.round(ul * 10) / 10,
      }
      const updated = [result, ...history].slice(0, 20)
      setHistory(updated)
      saveHistory(updated)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Speed test failed')
      setPhase('idle')
    }
  }, [testLatency, testDownload, testUpload, history])

  const clearHistory = () => {
    setHistory([])
    localStorage.removeItem(HISTORY_KEY)
  }

  const displaySpeed =
    phase === 'complete'
      ? downloadSpeed
      : phase === 'upload'
        ? currentSpeed || uploadSpeed
        : currentSpeed || downloadSpeed

  return (
    <div>
      <div className="mb-8">
        <div className="flex items-center gap-3">
          <Gauge className="h-6 w-6 text-indigo-400" />
          <h1 className="text-2xl font-bold text-white">Speed Test</h1>
        </div>
        <p className="text-gray-400 mt-1">Test network speed between your browser and the server</p>
      </div>

      {/* Speed Gauge */}
      <div className="bg-gray-800 rounded-xl p-8 mb-6">
        <SpeedGauge speed={displaySpeed} />

        {/* Phase Indicators */}
        <div className="flex justify-center gap-3 mt-6">
          <PhaseIndicator phase="latency" currentPhase={phase} />
          <PhaseIndicator phase="download" currentPhase={phase} />
          <PhaseIndicator phase="upload" currentPhase={phase} />
        </div>

        {/* Start Button */}
        <div className="text-center mt-8">
          {phase === 'idle' || phase === 'complete' ? (
            <button
              onClick={runTest}
              className="inline-flex items-center gap-2 px-8 py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-xl text-lg transition-colors"
            >
              <Zap className="h-5 w-5" />
              {phase === 'complete' ? 'Test Again' : 'Start Test'}
            </button>
          ) : (
            <div className="text-gray-400">
              <Loader className="h-6 w-6 animate-spin mx-auto mb-2" />
              Testing...
            </div>
          )}
        </div>

        {/* Error */}
        {error && (
          <div className="mt-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg text-center">
            <span className="text-red-400 text-sm">{error}</span>
          </div>
        )}

        {/* Results */}
        {phase === 'complete' && (
          <div className="grid grid-cols-3 gap-4 mt-8">
            <div className="bg-gray-700/50 rounded-xl p-4 text-center">
              <div className="flex items-center justify-center gap-2 mb-2">
                <Clock className="h-4 w-4 text-yellow-400" />
                <span className="text-sm text-gray-400">Latency</span>
              </div>
              <p className="text-2xl font-bold text-white">{latency.toFixed(1)}</p>
              <p className="text-xs text-gray-500">ms</p>
            </div>
            <div className="bg-gray-700/50 rounded-xl p-4 text-center">
              <div className="flex items-center justify-center gap-2 mb-2">
                <ArrowDown className="h-4 w-4 text-green-400" />
                <span className="text-sm text-gray-400">Download</span>
              </div>
              <p className="text-2xl font-bold text-white">{downloadSpeed.toFixed(1)}</p>
              <p className="text-xs text-gray-500">Mbps</p>
            </div>
            <div className="bg-gray-700/50 rounded-xl p-4 text-center">
              <div className="flex items-center justify-center gap-2 mb-2">
                <ArrowUp className="h-4 w-4 text-blue-400" />
                <span className="text-sm text-gray-400">Upload</span>
              </div>
              <p className="text-2xl font-bold text-white">{uploadSpeed.toFixed(1)}</p>
              <p className="text-xs text-gray-500">Mbps</p>
            </div>
          </div>
        )}
      </div>

      {/* History */}
      <div className="bg-gray-800 rounded-xl p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Wifi className="h-5 w-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-white">Test History</h2>
          </div>
          {history.length > 0 && (
            <button
              onClick={clearHistory}
              className="flex items-center gap-1 px-3 py-1.5 text-sm text-gray-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
            >
              <Trash2 className="h-3.5 w-3.5" />
              Clear
            </button>
          )}
        </div>

        {history.length === 0 ? (
          <div className="text-center py-8">
            <Gauge className="h-12 w-12 text-gray-600 mx-auto mb-3" />
            <p className="text-gray-400">No test history yet</p>
            <p className="text-gray-500 text-sm mt-1">Run a speed test to see results here.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-700">
                  <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">Date</th>
                  <th className="text-right py-3 px-4 text-sm font-medium text-gray-400">Latency</th>
                  <th className="text-right py-3 px-4 text-sm font-medium text-gray-400">Download</th>
                  <th className="text-right py-3 px-4 text-sm font-medium text-gray-400">Upload</th>
                </tr>
              </thead>
              <tbody>
                {history.map((result) => (
                  <tr key={result.id} className="border-b border-gray-700/50 hover:bg-gray-700/30">
                    <td className="py-3 px-4 text-sm text-gray-300">
                      {new Date(result.timestamp).toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-sm text-right">
                      <span className="text-yellow-400">{result.latency} ms</span>
                    </td>
                    <td className="py-3 px-4 text-sm text-right">
                      <span className="text-green-400">{result.download} Mbps</span>
                    </td>
                    <td className="py-3 px-4 text-sm text-right">
                      <span className="text-blue-400">{result.upload} Mbps</span>
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
