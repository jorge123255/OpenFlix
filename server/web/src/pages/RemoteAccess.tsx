import { useState, useEffect } from 'react'
import {
  Globe,
  Wifi,
  Link,
  Key,
  Shield,
  RefreshCw,
  CheckCircle,
  XCircle,
  Loader,
  Copy,
  ExternalLink,
  Save,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type LicenseStatus, type DiscoverySettings } from '../api/client'

function SettingSection({ title, icon, children }: { title: string; icon?: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="bg-gray-800 rounded-xl p-6 mb-6">
      <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        {icon}
        {title}
      </h2>
      <div className="space-y-4">{children}</div>
    </div>
  )
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

function CloudDiscoverySection() {
  const queryClient = useQueryClient()
  const [keyInput, setKeyInput] = useState('')
  const [keySaved, setKeySaved] = useState(false)

  const { data: discovery, isLoading: discoveryLoading } = useQuery<DiscoverySettings>({
    queryKey: ['discoverySettings'],
    queryFn: () => api.getDiscoverySettings(),
    refetchInterval: (q) => (q.state.data?.enabled ? 15000 : false),
    retry: 1,
  })

  const { data: licenseData } = useQuery<LicenseStatus>({
    queryKey: ['licenseStatus'],
    queryFn: () => api.getLicense(),
    retry: 1,
  })

  const { data: claimToken, isLoading: claimLoading, refetch: refetchClaim } = useQuery({
    queryKey: ['claimToken'],
    queryFn: () => api.getClaimToken(),
    enabled: false,
  })

  useEffect(() => {
    if (licenseData?.key) setKeyInput(licenseData.key)
  }, [licenseData])

  const toggleDiscovery = useMutation({
    mutationFn: (enabled: boolean) => api.setDiscoveryEnabled(enabled),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['discoverySettings'] }),
  })

  const saveLicense = useMutation({
    mutationFn: (key: string) => api.saveLicense(key),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['licenseStatus'] })
      setKeySaved(true)
      setTimeout(() => setKeySaved(false), 3000)
    },
  })

  const enabled = discovery?.enabled ?? false

  return (
    <SettingSection
      title="Away From Home (Cloud Discovery)"
      icon={<Globe className="h-5 w-5 text-indigo-400" />}
    >
      {/* Enable toggle */}
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-300">Enable Cloud Discovery</p>
          <p className="text-xs text-gray-500 mt-0.5">
            Allows the OpenFlix app to find this server when away from home.{' '}
            <span className="text-yellow-400">Paid feature.</span>
          </p>
        </div>
        {discoveryLoading ? (
          <Loader className="h-4 w-4 animate-spin text-gray-400" />
        ) : (
          <button
            type="button"
            role="switch"
            aria-checked={enabled}
            disabled={toggleDiscovery.isPending}
            onClick={() => toggleDiscovery.mutate(!enabled)}
            className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors disabled:opacity-50 ${
              enabled ? 'bg-indigo-600' : 'bg-gray-600'
            }`}
          >
            <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${enabled ? 'translate-x-6' : 'translate-x-1'}`} />
          </button>
        )}
      </div>

      {/* License key — always visible so user can enter key before enabling */}
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1 flex items-center gap-1.5">
          <Key className="h-3.5 w-3.5 text-yellow-400" />
          License Key
        </label>
        <div className="flex gap-2">
          <input
            type="text"
            value={keyInput}
            onChange={(e) => setKeyInput(e.target.value)}
            className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white font-mono text-sm"
            placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            spellCheck={false}
          />
          <button
            onClick={() => saveLicense.mutate(keyInput)}
            disabled={saveLicense.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white rounded-lg whitespace-nowrap"
          >
            {saveLicense.isPending ? <Loader className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            {saveLicense.isPending ? 'Saving...' : keySaved ? 'Saved!' : 'Save'}
          </button>
        </div>
        {licenseData && licenseData.status !== 'not_set' && (
          <div className={`flex items-center gap-2 mt-2 p-2.5 rounded-lg text-sm ${
            licenseData.status === 'valid' ? 'bg-green-500/10 border border-green-500/30' : 'bg-red-500/10 border border-red-500/30'
          }`}>
            {licenseData.status === 'valid'
              ? <CheckCircle className="h-4 w-4 text-green-400 flex-shrink-0" />
              : <XCircle className="h-4 w-4 text-red-400 flex-shrink-0" />}
            <span className={licenseData.status === 'valid' ? 'text-green-400' : 'text-red-400'}>
              {licenseData.status === 'valid' ? 'Valid' : 'Invalid key'}
            </span>
            {licenseData.masked && <span className="text-xs text-gray-500 ml-1 font-mono">{licenseData.masked}</span>}
          </div>
        )}
        <p className="text-xs text-gray-500 mt-1.5">
          Get a license key at <span className="text-indigo-400">discover.openflix.io/admin</span>
        </p>
      </div>

      {/* Connection status */}
      <div className="flex items-center justify-between p-3 bg-gray-900 rounded-lg">
        <div>
          <p className="text-sm font-medium text-gray-300">Registry Connection</p>
          {discovery?.publicIp && (
            <p className="text-xs text-gray-500 mt-0.5">Public IP: {discovery.publicIp}</p>
          )}
        </div>
        <div className="flex items-center gap-2">
          {discovery?.connected ? (
            <>
              <div className="h-2 w-2 rounded-full bg-green-400 animate-pulse" />
              <span className="text-sm text-green-400">Connected</span>
            </>
          ) : (
            <>
              <div className="h-2 w-2 rounded-full bg-gray-500" />
              <span className="text-sm text-gray-500">
                {licenseData?.status === 'valid' ? 'Connecting...' : 'Waiting for license'}
              </span>
            </>
          )}
        </div>
      </div>

      {/* Claim code for app pairing */}
      {enabled && (
        <div className="space-y-3 pt-2 border-t border-gray-700">
          <div>
            <p className="text-sm font-medium text-gray-300 mb-1">App Pairing Code</p>
            <p className="text-xs text-gray-500 mb-3">
              Generate a 4-character code to pair the OpenFlix app with this server when away from home.
            </p>
            <button
              onClick={() => refetchClaim()}
              disabled={claimLoading}
              className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white rounded-lg text-sm transition-colors disabled:opacity-50"
            >
              {claimLoading ? <Loader className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
              Generate Claim Code
            </button>
          </div>

          {claimToken && (
            <div className="p-4 rounded-lg bg-indigo-500/10 border border-indigo-500/20">
              <div className="flex items-center gap-2 mb-2">
                <Key className="h-4 w-4 text-indigo-400" />
                <p className="text-sm font-medium text-indigo-300">Claim Code</p>
              </div>
              <p className="text-xs text-gray-400 mb-3">
                Enter this code in the OpenFlix app under "Away from Home" to connect.
              </p>
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-2">
                  {claimToken.token.split('').map((char, i) => (
                    <div key={i} className="h-10 w-10 bg-gray-900 border border-indigo-500/40 rounded-lg flex items-center justify-center text-white text-lg font-bold font-mono">
                      {char.toUpperCase()}
                    </div>
                  ))}
                </div>
                <CopyButton text={claimToken.token.toUpperCase()} />
              </div>
              <p className="text-xs text-gray-500 mt-2">
                Expires: {new Date(claimToken.expiresAt).toLocaleString()}
              </p>
            </div>
          )}
        </div>
      )}
    </SettingSection>
  )
}

function TailscaleSection() {
  const queryClient = useQueryClient()
  const [authKey, setAuthKey] = useState('')
  const [showAuthKey, setShowAuthKey] = useState(false)

  const { data: status, isLoading: statusLoading } = useQuery({
    queryKey: ['remoteAccessStatus'],
    queryFn: () => api.getRemoteAccessStatus(),
    refetchInterval: 15000,
  })

  const { data: loginUrl, isLoading: loginUrlLoading, refetch: fetchLoginUrl } = useQuery({
    queryKey: ['remoteAccessLoginUrl'],
    queryFn: () => api.getRemoteAccessLoginUrl(),
    enabled: false,
  })

  const enableMutation = useMutation({
    mutationFn: (key?: string) => api.enableRemoteAccess(key || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['remoteAccessStatus'] })
      setAuthKey('')
      setShowAuthKey(false)
    },
  })

  const disableMutation = useMutation({
    mutationFn: () => api.disableRemoteAccess(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['remoteAccessStatus'] })
    },
  })

  const isConnected = status?.status === 'connected'
  const needsLogin = status?.status === 'needs_login'
  const isDisconnected = !status || status.status === 'disconnected' || status.status === 'not_running'

  return (
    <SettingSection
      title="Tailscale Remote Access"
      icon={<Wifi className="h-5 w-5 text-indigo-400" />}
    >
      {statusLoading && (
        <div className="flex items-center gap-2 text-gray-400 text-sm">
          <Loader className="h-4 w-4 animate-spin" />
          Checking Tailscale status...
        </div>
      )}

      {status && (
        <div className="space-y-4">
          <div className="flex items-center gap-3">
            {isConnected ? (
              <CheckCircle className="h-5 w-5 text-green-400" />
            ) : needsLogin ? (
              <XCircle className="h-5 w-5 text-yellow-400" />
            ) : (
              <XCircle className="h-5 w-5 text-red-400" />
            )}
            <div>
              <p
                className={`text-sm font-medium ${
                  isConnected
                    ? 'text-green-400'
                    : needsLogin
                    ? 'text-yellow-400'
                    : 'text-red-400'
                }`}
              >
                {isConnected
                  ? 'Connected'
                  : needsLogin
                  ? 'Needs Login'
                  : 'Disconnected'}
              </p>
              {status.tailscaleIp && (
                <p className="text-xs text-gray-500 mt-0.5">Tailscale IP: {status.tailscaleIp}</p>
              )}
              {status.hostname && (
                <p className="text-xs text-gray-500">Hostname: {status.hostname}</p>
              )}
            </div>
          </div>

          {needsLogin && (
            <div className="p-4 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
              <p className="text-sm text-yellow-400 mb-3">
                Tailscale requires authentication. Click below to get the login URL.
              </p>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => fetchLoginUrl()}
                  disabled={loginUrlLoading}
                  className="flex items-center gap-2 px-4 py-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
                >
                  {loginUrlLoading ? (
                    <Loader className="h-4 w-4 animate-spin" />
                  ) : (
                    <ExternalLink className="h-4 w-4" />
                  )}
                  Get Login URL
                </button>
                {loginUrl?.url && (
                  <a
                    href={loginUrl.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm transition-colors"
                  >
                    <ExternalLink className="h-4 w-4" />
                    Open Login Page
                  </a>
                )}
              </div>
              {loginUrl?.url && (
                <div className="mt-2 flex items-center gap-2">
                  <code className="flex-1 px-3 py-1.5 bg-gray-900 rounded-lg text-xs text-gray-300 font-mono truncate">
                    {loginUrl.url}
                  </code>
                  <CopyButton text={loginUrl.url} />
                </div>
              )}
            </div>
          )}

          {status.loginUrl && (
            <div className="p-4 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
              <p className="text-sm text-yellow-400 mb-2">Authenticate Tailscale:</p>
              <a
                href={status.loginUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 text-sm text-indigo-400 hover:text-indigo-300"
              >
                <ExternalLink className="h-4 w-4" />
                {status.loginUrl}
              </a>
            </div>
          )}

          <div className="flex items-center gap-3 pt-2">
            {isDisconnected || needsLogin ? (
              <div className="space-y-3 w-full">
                {showAuthKey ? (
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">
                      Auth Key (optional)
                    </label>
                    <p className="text-xs text-gray-500 mb-2">
                      Provide a Tailscale auth key for headless authentication, or leave blank to use the login URL.
                    </p>
                    <input
                      type="password"
                      value={authKey}
                      onChange={(e) => setAuthKey(e.target.value)}
                      placeholder="tskey-auth-..."
                      className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm"
                    />
                  </div>
                ) : (
                  <button
                    onClick={() => setShowAuthKey(true)}
                    className="text-xs text-gray-400 hover:text-gray-300 underline"
                  >
                    Use auth key instead
                  </button>
                )}
                <div className="flex gap-2">
                  <button
                    onClick={() => enableMutation.mutate(authKey || undefined)}
                    disabled={enableMutation.isPending}
                    className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
                  >
                    {enableMutation.isPending ? (
                      <Loader className="h-4 w-4 animate-spin" />
                    ) : (
                      <Wifi className="h-4 w-4" />
                    )}
                    Enable Tailscale
                  </button>
                </div>
                {enableMutation.isError && (
                  <p className="text-sm text-red-400">Failed to enable Tailscale. Check server logs.</p>
                )}
              </div>
            ) : (
              <button
                onClick={() => {
                  if (confirm('Disable Tailscale remote access?')) {
                    disableMutation.mutate()
                  }
                }}
                disabled={disableMutation.isPending}
                className="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
              >
                {disableMutation.isPending ? (
                  <Loader className="h-4 w-4 animate-spin" />
                ) : (
                  <XCircle className="h-4 w-4" />
                )}
                Disable Tailscale
              </button>
            )}
          </div>
        </div>
      )}

      {!statusLoading && !status && (
        <p className="text-sm text-gray-400">Could not load Tailscale status.</p>
      )}
    </SettingSection>
  )
}

function ExternalUrlSection() {
  const queryClient = useQueryClient()
  const [externalUrl, setExternalUrl] = useState('')
  const [saved, setSaved] = useState(false)

  const { data: config, isLoading: configLoading } = useQuery({
    queryKey: ['serverConfig'],
    queryFn: () => api.getServerConfig(),
  })

  const updateConfig = useMutation({
    mutationFn: (url: string) => api.updateServerConfig({ external_url: url }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['serverConfig'] })
      setSaved(true)
      setTimeout(() => setSaved(false), 2000)
    },
  })

  // Sync local state with fetched config
  const configExternalUrl = config?.external_url ?? ''
  const displayUrl = externalUrl !== '' || saved ? externalUrl : configExternalUrl

  return (
    <SettingSection
      title="External URL"
      icon={<Link className="h-5 w-5 text-indigo-400" />}
    >
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1">Custom External URL</label>
        <p className="text-xs text-gray-500 mb-2">
          Set a custom URL for clients to use when connecting to your server externally. Leave blank to use auto-detected values.
        </p>
        {configLoading ? (
          <div className="flex items-center gap-2 text-gray-400 text-sm">
            <Loader className="h-4 w-4 animate-spin" />
            Loading...
          </div>
        ) : (
          <div className="flex gap-2">
            <input
              type="url"
              value={displayUrl}
              onChange={(e) => setExternalUrl(e.target.value)}
              placeholder="https://my-server.example.com:32400"
              className="flex-1 px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500"
            />
            <button
              onClick={() => updateConfig.mutate(displayUrl)}
              disabled={updateConfig.isPending}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
            >
              {updateConfig.isPending ? (
                <Loader className="h-4 w-4 animate-spin" />
              ) : saved ? (
                <CheckCircle className="h-4 w-4" />
              ) : null}
              {saved ? 'Saved!' : 'Save'}
            </button>
          </div>
        )}
        {updateConfig.isError && (
          <p className="text-sm text-red-400 mt-2">Failed to save external URL.</p>
        )}
      </div>
    </SettingSection>
  )
}

export function RemoteAccessPage() {
  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white flex items-center gap-3">
          <Shield className="h-7 w-7 text-indigo-400" />
          Remote Access
        </h1>
        <p className="text-gray-400 mt-1">
          Configure how clients connect to your server from outside your home network
        </p>
      </div>

      <CloudDiscoverySection />
      <TailscaleSection />
      <ExternalUrlSection />
    </div>
  )
}
