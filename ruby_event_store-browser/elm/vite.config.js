import { defineConfig } from "vite";
import path from "path";
import elmPlugin from "vite-plugin-elm";

export default defineConfig({
  build: {
    outDir: "../public",
    emptyOutDir: false,
    brotliSize: false,
    lib: {
      entry: path.resolve(__dirname, "src/index.js"),
      fileName: () => "ruby_event_store_browser.js",
      formats: ["es"],
    },
    rollupOptions: {
      output: {
        assetFileNames: (assetInfo) => {
          if (assetInfo.name == "style.css")
            return "ruby_event_store_browser.css";
          return assetInfo.name;
        },
      },
    },
  },
  plugins: [elmPlugin()],
});
