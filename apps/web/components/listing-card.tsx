"use client";

import Link from "next/link";
import {
  Heart,
  MapPin,
  Gauge,
  Calendar,
  Fuel,
  Cog,
  ShieldCheck,
} from "lucide-react";
import { useEffect, useMemo, useState, type MouseEvent } from "react";

import { ListingBadge } from "@/components/badges";
import { ListingImage } from "@/components/listing-image";
import { useToast } from "@/components/toast";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { strings } from "@/lib/strings.tr";
import { cn } from "@/lib/utils";

export type Listing = {
  id: number;
  title: string;
  price: number;
  city: string;
  district: string;
  state: string;
  stale_state?: string | null;
  car_details?: {
    brand: string;
    model: string;
    year: number;
    mileage: number;
    transmission: string;
    fuel: string;
  };
  photos: { url: string }[];
  owner: {
    name: string;
    trust_score: number;
    response_time_bucket?: string | null;
    last_active_bucket: string;
  };
};

type ListingCardProps = {
  listing: Listing;
  initialFavorite?: boolean;
};

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

export function ListingCard({
  listing,
  initialFavorite = false,
}: ListingCardProps) {
  const { accessToken } = useAuth();
  const { push } = useToast();
  const [favorited, setFavorited] = useState(initialFavorite);
  const [pending, setPending] = useState(false);
  const photo = listing.photos[0]?.url || "/placeholder.png";
  useEffect(() => setFavorited(initialFavorite), [initialFavorite]);

  const transmission = useMemo(
    () =>
      listing.car_details
        ? (TRANSMISSION_MAP[listing.car_details.transmission] ??
          listing.car_details.transmission)
        : null,
    [listing.car_details],
  );
  const fuel = useMemo(
    () =>
      listing.car_details
        ? (FUEL_MAP[listing.car_details.fuel] ?? listing.car_details.fuel)
        : null,
    [listing.car_details],
  );

  async function toggleFavorite(event: MouseEvent<HTMLButtonElement>) {
    event.preventDefault();
    event.stopPropagation();
    if (!accessToken) {
      push({ title: strings.listings.favoriteLoginRequired });
      return;
    }
    setPending(true);
    try {
      if (favorited) {
        await apiFetchWithAuth(
          `/listings/${listing.id}/favorite`,
          accessToken,
          { method: "DELETE" },
        );
        setFavorited(false);
        push({ title: strings.listings.removedFromFavorites });
      } else {
        await apiFetchWithAuth(
          `/listings/${listing.id}/favorite`,
          accessToken,
          { method: "POST" },
        );
        setFavorited(true);
        push({ title: strings.listings.addedToFavorites });
      }
    } catch {
      push({
        title: strings.common.error,
        description: strings.common.tryAgain,
      });
    } finally {
      setPending(false);
    }
  }

  return (
    <article className="group relative overflow-hidden rounded-card border border-border bg-surface transition-all duration-200 hover:border-info/50 hover:shadow-card-hover">
      <Link href={`/ilanlar/${listing.id}`} className="block">
        <div className="relative aspect-[16/11] overflow-hidden bg-surface-2">
          <ListingImage
            src={photo}
            alt={listing.title}
            className="transition-transform duration-500 group-hover:scale-[1.025]"
          />
          <div className="absolute left-3 top-3">
            <ListingBadge
              state={listing.state}
              staleState={listing.stale_state}
            />
          </div>
          <div className="absolute bottom-3 left-3 flex items-center gap-2 rounded-lg bg-surface/95 px-2.5 py-2 backdrop-blur-sm">
            <ShieldCheck
              className={cn(
                "h-4 w-4",
                listing.owner.trust_score >= 80
                  ? "text-accent"
                  : "text-text-muted",
              )}
            />
            <div>
              <div className="text-[8px] font-semibold uppercase tracking-wider text-text-muted">
                Satıcı güven puanı
              </div>
              <div className="mt-0.5 text-xs font-bold text-foreground">
                {listing.owner.trust_score}
                <span className="font-normal text-text-muted"> / 100</span>
              </div>
            </div>
          </div>
        </div>
        <div className="p-4 sm:p-5">
          <div className="mb-2 flex items-center gap-1 text-[11px] text-text-muted">
            <MapPin className="h-3 w-3" />
            {listing.district} ·{" "}
            {listing.city === "ISTANBUL" ? "İstanbul" : listing.city}
          </div>
          <h3 className="line-clamp-2 min-h-[2.75rem] text-sm font-semibold leading-[1.375rem] text-foreground">
            {listing.title}
          </h3>
          {listing.car_details && (
            <div className="mt-3 grid grid-cols-2 gap-x-2 gap-y-2 text-[11px] text-text-muted">
              <span className="inline-flex items-center gap-1.5">
                <Calendar className="h-3.5 w-3.5" />
                {listing.car_details.year}
              </span>
              <span className="inline-flex items-center gap-1.5">
                <Gauge className="h-3.5 w-3.5" />
                {listing.car_details.mileage.toLocaleString("tr-TR")} km
              </span>
              <span className="inline-flex items-center gap-1.5">
                <Cog className="h-3.5 w-3.5" />
                {transmission}
              </span>
              <span className="inline-flex items-center gap-1.5">
                <Fuel className="h-3.5 w-3.5" />
                {fuel}
              </span>
            </div>
          )}
          <div className="mt-4 flex items-end justify-between border-t border-border pt-4">
            <div>
              <div className="text-[10px] text-text-muted">İlan fiyatı</div>
              <div className="mt-0.5 font-display text-lg font-semibold tracking-tight">
                {listing.price.toLocaleString("tr-TR")}{" "}
                <span className="text-xs font-normal">TL</span>
              </div>
            </div>
            <span className="text-xs text-text-muted">İncele ↗</span>
          </div>
        </div>
      </Link>
      <button
        type="button"
        onClick={toggleFavorite}
        disabled={pending}
        aria-pressed={favorited}
        aria-label={
          favorited
            ? strings.listings.removeFromFavorites
            : strings.listings.addToFavorites
        }
        className="absolute right-3 top-3 inline-flex h-9 w-9 items-center justify-center rounded-full bg-surface/95 text-foreground transition-colors hover:bg-surface disabled:opacity-60"
      >
        <Heart
          className={cn(
            "h-4 w-4",
            favorited ? "fill-danger text-danger" : "text-text-muted",
          )}
        />
      </button>
    </article>
  );
}
