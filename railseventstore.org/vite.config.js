import { defineConfig } from "vite";
import path from "path";

export default defineConfig({
  build: {
    outDir: ".tmp/dist",
    emptyOutDir: false,
    brotliSize: false,
    lib: {
      entry: path.resolve(__dirname, "source/index.js"),
      fileName: () => "index.js",
      formats: ["es"],
    },
  },
});
