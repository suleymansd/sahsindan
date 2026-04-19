import Link from "next/link";
import { HelpCircle, LifeBuoy, ShieldCheck } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";

const faqs = [
  {
    q: "Neden dogrulama gerekiyor?",
    a: "Kapali platformdayiz. Her uyenin kimligi ve niyeti dogrulanir, sahte ilan ve bosa mesaj riski azalir.",
  },
  {
    q: "Ilanlar neden onay bekliyor?",
    a: "Yayinda kalan ilanlar periyodik kontrol edilir. Satilan ilanlar otomatik arsive gecerek akis temiz kalir.",
  },
  {
    q: "Randevu nasil calisiyor?",
    a: "Alici talep gonderir, satici kabul veya ret verir. Tamamlanan randevular guven skorunu olumlu etkiler.",
  },
  {
    q: "Yanit orani nasil hesaplanir?",
    a: "Son mesajlara verilen cevap suresi ortalamasina bakilir. Ozel icerik degil, sadece hiz metrikleri kullanilir.",
  },
];

export default function HelpPage() {
  return (
    <main className="container py-10 md:py-14">
      <div className="space-y-7">
        <div className="relative overflow-hidden rounded-[1.7rem] border border-border/70 bg-[linear-gradient(145deg,hsla(var(--surface),0.9),hsla(var(--surface-2),0.72))] p-6 shadow-[0_20px_56px_rgba(8,28,54,0.14)] sm:p-8">
          <div className="pointer-events-none absolute -right-8 top-[-20px] h-28 w-28 rounded-full bg-[radial-gradient(circle,hsla(var(--primary),0.3),transparent_72%)]" />
          <div className="pointer-events-none absolute -left-10 bottom-[-18px] h-28 w-28 rounded-full bg-[radial-gradient(circle,hsla(var(--accent),0.3),transparent_72%)]" />

          <div className="relative grid gap-4 md:grid-cols-[1fr_auto] md:items-center">
            <div className="space-y-3">
              <div className="inline-flex items-center gap-2 rounded-full border border-success/20 bg-success-bg px-3 py-1 text-xs font-semibold text-success">
                <ShieldCheck className="h-3.5 w-3.5" />
                Yardim Merkezi
              </div>
              <h1 className="font-display text-3xl font-semibold text-foreground">Sik Sorulan Sorular</h1>
              <p className="max-w-3xl text-sm text-text-muted">
                sahsindan.com sadece dogrulanmis uyelerle calisir. Asagidaki rehber notlari, ilan, mesaj ve randevu
                akislarindaki temel kurallari hizlica aciklar.
              </p>
            </div>
            <div className="icon-3d animate-float">
              <HelpCircle className="h-4 w-4 text-primary" />
            </div>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          {faqs.map((item, index) => (
            <Card key={item.q} className="card-hover">
              <CardHeader>
                <div className="inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.12em] text-text-muted">
                  <span className="rounded-full border border-border/70 bg-surface px-2 py-0.5">0{index + 1}</span>
                  Soru
                </div>
                <div className="text-base font-semibold">{item.q}</div>
              </CardHeader>
              <CardContent className="text-sm text-text-muted">{item.a}</CardContent>
            </Card>
          ))}
        </div>

        <Card className="overflow-hidden">
          <CardContent className="grid gap-5 p-6 md:grid-cols-[1fr_auto] md:items-center md:p-8">
            <div>
              <div className="inline-flex items-center gap-2 text-sm font-semibold text-foreground">
                <LifeBuoy className="h-4 w-4 text-primary" />
                Hala yardim gerekiyor mu?
              </div>
              <p className="mt-1 text-sm text-text-muted">
                Destek ekibi; dogrulama, ilan olusturma ve panel akislarinda hizli yonlendirme saglar.
              </p>
            </div>
            <Button asChild>
              <Link href="mailto:destek@sahsindan.com">destek@sahsindan.com</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}
