import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Smartphone,
  Tv,
  Monitor,
  Globe,
  Trash2,
  Shield,
  Baby,
  Eye,
  EyeOff,
  RefreshCw,
  X,
  Save,
  ChevronRight,
} from 'lucide-react'
import { api } from '../api/client'

interface ClientDevice {
  id: number
  deviceId: string
  displayName: string
  platform: string
  lastSeen: string
  ipAddress: string
  appVersion: string
  kioskMode: boolean
  kidsOnlyMode: boolean
  maxRating: string
  defaultQuality: string
  maxBitrate: number
  startupSection: string
  theme: string
  enableDVR: boolean
  enableLiveTV: boolean
  enableDownloads: boolean
  createdAt: string
  updatedAt: string
}

const PLATFORM_LABELS: Record<string, string> = {
  apple_tv: 'Apple TV',
  android_tv: 'Android TV',
  fire_tv: 'Fire TV',
  ios: 'iOS',
  android: 'Android',
  web: 'Web',
}

const RATING_OPTIONS = ['', 'G', 'PG', 'PG-13', 'R', 'NC-17']
const QUALITY_OPTIONS = ['original', 'high', 'medium', 'low']
const SECTION_OPTIONS = ['home', 'livetv', 'dvr', 'kids', 'sports']
const THEME_OPTIONS = ['dark', 'light', 'auto']

function getPlatformIcon(platform: string) {
  switch (platform) {
    case 'apple_tv':
    case 'android_tv':
    case 'fire_tv':
      return Tv
    case 'ios':
    case 'android':
      return Smartphone
    case 'web':
      return Globe
    default:
      return Monitor
  }
}

function getPlatformBadgeColor(platform: string) {
  switch (platform) {
    case 'apple_tv':
      return 'bg-gray-600 text-gray-200'
    case 'android_tv':
      return 'bg-green-600/20 text-green-400'
    case 'fire_tv':
      return 'bg-orange-600/20 text-orange-400'
    case 'ios':
      return 'bg-blue-600/20 text-blue-400'
    case 'android':
      return 'bg-green-600/20 text-green-400'
    case 'web':
      return 'bg-purple-600/20 text-purple-400'
    default:
      return 'bg-gray-600/20 text-gray-400'
  }
}

function formatLastSeen(lastSeen: string) {
  const d = new Date(lastSeen)
  const now = new Date()
  const diff = now.getTime() - d.getTime()

  if (diff < 60000) return 'Just now'
  if (diff < 3600000) return `${Math.round(diff / 60000)}m ago`
  if (diff < 86400000) return `${Math.round(diff / 3600000)}h ago`
  if (diff < 604800000) return `${Math.round(diff / 86400000)}d ago`
  return d.toLocaleDateString()
}

function isOnline(lastSeen: string) {
  const diff = new Date().getTime() - new Date(lastSeen).getTime()
  return diff < 300000 // 5 minutes
}

export function DeviceManagerPage() {
  const queryClient = useQueryClient()
  const [selectedDevice, setSelectedDevice] = useState<ClientDevice | null>(null)
  const [editForm, setEditForm] = useState<Partial<ClientDevice>>({})
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null)

  const { data: devices, isLoading } = useQuery({
    queryKey: ['devices'],
    queryFn: async () => {
      const res = await api.client.get('/api/devices')
      return (res.data?.devices || []) as ClientDevice[]
    },
    refetchInterval: 10000,
  })

  const updateDevice = useMutation({
    mutationFn: async ({ id, ...data }: { id: number } & Partial<ClientDevice>) => {
      const res = await api.client.put(`/api/devices/${id}`, data)
      return res.data as ClientDevice
    },
    onSuccess: (updated) => {
      queryClient.invalidateQueries({ queryKey: ['devices'] })
      setSelectedDevice(updated)
      setEditForm({})
    },
  })

  const deleteDevice = useMutation({
    mutationFn: async (id: number) => {
      await api.client.delete(`/api/devices/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['devices'] })
      setSelectedDevice(null)
      setDeleteConfirm(null)
    },
  })

  const openDeviceEditor = (device: ClientDevice) => {
    setSelectedDevice(device)
    setEditForm({
      displayName: device.displayName,
      kioskMode: device.kioskMode,
      kidsOnlyMode: device.kidsOnlyMode,
      maxRating: device.maxRating,
      defaultQuality: device.defaultQuality,
      maxBitrate: device.maxBitrate,
      startupSection: device.startupSection,
      theme: device.theme,
      enableDVR: device.enableDVR,
      enableLiveTV: device.enableLiveTV,
      enableDownloads: device.enableDownloads,
    })
  }

  const handleSave = () => {
    if (!selectedDevice) return
    updateDevice.mutate({ id: selectedDevice.id, ...editForm })
  }

  if (isLoading) return <div className="text-gray-400">Loading devices...</div>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Device Manager</h1>
          <p className="text-gray-400 mt-1">
            Manage client devices, kiosk mode, kids-only restrictions, and per-device settings
          </p>
        </div>
        <button
          onClick={() => queryClient.invalidateQueries({ queryKey: ['devices'] })}
          className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
        >
          <RefreshCw className="h-4 w-4" /> Refresh
        </button>
      </div>

      <div className="flex gap-6">
        {/* Device List */}
        <div className={`${selectedDevice ? 'w-1/2' : 'w-full'} space-y-3 transition-all`}>
          {!devices || devices.length === 0 ? (
            <div className="bg-gray-800 rounded-xl p-12 text-center">
              <Smartphone className="h-12 w-12 text-gray-600 mx-auto mb-3" />
              <p className="text-gray-400 font-medium">No devices registered yet</p>
              <p className="text-gray-500 text-sm mt-1">
                Devices appear here when a client app connects and registers with the server.
              </p>
            </div>
          ) : (
            devices.map((device) => {
              const PlatformIcon = getPlatformIcon(device.platform)
              const online = isOnline(device.lastSeen)
              const isSelected = selectedDevice?.id === device.id

              return (
                <button
                  key={device.id}
                  onClick={() => openDeviceEditor(device)}
                  className={`w-full text-left bg-gray-800 rounded-xl p-4 hover:bg-gray-750 transition-colors border-2 ${
                    isSelected ? 'border-indigo-500' : 'border-transparent'
                  }`}
                >
                  <div className="flex items-center gap-4">
                    <div className={`p-2.5 rounded-lg ${online ? 'bg-green-500/10' : 'bg-gray-700'}`}>
                      <PlatformIcon className={`h-5 w-5 ${online ? 'text-green-400' : 'text-gray-500'}`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <h3 className="text-white font-semibold truncate">{device.displayName || 'Unnamed Device'}</h3>
                        {device.kioskMode && (
                          <span className="flex items-center gap-1 text-xs px-1.5 py-0.5 bg-yellow-500/20 text-yellow-400 rounded-full">
                            <EyeOff className="h-3 w-3" />Kiosk
                          </span>
                        )}
                        {device.kidsOnlyMode && (
                          <span className="flex items-center gap-1 text-xs px-1.5 py-0.5 bg-pink-500/20 text-pink-400 rounded-full">
                            <Baby className="h-3 w-3" />Kids
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-3 mt-1 text-xs text-gray-500">
                        <span className={`px-1.5 py-0.5 rounded ${getPlatformBadgeColor(device.platform)}`}>
                          {PLATFORM_LABELS[device.platform] || device.platform || 'Unknown'}
                        </span>
                        <span>{device.ipAddress}</span>
                        <span>{formatLastSeen(device.lastSeen)}</span>
                        {device.appVersion && <span>v{device.appVersion}</span>}
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className={`h-2 w-2 rounded-full ${online ? 'bg-green-400' : 'bg-gray-600'}`} />
                      <ChevronRight className="h-4 w-4 text-gray-600" />
                    </div>
                  </div>
                </button>
              )
            })
          )}
        </div>

        {/* Device Editor Panel */}
        {selectedDevice && (
          <div className="w-1/2 bg-gray-800 rounded-xl p-6 h-fit sticky top-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-white">Device Settings</h2>
              <button
                onClick={() => {
                  setSelectedDevice(null)
                  setEditForm({})
                }}
                className="p-1 text-gray-400 hover:text-white transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-5">
              {/* Display Name */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">Display Name</label>
                <input
                  type="text"
                  value={editForm.displayName || ''}
                  onChange={(e) => setEditForm({ ...editForm, displayName: e.target.value })}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  placeholder="e.g., Living Room Apple TV"
                />
              </div>

              {/* Device Info (read-only) */}
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div>
                  <span className="text-gray-500">Device ID</span>
                  <p className="text-gray-300 font-mono text-xs truncate">{selectedDevice.deviceId}</p>
                </div>
                <div>
                  <span className="text-gray-500">Platform</span>
                  <p className="text-gray-300">{PLATFORM_LABELS[selectedDevice.platform] || selectedDevice.platform}</p>
                </div>
                <div>
                  <span className="text-gray-500">IP Address</span>
                  <p className="text-gray-300">{selectedDevice.ipAddress}</p>
                </div>
                <div>
                  <span className="text-gray-500">Last Seen</span>
                  <p className="text-gray-300">{new Date(selectedDevice.lastSeen).toLocaleString()}</p>
                </div>
              </div>

              <hr className="border-gray-700" />

              {/* Kiosk Mode */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-yellow-500/10 rounded-lg">
                    <EyeOff className="h-4 w-4 text-yellow-400" />
                  </div>
                  <div>
                    <p className="text-white text-sm font-medium">Kiosk Mode</p>
                    <p className="text-gray-500 text-xs">Hides settings and admin features on this device</p>
                  </div>
                </div>
                <button
                  onClick={() => setEditForm({ ...editForm, kioskMode: !editForm.kioskMode })}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    editForm.kioskMode ? 'bg-yellow-500' : 'bg-gray-600'
                  }`}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      editForm.kioskMode ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>

              {/* Kids Only Mode */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-pink-500/10 rounded-lg">
                    <Baby className="h-4 w-4 text-pink-400" />
                  </div>
                  <div>
                    <p className="text-white text-sm font-medium">Kids Only Mode</p>
                    <p className="text-gray-500 text-xs">Restricts content to kids-rated only (full UI lockdown)</p>
                  </div>
                </div>
                <button
                  onClick={() => setEditForm({ ...editForm, kidsOnlyMode: !editForm.kidsOnlyMode })}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    editForm.kidsOnlyMode ? 'bg-pink-500' : 'bg-gray-600'
                  }`}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      editForm.kidsOnlyMode ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>

              {/* Max Rating */}
              <div>
                <label className="flex items-center gap-2 text-sm font-medium text-gray-300 mb-1">
                  <Shield className="h-4 w-4 text-indigo-400" />
                  Max Content Rating
                </label>
                <select
                  value={editForm.maxRating || ''}
                  onChange={(e) => setEditForm({ ...editForm, maxRating: e.target.value })}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="">No Limit</option>
                  {RATING_OPTIONS.filter(r => r !== '').map((r) => (
                    <option key={r} value={r}>{r}</option>
                  ))}
                </select>
                <p className="text-xs text-gray-500 mt-1">Overrides user profile rating. Leave empty for no restriction.</p>
              </div>

              <hr className="border-gray-700" />

              {/* Playback */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1">Default Quality</label>
                  <select
                    value={editForm.defaultQuality || 'original'}
                    onChange={(e) => setEditForm({ ...editForm, defaultQuality: e.target.value })}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    {QUALITY_OPTIONS.map((q) => (
                      <option key={q} value={q}>{q.charAt(0).toUpperCase() + q.slice(1)}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1">Startup Section</label>
                  <select
                    value={editForm.startupSection || 'home'}
                    onChange={(e) => setEditForm({ ...editForm, startupSection: e.target.value })}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    {SECTION_OPTIONS.map((s) => (
                      <option key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">Theme</label>
                <select
                  value={editForm.theme || 'dark'}
                  onChange={(e) => setEditForm({ ...editForm, theme: e.target.value })}
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  {THEME_OPTIONS.map((t) => (
                    <option key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</option>
                  ))}
                </select>
              </div>

              <hr className="border-gray-700" />

              {/* Feature Toggles */}
              <div>
                <h4 className="text-sm font-medium text-gray-300 mb-3 flex items-center gap-2">
                  <Eye className="h-4 w-4 text-indigo-400" />
                  Feature Toggles
                </h4>
                <div className="space-y-3">
                  {[
                    { key: 'enableDVR' as const, label: 'DVR Recording', desc: 'Allow DVR recording features' },
                    { key: 'enableLiveTV' as const, label: 'Live TV', desc: 'Allow live TV streaming' },
                    { key: 'enableDownloads' as const, label: 'Downloads', desc: 'Allow content downloads' },
                  ].map(({ key, label, desc }) => (
                    <div key={key} className="flex items-center justify-between">
                      <div>
                        <p className="text-white text-sm">{label}</p>
                        <p className="text-gray-500 text-xs">{desc}</p>
                      </div>
                      <button
                        onClick={() => setEditForm({ ...editForm, [key]: !editForm[key] })}
                        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                          editForm[key] ? 'bg-indigo-500' : 'bg-gray-600'
                        }`}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                            editForm[key] ? 'translate-x-6' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </div>
                  ))}
                </div>
              </div>

              <hr className="border-gray-700" />

              {/* Actions */}
              <div className="flex items-center justify-between pt-2">
                <button
                  onClick={() => setDeleteConfirm(selectedDevice.id)}
                  className="flex items-center gap-2 px-3 py-2 text-sm text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-lg transition-colors"
                >
                  <Trash2 className="h-4 w-4" /> Delete Device
                </button>
                <button
                  onClick={handleSave}
                  disabled={updateDevice.isPending}
                  className="flex items-center gap-2 px-4 py-2 text-sm bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-lg transition-colors"
                >
                  <Save className="h-4 w-4" />
                  {updateDevice.isPending ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </div>

            {/* Delete Confirmation */}
            {deleteConfirm !== null && (
              <div className="mt-4 p-4 bg-red-500/10 border border-red-500/30 rounded-lg">
                <p className="text-red-400 text-sm mb-3">
                  Are you sure you want to remove this device? The device can re-register on its next connection.
                </p>
                <div className="flex justify-end gap-2">
                  <button
                    onClick={() => setDeleteConfirm(null)}
                    className="px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 text-white rounded-lg"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => deleteDevice.mutate(deleteConfirm)}
                    disabled={deleteDevice.isPending}
                    className="px-3 py-1.5 text-sm bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white rounded-lg"
                  >
                    {deleteDevice.isPending ? 'Deleting...' : 'Delete'}
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
