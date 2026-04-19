"use client";

import { RouteGuard } from "@/components/route-guard";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <RouteGuard mode="verified">
      <div className="app-shell flex min-h-screen flex-col">
        <SiteHeader />
        <main className="relative flex-1 animate-fade-in">{children}</main>
        <SiteFooter />
      </div>
    </RouteGuard>
  );
}
