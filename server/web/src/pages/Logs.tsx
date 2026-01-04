import { useState, useEffect, useRef } from 'react'
import { FileText, RefreshCw, Trash2, Download, ArrowDown } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

interface LogsResponse {
  lines: string[]
  count: number
  path: string
  level: string
}

function useServerLogs(autoRefresh: boolean) {
  return useQuery({
    queryKey: ['serverLogs'],
    queryFn: async (): Promise<LogsResponse> => {
      const response = await fetch('/api/logs?lines=1000', {
        headers: {
          'X-Plex-Token': localStorage.getItem('openflix_token') || '',
        },
      })
      if (!response.ok) throw new Error('Failed to fetch logs')
      return response.json()
    },
    refetchInterval: autoRefresh ? 5000 : false,
  })
}

function useClearLogs() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      const response = await fetch('/api/logs', {
        method: 'DELETE',
        headers: {
          'X-Plex-Token': localStorage.getItem('openflix_token') || '',
        },
      })
      if (!response.ok) throw new Error('Failed to clear logs')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['serverLogs'] })
    },
  })
}

function getLogLevel(line: string): 'debug' | 'info' | 'warn' | 'error' | null {
  if (line.includes('level=debug') || line.includes('"level":"debug"')) return 'debug'
  if (line.includes('level=info') || line.includes('"level":"info"')) return 'info'
  if (line.includes('level=warning') || line.includes('"level":"warning"')) return 'warn'
  if (line.includes('level=error') || line.includes('"level":"error"')) return 'error'
  return null
}

const levelColors = {
  debug: 'text-gray-400',
  info: 'text-blue-400',
  warn: 'text-yellow-400',
  error: 'text-red-400',
}

export function LogsPage() {
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [filter, setFilter] = useState<'all' | 'debug' | 'info' | 'warn' | 'error'>('all')
  const [search, setSearch] = useState('')
  const { data: logs, isLoading, refetch } = useServerLogs(autoRefresh)
  const clearLogs = useClearLogs()
  const logsEndRef = useRef<HTMLDivElement>(null)
  const [autoScroll, setAutoScroll] = useState(true)

  useEffect(() => {
    if (autoScroll && logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: 'smooth' })
    }
  }, [logs?.lines, autoScroll])

  const filteredLines = logs?.lines.filter((line) => {
    // Level filter
    if (filter !== 'all') {
      const level = getLogLevel(line)
      if (level !== filter) return false
    }
    // Search filter
    if (search && !line.toLowerCase().includes(search.toLowerCase())) {
      return false
    }
    return true
  }) || []

  const handleDownload = () => {
    if (!logs?.lines) return
    const content = logs.lines.join('\n')
    const blob = new Blob([content], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `openflix-logs-${new Date().toISOString().split('T')[0]}.log`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="h-full flex flex-col">
      <div className="mb-4">
        <h1 className="text-2xl font-bold text-white">Server Logs</h1>
        <p className="text-gray-400 mt-1">
          {logs?.path ? `Log file: ${logs.path}` : 'View server logs in real-time'}
        </p>
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3 mb-4">
        {/* Search */}
        <input
          type="text"
          placeholder="Search logs..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm w-64"
        />

        {/* Level filter */}
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value as any)}
          className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
        >
          <option value="all">All Levels</option>
          <option value="debug">Debug</option>
          <option value="info">Info</option>
          <option value="warn">Warning</option>
          <option value="error">Error</option>
        </select>

        {/* Auto-refresh toggle */}
        <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer">
          <input
            type="checkbox"
            checked={autoRefresh}
            onChange={(e) => setAutoRefresh(e.target.checked)}
            className="rounded bg-gray-700 border-gray-600"
          />
          Auto-refresh
        </label>

        {/* Auto-scroll toggle */}
        <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer">
          <input
            type="checkbox"
            checked={autoScroll}
            onChange={(e) => setAutoScroll(e.target.checked)}
            className="rounded bg-gray-700 border-gray-600"
          />
          Auto-scroll
        </label>

        <div className="flex-1" />

        {/* Actions */}
        <button
          onClick={() => refetch()}
          className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
        >
          <RefreshCw className="h-4 w-4" />
          Refresh
        </button>

        <button
          onClick={handleDownload}
          disabled={!logs?.lines.length}
          className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 disabled:opacity-50 text-white rounded-lg text-sm"
        >
          <Download className="h-4 w-4" />
          Download
        </button>

        <button
          onClick={() => {
            if (confirm('Are you sure you want to clear all logs?')) {
              clearLogs.mutate()
            }
          }}
          disabled={clearLogs.isPending}
          className="flex items-center gap-2 px-3 py-2 bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white rounded-lg text-sm"
        >
          <Trash2 className="h-4 w-4" />
          Clear
        </button>
      </div>

      {/* Log count */}
      <div className="text-sm text-gray-400 mb-2">
        Showing {filteredLines.length} of {logs?.count || 0} log entries
        {logs?.level && <span className="ml-2">(Log level: {logs.level})</span>}
      </div>

      {/* Logs container */}
      <div className="flex-1 bg-gray-900 rounded-xl overflow-hidden">
        {isLoading ? (
          <div className="p-4 text-gray-400">Loading logs...</div>
        ) : filteredLines.length === 0 ? (
          <div className="p-8 text-center">
            <FileText className="h-12 w-12 text-gray-600 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-white mb-2">No logs found</h3>
            <p className="text-gray-400">
              {search || filter !== 'all' ? 'Try adjusting your filters' : 'Logs will appear here as they are generated'}
            </p>
          </div>
        ) : (
          <div className="h-full overflow-auto p-4 font-mono text-xs leading-relaxed">
            {filteredLines.map((line, index) => {
              const level = getLogLevel(line)
              return (
                <div
                  key={index}
                  className={`${level ? levelColors[level] : 'text-gray-300'} hover:bg-gray-800 px-1 -mx-1 rounded`}
                >
                  {line}
                </div>
              )
            })}
            <div ref={logsEndRef} />
          </div>
        )}
      </div>

      {/* Scroll to bottom button */}
      {!autoScroll && (
        <button
          onClick={() => logsEndRef.current?.scrollIntoView({ behavior: 'smooth' })}
          className="fixed bottom-8 right-8 p-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-full shadow-lg"
        >
          <ArrowDown className="h-5 w-5" />
        </button>
      )}
    </div>
  )
}
