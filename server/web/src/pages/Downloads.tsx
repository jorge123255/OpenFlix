import { useQuery } from '@tanstack/react-query'
import { Download, Smartphone, Tv, Monitor, Apple, MonitorSmartphone, QrCode, CheckCircle2 } from 'lucide-react'
import { QRCodeSVG } from 'qrcode.react'
import { useState } from 'react'

interface AppDownload {
  name: string
  filename: string
  platform: string
  version: string
  size: number
  description: string
  downloadUrl: string
}

interface DownloadsResponse {
  downloads: AppDownload[]
  count: number
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

function getPlatformIcon(platform: string) {
  switch (platform) {
    case 'android':
      return <Smartphone className="h-8 w-8" />
    case 'android-tv':
      return <Tv className="h-8 w-8" />
    case 'ios':
      return <Apple className="h-8 w-8" />
    case 'macos':
      return <Apple className="h-8 w-8" />
    case 'windows':
      return <Monitor className="h-8 w-8" />
    case 'linux':
      return <MonitorSmartphone className="h-8 w-8" />
    default:
      return <Download className="h-8 w-8" />
  }
}

function getPlatformColor(platform: string): string {
  switch (platform) {
    case 'android':
    case 'android-tv':
      return 'bg-green-500/20 text-green-400 border-green-500/30'
    case 'ios':
    case 'macos':
      return 'bg-gray-500/20 text-gray-300 border-gray-500/30'
    case 'windows':
      return 'bg-blue-500/20 text-blue-400 border-blue-500/30'
    case 'linux':
      return 'bg-orange-500/20 text-orange-400 border-orange-500/30'
    default:
      return 'bg-purple-500/20 text-purple-400 border-purple-500/30'
  }
}

export function DownloadsPage() {
  const [showQRModal, setShowQRModal] = useState(false)
  const [selectedApp, setSelectedApp] = useState<AppDownload | null>(null)

  const { data, isLoading, error } = useQuery<DownloadsResponse>({
    queryKey: ['downloads'],
    queryFn: async () => {
      const response = await fetch('/downloads')
      if (!response.ok) throw new Error('Failed to fetch downloads')
      return response.json()
    },
  })

  const serverUrl = typeof window !== 'undefined' ? window.location.origin : ''

  const openQRModal = (app: AppDownload) => {
    setSelectedApp(app)
    setShowQRModal(true)
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">Download Apps</h1>
        <p className="text-gray-400 mt-1">
          Download OpenFlix apps for your devices to stream your media library
        </p>
      </div>

      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500"></div>
        </div>
      )}

      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4 text-red-400">
          Failed to load downloads. Please try again later.
        </div>
      )}

      {data && data.downloads.length === 0 && (
        <div className="text-center py-12 bg-gray-800 rounded-xl">
          <Download className="h-12 w-12 text-gray-600 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No Apps Available</h3>
          <p className="text-gray-400">
            No app downloads are currently available. Check back later.
          </p>
        </div>
      )}

      {data && data.downloads.length > 0 && (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {data.downloads.map((app) => (
            <div
              key={app.filename}
              className={`bg-gray-800 rounded-xl p-6 border ${getPlatformColor(app.platform)} hover:border-opacity-60 transition-colors`}
            >
              <div className="flex items-start gap-4 mb-4">
                <div className={`p-3 rounded-lg ${getPlatformColor(app.platform)}`}>
                  {getPlatformIcon(app.platform)}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="text-lg font-semibold text-white truncate">
                    {app.name}
                  </h3>
                  <p className="text-sm text-gray-400">
                    Version {app.version}
                  </p>
                </div>
              </div>

              <p className="text-sm text-gray-300 mb-4">
                {app.description}
              </p>

              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-500">
                  {formatFileSize(app.size)}
                </span>
                <div className="flex gap-2">
                  {(app.platform === 'android' || app.platform === 'android-tv') && (
                    <button
                      onClick={() => openQRModal(app)}
                      className="flex items-center gap-2 px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white text-sm font-medium rounded-lg transition-colors"
                      title="Send to TV"
                    >
                      <QrCode className="h-4 w-4" />
                      <span className="hidden sm:inline">Send to TV</span>
                    </button>
                  )}
                  <a
                    href={app.downloadUrl}
                    download
                    className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-lg transition-colors"
                  >
                    <Download className="h-4 w-4" />
                    Download
                  </a>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Installation Instructions */}
      <div className="mt-12">
        <h2 className="text-xl font-semibold text-white mb-6">Installation Instructions</h2>

        <div className="grid gap-6 md:grid-cols-2">
          {/* Android TV */}
          <div className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center gap-3 mb-4">
              <Tv className="h-6 w-6 text-green-400" />
              <h3 className="text-lg font-medium text-white">Android TV / Fire TV</h3>
            </div>
            <ol className="list-decimal list-inside space-y-2 text-sm text-gray-300">
              <li>Download the APK file to a USB drive or use a file manager app</li>
              <li>Enable "Install from unknown sources" in Settings {'>'} Security</li>
              <li>Use a file manager to locate and install the APK</li>
              <li>Launch OpenFlix from your apps</li>
            </ol>
          </div>

          {/* Android Phone/Tablet */}
          <div className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center gap-3 mb-4">
              <Smartphone className="h-6 w-6 text-green-400" />
              <h3 className="text-lg font-medium text-white">Android Phone / Tablet</h3>
            </div>
            <ol className="list-decimal list-inside space-y-2 text-sm text-gray-300">
              <li>Download the APK file directly on your device</li>
              <li>Open the downloaded file from your notifications or Downloads app</li>
              <li>Allow installation from this source if prompted</li>
              <li>Tap Install and wait for completion</li>
            </ol>
          </div>
        </div>
      </div>

      {/* Quick Setup Section */}
      <div className="mt-8 bg-gray-800 rounded-xl p-6">
        <h3 className="text-lg font-medium text-white mb-4">Quick Setup</h3>
        <p className="text-sm text-gray-300 mb-4">
          After installing the app, open it and enter your server address to connect:
        </p>
        <div className="bg-gray-900 rounded-lg p-4 font-mono text-indigo-400">
          {serverUrl || 'http://your-server:32400'}
        </div>
      </div>

      {/* QR Code Modal */}
      {showQRModal && selectedApp && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4"
          onClick={() => setShowQRModal(false)}
        >
          <div
            className="bg-gray-800 rounded-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="p-6 border-b border-gray-700">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-white">Send App to Your TV</h2>
                <button
                  onClick={() => setShowQRModal(false)}
                  className="text-gray-400 hover:text-white p-1"
                >
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <p className="text-gray-400 text-sm mt-1">
                Follow these easy steps to install {selectedApp.name}
              </p>
            </div>

            {/* QR Code */}
            <div className="p-6 flex flex-col items-center border-b border-gray-700">
              <div className="bg-white p-4 rounded-xl">
                <QRCodeSVG
                  value={selectedApp.downloadUrl}
                  size={180}
                  level="M"
                />
              </div>
              <p className="text-gray-400 text-sm mt-3 text-center">
                Scan with your phone to download the app
              </p>
            </div>

            {/* Steps */}
            <div className="p-6">
              <h3 className="text-white font-semibold mb-4 flex items-center gap-2">
                <Smartphone className="h-5 w-5 text-indigo-400" />
                Easy 3-Step Setup
              </h3>

              <div className="space-y-4">
                {/* Step 1 */}
                <div className="flex gap-4">
                  <div className="flex-shrink-0 w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center text-white font-bold text-sm">
                    1
                  </div>
                  <div className="flex-1">
                    <h4 className="text-white font-medium">Scan QR Code with your phone</h4>
                    <p className="text-gray-400 text-sm mt-1">
                      Use your phone's camera app to scan the QR code above. The APK will download to your phone.
                    </p>
                  </div>
                </div>

                {/* Step 2 */}
                <div className="flex gap-4">
                  <div className="flex-shrink-0 w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center text-white font-bold text-sm">
                    2
                  </div>
                  <div className="flex-1">
                    <h4 className="text-white font-medium">Install "Send Files to TV" app</h4>
                    <p className="text-gray-400 text-sm mt-1">
                      Get this free app on both your phone AND your TV from their app stores.
                    </p>
                    <div className="flex flex-wrap gap-2 mt-2">
                      <a
                        href="https://play.google.com/store/apps/details?id=com.yablio.sendfilestotv"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-xs bg-green-700 hover:bg-green-600 text-white px-3 py-1.5 rounded-lg transition-colors"
                      >
                        <Smartphone className="h-3 w-3" />
                        Android Phone
                      </a>
                      <a
                        href="https://apps.apple.com/app/send-files-to-android-tv/id6723898949"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-xs bg-gray-600 hover:bg-gray-500 text-white px-3 py-1.5 rounded-lg transition-colors"
                      >
                        <Apple className="h-3 w-3" />
                        iPhone
                      </a>
                      <a
                        href="https://play.google.com/store/apps/details?id=com.yablio.sendfilestotv"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-xs bg-indigo-700 hover:bg-indigo-600 text-white px-3 py-1.5 rounded-lg transition-colors"
                      >
                        <Tv className="h-3 w-3" />
                        Android TV
                      </a>
                    </div>
                  </div>
                </div>

                {/* Step 3 */}
                <div className="flex gap-4">
                  <div className="flex-shrink-0 w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center text-white font-bold text-sm">
                    3
                  </div>
                  <div className="flex-1">
                    <h4 className="text-white font-medium">Send the APK to your TV</h4>
                    <p className="text-gray-400 text-sm mt-1">
                      Open "Send Files to TV" on your phone, select the downloaded APK, and send it to your TV. Then install it on your TV!
                    </p>
                  </div>
                </div>
              </div>

              {/* Success hint */}
              <div className="mt-6 p-4 bg-green-500/10 border border-green-500/30 rounded-lg">
                <div className="flex gap-3">
                  <CheckCircle2 className="h-5 w-5 text-green-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <h4 className="text-green-400 font-medium text-sm">After Installation</h4>
                    <p className="text-gray-300 text-sm mt-1">
                      Open OpenFlix on your TV and enter this server address:
                    </p>
                    <code className="block mt-2 text-indigo-400 bg-gray-900 px-3 py-2 rounded text-sm">
                      {serverUrl}
                    </code>
                  </div>
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-gray-700 flex justify-between items-center">
              <a
                href={selectedApp.downloadUrl}
                download
                className="text-sm text-gray-400 hover:text-white flex items-center gap-1"
              >
                <Download className="h-4 w-4" />
                Direct download instead
              </a>
              <button
                onClick={() => setShowQRModal(false)}
                className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-lg transition-colors"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
