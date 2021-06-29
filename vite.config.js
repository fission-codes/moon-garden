import { defineConfig } from 'vite'
import * as elmPlugin from 'vite-plugin-elm'

export default defineConfig({
  plugins: [elmPlugin.plugin()],
})
