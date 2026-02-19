import { useState } from 'react'
import {
  Users as UsersIcon,
  Plus,
  Trash2,
  Shield,
  ShieldOff,
  Baby,
  ChevronDown,
  ChevronRight,
  Loader,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import type { User, UserProfile } from '../types'

function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => api.getUsers(),
  })
}

function CreateUserModal({ onClose }: { onClose: () => void }) {
  const queryClient = useQueryClient()
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [isAdmin, setIsAdmin] = useState(false)
  const [error, setError] = useState('')

  const createUser = useMutation({
    mutationFn: (data: { username: string; email: string; password: string; isAdmin?: boolean }) =>
      api.createUser(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      onClose()
    },
    onError: (err: any) => {
      setError(err.response?.data?.error || 'Failed to create user')
    },
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    createUser.mutate({ username, email, password, isAdmin })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <h2 className="text-lg font-semibold text-white mb-4">Create User</h2>
        <form onSubmit={handleSubmit}>
          {error && (
            <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
              {error}
            </div>
          )}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Username</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              required
              minLength={6}
            />
          </div>
          <div className="mb-6">
            <label className="flex items-center gap-2 text-sm text-gray-300">
              <input
                type="checkbox"
                checked={isAdmin}
                onChange={(e) => setIsAdmin(e.target.checked)}
                className="rounded bg-gray-700 border-gray-600"
              />
              Administrator
            </label>
          </div>
          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={createUser.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {createUser.isPending ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function CreateProfileModal({ userId, onClose }: { userId: number; onClose: () => void }) {
  const queryClient = useQueryClient()
  const [name, setName] = useState('')
  const [isKid, setIsKid] = useState(false)
  const [error, setError] = useState('')

  const createProfile = useMutation({
    mutationFn: (data: { name: string; isKid?: boolean }) => api.createProfile(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['userProfiles', userId] })
      queryClient.invalidateQueries({ queryKey: ['users'] })
      onClose()
    },
    onError: (err: any) => {
      setError(err.response?.data?.error || 'Failed to create profile')
    },
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    createProfile.mutate({ name, isKid })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
        <h2 className="text-lg font-semibold text-white mb-4">Add Profile</h2>
        <form onSubmit={handleSubmit}>
          {error && (
            <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
              {error}
            </div>
          )}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-300 mb-2">Profile Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
              placeholder="e.g. Dad, Kids, Guest"
              required
            />
          </div>
          <div className="mb-6">
            <label className="flex items-center gap-2 text-sm text-gray-300">
              <input
                type="checkbox"
                checked={isKid}
                onChange={(e) => setIsKid(e.target.checked)}
                className="rounded bg-gray-700 border-gray-600"
              />
              Kid Profile
            </label>
            <p className="text-xs text-gray-500 mt-1 ml-6">Kid profiles have content restrictions</p>
          </div>
          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={createProfile.isPending}
              className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
            >
              {createProfile.isPending ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function UserProfilesList({ user }: { user: User }) {
  const queryClient = useQueryClient()

  const { data: profiles, isLoading } = useQuery({
    queryKey: ['userProfiles', user.id],
    queryFn: () => api.getUserProfiles(user.id),
  })

  const deleteProfile = useMutation({
    mutationFn: (id: number) => api.deleteProfile(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['userProfiles', user.id] })
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })

  const [showCreate, setShowCreate] = useState(false)

  if (isLoading) {
    return (
      <div className="px-4 pb-4 pt-1">
        <div className="flex items-center gap-2 text-gray-500 text-sm">
          <Loader className="h-3.5 w-3.5 animate-spin" />
          Loading profiles...
        </div>
      </div>
    )
  }

  return (
    <div className="px-4 pb-4 pt-1">
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs font-medium text-gray-400 uppercase tracking-wide">Profiles</span>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-1 px-2 py-1 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 rounded-md"
        >
          <Plus className="h-3 w-3" />
          Add
        </button>
      </div>
      {profiles && profiles.length > 0 ? (
        <div className="flex flex-wrap gap-2">
          {profiles.map((profile: UserProfile) => (
            <div
              key={profile.id}
              className="flex items-center gap-2 px-3 py-1.5 bg-gray-900 rounded-lg border border-gray-700"
            >
              <div className="h-6 w-6 rounded-full bg-purple-600 flex items-center justify-center text-white text-xs font-medium">
                {profile.name.charAt(0).toUpperCase()}
              </div>
              <span className="text-sm text-white">{profile.name}</span>
              {profile.isKid && (
                <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 bg-green-500/20 text-green-400 text-xs rounded-full">
                  <Baby className="h-2.5 w-2.5" />
                  Kid
                </span>
              )}
              <button
                onClick={() => {
                  if (confirm(`Delete profile "${profile.name}"?`)) {
                    deleteProfile.mutate(profile.id)
                  }
                }}
                className="p-0.5 text-gray-500 hover:text-red-400 rounded"
                title="Delete profile"
              >
                <Trash2 className="h-3 w-3" />
              </button>
            </div>
          ))}
        </div>
      ) : (
        <p className="text-xs text-gray-500">No profiles yet</p>
      )}
      {showCreate && <CreateProfileModal userId={user.id} onClose={() => setShowCreate(false)} />}
    </div>
  )
}

function UserRow({ user, onDelete }: { user: User; onDelete: () => void }) {
  const [expanded, setExpanded] = useState(false)

  return (
    <div>
      <div className="p-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => setExpanded(!expanded)}
            className="p-1 text-gray-400 hover:text-white rounded"
          >
            {expanded ? (
              <ChevronDown className="h-4 w-4" />
            ) : (
              <ChevronRight className="h-4 w-4" />
            )}
          </button>
          <div className="h-10 w-10 rounded-full bg-indigo-600 flex items-center justify-center text-white font-medium">
            {user.username.charAt(0).toUpperCase()}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-medium text-white">{user.title || user.username}</h3>
              {user.admin && (
                <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-indigo-500/20 text-indigo-400 text-xs rounded-full">
                  <Shield className="h-3 w-3" />
                  Admin
                </span>
              )}
              {user.restricted && (
                <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-orange-500/20 text-orange-400 text-xs rounded-full">
                  <ShieldOff className="h-3 w-3" />
                  Restricted
                </span>
              )}
            </div>
            <p className="text-sm text-gray-400">{user.email}</p>
          </div>
        </div>
        <button
          onClick={onDelete}
          disabled={user.admin}
          className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
          title={user.admin ? "Can't delete admin" : 'Delete user'}
        >
          <Trash2 className="h-4 w-4" />
        </button>
      </div>
      {expanded && <UserProfilesList user={user} />}
    </div>
  )
}

export function UsersPage() {
  const { data: users, isLoading } = useUsers()
  const queryClient = useQueryClient()
  const [showCreate, setShowCreate] = useState(false)

  const deleteUser = useMutation({
    mutationFn: (id: number) => api.deleteUser(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })

  const handleDelete = async (user: User) => {
    if (confirm(`Are you sure you want to delete ${user.username}? This will also delete all their profiles.`)) {
      deleteUser.mutate(user.id)
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Users & Profiles</h1>
          <p className="text-gray-400 mt-1">Manage server users and their profiles</p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
        >
          <Plus className="h-4 w-4" />
          Add User
        </button>
      </div>

      {isLoading ? (
        <div className="flex items-center gap-2 text-gray-400">
          <Loader className="h-5 w-5 animate-spin" />
          Loading users...
        </div>
      ) : users?.length ? (
        <div className="bg-gray-800 rounded-xl divide-y divide-gray-700">
          {users.map((user) => (
            <UserRow key={user.id} user={user} onDelete={() => handleDelete(user)} />
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <UsersIcon className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No users</h3>
          <p className="text-gray-400 mb-4">Add users to allow access to your server</p>
          <button
            onClick={() => setShowCreate(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
          >
            <Plus className="h-4 w-4" />
            Add User
          </button>
        </div>
      )}

      {showCreate && <CreateUserModal onClose={() => setShowCreate(false)} />}
    </div>
  )
}
