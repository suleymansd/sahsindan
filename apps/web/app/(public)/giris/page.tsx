import Link from "next/link";
import { ArrowRight, Shield, ShieldCheck, User } from "lucide-react";

const PANELS = [
  {
    href: "/giris/kullanici",
    title: "Kullanıcı Girişi",
    description: "İlan akışı, mesajlar ve randevu modüllerine erişim.",
    icon: User,
    badge: "Üye",
    tone: "primary" as const,
  },
  {
    href: "/giris/moderator",
    title: "Moderatör Girişi",
    description: "İlan, rapor ve doğrulama süreçlerinin operasyon yönetimi.",
    icon: Shield,
    badge: "Moderatör",
    tone: "accent" as const,
  },
  {
    href: "/giris/admin",
    title: "Admin Girişi",
    description: "Sistem ayarları, kritik yönetim işlemleri ve tam yetki.",
    icon: ShieldCheck,
    badge: "Admin",
    tone: "success" as const,
  },
];

const TONE = {
  primary: "bg-primary-light text-primary",
  accent: "bg-accent-light text-accent",
  success: "bg-success-bg text-success",
} as const;

export default function LoginSelectorPage() {
  return (
    <div className="container py-12 md:py-16">
      <div className="mx-auto max-w-5xl space-y-10">
        <div className="text-center">
          <div className="inline-flex items-center rounded-full border border-primary/20 bg-primary-light px-2.5 py-0.5 text-[11px] font-semibold text-primary">
            Ayrık rol panelleri
          </div>
          <h1 className="mt-4 font-display text-display-md font-bold tracking-tight text-foreground md:text-display-lg">
            Giriş panelini rolüne göre seç
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-body-lg text-text-muted">
            Üye, moderatör ve admin panelleri tamamen ayrık akışlarda çalışır. Yanlış panelden giriş
            denendiğinde oturum otomatik sonlandırılır.
          </p>
        </div>

        <div className="grid gap-4 md:grid-cols-3">
          {PANELS.map((panel) => {
            const Icon = panel.icon;
            return (
              <Link
                key={panel.href}
                href={panel.href}
                className="group block panel-glass p-6 transition-all duration-200 hover:-translate-y-0.5 hover:border-border-strong hover:shadow-card-hover"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${TONE[panel.tone]}`}>
                    <Icon className="h-5 w-5" strokeWidth={2} />
                  </div>
                  <span className="inline-flex items-center rounded-full border border-border bg-surface-2 px-2.5 py-0.5 text-[11px] font-semibold text-text-muted">
                    {panel.badge}
                  </span>
                </div>
                <h2 className="mt-5 text-title-md text-foreground">{panel.title}</h2>
                <p className="mt-2 text-body-md text-text-muted">{panel.description}</p>
                <div className="mt-5 inline-flex items-center gap-1 text-sm font-semibold text-primary">
                  Panele git
                  <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" />
                </div>
              </Link>
            );
          })}
        </div>
      </div>
    </div>
  );
}
