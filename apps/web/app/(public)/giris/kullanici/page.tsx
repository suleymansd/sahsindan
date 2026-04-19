"use client";

import { User } from "lucide-react";

import { RoleLoginPanel } from "@/components/auth/role-login-panel";
import type { UserSummary } from "@/lib/auth";

function resolveUserRedirect(user: UserSummary, redirectParam: string | null) {
  if (user.role === "USER_PENDING") return "/durum";
  if (redirectParam && redirectParam.startsWith("/") && !redirectParam.startsWith("/admin")) {
    return redirectParam;
  }
  return "/app";
}

const POINTS = [
  "Doğrulanmış kullanıcılar",
  "Doğrulama sürecindeki kullanıcılar",
  "İlan, mesaj ve randevu akışına erişen tüm üyeler",
];

export default function UserLoginPage() {
  return (
    <div className="container py-10 md:py-16">
      <div className="mx-auto grid max-w-5xl gap-6 md:grid-cols-[1.05fr_0.95fr] md:items-start">
        <RoleLoginPanel
          badge="Kullanıcı Paneli"
          title="Kullanıcı Girişi"
          description="Üye paneline erişim için bu giriş ekranını kullan."
          icon={User}
          expectedRoles={["USER_VERIFIED", "USER_PENDING"]}
          roleErrorMessage="Bu hesap kullanıcı paneline ait değil. Lütfen doğru giriş panelini seç."
          resolveRedirect={resolveUserRedirect}
          secondaryLabel="Diğer paneller"
          secondaryHref="/giris"
        />

        <aside className="panel-glass p-6 md:p-8">
          <div className="icon-3d text-primary">
            <User className="h-5 w-5" strokeWidth={2} />
          </div>
          <h2 className="mt-5 text-title-md text-foreground">Bu panel kimler için?</h2>
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
