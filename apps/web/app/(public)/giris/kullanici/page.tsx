"use client";

import { ArrowUpRight, CalendarDays, ShieldCheck, User } from "lucide-react";
import Link from "next/link";
import { RoleLoginPanel } from "@/components/auth/role-login-panel";
import type { UserSummary } from "@/lib/auth";

function resolveUserRedirect(user: UserSummary, redirectParam: string | null) {
  if (user.role === "USER_PENDING") return "/durum";
  if (
    redirectParam &&
    redirectParam.startsWith("/") &&
    !redirectParam.startsWith("/admin")
  )
    return redirectParam;
  return "/app";
}

export default function UserLoginPage() {
  return (
    <div className="container py-10 sm:py-16">
      <div className="mx-auto grid max-w-5xl overflow-hidden rounded-2xl border border-border bg-surface md:grid-cols-2">
        <aside className="flex flex-col justify-between bg-[#1a2b47] p-8 text-white sm:p-12">
          <div>
            <span className="market-eyebrow text-[#6ee7b7]">
              ŞAHSINDAN. GÜVENLE.
            </span>
            <h2 className="mt-7 text-3xl font-semibold leading-tight tracking-tight text-white lg:text-4xl">
              Bir sonraki aracına,
              <br />
              <span className="text-[#67d8ed]">bir adım daha yakın.</span>
            </h2>
            <p className="mt-5 max-w-sm text-sm leading-7 text-slate-300">
              Güven veren bir topluluk, doğrudan iletişim ve sana uygun araçlar.
            </p>
          </div>
          <div className="mt-12 space-y-5">
            <div className="flex items-center gap-3 text-sm text-slate-200">
              <ShieldCheck className="h-5 w-5 text-[#6ee7b7]" />
              Kimliği doğrulanmış üyeler
            </div>
            <div className="flex items-center gap-3 text-sm text-slate-200">
              <CalendarDays className="h-5 w-5 text-[#6ee7b7]" />
              Planlı görüşmeler, net iletişim
            </div>
            <Link
              href="/yardim"
              className="mt-8 inline-flex items-center gap-2 border-t border-white/15 pt-6 text-xs text-slate-300 hover:text-white"
            >
              Topluluğu tanı
              <ArrowUpRight className="h-4 w-4" />
            </Link>
          </div>
        </aside>
        <div className="flex items-center p-2 sm:p-5 [&>div]:w-full [&>div]:border-0 [&>div]:shadow-none">
          <RoleLoginPanel
            badge="TEKRAR HOŞ GELDİN"
            title="Hesabına giriş yap"
            description="Kaldığın yerden güvenle devam et."
            icon={User}
            expectedRoles={["USER_VERIFIED", "USER_PENDING"]}
            roleErrorMessage="Bu hesap kullanıcı paneline ait değil. Lütfen doğru giriş panelini seç."
            resolveRedirect={resolveUserRedirect}
            secondaryLabel="Diğer paneller"
            secondaryHref="/giris"
          />
        </div>
      </div>
    </div>
  );
}
