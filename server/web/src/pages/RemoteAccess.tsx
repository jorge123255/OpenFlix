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
  const [awaitingLoginUrl, setAwaitingLoginUrl] = useState(false)

  const { data: status, isLoading: statusLoading, refetch: refetchStatus } = useQuery({
    queryKey: ['remoteAccessStatus'],
    queryFn: () => api.getRemoteAccessStatus(),
    refetchInterval: awaitingLoginUrl ? 3000 : 30000,
  })

  const enableMutation = useMutation({
    mutationFn: (key?: string) => api.enableRemoteAccess(key || undefined),
    onSuccess: () => {
      setAuthKey('')
      setShowAuthKey(false)
      // If no auth key, tailscale up runs in background — poll frequently for login URL
      if (!authKey) {
        setAwaitingLoginUrl(true)
        setTimeout(() => {
          refetchStatus()
          setTimeout(() => {
            refetchStatus()
            setAwaitingLoginUrl(false)
          }, 5000)
        }, 3000)
      } else {
        queryClient.invalidateQueries({ queryKey: ['remoteAccessStatus'] })
      }
    },
  })

  const disableMutation = useMutation({
    mutationFn: () => api.disableRemoteAccess(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['remoteAccessStatus'] })
    },
  })

  // Stop fast-polling once we have a login URL
  useEffect(() => {
    if (awaitingLoginUrl && status?.loginUrl) {
      setAwaitingLoginUrl(false)
    }
  }, [status?.loginUrl, awaitingLoginUrl])

  const isNotInstalled = status?.status === 'not_installed'
  const isConnected = status?.status === 'connected'
  const needsLogin = status?.status === 'needs_login'
  const isDisconnected = !status || ['disconnected', 'not_running', 'Stopped'].includes(status.status ?? '')

  return (
    <SettingSection
      title="Tailscale VPN"
      icon={<Wifi className="h-5 w-5 text-indigo-400" />}
    >
      {/* What is Tailscale */}
      <div className="p-4 rounded-lg bg-gray-900 border border-gray-700 text-sm text-gray-400 space-y-1">
        <p className="text-gray-300 font-medium">What is Tailscale?</p>
        <p>Tailscale creates an encrypted private network between your server and your devices — no port forwarding needed. Once connected, you can reach your OpenFlix server securely from anywhere in the world using its Tailscale IP address.</p>
        <p className="text-xs text-gray-500 mt-1">Tailscale is free for personal use (up to 3 users / 100 devices). <span className="text-indigo-400">tailscale.com</span></p>
      </div>

      {statusLoading && (
        <div className="flex items-center gap-2 text-gray-400 text-sm">
          <Loader className="h-4 w-4 animate-spin" />
          Checking Tailscale status...
        </div>
      )}

      {status && (
        <div className="space-y-4">
          {/* Status badge */}
          <div className="flex items-center gap-3">
            {isConnected ? (
              <CheckCircle className="h-5 w-5 text-green-400" />
            ) : needsLogin ? (
              <Loader className="h-5 w-5 text-yellow-400" />
            ) : isNotInstalled ? (
              <XCircle className="h-5 w-5 text-gray-500" />
            ) : (
              <XCircle className="h-5 w-5 text-red-400" />
            )}
            <div>
              <p className={`text-sm font-medium ${
                isConnected ? 'text-green-400' :
                needsLogin ? 'text-yellow-400' :
                isNotInstalled ? 'text-gray-400' :
                'text-red-400'
              }`}>
                {isConnected ? 'Connected' :
                 needsLogin ? 'Waiting for login' :
                 isNotInstalled ? 'Not installed' :
                 'Disconnected'}
              </p>
              {status.tailscaleIp && (
                <p className="text-xs text-gray-500 mt-0.5">Tailscale IP: {status.tailscaleIp}</p>
              )}
              {status.hostname && (
                <p className="text-xs text-gray-500">Hostname: {status.hostname}</p>
              )}
              {status.magicDnsName && (
                <p className="text-xs text-gray-500">MagicDNS: {status.magicDnsName}</p>
              )}
            </div>
          </div>

          {/* Not installed */}
          {isNotInstalled && (
            <div className="p-4 rounded-lg bg-gray-900 border border-gray-600">
              <p className="text-sm text-gray-300 mb-2">Tailscale is not installed in the server container.</p>
              <p className="text-xs text-gray-500">The OpenFlix Docker image includes Tailscale. If you see this message, ensure you are running the latest image version.</p>
            </div>
          )}

          {/* Login URL — shown automatically when Tailscale needs auth */}
          {(needsLogin || awaitingLoginUrl || status.loginUrl) && (
            <div className="p-4 rounded-lg bg-yellow-500/10 border border-yellow-500/30 space-y-3">
              {awaitingLoginUrl && !status.loginUrl ? (
                <div className="flex items-center gap-2 text-yellow-400 text-sm">
                  <Loader className="h-4 w-4 animate-spin" />
                  Generating login URL...
                </div>
              ) : status.loginUrl ? (
                <>
                  <p className="text-sm text-yellow-300 font-medium">Action required: Log in to Tailscale</p>
                  <p className="text-xs text-gray-400">
                    Open the link below in your browser to authenticate this server with your Tailscale account. After logging in, the status above will update automatically.
                  </p>
                  <a
                    href={status.loginUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-4 py-2.5 bg-yellow-600 hover:bg-yellow-500 text-white rounded-lg text-sm font-medium transition-colors w-fit"
                  >
                    <ExternalLink className="h-4 w-4" />
                    Open Tailscale Login
                  </a>
                  <div className="flex items-center gap-2">
                    <code className="flex-1 px-3 py-1.5 bg-gray-900 rounded-lg text-xs text-gray-300 font-mono break-all">
                      {status.loginUrl}
                    </code>
                    <CopyButton text={status.loginUrl} />
                  </div>
                </>
              ) : null}
            </div>
          )}

          {/* Connected state — show URLs */}
          {isConnected && (
            <div className="p-3 bg-green-500/10 border border-green-500/20 rounded-lg space-y-1">
              <p className="text-xs font-medium text-green-400 mb-1">Access your server via Tailscale:</p>
              {status.tailscaleIp && (
                <div className="flex items-center gap-2">
                  <code className="text-xs text-gray-300 font-mono">{`http://${status.tailscaleIp}:32400`}</code>
                  <CopyButton text={`http://${status.tailscaleIp}:32400`} />
                </div>
              )}
              {status.magicDnsName && (
                <div className="flex items-center gap-2">
                  <code className="text-xs text-gray-300 font-mono">{status.magicDnsName}</code>
                  <CopyButton text={status.magicDnsName} />
                </div>
              )}
            </div>
          )}

          {/* Enable / Disable buttons */}
          <div className="pt-2">
            {isDisconnected || needsLogin ? (
              <div className="space-y-3">
                {!needsLogin && (
                  <>
                    {showAuthKey ? (
                      <div>
                        <label className="block text-sm font-medium text-gray-300 mb-1">
                          Auth Key (optional)
                        </label>
                        <p className="text-xs text-gray-500 mb-2">
                          Provide a pre-generated Tailscale auth key for headless setup. Without a key, a browser login URL will be generated instead.
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
                        Use auth key instead of browser login
                      </button>
                    )}
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
                      {enableMutation.isPending ? 'Starting...' : 'Enable Tailscale'}
                    </button>
                  </>
                )}
                {enableMutation.isError && (
                  <p className="text-sm text-red-400">Failed to start Tailscale. Check server logs.</p>
                )}
              </div>
            ) : isConnected ? (
              <button
                onClick={() => {
                  if (confirm('Disable Tailscale? You will no longer be able to access this server remotely via Tailscale.')) {
                    disableMutation.mutate()
                  }
                }}
                disabled={disableMutation.isPending}
                className="flex items-center gap-2 px-4 py-2 bg-red-600/80 hover:bg-red-600 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
              >
                {disableMutation.isPending ? (
                  <Loader className="h-4 w-4 animate-spin" />
                ) : (
                  <XCircle className="h-4 w-4" />
                )}
                Disconnect Tailscale
              </button>
            ) : null}
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
      title="External URL Override"
      icon={<Link className="h-5 w-5 text-indigo-400" />}
    >
      {/* Explanation */}
      <div className="p-4 rounded-lg bg-gray-900 border border-gray-700 text-sm text-gray-400 space-y-1">
        <p className="text-gray-300 font-medium">When do you need this?</p>
        <p>Most users don't need to set this. It's only needed if you have a custom domain or reverse proxy (e.g. <span className="text-gray-300 font-mono">openflix.yourdomain.com</span>) and want the app to connect via that address instead of your local or Tailscale IP.</p>
        <p className="text-xs text-gray-500 mt-1">If you're using Tailscale, the Tailscale IP/MagicDNS URL is used automatically — no override needed.</p>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1">Custom External URL</label>
        <p className="text-xs text-gray-500 mb-2">
          Override the URL the app uses to connect from outside your home network. Leave blank for automatic detection.
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
