"use client";

import { RouteGuard } from "@/components/route-guard";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { API_CONFIGURED } from "@/lib/api";

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <RouteGuard mode="public">
      <div className="public-shell flex min-h-screen flex-col">
        <SiteHeader />
        {!API_CONFIGURED && (
          <div role="status" className="border-b border-border bg-primary-light px-4 py-3 text-center text-sm text-foreground">
            Tanıtım yayını: Üyelik, giriş ve ilan işlemleri henüz açık değil.
          </div>
        )}
        <main className="relative flex-1 animate-fade-in">{children}</main>
        <SiteFooter />
      </div>
    </RouteGuard>
  );
}
