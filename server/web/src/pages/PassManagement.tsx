import { useState, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Search,
  X,
  Loader,
  Play,
  Pause,
  Trash2,
  Edit2,
  Video,
  Plus,
  Tv,
  ShieldCheck,
  FlaskConical,
} from 'lucide-react'
import { api } from '../api/client'
import type { DVRPass, PassTestAiring } from '../api/client'

// ---------- Helpers ----------

function formatKeep(pass: DVRPass): string {
  if (pass.KeepOnly === 'last') return `Keep last ${pass.KeepNum}`
  if (pass.KeepOnly === 'unwatched') return pass.KeepNum > 0 ? `Keep ${pass.KeepNum} unwatched` : 'Unwatched only'
  return 'Keep all'
}

function formatPadding(seconds: number): string {
  if (seconds === 0) return '0 min'
  const mins = Math.round(seconds / 60)
  return `${mins} min`
}

// ---------- Pass Form Modal ----------
interface PassFormValues {
  Name: string
  KeepOnly: string   // "" | "unwatched" | "last"
  KeepNum: number
  PaddingStart: number  // stored as minutes in the form, converted to seconds on save
  PaddingEnd: number
  Rerecord: boolean
  NewOnly: boolean       // adds EQ.Tags="New" → only record new episodes
  ExcludeSpecials: boolean // adds NE.EpisodeNumber=0 → skip specials / pilots
}

function PassFormModal({
  initial,
  onSave,
  onClose,
  isSaving,
}: {
  initial?: Partial<PassFormValues>
  onSave: (v: PassFormValues) => void
  onClose: () => void
  isSaving: boolean
}) {
  const [form, setForm] = useState<PassFormValues>({
    Name: initial?.Name ?? '',
    KeepOnly: initial?.KeepOnly ?? '',
    KeepNum: initial?.KeepNum ?? 0,
    PaddingStart: initial?.PaddingStart ?? 0,
    PaddingEnd: initial?.PaddingEnd ?? 0,
    Rerecord: initial?.Rerecord ?? false,
    NewOnly: initial?.NewOnly ?? true,
    ExcludeSpecials: initial?.ExcludeSpecials ?? false,
  })

  const set = <K extends keyof PassFormValues>(k: K, v: PassFormValues[K]) =>
    setForm((f) => ({ ...f, [k]: v }))

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl w-full max-w-lg border border-gray-700 shadow-xl">
        <div className="flex items-center justify-between p-5 border-b border-gray-700">
          <h2 className="text-lg font-semibold text-white">
            {initial?.Name ? 'Edit Pass' : 'New Recording Pass'}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-5 space-y-4 overflow-y-auto max-h-[70vh]">
          {/* Name */}
          <div>
            <label className="block text-sm text-gray-400 mb-1">
              Show / Title <span className="text-red-400">*</span>
            </label>
            <input
              type="text"
              value={form.Name}
              onChange={(e) => set('Name', e.target.value)}
              placeholder="e.g. Survivor"
              className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
            />
          </div>

          {/* Keep */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Keep</label>
              <select
                value={form.KeepOnly}
                onChange={(e) => set('KeepOnly', e.target.value)}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
              >
                <option value="">All episodes</option>
                <option value="unwatched">Unwatched only</option>
                <option value="last">Last N</option>
              </select>
            </div>
            {form.KeepOnly !== '' && (
              <div>
                <label className="block text-sm text-gray-400 mb-1">
                  {form.KeepOnly === 'last' ? 'Keep last N' : 'Max watched'}
                </label>
                <select
                  value={form.KeepNum}
                  onChange={(e) => set('KeepNum', Number(e.target.value))}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
                >
                  {[0, 1, 3, 5, 10, 20, 30, 50].map((n) => (
                    <option key={n} value={n}>{n === 0 ? 'All' : n}</option>
                  ))}
                </select>
              </div>
            )}
          </div>

          {/* Padding */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Pre-padding (min)</label>
              <input
                type="number"
                min={0}
                max={60}
                value={form.PaddingStart}
                onChange={(e) => set('PaddingStart', Number(e.target.value))}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Post-padding (min)</label>
              <input
                type="number"
                min={0}
                max={120}
                value={form.PaddingEnd}
                onChange={(e) => set('PaddingEnd', Number(e.target.value))}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          {/* Filter toggles */}
          <div className="space-y-2 pt-1">
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={form.NewOnly}
                onChange={(e) => set('NewOnly', e.target.checked)}
                className="w-4 h-4 rounded accent-indigo-600"
              />
              <div>
                <span className="text-sm text-gray-300">New episodes only</span>
                <p className="text-xs text-gray-500">Skip repeats and re-runs</p>
              </div>
            </label>
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={form.ExcludeSpecials}
                onChange={(e) => set('ExcludeSpecials', e.target.checked)}
                className="w-4 h-4 rounded accent-indigo-600"
              />
              <div>
                <span className="text-sm text-gray-300">Exclude specials</span>
                <p className="text-xs text-gray-500">Skip episodes with no episode number</p>
              </div>
            </label>
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={form.Rerecord}
                onChange={(e) => set('Rerecord', e.target.checked)}
                className="w-4 h-4 rounded accent-indigo-600"
              />
              <span className="text-sm text-gray-300">Re-record deleted episodes</span>
            </label>
          </div>
        </div>

        <div className="flex gap-3 p-5 border-t border-gray-700">
          <button
            onClick={onClose}
            className="flex-1 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm"
          >
            Cancel
          </button>
          <button
            onClick={() => onSave(form)}
            disabled={!form.Name.trim() || isSaving}
            className="flex-1 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-lg text-sm font-medium"
          >
            {isSaving ? 'Saving…' : 'Save Pass'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ---------- Pass Test Modal ----------
function PassTestModal({ pass, onClose }: { pass: DVRPass; onClose: () => void }) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['passTest', pass.ID],
    queryFn: () => api.testDVRPass({ EQ: pass.EQ, NE: pass.NE, IN: pass.IN, NI: pass.NI, GT: pass.GT, LT: pass.LT }),
  })

  const airings = data?.airings ?? []

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl w-full max-w-2xl border border-gray-700 shadow-xl flex flex-col max-h-[80vh]">
        <div className="flex items-center justify-between p-5 border-b border-gray-700 flex-shrink-0">
          <div>
            <h2 className="text-lg font-semibold text-white">Test Pass — {pass.Name}</h2>
            <p className="text-sm text-gray-400 mt-0.5">Upcoming airings that match this pass</p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="overflow-y-auto flex-1 p-4">
          {isLoading && (
            <div className="flex items-center justify-center py-12 text-gray-400">
              <Loader className="w-5 h-5 animate-spin mr-2" /> Checking guide...
            </div>
          )}
          {isError && (
            <div className="text-red-400 text-sm text-center py-8">Failed to test pass.</div>
          )}
          {!isLoading && !isError && airings.length === 0 && (
            <div className="text-center py-12 text-gray-400">
              <FlaskConical className="w-10 h-10 mx-auto mb-3 opacity-30" />
              <p>No upcoming airings match this pass in the next 14 days.</p>
            </div>
          )}
          {airings.length > 0 && (
            <div className="space-y-1">
              <p className="text-xs text-gray-500 mb-3">{data!.count} airing{data!.count !== 1 ? 's' : ''} found</p>
              {airings.map((a: PassTestAiring) => (
                <div key={a.programId} className="flex items-center gap-3 py-2.5 px-3 rounded-lg bg-gray-700/50">
                  {a.channelLogo ? (
                    <img src={a.channelLogo} alt={a.channelName} className="w-8 h-8 object-contain rounded" />
                  ) : (
                    <div className="w-8 h-8 flex items-center justify-center bg-gray-600 rounded">
                      <Tv className="w-4 h-4 text-gray-400" />
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-medium text-white">{a.title}</span>
                      {a.isNew && <span className="text-xs px-1.5 py-0.5 rounded bg-green-500/20 text-green-400">New</span>}
                      {a.isSports && <span className="text-xs px-1.5 py-0.5 rounded bg-blue-500/20 text-blue-400">Sports</span>}
                      {a.isMovie && <span className="text-xs px-1.5 py-0.5 rounded bg-purple-500/20 text-purple-400">Movie</span>}
                    </div>
                    {a.subtitle && <p className="text-xs text-gray-400 truncate">{a.subtitle}</p>}
                    <p className="text-xs text-gray-500">
                      {a.channelName} · {new Date(a.start).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })} {new Date(a.start).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      {a.episodeNum ? ` · ${a.episodeNum}` : ''}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="border-t border-gray-700 p-4 flex-shrink-0">
          <button onClick={onClose} className="w-full px-4 py-2 bg-gray-700 text-white text-sm rounded-lg hover:bg-gray-600 transition-colors">
            Close
          </button>
        </div>
      </div>
    </div>
  )
}

// ---------- Pass Card ----------
function PassCard({
  pass,
  onToggle,
  onDelete,
  onEdit,
  onTest,
  isToggling,
}: {
  pass: DVRPass
  onToggle: () => void
  onDelete: () => void
  onEdit: () => void
  onTest: () => void
  isToggling: boolean
}) {
  const isActive = !pass.Paused

  return (
    <div
      className={`bg-gray-800 rounded-xl border transition-colors ${
        isActive
          ? 'border-gray-700 hover:border-gray-600'
          : 'border-gray-700/40 opacity-60'
      }`}
    >
      <div className="p-4 flex items-center gap-4">
        {/* Icon */}
        <div className="flex-shrink-0 w-12 h-12 rounded-lg bg-gray-700 flex items-center justify-center">
          {pass.Image ? (
            <img src={pass.Image} alt={pass.Name} className="w-full h-full object-cover rounded-lg" />
          ) : (
            <Tv className="w-6 h-6 text-gray-500" />
          )}
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <h3 className="font-semibold text-white truncate">{pass.Name}</h3>
            {pass.Paused && (
              <span className="px-2 py-0.5 text-xs rounded bg-gray-600 text-gray-300">Paused</span>
            )}
          </div>

          <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-400">
            {/* Keep */}
            <span className="flex items-center gap-1">
              <Video className="w-3 h-3" />
              {formatKeep(pass)}
            </span>
            {/* Recordings count */}
            <span>{pass.NumJobs} recording{pass.NumJobs !== 1 ? 's' : ''}</span>
            {/* Padding */}
            {(pass.PaddingStart > 0 || pass.PaddingEnd > 0) && (
              <span>+{formatPadding(pass.PaddingStart)} / +{formatPadding(pass.PaddingEnd)}</span>
            )}
            {/* Condition badges */}
            {(pass.EQ as Record<string, unknown> | undefined)?.Tags === 'New' && (
              <span className="text-green-400">New only</span>
            )}
            {(pass.NE as Record<string, unknown> | undefined)?.EpisodeNumber === 0 && (
              <span className="text-yellow-400">No specials</span>
            )}
            {/* Rerecord */}
            {pass.Rerecord && <span className="text-indigo-400">Re-record</span>}
          </div>
        </div>

        {/* Actions */}
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
            onClick={onTest}
            className="p-2 text-gray-400 hover:text-green-400 hover:bg-gray-700 rounded-lg transition-colors"
            title="Test — see upcoming airings"
          >
            <FlaskConical className="w-4 h-4" />
          </button>
          <button
            onClick={onEdit}
            className="p-2 text-gray-400 hover:text-indigo-400 hover:bg-gray-700 rounded-lg transition-colors"
            title="Edit"
          >
            <Edit2 className="w-4 h-4" />
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

// ---------- Main Page ----------
export function PassManagementPage() {
  const queryClient = useQueryClient()
  const [searchQuery, setSearchQuery] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editPass, setEditPass] = useState<DVRPass | null>(null)
  const [testPass, setTestPass] = useState<DVRPass | null>(null)
  const [filterState, setFilterState] = useState<'all' | 'active' | 'paused'>('all')

  const { data: allPasses, isLoading } = useQuery({
    queryKey: ['dvrPasses'],
    queryFn: () => api.getDVRPasses(),
  })

  const seriesPasses = useMemo(
    () => (allPasses ?? []).filter((p) => p.Type === 'series'),
    [allPasses]
  )

  // Build condition maps from form toggles
  const buildConditions = (v: PassFormValues) => {
    const eq: Record<string, unknown> = { Title: v.Name }
    if (v.NewOnly) eq.Tags = 'New'
    const ne: Record<string, unknown> | undefined = v.ExcludeSpecials ? { EpisodeNumber: 0 } : undefined
    return { EQ: eq, NE: ne }
  }

  // Derive form values from an existing pass's condition maps
  const passToFormValues = (pass: DVRPass): Partial<PassFormValues> => {
    const eq = (pass.EQ ?? {}) as Record<string, unknown>
    const ne = (pass.NE ?? {}) as Record<string, unknown>
    return {
      Name: pass.Name,
      KeepOnly: pass.KeepOnly,
      KeepNum: pass.KeepNum,
      PaddingStart: Math.round(pass.PaddingStart / 60),
      PaddingEnd: Math.round(pass.PaddingEnd / 60),
      Rerecord: pass.Rerecord,
      NewOnly: eq.Tags === 'New',
      ExcludeSpecials: ne.EpisodeNumber === 0,
    }
  }

  const createMutation = useMutation({
    mutationFn: (v: PassFormValues) => {
      const { EQ, NE } = buildConditions(v)
      return api.createDVRPass({
        Type: 'series',
        Name: v.Name,
        KeepOnly: v.KeepOnly,
        KeepNum: v.KeepNum,
        PaddingStart: v.PaddingStart * 60,  // minutes → seconds
        PaddingEnd: v.PaddingEnd * 60,
        Rerecord: v.Rerecord,
        EQ,
        NE,
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dvrPasses'] })
      setShowForm(false)
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, v }: { id: number; v: PassFormValues }) => {
      const { EQ, NE } = buildConditions(v)
      return api.updateDVRPass(id, {
        Type: 'series',
        Name: v.Name,
        KeepOnly: v.KeepOnly,
        KeepNum: v.KeepNum,
        PaddingStart: v.PaddingStart * 60,
        PaddingEnd: v.PaddingEnd * 60,
        Rerecord: v.Rerecord,
        EQ,
        NE,
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dvrPasses'] })
      setEditPass(null)
    },
  })

  const pauseMutation = useMutation({
    mutationFn: ({ id, type }: { id: number; type: string }) => api.pauseDVRPass(id, type),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['dvrPasses'] }),
  })

  const resumeMutation = useMutation({
    mutationFn: ({ id, type }: { id: number; type: string }) => api.resumeDVRPass(id, type),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['dvrPasses'] }),
  })

  const deleteMutation = useMutation({
    mutationFn: (id: number) => api.deleteSeriesRule(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['dvrPasses'] }),
  })

  const filtered = useMemo(() => {
    let result = seriesPasses
    if (filterState === 'active') result = result.filter((p) => !p.Paused)
    else if (filterState === 'paused') result = result.filter((p) => p.Paused)
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase()
      result = result.filter((p) => p.Name.toLowerCase().includes(q))
    }
    return result
  }, [seriesPasses, filterState, searchQuery])

  const handleSave = (v: PassFormValues) => {
    createMutation.mutate(v)
  }

  const handleUpdate = (v: PassFormValues) => {
    if (!editPass) return
    updateMutation.mutate({ id: editPass.ID, v })
  }

  const handleToggle = (pass: DVRPass) => {
    if (!pass.Paused) pauseMutation.mutate({ id: pass.ID, type: pass.Type })
    else resumeMutation.mutate({ id: pass.ID, type: pass.Type })
  }

  const handleDelete = (pass: DVRPass) => {
    if (!confirm(`Delete pass for "${pass.Name}"? This will not remove existing recordings.`)) return
    deleteMutation.mutate(pass.ID)
  }

  const activeCount = seriesPasses.filter((p) => !p.Paused).length
  const pausedCount = seriesPasses.filter((p) => p.Paused).length

  return (
    <div>
      {/* Header */}
      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Pass Management</h1>
          <p className="text-gray-400 mt-1">
            Automatic recording rules — set a pass and never miss an episode
          </p>
        </div>
        <button
          onClick={() => setShowForm(true)}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm font-medium"
        >
          <Plus className="w-4 h-4" />
          New Pass
        </button>
      </div>

      {/* Stats bar */}
      {!isLoading && (
        <div className="flex items-center gap-4 mb-5 text-sm">
          {[
            { id: 'all',    label: `All (${seriesPasses.length})` },
            { id: 'active', label: `Active (${activeCount})` },
            { id: 'paused', label: `Paused (${pausedCount})` },
          ].map((f) => (
            <button
              key={f.id}
              onClick={() => setFilterState(f.id as typeof filterState)}
              className={`px-3 py-1.5 rounded-lg transition-colors ${
                filterState === f.id
                  ? 'bg-indigo-600 text-white'
                  : 'text-gray-400 hover:text-white hover:bg-gray-700'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>
      )}

      {/* Search */}
      <div className="relative mb-5">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          placeholder="Search passes…"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-9 pr-4 py-2.5 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500 text-sm"
        />
        {searchQuery && (
          <button
            onClick={() => setSearchQuery('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* List */}
      {isLoading ? (
        <div className="flex items-center justify-center py-16">
          <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      ) : filtered.length > 0 ? (
        <div className="space-y-2">
          {filtered.map((pass) => (
            <PassCard
              key={pass.ID}
              pass={pass}
              onToggle={() => handleToggle(pass)}
              onDelete={() => handleDelete(pass)}
              onEdit={() => setEditPass(pass)}
              onTest={() => setTestPass(pass)}
              isToggling={pauseMutation.isPending || resumeMutation.isPending}
            />
          ))}
        </div>
      ) : searchQuery || filterState !== 'all' ? (
        <div className="text-center py-16 bg-gray-800 rounded-xl">
          <Search className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No matches</h3>
          <button
            onClick={() => { setSearchQuery(''); setFilterState('all') }}
            className="mt-2 text-sm text-indigo-400 hover:text-indigo-300"
          >
            Clear filters
          </button>
        </div>
      ) : (
        <div className="text-center py-16 bg-gray-800 rounded-xl">
          <ShieldCheck className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No recording passes yet</h3>
          <p className="text-gray-400 mb-4">
            Create a pass for any show and it will be recorded automatically
          </p>
          <button
            onClick={() => setShowForm(true)}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm"
          >
            Create your first pass
          </button>
        </div>
      )}

      {/* Create modal */}
      {showForm && (
        <PassFormModal
          onSave={handleSave}
          onClose={() => setShowForm(false)}
          isSaving={createMutation.isPending}
        />
      )}

      {/* Edit modal */}
      {editPass && (
        <PassFormModal
          initial={passToFormValues(editPass)}
          onSave={handleUpdate}
          onClose={() => setEditPass(null)}
          isSaving={updateMutation.isPending}
        />
      )}

      {/* Test modal */}
      {testPass && (
        <PassTestModal pass={testPass} onClose={() => setTestPass(null)} />
      )}
    </div>
  )
}
