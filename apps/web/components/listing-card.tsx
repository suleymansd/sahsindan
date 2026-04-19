"use client";

import Link from "next/link";
import { Heart, MapPin, Gauge, Calendar, Fuel, Cog, Timer } from "lucide-react";
import { useMemo, useState, type MouseEvent } from "react";

import { ListingBadge, TrustBadge } from "@/components/badges";
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

export function ListingCard({ listing, initialFavorite = false }: ListingCardProps) {
  const { accessToken } = useAuth();
  const { push } = useToast();
  const [favorited, setFavorited] = useState(initialFavorite);
  const [pending, setPending] = useState(false);
  const photo = listing.photos[0]?.url || "/placeholder.png";

  const transmission = useMemo(
    () =>
      listing.car_details
        ? TRANSMISSION_MAP[listing.car_details.transmission] ?? listing.car_details.transmission
        : null,
    [listing.car_details]
  );
  const fuel = useMemo(
    () =>
      listing.car_details
        ? FUEL_MAP[listing.car_details.fuel] ?? listing.car_details.fuel
        : null,
    [listing.car_details]
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
        await apiFetchWithAuth(`/listings/${listing.id}/favorite`, accessToken, { method: "DELETE" });
        setFavorited(false);
        push({ title: strings.listings.removedFromFavorites });
      } else {
        await apiFetchWithAuth(`/listings/${listing.id}/favorite`, accessToken, { method: "POST" });
        setFavorited(true);
        push({ title: strings.listings.addedToFavorites });
      }
    } catch {
      push({ title: strings.common.error, description: strings.common.tryAgain });
    } finally {
      setPending(false);
    }
  }

  return (
    <Link
      href={`/ilanlar/${listing.id}`}
      className="group relative block overflow-hidden rounded-card border border-border/80 bg-surface/88 shadow-card backdrop-blur-md transition-all duration-200 hover:-translate-y-0.5 hover:border-border-strong hover:shadow-card-hover"
    >
      <div className="relative aspect-[4/3] overflow-hidden bg-surface-2">
        <img
          src={photo}
          alt={listing.title}
          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-[1.03]"
          loading="lazy"
        />

        <div className="absolute left-3 top-3 flex flex-wrap gap-1.5">
          <ListingBadge state={listing.state} staleState={listing.stale_state} />
          <TrustBadge score={listing.owner.trust_score} />
        </div>

        <button
          type="button"
          onClick={toggleFavorite}
          disabled={pending}
          aria-label={favorited ? strings.listings.removeFromFavorites : strings.listings.addToFavorites}
          className={cn(
            "absolute right-3 top-3 inline-flex h-9 w-9 items-center justify-center rounded-full border border-border/70 bg-surface/92 shadow-medium backdrop-blur transition-all",
            "hover:scale-105 active:scale-95 disabled:opacity-60"
          )}
        >
          <Heart
            className={cn(
              "h-[18px] w-[18px] transition-colors",
              favorited ? "fill-danger text-danger" : "text-text-muted"
            )}
          />
        </button>
      </div>

      <div className="space-y-3 p-4">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0 flex-1">
            <h3 className="truncate text-title-sm font-semibold text-foreground">{listing.title}</h3>
            {listing.car_details && (
              <p className="mt-0.5 truncate text-xs text-text-muted">
                {listing.car_details.brand} {listing.car_details.model}
              </p>
            )}
          </div>
          <div className="text-right font-display text-lg font-bold text-foreground">
            ₺{listing.price.toLocaleString("tr-TR")}
          </div>
        </div>

        {listing.car_details && (
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-text-muted">
            <span className="inline-flex items-center gap-1">
              <Calendar className="h-3.5 w-3.5" />
              {listing.car_details.year}
            </span>
            <span className="inline-flex items-center gap-1">
              <Gauge className="h-3.5 w-3.5" />
              {listing.car_details.mileage.toLocaleString("tr-TR")} km
            </span>
            <span className="inline-flex items-center gap-1">
              <Cog className="h-3.5 w-3.5" />
              {transmission}
            </span>
            <span className="inline-flex items-center gap-1">
              <Fuel className="h-3.5 w-3.5" />
              {fuel}
            </span>
          </div>
        )}

        <div className="flex items-center justify-between border-t border-border/70 pt-3 text-xs">
          <span className="inline-flex items-center gap-1 text-text-muted">
            <MapPin className="h-3.5 w-3.5 text-primary" />
            <span className="font-medium text-foreground">{listing.city}</span>
            <span>·</span>
            <span>{listing.district}</span>
          </span>
          <span className="inline-flex items-center gap-1 text-text-muted">
            <Timer className="h-3.5 w-3.5 text-accent" />
            {listing.owner.response_time_bucket || strings.listings.calculatingResponseTime}
          </span>
        </div>
      </div>
    </Link>
  );
}
