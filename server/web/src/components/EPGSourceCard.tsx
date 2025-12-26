import { RefreshCw, AlertCircle, CheckCircle, Clock, Tv, FileText } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'

interface EPGSource {
  id: number
  name: string
  providerType: string
  gracenoteAffiliate?: string
  gracenotePostalCode?: string
  url?: string
  enabled: boolean
  lastFetched?: string
  lastError?: string
  programCount?: number
  channelCount?: number
}

interface EPGSourceCardProps {
  source: EPGSource
  onRefresh: (id: number) => void
  onDelete: (id: number) => void
  isRefreshing: boolean
}

export function EPGSourceCard({ source, onRefresh, onDelete, isRefreshing }: EPGSourceCardProps) {
  const getStatusColor = () => {
    if (isRefreshing) return 'border-blue-500 bg-blue-500/10'
    if (source.lastError) return 'border-red-500 bg-red-500/5'
    if (source.lastFetched) return 'border-green-500 bg-green-500/5'
    return 'border-gray-600 bg-gray-800'
  }

  const getStatusIcon = () => {
    if (isRefreshing) {
      return <RefreshCw className="h-5 w-5 text-blue-400 animate-spin" />
    }
    if (source.lastError) {
      return <AlertCircle className="h-5 w-5 text-red-400" />
    }
    if (source.lastFetched) {
      return <CheckCircle className="h-5 w-5 text-green-400" />
    }
    return <Clock className="h-5 w-5 text-gray-400" />
  }

  const getStatusText = () => {
    if (isRefreshing) return 'Refreshing...'
    if (source.lastError) return 'Error'
    if (source.lastFetched) return 'Active'
    return 'Never fetched'
  }

  const getLastFetchedText = () => {
    if (!source.lastFetched) return 'Never'
    try {
      return formatDistanceToNow(new Date(source.lastFetched), { addSuffix: true })
    } catch {
      return 'Unknown'
    }
  }

  return (
    <div className={`rounded-lg border-2 ${getStatusColor()} p-4 transition-colors`}>
      {/* Header */}
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="font-semibold text-white text-lg">{source.name}</h3>
            <span className="px-2 py-0.5 bg-indigo-600 text-white text-xs rounded uppercase font-medium">
              {source.providerType}
            </span>
          </div>
          <p className="text-sm text-gray-400">
            {source.providerType === 'gracenote'
              ? `${source.gracenoteAffiliate} • ${source.gracenotePostalCode}`
              : source.url
            }
          </p>
        </div>
        <div className="flex items-center gap-2 ml-4">
          {getStatusIcon()}
          <span className={`text-sm font-medium ${
            isRefreshing ? 'text-blue-400' :
            source.lastError ? 'text-red-400' :
            source.lastFetched ? 'text-green-400' :
            'text-gray-400'
          }`}>
            {getStatusText()}
          </span>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3 mb-3">
        <div className="bg-gray-700/50 rounded p-2">
          <div className="flex items-center gap-1.5 text-gray-400 mb-1">
            <Tv className="h-3.5 w-3.5" />
            <span className="text-xs">Channels</span>
          </div>
          <p className="text-lg font-semibold text-white">{(source.channelCount || 0).toLocaleString()}</p>
        </div>
        <div className="bg-gray-700/50 rounded p-2">
          <div className="flex items-center gap-1.5 text-gray-400 mb-1">
            <FileText className="h-3.5 w-3.5" />
            <span className="text-xs">Programs</span>
          </div>
          <p className="text-lg font-semibold text-white">{(source.programCount || 0).toLocaleString()}</p>
        </div>
        <div className="bg-gray-700/50 rounded p-2">
          <div className="flex items-center gap-1.5 text-gray-400 mb-1">
            <Clock className="h-3.5 w-3.5" />
            <span className="text-xs">Updated</span>
          </div>
          <p className="text-xs font-medium text-white truncate">{getLastFetchedText()}</p>
        </div>
      </div>

      {/* Error Message */}
      {source.lastError && (
        <div className="mb-3 p-2 bg-red-900/20 border border-red-800 rounded">
          <p className="text-xs text-red-300">{source.lastError}</p>
        </div>
      )}

      {/* Actions */}
      <div className="flex gap-2">
        <button
          onClick={() => onRefresh(source.id)}
          disabled={isRefreshing}
          className="flex-1 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white text-sm rounded flex items-center justify-center gap-1.5"
        >
          <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          {isRefreshing ? 'Refreshing...' : 'Refresh'}
        </button>
        <button
          onClick={() => onDelete(source.id)}
          disabled={isRefreshing}
          className="px-3 py-1.5 bg-red-600 hover:bg-red-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white text-sm rounded"
        >
          Delete
        </button>
      </div>
    </div>
  )
}
