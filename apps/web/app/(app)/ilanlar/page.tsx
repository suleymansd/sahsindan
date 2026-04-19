"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  Car,
  Home,
  Wrench,
  Search,
  SlidersHorizontal,
  X,
  Filter,
  RotateCcw,
} from "lucide-react";

import { ListingCard, type Listing } from "@/components/listing-card";
import { CategoryCard } from "@/components/category-card";
import { FilterChips } from "@/components/filter-chips";
import { SectionHeader } from "@/components/section-header";
import { TrustBand } from "@/components/trust-band";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { EmptyState } from "@/components/ui/empty-state";
import { Skeleton } from "@/components/ui/skeleton";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { strings } from "@/lib/strings.tr";
import { UI } from "@/lib/strings";

const BRANDS = [
  "Alfa Romeo",
  "Audi",
  "BMW",
  "Chevrolet",
  "Fiat",
  "Ford",
  "Honda",
  "Hyundai",
  "Mercedes",
  "Nissan",
  "Opel",
  "Peugeot",
  "Renault",
  "Seat",
  "Skoda",
  "Toyota",
  "Volkswagen",
  "Volvo",
];

const BRAND_MODELS: Record<string, string[]> = {
  "Alfa Romeo": ["Giulia", "Stelvio", "Tonale"],
  Audi: ["A3", "A4", "A5", "A6", "Q3", "Q5", "Q7"],
  BMW: ["1 Series", "2 Series", "3 Series", "4 Series", "5 Series", "X1", "X3", "X5"],
  Chevrolet: ["Cruze", "Malibu", "Trax"],
  Fiat: ["Egea", "Tipo", "500"],
  Ford: ["Focus", "Fiesta", "Mondeo", "Kuga"],
  Honda: ["Civic", "Accord", "CR-V", "HR-V"],
  Hyundai: ["i20", "i30", "Elantra", "Tucson", "Santa Fe"],
  Mercedes: ["A180", "C200", "C220", "E200", "E220", "GLA", "GLC"],
  Nissan: ["Sentra", "Altima", "Qashqai", "X-Trail"],
  Opel: ["Corsa", "Astra", "Insignia"],
  Peugeot: ["208", "308", "3008", "5008"],
  Renault: ["Clio", "Megane", "Fluence", "Kadjar"],
  Seat: ["Ibiza", "Leon", "Ateca"],
  Skoda: ["Fabia", "Octavia", "Superb", "Kodiaq"],
  Toyota: ["Corolla", "Camry", "Yaris", "RAV4"],
  Volkswagen: ["Golf", "Polo", "Passat", "Tiguan", "Touareg"],
  Volvo: ["S60", "S90", "XC40", "XC60", "XC90"],
};

const TRANSMISSIONS = [
  { label: "Otomatik", value: "Automatic" },
  { label: "Manuel", value: "Manual" },
];
const FUELS = [
  { label: "Benzin", value: "Gasoline" },
  { label: "Dizel", value: "Diesel" },
  { label: "Hibrit", value: "Hybrid" },
  { label: "Elektrik", value: "Electric" },
  { label: "LPG", value: "LPG" },
];
const COLORS = ["Beyaz", "Siyah", "Gri", "Kırmızı", "Mavi", "Yeşil", "Turuncu", "Sarı"];

const SORT_OPTIONS = [
  { value: "newest", label: "En yeni" },
  { value: "price_asc", label: "Fiyat (artan)" },
  { value: "price_desc", label: "Fiyat (azalan)" },
  { value: "mileage_asc", label: "KM (artan)" },
  { value: "mileage_desc", label: "KM (azalan)" },
  { value: "year_desc", label: "Yıl (yeni)" },
  { value: "year_asc", label: "Yıl (eski)" },
];

type Filters = {
  q: string;
  brand: string;
  model: string;
  city: string;
  district: string;
  min_price: string;
  max_price: string;
  year_min: string;
  year_max: string;
  mileage_min: string;
  mileage_max: string;
  transmission: string;
  fuel: string;
  color: string;
  sort: string;
};

const EMPTY_FILTERS: Filters = {
  q: "",
  brand: "",
  model: "",
  city: "ISTANBUL",
  district: "",
  min_price: "",
  max_price: "",
  year_min: "",
  year_max: "",
  mileage_min: "",
  mileage_max: "",
  transmission: "",
  fuel: "",
  color: "",
  sort: "newest",
};

const SELECT_CLASS =
  "flex h-11 w-full items-center rounded-btn border border-border bg-surface px-3 text-sm text-foreground transition-colors hover:border-border-strong focus-visible:outline-none focus-visible:border-primary focus-visible:shadow-ring disabled:cursor-not-allowed disabled:opacity-60";

const LABEL_CLASS = "text-xs font-semibold text-foreground";

function FieldLabel({ htmlFor, children }: { htmlFor: string; children: React.ReactNode }) {
  return (
    <label htmlFor={htmlFor} className={LABEL_CLASS}>
      {children}
    </label>
  );
}

function FiltersPanel({
  filters,
  onChange,
  onApply,
  onClear,
}: {
  filters: Filters;
  onChange: (next: Partial<Filters>) => void;
  onApply: () => void;
  onClear: () => void;
}) {
  return (
    <div className="space-y-5">
      <div className="space-y-1.5">
        <FieldLabel htmlFor="q">Anahtar kelime</FieldLabel>
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
          <Input
            id="q"
            placeholder={strings.listings.searchPlaceholder}
            value={filters.q}
            onChange={(event) => onChange({ q: event.target.value })}
            className="pl-9"
          />
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
        <div className="space-y-1.5">
          <FieldLabel htmlFor="city">Şehir</FieldLabel>
          <select
            id="city"
            className={SELECT_CLASS}
            value={filters.city}
            onChange={(event) => onChange({ city: event.target.value })}
          >
            <option value="">Tüm şehirler</option>
            <option value="ISTANBUL">İstanbul</option>
          </select>
        </div>
        <div className="space-y-1.5">
          <FieldLabel htmlFor="district">İlçe</FieldLabel>
          <Input
            id="district"
            placeholder="Örn. Kadıköy"
            value={filters.district}
            onChange={(event) => onChange({ district: event.target.value })}
          />
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
        <div className="space-y-1.5">
          <FieldLabel htmlFor="brand">Marka</FieldLabel>
          <select
            id="brand"
            className={SELECT_CLASS}
            value={filters.brand}
            onChange={(event) => onChange({ brand: event.target.value, model: "" })}
          >
            <option value="">Tüm markalar</option>
            {BRANDS.map((brand) => (
              <option key={brand} value={brand}>
                {brand}
              </option>
            ))}
          </select>
        </div>
        {filters.brand && BRAND_MODELS[filters.brand] && (
          <div className="space-y-1.5">
            <FieldLabel htmlFor="model">Model</FieldLabel>
            <select
              id="model"
              className={SELECT_CLASS}
              value={filters.model}
              onChange={(event) => onChange({ model: event.target.value })}
            >
              <option value="">Tüm modeller</option>
              {BRAND_MODELS[filters.brand].map((model) => (
                <option key={model} value={model}>
                  {model}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      <div className="space-y-1.5">
        <span className={LABEL_CLASS}>Yıl aralığı</span>
        <div className="grid grid-cols-2 gap-2">
          <Input
            type="number"
            placeholder="Min"
            value={filters.year_min}
            onChange={(event) => onChange({ year_min: event.target.value })}
          />
          <Input
            type="number"
            placeholder="Max"
            value={filters.year_max}
            onChange={(event) => onChange({ year_max: event.target.value })}
          />
        </div>
      </div>

      <div className="space-y-1.5">
        <span className={LABEL_CLASS}>Kilometre aralığı</span>
        <div className="grid grid-cols-2 gap-2">
          <Input
            type="number"
            placeholder="Min km"
            value={filters.mileage_min}
            onChange={(event) => onChange({ mileage_min: event.target.value })}
          />
          <Input
            type="number"
            placeholder="Max km"
            value={filters.mileage_max}
            onChange={(event) => onChange({ mileage_max: event.target.value })}
          />
        </div>
      </div>

      <div className="space-y-1.5">
        <span className={LABEL_CLASS}>Fiyat aralığı (₺)</span>
        <div className="grid grid-cols-2 gap-2">
          <Input
            type="number"
            placeholder="Min"
            value={filters.min_price}
            onChange={(event) => onChange({ min_price: event.target.value })}
          />
          <Input
            type="number"
            placeholder="Max"
            value={filters.max_price}
            onChange={(event) => onChange({ max_price: event.target.value })}
          />
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
        <div className="space-y-1.5">
          <FieldLabel htmlFor="transmission">Vites</FieldLabel>
          <select
            id="transmission"
            className={SELECT_CLASS}
            value={filters.transmission}
            onChange={(event) => onChange({ transmission: event.target.value })}
          >
            <option value="">Tümü</option>
            {TRANSMISSIONS.map((item) => (
              <option key={item.value} value={item.value}>
                {item.label}
              </option>
            ))}
          </select>
        </div>
        <div className="space-y-1.5">
          <FieldLabel htmlFor="fuel">Yakıt</FieldLabel>
          <select
            id="fuel"
            className={SELECT_CLASS}
            value={filters.fuel}
            onChange={(event) => onChange({ fuel: event.target.value })}
          >
            <option value="">Tümü</option>
            {FUELS.map((item) => (
              <option key={item.value} value={item.value}>
                {item.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="space-y-1.5">
        <FieldLabel htmlFor="color">Renk</FieldLabel>
        <select
          id="color"
          className={SELECT_CLASS}
          value={filters.color}
          onChange={(event) => onChange({ color: event.target.value })}
        >
          <option value="">Tümü</option>
          {COLORS.map((item) => (
            <option key={item} value={item}>
              {item}
            </option>
          ))}
        </select>
      </div>

      <div className="flex items-center gap-2 pt-2">
        <Button onClick={onApply} className="flex-1">
          <Filter className="h-4 w-4" />
          Filtrele
        </Button>
        <Button variant="outline" onClick={onClear} aria-label="Temizle">
          <RotateCcw className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}

export default function ListingsPage() {
  const { accessToken, user } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();

  const canBrowse =
    user?.role === "USER_VERIFIED" || user?.role === "ADMIN" || user?.role === "MODERATOR";

  const initialFilters = useMemo<Filters>(
    () => ({
      q: searchParams?.get("q") || "",
      brand: searchParams?.get("brand") || "",
      model: searchParams?.get("model") || "",
      city: searchParams?.get("city") || "ISTANBUL",
      district: searchParams?.get("district") || "",
      min_price: searchParams?.get("min_price") || "",
      max_price: searchParams?.get("max_price") || "",
      year_min: searchParams?.get("year_min") || "",
      year_max: searchParams?.get("year_max") || "",
      mileage_min: searchParams?.get("mileage_min") || "",
      mileage_max: searchParams?.get("mileage_max") || "",
      transmission: searchParams?.get("transmission") || "",
      fuel: searchParams?.get("fuel") || "",
      color: searchParams?.get("color") || "",
      sort: searchParams?.get("sort") || "newest",
    }),
    [searchParams]
  );

  const [filters, setFilters] = useState<Filters>(initialFilters);

  useEffect(() => {
    setFilters(initialFilters);
  }, [initialFilters]);

  const queryParams = useMemo(() => {
    const params = new URLSearchParams();
    Object.entries(filters).forEach(([key, value]) => {
      if (value) params.set(key, value);
    });
    return params.toString();
  }, [filters]);

  const {
    data: listings,
    isLoading,
    isError,
    refetch,
  } = useQuery({
    queryKey: ["listings", queryParams],
    queryFn: async () => {
      if (!accessToken) return [] as Listing[];
      const res = await apiFetchWithAuth(`/listings?${queryParams}`, accessToken);
      return res.data as Listing[];
    },
    enabled: Boolean(accessToken && canBrowse),
  });

  const {
    data: favorites,
    isLoading: favoritesLoading,
  } = useQuery({
    queryKey: ["favorites-preview"],
    queryFn: async () => {
      if (!accessToken) return [] as Listing[];
      const res = await apiFetchWithAuth("/favorites", accessToken);
      return res.data as Listing[];
    },
    enabled: Boolean(accessToken && canBrowse),
  });

  const [recentListings, setRecentListings] = useState<
    { id: number; title: string; price: number; city: string; district: string; photo: string; meta?: string }[]
  >([]);

  useEffect(() => {
    try {
      const stored = JSON.parse(localStorage.getItem("recentListings") || "[]");
      if (Array.isArray(stored)) setRecentListings(stored);
    } catch {
      setRecentListings([]);
    }
  }, []);

  const featuredListings = useMemo(() => (listings ? listings.slice(0, 8) : []), [listings]);
  const totalCount = listings?.length ?? 0;

  function syncFilters(next: Filters) {
    setFilters(next);
    const params = new URLSearchParams();
    Object.entries(next).forEach(([key, value]) => {
      if (value) params.set(key, value);
    });
    const query = params.toString();
    router.push(query ? `/ilanlar?${query}` : "/ilanlar");
  }

  const handleApply = () => syncFilters(filters);
  const handleClear = () => syncFilters(EMPTY_FILTERS);

  function applyQuickFilter(next: Partial<Filters>) {
    const merged = { ...filters, ...next };
    if (Object.prototype.hasOwnProperty.call(next, "brand") && !next.brand) {
      merged.model = "";
    }
    syncFilters(merged);
  }

  const activeFilters = useMemo(() => {
    const items: Array<{ key: keyof Filters; label: string }> = [];
    if (filters.brand) items.push({ key: "brand", label: `Marka: ${filters.brand}` });
    if (filters.model) items.push({ key: "model", label: `Model: ${filters.model}` });
    if (filters.district) items.push({ key: "district", label: `İlçe: ${filters.district}` });
    if (filters.year_min) items.push({ key: "year_min", label: `Yıl ≥ ${filters.year_min}` });
    if (filters.year_max) items.push({ key: "year_max", label: `Yıl ≤ ${filters.year_max}` });
    if (filters.mileage_min) items.push({ key: "mileage_min", label: `KM ≥ ${filters.mileage_min}` });
    if (filters.mileage_max) items.push({ key: "mileage_max", label: `KM ≤ ${filters.mileage_max}` });
    if (filters.min_price) items.push({ key: "min_price", label: `₺ ≥ ${filters.min_price}` });
    if (filters.max_price) items.push({ key: "max_price", label: `₺ ≤ ${filters.max_price}` });
    if (filters.transmission) {
      const label =
        TRANSMISSIONS.find((item) => item.value === filters.transmission)?.label ??
        filters.transmission;
      items.push({ key: "transmission", label });
    }
    if (filters.fuel) {
      const label = FUELS.find((item) => item.value === filters.fuel)?.label ?? filters.fuel;
      items.push({ key: "fuel", label });
    }
    if (filters.color) items.push({ key: "color", label: filters.color });
    return items;
  }, [filters]);

  return (
    <div className="container pb-16">
      <div className="sticky top-[72px] z-30 -mx-4 border-b border-border bg-background/90 px-4 py-4 backdrop-blur-md md:-mx-6 md:px-6">
        <div className="space-y-3">
          <div className="flex flex-wrap items-end justify-between gap-3">
            <div>
              <h1 className="font-display text-display-sm font-bold tracking-tight text-foreground">
                {strings.listings.title}
              </h1>
              <p className="text-body-sm text-text-muted">{strings.listings.subtitle}</p>
            </div>
            <div className="text-xs text-text-muted">
              <span className="font-semibold text-foreground">{totalCount}</span> ilan
            </div>
          </div>

          <form
            onSubmit={(event) => {
              event.preventDefault();
              handleApply();
            }}
            className="flex flex-wrap items-center gap-2"
          >
            <div className="relative min-w-[220px] flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
              <Input
                placeholder={strings.listings.searchPlaceholder}
                value={filters.q}
                onChange={(event) => setFilters((prev) => ({ ...prev, q: event.target.value }))}
                className="pl-9"
              />
            </div>
            <select
              className={`${SELECT_CLASS} w-auto min-w-[160px]`}
              value={filters.sort}
              onChange={(event) => {
                const next = { ...filters, sort: event.target.value };
                syncFilters(next);
              }}
            >
              {SORT_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
            <Button type="submit">
              <Search className="h-4 w-4" />
              Ara
            </Button>
            <Sheet>
              <SheetTrigger asChild>
                <Button variant="outline" className="lg:hidden">
                  <SlidersHorizontal className="h-4 w-4" />
                  Filtreler
                </Button>
              </SheetTrigger>
              <SheetContent>
                <div>
                  <h2 className="font-display text-title-lg font-semibold">Filtreler</h2>
                  <p className="text-xs text-text-muted">İstediğin aracı daralt</p>
                </div>
                <div className="mt-5">
                  <FiltersPanel
                    filters={filters}
                    onChange={(next) => setFilters((prev) => ({ ...prev, ...next }))}
                    onApply={handleApply}
                    onClear={handleClear}
                  />
                </div>
              </SheetContent>
            </Sheet>
          </form>

          <FilterChips
            chips={[
              { label: "İstanbul", onClick: () => applyQuickFilter({ city: "ISTANBUL" }) },
              { label: "0–500K ₺", onClick: () => applyQuickFilter({ max_price: "500000" }) },
              { label: "2018+", onClick: () => applyQuickFilter({ year_min: "2018" }) },
              { label: "Otomatik", onClick: () => applyQuickFilter({ transmission: "Automatic" }) },
              { label: "Dizel", onClick: () => applyQuickFilter({ fuel: "Diesel" }) },
              { label: "Benzin", onClick: () => applyQuickFilter({ fuel: "Gasoline" }) },
            ]}
          />

          {activeFilters.length > 0 && (
            <div className="flex flex-wrap items-center gap-1.5 text-xs">
              <span className="text-text-muted">Uygulanan:</span>
              {activeFilters.map((filter) => (
                <button
                  key={filter.key}
                  type="button"
                  onClick={() => applyQuickFilter({ [filter.key]: "" } as Partial<Filters>)}
                  className="group inline-flex items-center gap-1 rounded-full border border-border bg-surface px-2.5 py-1 font-medium text-foreground transition-colors hover:border-border-strong"
                >
                  {filter.label}
                  <X className="h-3 w-3 text-text-muted group-hover:text-danger" />
                </button>
              ))}
              <button
                type="button"
                onClick={handleClear}
                className="inline-flex items-center gap-1 rounded-full border border-dashed border-border px-2.5 py-1 text-text-muted transition-colors hover:text-foreground"
              >
                <RotateCcw className="h-3 w-3" />
                Temizle
              </button>
            </div>
          )}
        </div>
      </div>

      {!canBrowse ? (
        <div className="mt-10 rounded-card border border-border bg-surface p-12 shadow-card">
          <EmptyState
            icon={accessToken ? Car : Search}
            title={accessToken ? strings.listings.verificationRequired : strings.listings.loginRequired}
            description={
              accessToken
                ? strings.listings.verificationRequiredDescription
                : strings.listings.loginRequiredDescription
            }
          />
        </div>
      ) : (
        <>
          <section className="mt-8 space-y-5">
            <SectionHeader title={UI.sections.categories} description="Şimdilik otomobil ile başlıyoruz." />
            <div className="grid gap-4 md:grid-cols-3">
              <CategoryCard
                title="Araç"
                description="Premium doğrulamalı otomobil ilanları."
                icon={<Car size={20} />}
                href="/ilanlar"
              />
              <CategoryCard
                title="Emlak"
                description="Yakında sadece doğrulanmış emlak ilanları."
                icon={<Home size={20} />}
                disabled
              />
              <CategoryCard
                title="Yedek Parça"
                description="Doğrulanmış satıcılardan parça satışları."
                icon={<Wrench size={20} />}
                disabled
              />
            </div>
          </section>

          <section className="mt-12 space-y-5">
            <SectionHeader
              title={UI.sections.featured}
              description="Editör seçkisi, hızlı yanıtlayan satıcılar."
            />
            {isLoading ? (
              <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
                {Array.from({ length: 4 }).map((_, idx) => (
                  <Skeleton key={idx} className="h-72" />
                ))}
              </div>
            ) : isError ? (
              <div className="flex items-center justify-between rounded-card border border-border bg-surface p-5 text-sm text-text-muted shadow-card">
                İlanlar yüklenemedi.
                <Button variant="outline" size="sm" onClick={() => refetch()}>
                  Tekrar dene
                </Button>
              </div>
            ) : (
              <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
                {featuredListings.map((listing) => (
                  <ListingCard key={listing.id} listing={listing} />
                ))}
              </div>
            )}
          </section>

          <section className="mt-12 space-y-5">
            <SectionHeader
              title={UI.sections.favorites}
              description="Kaydettiğin ilanlar burada hızlı erişimde."
              actionLabel="Tüm favoriler"
              actionHref="/favoriler"
            />
            {favoritesLoading ? (
              <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
                {Array.from({ length: 3 }).map((_, idx) => (
                  <Skeleton key={idx} className="h-72" />
                ))}
              </div>
            ) : favorites && favorites.length > 0 ? (
              <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
                {favorites.slice(0, 6).map((listing) => (
                  <ListingCard key={listing.id} listing={listing} initialFavorite />
                ))}
              </div>
            ) : (
              <div className="rounded-card border border-dashed border-border bg-surface-2/60 p-8 text-center text-sm text-text-muted">
                {UI.emptyStates.favorites}
              </div>
            )}
          </section>

          {recentListings.length > 0 && (
            <section className="mt-12 space-y-5">
              <SectionHeader
                title={UI.sections.recent}
                description="Son baktığın ilanlara geri dön."
              />
              <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                {recentListings.map((item) => (
                  <Link
                    key={item.id}
                    href={`/ilanlar/${item.id}`}
                    className="group overflow-hidden rounded-card border border-border bg-surface shadow-card transition-all duration-200 hover:-translate-y-0.5 hover:border-border-strong hover:shadow-card-hover"
                  >
                    <div className="aspect-[16/10] overflow-hidden bg-surface-2">
                      <img
                        src={item.photo}
                        alt={item.title}
                        className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-[1.03]"
                      />
                    </div>
                    <div className="space-y-1 p-4">
                      <div className="truncate text-sm font-semibold text-foreground">{item.title}</div>
                      <div className="text-xs text-text-muted">
                        {item.city} · {item.district}
                      </div>
                      <div className="text-sm font-bold text-foreground">
                        ₺{Number(item.price).toLocaleString("tr-TR")}
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            </section>
          )}

          <section className="mt-12">
            <TrustBand />
          </section>

          <section className="mt-14 space-y-5">
            <SectionHeader title="Tüm ilanlar" description={`${totalCount} ilan bulundu`} />
            <div className="grid gap-6 lg:grid-cols-[280px_1fr]">
              <aside className="hidden lg:block">
                <div className="sticky top-[220px] rounded-card border border-border bg-surface p-5 shadow-card">
                  <div className="flex items-center justify-between">
                    <h3 className="text-sm font-semibold text-foreground">Filtreler</h3>
                    <button
                      type="button"
                      onClick={handleClear}
                      className="text-xs font-medium text-primary hover:underline"
                    >
                      Temizle
                    </button>
                  </div>
                  <div className="mt-4">
                    <FiltersPanel
                      filters={filters}
                      onChange={(next) => setFilters((prev) => ({ ...prev, ...next }))}
                      onApply={handleApply}
                      onClear={handleClear}
                    />
                  </div>
                </div>
              </aside>

              <div>
                {isLoading ? (
                  <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
                    {Array.from({ length: 6 }).map((_, idx) => (
                      <Skeleton key={idx} className="h-72" />
                    ))}
                  </div>
                ) : isError ? (
                  <div className="flex items-center justify-between rounded-card border border-border bg-surface p-5 text-sm text-text-muted shadow-card">
                    Liste yüklenemedi.
                    <Button variant="outline" size="sm" onClick={() => refetch()}>
                      Tekrar dene
                    </Button>
                  </div>
                ) : listings && listings.length > 0 ? (
                  <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
                    {listings.map((listing) => (
                      <ListingCard key={listing.id} listing={listing} />
                    ))}
                  </div>
                ) : (
                  <div className="rounded-card border border-dashed border-border bg-surface-2/60 p-12 text-center text-sm text-text-muted">
                    {UI.emptyStates.listings}
                  </div>
                )}
              </div>
            </div>
          </section>
        </>
      )}
    </div>
  );
}
