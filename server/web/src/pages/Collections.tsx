import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  FolderOpen,
  Library,
  Plus,
  Trash2,
  Edit,
  Loader,
  X,
  Eye,
  Search,
  AlertCircle,
  Image,
  Hash,
  ChevronRight,
  ArrowLeft,
} from 'lucide-react'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface DVRCollection {
  id: number
  title: string
  description?: string
  thumb?: string
  smart: boolean
  smartRule?: string
  tmdbCollectionId?: number
  fileIds?: string
  groupIds?: string
  sort?: string
  order?: string
}

interface DVRFile {
  id: number
  title: string
  type?: string
  year?: number
  thumb?: string
  duration?: number
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

async function fetchCollections(): Promise<DVRCollection[]> {
  const res = await fetch('/dvr/v2/collections', { headers: authHeaders })
  if (!res.ok) throw new Error('Failed to fetch collections')
  const data = await res.json()
  return data.collections || []
}

async function createCollection(
  body: Partial<DVRCollection>,
): Promise<DVRCollection> {
  const res = await fetch('/dvr/v2/collections', {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to create collection')
  return res.json()
}

async function updateCollection(
  id: number,
  body: Partial<DVRCollection>,
): Promise<DVRCollection> {
  const res = await fetch(`/dvr/v2/collections/${id}`, {
    method: 'PUT',
    headers: authHeaders,
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to update collection')
  return res.json()
}

async function deleteCollection(id: number): Promise<void> {
  const res = await fetch(`/dvr/v2/collections/${id}`, {
    method: 'DELETE',
    headers: authHeaders,
  })
  if (!res.ok) throw new Error('Failed to delete collection')
}

async function fetchCollectionItems(id: number): Promise<DVRFile[]> {
  const res = await fetch(`/dvr/v2/collections/${id}/items`, {
    headers: authHeaders,
  })
  if (!res.ok) throw new Error('Failed to fetch items')
  const data = await res.json()
  return data.items || []
}

async function previewSmartRule(rule: string): Promise<DVRFile[]> {
  const res = await fetch('/dvr/v2/collections/preview', {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({ smartRule: rule }),
  })
  if (!res.ok) throw new Error('Failed to preview')
  const data = await res.json()
  return data.files || data.items || []
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
  return JSON.stringify(conditions.filter((c) => c.value.trim() !== ''))
}

function countFileIds(ids?: string): number {
  if (!ids) return 0
  return ids.split(',').filter(Boolean).length
}

// ---------------------------------------------------------------------------
// SmartRuleBuilder
// ---------------------------------------------------------------------------

function SmartRuleBuilder({
  conditions,
  onChange,
}: {
  conditions: SmartCondition[]
  onChange: (c: SmartCondition[]) => void
}) {
  const update = (idx: number, patch: Partial<SmartCondition>) => {
    onChange(conditions.map((c, i) => (i === idx ? { ...c, ...patch } : c)))
  }

  const add = () =>
    onChange([
      ...conditions,
      { field: 'title', operator: 'contains', value: '' },
    ])

  const remove = (idx: number) => {
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
            onChange={(e) => update(idx, { field: e.target.value })}
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
            onChange={(e) => update(idx, { operator: e.target.value })}
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
            onChange={(e) => update(idx, { value: e.target.value })}
            placeholder="Value"
            className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          />
          <button
            onClick={() => remove(idx)}
            disabled={conditions.length <= 1}
            className="p-2 text-gray-400 hover:text-red-400 disabled:opacity-30 rounded-lg hover:bg-gray-700 transition-colors"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ))}
      <button
        onClick={add}
        className="flex items-center gap-1 text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
      >
        <Plus className="w-3.5 h-3.5" />
        Add Condition
      </button>
    </div>
  )
}

// ---------------------------------------------------------------------------
// CollectionModal (Create / Edit)
// ---------------------------------------------------------------------------

function CollectionModal({
  collection,
  onClose,
}: {
  collection: DVRCollection | null
  onClose: () => void
}) {
  const queryClient = useQueryClient()
  const isEdit = !!collection

  const [title, setTitle] = useState(collection?.title || '')
  const [description, setDescription] = useState(collection?.description || '')
  const [thumb, setThumb] = useState(collection?.thumb || '')
  const [smart, setSmart] = useState(collection?.smart ?? true)
  const [conditions, setConditions] = useState<SmartCondition[]>(
    parseSmartRule(collection?.smartRule),
  )
  const [fileIds, setFileIds] = useState(collection?.fileIds || '')
  const [sort, setSort] = useState(collection?.sort || 'title')
  const [order, setOrder] = useState(collection?.order || 'asc')

  // Preview state
  const [previewFiles, setPreviewFiles] = useState<DVRFile[]>([])
  const [isPreviewing, setIsPreviewing] = useState(false)
  const [previewError, setPreviewError] = useState('')

  const createMut = useMutation({
    mutationFn: createCollection,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['collections'] })
      onClose()
    },
  })

  const updateMut = useMutation({
    mutationFn: (body: Partial<DVRCollection>) =>
      updateCollection(collection!.id, body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['collections'] })
      onClose()
    },
  })

  const saving = createMut.isPending || updateMut.isPending

  const handlePreview = async () => {
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
    const body: Partial<DVRCollection> = {
      title,
      description: description || undefined,
      thumb: thumb || undefined,
      smart,
      sort,
      order,
    }

    if (smart) {
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
            <Library className="w-5 h-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-white">
              {isEdit ? 'Edit Collection' : 'Create Collection'}
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
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Title
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
              placeholder="My Collection"
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

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Thumbnail URL
            </label>
            <input
              type="url"
              value={thumb}
              onChange={(e) => setThumb(e.target.value)}
              placeholder="https://..."
              className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
            />
          </div>

          {/* Smart / Manual toggle */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Content Source
            </label>
            <div className="flex gap-2 mb-4">
              <button
                type="button"
                onClick={() => setSmart(true)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  smart
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-700 text-gray-400 hover:text-white'
                }`}
              >
                Smart
              </button>
              <button
                type="button"
                onClick={() => setSmart(false)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  !smart
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-700 text-gray-400 hover:text-white'
                }`}
              >
                Manual
              </button>
            </div>

            {smart ? (
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
                  <div className="bg-gray-700/50 rounded-lg p-3 max-h-48 overflow-y-auto">
                    <p className="text-xs text-gray-400 mb-2">
                      {previewFiles.length} matched items
                    </p>
                    {previewFiles.map((f) => (
                      <div
                        key={f.id}
                        className="flex items-center gap-2 text-sm text-gray-300 py-1.5 border-b border-gray-700 last:border-0"
                      >
                        <span className="flex-1 truncate">{f.title}</span>
                        {f.year && (
                          <span className="text-xs text-gray-500">{f.year}</span>
                        )}
                        {f.type && (
                          <span className="text-xs px-1.5 py-0.5 bg-gray-600 text-gray-400 rounded">
                            {f.type}
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

          {/* Sorting */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs text-gray-400 mb-1">Sort By</label>
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
              <label className="block text-xs text-gray-400 mb-1">Order</label>
              <select
                value={order}
                onChange={(e) => setOrder(e.target.value)}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
              >
                <option value="asc">Ascending</option>
                <option value="desc">Descending</option>
              </select>
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
              disabled={saving || !title.trim()}
              className="flex-1 py-2.5 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
            >
              {saving ? (
                <Loader className="w-4 h-4 animate-spin mx-auto" />
              ) : isEdit ? (
                'Save Changes'
              ) : (
                'Create Collection'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// CollectionDetailView
// ---------------------------------------------------------------------------

function CollectionDetailView({
  collection,
  onBack,
}: {
  collection: DVRCollection
  onBack: () => void
}) {
  const {
    data: items,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['collection-items', collection.id],
    queryFn: () => fetchCollectionItems(collection.id),
  })

  return (
    <div>
      <button
        onClick={onBack}
        className="flex items-center gap-2 text-gray-400 hover:text-white mb-6 transition-colors"
      >
        <ArrowLeft className="w-4 h-4" />
        Back to Collections
      </button>

      <div className="mb-6">
        <div className="flex items-center gap-4">
          {collection.thumb ? (
            <img
              src={collection.thumb}
              alt={collection.title}
              className="w-20 h-20 rounded-xl object-cover"
            />
          ) : (
            <div className="w-20 h-20 bg-gray-800 rounded-xl flex items-center justify-center">
              <FolderOpen className="w-8 h-8 text-gray-600" />
            </div>
          )}
          <div>
            <h2 className="text-xl font-bold text-white">{collection.title}</h2>
            {collection.description && (
              <p className="text-gray-400 mt-1">{collection.description}</p>
            )}
            <div className="flex items-center gap-3 mt-2 text-sm text-gray-500">
              <span className={`px-2 py-0.5 rounded text-xs ${
                collection.smart
                  ? 'bg-purple-500/10 text-purple-400'
                  : 'bg-gray-700 text-gray-400'
              }`}>
                {collection.smart ? 'Smart' : 'Manual'}
              </span>
              {items && (
                <span>{items.length} items</span>
              )}
            </div>
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <AlertCircle className="w-10 h-10 text-red-400 mx-auto mb-3" />
          <p className="text-gray-400">Failed to load items</p>
        </div>
      ) : items && items.length > 0 ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
          {items.map((item) => (
            <div
              key={item.id}
              className="bg-gray-800 rounded-xl overflow-hidden border border-gray-700 hover:border-gray-600 transition-colors"
            >
              <div className="aspect-[2/3] bg-gray-700 relative">
                {item.thumb ? (
                  <img
                    src={item.thumb}
                    alt={item.title}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <Image className="w-8 h-8 text-gray-600" />
                  </div>
                )}
                {item.type && (
                  <span className="absolute top-2 right-2 px-1.5 py-0.5 bg-black/70 text-gray-300 text-xs rounded">
                    {item.type}
                  </span>
                )}
              </div>
              <div className="p-3">
                <h4 className="text-sm font-medium text-white truncate">
                  {item.title}
                </h4>
                {item.year && (
                  <p className="text-xs text-gray-500">{item.year}</p>
                )}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <FolderOpen className="w-10 h-10 text-gray-600 mx-auto mb-3" />
          <p className="text-gray-400">This collection is empty</p>
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// CollectionCard
// ---------------------------------------------------------------------------

function CollectionCard({
  collection,
  onEdit,
  onDelete,
  onView,
}: {
  collection: DVRCollection
  onEdit: () => void
  onDelete: () => void
  onView: () => void
}) {
  const itemCount = collection.smart
    ? null // smart collections don't have static count
    : countFileIds(collection.fileIds)

  return (
    <div
      className="bg-gray-800 rounded-xl overflow-hidden border border-gray-700 hover:border-gray-600 transition-colors group cursor-pointer"
      onClick={onView}
    >
      {/* Thumbnail */}
      <div className="aspect-video bg-gray-700 relative overflow-hidden">
        {collection.thumb ? (
          <img
            src={collection.thumb}
            alt={collection.title}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <FolderOpen className="w-12 h-12 text-gray-600" />
          </div>
        )}

        {/* Overlay badges */}
        <div className="absolute top-2 left-2">
          <span
            className={`px-2 py-0.5 rounded text-xs font-medium ${
              collection.smart
                ? 'bg-purple-500/80 text-white'
                : 'bg-gray-800/80 text-gray-300'
            }`}
          >
            {collection.smart ? 'Smart' : 'Manual'}
          </span>
        </div>

        {/* Actions overlay */}
        <div className="absolute top-2 right-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={(e) => {
              e.stopPropagation()
              onEdit()
            }}
            className="p-1.5 bg-gray-800/80 hover:bg-indigo-600 text-white rounded-lg transition-colors"
            title="Edit"
          >
            <Edit className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation()
              onDelete()
            }}
            className="p-1.5 bg-gray-800/80 hover:bg-red-600 text-white rounded-lg transition-colors"
            title="Delete"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      <div className="p-4">
        <h3 className="text-white font-semibold truncate">{collection.title}</h3>
        {collection.description && (
          <p className="text-sm text-gray-400 line-clamp-1 mt-0.5">
            {collection.description}
          </p>
        )}
        <div className="flex items-center justify-between mt-2">
          <div className="flex items-center gap-2 text-xs text-gray-500">
            {itemCount !== null && (
              <span className="flex items-center gap-1">
                <Hash className="w-3 h-3" />
                {itemCount} items
              </span>
            )}
            {collection.tmdbCollectionId && (
              <span className="px-1.5 py-0.5 bg-blue-500/10 text-blue-400 rounded">
                TMDB
              </span>
            )}
          </div>
          <ChevronRight className="w-4 h-4 text-gray-600 group-hover:text-gray-400 transition-colors" />
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// CollectionsPage (exported)
// ---------------------------------------------------------------------------

export function CollectionsPage() {
  const queryClient = useQueryClient()

  const {
    data: collections,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['collections'],
    queryFn: fetchCollections,
  })

  const deleteMut = useMutation({
    mutationFn: deleteCollection,
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['collections'] }),
  })

  const [modalCollection, setModalCollection] = useState<
    DVRCollection | null | 'new'
  >(null)
  const [viewingCollection, setViewingCollection] = useState<DVRCollection | null>(
    null,
  )
  const [searchQuery, setSearchQuery] = useState('')

  const filtered = (collections || []).filter((c) => {
    if (!searchQuery.trim()) return true
    const q = searchQuery.toLowerCase()
    return (
      c.title.toLowerCase().includes(q) ||
      c.description?.toLowerCase().includes(q)
    )
  })

  const handleDelete = (id: number) => {
    if (confirm('Delete this collection? This cannot be undone.')) {
      deleteMut.mutate(id)
    }
  }

  // Detail view
  if (viewingCollection) {
    return (
      <CollectionDetailView
        collection={viewingCollection}
        onBack={() => setViewingCollection(null)}
      />
    )
  }

  return (
    <div>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Collections</h1>
          <p className="text-gray-400 mt-1">
            Organize your media into smart playlists and curated collections
          </p>
        </div>
        <button
          onClick={() => setModalCollection('new')}
          className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
        >
          <Plus className="w-4 h-4" />
          New Collection
        </button>
      </div>

      {/* Search */}
      {(collections?.length || 0) > 3 && (
        <div className="relative mb-6">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search collections..."
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
            Failed to load collections
          </h3>
          <p className="text-gray-400 text-sm">
            {error instanceof Error ? error.message : 'Unknown error'}
          </p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 bg-gray-800 rounded-xl">
          <FolderOpen className="w-12 h-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">
            {searchQuery ? 'No matching collections' : 'No collections yet'}
          </h3>
          <p className="text-gray-400 mb-6">
            {searchQuery
              ? `No collections match "${searchQuery}"`
              : 'Create smart playlists or curate collections from your library.'}
          </p>
          {!searchQuery && (
            <button
              onClick={() => setModalCollection('new')}
              className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
            >
              <Plus className="w-4 h-4" />
              New Collection
            </button>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {filtered.map((col) => (
            <CollectionCard
              key={col.id}
              collection={col}
              onEdit={() => setModalCollection(col)}
              onDelete={() => handleDelete(col.id)}
              onView={() => setViewingCollection(col)}
            />
          ))}
        </div>
      )}

      {/* Modal */}
      {modalCollection !== null && (
        <CollectionModal
          collection={modalCollection === 'new' ? null : modalCollection}
          onClose={() => setModalCollection(null)}
        />
      )}
    </div>
  )
}
