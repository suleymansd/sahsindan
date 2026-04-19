"use client";

import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Building2, Coins, ImageIcon, MapPin, SlidersHorizontal } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/components/toast";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type SettingsData = {
  stale_days: number;
  confirm_window_days: number;
  photo_max_count: number;
  photo_max_mb: number;
  listing_fee: number;
  membership_fee: number;
  feature_flags: { real_estate?: boolean };
  city_lock: string;
};

export default function SettingsAdminPage() {
  const { accessToken, user } = useAuth();
  const { push } = useToast();
  const [form, setForm] = useState<SettingsData | null>(null);
  const [saving, setSaving] = useState(false);

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-settings"],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth("/admin/settings", accessToken);
      return res.data as SettingsData;
    },
    enabled: Boolean(accessToken),
  });

  useEffect(() => {
    if (data) setForm(data);
  }, [data]);

  function setNumber<K extends keyof SettingsData>(key: K, value: number) {
    if (!form) return;
    setForm({ ...form, [key]: Number.isFinite(value) ? value : 0 });
  }

  async function save() {
    if (!accessToken || !form) return;
    setSaving(true);
    try {
      await apiFetchWithAuth("/admin/settings", accessToken, {
        method: "PUT",
        body: JSON.stringify(form),
      });
      push({ title: "Ayarlar kaydedildi." });
    } catch {
      push({ title: "Ayarlar kaydedilemedi." });
    } finally {
      setSaving(false);
    }
  }

  if (user && user.role !== "ADMIN") {
    return (
      <Card>
        <CardContent className="p-6 text-sm text-text-muted">
          Bu sayfayı yalnızca admin kullanıcılar görebilir.
        </CardContent>
      </Card>
    );
  }

  if (isLoading || !form) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  if (isError) {
    return (
      <Card>
        <CardContent className="flex items-center justify-between gap-3 p-6 text-sm text-text-muted">
          Ayarlar yüklenemedi.
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            Tekrar dene
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <div className="panel-glass p-5">
        <div className="text-xs uppercase tracking-[0.12em] text-text-muted">Platform Konfigürasyonu</div>
        <h1 className="mt-1 font-display text-2xl font-semibold">Admin Ayarları</h1>
      </div>

      <div className="grid gap-4 xl:grid-cols-2">
        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="inline-flex items-center gap-2 text-sm text-text-muted">
              <SlidersHorizontal className="h-4 w-4" />
              İlan Döngüsü
            </div>

            <div className="grid gap-3 md:grid-cols-2">
              <SettingField
                label="Stale gün sayısı"
                value={form.stale_days}
                onChange={(value) => setNumber("stale_days", value)}
              />
              <SettingField
                label="Onay penceresi (gün)"
                value={form.confirm_window_days}
                onChange={(value) => setNumber("confirm_window_days", value)}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="inline-flex items-center gap-2 text-sm text-text-muted">
              <ImageIcon className="h-4 w-4" />
              Fotoğraf Limitleri
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <SettingField
                label="Maksimum adet"
                value={form.photo_max_count}
                onChange={(value) => setNumber("photo_max_count", value)}
              />
              <SettingField
                label="Maksimum MB"
                value={form.photo_max_mb}
                onChange={(value) => setNumber("photo_max_mb", value)}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="inline-flex items-center gap-2 text-sm text-text-muted">
              <Coins className="h-4 w-4" />
              Ücretlendirme
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <SettingField
                label="İlan ücreti"
                value={form.listing_fee}
                onChange={(value) => setNumber("listing_fee", value)}
              />
              <SettingField
                label="Üyelik ücreti"
                value={form.membership_fee}
                onChange={(value) => setNumber("membership_fee", value)}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="inline-flex items-center gap-2 text-sm text-text-muted">
              <Building2 className="h-4 w-4" />
              Modül ve Bölge Kontrolü
            </div>

            <div className="flex items-center justify-between rounded-btn border border-border/75 bg-surface/75 p-3 text-sm">
              <div>
                <div className="font-medium">Emlak Modülü</div>
                <div className="text-xs text-text-muted">Kapalıysa son kullanıcıda gizlenir.</div>
              </div>
              <Switch
                checked={Boolean(form.feature_flags?.real_estate)}
                onCheckedChange={(checked) =>
                  setForm({ ...form, feature_flags: { ...form.feature_flags, real_estate: checked } })
                }
              />
            </div>

            <div>
              <div className="mb-1 inline-flex items-center gap-1.5 text-xs text-text-muted">
                <MapPin className="h-3.5 w-3.5" />
                Şehir kilidi
              </div>
              <Input
                placeholder="örn. İstanbul"
                value={form.city_lock}
                onChange={(event) => setForm({ ...form, city_lock: event.target.value })}
              />
            </div>
          </CardContent>
        </Card>
      </div>

      <Button onClick={save} disabled={saving}>
        {saving ? "Kaydediliyor..." : "Ayarları Kaydet"}
      </Button>
    </div>
  );
}

function SettingField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: number;
  onChange: (value: number) => void;
}) {
  return (
    <div>
      <div className="mb-1 text-xs text-text-muted">{label}</div>
      <Input type="number" value={value} onChange={(event) => onChange(Number(event.target.value))} />
    </div>
  );
}
