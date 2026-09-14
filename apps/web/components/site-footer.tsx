import Link from "next/link";
import { ShieldCheck } from "lucide-react";

export function SiteFooter() {
  return (
    <footer className="mt-auto border-t border-border bg-surface">
      <div className="container flex flex-col gap-6 py-8 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <Link
            href="/"
            className="inline-flex items-center gap-2 font-display text-base font-semibold"
          >
            <ShieldCheck className="h-5 w-5 text-accent" />
            şahsından<span className="-ml-2 text-text-muted">.com</span>
          </Link>
          <p className="mt-2 text-xs text-text-muted">
            Güvenle tanış. Gönül rahatlığıyla ilerle.
          </p>
        </div>
        <nav
          aria-label="Alt menü"
          className="flex flex-wrap gap-6 text-xs text-text-muted"
        >
          <Link className="hover:text-foreground" href="/yardim">
            Yardım merkezi
          </Link>
          <Link className="hover:text-foreground" href="/yardim">
            Güven ve doğrulama
          </Link>
          <Link className="hover:text-foreground" href="/giris">
            Üye girişi
          </Link>
        </nav>
        <p className="text-xs text-text-muted">
          © {new Date().getFullYear()} şahsından.com
        </p>
      </div>
    </footer>
  );
}
