import Link from "next/link";
import {
  ArrowRight,
  CalendarDays,
  MessageSquare,
  ShieldCheck,
} from "lucide-react";
import { MarketplaceIntro } from "@/components/marketplace-intro";
import { Button } from "@/components/ui/button";

const steps = [
  {
    icon: ShieldCheck,
    number: "01",
    title: "Önce güven",
    description:
      "Profilini oluştur, doğrulama sürecini tamamla. Kimliği doğrulanmış üyelerle aynı toplulukta buluş.",
  },
  {
    icon: MessageSquare,
    number: "02",
    title: "Doğrudan iletişim",
    description:
      "İlanın detaylarını incele, sorularını satıcıya sor. Yanıt bilgilerini ve güven puanını birlikte değerlendir.",
  },
  {
    icon: CalendarDays,
    number: "03",
    title: "Planlı bir buluşma",
    description:
      "Aracı görmek için uygun bir randevu oluştur. Görüşme öncesinde yer ve zamanı netleştir.",
  },
];

export default function HomePage() {
  return (
    <div className="container">
      <MarketplaceIntro />
      <section className="border-t border-border py-12 sm:py-16">
        <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="market-eyebrow text-accent">
              HER ADIMDA DAHA FAZLA GÜVEN
            </p>
            <h2 className="mt-3 text-2xl font-semibold tracking-tight sm:text-3xl">
              İyi bir alışveriş, iyi bir tanışmayla başlar.
            </h2>
          </div>
          <Link
            href="/yardim"
            className="inline-flex items-center gap-2 text-sm font-semibold text-text-muted hover:text-foreground"
          >
            Nasıl çalışır?
            <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
        <div className="grid gap-5 md:grid-cols-3">
          {steps.map(({ icon: Icon, ...step }) => (
            <article
              key={step.number}
              className="rounded-xl border border-border bg-surface p-6 sm:p-7"
            >
              <div className="flex items-center justify-between">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-accent-light text-accent">
                  <Icon className="h-5 w-5" />
                </span>
                <span className="font-display text-xl text-border-strong">
                  {step.number}
                </span>
              </div>
              <h3 className="mt-6 text-lg font-semibold">{step.title}</h3>
              <p className="mt-3 text-sm leading-7 text-text-muted">
                {step.description}
              </p>
            </article>
          ))}
        </div>
      </section>
      <section className="mb-12 flex flex-col items-start justify-between gap-6 rounded-2xl bg-primary p-7 text-primary-foreground sm:flex-row sm:items-center sm:p-10 dark:border dark:border-border dark:bg-surface">
        <div>
          <h2 className="text-2xl font-semibold text-primary-foreground dark:text-foreground">
            Yeni bir başlangıca yer aç.
          </h2>
          <p className="mt-2 text-sm text-primary-foreground/75 dark:text-text-muted">
            Aracını satmak ya da bir sonrakini bulmak için topluluğa katıl.
          </p>
        </div>
        <Button asChild variant="secondary" size="lg">
          <Link href="/uye-ol">
            Hesap oluştur
            <ArrowRight className="h-4 w-4" />
          </Link>
        </Button>
      </section>
    </div>
  );
}
