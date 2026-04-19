"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight, Car, Home, Plus, Search, Wrench } from "lucide-react";

import { CategoryCard } from "@/components/category-card";
import { FilterChips } from "@/components/filter-chips";
import { ListingCard, type Listing } from "@/components/listing-card";
import { SectionHeader } from "@/components/section-header";
import { TrustBand } from "@/components/trust-band";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type RecentListing = {
  id: number;
  title: string;
  price: number;
  city: string;
  district: string;
  photo: string;
  meta: string;
};

export default function HomeVerifiedPage() {
  const { accessToken, user } = useAuth();
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [recent, setRecent] = useState<RecentListing[]>([]);

  const { data: listings, isLoading: isListingsLoading } = useQuery({
    queryKey: ["home-listings"],
    queryFn: async () => {
      if (!accessToken) return [];
      const res = await apiFetchWithAuth("/listings", accessToken);
      return res.data as Listing[];
    },
    enabled: Boolean(accessToken),
  });

  const { data: favorites, isLoading: isFavoritesLoading } = useQuery({
    queryKey: ["home-favorites"],
    queryFn: async () => {
      if (!accessToken) return [];
      const res = await apiFetchWithAuth("/favorites", accessToken);
      return res.data as Listing[];
    },
    enabled: Boolean(accessToken),
  });

  useEffect(() => {
    try {
      const stored = JSON.parse(localStorage.getItem("recentListings") || "[]");
      setRecent(stored);
    } catch {
      setRecent([]);
    }
  }, []);

  const featured = useMemo(() => (listings || []).slice(0, 8), [listings]);
  const favoritePreview = useMemo(() => (favorites || []).slice(0, 4), [favorites]);
  const firstName = user?.name?.split(" ")[0] ?? "";

  function handleSearch(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const value = query.trim();
    router.push(value ? `/ilanlar?q=${encodeURIComponent(value)}` : "/ilanlar");
  }

  return (
    <div className="container py-8 md:py-10">
      <div className="space-y-10">
        <div className="panel-glass relative overflow-hidden p-6 md:p-8">
          <div className="hero-orb hero-orb-primary absolute -right-8 -top-8 h-44 w-44 animate-glow-shift" />
          <div className="relative">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <div className="inline-flex items-center rounded-full border border-primary/25 bg-primary-light px-2.5 py-0.5 text-[11px] font-semibold text-primary">
                  Doğrulanmış topluluk
                </div>
                <h1 className="mt-3 font-display text-display-sm font-bold tracking-tight text-foreground md:text-display-md">
                  {firstName ? `Hoş geldin, ${firstName}` : "Güvenli alış-satış"}
                </h1>
                <p className="mt-2 max-w-xl text-body-md text-text-muted">
                  Yanıt süresi görünür, randevu akışı net. Belirsiz iletişim ve zaman kaybı minimumda.
                </p>
              </div>
              <Button onClick={() => router.push("/ilan-ver")}>
                <Plus className="h-4 w-4" />
                İlan Ver
              </Button>
            </div>

            <form onSubmit={handleSearch} className="mt-6 flex flex-col gap-2 sm:flex-row">
              <div className="relative flex-1">
                <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
                <Input
                  placeholder="Marka, model, il/ilçe veya anahtar kelime"
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  className="pl-9"
                />
              </div>
              <Button type="submit">
                <Search className="h-4 w-4" />
                Ara
              </Button>
            </form>

            <div className="mt-4">
              <FilterChips
                chips={[
                  { label: "İstanbul", onClick: () => router.push("/ilanlar?city=ISTANBUL") },
                  { label: "0-500K ₺", onClick: () => router.push("/ilanlar?max_price=500000") },
                  { label: "2018+", onClick: () => router.push("/ilanlar?year_min=2018") },
                  { label: "Otomatik", onClick: () => router.push("/ilanlar?transmission=Automatic") },
                  { label: "Dizel", onClick: () => router.push("/ilanlar?fuel=Diesel") },
                  { label: "Benzin", onClick: () => router.push("/ilanlar?fuel=Gasoline") },
                ]}
              />
            </div>
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-[1.4fr_0.6fr]">
          <div className="space-y-4">
            <SectionHeader
              title="Kategoriler"
              description="Sadece doğrulanmış kullanıcılar ilan verebilir."
              actionLabel="Tüm ilanlar"
              actionHref="/ilanlar"
            />
            <div className="grid gap-4 md:grid-cols-3">
              <CategoryCard
                title="Araç"
                description="Otomobil, SUV, hatchback"
                icon={<Car className="h-5 w-5" />}
                href="/ilanlar"
              />
              <CategoryCard
                title="Emlak"
                description="Yakında"
                icon={<Home className="h-5 w-5" />}
                disabled
              />
              <CategoryCard
                title="Yedek Parça"
                description="Yakında"
                icon={<Wrench className="h-5 w-5" />}
                disabled
              />
            </div>
          </div>
          <TrustBand />
        </div>

        <div className="space-y-5">
          <SectionHeader
            title="Öne çıkan ilanlar"
            description="Bugün öne çıkan doğrulanmış ilanlar"
            actionLabel="Tümünü gör"
            actionHref="/ilanlar"
          />
          {isListingsLoading ? (
            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
              {Array.from({ length: 4 }).map((_, index) => (
                <Skeleton key={index} className="h-72 w-full" />
              ))}
            </div>
          ) : featured.length ? (
            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
              {featured.map((listing) => (
                <ListingCard key={listing.id} listing={listing} />
              ))}
            </div>
          ) : (
            <div className="rounded-card border border-dashed border-border bg-surface-2/60 p-10">
              <EmptyState
                title="Henüz öne çıkan ilan yok"
                description="İlanlar yayınlandıkça burada listelenecek."
              />
            </div>
          )}
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          <div className="space-y-4">
            <SectionHeader
              title="Favorilerim"
              description="Beğendiğin ilanlara hızlı erişim"
              actionLabel="Tüm favoriler"
              actionHref="/favoriler"
            />
            {isFavoritesLoading ? (
              <Skeleton className="h-72 w-full" />
            ) : favoritePreview.length ? (
              <div className="grid gap-5 sm:grid-cols-2">
                {favoritePreview.map((listing) => (
                  <ListingCard key={listing.id} listing={listing} initialFavorite />
                ))}
              </div>
            ) : (
              <div className="rounded-card border border-dashed border-border bg-surface-2/60 p-8">
                <EmptyState
                  title="Favori yok"
                  description="Beğendiğin ilanlar burada görünecek."
                />
              </div>
            )}
          </div>

          <div className="space-y-4">
            <SectionHeader
              title="Son görüntülenenler"
              description="Yakın zamanda baktığın ilanlar"
              actionLabel="Tümünü gör"
              actionHref="/ilanlar"
            />
            {recent.length ? (
              <div className="space-y-2">
                {recent.slice(0, 5).map((item) => (
                  <Link
                    key={item.id}
                    href={`/ilanlar/${item.id}`}
                    className="group flex items-center gap-4 rounded-card border border-border/80 bg-surface/85 p-3 shadow-card backdrop-blur-md transition-all duration-200 hover:-translate-y-0.5 hover:border-border-strong hover:shadow-card-hover"
                  >
                    <img
                      src={item.photo || "/placeholder.png"}
                      alt={item.title}
                      className="h-16 w-20 shrink-0 rounded-lg object-cover"
                    />
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-sm font-semibold text-foreground">{item.title}</div>
                      <div className="truncate text-xs text-text-muted">{item.meta}</div>
                      <div className="text-xs text-text-muted">{item.city}</div>
                    </div>
                    <div className="flex items-center gap-2 text-sm font-bold text-foreground">
                      ₺{Number(item.price).toLocaleString("tr-TR")}
                      <ArrowRight className="h-4 w-4 text-text-muted transition-transform group-hover:translate-x-0.5 group-hover:text-primary" />
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <div className="rounded-card border border-dashed border-border bg-surface-2/60 p-8">
                <EmptyState
                  title="Henüz görüntülenen yok"
                  description="İlan detaylarına girdiğinde burada listelenecek."
                />
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
