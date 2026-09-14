"use client";

import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";

import { apiFetch, refreshSession } from "@/lib/api";

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
  login: (email: string, password: string, expectedRoles?: string[], otpCode?: string) => Promise<UserSummary>;
  register: (payload: Record<string, string>) => Promise<void>;
  refresh: (options?: { silent?: boolean }) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const queryClient = useQueryClient();
  const [user, setUser] = useState<UserSummary | null>(null);
  const [accessToken, setAccessToken] = useState<string | null>(null);
  const [status, setStatus] = useState<"loading" | "authenticated" | "unauthenticated">("loading");
  const generation = useRef(0);

  const login = useCallback(async (email: string, password: string, expectedRoles?: string[], otpCode?: string) => {
    const current = ++generation.current;
    const res = await apiFetch("/auth/login", {
      method: "POST",
      skipAuthRedirect: true,
      body: JSON.stringify({ email, password, ...(otpCode ? { otp_code: otpCode } : {}) }),
    });
    const nextUser = res.data.user as UserSummary;
    if (expectedRoles && !expectedRoles.includes(nextUser.role)) return nextUser;
    if (current !== generation.current) return nextUser;
    queryClient.clear();
    setAccessToken(res.data.access_token);
    setUser(nextUser);
    setStatus("authenticated");
    return nextUser;
  }, [queryClient]);

  const register = useCallback(async (payload: Record<string, string>) => {
    const current = ++generation.current;
    const res = await apiFetch("/auth/register", {
      method: "POST",
      body: JSON.stringify(payload),
    });
    if (current !== generation.current) return;
    queryClient.clear();
    setAccessToken(res.data.access_token);
    setUser(res.data.user);
    setStatus("authenticated");
  }, [queryClient]);

  const refresh = useCallback(async (options?: { silent?: boolean }) => {
    const current = ++generation.current;
    const res = await refreshSession();
    const me = await apiFetch("/auth/me", {
      headers: { Authorization: `Bearer ${res.data.access_token}` },
      skipAuthRedirect: options?.silent,
    });
    if (current !== generation.current) return;
    setAccessToken(res.data.access_token);
    setUser(me.data);
    setStatus("authenticated");
  }, []);

  const logout = useCallback(async () => {
    ++generation.current;
    try {
      await apiFetch("/auth/logout", { method: "POST", skipAuthRedirect: true });
    } finally {
      queryClient.clear();
      setAccessToken(null);
      setUser(null);
      setStatus("unauthenticated");
    }
  }, [queryClient]);

  const value = useMemo(
    () => ({ user, accessToken, status, login, register, refresh, logout }),
    [user, accessToken, status, login, register, refresh, logout]
  );

  useEffect(() => {
    const bootstrap = refresh({ silent: true });
    const current = generation.current;
    bootstrap.catch(() => {
      if (current !== generation.current) return;
      setUser(null);
      setAccessToken(null);
      setStatus("unauthenticated");
    });
    const sessionGeneration = generation;
    return () => { ++sessionGeneration.current; };
  }, [refresh]);

  useEffect(() => {
    function handleLogout() {
      ++generation.current;
      queryClient.clear();
      setUser(null);
      setAccessToken(null);
      setStatus("unauthenticated");
    }
    function handleToken(event: Event) {
      setAccessToken((event as CustomEvent<string>).detail);
    }
    window.addEventListener("auth:logout", handleLogout);
    window.addEventListener("auth:token", handleToken);
    return () => {
      window.removeEventListener("auth:logout", handleLogout);
      window.removeEventListener("auth:token", handleToken);
    };
  }, [queryClient]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("AuthProvider missing");
  }
  return ctx;
}
