"use client";

import { ShieldCheck, TimerReset, UserCheck } from "lucide-react";

export function TrustBand() {
  const items = [
    {
      title: "Kimlik doğrulanmış üyeler",
      description: "Her üye ilan görmeden önce onaydan geçer.",
      icon: UserCheck,
    },
    {
      title: "Şeffaf güven skoru",
      description: "Randevu ve raporlar skora yansır.",
      icon: ShieldCheck,
    },
    {
      title: "Yanıt süresi görünür",
      description: "Satıcının ortalama cevap hızı her ilanda net.",
      icon: TimerReset,
    },
  ];

  return (
    <div className="panel-glass p-6">
      <div className="grid gap-6 md:grid-cols-3 lg:grid-cols-1 xl:grid-cols-1">
        {items.map((item) => {
          const Icon = item.icon;
          return (
            <div key={item.title} className="flex items-start gap-3">
              <div className="icon-3d shrink-0 text-primary">
                <Icon className="h-5 w-5" strokeWidth={1.8} />
              </div>
              <div className="space-y-0.5">
                <div className="text-sm font-semibold text-foreground">{item.title}</div>
                <div className="text-xs leading-relaxed text-text-muted">{item.description}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
