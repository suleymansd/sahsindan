import Link from "next/link";
import { ShieldCheck } from "lucide-react";

const productLinks = [
  { href: "/ilanlar", label: "İlanlar" },
  { href: "/giris", label: "Giriş" },
  { href: "/uye-ol", label: "Üye Ol" },
  { href: "/yardim", label: "Yardım Merkezi" },
];

const policyLinks = [
  { href: "/yardim", label: "Güven Kuralları" },
  { href: "/yardim", label: "Doğrulama Politikası" },
  { href: "/yardim", label: "Randevu Disiplini" },
  { href: "/yardim", label: "Gizlilik & KVKK" },
];

const companyLinks = [
  { href: "/yardim", label: "Hakkımızda" },
  { href: "/yardim", label: "İletişim" },
  { href: "/yardim", label: "Kariyer" },
];

export function SiteFooter() {
  return (
    <footer className="mt-20 border-t border-border/70 bg-surface/55 backdrop-blur-md">
      <div className="container py-12">
        <div className="panel-glass grid gap-10 p-8 md:grid-cols-[1.4fr_1fr_1fr_1fr]">
          <div className="space-y-4">
            <div className="flex items-center gap-2.5">
              <div className="icon-3d text-primary">
                <ShieldCheck className="h-4.5 w-4.5" strokeWidth={2.5} />
              </div>
              <div className="font-display text-[17px] font-semibold tracking-tight text-foreground">
                şahsından.com
              </div>
            </div>
            <p className="max-w-sm text-body-md leading-relaxed text-text-muted">
              Doğrulanmış üyelerle güvenli araç alım-satımı. Net iletişim, planlı randevu, taze
              ilanlar.
            </p>
            <div className="inline-flex items-center gap-2 rounded-full border border-border bg-surface-2 px-3 py-1.5 text-[11px] font-semibold text-text-muted">
              <span className="h-1.5 w-1.5 rounded-full bg-success" />
              Sistem aktif
            </div>
          </div>

          <FooterColumn title="Ürün" links={productLinks} />
          <FooterColumn title="Politikalar" links={policyLinks} />
          <FooterColumn title="Şirket" links={companyLinks} />
        </div>

        <div className="mt-8 flex flex-col items-start justify-between gap-3 border-t border-border/70 pt-6 text-xs text-text-muted sm:flex-row sm:items-center">
          <div>© {new Date().getFullYear()} şahsından.com - Tüm hakları saklıdır.</div>
          <div className="flex items-center gap-4">
            <Link href="/yardim" className="transition-colors hover:text-foreground">
              KVKK
            </Link>
            <Link href="/yardim" className="transition-colors hover:text-foreground">
              Çerez Politikası
            </Link>
            <Link href="/yardim" className="transition-colors hover:text-foreground">
              Şartlar
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}

function FooterColumn({
  title,
  links,
}: {
  title: string;
  links: { href: string; label: string }[];
}) {
  return (
    <div className="space-y-3">
      <div className="text-[11px] font-semibold uppercase tracking-wider text-text-muted">{title}</div>
      <ul className="space-y-2.5">
        {links.map((item) => (
          <li key={item.label}>
            <Link href={item.href} className="text-sm text-foreground/85 transition-colors hover:text-foreground">
              {item.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
