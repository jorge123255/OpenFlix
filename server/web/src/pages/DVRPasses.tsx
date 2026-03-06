import { useState, useMemo, useEffect, useRef } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Search,
  X,
  Loader,
  Play,
  Pause,
  Trash2,
  Edit,
  Video,
  ArrowUpDown,
  Trophy,
  Tv,
  Film,
  ListFilter,
  Plus,
  CalendarDays,
  CheckSquare,
  Square,
  ChevronDown,
  Bell,
} from 'lucide-react'
import { api } from '../api/client'
import type { DVRPass, ShowSearchResult, ShowTrackerInfo } from '../api/client'

type SortField = 'name' | 'jobs' | 'priority'

function formatKeep(pass: DVRPass): string {
  if (pass.KeepOnly === 'last') return `Keep last ${pass.KeepNum}`
  if (pass.KeepOnly === 'unwatched') return pass.KeepNum > 0 ? `Keep ${pass.KeepNum} unwatched` : 'Unwatched only'
  return 'Keep all'
}

export function DVRPassesPage() {
  const queryClient = useQueryClient()
  const [searchQuery, setSearchQuery] = useState('')
  const [sortField, setSortField] = useState<SortField>('name')
  const [sortAsc, setSortAsc] = useState(true)
  const [showNewRule, setShowNewRule] = useState(false)
  const [editingPass, setEditingPass] = useState<DVRPass | null>(null)

  const { data: passes, isLoading } = useQuery({
    queryKey: ['dvrPasses'],
    queryFn: () => api.getDVRPasses(),
  })

  const pauseMutation = useMutation({
    mutationFn: ({ id, type }: { id: number; type: string }) => api.pauseDVRPass(id, type),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['dvrPasses'] }),
  })

  const resumeMutation = useMutation({
    mutationFn: ({ id, type }: { id: number; type: string }) => api.resumeDVRPass(id, type),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['dvrPasses'] }),
  })

  const deleteSeriesRule = useMutation({
    mutationFn: (id: number) => api.deleteSeriesRule(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['dvrPasses'] }),
  })

  const filteredPasses = useMemo(() => {
    if (!passes) return []

    let result = passes
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase()
      result = result.filter(
        (p) =>
          p.Name.toLowerCase().includes(q) ||
          (p.TeamName && p.TeamName.toLowerCase().includes(q)) ||
          (p.League && p.League.toLowerCase().includes(q))
      )
    }

    result = [...result].sort((a, b) => {
      let cmp = 0
      switch (sortField) {
        case 'name':
          cmp = a.Name.localeCompare(b.Name)
          break
        case 'jobs':
          cmp = a.NumJobs - b.NumJobs
          break
        case 'priority':
          cmp = a.Priority - b.Priority
          break
      }
      return sortAsc ? cmp : -cmp
    })

    return result
  }, [passes, searchQuery, sortField, sortAsc])

  const handleSort = (field: SortField) => {
    if (sortField === field) setSortAsc(!sortAsc)
    else { setSortField(field); setSortAsc(true) }
  }

  const handleToggle = (pass: DVRPass) => {
    if (!pass.Paused) pauseMutation.mutate({ id: pass.ID, type: pass.Type })
    else resumeMutation.mutate({ id: pass.ID, type: pass.Type })
  }

  const handleDelete = (pass: DVRPass) => {
    if (!confirm(`Delete pass "${pass.Name}"? This will not remove existing recordings.`)) return
    if (pass.Type === 'series') deleteSeriesRule.mutate(pass.ID)
  }

  return (
    <div>
      <div className="mb-8 flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">DVR Passes</h1>
          <p className="text-gray-400 mt-1">Manage your recording rules and team passes</p>
        </div>
        <button
          onClick={() => setShowNewRule(true)}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors font-medium"
        >
          <Plus className="w-4 h-4" />
          New Rule
        </button>
      </div>

      {showNewRule && (
        <NewRuleModal
          onClose={() => setShowNewRule(false)}
          onCreated={() => {
            setShowNewRule(false)
            queryClient.invalidateQueries({ queryKey: ['dvrPasses'] })
          }}
        />
      )}

      {editingPass && (
        <EditRuleModal
          pass={editingPass}
          onClose={() => setEditingPass(null)}
          onSaved={() => {
            setEditingPass(null)
            queryClient.invalidateQueries({ queryKey: ['dvrPasses'] })
          }}
        />
      )}

      {/* Search and Sort Bar */}
      <div className="mb-6 flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search passes..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-gray-400 hover:text-white"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>

        <div className="flex items-center gap-1 bg-gray-800 rounded-lg p-1">
          <ListFilter className="w-4 h-4 text-gray-400 ml-2" />
          {(['name', 'jobs', 'priority'] as SortField[]).map((field) => (
            <button
              key={field}
              onClick={() => handleSort(field)}
              className={`px-3 py-1.5 text-sm rounded-md font-medium transition-colors flex items-center gap-1 ${
                sortField === field
                  ? 'bg-indigo-600 text-white'
                  : 'text-gray-400 hover:text-white hover:bg-gray-700'
              }`}
            >
              {field.charAt(0).toUpperCase() + field.slice(1)}
              {sortField === field && <ArrowUpDown className="w-3 h-3" />}
            </button>
          ))}
        </div>
      </div>

      {/* Pass List */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      ) : filteredPasses.length > 0 ? (
        <div className="space-y-3">
          {filteredPasses.map((pass) => (
            <PassCard
              key={`${pass.Type}-${pass.ID}`}
              pass={pass}
              onToggle={() => handleToggle(pass)}
              onEdit={() => setEditingPass(pass)}
              onDelete={() => handleDelete(pass)}
              isToggling={pauseMutation.isPending || resumeMutation.isPending}
            />
          ))}
        </div>
      ) : searchQuery ? (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <Search className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No matches found</h3>
          <p className="text-gray-400">No passes match "{searchQuery}"</p>
          <button
            onClick={() => setSearchQuery('')}
            className="mt-4 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
          >
            Clear search
          </button>
        </div>
      ) : (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <Video className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No recording passes</h3>
          <p className="text-gray-400">Create series rules from DVR or team passes from Team Pass</p>
        </div>
      )}
    </div>
  )
}

function PassCard({
  pass,
  onToggle,
  onEdit,
  onDelete,
  isToggling,
}: {
  pass: DVRPass
  onToggle: () => void
  onEdit: () => void
  onDelete: () => void
  isToggling: boolean
}) {
  const isActive = !pass.Paused
  const typeColor =
    pass.Type === 'team'
      ? 'bg-amber-500/20 text-amber-400'
      : 'bg-indigo-500/20 text-indigo-400'
  const TypeIcon = pass.Type === 'team' ? Trophy : Tv

  return (
    <div
      className={`bg-gray-800 rounded-xl border transition-colors ${
        isActive ? 'border-gray-700 hover:border-gray-600' : 'border-gray-700/50 opacity-60'
      }`}
    >
      <div className="p-4 flex items-start gap-4">
        <div className="flex-shrink-0 w-16 h-24 rounded-lg overflow-hidden bg-gray-700 flex items-center justify-center">
          {pass.Image ? (
            <img src={pass.Image} alt={pass.Name} className="w-full h-full object-cover" />
          ) : (
            <TypeIcon className="w-8 h-8 text-gray-500" />
          )}
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <h3 className="font-semibold text-white text-lg truncate">{pass.Name}</h3>
              <div className="mt-1 flex flex-wrap items-center gap-2">
                <span className={`px-2 py-0.5 text-xs font-medium rounded ${typeColor}`}>
                  {pass.Type === 'team' ? 'Team Pass' : 'Series Rule'}
                </span>
                {pass.Paused && (
                  <span className="px-2 py-0.5 text-xs font-medium rounded bg-gray-600 text-gray-300">
                    Paused
                  </span>
                )}
                {pass.League && (
                  <span className="px-2 py-0.5 text-xs font-medium rounded bg-green-500/20 text-green-400">
                    {pass.League}
                  </span>
                )}
              </div>
            </div>
          </div>

          <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-gray-400">
            <span className="flex items-center gap-1">
              <Video className="w-3.5 h-3.5" />
              {pass.NumJobs} recording{pass.NumJobs !== 1 ? 's' : ''}
            </span>
            <span>{formatKeep(pass)}</span>
            {pass.Rerecord && <span className="text-indigo-400">Re-record</span>}
          </div>
          {pass.Tracker && <TrackerBadge tracker={pass.Tracker} />}
        </div>

        <div className="flex-shrink-0 flex items-center gap-1">
          <button
            onClick={onToggle}
            disabled={isToggling}
            className={`p-2 rounded-lg transition-colors ${
              isActive
                ? 'text-gray-400 hover:text-amber-400 hover:bg-gray-700'
                : 'text-amber-400 hover:text-green-400 hover:bg-gray-700'
            }`}
            title={isActive ? 'Pause' : 'Resume'}
          >
            {isActive ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
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

function TrackerBadge({ tracker }: { tracker: ShowTrackerInfo }) {
  if (!tracker.nextSeasonNumber || !tracker.nextEpisodeAirDate) return null
  const d = new Date(tracker.nextEpisodeAirDate)
  const label = d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
  return (
    <div className="mt-1.5 flex items-center gap-1 text-blue-400 text-xs">
      <Bell className="w-3 h-3" />
      <span>Season {tracker.nextSeasonNumber} premieres {label}</span>
    </div>
  )
}

function formatAirDay(isoString: string): string {
  const d = new Date(isoString)
  return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })
}

function NewRuleModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const [query, setQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')
  const [mediaType, setMediaType] = useState<'tv' | 'movie'>('tv')
  const [creatingTitle, setCreatingTitle] = useState<string | null>(null)
  const [createError, setCreateError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedQuery(query.trim()), 400)
    return () => clearTimeout(timer)
  }, [query])

  const { data: results = [], isLoading } = useQuery({
    queryKey: ['show-search', debouncedQuery, mediaType],
    queryFn: () =>
      debouncedQuery.length >= 2
        ? api.searchShowForPass(debouncedQuery, mediaType)
        : Promise.resolve([] as ShowSearchResult[]),
  })

  const handleSelect = async (result: ShowSearchResult) => {
    if (creatingTitle) return
    setCreatingTitle(result.title)
    setCreateError(null)
    try {
      await api.createDVRPass({
        Type: 'series',
        Name: result.title,
        Image: result.posterUrl,
        EQ: { Title: result.title },
        Rerecord: false,
        KeepOnly: '',
        KeepNum: 0,
        PaddingStart: 0,
        PaddingEnd: 0,
        Limit: 0,
        Priority: 0,
        TmdbId: result.tmdbId,
        MediaType: result.mediaType,
      })
      onCreated()
    } catch {
      setCreateError('Failed to create rule. Please try again.')
      setCreatingTitle(null)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-black/70 pt-16 px-4 overflow-y-auto">
      <div className="bg-gray-800 rounded-xl shadow-2xl w-full max-w-2xl border border-gray-700 mb-8">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-700">
          <h2 className="text-lg font-semibold text-white">New Recording Rule</h2>
          <button onClick={onClose} className="p-1 text-gray-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Search + type toggle */}
        <div className="px-5 py-4 border-b border-gray-700 space-y-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              ref={inputRef}
              type="text"
              placeholder="Search shows & movies..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="w-full pl-9 pr-4 py-2.5 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
            {query && (
              <button
                onClick={() => setQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
          <div className="flex gap-2">
            {(['tv', 'movie'] as const).map((t) => (
              <button
                key={t}
                onClick={() => setMediaType(t)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  mediaType === t
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-700 text-gray-400 hover:text-white'
                }`}
              >
                {t === 'tv' ? <Tv className="w-3.5 h-3.5" /> : <Film className="w-3.5 h-3.5" />}
                {t === 'tv' ? 'TV Shows' : 'Movies'}
              </button>
            ))}
          </div>
        </div>

        {/* Poster grid results — scrollable */}
        <div className="p-5 min-h-48 max-h-[55vh] overflow-y-auto">
          {isLoading ? (
            <div className="flex items-center justify-center py-10">
              <Loader className="w-6 h-6 text-indigo-500 animate-spin" />
            </div>
          ) : results.length === 0 && debouncedQuery.length >= 2 ? (
            <div className="text-center py-10 text-gray-500 text-sm">
              No results found for "{debouncedQuery}"
            </div>
          ) : results.length === 0 ? (
            <div className="text-center py-10 text-gray-500 text-sm">
              Search for a show or movie to create a recording rule
            </div>
          ) : (
            <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
              {results.map((result, idx) => (
                <ShowPosterCard
                  key={`${result.tmdbId ?? result.title}-${idx}`}
                  result={result}
                  creatingTitle={creatingTitle}
                  onSelect={handleSelect}
                />
              ))}
            </div>
          )}
        </div>

        {createError && (
          <div className="px-5 py-3 bg-red-500/10 border-t border-red-500/20 text-red-400 text-sm">
            {createError}
          </div>
        )}
      </div>
    </div>
  )
}

function ShowPosterCard({
  result,
  creatingTitle,
  onSelect,
}: {
  result: ShowSearchResult
  creatingTitle: string | null
  onSelect: (r: ShowSearchResult) => void
}) {
  const isThisOne = creatingTitle === result.title
  const anyCreating = creatingTitle !== null

  return (
    <button
      disabled={anyCreating}
      onClick={() => onSelect(result)}
      className="group flex flex-col gap-1.5 text-left disabled:cursor-not-allowed hover:scale-105 transition-transform"
      style={{ opacity: anyCreating && !isThisOne ? 0.4 : 1 }}
    >
      {/* Poster */}
      <div className="relative w-full aspect-[2/3] rounded-lg overflow-hidden bg-gray-700 flex items-center justify-center">
        {result.posterUrl ? (
          <img
            src={result.posterUrl}
            alt={result.title}
            className="w-full h-full object-cover"
            loading="lazy"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-indigo-800/80 to-purple-900/60">
            {result.mediaType === 'movie' ? (
              <Film className="w-10 h-10 text-indigo-300/70" />
            ) : (
              <Tv className="w-10 h-10 text-indigo-300/70" />
            )}
          </div>
        )}
        {/* Hover overlay */}
        <div className="absolute inset-0 bg-indigo-600/0 group-hover:bg-indigo-600/20 transition-colors rounded-lg" />
        {/* Per-card creating spinner */}
        {isThisOne && (
          <div className="absolute inset-0 bg-black/60 flex items-center justify-center rounded-lg">
            <Loader className="w-6 h-6 text-white animate-spin" />
          </div>
        )}
      </div>

      {/* Title + year */}
      <p className="text-white text-xs font-medium leading-tight line-clamp-2">
        {result.title}
        {result.year ? <span className="text-gray-400 font-normal"> ({result.year})</span> : null}
      </p>

      {/* Next airing / not in guide */}
      {result.nextAiring ? (
        <p className="text-blue-400 text-xs flex items-center gap-1 leading-tight">
          <CalendarDays className="w-3 h-3 flex-shrink-0" />
          {formatAirDay(result.nextAiring.start)} · {result.nextAiring.channelName}
        </p>
      ) : (
        <p className="text-gray-500 text-xs leading-tight">Not in guide yet</p>
      )}
    </button>
  )
}

// ─── EditRuleModal ────────────────────────────────────────────────────────────

type ConditionKey =
  | 'Title' | 'Channel' | 'EpisodeTitle' | 'EventTitle' | 'Tags'
  | 'Categories' | 'Genres' | 'Time' | 'Duration' | 'OriginalDate'
  | 'SeasonNumber' | 'EpisodeNumber' | 'Directors' | 'Cast' | 'Summary'

type ConditionType = 'EQ' | 'NE' | 'IN' | 'NI' | 'LT' | 'GT'

type FlatCondition = { key: ConditionKey; type: ConditionType; value: string }

const CONDITION_KEYS: ConditionKey[] = [
  'Title', 'Channel', 'EpisodeTitle', 'EventTitle', 'Tags',
  'Categories', 'Genres', 'Time', 'Duration', 'OriginalDate',
  'SeasonNumber', 'EpisodeNumber', 'Directors', 'Cast', 'Summary',
]

function typesForKey(key: ConditionKey): ConditionType[] {
  if (key === 'Time') return ['IN', 'NI']
  if (['Duration', 'OriginalDate', 'EpisodeNumber', 'SeasonNumber'].includes(key))
    return ['EQ', 'NE', 'LT', 'GT']
  if (['Title', 'EpisodeTitle', 'EventTitle', 'Tags', 'Categories', 'Genres', 'Directors', 'Cast', 'Summary'].includes(key))
    return ['EQ', 'NE', 'IN', 'NI']
  return ['EQ', 'NE', 'IN', 'NI', 'LT', 'GT']
}

function conditionTypeLabel(t: ConditionType) {
  return { EQ: '==', NE: '!=', IN: 'contains', NI: 'excludes', LT: '<', GT: '>' }[t]
}

/** Flatten EQ/NE/IN/NI/GT/LT maps into a list of FlatCondition rows */
function flattenConditions(pass: DVRPass): FlatCondition[] {
  const out: FlatCondition[] = []
  for (const type of ['EQ', 'NE', 'IN', 'NI', 'GT', 'LT'] as ConditionType[]) {
    const map = (pass as unknown as Record<string, unknown>)[type] as Record<string, unknown> | undefined
    if (!map) continue
    for (const [key, val] of Object.entries(map)) {
      const vals = Array.isArray(val) ? val : [val]
      for (const v of vals) {
        out.push({ key: key as ConditionKey, type, value: String(v) })
      }
    }
  }
  return out
}

/** Build EQ/NE/IN/NI/GT/LT maps from flat conditions */
function buildConditionMaps(rows: FlatCondition[]) {
  const maps: Record<string, Record<string, unknown>> = {}
  for (const { key, type, value } of rows) {
    if (!maps[type]) maps[type] = {}
    const existing = maps[type][key]
    if (existing === undefined) {
      maps[type][key] = value
    } else if (Array.isArray(existing)) {
      maps[type][key] = [...existing, value]
    } else {
      maps[type][key] = [existing, value]
    }
  }
  return maps
}

function keepLabel(keepOnly: string, keepNum: number) {
  if (keepOnly === 'last') return keepNum ? `Last ${keepNum}` : 'Last 1'
  if (keepOnly === 'unwatched') return 'Unwatched only'
  return 'All episodes'
}

function EditRuleModal({
  pass,
  onClose,
  onSaved,
}: {
  pass: DVRPass
  onClose: () => void
  onSaved: () => void
}) {
  const [tab, setTab] = useState<'simple' | 'advanced'>('simple')
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  // Simple fields
  const eqMap = (pass.EQ as Record<string, unknown> | undefined) ?? {}
  const [newOnly, setNewOnly] = useState((eqMap['Tags'] as string) === 'New')
  const [channel, setChannel] = useState((eqMap['Channel'] as string) ?? '')
  const [paddingBefore, setPaddingBefore] = useState(Math.round((pass.PaddingStart ?? 0) / 60))
  const [paddingAfter, setPaddingAfter] = useState(Math.round((pass.PaddingEnd ?? 0) / 60))
  const [keepOnly, setKeepOnly] = useState(pass.KeepOnly ?? '')
  const [keepNum, setKeepNum] = useState(pass.KeepNum ?? 0)

  // Advanced fields
  const [name, setName] = useState(pass.Name)
  const [limit, setLimit] = useState(pass.Limit ?? 0)
  const [rerecord, setRerecord] = useState(pass.Rerecord ?? false)

  // Conditions (excluding Tags/Channel managed in simple tab)
  const [conditions, setConditions] = useState<FlatCondition[]>(() =>
    flattenConditions(pass).filter((c) => !(c.key === 'Tags' && c.value === 'New') && c.key !== 'Channel')
  )
  const [newCond, setNewCond] = useState<FlatCondition>({ key: 'Title', type: 'EQ', value: '' })
  const [addingCond, setAddingCond] = useState(false)

  const handleSave = async () => {
    setSaving(true)
    setSaveError(null)
    try {
      // Build EQ map — start with conditions, add simple-tab overrides
      const condMaps = buildConditionMaps(conditions)
      const eq = { ...(condMaps['EQ'] ?? {}) }
      if (channel.trim()) eq['Channel'] = channel.trim()
      else delete eq['Channel']
      if (newOnly) eq['Tags'] = 'New'
      else delete eq['Tags']

      await api.updateDVRPass(pass.ID, {
        Name: name,
        PaddingStart: paddingBefore * 60,
        PaddingEnd: paddingAfter * 60,
        KeepOnly: keepOnly,
        KeepNum: keepNum,
        Limit: limit,
        Rerecord: rerecord,
        EQ: Object.keys(eq).length ? eq : undefined,
        NE: condMaps['NE'],
        IN: condMaps['IN'],
        NI: condMaps['NI'],
        GT: condMaps['GT'],
        LT: condMaps['LT'],
      })
      onSaved()
    } catch {
      setSaveError('Save failed. Please try again.')
      setSaving(false)
    }
  }

  const addCondition = () => {
    if (!newCond.value.trim()) return
    setConditions((prev) => [...prev, { ...newCond }])
    setNewCond({ key: 'Title', type: 'EQ', value: '' })
    setAddingCond(false)
  }

  const removeCondition = (idx: number) => setConditions((prev) => prev.filter((_, i) => i !== idx))

  const KEEP_OPTIONS = [
    { label: 'All episodes', keepOnly: '', keepNum: 0 },
    { label: 'Last 1', keepOnly: 'last', keepNum: 1 },
    { label: 'Last 2', keepOnly: 'last', keepNum: 2 },
    { label: 'Last 3', keepOnly: 'last', keepNum: 3 },
    { label: 'Last 5', keepOnly: 'last', keepNum: 5 },
    { label: 'Last 10', keepOnly: 'last', keepNum: 10 },
    { label: 'Unwatched only', keepOnly: 'unwatched', keepNum: 0 },
  ]

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-black/70 pt-12 px-4 overflow-y-auto">
      <div className="bg-gray-800 rounded-xl shadow-2xl w-full max-w-lg border border-gray-700 mb-8">
        {/* Header */}
        <div className="flex items-center gap-3 px-5 py-4 border-b border-gray-700">
          {pass.Image && (
            <img src={pass.Image} alt={pass.Name} className="w-10 h-14 object-cover rounded" />
          )}
          <div className="flex-1 min-w-0">
            <h2 className="text-lg font-semibold text-white truncate">{pass.Name}</h2>
            <p className="text-xs text-gray-400">Edit recording rule</p>
          </div>
          <button onClick={onClose} className="p-1 text-gray-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-gray-700">
          {(['simple', 'advanced'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`flex-1 py-2.5 text-sm font-medium transition-colors ${
                tab === t
                  ? 'text-white border-b-2 border-indigo-500'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              {t === 'simple' ? 'Simple' : 'Advanced'}
            </button>
          ))}
        </div>

        <div className="px-5 py-4 space-y-5">
          {tab === 'simple' && (
            <>
              {/* Record new/all toggle */}
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-white">Record</p>
                  <p className="text-xs text-gray-400">Which episodes to record</p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => setNewOnly(true)}
                    className={`px-3 py-1.5 text-sm rounded-lg font-medium transition-colors ${newOnly ? 'bg-indigo-600 text-white' : 'bg-gray-700 text-gray-400 hover:text-white'}`}
                  >New Episodes</button>
                  <button
                    onClick={() => setNewOnly(false)}
                    className={`px-3 py-1.5 text-sm rounded-lg font-medium transition-colors ${!newOnly ? 'bg-indigo-600 text-white' : 'bg-gray-700 text-gray-400 hover:text-white'}`}
                  >All Episodes</button>
                </div>
              </div>

              {/* Channel filter */}
              <div>
                <label className="block text-sm font-medium text-white mb-1.5">Channel Number</label>
                <input
                  type="text"
                  placeholder="Any channel"
                  value={channel}
                  onChange={(e) => setChannel(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-500 text-sm focus:outline-none focus:border-indigo-500"
                />
              </div>

              {/* Padding */}
              <div>
                <p className="text-sm font-medium text-white mb-1.5">Padding (minutes)</p>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">Before</label>
                    <input
                      type="number" min={0} max={120}
                      value={paddingBefore}
                      onChange={(e) => setPaddingBefore(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">After</label>
                    <input
                      type="number" min={0} max={120}
                      value={paddingAfter}
                      onChange={(e) => setPaddingAfter(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                    />
                  </div>
                </div>
              </div>

              {/* Keep */}
              <div>
                <label className="block text-sm font-medium text-white mb-1.5">Keep</label>
                <div className="relative">
                  <select
                    value={`${keepOnly}|${keepNum}`}
                    onChange={(e) => {
                      const [ko, kn] = e.target.value.split('|')
                      setKeepOnly(ko)
                      setKeepNum(Number(kn))
                    }}
                    className="w-full px-3 py-2 pr-8 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500 appearance-none"
                  >
                    {KEEP_OPTIONS.map((o) => (
                      <option key={o.label} value={`${o.keepOnly}|${o.keepNum}`}>{o.label}</option>
                    ))}
                  </select>
                  <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </div>
            </>
          )}

          {tab === 'advanced' && (
            <>
              {/* Name */}
              <div>
                <label className="block text-sm font-medium text-white mb-1.5">Name</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                />
              </div>

              {/* Limit */}
              <div>
                <label className="block text-sm font-medium text-white mb-1.5">Recording Limit</label>
                <div className="relative">
                  <select
                    value={limit}
                    onChange={(e) => setLimit(Number(e.target.value))}
                    className="w-full px-3 py-2 pr-8 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500 appearance-none"
                  >
                    <option value={0}>No limit</option>
                    {[3, 5, 10, 20, 50, 100].map((n) => (
                      <option key={n} value={n}>{n} recordings</option>
                    ))}
                  </select>
                  <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </div>

              {/* Rerecord */}
              <div
                className="flex items-center gap-3 cursor-pointer"
                onClick={() => setRerecord((v) => !v)}
              >
                {rerecord ? (
                  <CheckSquare className="w-5 h-5 text-indigo-400 flex-shrink-0" />
                ) : (
                  <Square className="w-5 h-5 text-gray-500 flex-shrink-0" />
                )}
                <div>
                  <p className="text-sm font-medium text-white">Re-record deleted episodes</p>
                  <p className="text-xs text-gray-400">Record again if a saved episode is deleted</p>
                </div>
              </div>

              {/* Conditions */}
              <div>
                <p className="text-sm font-medium text-white mb-2">Conditions</p>
                <div className="space-y-2">
                  {conditions.length === 0 && !addingCond && (
                    <p className="text-xs text-gray-500">No extra conditions</p>
                  )}
                  {conditions.map((c, i) => (
                    <div key={i} className="flex items-center gap-2 bg-gray-700 rounded-lg px-3 py-2 text-sm">
                      <span className="text-gray-300 font-medium">{c.key}</span>
                      <span className="text-indigo-400 text-xs">{conditionTypeLabel(c.type)}</span>
                      <span className="text-white flex-1 truncate">{c.value}</span>
                      <button
                        onClick={() => removeCondition(i)}
                        className="text-gray-500 hover:text-red-400 flex-shrink-0"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  ))}

                  {addingCond && (
                    <div className="bg-gray-700 rounded-lg p-3 space-y-2">
                      <div className="grid grid-cols-2 gap-2">
                        <select
                          value={newCond.key}
                          onChange={(e) => {
                            const k = e.target.value as ConditionKey
                            const types = typesForKey(k)
                            setNewCond({ key: k, type: types[0], value: '' })
                          }}
                          className="px-2 py-1.5 bg-gray-600 border border-gray-500 rounded text-white text-xs focus:outline-none"
                        >
                          {CONDITION_KEYS.map((k) => <option key={k}>{k}</option>)}
                        </select>
                        <select
                          value={newCond.type}
                          onChange={(e) => setNewCond((c) => ({ ...c, type: e.target.value as ConditionType }))}
                          className="px-2 py-1.5 bg-gray-600 border border-gray-500 rounded text-white text-xs focus:outline-none"
                        >
                          {typesForKey(newCond.key).map((t) => (
                            <option key={t} value={t}>{conditionTypeLabel(t)}</option>
                          ))}
                        </select>
                      </div>
                      <input
                        type="text"
                        placeholder={`Value for ${newCond.key}...`}
                        value={newCond.value}
                        onChange={(e) => setNewCond((c) => ({ ...c, value: e.target.value }))}
                        onKeyDown={(e) => e.key === 'Enter' && addCondition()}
                        className="w-full px-2 py-1.5 bg-gray-600 border border-gray-500 rounded text-white text-xs focus:outline-none"
                        autoFocus
                      />
                      <div className="flex gap-2">
                        <button
                          onClick={addCondition}
                          className="px-3 py-1 bg-indigo-600 hover:bg-indigo-700 text-white text-xs rounded font-medium"
                        >Add</button>
                        <button
                          onClick={() => setAddingCond(false)}
                          className="px-3 py-1 bg-gray-600 hover:bg-gray-500 text-white text-xs rounded"
                        >Cancel</button>
                      </div>
                    </div>
                  )}

                  {!addingCond && (
                    <button
                      onClick={() => setAddingCond(true)}
                      className="flex items-center gap-1 text-xs text-indigo-400 hover:text-indigo-300 mt-1"
                    >
                      <Plus className="w-3.5 h-3.5" /> Add condition
                    </button>
                  )}
                </div>
              </div>
            </>
          )}
        </div>

        {saveError && (
          <div className="px-5 py-2 bg-red-500/10 border-t border-red-500/20 text-red-400 text-sm">
            {saveError}
          </div>
        )}

        {/* Footer */}
        <div className="flex items-center justify-between px-5 py-4 border-t border-gray-700">
          <div className="text-xs text-gray-500">
            Keep: {keepLabel(keepOnly, keepNum)}
            {paddingBefore > 0 || paddingAfter > 0 ? ` · +${paddingBefore}/${paddingAfter}min` : ''}
          </div>
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-sm text-gray-400 hover:text-white transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white text-sm font-medium rounded-lg transition-colors"
            >
              {saving && <Loader className="w-3.5 h-3.5 animate-spin" />}
              Save
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
