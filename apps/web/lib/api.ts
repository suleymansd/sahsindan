const configuredApiUrl = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:8080/api";
export const API_URL = configuredApiUrl.startsWith("/") && typeof window !== "undefined"
  ? `${window.location.origin}${configuredApiUrl}` : configuredApiUrl;

type ApiOptions = RequestInit & { skipAuthRedirect?: boolean };

let refreshing: Promise<any> | null = null;

export function refreshSession() {
  if (!refreshing) {
    refreshing = apiFetch("/auth/refresh", { method: "POST", skipAuthRedirect: true })
      .finally(() => { refreshing = null; });
  }
  return refreshing;
}

export async function apiFetch(path: string, options: ApiOptions = {}) {
  const { skipAuthRedirect, ...init } = options;
  try {
    const headers = new Headers(init.headers);
    if (!(init.body instanceof FormData) && !headers.has("Content-Type")) {
      headers.set("Content-Type", "application/json");
    }
    const request = {
      ...init,
      headers,
      credentials: "include" as const,
      signal: init.signal || AbortSignal.timeout(15000),
    };
    let res = await fetch(`${API_URL}${path}`, request);

    if (res.status === 401 && headers.has("Authorization") && path !== "/auth/refresh") {
      try {
        const refreshed = await refreshSession();
        headers.set("Authorization", `Bearer ${refreshed.data.access_token}`);
        if (typeof window !== "undefined") {
          window.dispatchEvent(new CustomEvent("auth:token", { detail: refreshed.data.access_token }));
        }
        res = await fetch(`${API_URL}${path}`, { ...request, headers });
      } catch (error) {
        // A service outage should not destroy a valid session.
        if (!(error instanceof Error) || error.message !== "Invalid session") throw error;
      }
    }

    if (res.status === 401 && path === "/auth/refresh") throw new Error("Invalid session");

    if (res.status === 401 && !skipAuthRedirect && typeof window !== "undefined") {
      const nextPath = window.location.pathname.startsWith("/admin") ? "/giris/admin" : "/giris/kullanici";
      const redirectTo = `${window.location.pathname}${window.location.search || ""}`;
      window.dispatchEvent(new CustomEvent("auth:logout"));
      window.location.href = `${nextPath}?redirect=${encodeURIComponent(redirectTo)}`;
      throw new Error("Unauthorized");
    }

    if (!res.ok) {
      const payload = await res.json().catch(() => ({}));
      throw new Error(payload?.error?.message || `Request failed with status ${res.status}`);
    }

    return res.json();
  } catch (error) {
    if (error instanceof TypeError && error.message.includes("fetch")) {
      throw new Error("Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.");
    }
    throw error;
  }
}

export async function apiFetchWithAuth(path: string, token: string, options: RequestInit = {}) {
  const headers = new Headers(options.headers);
  headers.set("Authorization", `Bearer ${token}`);
  return apiFetch(path, {
    ...options,
    headers,
  });
}
