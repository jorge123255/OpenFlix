import { useState } from 'react'
import {
  RefreshCw,
  Download,
  CheckCircle,
  AlertTriangle,
  Loader,
  Server,
  ArrowRight,
  Clock,
  Tag,
  FileText,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

interface UpdaterStatus {
  currentVersion: string
  latestVersion?: string
  updateAvailable: boolean
  lastChecked?: string
  releaseNotes?: string
  releaseDate?: string
  downloadUrl?: string
  changelog?: string[]
}

const TOKEN_KEY = 'openflix_token'

function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString()
}

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime()
  const minutes = Math.floor(diff / 60000)
  if (minutes < 1) return 'just now'
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return `${days}d ago`
}

async function fetchUpdaterStatus(): Promise<UpdaterStatus> {
  const res = await fetch('/admin/updater/status', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch updater status')
  return res.json()
}

async function checkForUpdates(): Promise<UpdaterStatus> {
  const res = await fetch('/admin/updater/check', {
    method: 'POST',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to check for updates')
  return res.json()
}

async function applyUpdate(): Promise<void> {
  const res = await fetch('/admin/updater/apply', {
    method: 'POST',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to apply update')
}

export function UpdaterPage() {
  const queryClient = useQueryClient()
  const [confirmApply, setConfirmApply] = useState(false)
  const [applySuccess, setApplySuccess] = useState(false)

  const { data: status, isLoading, error, refetch } = useQuery({
    queryKey: ['updaterStatus'],
    queryFn: fetchUpdaterStatus,
  })

  const checkMutation = useMutation({
    mutationFn: checkForUpdates,
    onSuccess: (data) => {
      queryClient.setQueryData(['updaterStatus'], data)
    },
  })

  const applyMutation = useMutation({
    mutationFn: applyUpdate,
    onSuccess: () => {
      setConfirmApply(false)
      setApplySuccess(true)
    },
  })

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <AlertTriangle className="h-12 w-12 text-red-400" />
        <h3 className="text-lg font-medium text-white">Failed to load updater status</h3>
        <p className="text-gray-400 text-sm">{(error as Error).message}</p>
        <button
          onClick={() => refetch()}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
        >
          <RefreshCw className="h-4 w-4" />
          Retry
        </button>
      </div>
    )
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white flex items-center gap-3">
          <RefreshCw className="h-7 w-7 text-indigo-400" />
          Server Updates
        </h1>
        <p className="text-gray-400 mt-1">Manage OpenFlix server updates</p>
      </div>

      {/* Apply Success Banner */}
      {applySuccess && (
        <div className="mb-6 p-4 bg-green-500/10 border border-green-500/30 rounded-xl">
          <div className="flex items-start gap-3">
            <CheckCircle className="h-5 w-5 text-green-400 mt-0.5" />
            <div>
              <h3 className="text-sm font-medium text-green-400">Update applied successfully</h3>
              <p className="text-xs text-gray-400 mt-1">
                The server is restarting with the new version. This page will reload automatically
                once the server is back online. If it does not reload, try refreshing the page manually.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Current Version Card */}
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-indigo-600/20 rounded-lg">
              <Server className="h-8 w-8 text-indigo-400" />
            </div>
            <div>
              <p className="text-sm text-gray-400">Current Version</p>
              <p className="text-3xl font-bold text-white">{status?.currentVersion || 'Unknown'}</p>
            </div>
          </div>
          <button
            onClick={() => checkMutation.mutate()}
            disabled={checkMutation.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 text-white rounded-lg"
          >
            {checkMutation.isPending ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            {checkMutation.isPending ? 'Checking...' : 'Check for Updates'}
          </button>
        </div>
        {status?.lastChecked && (
          <p className="text-xs text-gray-500 mt-3 flex items-center gap-1.5">
            <Clock className="h-3 w-3" />
            Last checked: {formatDate(status.lastChecked)} ({timeAgo(status.lastChecked)})
          </p>
        )}
      </div>

      {/* Check Error */}
      {checkMutation.error && (
        <div className="mb-6 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">{(checkMutation.error as Error).message}</span>
        </div>
      )}

      {/* Apply Error */}
      {applyMutation.error && (
        <div className="mb-6 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">{(applyMutation.error as Error).message}</span>
        </div>
      )}

      {/* Update Available */}
      {status?.updateAvailable && status.latestVersion ? (
        <div className="bg-gray-800 rounded-xl overflow-hidden mb-6">
          {/* Update Header */}
          <div className="p-6 border-b border-gray-700">
            <div className="flex items-center justify-between">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <span className="px-2.5 py-1 bg-green-600/20 text-green-400 border border-green-500/30 rounded-full text-xs font-medium">
                    Update Available
                  </span>
                </div>
                <div className="flex items-center gap-3 text-lg">
                  <span className="text-gray-400 font-mono">{status.currentVersion}</span>
                  <ArrowRight className="h-5 w-5 text-gray-500" />
                  <span className="text-green-400 font-bold font-mono">{status.latestVersion}</span>
                </div>
                {status.releaseDate && (
                  <p className="text-xs text-gray-500 mt-2 flex items-center gap-1.5">
                    <Tag className="h-3 w-3" />
                    Released: {formatDate(status.releaseDate)}
                  </p>
                )}
              </div>
              {!confirmApply ? (
                <button
                  onClick={() => setConfirmApply(true)}
                  className="flex items-center gap-2 px-5 py-2.5 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium"
                >
                  <Download className="h-4 w-4" />
                  Update Now
                </button>
              ) : (
                <div className="flex flex-col items-end gap-2">
                  <p className="text-xs text-yellow-400">The server will restart during the update.</p>
                  <div className="flex gap-2">
                    <button
                      onClick={() => applyMutation.mutate()}
                      disabled={applyMutation.isPending}
                      className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 disabled:bg-green-800 text-white rounded-lg text-sm"
                    >
                      {applyMutation.isPending ? (
                        <Loader className="h-4 w-4 animate-spin" />
                      ) : (
                        <Download className="h-4 w-4" />
                      )}
                      {applyMutation.isPending ? 'Applying...' : 'Confirm Update'}
                    </button>
                    <button
                      onClick={() => setConfirmApply(false)}
                      className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Release Notes */}
          {(status.releaseNotes || (status.changelog && status.changelog.length > 0)) && (
            <div className="p-6">
              <h3 className="text-sm font-medium text-gray-300 mb-3 flex items-center gap-2">
                <FileText className="h-4 w-4" />
                Release Notes
              </h3>
              {status.releaseNotes ? (
                <div className="bg-gray-900 rounded-lg p-4 text-sm text-gray-300 leading-relaxed whitespace-pre-wrap font-mono">
                  {status.releaseNotes}
                </div>
              ) : status.changelog ? (
                <ul className="space-y-1.5">
                  {status.changelog.map((entry, i) => (
                    <li key={i} className="text-sm text-gray-300 flex items-start gap-2">
                      <span className="text-indigo-400 mt-1">-</span>
                      {entry}
                    </li>
                  ))}
                </ul>
              ) : null}
            </div>
          )}
        </div>
      ) : status && !status.updateAvailable ? (
        /* Up to Date */
        <div className="bg-gray-800 rounded-xl p-8 text-center">
          <CheckCircle className="h-16 w-16 text-green-400 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-white mb-2">You're up to date!</h3>
          <p className="text-gray-400">
            OpenFlix {status.currentVersion} is the latest version.
          </p>
          {status.lastChecked && (
            <p className="text-xs text-gray-500 mt-3">
              Last checked {timeAgo(status.lastChecked)}
            </p>
          )}
        </div>
      ) : null}
    </div>
  )
}
