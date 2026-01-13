import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Trophy,
  Plus,
  Search,
  Trash2,
  Edit,
  Power,
  Calendar,
  Loader2,
  X,
  Clock,
  Tv
} from 'lucide-react'
import { api } from '../api/client'

interface TeamPass {
  id: number
  userId: number
  teamName: string
  teamAliases: string
  league: string
  channelIds: string
  prePadding: number
  postPadding: number
  keepCount: number
  priority: number
  enabled: boolean
  createdAt: string
  updatedAt: string
  upcomingCount?: number
  logoUrl?: string
}

interface Team {
  name: string
  city: string
  nickname: string
  league: string
  aliases: string[]
  logoUrl?: string
}

interface UpcomingGame {
  program: {
    id: number
    title: string
    start: string
    end: string
    channelId: string
    teams?: string
    league?: string
  }
  channel?: {
    id: number
    name: string
    number: number
    logo?: string
  }
}

interface TeamPassStats {
  totalPasses: number
  activePasses: number
  upcomingGames: number
  scheduledRecordings: number
}

const LEAGUES = ['NFL', 'NBA', 'MLB', 'NHL', 'MLS']

function TeamPassPage() {
  const queryClient = useQueryClient()
  const [showAddModal, setShowAddModal] = useState(false)
  const [editingPass, setEditingPass] = useState<TeamPass | null>(null)
  const [selectedPass, setSelectedPass] = useState<TeamPass | null>(null)
  const [teamSearch, setTeamSearch] = useState('')
  const [selectedLeague, setSelectedLeague] = useState<string>('NFL')

  // Fetch team passes
  const { data: passesData, isLoading } = useQuery<{ teamPasses: TeamPass[] }>({
    queryKey: ['teamPasses'],
    queryFn: async () => {
      const response = await fetch('/api/teampass', {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    }
  })

  // Fetch stats
  const { data: stats } = useQuery<TeamPassStats>({
    queryKey: ['teamPassStats'],
    queryFn: async () => {
      const response = await fetch('/api/teampass/stats', {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    }
  })

  // Fetch teams by league
  const { data: teamsData } = useQuery<{ teams: Team[] }>({
    queryKey: ['leagueTeams', selectedLeague],
    queryFn: async () => {
      const response = await fetch(`/api/teampass/leagues/${selectedLeague}/teams`, {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    enabled: showAddModal || editingPass !== null
  })

  // Search teams
  const { data: searchResults } = useQuery<{ teams: Team[] }>({
    queryKey: ['teamSearch', teamSearch],
    queryFn: async () => {
      const response = await fetch(`/api/teampass/teams/search?q=${encodeURIComponent(teamSearch)}`, {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    enabled: teamSearch.length >= 2
  })

  // Fetch upcoming games for selected pass
  const { data: upcomingData } = useQuery<{ teamPass: TeamPass; games: UpcomingGame[] }>({
    queryKey: ['teamPassUpcoming', selectedPass?.id],
    queryFn: async () => {
      const response = await fetch(`/api/teampass/${selectedPass!.id}/upcoming`, {
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    enabled: selectedPass !== null
  })

  // Create team pass
  const createMutation = useMutation({
    mutationFn: async (data: Partial<TeamPass>) => {
      const response = await fetch('/api/teampass', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || ''
        },
        body: JSON.stringify(data)
      })
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teamPasses'] })
      queryClient.invalidateQueries({ queryKey: ['teamPassStats'] })
      setShowAddModal(false)
    }
  })

  // Update team pass
  const updateMutation = useMutation({
    mutationFn: async ({ id, data }: { id: number; data: Partial<TeamPass> }) => {
      const response = await fetch(`/api/teampass/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || ''
        },
        body: JSON.stringify(data)
      })
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teamPasses'] })
      setEditingPass(null)
    }
  })

  // Delete team pass
  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await fetch(`/api/teampass/${id}`, {
        method: 'DELETE',
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teamPasses'] })
      queryClient.invalidateQueries({ queryKey: ['teamPassStats'] })
    }
  })

  // Toggle team pass
  const toggleMutation = useMutation({
    mutationFn: async (id: number) => {
      const response = await fetch(`/api/teampass/${id}/toggle`, {
        method: 'PUT',
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teamPasses'] })
    }
  })

  // Process team passes
  const processMutation = useMutation({
    mutationFn: async () => {
      const response = await fetch('/api/teampass/process', {
        method: 'POST',
        headers: { 'X-Plex-Token': api.getToken() || '' }
      })
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teamPassStats'] })
    }
  })

  const teamPasses = passesData?.teamPasses || []
  const teams = teamSearch.length >= 2 ? (searchResults?.teams || []) : (teamsData?.teams || [])

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Team Pass</h1>
          <p className="text-gray-400">Auto-record games for your favorite sports teams</p>
        </div>

        <div className="flex gap-3">
          <button
            onClick={() => processMutation.mutate()}
            disabled={processMutation.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors"
          >
            {processMutation.isPending ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Calendar className="w-4 h-4" />
            )}
            Process Now
          </button>
          <button
            onClick={() => setShowAddModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-500 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Team
          </button>
        </div>
      </div>

      {/* Stats */}
      {stats && (
        <div className="grid grid-cols-4 gap-4 mb-6">
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-orange-400">
              <Trophy className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.totalPasses}</span>
            </div>
            <p className="text-sm text-gray-400">Team Passes</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-green-400">
              <Power className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.activePasses}</span>
            </div>
            <p className="text-sm text-gray-400">Active</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-blue-400">
              <Calendar className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.upcomingGames}</span>
            </div>
            <p className="text-sm text-gray-400">Upcoming Games</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-4">
            <div className="flex items-center gap-2 text-red-400">
              <Clock className="w-5 h-5" />
              <span className="text-2xl font-bold">{stats.scheduledRecordings}</span>
            </div>
            <p className="text-sm text-gray-400">Scheduled</p>
          </div>
        </div>
      )}

      {/* Team Passes List */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 text-indigo-500 animate-spin" />
        </div>
      ) : teamPasses.length === 0 ? (
        <div className="text-center py-12 bg-gray-800 rounded-lg">
          <Trophy className="w-16 h-16 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No Team Passes</h3>
          <p className="text-gray-400 mb-4">
            Add your favorite teams to automatically record their games
          </p>
          <button
            onClick={() => setShowAddModal(true)}
            className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-500"
          >
            Add Your First Team
          </button>
        </div>
      ) : (
        <div className="grid gap-4">
          {teamPasses.map((pass) => (
            <div
              key={pass.id}
              className={`bg-gray-800 rounded-lg p-4 border-l-4 ${
                pass.enabled ? 'border-green-500' : 'border-gray-600'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className={`w-12 h-12 rounded-lg ${getLeagueColor(pass.league)} flex items-center justify-center overflow-hidden`}>
                    {pass.logoUrl ? (
                      <img src={pass.logoUrl} alt={pass.teamName} className="w-10 h-10 object-contain" />
                    ) : (
                      <Trophy className="w-6 h-6 text-white" />
                    )}
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-white">{pass.teamName}</h3>
                    <div className="flex items-center gap-2 text-sm text-gray-400">
                      <span className={`px-2 py-0.5 rounded ${getLeagueColor(pass.league)} text-white text-xs`}>
                        {pass.league}
                      </span>
                      {pass.upcomingCount !== undefined && pass.upcomingCount > 0 && (
                        <span className="text-blue-400">
                          {pass.upcomingCount} upcoming game{pass.upcomingCount !== 1 ? 's' : ''}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setSelectedPass(pass)}
                    className="p-2 text-gray-400 hover:text-blue-400 transition-colors"
                    title="View upcoming games"
                  >
                    <Calendar className="w-5 h-5" />
                  </button>
                  <button
                    onClick={() => toggleMutation.mutate(pass.id)}
                    className={`p-2 transition-colors ${
                      pass.enabled ? 'text-green-400 hover:text-green-300' : 'text-gray-500 hover:text-gray-400'
                    }`}
                    title={pass.enabled ? 'Disable' : 'Enable'}
                  >
                    <Power className="w-5 h-5" />
                  </button>
                  <button
                    onClick={() => setEditingPass(pass)}
                    className="p-2 text-gray-400 hover:text-white transition-colors"
                    title="Edit"
                  >
                    <Edit className="w-5 h-5" />
                  </button>
                  <button
                    onClick={() => {
                      if (confirm(`Delete team pass for ${pass.teamName}?`)) {
                        deleteMutation.mutate(pass.id)
                      }
                    }}
                    className="p-2 text-gray-400 hover:text-red-400 transition-colors"
                    title="Delete"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {/* Settings row */}
              <div className="mt-3 pt-3 border-t border-gray-700 flex gap-6 text-sm text-gray-400">
                <span>Pre-padding: {pass.prePadding}m</span>
                <span>Post-padding: {pass.postPadding}m</span>
                {pass.keepCount > 0 && <span>Keep: {pass.keepCount} recordings</span>}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add/Edit Modal */}
      {(showAddModal || editingPass) && (
        <TeamPassModal
          pass={editingPass}
          teams={teams}
          selectedLeague={selectedLeague}
          onLeagueChange={setSelectedLeague}
          teamSearch={teamSearch}
          onTeamSearchChange={setTeamSearch}
          onClose={() => {
            setShowAddModal(false)
            setEditingPass(null)
            setTeamSearch('')
          }}
          onSave={(data) => {
            if (editingPass) {
              updateMutation.mutate({ id: editingPass.id, data })
            } else {
              createMutation.mutate(data)
            }
          }}
          isLoading={createMutation.isPending || updateMutation.isPending}
        />
      )}

      {/* Upcoming Games Modal */}
      {selectedPass && upcomingData && (
        <UpcomingGamesModal
          teamPass={selectedPass}
          games={upcomingData.games || []}
          onClose={() => setSelectedPass(null)}
        />
      )}
    </div>
  )
}

interface TeamPassModalProps {
  pass: TeamPass | null
  teams: Team[]
  selectedLeague: string
  onLeagueChange: (league: string) => void
  teamSearch: string
  onTeamSearchChange: (search: string) => void
  onClose: () => void
  onSave: (data: Partial<TeamPass>) => void
  isLoading: boolean
}

function TeamPassModal({
  pass,
  teams,
  selectedLeague,
  onLeagueChange,
  teamSearch,
  onTeamSearchChange,
  onClose,
  onSave,
  isLoading
}: TeamPassModalProps) {
  const [formData, setFormData] = useState({
    teamName: pass?.teamName || '',
    league: pass?.league || selectedLeague,
    logoUrl: pass?.logoUrl || '',
    prePadding: pass?.prePadding ?? 5,
    postPadding: pass?.postPadding ?? 60,
    keepCount: pass?.keepCount ?? 0,
    priority: pass?.priority ?? 0,
    enabled: pass?.enabled ?? true
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSave(formData)
  }

  const selectTeam = (team: Team) => {
    setFormData({ ...formData, teamName: team.name, league: team.league, logoUrl: team.logoUrl || '' })
    onTeamSearchChange('')
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70">
      <div className="bg-gray-800 rounded-lg w-full max-w-lg p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-white">
            {pass ? 'Edit Team Pass' : 'Add Team Pass'}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Team Search/Select */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Team
            </label>
            {formData.teamName ? (
              <div className="flex items-center justify-between p-3 bg-gray-700 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded ${getLeagueColor(formData.league)} flex items-center justify-center overflow-hidden`}>
                    {formData.logoUrl ? (
                      <img src={formData.logoUrl} alt={formData.teamName} className="w-8 h-8 object-contain" />
                    ) : (
                      <Trophy className="w-5 h-5 text-white" />
                    )}
                  </div>
                  <div>
                    <p className="text-white font-medium">{formData.teamName}</p>
                    <p className="text-sm text-gray-400">{formData.league}</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setFormData({ ...formData, teamName: '', league: selectedLeague, logoUrl: '' })}
                  className="text-gray-400 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            ) : (
              <div>
                {/* League tabs */}
                <div className="flex gap-2 mb-3">
                  {LEAGUES.map((league) => (
                    <button
                      key={league}
                      type="button"
                      onClick={() => {
                        onLeagueChange(league)
                        setFormData({ ...formData, league })
                      }}
                      className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
                        selectedLeague === league
                          ? getLeagueColor(league) + ' text-white'
                          : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                      }`}
                    >
                      {league}
                    </button>
                  ))}
                </div>

                {/* Search input */}
                <div className="relative mb-3">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="text"
                    value={teamSearch}
                    onChange={(e) => onTeamSearchChange(e.target.value)}
                    placeholder="Search teams..."
                    className="w-full pl-9 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>

                {/* Teams grid */}
                <div className="max-h-48 overflow-y-auto grid grid-cols-2 gap-2">
                  {teams.map((team) => (
                    <button
                      key={team.name}
                      type="button"
                      onClick={() => selectTeam(team)}
                      className="p-2 bg-gray-700 rounded hover:bg-gray-600 text-left transition-colors flex items-center gap-2"
                    >
                      <div className={`w-8 h-8 rounded ${getLeagueColor(team.league)} flex items-center justify-center overflow-hidden flex-shrink-0`}>
                        {team.logoUrl ? (
                          <img src={team.logoUrl} alt={team.name} className="w-6 h-6 object-contain" />
                        ) : (
                          <Trophy className="w-4 h-4 text-white" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="text-white text-sm font-medium truncate">{team.name}</p>
                        <p className="text-xs text-gray-400 truncate">{team.city}</p>
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Padding Settings */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Start Early (minutes)
              </label>
              <input
                type="number"
                value={formData.prePadding}
                onChange={(e) => setFormData({ ...formData, prePadding: parseInt(e.target.value) || 0 })}
                min={0}
                max={60}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-green-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Extend (minutes)
              </label>
              <input
                type="number"
                value={formData.postPadding}
                onChange={(e) => setFormData({ ...formData, postPadding: parseInt(e.target.value) || 0 })}
                min={0}
                max={120}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-green-500"
              />
              <p className="text-xs text-gray-500 mt-1">Extra time for overtime</p>
            </div>
          </div>

          {/* Keep Count */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Keep Last N Recordings (0 = unlimited)
            </label>
            <input
              type="number"
              value={formData.keepCount}
              onChange={(e) => setFormData({ ...formData, keepCount: parseInt(e.target.value) || 0 })}
              min={0}
              className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>

          {/* Actions */}
          <div className="flex justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!formData.teamName || isLoading}
              className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading && <Loader2 className="w-4 h-4 animate-spin" />}
              {pass ? 'Save Changes' : 'Add Team Pass'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

interface UpcomingGamesModalProps {
  teamPass: TeamPass
  games: UpcomingGame[]
  onClose: () => void
}

function UpcomingGamesModal({ teamPass, games, onClose }: UpcomingGamesModalProps) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70">
      <div className="bg-gray-800 rounded-lg w-full max-w-2xl max-h-[80vh] flex flex-col">
        <div className="flex items-center justify-between p-6 border-b border-gray-700">
          <div>
            <h2 className="text-xl font-bold text-white">{teamPass.teamName}</h2>
            <p className="text-sm text-gray-400">Upcoming Games</p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6">
          {games.length === 0 ? (
            <div className="text-center py-8">
              <Calendar className="w-12 h-12 text-gray-600 mx-auto mb-3" />
              <p className="text-gray-400">No upcoming games found</p>
            </div>
          ) : (
            <div className="space-y-3">
              {games.map((game, index) => (
                <div key={index} className="bg-gray-700 rounded-lg p-4">
                  <div className="flex items-start justify-between">
                    <div>
                      <h4 className="font-medium text-white">{game.program.title}</h4>
                      {game.program.teams && (
                        <p className="text-sm text-gray-300">{game.program.teams}</p>
                      )}
                    </div>
                    {game.program.league && (
                      <span className={`px-2 py-0.5 rounded text-xs text-white ${getLeagueColor(game.program.league)}`}>
                        {game.program.league}
                      </span>
                    )}
                  </div>
                  <div className="mt-2 flex items-center gap-4 text-sm text-gray-400">
                    <span className="text-blue-400">
                      {formatDateTime(game.program.start)}
                    </span>
                    {game.channel && (
                      <span className="flex items-center gap-1">
                        <Tv className="w-3 h-3" />
                        {game.channel.name}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function getLeagueColor(league: string): string {
  switch (league?.toUpperCase()) {
    case 'NFL':
      return 'bg-blue-600'
    case 'NBA':
      return 'bg-orange-600'
    case 'MLB':
      return 'bg-red-600'
    case 'NHL':
      return 'bg-gray-600'
    case 'MLS':
      return 'bg-green-600'
    default:
      return 'bg-purple-600'
  }
}

function formatDateTime(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const tomorrow = new Date(now)
  tomorrow.setDate(tomorrow.getDate() + 1)

  const isToday = date.toDateString() === now.toDateString()
  const isTomorrow = date.toDateString() === tomorrow.toDateString()

  const timeStr = date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })

  if (isToday) return `Today ${timeStr}`
  if (isTomorrow) return `Tomorrow ${timeStr}`
  return date.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' }) + ` ${timeStr}`
}

export default TeamPassPage
