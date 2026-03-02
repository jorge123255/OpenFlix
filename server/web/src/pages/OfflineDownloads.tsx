import { useState, useEffect } from 'react'
import {
  CloudDownload,
  Trash2,
  RefreshCw,
  AlertTriangle,
  Loader,
  HardDrive,
  Smartphone,
  Clock,
  CheckCircle2,
  XCircle,
  PauseCircle,
  Settings,
  Save,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

interface OfflineDownload {
  id: number
  userId: number
  deviceId: string
  mediaItemId: number
  mediaFileId: number
  title: string
  quality: string
  fileSize: number
  status: string
  progress: number
  expiresAt: string
  watchedPosition: number
  watched: boolean
  createdAt: string
  updatedAt: string
}

interface DownloadsResponse {
  downloads: OfflineDownload[]
  count: number
  totalSize: number
  activeCount: number
}

interface OfflineSettings {
  maxDownloads: number
  expiryDays: number
  allowedQualities: string[]
}

const TOKEN_KEY = 'openflix_token'

function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString()
}

function formatRelativeDate(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = date.getTime() - now.getTime()
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24))
  if (diffDays < 0) return 'Expired'
  if (diffDays === 0) return 'Today'
  if (diffDays === 1) return 'Tomorrow'
  return `${diffDays} days`
}

function statusBadge(status: string) {
  switch (status) {
    case 'pending':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-yellow-500/20 text-yellow-400 border border-yellow-500/30">
          <Clock className="h-3 w-3" />
          Pending
        </span>
      )
    case 'downloading':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-blue-500/20 text-blue-400 border border-blue-500/30">
          <CloudDownload className="h-3 w-3" />
          Downloading
        </span>
      )
    case 'completed':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-500/20 text-green-400 border border-green-500/30">
          <CheckCircle2 className="h-3 w-3" />
          Completed
        </span>
      )
    case 'expired':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-gray-500/20 text-gray-400 border border-gray-500/30">
          <XCircle className="h-3 w-3" />
          Expired
        </span>
      )
    case 'deleted':
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-red-500/20 text-red-400 border border-red-500/30">
          <Trash2 className="h-3 w-3" />
          Deleted
        </span>
      )
    default:
      return (
        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-gray-500/20 text-gray-400 border border-gray-500/30">
          <PauseCircle className="h-3 w-3" />
          {status}
        </span>
      )
  }
}

function qualityBadge(quality: string) {
  const colors: Record<string, string> = {
    original: 'bg-purple-500/20 text-purple-400 border-purple-500/30',
    high: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
    medium: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
    low: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
  }
  const color = colors[quality] || colors.low
  return (
    <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium border ${color}`}>
      {quality}
    </span>
  )
}

async function fetchDownloads(): Promise<DownloadsResponse> {
  const res = await fetch('/api/offline/downloads', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch offline downloads')
  return res.json()
}

async function fetchSettings(): Promise<OfflineSettings> {
  const res = await fetch('/api/offline/settings', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch settings')
  return res.json()
}

async function deleteDownload(id: number): Promise<void> {
  const res = await fetch(`/api/offline/${id}`, {
    method: 'DELETE',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to delete download')
}

async function updateSettings(data: Partial<OfflineSettings>): Promise<OfflineSettings> {
  const res = await fetch('/api/offline/settings', {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'X-Plex-Token': getToken(),
    },
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error('Failed to update settings')
  return res.json()
}

export function OfflineDownloadsPage() {
  const queryClient = useQueryClient()
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null)
  const [showSettings, setShowSettings] = useState(false)
  const [editMaxDownloads, setEditMaxDownloads] = useState<number>(25)
  const [editExpiryDays, setEditExpiryDays] = useState<number>(30)

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['offline-downloads'],
    queryFn: fetchDownloads,
  })

  const { data: settings } = useQuery({
    queryKey: ['offline-settings'],
    queryFn: fetchSettings,
  })

  useEffect(() => {
    if (settings) {
      setEditMaxDownloads(settings.maxDownloads)
      setEditExpiryDays(settings.expiryDays)
    }
  }, [settings])

  const deleteMutation = useMutation({
    mutationFn: deleteDownload,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['offline-downloads'] })
      setConfirmDeleteId(null)
    },
  })

  const settingsMutation = useMutation({
    mutationFn: updateSettings,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['offline-settings'] })
    },
  })

  const downloads = data?.downloads || []
  const filteredDownloads =
    statusFilter === 'all'
      ? downloads
      : downloads.filter((d) => d.status === statusFilter)

  const totalSize = data?.totalSize || 0
  const activeCount = data?.activeCount || 0

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
        <h3 className="text-lg font-medium text-white">Failed to load offline downloads</h3>
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
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-3">
            <CloudDownload className="h-7 w-7 text-indigo-400" />
            Offline Downloads
          </h1>
          <p className="text-gray-400 mt-1">
            Manage media downloaded to client devices for offline viewing
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setShowSettings(!showSettings)}
            className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
          >
            <Settings className="h-4 w-4" />
            Settings
          </button>
          <button
            onClick={() => refetch()}
            className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-gray-800 rounded-xl p-5 border border-gray-700">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-indigo-500/20 rounded-lg">
              <CloudDownload className="h-5 w-5 text-indigo-400" />
            </div>
            <span className="text-sm text-gray-400">Total Downloads</span>
          </div>
          <p className="text-2xl font-bold text-white">{downloads.length}</p>
        </div>
        <div className="bg-gray-800 rounded-xl p-5 border border-gray-700">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-green-500/20 rounded-lg">
              <HardDrive className="h-5 w-5 text-green-400" />
            </div>
            <span className="text-sm text-gray-400">Total Storage Used</span>
          </div>
          <p className="text-2xl font-bold text-white">{formatBytes(totalSize)}</p>
        </div>
        <div className="bg-gray-800 rounded-xl p-5 border border-gray-700">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-blue-500/20 rounded-lg">
              <Smartphone className="h-5 w-5 text-blue-400" />
            </div>
            <span className="text-sm text-gray-400">Active Downloads</span>
          </div>
          <p className="text-2xl font-bold text-white">{activeCount}</p>
        </div>
      </div>

      {/* Settings Panel */}
      {showSettings && settings && (
        <div className="mb-6 bg-gray-800 rounded-xl p-6 border border-gray-700">
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <Settings className="h-5 w-5 text-gray-400" />
            Offline Download Settings
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-1">
                Max Downloads per Device
              </label>
              <input
                type="number"
                min={1}
                value={editMaxDownloads}
                onChange={(e) => setEditMaxDownloads(parseInt(e.target.value) || 1)}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-1">
                Expiry (days)
              </label>
              <input
                type="number"
                min={1}
                value={editExpiryDays}
                onChange={(e) => setEditExpiryDays(parseInt(e.target.value) || 1)}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-1">
                Allowed Qualities
              </label>
              <p className="text-sm text-gray-300">
                {settings.allowedQualities?.join(', ') || 'original, high, medium, low'}
              </p>
            </div>
          </div>
          <div className="mt-4 flex justify-end">
            <button
              onClick={() =>
                settingsMutation.mutate({
                  maxDownloads: editMaxDownloads,
                  expiryDays: editExpiryDays,
                })
              }
              disabled={settingsMutation.isPending}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg text-sm"
            >
              <Save className="h-4 w-4" />
              {settingsMutation.isPending ? 'Saving...' : 'Save Settings'}
            </button>
          </div>
          {settingsMutation.error && (
            <div className="mt-3 p-2 bg-red-500/10 border border-red-500/30 rounded-lg">
              <span className="text-red-400 text-sm">
                {(settingsMutation.error as Error).message}
              </span>
            </div>
          )}
        </div>
      )}

      {/* Status Filter */}
      <div className="flex items-center gap-2 mb-4">
        {['all', 'pending', 'downloading', 'completed', 'expired'].map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
              statusFilter === status
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
          >
            {status.charAt(0).toUpperCase() + status.slice(1)}
          </button>
        ))}
      </div>

      {/* Empty State */}
      {filteredDownloads.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-64 bg-gray-800 rounded-xl">
          <CloudDownload className="h-16 w-16 text-gray-600 mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No offline downloads</h3>
          <p className="text-gray-400 text-sm">
            {statusFilter === 'all'
              ? 'No media has been downloaded for offline viewing yet'
              : `No downloads with status "${statusFilter}"`}
          </p>
        </div>
      ) : (
        /* Downloads Table */
        <div className="bg-gray-800 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="text-left text-sm text-gray-400 border-b border-gray-700">
                  <th className="px-6 py-4 font-medium">Title</th>
                  <th className="px-6 py-4 font-medium">Device</th>
                  <th className="px-6 py-4 font-medium">Quality</th>
                  <th className="px-6 py-4 font-medium">Size</th>
                  <th className="px-6 py-4 font-medium">Status</th>
                  <th className="px-6 py-4 font-medium">Progress</th>
                  <th className="px-6 py-4 font-medium">Expires</th>
                  <th className="px-6 py-4 font-medium">Watch State</th>
                  <th className="px-6 py-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="text-sm">
                {filteredDownloads.map((download) => (
                  <tr
                    key={download.id}
                    className="border-b border-gray-700/50 hover:bg-gray-700/30 transition-colors"
                  >
                    <td className="px-6 py-4">
                      <p className="text-white font-medium">{download.title}</p>
                      <p className="text-gray-500 text-xs mt-0.5">
                        ID: {download.mediaItemId}
                      </p>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1.5">
                        <Smartphone className="h-3.5 w-3.5 text-gray-500" />
                        <span className="text-gray-300 text-xs">{download.deviceId}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">{qualityBadge(download.quality)}</td>
                    <td className="px-6 py-4 text-gray-300">
                      <div className="flex items-center gap-1.5">
                        <HardDrive className="h-3.5 w-3.5 text-gray-500" />
                        {formatBytes(download.fileSize)}
                      </div>
                    </td>
                    <td className="px-6 py-4">{statusBadge(download.status)}</td>
                    <td className="px-6 py-4">
                      <div className="w-24">
                        <div className="flex items-center gap-2">
                          <div className="flex-1 bg-gray-700 rounded-full h-1.5">
                            <div
                              className="bg-indigo-500 h-1.5 rounded-full transition-all"
                              style={{ width: `${Math.round(download.progress * 100)}%` }}
                            />
                          </div>
                          <span className="text-gray-400 text-xs">
                            {Math.round(download.progress * 100)}%
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`text-xs ${
                          new Date(download.expiresAt) < new Date()
                            ? 'text-red-400'
                            : 'text-gray-400'
                        }`}
                        title={formatDate(download.expiresAt)}
                      >
                        {formatRelativeDate(download.expiresAt)}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {download.watched ? (
                        <span className="inline-flex items-center gap-1 text-green-400 text-xs">
                          <CheckCircle2 className="h-3.5 w-3.5" />
                          Watched
                        </span>
                      ) : download.watchedPosition > 0 ? (
                        <span className="text-yellow-400 text-xs">
                          {Math.floor(download.watchedPosition / 60000)}m
                        </span>
                      ) : (
                        <span className="text-gray-500 text-xs">--</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        {confirmDeleteId === download.id ? (
                          <div className="flex items-center gap-1">
                            <button
                              onClick={() => deleteMutation.mutate(download.id)}
                              disabled={deleteMutation.isPending}
                              className="px-2 py-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg text-xs"
                            >
                              {deleteMutation.isPending ? '...' : 'Confirm'}
                            </button>
                            <button
                              onClick={() => setConfirmDeleteId(null)}
                              className="px-2 py-1.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-xs"
                            >
                              Cancel
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={() => setConfirmDeleteId(download.id)}
                            className="flex items-center gap-1.5 px-3 py-1.5 bg-red-600/20 hover:bg-red-600/30 text-red-400 border border-red-500/30 rounded-lg text-xs"
                            title="Delete"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                            Delete
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Mutation error messages */}
      {deleteMutation.error && (
        <div className="mt-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">
            Failed to delete: {(deleteMutation.error as Error).message}
          </span>
        </div>
      )}
    </div>
  )
}
