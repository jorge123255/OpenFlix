import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Layout } from './components/Layout'
import { LoginPage } from './pages/Login'
import { DashboardPage } from './pages/Dashboard'
import { UsersPage } from './pages/Users'
import { LibrariesPage } from './pages/Libraries'
import { MediaPage } from './pages/Media'
import { LiveTVPage } from './pages/LiveTV'
import { EPGEditorSimplePage } from './pages/EPGEditorSimple'
import { TVGuidePage } from './pages/TVGuide'
import OnLaterPage from './pages/OnLater'
import TeamPassPage from './pages/TeamPass'
import { DVRPage } from './pages/DVR'
import { VODPage } from './pages/VOD'
import { TranscodePage } from './pages/Transcode'
import { LogsPage } from './pages/Logs'
import { SettingsPage } from './pages/Settings'
import { DownloadsPage } from './pages/Downloads'
import { TunersPage } from './pages/Tuners'
import { ChannelCollectionsPage } from './pages/ChannelCollections'
import { ArtworkManagerPage } from './pages/ArtworkManager'
import { CollectionsPage } from './pages/Collections'
import { FileUploadPage } from './pages/FileUpload'
import { ClientConnectionsPage } from './pages/ClientConnections'
import { DiagnosticsPage } from './pages/Diagnostics'
import { SpeedTestPage } from './pages/SpeedTest'
import { JobQueuePage } from './pages/JobQueue'
import { VirtualChannelsPage } from './pages/VirtualChannels'
import { SegmentDetectionPage } from './pages/SegmentDetection'
import { SearchPage } from './pages/Search'
import { UpdaterPage } from './pages/Updater'
import { ComskipSettingsPage } from './pages/ComskipSettings'
import { SetupWizardPage } from './pages/SetupWizard'
import { BackupsPage } from './pages/Backups'
import { TrashPage } from './pages/Trash'
import { NotificationsPage } from './pages/Notifications'
import { SubtitlesPage } from './pages/Subtitles'
import { SchedulerPage } from './pages/Scheduler'
import { DeviceManagerPage } from './pages/DeviceManager'
import { OfflineDownloadsPage } from './pages/OfflineDownloads'
import { api } from './api/client'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30000,
      retry: 1,
    },
  },
})

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  if (!api.isAuthenticated()) {
    return <Navigate to="/ui/login" replace />
  }
  return <>{children}</>
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/ui/login" element={<LoginPage />} />
          <Route
            path="/ui"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<DashboardPage />} />
            <Route path="users" element={<UsersPage />} />
            <Route path="libraries" element={<LibrariesPage />} />
            <Route path="media" element={<MediaPage />} />
            <Route path="livetv" element={<LiveTVPage />} />
            <Route path="livetv/epg-editor" element={<EPGEditorSimplePage />} />
            <Route path="tvguide" element={<TVGuidePage />} />
            <Route path="onlater" element={<OnLaterPage />} />
            <Route path="teampass" element={<TeamPassPage />} />
            <Route path="dvr" element={<DVRPage />} />
            <Route path="vod" element={<VODPage />} />
            <Route path="transcode" element={<TranscodePage />} />
            <Route path="logs" element={<LogsPage />} />
            <Route path="settings" element={<SettingsPage />} />
            <Route path="downloads" element={<DownloadsPage />} />
            <Route path="tuners" element={<TunersPage />} />
            <Route path="channel-collections" element={<ChannelCollectionsPage />} />
            <Route path="artwork" element={<ArtworkManagerPage />} />
            <Route path="collections" element={<CollectionsPage />} />
            <Route path="upload" element={<FileUploadPage />} />
            <Route path="connections" element={<ClientConnectionsPage />} />
            <Route path="diagnostics" element={<DiagnosticsPage />} />
            <Route path="speedtest" element={<SpeedTestPage />} />
            <Route path="jobs" element={<JobQueuePage />} />
            <Route path="virtual-channels" element={<VirtualChannelsPage />} />
            <Route path="segments" element={<SegmentDetectionPage />} />
            <Route path="search" element={<SearchPage />} />
            <Route path="updater" element={<UpdaterPage />} />
            <Route path="comskip" element={<ComskipSettingsPage />} />
            <Route path="setup" element={<SetupWizardPage />} />
            <Route path="backups" element={<BackupsPage />} />
            <Route path="trash" element={<TrashPage />} />
            <Route path="notifications" element={<NotificationsPage />} />
            <Route path="subtitles" element={<SubtitlesPage />} />
            <Route path="scheduler" element={<SchedulerPage />} />
            <Route path="devices" element={<DeviceManagerPage />} />
            <Route path="offline" element={<OfflineDownloadsPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/ui" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}

export default App
