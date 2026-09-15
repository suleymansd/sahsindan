import { defineRailway, image, project, service, volume } from "railway/iac";

// This file is a deployment plan, not a billing cap. Applying it starts billed
// resources. No automatic apply workflow is installed.
const region = "europe-west4";
const MiB = 1024 * 1024;
const small = (memoryMiB: number, cpu: number) => ({
  region,
  numReplicas: 1,
  restartPolicyType: "ON_FAILURE" as const,
  restartPolicyMaxRetries: 2,
  limitOverride: { containers: { cpu, memoryBytes: memoryMiB * MiB } },
});

export default defineRailway((ctx) => {
  if (ctx.projectId !== "87da6148-dba9-4e45-b6cf-f42e7819b820" || ctx.environment !== "production") {
    throw new Error("This configuration belongs only to sahsindan / production.");
  }
  const databaseDisk = volume("database-data", { region, sizeMB: 1024 });
  const redisDisk = volume("redis-data", { region, sizeMB: 512 });
  const uploads = volume("uploads", { region, sizeMB: 1024 });
  const db = service("postgres", {
    source: image("postgres:16-alpine", { autoUpdates: { type: "disabled" } }),
    start: "docker-entrypoint.sh postgres -c max_connections=30 -c shared_buffers=32MB -c work_mem=2MB -c statement_timeout=15000 -c idle_in_transaction_session_timeout=30000",
    deploy: small(256, 0.5),
    env: {
      POSTGRES_DB: "sahsindan", POSTGRES_USER: "sahsindan",
      POSTGRES_PASSWORD: ctx.shared.DATABASE_PASSWORD,
      PGDATA: "/var/lib/postgresql/data/pgdata",
    },
    volumeMounts: { "/var/lib/postgresql/data": databaseDisk },
  });
  const cache = service("redis", {
    source: image("redis:7.4.11-alpine", { autoUpdates: { type: "disabled" } }),
    // REDIS_PASSWORD must be a URL-safe random secret. The quoted shell
    // expansion does not evaluate the password as shell code.
    start: 'sh -c \'exec docker-entrypoint.sh redis-server --requirepass "$REDIS_PASSWORD" --appendonly yes --appendfsync always --maxmemory 32mb --maxmemory-policy noeviction\'',
    deploy: small(128, 0.25),
    env: { REDIS_PASSWORD: ctx.shared.REDIS_PASSWORD },
    volumeMounts: { "/data": redisDisk },
  });
  const api = service("api", {
    // Deliberately no GitHub source: upload reviewed code manually with
    // `railway up services/api --path-as-root --service api` after activation.
    build: { builder: "DOCKERFILE", dockerfilePath: "Dockerfile" },
    start: "python scripts/railway_start.py",
    preDeploy: "alembic upgrade head",
    healthcheck: "/ready",
    healthcheckTimeout: 120,
    deploy: { ...small(512, 0.5), requiredMountPath: "/app/storage" },
    env: {
      APP_ENV: "production", PORT: "8000", RAILWAY_RUN_UID: "0",
      DATABASE_URL: "postgresql+psycopg://sahsindan:${{shared.DATABASE_PASSWORD}}@${{postgres.RAILWAY_PRIVATE_DOMAIN}}:5432/sahsindan",
      REDIS_URL: "redis://:${{shared.REDIS_PASSWORD}}@${{redis.RAILWAY_PRIVATE_DOMAIN}}:6379/0",
      JWT_SECRET: ctx.shared.JWT_SECRET,
      JWT_REFRESH_SECRET: ctx.shared.JWT_REFRESH_SECRET,
      MFA_ENCRYPTION_KEY: ctx.shared.MFA_ENCRYPTION_KEY,
      PUBLIC_API_URL: ctx.shared.PUBLIC_API_URL,
      PUBLIC_WEB_URL: ctx.shared.PUBLIC_WEB_URL,
      CORS_ORIGINS: ctx.shared.PUBLIC_WEB_URL,
      FALLBACK_IMAGE_URL: "${{shared.PUBLIC_WEB_URL}}/placeholder.png",
      DISABLE_STORAGE: "true", DISABLE_STALE_JOB: "true",
      VERIFICATION_MODE: "manual", VERIFICATION_RETENTION_DAYS: "30",
      SQLALCHEMY_POOL_SIZE: "2", SQLALCHEMY_MAX_OVERFLOW: "1",
      SQLALCHEMY_POOL_TIMEOUT: "5", SQLALCHEMY_POOL_RECYCLE: "300",
      API_DAILY_REQUEST_LIMIT: "10000", API_DAILY_RESPONSE_BYTES: "52428800",
      API_IP_REQUESTS_PER_MINUTE: "120", API_USER_REQUESTS_PER_MINUTE: "60",
      STORAGE_BUDGET_BYTES: "536870912",
      UPLOAD_GLOBAL_DAILY_BYTES: "52428800", UPLOAD_USER_DAILY_BYTES: "10485760",
      MAX_ACTIVE_LISTINGS_PER_USER: "5", MAX_FAVORITES_PER_USER: "100",
      WEBSOCKET_CONNECTIONS_PER_USER: "2", SMTP_DAILY_MESSAGE_LIMIT: "10",
      SMTP_HOST: "", SMTP_SENDER: "", SMTP_USERNAME: "", SMTP_PASSWORD: "",
    },
    volumeMounts: { "/app/storage": uploads },
  });
  const web = service("web", {
    build: { builder: "DOCKERFILE", dockerfilePath: "Dockerfile" },
    start: "node server.js",
    healthcheck: "/giris/kullanici",
    healthcheckTimeout: 120,
    deploy: { ...small(256, 0.5), sleepApplication: true },
    env: {
      PORT: "3000", HOSTNAME: "0.0.0.0", NODE_ENV: "production",
      NEXT_TELEMETRY_DISABLED: "1",
      NEXT_PUBLIC_API_URL: "${{shared.PUBLIC_API_URL}}/api",
    },
  });
  return project("sahsindan", { resources: [db, cache, api, web, databaseDisk, redisDisk, uploads] });
});
