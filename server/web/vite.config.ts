import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: '/ui/',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
  server: {
    proxy: {
      '/auth': 'http://localhost:32400',
      '/admin': 'http://localhost:32400',
      '/livetv': 'http://localhost:32400',
      '/dvr': 'http://localhost:32400',
      '/library': 'http://localhost:32400',
    }
  }
})
