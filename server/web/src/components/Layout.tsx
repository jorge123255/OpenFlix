import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard,
  Users,
  FolderOpen,
  Film,
  Tv,
  Video,
  FileText,
  Settings,
  LogOut,
  Menu,
  X,
  Cpu,
  CalendarDays,
  Download,
  Clock,
  Trophy,
  CloudDownload,
  Radio,
  Layers,
  Image,
  FolderHeart,
  Upload,
  MonitorSmartphone,
  Activity,
  Gauge,
  ListTodo,
  TvMinimal,
  Scissors,
  Search,
  RefreshCw,
  SlidersHorizontal,
  DatabaseBackup,
  Trash2,
  ChevronDown,
  type LucideIcon,
} from 'lucide-react'
import { useState } from 'react'
import { useCurrentUser, useLogout } from '../hooks/useAuth'

interface NavItem {
  name: string
  href: string
  icon: LucideIcon
}

interface NavGroup {
  label: string
  items: NavItem[]
}

const navGroups: NavGroup[] = [
  {
    label: '',
    items: [
      { name: 'Dashboard', href: '/ui', icon: LayoutDashboard },
      { name: 'Search', href: '/ui/search', icon: Search },
    ],
  },
  {
    label: 'Media',
    items: [
      { name: 'Libraries', href: '/ui/libraries', icon: FolderOpen },
      { name: 'Media', href: '/ui/media', icon: Film },
      { name: 'Collections', href: '/ui/collections', icon: FolderHeart },
      { name: 'Artwork', href: '/ui/artwork', icon: Image },
    ],
  },
  {
    label: 'Live TV',
    items: [
      { name: 'Live TV', href: '/ui/livetv', icon: Tv },
      { name: 'TV Guide', href: '/ui/tvguide', icon: CalendarDays },
      { name: 'Tuners', href: '/ui/tuners', icon: Radio },
      { name: 'Channel Collections', href: '/ui/channel-collections', icon: Layers },
      { name: 'Virtual Channels', href: '/ui/virtual-channels', icon: TvMinimal },
    ],
  },
  {
    label: 'DVR & Recording',
    items: [
      { name: 'DVR', href: '/ui/dvr', icon: Video },
      { name: 'On Later', href: '/ui/onlater', icon: Clock },
      { name: 'Team Pass', href: '/ui/teampass', icon: Trophy },
      { name: 'Comskip', href: '/ui/comskip', icon: SlidersHorizontal },
      { name: 'Segments', href: '/ui/segments', icon: Scissors },
    ],
  },
  {
    label: 'Content',
    items: [
      { name: 'VOD', href: '/ui/vod', icon: CloudDownload },
      { name: 'Downloads', href: '/ui/downloads', icon: Download },
      { name: 'Upload', href: '/ui/upload', icon: Upload },
    ],
  },
  {
    label: 'System',
    items: [
      { name: 'Users', href: '/ui/users', icon: Users },
      { name: 'Settings', href: '/ui/settings', icon: Settings },
      { name: 'Transcode', href: '/ui/transcode', icon: Cpu },
      { name: 'Jobs', href: '/ui/jobs', icon: ListTodo },
      { name: 'Logs', href: '/ui/logs', icon: FileText },
      { name: 'Diagnostics', href: '/ui/diagnostics', icon: Activity },
      { name: 'Connections', href: '/ui/connections', icon: MonitorSmartphone },
      { name: 'Speed Test', href: '/ui/speedtest', icon: Gauge },
      { name: 'Backups', href: '/ui/backups', icon: DatabaseBackup },
      { name: 'Trash', href: '/ui/trash', icon: Trash2 },
      { name: 'Updater', href: '/ui/updater', icon: RefreshCw },
    ],
  },
]

function NavSection({ group, location, onNavigate }: { group: NavGroup; location: ReturnType<typeof useLocation>; onNavigate: () => void }) {
  const hasActiveChild = group.items.some((item) => location.pathname === item.href)
  const [open, setOpen] = useState(group.label === '' || hasActiveChild)

  // Ungrouped items (Dashboard, Search) — always show
  if (!group.label) {
    return (
      <div className="mb-1">
        {group.items.map((item) => {
          const isActive = location.pathname === item.href
          return (
            <Link
              key={item.name}
              to={item.href}
              onClick={onNavigate}
              className={`flex items-center gap-3 px-3 py-2 mb-0.5 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-indigo-600 text-white'
                  : 'text-gray-300 hover:bg-gray-700 hover:text-white'
              }`}
            >
              <item.icon className="h-4 w-4" />
              {item.name}
            </Link>
          )
        })}
      </div>
    )
  }

  return (
    <div className="mb-1">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center justify-between w-full px-3 py-1.5 text-xs font-semibold uppercase tracking-wider text-gray-500 hover:text-gray-300 transition-colors"
      >
        {group.label}
        <ChevronDown className={`h-3 w-3 transition-transform ${open ? '' : '-rotate-90'}`} />
      </button>
      {open && (
        <div>
          {group.items.map((item) => {
            const isActive = location.pathname === item.href
            return (
              <Link
                key={item.name}
                to={item.href}
                onClick={onNavigate}
                className={`flex items-center gap-3 px-3 py-1.5 mb-0.5 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-indigo-600 text-white'
                    : 'text-gray-300 hover:bg-gray-700 hover:text-white'
                }`}
              >
                <item.icon className="h-4 w-4" />
                {item.name}
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}

export function Layout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { data: user } = useCurrentUser()
  const logout = useLogout()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const handleLogout = async () => {
    await logout.mutateAsync()
    navigate('/ui/login')
  }

  return (
    <div className="min-h-screen bg-gray-900">
      {/* Mobile sidebar backdrop */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 w-64 flex flex-col transform bg-gray-800 transition-transform duration-200 ease-in-out lg:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex h-14 shrink-0 items-center justify-between px-6 border-b border-gray-700">
          <span className="text-xl font-bold text-white">OpenFlix</span>
          <button
            className="lg:hidden text-gray-400 hover:text-white"
            onClick={() => setSidebarOpen(false)}
          >
            <X className="h-6 w-6" />
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto px-3 py-3 scrollbar-thin">
          {navGroups.map((group) => (
            <NavSection
              key={group.label || '_top'}
              group={group}
              location={location}
              onNavigate={() => setSidebarOpen(false)}
            />
          ))}
        </nav>

        <div className="shrink-0 p-3 border-t border-gray-700">
          <div className="flex items-center gap-3 mb-2">
            <div className="h-8 w-8 rounded-full bg-indigo-600 flex items-center justify-center text-white font-medium text-sm">
              {user?.username?.charAt(0).toUpperCase() || 'U'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-white truncate">
                {user?.title || user?.username}
              </p>
              <p className="text-xs text-gray-400">
                {user?.admin ? 'Administrator' : 'User'}
              </p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 w-full px-3 py-1.5 text-sm text-gray-300 hover:bg-gray-700 hover:text-white rounded-lg transition-colors"
          >
            <LogOut className="h-4 w-4" />
            Sign out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Mobile header */}
        <header className="sticky top-0 z-30 flex h-16 items-center gap-4 border-b border-gray-700 bg-gray-800 px-4 lg:hidden">
          <button
            className="text-gray-400 hover:text-white"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="h-6 w-6" />
          </button>
          <span className="text-lg font-semibold text-white">OpenFlix</span>
        </header>

        {/* Page content */}
        <main className="p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
