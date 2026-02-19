import { useState } from 'react'
import { ScanLine, Layers, Trash2, Plus, Loader, AlertCircle, Play, Pencil, Download } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

const authFetch = async (url: string, options?: RequestInit) => {
  const token = localStorage.getItem('openflix_token') || ''
  const res = await fetch(url, {
    ...options,
    headers: { 'X-Plex-Token': token, 'Content-Type': 'application/json', ...options?.headers },
  })
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

interface DetectedSegment {
  id: number
  fileId: number
  type: string
  startTime: number
  endTime: number
}

interface SegmentsResponse {
  segments: DetectedSegment[]
  duration?: number
  fileName?: string
}

function formatTime(seconds: number): string {
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = Math.floor(seconds % 60)
  if (h > 0) {
    return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
  }
  return `${m}:${s.toString().padStart(2, '0')}`
}

function formatDuration(startTime: number, endTime: number): string {
  const dur = endTime - startTime
  if (dur < 60) return `${dur.toFixed(1)}s`
  return formatTime(dur)
}

const segmentColors: Record<string, string> = {
  intro: 'bg-blue-500',
  outro: 'bg-orange-500',
  credits: 'bg-purple-500',
  commercial: 'bg-red-500',
}

const segmentTextColors: Record<string, string> = {
  intro: 'text-blue-400',
  outro: 'text-orange-400',
  credits: 'text-purple-400',
  commercial: 'text-red-400',
}

const segmentBgColors: Record<string, string> = {
  intro: 'bg-blue-500/20',
  outro: 'bg-orange-500/20',
  credits: 'bg-purple-500/20',
  commercial: 'bg-red-500/20',
}

function SegmentTimeline({ segments, duration }: { segments: DetectedSegment[]; duration: number }) {
  if (duration <= 0) return null
  return (
    <div className="space-y-3">
      <div className="relative h-12 bg-gray-700 rounded-lg overflow-hidden">
        {segments.map((seg) => {
          const left = (seg.startTime / duration) * 100
          const width = ((seg.endTime - seg.startTime) / duration) * 100
          return (
            <div
              key={seg.id}
              className={`absolute top-0 bottom-0 ${segmentColors[seg.type] || 'bg-gray-500'} opacity-70 hover:opacity-90 transition-opacity cursor-pointer`}
              style={{ left: `${left}%`, width: `${Math.max(width, 0.5)}%` }}
              title={`${seg.type}: ${formatTime(seg.startTime)} - ${formatTime(seg.endTime)}`}
            />
          )
        })}
      </div>
      {/* Time markers */}
      <div className="flex justify-between text-xs text-gray-500">
        <span>0:00</span>
        <span>{formatTime(duration / 4)}</span>
        <span>{formatTime(duration / 2)}</span>
        <span>{formatTime((duration * 3) / 4)}</span>
        <span>{formatTime(duration)}</span>
      </div>
      {/* Legend */}
      <div className="flex gap-4 flex-wrap">
        {Object.entries(segmentColors).map(([type, color]) => (
          <div key={type} className="flex items-center gap-2">
            <div className={`w-3 h-3 rounded ${color}`} />
            <span className="text-xs text-gray-400 capitalize">{type}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

function AddSegmentForm({
  onAdd,
  isAdding,
}: {
  onAdd: (segment: { type: string; startTime: number; endTime: number }) => void
  isAdding: boolean
}) {
  const [type, setType] = useState('intro')
  const [startMin, setStartMin] = useState(0)
  const [startSec, setStartSec] = useState(0)
  const [endMin, setEndMin] = useState(0)
  const [endSec, setEndSec] = useState(30)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const startTime = startMin * 60 + startSec
    const endTime = endMin * 60 + endSec
    if (endTime <= startTime) return
    onAdd({ type, startTime, endTime })
  }

  return (
    <form onSubmit={handleSubmit} className="bg-gray-700/50 rounded-lg p-4">
      <h4 className="text-sm font-medium text-gray-300 mb-3">Add Segment Manually</h4>
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
        <div>
          <label className="block text-xs text-gray-500 mb-1">Type</label>
          <select
            value={type}
            onChange={(e) => setType(e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
          >
            <option value="intro">Intro</option>
            <option value="outro">Outro</option>
            <option value="credits">Credits</option>
            <option value="commercial">Commercial</option>
          </select>
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1">Start Time</label>
          <div className="flex gap-1">
            <input
              type="number"
              min="0"
              value={startMin}
              onChange={(e) => setStartMin(Number(e.target.value))}
              className="w-16 px-2 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm text-center"
              placeholder="min"
            />
            <span className="text-gray-500 self-center">:</span>
            <input
              type="number"
              min="0"
              max="59"
              value={startSec}
              onChange={(e) => setStartSec(Number(e.target.value))}
              className="w-16 px-2 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm text-center"
              placeholder="sec"
            />
          </div>
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1">End Time</label>
          <div className="flex gap-1">
            <input
              type="number"
              min="0"
              value={endMin}
              onChange={(e) => setEndMin(Number(e.target.value))}
              className="w-16 px-2 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm text-center"
              placeholder="min"
            />
            <span className="text-gray-500 self-center">:</span>
            <input
              type="number"
              min="0"
              max="59"
              value={endSec}
              onChange={(e) => setEndSec(Number(e.target.value))}
              className="w-16 px-2 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm text-center"
              placeholder="sec"
            />
          </div>
        </div>
        <div className="flex items-end">
          <button
            type="submit"
            disabled={isAdding}
            className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg text-sm"
          >
            {isAdding ? <Loader className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
            Add
          </button>
        </div>
      </div>
    </form>
  )
}

function EditSegmentModal({
  segment,
  onSave,
  onClose,
}: {
  segment: DetectedSegment
  onSave: (id: number, data: { type: string; startTime: number; endTime: number }) => void
  onClose: () => void
}) {
  const [type, setType] = useState(segment.type)
  const [startMin, setStartMin] = useState(Math.floor(segment.startTime / 60))
  const [startSec, setStartSec] = useState(Math.floor(segment.startTime % 60))
  const [endMin, setEndMin] = useState(Math.floor(segment.endTime / 60))
  const [endSec, setEndSec] = useState(Math.floor(segment.endTime % 60))

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const startTime = startMin * 60 + startSec
    const endTime = endMin * 60 + endSec
    if (endTime <= startTime) return
    onSave(segment.id, { type, startTime, endTime })
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <h3 className="text-lg font-semibold text-white mb-4">Edit Segment</h3>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">Type</label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
            >
              <option value="intro">Intro</option>
              <option value="outro">Outro</option>
              <option value="credits">Credits</option>
              <option value="commercial">Commercial</option>
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">Start Time</label>
              <div className="flex gap-1">
                <input
                  type="number"
                  min="0"
                  value={startMin}
                  onChange={(e) => setStartMin(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  placeholder="min"
                />
                <span className="text-gray-500 self-center">:</span>
                <input
                  type="number"
                  min="0"
                  max="59"
                  value={startSec}
                  onChange={(e) => setStartSec(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  placeholder="sec"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">End Time</label>
              <div className="flex gap-1">
                <input
                  type="number"
                  min="0"
                  value={endMin}
                  onChange={(e) => setEndMin(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  placeholder="min"
                />
                <span className="text-gray-500 self-center">:</span>
                <input
                  type="number"
                  min="0"
                  max="59"
                  value={endSec}
                  onChange={(e) => setEndSec(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                  placeholder="sec"
                />
              </div>
            </div>
          </div>
          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              Save
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export function SegmentDetectionPage() {
  const queryClient = useQueryClient()
  const [fileId, setFileId] = useState('')
  const [groupId, setGroupId] = useState('')
  const [editingSegment, setEditingSegment] = useState<DetectedSegment | null>(null)

  const activeFileId = fileId.trim()

  const {
    data: segmentsData,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['segments', activeFileId],
    queryFn: () => authFetch(`/dvr/v2/files/${activeFileId}/segments`) as Promise<SegmentsResponse>,
    enabled: !!activeFileId,
  })

  const detectFile = useMutation({
    mutationFn: (id: string) =>
      authFetch(`/dvr/v2/files/${id}/detect-segments`, { method: 'POST' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['segments', activeFileId] })
    },
  })

  const detectGroup = useMutation({
    mutationFn: (id: string) =>
      authFetch(`/dvr/v2/groups/${id}/detect-segments`, { method: 'POST' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['segments', activeFileId] })
    },
  })

  const deleteAllSegments = useMutation({
    mutationFn: (id: string) =>
      authFetch(`/dvr/v2/files/${id}/segments`, { method: 'DELETE' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['segments', activeFileId] })
    },
  })

  const segments = segmentsData?.segments || []
  const duration = segmentsData?.duration || 0

  const handleAddSegment = (data: { type: string; startTime: number; endTime: number }) => {
    // In production, POST to API to add segment. For now we just refetch.
    authFetch(`/dvr/v2/files/${activeFileId}/segments`, {
      method: 'POST',
      body: JSON.stringify(data),
    }).then(() => {
      queryClient.invalidateQueries({ queryKey: ['segments', activeFileId] })
    })
  }

  const handleEditSegment = (id: number, data: { type: string; startTime: number; endTime: number }) => {
    authFetch(`/dvr/v2/files/${activeFileId}/segments/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }).then(() => {
      queryClient.invalidateQueries({ queryKey: ['segments', activeFileId] })
    })
  }

  const handleDeleteSegment = (id: number) => {
    authFetch(`/dvr/v2/files/${activeFileId}/segments/${id}`, {
      method: 'DELETE',
    }).then(() => {
      queryClient.invalidateQueries({ queryKey: ['segments', activeFileId] })
    })
  }

  return (
    <div>
      <div className="mb-8">
        <div className="flex items-center gap-3">
          <ScanLine className="h-6 w-6 text-indigo-400" />
          <h1 className="text-2xl font-bold text-white">Segment Detection</h1>
        </div>
        <p className="text-gray-400 mt-1">View and edit intro, outro, credits, and commercial segments</p>
      </div>

      {/* File/Group Selector */}
      <div className="bg-gray-800 rounded-xl p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">File ID</label>
            <div className="flex gap-2">
              <input
                type="text"
                value={fileId}
                onChange={(e) => setFileId(e.target.value)}
                className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="Enter file ID..."
              />
              <button
                onClick={() => detectFile.mutate(activeFileId)}
                disabled={!activeFileId || detectFile.isPending}
                className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 disabled:cursor-not-allowed text-white rounded-lg whitespace-nowrap"
              >
                {detectFile.isPending ? (
                  <Loader className="h-4 w-4 animate-spin" />
                ) : (
                  <Play className="h-4 w-4" />
                )}
                Detect Segments
              </button>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Group ID (cross-episode)</label>
            <div className="flex gap-2">
              <input
                type="text"
                value={groupId}
                onChange={(e) => setGroupId(e.target.value)}
                className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                placeholder="Enter group ID..."
              />
              <button
                onClick={() => detectGroup.mutate(groupId.trim())}
                disabled={!groupId.trim() || detectGroup.isPending}
                className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 disabled:cursor-not-allowed text-white rounded-lg whitespace-nowrap"
              >
                {detectGroup.isPending ? (
                  <Loader className="h-4 w-4 animate-spin" />
                ) : (
                  <Layers className="h-4 w-4" />
                )}
                Detect Group
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Detection Results */}
      {!activeFileId ? (
        <div className="bg-gray-800 rounded-xl p-12 text-center">
          <ScanLine className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">Enter a File ID</h3>
          <p className="text-gray-400">Enter a DVR file ID above to view and manage its detected segments.</p>
        </div>
      ) : isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader className="h-8 w-8 text-indigo-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-gray-800 rounded-xl p-6 text-center">
          <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">Failed to load segments</h3>
          <p className="text-gray-400">Could not fetch segments for file ID: {activeFileId}</p>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Timeline Visualization */}
          <div className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white">
                Timeline
                {segmentsData?.fileName && (
                  <span className="text-sm text-gray-400 font-normal ml-2">- {segmentsData.fileName}</span>
                )}
              </h2>
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-400">
                  {segments.length} segment{segments.length !== 1 ? 's' : ''} detected
                </span>
                {segments.length > 0 && (
                  <>
                    <button
                      onClick={() => {
                        const token = localStorage.getItem('openflix_token') || ''
                        const url = `/dvr/v2/files/${activeFileId}/export.edl?types=commercial,intro,outro,credits&X-Plex-Token=${token}`
                        window.open(url, '_blank')
                      }}
                      className="flex items-center gap-1 px-3 py-1 text-sm text-indigo-400 hover:text-indigo-300 hover:bg-indigo-500/10 rounded-lg transition-colors"
                      title="Download EDL file for use with Kodi, MPC-HC, and other players"
                    >
                      <Download className="h-3.5 w-3.5" />
                      Export EDL
                    </button>
                    <button
                      onClick={() => {
                        const token = localStorage.getItem('openflix_token') || ''
                        const url = `/dvr/v2/files/${activeFileId}/export.edl?format=mplayer&types=commercial,intro,outro,credits&X-Plex-Token=${token}`
                        window.open(url, '_blank')
                      }}
                      className="flex items-center gap-1 px-3 py-1 text-sm text-indigo-400 hover:text-indigo-300 hover:bg-indigo-500/10 rounded-lg transition-colors"
                      title="Download MPlayer-format EDL file"
                    >
                      <Download className="h-3.5 w-3.5" />
                      EDL (MPlayer)
                    </button>
                    <button
                      onClick={() => {
                        if (confirm('Delete all segments for this file?')) {
                          deleteAllSegments.mutate(activeFileId)
                        }
                      }}
                      disabled={deleteAllSegments.isPending}
                      className="flex items-center gap-1 px-3 py-1 text-sm text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-lg transition-colors"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                      Clear All
                    </button>
                  </>
                )}
              </div>
            </div>

            {duration > 0 ? (
              <SegmentTimeline segments={segments} duration={duration} />
            ) : segments.length > 0 ? (
              <SegmentTimeline
                segments={segments}
                duration={Math.max(...segments.map((s) => s.endTime), 1)}
              />
            ) : (
              <div className="h-12 bg-gray-700 rounded-lg flex items-center justify-center">
                <span className="text-sm text-gray-500">No segments detected</span>
              </div>
            )}
          </div>

          {/* Segment Table */}
          <div className="bg-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-4">Segments</h2>

            {segments.length === 0 ? (
              <div className="text-center py-8">
                <ScanLine className="h-10 w-10 text-gray-600 mx-auto mb-3" />
                <p className="text-gray-400 mb-2">No segments found</p>
                <p className="text-gray-500 text-sm">
                  Run detection or add segments manually below.
                </p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-gray-700">
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">Type</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">Start</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">End</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-400">Duration</th>
                      <th className="text-right py-3 px-4 text-sm font-medium text-gray-400">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {segments.map((seg) => (
                      <tr key={seg.id} className="border-b border-gray-700/50 hover:bg-gray-700/30">
                        <td className="py-3 px-4">
                          <span
                            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded text-xs font-medium capitalize ${
                              segmentBgColors[seg.type] || 'bg-gray-700'
                            } ${segmentTextColors[seg.type] || 'text-gray-300'}`}
                          >
                            <span className={`w-2 h-2 rounded-full ${segmentColors[seg.type] || 'bg-gray-500'}`} />
                            {seg.type}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-sm text-gray-300 font-mono">
                          {formatTime(seg.startTime)}
                        </td>
                        <td className="py-3 px-4 text-sm text-gray-300 font-mono">
                          {formatTime(seg.endTime)}
                        </td>
                        <td className="py-3 px-4 text-sm text-gray-400">
                          {formatDuration(seg.startTime, seg.endTime)}
                        </td>
                        <td className="py-3 px-4 text-right">
                          <div className="flex items-center justify-end gap-1">
                            <button
                              onClick={() => setEditingSegment(seg)}
                              className="p-1.5 text-gray-400 hover:text-indigo-400 hover:bg-gray-700 rounded-lg transition-colors"
                              title="Edit"
                            >
                              <Pencil className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => handleDeleteSegment(seg.id)}
                              className="p-1.5 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg transition-colors"
                              title="Delete"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            {/* Add Segment Form */}
            <div className="mt-4 pt-4 border-t border-gray-700">
              <AddSegmentForm onAdd={handleAddSegment} isAdding={false} />
            </div>
          </div>

          {/* Detection Status Messages */}
          {detectFile.isSuccess && (
            <div className="flex items-center gap-2 p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
              <ScanLine className="h-4 w-4 text-green-400" />
              <span className="text-green-400 text-sm">Segment detection completed successfully.</span>
            </div>
          )}
          {detectFile.isError && (
            <div className="flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
              <AlertCircle className="h-4 w-4 text-red-400" />
              <span className="text-red-400 text-sm">Segment detection failed. Please try again.</span>
            </div>
          )}
          {detectGroup.isSuccess && (
            <div className="flex items-center gap-2 p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
              <Layers className="h-4 w-4 text-green-400" />
              <span className="text-green-400 text-sm">Group segment detection completed.</span>
            </div>
          )}
        </div>
      )}

      {/* Edit Modal */}
      {editingSegment && (
        <EditSegmentModal
          segment={editingSegment}
          onSave={handleEditSegment}
          onClose={() => setEditingSegment(null)}
        />
      )}
    </div>
  )
}
