"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowLeft,
  BadgeCheck,
  Briefcase,
  CalendarClock,
  CircleDashed,
  FileCheck2,
  Mail,
  MapPin,
  Phone,
  ShieldAlert,
  ShieldCheck,
  User2,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/toast";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type VerificationDetail = {
  id: number;
  status: string;
  reason?: string | null;
  reason_code?: string | null;
  created_at: string;
  updated_at: string;
  user: {
    id: number;
    email: string;
    phone: string;
    role: string;
    status: string;
    trust_score: number;
    name?: string | null;
    city?: string | null;
    profession?: string | null;
  };
  assets: Array<{ id: number; type: string; key: string }>;
  audit: Array<{ id: number; action: string; meta: unknown; created_at: string }>;
};

function getStatusMeta(status: string): {
  label: string;
  variant: "success" | "danger" | "warning" | "neutral";
  icon: typeof ShieldCheck;
} {
  if (status === "APPROVED") {
    return { label: "Onaylandı", variant: "success", icon: ShieldCheck };
  }
  if (status === "REJECTED") {
    return { label: "Reddedildi", variant: "danger", icon: ShieldAlert };
  }
  if (status === "MORE_INFO") {
    return { label: "Ek Bilgi Bekliyor", variant: "warning", icon: FileCheck2 };
  }
  return { label: "İncelemede", variant: "neutral", icon: CircleDashed };
}

function InfoRow({ icon: Icon, label, value }: { icon: typeof Mail; label: string; value: string }) {
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

export default function VerificationDetailPage() {
  const { accessToken } = useAuth();
  const params = useParams();
  const router = useRouter();
  const { push } = useToast();
  const [note, setNote] = useState("");
  const [rejectReason, setRejectReason] = useState("");
  const [rejectCode, setRejectCode] = useState("");
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [loadingAction, setLoadingAction] = useState<string | null>(null);

  const requestId = Number(params.id);

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-verification", requestId],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth(`/admin/verification/${requestId}`, accessToken);
      return res.data as VerificationDetail;
    },
    enabled: Boolean(accessToken && requestId),
  });

  async function approve() {
    if (!accessToken) return;
    setLoadingAction("approve");
    try {
      await apiFetchWithAuth(`/admin/verification/${requestId}/approve`, accessToken, {
        method: "POST",
        body: JSON.stringify({ reason: note || null }),
      });
      push({ title: "Doğrulama onaylandı." });
      setNote("");
      refetch();
    } catch {
      push({ title: "Onay başarısız.", description: "Tekrar deneyin." });
    } finally {
      setLoadingAction(null);
    }
  }

  async function reject() {
    if (!accessToken || !rejectReason.trim()) {
      push({ title: "Red nedeni zorunludur." });
      return;
    }
    setLoadingAction("reject");
    try {
      await apiFetchWithAuth(`/admin/verification/${requestId}/reject`, accessToken, {
        method: "POST",
        body: JSON.stringify({ reason: rejectReason, reason_code: rejectCode || null }),
      });
      push({ title: "Başvuru reddedildi." });
      setRejectReason("");
      setRejectCode("");
      refetch();
    } catch {
      push({ title: "Red işlemi başarısız." });
    } finally {
      setLoadingAction(null);
    }
  }

  async function requestMoreInfo() {
    if (!accessToken) return;
    setLoadingAction("more-info");
    try {
      await apiFetchWithAuth(`/admin/verification/${requestId}/request-more-info`, accessToken, {
        method: "POST",
        body: JSON.stringify({ note: note || null }),
      });
      push({ title: "Ek bilgi istendi." });
      setNote("");
      refetch();
    } catch {
      push({ title: "İstek başarısız." });
    } finally {
      setLoadingAction(null);
    }
  }

  async function openAsset(assetId: number) {
    if (!accessToken) return;
    try {
      const res = await apiFetchWithAuth(`/admin/verification/${requestId}/assets/${assetId}/signed-url`, accessToken);
      setPreviewUrl(res.data.url);
    } catch {
      push({ title: "Belge açılamadı." });
    }
  }

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-48 w-full" />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <Card>
        <CardContent className="flex items-center justify-between gap-3 p-6 text-sm text-text-muted">
          Başvuru yüklenemedi.
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            Tekrar dene
          </Button>
        </CardContent>
      </Card>
    );
  }

  const statusMeta = getStatusMeta(data.status);
  const StatusIcon = statusMeta.icon;

  return (
    <div className="space-y-6">
      <div className="panel-glass p-5">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="text-xs uppercase tracking-[0.12em] text-text-muted">Doğrulama Başvurusu</div>
            <h1 className="mt-1 font-display text-2xl font-semibold">Başvuru #{data.id}</h1>
          </div>
          <Button variant="outline" onClick={() => router.back()}>
            <ArrowLeft className="h-4 w-4" />
            Geri dön
          </Button>
        </div>
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardContent className="space-y-5 p-6">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div>
                <div className="text-sm text-text-muted">Kullanıcı Profili</div>
                <div className="mt-1 text-xl font-semibold">{data.user.name || "İsimsiz Kullanıcı"}</div>
              </div>
              <Badge variant={statusMeta.variant}>{statusMeta.label}</Badge>
            </div>

            <div className="grid gap-3 md:grid-cols-2">
              <InfoRow icon={Mail} label="E-posta" value={data.user.email} />
              <InfoRow icon={Phone} label="Telefon" value={data.user.phone} />
              <InfoRow icon={User2} label="Rol" value={data.user.role} />
              <InfoRow icon={MapPin} label="Şehir" value={data.user.city || "Belirtilmedi"} />
              <InfoRow icon={Briefcase} label="Meslek" value={data.user.profession || "Belirtilmedi"} />
              <InfoRow icon={BadgeCheck} label="Güven Skoru" value={`${data.user.trust_score}`} />
            </div>

            <div className="rounded-card border border-border/80 bg-surface-2/60 p-4 text-sm text-text-muted">
              <div className="font-medium text-foreground">Başvuru Zamanı</div>
              <div className="mt-1 inline-flex items-center gap-1.5">
                <CalendarClock className="h-4 w-4 text-info" />
                {new Date(data.created_at).toLocaleString("tr-TR")}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="text-sm text-text-muted">Karar Özeti</div>
            <div className="rounded-card border border-border/80 bg-surface-2/60 p-4">
              <div className="inline-flex items-center gap-2">
                <span className="icon-3d h-8 w-8">
                  <StatusIcon className="h-4 w-4" />
                </span>
                <div>
                  <div className="text-sm font-medium">{statusMeta.label}</div>
                  <div className="text-xs text-text-muted">
                    Güncelleme: {new Date(data.updated_at).toLocaleString("tr-TR")}
                  </div>
                </div>
              </div>
            </div>
            <div className="space-y-1 text-sm">
              <div className="text-text-muted">Açıklama</div>
              <div className="rounded-btn border border-border/75 bg-surface px-3 py-2 text-sm">
                {data.reason || "Açıklama girilmedi."}
              </div>
            </div>
            <div className="space-y-1 text-sm">
              <div className="text-text-muted">Sebep Kodu</div>
              <div className="rounded-btn border border-border/75 bg-surface px-3 py-2 text-sm">
                {data.reason_code || "-"}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="space-y-4 p-6">
          <div className="text-sm text-text-muted">Belgeler</div>
          {data.assets.length ? (
            <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
              {data.assets.map((asset) => (
                <button
                  key={asset.id}
                  type="button"
                  onClick={() => openAsset(asset.id)}
                  className="group rounded-card border border-border/80 bg-surface px-4 py-3 text-left transition-all hover:-translate-y-0.5 hover:border-info/45 hover:shadow-soft"
                >
                  <div className="inline-flex items-center gap-2 text-sm font-medium">
                    <span className="icon-3d h-7 w-7">
                      <FileCheck2 className="h-3.5 w-3.5" />
                    </span>
                    {asset.type}
                  </div>
                  <div className="mt-2 text-xs text-text-muted">Belgeyi güvenli bağlantı ile aç</div>
                </button>
              ))}
            </div>
          ) : (
            <div className="text-sm text-text-muted">Belge bulunamadı.</div>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-4 xl:grid-cols-2">
        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="text-sm text-text-muted">Onay / Ek Bilgi</div>
            <Textarea
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="Onay notu veya ek bilgi talebi"
            />
            <div className="flex flex-wrap gap-2">
              <Button onClick={approve} disabled={loadingAction === "approve"}>
                {loadingAction === "approve" ? "Onaylanıyor..." : "Onayla"}
              </Button>
              <Button variant="outline" onClick={requestMoreInfo} disabled={loadingAction === "more-info"}>
                {loadingAction === "more-info" ? "Gönderiliyor..." : "Ek Bilgi İste"}
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="text-sm text-text-muted">Reddet</div>
            <div className="grid gap-3">
              <Input
                placeholder="Red sebebi (zorunlu)"
                value={rejectReason}
                onChange={(event) => setRejectReason(event.target.value)}
              />
              <Input
                placeholder="Red kodu (opsiyonel)"
                value={rejectCode}
                onChange={(event) => setRejectCode(event.target.value)}
              />
            </div>
            <Button variant="destructive" onClick={reject} disabled={loadingAction === "reject"}>
              {loadingAction === "reject" ? "Reddediliyor..." : "Reddet"}
            </Button>
          </CardContent>
        </Card>
      </div>

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

      <Dialog open={Boolean(previewUrl)} onOpenChange={() => setPreviewUrl(null)}>
        <DialogContent className="max-w-3xl">
          {previewUrl ? (
            <img src={previewUrl} alt="Belge önizleme" className="max-h-[70vh] w-full rounded-card object-contain" />
          ) : null}
        </DialogContent>
      </Dialog>
    </div>
  );
}
