import { useState, useMemo, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  ListOrdered,
  Radio,
  Plus,
  Trash2,
  Edit,
  Loader,
  X,
  Download,
  Copy,
  Check,
  Search,
  AlertCircle,
  GripVertical,
  ChevronRight,
  ChevronLeft,
  Tv,
  Hash,
  Zap,
  Eye,
} from 'lucide-react'

const isAbsoluteUrl = (url?: string) => url ? /^https?:\/\//i.test(url) : false

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SmartRuleCond {
  field: string
  op: string
  value: string
}

interface SmartRuleConfig {
  enabled: boolean
  conditions: SmartRuleCond[]
  match: 'any' | 'all'
}

interface ChannelCollection {
  id: number
  name: string
  description?: string
  smart?: boolean
  smartRules?: string
  channelIds: string
  virtualStationIds?: string
}

interface LiveChannel {
  id: number
  number: number | string
  name: string
  logo?: string
  group?: string
  sourceName?: string
  sourceType?: string
  sourceId: number
  enabled: boolean
}

interface VirtualStation {
  id: number
  name: string
  number: number
  logo?: string
  enabled: boolean
}

// ---------------------------------------------------------------------------
// Constants for smart rules
// ---------------------------------------------------------------------------

const FIELD_OPTIONS: { value: string; label: string }[] = [
  { value: 'group', label: 'Group' },
  { value: 'name', label: 'Channel Name' },
  { value: 'number', label: 'Channel Number' },
  { value: 'sourceName', label: 'Source Name' },
  { value: 'sourceType', label: 'Source Type' },
  { value: 'hd', label: 'HD' },
  { value: 'favorite', label: 'Favorite' },
]

const OP_OPTIONS: Record<string, { value: string; label: string }[]> = {
  group: [
    { value: 'eq', label: 'equals' },
    { value: 'neq', label: 'not equals' },
    { value: 'contains', label: 'contains' },
    { value: 'starts_with', label: 'starts with' },
  ],
  name: [
    { value: 'eq', label: 'equals' },
    { value: 'neq', label: 'not equals' },
    { value: 'contains', label: 'contains' },
    { value: 'not_contains', label: 'does not contain' },
    { value: 'starts_with', label: 'starts with' },
    { value: 'ends_with', label: 'ends with' },
  ],
  number: [
    { value: 'eq', label: 'equals' },
    { value: 'gt', label: 'greater than' },
    { value: 'lt', label: 'less than' },
    { value: 'gte', label: 'at least' },
    { value: 'lte', label: 'at most' },
  ],
  sourceName: [
    { value: 'eq', label: 'equals' },
    { value: 'neq', label: 'not equals' },
    { value: 'contains', label: 'contains' },
  ],
  sourceType: [
    { value: 'eq', label: 'equals' },
    { value: 'neq', label: 'not equals' },
  ],
  hd: [{ value: 'eq', label: 'is' }],
  favorite: [{ value: 'eq', label: 'is' }],
}

function getOpsForField(field: string) {
  return OP_OPTIONS[field] || OP_OPTIONS['name']
}

// ---------------------------------------------------------------------------
// API helpers
// ---------------------------------------------------------------------------

const authHeaders: Record<string, string> = {
  'X-Plex-Token': localStorage.getItem('openflix_token') || '',
  'Content-Type': 'application/json',
}

async function fetchChannelCollections(): Promise<ChannelCollection[]> {
  const res = await fetch('/dvr/v2/channel-collections', {
    headers: authHeaders,
  })
  if (!res.ok) throw new Error('Failed to fetch channel collections')
  const data = await res.json()
  return data.collections || []
}

async function createChannelCollection(
  body: Partial<ChannelCollection>,
): Promise<ChannelCollection> {
  const res = await fetch('/dvr/v2/channel-collections', {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to create channel collection')
  return res.json()
}

async function updateChannelCollection(
  id: number,
  body: Partial<ChannelCollection>,
): Promise<ChannelCollection> {
  const res = await fetch(`/dvr/v2/channel-collections/${id}`, {
    method: 'PUT',
    headers: authHeaders,
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to update channel collection')
  return res.json()
}

async function deleteChannelCollection(id: number): Promise<void> {
  const res = await fetch(`/dvr/v2/channel-collections/${id}`, {
    method: 'DELETE',
    headers: authHeaders,
  })
  if (!res.ok) throw new Error('Failed to delete channel collection')
}

async function fetchLiveChannels(): Promise<LiveChannel[]> {
  const res = await fetch('/livetv/channels', { headers: authHeaders })
  if (!res.ok) throw new Error('Failed to fetch channels')
  const data = await res.json()
  return data.channels || []
}

async function fetchVirtualStations(): Promise<VirtualStation[]> {
  const res = await fetch('/dvr/v2/virtual-stations', { headers: authHeaders })
  if (!res.ok) throw new Error('Failed to fetch virtual stations')
  const data = await res.json()
  return data.stations || []
}

async function previewSmartRules(
  smartRules: string,
): Promise<{ count: number; channels: LiveChannel[] }> {
  const res = await fetch('/dvr/v2/channel-collection-rules/preview', {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({ smartRules }),
  })
  if (!res.ok) throw new Error('Failed to preview rules')
  return res.json()
}

async function fetchChannelGroups(): Promise<string[]> {
  const res = await fetch('/dvr/v2/channel-collection-meta/groups', {
    headers: authHeaders,
  })
  if (!res.ok) return []
  const data = await res.json()
  return data.groups || []
}

async function fetchChannelSources(): Promise<string[]> {
  const res = await fetch('/dvr/v2/channel-collection-meta/sources', {
    headers: authHeaders,
  })
  if (!res.ok) return []
  const data = await res.json()
  return data.sources || []
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function parseIds(str: string | undefined): number[] {
  if (!str) return []
  return str
    .split(',')
    .map((s) => parseInt(s.trim(), 10))
    .filter((n) => !isNaN(n))
}

function serializeIds(ids: number[]): string {
  return ids.join(',')
}

function getM3UExportUrl(id: number): string {
  const token = localStorage.getItem('openflix_token') || ''
  return `/dvr/v2/channel-collections/${id}/export.m3u?X-Plex-Token=${token}`
}

function parseSmartRules(json?: string): SmartRuleConfig {
  if (!json) {
    return { enabled: true, conditions: [], match: 'any' }
  }
  try {
    return JSON.parse(json) as SmartRuleConfig
  } catch {
    return { enabled: true, conditions: [], match: 'any' }
  }
}

function emptyCondition(): SmartRuleCond {
  return { field: 'group', op: 'eq', value: '' }
}

// ---------------------------------------------------------------------------
// SmartRulesBuilder
// ---------------------------------------------------------------------------

function SmartRulesBuilder({
  config,
  onChange,
}: {
  config: SmartRuleConfig
  onChange: (cfg: SmartRuleConfig) => void
}) {
  const { data: groups } = useQuery({
    queryKey: ['channel-collection-groups'],
    queryFn: fetchChannelGroups,
  })

  const { data: sources } = useQuery({
    queryKey: ['channel-collection-sources'],
    queryFn: fetchChannelSources,
  })

  const [previewResult, setPreviewResult] = useState<{
    count: number
    channels: LiveChannel[]
  } | null>(null)
  const [previewing, setPreviewing] = useState(false)

  const addCondition = () => {
    onChange({
      ...config,
      conditions: [...config.conditions, emptyCondition()],
    })
  }

  const removeCondition = (index: number) => {
    onChange({
      ...config,
      conditions: config.conditions.filter((_, i) => i !== index),
    })
  }

  const updateCondition = (
    index: number,
    updates: Partial<SmartRuleCond>,
  ) => {
    const next = config.conditions.map((c, i) =>
      i === index ? { ...c, ...updates } : c,
    )
    // Reset op and value when field changes
    if (updates.field !== undefined) {
      const ops = getOpsForField(updates.field)
      next[index].op = ops[0]?.value || 'eq'
      if (updates.field === 'hd' || updates.field === 'favorite') {
        next[index].value = 'true'
      } else {
        next[index].value = ''
      }
    }
    onChange({ ...config, conditions: next })
    setPreviewResult(null)
  }

  const handlePreview = useCallback(async () => {
    if (config.conditions.length === 0) return
    setPreviewing(true)
    setPreviewResult(null)
    try {
      const rulesJSON = JSON.stringify(config)
      const result = await previewSmartRules(rulesJSON)
      setPreviewResult(result)
    } catch {
      // ignore
    } finally {
      setPreviewing(false)
    }
  }, [config])

  const renderValueInput = (cond: SmartRuleCond, index: number) => {
    // Boolean fields
    if (cond.field === 'hd' || cond.field === 'favorite') {
      return (
        <select
          value={cond.value}
          onChange={(e) => updateCondition(index, { value: e.target.value })}
          className="flex-1 min-w-0 px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs focus:outline-none focus:border-indigo-500"
        >
          <option value="true">Yes</option>
          <option value="false">No</option>
        </select>
      )
    }

    // Group field with datalist suggestions
    if (cond.field === 'group' && groups && groups.length > 0) {
      return (
        <>
          <input
            list={`group-options-${index}`}
            type="text"
            value={cond.value}
            onChange={(e) =>
              updateCondition(index, { value: e.target.value })
            }
            placeholder="e.g. Sports"
            className="flex-1 min-w-0 px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
          <datalist id={`group-options-${index}`}>
            {groups.map((g) => (
              <option key={g} value={g} />
            ))}
          </datalist>
        </>
      )
    }

    // Source name field with datalist suggestions
    if (cond.field === 'sourceName' && sources && sources.length > 0) {
      return (
        <>
          <input
            list={`source-options-${index}`}
            type="text"
            value={cond.value}
            onChange={(e) =>
              updateCondition(index, { value: e.target.value })
            }
            placeholder="e.g. My IPTV"
            className="flex-1 min-w-0 px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
          <datalist id={`source-options-${index}`}>
            {sources.map((s) => (
              <option key={s} value={s} />
            ))}
          </datalist>
        </>
      )
    }

    // Source type dropdown
    if (cond.field === 'sourceType') {
      return (
        <select
          value={cond.value}
          onChange={(e) => updateCondition(index, { value: e.target.value })}
          className="flex-1 min-w-0 px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs focus:outline-none focus:border-indigo-500"
        >
          <option value="">Select...</option>
          <option value="m3u">M3U</option>
          <option value="xtream">Xtream</option>
        </select>
      )
    }

    // Default text input
    return (
      <input
        type={cond.field === 'number' ? 'number' : 'text'}
        value={cond.value}
        onChange={(e) => updateCondition(index, { value: e.target.value })}
        placeholder={
          cond.field === 'number' ? 'e.g. 100' : 'e.g. ESPN'
        }
        className="flex-1 min-w-0 px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs placeholder-gray-500 focus:outline-none focus:border-indigo-500"
      />
    )
  }

  return (
    <div className="space-y-4">
      {/* Match mode */}
      <div className="flex items-center gap-4">
        <span className="text-xs text-gray-400">Match channels where:</span>
        <div className="flex items-center gap-2">
          <label className="flex items-center gap-1.5 cursor-pointer">
            <input
              type="radio"
              name="matchMode"
              checked={config.match === 'any'}
              onChange={() => {
                onChange({ ...config, match: 'any' })
                setPreviewResult(null)
              }}
              className="text-indigo-500 focus:ring-indigo-500 bg-gray-700 border-gray-600"
            />
            <span className="text-xs text-gray-300">Any condition</span>
          </label>
          <label className="flex items-center gap-1.5 cursor-pointer">
            <input
              type="radio"
              name="matchMode"
              checked={config.match === 'all'}
              onChange={() => {
                onChange({ ...config, match: 'all' })
                setPreviewResult(null)
              }}
              className="text-indigo-500 focus:ring-indigo-500 bg-gray-700 border-gray-600"
            />
            <span className="text-xs text-gray-300">All conditions</span>
          </label>
        </div>
      </div>

      {/* Conditions */}
      <div className="space-y-2">
        {config.conditions.map((cond, i) => (
          <div key={i} className="flex items-center gap-2">
            {/* Field dropdown */}
            <select
              value={cond.field}
              onChange={(e) => updateCondition(i, { field: e.target.value })}
              className="w-36 flex-shrink-0 px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs focus:outline-none focus:border-indigo-500"
            >
              {FIELD_OPTIONS.map((f) => (
                <option key={f.value} value={f.value}>
                  {f.label}
                </option>
              ))}
            </select>

            {/* Operator dropdown */}
            <select
              value={cond.op}
              onChange={(e) => updateCondition(i, { op: e.target.value })}
              className="w-32 flex-shrink-0 px-2 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs focus:outline-none focus:border-indigo-500"
            >
              {getOpsForField(cond.field).map((op) => (
                <option key={op.value} value={op.value}>
                  {op.label}
                </option>
              ))}
            </select>

            {/* Value input */}
            {renderValueInput(cond, i)}

            {/* Remove button */}
            <button
              type="button"
              onClick={() => removeCondition(i)}
              className="p-1.5 text-gray-500 hover:text-red-400 rounded-lg hover:bg-gray-700 transition-colors flex-shrink-0"
              title="Remove condition"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        ))}
      </div>

      {/* Add condition + Preview */}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={addCondition}
          className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-indigo-400 hover:text-indigo-300 border border-indigo-500/30 hover:border-indigo-500/50 rounded-lg transition-colors"
        >
          <Plus className="w-3.5 h-3.5" />
          Add Condition
        </button>

        {config.conditions.length > 0 && (
          <button
            type="button"
            onClick={handlePreview}
            disabled={previewing}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-emerald-400 hover:text-emerald-300 border border-emerald-500/30 hover:border-emerald-500/50 rounded-lg transition-colors disabled:opacity-50"
          >
            {previewing ? (
              <Loader className="w-3.5 h-3.5 animate-spin" />
            ) : (
              <Eye className="w-3.5 h-3.5" />
            )}
            Preview
          </button>
        )}

        {previewResult !== null && (
          <span className="text-xs text-gray-400">
            {previewResult.count === 0 ? (
              <span className="text-amber-400">No channels match</span>
            ) : (
              <>
                <span className="text-emerald-400 font-medium">
                  {previewResult.count}
                </span>{' '}
                channel{previewResult.count !== 1 ? 's' : ''} matched
              </>
            )}
          </span>
        )}
      </div>

      {/* Preview results */}
      {previewResult && previewResult.channels.length > 0 && (
        <div className="bg-gray-700/30 border border-gray-600 rounded-lg max-h-48 overflow-y-auto">
          {previewResult.channels.map((ch) => (
            <div
              key={ch.id}
              className="flex items-center gap-2 px-3 py-1.5 border-b border-gray-700/50 last:border-0"
            >
              {isAbsoluteUrl(ch.logo) ? (
                <img
                  src={ch.logo}
                  alt=""
                  className="w-5 h-5 rounded object-contain flex-shrink-0 bg-gray-800"
                />
              ) : (
                <div className="w-5 h-5 rounded bg-gray-800 flex items-center justify-center flex-shrink-0">
                  <Tv className="w-2.5 h-2.5 text-gray-600" />
                </div>
              )}
              <span className="text-xs text-gray-500 font-mono w-8 text-right flex-shrink-0">
                {ch.number}
              </span>
              <span className="text-sm text-gray-300 truncate flex-1">
                {ch.name}
              </span>
              {ch.group && (
                <span className="text-xs text-gray-500 truncate max-w-24">
                  {ch.group}
                </span>
              )}
            </div>
          ))}
        </div>
      )}

      {config.conditions.length === 0 && (
        <p className="text-xs text-gray-500">
          Add conditions to automatically populate this lineup based on channel
          properties like group, name, or source.
        </p>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// ChannelPicker
// ---------------------------------------------------------------------------

function ChannelPicker({
  allChannels,
  selectedIds,
  onChange,
}: {
  allChannels: LiveChannel[]
  selectedIds: number[]
  onChange: (ids: number[]) => void
}) {
  const [availableSearch, setAvailableSearch] = useState('')
  const [selectedSearch, setSelectedSearch] = useState('')

  const selectedSet = useMemo(() => new Set(selectedIds), [selectedIds])

  const available = useMemo(
    () =>
      allChannels.filter((ch) => {
        if (selectedSet.has(ch.id)) return false
        if (!availableSearch.trim()) return true
        const q = availableSearch.toLowerCase()
        return (
          ch.name.toLowerCase().includes(q) ||
          String(ch.number).includes(q) ||
          ch.group?.toLowerCase().includes(q)
        )
      }),
    [allChannels, selectedSet, availableSearch],
  )

  const selectedChannels = useMemo(
    () =>
      selectedIds
        .map((id) => allChannels.find((ch) => ch.id === id))
        .filter(Boolean) as LiveChannel[],
    [selectedIds, allChannels],
  )

  const filteredSelected = useMemo(
    () =>
      selectedChannels.filter((ch) => {
        if (!selectedSearch.trim()) return true
        const q = selectedSearch.toLowerCase()
        return (
          ch.name.toLowerCase().includes(q) ||
          String(ch.number).includes(q)
        )
      }),
    [selectedChannels, selectedSearch],
  )

  const addChannel = (id: number) => {
    onChange([...selectedIds, id])
  }

  const removeChannel = (id: number) => {
    onChange(selectedIds.filter((i) => i !== id))
  }

  const moveUp = (index: number) => {
    if (index <= 0) return
    const next = [...selectedIds]
    ;[next[index - 1], next[index]] = [next[index], next[index - 1]]
    onChange(next)
  }

  const moveDown = (index: number) => {
    if (index >= selectedIds.length - 1) return
    const next = [...selectedIds]
    ;[next[index], next[index + 1]] = [next[index + 1], next[index]]
    onChange(next)
  }

  const addAll = () => {
    const newIds = available.map((ch) => ch.id)
    onChange([...selectedIds, ...newIds])
  }

  const removeAll = () => {
    onChange([])
  }

  return (
    <div className="grid grid-cols-2 gap-4">
      {/* Available */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <label className="text-sm font-medium text-gray-300">
            Available ({available.length})
          </label>
          <button
            type="button"
            onClick={addAll}
            className="text-xs text-indigo-400 hover:text-indigo-300 transition-colors"
          >
            Add All
          </button>
        </div>
        <div className="relative mb-2">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
          <input
            type="text"
            value={availableSearch}
            onChange={(e) => setAvailableSearch(e.target.value)}
            placeholder="Search..."
            className="w-full pl-8 pr-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
        </div>
        <div className="bg-gray-700/40 border border-gray-600 rounded-lg max-h-64 overflow-y-auto">
          {available.length === 0 ? (
            <div className="p-4 text-center text-xs text-gray-500">
              {availableSearch ? 'No matches' : 'All channels selected'}
            </div>
          ) : (
            available.map((ch) => (
              <button
                key={ch.id}
                type="button"
                onClick={() => addChannel(ch.id)}
                className="w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-gray-700 transition-colors border-b border-gray-700/50 last:border-0"
              >
                {isAbsoluteUrl(ch.logo) ? (
                  <img
                    src={ch.logo}
                    alt=""
                    className="w-6 h-6 rounded object-contain flex-shrink-0 bg-gray-800"
                  />
                ) : (
                  <div className="w-6 h-6 rounded bg-gray-800 flex items-center justify-center flex-shrink-0">
                    <Tv className="w-3 h-3 text-gray-600" />
                  </div>
                )}
                <span className="text-xs text-gray-400 font-mono w-8 text-right flex-shrink-0">
                  {ch.number}
                </span>
                <span className="text-sm text-gray-300 truncate flex-1">
                  {ch.name}
                </span>
                <ChevronRight className="w-3.5 h-3.5 text-gray-600 flex-shrink-0" />
              </button>
            ))
          )}
        </div>
      </div>

      {/* Selected */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <label className="text-sm font-medium text-gray-300">
            Selected ({selectedIds.length})
          </label>
          {selectedIds.length > 0 && (
            <button
              type="button"
              onClick={removeAll}
              className="text-xs text-red-400 hover:text-red-300 transition-colors"
            >
              Remove All
            </button>
          )}
        </div>
        <div className="relative mb-2">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
          <input
            type="text"
            value={selectedSearch}
            onChange={(e) => setSelectedSearch(e.target.value)}
            placeholder="Search..."
            className="w-full pl-8 pr-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-xs placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
        </div>
        <div className="bg-gray-700/40 border border-gray-600 rounded-lg max-h-64 overflow-y-auto">
          {filteredSelected.length === 0 ? (
            <div className="p-4 text-center text-xs text-gray-500">
              {selectedSearch ? 'No matches' : 'No channels selected'}
            </div>
          ) : (
            filteredSelected.map((ch) => {
              const realIdx = selectedIds.indexOf(ch.id)
              return (
                <div
                  key={ch.id}
                  className="flex items-center gap-1 px-2 py-1.5 border-b border-gray-700/50 last:border-0 group"
                >
                  <GripVertical className="w-3.5 h-3.5 text-gray-600 flex-shrink-0" />
                  <span className="text-xs text-gray-500 font-mono w-5 text-right flex-shrink-0">
                    {realIdx + 1}
                  </span>
                  {isAbsoluteUrl(ch.logo) ? (
                    <img
                      src={ch.logo}
                      alt=""
                      className="w-5 h-5 rounded object-contain flex-shrink-0 bg-gray-800"
                    />
                  ) : (
                    <div className="w-5 h-5 rounded bg-gray-800 flex items-center justify-center flex-shrink-0">
                      <Tv className="w-2.5 h-2.5 text-gray-600" />
                    </div>
                  )}
                  <span className="text-sm text-gray-300 truncate flex-1">
                    {ch.name}
                  </span>
                  <div className="flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0">
                    <button
                      type="button"
                      onClick={() => moveUp(realIdx)}
                      disabled={realIdx === 0}
                      className="p-0.5 text-gray-500 hover:text-white disabled:opacity-30 transition-colors"
                      title="Move up"
                    >
                      <ChevronLeft className="w-3.5 h-3.5 rotate-90" />
                    </button>
                    <button
                      type="button"
                      onClick={() => moveDown(realIdx)}
                      disabled={realIdx === selectedIds.length - 1}
                      className="p-0.5 text-gray-500 hover:text-white disabled:opacity-30 transition-colors"
                      title="Move down"
                    >
                      <ChevronRight className="w-3.5 h-3.5 rotate-90" />
                    </button>
                    <button
                      type="button"
                      onClick={() => removeChannel(ch.id)}
                      className="p-0.5 text-gray-500 hover:text-red-400 transition-colors"
                      title="Remove"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              )
            })
          )}
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// CollectionModal (Create / Edit)
// ---------------------------------------------------------------------------

function ChannelCollectionModal({
  collection,
  onClose,
}: {
  collection: ChannelCollection | null
  onClose: () => void
}) {
  const queryClient = useQueryClient()
  const isEdit = !!collection

  const [name, setName] = useState(collection?.name || '')
  const [description, setDescription] = useState(collection?.description || '')
  const [isSmart, setIsSmart] = useState(collection?.smart || false)
  const [smartRuleConfig, setSmartRuleConfig] = useState<SmartRuleConfig>(
    parseSmartRules(collection?.smartRules),
  )
  const [channelIds, setChannelIds] = useState<number[]>(
    parseIds(collection?.channelIds),
  )
  const [virtualStationIds, setVirtualStationIds] = useState<number[]>(
    parseIds(collection?.virtualStationIds),
  )

  // Fetch available channels and virtual stations
  const { data: allChannels, isLoading: loadingChannels } = useQuery({
    queryKey: ['live-channels'],
    queryFn: fetchLiveChannels,
  })

  const { data: allStations } = useQuery({
    queryKey: ['virtual-stations'],
    queryFn: fetchVirtualStations,
  })

  const createMut = useMutation({
    mutationFn: createChannelCollection,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channel-collections'] })
      onClose()
    },
  })

  const updateMut = useMutation({
    mutationFn: (body: Partial<ChannelCollection>) =>
      updateChannelCollection(collection!.id, body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channel-collections'] })
      onClose()
    },
  })

  const saving = createMut.isPending || updateMut.isPending

  const toggleStation = (id: number) => {
    setVirtualStationIds((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id],
    )
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const body: Partial<ChannelCollection> = {
      name,
      description: description || undefined,
      smart: isSmart,
      smartRules: isSmart ? JSON.stringify(smartRuleConfig) : undefined,
      channelIds: isSmart ? '' : serializeIds(channelIds),
      virtualStationIds: serializeIds(virtualStationIds) || undefined,
    }

    if (isEdit) {
      updateMut.mutate(body)
    } else {
      createMut.mutate(body)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-gray-800 rounded-xl w-full max-w-3xl max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-gray-800 px-6 pt-6 pb-4 border-b border-gray-700 flex items-center justify-between z-10">
          <div className="flex items-center gap-3">
            <ListOrdered className="w-5 h-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-white">
              {isEdit ? 'Edit Channel Lineup' : 'Create Channel Lineup'}
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
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">
                Lineup Name
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
                placeholder="My Custom Lineup"
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">
                Description
              </label>
              <input
                type="text"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Optional description"
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          {/* Mode Toggle: Manual vs Smart */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Lineup Type
            </label>
            <div className="flex rounded-lg border border-gray-600 overflow-hidden">
              <button
                type="button"
                onClick={() => setIsSmart(false)}
                className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium transition-colors ${
                  !isSmart
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-700 text-gray-400 hover:text-gray-300'
                }`}
              >
                <ListOrdered className="w-4 h-4" />
                Manual
              </button>
              <button
                type="button"
                onClick={() => setIsSmart(true)}
                className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium transition-colors ${
                  isSmart
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-700 text-gray-400 hover:text-gray-300'
                }`}
              >
                <Zap className="w-4 h-4" />
                Smart (Auto-populate)
              </button>
            </div>
          </div>

          {/* Smart Rules or Manual Channel Picker */}
          {isSmart ? (
            <div>
              <h3 className="text-sm font-medium text-gray-300 mb-3">
                Auto-populate Rules
              </h3>
              <SmartRulesBuilder
                config={smartRuleConfig}
                onChange={setSmartRuleConfig}
              />
            </div>
          ) : (
            <div>
              <h3 className="text-sm font-medium text-gray-300 mb-3">
                Channels
              </h3>
              {loadingChannels ? (
                <div className="flex items-center justify-center py-8">
                  <Loader className="w-6 h-6 text-indigo-500 animate-spin" />
                </div>
              ) : allChannels ? (
                <ChannelPicker
                  allChannels={allChannels}
                  selectedIds={channelIds}
                  onChange={setChannelIds}
                />
              ) : (
                <p className="text-gray-500 text-sm">
                  No channels available
                </p>
              )}
            </div>
          )}

          {/* Virtual Stations */}
          {allStations && allStations.length > 0 && (
            <div>
              <h3 className="text-sm font-medium text-gray-300 mb-3">
                Include Virtual Stations
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {allStations
                  .filter((s) => s.enabled)
                  .map((station) => {
                    const selected = virtualStationIds.includes(station.id)
                    return (
                      <button
                        key={station.id}
                        type="button"
                        onClick={() => toggleStation(station.id)}
                        className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-sm text-left transition-colors ${
                          selected
                            ? 'border-indigo-500 bg-indigo-500/10 text-white'
                            : 'border-gray-600 bg-gray-700/40 text-gray-400 hover:border-gray-500'
                        }`}
                      >
                        <Radio
                          className={`w-4 h-4 flex-shrink-0 ${
                            selected ? 'text-indigo-400' : 'text-gray-500'
                          }`}
                        />
                        <span className="truncate">{station.name}</span>
                        <span className="text-xs text-gray-500 font-mono flex-shrink-0">
                          #{station.number}
                        </span>
                      </button>
                    )
                  })}
              </div>
            </div>
          )}

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
                'Create Lineup'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// LineupCard
// ---------------------------------------------------------------------------

function LineupCard({
  lineup,
  onEdit,
  onDelete,
}: {
  lineup: ChannelCollection
  onEdit: () => void
  onDelete: () => void
}) {
  const [copied, setCopied] = useState(false)

  const channelCount = parseIds(lineup.channelIds).length
  const virtualCount = parseIds(lineup.virtualStationIds).length
  const totalCount = channelCount + virtualCount

  const handleExport = () => {
    const url = getM3UExportUrl(lineup.id)
    window.open(url, '_blank')
  }

  const handleCopyUrl = async () => {
    const url = `${window.location.origin}${getM3UExportUrl(lineup.id)}`
    try {
      await navigator.clipboard.writeText(url)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      // Fallback
      const textarea = document.createElement('textarea')
      textarea.value = url
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  // Parse smart rules to show summary
  const smartSummary = useMemo(() => {
    if (!lineup.smart || !lineup.smartRules) return null
    try {
      const cfg = JSON.parse(lineup.smartRules) as SmartRuleConfig
      if (!cfg.conditions || cfg.conditions.length === 0) return 'No rules defined'
      const parts = cfg.conditions.map((c) => {
        const fieldLabel =
          FIELD_OPTIONS.find((f) => f.value === c.field)?.label || c.field
        return `${fieldLabel} ${c.op} "${c.value}"`
      })
      const joiner = cfg.match === 'all' ? ' AND ' : ' OR '
      return parts.join(joiner)
    } catch {
      return 'Smart rules'
    }
  }, [lineup.smart, lineup.smartRules])

  return (
    <div className="bg-gray-800 rounded-xl p-5 border border-gray-700 hover:border-gray-600 transition-colors">
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-start gap-4 flex-1 min-w-0">
          <div
            className={`flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center ${
              lineup.smart
                ? 'bg-amber-600/20'
                : 'bg-indigo-600/20'
            }`}
          >
            {lineup.smart ? (
              <Zap className="w-6 h-6 text-amber-400" />
            ) : (
              <ListOrdered className="w-6 h-6 text-indigo-400" />
            )}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <h3 className="text-white font-semibold truncate">
                {lineup.name}
              </h3>
              {lineup.smart && (
                <span className="inline-flex items-center gap-1 px-1.5 py-0.5 text-[10px] font-medium bg-amber-500/20 text-amber-400 rounded">
                  <Zap className="w-2.5 h-2.5" />
                  SMART
                </span>
              )}
            </div>
            {lineup.description && (
              <p className="text-sm text-gray-400 line-clamp-1 mt-0.5">
                {lineup.description}
              </p>
            )}
            {smartSummary && (
              <p className="text-xs text-amber-400/70 line-clamp-1 mt-0.5 font-mono">
                {smartSummary}
              </p>
            )}
            <div className="flex flex-wrap items-center gap-3 mt-2 text-xs text-gray-500">
              {!lineup.smart && (
                <span className="flex items-center gap-1">
                  <Tv className="w-3 h-3" />
                  {channelCount} channels
                </span>
              )}
              {lineup.smart && (
                <span className="flex items-center gap-1">
                  <Zap className="w-3 h-3" />
                  Auto-populated
                </span>
              )}
              {virtualCount > 0 && (
                <span className="flex items-center gap-1">
                  <Radio className="w-3 h-3" />
                  {virtualCount} virtual
                </span>
              )}
              {!lineup.smart && (
                <span className="flex items-center gap-1">
                  <Hash className="w-3 h-3" />
                  {totalCount} total
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-1 flex-shrink-0">
          <button
            onClick={handleExport}
            className="p-2 text-gray-400 hover:text-green-400 hover:bg-gray-700 rounded-lg transition-colors"
            title="Export M3U"
          >
            <Download className="w-4 h-4" />
          </button>
          <button
            onClick={handleCopyUrl}
            className="p-2 text-gray-400 hover:text-blue-400 hover:bg-gray-700 rounded-lg transition-colors"
            title="Copy M3U URL"
          >
            {copied ? (
              <Check className="w-4 h-4 text-green-400" />
            ) : (
              <Copy className="w-4 h-4" />
            )}
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
// ChannelCollectionsPage (exported)
// ---------------------------------------------------------------------------

export function ChannelCollectionsPage() {
  const queryClient = useQueryClient()

  const {
    data: lineups,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['channel-collections'],
    queryFn: fetchChannelCollections,
  })

  const deleteMut = useMutation({
    mutationFn: deleteChannelCollection,
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['channel-collections'] }),
  })

  const [modalLineup, setModalLineup] = useState<
    ChannelCollection | null | 'new'
  >(null)
  const [searchQuery, setSearchQuery] = useState('')

  const filtered = (lineups || []).filter((l) => {
    if (!searchQuery.trim()) return true
    const q = searchQuery.toLowerCase()
    return (
      l.name.toLowerCase().includes(q) ||
      l.description?.toLowerCase().includes(q)
    )
  })

  const handleDelete = (id: number) => {
    if (confirm('Delete this channel lineup? This cannot be undone.')) {
      deleteMut.mutate(id)
    }
  }

  return (
    <div>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Channel Lineups</h1>
          <p className="text-gray-400 mt-1">
            Build custom channel lineups and export them as M3U playlists
          </p>
        </div>
        <button
          onClick={() => setModalLineup('new')}
          className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
        >
          <Plus className="w-4 h-4" />
          New Lineup
        </button>
      </div>

      {/* Search */}
      {(lineups?.length || 0) > 3 && (
        <div className="relative mb-6">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search lineups..."
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
            Failed to load channel lineups
          </h3>
          <p className="text-gray-400 text-sm">
            {error instanceof Error ? error.message : 'Unknown error'}
          </p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 bg-gray-800 rounded-xl">
          <ListOrdered className="w-12 h-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">
            {searchQuery ? 'No matching lineups' : 'No channel lineups yet'}
          </h3>
          <p className="text-gray-400 mb-6">
            {searchQuery
              ? `No lineups match "${searchQuery}"`
              : 'Create custom channel lineups for external players via M3U.'}
          </p>
          {!searchQuery && (
            <button
              onClick={() => setModalLineup('new')}
              className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
            >
              <Plus className="w-4 h-4" />
              New Lineup
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((lineup) => (
            <LineupCard
              key={lineup.id}
              lineup={lineup}
              onEdit={() => setModalLineup(lineup)}
              onDelete={() => handleDelete(lineup.id)}
            />
          ))}
        </div>
      )}

      {/* Modal */}
      {modalLineup !== null && (
        <ChannelCollectionModal
          collection={modalLineup === 'new' ? null : modalLineup}
          onClose={() => setModalLineup(null)}
        />
      )}
    </div>
  )
}
