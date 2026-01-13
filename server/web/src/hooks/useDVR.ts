import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import type { SeriesRule } from '../types'

export function useRecordings() {
  return useQuery({
    queryKey: ['recordings'],
    queryFn: () => api.getRecordings(),
  })
}

export function useDeleteRecording() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => api.deleteRecording(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recordings'] })
    },
  })
}

export function useSeriesRules() {
  return useQuery({
    queryKey: ['seriesRules'],
    queryFn: () => api.getSeriesRules(),
  })
}

export function useCreateSeriesRule() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: Partial<SeriesRule>) => api.createSeriesRule(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['seriesRules'] })
    },
  })
}

export function useUpdateSeriesRule() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<SeriesRule> }) =>
      api.updateSeriesRule(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['seriesRules'] })
    },
  })
}

export function useDeleteSeriesRule() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => api.deleteSeriesRule(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['seriesRules'] })
    },
  })
}

export function useRecordingConflicts() {
  return useQuery({
    queryKey: ['recordingConflicts'],
    queryFn: () => api.getRecordingConflicts(),
    refetchInterval: 60000, // Refresh every minute
  })
}

export function useResolveConflict() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ keepId, cancelId }: { keepId: number; cancelId: number }) =>
      api.resolveConflict(keepId, cancelId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recordings'] })
      queryClient.invalidateQueries({ queryKey: ['recordingConflicts'] })
    },
  })
}

export function useRecordingStats() {
  return useQuery({
    queryKey: ['recordingStats'],
    queryFn: () => api.getRecordingStats(),
    refetchInterval: 5000, // Refresh every 5 seconds for live stats
  })
}
