"use client";

import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";

import { apiFetch, apiFetchWithAuth } from "@/lib/api";

export type UserSummary = {
  id: number;
  email: string;
  phone: string;
  name?: string | null;
  role: string;
  status?: string;
  trust_score: number;
};

type AuthContextValue = {
  user: UserSummary | null;
  accessToken: string | null;
  status: "loading" | "authenticated" | "unauthenticated";
  login: (email: string, password: string) => Promise<UserSummary>;
  register: (payload: Record<string, string>) => Promise<void>;
  refresh: (options?: { silent?: boolean }) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<UserSummary | null>(null);
  const [accessToken, setAccessToken] = useState<string | null>(null);
  const [status, setStatus] = useState<"loading" | "authenticated" | "unauthenticated">("loading");

  const login = useCallback(async (email: string, password: string) => {
    const res = await apiFetch("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
    const nextUser = res.data.user as UserSummary;
    setAccessToken(res.data.access_token);
    setUser(nextUser);
    setStatus("authenticated");
    return nextUser;
  }, []);

  const register = useCallback(async (payload: Record<string, string>) => {
    const res = await apiFetch("/auth/register", {
      method: "POST",
      body: JSON.stringify(payload),
    });
    setAccessToken(res.data.access_token);
    setUser(res.data.user);
    setStatus("authenticated");
  }, []);

  const refresh = useCallback(async (options?: { silent?: boolean }) => {
    const res = await apiFetch("/auth/refresh", {
      method: "POST",
      skipAuthRedirect: options?.silent,
    });
    setAccessToken(res.data.access_token);
    const me = await apiFetchWithAuth("/auth/me", res.data.access_token);
    setUser(me.data);
    setStatus("authenticated");
  }, []);

  const logout = useCallback(async () => {
    await apiFetch("/auth/logout", { method: "POST" });
    setAccessToken(null);
    setUser(null);
    setStatus("unauthenticated");
  }, []);

  const value = useMemo(
    () => ({ user, accessToken, status, login, register, refresh, logout }),
    [user, accessToken, status, login, register, refresh, logout]
  );

  useEffect(() => {
    const authBootstrap = Promise.race([
      refresh({ silent: true }),
      new Promise<never>((_, reject) => {
        setTimeout(() => reject(new Error("auth_bootstrap_timeout")), 4000);
      }),
    ]);

    authBootstrap.catch(() => {
      setUser(null);
      setAccessToken(null);
      setStatus("unauthenticated");
    });
  }, [refresh]);

  useEffect(() => {
    if (status !== "loading") return;
    const timeout = setTimeout(() => {
      setStatus((prev) => (prev === "loading" ? "unauthenticated" : prev));
    }, 5000);
    return () => clearTimeout(timeout);
  }, [status]);

  useEffect(() => {
    function handleLogout() {
      setUser(null);
      setAccessToken(null);
      setStatus("unauthenticated");
    }
    window.addEventListener("auth:logout", handleLogout);
    return () => window.removeEventListener("auth:logout", handleLogout);
  }, []);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("AuthProvider missing");
  }
  return ctx;
}
