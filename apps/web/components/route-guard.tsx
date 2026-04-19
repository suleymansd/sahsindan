"use client";

import { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";

import { useAuth } from "@/lib/auth";

type GuardMode = "public" | "pending" | "verified" | "admin" | "authenticated";

const VERIFIED_ROLES = new Set(["USER_VERIFIED", "ADMIN", "MODERATOR"]);
const ADMIN_ROLES = new Set(["ADMIN", "MODERATOR"]);

function LoadingScreen() {
  return (
    <div className="flex min-h-screen items-center justify-center px-4">
      <div className="rounded-card border border-border/70 bg-surface/90 px-5 py-3 text-sm font-semibold text-text-muted shadow-soft">
        Yukleniyor...
      </div>
    </div>
  );
}

export function RouteGuard({ mode, children }: { mode: GuardMode; children: React.ReactNode }) {
  const { user, status } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  const isBanned = user?.role === "BANNED" || user?.status === "SUSPENDED";

  useEffect(() => {
    if (status === "loading") return;

    const loginPath = mode === "admin" ? "/giris/admin" : "/giris/kullanici";

    if (mode === "public") {
      if (user?.role === "USER_PENDING") {
        router.replace("/durum");
      } else if (user && ADMIN_ROLES.has(user.role)) {
        router.replace("/admin");
      } else if (user && VERIFIED_ROLES.has(user.role)) {
        router.replace("/app");
      }
      return;
    }

    if (!user) {
      router.replace(`${loginPath}?redirect=${encodeURIComponent(pathname || "/")}`);
      return;
    }

    if (mode === "pending") {
      if (user.role !== "USER_PENDING") {
        router.replace(VERIFIED_ROLES.has(user.role) ? "/app" : "/giris/kullanici");
      }
      return;
    }

    if (mode === "authenticated") {
      if (isBanned) {
        router.replace("/giris/kullanici");
      }
      return;
    }

    if (mode === "verified") {
      if (!VERIFIED_ROLES.has(user.role)) {
        router.replace(user.role === "USER_PENDING" ? "/durum" : "/giris/kullanici");
      }
      return;
    }

    if (mode === "admin") {
      if (!ADMIN_ROLES.has(user.role)) {
        router.replace("/403");
      }
    }
  }, [mode, pathname, router, status, user]);

  if (status === "loading") return <LoadingScreen />;

  if (mode === "public") {
    if (user?.role === "USER_PENDING" || (user && VERIFIED_ROLES.has(user.role))) {
      return <LoadingScreen />;
    }
    return <>{children}</>;
  }

  if (!user) return <LoadingScreen />;

  if (mode === "pending" && user.role !== "USER_PENDING") return <LoadingScreen />;
  if (mode === "authenticated" && isBanned) return <LoadingScreen />;
  if (mode === "verified" && !VERIFIED_ROLES.has(user.role)) return <LoadingScreen />;
  if (mode === "admin" && !ADMIN_ROLES.has(user.role)) return <LoadingScreen />;

  return <>{children}</>;
}
