import { defineConfig } from 'vite'
import * as elmPlugin from 'vite-plugin-elm'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url';

const currentDir = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  plugins: [elmPlugin.plugin()],
  build: {
    target: 'es2020',
    rollupOptions: {
      input: {
        main: resolve(currentDir, 'index.html'),
        view_test: resolve(currentDir, 'view_test.html'),
        viewer: resolve(currentDir, 'viewer/index.html'),
      }
    }
  }
})
