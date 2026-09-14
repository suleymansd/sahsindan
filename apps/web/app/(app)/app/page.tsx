"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight, Heart, History } from "lucide-react";
import { MarketplaceIntro } from "@/components/marketplace-intro";
import { ListingCard, type Listing } from "@/components/listing-card";
import { SectionHeader } from "@/components/section-header";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
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
  const [recent, setRecent] = useState<RecentListing[]>([]);
  const {
    data: listings = [],
    isLoading,
    isError,
    refetch,
  } = useQuery({
    queryKey: ["home-listings"],
    queryFn: async () =>
      (await apiFetchWithAuth("/listings", accessToken!)).data as Listing[],
    enabled: Boolean(accessToken),
  });
  const {
    data: favorites = [],
    isLoading: favoritesLoading,
    isError: favoritesError,
  } = useQuery({
    queryKey: ["home-favorites"],
    queryFn: async () =>
      (await apiFetchWithAuth("/favorites", accessToken!)).data as Listing[],
    enabled: Boolean(accessToken),
  });
  useEffect(() => {
    try {
      const stored = JSON.parse(localStorage.getItem("recentListings") || "[]");
      setRecent(Array.isArray(stored) ? stored : []);
    } catch {
      setRecent([]);
    }
  }, []);
  return (
    <div className="container pb-12">
      <MarketplaceIntro name={user?.name?.split(" ")[0]} />
      <section className="border-t border-border pt-9">
        <SectionHeader
          title="Son eklenen ilanlar"
          description="Bir sonraki yolculuğun burada başlasın."
          actionLabel="Tüm ilanları gör"
          actionHref="/ilanlar"
        />
        <div className="mt-6">
          {isLoading ? (
            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
              {Array.from({ length: 4 }, (_, i) => (
                <Skeleton key={i} className="h-96" />
              ))}
            </div>
          ) : isError ? (
            <div
              role="alert"
              className="card flex items-center justify-between p-6 text-sm"
            >
              İlanlar yüklenemedi.
              <Button variant="outline" onClick={() => refetch()}>
                Tekrar dene
              </Button>
            </div>
          ) : listings.length ? (
            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
              {listings.slice(0, 8).map((listing) => (
                <ListingCard
                  key={listing.id}
                  listing={listing}
                  initialFavorite={favorites.some(
                    (favorite) => favorite.id === listing.id,
                  )}
                />
              ))}
            </div>
          ) : (
            <div className="card p-10">
              <EmptyState
                title="Henüz ilan yok"
                description="Yeni ilanlar yayınlandığında burada görünecek."
              />
            </div>
          )}
        </div>
      </section>
      <div className="mt-12 grid gap-8 lg:grid-cols-2">
        <section>
          <div className="mb-5 flex items-center gap-2">
            <Heart className="h-4 w-4 text-accent" />
            <h2 className="text-lg font-semibold">Favorilerin</h2>
            <Link
              className="ml-auto text-xs font-semibold text-text-muted hover:text-foreground"
              href="/favoriler"
            >
              Tümünü gör →
            </Link>
          </div>
          {favoritesLoading ? (
            <Skeleton className="h-48" />
          ) : favoritesError ? (
            <div className="card p-6 text-sm text-text-muted">
              Favorilerin yüklenemedi.{" "}
              <Link className="underline" href="/favoriler">
                Favoriler sayfasını aç
              </Link>
            </div>
          ) : favorites.length ? (
            <div className="grid gap-5 sm:grid-cols-2">
              {favorites.slice(0, 2).map((listing) => (
                <ListingCard
                  key={listing.id}
                  listing={listing}
                  initialFavorite
                />
              ))}
            </div>
          ) : (
            <div className="card flex min-h-44 flex-col items-center justify-center p-6 text-center">
              <Heart className="mb-3 h-6 w-6 text-border-strong" />
              <p className="text-sm font-medium">
                Aklında kalsın, burada dursun.
              </p>
              <p className="mt-2 text-xs text-text-muted">
                Beğendiğin ilanları kalp simgesiyle kaydet.
              </p>
            </div>
          )}
        </section>
        <section>
          <div className="mb-5 flex items-center gap-2">
            <History className="h-4 w-4 text-accent" />
            <h2 className="text-lg font-semibold">Son baktıkların</h2>
          </div>
          {recent.length ? (
            <div className="card divide-y divide-border overflow-hidden">
              {recent.slice(0, 4).map((item) => (
                <Link
                  key={item.id}
                  href={`/ilanlar/${item.id}`}
                  className="flex items-center gap-3 p-4 transition-colors hover:bg-surface-2"
                >
                  <img
                    src={item.photo || "/placeholder.png"}
                    alt={item.title}
                    className="h-16 w-20 shrink-0 rounded-lg object-cover"
                  />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold">
                      {item.title}
                    </p>
                    <p className="mt-1 text-xs text-text-muted">{item.meta}</p>
                    <p className="mt-1 text-sm font-semibold">
                      {Number(item.price).toLocaleString("tr-TR")} TL
                    </p>
                  </div>
                  <ArrowRight className="h-4 w-4 shrink-0 text-text-muted" />
                </Link>
              ))}
            </div>
          ) : (
            <div className="card flex min-h-44 flex-col items-center justify-center p-6 text-center">
              <History className="mb-3 h-6 w-6 text-border-strong" />
              <p className="text-sm font-medium">Keşfetmeye buradan başla.</p>
              <p className="mt-2 text-xs text-text-muted">
                İncelediğin ilanlara kolayca geri dönebileceksin.
              </p>
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
