import { useState, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  LayoutList,
  Plus,
  Trash2,
  Edit,
  Loader,
  X,
  Search,
  GripVertical,
  Film,
  Tv,
  Clock,
  Wand2,
  FolderPlus,
  ChevronDown,
  Info,
  Eye,
} from 'lucide-react'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface PersonalSection {
  id: number
  userId: number
  name: string
  description: string
  sectionType: string // "smart" | "manual"
  smartFilter: string
  position: number
  itemCount: number
  createdAt: string
  updatedAt: string
}

interface SectionItem {
  id: number
  mediaId: number
  position: number
  title: string
  type: string
  year?: number
  thumb?: string
  duration?: number
  summary?: string
}

interface SectionDetail {
  section: PersonalSection
  items: SectionItem[]
}

interface SmartFilterCriteria {
  contentType: string
  genre: string
  yearFrom: number
  yearTo: number
  minRating: number
  maxRating: number
  watchedState: string
  sortBy: string
  sortDir: string
}

// ---------------------------------------------------------------------------
// API helpers
// ---------------------------------------------------------------------------

const getAuthHeaders = (): Record<string, string> => ({
  'X-Plex-Token': localStorage.getItem('openflix_token') || '',
  'Content-Type': 'application/json',
})

async function fetchSections(): Promise<PersonalSection[]> {
  const res = await fetch('/api/sections', { headers: getAuthHeaders() })
  if (!res.ok) throw new Error('Failed to fetch sections')
  const data = await res.json()
  return data.sections || []
}

async function fetchSection(id: number): Promise<SectionDetail> {
  const res = await fetch(`/api/sections/${id}`, { headers: getAuthHeaders() })
  if (!res.ok) throw new Error('Failed to fetch section')
  return res.json()
}

async function createSection(body: {
  name: string
  description: string
  sectionType: string
  smartFilter?: string
}): Promise<PersonalSection> {
  const res = await fetch('/api/sections', {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to create section')
  return res.json()
}

async function updateSection(
  id: number,
  body: { name?: string; description?: string; smartFilter?: string }
): Promise<PersonalSection> {
  const res = await fetch(`/api/sections/${id}`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error('Failed to update section')
  return res.json()
}

async function deleteSection(id: number): Promise<void> {
  const res = await fetch(`/api/sections/${id}`, {
    method: 'DELETE',
    headers: getAuthHeaders(),
  })
  if (!res.ok) throw new Error('Failed to delete section')
}

async function removeSectionItem(sectionId: number, itemId: number): Promise<void> {
  const res = await fetch(`/api/sections/${sectionId}/items/${itemId}`, {
    method: 'DELETE',
    headers: getAuthHeaders(),
  })
  if (!res.ok) throw new Error('Failed to remove item')
}

async function reorderSectionItems(sectionId: number, itemIds: number[]): Promise<void> {
  const res = await fetch(`/api/sections/${sectionId}/reorder`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify({ itemIds }),
  })
  if (!res.ok) throw new Error('Failed to reorder items')
}

async function addItemsToSection(sectionId: number, mediaIds: number[]): Promise<void> {
  const res = await fetch(`/api/sections/${sectionId}/items`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ mediaIds }),
  })
  if (!res.ok) throw new Error('Failed to add items')
}

async function previewSmartFilter(smartFilter: string): Promise<SectionItem[]> {
  const res = await fetch('/api/sections/preview', {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ smartFilter, limit: 50 }),
  })
  if (!res.ok) return []
  const data = await res.json()
  return (data.items || []).map((item: Record<string, unknown>) => ({
    id: (item.id || 0) as number,
    mediaId: (item.id || 0) as number,
    position: 0,
    title: (item.title || '') as string,
    type: (item.type || '') as string,
    year: (item.year || 0) as number,
    thumb: (item.thumb || '') as string,
    duration: (item.duration || 0) as number,
  }))
}

async function fetchGenres(): Promise<string[]> {
  const res = await fetch('/api/sections/genres', { headers: getAuthHeaders() })
  if (!res.ok) return []
  const data = await res.json()
  return data.genres || []
}

async function searchMedia(query: string): Promise<SectionItem[]> {
  const res = await fetch(`/api/search?query=${encodeURIComponent(query)}&limit=20`, {
    headers: getAuthHeaders(),
  })
  if (!res.ok) return []
  const data = await res.json()
  const results = data.results || data.items || []
  return results.map((r: Record<string, unknown>) => ({
    id: 0,
    mediaId: (r.ratingKey || r.id || r.mediaId) as number,
    position: 0,
    title: (r.title || '') as string,
    type: (r.type || '') as string,
    year: (r.year || 0) as number,
    thumb: (r.thumb || '') as string,
    duration: (r.duration || 0) as number,
  }))
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function formatDuration(ms: number): string {
  if (!ms) return ''
  const minutes = Math.floor(ms / 60000)
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0) return `${hours}h ${mins}m`
  return `${mins}m`
}

function getTypeIcon(type: string) {
  switch (type) {
    case 'movie':
      return <Film className="h-4 w-4 text-blue-400" />
    case 'show':
    case 'episode':
      return <Tv className="h-4 w-4 text-green-400" />
    default:
      return <Film className="h-4 w-4 text-gray-400" />
  }
}

function defaultSmartFilter(): SmartFilterCriteria {
  return {
    contentType: 'movie',
    genre: '',
    yearFrom: 0,
    yearTo: 0,
    minRating: 0,
    maxRating: 0,
    watchedState: 'any',
    sortBy: 'title',
    sortDir: 'asc',
  }
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function PersonalSectionsPage() {
  const queryClient = useQueryClient()
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [showCreateDropdown, setShowCreateDropdown] = useState(false)
  const [showCreateDialog, setShowCreateDialog] = useState<'manual' | 'smart' | null>(null)
  const [editingSection, setEditingSection] = useState<PersonalSection | null>(null)
  const [showAddItems, setShowAddItems] = useState(false)
  const [addSearchQuery, setAddSearchQuery] = useState('')
  const [dragIndex, setDragIndex] = useState<number | null>(null)

  // Queries
  const { data: sections = [], isLoading } = useQuery({
    queryKey: ['personal-sections'],
    queryFn: fetchSections,
  })

  const { data: sectionDetail, isLoading: isLoadingDetail } = useQuery({
    queryKey: ['personal-section', selectedId],
    queryFn: () => fetchSection(selectedId!),
    enabled: !!selectedId,
  })

  const { data: genres = [] } = useQuery({
    queryKey: ['available-genres'],
    queryFn: fetchGenres,
  })

  const { data: addSearchResults = [] } = useQuery({
    queryKey: ['section-media-search', addSearchQuery],
    queryFn: () => searchMedia(addSearchQuery),
    enabled: showAddItems && addSearchQuery.length >= 2,
  })

  // Mutations
  const createMutation = useMutation({
    mutationFn: createSection,
    onSuccess: (newSection) => {
      queryClient.invalidateQueries({ queryKey: ['personal-sections'] })
      setShowCreateDialog(null)
      setSelectedId(newSection.id)
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: { name?: string; description?: string; smartFilter?: string } }) =>
      updateSection(id, body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['personal-sections'] })
      queryClient.invalidateQueries({ queryKey: ['personal-section', selectedId] })
      setEditingSection(null)
    },
  })

  const deleteMutation = useMutation({
    mutationFn: deleteSection,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['personal-sections'] })
      setSelectedId(null)
    },
  })

  const removeItemMutation = useMutation({
    mutationFn: ({ sectionId, itemId }: { sectionId: number; itemId: number }) =>
      removeSectionItem(sectionId, itemId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['personal-section', selectedId] })
      queryClient.invalidateQueries({ queryKey: ['personal-sections'] })
    },
  })

  const reorderMutation = useMutation({
    mutationFn: ({ sectionId, itemIds }: { sectionId: number; itemIds: number[] }) =>
      reorderSectionItems(sectionId, itemIds),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['personal-section', selectedId] })
    },
  })

  const addItemsMutation = useMutation({
    mutationFn: ({ sectionId, mediaIds }: { sectionId: number; mediaIds: number[] }) =>
      addItemsToSection(sectionId, mediaIds),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['personal-section', selectedId] })
      queryClient.invalidateQueries({ queryKey: ['personal-sections'] })
      setShowAddItems(false)
      setAddSearchQuery('')
    },
  })

  // Drag and drop
  const handleDragStart = useCallback((index: number) => {
    setDragIndex(index)
  }, [])

  const handleDragOver = useCallback(
    (e: React.DragEvent, _index: number) => {
      e.preventDefault()
    },
    []
  )

  const handleDrop = useCallback(
    (index: number) => {
      if (dragIndex === null || !sectionDetail?.items) return
      const items = [...sectionDetail.items]
      const [moved] = items.splice(dragIndex, 1)
      items.splice(index, 0, moved)
      const itemIds = items.map((it) => it.id)
      reorderMutation.mutate({ sectionId: selectedId!, itemIds })
      setDragIndex(null)
    },
    [dragIndex, sectionDetail, selectedId, reorderMutation]
  )

  const filteredSections = sections.filter((s) =>
    s.name.toLowerCase().includes(searchQuery.toLowerCase())
  )

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader className="h-8 w-8 animate-spin text-indigo-500" />
      </div>
    )
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-white">Personal Sections</h1>
        <p className="text-sm text-gray-400 mt-1">
          Curate your own personal sections for OpenFlix.
        </p>
      </div>

      {/* Info banner */}
      <div className="mb-6 flex items-start gap-3 p-4 bg-blue-900/20 border border-blue-800/50 rounded-lg">
        <Info className="h-5 w-5 text-blue-400 flex-shrink-0 mt-0.5" />
        <p className="text-sm text-blue-300">
          Apply your Personal Sections to your client's sidebar navigation in the Client Settings section.
        </p>
      </div>

      <div className="flex gap-6 h-[calc(100vh-260px)]">
        {/* Left panel - Section list */}
        <div className="w-80 flex-shrink-0 bg-gray-800 rounded-lg border border-gray-700 flex flex-col">
          {/* Search and create */}
          <div className="p-3 border-b border-gray-700 space-y-2">
            <div className="flex gap-2">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search sections..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div className="relative">
                <button
                  onClick={() => setShowCreateDropdown(!showCreateDropdown)}
                  className="p-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors flex items-center gap-1"
                  title="Create section"
                >
                  <Plus className="h-4 w-4" />
                  <ChevronDown className="h-3 w-3" />
                </button>
                {showCreateDropdown && (
                  <>
                    <div className="fixed inset-0 z-10" onClick={() => setShowCreateDropdown(false)} />
                    <div className="absolute right-0 top-full mt-1 z-20 w-52 bg-gray-700 rounded-lg shadow-xl border border-gray-600 py-1">
                      <button
                        onClick={() => {
                          setShowCreateDropdown(false)
                          setShowCreateDialog('smart')
                        }}
                        className="w-full flex items-center gap-2 px-4 py-2 text-sm text-white hover:bg-gray-600 transition-colors"
                      >
                        <Wand2 className="h-4 w-4 text-purple-400" />
                        Add Smart Section
                      </button>
                      <button
                        onClick={() => {
                          setShowCreateDropdown(false)
                          setShowCreateDialog('manual')
                        }}
                        className="w-full flex items-center gap-2 px-4 py-2 text-sm text-white hover:bg-gray-600 transition-colors"
                      >
                        <FolderPlus className="h-4 w-4 text-blue-400" />
                        Add Manual Section
                      </button>
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>

          {/* Section list */}
          <div className="flex-1 overflow-y-auto">
            {filteredSections.map((section) => (
              <button
                key={section.id}
                onClick={() => setSelectedId(section.id)}
                className={`w-full text-left px-4 py-3 border-b border-gray-700/50 transition-colors ${
                  selectedId === section.id
                    ? 'bg-indigo-600/20 border-l-2 border-l-indigo-500'
                    : 'hover:bg-gray-700/50'
                }`}
              >
                <div className="flex items-center gap-2">
                  {section.sectionType === 'smart' ? (
                    <Wand2 className="h-3.5 w-3.5 text-purple-400 flex-shrink-0" />
                  ) : (
                    <LayoutList className="h-3.5 w-3.5 text-blue-400 flex-shrink-0" />
                  )}
                  <span className="font-medium text-white text-sm truncate">{section.name}</span>
                </div>
                <div className="text-xs text-gray-400 mt-1 ml-5.5">
                  {section.sectionType === 'smart' ? 'Smart' : 'Manual'} - {section.itemCount}{' '}
                  {section.itemCount === 1 ? 'item' : 'items'}
                </div>
              </button>
            ))}
            {filteredSections.length === 0 && (
              <div className="p-4 text-center text-gray-500 text-sm">
                {searchQuery
                  ? 'No sections match your search'
                  : 'No personal sections yet. Click + to create one.'}
              </div>
            )}
          </div>
        </div>

        {/* Right panel - Section detail */}
        <div className="flex-1 bg-gray-800 rounded-lg border border-gray-700 flex flex-col overflow-hidden">
          {!selectedId ? (
            <div className="flex-1 flex items-center justify-center text-gray-500">
              <div className="text-center">
                <LayoutList className="h-12 w-12 mx-auto mb-3 text-gray-600" />
                <p className="text-sm">Select a section to view its contents</p>
              </div>
            </div>
          ) : isLoadingDetail ? (
            <div className="flex-1 flex items-center justify-center">
              <Loader className="h-6 w-6 animate-spin text-indigo-500" />
            </div>
          ) : sectionDetail ? (
            <>
              {/* Section header */}
              <div className="p-4 border-b border-gray-700 flex items-start justify-between">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    {sectionDetail.section.sectionType === 'smart' ? (
                      <Wand2 className="h-4 w-4 text-purple-400" />
                    ) : (
                      <LayoutList className="h-4 w-4 text-blue-400" />
                    )}
                    <h2 className="text-lg font-semibold text-white truncate">
                      {sectionDetail.section.name}
                    </h2>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-gray-700 text-gray-300">
                      {sectionDetail.section.sectionType}
                    </span>
                  </div>
                  {sectionDetail.section.description && (
                    <p className="text-sm text-gray-400 mt-1">{sectionDetail.section.description}</p>
                  )}
                  <p className="text-xs text-gray-500 mt-1">
                    {sectionDetail.items.length} {sectionDetail.items.length === 1 ? 'item' : 'items'}
                  </p>
                </div>
                <div className="flex gap-2 ml-4">
                  {sectionDetail.section.sectionType === 'manual' && (
                    <button
                      onClick={() => setShowAddItems(true)}
                      className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors flex items-center gap-1"
                    >
                      <Plus className="h-3.5 w-3.5" />
                      Add Items
                    </button>
                  )}
                  <button
                    onClick={() => setEditingSection(sectionDetail.section)}
                    className="p-1.5 text-gray-400 hover:text-white transition-colors"
                    title="Edit section"
                  >
                    <Edit className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => {
                      if (confirm('Delete this section?')) {
                        deleteMutation.mutate(selectedId)
                      }
                    }}
                    className="p-1.5 text-gray-400 hover:text-red-400 transition-colors"
                    title="Delete section"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Items list */}
              <div className="flex-1 overflow-y-auto">
                {sectionDetail.items.length === 0 ? (
                  <div className="p-8 text-center text-gray-500">
                    <p className="text-sm">
                      {sectionDetail.section.sectionType === 'smart'
                        ? 'No items match the current filter criteria.'
                        : 'This section is empty.'}
                    </p>
                    {sectionDetail.section.sectionType === 'manual' && (
                      <button
                        onClick={() => setShowAddItems(true)}
                        className="mt-3 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors"
                      >
                        Add Items
                      </button>
                    )}
                  </div>
                ) : (
                  <div>
                    {sectionDetail.items.map((item, index) => (
                      <div
                        key={`${item.id}-${item.mediaId}`}
                        draggable={sectionDetail.section.sectionType === 'manual'}
                        onDragStart={() => handleDragStart(index)}
                        onDragOver={(e) => handleDragOver(e, index)}
                        onDrop={() => handleDrop(index)}
                        className={`flex items-center gap-3 px-4 py-3 border-b border-gray-700/30 hover:bg-gray-700/30 transition-colors group ${
                          sectionDetail.section.sectionType === 'manual'
                            ? 'cursor-grab active:cursor-grabbing'
                            : ''
                        }`}
                      >
                        {sectionDetail.section.sectionType === 'manual' && (
                          <GripVertical className="h-4 w-4 text-gray-600 group-hover:text-gray-400 flex-shrink-0" />
                        )}
                        <span className="text-xs text-gray-500 w-6 text-right flex-shrink-0">
                          {index + 1}
                        </span>
                        {item.thumb ? (
                          <img
                            src={item.thumb}
                            alt=""
                            className="h-10 w-16 object-cover rounded flex-shrink-0 bg-gray-700"
                          />
                        ) : (
                          <div className="h-10 w-16 bg-gray-700 rounded flex items-center justify-center flex-shrink-0">
                            {getTypeIcon(item.type)}
                          </div>
                        )}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            {getTypeIcon(item.type)}
                            <span className="text-sm text-white truncate">{item.title}</span>
                          </div>
                          <div className="flex items-center gap-2 text-xs text-gray-500 mt-0.5">
                            {(item.year ?? 0) > 0 && <span>{item.year}</span>}
                            {(item.duration ?? 0) > 0 && (
                              <>
                                <Clock className="h-3 w-3" />
                                <span>{formatDuration(item.duration ?? 0)}</span>
                              </>
                            )}
                          </div>
                        </div>
                        {sectionDetail.section.sectionType === 'manual' && (
                          <button
                            onClick={() =>
                              removeItemMutation.mutate({ sectionId: selectedId, itemId: item.id })
                            }
                            className="p-1 text-gray-600 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-all"
                            title="Remove from section"
                          >
                            <X className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </>
          ) : null}
        </div>
      </div>

      {/* Create Section Dialog */}
      {showCreateDialog && (
        <CreateSectionDialog
          type={showCreateDialog}
          genres={genres}
          onSave={(body) => createMutation.mutate(body)}
          onClose={() => setShowCreateDialog(null)}
          saving={createMutation.isPending}
        />
      )}

      {/* Edit Section Dialog */}
      {editingSection && (
        <EditSectionDialog
          section={editingSection}
          genres={genres}
          onSave={(body) => updateMutation.mutate({ id: editingSection.id, body })}
          onClose={() => setEditingSection(null)}
          saving={updateMutation.isPending}
        />
      )}

      {/* Add Items Dialog (manual sections only) */}
      {showAddItems && selectedId && (
        <AddItemsDialog
          searchQuery={addSearchQuery}
          onSearchChange={setAddSearchQuery}
          searchResults={addSearchResults}
          onAdd={(mediaIds) => addItemsMutation.mutate({ sectionId: selectedId, mediaIds })}
          onClose={() => {
            setShowAddItems(false)
            setAddSearchQuery('')
          }}
          adding={addItemsMutation.isPending}
        />
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Create Section Dialog
// ---------------------------------------------------------------------------

function CreateSectionDialog({
  type,
  genres,
  onSave,
  onClose,
  saving,
}: {
  type: 'smart' | 'manual'
  genres: string[]
  onSave: (body: { name: string; description: string; sectionType: string; smartFilter?: string }) => void
  onClose: () => void
  saving: boolean
}) {
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [filter, setFilter] = useState<SmartFilterCriteria>(defaultSmartFilter())
  const [previewItems, setPreviewItems] = useState<SectionItem[]>([])
  const [previewing, setPreviewing] = useState(false)

  const handlePreview = async () => {
    setPreviewing(true)
    try {
      const items = await previewSmartFilter(JSON.stringify(filter))
      setPreviewItems(items)
    } finally {
      setPreviewing(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl border border-gray-700 w-full max-w-2xl p-6 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            {type === 'smart' ? (
              <Wand2 className="h-5 w-5 text-purple-400" />
            ) : (
              <FolderPlus className="h-5 w-5 text-blue-400" />
            )}
            <h3 className="text-lg font-semibold text-white">
              {type === 'smart' ? 'Create Smart Section' : 'Create Manual Section'}
            </h3>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="My Section"
              className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
              autoFocus
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">Description</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Optional description..."
              rows={2}
              className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none resize-none"
            />
          </div>

          {/* Smart filter builder */}
          {type === 'smart' && (
            <SmartFilterBuilder filter={filter} onChange={setFilter} genres={genres} />
          )}

          {/* Preview for smart sections */}
          {type === 'smart' && (
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-sm font-medium text-gray-300">Preview</label>
                <button
                  onClick={handlePreview}
                  disabled={previewing}
                  className="px-3 py-1 bg-gray-700 hover:bg-gray-600 text-white text-xs rounded-lg transition-colors flex items-center gap-1"
                >
                  {previewing ? (
                    <Loader className="h-3 w-3 animate-spin" />
                  ) : (
                    <Eye className="h-3 w-3" />
                  )}
                  Preview Results
                </button>
              </div>
              {previewItems.length > 0 && (
                <div className="border border-gray-700 rounded-lg max-h-48 overflow-y-auto">
                  {previewItems.map((item) => (
                    <div
                      key={item.mediaId}
                      className="flex items-center gap-2 px-3 py-2 border-b border-gray-700/30 text-sm"
                    >
                      {getTypeIcon(item.type)}
                      <span className="text-white truncate">{item.title}</span>
                      {(item.year ?? 0) > 0 && <span className="text-gray-500 text-xs">({item.year})</span>}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="flex justify-end gap-3 mt-6">
          <button onClick={onClose} className="px-4 py-2 text-gray-300 hover:text-white transition-colors">
            Cancel
          </button>
          <button
            onClick={() =>
              onSave({
                name,
                description,
                sectionType: type,
                smartFilter: type === 'smart' ? JSON.stringify(filter) : undefined,
              })
            }
            disabled={!name.trim() || saving}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {saving && <Loader className="h-4 w-4 animate-spin" />}
            Create Section
          </button>
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Edit Section Dialog
// ---------------------------------------------------------------------------

function EditSectionDialog({
  section,
  genres,
  onSave,
  onClose,
  saving,
}: {
  section: PersonalSection
  genres: string[]
  onSave: (body: { name?: string; description?: string; smartFilter?: string }) => void
  onClose: () => void
  saving: boolean
}) {
  const [name, setName] = useState(section.name)
  const [description, setDescription] = useState(section.description || '')
  const [filter, setFilter] = useState<SmartFilterCriteria>(() => {
    if (section.sectionType === 'smart' && section.smartFilter) {
      try {
        return JSON.parse(section.smartFilter) as SmartFilterCriteria
      } catch {
        return defaultSmartFilter()
      }
    }
    return defaultSmartFilter()
  })

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl border border-gray-700 w-full max-w-2xl p-6 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-white">Edit Section</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
              autoFocus
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">Description</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none resize-none"
            />
          </div>

          {section.sectionType === 'smart' && (
            <SmartFilterBuilder filter={filter} onChange={setFilter} genres={genres} />
          )}
        </div>

        <div className="flex justify-end gap-3 mt-6">
          <button onClick={onClose} className="px-4 py-2 text-gray-300 hover:text-white transition-colors">
            Cancel
          </button>
          <button
            onClick={() =>
              onSave({
                name,
                description,
                smartFilter: section.sectionType === 'smart' ? JSON.stringify(filter) : undefined,
              })
            }
            disabled={!name.trim() || saving}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {saving && <Loader className="h-4 w-4 animate-spin" />}
            Save
          </button>
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Smart Filter Builder
// ---------------------------------------------------------------------------

function SmartFilterBuilder({
  filter,
  onChange,
  genres,
}: {
  filter: SmartFilterCriteria
  onChange: (f: SmartFilterCriteria) => void
  genres: string[]
}) {
  const update = (key: keyof SmartFilterCriteria, value: string | number) => {
    onChange({ ...filter, [key]: value })
  }

  return (
    <div className="space-y-3 p-4 bg-gray-900/50 rounded-lg border border-gray-700">
      <h4 className="text-sm font-medium text-gray-300 mb-2">Filter Criteria</h4>

      <div className="grid grid-cols-2 gap-3">
        {/* Content Type */}
        <div>
          <label className="block text-xs text-gray-400 mb-1">Content Type</label>
          <select
            value={filter.contentType}
            onChange={(e) => update('contentType', e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
          >
            <option value="movie">Movies</option>
            <option value="show">Shows</option>
            <option value="movie,show">Movies & Shows</option>
            <option value="episode">Episodes</option>
          </select>
        </div>

        {/* Genre */}
        <div>
          <label className="block text-xs text-gray-400 mb-1">Genre</label>
          <select
            value={filter.genre}
            onChange={(e) => update('genre', e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
          >
            <option value="">Any Genre</option>
            {genres.map((g) => (
              <option key={g} value={g}>
                {g}
              </option>
            ))}
          </select>
        </div>

        {/* Year From */}
        <div>
          <label className="block text-xs text-gray-400 mb-1">Year From</label>
          <input
            type="number"
            value={filter.yearFrom || ''}
            onChange={(e) => update('yearFrom', parseInt(e.target.value) || 0)}
            placeholder="Any"
            className="w-full px-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
          />
        </div>

        {/* Year To */}
        <div>
          <label className="block text-xs text-gray-400 mb-1">Year To</label>
          <input
            type="number"
            value={filter.yearTo || ''}
            onChange={(e) => update('yearTo', parseInt(e.target.value) || 0)}
            placeholder="Any"
            className="w-full px-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
          />
        </div>

        {/* Min Rating */}
        <div>
          <label className="block text-xs text-gray-400 mb-1">Min Rating</label>
          <input
            type="number"
            step="0.1"
            min="0"
            max="10"
            value={filter.minRating || ''}
            onChange={(e) => update('minRating', parseFloat(e.target.value) || 0)}
            placeholder="Any"
            className="w-full px-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
          />
        </div>

        {/* Max Rating */}
        <div>
          <label className="block text-xs text-gray-400 mb-1">Max Rating</label>
          <input
            type="number"
            step="0.1"
            min="0"
            max="10"
            value={filter.maxRating || ''}
            onChange={(e) => update('maxRating', parseFloat(e.target.value) || 0)}
            placeholder="Any"
            className="w-full px-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
          />
        </div>

        {/* Sort By */}
        <div>
          <label className="block text-xs text-gray-400 mb-1">Sort By</label>
          <select
            value={filter.sortBy}
            onChange={(e) => update('sortBy', e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
          >
            <option value="title">Title</option>
            <option value="year">Year</option>
            <option value="rating">Rating</option>
            <option value="addedAt">Date Added</option>
          </select>
        </div>

        {/* Sort Direction */}
        <div>
          <label className="block text-xs text-gray-400 mb-1">Sort Direction</label>
          <select
            value={filter.sortDir}
            onChange={(e) => update('sortDir', e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 text-white text-sm rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
          >
            <option value="asc">Ascending</option>
            <option value="desc">Descending</option>
          </select>
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Add Items Dialog (same as Playlists)
// ---------------------------------------------------------------------------

function AddItemsDialog({
  searchQuery,
  onSearchChange,
  searchResults,
  onAdd,
  onClose,
  adding,
}: {
  searchQuery: string
  onSearchChange: (q: string) => void
  searchResults: SectionItem[]
  onAdd: (mediaIds: number[]) => void
  onClose: () => void
  adding: boolean
}) {
  const [selected, setSelected] = useState<Set<number>>(new Set())

  const toggleItem = (mediaId: number) => {
    const next = new Set(selected)
    if (next.has(mediaId)) {
      next.delete(mediaId)
    } else {
      next.add(mediaId)
    }
    setSelected(next)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-gray-800 rounded-xl border border-gray-700 w-full max-w-lg p-6 max-h-[80vh] flex flex-col">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-white">Add Items to Section</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Search your library..."
            className="w-full pl-9 pr-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-indigo-500 focus:outline-none"
            autoFocus
          />
        </div>

        <div className="flex-1 overflow-y-auto min-h-0 border border-gray-700 rounded-lg">
          {searchQuery.length < 2 ? (
            <div className="p-8 text-center text-gray-500 text-sm">
              Type at least 2 characters to search
            </div>
          ) : searchResults.length === 0 ? (
            <div className="p-8 text-center text-gray-500 text-sm">No results found</div>
          ) : (
            searchResults.map((item) => (
              <button
                key={item.mediaId}
                onClick={() => toggleItem(item.mediaId)}
                className={`w-full flex items-center gap-3 px-4 py-3 border-b border-gray-700/30 transition-colors text-left ${
                  selected.has(item.mediaId) ? 'bg-indigo-600/20' : 'hover:bg-gray-700/50'
                }`}
              >
                <div
                  className={`h-5 w-5 rounded border flex items-center justify-center flex-shrink-0 ${
                    selected.has(item.mediaId)
                      ? 'bg-indigo-600 border-indigo-600'
                      : 'border-gray-500'
                  }`}
                >
                  {selected.has(item.mediaId) && (
                    <svg className="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                    </svg>
                  )}
                </div>
                {item.thumb ? (
                  <img
                    src={item.thumb}
                    alt=""
                    className="h-8 w-12 object-cover rounded bg-gray-700 flex-shrink-0"
                  />
                ) : (
                  <div className="h-8 w-12 bg-gray-700 rounded flex items-center justify-center flex-shrink-0">
                    {getTypeIcon(item.type)}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="text-sm text-white truncate">{item.title}</div>
                  <div className="text-xs text-gray-500">
                    {item.type} {item.year ? `(${item.year})` : ''}
                  </div>
                </div>
              </button>
            ))
          )}
        </div>

        <div className="flex items-center justify-between mt-4">
          <span className="text-sm text-gray-400">
            {selected.size} {selected.size === 1 ? 'item' : 'items'} selected
          </span>
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={() => onAdd(Array.from(selected))}
              disabled={selected.size === 0 || adding}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {adding && <Loader className="h-4 w-4 animate-spin" />}
              Add Selected
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
