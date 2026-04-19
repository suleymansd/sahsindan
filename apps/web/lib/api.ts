export const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:8080/api";

type ApiOptions = RequestInit & { skipAuthRedirect?: boolean };

export async function apiFetch(path: string, options: ApiOptions = {}) {
  const { skipAuthRedirect, ...init } = options;
  try {
    const res = await fetch(`${API_URL}${path}`, {
      ...init,
      headers: {
        "Content-Type": "application/json",
        ...(init.headers || {}),
      },
      credentials: "include",
    });

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
  return apiFetch(path, {
    ...options,
    headers: {
      ...(options.headers || {}),
      Authorization: `Bearer ${token}`,
    },
  });
}
