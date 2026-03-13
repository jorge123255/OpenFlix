import { useEffect, useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'

export function useSetupCheck() {
  const [checked, setChecked] = useState(false)
  const navigate = useNavigate()
  const location = useLocation()

  useEffect(() => {
    // Skip if already on setup page or login page
    if (location.pathname.startsWith('/ui/setup') || location.pathname === '/ui/login') {
      setChecked(true)
      return
    }

    // Check if setup is needed
    fetch('/api/setup/status')
      .then(res => res.json())
      .then(data => {
        if (data.needsSetup) {
          navigate('/ui/setup', { replace: true })
        }
        setChecked(true)
      })
      .catch(() => {
        setChecked(true) // Don't block on error
      })
  }, [location.pathname, navigate])

  return checked
}
