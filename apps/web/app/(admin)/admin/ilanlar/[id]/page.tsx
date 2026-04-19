"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowLeft,
  CalendarClock,
  CircleDashed,
  FileClock,
  Gauge,
  MapPin,
  ShieldCheck,
  ShieldX,
  UserRound,
} from "lucide-react";

import { ListingGallery } from "@/components/listing-gallery";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/components/toast";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type ListingDetail = {
  listing: {
    id: number;
    title: string;
    state: string;
    stale_state?: string | null;
    price: number;
    city: string;
    district: string;
    last_confirmed_at?: string | null;
    photos?: Array<{ url: string }>;
    owner?: { name?: string | null };
  };
  audit: Array<{ id: number; action: string; meta: unknown; created_at: string }>;
};

function getListingStateMeta(state: string): {
  label: string;
  variant: "neutral" | "success" | "danger" | "warning";
  icon: typeof ShieldCheck;
} {
  if (state === "PUBLISHED") return { label: "Yayında", variant: "success", icon: ShieldCheck };
  if (state === "SOLD") return { label: "Satıldı", variant: "danger", icon: ShieldX };
  if (state === "REJECTED") return { label: "Reddedildi", variant: "danger", icon: ShieldX };
  if (state === "DRAFT") return { label: "Taslak", variant: "warning", icon: FileClock };
  if (state === "ARCHIVED") return { label: "Arşiv", variant: "neutral", icon: CircleDashed };
  return { label: state, variant: "neutral", icon: CircleDashed };
}

function ActionButton({
  busy,
  code,
  label,
  onClick,
  variant = "outline",
  disabled,
}: {
  busy: string | null;
  code: string;
  label: string;
  onClick: () => void;
  variant?: "outline" | "default" | "destructive";
  disabled?: boolean;
}) {
  const isBusy = busy === code;
  return (
    <Button variant={variant} onClick={onClick} disabled={Boolean(disabled || isBusy)}>
      {isBusy ? "İşleniyor..." : label}
    </Button>
  );
}

export default function ListingDetailAdminPage() {
  const { accessToken, user } = useAuth();
  const params = useParams();
  const router = useRouter();
  const { push } = useToast();
  const [reason, setReason] = useState("");
  const [busy, setBusy] = useState<string | null>(null);

  const listingId = Number(params.id);
  const isAdmin = user?.role === "ADMIN";

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-listing", listingId],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth(`/admin/listings/${listingId}`, accessToken);
      return res.data as ListingDetail;
    },
    enabled: Boolean(accessToken && listingId),
  });

  async function runAction(action: string) {
    if (!accessToken) return;
    if ((action === "take-down" || action === "reject" || action === "note") && !reason.trim()) {
      push({ title: "Sebep zorunludur." });
      return;
    }
    setBusy(action);
    try {
      await apiFetchWithAuth(`/admin/listings/${listingId}/${action}`, accessToken, {
        method: "POST",
        body: JSON.stringify({ reason: reason || null }),
      });
      push({ title: "İlan güncellendi." });
      setReason("");
      refetch();
    } catch {
      push({ title: "İşlem başarısız." });
    } finally {
      setBusy(null);
    }
  }

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <Card>
        <CardContent className="flex items-center justify-between gap-3 p-6 text-sm text-text-muted">
          İlan yüklenemedi.
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            Tekrar dene
          </Button>
        </CardContent>
      </Card>
    );
  }

  const listing = data.listing;
  const stateMeta = getListingStateMeta(String(listing.state));
  const StateIcon = stateMeta.icon;
  const staleLabel = listing.stale_state === "NEEDS_CONFIRMATION" ? "Onay Bekliyor" : listing.stale_state;

  return (
    <div className="space-y-6">
      <div className="panel-glass p-5">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="text-xs uppercase tracking-[0.12em] text-text-muted">İlan Moderasyonu</div>
            <h1 className="mt-1 font-display text-2xl font-semibold">{listing.title}</h1>
          </div>
          <Button variant="outline" onClick={() => router.back()}>
            <ArrowLeft className="h-4 w-4" />
            Geri dön
          </Button>
        </div>
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardContent className="p-4">
            <ListingGallery photos={listing.photos || []} title={listing.title} />
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-4 p-6 text-sm">
            <div className="text-text-muted">İlan Özeti</div>
            <div className="inline-flex items-center gap-2 rounded-btn border border-border/80 bg-surface-2/70 px-3 py-2">
              <span className="icon-3d h-7 w-7">
                <StateIcon className="h-3.5 w-3.5" />
              </span>
              <Badge variant={stateMeta.variant}>{stateMeta.label}</Badge>
              {staleLabel ? <Badge variant="warning">{staleLabel}</Badge> : null}
            </div>

            <div className="space-y-2">
              <InfoLine icon={Gauge} label="Fiyat" value={`₺ ${listing.price.toLocaleString("tr-TR")}`} strong />
              <InfoLine icon={MapPin} label="Konum" value={`${listing.city} / ${listing.district}`} />
              <InfoLine icon={UserRound} label="Satıcı" value={listing.owner?.name || "-"} />
              <InfoLine
                icon={CalendarClock}
                label="Son Doğrulama"
                value={
                  listing.last_confirmed_at
                    ? new Date(listing.last_confirmed_at).toLocaleDateString("tr-TR")
                    : "Henüz doğrulanmadı"
                }
              />
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="space-y-4 p-6">
          <div className="text-sm text-text-muted">Moderasyon Aksiyonları</div>
          <Input placeholder="Sebep / iç not" value={reason} onChange={(event) => setReason(event.target.value)} />
          <div className="flex flex-wrap gap-2">
            <ActionButton busy={busy} code="take-down" label="Yayından Kaldır" onClick={() => runAction("take-down")} />
            <ActionButton busy={busy} code="reject" label="Reddet" onClick={() => runAction("reject")} />
            <ActionButton busy={busy} code="archive" label="Arşivle" onClick={() => runAction("archive")} />
            <ActionButton busy={busy} code="note" label="Not Ekle" onClick={() => runAction("note")} />
            {isAdmin ? (
              <ActionButton
                busy={busy}
                code="restore"
                label="Geri Yükle"
                variant="default"
                onClick={() => runAction("restore")}
              />
            ) : (
              <Button variant="outline" disabled>
                Geri Yükle (ADMIN)
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="space-y-4 p-6">
          <div className="text-sm text-text-muted">İşlem Geçmişi</div>
          {data.audit.length ? (
            <div className="space-y-2">
              {data.audit.map((item) => (
                <div
                  key={item.id}
                  className="flex items-center justify-between gap-3 rounded-btn border border-border/75 bg-surface/85 px-3 py-2"
                >
                  <div className="text-sm font-medium">{item.action}</div>
                  <div className="text-xs text-text-muted">{new Date(item.created_at).toLocaleString("tr-TR")}</div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-sm text-text-muted">Kayıt yok.</div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function InfoLine({
  icon: Icon,
  label,
  value,
  strong,
}: {
  icon: typeof Gauge;
  label: string;
  value: string;
  strong?: boolean;
}) {
  return (
    <div className="rounded-btn border border-border/80 bg-surface/80 px-3 py-2">
      <div className="inline-flex items-center gap-1.5 text-xs text-text-muted">
        <Icon className="h-3.5 w-3.5" />
        {label}
      </div>
      <div className={strong ? "mt-1 text-base font-semibold text-primary" : "mt-1 text-sm font-medium"}>{value}</div>
    </div>
  );
}
