import { useState } from 'react'
import { Trash2, RotateCcw, RefreshCw, AlertTriangle, Loader, FileText, HardDrive } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

interface TrashedFile {
  id: number
  title: string
  description?: string
  filePath?: string
  fileSize?: number
  deletedAt: string
  channelName?: string
  duration?: number
  status?: string
}

interface TrashResponse {
  items: TrashedFile[]
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

function formatDuration(minutes?: number): string {
  if (!minutes) return '--'
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return h > 0 ? `${h}h ${m}m` : `${m}m`
}

async function fetchTrash(): Promise<TrashResponse> {
  const res = await fetch('/dvr/v2/trash', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch trash')
  return res.json()
}

async function restoreItem(id: number): Promise<void> {
  const res = await fetch(`/dvr/v2/trash/${id}/restore`, {
    method: 'POST',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to restore item')
}

async function deleteItem(id: number): Promise<void> {
  const res = await fetch(`/dvr/v2/trash/${id}`, {
    method: 'DELETE',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to delete item')
}

async function emptyTrash(): Promise<void> {
  const res = await fetch('/dvr/v2/trash', {
    method: 'DELETE',
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to empty trash')
}

export function TrashPage() {
  const queryClient = useQueryClient()
  const [confirmEmpty, setConfirmEmpty] = useState(false)
  const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null)

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['trash'],
    queryFn: fetchTrash,
  })

  const restoreMutation = useMutation({
    mutationFn: restoreItem,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trash'] })
    },
  })

  const deleteMutation = useMutation({
    mutationFn: deleteItem,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trash'] })
      setConfirmDeleteId(null)
    },
  })

  const emptyMutation = useMutation({
    mutationFn: emptyTrash,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trash'] })
      setConfirmEmpty(false)
    },
  })

  const items = data?.items || []
  const totalSize = items.reduce((acc, item) => acc + (item.fileSize || 0), 0)

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
        <h3 className="text-lg font-medium text-white">Failed to load trash</h3>
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
            <Trash2 className="h-7 w-7 text-red-400" />
            Trash
          </h1>
          <p className="text-gray-400 mt-1">
            {items.length} item{items.length !== 1 ? 's' : ''} in trash
            {totalSize > 0 && ` (${formatBytes(totalSize)} total)`}
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
          {items.length > 0 && (
            <button
              onClick={() => setConfirmEmpty(true)}
              disabled={emptyMutation.isPending}
              className="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 disabled:bg-red-800 text-white rounded-lg text-sm"
            >
              <Trash2 className="h-4 w-4" />
              {emptyMutation.isPending ? 'Emptying...' : 'Empty Trash'}
            </button>
          )}
        </div>
      </div>

      {/* Empty Trash Confirmation */}
      {confirmEmpty && (
        <div className="mb-6 p-4 bg-red-500/10 border border-red-500/30 rounded-xl">
          <div className="flex items-start gap-3">
            <AlertTriangle className="h-5 w-5 text-red-400 mt-0.5 flex-shrink-0" />
            <div className="flex-1">
              <h3 className="text-sm font-medium text-red-400">Permanently delete all items?</h3>
              <p className="text-xs text-gray-400 mt-1">
                This will permanently delete {items.length} item{items.length !== 1 ? 's' : ''} ({formatBytes(totalSize)}). This action cannot be undone.
              </p>
              <div className="flex gap-2 mt-3">
                <button
                  onClick={() => emptyMutation.mutate()}
                  disabled={emptyMutation.isPending}
                  className="px-3 py-1.5 bg-red-600 hover:bg-red-700 disabled:bg-red-800 text-white text-sm rounded-lg"
                >
                  {emptyMutation.isPending ? 'Deleting...' : 'Yes, Delete All'}
                </button>
                <button
                  onClick={() => setConfirmEmpty(false)}
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
      {items.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-64 bg-gray-800 rounded-xl">
          <Trash2 className="h-16 w-16 text-gray-600 mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">Trash is empty</h3>
          <p className="text-gray-400 text-sm">Deleted DVR recordings will appear here</p>
        </div>
      ) : (
        /* Trash Table */
        <div className="bg-gray-800 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="text-left text-sm text-gray-400 border-b border-gray-700">
                  <th className="px-6 py-4 font-medium">Title</th>
                  <th className="px-6 py-4 font-medium">Channel</th>
                  <th className="px-6 py-4 font-medium">Duration</th>
                  <th className="px-6 py-4 font-medium">Size</th>
                  <th className="px-6 py-4 font-medium">Deleted</th>
                  <th className="px-6 py-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="text-sm">
                {items.map((item) => (
                  <tr
                    key={item.id}
                    className="border-b border-gray-700/50 hover:bg-gray-700/30 transition-colors"
                  >
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <FileText className="h-5 w-5 text-gray-500 flex-shrink-0" />
                        <div>
                          <p className="text-white font-medium">{item.title}</p>
                          {item.description && (
                            <p className="text-gray-500 text-xs mt-0.5 line-clamp-1 max-w-xs">
                              {item.description}
                            </p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-gray-300">{item.channelName || '--'}</td>
                    <td className="px-6 py-4 text-gray-300">{formatDuration(item.duration)}</td>
                    <td className="px-6 py-4 text-gray-300">
                      <div className="flex items-center gap-1.5">
                        <HardDrive className="h-3.5 w-3.5 text-gray-500" />
                        {item.fileSize ? formatBytes(item.fileSize) : '--'}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-gray-400 text-xs">
                      {formatDate(item.deletedAt)}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => restoreMutation.mutate(item.id)}
                          disabled={restoreMutation.isPending}
                          className="flex items-center gap-1.5 px-3 py-1.5 bg-green-600/20 hover:bg-green-600/30 text-green-400 border border-green-500/30 rounded-lg text-xs"
                          title="Restore"
                        >
                          <RotateCcw className="h-3.5 w-3.5" />
                          Restore
                        </button>
                        {confirmDeleteId === item.id ? (
                          <div className="flex items-center gap-1">
                            <button
                              onClick={() => deleteMutation.mutate(item.id)}
                              disabled={deleteMutation.isPending}
                              className="px-2 py-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg text-xs"
                            >
                              {deleteMutation.isPending ? 'Deleting...' : 'Confirm'}
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
                            onClick={() => setConfirmDeleteId(item.id)}
                            className="flex items-center gap-1.5 px-3 py-1.5 bg-red-600/20 hover:bg-red-600/30 text-red-400 border border-red-500/30 rounded-lg text-xs"
                            title="Delete Permanently"
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
      {restoreMutation.error && (
        <div className="mt-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">
            Failed to restore: {(restoreMutation.error as Error).message}
          </span>
        </div>
      )}
      {deleteMutation.error && (
        <div className="mt-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">
            Failed to delete: {(deleteMutation.error as Error).message}
          </span>
        </div>
      )}
      {emptyMutation.error && (
        <div className="mt-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">
            Failed to empty trash: {(emptyMutation.error as Error).message}
          </span>
        </div>
      )}
    </div>
  )
}
