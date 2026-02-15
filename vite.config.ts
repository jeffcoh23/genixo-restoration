import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  plugins: [RubyPlugin(), react(), tailwindcss()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./app/frontend", import.meta.url)),
    },
  },
  server: {
    hmr: { overlay: true },
  },
});
