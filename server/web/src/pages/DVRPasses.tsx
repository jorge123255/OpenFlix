import { useState, useMemo } from 'react'
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
  Calendar,
  ListFilter,
} from 'lucide-react'
import { api } from '../api/client'
import type { DVRPass } from '../api/client'

type SortField = 'name' | 'jobs' | 'date' | 'priority'

export function DVRPassesPage() {
  const queryClient = useQueryClient()
  const [searchQuery, setSearchQuery] = useState('')
  const [sortField, setSortField] = useState<SortField>('name')
  const [sortAsc, setSortAsc] = useState(true)

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
          p.name.toLowerCase().includes(q) ||
          (p.teamName && p.teamName.toLowerCase().includes(q)) ||
          (p.league && p.league.toLowerCase().includes(q)) ||
          (p.keywords && p.keywords.toLowerCase().includes(q))
      )
    }

    result = [...result].sort((a, b) => {
      let cmp = 0
      switch (sortField) {
        case 'name':
          cmp = a.name.localeCompare(b.name)
          break
        case 'jobs':
          cmp = a.jobCount - b.jobCount
          break
        case 'date':
          cmp = new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
          break
        case 'priority':
          cmp = a.priority - b.priority
          break
      }
      return sortAsc ? cmp : -cmp
    })

    return result
  }, [passes, searchQuery, sortField, sortAsc])

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortAsc(!sortAsc)
    } else {
      setSortField(field)
      setSortAsc(true)
    }
  }

  const handleToggle = (pass: DVRPass) => {
    if (pass.enabled) {
      pauseMutation.mutate({ id: pass.id, type: pass.type })
    } else {
      resumeMutation.mutate({ id: pass.id, type: pass.type })
    }
  }

  const handleDelete = (pass: DVRPass) => {
    if (!confirm(`Delete pass "${pass.name}"? This will not remove existing recordings.`)) return
    if (pass.type === 'series') {
      deleteSeriesRule.mutate(pass.id)
    }
  }

  const formatDate = (dateStr: string): string => {
    return new Date(dateStr).toLocaleDateString([], {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    })
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">DVR Passes</h1>
        <p className="text-gray-400 mt-1">Manage your recording rules and team passes</p>
      </div>

      {/* Search and Sort Bar */}
      <div className="mb-6 flex flex-col sm:flex-row gap-4">
        {/* Search Input */}
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

        {/* Sort Buttons */}
        <div className="flex items-center gap-1 bg-gray-800 rounded-lg p-1">
          <ListFilter className="w-4 h-4 text-gray-400 ml-2" />
          {(['name', 'jobs', 'date', 'priority'] as SortField[]).map((field) => (
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
              {sortField === field && (
                <ArrowUpDown className="w-3 h-3" />
              )}
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
              key={`${pass.type}-${pass.id}`}
              pass={pass}
              onToggle={() => handleToggle(pass)}
              onDelete={() => handleDelete(pass)}
              formatDate={formatDate}
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
          <p className="text-gray-400">
            Create series rules from DVR or team passes from Team Pass
          </p>
        </div>
      )}
    </div>
  )
}

function PassCard({
  pass,
  onToggle,
  onDelete,
  formatDate,
  isToggling,
}: {
  pass: DVRPass
  onToggle: () => void
  onDelete: () => void
  formatDate: (d: string) => string
  isToggling: boolean
}) {
  const typeColor =
    pass.type === 'team'
      ? 'bg-amber-500/20 text-amber-400'
      : 'bg-indigo-500/20 text-indigo-400'
  const TypeIcon = pass.type === 'team' ? Trophy : Tv

  return (
    <div
      className={`bg-gray-800 rounded-xl border transition-colors ${
        pass.enabled
          ? 'border-gray-700 hover:border-gray-600'
          : 'border-gray-700/50 opacity-60'
      }`}
    >
      <div className="p-4 flex items-start gap-4">
        {/* Poster / Icon placeholder */}
        <div className="flex-shrink-0 w-16 h-24 rounded-lg overflow-hidden bg-gray-700 flex items-center justify-center">
          {pass.thumb ? (
            <img
              src={pass.thumb}
              alt={pass.name}
              className="w-full h-full object-cover"
            />
          ) : (
            <TypeIcon className="w-8 h-8 text-gray-500" />
          )}
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <h3 className="font-semibold text-white text-lg truncate">{pass.name}</h3>
              <div className="mt-1 flex flex-wrap items-center gap-2">
                <span
                  className={`px-2 py-0.5 text-xs font-medium rounded ${typeColor}`}
                >
                  {pass.type === 'team' ? 'Team Pass' : 'Series Rule'}
                </span>
                {!pass.enabled && (
                  <span className="px-2 py-0.5 text-xs font-medium rounded bg-gray-600 text-gray-300">
                    Paused
                  </span>
                )}
                {pass.league && (
                  <span className="px-2 py-0.5 text-xs font-medium rounded bg-green-500/20 text-green-400">
                    {pass.league}
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Metadata row */}
          <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-gray-400">
            <span className="flex items-center gap-1">
              <Video className="w-3.5 h-3.5" />
              {pass.jobCount} recording{pass.jobCount !== 1 ? 's' : ''}
            </span>
            <span className="flex items-center gap-1">
              <Calendar className="w-3.5 h-3.5" />
              Created {formatDate(pass.createdAt)}
            </span>
            {pass.keepCount > 0 && (
              <span>Keep last {pass.keepCount}</span>
            )}
            {pass.keepCount === 0 && (
              <span>Keep all</span>
            )}
            {pass.keywords && (
              <span>Keywords: {pass.keywords}</span>
            )}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex-shrink-0 flex items-center gap-1">
          <button
            onClick={onToggle}
            disabled={isToggling}
            className={`p-2 rounded-lg transition-colors ${
              pass.enabled
                ? 'text-gray-400 hover:text-amber-400 hover:bg-gray-700'
                : 'text-amber-400 hover:text-green-400 hover:bg-gray-700'
            }`}
            title={pass.enabled ? 'Pause' : 'Resume'}
          >
            {pass.enabled ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
          </button>
          <button
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
