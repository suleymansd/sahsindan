"use client";

import Link from "next/link";
import { AlertTriangle, CheckCircle2, Files, Flag, ShieldCheck, Users } from "lucide-react";
import { useQuery } from "@tanstack/react-query";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type DashboardData = {
  pending_verifications: number;
  approved_today: number;
  published_listings: number;
  reports_last_7d: number;
  top_reported: Array<{ id: number; title: string; state: string; count: number }>;
};

export default function AdminPage() {
  const { accessToken } = useAuth();

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-dashboard"],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth("/admin/dashboard", accessToken);
      return res.data as DashboardData;
    },
    enabled: Boolean(accessToken),
  });

  return (
    <div className="space-y-8">
      <div className="panel-glass p-6">
        <Badge variant="solid-accent">Yönetim Merkezi</Badge>
        <h1 className="mt-3 font-display text-3xl font-semibold tracking-tight">Yönetim Paneli</h1>
        <p className="mt-2 text-sm text-text-muted">Doğrulama, ilan ve güven operasyonları tek ekranda.</p>
      </div>

      {isLoading ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {Array.from({ length: 4 }).map((_, idx) => (
            <Card key={idx}>
              <CardContent className="space-y-3 p-5">
                <Skeleton className="h-4 w-24" />
                <Skeleton className="h-8 w-20" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : null}

      {isError ? (
        <Card>
          <CardContent className="flex items-center justify-between gap-3 p-6 text-sm text-text-muted">
            Yönetim verileri yüklenemedi.
            <Button variant="outline" size="sm" onClick={() => refetch()}>
              Tekrar Dene
            </Button>
          </CardContent>
        </Card>
      ) : null}

      {data ? (
        <>
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <KpiCard
              label="Bekleyen Doğrulama"
              value={data.pending_verifications}
              icon={ShieldCheck}
              tone="warning"
            />
            <KpiCard
              label="Bugün Onaylanan"
              value={data.approved_today}
              icon={CheckCircle2}
              tone="success"
            />
            <KpiCard
              label="Yayındaki İlan"
              value={data.published_listings}
              icon={Files}
              tone="info"
            />
            <KpiCard
              label="Son 7 Gün Rapor"
              value={data.reports_last_7d}
              icon={Flag}
              tone="danger"
            />
          </div>

          <div className="grid gap-4 lg:grid-cols-3">
            <Card className="lg:col-span-2">
              <CardContent className="space-y-4 p-6">
                <div className="flex items-center justify-between gap-3">
                  <h2 className="font-display text-lg font-semibold">En Çok Raporlanan İlanlar</h2>
                  <Button size="sm" variant="outline" asChild>
                    <Link href="/admin/raporlar">Raporları İncele</Link>
                  </Button>
                </div>
                {data.top_reported.length ? (
                  data.top_reported.map((item) => (
                    <div key={item.id} className="flex items-center justify-between rounded-xl border border-border/70 bg-surface-2/70 px-3 py-2 text-sm">
                      <div>
                        <div className="font-medium">{item.title}</div>
                        <div className="text-xs text-text-muted">{item.state}</div>
                      </div>
                      <div className="rounded-full border border-danger/20 bg-danger-bg px-3 py-1 text-xs text-danger">
                        {item.count} rapor
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="text-sm text-text-muted">Raporlanan ilan yok.</div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardContent className="space-y-4 p-6">
                <h2 className="font-display text-lg font-semibold">Hızlı Aksiyonlar</h2>
                <div className="flex flex-col gap-2">
                  <Button asChild>
                    <Link href="/admin/dogrulamalar">Doğrulama Kuyruğu</Link>
                  </Button>
                  <Button variant="outline" asChild>
                    <Link href="/admin/ilanlar">İlan Moderasyonu</Link>
                  </Button>
                  <Button variant="outline" asChild>
                    <Link href="/admin/kullanicilar">Kullanıcı Yönetimi</Link>
                  </Button>
                </div>
                <div className="rounded-xl border border-warning/30 bg-warning-bg/70 p-3 text-xs text-text-muted">
                  <div className="inline-flex items-center gap-1.5 font-medium text-foreground">
                    <AlertTriangle className="h-3.5 w-3.5 text-warning" />
                    Operasyon Notu
                  </div>
                  <p className="mt-1">Rapor yoğunluğu arttığında önce doğrulama ve yayındaki ilan akışını temizle.</p>
                </div>
              </CardContent>
            </Card>
          </div>
        </>
      ) : null}
    </div>
  );
}

function KpiCard({
  label,
  value,
  icon: Icon,
  tone,
}: {
  label: string;
  value: number;
  icon: typeof Users;
  tone: "warning" | "success" | "info" | "danger";
}) {
  const toneClass =
    tone === "warning"
      ? "text-warning bg-warning-bg border-warning/25"
      : tone === "success"
        ? "text-success bg-success-bg border-success/25"
        : tone === "danger"
          ? "text-danger bg-danger-bg border-danger/25"
          : "text-info bg-info-bg border-info/25";

  return (
    <Card>
      <CardContent className="space-y-3 p-5">
        <div className="flex items-center justify-between">
          <div className="text-xs uppercase tracking-[0.12em] text-text-muted">{label}</div>
          <div className={`inline-flex h-8 w-8 items-center justify-center rounded-lg border ${toneClass}`}>
            <Icon className="h-4 w-4" />
          </div>
        </div>
        <div className="text-3xl font-semibold">{value}</div>
      </CardContent>
    </Card>
  );
}
