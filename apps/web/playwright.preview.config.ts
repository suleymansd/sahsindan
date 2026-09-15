import { defineConfig } from "@playwright/test";
import base from "./playwright.config";

const liveUrl = process.env.PUBLICATION_BASE_URL;

export default defineConfig({
  ...base,
  testDir: "./tests/preview",
  use: { ...base.use, baseURL: liveUrl || "http://127.0.0.1:3080" },
  webServer: liveUrl ? undefined : {
    command: "npm run build && npm run start -- --hostname 127.0.0.1 --port 3080",
    url: "http://127.0.0.1:3080/giris/kullanici",
    timeout: 180000,
    reuseExistingServer: false,
    env: { NEXT_PUBLIC_API_URL: "", NEXT_BUILD_DIR: ".next-e2e" },
  },
});
