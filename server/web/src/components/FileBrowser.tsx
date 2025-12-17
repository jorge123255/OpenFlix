import { useState, useEffect } from 'react'
import { Folder, File, ChevronRight, ChevronUp, HardDrive, Home, Loader2 } from 'lucide-react'
import { api } from '../api/client'
import type { FilesystemEntry } from '../types'

interface FileBrowserProps {
  onSelect: (path: string) => void
  onCancel: () => void
  initialPath?: string
}

export function FileBrowser({ onSelect, onCancel, initialPath }: FileBrowserProps) {
  const [currentPath, setCurrentPath] = useState(initialPath || '')
  const [parentPath, setParentPath] = useState<string | undefined>()
  const [entries, setEntries] = useState<FilesystemEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [manualPath, setManualPath] = useState(initialPath || '')

  useEffect(() => {
    loadDirectory(currentPath || undefined)
  }, [currentPath])

  const loadDirectory = async (path?: string) => {
    setLoading(true)
    setError(null)
    try {
      const response = await api.browseFilesystem(path)
      setEntries(response.entries)
      setParentPath(response.parentPath)
      setManualPath(response.path)
    } catch (err) {
      setError('Failed to load directory')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  const handleNavigate = (path: string) => {
    setCurrentPath(path)
  }

  const handleGoUp = () => {
    if (parentPath !== undefined) {
      setCurrentPath(parentPath)
    }
  }

  const handleSelect = () => {
    onSelect(manualPath || currentPath)
  }

  const handleManualPathSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setCurrentPath(manualPath)
  }

  const formatSize = (bytes?: number) => {
    if (!bytes) return ''
    const units = ['B', 'KB', 'MB', 'GB', 'TB']
    let i = 0
    let size = bytes
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024
      i++
    }
    return `${size.toFixed(1)} ${units[i]}`
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl w-full max-w-2xl max-h-[80vh] flex flex-col">
        {/* Header */}
        <div className="p-4 border-b border-gray-700">
          <h2 className="text-lg font-semibold text-white mb-3">Select Directory</h2>

          {/* Manual path input */}
          <form onSubmit={handleManualPathSubmit} className="flex gap-2">
            <input
              type="text"
              value={manualPath}
              onChange={(e) => setManualPath(e.target.value)}
              className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm font-mono"
              placeholder="/path/to/media"
            />
            <button
              type="submit"
              className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
            >
              Go
            </button>
          </form>
        </div>

        {/* Navigation breadcrumb / up button */}
        <div className="px-4 py-2 border-b border-gray-700 flex items-center gap-2">
          <button
            onClick={handleGoUp}
            disabled={!parentPath && parentPath !== ''}
            className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded disabled:opacity-50 disabled:cursor-not-allowed"
            title="Go up"
          >
            <ChevronUp className="h-4 w-4" />
          </button>
          <span className="text-sm text-gray-400 truncate">{currentPath || 'Select a location'}</span>
        </div>

        {/* File listing */}
        <div className="flex-1 overflow-y-auto p-2">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-6 w-6 text-indigo-400 animate-spin" />
            </div>
          ) : error ? (
            <div className="text-center py-12">
              <p className="text-red-400">{error}</p>
              <button
                onClick={() => loadDirectory(currentPath || undefined)}
                className="mt-2 text-sm text-indigo-400 hover:text-indigo-300"
              >
                Retry
              </button>
            </div>
          ) : entries.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              Empty directory
            </div>
          ) : (
            <div className="space-y-0.5">
              {entries.map((entry) => (
                <button
                  key={entry.path}
                  onClick={() => entry.isDir && handleNavigate(entry.path)}
                  disabled={!entry.isDir}
                  className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left transition-colors ${
                    entry.isDir
                      ? 'hover:bg-gray-700 cursor-pointer'
                      : 'opacity-50 cursor-not-allowed'
                  }`}
                >
                  {entry.isDir ? (
                    entry.name === 'Home' ? (
                      <Home className="h-4 w-4 text-blue-400 flex-shrink-0" />
                    ) : entry.name === 'Root' || entry.path.match(/^[A-Z]:[\\/]?$/) ? (
                      <HardDrive className="h-4 w-4 text-gray-400 flex-shrink-0" />
                    ) : (
                      <Folder className="h-4 w-4 text-yellow-400 flex-shrink-0" />
                    )
                  ) : (
                    <File className="h-4 w-4 text-gray-500 flex-shrink-0" />
                  )}
                  <span className="flex-1 text-sm text-white truncate">{entry.name}</span>
                  {!entry.isDir && entry.size && (
                    <span className="text-xs text-gray-500">{formatSize(entry.size)}</span>
                  )}
                  {entry.isDir && (
                    <ChevronRight className="h-4 w-4 text-gray-600 flex-shrink-0" />
                  )}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-gray-700 flex gap-3">
          <button
            onClick={onCancel}
            className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
          >
            Cancel
          </button>
          <button
            onClick={handleSelect}
            disabled={!manualPath}
            className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-lg"
          >
            Select This Directory
          </button>
        </div>
      </div>
    </div>
  )
}
