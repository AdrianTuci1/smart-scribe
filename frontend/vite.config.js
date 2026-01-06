import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { ViteImageOptimizer } from 'vite-plugin-image-optimizer';

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    ViteImageOptimizer({
      /* pass your config */
    }),
    react(),
    tailwindcss(),
  ],
  define: {
    global: 'window',
  },
})
