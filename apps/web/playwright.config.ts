import { defineConfig, devices } from "@playwright/test";
import { existsSync } from "node:fs";

const python = process.env.API_PYTHON || (existsSync("../../services/api/.venv-audit/bin/python")
  ? "../../services/api/.venv-audit/bin/python" : "python3");

export default defineConfig({
  testDir: "./tests/e2e",
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 60000,
  expect: { timeout: 15000 },
  reporter: "list",
  use: { baseURL: "http://127.0.0.1:3080", trace: "retain-on-failure",
    launchOptions: { executablePath: process.env.PLAYWRIGHT_EXECUTABLE_PATH || (process.platform === "darwin" && existsSync("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome") ? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" : undefined) },
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: [
    { command: `"${python}" ../../services/api/scripts/e2e_server.py`, url: "http://127.0.0.1:8091/health", reuseExistingServer: false },
    { command: process.env.E2E_DEV_SERVER === "1"
        ? "npm run dev -- --hostname 127.0.0.1 --port 3080"
        : "npm run build && npm run start -- --hostname 127.0.0.1 --port 3080",
      url: "http://127.0.0.1:3080/giris/kullanici",
      timeout: 180000, reuseExistingServer: false,
      env: { NEXT_PUBLIC_API_URL: "http://127.0.0.1:8091/api", NEXT_BUILD_DIR: ".next-e2e" } },
  ],
});
