import { useState } from 'react'
import {
  Users,
  Mail,
  Trash2,
  Shield,
  Copy,
  CheckCircle,
  Loader,
  UserPlus,
  Send,
  Link,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'

function formatDate(dateStr: string | undefined): string {
  if (!dateStr) return 'Unknown'
  try {
    return new Date(dateStr).toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    })
  } catch {
    return 'Unknown'
  }
}

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      // fallback
    }
  }

  return (
    <button
      onClick={handleCopy}
      className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white rounded-lg text-sm transition-colors"
      title="Copy to clipboard"
    >
      {copied ? <CheckCircle className="h-3.5 w-3.5 text-green-400" /> : <Copy className="h-3.5 w-3.5" />}
      {copied ? 'Copied!' : 'Copy'}
    </button>
  )
}

interface AdminUser {
  id: number
  username: string
  email: string
  admin: boolean
  createdAt: string
}

function CurrentUsersSection() {
  const queryClient = useQueryClient()

  const { data: users, isLoading, error } = useQuery({
    queryKey: ['adminUsers'],
    queryFn: () => api.getAdminUsers(),
  })

  const deleteUser = useMutation({
    mutationFn: (id: number) => api.deleteUser(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminUsers'] })
    },
  })

  const handleDelete = (user: AdminUser) => {
    if (confirm(`Are you sure you want to remove ${user.username || user.email} from the server?`)) {
      deleteUser.mutate(user.id)
    }
  }

  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        <Users className="h-5 w-5 text-indigo-400" />
        Current Users
      </h2>

      {isLoading && (
        <div className="flex items-center gap-2 text-gray-400 text-sm">
          <Loader className="h-4 w-4 animate-spin" />
          Loading users...
        </div>
      )}

      {error && (
        <div className="p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
          Failed to load users
        </div>
      )}

      {users && users.length === 0 && (
        <div className="text-center py-8">
          <Users className="h-10 w-10 text-gray-600 mx-auto mb-3" />
          <p className="text-gray-400 text-sm">No users yet. Invite someone to get started.</p>
        </div>
      )}

      {users && users.length > 0 && (
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-700">
                <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wide pb-3 pr-4">
                  User
                </th>
                <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wide pb-3 pr-4">
                  Email
                </th>
                <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wide pb-3 pr-4">
                  Role
                </th>
                <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wide pb-3 pr-4">
                  Joined
                </th>
                <th className="pb-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700">
              {users.map((user) => (
                <tr key={user.id} className="group">
                  <td className="py-3 pr-4">
                    <div className="flex items-center gap-3">
                      <div className="h-8 w-8 rounded-full bg-indigo-600 flex items-center justify-center text-white font-medium text-sm flex-shrink-0">
                        {(user.username || user.email).charAt(0).toUpperCase()}
                      </div>
                      <span className="text-sm font-medium text-white">
                        {user.username || '—'}
                      </span>
                    </div>
                  </td>
                  <td className="py-3 pr-4">
                    <span className="text-sm text-gray-400">{user.email || '—'}</span>
                  </td>
                  <td className="py-3 pr-4">
                    {user.admin ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-indigo-500/20 text-indigo-400 text-xs rounded-full">
                        <Shield className="h-3 w-3" />
                        Admin
                      </span>
                    ) : (
                      <span className="text-xs text-gray-500">Member</span>
                    )}
                  </td>
                  <td className="py-3 pr-4">
                    <span className="text-sm text-gray-500">{formatDate(user.createdAt)}</span>
                  </td>
                  <td className="py-3">
                    <button
                      onClick={() => handleDelete(user)}
                      disabled={user.admin || deleteUser.isPending}
                      className="p-1.5 text-gray-500 hover:text-red-400 hover:bg-gray-700 rounded-lg disabled:opacity-30 disabled:cursor-not-allowed transition-colors opacity-0 group-hover:opacity-100"
                      title={user.admin ? "Can't remove admin" : 'Remove user'}
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

interface InviteResult {
  token: string
  inviteUrl: string
}

function InviteSection() {
  const [email, setEmail] = useState('')
  const [result, setResult] = useState<InviteResult | null>(null)
  const [error, setError] = useState('')

  const inviteMutation = useMutation({
    mutationFn: (emailAddr: string) => api.createInvite(emailAddr),
    onSuccess: (data) => {
      setResult(data)
      setEmail('')
      setError('')
    },
    onError: (err: any) => {
      setError(err.response?.data?.error || 'Failed to create invite')
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setResult(null)
    setError('')
    if (email.trim()) {
      inviteMutation.mutate(email.trim())
    }
  }

  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        <UserPlus className="h-5 w-5 text-indigo-400" />
        Invite Someone
      </h2>

      <p className="text-sm text-gray-400 mb-4">
        Send an invite link to allow someone to create an account on your server.
      </p>

      <form onSubmit={handleSubmit}>
        {error && (
          <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
            {error}
          </div>
        )}

        <div className="flex gap-2">
          <div className="flex-1 relative">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-500" />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="friend@example.com"
              className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:border-indigo-500"
              required
            />
          </div>
          <button
            type="submit"
            disabled={inviteMutation.isPending || !email.trim()}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
          >
            {inviteMutation.isPending ? (
              <Loader className="h-4 w-4 animate-spin" />
            ) : (
              <Send className="h-4 w-4" />
            )}
            Send Invite
          </button>
        </div>
      </form>

      {result && (
        <div className="mt-4 p-4 rounded-lg bg-green-500/10 border border-green-500/20">
          <div className="flex items-center gap-2 mb-3">
            <CheckCircle className="h-4 w-4 text-green-400" />
            <p className="text-sm font-medium text-green-400">Invite Created!</p>
          </div>
          <p className="text-xs text-gray-400 mb-3">
            Share this invite link with your friend. It can only be used once.
          </p>

          <div className="space-y-3">
            {result.inviteUrl && (
              <div>
                <p className="text-xs text-gray-500 mb-1">Invite Link</p>
                <div className="flex items-center gap-2">
                  <div className="flex-1 flex items-center gap-2 px-3 py-2 bg-gray-900 rounded-lg">
                    <Link className="h-3.5 w-3.5 text-gray-500 flex-shrink-0" />
                    <code className="text-xs text-gray-300 font-mono truncate">{result.inviteUrl}</code>
                  </div>
                  <CopyButton text={result.inviteUrl} />
                </div>
              </div>
            )}

            {result.token && (
              <div>
                <p className="text-xs text-gray-500 mb-1">Invite Token</p>
                <div className="flex items-center gap-2">
                  <code className="flex-1 px-3 py-2 bg-gray-900 rounded-lg text-xs text-gray-300 font-mono">
                    {result.token}
                  </code>
                  <CopyButton text={result.token} />
                </div>
              </div>
            )}
          </div>

          <button
            onClick={() => setResult(null)}
            className="mt-3 text-xs text-gray-500 hover:text-gray-300 underline"
          >
            Dismiss
          </button>
        </div>
      )}
    </div>
  )
}

export function FamilySharingPage() {
  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white flex items-center gap-3">
          <Users className="h-7 w-7 text-indigo-400" />
          Family Sharing
        </h1>
        <p className="text-gray-400 mt-1">
          Share your server with family and friends by managing users and sending invite links
        </p>
      </div>

      <CurrentUsersSection />
      <InviteSection />
    </div>
  )
}
