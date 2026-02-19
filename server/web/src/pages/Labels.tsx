import { useState, useMemo } from 'react'
import {
  Tag,
  RefreshCw,
  Loader,
  AlertTriangle,
  X,
  Plus,
  Check,
  ChevronLeft,
  FileText,
  Clock,
  Tv,
  Search,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

// ============ Types ============

interface LabelInfo {
  label: string
  count: number
}

interface DVRFile {
  id: number
  title: string
  subtitle?: string
  description?: string
  thumb?: string
  channelName?: string
  episodeNum?: string
  duration?: number
  fileSize?: number
  labels?: string
  createdAt: string
  seasonNumber?: number
  episodeNumber?: number
  isMovie?: boolean
}

// ============ Constants ============

const TOKEN_KEY = 'openflix_token'

const LABEL_COLORS = [
  { bg: 'bg-indigo-500/20', text: 'text-indigo-300', border: 'border-indigo-500/30', dot: 'bg-indigo-400' },
  { bg: 'bg-green-500/20', text: 'text-green-300', border: 'border-green-500/30', dot: 'bg-green-400' },
  { bg: 'bg-amber-500/20', text: 'text-amber-300', border: 'border-amber-500/30', dot: 'bg-amber-400' },
  { bg: 'bg-red-500/20', text: 'text-red-300', border: 'border-red-500/30', dot: 'bg-red-400' },
  { bg: 'bg-purple-500/20', text: 'text-purple-300', border: 'border-purple-500/30', dot: 'bg-purple-400' },
  { bg: 'bg-blue-500/20', text: 'text-blue-300', border: 'border-blue-500/30', dot: 'bg-blue-400' },
  { bg: 'bg-pink-500/20', text: 'text-pink-300', border: 'border-pink-500/30', dot: 'bg-pink-400' },
  { bg: 'bg-teal-500/20', text: 'text-teal-300', border: 'border-teal-500/30', dot: 'bg-teal-400' },
]

// ============ Helpers ============

function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

function hashString(str: string): number {
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash // Convert to 32-bit integer
  }
  return Math.abs(hash)
}

function getLabelColor(label: string) {
  const index = hashString(label) % LABEL_COLORS.length
  return LABEL_COLORS[index]
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString()
}

function formatDuration(seconds?: number): string {
  if (!seconds) return '--'
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
}

function getEpisodeInfo(file: DVRFile): string {
  if (file.isMovie) return 'Movie'
  if (file.seasonNumber != null && file.episodeNumber != null) {
    return `S${String(file.seasonNumber).padStart(2, '0')}E${String(file.episodeNumber).padStart(2, '0')}`
  }
  if (file.episodeNum) return file.episodeNum
  return ''
}

// ============ API Functions ============

async function fetchLabels(): Promise<{ labels: LabelInfo[] }> {
  const res = await fetch('/dvr/labels', {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch labels')
  return res.json()
}

async function fetchFilesByLabel(label: string): Promise<{ files: DVRFile[]; totalCount: number }> {
  const res = await fetch(`/dvr/labels/${encodeURIComponent(label)}/files`, {
    headers: { 'X-Plex-Token': getToken() },
  })
  if (!res.ok) throw new Error('Failed to fetch files')
  return res.json()
}

async function setFileLabels(fileId: number, labels: string[]): Promise<void> {
  const res = await fetch(`/dvr/v2/files/${fileId}/labels`, {
    method: 'PUT',
    headers: {
      'X-Plex-Token': getToken(),
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ labels }),
  })
  if (!res.ok) throw new Error('Failed to update labels')
}

async function bulkLabelAction(action: string, label: string, fileIds: number[]): Promise<void> {
  const res = await fetch('/dvr/labels/bulk', {
    method: 'POST',
    headers: {
      'X-Plex-Token': getToken(),
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ action, label, fileIds }),
  })
  if (!res.ok) throw new Error('Failed to perform bulk action')
}

// ============ Components ============

function LabelChip({
  label,
  count,
  selected,
  onClick,
}: {
  label: string
  count?: number
  selected?: boolean
  onClick?: () => void
}) {
  const color = getLabelColor(label)
  return (
    <button
      onClick={onClick}
      className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-medium border transition-all ${
        selected
          ? `${color.bg} ${color.text} ${color.border} ring-2 ring-offset-1 ring-offset-gray-900 ring-${color.dot.replace('bg-', '')}`
          : `${color.bg} ${color.text} ${color.border} hover:brightness-125`
      }`}
    >
      <span className={`w-2 h-2 rounded-full ${color.dot}`} />
      {label}
      {count != null && (
        <span className="text-xs opacity-70">({count})</span>
      )}
    </button>
  )
}

function AddLabelModal({
  onClose,
  onSubmit,
  existingLabels,
}: {
  onClose: () => void
  onSubmit: (label: string) => void
  existingLabels: string[]
}) {
  const [newLabel, setNewLabel] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const trimmed = newLabel.trim()
    if (trimmed) {
      onSubmit(trimmed)
      onClose()
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md border border-gray-700 shadow-xl">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-white">Add Label</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <input
            type="text"
            value={newLabel}
            onChange={(e) => setNewLabel(e.target.value)}
            placeholder="Enter label name..."
            className="w-full px-4 py-2.5 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent mb-4"
            autoFocus
          />

          {existingLabels.length > 0 && (
            <div className="mb-4">
              <p className="text-xs text-gray-400 mb-2">Or pick an existing label:</p>
              <div className="flex flex-wrap gap-2 max-h-32 overflow-y-auto">
                {existingLabels.map((label) => (
                  <LabelChip
                    key={label}
                    label={label}
                    onClick={() => {
                      onSubmit(label)
                      onClose()
                    }}
                  />
                ))}
              </div>
            </div>
          )}

          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!newLabel.trim()}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 disabled:text-gray-400 text-white rounded-lg text-sm flex items-center gap-2"
            >
              <Plus className="h-4 w-4" />
              Add Label
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function QuickLabelDropdown({
  fileId,
  currentLabels,
  allLabels,
  onUpdate,
  onClose,
}: {
  fileId: number
  currentLabels: string[]
  allLabels: string[]
  onUpdate: (fileId: number, labels: string[]) => void
  onClose: () => void
}) {
  const [newLabel, setNewLabel] = useState('')

  const toggleLabel = (label: string) => {
    const updated = currentLabels.includes(label)
      ? currentLabels.filter((l) => l !== label)
      : [...currentLabels, label]
    onUpdate(fileId, updated)
  }

  const addNewLabel = () => {
    const trimmed = newLabel.trim()
    if (trimmed && !currentLabels.includes(trimmed)) {
      onUpdate(fileId, [...currentLabels, trimmed])
      setNewLabel('')
    }
  }

  return (
    <div className="absolute right-0 top-full mt-1 z-30 w-64 bg-gray-800 border border-gray-700 rounded-xl shadow-xl p-3">
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs font-semibold text-gray-400 uppercase">Labels</span>
        <button onClick={onClose} className="text-gray-500 hover:text-white">
          <X className="h-3.5 w-3.5" />
        </button>
      </div>

      <div className="max-h-40 overflow-y-auto space-y-1 mb-2">
        {allLabels.map((label) => {
          const isActive = currentLabels.includes(label)
          const color = getLabelColor(label)
          return (
            <button
              key={label}
              onClick={() => toggleLabel(label)}
              className={`flex items-center gap-2 w-full px-2.5 py-1.5 rounded-lg text-sm transition-colors ${
                isActive
                  ? `${color.bg} ${color.text}`
                  : 'text-gray-300 hover:bg-gray-700'
              }`}
            >
              <span className={`w-2 h-2 rounded-full ${color.dot}`} />
              <span className="flex-1 text-left">{label}</span>
              {isActive && <Check className="h-3.5 w-3.5" />}
            </button>
          )
        })}
        {allLabels.length === 0 && (
          <p className="text-xs text-gray-500 py-2 text-center">No labels yet</p>
        )}
      </div>

      <div className="border-t border-gray-700 pt-2">
        <div className="flex gap-1.5">
          <input
            type="text"
            value={newLabel}
            onChange={(e) => setNewLabel(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && addNewLabel()}
            placeholder="New label..."
            className="flex-1 px-2.5 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-sm text-white placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
          <button
            onClick={addNewLabel}
            disabled={!newLabel.trim()}
            className="px-2.5 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-700 disabled:text-gray-500 text-white rounded-lg text-sm"
          >
            <Plus className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>
    </div>
  )
}

// ============ Main Page ============

export function LabelsPage() {
  const queryClient = useQueryClient()
  const [selectedLabel, setSelectedLabel] = useState<string | null>(null)
  const [selectedFileIds, setSelectedFileIds] = useState<Set<number>>(new Set())
  const [showAddModal, setShowAddModal] = useState(false)
  const [bulkLabel, setBulkLabel] = useState('')
  const [showBulkInput, setShowBulkInput] = useState(false)
  const [quickLabelFileId, setQuickLabelFileId] = useState<number | null>(null)
  const [searchQuery, setSearchQuery] = useState('')

  // Fetch all labels
  const {
    data: labelsData,
    isLoading: labelsLoading,
    error: labelsError,
    refetch: refetchLabels,
  } = useQuery({
    queryKey: ['dvr-labels'],
    queryFn: fetchLabels,
  })

  // Fetch files for selected label
  const {
    data: filesData,
    isLoading: filesLoading,
    error: filesError,
  } = useQuery({
    queryKey: ['dvr-label-files', selectedLabel],
    queryFn: () => fetchFilesByLabel(selectedLabel!),
    enabled: !!selectedLabel,
  })

  // Set file labels mutation
  const setLabelsMutation = useMutation({
    mutationFn: ({ fileId, labels }: { fileId: number; labels: string[] }) =>
      setFileLabels(fileId, labels),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dvr-labels'] })
      queryClient.invalidateQueries({ queryKey: ['dvr-label-files'] })
    },
  })

  // Bulk label mutation
  const bulkMutation = useMutation({
    mutationFn: ({ action, label, fileIds }: { action: string; label: string; fileIds: number[] }) =>
      bulkLabelAction(action, label, fileIds),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dvr-labels'] })
      queryClient.invalidateQueries({ queryKey: ['dvr-label-files'] })
      setSelectedFileIds(new Set())
      setShowBulkInput(false)
      setBulkLabel('')
    },
  })

  const labels = labelsData?.labels || []
  const files = filesData?.files || []
  const allLabelNames = useMemo(() => labels.map((l) => l.label).sort(), [labels])

  // Filter files by search query
  const filteredFiles = useMemo(() => {
    if (!searchQuery) return files
    const q = searchQuery.toLowerCase()
    return files.filter(
      (f) =>
        f.title.toLowerCase().includes(q) ||
        (f.subtitle && f.subtitle.toLowerCase().includes(q)) ||
        (f.channelName && f.channelName.toLowerCase().includes(q))
    )
  }, [files, searchQuery])

  const toggleFileSelection = (id: number) => {
    setSelectedFileIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
  }

  const toggleSelectAll = () => {
    if (selectedFileIds.size === filteredFiles.length) {
      setSelectedFileIds(new Set())
    } else {
      setSelectedFileIds(new Set(filteredFiles.map((f) => f.id)))
    }
  }

  const handleRemoveLabelFromFile = (fileId: number) => {
    if (!selectedLabel) return
    const file = files.find((f) => f.id === fileId)
    if (!file) return
    const currentLabels = file.labels ? file.labels.split(',').map((l) => l.trim()).filter(Boolean) : []
    const updatedLabels = currentLabels.filter((l) => l !== selectedLabel)
    setLabelsMutation.mutate({ fileId, labels: updatedLabels })
  }

  const handleQuickLabelUpdate = (fileId: number, newLabels: string[]) => {
    setLabelsMutation.mutate({ fileId, labels: newLabels })
  }

  const handleBulkAdd = () => {
    const trimmed = bulkLabel.trim()
    if (!trimmed || selectedFileIds.size === 0) return
    bulkMutation.mutate({
      action: 'add',
      label: trimmed,
      fileIds: Array.from(selectedFileIds),
    })
  }

  const handleBulkRemove = () => {
    if (!selectedLabel || selectedFileIds.size === 0) return
    bulkMutation.mutate({
      action: 'remove',
      label: selectedLabel,
      fileIds: Array.from(selectedFileIds),
    })
  }

  // Loading state
  if (labelsLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
      </div>
    )
  }

  // Error state
  if (labelsError) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <AlertTriangle className="h-12 w-12 text-red-400" />
        <h3 className="text-lg font-medium text-white">Failed to load labels</h3>
        <p className="text-gray-400 text-sm">{(labelsError as Error).message}</p>
        <button
          onClick={() => refetchLabels()}
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
            <Tag className="h-7 w-7 text-indigo-400" />
            Labels
          </h1>
          <p className="text-gray-400 mt-1">
            {labels.length} label{labels.length !== 1 ? 's' : ''} across your DVR library
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => refetchLabels()}
            className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>
      </div>

      {/* Labels Overview */}
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4">
          All Labels
        </h2>
        {labels.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12">
            <Tag className="h-12 w-12 text-gray-600 mb-3" />
            <p className="text-gray-400 text-sm mb-1">No labels found</p>
            <p className="text-gray-500 text-xs">
              Add labels to your DVR recordings to organize them
            </p>
          </div>
        ) : (
          <div className="flex flex-wrap gap-2">
            {labels
              .sort((a, b) => b.count - a.count)
              .map((labelInfo) => (
                <LabelChip
                  key={labelInfo.label}
                  label={labelInfo.label}
                  count={labelInfo.count}
                  selected={selectedLabel === labelInfo.label}
                  onClick={() =>
                    setSelectedLabel(
                      selectedLabel === labelInfo.label ? null : labelInfo.label
                    )
                  }
                />
              ))}
          </div>
        )}
      </div>

      {/* Filtered View */}
      {selectedLabel && (
        <div>
          {/* Filter header */}
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <button
                onClick={() => {
                  setSelectedLabel(null)
                  setSelectedFileIds(new Set())
                  setSearchQuery('')
                }}
                className="flex items-center gap-1.5 text-gray-400 hover:text-white transition-colors text-sm"
              >
                <ChevronLeft className="h-4 w-4" />
                Back
              </button>
              <div className="flex items-center gap-2">
                <LabelChip label={selectedLabel} />
                <span className="text-gray-400 text-sm">
                  {filesData?.totalCount || 0} file{(filesData?.totalCount || 0) !== 1 ? 's' : ''}
                </span>
              </div>
            </div>

            <div className="flex items-center gap-2">
              {/* Search within label */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Filter..."
                  className="pl-9 pr-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-sm text-white placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 w-48"
                />
              </div>

              {/* Bulk actions */}
              {selectedFileIds.size > 0 && (
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-400">
                    {selectedFileIds.size} selected
                  </span>
                  {showBulkInput ? (
                    <div className="flex items-center gap-1.5">
                      <input
                        type="text"
                        value={bulkLabel}
                        onChange={(e) => setBulkLabel(e.target.value)}
                        onKeyDown={(e) => e.key === 'Enter' && handleBulkAdd()}
                        placeholder="Label name..."
                        className="px-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-sm text-white placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 w-36"
                        autoFocus
                      />
                      <button
                        onClick={handleBulkAdd}
                        disabled={!bulkLabel.trim() || bulkMutation.isPending}
                        className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-700 text-white text-xs rounded-lg"
                      >
                        {bulkMutation.isPending ? 'Adding...' : 'Add'}
                      </button>
                      <button
                        onClick={() => {
                          setShowBulkInput(false)
                          setBulkLabel('')
                        }}
                        className="px-2 py-1.5 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-xs"
                      >
                        <X className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  ) : (
                    <>
                      <button
                        onClick={() => setShowBulkInput(true)}
                        className="flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-300 border border-indigo-500/30 rounded-lg text-xs"
                      >
                        <Plus className="h-3.5 w-3.5" />
                        Add Label
                      </button>
                      <button
                        onClick={handleBulkRemove}
                        disabled={bulkMutation.isPending}
                        className="flex items-center gap-1.5 px-3 py-1.5 bg-red-600/20 hover:bg-red-600/30 text-red-300 border border-red-500/30 rounded-lg text-xs"
                      >
                        <X className="h-3.5 w-3.5" />
                        {bulkMutation.isPending ? 'Removing...' : `Remove "${selectedLabel}"`}
                      </button>
                    </>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Files table */}
          {filesLoading ? (
            <div className="flex items-center justify-center h-32">
              <Loader className="h-6 w-6 text-indigo-500 animate-spin" />
            </div>
          ) : filesError ? (
            <div className="flex flex-col items-center justify-center h-32 gap-3 bg-gray-800 rounded-xl">
              <AlertTriangle className="h-8 w-8 text-red-400" />
              <p className="text-sm text-gray-400">{(filesError as Error).message}</p>
            </div>
          ) : filteredFiles.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-32 bg-gray-800 rounded-xl">
              <FileText className="h-10 w-10 text-gray-600 mb-2" />
              <p className="text-gray-400 text-sm">
                {searchQuery ? 'No files match your search' : 'No files with this label'}
              </p>
            </div>
          ) : (
            <div className="bg-gray-800 rounded-xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="text-left text-sm text-gray-400 border-b border-gray-700">
                      <th className="px-4 py-3 font-medium w-10">
                        <input
                          type="checkbox"
                          checked={selectedFileIds.size === filteredFiles.length && filteredFiles.length > 0}
                          onChange={toggleSelectAll}
                          className="rounded border-gray-600 bg-gray-700 text-indigo-600 focus:ring-indigo-500"
                        />
                      </th>
                      <th className="px-4 py-3 font-medium">Title</th>
                      <th className="px-4 py-3 font-medium">Episode</th>
                      <th className="px-4 py-3 font-medium">Channel</th>
                      <th className="px-4 py-3 font-medium">Duration</th>
                      <th className="px-4 py-3 font-medium">Date</th>
                      <th className="px-4 py-3 font-medium">Labels</th>
                      <th className="px-4 py-3 font-medium text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="text-sm">
                    {filteredFiles.map((file) => {
                      const fileLabels = file.labels
                        ? file.labels.split(',').map((l) => l.trim()).filter(Boolean)
                        : []
                      return (
                        <tr
                          key={file.id}
                          className="border-b border-gray-700/50 hover:bg-gray-700/30 transition-colors"
                        >
                          <td className="px-4 py-3">
                            <input
                              type="checkbox"
                              checked={selectedFileIds.has(file.id)}
                              onChange={() => toggleFileSelection(file.id)}
                              className="rounded border-gray-600 bg-gray-700 text-indigo-600 focus:ring-indigo-500"
                            />
                          </td>
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-3">
                              {file.thumb ? (
                                <img
                                  src={file.thumb}
                                  alt=""
                                  className="w-10 h-14 object-cover rounded bg-gray-700 flex-shrink-0"
                                  onError={(e) => {
                                    ;(e.target as HTMLImageElement).style.display = 'none'
                                  }}
                                />
                              ) : (
                                <div className="w-10 h-14 bg-gray-700 rounded flex items-center justify-center flex-shrink-0">
                                  <FileText className="h-4 w-4 text-gray-500" />
                                </div>
                              )}
                              <div>
                                <p className="text-white font-medium">{file.title}</p>
                                {file.subtitle && (
                                  <p className="text-gray-500 text-xs mt-0.5 line-clamp-1 max-w-xs">
                                    {file.subtitle}
                                  </p>
                                )}
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-3 text-gray-300">
                            {getEpisodeInfo(file) || '--'}
                          </td>
                          <td className="px-4 py-3">
                            {file.channelName ? (
                              <div className="flex items-center gap-1.5">
                                <Tv className="h-3.5 w-3.5 text-gray-500" />
                                <span className="text-gray-300">{file.channelName}</span>
                              </div>
                            ) : (
                              <span className="text-gray-500">--</span>
                            )}
                          </td>
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-1.5">
                              <Clock className="h-3.5 w-3.5 text-gray-500" />
                              <span className="text-gray-300">{formatDuration(file.duration)}</span>
                            </div>
                          </td>
                          <td className="px-4 py-3 text-gray-400 text-xs">
                            {formatDate(file.createdAt)}
                          </td>
                          <td className="px-4 py-3">
                            <div className="flex flex-wrap gap-1">
                              {fileLabels.map((l) => (
                                <LabelChip key={l} label={l} />
                              ))}
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <div className="flex items-center justify-end gap-1.5 relative">
                              {/* Quick label button */}
                              <button
                                onClick={() =>
                                  setQuickLabelFileId(
                                    quickLabelFileId === file.id ? null : file.id
                                  )
                                }
                                className="p-1.5 text-gray-400 hover:text-indigo-400 hover:bg-gray-700 rounded-lg transition-colors"
                                title="Manage labels"
                              >
                                <Plus className="h-4 w-4" />
                              </button>

                              {/* Remove label button */}
                              <button
                                onClick={() => handleRemoveLabelFromFile(file.id)}
                                disabled={setLabelsMutation.isPending}
                                className="p-1.5 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg transition-colors"
                                title={`Remove "${selectedLabel}" label`}
                              >
                                <X className="h-4 w-4" />
                              </button>

                              {/* Quick label dropdown */}
                              {quickLabelFileId === file.id && (
                                <QuickLabelDropdown
                                  fileId={file.id}
                                  currentLabels={fileLabels}
                                  allLabels={allLabelNames}
                                  onUpdate={handleQuickLabelUpdate}
                                  onClose={() => setQuickLabelFileId(null)}
                                />
                              )}
                            </div>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Add Label Modal */}
      {showAddModal && (
        <AddLabelModal
          onClose={() => setShowAddModal(false)}
          onSubmit={(label) => {
            if (selectedFileIds.size > 0) {
              bulkMutation.mutate({
                action: 'add',
                label,
                fileIds: Array.from(selectedFileIds),
              })
            }
          }}
          existingLabels={allLabelNames}
        />
      )}

      {/* Mutation error messages */}
      {setLabelsMutation.error && (
        <div className="mt-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">
            Failed to update labels: {(setLabelsMutation.error as Error).message}
          </span>
        </div>
      )}
      {bulkMutation.error && (
        <div className="mt-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-400 flex-shrink-0" />
          <span className="text-red-400 text-sm">
            Bulk operation failed: {(bulkMutation.error as Error).message}
          </span>
        </div>
      )}
    </div>
  )
}
