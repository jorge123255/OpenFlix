import { useState, useMemo, useRef, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Search, Check, X } from 'lucide-react'
import { api } from '../api/client'

const isAbsoluteUrl = (url?: string) => url ? /^https?:\/\//i.test(url) : false

interface Channel {
  id: number
  sourceId: number
  channelId: string
  number: number
  name: string
  logo?: string
  group?: string
  streamUrl: string
  enabled: boolean
  epgSourceId?: number
}

interface EPGProgram {
  id: number
  channelId: string
  callSign?: string
  channelNo?: string
  affiliateName?: string
  title: string
  description?: string
  start: string
  end: string
  category?: string
}

export function EPGEditorSimplePage() {
  const queryClient = useQueryClient()
  const [searchQuery, setSearchQuery] = useState('')
  const [epgSourceId, setEpgSourceId] = useState<number | null>(null)
  const [mappingChannel, setMappingChannel] = useState<string | null>(null)
  const [selectedChannels, setSelectedChannels] = useState<Set<number>>(new Set())
  const [bulkMappingEPGChannel, setBulkMappingEPGChannel] = useState<string | null>(null)
  const [m3uSearchQuery, setM3uSearchQuery] = useState('')
  const [m3uModalSearchQuery, setM3uModalSearchQuery] = useState('')
  const searchInputRef = useRef<HTMLInputElement>(null)

  // Fetch all channels
  const { data: channelsData } = useQuery({
    queryKey: ['channels'],
    queryFn: async () => {
      const response = await fetch('/livetv/channels', {
        headers: { 'X-Plex-Token': api.getToken() || '' },
      })
      const data = await response.json()
      return data.channels as Channel[]
    },
  })

  // Fetch EPG sources
  const { data: epgSources } = useQuery({
    queryKey: ['epgSources'],
    queryFn: async () => {
      const response = await api.getEPGSources()
      return response
    },
  })

  // Fetch EPG programs for the selected source
  const { data: programsData, isLoading } = useQuery({
    queryKey: ['allEPGPrograms', epgSourceId],
    queryFn: () => api.getEPGPrograms({
      epgSourceId: epgSourceId || undefined,
      limit: 10000,
    }),
    enabled: !!epgSourceId,
  })

  // Update channel mutation
  const updateChannel = useMutation({
    mutationFn: async (data: { channelId: number; epgSourceId: number; epgChannelId: string }) => {
      const response = await fetch(`/livetv/channels/${data.channelId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || '',
        },
        body: JSON.stringify({
          epgSourceId: data.epgSourceId,
          channelId: data.epgChannelId,
        }),
      })
      if (!response.ok) throw new Error('Failed to update channel')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channels'] })
      setMappingChannel(null)
    },
  })

  // Bulk map mutation
  const bulkMapChannels = useMutation({
    mutationFn: async (data: { channelIds: number[]; epgSourceId: number; epgChannelId: string }) => {
      const response = await fetch('/livetv/channels/bulk-map', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Plex-Token': api.getToken() || '',
        },
        body: JSON.stringify({
          channelIds: data.channelIds,
          epgSourceId: data.epgSourceId,
          epgChannelId: data.epgChannelId,
        }),
      })
      if (!response.ok) throw new Error('Failed to bulk map channels')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channels'] })
      setSelectedChannels(new Set())
      setBulkMappingEPGChannel(null)
    },
  })

  // Unmap mutation
  const unmapChannel = useMutation({
    mutationFn: async (channelId: number) => {
      const response = await fetch(`/livetv/channels/${channelId}/epg-mapping`, {
        method: 'DELETE',
        headers: {
          'X-Plex-Token': api.getToken() || '',
        },
      })
      if (!response.ok) throw new Error('Failed to unmap channel')
      return response.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channels'] })
    },
  })

  // Group programs by channel ID and get current/next program
  const epgChannelMap = new Map<string, EPGProgram[]>()
  programsData?.programs.forEach(program => {
    if (!epgChannelMap.has(program.channelId)) {
      epgChannelMap.set(program.channelId, [])
    }
    epgChannelMap.get(program.channelId)!.push(program)
  })

  // Get current or next program for each channel
  const now = new Date()
  const epgChannels = Array.from(epgChannelMap.entries()).map(([channelId, programs]) => {
    const currentProgram = programs.find(p => new Date(p.start) <= now && new Date(p.end) > now)
    const nextProgram = programs.find(p => new Date(p.start) > now)
    const latestProgram = programs.sort((a, b) => new Date(b.start).getTime() - new Date(a.start).getTime())[0]

    return {
      channelId,
      currentProgram: currentProgram || nextProgram || latestProgram,
      programCount: programs.length,
    }
  }).filter(ch => ch.currentProgram)

  // Filter EPG channels by search
  const filteredEPGChannels = epgChannels.filter(ch =>
    ch.channelId.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ch.currentProgram.callSign?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ch.currentProgram.channelNo?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ch.currentProgram.affiliateName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ch.currentProgram.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ch.currentProgram.description?.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const handleMap = (epgChannelId: string, m3uChannelId: number) => {
    if (!epgSourceId) return
    updateChannel.mutate({
      channelId: m3uChannelId,
      epgSourceId,
      epgChannelId,
    })
  }

  // Get all M3U channels mapped to this EPG channel
  const getMappedChannels = (epgChannelId: string) => {
    return channelsData?.filter(ch => ch.channelId === epgChannelId && ch.epgSourceId === epgSourceId) || []
  }

  // Toggle channel selection
  const toggleChannelSelection = (channelId: number) => {
    const newSelection = new Set(selectedChannels)
    if (newSelection.has(channelId)) {
      newSelection.delete(channelId)
    } else {
      newSelection.add(channelId)
    }
    setSelectedChannels(newSelection)
  }

  // Bulk map selected channels
  const handleBulkMap = (epgChannelId: string) => {
    if (!epgSourceId || selectedChannels.size === 0) return
    bulkMapChannels.mutate({
      channelIds: Array.from(selectedChannels),
      epgSourceId,
      epgChannelId,
    })
  }

  // Market-aware affiliate mapping
  const marketAffiliates: Record<string, Record<string, string>> = {
    // Format: market -> { network: callSign }
    'NEW YORK': { CBS: 'WCBS', NBC: 'WNBC', ABC: 'WABC', FOX: 'WNYW', CW: 'WPIX', PBS: 'WNET' },
    'LOS ANGELES': { CBS: 'KCBS', NBC: 'KNBC', ABC: 'KABC', FOX: 'KTTV', CW: 'KTLA', PBS: 'KCET' },
    'CHICAGO': { CBS: 'WBBM', NBC: 'WMAQ', ABC: 'WLS', FOX: 'WFLD', CW: 'WGN', PBS: 'WTTW' },
    'PHILADELPHIA': { CBS: 'KYW', NBC: 'WCAU', ABC: 'WPVI', FOX: 'WTXF', CW: 'WPHL', PBS: 'WHYY' },
    'DALLAS': { CBS: 'KTVT', NBC: 'KXAS', ABC: 'WFAA', FOX: 'KDFW', CW: 'KDAF', PBS: 'KERA' },
    'SAN FRANCISCO': { CBS: 'KPIX', NBC: 'KNTV', ABC: 'KGO', FOX: 'KTVU', CW: 'KBCW', PBS: 'KQED' },
    'BOSTON': { CBS: 'WBZ', NBC: 'WBTS', ABC: 'WCVB', FOX: 'WFXT', CW: 'WLVI', PBS: 'WGBH' },
    'ATLANTA': { CBS: 'WGCL', NBC: 'WXIA', ABC: 'WSB', FOX: 'WAGA', CW: 'WPCH', PBS: 'WGTV' },
    'SEATTLE': { CBS: 'KIRO', NBC: 'KING', ABC: 'KOMO', FOX: 'KCPQ', CW: 'KSTW', PBS: 'KCTS' },
    'HOUSTON': { CBS: 'KHOU', NBC: 'KPRC', ABC: 'KTRK', FOX: 'KRIV', CW: 'KIAH', PBS: 'KUHT' },
    'DENVER': { CBS: 'KCNC', NBC: 'KUSA', ABC: 'KMGH', FOX: 'KDVR', CW: 'KWGN', PBS: 'KRMA' },
    'PHOENIX': { CBS: 'KPHO', NBC: 'KPNX', ABC: 'KNXV', FOX: 'KSAZ', CW: 'KASW', PBS: 'KAET' },
    'MINNEAPOLIS': { CBS: 'WCCO', NBC: 'KARE', ABC: 'KSTP', FOX: 'KMSP', CW: 'WUCW', PBS: 'TPT' },
    'MIAMI': { CBS: 'WFOR', NBC: 'WTVJ', ABC: 'WPLG', FOX: 'WSVN', CW: 'WSFL', PBS: 'WPBT' },
    'WASHINGTON DC': { CBS: 'WUSA', NBC: 'WRC', ABC: 'WJLA', FOX: 'WTTG', CW: 'WDCW', PBS: 'WETA' },
    'DETROIT': { CBS: 'WWJ', NBC: 'WDIV', ABC: 'WXYZ', FOX: 'WJBK', CW: 'WKBD', PBS: 'WTVS' },
  }

  // Detect market from M3U channel name
  const detectM3UMarket = (name: string): string | null => {
    const upperName = name.toUpperCase()
    const marketKeywords: Record<string, string[]> = {
      'NEW YORK': ['NEW YORK', 'NY ', 'NYC', 'A3 NEW YORK', 'WCBS', 'WNBC', 'WABC', 'WNYW', 'WPIX'],
      'LOS ANGELES': ['LOS ANGELES', 'LA ', 'L.A.', 'KCBS', 'KNBC', 'KABC', 'KTTV', 'KTLA'],
      'CHICAGO': ['CHICAGO', 'CHI', 'WBBM', 'WMAQ', 'WLS', 'WFLD', 'WGN'],
      'PHILADELPHIA': ['PHILADELPHIA', 'PHILLY', 'KYW', 'WCAU', 'WPVI'],
      'DALLAS': ['DALLAS', 'DFW', 'KTVT', 'KXAS', 'WFAA', 'KDFW'],
      'SAN FRANCISCO': ['SAN FRANCISCO', 'SF ', 'BAY AREA', 'KPIX', 'KNTV', 'KGO', 'KTVU'],
      'BOSTON': ['BOSTON', 'WBZ', 'WBTS', 'WCVB', 'WFXT'],
      'ATLANTA': ['ATLANTA', 'ATL', 'WGCL', 'WXIA', 'WSB', 'WAGA'],
      'SEATTLE': ['SEATTLE', 'SEA', 'KIRO', 'KING', 'KOMO', 'KCPQ'],
      'HOUSTON': ['HOUSTON', 'KHOU', 'KPRC', 'KTRK', 'KRIV'],
      'DENVER': ['DENVER', 'KCNC', 'KUSA', 'KMGH', 'KDVR'],
      'PHOENIX': ['PHOENIX', 'PHX', 'KPHO', 'KPNX', 'KNXV', 'KSAZ'],
      'MINNEAPOLIS': ['MINNEAPOLIS', 'TWIN CITIES', 'WCCO', 'KARE', 'KSTP', 'KMSP'],
      'MIAMI': ['MIAMI', 'WFOR', 'WTVJ', 'WPLG', 'WSVN'],
      'WASHINGTON DC': ['WASHINGTON', 'DC', 'WUSA', 'WRC', 'WJLA', 'WTTG'],
      'DETROIT': ['DETROIT', 'WWJ', 'WDIV', 'WXYZ', 'WJBK'],
    }

    for (const [market, keywords] of Object.entries(marketKeywords)) {
      if (keywords.some(kw => upperName.includes(kw))) {
        return market
      }
    }
    return null
  }

  // Detect EPG source market from postal code (approximate)
  const detectEPGMarket = (): string | null => {
    const source = epgSources?.find(s => s.id === epgSourceId)
    if (!source?.gracenotePostalCode) return null

    const zip = source.gracenotePostalCode.substring(0, 3)
    const zipToMarket: Record<string, string> = {
      // New York area
      '100': 'NEW YORK', '101': 'NEW YORK', '102': 'NEW YORK', '103': 'NEW YORK', '104': 'NEW YORK',
      '105': 'NEW YORK', '106': 'NEW YORK', '107': 'NEW YORK', '108': 'NEW YORK', '109': 'NEW YORK',
      '110': 'NEW YORK', '111': 'NEW YORK', '112': 'NEW YORK', '113': 'NEW YORK', '114': 'NEW YORK',
      // Los Angeles area
      '900': 'LOS ANGELES', '901': 'LOS ANGELES', '902': 'LOS ANGELES', '903': 'LOS ANGELES',
      '904': 'LOS ANGELES', '905': 'LOS ANGELES', '906': 'LOS ANGELES', '907': 'LOS ANGELES',
      '908': 'LOS ANGELES', '910': 'LOS ANGELES', '911': 'LOS ANGELES', '912': 'LOS ANGELES',
      '913': 'LOS ANGELES', '914': 'LOS ANGELES', '915': 'LOS ANGELES', '916': 'LOS ANGELES',
      '917': 'LOS ANGELES', '918': 'LOS ANGELES',
      // Chicago area
      '600': 'CHICAGO', '601': 'CHICAGO', '602': 'CHICAGO', '603': 'CHICAGO', '604': 'CHICAGO',
      '605': 'CHICAGO', '606': 'CHICAGO', '607': 'CHICAGO', '608': 'CHICAGO',
      // Philadelphia area
      '190': 'PHILADELPHIA', '191': 'PHILADELPHIA', '192': 'PHILADELPHIA', '193': 'PHILADELPHIA', '194': 'PHILADELPHIA',
      // Dallas area
      '750': 'DALLAS', '751': 'DALLAS', '752': 'DALLAS', '753': 'DALLAS', '754': 'DALLAS', '755': 'DALLAS',
      // San Francisco area
      '940': 'SAN FRANCISCO', '941': 'SAN FRANCISCO', '942': 'SAN FRANCISCO', '943': 'SAN FRANCISCO',
      '944': 'SAN FRANCISCO', '945': 'SAN FRANCISCO', '946': 'SAN FRANCISCO', '947': 'SAN FRANCISCO',
      // Boston area
      '021': 'BOSTON', '022': 'BOSTON', '023': 'BOSTON', '024': 'BOSTON',
      // Atlanta area
      '300': 'ATLANTA', '301': 'ATLANTA', '302': 'ATLANTA', '303': 'ATLANTA', '304': 'ATLANTA',
      '305': 'ATLANTA', '306': 'ATLANTA', '307': 'ATLANTA', '308': 'ATLANTA', '309': 'ATLANTA',
      '310': 'ATLANTA', '311': 'ATLANTA', '312': 'ATLANTA', '313': 'ATLANTA', '314': 'ATLANTA',
      '315': 'ATLANTA', '316': 'ATLANTA', '317': 'ATLANTA', '318': 'ATLANTA', '319': 'ATLANTA',
      // Seattle area
      '980': 'SEATTLE', '981': 'SEATTLE', '982': 'SEATTLE', '983': 'SEATTLE', '984': 'SEATTLE',
      // Houston area
      '770': 'HOUSTON', '771': 'HOUSTON', '772': 'HOUSTON', '773': 'HOUSTON', '774': 'HOUSTON',
      '775': 'HOUSTON', '776': 'HOUSTON', '777': 'HOUSTON', '778': 'HOUSTON', '779': 'HOUSTON',
      // Denver area
      '800': 'DENVER', '801': 'DENVER', '802': 'DENVER', '803': 'DENVER', '804': 'DENVER', '805': 'DENVER',
      // Phoenix area
      '850': 'PHOENIX', '851': 'PHOENIX', '852': 'PHOENIX', '853': 'PHOENIX',
      // Minneapolis area
      '550': 'MINNEAPOLIS', '551': 'MINNEAPOLIS', '553': 'MINNEAPOLIS', '554': 'MINNEAPOLIS', '555': 'MINNEAPOLIS',
      // Miami area
      '330': 'MIAMI', '331': 'MIAMI', '332': 'MIAMI', '333': 'MIAMI', '334': 'MIAMI',
      // Washington DC area
      '200': 'WASHINGTON DC', '201': 'WASHINGTON DC', '202': 'WASHINGTON DC', '203': 'WASHINGTON DC',
      '204': 'WASHINGTON DC', '205': 'WASHINGTON DC', '206': 'WASHINGTON DC', '207': 'WASHINGTON DC',
      '208': 'WASHINGTON DC', '209': 'WASHINGTON DC', '210': 'WASHINGTON DC', '211': 'WASHINGTON DC',
      '212': 'WASHINGTON DC', '220': 'WASHINGTON DC', '221': 'WASHINGTON DC', '222': 'WASHINGTON DC',
      '223': 'WASHINGTON DC',
      // Detroit area
      '480': 'DETROIT', '481': 'DETROIT', '482': 'DETROIT', '483': 'DETROIT', '484': 'DETROIT',
    }

    return zipToMarket[zip] || null
  }

  // Extract network from M3U channel name
  const extractNetwork = (name: string): string | null => {
    const upperName = name.toUpperCase()
    if (upperName.includes('CBS')) return 'CBS'
    if (upperName.includes('NBC')) return 'NBC'
    if (upperName.includes('ABC')) return 'ABC'
    if (upperName.includes('FOX')) return 'FOX'
    if (upperName.includes('PBS')) return 'PBS'
    if (upperName.includes('CW')) return 'CW'
    return null
  }

  // Get market mismatch info for selected channels
  const getMarketMismatchInfo = () => {
    const epgMarket = detectEPGMarket()
    if (!epgMarket || selectedChannels.size === 0) return null

    const mismatches: Array<{
      channel: Channel
      m3uMarket: string
      network: string | null
      localEquivalent: string | null
    }> = []

    selectedChannels.forEach(channelId => {
      const channel = channelsData?.find(c => c.id === channelId)
      if (!channel) return

      const m3uMarket = detectM3UMarket(channel.name)
      if (m3uMarket && m3uMarket !== epgMarket) {
        const network = extractNetwork(channel.name)
        const localEquivalent = network && marketAffiliates[epgMarket]?.[network]
        mismatches.push({ channel, m3uMarket, network, localEquivalent })
      }
    })

    return mismatches.length > 0 ? { epgMarket, mismatches } : null
  }

  const marketMismatchInfo = getMarketMismatchInfo()

  // Extract network keywords from channel name for smart matching
  const extractNetworkKeywords = (name: string): string[] => {
    const networkMap: Record<string, string[]> = {
      'CBS': ['CBS', 'WCBS', 'KCBS', 'KIRO', 'WBBM', 'KDKA', 'KYW', 'WJZ', 'WCCO', 'WWJ', 'KCNC', 'KTVT', 'KHOU', 'KPIX', 'KCAL', 'CBS TELEVISION'],
      'NBC': ['NBC', 'WNBC', 'KNBC', 'KING', 'WMAQ', 'WCAU', 'WRC', 'WTVJ', 'KXAS', 'NATIONAL BROADCASTING'],
      'ABC': ['ABC', 'WABC', 'KABC', 'KOMO', 'WLS', 'WPVI', 'KGO', 'WTVD', 'AMERICAN BROADCASTING'],
      'FOX': ['FOX', 'WNYW', 'KTTV', 'KCPQ', 'WFLD', 'WTXF', 'WTTG', 'KRIV', 'FOX ENTERTAINMENT'],
      'PBS': ['PBS', 'WNET', 'WGBH', 'KCTS', 'KCET', 'WETA', 'PUBLIC BROADCASTING'],
      'CW': ['CW', 'WPIX', 'KTLA', 'KSTW'],
      'ESPN': ['ESPN', 'ESPN2', 'ESPNU', 'ESPNEWS'],
      'CNN': ['CNN', 'HLN'],
      'MSNBC': ['MSNBC'],
      'HBO': ['HBO'],
      'SHOWTIME': ['SHOWTIME', 'SHO'],
      'DISCOVERY': ['DISCOVERY', 'TLC', 'HGTV', 'FOOD NETWORK'],
      'NICKELODEON': ['NICKELODEON', 'NICK', 'NICKJR', 'NICKTOONS'],
      'DISNEY': ['DISNEY', 'DISN', 'DXD'],
      'CARTOON': ['CARTOON', 'TOON', 'BOOMERANG'],
      'AMC': ['AMC'],
      'TNT': ['TNT', 'TBS', 'TRUTV'],
      'USA': ['USA NETWORK', 'USA'],
      'FX': ['FX', 'FXX', 'FXM'],
      'BRAVO': ['BRAVO'],
      'SYFY': ['SYFY', 'SCI-FI'],
      'HALLMARK': ['HALLMARK'],
      'LIFETIME': ['LIFETIME', 'LMN'],
      'HISTORY': ['HISTORY', 'H2'],
      'NATGEO': ['NAT GEO', 'NATIONAL GEOGRAPHIC', 'NGWILD'],
      'COMEDY': ['COMEDY CENTRAL', 'COMEDY'],
      'MTV': ['MTV', 'VH1', 'CMT'],
      'BET': ['BET'],
      'OXYGEN': ['OXYGEN'],
      'ANIMAL': ['ANIMAL PLANET'],
    }

    const upperName = name.toUpperCase()
    const foundNetworks: string[] = []

    for (const [network, keywords] of Object.entries(networkMap)) {
      for (const keyword of keywords) {
        if (upperName.includes(keyword)) {
          foundNetworks.push(network)
          // Also add the specific keyword for more precise matching
          foundNetworks.push(keyword)
          // Add local equivalent call signs if we know the EPG market
          const epgMarket = detectEPGMarket()
          if (epgMarket && marketAffiliates[epgMarket]?.[network]) {
            foundNetworks.push(marketAffiliates[epgMarket][network])
          }
          break
        }
      }
    }

    return foundNetworks
  }

  // Get network keywords from all selected M3U channels
  const getSelectedChannelKeywords = (): string[] => {
    if (selectedChannels.size === 0) return []
    const keywords: string[] = []
    selectedChannels.forEach(channelId => {
      const channel = channelsData?.find(c => c.id === channelId)
      if (channel) {
        keywords.push(...extractNetworkKeywords(channel.name))
      }
    })
    return [...new Set(keywords)] // Remove duplicates
  }

  // Check if an EPG channel matches any of the keywords
  const epgChannelMatchesKeywords = (epgChannel: typeof epgChannels[0], keywords: string[]): boolean => {
    if (keywords.length === 0) return false
    const callSign = epgChannel.currentProgram.callSign?.toUpperCase() || ''
    const affiliate = epgChannel.currentProgram.affiliateName?.toUpperCase() || ''
    const channelId = epgChannel.channelId.toUpperCase()

    return keywords.some(keyword =>
      callSign.includes(keyword) ||
      affiliate.includes(keyword) ||
      channelId.includes(keyword)
    )
  }

  // Get suggested EPG channels based on selected M3U channels
  const selectedKeywords = getSelectedChannelKeywords()
  const suggestedEPGChannels = selectedKeywords.length > 0
    ? filteredEPGChannels.filter(ch => epgChannelMatchesKeywords(ch, selectedKeywords))
    : []
  const otherEPGChannels = selectedKeywords.length > 0
    ? filteredEPGChannels.filter(ch => !epgChannelMatchesKeywords(ch, selectedKeywords))
    : filteredEPGChannels

  // Filter M3U channels by search query for the mapping dropdown
  const filteredM3uChannels = useMemo(() => {
    if (!channelsData) return []
    if (!m3uSearchQuery.trim()) return channelsData
    const query = m3uSearchQuery.toLowerCase()
    return channelsData.filter(ch =>
      ch.name.toLowerCase().includes(query) ||
      ch.number.toString().includes(query) ||
      ch.group?.toLowerCase().includes(query)
    )
  }, [channelsData, m3uSearchQuery])

  // Group M3U channels by group/provider
  const groupedM3uChannels = useMemo(() => {
    const groups: Record<string, Channel[]> = {}
    filteredM3uChannels.forEach(channel => {
      const groupName = channel.group || 'Uncategorized'
      if (!groups[groupName]) {
        groups[groupName] = []
      }
      groups[groupName].push(channel)
    })
    // Sort groups alphabetically
    return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
  }, [filteredM3uChannels])

  // Filter M3U channels for the modal selection
  const filteredModalM3uChannels = useMemo(() => {
    if (!channelsData) return []
    if (!m3uModalSearchQuery.trim()) return channelsData
    const query = m3uModalSearchQuery.toLowerCase()
    return channelsData.filter(ch =>
      ch.name.toLowerCase().includes(query) ||
      ch.number.toString().includes(query) ||
      ch.group?.toLowerCase().includes(query)
    )
  }, [channelsData, m3uModalSearchQuery])

  // Group filtered modal channels by group/provider
  const groupedModalM3uChannels = useMemo(() => {
    const groups: Record<string, Channel[]> = {}
    filteredModalM3uChannels.forEach(channel => {
      const groupName = channel.group || 'Uncategorized'
      if (!groups[groupName]) {
        groups[groupName] = []
      }
      groups[groupName].push(channel)
    })
    return Object.entries(groups).sort((a, b) => a[0].localeCompare(b[0]))
  }, [filteredModalM3uChannels])

  // Focus search input when mapping dropdown opens
  useEffect(() => {
    if (mappingChannel && searchInputRef.current) {
      searchInputRef.current.focus()
    }
  }, [mappingChannel])

  // Reset search when closing mapping dropdown
  const closeMappingDropdown = () => {
    setMappingChannel(null)
    setM3uSearchQuery('')
  }

  return (
    <div className="h-screen flex flex-col bg-gray-900">
      {/* Header */}
      <div className="p-6 border-b border-gray-700">
        <h1 className="text-2xl font-bold text-white mb-4">EPG Mapper - Simple Mode</h1>

        {/* EPG Source Selection */}
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Select EPG Source
          </label>
          <select
            value={epgSourceId || ''}
            onChange={(e) => setEpgSourceId(e.target.value ? parseInt(e.target.value) : null)}
            className="w-full max-w-md px-4 py-2 bg-gray-800 border border-gray-600 rounded-lg text-white"
          >
            <option value="">Choose an EPG source...</option>
            {epgSources?.map((source) => (
              <option key={source.id} value={source.id}>
                {source.name} ({source.channelCount} channels, {source.programCount} programs)
              </option>
            ))}
          </select>
        </div>

        {/* Search */}
        {epgSourceId && (
          <div className="flex items-center gap-3">
            <div className="relative max-w-md flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search EPG channels or programs..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-10 py-2 bg-gray-800 border border-gray-600 rounded-lg text-white placeholder-gray-400"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-2 top-1/2 -translate-y-1/2 p-1 hover:bg-gray-700 rounded"
                  title="Clear search"
                >
                  <X className="h-4 w-4 text-gray-400" />
                </button>
              )}
            </div>
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="px-4 py-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg text-sm font-medium"
              >
                Clear Filter - Show All {epgChannels.length} Channels
              </button>
            )}
          </div>
        )}
      </div>

      {/* M3U Channel Selection Toolbar - Always show when EPG source selected */}
      {epgSourceId && (
        <div className="px-6 py-3 bg-gray-800 border-b border-gray-700 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Check className="h-5 w-5 text-indigo-400" />
            <span className="text-white font-medium">
              {selectedChannels.size > 0
                ? `${selectedChannels.size} M3U channel(s) selected`
                : 'Select M3U channels to bulk map'}
            </span>
          </div>
          <div className="flex gap-2">
            {selectedChannels.size > 0 && (
              <button
                onClick={() => setSelectedChannels(new Set())}
                className="px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-sm rounded"
              >
                Clear Selection
              </button>
            )}
            <button
              onClick={() => setBulkMappingEPGChannel('selecting')}
              className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded flex items-center gap-1.5"
            >
              <Check className="h-4 w-4" />
              {selectedChannels.size > 0 ? `Selected ${selectedChannels.size} channels` : 'Select M3U Channels...'}
            </button>
          </div>
        </div>
      )}

      {/* EPG Channels List */}
      <div className="flex-1 overflow-y-auto p-6">
        {!epgSourceId ? (
          <div className="text-center py-12 text-gray-400">
            <p>Select an EPG source above to start mapping channels</p>
          </div>
        ) : isLoading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500 mx-auto"></div>
            <p className="text-gray-400 mt-4">Loading EPG channels...</p>
          </div>
        ) : (
          <div className="max-w-6xl mx-auto">
            <div className="mb-4 flex items-center gap-3">
              <span className="text-sm text-gray-400">
                Showing {filteredEPGChannels.length} of {epgChannels.length} EPG channels
                {searchQuery && (
                  <span className="ml-1 text-yellow-400">
                    (filtered by "{searchQuery}")
                  </span>
                )}
              </span>
              {selectedKeywords.length > 0 && suggestedEPGChannels.length > 0 && (
                <span className="text-sm text-green-400">
                  ({suggestedEPGChannels.length} suggested matches)
                </span>
              )}
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="text-sm text-yellow-400 hover:text-yellow-300 underline"
                >
                  Clear filter to see all channels
                </button>
              )}
            </div>

            {/* Market Mismatch Warning */}
            {marketMismatchInfo && (
              <div className="mb-6 bg-yellow-900/30 border-2 border-yellow-600/50 rounded-lg p-4">
                <div className="flex items-start gap-3">
                  <span className="text-2xl">⚠️</span>
                  <div className="flex-1">
                    <h3 className="font-bold text-yellow-400 text-lg mb-2">
                      Market Mismatch Detected
                    </h3>
                    <p className="text-yellow-200 mb-3">
                      Your EPG source is for <span className="font-bold">{marketMismatchInfo.epgMarket}</span>, but some selected M3U channels appear to be from different markets:
                    </p>
                    <div className="space-y-2 mb-4">
                      {marketMismatchInfo.mismatches.map(({ channel, m3uMarket, network, localEquivalent }) => (
                        <div key={channel.id} className="bg-yellow-900/30 rounded p-3">
                          <div className="flex items-center justify-between">
                            <div>
                              <span className="text-white font-medium">{channel.name}</span>
                              <span className="text-yellow-300 ml-2">({m3uMarket})</span>
                            </div>
                            {localEquivalent && (
                              <div className="text-sm">
                                <span className="text-gray-400">Local {network}: </span>
                                <span className="text-green-400 font-bold">{localEquivalent}</span>
                              </div>
                            )}
                          </div>
                          {localEquivalent && (
                            <p className="text-sm text-yellow-200/70 mt-1">
                              💡 Look for <span className="font-bold text-green-400">{localEquivalent}</span> in the suggestions below - it's the {marketMismatchInfo.epgMarket} {network} affiliate
                            </p>
                          )}
                        </div>
                      ))}
                    </div>
                    <p className="text-sm text-yellow-200/70">
                      You can still map these channels, but the EPG data may not match. Consider adding an EPG source for the channel's market or use the local equivalent.
                    </p>
                  </div>
                </div>
              </div>
            )}

            {/* Suggested Matches Section */}
            {selectedChannels.size > 0 && suggestedEPGChannels.length > 0 && (
              <div className="mb-6">
                <div className="flex items-center gap-2 mb-3">
                  <div className="h-2 w-2 bg-green-500 rounded-full animate-pulse"></div>
                  <h2 className="text-lg font-semibold text-green-400">
                    🎯 Suggested Matches for Your Selection
                  </h2>
                </div>
                <p className="text-sm text-gray-400 mb-3">
                  Based on your selected M3U channel(s), these EPG channels are likely matches
                  {detectEPGMarket() && <span className="text-blue-400"> in {detectEPGMarket()}</span>}:
                </p>
                <div className="space-y-3">
                  {suggestedEPGChannels.map((epgChannel) => {
                    const isCurrentlyAiring = new Date(epgChannel.currentProgram.start) <= now &&
                                             new Date(epgChannel.currentProgram.end) > now

                    return (
                      <div
                        key={epgChannel.channelId}
                        className="bg-gray-800 rounded-lg p-4 border-2 border-green-600/50 shadow-lg shadow-green-900/20"
                      >
                        <div className="flex items-start justify-between gap-4">
                          <div className="flex-1">
                            <div className="flex items-center gap-3 mb-2">
                              <h3 className="font-semibold text-white text-lg">
                                {epgChannel.currentProgram.callSign || epgChannel.channelId.replace(/^(gracenote|fubo)-/, '')}
                                {epgChannel.currentProgram.channelNo && (
                                  <span className="ml-2 text-gray-400">
                                    Ch {epgChannel.currentProgram.channelNo}
                                  </span>
                                )}
                              </h3>
                              {epgChannel.currentProgram.affiliateName && (
                                <span className="px-3 py-1 bg-green-600 text-white text-sm rounded font-medium">
                                  {epgChannel.currentProgram.affiliateName}
                                </span>
                              )}
                              {isCurrentlyAiring && (
                                <span className="px-2 py-0.5 bg-red-600 text-white text-xs rounded font-medium">
                                  LIVE NOW
                                </span>
                              )}
                            </div>

                            <div className="mb-1">
                              <p className="text-white font-medium">{epgChannel.currentProgram.title}</p>
                              {epgChannel.currentProgram.description && (
                                <p className="text-sm text-gray-400 line-clamp-2 mt-1">
                                  {epgChannel.currentProgram.description}
                                </p>
                              )}
                            </div>

                            {/* Show mapped channels */}
                            {getMappedChannels(epgChannel.channelId).length > 0 && (
                              <div className="mt-3 space-y-1.5">
                                <p className="text-xs text-gray-400 font-medium">Mapped M3U Channels:</p>
                                {getMappedChannels(epgChannel.channelId).map((m3uChannel) => (
                                  <div key={m3uChannel.id} className="flex items-center gap-2 text-sm bg-gray-700/50 rounded px-2 py-1.5">
                                    <Check className="h-3.5 w-3.5 text-green-400 flex-shrink-0" />
                                    <span className="text-white flex-1">{m3uChannel.name} (#{m3uChannel.number})</span>
                                    <button
                                      onClick={() => unmapChannel.mutate(m3uChannel.id)}
                                      className="text-red-400 hover:text-red-300 text-xs px-2 py-0.5 hover:bg-red-900/20 rounded"
                                    >
                                      Unmap
                                    </button>
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>

                          <div className="flex-shrink-0">
                            <button
                              onClick={() => handleBulkMap(epgChannel.channelId)}
                              className="px-6 py-3 bg-green-600 hover:bg-green-700 text-white text-sm rounded-lg font-bold flex items-center gap-2 shadow-lg"
                            >
                              <Check className="h-5 w-5" />
                              Map {selectedChannels.size} Here
                            </button>
                          </div>
                        </div>
                      </div>
                    )
                  })}
                </div>

                {otherEPGChannels.length > 0 && (
                  <div className="mt-6 mb-3">
                    <h2 className="text-lg font-semibold text-gray-400">Other EPG Channels</h2>
                  </div>
                )}
              </div>
            )}

            {/* Regular/Other EPG Channels */}
            <div className="space-y-3">
              {(selectedChannels.size > 0 && suggestedEPGChannels.length > 0 ? otherEPGChannels : filteredEPGChannels).map((epgChannel) => {
                const isCurrentlyAiring = new Date(epgChannel.currentProgram.start) <= now &&
                                         new Date(epgChannel.currentProgram.end) > now

                return (
                  <div
                    key={epgChannel.channelId}
                    className="bg-gray-800 rounded-lg p-4 border border-gray-700"
                  >
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="font-semibold text-white">
                            {epgChannel.currentProgram.callSign || epgChannel.channelId.replace(/^(gracenote|fubo)-/, '')}
                            {epgChannel.currentProgram.channelNo && (
                              <span className="ml-2 text-gray-400">
                                Ch {epgChannel.currentProgram.channelNo}
                              </span>
                            )}
                          </h3>
                          {epgChannel.currentProgram.affiliateName && (
                            <span className="px-2 py-0.5 bg-blue-600 text-white text-xs rounded">
                              {epgChannel.currentProgram.affiliateName}
                            </span>
                          )}
                          {isCurrentlyAiring && (
                            <span className="px-2 py-0.5 bg-red-600 text-white text-xs rounded font-medium">
                              LIVE NOW
                            </span>
                          )}
                          <span className="text-xs text-gray-500">
                            {epgChannel.programCount} programs
                          </span>
                        </div>

                        <div className="mb-1">
                          <p className="text-white font-medium">{epgChannel.currentProgram.title}</p>
                          {epgChannel.currentProgram.description && (
                            <p className="text-sm text-gray-400 line-clamp-2 mt-1">
                              {epgChannel.currentProgram.description}
                            </p>
                          )}
                        </div>

                        <div className="flex items-center gap-4 text-xs text-gray-500">
                          <span>
                            {new Date(epgChannel.currentProgram.start).toLocaleString()}
                          </span>
                          {epgChannel.currentProgram.category && (
                            <span className="px-2 py-1 bg-gray-700 rounded">
                              {epgChannel.currentProgram.category}
                            </span>
                          )}
                        </div>

                        {/* Show all mapped M3U channels */}
                        {getMappedChannels(epgChannel.channelId).length > 0 && (
                          <div className="mt-3 space-y-1.5">
                            <p className="text-xs text-gray-400 font-medium">Mapped M3U Channels:</p>
                            {getMappedChannels(epgChannel.channelId).map((m3uChannel) => (
                              <div key={m3uChannel.id} className="flex items-center gap-2 text-sm bg-gray-700/50 rounded px-2 py-1.5">
                                <Check className="h-3.5 w-3.5 text-green-400 flex-shrink-0" />
                                <span className="text-white flex-1">{m3uChannel.name} (#{m3uChannel.number})</span>
                                <button
                                  onClick={() => unmapChannel.mutate(m3uChannel.id)}
                                  className="text-red-400 hover:text-red-300 text-xs px-2 py-0.5 hover:bg-red-900/20 rounded"
                                  title="Remove mapping"
                                >
                                  Unmap
                                </button>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>

                      <div className="flex-shrink-0 flex flex-col gap-2">
                        {/* Bulk map button when channels are selected */}
                        {selectedChannels.size > 0 && (
                          <button
                            onClick={() => handleBulkMap(epgChannel.channelId)}
                            className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm rounded font-medium flex items-center gap-1.5"
                          >
                            <Check className="h-4 w-4" />
                            Map {selectedChannels.size} Selected Here
                          </button>
                        )}

                        {/* Individual mapping button - opens modal */}
                        <button
                          onClick={() => setMappingChannel(epgChannel.channelId)}
                          className={`px-4 py-2 rounded text-sm font-medium ${
                            getMappedChannels(epgChannel.channelId).length > 0
                              ? 'bg-gray-700 hover:bg-gray-600 text-white'
                              : 'bg-indigo-600 hover:bg-indigo-700 text-white'
                          }`}
                        >
                          {getMappedChannels(epgChannel.channelId).length > 0 ? 'Map Another' : 'Map Channel'}
                        </button>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        )}
      </div>

      {/* M3U Channel Selection Modal */}
      {bulkMappingEPGChannel === 'selecting' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => { setBulkMappingEPGChannel(null); setM3uModalSearchQuery(''); }}>
          <div className="bg-gray-800 rounded-lg shadow-xl max-w-2xl w-full max-h-[80vh] flex flex-col" onClick={(e) => e.stopPropagation()}>
            {/* Header */}
            <div className="p-4 border-b border-gray-700">
              <h2 className="text-xl font-bold text-white">Select M3U Channels to Map</h2>
              <p className="text-sm text-gray-400 mt-1">
                Choose the M3U channels you want to map to an EPG channel
              </p>
              {/* Search input */}
              <div className="relative mt-3">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search channels by name, number, or group..."
                  value={m3uModalSearchQuery}
                  onChange={(e) => setM3uModalSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded text-white placeholder-gray-400 text-sm"
                  autoFocus
                />
                {m3uModalSearchQuery && (
                  <button
                    onClick={() => setM3uModalSearchQuery('')}
                    className="absolute right-2 top-1/2 -translate-y-1/2 p-1 hover:bg-gray-600 rounded"
                  >
                    <X className="h-4 w-4 text-gray-400" />
                  </button>
                )}
              </div>
              {/* Results count */}
              <div className="text-xs text-gray-400 mt-2">
                {filteredModalM3uChannels.length} channel{filteredModalM3uChannels.length !== 1 ? 's' : ''} found
                {m3uModalSearchQuery && ` for "${m3uModalSearchQuery}"`}
              </div>
            </div>

            {/* Channel List */}
            <div className="flex-1 overflow-y-auto p-4">
              {!channelsData || channelsData.length === 0 ? (
                <div className="text-center py-8 text-gray-400">
                  <p>No M3U channels available</p>
                </div>
              ) : filteredModalM3uChannels.length === 0 ? (
                <div className="text-center py-8 text-gray-400">
                  <p>No channels match your search</p>
                </div>
              ) : groupedModalM3uChannels.length > 1 ? (
                // Show grouped channels when there are multiple groups
                <div className="space-y-4">
                  {groupedModalM3uChannels.map(([groupName, channels]) => (
                    <div key={groupName}>
                      <div className="px-2 py-1.5 bg-gray-700 rounded text-sm font-semibold text-gray-300 mb-2 flex items-center justify-between">
                        <span>{groupName}</span>
                        <span className="text-xs text-gray-400">{channels.length} channels</span>
                      </div>
                      <div className="space-y-2">
                        {channels.map((channel) => (
                          <label
                            key={channel.id}
                            className={`flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-colors ${
                              selectedChannels.has(channel.id)
                                ? 'bg-indigo-900/40 border-2 border-indigo-600'
                                : 'bg-gray-700/50 border-2 border-transparent hover:bg-gray-700'
                            }`}
                          >
                            <input
                              type="checkbox"
                              checked={selectedChannels.has(channel.id)}
                              onChange={() => toggleChannelSelection(channel.id)}
                              className="w-4 h-4 rounded border-gray-500 bg-gray-600 text-indigo-600 focus:ring-indigo-500"
                            />
                            {isAbsoluteUrl(channel.logo) && (
                              <img src={channel.logo} alt="" className="w-8 h-8 rounded object-cover" />
                            )}
                            <div className="flex-1">
                              <div className="text-white font-medium">{channel.name}</div>
                              <div className="text-xs text-gray-400">Channel #{channel.number}</div>
                            </div>
                            {channel.epgSourceId && (
                              <span className="text-xs text-green-400">Already mapped</span>
                            )}
                          </label>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                // Show flat list when there's only one group
                <div className="space-y-2">
                  {filteredModalM3uChannels.map((channel) => (
                    <label
                      key={channel.id}
                      className={`flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-colors ${
                        selectedChannels.has(channel.id)
                          ? 'bg-indigo-900/40 border-2 border-indigo-600'
                          : 'bg-gray-700/50 border-2 border-transparent hover:bg-gray-700'
                      }`}
                    >
                      <input
                        type="checkbox"
                        checked={selectedChannels.has(channel.id)}
                        onChange={() => toggleChannelSelection(channel.id)}
                        className="w-4 h-4 rounded border-gray-500 bg-gray-600 text-indigo-600 focus:ring-indigo-500"
                      />
                      {isAbsoluteUrl(channel.logo) && (
                        <img src={channel.logo} alt="" className="w-8 h-8 rounded object-cover" />
                      )}
                      <div className="flex-1">
                        <div className="text-white font-medium">{channel.name}</div>
                        <div className="text-xs text-gray-400">Channel #{channel.number}</div>
                      </div>
                      {channel.epgSourceId && (
                        <span className="text-xs text-green-400">Already mapped</span>
                      )}
                    </label>
                  ))}
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-gray-700 flex items-center justify-between">
              <span className="text-sm text-gray-400">
                {selectedChannels.size} channel(s) selected
              </span>
              <div className="flex gap-2">
                <button
                  onClick={() => { setBulkMappingEPGChannel(null); setM3uModalSearchQuery(''); }}
                  className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded"
                >
                  Done
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Individual Channel Mapping Modal */}
      {mappingChannel && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={closeMappingDropdown}>
          <div className="bg-gray-800 rounded-lg shadow-xl max-w-2xl w-full max-h-[80vh] flex flex-col" onClick={(e) => e.stopPropagation()}>
            {/* Header */}
            <div className="p-4 border-b border-gray-700">
              <h2 className="text-xl font-bold text-white">Map M3U Channel to EPG</h2>
              <p className="text-sm text-gray-400 mt-1">
                Select an M3U channel to map to: <span className="text-indigo-400 font-medium">
                  {epgChannels.find(ch => ch.channelId === mappingChannel)?.currentProgram.callSign || mappingChannel}
                </span>
              </p>
              {/* Search input */}
              <div className="relative mt-3">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  ref={searchInputRef}
                  type="text"
                  placeholder="Search M3U channels by name, number, or group..."
                  value={m3uSearchQuery}
                  onChange={(e) => setM3uSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded text-white placeholder-gray-400 text-sm"
                  autoFocus
                />
                {m3uSearchQuery && (
                  <button
                    onClick={() => setM3uSearchQuery('')}
                    className="absolute right-2 top-1/2 -translate-y-1/2 p-1 hover:bg-gray-600 rounded"
                  >
                    <X className="h-4 w-4 text-gray-400" />
                  </button>
                )}
              </div>
              {/* Results count */}
              <div className="text-xs text-gray-400 mt-2">
                {filteredM3uChannels.length} channel{filteredM3uChannels.length !== 1 ? 's' : ''} found
                {m3uSearchQuery && ` for "${m3uSearchQuery}"`}
              </div>
            </div>

            {/* Channel List */}
            <div className="flex-1 overflow-y-auto p-4">
              {!channelsData || channelsData.length === 0 ? (
                <div className="text-center py-8 text-gray-400">
                  <p>No M3U channels available</p>
                </div>
              ) : filteredM3uChannels.length === 0 ? (
                <div className="text-center py-8 text-gray-400">
                  <p>No channels match your search</p>
                </div>
              ) : groupedM3uChannels.length > 1 ? (
                // Show grouped channels when there are multiple groups
                <div className="space-y-4">
                  {groupedM3uChannels.map(([groupName, channels]) => (
                    <div key={groupName}>
                      <div className="px-2 py-1.5 bg-gray-700 rounded text-sm font-semibold text-gray-300 mb-2 flex items-center justify-between">
                        <span>{groupName}</span>
                        <span className="text-xs text-gray-400">{channels.length} channels</span>
                      </div>
                      <div className="space-y-1">
                        {channels.map((channel) => (
                          <button
                            key={channel.id}
                            onClick={() => {
                              handleMap(mappingChannel, channel.id)
                              closeMappingDropdown()
                            }}
                            className="w-full flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-colors bg-gray-700/50 hover:bg-indigo-900/40 hover:border-indigo-600 border-2 border-transparent"
                          >
                            {isAbsoluteUrl(channel.logo) && (
                              <img src={channel.logo} alt="" className="w-8 h-8 rounded object-cover" />
                            )}
                            <div className="flex-1 text-left">
                              <div className="text-white font-medium">{channel.name}</div>
                              <div className="text-xs text-gray-400">Channel #{channel.number}</div>
                            </div>
                            {channel.epgSourceId && (
                              <span className="text-xs text-green-400">Already mapped</span>
                            )}
                          </button>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                // Show flat list when there's only one group
                <div className="space-y-1">
                  {filteredM3uChannels.map((channel) => (
                    <button
                      key={channel.id}
                      onClick={() => {
                        handleMap(mappingChannel, channel.id)
                        closeMappingDropdown()
                      }}
                      className="w-full flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-colors bg-gray-700/50 hover:bg-indigo-900/40 hover:border-indigo-600 border-2 border-transparent"
                    >
                      {isAbsoluteUrl(channel.logo) && (
                        <img src={channel.logo} alt="" className="w-8 h-8 rounded object-cover" />
                      )}
                      <div className="flex-1 text-left">
                        <div className="text-white font-medium">{channel.name}</div>
                        <div className="text-xs text-gray-400">Channel #{channel.number}</div>
                      </div>
                      {channel.epgSourceId && (
                        <span className="text-xs text-green-400">Already mapped</span>
                      )}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-gray-700 flex justify-end">
              <button
                onClick={closeMappingDropdown}
                className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
