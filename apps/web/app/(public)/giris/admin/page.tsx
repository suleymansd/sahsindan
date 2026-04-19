"use client";

import { ShieldCheck } from "lucide-react";

import { RoleLoginPanel } from "@/components/auth/role-login-panel";
import type { UserSummary } from "@/lib/auth";

function resolveAdminRedirect(_user: UserSummary, redirectParam: string | null) {
  if (redirectParam && redirectParam.startsWith("/admin")) {
    return redirectParam;
  }
  return "/admin";
}

const POINTS = [
  "Platform ayarları ve politika yönetimi",
  "Tüm moderasyon ve rapor yetkileri",
  "Kritik sistem operasyonları",
];

export default function AdminLoginPage() {
  return (
    <div className="container py-10 md:py-16">
      <div className="mx-auto grid max-w-5xl gap-6 md:grid-cols-[1.05fr_0.95fr] md:items-start">
        <RoleLoginPanel
          badge="Admin Paneli"
          title="Admin Girişi"
          description="Sistem ayarları ve tam yetkili yönetim işlemleri için admin panel girişi."
          icon={ShieldCheck}
          expectedRoles={["ADMIN"]}
          roleErrorMessage="Bu hesap admin paneline ait değil."
          resolveRedirect={resolveAdminRedirect}
          secondaryLabel="Diğer paneller"
          secondaryHref="/giris"
        />

        <aside className="panel-glass p-6 md:p-8">
          <div className="icon-3d text-success">
            <ShieldCheck className="h-5 w-5" strokeWidth={2} />
          </div>
          <h2 className="mt-5 text-title-md text-foreground">Admin panel kapsamı</h2>
          <ul className="mt-4 space-y-2">
            {POINTS.map((p) => (
              <li key={p} className="rounded-xl border border-border/70 bg-surface-2/80 px-3 py-2.5 text-sm text-text-muted">
                {p}
              </li>
            ))}
          </ul>
        </aside>
      </div>
    </div>
  );
}
