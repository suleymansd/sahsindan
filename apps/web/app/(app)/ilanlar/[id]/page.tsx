"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  Calendar,
  CheckCircle2,
  Clock,
  Fuel,
  Gauge,
  Heart,
  MapPin,
  Palette,
  Settings,
  Shield,
  ShieldAlert,
  UserRound,
} from "lucide-react";

import { AppointmentModal } from "@/components/appointment-modal";
import { ListingBadge, ResponseStats, TrustBadge } from "@/components/badges";
import { ListingGallery } from "@/components/listing-gallery";
import { TrustScore } from "@/components/trust-score";
import { MessageDrawer } from "@/components/message-drawer";
import { VehiclePartsStatus } from "@/components/vehicle-parts-status";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { strings } from "@/lib/strings.tr";
import { toFriendlyError } from "@/lib/errors";

const TRANSMISSION_MAP: Record<string, string> = {
  Automatic: "Otomatik",
  Manual: "Manuel",
};
const FUEL_MAP: Record<string, string> = {
  Gasoline: "Benzin",
  Diesel: "Dizel",
  Hybrid: "Hibrit",
  Electric: "Elektrik",
  LPG: "LPG",
};

export default function ListingDetailPage() {
  const params = useParams();
  const id = Number(params?.id);
  const { accessToken, user } = useAuth();
  const [status, setStatus] = useState<string | null>(null);

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["listing", id],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth(`/listings/${id}`, accessToken);
      return res.data;
    },
    enabled: Boolean(accessToken && id),
  });

  const ownerId = data?.owner?.id as number | undefined;
  const canFollow = Boolean(accessToken && user && ownerId && user.id !== ownerId);
  const { data: followStatus, refetch: refetchFollowStatus } = useQuery({
    queryKey: ["follow-status", ownerId, user?.id],
    queryFn: async () => {
      if (!accessToken || !ownerId) return null;
      const res = await apiFetchWithAuth(`/follows/status/${ownerId}`, accessToken);
      return res.data as { is_following: boolean; followers_count: number; following_count: number };
    },
    enabled: canFollow,
  });

  useEffect(() => {
    if (!data) return;
    try {
      const recent = JSON.parse(localStorage.getItem("recentListings") || "[]");
      const entry = {
        id: data.id,
        title: data.title,
        price: data.price,
        city: data.city,
        district: data.district,
        photo: data.photos?.[0]?.url || "/placeholder.png",
        meta: data.car_details
          ? `${data.car_details.year} • ${data.car_details.mileage.toLocaleString("tr-TR")} km`
          : "",
      };
      const next = [entry, ...recent.filter((item: { id: number }) => item.id !== data.id)].slice(0, 10);
      localStorage.setItem("recentListings", JSON.stringify(next));
    } catch {}
  }, [data]);

  if (!accessToken) {
    return (
      <div className="container py-12">
        <EmptyCard
          icon={<Shield className="h-6 w-6 text-primary" />}
          title={strings.listingDetail.loginRequired}
          description={strings.listingDetail.loginRequiredDescription}
        />
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="container py-10">
        <div className="grid gap-6 lg:grid-cols-[1.5fr_1fr]">
          <div className="space-y-5">
            <Skeleton className="aspect-[16/10] w-full" />
            <Skeleton className="h-64 w-full" />
          </div>
          <Skeleton className="h-96 w-full" />
        </div>
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div className="container py-12">
        <EmptyCard
          icon={<ShieldAlert className="h-6 w-6 text-danger" />}
          title="İlan yüklenemedi"
          description="Lütfen tekrar deneyin."
          action={
            <Button variant="outline" onClick={() => refetch()}>
              Tekrar dene
            </Button>
          }
        />
      </div>
    );
  }

  const isOwner = user?.id === data.owner.id;
  const isInactive = ["SOLD", "ARCHIVED", "REJECTED"].includes(data.state);
  const needsVerification =
    user?.role !== "USER_VERIFIED" && user?.role !== "ADMIN" && user?.role !== "MODERATOR";
  const disabledReason = isInactive
    ? "İlan aktif değil"
    : needsVerification
      ? "Doğrulama gerekli"
      : undefined;

  const changedParts = Array.isArray(data.car_details?.changed_parts)
    ? data.car_details.changed_parts
    : [];

  async function toggleFavorite() {
    if (!accessToken) return;
    try {
      await apiFetchWithAuth(`/listings/${data.id}/favorite`, accessToken, { method: "POST" });
      setStatus(strings.listings.addedToFavorites);
    } catch (err) {
      setStatus(toFriendlyError(err));
    }
  }

  async function toggleFollow() {
    if (!accessToken || !ownerId || !canFollow) return;
    try {
      if (followStatus?.is_following) {
        await apiFetchWithAuth(`/follows/${ownerId}`, accessToken, { method: "DELETE" });
        setStatus("Takipten çıkarıldı.");
      } else {
        await apiFetchWithAuth(`/follows/${ownerId}`, accessToken, { method: "POST" });
        setStatus("Kullanıcı takip edildi.");
      }
      refetchFollowStatus();
    } catch (err) {
      setStatus(toFriendlyError(err));
    }
  }

  async function confirmActive() {
    if (!accessToken) return;
    await apiFetchWithAuth(`/listings/${data.id}/confirm-active`, accessToken, { method: "POST" });
    setStatus(strings.listingDetail.listingUpdated);
    refetch();
  }

  return (
    <div className="container py-7 md:py-9">
      <nav aria-label="İçerik yolu" className="mb-6 flex flex-wrap items-center gap-2 text-xs text-text-muted"><Link href="/app" className="hover:text-foreground">Keşfet</Link><span>/</span><Link href="/ilanlar" className="hover:text-foreground">Otomobil ilanları</Link><span>/</span><span>{data.car_details?.brand || "İlan detayı"}</span><span className="ml-auto">İlan no: {data.id}</span></nav>
      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_360px] lg:gap-8">
        <div className="space-y-6">
          <ListingGallery photos={data.photos} title={data.title} />

          <div className="rounded-card border border-border bg-surface p-6 shadow-card md:p-8">
            <div className="flex flex-wrap items-center gap-1.5">
              <ListingBadge state={data.state} staleState={data.stale_state} />
              <TrustBadge score={data.owner.trust_score} />
              {data.stale_state === "NEEDS_CONFIRMATION" && (
                <Badge variant="warning" className="gap-1">
                  <Clock className="h-3 w-3" />
                  {strings.listingDetail.awaitingConfirmation}
                </Badge>
              )}
            </div>

            <h1 className="mt-4 font-display text-display-sm font-bold leading-tight tracking-tight text-foreground md:text-display-md">
              {data.title}
            </h1>
            <div className="mt-2 flex items-center gap-1.5 text-sm text-text-muted">
              <MapPin className="h-4 w-4 text-primary" />
              <span className="font-medium text-foreground">{data.city}</span>
              <span>·</span>
              <span>{data.district}</span>
            </div>

            <div className="mt-6 flex items-baseline gap-2">
              <span className="font-display text-display-md font-bold text-foreground md:text-display-lg">
                ₺{Number(data.price).toLocaleString("tr-TR")}
              </span>
            </div>

            {data.description && (
              <div className="mt-8 space-y-2">
                <h3 className="text-title-md text-foreground">
                  {strings.listingDetail.description}
                </h3>
                <p className="whitespace-pre-line text-body-md leading-relaxed text-foreground/85">
                  {data.description}
                </p>
              </div>
            )}

            {data.car_details && (
              <div className="mt-8 space-y-3">
                <h3 className="text-title-md text-foreground">
                  {strings.listingDetail.vehicleDetails}
                </h3>
                <div className="grid gap-2.5 sm:grid-cols-2">
                  <DetailItem
                    icon={<Settings className="h-4 w-4" />}
                    label={strings.listingDetail.brand}
                    value={data.car_details.brand}
                  />
                  <DetailItem
                    icon={<Settings className="h-4 w-4" />}
                    label={strings.listingDetail.model}
                    value={data.car_details.model}
                  />
                  <DetailItem
                    icon={<Calendar className="h-4 w-4" />}
                    label={strings.listingDetail.year}
                    value={String(data.car_details.year)}
                  />
                  <DetailItem
                    icon={<Gauge className="h-4 w-4" />}
                    label={strings.listingDetail.mileage}
                    value={`${data.car_details.mileage.toLocaleString("tr-TR")} km`}
                  />
                  <DetailItem
                    icon={<Settings className="h-4 w-4" />}
                    label={strings.listingDetail.transmission}
                    value={
                      TRANSMISSION_MAP[data.car_details.transmission] ?? data.car_details.transmission
                    }
                  />
                  <DetailItem
                    icon={<Fuel className="h-4 w-4" />}
                    label={strings.listingDetail.fuelType}
                    value={FUEL_MAP[data.car_details.fuel] ?? data.car_details.fuel}
                  />
                  {data.car_details.color && (
                    <DetailItem
                      icon={<Palette className="h-4 w-4" />}
                      label={strings.listingDetail.color}
                      value={data.car_details.color}
                    />
                  )}
                </div>
              </div>
            )}

            <div className="mt-8">
              <VehiclePartsStatus changedParts={changedParts} />
            </div>
          </div>
        </div>

        <div className="space-y-5">
          <div className="sticky top-36 space-y-4">
            <div className="rounded-card border border-border bg-surface p-6 shadow-card">
              <div className="mb-6 border-b border-border pb-5"><div className="text-xs text-text-muted">İlan fiyatı</div><div className="mt-2 font-display text-3xl font-semibold tracking-tight">{Number(data.price).toLocaleString("tr-TR")} <span className="text-base font-normal">TL</span></div><div className="mt-2 flex items-center gap-1.5 text-xs text-text-muted"><MapPin className="h-3 w-3" />{data.district}, {data.city === "ISTANBUL" ? "İstanbul" : data.city}</div></div>
              <div className="flex items-start gap-3">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-primary-light text-primary">
                  <UserRound className="h-5 w-5" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="text-[11px] font-semibold uppercase tracking-wider text-text-muted">
                    {strings.listingDetail.sellerInfo}
                  </div>
                  <div className="mt-0.5 truncate text-title-md font-semibold text-foreground">
                    {data.owner.name}
                  </div>
                  <div className="mt-1.5 inline-flex items-center gap-1 rounded-full bg-success-bg px-2 py-0.5 text-[11px] font-semibold text-success">
                    <CheckCircle2 className="h-3 w-3" />
                    {strings.listingDetail.verifiedSeller}
                  </div>
                </div>
              </div>

              <div className="mt-5"><TrustScore score={data.owner.trust_score} /></div>
              <div className="mt-4 border-t border-border pt-4">
                <ResponseStats
                  responseTime={data.owner.response_time_bucket}
                  lastActive={data.owner.last_active_bucket}
                />
              </div>

              <div className="mt-5 flex flex-col gap-2">
                <MessageDrawer listingId={data.id} disabledReason={disabledReason} />
                <AppointmentModal listingId={data.id} disabledReason={disabledReason} />
                <Button
                  variant="outline"
                  disabled={Boolean(disabledReason)}
                  onClick={toggleFavorite}
                  className="w-full"
                >
                  <Heart className="h-4 w-4" />
                  {disabledReason || strings.listingDetail.addToFavorites}
                </Button>
                {canFollow && (
                  <Button
                    variant={followStatus?.is_following ? "secondary" : "ghost"}
                    onClick={toggleFollow}
                    className="w-full"
                  >
                    {followStatus?.is_following ? "Takibi Bırak" : "Takip Et"}
                    {typeof followStatus?.followers_count === "number"
                      ? ` · ${followStatus.followers_count}`
                      : ""}
                  </Button>
                )}
              </div>

              {isOwner && data.stale_state === "NEEDS_CONFIRMATION" && (
                <div className="mt-4 border-t border-border pt-4">
                  <Button onClick={confirmActive} className="w-full">
                    {strings.listings.confirmActive}
                  </Button>
                </div>
              )}

              {status && (
                <div className="mt-4 rounded-lg border border-success/25 bg-success-bg px-3 py-2 text-xs font-medium text-success">
                  {status}
                </div>
              )}
            </div>

            {isInactive && (
              <div className="rounded-card border border-warning/25 bg-warning-bg p-4">
                <div className="flex gap-3">
                  <ShieldAlert className="mt-0.5 h-5 w-5 shrink-0 text-warning" />
                  <div>
                    <div className="text-sm font-semibold text-warning">
                      {strings.listingDetail.inactiveListing}
                    </div>
                    <p className="mt-0.5 text-xs text-warning/90">
                      {strings.listingDetail.inactiveListingDescription}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function DetailItem({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-start gap-3 rounded-lg border border-border bg-surface-2 p-3">
      <div className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-surface text-primary">
        {icon}
      </div>
      <div className="min-w-0 flex-1 space-y-0.5">
        <div className="text-[11px] font-medium uppercase tracking-wider text-text-muted">
          {label}
        </div>
        <div className="truncate text-sm font-semibold text-foreground">{value}</div>
      </div>
    </div>
  );
}

function EmptyCard({
  icon,
  title,
  description,
  action,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="mx-auto max-w-md rounded-card border border-border bg-surface p-8 text-center shadow-card">
      <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-primary-light">
        {icon}
      </div>
      <h3 className="mt-5 text-title-lg text-foreground">{title}</h3>
      <p className="mt-2 text-body-md text-text-muted">{description}</p>
      {action && <div className="mt-5">{action}</div>}
    </div>
  );
}
