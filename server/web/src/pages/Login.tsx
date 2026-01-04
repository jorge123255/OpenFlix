import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useLogin, useRegister } from '../hooks/useAuth'
import { Tv } from 'lucide-react'

export function LoginPage() {
  const navigate = useNavigate()
  const login = useLogin()
  const register = useRegister()
  const [isSignup, setIsSignup] = useState(false)
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSuccess('')

    if (isSignup) {
      if (password !== confirmPassword) {
        setError('Passwords do not match')
        return
      }
      if (password.length < 6) {
        setError('Password must be at least 6 characters')
        return
      }

      try {
        await register.mutateAsync({ username, email, password })
        setSuccess('Account created! You can now sign in.')
        setIsSignup(false)
        setPassword('')
        setConfirmPassword('')
        setEmail('')
      } catch (err: unknown) {
        const axiosError = err as { response?: { data?: { error?: string } } }
        setError(axiosError.response?.data?.error || 'Failed to create account')
      }
    } else {
      try {
        const result = await login.mutateAsync({ username, password })
        if (!result.user.admin) {
          setError('Admin access required')
          return
        }
        navigate('/ui')
      } catch (err) {
        setError('Invalid username or password')
      }
    }
  }

  const toggleMode = () => {
    setIsSignup(!isSignup)
    setError('')
    setSuccess('')
    setPassword('')
    setConfirmPassword('')
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900 px-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-indigo-600 mb-4">
            <Tv className="h-8 w-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">OpenFlix Admin</h1>
          <p className="text-gray-400 mt-2">
            {isSignup ? 'Create your admin account' : 'Sign in to manage your server'}
          </p>
        </div>

        <form onSubmit={handleSubmit} className="bg-gray-800 rounded-xl p-6 shadow-xl">
          {error && (
            <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
              {error}
            </div>
          )}

          {success && (
            <div className="mb-4 p-3 rounded-lg bg-green-500/10 border border-green-500/20 text-green-400 text-sm">
              {success}
            </div>
          )}

          <div className="mb-4">
            <label htmlFor="username" className="block text-sm font-medium text-gray-300 mb-2">
              Username
            </label>
            <input
              id="username"
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              placeholder="Enter your username"
              required
            />
          </div>

          {isSignup && (
            <div className="mb-4">
              <label htmlFor="email" className="block text-sm font-medium text-gray-300 mb-2">
                Email
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                placeholder="Enter your email"
                required
              />
            </div>
          )}

          <div className="mb-4">
            <label htmlFor="password" className="block text-sm font-medium text-gray-300 mb-2">
              Password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              placeholder="Enter your password"
              required
            />
          </div>

          {isSignup && (
            <div className="mb-4">
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-300 mb-2">
                Confirm Password
              </label>
              <input
                id="confirmPassword"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                placeholder="Confirm your password"
                required
              />
            </div>
          )}

          <button
            type="submit"
            disabled={login.isPending || register.isPending}
            className="w-full py-2 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 disabled:cursor-not-allowed text-white font-medium rounded-lg transition-colors mb-4"
          >
            {login.isPending || register.isPending
              ? (isSignup ? 'Creating account...' : 'Signing in...')
              : (isSignup ? 'Create Account' : 'Sign in')}
          </button>

          <div className="text-center">
            <button
              type="button"
              onClick={toggleMode}
              className="text-indigo-400 hover:text-indigo-300 text-sm transition-colors"
            >
              {isSignup ? 'Already have an account? Sign in' : "Don't have an account? Sign up"}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
