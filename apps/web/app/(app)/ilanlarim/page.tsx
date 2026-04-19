"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Plus, FileBox } from "lucide-react";

import { ListingBadge } from "@/components/badges";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { Skeleton } from "@/components/ui/skeleton";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { cn } from "@/lib/utils";

const TABS = [
  { key: "PUBLISHED", label: "Yayında" },
  { key: "DRAFT", label: "Taslak" },
  { key: "SOLD", label: "Satıldı" },
  { key: "ARCHIVED", label: "Arşiv" },
];

export default function MyListingsPage() {
  const { accessToken } = useAuth();
  const [activeTab, setActiveTab] = useState("PUBLISHED");

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["my-listings"],
    queryFn: async () => {
      if (!accessToken) return [];
      const res = await apiFetchWithAuth(
        "/listings?mine=true&include_inactive=true",
        accessToken
      );
      return res.data as Array<any>;
    },
    enabled: Boolean(accessToken),
  });

  const counts = useMemo(() => {
    const c: Record<string, number> = {};
    (data || []).forEach((l) => {
      c[l.state] = (c[l.state] || 0) + 1;
    });
    return c;
  }, [data]);

  const filtered = useMemo(() => {
    if (!data) return [];
    return data.filter((listing) => listing.state === activeTab);
  }, [data, activeTab]);

  async function handleAction(
    listingId: number,
    action: "publish" | "mark-sold" | "confirm-active"
  ) {
    if (!accessToken) return;
    await apiFetchWithAuth(`/listings/${listingId}/${action}`, accessToken, { method: "POST" });
    refetch();
  }

  return (
    <div className="container py-10">
      <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <h1 className="font-display text-display-sm font-bold tracking-tight text-foreground md:text-display-md">
            İlanlarım
          </h1>
          <p className="mt-1 text-body-md text-text-muted">
            Taslak, yayında, satıldı ve arşiv durumlarını buradan yönet.
          </p>
        </div>
        <Button asChild>
          <Link href="/ilan-ver">
            <Plus className="h-4 w-4" />
            Yeni İlan Ver
          </Link>
        </Button>
      </div>

      <div className="mt-6 flex flex-wrap gap-1 rounded-card border border-border bg-surface p-1 shadow-card">
        {TABS.map((tab) => {
          const active = tab.key === activeTab;
          const count = counts[tab.key] ?? 0;
          return (
            <button
              key={tab.key}
              type="button"
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                "inline-flex items-center gap-2 rounded-md px-3.5 py-2 text-sm font-medium transition-colors",
                active
                  ? "bg-primary-light text-primary"
                  : "text-text-muted hover:bg-surface-2 hover:text-foreground"
              )}
            >
              {tab.label}
              <span
                className={cn(
                  "inline-flex h-5 min-w-[20px] items-center justify-center rounded-full px-1.5 text-[11px] font-semibold",
                  active ? "bg-primary text-primary-foreground" : "bg-surface-2 text-text-muted"
                )}
              >
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {isLoading ? (
        <div className="mt-8 grid gap-5 md:grid-cols-2">
          {Array.from({ length: 4 }).map((_, idx) => (
            <Skeleton key={idx} className="h-56" />
          ))}
        </div>
      ) : filtered.length ? (
        <div className="mt-8 grid gap-5 md:grid-cols-2">
          {filtered.map((listing) => {
            const needsConfirmation = listing.stale_state === "NEEDS_CONFIRMATION";
            return (
              <div
                key={listing.id}
                className="rounded-card border border-border bg-surface p-5 shadow-card transition-all duration-200 hover:border-border-strong hover:shadow-card-hover"
              >
                <div className="flex items-start justify-between gap-3">
                  <ListingBadge state={listing.state} staleState={listing.stale_state} />
                  <div className="text-xs font-medium text-text-muted">#{listing.id}</div>
                </div>

                <div className="mt-3">
                  <h3 className="text-title-md text-foreground">{listing.title}</h3>
                  <p className="text-xs text-text-muted">
                    {listing.city} · {listing.district}
                  </p>
                </div>

                <p className="mt-2 text-sm text-text-muted">
                  {listing.car_details.brand} {listing.car_details.model} ·{" "}
                  {listing.car_details.year} ·{" "}
                  {listing.car_details.mileage.toLocaleString("tr-TR")} km
                </p>

                <div className="mt-3 font-display text-xl font-bold text-foreground">
                  ₺{Number(listing.price).toLocaleString("tr-TR")}
                </div>

                <div className="mt-4 flex flex-wrap gap-2">
                  <Button variant="outline" size="sm" asChild>
                    <Link href={`/ilanlar/${listing.id}`}>Detaya git</Link>
                  </Button>
                  {listing.state === "DRAFT" && (
                    <Button size="sm" onClick={() => handleAction(listing.id, "publish")}>
                      Yayınla
                    </Button>
                  )}
                  {listing.state === "PUBLISHED" && (
                    <Button
                      variant="secondary"
                      size="sm"
                      onClick={() => handleAction(listing.id, "mark-sold")}
                    >
                      Satıldı işaretle
                    </Button>
                  )}
                  {needsConfirmation && (
                    <Button
                      variant="secondary"
                      size="sm"
                      onClick={() => handleAction(listing.id, "confirm-active")}
                    >
                      İlanı onayla
                    </Button>
                  )}
                  {listing.state === "ARCHIVED" && (
                    <Button
                      variant="secondary"
                      size="sm"
                      onClick={() => handleAction(listing.id, "confirm-active")}
                    >
                      Yeniden yayınla
                    </Button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="mt-8 rounded-card border border-dashed border-border bg-surface-2/60 p-10">
          <EmptyState
            icon={FileBox}
            title="Bu durumda ilan yok"
            description={'Yeni ilan vermek için "İlan Ver" butonunu kullan.'}
          />
        </div>
      )}
    </div>
  );
}
