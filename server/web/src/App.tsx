import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Layout } from './components/Layout'
import { LoginPage } from './pages/Login'
import { DashboardPage } from './pages/Dashboard'
import { UsersPage } from './pages/Users'
import { LibrariesPage } from './pages/Libraries'
import { MediaPage } from './pages/Media'
import { LiveTVPage } from './pages/LiveTV'
import { DVRPage } from './pages/DVR'
import { SettingsPage } from './pages/Settings'
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
            <Route path="dvr" element={<DVRPage />} />
            <Route path="settings" element={<SettingsPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/ui" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}

export default App
