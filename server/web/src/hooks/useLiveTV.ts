import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'

export function useM3USources() {
  return useQuery({
    queryKey: ['m3uSources'],
    queryFn: () => api.getM3USources(),
  })
}

export function useCreateM3USource() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: { name: string; url: string }) => api.createM3USource(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['m3uSources'] })
    },
  })
}

export function useDeleteM3USource() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => api.deleteM3USource(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['m3uSources'] })
    },
  })
}

export function useRefreshM3USource() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => api.refreshM3USource(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['m3uSources'] })
    },
  })
}

export function useEPGSources() {
  return useQuery({
    queryKey: ['epgSources'],
    queryFn: () => api.getEPGSources(),
  })
}

export function useCreateEPGSource() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: { name: string; url: string }) => api.createEPGSource(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['epgSources'] })
    },
  })
}

export function useDeleteEPGSource() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => api.deleteEPGSource(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['epgSources'] })
    },
  })
}

export function useRefreshEPG() {
  return useMutation({
    mutationFn: () => api.refreshEPG(),
  })
}
