"use client";

import Link from "next/link";
import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type AdminListing = {
  id: number;
  title: string;
  state: string;
  city: string;
  price: number;
  owner: { id: number; email: string };
  created_at: string;
};

export default function ListingsAdminPage() {
  const { accessToken } = useAuth();
  const [state, setState] = useState("all");
  const [city, setCity] = useState("");
  const [flagged, setFlagged] = useState("all");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-listings", state, city, flagged],
    queryFn: async () => {
      if (!accessToken) return { data: [], meta: {} };
      const params = new URLSearchParams();
      if (state !== "all") params.set("state", state);
      if (city) params.set("city", city);
      if (flagged !== "all") params.set("flagged", flagged === "true" ? "true" : "false");
      const res = await apiFetchWithAuth(`/admin/listings?${params.toString()}`, accessToken);
      return res as { data: AdminListing[]; meta: { total: number } };
    },
    enabled: Boolean(accessToken),
  });

  return (
    <div className="space-y-6">
      <div className="panel-glass p-5">
        <div className="text-sm text-text-muted">İlan Moderasyonu</div>
        <h1 className="mt-1 font-display text-2xl font-semibold">İlanlar</h1>
      </div>

      <Card>
        <CardContent className="grid gap-4 p-6 md:grid-cols-3">
          <Input placeholder="Şehir" value={city} onChange={(event) => setCity(event.target.value)} />
          <select
            value={state}
            onChange={(event) => setState(event.target.value)}
            className="h-12 w-full rounded-btn border border-border/85 bg-surface/90 px-3 text-sm shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <option value="all">Tüm durumlar</option>
            <option value="DRAFT">DRAFT</option>
            <option value="PUBLISHED">PUBLISHED</option>
            <option value="SOLD">SOLD</option>
            <option value="ARCHIVED">ARCHIVED</option>
            <option value="REJECTED">REJECTED</option>
          </select>
          <select
            value={flagged}
            onChange={(event) => setFlagged(event.target.value)}
            className="h-12 w-full rounded-btn border border-border/85 bg-surface/90 px-3 text-sm shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <option value="all">Tümü</option>
            <option value="true">Şüpheli</option>
            <option value="false">Şüpheli değil</option>
          </select>
        </CardContent>
      </Card>

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 6 }).map((_, idx) => (
            <Skeleton key={idx} className="h-16 w-full" />
          ))}
        </div>
      ) : null}

      {isError ? (
        <Card>
          <CardContent className="flex items-center justify-between gap-3 p-6 text-sm text-text-muted">
            Liste yüklenemedi.
            <Button variant="outline" size="sm" onClick={() => refetch()}>
              Tekrar dene
            </Button>
          </CardContent>
        </Card>
      ) : null}

      {data?.data?.length ? (
        <div className="space-y-3">
          {data.data.map((listing) => (
            <Card key={listing.id}>
              <CardContent className="flex flex-wrap items-center justify-between gap-4 p-5 text-sm">
                <div>
                  <div className="font-medium">{listing.title}</div>
                  <div className="flex flex-wrap items-center gap-2 text-xs text-text-muted">
                    <span>{listing.city}</span>
                    <Badge
                      variant={
                        listing.state === "PUBLISHED"
                          ? "success"
                          : listing.state === "SOLD"
                            ? "danger"
                            : listing.state === "ARCHIVED"
                              ? "neutral"
                              : listing.state === "REJECTED"
                                ? "danger"
                                : "warning"
                      }
                    >
                      {listing.state}
                    </Badge>
                  </div>
                </div>
                <div className="text-xs text-text-muted">₺ {listing.price.toLocaleString("tr-TR")}</div>
                <Button size="sm" asChild>
                  <Link href={`/admin/ilanlar/${listing.id}`}>İncele</Link>
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        !isLoading && (
          <Card>
            <CardContent className="p-6 text-sm text-text-muted">Sonuç bulunamadı.</CardContent>
          </Card>
        )
      )}
    </div>
  );
}
