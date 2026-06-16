import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'
import { fileURLToPath } from 'url'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const backendTarget = env.VITE_BACKEND_TARGET || 'http://127.0.0.1:9090'
  const publicBase = normalizeBase(env.VITE_PUBLIC_BASE || '/')
  const __filename = fileURLToPath(import.meta.url)
  const __dirname = path.dirname(__filename)

  return {
    base: publicBase,
    plugins: [vue()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
    server: {
      port: 8084,
      strictPort: true,
      proxy: {
        '/api': {
          target: backendTarget,
          changeOrigin: true,
          rewrite: (p) => p.replace(/^\/api\/dev-api\/auth/, '/auth'),
        },
        '/dev-api': {
          target: backendTarget,
          changeOrigin: true,
          rewrite: (p) => p.replace(/^\/dev-api/, ''),
        },
        '/auth': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/login': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/smsLogin': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/emailLogin': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/checkPhone': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/resetPwd': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/captchaImage': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/register': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/open': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/system': {
          target: backendTarget,
          changeOrigin: true,
        },
        '/train': {
          target: backendTarget,
          changeOrigin: true,
        },
      },
    },
    build: {
      outDir: 'dist',
      sourcemap: false,
      rollupOptions: {
        output: {
          manualChunks(id) {
            if (!id.includes('node_modules')) return
            if (id.includes('element-plus')) return 'element-plus'
            if (id.includes('chart.js')) return 'chartjs'
            if (id.includes('jspdf')) return 'jspdf'
            if (id.includes('html2canvas')) return 'html2canvas'
            if (id.includes('/quill/') || id.includes('quill')) return 'quill'
            return 'vendor'
          }
        }
      },
      chunkSizeWarningLimit: 800
    },
    esbuild: mode === 'production'
      ? { drop: ['console', 'debugger'] }
      : undefined,
    define: {
      __APP_TITLE__: JSON.stringify('华智酒店及度假村员工培训平台'),
    },
  }
})

function normalizeBase(value) {
  if (!value) return '/'
  const normalized = value.startsWith('/') ? value : `/${value}`
  return normalized.endsWith('/') ? normalized : `${normalized}/`
}
