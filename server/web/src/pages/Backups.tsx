import { useState } from 'react'
import {
  Database,
  Plus,
  Download,
  Trash2,
  RotateCcw,
  RefreshCw,
  AlertTriangle,
  Loader,
  CheckCircle,
  FileText,
  HardDrive,
  Clock,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

interface Backup {
  filename: string
  size: number
  createdAt: string
  version?: string
}

interface BackupsResponse {
  backups: Backup[]
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

async function fetchBackups(): Promise<BackupsResponse> {
  const res = await fetch('/admin/backups', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch backups')
  return res.json()
}

async function createBackup(): Promise<void> {
  const res = await fetch('/admin/backups', {
    method: 'POST',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to create backup')
}

async function deleteBackup(filename: string): Promise<void> {
  const res = await fetch(`/admin/backups/${encodeURIComponent(filename)}`, {
    method: 'DELETE',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to delete backup')
}

async function restoreBackup(filename: string): Promise<void> {
  const res = await fetch(`/admin/backups/${encodeURIComponent(filename)}/restore`, {
    method: 'POST',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to restore backup')
}

function downloadBackup(filename: string): void {
  const token = getToken()
  const url = `/admin/backups/${encodeURIComponent(filename)}/download?X-Plex-Token=${encodeURIComponent(token)}`
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
}

export function BackupsPage() {
  const queryClient = useQueryClient()
  const [confirmRestore, setConfirmRestore] = useState<string | null>(null)
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['backups'],
    queryFn: fetchBackups,
  })

  const createMutation = useMutation({
    mutationFn: createBackup,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['backups'] })
      setSuccessMessage('Backup created successfully')
      setTimeout(() => setSuccessMessage(null), 4000)
    },
  })

  const deleteMutation = useMutation({
    mutationFn: deleteBackup,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['backups'] })
      setConfirmDelete(null)
      setSuccessMessage('Backup deleted')
      setTimeout(() => setSuccessMessage(null), 4000)
    },
  })

  const restoreMutation = useMutation({
    mutationFn: restoreBackup,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['backups'] })
      setConfirmRestore(null)
      setSuccessMessage('Backup restored successfully. You may need to restart the server.')
      setTimeout(() => setSuccessMessage(null), 8000)
    },
  })

  const backups = data?.backups || []

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
        <h3 className="text-lg font-medium text-white">Failed to load backups</h3>
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
            <Database className="h-7 w-7 text-indigo-400" />
            Backups
          </h1>
          <p className="text-gray-400 mt-1">
            {backups.length} backup{backups.length !== 1 ? 's' : ''} available
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => refetch()}
            className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
          <button
            onClick={() => createMutation.mutate()}
            disabled={createMutation.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg text-sm"
          >
            {createMutation.isPending ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <Plus className="h-4 w-4" />
            )}
            {createMutation.isPending ? 'Creating...' : 'Create Backup'}
          </button>
        </div>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="mb-6 p-3 bg-green-500/10 border border-green-500/30 rounded-lg flex items-center gap-2">
          <CheckCircle className="h-4 w-4 text-green-400 flex-shrink-0" />
          <span className="text-green-400 text-sm">{successMessage}</span>
        </div>
      )}

      {/* Mutation Errors */}
      {(createMutation.error || deleteMutation.error || restoreMutation.error) && (
        <div className="mb-6 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">
            {(createMutation.error as Error)?.message ||
              (deleteMutation.error as Error)?.message ||
              (restoreMutation.error as Error)?.message}
          </span>
        </div>
      )}

      {/* Restore Confirmation Modal */}
      {confirmRestore && (
        <div className="mb-6 p-4 bg-yellow-500/10 border border-yellow-500/30 rounded-xl">
          <div className="flex items-start gap-3">
            <AlertTriangle className="h-5 w-5 text-yellow-400 mt-0.5 flex-shrink-0" />
            <div className="flex-1">
              <h3 className="text-sm font-medium text-yellow-400">Restore backup?</h3>
              <p className="text-xs text-gray-400 mt-1">
                This will restore the database from <span className="font-mono text-gray-300">{confirmRestore}</span>.
                The current database will be overwritten. The server may restart after restore.
              </p>
              <div className="flex gap-2 mt-3">
                <button
                  onClick={() => restoreMutation.mutate(confirmRestore)}
                  disabled={restoreMutation.isPending}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-yellow-600 hover:bg-yellow-700 disabled:bg-yellow-800 text-white text-sm rounded-lg"
                >
                  {restoreMutation.isPending ? (
                    <Loader className="h-3.5 w-3.5 animate-spin" />
                  ) : (
                    <RotateCcw className="h-3.5 w-3.5" />
                  )}
                  {restoreMutation.isPending ? 'Restoring...' : 'Yes, Restore'}
                </button>
                <button
                  onClick={() => setConfirmRestore(null)}
                  className="px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-sm rounded-lg"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Empty State */}
      {backups.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-64 bg-gray-800 rounded-xl">
          <Database className="h-16 w-16 text-gray-600 mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No backups yet</h3>
          <p className="text-gray-400 text-sm mb-4">Create your first backup to protect your configuration</p>
          <button
            onClick={() => createMutation.mutate()}
            disabled={createMutation.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
          >
            <Plus className="h-4 w-4" />
            Create Backup
          </button>
        </div>
      ) : (
        /* Backups List */
        <div className="space-y-3">
          {backups.map((backup) => (
            <div
              key={backup.filename}
              className="bg-gray-800 rounded-xl p-5 flex items-center gap-4 hover:bg-gray-750 transition-colors"
            >
              <div className="p-3 bg-indigo-600/20 rounded-lg flex-shrink-0">
                <FileText className="h-6 w-6 text-indigo-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white font-medium truncate">{backup.filename}</p>
                <div className="flex items-center gap-4 mt-1 text-xs text-gray-400">
                  <span className="flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    {formatDate(backup.createdAt)}
                    <span className="text-gray-500">({timeAgo(backup.createdAt)})</span>
                  </span>
                  <span className="flex items-center gap-1">
                    <HardDrive className="h-3 w-3" />
                    {formatBytes(backup.size)}
                  </span>
                  {backup.version && (
                    <span className="text-gray-500">v{backup.version}</span>
                  )}
                </div>
              </div>
              <div className="flex items-center gap-2 flex-shrink-0">
                <button
                  onClick={() => downloadBackup(backup.filename)}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-xs"
                  title="Download"
                >
                  <Download className="h-3.5 w-3.5" />
                  Download
                </button>
                <button
                  onClick={() => setConfirmRestore(backup.filename)}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-yellow-600/20 hover:bg-yellow-600/30 text-yellow-400 border border-yellow-500/30 rounded-lg text-xs"
                  title="Restore"
                >
                  <RotateCcw className="h-3.5 w-3.5" />
                  Restore
                </button>
                {confirmDelete === backup.filename ? (
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => deleteMutation.mutate(backup.filename)}
                      disabled={deleteMutation.isPending}
                      className="px-2 py-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg text-xs"
                    >
                      {deleteMutation.isPending ? '...' : 'Confirm'}
                    </button>
                    <button
                      onClick={() => setConfirmDelete(null)}
                      className="px-2 py-1.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-xs"
                    >
                      Cancel
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => setConfirmDelete(backup.filename)}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-red-600/20 hover:bg-red-600/30 text-red-400 border border-red-500/30 rounded-lg text-xs"
                    title="Delete"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                    Delete
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
