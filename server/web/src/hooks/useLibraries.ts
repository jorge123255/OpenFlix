import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import type { CreateLibraryRequest, Library } from '../types'

export function useLibraries() {
  return useQuery({
    queryKey: ['libraries'],
    queryFn: () => api.getLibraries(),
  })
}

export function useLibraryStats(libraryId: number) {
  return useQuery({
    queryKey: ['library-stats', libraryId],
    queryFn: () => api.getLibraryStats(libraryId),
  })
}

export function useCreateLibrary() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: CreateLibraryRequest) => api.createLibrary(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
    },
  })
}

export function useUpdateLibrary() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<Library> }) =>
      api.updateLibrary(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
    },
  })
}

export function useDeleteLibrary() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => api.deleteLibrary(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
    },
  })
}

export function useScanLibrary() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => api.scanLibrary(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['library-stats'] })
    },
  })
}

export function useAddLibraryPath() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ libraryId, path }: { libraryId: number; path: string }) =>
      api.addLibraryPath(libraryId, path),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
    },
  })
}

export function useRemoveLibraryPath() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ libraryId, pathId }: { libraryId: number; pathId: number }) =>
      api.removeLibraryPath(libraryId, pathId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
    },
  })
}
