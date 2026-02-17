import { useState, useRef } from 'react'
import { Upload, FolderInput, Loader, CheckCircle, AlertCircle, X, File, ToggleLeft, ToggleRight } from 'lucide-react'

interface UploadItem {
  id: string
  file: File
  progress: number
  status: 'pending' | 'uploading' | 'complete' | 'error'
  error?: string
  title: string
  group: string
  category: string
}

interface ImportResult {
  success: boolean
  message: string
  imported?: number
}

function DropZone({ onFiles }: { onFiles: (files: FileList) => void }) {
  const [dragging, setDragging] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  return (
    <div
      className={`border-2 border-dashed rounded-xl p-12 text-center transition-colors cursor-pointer ${
        dragging ? 'border-indigo-500 bg-indigo-500/10' : 'border-gray-600 hover:border-gray-500'
      }`}
      onDragOver={(e) => {
        e.preventDefault()
        setDragging(true)
      }}
      onDragLeave={() => setDragging(false)}
      onDrop={(e) => {
        e.preventDefault()
        setDragging(false)
        onFiles(e.dataTransfer.files)
      }}
      onClick={() => inputRef.current?.click()}
    >
      <Upload className="h-12 w-12 mx-auto text-gray-400 mb-4" />
      <p className="text-gray-300 text-lg">Drag and drop video files here</p>
      <p className="text-gray-500 text-sm mt-1">or click to browse</p>
      <p className="text-gray-600 text-xs mt-3">Supports MP4, MKV, AVI, TS, M2TS, MOV</p>
      <input
        ref={inputRef}
        type="file"
        className="hidden"
        accept="video/*,.mkv,.avi,.ts,.m2ts,.mov"
        multiple
        onChange={(e) => e.target.files && onFiles(e.target.files)}
      />
    </div>
  )
}

function UploadItemRow({
  item,
  onRemove,
  onUpdateMeta,
}: {
  item: UploadItem
  onRemove: () => void
  onUpdateMeta: (field: string, value: string) => void
}) {
  const formatSize = (bytes: number): string => {
    if (bytes >= 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`
    if (bytes >= 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(0)} MB`
    return `${(bytes / 1024).toFixed(0)} KB`
  }

  return (
    <div className="bg-gray-700/50 rounded-lg p-4">
      <div className="flex items-start gap-4">
        <div className="p-2 bg-gray-600 rounded-lg flex-shrink-0">
          <File className="h-5 w-5 text-gray-300" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between mb-2">
            <div>
              <p className="text-white font-medium truncate">{item.file.name}</p>
              <p className="text-xs text-gray-500">{formatSize(item.file.size)}</p>
            </div>
            <div className="flex items-center gap-2 flex-shrink-0">
              {item.status === 'uploading' && (
                <Loader className="h-4 w-4 text-indigo-400 animate-spin" />
              )}
              {item.status === 'complete' && (
                <CheckCircle className="h-4 w-4 text-green-400" />
              )}
              {item.status === 'error' && (
                <AlertCircle className="h-4 w-4 text-red-400" />
              )}
              {(item.status === 'pending' || item.status === 'error') && (
                <button
                  onClick={onRemove}
                  className="p-1 text-gray-400 hover:text-red-400 transition-colors"
                >
                  <X className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>

          {/* Progress bar */}
          {item.status === 'uploading' && (
            <div className="h-1.5 bg-gray-600 rounded-full overflow-hidden mb-3">
              <div
                className="h-full bg-indigo-500 rounded-full transition-all duration-300"
                style={{ width: `${item.progress}%` }}
              />
            </div>
          )}

          {item.status === 'error' && (
            <p className="text-sm text-red-400 mb-2">{item.error || 'Upload failed'}</p>
          )}

          {/* Metadata fields */}
          {item.status === 'pending' && (
            <div className="grid grid-cols-3 gap-2 mt-2">
              <input
                type="text"
                value={item.title}
                onChange={(e) => onUpdateMeta('title', e.target.value)}
                className="px-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                placeholder="Title"
              />
              <input
                type="text"
                value={item.group}
                onChange={(e) => onUpdateMeta('group', e.target.value)}
                className="px-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                placeholder="Group (optional)"
              />
              <select
                value={item.category}
                onChange={(e) => onUpdateMeta('category', e.target.value)}
                className="px-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
              >
                <option value="">Category</option>
                <option value="movie">Movie</option>
                <option value="tv">TV Show</option>
                <option value="sports">Sports</option>
                <option value="other">Other</option>
              </select>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function ServerImportTab() {
  const [path, setPath] = useState('')
  const [importing, setImporting] = useState(false)
  const [result, setResult] = useState<ImportResult | null>(null)

  const handleImport = async () => {
    if (!path.trim()) return
    setImporting(true)
    setResult(null)
    try {
      const token = localStorage.getItem('openflix_token') || ''
      const res = await fetch('/dvr/v2/files/import', {
        method: 'POST',
        headers: { 'X-Plex-Token': token, 'Content-Type': 'application/json' },
        body: JSON.stringify({ path: path.trim() }),
      })
      if (!res.ok) throw new Error(`Import failed: ${res.status}`)
      const data = await res.json()
      setResult({ success: true, message: data.message || 'File imported successfully', imported: data.imported })
    } catch (err) {
      setResult({ success: false, message: err instanceof Error ? err.message : 'Import failed' })
    } finally {
      setImporting(false)
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-2">Server File Path</label>
        <div className="flex gap-2">
          <input
            type="text"
            value={path}
            onChange={(e) => {
              setPath(e.target.value)
              setResult(null)
            }}
            className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white font-mono text-sm"
            placeholder="/path/to/video/file.mp4"
          />
          <button
            onClick={handleImport}
            disabled={!path.trim() || importing}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 disabled:cursor-not-allowed text-white rounded-lg whitespace-nowrap"
          >
            {importing ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <FolderInput className="h-4 w-4" />
            )}
            Import
          </button>
        </div>
        <p className="text-xs text-gray-500 mt-1">
          Enter the full path to a video file on the server.
        </p>
      </div>

      {result && (
        <div
          className={`flex items-center gap-2 p-3 rounded-lg ${
            result.success
              ? 'bg-green-500/10 border border-green-500/30'
              : 'bg-red-500/10 border border-red-500/30'
          }`}
        >
          {result.success ? (
            <CheckCircle className="h-4 w-4 text-green-400 flex-shrink-0" />
          ) : (
            <AlertCircle className="h-4 w-4 text-red-400 flex-shrink-0" />
          )}
          <span className={result.success ? 'text-green-400 text-sm' : 'text-red-400 text-sm'}>
            {result.message}
          </span>
        </div>
      )}
    </div>
  )
}

function BulkImportTab() {
  const [dirPath, setDirPath] = useState('')
  const [recursive, setRecursive] = useState(true)
  const [groupName, setGroupName] = useState('')
  const [importing, setImporting] = useState(false)
  const [result, setResult] = useState<ImportResult | null>(null)

  const handleBulkImport = async () => {
    if (!dirPath.trim()) return
    setImporting(true)
    setResult(null)
    try {
      const token = localStorage.getItem('openflix_token') || ''
      const res = await fetch('/dvr/v2/files/import/bulk', {
        method: 'POST',
        headers: { 'X-Plex-Token': token, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          path: dirPath.trim(),
          recursive,
          groupName: groupName.trim() || undefined,
        }),
      })
      if (!res.ok) throw new Error(`Bulk import failed: ${res.status}`)
      const data = await res.json()
      setResult({
        success: true,
        message: data.message || 'Bulk import completed',
        imported: data.imported,
      })
    } catch (err) {
      setResult({ success: false, message: err instanceof Error ? err.message : 'Bulk import failed' })
    } finally {
      setImporting(false)
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-2">Directory Path</label>
        <input
          type="text"
          value={dirPath}
          onChange={(e) => {
            setDirPath(e.target.value)
            setResult(null)
          }}
          className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white font-mono text-sm"
          placeholder="/path/to/video/directory"
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Group Name (optional)</label>
          <input
            type="text"
            value={groupName}
            onChange={(e) => setGroupName(e.target.value)}
            className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
            placeholder="e.g., Season 1"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Recursive Scan</label>
          <button
            onClick={() => setRecursive(!recursive)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
              recursive
                ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30'
                : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
            }`}
          >
            {recursive ? (
              <>
                <ToggleRight className="h-5 w-5" />
                Include Subdirectories
              </>
            ) : (
              <>
                <ToggleLeft className="h-5 w-5" />
                Top-Level Only
              </>
            )}
          </button>
        </div>
      </div>

      <button
        onClick={handleBulkImport}
        disabled={!dirPath.trim() || importing}
        className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 disabled:cursor-not-allowed text-white rounded-lg"
      >
        {importing ? (
          <Loader className="h-4 w-4 animate-spin" />
        ) : (
          <FolderInput className="h-4 w-4" />
        )}
        {importing ? 'Importing...' : 'Start Bulk Import'}
      </button>

      {result && (
        <div
          className={`flex items-center gap-2 p-3 rounded-lg ${
            result.success
              ? 'bg-green-500/10 border border-green-500/30'
              : 'bg-red-500/10 border border-red-500/30'
          }`}
        >
          {result.success ? (
            <CheckCircle className="h-4 w-4 text-green-400 flex-shrink-0" />
          ) : (
            <AlertCircle className="h-4 w-4 text-red-400 flex-shrink-0" />
          )}
          <span className={result.success ? 'text-green-400 text-sm' : 'text-red-400 text-sm'}>
            {result.message}
            {result.imported !== undefined && ` (${result.imported} files imported)`}
          </span>
        </div>
      )}
    </div>
  )
}

export function FileUploadPage() {
  const [activeTab, setActiveTab] = useState<'upload' | 'import' | 'bulk'>('upload')
  const [uploadItems, setUploadItems] = useState<UploadItem[]>([])

  const handleFiles = (files: FileList) => {
    const newItems: UploadItem[] = Array.from(files).map((file) => ({
      id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
      file,
      progress: 0,
      status: 'pending' as const,
      title: file.name.replace(/\.[^.]+$/, '').replace(/[._-]/g, ' '),
      group: '',
      category: '',
    }))
    setUploadItems((prev) => [...prev, ...newItems])
  }

  const removeItem = (id: string) => {
    setUploadItems((prev) => prev.filter((item) => item.id !== id))
  }

  const updateItemMeta = (id: string, field: string, value: string) => {
    setUploadItems((prev) =>
      prev.map((item) =>
        item.id === id ? { ...item, [field]: value } : item
      )
    )
  }

  const uploadFile = async (item: UploadItem) => {
    setUploadItems((prev) =>
      prev.map((i) => (i.id === item.id ? { ...i, status: 'uploading' as const, progress: 0 } : i))
    )

    try {
      const token = localStorage.getItem('openflix_token') || ''
      const formData = new FormData()
      formData.append('file', item.file)
      if (item.title) formData.append('title', item.title)
      if (item.group) formData.append('group', item.group)
      if (item.category) formData.append('category', item.category)

      const xhr = new XMLHttpRequest()
      xhr.open('POST', '/dvr/v2/files/upload')
      xhr.setRequestHeader('X-Plex-Token', token)

      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          const progress = Math.round((e.loaded / e.total) * 100)
          setUploadItems((prev) =>
            prev.map((i) => (i.id === item.id ? { ...i, progress } : i))
          )
        }
      }

      await new Promise<void>((resolve, reject) => {
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            setUploadItems((prev) =>
              prev.map((i) =>
                i.id === item.id ? { ...i, status: 'complete' as const, progress: 100 } : i
              )
            )
            resolve()
          } else {
            reject(new Error(`Upload failed: ${xhr.status}`))
          }
        }
        xhr.onerror = () => reject(new Error('Upload failed'))
        xhr.send(formData)
      })
    } catch (err) {
      setUploadItems((prev) =>
        prev.map((i) =>
          i.id === item.id
            ? { ...i, status: 'error' as const, error: err instanceof Error ? err.message : 'Upload failed' }
            : i
        )
      )
    }
  }

  const uploadAll = async () => {
    const pending = uploadItems.filter((item) => item.status === 'pending')
    for (const item of pending) {
      await uploadFile(item)
    }
  }

  const pendingCount = uploadItems.filter((i) => i.status === 'pending').length
  const completedCount = uploadItems.filter((i) => i.status === 'complete').length

  return (
    <div>
      <div className="mb-8">
        <div className="flex items-center gap-3">
          <Upload className="h-6 w-6 text-indigo-400" />
          <h1 className="text-2xl font-bold text-white">File Upload</h1>
        </div>
        <p className="text-gray-400 mt-1">Upload video files or import from the server filesystem</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-6">
        {[
          { key: 'upload' as const, label: 'Upload Files', icon: Upload },
          { key: 'import' as const, label: 'Import from Server', icon: FolderInput },
          { key: 'bulk' as const, label: 'Bulk Import', icon: FolderInput },
        ].map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            onClick={() => setActiveTab(key)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
              activeTab === key
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-800 text-gray-400 hover:text-white'
            }`}
          >
            <Icon className="h-4 w-4" />
            {label}
          </button>
        ))}
      </div>

      {/* Upload Tab */}
      {activeTab === 'upload' && (
        <div className="space-y-6">
          <div className="bg-gray-800 rounded-xl p-6">
            <DropZone onFiles={handleFiles} />
          </div>

          {/* Upload Queue */}
          {uploadItems.length > 0 && (
            <div className="bg-gray-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-white">
                  Upload Queue
                  <span className="text-sm text-gray-400 font-normal ml-2">
                    {completedCount}/{uploadItems.length} complete
                  </span>
                </h2>
                <div className="flex gap-2">
                  {pendingCount > 0 && (
                    <button
                      onClick={uploadAll}
                      className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm"
                    >
                      <Upload className="h-4 w-4" />
                      Upload All ({pendingCount})
                    </button>
                  )}
                  <button
                    onClick={() => setUploadItems([])}
                    className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-gray-300 rounded-lg text-sm"
                  >
                    Clear
                  </button>
                </div>
              </div>
              <div className="space-y-3">
                {uploadItems.map((item) => (
                  <UploadItemRow
                    key={item.id}
                    item={item}
                    onRemove={() => removeItem(item.id)}
                    onUpdateMeta={(field, value) => updateItemMeta(item.id, field, value)}
                  />
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Server Import Tab */}
      {activeTab === 'import' && (
        <div className="bg-gray-800 rounded-xl p-6">
          <div className="flex items-center gap-2 mb-4">
            <FolderInput className="h-5 w-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-white">Import from Server</h2>
          </div>
          <ServerImportTab />
        </div>
      )}

      {/* Bulk Import Tab */}
      {activeTab === 'bulk' && (
        <div className="bg-gray-800 rounded-xl p-6">
          <div className="flex items-center gap-2 mb-4">
            <FolderInput className="h-5 w-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-white">Bulk Import Directory</h2>
          </div>
          <BulkImportTab />
        </div>
      )}
    </div>
  )
}
