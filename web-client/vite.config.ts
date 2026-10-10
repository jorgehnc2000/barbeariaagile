import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath, URL } from 'node:url';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  optimizeDeps: {
    exclude: ['lucide-react'],
  },
  server: {
    proxy: {
      '/api/mp/card_tokens': {
        target: 'https://api.mercadopago.com',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/mp\/card_tokens/, '/v1/card_tokens'),
      },
      '/api/create-subscription': {
        target: 'https://rgrhalzcbhhydizlgztn.supabase.co',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/create-subscription/, '/functions/v1/create-subscription'),
      },
    },
  },
});
