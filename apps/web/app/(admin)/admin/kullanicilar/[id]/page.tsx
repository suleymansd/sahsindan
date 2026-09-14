"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowLeft,
  CalendarClock,
  FileText,
  Mail,
  MapPin,
  Phone,
  Shield,
  ShieldBan,
  User,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/toast";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type UserDetail = {
  id: number;
  email: string;
  phone: string;
  role: string;
  status: string;
  trust_score: number;
  last_login_at: string | null;
  created_at: string;
  profile: {
    name?: string | null;
    city?: string | null;
    profession?: string | null;
    profession_verified?: boolean;
  };
  verification_requests: Array<{
    id: number;
    status: string;
    reason?: string | null;
    reason_code?: string | null;
    created_at: string;
  }>;
  listings: Array<{ id: number; title: string; state: string }>;
  trust: {
    total: number;
    base: number;
    profession: number;
    completed_appointments: number;
    no_show_penalty: number;
    report_penalty: number;
  };
  audit: Array<{ id: number; action: string; meta: unknown; created_at: string }>;
};

function roleVariant(role: string): "warning" | "success" | "danger" | "neutral" {
  if (role === "ADMIN" || role === "MODERATOR") return "warning";
  if (role === "USER_VERIFIED") return "success";
  if (role === "BANNED") return "danger";
  return "neutral";
}

export default function UserDetailPage() {
  const { accessToken, user } = useAuth();
  const params = useParams();
  const router = useRouter();
  const { push } = useToast();
  const [note, setNote] = useState("");
  const [role, setRole] = useState("USER_PENDING");
  const [busy, setBusy] = useState<string | null>(null);

  const userId = Number(params.id);
  const isAdmin = user?.role === "ADMIN";

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-user", userId],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth(`/admin/users/${userId}`, accessToken);
      return res.data as UserDetail;
    },
    enabled: Boolean(accessToken && userId),
  });

  useEffect(() => {
    if (data?.role) {
      setRole(data.role);
    }
  }, [data?.role]);

  async function addNote() {
    if (!accessToken || !note.trim()) {
      push({ title: "Not boş olamaz." });
      return;
    }
    setBusy("note");
    try {
      await apiFetchWithAuth(`/admin/users/${userId}/internal-note`, accessToken, {
        method: "POST",
        body: JSON.stringify({ note }),
      });
      push({ title: "Not eklendi." });
      setNote("");
      refetch();
    } catch {
      push({ title: "Not eklenemedi." });
    } finally {
      setBusy(null);
    }
  }

  async function banUser() {
    if (!accessToken) return;
    setBusy("ban");
    try {
      await apiFetchWithAuth(`/admin/users/${userId}/ban`, accessToken, {
        method: "POST",
        body: JSON.stringify({ reason: note || null }),
      });
      push({ title: "Kullanıcı banlandı." });
      refetch();
    } catch {
      push({ title: "Ban işlemi başarısız." });
    } finally {
      setBusy(null);
    }
  }

  async function unbanUser() {
    if (!accessToken) return;
    setBusy("unban");
    try {
      await apiFetchWithAuth(`/admin/users/${userId}/unban`, accessToken, {
        method: "POST",
        body: JSON.stringify({ role }),
      });
      push({ title: "Kullanıcı aktif edildi." });
      refetch();
    } catch {
      push({ title: "Unban başarısız." });
    } finally {
      setBusy(null);
    }
  }

  async function updateRole() {
    if (!accessToken) return;
    setBusy("role");
    try {
      await apiFetchWithAuth(`/admin/users/${userId}/role`, accessToken, {
        method: "POST",
        body: JSON.stringify({ role }),
      });
      push({ title: "Rol güncellendi." });
      refetch();
    } catch {
      push({ title: "Rol güncellenemedi." });
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
          Kullanıcı yüklenemedi.
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
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="text-xs uppercase tracking-[0.12em] text-text-muted">Kullanıcı Yönetimi</div>
            <h1 className="mt-1 font-display text-2xl font-semibold">{data.profile.name || data.email}</h1>
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
            <div className="flex flex-wrap items-center gap-2">
              <Badge variant={roleVariant(data.role)}>{data.role}</Badge>
              <Badge variant={data.status === "ACTIVE" ? "success" : "warning"}>{data.status}</Badge>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <InfoRow icon={Mail} label="E-posta" value={data.email} />
              <InfoRow icon={Phone} label="Telefon" value={data.phone} />
              <InfoRow icon={User} label="Meslek" value={data.profile.profession || "Belirtilmedi"} />
              <InfoRow icon={MapPin} label="Şehir" value={data.profile.city || "Belirtilmedi"} />
              <InfoRow
                icon={CalendarClock}
                label="Son giriş"
                value={data.last_login_at ? new Date(data.last_login_at).toLocaleString("tr-TR") : "Yok"}
              />
              <InfoRow
                icon={CalendarClock}
                label="Kayıt tarihi"
                value={new Date(data.created_at).toLocaleDateString("tr-TR")}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-3 p-6 text-sm">
            <div className="text-text-muted">Güven Skoru</div>
            <div className="text-4xl font-semibold">{data.trust.total}</div>
            <div className="space-y-2 text-xs">
              <ScoreLine label="Temel puan" value={data.trust.base} plus />
              <ScoreLine label="Meslek doğrulama" value={data.trust.profession} plus />
              <ScoreLine label="Tamamlanan randevu" value={data.trust.completed_appointments} plus />
              <ScoreLine label="No-show cezası" value={data.trust.no_show_penalty} minus />
              <ScoreLine label="Rapor cezası" value={data.trust.report_penalty} minus />
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4 xl:grid-cols-2">
        <Card>
          <CardContent className="space-y-4 p-6 text-sm">
            <div className="text-text-muted">Doğrulama Geçmişi</div>
            {data.verification_requests.length ? (
              <div className="space-y-2">
                {data.verification_requests.map((req) => (
                  <div key={req.id} className="rounded-btn border border-border/75 bg-surface/85 px-3 py-2">
                    <div className="inline-flex items-center gap-2">
                      <Badge variant={req.status === "APPROVED" ? "success" : req.status === "REJECTED" ? "danger" : "warning"}>
                        {req.status}
                      </Badge>
                      <span className="text-xs text-text-muted">#{req.id}</span>
                    </div>
                    <div className="mt-1 text-xs text-text-muted">
                      {new Date(req.created_at).toLocaleString("tr-TR")}
                    </div>
                    {req.reason ? <div className="mt-1 text-xs">{req.reason}</div> : null}
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-text-muted">Başvuru yok.</div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardContent className="space-y-4 p-6 text-sm">
            <div className="text-text-muted">Kullanıcı İlanları</div>
            {data.listings.length ? (
              <div className="space-y-2">
                {data.listings.map((listing) => (
                  <div key={listing.id} className="flex items-center justify-between rounded-btn border border-border/75 bg-surface/85 px-3 py-2">
                    <div className="line-clamp-1 text-sm font-medium">{listing.title}</div>
                    <Badge variant={listing.state === "PUBLISHED" ? "success" : listing.state === "SOLD" ? "danger" : "neutral"}>
                      {listing.state}
                    </Badge>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-text-muted">İlan yok.</div>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="space-y-4 p-6">
          <div className="text-sm text-text-muted">Admin Aksiyonları</div>
          <Textarea placeholder="İç not veya ban nedeni" value={note} onChange={(event) => setNote(event.target.value)} />

          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <Input
              placeholder="Rol seç"
              value={role}
              onChange={(event) => setRole(event.target.value)}
              list="admin-user-role-options"
            />
            <datalist id="admin-user-role-options">
              <option value="ADMIN" />
              <option value="MODERATOR" />
              <option value="USER_VERIFIED" />
              <option value="USER_PENDING" />
              <option value="BANNED" />
            </datalist>

            <Button variant="outline" onClick={addNote} disabled={busy === "note"}>
              {busy === "note" ? "Kaydediliyor..." : "Not Ekle"}
            </Button>

            {isAdmin ? (
              <Button variant="outline" onClick={updateRole} disabled={busy === "role"}>
                {busy === "role" ? "Güncelleniyor..." : "Rolü Güncelle"}
              </Button>
            ) : (
              <Button variant="outline" disabled>
                Rol Güncelle (ADMIN)
              </Button>
            )}

            {isAdmin ? (
              <Button variant="destructive" onClick={banUser} disabled={busy === "ban"}>
                {busy === "ban" ? "İşleniyor..." : "Banla"}
              </Button>
            ) : (
              <Button variant="outline" disabled>
                Banla (ADMIN)
              </Button>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {isAdmin ? (
              <Button variant="outline" onClick={unbanUser} disabled={busy === "unban"}>
                {busy === "unban" ? "İşleniyor..." : "Ban Kaldır"}
              </Button>
            ) : (
              <Button variant="outline" disabled>
                Ban Kaldır (ADMIN)
              </Button>
            )}
            <div className="inline-flex items-center gap-1 rounded-full border border-warning/30 bg-warning-bg px-3 py-1 text-xs text-warning">
              <ShieldBan className="h-3.5 w-3.5" />
              Kritik aksiyonlar audit log&apos;a yazılır
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
                  <div className="inline-flex items-center gap-1.5 text-sm font-medium">
                    <FileText className="h-3.5 w-3.5 text-info" />
                    {item.action}
                  </div>
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
  icon: typeof Mail;
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

function ScoreLine({ label, value, plus, minus }: { label: string; value: number; plus?: boolean; minus?: boolean }) {
  return (
    <div className="flex items-center justify-between rounded-btn border border-border/75 bg-surface/75 px-2.5 py-1.5">
      <span className="inline-flex items-center gap-1 text-text-muted">
        <Shield className="h-3.5 w-3.5" />
        {label}
      </span>
      <span
        className={
          plus
            ? "font-semibold text-success"
            : minus
              ? "font-semibold text-danger"
              : "font-semibold text-foreground"
        }
      >
        {plus ? `+${value}` : value}
      </span>
    </div>
  );
}
