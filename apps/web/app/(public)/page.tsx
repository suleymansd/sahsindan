import Link from "next/link";
import {
  ArrowRight,
  BadgeCheck,
  Calendar,
  MessageSquare,
  RefreshCw,
  Search,
  ShieldCheck,
  Sparkles,
  TrendingUp,
  UserCheck,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

const features = [
  {
    icon: UserCheck,
    title: "Kimlik doğrulanmış üyeler",
    description:
      "Her üye kimlik ve meslek doğrulamasından geçer. Fake profil, tekrar hesap, amatör satıcı yok.",
  },
  {
    icon: MessageSquare,
    title: "Net iletişim",
    description:
      "Satıcının ortalama yanıt süresi ve son aktifliği görünür. Cevap gelmezse saat kaç olduğunu sen de biliyorsun.",
  },
  {
    icon: Calendar,
    title: "Planlı randevu",
    description:
      "Test sürüşü, pazarlık ve ekspertiz için takvim üzerinden randevu. No-show -> güven skoru düşer.",
  },
  {
    icon: RefreshCw,
    title: "Taze ilanlar",
    description:
      "Satıcı 30 gün içinde ilanı yenilemezse arşive düşer. Eski stok, gereksiz mesaj yok.",
  },
  {
    icon: TrendingUp,
    title: "Şeffaf güven skoru",
    description:
      "Tamamlanan randevular skoru yükseltir. Şikayet ve no-show skoru düşürür. Her şey kamuya açık.",
  },
  {
    icon: ShieldCheck,
    title: "Moderasyon + raporlama",
    description: "Ekibimiz her ilanı görür; şüpheli davranışlar saat içinde kaldırılır.",
  },
];

const steps = [
  {
    num: "01",
    title: "Doğrulan",
    description: "Kimlik + meslek kontrolünden geç. Moderasyon onayı genelde birkaç saat.",
  },
  {
    num: "02",
    title: "Keşfet veya ilan ver",
    description: "Sadece doğrulanmış üyeler satıyor, sadece doğrulanmış üyeler mesajlaşıyor.",
  },
  {
    num: "03",
    title: "Görüş, pazarlık et",
    description: "Randevu al, ekspertiz yaptır, güvenli şekilde el sıkış.",
  },
];

export default function HomePage() {
  return (
    <div>
      <section className="relative overflow-hidden border-b border-border/70">
        <div className="pointer-events-none absolute inset-0 overflow-hidden">
          <div className="hero-orb hero-orb-primary animate-glow-shift left-[-140px] top-[-110px] h-[390px] w-[390px]" />
          <div className="hero-orb hero-orb-accent animate-glow-shift right-[-150px] top-[30px] h-[350px] w-[350px]" />
        </div>

        <div className="container relative py-16 md:py-24">
          <div className="mx-auto max-w-3xl text-center">
            <Badge variant="solid" size="lg" className="mx-auto inline-flex">
              <Sparkles className="h-3.5 w-3.5" />
              Doğrulanmış kapalı pazar
            </Badge>
            <h1 className="mt-6 font-display text-[42px] font-bold leading-[1.04] tracking-tight text-foreground sm:text-5xl md:text-6xl">
              Aracı değil,
              <span className="bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent"> güvenilir kişiyi </span>
              bul.
            </h1>
            <p className="mx-auto mt-5 max-w-2xl text-lg leading-relaxed text-text-muted">
              Kimliği doğrulanmış üyeler arasında güvenli alım-satım. Net iletişim, planlı randevu,
              taze ilanlar. Zaman kaybı yok.
            </p>
            <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
              <Button size="lg" asChild>
                <Link href="/uye-ol">
                  Üye Ol
                  <ArrowRight className="h-4 w-4" />
                </Link>
              </Button>
              <Button size="lg" variant="outline" asChild>
                <Link href="/giris">Giriş Yap</Link>
              </Button>
            </div>

            <div className="mt-10 flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm text-text-muted">
              <div className="inline-flex items-center gap-1.5">
                <BadgeCheck className="h-4 w-4 text-success" />
                Kimlik + meslek doğrulaması
              </div>
              <div className="inline-flex items-center gap-1.5">
                <ShieldCheck className="h-4 w-4 text-success" />
                WCAG AA erişilebilirlik
              </div>
              <div className="inline-flex items-center gap-1.5">
                <RefreshCw className="h-4 w-4 text-success" />
                Taze ilan garantisi
              </div>
            </div>
          </div>

          <div className="mx-auto mt-16 max-w-5xl">
            <div className="panel-glass p-2">
              <div className="rounded-2xl border border-border/70 bg-gradient-to-b from-surface to-surface-2 p-6 md:p-10">
                <div className="grid gap-6 md:grid-cols-3">
                  <MetricCard label="Yanıt süresi" value="< 2 saat" description="Ortalama satıcı cevap süresi" />
                  <MetricCard label="Doğrulanmış üye" value="%100" description="Her kullanıcı onay sürecinden geçer" />
                  <MetricCard label="Taze ilan" value="30 gün" description="Sonra yenileme ya da arşiv" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="container py-16 md:py-24">
        <div className="mx-auto max-w-2xl text-center">
          <div className="inline-block text-[11px] font-semibold uppercase tracking-wider text-primary">
            Neden şahsından.com
          </div>
          <h2 className="mt-3 font-display text-display-md tracking-tight text-foreground md:text-display-lg">
            Ciddi alıcı, ciddi satıcı. Başka kimse yok.
          </h2>
          <p className="mt-4 text-body-lg text-text-muted">
            Geleneksel pazarlarda zaman yiyen 4 büyük sorunu katmanlı bir güven altyapısıyla
            çözüyoruz.
          </p>
        </div>

        <div className="mx-auto mt-12 grid max-w-6xl gap-4 md:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => {
            const Icon = feature.icon;
            return (
              <div
                key={feature.title}
                className="group panel-glass p-6 transition-all duration-200 hover:-translate-y-0.5 hover:border-border-strong hover:shadow-card-hover"
              >
                <div className="icon-3d text-primary transition-transform duration-200 group-hover:scale-110">
                  <Icon className="h-5 w-5" strokeWidth={2} />
                </div>
                <h3 className="mt-5 text-title-md text-foreground">{feature.title}</h3>
                <p className="mt-2 text-body-md leading-relaxed text-text-muted">{feature.description}</p>
              </div>
            );
          })}
        </div>
      </section>

      <section className="border-y border-border/70 bg-surface/45 backdrop-blur-sm">
        <div className="container py-16 md:py-24">
          <div className="mx-auto max-w-2xl text-center">
            <div className="inline-block text-[11px] font-semibold uppercase tracking-wider text-accent">
              Nasıl çalışıyor
            </div>
            <h2 className="mt-3 font-display text-display-md tracking-tight text-foreground md:text-display-lg">
              Üç adımda içerdesin.
            </h2>
          </div>

          <div className="mx-auto mt-12 grid max-w-5xl gap-6 md:grid-cols-3">
            {steps.map((step, i) => (
              <div key={step.num} className="relative">
                <div className="panel-glass p-6">
                  <div className="font-display text-4xl font-bold text-primary/22">{step.num}</div>
                  <h3 className="mt-4 text-title-md text-foreground">{step.title}</h3>
                  <p className="mt-2 text-body-md leading-relaxed text-text-muted">{step.description}</p>
                </div>
                {i < steps.length - 1 && (
                  <div className="absolute -right-3 top-1/2 hidden h-6 w-6 -translate-y-1/2 items-center justify-center rounded-full border border-border bg-surface text-text-muted md:flex">
                    <ArrowRight className="h-3 w-3" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="container py-16 md:py-24">
        <div className="relative overflow-hidden rounded-3xl border border-border/70 bg-gradient-to-br from-primary via-primary-hover to-accent p-10 text-center shadow-xl md:p-16">
          <div className="pointer-events-none absolute inset-0">
            <div className="absolute -left-20 top-0 h-64 w-64 rounded-full bg-white/10 blur-3xl" />
            <div className="absolute -right-20 bottom-0 h-64 w-64 rounded-full bg-accent/20 blur-3xl" />
          </div>
          <div className="relative mx-auto max-w-2xl">
            <h2 className="font-display text-display-md tracking-tight text-white md:text-4xl">Hazır mısın?</h2>
            <p className="mt-4 text-lg text-white/88">
              Doğrulanmış bir topluluğa katıl. Zaman kaybetme, güveni yanında bulundur.
            </p>
            <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
              <Button size="lg" variant="secondary" asChild>
                <Link href="/uye-ol">
                  Hemen Üye Ol
                  <ArrowRight className="h-4 w-4" />
                </Link>
              </Button>
              <Button size="lg" variant="ghost" className="text-white hover:bg-white/15 hover:text-white" asChild>
                <Link href="/ilanlar">
                  <Search className="h-4 w-4" />
                  İlanlara Bak
                </Link>
              </Button>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

function MetricCard({
  label,
  value,
  description,
}: {
  label: string;
  value: string;
  description: string;
}) {
  return (
    <div className="space-y-1">
      <div className="text-[11px] font-semibold uppercase tracking-wider text-text-muted">{label}</div>
      <div className="font-display text-display-md font-bold text-foreground">{value}</div>
      <div className="text-body-md text-text-muted">{description}</div>
    </div>
  );
}
