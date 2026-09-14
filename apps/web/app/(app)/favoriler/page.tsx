"use client";

import { useState } from "react";
import { Heart } from "lucide-react";
import { useQuery } from "@tanstack/react-query";

import { ListingCard, type Listing } from "@/components/listing-card";
import { SectionHeader } from "@/components/section-header";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { Skeleton } from "@/components/ui/skeleton";
import { PageControls } from "@/components/page-controls";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { UI } from "@/lib/strings";

export default function FavoritesPage() {
  const [page, setPage] = useState(0);
  const { accessToken } = useAuth();

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["favorites", page],
    queryFn: async () => {
      if (!accessToken) return [] as Listing[];
      const res = await apiFetchWithAuth(`/favorites?limit=50&offset=${page * 50}`, accessToken);
      return res.data as Listing[];
    },
    enabled: Boolean(accessToken),
  });

  return (
    <div className="container py-10">
      <SectionHeader
        title={UI.sections.favorites}
        description={`Kaydettiğin ilanlar burada listelenir${data?.length ? ` · ${data.length} ilan` : ""}.`}
      />

      {accessToken && !isLoading && <PageControls page={page} count={data?.length ?? 0} onChange={setPage} />}
      {!accessToken ? (
        <div className="mt-6 rounded-card border border-border bg-surface p-8 shadow-card">
          <EmptyState
            icon={Heart}
            title="Favorileri görmek için giriş yap"
            description="Giriş yaptığında kaydettiğin ilanlar burada listelenir."
          />
        </div>
      ) : isLoading ? (
        <div className="mt-8 grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 6 }).map((_, idx) => (
            <Skeleton key={idx} className="h-72" />
          ))}
        </div>
      ) : isError ? (
        <div className="mt-8 flex items-center justify-between rounded-card border border-border bg-surface p-5 shadow-card">
          <span className="text-sm text-text-muted">Favoriler yüklenemedi.</span>
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            Tekrar dene
          </Button>
        </div>
      ) : data && data.length ? (
        <div className="mt-8 grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
          {data.map((listing) => (
            <ListingCard key={listing.id} listing={listing} initialFavorite />
          ))}
        </div>
      ) : (
        <div className="mt-8 rounded-card border border-dashed border-border bg-surface-2/60 p-10">
          <EmptyState
            icon={Heart}
            title="Henüz favori yok"
            description={UI.emptyStates.favorites}
          />
        </div>
      )}
    </div>
  );
}
