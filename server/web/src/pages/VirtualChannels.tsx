import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Radio,
  Tv,
  Plus,
  Trash2,
  Edit,
  Loader,
  X,
  Eye,
  Shuffle,
  Repeat,
  Hash,
  Search,
  AlertCircle,
  Power,
} from 'lucide-react'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface VirtualStation {
  id: number
  name: string
  number: number
  logo?: string
  description?: string
  smartRule?: string
  fileIds?: string
  sort?: string
  order?: string
  shuffle: boolean
  loop: boolean
  limit: number
  enabled: boolean
}

interface PreviewFile {
  id: number
  title: string
  duration?: number
  type?: string
}

interface SmartCondition {
  field: string
  operator: string
  value: string
}

// ---------------------------------------------------------------------------
// API helpers
// ---------------------------------------------------------------------------

const authHeaders: Record<string, string> = {
  'X-Plex-Token': localStorage.getItem('openflix_token') || '',
  'Content-Type': 'application/json',
}

async function fetchStations(): Promise<VirtualStation[]> {
  const res = await fetch('/dvr/v2/virtual-stations', { headers: authHeaders })
  if (!res.ok) throw new Error('Failed to fetch virtual stations')
  const data = await res.json()
  return data.stations || []
}

async function createStation(
  body: Partial<VirtualStation>,
): Promise<VirtualStation> {
  const res = await fetch('/dvr/v2/virtual-stations', {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to create station')
  return res.json()
}

async function updateStation(
  id: number,
  body: Partial<VirtualStation>,
): Promise<VirtualStation> {
  const res = await fetch(`/dvr/v2/virtual-stations/${id}`, {
    method: 'PUT',
    headers: authHeaders,
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to update station')
  return res.json()
}

async function deleteStation(id: number): Promise<void> {
  const res = await fetch(`/dvr/v2/virtual-stations/${id}`, {
    method: 'DELETE',
    headers: authHeaders,
  })
  if (!res.ok) throw new Error('Failed to delete station')
}

async function previewSmartRule(rule: string): Promise<PreviewFile[]> {
  const res = await fetch('/dvr/v2/virtual-stations/preview', {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({ smartRule: rule }),
  })
  if (!res.ok) throw new Error('Failed to preview')
  const data = await res.json()
  return data.files || []
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const SMART_FIELDS = [
  { value: 'title', label: 'Title' },
  { value: 'genre', label: 'Genre' },
  { value: 'year', label: 'Year' },
  { value: 'rating', label: 'Rating' },
  { value: 'duration', label: 'Duration' },
  { value: 'type', label: 'Type' },
  { value: 'studio', label: 'Studio' },
  { value: 'resolution', label: 'Resolution' },
  { value: 'addedAt', label: 'Date Added' },
]

const SMART_OPERATORS = [
  { value: 'is', label: 'is' },
  { value: 'is_not', label: 'is not' },
  { value: 'contains', label: 'contains' },
  { value: 'starts_with', label: 'starts with' },
  { value: 'ends_with', label: 'ends with' },
  { value: 'gt', label: 'greater than' },
  { value: 'lt', label: 'less than' },
]

const SORT_OPTIONS = [
  { value: 'title', label: 'Title' },
  { value: 'year', label: 'Year' },
  { value: 'addedAt', label: 'Date Added' },
  { value: 'duration', label: 'Duration' },
  { value: 'rating', label: 'Rating' },
  { value: 'random', label: 'Random' },
]

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function parseSmartRule(rule?: string): SmartCondition[] {
  if (!rule) return [{ field: 'title', operator: 'contains', value: '' }]
  try {
    const parsed = JSON.parse(rule)
    if (Array.isArray(parsed) && parsed.length > 0) return parsed
  } catch {
    // ignore
  }
  return [{ field: 'title', operator: 'contains', value: '' }]
}

function serializeSmartRule(conditions: SmartCondition[]): string {
  return JSON.stringify(
    conditions.filter((c) => c.value.trim() !== ''),
  )
}

// ---------------------------------------------------------------------------
// SmartRuleBuilder
// ---------------------------------------------------------------------------

function SmartRuleBuilder({
  conditions,
  onChange,
}: {
  conditions: SmartCondition[]
  onChange: (conditions: SmartCondition[]) => void
}) {
  const updateCondition = (
    idx: number,
    patch: Partial<SmartCondition>,
  ) => {
    const next = conditions.map((c, i) =>
      i === idx ? { ...c, ...patch } : c,
    )
    onChange(next)
  }

  const addCondition = () => {
    onChange([
      ...conditions,
      { field: 'title', operator: 'contains', value: '' },
    ])
  }

  const removeCondition = (idx: number) => {
    if (conditions.length <= 1) return
    onChange(conditions.filter((_, i) => i !== idx))
  }

  return (
    <div className="space-y-3">
      <label className="block text-sm font-medium text-gray-300">
        Smart Rules
      </label>
      {conditions.map((cond, idx) => (
        <div key={idx} className="flex items-center gap-2">
          {idx > 0 && (
            <span className="text-xs text-indigo-400 font-medium w-8">AND</span>
          )}
          {idx === 0 && <span className="w-8" />}
          <select
            value={cond.field}
            onChange={(e) => updateCondition(idx, { field: e.target.value })}
            className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
          >
            {SMART_FIELDS.map((f) => (
              <option key={f.value} value={f.value}>
                {f.label}
              </option>
            ))}
          </select>
          <select
            value={cond.operator}
            onChange={(e) =>
              updateCondition(idx, { operator: e.target.value })
            }
            className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
          >
            {SMART_OPERATORS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
          <input
            type="text"
            value={cond.value}
            onChange={(e) => updateCondition(idx, { value: e.target.value })}
            placeholder="Value"
            className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
          <button
            onClick={() => removeCondition(idx)}
            disabled={conditions.length <= 1}
            className="p-2 text-gray-400 hover:text-red-400 disabled:opacity-30 rounded-lg hover:bg-gray-700 transition-colors"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ))}
      <button
        onClick={addCondition}
        className="flex items-center gap-1 text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
      >
        <Plus className="w-3.5 h-3.5" />
        Add Condition
      </button>
    </div>
  )
}

// ---------------------------------------------------------------------------
// StationModal (Create / Edit)
// ---------------------------------------------------------------------------

function StationModal({
  station,
  onClose,
}: {
  station: VirtualStation | null // null = create
  onClose: () => void
}) {
  const queryClient = useQueryClient()
  const isEdit = !!station

  const [name, setName] = useState(station?.name || '')
  const [number, setNumber] = useState(station?.number || 1)
  const [logo, setLogo] = useState(station?.logo || '')
  const [description, setDescription] = useState(station?.description || '')
  const [contentMode, setContentMode] = useState<'smart' | 'manual'>(
    station?.smartRule ? 'smart' : 'manual',
  )
  const [conditions, setConditions] = useState<SmartCondition[]>(
    parseSmartRule(station?.smartRule),
  )
  const [fileIds, setFileIds] = useState(station?.fileIds || '')
  const [shuffleEnabled, setShuffleEnabled] = useState(station?.shuffle ?? false)
  const [loopEnabled, setLoopEnabled] = useState(station?.loop ?? true)
  const [sort, setSort] = useState(station?.sort || 'title')
  const [order, setOrder] = useState(station?.order || 'asc')
  const [limit, setLimit] = useState(station?.limit || 0)

  // Preview state
  const [previewFiles, setPreviewFiles] = useState<PreviewFile[]>([])
  const [isPreviewing, setIsPreviewing] = useState(false)
  const [previewError, setPreviewError] = useState('')

  const createMut = useMutation({
    mutationFn: createStation,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['virtual-stations'] })
      onClose()
    },
  })

  const updateMut = useMutation({
    mutationFn: (body: Partial<VirtualStation>) =>
      updateStation(station!.id, body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['virtual-stations'] })
      onClose()
    },
  })

  const saving = createMut.isPending || updateMut.isPending

  const handlePreview = async () => {
    if (contentMode !== 'smart') return
    setIsPreviewing(true)
    setPreviewError('')
    try {
      const files = await previewSmartRule(serializeSmartRule(conditions))
      setPreviewFiles(files)
    } catch (e) {
      setPreviewError(e instanceof Error ? e.message : 'Preview failed')
    } finally {
      setIsPreviewing(false)
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const body: Partial<VirtualStation> = {
      name,
      number,
      logo: logo || undefined,
      description: description || undefined,
      shuffle: shuffleEnabled,
      loop: loopEnabled,
      sort,
      order,
      limit,
      enabled: station?.enabled ?? true,
    }

    if (contentMode === 'smart') {
      body.smartRule = serializeSmartRule(conditions)
      body.fileIds = undefined
    } else {
      body.fileIds = fileIds
      body.smartRule = undefined
    }

    if (isEdit) {
      updateMut.mutate(body)
    } else {
      createMut.mutate(body)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-gray-800 px-6 pt-6 pb-4 border-b border-gray-700 flex items-center justify-between z-10">
          <div className="flex items-center gap-3">
            <Radio className="w-5 h-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-white">
              {isEdit ? 'Edit Virtual Channel' : 'Create Virtual Channel'}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-white rounded-lg hover:bg-gray-700 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {/* Basic info */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">
                Channel Name
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
                placeholder="24/7 Action Movies"
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">
                Channel Number
              </label>
              <input
                type="number"
                value={number}
                onChange={(e) => setNumber(parseInt(e.target.value) || 1)}
                min={1}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Logo URL
            </label>
            <input
              type="url"
              value={logo}
              onChange={(e) => setLogo(e.target.value)}
              placeholder="https://..."
              className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Description
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              placeholder="Optional description..."
              className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 resize-none focus:outline-none focus:border-indigo-500"
            />
          </div>

          {/* Content Source Tabs */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Content Source
            </label>
            <div className="flex gap-2 mb-4">
              <button
                type="button"
                onClick={() => setContentMode('smart')}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  contentMode === 'smart'
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-700 text-gray-400 hover:text-white'
                }`}
              >
                Smart Rule
              </button>
              <button
                type="button"
                onClick={() => setContentMode('manual')}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  contentMode === 'manual'
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-700 text-gray-400 hover:text-white'
                }`}
              >
                Manual
              </button>
            </div>

            {contentMode === 'smart' ? (
              <div className="space-y-4">
                <SmartRuleBuilder
                  conditions={conditions}
                  onChange={setConditions}
                />
                <button
                  type="button"
                  onClick={handlePreview}
                  disabled={isPreviewing}
                  className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm font-medium transition-colors"
                >
                  {isPreviewing ? (
                    <Loader className="w-4 h-4 animate-spin" />
                  ) : (
                    <Eye className="w-4 h-4" />
                  )}
                  Preview Matches
                </button>

                {previewError && (
                  <p className="text-red-400 text-sm flex items-center gap-1">
                    <AlertCircle className="w-4 h-4" />
                    {previewError}
                  </p>
                )}

                {previewFiles.length > 0 && (
                  <div className="bg-gray-700/50 rounded-lg p-3 max-h-40 overflow-y-auto">
                    <p className="text-xs text-gray-400 mb-2">
                      {previewFiles.length} matched files
                    </p>
                    {previewFiles.map((f) => (
                      <div
                        key={f.id}
                        className="text-sm text-gray-300 py-1 border-b border-gray-700 last:border-0"
                      >
                        {f.title}
                        {f.type && (
                          <span className="text-xs text-gray-500 ml-2">
                            ({f.type})
                          </span>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ) : (
              <div>
                <label className="block text-xs text-gray-400 mb-1">
                  File IDs (comma-separated)
                </label>
                <textarea
                  value={fileIds}
                  onChange={(e) => setFileIds(e.target.value)}
                  rows={3}
                  placeholder="1, 2, 3, ..."
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm font-mono placeholder-gray-500 resize-none focus:outline-none focus:border-indigo-500"
                />
              </div>
            )}
          </div>

          {/* Playback Options */}
          <div className="border-t border-gray-700 pt-5 space-y-4">
            <h3 className="text-sm font-medium text-gray-300">
              Playback Options
            </h3>

            <div className="grid grid-cols-2 gap-4">
              <label className="flex items-center gap-3 cursor-pointer">
                <div
                  className={`relative w-10 h-5 rounded-full transition-colors ${
                    shuffleEnabled ? 'bg-indigo-600' : 'bg-gray-600'
                  }`}
                  onClick={() => setShuffleEnabled(!shuffleEnabled)}
                >
                  <div
                    className={`absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform ${
                      shuffleEnabled ? 'translate-x-5' : ''
                    }`}
                  />
                </div>
                <div className="flex items-center gap-1.5 text-sm text-gray-300">
                  <Shuffle className="w-4 h-4" />
                  Shuffle
                </div>
              </label>

              <label className="flex items-center gap-3 cursor-pointer">
                <div
                  className={`relative w-10 h-5 rounded-full transition-colors ${
                    loopEnabled ? 'bg-indigo-600' : 'bg-gray-600'
                  }`}
                  onClick={() => setLoopEnabled(!loopEnabled)}
                >
                  <div
                    className={`absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform ${
                      loopEnabled ? 'translate-x-5' : ''
                    }`}
                  />
                </div>
                <div className="flex items-center gap-1.5 text-sm text-gray-300">
                  <Repeat className="w-4 h-4" />
                  Loop
                </div>
              </label>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-xs text-gray-400 mb-1">Sort</label>
                <select
                  value={sort}
                  onChange={(e) => setSort(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                >
                  {SORT_OPTIONS.map((s) => (
                    <option key={s.value} value={s.value}>
                      {s.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">
                  Order
                </label>
                <select
                  value={order}
                  onChange={(e) => setOrder(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                >
                  <option value="asc">Ascending</option>
                  <option value="desc">Descending</option>
                </select>
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">
                  Limit (0 = all)
                </label>
                <input
                  type="number"
                  value={limit}
                  onChange={(e) => setLimit(parseInt(e.target.value) || 0)}
                  min={0}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                />
              </div>
            </div>
          </div>

          {/* Error */}
          {(createMut.isError || updateMut.isError) && (
            <p className="text-red-400 text-sm flex items-center gap-1">
              <AlertCircle className="w-4 h-4" />
              {(createMut.error || updateMut.error)?.message ||
                'Operation failed'}
            </p>
          )}

          {/* Actions */}
          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || !name.trim()}
              className="flex-1 py-2.5 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
            >
              {saving ? (
                <Loader className="w-4 h-4 animate-spin mx-auto" />
              ) : isEdit ? (
                'Save Changes'
              ) : (
                'Create Channel'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// StationCard
// ---------------------------------------------------------------------------

function StationCard({
  station,
  onEdit,
  onDelete,
  onToggle,
}: {
  station: VirtualStation
  onEdit: () => void
  onDelete: () => void
  onToggle: () => void
}) {
  const fileCount = station.fileIds
    ? station.fileIds.split(',').filter(Boolean).length
    : 0

  return (
    <div
      className={`bg-gray-800 rounded-xl p-5 border transition-colors ${
        station.enabled
          ? 'border-gray-700 hover:border-gray-600'
          : 'border-gray-700/50 opacity-60'
      }`}
    >
      <div className="flex items-start gap-4">
        {/* Logo */}
        <div className="flex-shrink-0 w-16 h-16 rounded-lg bg-gray-700 flex items-center justify-center overflow-hidden">
          {station.logo ? (
            <img
              src={station.logo}
              alt={station.name}
              className="w-full h-full object-cover"
            />
          ) : (
            <Tv className="w-8 h-8 text-gray-500" />
          )}
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2 py-0.5 bg-indigo-600/20 text-indigo-400 text-xs font-mono rounded">
              #{station.number}
            </span>
            <h3 className="text-white font-semibold truncate">{station.name}</h3>
          </div>

          {station.description && (
            <p className="text-sm text-gray-400 line-clamp-1 mb-2">
              {station.description}
            </p>
          )}

          <div className="flex flex-wrap items-center gap-3 text-xs text-gray-500">
            {station.smartRule && (
              <span className="flex items-center gap-1 px-2 py-0.5 bg-purple-500/10 text-purple-400 rounded">
                <Search className="w-3 h-3" />
                Smart Rule
              </span>
            )}
            {fileCount > 0 && !station.smartRule && (
              <span className="flex items-center gap-1">
                <Hash className="w-3 h-3" />
                {fileCount} files
              </span>
            )}
            {station.shuffle && (
              <span className="flex items-center gap-1">
                <Shuffle className="w-3 h-3" />
                Shuffle
              </span>
            )}
            {station.loop && (
              <span className="flex items-center gap-1">
                <Repeat className="w-3 h-3" />
                Loop
              </span>
            )}
            {station.limit > 0 && (
              <span>Limit: {station.limit}</span>
            )}
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-1 flex-shrink-0">
          <button
            onClick={onToggle}
            className={`p-2 rounded-lg transition-colors ${
              station.enabled
                ? 'text-green-400 hover:bg-gray-700'
                : 'text-gray-500 hover:bg-gray-700'
            }`}
            title={station.enabled ? 'Disable' : 'Enable'}
          >
            <Power className="w-4 h-4" />
          </button>
          <button
            onClick={onEdit}
            className="p-2 text-gray-400 hover:text-indigo-400 hover:bg-gray-700 rounded-lg transition-colors"
            title="Edit"
          >
            <Edit className="w-4 h-4" />
          </button>
          <button
            onClick={onDelete}
            className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg transition-colors"
            title="Delete"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// VirtualChannelsPage (exported)
// ---------------------------------------------------------------------------

export function VirtualChannelsPage() {
  const queryClient = useQueryClient()

  const {
    data: stations,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['virtual-stations'],
    queryFn: fetchStations,
  })

  const deleteMut = useMutation({
    mutationFn: deleteStation,
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['virtual-stations'] }),
  })

  const toggleMut = useMutation({
    mutationFn: ({ id, enabled }: { id: number; enabled: boolean }) =>
      updateStation(id, { enabled }),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['virtual-stations'] }),
  })

  const [modalStation, setModalStation] = useState<
    VirtualStation | null | 'new'
  >(null)
  const [searchQuery, setSearchQuery] = useState('')

  const filteredStations = (stations || []).filter((s) => {
    if (!searchQuery.trim()) return true
    const q = searchQuery.toLowerCase()
    return (
      s.name.toLowerCase().includes(q) ||
      s.description?.toLowerCase().includes(q) ||
      String(s.number).includes(q)
    )
  })

  const handleDelete = (id: number) => {
    if (confirm('Delete this virtual channel? This cannot be undone.')) {
      deleteMut.mutate(id)
    }
  }

  return (
    <div>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Virtual Channels</h1>
          <p className="text-gray-400 mt-1">
            Create custom 24/7 channels from your DVR library
          </p>
        </div>
        <button
          onClick={() => setModalStation('new')}
          className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
        >
          <Plus className="w-4 h-4" />
          New Channel
        </button>
      </div>

      {/* Search */}
      {(stations?.length || 0) > 3 && (
        <div className="relative mb-6">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search channels..."
            className="w-full pl-10 pr-4 py-2.5 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
        </div>
      )}

      {/* Content */}
      {isLoading ? (
        <div className="flex items-center justify-center py-16">
          <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="text-center py-16 bg-gray-800 rounded-xl">
          <AlertCircle className="w-12 h-12 text-red-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">
            Failed to load virtual channels
          </h3>
          <p className="text-gray-400 text-sm">
            {error instanceof Error ? error.message : 'Unknown error'}
          </p>
        </div>
      ) : filteredStations.length === 0 ? (
        <div className="text-center py-16 bg-gray-800 rounded-xl">
          <Radio className="w-12 h-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">
            {searchQuery ? 'No matching channels' : 'No virtual channels yet'}
          </h3>
          <p className="text-gray-400 mb-6">
            {searchQuery
              ? `No channels match "${searchQuery}"`
              : 'Create your first custom 24/7 channel.'}
          </p>
          {!searchQuery && (
            <button
              onClick={() => setModalStation('new')}
              className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
            >
              <Plus className="w-4 h-4" />
              New Channel
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          {filteredStations
            .sort((a, b) => a.number - b.number)
            .map((station) => (
              <StationCard
                key={station.id}
                station={station}
                onEdit={() => setModalStation(station)}
                onDelete={() => handleDelete(station.id)}
                onToggle={() =>
                  toggleMut.mutate({
                    id: station.id,
                    enabled: !station.enabled,
                  })
                }
              />
            ))}
        </div>
      )}

      {/* Modal */}
      {modalStation !== null && (
        <StationModal
          station={modalStation === 'new' ? null : modalStation}
          onClose={() => setModalStation(null)}
        />
      )}
    </div>
  )
}
