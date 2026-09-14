"use client";

import Link from "next/link";
import { useEffect, useId, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Search, SlidersHorizontal, X, Filter, RotateCcw } from "lucide-react";

import { ListingCard, type Listing } from "@/components/listing-card";
import { FilterChips } from "@/components/filter-chips";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { EmptyState } from "@/components/ui/empty-state";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Sheet,
  SheetContent,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
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
  BMW: [
    "1 Series",
    "2 Series",
    "3 Series",
    "4 Series",
    "5 Series",
    "X1",
    "X3",
    "X5",
  ],
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
const COLORS = [
  "Beyaz",
  "Siyah",
  "Gri",
  "Kırmızı",
  "Mavi",
  "Yeşil",
  "Turuncu",
  "Sarı",
];

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

function FieldLabel({
  htmlFor,
  children,
}: {
  htmlFor: string;
  children: React.ReactNode;
}) {
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
  const prefix = useId();
  return (
    <div className="space-y-5">
      <div className="space-y-1.5">
        <FieldLabel htmlFor={`${prefix}-q`}>Anahtar kelime</FieldLabel>
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
          <Input
            id={`${prefix}-q`}
            placeholder={strings.listings.searchPlaceholder}
            value={filters.q}
            onChange={(event) => onChange({ q: event.target.value })}
            className="pl-9"
          />
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
        <div className="space-y-1.5">
          <FieldLabel htmlFor={`${prefix}-city`}>Şehir</FieldLabel>
          <select
            id={`${prefix}-city`}
            className={SELECT_CLASS}
            value={filters.city}
            onChange={(event) => onChange({ city: event.target.value })}
          >
            <option value="">Tüm şehirler</option>
            <option value="ISTANBUL">İstanbul</option>
          </select>
        </div>
        <div className="space-y-1.5">
          <FieldLabel htmlFor={`${prefix}-district`}>İlçe</FieldLabel>
          <Input
            id={`${prefix}-district`}
            placeholder="Örn. Kadıköy"
            value={filters.district}
            onChange={(event) => onChange({ district: event.target.value })}
          />
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
        <div className="space-y-1.5">
          <FieldLabel htmlFor={`${prefix}-brand`}>Marka</FieldLabel>
          <select
            id={`${prefix}-brand`}
            className={SELECT_CLASS}
            value={filters.brand}
            onChange={(event) =>
              onChange({ brand: event.target.value, model: "" })
            }
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
            <FieldLabel htmlFor={`${prefix}-model`}>Model</FieldLabel>
            <select
              id={`${prefix}-model`}
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
            aria-label="En düşük model yılı"
            value={filters.year_min}
            onChange={(event) => onChange({ year_min: event.target.value })}
          />
          <Input
            type="number"
            placeholder="Max"
            aria-label="En yüksek model yılı"
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
            aria-label="En düşük kilometre"
            value={filters.mileage_min}
            onChange={(event) => onChange({ mileage_min: event.target.value })}
          />
          <Input
            type="number"
            placeholder="Max km"
            aria-label="En yüksek kilometre"
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
            aria-label="En düşük fiyat"
            value={filters.min_price}
            onChange={(event) => onChange({ min_price: event.target.value })}
          />
          <Input
            type="number"
            placeholder="Max"
            aria-label="En yüksek fiyat"
            value={filters.max_price}
            onChange={(event) => onChange({ max_price: event.target.value })}
          />
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
        <div className="space-y-1.5">
          <FieldLabel htmlFor={`${prefix}-transmission`}>Vites</FieldLabel>
          <select
            id={`${prefix}-transmission`}
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
          <FieldLabel htmlFor={`${prefix}-fuel`}>Yakıt</FieldLabel>
          <select
            id={`${prefix}-fuel`}
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
        <FieldLabel htmlFor={`${prefix}-color`}>Renk</FieldLabel>
        <select
          id={`${prefix}-color`}
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
    user?.role === "USER_VERIFIED" ||
    user?.role === "ADMIN" ||
    user?.role === "MODERATOR";

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
    [searchParams],
  );

  const [filters, setFilters] = useState<Filters>(initialFilters);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [page, setPage] = useState(0);

  useEffect(() => {
    setFilters(initialFilters);
    setPage(0);
  }, [initialFilters]);

  const queryParams = useMemo(() => {
    const params = new URLSearchParams();
    Object.entries(initialFilters).forEach(([key, value]) => {
      if (value) params.set(key, value);
    });
    return params.toString();
  }, [initialFilters]);

  const {
    data,
    isLoading,
    isError,
    refetch,
  } = useQuery({
    queryKey: ["listings", queryParams, page],
    queryFn: async () => {
      if (!accessToken) return { items: [] as Listing[], hasMore: false };
      const res = await apiFetchWithAuth(
        `/listings?${queryParams}&limit=24&offset=${page * 24}`,
        accessToken,
      );
      return { items: res.data as Listing[], hasMore: Boolean(res.meta?.has_more) };
    },
    enabled: Boolean(accessToken && canBrowse),
  });

  const listings = data?.items;
  const totalCount = listings?.length ?? 0;

  function syncFilters(next: Filters) {
    setFilters(next);
    const params = new URLSearchParams();
    Object.entries(next).forEach(([key, value]) => {
      if (value) params.set(key, value);
    });
    const query = params.toString();
    router.push(query ? `/ilanlar?${query}` : "/ilanlar", { scroll: false });
    setFiltersOpen(false);
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
    if (initialFilters.brand)
      items.push({ key: "brand", label: `Marka: ${initialFilters.brand}` });
    if (initialFilters.model)
      items.push({ key: "model", label: `Model: ${initialFilters.model}` });
    if (initialFilters.district)
      items.push({
        key: "district",
        label: `İlçe: ${initialFilters.district}`,
      });
    if (initialFilters.year_min)
      items.push({
        key: "year_min",
        label: `Yıl ≥ ${initialFilters.year_min}`,
      });
    if (initialFilters.year_max)
      items.push({
        key: "year_max",
        label: `Yıl ≤ ${initialFilters.year_max}`,
      });
    if (initialFilters.mileage_min)
      items.push({
        key: "mileage_min",
        label: `KM ≥ ${initialFilters.mileage_min}`,
      });
    if (initialFilters.mileage_max)
      items.push({
        key: "mileage_max",
        label: `KM ≤ ${initialFilters.mileage_max}`,
      });
    if (initialFilters.min_price)
      items.push({
        key: "min_price",
        label: `₺ ≥ ${initialFilters.min_price}`,
      });
    if (initialFilters.max_price)
      items.push({
        key: "max_price",
        label: `₺ ≤ ${initialFilters.max_price}`,
      });
    if (initialFilters.transmission) {
      const label =
        TRANSMISSIONS.find((item) => item.value === initialFilters.transmission)
          ?.label ?? initialFilters.transmission;
      items.push({ key: "transmission", label });
    }
    if (initialFilters.fuel) {
      const label =
        FUELS.find((item) => item.value === initialFilters.fuel)?.label ??
        initialFilters.fuel;
      items.push({ key: "fuel", label });
    }
    if (initialFilters.color)
      items.push({ key: "color", label: initialFilters.color });
    return items;
  }, [initialFilters]);

  return (
    <div className="container py-7 sm:py-9">
      <nav
        aria-label="İçerik yolu"
        className="mb-6 flex items-center gap-2 text-xs text-text-muted"
      >
        <Link href="/app" className="hover:text-foreground">
          Keşfet
        </Link>
        <span>/</span>
        <span>Otomobil ilanları</span>
      </nav>
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="market-eyebrow text-accent">SANA UYGUN ARACI BUL</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight sm:text-3xl">
            Otomobil ilanları
          </h1>
          <p className="mt-2 text-sm text-text-muted">
            İstanbul’da yeni bir yolculuğa başla.
          </p>
        </div>
      </div>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          handleApply();
        }}
        className="my-6 flex flex-wrap gap-2"
      >
        <div className="relative min-w-0 flex-1">
          <Search className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
          <Input
            aria-label="İlanlarda ara"
            placeholder={strings.listings.searchPlaceholder}
            value={filters.q}
            onChange={(event) =>
              setFilters((prev) => ({ ...prev, q: event.target.value }))
            }
            className="h-12 bg-surface pl-11"
          />
        </div>
        <Button type="submit" className="h-12 px-6">
          Ara
          <Search className="h-4 w-4" />
        </Button>
        <Sheet open={filtersOpen} onOpenChange={setFiltersOpen}>
          <SheetTrigger asChild>
            <Button
              type="button"
              variant="outline"
              className="h-12 lg:hidden"
              aria-label="Filtreleri aç"
            >
              <SlidersHorizontal className="h-4 w-4" />
              <span className="hidden sm:inline">Filtreler</span>
            </Button>
          </SheetTrigger>
          <SheetContent>
            <SheetTitle className="mb-6 text-lg font-semibold">
              Filtreler
            </SheetTitle>
            <FiltersPanel
              filters={filters}
              onChange={(next) => setFilters((prev) => ({ ...prev, ...next }))}
              onApply={handleApply}
              onClear={handleClear}
            />
          </SheetContent>
        </Sheet>
      </form>
      <FilterChips
        chips={[
          {
            label: "Otomatik",
            onClick: () => applyQuickFilter({ transmission: "Automatic" }),
          },
          {
            label: "Elektrikli",
            onClick: () => applyQuickFilter({ fuel: "Electric" }),
          },
          {
            label: "2018 ve üzeri",
            onClick: () => applyQuickFilter({ year_min: "2018" }),
          },
          {
            label: "500.000 TL’ye kadar",
            onClick: () => applyQuickFilter({ max_price: "500000" }),
          },
        ]}
      />
      <div className="mt-8 grid items-start gap-7 lg:grid-cols-[240px_minmax(0,1fr)]">
        <aside className="hidden rounded-xl border border-border bg-surface p-5 lg:block">
          <div className="mb-5 flex items-center justify-between border-b border-border pb-4">
            <h2 className="flex items-center gap-2 text-sm font-semibold">
              <SlidersHorizontal className="h-4 w-4" />
              Filtreler
            </h2>
            <button
              onClick={handleClear}
              className="text-xs text-text-muted hover:text-foreground"
            >
              Sıfırla
            </button>
          </div>
          <FiltersPanel
            filters={filters}
            onChange={(next) => setFilters((prev) => ({ ...prev, ...next }))}
            onApply={handleApply}
            onClear={handleClear}
          />
        </aside>
        <section className="min-w-0">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
            <p aria-live="polite" className="text-sm text-text-muted">
              {isLoading ? (
                "İlanlar yükleniyor…"
              ) : (
                <>
                  <strong className="font-semibold text-foreground">
                    {totalCount} ilan
                  </strong>{" "}
                  bulundu
                </>
              )}
            </p>
            <label className="flex items-center gap-2 text-xs text-text-muted">
              <span>Sırala</span>
              <select
                aria-label="İlanları sırala"
                className="h-10 rounded-lg border border-border bg-surface px-3 text-xs text-foreground"
                value={initialFilters.sort}
                onChange={(event) =>
                  syncFilters({ ...initialFilters, sort: event.target.value })
                }
              >
                {SORT_OPTIONS.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </label>
          </div>
          {activeFilters.length > 0 && (
            <div className="mb-5 flex flex-wrap gap-2">
              {activeFilters.map((item) => (
                <button
                  key={item.key}
                  onClick={() => applyQuickFilter({ [item.key]: "" })}
                  className="inline-flex items-center gap-2 rounded-full bg-primary-light px-3 py-1.5 text-xs text-foreground"
                  aria-label={`${item.label} filtresini kaldır`}
                >
                  {item.label}
                  <X className="h-3 w-3" />
                </button>
              ))}
            </div>
          )}
          {!canBrowse ? (
            <EmptyState
              title="Üye girişi gerekli"
              description="İlanları görmek için doğrulanmış hesabınla giriş yap."
            />
          ) : isLoading ? (
            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 6 }, (_, i) => (
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
          ) : listings?.length ? (
            <div className="space-y-6"><div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
              {listings.map((listing) => (
                <ListingCard key={listing.id} listing={listing} />
              ))}
            </div><nav aria-label="İlan sayfaları" className="flex items-center justify-center gap-4">
              <Button variant="outline" disabled={page === 0} onClick={() => setPage(page - 1)}>Önceki</Button>
              <span className="text-sm text-text-muted">Sayfa {page + 1}</span>
              <Button variant="outline" disabled={!data?.hasMore} onClick={() => setPage(page + 1)}>Sonraki</Button>
            </nav></div>
          ) : (
            <div className="card p-10 text-center">
              {page > 0 && <Button variant="outline" onClick={() => setPage(page - 1)}>Önceki sayfa</Button>}
              <EmptyState
                title={UI.emptyStates.listings}
                description="Aramanı genişletmek için birkaç filtreyi kaldırabilirsin."
              />
              <Button variant="outline" className="mt-5" onClick={handleClear}>
                Filtreleri temizle
              </Button>
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
