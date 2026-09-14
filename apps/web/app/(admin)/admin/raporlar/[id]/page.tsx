"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  AlertTriangle,
  ArrowLeft,
  CalendarClock,
  FileWarning,
  Flag,
  ListChecks,
  ShieldBan,
  User,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/toast";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type ReportDetail = {
  id: number;
  listing_id?: number | null;
  target_type: string;
  target_id: number | null;
  reason: string;
  category?: string | null;
  status: string;
  created_at: string;
  reporter?: { id: number; email: string } | null;
  audit: Array<{ id: number; action: string; meta: unknown; created_at: string }>;
};

function getReportStatusMeta(status: string): {
  label: string;
  variant: "neutral" | "warning" | "success";
} {
  if (status === "IN_REVIEW") return { label: "İnceleniyor", variant: "warning" };
  if (status === "RESOLVED") return { label: "Çözüldü", variant: "success" };
  return { label: "Açık", variant: "neutral" };
}

export default function ReportDetailPage() {
  const { accessToken } = useAuth();
  const params = useParams();
  const router = useRouter();
  const { push } = useToast();
  const [status, setStatus] = useState("OPEN");
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState<string | null>(null);

  const reportId = Number(params.id);

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-report", reportId],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth(`/admin/reports/${reportId}`, accessToken);
      return res.data as ReportDetail;
    },
    enabled: Boolean(accessToken && reportId),
  });

  useEffect(() => {
    if (data?.status) setStatus(data.status);
  }, [data?.status]);

  async function updateStatus() {
    if (!accessToken) return;
    setBusy("status");
    try {
      await apiFetchWithAuth(`/admin/reports/${reportId}/set-status`, accessToken, {
        method: "POST",
        body: JSON.stringify({ status }),
      });
      push({ title: "Durum güncellendi." });
      refetch();
    } catch {
      push({ title: "Durum güncellenemedi." });
    } finally {
      setBusy(null);
    }
  }

  async function takeDownListing() {
    if (!accessToken) return;
    setBusy("take-down");
    try {
      await apiFetchWithAuth(`/admin/reports/${reportId}/action`, accessToken, {
        method: "POST",
        body: JSON.stringify({ action: "take_down_listing", note }),
      });
      push({ title: "İlana aksiyon uygulandı." });
      refetch();
    } catch {
      push({ title: "Aksiyon başarısız." });
    } finally {
      setBusy(null);
    }
  }

  async function suggestBan() {
    if (!accessToken) return;
    setBusy("ban-suggest");
    try {
      await apiFetchWithAuth(`/admin/reports/${reportId}/action`, accessToken, {
        method: "POST",
        body: JSON.stringify({ action: "ban_suggest", note }),
      });
      push({ title: "Ban önerisi kaydedildi." });
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
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-48 w-full" />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <Card>
        <CardContent className="flex items-center justify-between gap-3 p-6 text-sm text-text-muted">
          Rapor yüklenemedi.
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            Tekrar dene
          </Button>
        </CardContent>
      </Card>
    );
  }

  const statusMeta = getReportStatusMeta(data.status);

  return (
    <div className="space-y-6">
      <div className="panel-glass p-5">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="text-xs uppercase tracking-[0.12em] text-text-muted">Rapor Yönetimi</div>
            <h1 className="mt-1 font-display text-2xl font-semibold">Rapor #{data.id}</h1>
          </div>
          <Button variant="outline" onClick={() => router.back()}>
            <ArrowLeft className="h-4 w-4" />
            Geri dön
          </Button>
        </div>
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardContent className="space-y-4 p-6 text-sm">
            <div className="inline-flex items-center gap-2">
              <span className="icon-3d h-8 w-8">
                <AlertTriangle className="h-4 w-4" />
              </span>
              <div>
                <div className="font-medium">{data.reason}</div>
                <div className="text-xs text-text-muted">Kategori: {data.category || "Genel"}</div>
              </div>
            </div>

            <div className="grid gap-3 md:grid-cols-2">
              <InfoRow icon={Flag} label="Rapor Türü" value={data.target_type} />
              <InfoRow icon={FileWarning} label="Hedef ID" value={String(data.target_id ?? "-")} />
              <InfoRow icon={ListChecks} label="İlan ID" value={String(data.listing_id ?? "-")} />
              <InfoRow
                icon={User}
                label="Raporlayan"
                value={data.reporter?.email || "Kullanıcı bilgisi yok"}
              />
              <InfoRow
                icon={CalendarClock}
                label="Oluşturulma"
                value={new Date(data.created_at).toLocaleString("tr-TR")}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-4 p-6 text-sm">
            <div className="text-text-muted">Durum</div>
            <Badge variant={statusMeta.variant}>{statusMeta.label}</Badge>
            <select
              value={status}
              onChange={(event) => setStatus(event.target.value)}
              className="h-12 w-full rounded-btn border border-border/85 bg-surface/90 px-3 text-sm shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              <option value="OPEN">Açık</option>
              <option value="IN_REVIEW">İnceleniyor</option>
              <option value="RESOLVED">Çözüldü</option>
            </select>
            <Button onClick={updateStatus} disabled={busy === "status"}>
              {busy === "status" ? "Kaydediliyor..." : "Durumu Kaydet"}
            </Button>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="space-y-4 p-6">
          <div className="text-sm text-text-muted">Aksiyon Uygula</div>
          <Textarea placeholder="Aksiyon notu" value={note} onChange={(event) => setNote(event.target.value)} />
          <div className="flex flex-wrap gap-2">
            <Button variant="outline" onClick={takeDownListing} disabled={busy === "take-down"}>
              {busy === "take-down" ? "İşleniyor..." : "İlanı Yayından Kaldır"}
            </Button>
            <Button variant="outline" onClick={suggestBan} disabled={busy === "ban-suggest"}>
              {busy === "ban-suggest" ? "İşleniyor..." : "Ban Önerisi Oluştur"}
            </Button>
            <div className="inline-flex items-center gap-1 rounded-full border border-warning/30 bg-warning-bg px-3 py-1 text-xs text-warning">
              <ShieldBan className="h-3.5 w-3.5" />
              Aksiyonlar audit log&apos;a kaydedilir
            </div>
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

function InfoRow({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof Flag;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-btn border border-border/80 bg-surface/85 px-3 py-2.5">
      <div className="inline-flex items-center gap-1.5 text-xs text-text-muted">
        <Icon className="h-3.5 w-3.5" />
        {label}
      </div>
      <div className="mt-1 text-sm font-medium">{value}</div>
    </div>
  );
}
