import Link from "next/link";
import {
  ArrowRight,
  CarFront,
  MapPin,
  Search,
  ShieldCheck,
} from "lucide-react";

export function MarketplaceIntro({ name }: { name?: string }) {
  return (
    <section className="market-hero text-center">
      <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-border bg-surface px-3 py-1.5 text-xs text-text-muted">
        <span className="h-1.5 w-1.5 rounded-full bg-accent" />
        {name
          ? `Hoş geldin, ${name}`
          : "İstanbul’un doğrulanmış araç topluluğu"}
      </div>
      <h1 className="market-title">
        Doğru araç.
        <br />
        <span className="text-info">Doğru kişiden.</span>
      </h1>
      <p className="mx-auto mt-5 max-w-xl text-sm leading-7 text-text-muted sm:text-base">
        Bir sonraki aracını güvenle keşfet.
        <br className="sm:hidden" /> Satıcıyı tanı, detayları incele, görüşmeni
        planla.
      </p>
      <form
        action="/ilanlar"
        method="get"
        className="market-search mx-auto mt-8 flex max-w-2xl items-center gap-3 rounded-2xl border border-border-strong/50 bg-surface p-2 sm:p-3"
      >
        <Search className="ml-2 h-5 w-5 shrink-0 text-text-muted sm:ml-3" />
        <input
          name="q"
          aria-label="Araç ara"
          placeholder="Marka, model veya aradığın araç…"
          className="h-11 min-w-0 flex-1 bg-transparent text-sm outline-none sm:text-base"
        />
        <button
          type="submit"
          className="inline-flex h-12 shrink-0 items-center gap-2 rounded-xl bg-primary px-4 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary-hover sm:px-6"
        >
          <span className="hidden sm:inline">İlanları keşfet</span>
          <ArrowRight className="h-5 w-5" />
          <span className="sr-only sm:hidden">Ara</span>
        </button>
      </form>
      <div className="mt-5 flex flex-wrap items-center justify-center gap-2 text-xs">
        <span className="mr-1 text-text-muted">Popüler aramalar</span>
        {[
          ["Otomatik", "transmission=Automatic"],
          ["Elektrikli", "fuel=Electric"],
          ["2018 ve üzeri", "year_min=2018"],
        ].map(([label, query]) => (
          <Link
            key={query}
            href={`/ilanlar?${query}`}
            className="rounded-full border border-border bg-surface px-3 py-2 text-foreground transition-colors hover:border-accent hover:text-accent"
          >
            {label}
          </Link>
        ))}
      </div>
      <div className="mx-auto mt-9 flex max-w-2xl flex-wrap justify-center gap-x-8 gap-y-3 border-t border-border pt-6 text-xs text-text-muted">
        <span className="inline-flex items-center gap-2">
          <ShieldCheck className="h-4 w-4 text-accent" />
          Doğrulanmış üyeler
        </span>
        <span className="inline-flex items-center gap-2">
          <CarFront className="h-4 w-4 text-accent" />
          Doğrudan sahibinden
        </span>
        <span className="inline-flex items-center gap-2">
          <MapPin className="h-4 w-4 text-accent" />
          İstanbul
        </span>
      </div>
    </section>
  );
}
